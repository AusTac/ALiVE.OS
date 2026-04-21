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

    // EH callbacks are lean - validator itself handles debounce + logging.
    // No per-fire diag_log here because OnEntityAttributeChanged fires
    // once per attribute (an OPCOM Save triggers ~16 calls), which
    // would drown the RPT.
    //
    // Each EH passes a trigger tag to the validator; the validator uses
    // it to decide whether to emit a positive "sync OK" green toast
    // (only on "sync" trigger) vs just a silent OK log.
    //
    // OnEntityAttributeChanged fires on EVERY attribute change including
    // position (module moves), rotation, layer reassignment, etc. Without
    // a filter the validator would re-run every time a mission-maker
    // nudges a module. Gate on property-name containing "faction" so
    // only the relevant attributes trigger:
    //   ALiVE_mil_opcom_factions / factionsManual / faction1..faction4
    //   ALiVE_<placement>_faction
    // Sync/preview triggers always fire - sync change is inherently
    // faction-relevant and preview is the last-chance safety net.
    add3DENEventHandler ["OnEntityAttributeChanged", {
        params ["_entity", "_property"];
        if ((toLower _property) find "faction" >= 0) then {
            // Only fire the validator if the changed entity is part of a
            // sync graph. Otherwise the mission-maker is configuring a
            // standalone module that's not wired to anything yet; the
            // validator's pre-sync gate would skip it anyway, but running
            // on every attribute edit of an unsynced module wastes cycles
            // and pollutes the RPT with "OK (checked=0)" noise.
            private _syncs = (get3DENConnections _entity) select {(_x select 0) == "Sync"};
            if (count _syncs > 0) then {
                ["attr"] call ALiVE_edenFactionValidator;
            };
        };
    }];
    add3DENEventHandler ["OnConnectingEnd",  { ["sync"]    call ALiVE_edenFactionValidator }];
    add3DENEventHandler ["OnMissionPreview", { ["preview"] call ALiVE_edenFactionValidator }];
    diag_log "ALiVE 3DEN: faction-sync validator registered (OnEntityAttributeChanged + OnConnectingEnd + OnMissionPreview)";
};
