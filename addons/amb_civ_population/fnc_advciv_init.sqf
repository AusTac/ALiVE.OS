#include "\x\alive\addons\amb_civ_population\script_component.hpp"
SCRIPT(advciv_init);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_advciv_init
Description:
    Main initialization entry point for the Advanced Civilians system.
    Called from XEH_postInit (server side) after all globals and utility
    functions have been published by fnc_civilianPopulationSystemInit.

    Responsibilities:
      - Registers all civilian units that are already alive at mission start
        into the AdvCiv brain loop.
      - Starts a catch-all spawn loop that registers any civilian units that
        spawn during the window before XEH_postInit's CBA_fnc_addClassEventHandler
        catch-all becomes active.

    Everything else (event handlers, per-frame decay, brain tick loop) is
    owned by XEH_postInit and must not be duplicated here.

Parameters:
    None

Returns:
    Nothing

Examples:
    (begin example)
    call ALIVE_fnc_advciv_init;
    (end)

Author:
    Jman
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};

if (isNil "ALiVE_advciv_enabled" || {!ALiVE_advciv_enabled}) exitWith {
    ["ALiVE Advanced Civilians - Not enabled (no Civilian Population module or disabled in settings)"] call ALIVE_fnc_dump;
};

["ALiVE Advanced Civilians - Initializing..."] call ALIVE_fnc_dump;

// Register all civilians that are already present at mission start
{
    [_x] call ALiVE_fnc_advciv_brainLoop;
} forEach (allUnits select {side _x == civilian && {alive _x} && {!isPlayer _x}});

// Catch-all loop: registers any civilian units that spawn in the brief window
// between this init call and the XBA CBA_fnc_addClassEventHandler becoming active.
// Exits cleanly once ALiVE_advciv_enabled is cleared.
[] spawn {
    if (isNil "ALiVE_advciv_enabled" || {!ALiVE_advciv_enabled}) exitWith {};
    while {ALiVE_advciv_enabled} do {
        {
            if (alive _x && {side _x == civilian} && {!isPlayer _x} && {!(_x getVariable ["ALiVE_advciv_active", false])}) then {
                [_x] call ALiVE_fnc_advciv_initUnit;
            };
        } forEach allUnits;
        sleep 10;
    };
};

["ALiVE Advanced Civilians - Initialization complete"] call ALIVE_fnc_dump;
