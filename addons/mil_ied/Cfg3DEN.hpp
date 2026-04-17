// ----------------------------------------------------------------------------
// Cfg3DEN custom attribute controls for mil_ied
//
// ALiVE_IntegrationChoice:
//   Dynamic Combo attribute whose items are populated at Eden-panel-open
//   time from two sources:
//     1. Two special meta-choices always present:
//          "_auto"         -> "Auto (detect)"
//          "_force_alive"  -> "Force ALiVE handling"
//     2. One "Defer to: <displayName>" item per Cfg3rdPartyIEDs entry whose
//        cfgPatchesName addon is actually loaded right now (isClass CfgPatches
//        check). The ALiVE_Vanilla_A3 baseline entry is hidden from the
//        dropdown since it's always present and not a meaningful authority.
//
//   Stored attribute value is the string data token:
//     "_auto", "_force_alive", or a registry className (e.g. "ACE_Explosives").
//
//   The runtime resolver in fnc_IED.sqf reads the stored choice and picks
//   "alive" or "mine" accordingly; if the user saved a choice for a mod
//   they've since unloaded, the resolver falls back to the Auto rule with
//   a diag_log warning.
//
//   attributeLoad / attributeSave live in separate .sqf files so the config
//   preprocessor isn't asked to cope with multi-line strings (which fail
//   with "Mismatched or missing quotes" on Windows CRLF).
// ----------------------------------------------------------------------------

class Cfg3DEN {
    class Attributes {
        class Combo; // BI's Combo base class - forward declaration
        class ALiVE_IntegrationChoice: Combo {
            attributeLoad = "_this call ALIVE_fnc_edenIntegrationChoiceLoad";
            attributeSave = "_this call ALIVE_fnc_edenIntegrationChoiceSave";
        };
    };
};
