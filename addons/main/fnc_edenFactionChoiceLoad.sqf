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
//    STRICT SIDE FILTER: only include factions with side 0/1/2/3 (OPFOR /
//    BLUFOR / INDFOR / CIVILIAN). Drops BI internals like "Default", "Alive",
//    "Buildings" etc. which use side 7 for logic/non-combat purposes and
//    aren't valid faction choices for mission makers.
// ------------------------------------------------------------------------
private _seen = createHashMap; // lowercase classname -> true, for dedup
private _entries = [];
private _totalScanned = 0;
private _droppedBadSide = 0;

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

                if (_side in [0, 1, 2, 3]) then {
                    private _dn = getText (_fac >> "displayName");
                    if (_dn isEqualTo "") then { _dn = _cn };
                    _entries pushBack [_cn, _dn, _side];
                } else {
                    _droppedBadSide = _droppedBadSide + 1;
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
    "ALIVE FactionChoice LOAD: scanned=%1 dropped(bad side)=%2 populated=%3 stored='%4' selected=%5 (lbData='%6')",
    _totalScanned,
    _droppedBadSide,
    count _entries,
    _value,
    _foundIdx,
    if (_foundIdx >= 0 && _foundIdx < lbSize _ctrl) then { _ctrl lbData _foundIdx } else { "(none)" }
];
