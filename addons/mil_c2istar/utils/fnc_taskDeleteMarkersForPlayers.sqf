#include "\x\alive\addons\mil_C2ISTAR\script_component.hpp"
SCRIPT(taskDeleteMarkersForPlayers);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_taskDeleteMarkersForPlayers

Description:
Mark a position for players

Parameters:

Returns:

Examples:
(begin example)
(end)

See Also:

Author:
ARJay
---------------------------------------------------------------------------- */

private ["_taskPosition","_taskSide","_taskType","_colour","_markerDefinition","_player"];

params [
    ["_taskPlayers", []],
    ["_taskID", "", [""]]
];

{
    _player = [_x] call ALIVE_fnc_getPlayerByUID;

    if !(isNull _player) then {
        if(isDedicated) then {
            [[_taskID],"ALIVE_fnc_taskDeleteMarkers",_player,false,false] spawn BIS_fnc_MP;
        }else{
            [_taskID] call ALIVE_fnc_taskDeleteMarkers;
        };
    };

} forEach _taskPlayers;