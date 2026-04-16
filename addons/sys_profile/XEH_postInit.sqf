/* ----------------------------------------------------------------------------
XEH_postInit for sys_profile

Registers a Map mission event handler so that debug markers are rebuilt for
every registered profile the moment the player opens the map. Without this,
stationary profiles never refresh their markers — createDebugMarkers is
visibleMap-gated (added to fix issue #838) and the position-change refresh
path is both throttled and skipped for profiles that don't move.

Server-only: the profile simulator runs server-side and createMarker is global.
On dedicated MP the server has no map UI so this EH never fires, which is fine
because visibleMap is permanently false on dedicated and no markers would be
created anyway. On SP / listen server the server machine is the map user, so
the refresh triggers correctly.

Author:
Jman
---------------------------------------------------------------------------- */
#include "script_component.hpp"

if (!isServer) exitWith {};

addMissionEventHandler ["Map", {
    params ["_mapIsOpened"];
    if (!_mapIsOpened) exitWith {};
    if (isNil "ALIVE_profileHandler") exitWith {};

    // Only bother if debug is actually on — nothing to refresh otherwise.
    private _debugOn = [ALIVE_profileHandler, "debug"] call ALIVE_fnc_profileHandler;
    if (!_debugOn) exitWith {};

    // Re-toggle debug: the existing case "debug" path in fnc_profileHandler
    // enumerates every registered profile, deletes its markers, then (because
    // we pass true) recreates them. This is the map-open full-refresh sweep.
    [ALIVE_profileHandler, "debug", true] call ALIVE_fnc_profileHandler;
}];
