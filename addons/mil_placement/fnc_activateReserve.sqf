#include "\x\alive\addons\mil_placement\script_component.hpp"
SCRIPT(activateReserve);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_activateReserve

Description:
    Reserve-pool activation tick for a single mil_placement cluster.
    Called periodically by the activation watcher PFH started at the
    end of fnc_MP.sqf's cluster placement loop.

    Cascade:
      1. Cluster has reserves remaining? If pool empty, exit.
      2. Active force still above threshold? Compare alive count to
         the cluster's activeAtSpawn snapshot. Only kills decrement -
         virtualisation does not.
      3. Cooldown elapsed since last activation? (Default 30 s.)
      4. Player(s) within objective engagement radius? No point
         reinforcing an empty area.
      5. Candidate building available? Building must be inside the
         objective radius, >= 80 m from any player, and have at
         least one BIS_fnc_buildingPositions slot.
      6. Pop one group config from the reserve pool, place it as a
         garrison profile in the candidate building, tag it with the
         home cluster, register in the active list, stamp lastReserveWake.

Parameters:
    _this select 0: HASH   - cluster (mil_placement cluster hash)
    _this select 1: OBJECT - mil_placement module logic (for live attrs)

Returns:
    BOOLEAN - true if a reserve was activated this tick, false otherwise.

Examples:
    (begin example)
    private _activated = [_cluster, _logic] call ALIVE_fnc_activateReserve;
    (end)

See Also:
    ALIVE_fnc_MP

Author:
    Jman
Peer Reviewed:
    nil
---------------------------------------------------------------------------- */

params [
    ["_cluster", [], [[]]],
    ["_logic", objNull, [objNull]]
];

if (count _cluster == 0 || {isNull _logic}) exitWith { false };

private _debug = !isNil "ALiVE_vehicleSpawn_debug" && {ALiVE_vehicleSpawn_debug};

// 1. Reserves remaining? Silent skip in steady state - no point
//    logging clusters that have no reserves to begin with.
private _reservePool = [_cluster, "reservePool", []] call ALiVE_fnc_hashGet;
if (count _reservePool == 0) exitWith { false };

private _center = [_cluster, "center"] call ALiVE_fnc_hashGet;

// 2. Threshold check - alive vs activeAtSpawn.
//    Edge case: activeAtSpawn==0 means placement put groups into this
//    cluster's reserve pool but never spawned an active group there
//    (typical when group distribution + Readiness leaves a tail
//    cluster with all-reserve infantry). Fall back to proximity-only
//    activation - skip the threshold check, let the player-presence
//    and candidate-building gates decide. Subject to the cooldown so
//    the cluster doesn't waterfall on first contact.
private _activeAtSpawn = [_cluster, "reserveActiveAtSpawn", 0] call ALiVE_fnc_hashGet;
private _activeIDs = [_cluster, "activeProfileIDs", []] call ALiVE_fnc_hashGet;
private _aliveCount = {
    private _p = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
    !isNil "_p"
} count _activeIDs;

private _threshold = parseNumber ([_logic, "reserveActivationThreshold"] call ALIVE_fnc_MP);

// Threshold gate. When activeAtSpawn > 0 AND fraction > threshold,
// the force is healthy - skip silently. When activeAtSpawn == 0,
// fall through (proximity-only activation; see comment above).
if (_activeAtSpawn > 0 && {(_aliveCount / _activeAtSpawn) > _threshold}) exitWith { false };

// 3. Cooldown elapsed?
private _cooldown = parseNumber ([_logic, "reserveActivationCooldown"] call ALIVE_fnc_MP);
private _lastWake = [_cluster, "lastReserveWake", -999] call ALiVE_fnc_hashGet;
if ((serverTime - _lastWake) < _cooldown) exitWith {
    if (_debug) then {
        diag_log format ["[ALiVE Reserve DEBUG] SKIP cluster_center=%1 reason=cooldown waiting=%2s remaining=%3s reserves=%4 activeAlive=%5/%6",
            _center, _cooldown, round (_cooldown - (serverTime - _lastWake)),
            count _reservePool, _aliveCount, _activeAtSpawn];
    };
    false
};

// 4. Players within engagement radius?
private _size = [_cluster, "size", 200] call ALiVE_fnc_hashGet;
private _engagementRadius = _size * 1.5;
private _playersInArea = (allPlayers - entities "HeadlessClient_F")
    select { (_x distance2D _center) < _engagementRadius };
if (_playersInArea isEqualTo []) exitWith {
    if (_debug) then {
        diag_log format ["[ALiVE Reserve DEBUG] SKIP cluster_center=%1 reason=no-player-in-area engagementRadius=%2 reserves=%3 activeAlive=%4/%5",
            _center, _engagementRadius, count _reservePool, _aliveCount, _activeAtSpawn];
    };
    false
};

// 5. Peek at first entry to determine type. Reserve pool entries
//    have a type discriminator at index 0:
//      "VEHICLE"  - empty vehicle profile already spawned at parking;
//                   crew added to the existing empty entity profile.
//      "INFANTRY" - group config held; crew spawned at a building.
//    Legacy v1 entries had no discriminator (4-element shape); for
//    forward-compat treat type-less as "INFANTRY".
private _reserveEntry = _reservePool select 0;
private _entryType = if (count _reserveEntry > 0 && {(_reserveEntry select 0) isEqualType ""}) then {
    _reserveEntry select 0
} else {
    "INFANTRY"
};

private _guardRadius = parseNumber ([_logic, "guardRadius"] call ALIVE_fnc_MP);
private _guardPatrolPercentage = parseNumber ([_logic, "guardPatrolPercentage"] call ALIVE_fnc_MP);
private _activated = false;

// Helper: orphaned-crew → infantry fallback. Activates as if INFANTRY,
// using the group class from the orphan entry. Shared between vehicle-
// reserve orphan branch and (potentially) future fall-throughs.
private _fnc_activateAsInfantry = {
    params ["_group", "_faction", "_onEachSpawn", "_onEachSpawnOnce"];

    // Building check (same gate as native infantry path)
    private _proximityGate = 80;
    private _buildingsInArea = nearestObjects [_center, ["Building", "House"], _size];
    private _candidateBuilding = objNull;
    {
        private _b = _x;
        private _slots = _b call BIS_fnc_buildingPositions;
        if (count _slots == 0) then { continue };
        private _tooClose = _playersInArea findIf { (_b distance2D _x) < _proximityGate };
        if (_tooClose >= 0) then { continue };
        _candidateBuilding = _b;
    } forEach _buildingsInArea;

    if (isNull _candidateBuilding) exitWith {
        if (_debug) then {
            diag_log format ["[ALiVE Reserve DEBUG] SKIP cluster_center=%1 reason=no-safe-building reserves=%2 activeAlive=%3/%4",
                _center, count _reservePool, _aliveCount, _activeAtSpawn];
        };
        false
    };

    // Spawn 5-15 m outside the building.
    private _spawnPos = [position _candidateBuilding, 5 + random 10] call CBA_fnc_RandPos;
    private _profiles = [_group, _spawnPos, random 360, true, _faction, false, false, "STEALTH", _onEachSpawn, _onEachSpawnOnce] call ALIVE_fnc_createProfilesFromGroupConfig;

    {
        if (([_x, "type"] call ALiVE_fnc_hashGet) == "entity") then {
            [_x, "setActiveCommand", ["ALIVE_fnc_garrison", "spawn", [_guardRadius, "true", [0,0,0], "", 1, _guardPatrolPercentage]]] call ALIVE_fnc_profileEntity;
            [_x, "homeCluster", _cluster] call ALiVE_fnc_hashSet;
            _activeIDs pushBack ([_x, "profileID"] call ALiVE_fnc_hashGet);
        };
    } forEach _profiles;

    if (_debug) then {
        diag_log format ["[ALiVE Reserve DEBUG] ACTIVATE-INFANTRY faction=%1 cluster_center=%2 building=%3 activeAlive=%4/%5 reservesRemaining=%6",
            _faction, _center, typeOf _candidateBuilding,
            _aliveCount, _activeAtSpawn, count _reservePool - 1];
    };

    true
};

if (_entryType == "VEHICLE") then {
    _reserveEntry params ["", "_groupClass", "_vehicleProfileID", "_entityProfileID", "_entryFaction", "_entryOnSpawn", "_entryOnSpawnOnce"];

    // Look up profiles by ID. Pool entries store IDs (strings) not
    // array references to avoid the recursive-array cycle (entity has
    // homeCluster=cluster, cluster has reservePool, so embedding the
    // entity array in reservePool would form a loop).
    private _profileVehicle = [ALIVE_profileHandler, "getProfile", _vehicleProfileID] call ALIVE_fnc_profileHandler;
    private _profileEntity = [ALIVE_profileHandler, "getProfile", _entityProfileID] call ALIVE_fnc_profileHandler;

    // Orphan check: profile missing (unregistered = profile killed and
    // the handler removed it) OR the live in-world vehicle is dead.
    // Don't check the profile's "damage" hash field - that stores an
    // array of [hitPoint, damage] pairs (see vehicleGetDamage), not a
    // scalar. Profile-handler-based detection is reliable on its own;
    // the in-world alive-check covers the brief window between vehicle
    // destruction and handler unregistration.
    private _vehicleMissing = isNil "_profileVehicle";
    private _vehicleObject = if (_vehicleMissing) then { objNull } else { [_profileVehicle, "vehicle", objNull] call ALiVE_fnc_hashGet };
    private _isOrphaned = _vehicleMissing
        || {!isNull _vehicleObject && {!alive _vehicleObject}};

    if (_isOrphaned) then {
        private _orphanBehaviour = [_logic, "reserveOrphanCrewBehaviour"] call ALIVE_fnc_MP;
        // Pop orphan from pool first - either way, this entry is consumed.
        _reservePool deleteAt 0;

        if (_orphanBehaviour == "Drop") then {
            if (_debug) then {
                diag_log format ["[ALiVE Reserve DEBUG] DROP-ORPHAN cluster_center=%1 vehicleClass=%2 reservesRemaining=%3",
                    _center, [_profileVehicle, "vehicleClass", "?"] call ALiVE_fnc_hashGet, count _reservePool];
            };
            // Activated=false (no real activation), but still update
            // lastReserveWake so we don't spin every tick burning CPU on
            // the same orphan that's already gone.
            [_cluster, "lastReserveWake", serverTime] call ALiVE_fnc_hashSet;
        } else {
            // SpawnAsInfantry - reuse the infantry helper.
            _activated = [_groupClass, _entryFaction, _entryOnSpawn, _entryOnSpawnOnce] call _fnc_activateAsInfantry;
        };
    } else {
        // Vehicle alive - add crew to the existing empty entity profile,
        // clear busy flags, unlock if applicable, then despawn / spawn
        // the entity so the new crew materialises inside the truck.
        private _vehicleClass = [_profileVehicle, "vehicleClass"] call ALiVE_fnc_hashGet;
        private _crew = _vehicleClass call ALIVE_fnc_configGetVehicleCrew;
        private _vehiclePositions = [_vehicleClass] call ALIVE_fnc_configGetVehicleEmptyPositions;
        private _countCrewPositions = 0;
        for "_i" from 0 to (count _vehiclePositions) - 3 do {
            _countCrewPositions = _countCrewPositions + (_vehiclePositions select _i);
        };
        private _vehiclePos = [_profileVehicle, "position", _center] call ALiVE_fnc_hashGet;

        // Add vehicle's own crew (driver/gunner/commander).
        for "_i" from 0 to _countCrewPositions - 1 do {
            [_profileEntity, "addUnit", [_crew, _vehiclePos, 0, "PRIVATE"]] call ALIVE_fnc_profileEntity;
        };

        // Add dismount infantry from group config (Man entries).
        private _groupConfig = [_entryFaction, _groupClass] call ALIVE_fnc_configGetGroup;
        for "_i" from 0 to (count _groupConfig) - 1 do {
            private _entry = _groupConfig select _i;
            if (isClass _entry) then {
                private _entryVehicle = getText (_entry >> "vehicle");
                private _entryRank = getText (_entry >> "rank");
                if (_entryVehicle isKindOf "Man") then {
                    [_profileEntity, "addUnit", [_entryVehicle, _vehiclePos, 0, _entryRank]] call ALIVE_fnc_profileEntity;
                };
            };
        };

        // Clear busy flags - OPCOM picks them up next tick.
        [_profileEntity, "busy", false] call ALIVE_fnc_profileEntity;
        [_profileVehicle, "busy", false] call ALIVE_fnc_profileVehicle;

        // Unlock the world vehicle if it was locked at placement. The
        // profile flag stays set; the spawn-time lock in profileVehicle
        // also gates on busy=true (just cleared above), so subsequent
        // virtualisation despawn / spawn cycles won't re-lock now that
        // the entity has been activated.
        if ([_profileVehicle, "ALiVE_reserveLocked", false] call ALiVE_fnc_HashGet) then {
            if (!isNull _vehicleObject) then { _vehicleObject lock 0; };
        };

        // Set active command BEFORE the despawn/spawn cycle. The
        // command lives on the entity profile's "commands" field and
        // gets picked up when the next spawn flow materialises the
        // crew. Doing it inline here uses the outer scope's
        // _guardRadius / _guardPatrolPercentage cleanly - capturing
        // them through `[args] spawn { params [...] }` was producing
        // "Undefined variable: _gr" errors (likely a SQF scope quirk
        // when call'd-functions internally suspend mid-spawn-block).
        [_profileEntity, "setActiveCommand", ["ALIVE_fnc_garrison", "spawn", [_guardRadius, "true", [0,0,0], "", 1, _guardPatrolPercentage]]] call ALIVE_fnc_profileEntity;

        // Despawn + spawn cycle on the entity to materialise the new
        // crew. The vehicle profile is independent and stays as-is, so
        // no visual flicker on the truck itself - just crew popping
        // into the seats on the next tick.
        //
        // Wrapped in a scheduled spawn because the PFH that called us
        // runs in unscheduled context, but fnc_profileEntity's "spawn"
        // path uses `sleep ALiVE_smoothSpawn` internally - which errors
        // "Suspending not allowed in this context" if call'd from a PFH.
        [_profileEntity] spawn {
            params ["_pe"];
            [_pe, "despawn"] call ALIVE_fnc_profileEntity;
            [_pe, "spawn"] call ALIVE_fnc_profileEntity;
        };

        // Track in cluster's active list so subsequent threshold checks
        // count this entity.
        _activeIDs pushBack ([_profileEntity, "profileID"] call ALiVE_fnc_hashGet);

        _reservePool deleteAt 0;
        _activated = true;

        if (_debug) then {
            // Threshold display with NaN guard. _threshold has been
            // observed to log as "scalar NaN" through the format
            // chain in some attribute-reading paths; guard so the log
            // is readable rather than chasing the underlying type bug.
            private _thresholdStr = if (_threshold > 0 && _threshold <= 1) then { str (round (_threshold * 100)) } else { "?" };
            diag_log format ["[ALiVE Reserve DEBUG] ACTIVATE-VEHICLE faction=%1 cluster_center=%2 vehicleClass=%3 crewCount=%4 activeAlive=%5/%6 threshold=%7%% reservesRemaining=%8",
                _entryFaction, _center, _vehicleClass, _countCrewPositions,
                _aliveCount, _activeAtSpawn, _thresholdStr, count _reservePool];
        };
    };
} else {
    // INFANTRY reserve. Legacy 4-element entries fall here too (treated
    // as INFANTRY).
    private _group = if (_entryType == "INFANTRY") then {
        _reserveEntry select 1
    } else {
        _reserveEntry select 0  // legacy v1 shape
    };
    private _entryFaction = if (_entryType == "INFANTRY") then {
        _reserveEntry select 2
    } else {
        _reserveEntry select 1
    };
    private _entryOnSpawn = if (_entryType == "INFANTRY") then {
        _reserveEntry select 3
    } else {
        _reserveEntry select 2
    };
    private _entryOnSpawnOnce = if (_entryType == "INFANTRY") then {
        _reserveEntry select 4
    } else {
        _reserveEntry select 3
    };

    private _ok = [_group, _entryFaction, _entryOnSpawn, _entryOnSpawnOnce] call _fnc_activateAsInfantry;
    if (_ok) then {
        _reservePool deleteAt 0;
        _activated = true;
    };
};

// Common post-success bookkeeping.
if (_activated) then {
    [_cluster, "reservePool", _reservePool] call ALiVE_fnc_hashSet;
    [_cluster, "activeProfileIDs", _activeIDs] call ALiVE_fnc_hashSet;
    [_cluster, "lastReserveWake", serverTime] call ALiVE_fnc_hashSet;
};

_activated
