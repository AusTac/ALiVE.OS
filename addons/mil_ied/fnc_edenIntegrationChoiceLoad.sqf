#include "\x\alive\addons\mil_ied\script_component.hpp"
SCRIPT(edenIntegrationChoiceLoad);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_edenIntegrationChoiceLoad

Description:
Eden-attribute `attributeLoad` handler for the custom ALiVE_IntegrationChoice
control. Populates the Combo list with the two meta-choices plus one
"Defer to: <displayName>" entry per Cfg3rdPartyIEDs registry subclass whose
cfgPatchesName addon is currently loaded. Sets the selection to match the
attribute's stored value, defaulting to "_auto".

Lives in its own .sqf file because Arma's config preprocessor struggles with
multi-line `"..."` strings containing backslash-newline continuations on
Windows CRLF files.

Parameters:
    _this: DISPLAY - the Eden attribute's display. Combo control has IDC 100.

Author:
Jman
---------------------------------------------------------------------------- */

private _ctrl = (_this controlsGroupCtrl 100);
lbClear _ctrl;

// Two always-present meta-choices.
private _specials = [
    ["_auto",        "Auto (detect)"],
    ["_force_alive", "Force ALiVE handling"]
];
{
    _x params ["_data", "_label"];
    private _idx = _ctrl lbAdd _label;
    _ctrl lbSetData [_idx, _data];
} forEach _specials;

// One entry per loaded registry integration (vanilla baseline hidden).
private _registry = configFile >> "Cfg3rdPartyIEDs";
if (isClass _registry) then {
    for "_i" from 0 to (count _registry - 1) do {
        private _entry = _registry select _i;
        if (isClass _entry) then {
            private _cn = configName _entry;
            private _cp = getText (_entry >> "cfgPatchesName");
            if (_cn != "ALiVE_Vanilla_A3" && _cp != "" && {isClass (configFile >> "CfgPatches" >> _cp)}) then {
                private _dn = getText (_entry >> "displayName");
                private _idx = _ctrl lbAdd format ["Defer to: %1", _dn];
                _ctrl lbSetData [_idx, _cn];
            };
        };
    };
};

// Restore selection from stored value; fall back to "_auto" for nil/bad.
private _value = _this getVariable "value";
if (isNil "_value" || {typeName _value != "STRING" || {_value == ""}}) then {
    _value = "_auto";
};

private _selIdx = 0;
for "_i" from 0 to (lbSize _ctrl - 1) do {
    if ((_ctrl lbData _i) == _value) exitWith { _selIdx = _i; };
};
_ctrl lbSetCurSel _selIdx;
