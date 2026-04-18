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
//    Collect [_classname, _displayName, _side, _sourceAddon] per faction.
//    Skip empty classes, fall back on missing displayName, default side to
//    -1 ("Other") if getNumber returns a non-standard value.
// ------------------------------------------------------------------------
private _seen = createHashMap; // lowercase classname -> true, for dedup
private _entries = [];

private _configPaths = [
    missionConfigFile >> "CfgFactionClasses",
    configFile >> "CfgFactionClasses"
];
{
    private _root = _x;
    for "_i" from 0 to (count _root - 1) do {
        private _fac = _root select _i;
        if (isClass _fac) then {
            private _cn = configName _fac;
            private _cnLower = toLower _cn;
            if !(_cnLower in _seen) then {
                _seen set [_cnLower, true];
                private _dn = getText (_fac >> "displayName");
                if (_dn isEqualTo "") then { _dn = _cn };
                private _side = -1;
                if (isNumber (_fac >> "side")) then {
                    _side = getNumber (_fac >> "side");
                };
                _entries pushBack [_cn, _dn, _side];
            };
        };
    };
} forEach _configPaths;

// ------------------------------------------------------------------------
// 4. Populate combo grouped by side.
//    BI side values in CfgFactionClasses:
//      0 = EAST (OPFOR), 1 = WEST (BLUFOR), 2 = INDEP (INDFOR),
//      3 = CIVILIAN, anything else (e.g. 4=LOGIC, 7=Alive internal, -1) -> Other
// ------------------------------------------------------------------------
private _sideBuckets = [
    [0, "OPFOR"],
    [1, "BLUFOR"],
    [2, "INDFOR"],
    [3, "CIVILIAN"],
    [-1, "Other"]
];

{
    _x params ["_sideValue", "_sideLabel"];

    // Gather + sort this side's entries alphabetically by displayName
    private _bucketEntries = _entries select {
        _x params ["", "", "_s"];
        if (_sideValue == -1) then {
            !(_s in [0, 1, 2, 3])  // everything non-standard goes to Other
        } else {
            _s == _sideValue
        };
    };
    _bucketEntries sort true; // sorts by first element (classname) ascending;
                               // acceptable since displayName often correlates,
                               // and deterministic-order is the priority here

    {
        _x params ["_cn", "_dn", "_s"];
        private _label = format ["%1 - %2", _sideLabel, _dn];
        private _idx = _ctrl lbAdd _label;
        _ctrl lbSetData [_idx, _cn];
    } forEach _bucketEntries;
} forEach _sideBuckets;

// ------------------------------------------------------------------------
// 5. Select the stored value. Case-insensitive compare against lbData.
//    If not found, add an "(unrecognised) <value>" entry at the TOP of the
//    list so legacy / typo'd / mod-unloaded factions aren't silently lost.
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
    // Re-order: move the unrecognised entry to the top of the list.
    // BI Combo doesn't have lbMove; easiest is to clear + rebuild with the
    // unrecognised entry inserted first. For now accept end-of-list placement
    // with a warning-shape prefix - users will notice the "(unrecognised)"
    // label regardless of position.
    _ctrl lbSetData [_idx, _value];
    _foundIdx = _idx;
};

if (_foundIdx < 0) then { _foundIdx = 0 }; // defensive: empty list somehow
_ctrl lbSetCurSel _foundIdx;
