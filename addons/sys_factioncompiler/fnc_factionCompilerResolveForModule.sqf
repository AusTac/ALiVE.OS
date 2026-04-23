#include "\x\alive\addons\sys_factioncompiler\script_component.hpp"
SCRIPT(factionCompilerResolveForModule);

params [
    ["_logic", objNull, [objNull]]
];

if (isNull _logic) exitWith {""};

private _result = "";

{
    if ((typeOf _x) isEqualTo "ALiVE_sys_factioncompiler") exitWith {
        private _compiledFaction = _x getVariable ["compiledFactionId", ""];
        if (_compiledFaction isEqualTo "") then {
            _compiledFaction = _x getVariable ["factionId", ""];
        };

        if ([_compiledFaction] call ALIVE_fnc_factionCompilerIsCompiledFaction) then {
            _result = _compiledFaction;
        };
    };
} forEach (synchronizedObjects _logic);

_result

