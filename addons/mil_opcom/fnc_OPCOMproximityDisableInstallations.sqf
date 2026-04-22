#include "\x\alive\addons\mil_OPCOM\script_component.hpp"
SCRIPT(OPCOMproximityDisableInstallations);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_OPCOMproximityDisableInstallations

Description:
Phase 2.2 of issue #697. Allows friendly (non-insurgent-side) forces to
automatically disable enemy asymmetric installations (IED factories,
recruitment HQs, weapons depots) via proximity presence, without requiring
a player to walk up and hold the interaction key.

Runs a single-pass scan over one asymmetric OPCOM's objectives. For each
alive, not-already-disabled installation of the three player-disable
types (factory / HQ / depot), checks whether any enemy-side unit to the
OPCOM (i.e. on a side hostile to the insurgents the OPCOM controls) is
present within a fixed radius around the installation building. If so,
triggers the exact same disable path the player hold-action uses -
building variable flag + ALIVE_fnc_INS_buildingKilledEH cleanup +
per-side subtitle.

Gated on:
  - OPCOM controltype == "asymmetric"
  - handler's friendlyDisableMode in ["proximity", "both"]

Intended to be called periodically (e.g. every 30 seconds) from a spawn
loop started at OPCOM init.

Parameters:
    _this select 0: OPCOM handler hashmap (required)

Returns:
    Nothing

Author:
Jman
---------------------------------------------------------------------------- */

if !(isServer) exitWith {};

params [["_handler", [], [[]]]];

// Safety: if the OPCOM's logic has been disposed since the spawn loop
// scheduled this call, skip. The handler hashmap persists in memory
// (referenced by the spawn scope) but the module object is nulled on
// dispose.
private _module = [_handler, "module", objNull] call ALiVE_fnc_HashGet;
if (isNull _module) exitWith {};

// Gate: only asymmetric OPCOMs with the feature enabled
private _controltype = [_handler, "controltype", ""] call ALiVE_fnc_HashGet;
if (_controltype != "asymmetric") exitWith {};

private _friendlyDisableMode = [_handler, "friendlyDisableMode", "off"] call ALiVE_fnc_HashGet;
if !(_friendlyDisableMode in ["proximity", "both"]) exitWith {};

// Convert the OPCOM's enemy-side list to side objects for the
// `side (group _x)` comparison below. "enemy" here means enemy of the
// insurgent OPCOM - i.e. the friendly-side units the issue refers to.
private _sidesEnemy = [_handler, "sidesenemy", []] call ALiVE_fnc_HashGet;
private _sideObjectsEnemy = _sidesEnemy apply {[_x] call ALiVE_fnc_sideTextToObject};
if (count _sideObjectsEnemy == 0) exitWith {};

// Installation specs: keys match the objective-hashmap entries written by
// spawnIEDfactory / spawnHQ / spawnDepot. disabledVar / subtitle title /
// subtitle text mirror the hold-action calls in those spawn functions
// exactly so mission-makers see the same UX whether the player or AI
// triggered the disable.
private _installationSpecs = [
    ["factory", "ALiVE_MIL_OPCOM_FACTORY_DISABLED", "Nice Job", "%1 disabled the IED factory at grid %2!"],
    ["HQ",      "ALiVE_MIL_OPCOM_HQ_DISABLED",      "Congratulations", "%1 disabled the Recruitment HQ at grid %2!"],
    ["depot",   "ALiVE_MIL_OPCOM_DEPOT_DISABLED",   "Good work", "%1 disabled the weapons depot at grid %2!"]
];

// Proximity radius around the installation building in meters. Matches
// roughly the CQB/objective garrison scale - if friendlies are operating
// within 150 m of an insurgent installation and the insurgents haven't
// killed them, the area is effectively interdicted.
private _PROXIMITY_RADIUS = 150;

private _objectives = [_handler, "objectives", []] call ALiVE_fnc_HashGet;

{
    private _objective = _x;
    {
        _x params ["_installationKey", "_disabledVar", "_subtitleTitle", "_subtitleText"];

        // Convert stored [pos, typeName] array back to the actual building
        // object. Reuses the same convertObject dispatch the existing
        // OPCOMToggleInstallations + holdAction paths use, so we match
        // their resolution semantics exactly. All validity checks nest
        // in one `then {}` block - exitWith inside forEach is "break" in
        // SQF, not "continue", so using it to skip mid-iteration would
        // wrongly abandon the remaining installation types for the same
        // objective (e.g. factory missing -> HQ + depot never checked).
        private _stored = [_objective, _installationKey, []] call ALiVE_fnc_HashGet;
        private _building = [_handler, "convertObject", _stored] call ALiVE_fnc_OPCOM;

        private _canProceed = !isNull _building
            && {alive _building}
            // Idempotence: if a player hold-action (or an earlier scan)
            // already disabled this building, don't re-fire. The hold-
            // action path sets this same variable at fnc_INS_helpers.sqf
            // ~1359.
            && {!(_building getVariable [_disabledVar, false])};

        if (_canProceed) then {
            // Spatial query: any enemy-side living unit/vehicle within
            // _PROXIMITY_RADIUS of the building. Include Man / Car /
            // Tank / Air / Ship so both infantry and vehicle forces
            // count as "friendly presence".
            private _nearbyEnemies = (_building nearEntities [["Man","Car","Tank","Air","Ship"], _PROXIMITY_RADIUS]) select {
                alive _x && {(side (group _x)) in _sideObjectsEnemy}
            };

            if (count _nearbyEnemies > 0) then {
                // Mirror the hold-action callback exactly
                // (fnc_INS_helpers.sqf ~1357-1364). `_caller` is the
                // nearest friendly unit - passed through so the event
                // log + subtitle name someone rather than leaving
                // "objNull disabled the ...".
                private _caller = _nearbyEnemies select 0;
                _building setVariable [_disabledVar, true, true];
                [_building, _caller] remoteExec ["ALIVE_fnc_INS_buildingKilledEH", 2];
                [_subtitleTitle, format [_subtitleText, name _caller, mapGridPosition _building]] remoteExec ["BIS_fnc_showSubtitle", side (group _caller)];
            };
        };
    } forEach _installationSpecs;
} forEach _objectives;
