#include "\x\alive\addons\mil_IED\script_component.hpp"

SCRIPT(createIED);

#define SUPERCLASS ALIVE_fnc_baseClass
#define MAINCLASS ALIVE_fnc_ied
#define DEFAULT_IED_THREAT 60
#define DEFAULT_IED_CHARGE "ALIVE_IEDUrbanSmall_Remote_Ammo"

// IED - create IED(s) at location
private ["_position","_town","_debug","_numIEDs","_j","_size","_posloc","_IEDs","_threat","_IEDData","_IEDcount", "_dud"];

if !(isServer) exitWith {diag_log "IED Not running on server!";};

TRACE_1("IED",_this);

_debug = ADDON getVariable ["debug", false];
_threat = ADDON getVariable ["IED_Threat", DEFAULT_IED_THREAT];
// Resolved at module init by ALIVE_fnc_detectIEDIntegrations + the Auto/Force
// rules: "alive" = full ALiVE pipeline (arm + proximity + disarm), "mine" = Arma
// mineActive semantics (skip ALiVE arming, let the 3rd-party mod detonate).
private _integrationMode = ADDON getVariable ["resolvedIntegrationMode", "alive"];
private _thirdParty = (_integrationMode == "mine");

if (_thirdParty && _debug) then {
    ["MIL IED: Using mine-semantics (3rd-party integration)"] call ALiVE_fnc_dump;
};

_position = _this select 0;
_size = _this select 1;

if ((count _this) > 2) then {
    _town = _this select 2;
};

if ((count _this) > 3) then {
    _numIEDs = _this select 3;
} else {
    // IMPROVED: Reduced spawn formula - divisor changed from 50 to 150 for 67% reduction
    _numIEDs = round ((_size / 150) * ( _threat / 100));
    // Ensure minimum of 1 IED if threat > 0
    if (_numIEDs < 1 && _threat > 0) then {_numIEDs = 1;};
};

// Get IEDs from store if available
_IEDs = [[GVAR(STORE), "IEDs"] call ALiVE_fnc_hashGet, _town, [] call ALiVE_fnc_hashCreate] call ALiVE_fnc_hashGet;
_IEDcount = count (_IEDs select 1);

// IF first time creating IEDs for location go work out how many IEDs
if (_IEDcount == 0) then {
    diag_log format ["ALIVE-%1 IED: creating %2 IEDs at %5 (%3) - size %4", time, _numIEDs, mapgridposition  _position, _size, _town];

    // Find positions in area
    _posloc = [];
    _posloc = [_position, true, true, true, _size] call ALIVE_fnc_placeIED;
    if (_debug) then {
        diag_log format ["ALIVE-%1 IED: Found %2 spots for IEDs",time, count _posloc];
    };

    // Clamp numIEDs to available positions.
    // Use (count _posloc) not (count _posloc) - 1 to avoid going negative.
    // If posloc is empty the for-loop handles it naturally since 1 to 0 never executes.
    if (_numIEDs > (count _posloc)) then {
        _numIEDs = count _posloc;
    };

    // Bail out early with a clear debug message if there are no valid positions
    if (_numIEDs == 0) exitWith {
        diag_log format ["ALIVE-%1 IED: No valid positions found for IEDs at %2 - skipping", time, _town];
    };

    _IEDData = [] call ALiVE_fnc_hashCreate;

} else {
    _numIEDs = _IEDcount;
};

for "_j" from 1 to _numIEDs do {
    private ["_IEDpos","_pos","_cen","_near","_IED","_IEDskin","_data","_ID","_error","_IEDskins"];

    // Select Position for IED and remove position used
    _error = false;

    If (_IEDcount == 0) then {
        _index = round (random ((count _posloc) -1));
        _pos = _posloc select _index;
        _posloc set [_index, -1];
        _posloc = _posloc - [-1];

        // Use validated position directly - our placement validation already handled terrain/obstacles
        _IEDpos = _pos;

        private ["_IEDskins","_near","_choice","_allIEDClasses"];

        // Check no other IEDs nearby - IMPROVED: increased from 3m to 12m for better spacing
        // IMPORTANT: use only the actual ALIVE IED model classes here, NOT urbanIEDClasses.
        // urbanIEDClasses includes clutter objects (Land_Sacks_heap_F etc.) which are also
        // placed as camouflage by earlier iterations - using the full list causes false positives
        // where the proximity check finds its own clutter and skips the IED placement.
        private _realIEDClasses = ["ALIVE_IEDUrbanSmall_Remote_Ammo","ALIVE_IEDLandSmall_Remote_Ammo","ALIVE_IEDUrbanBig_Remote_Ammo","ALIVE_IEDLandBig_Remote_Ammo","ALIVE_DemoCharge_Remote_Ammo","ALIVE_SatchelCharge_Remote_Ammo"];
        _near = nearestObjects [_IEDpos, _realIEDClasses, 12];

        // Exit THIS ITERATION if other IEDs are found or position is on water
        if (count _near > 0) then {
            diag_log format ["ALIVE-%1 IED: skipping - other IEDs found %2",time,_near]; 
            _error = true;
        };
        if (surfaceIsWater _IEDpos) then {
            diag_log format ["ALIVE-%1 IED: skipping - pos was on water.",time]; 
            _error = true;
        };

        // Check not placed near a player
        // Skip THIS ITERATION if position is too close to a player
        if ({(getpos _x distance _IEDpos) < 75} count ([] call BIS_fnc_listPlayers) > 0) then {
            diag_log format ["ALIVE-%1 IED: skipping - placement too close to player.",time]; 
            _error = true;
        };

        // If error occurred, skip IED creation for this iteration
        if (!_error) then {
        private _isRoadContext = false;

        if (isOnRoad _IEDpos) then {
            _IEDskins = ADDON getVariable ["resolvedRoadIEDClasses", [ADDON, "roadIEDClasses"] call MAINCLASS];
            _isRoadContext = true;
        } else {
            // Check to see proximity to houses (use "House" base class to catch all map building types)
            if (count (_IEDpos nearObjects ["House", 40]) > 0) then {
                _IEDskins = ADDON getVariable ["resolvedUrbanIEDClasses", [ADDON, "urbanIEDClasses"] call MAINCLASS];

                // Add clutter nearby so its not so obvious that there is an IED
                private ["_clutter","_c","_clut","_clutm","_t"];
                _clutter = ADDON getVariable ["resolvedClutterClasses", [ADDON, "clutterClasses"] call MAINCLASS];
                for "_c" from 1 to (2 + (ceil(random 6))) do {

                    //Seems to cause a crash lateley if _clutter is empty (trigger-related?)
                    //Fixme: @Tup: why is clutter clutterClasses empty?
                    if (count _clutter > 0) then {
                        _clut = createVehicle [(selectRandom _clutter),_IEDpos, [], 40, "NONE"];
                        _clut setvariable [QUOTE(ADDON), true];

                        //Fixme: what happens if clut is nil or null
                        while {isOnRoad _clut} do {
                            _clut setPos [((position _clut) select 0) - 10 + random 20, ((position _clut) select 1) - 10 + random 20, ((position _clut) select 2)];
                        };
                    };

                    /* if (_debug) then {
                        diag_log format ["ALIVE-%1 IED: Planting clutter (%2) at %3.", time, typeOf _clut, position _clut];
                        //Mark clutter position
                        _t = format["cl_r%1", floor (random 1000)];
                        _clutm = [_t, position _clut, "Icon", [1,1], "TEXT:", "", "TYPE:", "mil_dot", "COLOR:", "ColorGreen", "GLOBAL"] call CBA_fnc_createMarker;
                        _clut setvariable ["Marker", _clutm];
                    };*/
                };
            } else {
                _IEDskins = ADDON getVariable ["resolvedRoadIEDClasses", [ADDON, "roadIEDClasses"] call MAINCLASS];
                _isRoadContext = true;
            };
        };

        // Road IED clutter - sparse (1-3 pieces) and placed tight to the IED
        // to break up its silhouette against open verge. Urban IEDs already
        // get dense clutter above; rural road IEDs previously had none, which
        // left a bare model visible against cleared shoulder terrain.
        if (_isRoadContext) then {
            private ["_clutter","_roadC","_roadClut"];
            _clutter = ADDON getVariable ["resolvedClutterClasses", [ADDON, "clutterClasses"] call MAINCLASS];
            for "_roadC" from 1 to (1 + (ceil (random 2))) do {
                if (count _clutter > 0) then {
                    _roadClut = createVehicle [(selectRandom _clutter), _IEDpos, [], 8, "NONE"];
                    _roadClut setvariable [QUOTE(ADDON), true];

                    // Nudge off tarmac if it landed on a road. Bounded retry
                    // so we don't infinite-loop on wide intersections.
                    private _retry = 0;
                    while {isOnRoad _roadClut && _retry < 8} do {
                        _roadClut setPos [
                            ((position _roadClut) select 0) - 6 + random 12,
                            ((position _roadClut) select 1) - 6 + random 12,
                            ((position _roadClut) select 2)
                        ];
                        _retry = _retry + 1;
                    };
                };
            };
        };

        if !(_thirdParty) then {
            _IEDpos set [2, -0.1];
        };
        _IEDskin = (selectRandom _IEDskins);
        _IED = createVehicle [_IEDskin, _IEDpos, [], 0, "NONE"];

        _ID = format ["%1-%2", _town, _j];
        if (random 1 < 0.95) then {_dud = false} else {_dud = true};

        _data = [] call ALiVE_fnc_hashCreate;
        [_data, "IEDskin", _IEDskin] call ALiVE_fnc_hashSet;
        [_data, "IEDpos", getposATL _IED] call ALiVE_fnc_hashSet;
        [_data, "IEDtype", "IED"] call ALiVE_fnc_hashSet;
        [_data, "IEDDud", _dud] call ALiVE_fnc_hashSet;
        [_IEDData, _ID, _data] call ALiVE_fnc_hashSet;

        }; // End of if (!_error) block - only create IED if no errors

    } else {
        private ["_data"];
        _ID = (_IEDs select 1) select (_j-1);
        _data = [_IEDs, _ID] call ALiVE_fnc_hashGet;
        _dud = [_data, "IEDDud"] call ALiVE_fnc_hashGet;
        _IED = createVehicle [[_data, "IEDskin", "ALIVE_IEDUrbanSmall_Remote_Ammo"] call ALiVE_fnc_hashGet, [_data, "IEDpos",[0,0,0]] call ALiVE_fnc_hashGet, [], 0, "NONE"];
        if (_thirdParty) then {
            _IED setpos [(position _IED) select 0, (position _IED) select 1, 0.15];
        };
    };

    // Only proceed with IED setup if no error occurred and IED was created
    if (!_error) then {
        _IED setvariable ["ID", _ID];
    _IED setvariable ["town", _town];

    // Check if Dud IED
    if (!_dud && !_thirdParty) then {
        [_IED, typeOf _IED] call ALIVE_fnc_armIED;

        // Attach something that can take a hit to the IED and add a damage handler
        _IEDCharge = createVehicle ["ALIVE_DemoCharge_Remote_Ammo",getposATL _IED, [], 0, "CAN_COLLIDE"];
        _IEDCharge attachTo [_IED, [0,0,0]];

        // Add damage handler
        _ehID = _IEDCharge addeventhandler ["HandleDamage",{

            private _charge = _this select 0;
            private _killer = _this select 3;
            private _IED = attachedTo _charge;
            private _pos = getpos _charge;

            //diag_log str(_this);
            if (isPlayer _killer) then { // GO BOOOOOOOOOOM AND AWARD PLAYER

                if (ADDON getVariable "debug") then {
                    diag_log format ["ALIVE-%1 IED: %2 explodes due to damage by %3", time, _IED, _killer];
                    [_IED getvariable "Marker"] call cba_fnc_deleteEntity;
                };

				// Update Sector Hostility
    			[position _IED, [str(side (group _killer))], +10] call ALiVE_fnc_updateSectorHostility;

                //set pos to 0 height and give it an extra shot
                _pos set [2,0];
                "M_Mo_120mm_AT" createVehicle _pos;
            };

            // Remove from store if damaged
            [ADDON, "removeIED", _IED] call ALiVE_fnc_IED;

            // Delete IED, charge, and ALL proximity/detection triggers to prevent double-detonation
            // (armIED also creates triggers; deleting here stops them firing after EH detonation)
            detach _ied;
            deleteVehicle _IED;
            deletevehicle _charge;

            // Including all triggers around
            private _trgr = _pos nearObjects ["EmptyDetector", 3];
            {
                deleteVehicle _x;
            } foreach _trgr;
        }];

        _IED setVariable ["ehID",_ehID, true];
        _IED setvariable ["charge", _IEDCharge, true];
    };

    if (_thirdParty) then {

        // ["MIL IED: Adding EH to 3rd party IEDs : %1 - %2", typeOf _IED, _IED] call ALiVE_fnc_dump;

    };

    if (_debug) then {
        private ["_t","_markers","_text","_iedm"];

        //Mark IED position
        _t = format["ied_r%1", floor (random 1000)];
        _text = "IED";

        _iedm = [_t, position _IED, "Icon", [0.5,0.5], "TEXT:", _text, "TYPE:", "mil_dot", "COLOR:", "ColorRed", "GLOBAL"] call CBA_fnc_createMarker;
        _IED setvariable ["Marker", _iedm];

        _markers = ADDON getVariable ["debugMarkers",[]];
        _markers pushback _iedm;
        ADDON setVariable ["debugMarkers",_markers];

    };
    }; // End of if (!_error) - only set up IED if it was successfully created
};

// Set data
if (_IEDcount == 0) then {
    [[GVAR(STORE), "IEDs"] call ALiVE_fnc_hashGet, _town, _IEDData] call ALiVE_fnc_hashSet;
};
