#include "\x\alive\addons\main\script_component.hpp"
SCRIPT(edenFactionChoiceLoad);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_edenFactionChoiceLoad

Description:
Eden-attribute `attributeLoad` handler for the shared ALiVE_FactionChoice
control. Populates the Combo with every faction found in CfgFactionClasses
(both missionConfigFile and configFile), grouped by side. Preserves legacy
typed strings by adding an "(unrecognised)" entry at the top if the stored
value doesn't match any loaded faction.

Defensive enumeration:
  - Missing displayName falls back to the classname
  - Missing/invalid side falls into the "Other" bucket instead of dropping
  - Empty CfgFactionClasses entries are skipped silently
  - Duplicate classnames across missionConfig + configFile are deduped

Case-insensitive matching when restoring the selected value (closes #651).

Shared across mil_placement, civ_placement, civ_placement_custom, and any
future ALiVE module with a `faction` attribute.

Lives in its own .sqf file because Arma's config preprocessor struggles with
multi-line `"..."` strings containing backslash-newline continuations on
Windows CRLF files (same rationale as mil_ied's edenIntegrationChoice
handlers).

Parameters:
    _this: DISPLAY - the Eden attribute's display. Combo control has IDC 100.

Author:
Jman
---------------------------------------------------------------------------- */

// ------------------------------------------------------------------------
// 1. Resolve the currently-stored faction string.
//    Priority: logic variable > Eden attribute value slot > "OPF_F" default.
// ------------------------------------------------------------------------
private _selected = get3DENSelected "logic";
private _storedFromLogic = if (count _selected > 0) then {
    (_selected select 0) getVariable ["faction", nil]
} else {
    nil
};
private _edenValue = _this getVariable "value";

private _value = "OPF_F";
if (!isNil "_edenValue" && {typeName _edenValue == "STRING"} && {_edenValue != ""}) then {
    _value = _edenValue;
};
if (!isNil "_storedFromLogic" && {typeName _storedFromLogic == "STRING"} && {_storedFromLogic != ""}) then {
    _value = _storedFromLogic;  // logic variable wins - re-opening the panel picks up the just-saved value
};

// Defensive: strip surrounding single quotes from the stored value. Legacy
// missions saved with an earlier version of the Combo defaultValue format
// (`"""'OPF_F'"""`) accidentally wrote a 7-char quoted string `'OPF_F'`
// instead of the intended 5-char `OPF_F`, because the config-level triple-
// quote + inner-single-quote combination evaluated to an SQF literal that
// kept the apostrophes. Stripping them here heals those missions on next
// save (the Save handler returns clean lbData).
private _len = count _value;
if (
    _len >= 2 &&
    {(_value select [0, 1]) == "'"} &&
    {(_value select [_len - 1, 1]) == "'"}
) then {
    _value = _value select [1, _len - 2];
};

// ------------------------------------------------------------------------
// 2. Locate the Combo control inside the attribute display.
//    BI Combo template exposes its combo at IDC 100.
// ------------------------------------------------------------------------
private _ctrl = _this controlsGroupCtrl 100;
if (isNull _ctrl) exitWith {
    diag_log "ALIVE FactionChoice LOAD: combo control (IDC 100) not found";
};

lbClear _ctrl;

// ------------------------------------------------------------------------
// 3. Enumerate factions defensively.
//
//    Two filters:
//    (a) STRICT SIDE FILTER: only include factions with side 0/1/2/3
//        (OPFOR / BLUFOR / INDFOR / CIVILIAN). Drops BI internals like
//        "Default", "Alive", "Buildings" which use side 7 for logic /
//        non-combat purposes.
//    (b) STRUCTURAL USABILITY FILTER: only include factions that actually
//        have CfgGroups entries for their side. mil_placement /
//        civ_placement spawn UNIT GROUPS, so a faction with no CfgGroups
//        coverage can't be used by these modules. This auto-excludes BI
//        internals like "Virtual" (VR training), "Civilian Other
//        (Interactive)" (Argo-era interactive content), mod dummy-faction
//        stubs, etc. - without needing a maintained blacklist.
//
//    Design choice: structural filter beats hardcoded blacklist because it
//    stays correct as new mods and BI updates introduce new internal
//    factions. If a mod later registers a faction WITH CfgGroups that
//    shouldn't appear, Phase 2's Cfg3rdPartyFactions registry will
//    provide a config-driven exclusion hook.
// ------------------------------------------------------------------------

// Side index -> CfgGroups top-level class name. Side 0/1/2/3 only; the
// bad-side filter below handles everything else.
private _sideCfgGroupsName = ["East", "West", "Indep", "Civilian"];

private _seen = createHashMap; // lowercase classname -> true, for dedup
private _entries = [];
private _totalScanned = 0;
private _droppedBadSide = 0;
private _droppedNoGroups = 0;

private _configPaths = [
    missionConfigFile >> "CfgFactionClasses",
    configFile >> "CfgFactionClasses"
];
{
    private _root = _x;
    for "_i" from 0 to (count _root - 1) do {
        private _fac = _root select _i;
        if (isClass _fac) then {
            _totalScanned = _totalScanned + 1;
            private _cn = configName _fac;
            private _cnLower = toLower _cn;
            if !(_cnLower in _seen) then {
                _seen set [_cnLower, true];
                // getNumber follows inheritance and returns 0 for missing,
                // so use it directly then validate the result is a real side.
                private _side = getNumber (_fac >> "side");
                // isNumber check distinguishes "explicitly 0" from "missing".
                // If side property is entirely absent (not even inherited),
                // treat as -1 so the validation below drops the entry.
                if !(isNumber (_fac >> "side")) then { _side = -1 };

                if !(_side in [0, 1, 2, 3]) then {
                    _droppedBadSide = _droppedBadSide + 1;
                } else {
                    // Structural usability filter:
                    //   Military sides (0/1/2) spawn via CfgGroups entries
                    //   (squads / platoons / companies). A military faction
                    //   with no CfgGroups is unusable by mil_placement.
                    //   Civilian side (3) spawns INDIVIDUAL units via
                    //   findVehicleType "Man" + createUnit. Vanilla A3's
                    //   CfgGroups >> Civilian >> CIV_F is empty (no defined
                    //   squads), but CIV_F is the primary faction for every
                    //   civilian placement mission. Exempt civilians from
                    //   the CfgGroups check.
                    private _usable = if (_side == 3) then {
                        true
                    } else {
                        private _sideName = _sideCfgGroupsName select _side;
                        private _groupsEntry = configFile >> "CfgGroups" >> _sideName >> _cn;
                        isClass _groupsEntry && {count _groupsEntry > 0}
                    };
                    if (_usable) then {
                        private _dn = getText (_fac >> "displayName");
                        if (_dn isEqualTo "") then { _dn = _cn };
                        _entries pushBack [_cn, _dn, _side];
                    } else {
                        _droppedNoGroups = _droppedNoGroups + 1;
                    };
                };
            };
        };
    };
} forEach _configPaths;

// ------------------------------------------------------------------------
// 4. Populate combo grouped by side.
//    Order: OPFOR, BLUFOR, INDFOR, CIVILIAN.
// ------------------------------------------------------------------------
private _sideBuckets = [
    [0, "OPFOR"],
    [1, "BLUFOR"],
    [2, "INDFOR"],
    [3, "CIVILIAN"]
];

{
    _x params ["_sideValue", "_sideLabel"];
    private _bucketEntries = _entries select {
        _x params ["", "", "_s"];
        _s == _sideValue
    };
    // Sort by classname ascending (first element). Deterministic ordering.
    _bucketEntries sort true;

    {
        _x params ["_cn", "_dn"];
        private _label = format ["%1 - %2", _sideLabel, _dn];
        private _idx = _ctrl lbAdd _label;
        _ctrl lbSetData [_idx, _cn];
    } forEach _bucketEntries;
} forEach _sideBuckets;

// ------------------------------------------------------------------------
// 5. Select the stored value. Case-insensitive compare against lbData.
//    If not found, add an "(unrecognised) <value>" entry so legacy / typo'd
//    / mod-unloaded factions aren't silently lost.
// ------------------------------------------------------------------------
private _foundIdx = -1;
private _valueLower = toLower _value;
for "_i" from 0 to (lbSize _ctrl - 1) do {
    if ((toLower (_ctrl lbData _i)) == _valueLower) exitWith {
        _foundIdx = _i;
    };
};

if (_foundIdx == -1 && _value != "") then {
    private _idx = _ctrl lbAdd format ["(unrecognised) %1", _value];
    _ctrl lbSetData [_idx, _value];
    _foundIdx = _idx;
};

if (_foundIdx < 0) then { _foundIdx = 0 }; // defensive: empty list somehow
_ctrl lbSetCurSel _foundIdx;

// ------------------------------------------------------------------------
// Diagnostic logging: helps debug cases where a user expected a faction
// to appear in the dropdown but didn't see it. RPT output includes:
//  - total CfgFactionClasses entries scanned (mission + base config)
//  - how many were dropped by the strict side filter (side != 0/1/2/3)
//  - count of entries populated into the combo
//  - the stored value being matched against
//  - match outcome (index + resolved lbData, or "(added as unrecognised)")
// ------------------------------------------------------------------------
diag_log format [
    "ALIVE FactionChoice LOAD: scanned=%1 dropped(bad side)=%2 dropped(no CfgGroups)=%3 populated=%4 stored='%5' selected=%6 (lbData='%7')",
    _totalScanned,
    _droppedBadSide,
    _droppedNoGroups,
    count _entries,
    _value,
    _foundIdx,
    if (_foundIdx >= 0 && _foundIdx < lbSize _ctrl) then { _ctrl lbData _foundIdx } else { "(none)" }
];
