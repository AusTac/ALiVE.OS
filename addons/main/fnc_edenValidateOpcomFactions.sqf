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

Scope parameter:
    _this select 1 (optional, default []):
        Array of OPCOM entity objects to restrict validation to. When
        non-empty, only those OPCOMs are checked (used by sync/attr
        triggers so the user sees feedback about the OPCOM they just
        touched, not a global re-audit that surfaces pre-existing
        misconfigs on unrelated OPCOMs). When empty, walks every OPCOM
        in the scene (used by the preview trigger as the last-chance
        safety net).

Author:
Jman
---------------------------------------------------------------------------- */

if !(is3DEN) exitWith {};

params [["_trigger", "attr", [""]], ["_scope", [], [[]]]];

// Debounce: cancel any pending run and schedule a fresh one. Bulk sync
// / paste ops (and Eden's per-attribute OnEntityAttributeChanged bursts
// - one event per attribute means ~16 fires from a single OPCOM Save)
// would otherwise run the validator N times. Only the LAST scheduled
// run actually executes.
if (!isNil "ALIVE_edenFactionValidatorPending") then {
    terminate ALIVE_edenFactionValidatorPending;
};
ALIVE_edenFactionValidatorPending = [_trigger, _scope] spawn {
    params ["_trigger", "_scope"];
    sleep 0.5;
    diag_log format ["ALiVE 3DEN faction-sync check: running (trigger=%1 scope=%2)", _trigger, count _scope];

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

    // Per-trigger scoping: when the caller passes a non-empty _scope
    // list (OPCOM entities), only those OPCOMs are validated. Keeps
    // sync/attr feedback focused on the OPCOM the user just touched,
    // instead of surfacing pre-existing misconfigs on unrelated OPCOMs
    // in the scene every time anything changes.
    //
    // Empty _scope (preview trigger, or legacy callers) falls back to
    // the global walk: flatten all3DENEntities' mixed-type buckets
    // (objects/triggers/systems hold objNull; markers/layers/
    // connections hold strings/numbers/arrays - filter per-element),
    // then filter to OPCOM-class logics.
    private _opcomsToValidate = if (count _scope > 0) then {
        _scope
    } else {
        private _all = [];
        {
            {
                if (_x isEqualType objNull && {!isNull _x} && {(typeOf _x) in _OPCOM_CLASSES}) then {
                    _all pushBack _x;
                };
            } forEach _x;
        } forEach all3DENEntities;
        _all
    };

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

            // Bidirectional check: both sets must be empty for an OPCOM
            // to count as correctly wired.
            //
            //   _unmatched = OPCOM declares factions that NO synced
            //                placement provides -> runtime "no groups"
            //                error.
            //   _orphaned  = synced placement provides factions the
            //                OPCOM doesn't declare -> wasted sync; the
            //                mission-maker probably meant to sync that
            //                placement to a different OPCOM.
            //
            // Either condition alone is worth warning about.
            private _unmatched = _opcomFactions select { !(_x in _availableFactions) };
            private _orphaned  = _availableFactions select { !(_x in _opcomFactions) };

            // Track which OPCOM factions DID resolve (intersection with
            // available) for the green OK toast listing.
            {
                if ((_x in _availableFactions) && {!(_x in _resolvedFactions)}) then {
                    _resolvedFactions pushBack _x;
                };
            } forEach _opcomFactions;

            if (count _unmatched > 0 || {count _orphaned > 0}) then {
                // Truncate each list to first 5 entries in the toast so a
                // wildly-misconfigured module doesn't spam a wall of
                // text. Full lists still go to diag_log.
                private _truncate = {
                    params ["_list"];
                    if (count _list > 5) then {
                        (_list select [0, 5]) + [format ["... (+%1 more)", (count _list) - 5]]
                    } else {
                        _list
                    }
                };
                private _parts = [];
                if (count _unmatched > 0) then {
                    _parts pushBack format [
                        "wants [%1] but no synced placement provides these",
                        ([_unmatched] call _truncate) joinString ", "
                    ];
                };
                if (count _orphaned > 0) then {
                    _parts pushBack format [
                        "has synced placement(s) providing [%1] that this OPCOM doesn't declare in its Factions",
                        ([_orphaned] call _truncate) joinString ", "
                    ];
                };
                private _msg = format [
                    "ALiVE: AI Commander '%1' %2. Fix by adjusting the Factions multi-select or the synced placement faction fields to align.",
                    _name,
                    _parts joinString "; and "
                ];
                // BIS_fnc_3DENNotification - 3DEN-native toast top-middle.
                // systemChat is NOT used - it's silently discarded in the
                // 3DEN editor (chat overlay inactive).
                //
                // 60-second duration: mismatch messages can be long (faction
                // lists, combined unmatched+orphaned clauses) and the
                // mission-maker needs time to read the full text and the
                // suggested fix before the toast fades. Previous 20s was
                // long enough to notice but often not long enough to fully
                // read and act.
                // type 1 = Red warning, duration 60 seconds.
                [_msg, 1, 60] call BIS_fnc_3DENNotification;
                diag_log format [
                    "ALiVE 3DEN faction-sync check: AI Commander '%1' unmatched=[%2] orphaned=[%3] available=[%4]",
                    _name,
                    _unmatched joinString ", ",
                    _orphaned joinString ", ",
                    _availableFactions joinString ", "
                ];
                _warnings = _warnings + 1;
            };
        };
    } forEach _opcomsToValidate;

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
