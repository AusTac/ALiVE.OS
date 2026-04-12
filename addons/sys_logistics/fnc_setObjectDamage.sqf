#include "\x\alive\addons\sys_logistics\script_component.hpp"
SCRIPT(setObjectDamage);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_setObjectDamage
Description:

Set damage of given object

Parameters:
_this: ARRAY of OBJECTs

Returns:
SCALAR - Damage

See Also:
- <ALIVE_fnc_setObjectCargo>

Author:
Highhead

Peer Reviewed:
nil
---------------------------------------------------------------------------- */

private ["_object","_damage"];

_object = _this param [0, objNull, [objNull]];
_damage = _this param [1, -1, [-1]];

if (isNull _object) exitwith {};

_object setDamage _damage;
_damage;