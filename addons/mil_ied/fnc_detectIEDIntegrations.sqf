#include "\x\alive\addons\mil_ied\script_component.hpp"
SCRIPT(detectIEDIntegrations);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_detectIEDIntegrations
Description:
Walks the Cfg3rdPartyIEDs config registry and returns the subset of
entries whose cfgPatchesName is actually loaded as a CfgPatches class.
This is the runtime-detection entry point for the auto-detect 3rd-party
IED integration strategy - see memory note strategy_auto_detect_addons.

Each returned record is a SQF HashMap with keys:
    cfgPatchesName, displayName, mode,
    roadIEDClasses, urbanIEDClasses, clutterClasses, detonator, className

Phase 1 scope: detection + return only. The consumers (armIED, createIED,
removeIED, Object Classes merge) will start using the mode and class
arrays in later phases.

Parameters:
    None.

Returns:
    ARRAY of HashMaps - one per detected integration. Empty if none.

Author:
Jman
---------------------------------------------------------------------------- */

private _result = [];
private _registry = configFile >> "Cfg3rdPartyIEDs";

if (!isClass _registry) exitWith { _result };

for "_i" from 0 to (count _registry - 1) do {
    private _entry = _registry select _i;
    if (isClass _entry) then {
        private _cfgPatchesName = getText (_entry >> "cfgPatchesName");
        // Skip entries without a cfgPatchesName or whose named addon isn't loaded.
        if (_cfgPatchesName != "" && {isClass (configFile >> "CfgPatches" >> _cfgPatchesName)}) then {
            private _record = createHashMap;
            _record set ["cfgPatchesName",   _cfgPatchesName];
            _record set ["displayName",      getText  (_entry >> "displayName")];
            _record set ["mode",             getText  (_entry >> "mode")];
            _record set ["roadIEDClasses",   getArray (_entry >> "roadIEDClasses")];
            _record set ["urbanIEDClasses",  getArray (_entry >> "urbanIEDClasses")];
            _record set ["clutterClasses",   getArray (_entry >> "clutterClasses")];
            _record set ["detonator",        getArray (_entry >> "detonator")];
            _record set ["className",        configName _entry];
            _result pushBack _record;
        };
    };
};

_result
