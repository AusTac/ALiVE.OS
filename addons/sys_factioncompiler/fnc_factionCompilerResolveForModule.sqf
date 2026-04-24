#include "\x\alive\addons\sys_factioncompiler\script_component.hpp"
SCRIPT(factionCompilerResolveForModule);

params [
    ["_logic", objNull, [objNull]]
];

if (isNull _logic) exitWith {""};

private _result = "";

{
    if (_result isEqualTo "" && {(typeOf _x) isEqualTo "ALiVE_sys_factioncompiler"}) then {
        private _compiledFaction = _x getVariable ["compiledFactionId", ""];
        private _compilerError = _x getVariable ["compiledFactionError", ""];

        if (_compiledFaction isEqualTo "" && {_compilerError isEqualTo ""}) then {
            _compiledFaction = _x getVariable ["factionId", ""];
        };

        if !(_compiledFaction isEqualTo "") then {
            if ([_compiledFaction] call ALIVE_fnc_factionCompilerIsCompiledFaction) then {
                _result = _compiledFaction;
            };
        };
    };
} forEach (synchronizedObjects _logic);

_result

