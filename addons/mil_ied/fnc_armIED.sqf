#include "\x\alive\addons\mil_IED\script_component.hpp"
SCRIPT(armIED);

#define SUPERCLASS ALIVE_fnc_baseClass
#define MAINCLASS ALIVE_fnc_ied

// Create trigger for IED detonation
private ["_IED","_trg","_type","_shell","_proximity","_debug"];

if !(isServer) exitWith {diag_log "ArmIED Not running on server!";};

_debug = ADDON getVariable ["debug", false];
_detection = ADDON getVariable ["IED_Detection", 1];
_device = ADDON getVariable ["IED_Detection_Device", "MineDetector"];

// Build trigger condition strings based on AI_Triggerable setting.
// Two separate conditions are needed:
//
// _condSpawn  - used by the large area spawn trigger (IED/bomber creation)
//               needs a count over units to determine if anyone is present
//
// _condDetonate - used by the small proximity detonation trigger on each IED
//                 player mode: original per-unit EOD/detector check
//                 AI mode: any alive unit at ground level in trigger area
//
private _aiTriggerable = ADDON getVariable ["aiTriggerable", false];

private _condDetonate = if (_aiTriggerable) then {
    // AI + players: any alive unit at ground level detonates the IED.
    // No EOD/detector check - that is a player-only concept.
    // vehicle _x handles the case where _x is already the vehicle (tank etc.)
    format["({alive (vehicle _x) && ((getposATL (vehicle _x)) select 2 < 8)} count thislist > 0)"]
} else {
    // Players only: _x in thisList checks the person object (vehicle _x is never in thisList
    // for EmptyDetector triggers - it would always evaluate false for players in vehicles).
    // getposATL (vehicle _x) gives the vehicle hull height for the altitude check.
    format["({_x in thisList && ((getposATL (vehicle _x)) select 2 < 8) && !('%1' in (items _x)) && (getText (configFile >> 'cfgVehicles' >> typeof _x >> 'displayName') != 'Explosive Specialist') && ([vehicleVarName _x,'EOD'] call CBA_fnc_find == -1)} count ([] call BIS_fnc_listPlayers) > 0)", _device]
};

private _condDetect = if (_aiTriggerable) then {
    // AI + players with detector get the detection notification
    format["({_x in thisList && ((getposATL (vehicle _x)) select 2 < 8) && (('%1' in (items _x)) || (getText (configFile >> 'cfgVehicles' >> typeof _x >> 'displayName') == 'Explosive Specialist') || ([vehicleVarName _x,'EOD'] call CBA_fnc_find != -1))} count thislist > 0)", _device]
} else {
    format["({_x in thisList && ((getposATL (vehicle _x)) select 2 < 8) && (('%1' in (items _x)) || (getText (configFile >> 'cfgVehicles' >> typeof _x >> 'displayName') == 'Explosive Specialist') || ([vehicleVarName _x,'EOD'] call CBA_fnc_find != -1))} count ([] call BIS_fnc_listPlayers) > 0)", _device]
};

private _condDisarm = if (_aiTriggerable) then {
    // Any alive unit at ground level can set off pressure trigger
    "({alive (vehicle _x) && ((getposATL (vehicle _x)) select 2 < 8)} count thislist > 0)"
} else {
    // _x in thisList checks the person; getposATL (vehicle _x) checks hull height
    "({_x in thisList && ((getposATL (vehicle _x)) select 2 < 8)} count ([] call BIS_fnc_listPlayers) > 0)"
};

_IED = _this select 0;
_type = _this select 1;

if (count _this > 2) then {
    _shell = _this select 2;
} else {
    _shell = [["M_Mo_120mm_AT","M_Mo_120mm_AT_LG","M_Mo_82mm_AT_LG","R_60mm_HE","Bomb_04_F","Bomb_03_F"],[4,8,2,1,1,1]] call BIS_fnc_selectRandomWeighted;
};

_proximity = 2 + floor(random 10);

if (_debug) then {
    diag_log format ["ALIVE-%1 IED: arming IED at %2 of %3 as %4 with proximity of %5",time, getposATL _IED,_type,_shell,_proximity];
};

// Add Action to IED for disarmm
/*
if !(isDedicated) then {
    _IED addAction ["<t color='#ff0000'>Disarm IED</t>",ALiVE_fnc_disarmIED, "", 6, false, true,"", "_target distance _this < 3"];
} else {
    [_IED,"ALiVE_fnc_addActionIED", true, true, true] call BIS_fnc_MP;
};
*/

_IED remoteExec ["ALiVE_fnc_addActionIED", 0, true];

// Arm-time grace period: the triggers for this IED are created AFTER a delay.
// This prevents instant detonation when an IED is placed in an area where the
// player is already present at placement time (e.g. player spawning into a town
// while the IED placement batch is running).
//
// Critically: we do NOT create triggers now and switch their activation later.
// Switching EmptyDetector activation from NONE to ANY causes the engine to
// immediately evaluate the condition against whatever is currently in thislist,
// detonating any IED that has units present at the moment of the switch.
// Creating the triggers fresh after the grace period avoids this entirely.
//
// The spawn is non-blocking - does not stall the IED creation loop.
private _gracePeriod = 15;

[
    _IED,
    _type,
    _shell,
    _proximity,
    _condDetonate,
    _condDetect,
    _condDisarm,
    _gracePeriod
] spawn {
    params ["_ied", "_type", "_shell", "_proximity", "_condDetonate", "_condDetect", "_condDisarm", "_grace"];

    sleep _grace;

    // Bail if the IED was found and disarmed during the grace window
    if (isNull _ied || !alive _ied) exitWith {};

    // If a player is still within the detonation radius + a safety buffer when the
    // grace expires, wait until they have moved clear before creating the triggers.
    // AI units are intentionally excluded here - they are valid targets once armed.
    private _clearRadius = _proximity + 15;
    waitUntil {
        if (isNull _ied || !alive _ied) exitWith { true };
        sleep 0.5;
        ({(vehicle _x) distance _ied < _clearRadius} count ([] call BIS_fnc_listPlayers)) == 0
    };

    // Re-check after waitUntil in case IED was removed while waiting
    if (isNull _ied || !alive _ied) exitWith {};

    // -------------------------------------------------------------------------
    // Replace EmptyDetector triggers with a polling loop.
    // EmptyDetector with ANY/PRESENT fires synchronously on createTrigger if
    // units are already present — no grace period approach can prevent this.
    // The loop checks proximity every 0.5s and is immune to this engine behaviour.
    // -------------------------------------------------------------------------
    [_ied, _type, _shell, _proximity, _condDetonate, _condDetect, _condDisarm] spawn {
        params ["_ied", "_type", "_shell", "_proximity", "_condDetonate", "_condDetect", "_condDisarm"];

        private _aiTriggerable = ADDON getVariable ["aiTriggerable", false];
        private _device        = ADDON getVariable ["IED_Detection_Device", "MineDetector"];
        private _detection     = ADDON getVariable ["IED_Detection", 1];
        private _detectedOnce  = false;
        private _detonated     = false;

        while {!_detonated && !isNull _ied && alive _ied} do {
            sleep 0.5;

            if (isNull _ied || !alive _ied) then { _detonated = true; } else {

                // --- Detection hint (engineer / mine detector) ---
                private _detectList = _ied nearEntities ["Man", _proximity + 5];
                if (!_detectedOnce) then {
                    private _detectors = _detectList select {
                        alive _x &&
                        ((getposATL _x) select 2 < 8) &&
                        (
                            (_device in (items _x)) ||
                            (getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName") == "Explosive Specialist") ||
                            ([vehicleVarName _x, "EOD"] call CBA_fnc_find != -1)
                        ) &&
                        (if (_aiTriggerable) then { true } else { _x in ([] call BIS_fnc_listPlayers) })
                    };
                    if (count _detectors > 0) then {
                        [_ied, _detection, _detectors, _detection, _device] call ALiVE_fnc_detectIED;
                        _detectedOnce = true;
                    };
                };

                // --- Detonation check ---
                // Build candidate list: men and ground vehicles within proximity.
                private _detonateList = _ied nearEntities ["Man", _proximity];
                _detonateList append (_ied nearEntities ["LandVehicle", _proximity]);

                // Filter to alive units at ground level only.
                _detonateList = _detonateList select {
                    alive _x && ((getposATL (vehicle _x)) select 2 < 8)
                };

                private _shouldDetonate = false;

                if (_aiTriggerable) then {
                    // AI + players can detonate, BUT:
                    // - Players carrying a detector or with EOD role are exempt
                    //   (they get a detection hint instead, same as aiTriggerable=false).
                    // - Pure AI units (non-players) always detonate regardless.
                    private _players = [] call BIS_fnc_listPlayers;

                    private _detonatingUnits = _detonateList select { private _x2 = _x;
                        private _isPlayer = (_x2 in _players) || (vehicle _x2 in _players);
                        if (_isPlayer) then {
                            // Player: only detonates if no EOD/detector
                            !(_device in (items _x2)) &&
                            (getText (configFile >> "CfgVehicles" >> typeOf _x2 >> "displayName") != "Explosive Specialist") &&
                            ([vehicleVarName _x2, "EOD"] call CBA_fnc_find == -1)
                        } else {
                            // AI: always detonates
                            true
                        }
                    };
                    _shouldDetonate = count _detonatingUnits > 0;
                } else {
                    // Players only, no EOD/detector
                    private _nearPlayers = ([] call BIS_fnc_listPlayers) select {
                        (vehicle _x) distance _ied < _proximity &&
                        ((getposATL (vehicle _x)) select 2 < 8) &&
                        !(_device in (items _x)) &&
                        (getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName") != "Explosive Specialist") &&
                        ([vehicleVarName _x, "EOD"] call CBA_fnc_find == -1)
                    };
                    _shouldDetonate = count _nearPlayers > 0;
                };

                if (_shouldDetonate) then {
                    deletevehicle (_ied getVariable ["Detect_Trigger", objNull]);
                    deletevehicle (_ied getVariable ["Det_Trigger",    objNull]);
                    deletevehicle (_ied getVariable ["Trigger",        objNull]);
                    [ALiVE_mil_ied, "removeIED", _ied] call ALiVE_fnc_IED;
                    _shell createVehicle [(getpos _ied) select 0, (getpos _ied) select 1, 0];
                    deletevehicle _ied;
                    _detonated = true;
                };

            }; // end isNull check
        }; // end while
    };

    // Minimal stub triggers kept so that fnc_RemoveIED's nearObjects ["EmptyDetector",3]
    // still finds something to clean up. They have condition "false" so they never fire.
    private _trg = createTrigger ["EmptyDetector", getposATL _ied];
    _trg setTriggerArea [1, 1, 0, false];
    _trg setTriggerActivation ["NONE", "PRESENT", false];
    _trg setTriggerStatements ["false", "", ""];
    _ied setVariable ["Trigger", _trg];

    private _trgDetect = createTrigger ["EmptyDetector", getposATL _ied];
    _trgDetect setTriggerArea [1, 1, 0, false];
    _trgDetect setTriggerActivation ["NONE", "PRESENT", false];
    _trgDetect setTriggerStatements ["false", "", ""];
    _ied setVariable ["Detect_Trigger", _trgDetect];

    private _trgDisarm = createTrigger ["EmptyDetector", getposATL _ied];
    _trgDisarm setTriggerArea [1, 1, 0, false];
    _trgDisarm setTriggerActivation ["NONE", "PRESENT", false];
    _trgDisarm setTriggerStatements ["false", "", ""];
    _ied setVariable ["Det_Trigger", _trgDisarm];
};

// Note: the per-IED triggers are created asynchronously above after the grace period.
// The IED object itself exists immediately; only the trigger creation is deferred.
// Code below this point that previously created the three triggers inline has been
// moved into the spawned block above.
