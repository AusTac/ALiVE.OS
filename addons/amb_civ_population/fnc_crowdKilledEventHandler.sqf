#include "\x\alive\addons\amb_civ_population\script_component.hpp"
SCRIPT(crowdKilledEventHandler);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_crowdKilledEventHandler

Description:
Killed event handler for crowd units

Parameters:

Returns:

Examples:
(begin example)
_eventID = _unit addEventHandler["Killed", ALIVE_fnc_crowdKilledEventHandler];
(end)

See Also:

Author:
ARJay
---------------------------------------------------------------------------- */

params ["_unit","_killer"];

// Set the crowd system to stop spawning due to combat in the area
private _crowdActivatorFSM = [ALIVE_civilianPopulationSystem, "crowd_FSM"] call ALiVE_fnc_HashGet;
_crowdActivatorFSM setFSMVariable ["_noCombat",(time + 60)];

[_unit,""] call ALIVE_fnc_switchMove;

private _killerSide = str(side (group _killer));

// Hostility will increase towards killer's faction

// log event and update hostility
// Issue #14: original code had blocks swapped — the else branch called
// position _unit when _unit was nil, causing a guaranteed crash.
// Hostility update and event log both belong in the not-nil branch.
if !(isNil "_unit") then {
	private _position = getPosASL _unit;
	private _faction = faction _unit;
	private _side = side group _unit;

	[position _unit,[_killerSide], +10] call ALiVE_fnc_updateSectorHostility;

	private _event = ['AGENT_KILLED', [_position,_faction,_side,_killerSide],"Agent"] call ALIVE_fnc_event;
	private _eventID = [ALIVE_eventLog, "addEvent",_event] call ALIVE_fnc_eventLog;
};

// Make any crowds nearby flee
if !(isNil "_unit") then {
	private _nearCivs = [position _unit, 100, civilian] call ALIVE_fnc_getSideManNear;
	{
		private _isCrowdCiv = (_x getVariable ["ALIVE_CIV_ACTION",false]) isEqualType "";
		if (_isCrowdCiv) then {
			[_x, _killer, 50] call ALiVE_fnc_crowdFiredNearEventHandler;
		};
	} foreach _nearCivs;
};

// Issue #16: prune dead agent from FSM _activeAgents immediately.
// Without this, dead agents remain in the array until the next out-of-range
// despawn cycle, causing the array to grow unbounded in sustained combat.
if (isServer && {!isNil "_unit"}) then {
	private _crowdFSM = [ALIVE_civilianPopulationSystem, "crowd_FSM"] call ALiVE_fnc_HashGet;
	if (!isNil "_crowdFSM") then {
		private _agents = _crowdFSM getFSMVariable "_activeAgents";
		if (!isNil "_agents" && {_agents isEqualType []}) then {
			private _idx = _agents find _unit;
			if (_idx > -1) then {
				_agents set [_idx, -1];
				_crowdFSM setFSMVariable ["_activeAgents", _agents - [-1]];
			};
		};
	};
};