#include "script_component.hpp"

LOG(MSG_INIT);

//Set ALiVE Interaction menu on custom userkey 20 and if none is defined fallback to 221 App key
if ((count ActionKeys "User20") > 0) then {
    SELF_INTERACTION_KEY = [(ActionKeys "User20" select 0),[false,false,false]];
} else {
    SELF_INTERACTION_KEY = [221,[false,false,false]];
};

["ALiVE","openMenu", "Open Menu (Requires Restart)", {playsound "HintCollapse"}, {}, SELF_INTERACTION_KEY] call CBA_fnc_addKeybind;

// 3DEN editor-time OPCOM<->placement faction-sync validator.
//
// Registered in preInit because XEH_postInit does NOT fire in pure-
// Eden editor mode (no scenario = no mission post-init). PreInit
// always fires and at that point the 3DEN editor display is already
// loaded (CBA's "3DEN item list preloaded" log precedes PreInit
// start in Eden sessions).
//
// Notify-only - does NOT auto-fix (placement modules' `faction`
// field is single-value, so auto-adding would silently destroy the
// mission-maker's existing choice).
if (is3DEN) then {
    // Event names per BI wiki Arma_3:_Eden_Editor_Event_Handlers
    // (verified valid enum values - earlier guesses like
    // OnConnectionChanged / OnAttributesChanged throw "Unknown enum
    // value" at registration):
    //   OnEntityAttributeChanged - fires when an entity's attribute
    //                              is changed (via dialog OR via
    //                              script commands).
    //   OnConnectingEnd          - fires when user finishes drawing
    //                              a sync connection line between
    //                              two entities.
    //   OnMissionPreview         - fires when user hits Play/Preview
    //                              (last-chance safety net).
    // 500ms debounce inside the validator collapses bursts of these
    // events into one run.
    // CfgFunctions may not be compiled in pure-Eden mode (no scenario
    // = no mission preInit = BI's own CfgFunctions phase may be skipped).
    // Inline-compile the validator here via compile preprocessFileLineNumbers
    // so it's guaranteed available when the EHs fire. CfgFunctions entry
    // still registered for completeness / runtime callers.
    ALiVE_edenFactionValidator = compile preprocessFileLineNumbers "\x\alive\addons\main\fnc_edenValidateOpcomFactions.sqf";
    diag_log format ["ALiVE 3DEN: inline-compiled validator; typeName=%1", typeName ALiVE_edenFactionValidator];

    // EH callbacks scope validation to the OPCOMs actually affected by
    // each event, then hand off to the debounced validator. Without
    // scoping, every sync/attr event triggered a global re-walk and
    // surfaced pre-existing misconfigs on unrelated OPCOMs - confusing
    // feedback when the user's action was on a different OPCOM.
    //
    // Scoping rules per trigger:
    //   sync    - validate only OPCOMs at the endpoints of the changed
    //             connection. If neither endpoint is an OPCOM, skip.
    //   attr    - if the changed entity is an OPCOM, validate just it.
    //             If it's a placement, validate only the OPCOMs the
    //             placement is currently synced to.
    //   preview - empty scope -> validator falls back to global walk
    //             (last-chance safety net before mission load).
    //
    // Each EH passes a trigger tag so the validator can tune output
    // (only "sync" / "attr" emit the green "all OK" toast; "preview"
    // skips green because the user is about to see the mission run).
    //
    // No per-fire diag_log in EH callbacks: OnEntityAttributeChanged
    // fires once per attribute (one OPCOM Save = ~16 calls). The
    // validator's own diag_log (after 500ms debounce) gives exactly one
    // log line per user action.

    // OnEntityAttributeChanged fires on EVERY attribute change including
    // position, rotation, layer reassignment, etc. Filter on property-
    // name containing "faction" first so unrelated edits don't even
    // reach the scope computation:
    //   ALiVE_mil_opcom_factions / factionsManual / faction1..faction4
    //   ALiVE_<placement>_faction
    add3DENEventHandler ["OnEntityAttributeChanged", {
        params ["_entity", "_property"];
        if ((toLower _property) find "faction" < 0) exitWith {};

        // Entity must be part of a sync graph - otherwise the mission-
        // maker is still configuring a standalone module and the pre-
        // sync gate inside the validator would skip it anyway.
        private _syncs = (get3DENConnections _entity) select {(_x select 0) == "Sync"};
        if (count _syncs == 0) exitWith {};

        // Build scope. If entity IS an OPCOM, scope is just that OPCOM.
        // If it's a placement (or any other entity), walk its sync
        // peers and collect the OPCOMs at the other end - those are the
        // OPCOMs whose validation state could have changed.
        private _scope = [];
        if ((typeOf _entity) == "ALiVE_mil_OPCOM") then {
            _scope pushBack _entity;
        } else {
            {
                private _peer = _x select 1;
                if (!isNil "_peer" && {_peer isEqualType objNull} && {!isNull _peer} && {(typeOf _peer) == "ALiVE_mil_OPCOM"}) then {
                    _scope pushBackUnique _peer;
                };
            } forEach _syncs;
        };

        if (count _scope > 0) then {
            ["attr", _scope] call ALiVE_edenFactionValidator;
        };
    }];

    // OnConnectingEnd fires on BOTH connect AND disconnect.
    // Observed parameter structure (A3 2.18):
    //   _this[0] = connection type string ("Sync")
    //   _this[1] = 6-element metadata array (not useful for endpoint recovery)
    //   _this[2] = destination endpoint object (the entity the user dropped on),
    //              or nil on disconnect
    //
    // The DESTINATION is the only reliable endpoint in _this. We infer which
    // OPCOM(s) need revalidation from it:
    //   - destination is an OPCOM      -> scope that OPCOM directly
    //   - destination is a placement   -> walk its sync peers and collect
    //     (or other module-type)          OPCOMs. OnConnectingEnd fires AFTER
    //                                     the connection is established, so
    //                                     the just-drawn edge shows up in
    //                                     get3DENConnections and the source-
    //                                     side OPCOM is reachable from the
    //                                     destination-side peer list.
    //   - destination is nil           -> disconnect action; source endpoint
    //     (disconnect)                    is not recoverable from _this.
    //                                     Skip - the PREVIEW safety net or
    //                                     the next attr/sync action will
    //                                     catch any resulting issue.
    add3DENEventHandler ["OnConnectingEnd", {
        private _dest = _this param [2, objNull];
        if (isNil "_dest") exitWith {};                   // disconnect
        if !(_dest isEqualType objNull) exitWith {};      // unexpected shape
        if (isNull _dest) exitWith {};

        private _scope = [];
        if ((typeOf _dest) == "ALiVE_mil_OPCOM") then {
            _scope pushBack _dest;
        } else {
            // Destination is not an OPCOM - it's the other end of the sync
            // (typically a placement). Walk its current sync connections to
            // find the OPCOM(s) the user just linked it to.
            private _syncs = (get3DENConnections _dest) select {(_x select 0) == "Sync"};
            {
                private _peer = _x select 1;
                if (!isNil "_peer" && {_peer isEqualType objNull} && {!isNull _peer} && {(typeOf _peer) == "ALiVE_mil_OPCOM"}) then {
                    _scope pushBackUnique _peer;
                };
            } forEach _syncs;
        };

        // Skip entirely if the changed connection didn't touch an OPCOM -
        // a sync between two non-OPCOM modules can't affect OPCOM-faction
        // validation.
        if (count _scope > 0) then {
            ["sync", _scope] call ALiVE_edenFactionValidator;
        };
    }];

    // Preview: empty scope -> validator walks every OPCOM in the scene.
    add3DENEventHandler ["OnMissionPreview", { ["preview", []] call ALiVE_edenFactionValidator }];
    diag_log "ALiVE 3DEN: faction-sync validator registered (scoped: OnEntityAttributeChanged + OnConnectingEnd + OnMissionPreview)";
};
