#include "\x\alive\addons\main\script_component.hpp"
SCRIPT(edenFactionChoiceSave);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_edenFactionChoiceSave

Description:
Eden-attribute `attributeSave` handler for the shared ALiVE_FactionChoice
control. Returns the currently-selected entry's lbData (the faction
classname), falling back to the default "OPF_F" if nothing is selected.

Three storage paths to make the string value survive Eden's numeric-leaning
Combo serialisation:
  1. Push into Eden's "value" attribute slot on the control so SQM
     serialisation sees it.
  2. setVariable directly on each edited logic under the variable name
     "faction" so the attributeLoad handler finds it on re-open.
  3. The attribute's `expression` in CfgVehicles applies the SQM-stored
     value back onto the logic at mission start (landing on the same
     variable name "faction").

Shared across mil_placement, civ_placement, civ_placement_custom, and any
future ALiVE module with a `faction` attribute.

Parameters:
    _this: DISPLAY - the Eden attribute's display. Combo control has IDC 100.

Returns:
    STRING - the selected faction classname (e.g. "OPF_F", "rhs_faction_msv").
             For "(unrecognised)" entries, the original stored string is
             preserved in lbData and returned unchanged.

Author:
Jman
---------------------------------------------------------------------------- */

private _ctrl = (_this controlsGroupCtrl 100);
private _sel = lbCurSel _ctrl;
private _result = if (_sel < 0) then {
    "OPF_F"
} else {
    _ctrl lbData _sel
};

// Defensive: if lbData was somehow empty, don't silently write "" to the logic
if (typeName _result != "STRING" || {_result == ""}) then {
    _result = "OPF_F";
};

// Path 1: Eden "value" slot - for SQM serialisation
_this setVariable ["value", _result];

// Path 2: logic variable - for attributeLoad to find on re-open
{
    _x setVariable ["faction", _result, true];
} forEach (get3DENSelected "logic");

// Path 3 (mission start re-apply) is handled by the attribute's `expression`
// declared in each consuming module's CfgVehicles.hpp.

_result
