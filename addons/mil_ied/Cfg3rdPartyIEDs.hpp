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
//                                 "alive"      - full ALiVE pipeline
//                                                (proximity accumulator,
//                                                custom disarm, demo charge
//                                                attached, Disarm IED action).
//                                 "mine"       - placed via createVehicle;
//                                                ALiVE skips arming/disarm and
//                                                delegates detonation to the
//                                                3rd-party system. Inert with
//                                                pressure-mine classes that
//                                                aren't auto-armed - prefer
//                                                "alive" + stompRadius for
//                                                those, or "engineMine" below.
//                                 "passive"    - placed via createVehicle; no
//                                                ALiVE pipeline, no demo
//                                                charge, no Disarm IED action.
//                                                Engine handles damage via
//                                                collision physics. For
//                                                contact-damage traps that
//                                                aren't explosive (e.g. SOG
//                                                Prairie Fire punji sticks).
//                                 "engineMine" - placed via CREATEMINE (not
//                                                createVehicle), so the engine
//                                                arms the object as a real
//                                                mine. No ALiVE pipeline, no
//                                                demo charge, no Disarm IED
//                                                action. For tripwire mines
//                                                and pressure mines that the
//                                                engine should fully manage
//                                                (RHS OZM-72, SOG booby
//                                                traps).
//
//   The placementZ / chargeOffsetZ / stompRadius fields below only apply in
//   "alive" mode. For passive / engineMine they're ignored.
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
//   chargeOffsetZ     (number)  optional - Z offset of the attached
//                                          ALIVE_DemoCharge_Remote_Ammo
//                                          relative to the IED. Default: 0
//                                          (charge sits on top of IED, fine
//                                          for trash-pile visuals). Override
//                                          to negative (e.g. -0.3) for
//                                          visible mine entities so the
//                                          charge is buried out of sight and
//                                          only the mine is visible. The
//                                          shoot-to-detonate damage handler
//                                          is mirrored to the mine itself in
//                                          this case so a buried charge
//                                          doesn't break that path.
//   stompRadius       (number)  optional - distance (m) at which a relevant
//                                          unit (player, or AI when
//                                          AI_Triggerable=Yes) instantly
//                                          triggers the IED, BYPASSING the
//                                          engineer trip-accumulator. Use for
//                                          pressure-mine integrations (RHS
//                                          PMN-2, PFM-1, etc.) where the
//                                          real-world trigger is "step on
//                                          it". Default: 0 (no stomp check;
//                                          accumulator alone). The disarm
//                                          addAction range (3m) is still
//                                          larger than typical stomp radii
//                                          so engineers can defuse from a
//                                          safe stand-off distance.
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
        chargeOffsetZ     = 0;          // charge inside the trash-pile model
        stompRadius       = 0;          // command-detonated, no pressure trigger
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
    // Class selection: modern Russian mines that fit insurgent-IED use.
    // IMPORTANT: only **pressure-activated** mines work with ALiVE's
    // proximity-accumulator trigger model. Tripwire mines (e.g. OZM-72)
    // appear inert because their wire is engine-trigger-driven and Arma
    // only wires that up for createMine, not createVehicle.
    //   roadIEDClasses  - TM-62M anti-tank (pressure) for roadside placement
    //   urbanIEDClasses - PMN-2 anti-personnel (pressure) + PFM-1 butterfly
    //                     (pressure) for foot traffic
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
            "rhs_mine_pfm1"
        };
        clutterClasses[]  = {};   // use ALiVE clutter defaults via lenient fallback
        detonator[]       = {};
        placementZ        = 0;    // surface - RHS mines are visible objects
        chargeOffsetZ     = -0.3; // bury the demo charge below the visible mine
        stompRadius       = 0.6;  // pressure-trigger: stepping on the mine = boom
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
        chargeOffsetZ     = 0;    // charge inside the trash-pile model
        stompRadius       = 0;    // command-detonated, no pressure trigger
    };

    // ------------------------------------------------------------------------
    // SOG Prairie Fire (S.O.G. - Vietnam-era CDLC).
    //
    // SOG splits IED-style content across three CfgPatches:
    //   weapons_f_vietnam_c     - core mines (M14/15/16, TM57, M18 claymore,
    //                             tripwires, satchels, punji sticks)
    //   weapons_f_vietnam_03_c  - improvised IEDs (bike, pot, jerrycan, DH-10,
    //                             cartridge, lighter)
    //   structures_f_vietnam_c  - punji fence terrain props
    // We detect on `weapons_f_vietnam_c` (always loaded with SOG) for all
    // three SOG entries; if `_03_c` is somehow absent the bike/pot/jerrycan
    // createVehicle calls return objNull and the null-IED guard in
    // fnc_createIED handles it silently.
    //
    // Three entries because SOG needs three different runtime semantics:
    //   SOG_Command     - command-detonated _range / _remote variants run
    //                     through the full ALiVE pipeline (charge + accumulator
    //                     + Disarm action). This is the closest match to how
    //                     ALiVE has always worked.
    //   SOG_Mines       - pressure mines and tripwires placed via createMINE
    //                     (engineMine mode) so the engine arms them as proper
    //                     mines. ALiVE skips arming so the engine's pressure /
    //                     tripwire detection actually fires.
    //   SOG_Punji       - punji sticks and punji fences are NON-explosive
    //                     contact-damage hazards. createVehicle places them and
    //                     the engine handles damage on collision. No ALiVE
    //                     pipeline, no demo charge.
    // ------------------------------------------------------------------------

    // SOG: command-detonated improvised IEDs (bike, pot, jerrycan, DH-10
    // directional, M18 claymore range, satchel remote, ammo box booby trap).
    // All classes selected are the `_range` / `_remote` variants that the SOG
    // mod treats as command-detonated - perfect match for ALiVE's accumulator-
    // driven pipeline (the trigger-man "decides" when to detonate based on
    // proximity / damage).
    //
    // Placement is trash-pile style (bury -0.1, charge inside) so the props
    // sit naturally on roads and aren't hovering. ALiVE's clutter spawn doesn't
    // hide these because they're the visual themselves (bike, pot etc.).
    class SOG_Command {
        cfgPatchesName = "weapons_f_vietnam_c";
        displayName    = "SOG Prairie Fire: Command IEDs";
        mode           = "alive";
        roadIEDClasses[] = {
            "vn_mine_bike_range",
            "vn_mine_jerrycan_range",
            "vn_mine_dh10_range"
        };
        urbanIEDClasses[] = {
            "vn_mine_pot_range",
            "vn_mine_ammobox_range",
            "vn_mine_satchel_remote_02",
            "vn_mine_m18_range",
            "vn_mine_m112_remote"
        };
        clutterClasses[]  = {};
        detonator[]       = {};
        placementZ        = -0.1;
        chargeOffsetZ     = 0;
        stompRadius       = 0;
    };

    // SOG: pressure mines + tripwire mines, placed via createMine so the
    // engine arms them. ALiVE pipeline is skipped entirely (no charge attached,
    // no Disarm IED action, no accumulator) - the engine's built-in mine
    // trigger logic handles detection and detonation.
    //
    // Anti-tank pressure mines (TM-57, M15) -> road pool.
    // Anti-personnel pressure (M14, M16) + tripwires (M16/F1/M49 frag, arty,
    // mortar) + booby-trap pickups (lighter, board with nails) -> urban pool.
    //
    // placementZ / chargeOffsetZ / stompRadius are all ignored in engineMine
    // mode (engine handles trigger + visual placement). Defaults left at 0
    // for clarity.
    class SOG_Mines {
        cfgPatchesName = "weapons_f_vietnam_c";
        displayName    = "SOG Prairie Fire: Mines & Tripwires";
        mode           = "engineMine";
        roadIEDClasses[] = {
            "vn_mine_tm57",
            "vn_mine_m15"
        };
        urbanIEDClasses[] = {
            "vn_mine_m14",
            "vn_mine_m16",
            "vn_mine_tripwire_m16_02",
            "vn_mine_tripwire_m16_04",
            "vn_mine_tripwire_f1_02",
            "vn_mine_tripwire_f1_04",
            "vn_mine_tripwire_arty",
            "vn_mine_tripwire_m49_02",
            "vn_mine_tripwire_m49_04",
            "vn_mine_tripwire_mortar",
            "vn_mine_gboard",
            "vn_mine_lighter"
        };
        clutterClasses[]  = {};
        detonator[]       = {};
        placementZ        = 0;
        chargeOffsetZ     = 0;
        stompRadius       = 0;
    };

    // SOG: punji sticks + punji fences. NON-EXPLOSIVE contact-damage hazards
    // (sharpened bamboo) - the engine handles damage on collision via the
    // model itself. Placed via createVehicle (passive mode) with no ALiVE
    // pipeline whatsoever: no arm, no charge, no Disarm action, no marker
    // (these are area-denial obstacles, not detonating IEDs).
    //
    // All assigned to urban pool because they're jungle-path / perimeter
    // hazards that fit infantry-traffic areas, not vehicle roads.
    //
    // Land_vn_fence_punji_* are terrain props from structures_f_vietnam_c -
    // included here because they serve the same role (passive contact damage)
    // and this entry's mode handles them correctly.
    class SOG_Punji {
        cfgPatchesName = "weapons_f_vietnam_c";
        displayName    = "SOG Prairie Fire: Punji Hazards";
        mode           = "passive";
        roadIEDClasses[] = {};
        urbanIEDClasses[] = {
            "vn_mine_punji_01",
            "vn_mine_punji_02",
            "vn_mine_punji_03",
            "vn_mine_punji_04",
            "vn_mine_punji_05",
            "Land_vn_fence_punji_01_03",
            "Land_vn_fence_punji_01_05",
            "Land_vn_fence_punji_01_10",
            "Land_vn_fence_punji_02_03",
            "Land_vn_fence_punji_02_05",
            "Land_vn_fence_punji_02_10"
        };
        clutterClasses[]  = {};
        detonator[]       = {};
        placementZ        = 0;
        chargeOffsetZ     = 0;
        stompRadius       = 0;
    };

};
