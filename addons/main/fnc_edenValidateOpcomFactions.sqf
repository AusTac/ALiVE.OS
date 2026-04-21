#include "\x\alive\addons\main\script_component.hpp"
SCRIPT(edenValidateOpcomFactions);

/* ----------------------------------------------------------------------------
Function: ALiVE_fnc_edenValidateOpcomFactions
Description:
Editor-time validator — walks every OPCOM entity in the mission and checks
that each OPCOM's declared factions (multi-select `factions` +
free-text `factionsManual` override) are actually provided by at least
one of its synced placement modules. Emits a systemChat + diag_log
warning per mismatched OPCOM so mission-makers catch OPCOM<->placement
faction misconfigurations before mission preview / runtime.

Mirrors the runtime MISMATCH log in fnc_OPCOM.sqf (~line 500) but fires
in the Eden editor instead of at mission load, giving mission-makers
earlier feedback when they sync modules or edit faction attributes.

Called from 3DEN event handlers (OnConnectionChanged, OnAttributesChanged)
registered in XEH_postInit.sqf. Safe no-op outside Eden.

Debounce: a 0.5s scheduled-script window collapses bursts (bulk paste,
multi-module sync ops) into one validation run.

Parameters:
    none

Returns:
    nil

Warnings only - does NOT auto-fix. Placement modules' `faction` field
is single-value (not multi); auto-adding could silently destroy the
mission-maker's existing choice and create two-way sync conflicts. Tier-1
notify-only by design.

Trigger parameter:
    _this select 0 (optional, default "attr"):
        "sync"    - validator fired from OnConnectingEnd; emits a green
                    "Sync OK" notification when no mismatches.
        "attr"    - validator fired from OnEntityAttributeChanged.
        "preview" - validator fired from OnMissionPreview.
    Mismatch warning fires regardless of trigger. Positive "all OK"
    confirmation is ONLY emitted for the "sync" trigger to avoid
    drowning the user in repeated green toasts every attribute edit.

Author:
Jman
---------------------------------------------------------------------------- */

if !(is3DEN) exitWith {};

params [["_trigger", "attr", [""]]];

// Debounce: cancel any pending run and schedule a fresh one. Bulk sync
// / paste ops (and Eden's per-attribute OnEntityAttributeChanged bursts
// - one event per attribute means ~16 fires from a single OPCOM Save)
// would otherwise run the validator N times. Only the LAST scheduled
// run actually executes.
if (!isNil "ALIVE_edenFactionValidatorPending") then {
    terminate ALIVE_edenFactionValidatorPending;
};
ALIVE_edenFactionValidatorPending = [_trigger] spawn {
    params ["_trigger"];
    sleep 0.5;
    diag_log format ["ALiVE 3DEN faction-sync check: running (trigger=%1)", _trigger];

    private _OPCOM_CLASSES = ["ALiVE_mil_OPCOM"];
    private _PLACEMENT_CLASSES = [
        "ALiVE_mil_placement",
        "ALiVE_civ_placement",
        "ALiVE_civ_placement_custom",
        "ALiVE_mil_placement_custom",
        "ALiVE_mil_placement_spe"
    ];

    // Parse a stored multi-select faction value into a list of classnames.
    // Accepts the three round-trip shapes the multi-select Load/Save
    // handler supports: SQF array literal "[\"a\",\"b\"]", CSV "a,b",
    // or single classname "a". Empty string / nil -> [].
    private _parseFactions = {
        params ["_str"];
        if (_str isEqualType []) exitWith { +_str };
        if !(_str isEqualType "") exitWith { [] };
        if (_str == "") exitWith { [] };
        private _s = _str;
        _s = [_s, " ", ""] call CBA_fnc_replace;
        _s = [_s, "[", ""] call CBA_fnc_replace;
        _s = [_s, "]", ""] call CBA_fnc_replace;
        _s = [_s, """", ""] call CBA_fnc_replace;
        [_s, ","] call CBA_fnc_split
    };

    // Resolve a placement module's faction - prefer the user-set value,
    // fall back to the attribute's CfgVehicles defaultValue so an
    // untouched placement ("OPF_F" default) still counts as providing
    // OPF_F to a synced OPCOM.
    private _resolvePlacementFaction = {
        params ["_mod"];
        private _f = _mod getVariable ["faction", ""];
        if (_f != "") exitWith { _f };
        // defaultValue in CfgVehicles is stored as a quoted-string literal
        // e.g. """OPF_F""" -> strip surrounding quotes to get the bare
        // classname.
        private _cfgDefault = getText (configFile >> "CfgVehicles" >> (typeOf _mod) >> "Attributes" >> "faction" >> "defaultValue");
        _cfgDefault = [_cfgDefault, """", ""] call CBA_fnc_replace;
        _cfgDefault
    };

    // Collect all 3DEN Object entities. all3DENEntities returns
    // mixed-type buckets per current A3 docs:
    //   [_objects, _groups, _triggers, _systems, _markers, _layers,
    //    _comments, _connections]
    // Only some buckets hold Objects (objects/triggers/systems/comments);
    // others hold Strings (markers), Numbers (layers), Arrays
    // (connections). Filter per-element to pick only Object-typed
    // entries - modules (systems) are what we actually care about.
    private _allLogics = [];
    {
        {
            if (_x isEqualType objNull && {!isNull _x}) then {
                _allLogics pushBack _x;
            };
        } forEach _x;
    } forEach all3DENEntities;

    private _warnings = 0;
    // Count OPCOMs that actually got past the pre-sync gate (i.e. had
    // at least one synced placement). Needed so we don't emit a green
    // "all OK" on desync - which fires OnConnectingEnd and results in
    // zero warnings because zero OPCOMs were actually validated.
    private _opcomsChecked = 0;
    // Collected for the green OK toast so mission-makers see WHICH
    // factions resolved, not just that everything is fine.
    private _resolvedFactions = [];

    {
        private _opcom = _x;
        if ((typeOf _opcom) in _OPCOM_CLASSES) then {

            private _name = _opcom getVariable ["customName", ""];
            // Parentheses not angle brackets - BIS_fnc_3DENNotification
            // parses message content as XML and breaks on bare < >.
            if (_name == "") then { _name = format ["(unnamed %1)", typeOf _opcom] };

            private _factionsVal       = _opcom getVariable ["factions",       ""];
            private _factionsManualVal = _opcom getVariable ["factionsManual", ""];

            private _opcomFactions = [_factionsVal]       call _parseFactions;
            _opcomFactions = _opcomFactions + ([_factionsManualVal] call _parseFactions);

            // Dedup + drop empties / sentinel
            private _dedup = [];
            {
                if (_x isEqualType "" && {_x != ""} && {_x != "NONE"} && {!(_x in _dedup)}) then {
                    _dedup pushBack _x;
                };
            } forEach _opcomFactions;
            _opcomFactions = _dedup;

            // Mirror the runtime fallback in fnc_OPCOM.sqf:203-209:
            // when both multi-select and manual overrides are empty,
            // the OPCOM runtime defaults to ["BLU_F"]. Validate against
            // that fallback so a mission-maker who synced both modules
            // at their out-of-box defaults (OPCOM empty -> BLU_F,
            // mil_placement OPF_F) still sees the obvious mismatch
            // instead of silent "checked=0". The validator is only
            // useful if it tells users about misconfigurations they
            // haven't deliberately declared.
            if (count _opcomFactions == 0) then {
                _opcomFactions = ["BLU_F"];
            };

            // Collect factions provided by this OPCOM's synced placement
            // modules.
            //
            // synchronizedObjects is a RUNTIME command - returns [] in
            // 3DEN editor time. The 3DEN-time equivalent is
            // get3DENConnections which returns [[type, to], ...]; we
            // filter for type == "Sync" to match the drag-sync lines
            // mission-makers draw between modules (other connection
            // types include Group, WaypointActivation, etc. - not
            // relevant here).
            private _connections = get3DENConnections _opcom;
            private _synced = (_connections select {(_x select 0) == "Sync"}) apply {_x select 1};
            private _availableFactions = [];
            {
                if ((typeOf _x) in _PLACEMENT_CLASSES) then {
                    private _f = [_x] call _resolvePlacementFaction;
                    if (_f != "" && {!(_f in _availableFactions)}) then {
                        _availableFactions pushBack _f;
                    };
                };
            } forEach _synced;

            // Pre-sync gate: if no placement modules are synced yet, the
            // mission-maker is still building and the OPCOM factions
            // they've picked have nothing to compare against. Skip this
            // OPCOM - don't nag about a mismatch that's actually just
            // "not yet wired up". Also prevents false-positive green
            // "all OK" on desync (OnConnectingEnd fires on disconnect,
            // we arrive here with no placements synced, would otherwise
            // signal OK for something never validated).
            if (count _availableFactions == 0) exitWith {};

            _opcomsChecked = _opcomsChecked + 1;

            private _unmatched = _opcomFactions select { !(_x in _availableFactions) };

            // Track which OPCOM factions DID resolve (intersection with
            // available) for the green OK toast listing.
            {
                if ((_x in _availableFactions) && {!(_x in _resolvedFactions)}) then {
                    _resolvedFactions pushBack _x;
                };
            } forEach _opcomFactions;

            if (count _unmatched > 0) then {
                // Truncate to first 5 unmatched in the toast so a
                // wildly-misconfigured module doesn't spam a wall of
                // text. Full list still goes to diag_log.
                private _unmatchedDisplay = if (count _unmatched > 5) then {
                    (_unmatched select [0, 5]) + [format ["... (+%1 more)", (count _unmatched) - 5]]
                } else {
                    _unmatched
                };
                private _msg = format [
                    "ALiVE: AI Commander '%1' wants %2 - synced placement modules don't provide these. Available: [%3]. Add / sync a placement for the missing faction(s), or edit the Factions multi-select.",
                    _name,
                    _unmatchedDisplay joinString ", ",
                    _availableFactions joinString ", "
                ];
                // Dual notification:
                //  1. BIS_fnc_3DENNotification - 3DEN-native toast top-middle
                //     (type 1 = warning). Short-lived; eye-catch.
                //  2. hintSilent - persistent top-right panel that stays
                //     until the user dismisses it or the next hint replaces
                //     it. This is the "stays visible long enough to read"
                //     channel the mission-maker actually needs.
                // systemChat is NOT used - it's silently discarded in the
                // 3DEN editor (chat overlay inactive).
                // type 1 = Red warning, duration 20 seconds.
                [_msg, 1, 20] call BIS_fnc_3DENNotification;
                diag_log format [
                    "ALiVE 3DEN faction-sync check: AI Commander '%1' unmatched=[%2] available=[%3]",
                    _name,
                    _unmatched joinString ", ",
                    _availableFactions joinString ", "
                ];
                _warnings = _warnings + 1;
            };
        };
    } forEach _allLogics;

    // One-line "all clear" log so mission-makers + debug builds see the
    // validator actually ran.
    if (_warnings == 0) then {
        diag_log format ["ALiVE 3DEN faction-sync check: OK (checked=%1)", _opcomsChecked];

        // Positive confirmation toast only on sync trigger AND only if
        // at least one OPCOM actually got through the pre-sync gate.
        // Otherwise a desync action (which also fires OnConnectingEnd)
        // with 0 checked OPCOMs would false-positive as "all OK".
        // Attribute-edit and mission-preview triggers also skip the
        // green signal to avoid drowning the editor in green toasts.
        //
        // MESSAGE TEXT: no `<` or `>` anywhere - BIS_fnc_3DENNotification
        // interprets message content as XML and truncates at the first
        // `<`. "ALiVE: OPCOM to placement ..." not "ALiVE: OPCOM <->
        // placement ...".
        // Positive green toast fires on either "sync" OR "attr" triggers:
        //   sync - user drew a sync connection and everything resolves
        //   attr - user closed an attribute dialog (OPCOM or placement
        //          module OK-clicked) and everything now resolves
        // Skipped for "preview" trigger because the user is about to see
        // the mission run anyway. 0.5s debounce collapses the per-
        // attribute event burst (one OPCOM Save -> ~16 attr events)
        // into one toast.
        if ((_trigger in ["sync", "attr"]) && {_opcomsChecked > 0}) then {
            private _factionList = if (count _resolvedFactions > 0) then {
                _resolvedFactions joinString ", "
            } else {
                "(none resolved)"
            };
            private _okMsg = format [
                "ALiVE: Sync OK. %1 AI Commander(s) resolve to faction(s) [%2] via synced placement modules.",
                _opcomsChecked,
                _factionList
            ];
            // type 0 = Green notification, duration 15 seconds.
            [_okMsg, 0, 15] call BIS_fnc_3DENNotification;
        };
    };
};
