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
if (_sel < 0) exitWith { "_auto" };
_ctrl lbData _sel
