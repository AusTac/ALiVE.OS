/* ----------------------------------------------------------------------------
XEH_postInit for mil_ied

Registers a Map mission event handler so that debug markers are rebuilt
every time the player opens the map. Two reasons this is needed:

1. At module init, case "createMarkers" iterates GVAR(STORE)'s triggers hash
   which is empty - no town IED triggers have been registered yet. Any
   markers intended for existing IEDs can't be built until that hash is
   populated. Re-firing on map-open guarantees a fresh rebuild once
   triggers/IEDs actually exist.

2. Inline marker creation in fnc_createIED.sqf can miss markers when
   _debug evaluates to an unexpected type (Eden Combo SCALAR, for
   example). Rebuilding from the authoritative triggers/IEDs hash on
   map-open makes the marker state self-correcting.

Server-only - the createMarkers case uses CBA_fnc_createMarker with
"GLOBAL" scope which broadcasts to all clients from the server. On
dedicated server visibleMap is permanently false so the EH never fires,
but that's the same story as sys_profile's equivalent and debug testing
happens SP / listen server.

Author:
Jman
---------------------------------------------------------------------------- */
#include "script_component.hpp"

if (!isServer) exitWith {};

addMissionEventHandler ["Map", {
    params ["_mapIsOpened"];
    if (!_mapIsOpened) exitWith {};
    if (isNil QUOTE(ADDON)) exitWith {};

    // Only bother if debug is actually on - nothing to rebuild otherwise.
    private _debugOn = ADDON getVariable ["debug", false];
    if (!_debugOn) exitWith {};

    // Re-toggle debug: the case "debug" path deletes existing debug markers
    // and recreates them from GVAR(STORE)'s triggers hash. That's the full
    // map-open refresh sweep.
    [ADDON, "debug", true] call ALIVE_fnc_IED;
}];
