#include "\x\alive\addons\x_lib\script_component.hpp"
SCRIPT(debugMarkerOffset);

/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_debugMarkerOffset
Description:
Returns a stable compass-point offset position for a debug text marker,
keyed on the emitter's registered identifier. Multiple modules stacking
debug markers at the same cluster / objective / sector centre overlap
into unreadable text soup (mil_opcom, fnc_strategic, fnc_analysis all
default to _center). This helper reserves each known emitter a compass
slot on a 75m radius around the anchor so labels fan out instead of
colliding.

Emitters not in the registry fall back to the anchor unchanged, so a
new debug marker call site is opt-in: add a case below and start
using it.

Parameters:
_this select 0: STRING - emitter identifier (see registry below)
_this select 1: ARRAY  - anchor position [x,y] or [x,y,z]

Returns:
ARRAY - offset position [x,y,z]

Examples:
(begin example)
_labelPos = ["opcom", _center] call ALiVE_fnc_debugMarkerOffset;
_m = createMarker [_markerName, _labelPos];
_m setMarkerText "EAST #3";
(end)

Registered emitters (2026-04-20):
    "strategic"        cluster label (fnc_strategic/fnc_cluster.sqf)     anchor
    "opcom"            OPCOM objectives (mil_opcom/fnc_OPCOM.sqf)        N +75m
    "analysis.live"    live-analysis type marker (fnc_analysis)          E +75m
    "analysis.sector"  sector ID label (fnc_analysis/fnc_sector.sqf)     S -75m

Reserved compass slots for future emitters:
    W -75m, NE, NW, SE, SW

Author:
Jman
---------------------------------------------------------------------------- */

params ["_emitterId", "_center"];

private _offset = switch (_emitterId) do {
    case "strategic":        {[  0,   0]};
    case "opcom":            {[  0,  75]};
    case "analysis.live":    {[ 75,   0]};
    case "analysis.sector":  {[  0, -75]};
    default                  {[  0,   0]};
};

[
    (_center select 0) + (_offset select 0),
    (_center select 1) + (_offset select 1),
    _center param [2, 0]
]
