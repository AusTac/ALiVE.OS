// Disarm IED - ran on client only
#include "\x\alive\addons\mil_IED\script_component.hpp"
SCRIPT(disarmIED);

// Client-side disarm handler. Introduces a skill-scaled disarm time during
// which the IED remains vulnerable to the server-side trip accumulator (another
// engineer stepping in, or the disarmer themselves standing/sprinting mid-job).
// The "new device" wire-guess chance also scales with skill.
//
// Tunables (ADDON getVariable):
//   IED_Engineer_Disarm_BaseTime      - base disarm seconds at skill 1.0 (default 60)
//   IED_Engineer_Disarm_NewDeviceBase - baseline wire-guess threshold (default 0.75)
//                                       Effective trigger rate: ~10% at skill 1.0,
//                                       ~25% at skill 0, clamped into [0.70, 0.90].

private ["_debug","_IED","_caller","_id","_IEDCharge"];

if (isDedicated) exitWith {diag_log "disarmIED running on server!";};

_debug = ADDON getVariable ["debug", false];

_IED    = _this select 0;
_caller = _this select 1;
_id     = _this select 2;

_IEDCharge = _IED getVariable ["charge", nil];

// Everything below needs scheduled context (sleep / waitUntil). addAction
// callbacks are unscheduled, so spawn a fresh thread.
[_IED, _caller, _id, _IEDCharge] spawn {
    params ["_IED", "_caller", "_id", "_IEDCharge"];

    private _skill = _caller skillFinal "commanding";

    // Skill-scaled disarm time. Skill 1.0 -> baseTime, skill 0 -> 1.5x baseTime,
    // floored at 50% of baseTime for any hypothetical over-skilled unit.
    private _baseTime   = ADDON getVariable ["IED_Engineer_Disarm_BaseTime", 60];
    private _disarmTime = ((_baseTime * (1.5 - 0.5 * _skill)) max (_baseTime * 0.5));

    hint format ["Disarming IED… (~%1s)", round _disarmTime];

    // Interruptible wait. If the server-side accumulator detonates the IED
    // during disarm, our reference goes null and we bail.
    private _elapsed = 0;
    while {_elapsed < _disarmTime} do {
        sleep 1;
        if (isNull _IED || !alive _IED) exitWith {};
        _elapsed = _elapsed + 1;
    };

    if (isNull _IED || !alive _IED) exitWith {
        hint "";
    };

    // Skill-scaled new-device chance.
    private _newDeviceBase      = ADDON getVariable ["IED_Engineer_Disarm_NewDeviceBase", 0.75];
    private _newDeviceThreshold = ((_newDeviceBase + 0.15 * _skill) min 0.90) max 0.70;

    if ((random 1) > _newDeviceThreshold) then {

        // "New device" - guess red or blue wire. 50/50 coin flip.
        private _wire = if ((random 1) > 0.5) then { "blue" } else { "red" };
        tup_ied_wire = "";

        private _tup_iedPrompt = createDialog "tup_ied_DisarmPrompt";
        noesckey = (findDisplay 1600) displayAddEventHandler ["KeyDown", "if ((_this select 1) == 1) then { true }"];

        waitUntil {sleep 0.3; tup_ied_wire != ""};

        private _selectedWire = tup_ied_wire;
        private _success      = (_selectedWire == _wire);

        // Re-check IED validity - could have been detonated while dialog was open.
        if (isNull _IED || !alive _IED) exitWith { hint ""; };

        if (_success) then {
            private _trgr = (position _IED) nearObjects ["EmptyDetector", 3];
            {
                deleteVehicle _x;
            } foreach _trgr;

            if !(isNil "_IEDCharge") then {
                _IEDCharge removeEventHandler ["handleDamage", _IED getVariable "ehID"];
            };

            [[position _IED, [str(side group player)], -20] ,"ALiVE_fnc_updateSectorHostility", false, false, true] call BIS_fnc_MP;
            [[ADDON, "removeIED", _IED] ,"ALiVE_fnc_IED", false, false, true] call BIS_fnc_MP;

            deleteVehicle _IEDCharge;
            deleteVehicle _IED;

            hint "You guessed correct! IED is disarmed";
        } else {
            // Wrong wire - detonate.
            private _shell = [["M_Mo_120mm_AT","M_Mo_120mm_AT_LG","M_Mo_82mm_AT_LG","R_60mm_HE","Bomb_04_F","Bomb_03_F"],[4,8,2,1,1,1]] call BIS_fnc_selectRandomWeighted;
            _shell createVehicle getposATL _IED;

            private _trgr = (position _IED) nearObjects ["EmptyDetector", 3];
            {
                deleteVehicle _x;
            } foreach _trgr;

            [[position _IED, [str(side group player)], +10] ,"ALiVE_fnc_updateSectorHostility", false, false, true] call BIS_fnc_MP;
            [[ADDON, "removeIED", _IED] ,"ALiVE_fnc_IED", false, false, true] call BIS_fnc_MP;

            deleteVehicle _IEDCharge;
            deleteVehicle _IED;
        };

    } else {

        // Standard disarm - automatic success.
        [_IED, _id] remoteExec ["ALiVE_fnc_removeActionIED", 0, true];

        private _trgr = (position _IED) nearObjects ["EmptyDetector", 3];
        {
            deleteVehicle _x;
        } foreach _trgr;

        if !(isNil "_IEDCharge") then {
            _IEDCharge removeEventHandler ["handleDamage", _IED getVariable "ehID"];
        };

        [[position _IED, [str(side group player)], -20] ,"ALiVE_fnc_updateSectorHostility", false, false, true] call BIS_fnc_MP;
        [[ADDON, "removeIED", _IED] ,"ALiVE_fnc_IED", false, false, true] call BIS_fnc_MP;

        deleteVehicle _IEDCharge;
        deleteVehicle _IED;

        hint "IED is disarmed";
    };
};
