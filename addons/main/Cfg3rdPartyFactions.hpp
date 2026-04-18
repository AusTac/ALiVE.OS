// ----------------------------------------------------------------------------
// Cfg3rdPartyFactions
//
// Optional metadata registry consumed by the shared ALiVE_FactionChoice
// faction dropdown (see fnc_edenFactionChoiceLoad.sqf). Each subclass
// declares a sentinel addon name plus per-faction overrides for entries
// that need polish / correction beyond what auto-detection provides.
//
// THIS REGISTRY DOES NOT ADD FACTIONS TO ALiVE. The dropdown is driven
// by CfgFactionClasses + a structural usability filter (CfgGroups for
// military sides, civilian blacklist for side 3). The registry only
// REFINES what's already there:
//   - hide a faction that passes the structural filter but shouldn't appear
//   - replace an ugly classname-fallback displayName with a curated label
//   - override the auto-detected source-addon suffix in the dropdown label
//
// Faction GROUP SYNTHESIS (making non-conforming factions actually
// spawnable when they ship without CfgGroups) is a separate, future
// effort - see strategy_faction_redirect_and_inference.md in the
// project memory. Phase 2 of mil_placement overhaul is metadata-only.
//
// This class is intentionally open - any addon (a 3rd-party compat PBO,
// a mission-maker's own mod, a future ALiVE release) can extend the
// registry by declaring additional subclasses in its own config.cpp. No
// ALiVE core changes required.
//
// Schema per subclass:
//   cfgPatchesName    (string)  REQUIRED - CfgPatches class name to
//                                          detect. Entry is ignored if
//                                          this addon isn't loaded.
//   displayName       (string)  REQUIRED - human-readable label for logs
//                                          and future UI hints. Doesn't
//                                          appear in the dropdown today.
//   class factions {                       OPTIONAL - per-faction overrides
//       class <FactionClassname> {
//           displayName   (string)  override the displayName shown in
//                                   the dropdown (e.g. clean up an ugly
//                                   "rhs_faction_vdv_45" -> "RHS - 45th
//                                   Guards Brigade").
//           sourceLabel   (string)  override the auto-detected source-
//                                   addon suffix. Use for friendly names
//                                   when configSourceAddonList returns a
//                                   technical token (e.g. "rhsafrf" ->
//                                   "RHS: AFRF") or to consolidate when
//                                   multiple addons contribute to the
//                                   same logical faction.
//           excluded      (number)  set to 1 to hide this faction from
//                                   the dropdown even though it passes
//                                   the structural usability filter.
//                                   Use sparingly - the structural filter
//                                   already catches BI internals like
//                                   Virtual_F / Interactive_F. Reach for
//                                   this when a mod ships a real-looking
//                                   faction that isn't actually meant
//                                   for mission-maker use (sub-faction
//                                   stubs, dummy entries).
//       };
//   };
//
// All faction classnames are matched case-insensitively against
// CfgFactionClasses, so casing in the registry doesn't matter.
// ----------------------------------------------------------------------------

class Cfg3rdPartyFactions {

    // Vanilla A3 baseline. Always-detected (A3_Characters_F is part of
    // the base game). Currently no overrides - vanilla factions display
    // cleanly via auto-detection. Serves as the schema reference and a
    // detection smoke test at module init.
    class ALiVE_Vanilla_A3 {
        cfgPatchesName = "A3_Characters_F";
        displayName    = "Arma 3 (Vanilla)";
        class factions {
            // No overrides currently needed - CIV_F / OPF_F / BLU_F /
            // IND_F all auto-resolve correctly. Add here if a vanilla
            // faction needs displayName / sourceLabel / exclusion polish.
        };
    };

    // RHS: AFRF (Armed Forces of the Russian Federation).
    // Hides rhs_faction_vdv_45 - sub-faction stub with no displayName,
    // shows up as "OPFOR - rhs_faction_vdv_45 (rhsafrf)" in the dropdown
    // which is just noise. Real RHS factions (msv, vdv, vmf, etc.) are
    // unaffected and continue to auto-resolve.
    class RHS_AFRF {
        cfgPatchesName = "rhs_main";
        displayName    = "RHS: AFRF";
        class factions {
            class rhs_faction_vdv_45 {
                excluded = 1;
            };
        };
    };

};
