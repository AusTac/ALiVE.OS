#include "\x\alive\addons\x_lib\script_component.hpp"
SCRIPT(inferFactionMapping);

/* ----------------------------------------------------------------------------
Function: ALiVE_fnc_inferFactionMapping

Description:
Builds an ALiVE_factionCustomMappings-shaped hashmap for a faction that
ships without proper CfgGroups support, by determining the dominant side
from its CfgVehicles units and producing a REDIRECT mapping to a vanilla
A3 faction on the same side.

This is Phase 3c.1 of the mil_placement overhaul - the foundational
"redirect-only" tier of inference. The faction becomes selectable in
ALiVE's faction dropdown and will spawn units of the correct side, but
the units themselves are vanilla A3 (the mod's units are NOT yet
substituted). Phase 3c.2 will add unit-substitution at spawn time so
the mod's units actually appear.

Skips factions where inference is unnecessary or impossible:
  - already mapped via CustomFactions.hpp / sys_orbatcreator output /
    Cfg3rdPartyFactions registry (don't override explicit mappings)
  - already has proper CfgGroups entries on its expected side (the
    existing infrastructure already handles them)
  - no CfgVehicles Man-class units (can't determine dominant side)
  - non-standard CfgFactionClasses side value (logic / internal classes)

Parameters:
String - faction classname

Returns:
HashMap - mapping in same shape as CustomFactions.hpp produces.
nil     - if inference is unnecessary / impossible for this faction.

Examples:
(begin example)
_mapping = "rhs_faction_some_unmapped_thing" call ALiVE_fnc_inferFactionMapping;
if (!isNil "_mapping") then {
    [ALiVE_factionCustomMappings, "rhs_faction_some_unmapped_thing", _mapping] call ALiVE_fnc_hashSet;
};
(end)

See Also:
- ALiVE_fnc_inferFactionMappingsAll  (walks every loaded faction)

Author:
Jman
---------------------------------------------------------------------------- */

private _faction = _this;
if (typeName _faction != "STRING" || {_faction == ""}) exitWith { nil };

// Skip 1: already explicitly mapped (CustomFactions.hpp / orbatcreator /
// Cfg3rdPartyFactions). Don't override curated data with inferred guesses.
if (!isNil "ALiVE_factionCustomMappings") then {
    if (_faction in (ALiVE_factionCustomMappings select 1)) exitWith { nil };
};

// Skip 2: faction class itself doesn't exist or has invalid side
private _factionConfig = configFile >> "CfgFactionClasses" >> _faction;
if !(isClass _factionConfig) exitWith { nil };
private _side = getNumber (_factionConfig >> "side");
if !(_side in [0, 1, 2, 3]) exitWith { nil };

// Skip 3: faction already has proper CfgGroups for its side (no inference needed,
// existing infrastructure handles it). Skip the structural check for civilians;
// they don't use CfgGroups (spawn as individuals via createUnit).
if (_side != 3) then {
    private _sideCfgGroupsName = ["East", "West", "Indep"] select _side;
    private _existingGroups = configFile >> "CfgGroups" >> _sideCfgGroupsName >> _faction;
    if (isClass _existingGroups && {count _existingGroups > 0}) exitWith {};
};

// Probe: faction must have at least one CfgVehicles Man-class unit.
// Without that we can't establish that the faction is meant for unit
// spawning at all (e.g. mod might define a faction class for static-
// object decoration, no actual units).
private _vehicles = "true" configClasses (configFile >> "CfgVehicles");
private _factionTagLower = toLower _faction;
private _hasManUnit = (_vehicles findIf {
    (toLower (getText (_x >> "faction"))) == _factionTagLower &&
    {(configName _x) isKindOf "Man"}
}) >= 0;
if (!_hasManUnit) exitWith { nil };

// Build the redirect mapping. Side and GroupSideName use the all-caps
// convention from CustomFactions.hpp ("EAST" / "WEST" / "INDEP" / "CIV").
// Note INDEP not GUER - configGetFactionGroups normalizes both but
// CustomFactions.hpp uses INDEP-style.
private _sideText = ["EAST", "WEST", "INDEP", "CIV"] select _side;
private _redirectTarget = ["OPF_F", "BLU_F", "IND_F", "CIV_F"] select _side;

private _mapping = [] call ALiVE_fnc_hashCreate;
[_mapping, "Side", _sideText] call ALiVE_fnc_hashSet;
[_mapping, "GroupSideName", _sideText] call ALiVE_fnc_hashSet;
[_mapping, "FactionName", _faction] call ALiVE_fnc_hashSet;
[_mapping, "GroupFactionName", _redirectTarget] call ALiVE_fnc_hashSet;

// Empty GroupFactionTypes + Groups - the consumers (fnc_configGetRandomGroup
// in particular) fall through to the redirect target's CfgGroups when these
// are empty. This is the Phase 3c.1 minimum: faction works, vanilla units
// spawn. Phase 3c.2 will populate Groups with synthesized arrays of the
// mod's actual unit classes.
private _typeMappings = [] call ALiVE_fnc_hashCreate;
[_mapping, "GroupFactionTypes", _typeMappings] call ALiVE_fnc_hashSet;

private _emptyGroups = [] call ALiVE_fnc_hashCreate;
[_mapping, "Groups", _emptyGroups] call ALiVE_fnc_hashSet;

_mapping
