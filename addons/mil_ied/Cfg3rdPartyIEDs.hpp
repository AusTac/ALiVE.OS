// ----------------------------------------------------------------------------
// Cfg3rdPartyIEDs
//
// Registry of 3rd-party IED integrations that ALiVE's mil_ied module should
// recognise at runtime. The module walks this class at init, keeps only the
// entries whose `cfgPatchesName` is actually loaded (via
// `isClass (configFile >> "CfgPatches" >> cfgPatchesName)`), and can merge
// the declared class lists into the runtime IED pools.
//
// This class is intentionally open - ANY addon (a 3rd-party compat PBO, a
// mission-maker's own mod, or a future ALiVE release) can extend the
// registry by declaring additional subclasses in its own config.cpp. No
// ALiVE core changes required.
//
// Schema per subclass:
//   cfgPatchesName    (string)  REQUIRED - CfgPatches class name to detect.
//   displayName       (string)  REQUIRED - human-readable label for logs and UI.
//   mode              (string)  REQUIRED - runtime arming semantics:
//                                 "alive" - full ALiVE pipeline (proximity
//                                           accumulator, custom disarm etc.)
//                                 "mine"  - Arma mineActive semantics;
//                                           ALiVE skips arming/disarm and
//                                           delegates detonation to the
//                                           3rd-party system.
//   roadIEDClasses[]  (array)   optional - classes to append to the road
//                                          IED pool when this integration
//                                          is active.
//   urbanIEDClasses[] (array)   optional - classes to append to the urban
//                                          IED pool when this integration
//                                          is active.
//   clutterClasses[]  (array)   optional - classes to append to the clutter
//                                          pool when this integration is
//                                          active.
//   detonator[]       (array)   optional - magazine/ammo classes used for
//                                          detonation - reserved for future
//                                          disarm/recovery logic.
//   placementZ        (number)  optional - vertical placement offset for the
//                                          IED entity. Default: -0.1 (buried,
//                                          matches ALiVE's classic
//                                          trash-pile-with-bomb-inside look).
//                                          Override to 0 / +0.05 for visible
//                                          mine entities (RHS, etc.) so they
//                                          aren't hidden under terrain.
//
// Phase-1 note: the arrays above are defined for forward compatibility but
// are not yet consumed by the placement pipeline. The Object Classes merge
// work is Phase 3 of the auto-detection strategy. For now this registry is
// used for detection + logging only.
// ----------------------------------------------------------------------------

class Cfg3rdPartyIEDs {

    // Baseline vanilla Arma 3 entry. Always detected (A3_Weapons_F_Explosives
    // is part of the base game so isClass always returns true). Serves as:
    //   - a reference schema example for community extensions,
    //   - a detection smoke test at init time,
    //   - documentation that ALiVE's compile-time default class lists
    //     already cover the vanilla case (so no class arrays needed here).
    class ALiVE_Vanilla_A3 {
        cfgPatchesName = "A3_Weapons_F_Explosives";
        displayName    = "Arma 3 (Vanilla)";
        mode           = "alive";
        roadIEDClasses[]  = {};
        urbanIEDClasses[] = {};
        clutterClasses[]  = {};
        detonator[]       = {};
        placementZ        = -0.1;       // bury (trash-pile look)
    };

    // RHS: AFRF (Armed Forces of the Russian Federation).
    // Detection key is `rhs_main`, the AFRF core addon. Other RHS variants
    // (USAF / GREF / SAF) each have their own cfgPatches name and would
    // get their own registry entries; this one is just AFRF.
    //
    // mode = "alive" - RHS mines are pressure-triggered and Arma's
    // createVehicle does NOT auto-arm them (createMine would, but ALiVE
    // doesn't use that path). In "mine" mode they sit inert: no Arma
    // detonation, no ACE/vanilla defuse hook recognition. So instead we
    // run them through ALiVE's full pipeline:
    //   - armIED attaches a damage-sensitive demo charge to the RHS mine
    //   - proximity-loop trip accumulator handles approach detection
    //   - Disarm IED addAction + skill-scaled wire-guess minigame for defuse
    //   - Detonation creates a separate shell explosion via ALiVE
    // The RHS mine becomes a visual anchor; ALiVE drives all behaviour.
    // The Z=-0.1 bury that ALiVE applies to its own IEDs also applies to
    // these, so the mine sits half-buried under ALiVE clutter (camouflage).
    //
    // Class selection: modern Russian mines that fit insurgent-IED use:
    //   roadIEDClasses  - TM-62M anti-tank for roadside placement
    //   urbanIEDClasses - PMN-2 anti-personnel + OZM-72 bouncing AP for
    //                     foot traffic / urban
    // All are placeable entities (no _module / _used / _mag suffix).
    //
    // Note: ACE is also loaded as mode=mine; my resolver picks the FIRST
    // mine-mode match under Auto. Since RHS is mode=alive, Auto won't pick
    // it as a candidate even when iChoice=_auto. Use the dropdown's
    // "Defer to: RHS: AFRF" to explicitly select this entry.
    class RHS_AFRF {
        cfgPatchesName = "rhs_main";
        displayName    = "RHS: AFRF";
        mode           = "alive";
        roadIEDClasses[] = {
            "rhs_mine_tm62m"
        };
        urbanIEDClasses[] = {
            "rhs_mine_pmn2",
            "rhs_mine_ozm72_a"
        };
        clutterClasses[]  = {};   // use ALiVE clutter defaults via lenient fallback
        detonator[]       = {};
        placementZ        = 0;    // surface - RHS mines are visible objects
    };

    // ACE 3 Explosives - IED/mine classes and detonation use ACE's explosives
    // framework (triggers, range cards, defuse interaction wheel) which maps
    // better to Arma's mineActive semantics than to ALiVE's
    // proximity-accumulator pipeline.
    //
    // ACE 3 doesn't define its own ACE_IED_* classes; instead it adds
    // interaction-wheel handlers to the vanilla A3 IED ammo classes when
    // `ace_explosives` is loaded. So we populate the pools with the vanilla
    // A3 IED classes - placing those means ACE's defuse UI will fire on them.
    //
    // (ALiVE's own ALIVE_IED* classes inherit from Thing, not from MineBase,
    // so they wouldn't trigger ACE's mine interactions even with this entry
    // loaded. That's why this entry uses the vanilla A3 names instead.)
    class ACE_Explosives {
        cfgPatchesName = "ace_explosives";
        displayName    = "ACE 3 Explosives";
        mode           = "mine";
        roadIEDClasses[] = {
            "IEDLandSmall_Remote_Ammo",
            "IEDLandBig_Remote_Ammo"
        };
        urbanIEDClasses[] = {
            "IEDUrbanSmall_Remote_Ammo",
            "IEDUrbanBig_Remote_Ammo"
        };
        clutterClasses[]  = {};   // use ALiVE clutter defaults via lenient fallback
        detonator[]       = {};
        placementZ        = -0.1; // bury slightly (vanilla A3 IED visuals are trash piles)
    };

};
