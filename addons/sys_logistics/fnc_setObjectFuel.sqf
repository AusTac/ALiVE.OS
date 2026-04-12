#include "\x\alive\addons\sys_logistics\script_component.hpp"
SCRIPT(getObjectFuel);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_getObjectFuel
Description:

Gets fuel state of the given object.

Parameters:
_this: ARRAY of OBJECTs

Returns:
NUMBER - Fuel

See Also:
- <ALIVE_fnc_setObjectCargo>

Author:
Highhead

Peer Reviewed:
nil
---------------------------------------------------------------------------- */

private ["_object","_fuel"];

_object = _this param [0, objNull, [objNull]];
_fuel = _this param [1, -1, [-1]];

if (isNull _object) exitwith {};

_object setFuel _fuel;
_fuel;