#include "\x\alive\addons\x_lib\script_component.hpp"
SCRIPT(substituteFactionVehicle);

/* ----------------------------------------------------------------------------
Function: ALiVE_fnc_substituteFactionVehicle

Description:
Phase 3c.2b of the mil_placement overhaul. Vehicle/static counterpart to
ALiVE_fnc_substituteFactionUnit. Given a vanilla A3 vehicle class
(produced by spawning through an inferred-faction redirect or by
mil_placement's side-default fallback when the mod faction has no
vehicles in a category) and the original mod faction the user actually
selected, return a same-kindOf vehicle from the mod faction so the
spawned vehicles look like the mod's instead of vanilla A3.

Three caller paths:
  1. createProfilesFromGroupConfig - vehicles inside a CfgGroups group
     (a Motorized Squad's transport truck, a Mortar Team's mortar, etc.)
  2. createProfilesCrewedVehicle - standalone crewed vehicles spawned by
     mil_placement (HQ helis, supply trucks, motorised/mech/armoured,
     statics in support placements)
  3. createProfilesUnCrewedVehicle - standalone uncrewed vehicles
     (parked supplies, empty heli pads)

Bucketing follows ALiVE_fnc_vehicleGetKindOf's canonical 8-category
model (Car / Tank / Armored / Truck / Ship / Helicopter / Plane /
StaticWeapon) so substitution preserves vehicle role-intent within a
group - a transport truck never substitutes to a tank. Statics get
finer sub-bucketing (StaticMortar / StaticATWeapon / StaticAAWeapon /
StaticGMGWeapon / StaticMGWeapon) because a mortar-for-HMG swap would
break tactical intent.

Per-faction vehicle pools are cached in ALiVE_factionVehiclePoolCache.
First call for a faction enumerates its CfgVehicles non-Man scope>=2
entries, classifies each by kindOf, buckets accordingly. Subsequent
calls just look up the cached pool. Same nil-in-array cache lookup
trap that hit substituteFactionUnit applies here - use `in` against
the hashmap key set rather than `getOrDefault [k, nil]`.

Fallback chain (per substitution):
  1. Target faction has vehicles of the requested kindOf -> random pick
  2. Otherwise -> source unchanged (vanilla A3 vehicle stays)

NOTE: NO cross-category fallback. Unlike infantry where "Rifleman"
makes a sensible catch-all, vehicles have no universal fallback -
a Plane-for-Helicopter swap, or Tank-for-Truck, would be worse than
keeping the vanilla A3 vehicle. Sparse-pool factions just keep their
vanilla A3 fallbacks for missing categories. This is consistent with
3c.1's redirect-only behaviour for Phase 3c.1-only factions.

Parameters:
Array - [_sourceVehicle, _targetFaction]
    _sourceVehicle : STRING - vanilla A3 (or otherwise unsubstituted)
                              vehicle classname.
    _targetFaction : STRING - the mod faction classname the mission-maker
                              originally selected.

Returns:
STRING - substituted vehicle classname from _targetFaction, or
         _sourceVehicle unchanged if no same-kindOf vehicle exists.

Examples:
(begin example)
_sub = ["O_Truck_03_transport_F", "rhsgref_faction_un"] call ALiVE_fnc_substituteFactionVehicle;
// -> e.g. "rhsgref_BTR60_un" (or unchanged if UN has no Truck-kindOf vehicles)
(end)

See Also:
- ALiVE_fnc_vehicleGetKindOf       (canonical kindOf bucketing)
- ALiVE_fnc_substituteFactionUnit  (infantry counterpart - 3c.2a)
- ALiVE_fnc_inferFactionMapping    (Phase 3c.1 redirect that triggers this)

Author:
Jman
---------------------------------------------------------------------------- */

params [
    ["_sourceVehicle", "", [""]],
    ["_targetFaction", "", [""]]
];

if (_sourceVehicle == "" || _targetFaction == "") exitWith { _sourceVehicle };

// Lazy-init the global pool cache. HashMap-of-hashmaps keyed by faction
// classname. Inner hashmap: kindOf-bucket -> array of vehicle classnames.
if (isNil "ALiVE_factionVehiclePoolCache") then {
    ALiVE_factionVehiclePoolCache = createHashMap;
};

// ------------------------------------------------------------------------
// Helper: classify a vehicle into a substitution bucket.
//
// Non-statics use vehicleGetKindOf's 8-category convention directly.
// Statics get finer-grained dispatch because tactical role within the
// "StaticWeapon" family matters - a mortar request must not satisfy
// from the HMG bucket. Catch-all "StaticWeapon" handles searchlights /
// sentries / mod-specific oddballs that don't fit a named subtype.
//
// Order matters for statics: more-specific isKindOf checks first, then
// the StaticWeapon catch-all only if none of the named subtypes match.
// ------------------------------------------------------------------------
private _classify = {
    params ["_v"];
    if (_v isKindOf "StaticWeapon") exitWith {
        switch (true) do {
            case (_v isKindOf "StaticMortar")     : { "StaticMortar" };
            case (_v isKindOf "StaticATWeapon")   : { "StaticATWeapon" };
            case (_v isKindOf "StaticAAWeapon")   : { "StaticAAWeapon" };
            case (_v isKindOf "StaticGMGWeapon")  : { "StaticGMGWeapon" };
            case (_v isKindOf "StaticMGWeapon")   : { "StaticMGWeapon" };
            default                               { "StaticWeapon" };
        };
    };
    _v call ALiVE_fnc_vehicleGetKindOf
};

// ------------------------------------------------------------------------
// 1. Get (or build) the vehicle pool for _targetFaction.
//
// Cache lookup gotcha (same as substituteFactionUnit): SQF arrays drop
// literal `nil` elements at parse time, so `getOrDefault [_target, nil]`
// silently returns nil EVEN when the key exists. Using `in` against the
// hashmap key set sidesteps the nil-in-array trap.
// ------------------------------------------------------------------------
private _pool = if (_targetFaction in ALiVE_factionVehiclePoolCache) then {
    ALiVE_factionVehiclePoolCache get _targetFaction
};
if (isNil "_pool") then {
    _pool = createHashMap;

    // Enumerate every CfgVehicles non-Man scope>=2 entry belonging to
    // _targetFaction. Cache miss is the expensive path (configClasses
    // across CfgVehicles is ~3000+ entries on a heavily-modded loadout)
    // - we pay it once per faction per mission session.
    private _factionTagLower = toLower _targetFaction;
    private _vehicles = "true" configClasses (configFile >> "CfgVehicles");
    {
        private _vCfg = _x;
        private _vCN  = configName _vCfg;
        // Skip Man (handled by substituteFactionUnit) and scope=0/1
        // (base classes / hidden helpers that would error on createVehicle).
        if (
            (toLower (getText (_vCfg >> "faction"))) == _factionTagLower &&
            {!(_vCN isKindOf "Man")} &&
            {getNumber (_vCfg >> "scope") >= 2}
        ) then {
            private _kind = [_vCN] call _classify;
            // _classify returns "Vehicle" generic for entries that don't
            // match any kindOf - those are usually props / decoration /
            // weird mod helpers. Skip them to keep the pool clean.
            if (_kind != "Vehicle") then {
                private _bucket = _pool getOrDefault [_kind, []];
                _bucket pushBack _vCN;
                _pool set [_kind, _bucket];
            };
        };
    } forEach _vehicles;

    ALiVE_factionVehiclePoolCache set [_targetFaction, _pool];

    // Diagnostic - logged once per faction at first cache miss. Helps
    // verify what categories a mod faction actually populates and
    // whether vanilla-A3 fallbacks happen because the mod simply has
    // no vehicles of that kindOf.
    private _summary = [];
    {
        _summary pushBack format ["%1=%2", _x, count _y];
    } forEach _pool;
    diag_log format [
        "ALiVE substituteFactionVehicle: built vehicle pool for '%1' (%2 buckets: %3)",
        _targetFaction, count _pool, _summary joinString ", "
    ];
};

// ------------------------------------------------------------------------
// 2. Classify the source vehicle's bucket.
// ------------------------------------------------------------------------
private _sourceKind = [_sourceVehicle] call _classify;
if (_sourceKind == "Vehicle") exitWith { _sourceVehicle };

// ------------------------------------------------------------------------
// 3. Resolve via fallback chain. NO cross-category fallback - sparse-pool
//    factions just keep their vanilla A3 source for missing categories.
// ------------------------------------------------------------------------
private _candidates = _pool getOrDefault [_sourceKind, []];
if (count _candidates == 0) exitWith {
    // Target faction has no vehicles of this kindOf - keep source
    // unchanged. Same outcome as Phase 3c.1 redirect-only behaviour.
    _sourceVehicle
};

private _result = selectRandom _candidates;

// Diagnostic - log the FIRST substitution per (faction, sourceKind)
// pair so we can verify in-RPT that the mod faction's vehicles are
// actually being returned. Subsequent substitutions for the same pair
// are silent to avoid log spam.
if (isNil "ALiVE_factionVehicleSubstitutionSeen") then {
    ALiVE_factionVehicleSubstitutionSeen = createHashMap;
};
private _seenKey = format ["%1::%2", _targetFaction, _sourceKind];
if !(_seenKey in ALiVE_factionVehicleSubstitutionSeen) then {
    ALiVE_factionVehicleSubstitutionSeen set [_seenKey, true];
    diag_log format [
        "ALiVE substituteFactionVehicle: '%1' (%2) -> '%3' [faction=%4, pool=%5 candidates]",
        _sourceVehicle, _sourceKind, _result, _targetFaction, count _candidates
    ];
};

_result
