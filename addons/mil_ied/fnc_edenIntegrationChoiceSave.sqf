#include "\x\alive\addons\mil_ied\script_component.hpp"
SCRIPT(edenIntegrationChoiceSave);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_edenIntegrationChoiceSave

Description:
Eden-attribute `attributeSave` handler for ALiVE_IntegrationChoice.
Returns the currently-selected Combo item's lbData token, or "_auto" if
nothing is selected. The returned value becomes the attribute's stored
value on the logic.

Parameters:
    _this: DISPLAY - the Eden attribute's display. Combo control has IDC 100.

Returns:
    STRING - one of "_auto", "_force_alive", or a registry className.

Author:
Jman
---------------------------------------------------------------------------- */

private _ctrl = (_this controlsGroupCtrl 100);
private _sel = lbCurSel _ctrl;
private _result = if (_sel < 0) then {
    "_auto"
} else {
    _ctrl lbData _sel
};

// Eden's built-in Combo treats attribute values as numeric, so by default
// our string payload would be discarded. Three storage paths to make the
// choice survive: (1) push into Eden's "value" attribute slot on the
// control so SQM serialisation sees it, (2) setVariable directly on each
// edited logic so re-opening the attribute panel finds it immediately
// (attributeLoad reads from here), (3) the attribute's `expression` in
// CfgVehicles applies the SQM-stored value back onto the logic at mission
// start, landing on the same variable name.
_this setVariable ["value", _result];
{
    _x setVariable ["integrationChoice", _result, true];
} forEach (get3DENSelected "logic");

_result
