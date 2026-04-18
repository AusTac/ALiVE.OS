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

// Civilian-only blacklist. Civilians are exempt from the CfgGroups
// structural filter (they spawn as individuals, not groups), so we need
// a targeted list for internal / non-real civilian-side factions that
// have CfgVehicles units but aren't meaningful mission-maker choices.
// Extend as new edge cases surface. Phase 2's Cfg3rdPartyFactions
// registry will turn this into a config-driven exclusion hook.
// Entries MUST be lowercase classnames for the toLower comparison below.
// (Caveat: BI's CfgFactionClasses uses _F suffix on most internal
// civilian classes - blacklist by classname, not displayName.)
private _civilianBlacklist = [
    "virtual_f",      // BI VR / Virtual Arsenal training faction (displayName "Virtual")
    "interactive_f"   // BI Argo-era interactive content (displayName "Other (Interactive)")
];

// ------------------------------------------------------------------------
// Build registry overrides map from Cfg3rdPartyFactions. Walks each
// registry subclass whose cfgPatchesName is loaded, collects any per-
// faction overrides (displayName / sourceLabel / excluded) into a
// hashmap keyed by lowercase faction classname. Empty/no-overrides
// registry is fine - the auto-detection paths below run unmodified.
// ------------------------------------------------------------------------
private _registryOverrides = createHashMap;
private _registry = configFile >> "Cfg3rdPartyFactions";
if (isClass _registry) then {
    for "_i" from 0 to (count _registry - 1) do {
        private _entry = _registry select _i;
        if (isClass _entry) then {
            private _cp = getText (_entry >> "cfgPatchesName");
            if (_cp != "" && {isClass (configFile >> "CfgPatches" >> _cp)}) then {
                private _factionsClass = _entry >> "factions";
                if (isClass _factionsClass) then {
                    for "_j" from 0 to (count _factionsClass - 1) do {
                        private _facOverride = _factionsClass select _j;
                        if (isClass _facOverride) then {
                            private _facCN = configName _facOverride;
                            private _override = createHashMap;
                            if (isText (_facOverride >> "displayName")) then {
                                _override set ["displayName", getText (_facOverride >> "displayName")];
                            };
                            if (isText (_facOverride >> "sourceLabel")) then {
                                _override set ["sourceLabel", getText (_facOverride >> "sourceLabel")];
                            };
                            if (isNumber (_facOverride >> "excluded")) then {
                                _override set ["excluded", getNumber (_facOverride >> "excluded") > 0];
                            };
                            _registryOverrides set [toLower _facCN, _override];
                        };
                    };
                };
            };
        };
    };
};

private _seen = createHashMap; // lowercase classname -> true, for dedup
private _entries = [];
private _totalScanned = 0;
private _droppedBadSide = 0;
private _droppedNoGroups = 0;
private _droppedRegistryExcluded = 0;

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
                    // Source addon: which PBO contributed this faction's
                    // ALiVE-relevant content. For military sides this is the
                    // CfgGroups owner; for civilians, the CfgFactionClasses
                    // owner (CfgGroups is empty for vanilla civilians, so
                    // we fall back to the faction class's source addon).
                    // Used as a suffix on the dropdown label so mission-
                    // makers can see "OPFOR - RHS MSV (rhsafrf)" rather
                    // than guessing which mod the faction came from.
                    private _sourceAddon = "";

                    private _usable = if (_side == 3) then {
                        // Civilian: always include UNLESS blacklisted as a
                        // known internal / non-real civilian-side faction
                        // (see _civilianBlacklist above).
                        if (!((toLower _cn) in _civilianBlacklist)) then {
                            private _facSources = configSourceAddonList _fac;
                            if (count _facSources > 0) then {
                                _sourceAddon = _facSources select 0;
                            };
                            true
                        } else {
                            false
                        };
                    } else {
                        private _sideName = _sideCfgGroupsName select _side;
                        private _groupsEntry = configFile >> "CfgGroups" >> _sideName >> _cn;
                        if (isClass _groupsEntry && {count _groupsEntry > 0}) then {
                            private _grpSources = configSourceAddonList _groupsEntry;
                            if (count _grpSources > 0) then {
                                _sourceAddon = _grpSources select 0;
                            };
                            true
                        } else {
                            false
                        };
                    };
                    if (_usable) then {
                        // Consult Cfg3rdPartyFactions registry for per-
                        // faction overrides (excluded / displayName /
                        // sourceLabel). Empty hashmap if no override.
                        private _override = _registryOverrides getOrDefault [_cnLower, createHashMap];

                        if (_override getOrDefault ["excluded", false]) then {
                            _droppedRegistryExcluded = _droppedRegistryExcluded + 1;
                        } else {
                            // displayName: registry override > config > classname
                            private _dn = _override getOrDefault ["displayName", ""];
                            if (_dn isEqualTo "") then {
                                _dn = getText (_fac >> "displayName");
                                if (_dn isEqualTo "") then { _dn = _cn };
                            };
                            // sourceLabel: registry override > auto-detected addon
                            private _srcOverride = _override getOrDefault ["sourceLabel", ""];
                            if (_srcOverride != "") then {
                                _sourceAddon = _srcOverride;
                            };
                            _entries pushBack [_cn, _dn, _side, _sourceAddon];
                        };
                    } else {
                        _droppedNoGroups = _droppedNoGroups + 1;
                    };
                };
            };
        };
    };
} forEach _configPaths;

// ------------------------------------------------------------------------
// 4. Pre-check stored value against the in-memory entries list.
//    If the stored value doesn't match any entry, the "(unrecognised)
//    <value>" placeholder is added FIRST so it sits at the TOP of the
//    dropdown. Better UX than tucking unknown values at the end of a
//    long alphabetical list - mission-makers immediately see that their
//    stored faction isn't in the current loadout.
// ------------------------------------------------------------------------
private _valueLower = toLower _value;
private _hasMatch = (_entries findIf {
    _x params ["_cn"];
    (toLower _cn) == _valueLower
}) >= 0;

private _foundIdx = -1;

if (!_hasMatch && _value != "") then {
    private _idx = _ctrl lbAdd format ["(unrecognised) %1", _value];
    _ctrl lbSetData [_idx, _value];
    _foundIdx = _idx;  // top entry is the unrecognised one
};

// ------------------------------------------------------------------------
// 5. Populate combo grouped by side.
//    Order: OPFOR, BLUFOR, INDFOR, CIVILIAN. Within each bucket, entries
//    sorted alphabetically by classname for deterministic ordering.
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
    _bucketEntries sort true; // by classname ascending

    {
        _x params ["_cn", "_dn", "", "_sourceAddon"];
        // Suffix the label with the source addon so mission-makers can
        // see where the faction's CfgGroups (or CfgFactionClasses for
        // civilians) was contributed from. Helps diagnose missing CDLC
        // compat PBOs ("RHS - GREF (rhsgref)" vs "RHS - GREF (no source)"
        // would tell the user composition_rhs_gref didn't load).
        private _label = if (_sourceAddon == "") then {
            format ["%1 - %2", _sideLabel, _dn]
        } else {
            format ["%1 - %2 (%3)", _sideLabel, _dn, _sourceAddon]
        };
        private _idx = _ctrl lbAdd _label;
        _ctrl lbSetData [_idx, _cn];
        // If this is the matching entry, remember the index for selection.
        if (_foundIdx == -1 && (toLower _cn) == _valueLower) then {
            _foundIdx = _idx;
        };
    } forEach _bucketEntries;
} forEach _sideBuckets;

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
    "ALIVE FactionChoice LOAD: scanned=%1 dropped(bad side)=%2 dropped(no CfgGroups)=%3 dropped(registry excluded)=%4 populated=%5 stored='%6' selected=%7 (lbData='%8')",
    _totalScanned,
    _droppedBadSide,
    _droppedNoGroups,
    _droppedRegistryExcluded,
    count _entries,
    _value,
    _foundIdx,
    if (_foundIdx >= 0 && _foundIdx < lbSize _ctrl) then { _ctrl lbData _foundIdx } else { "(none)" }
];
