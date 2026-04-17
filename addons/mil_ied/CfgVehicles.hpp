class CfgVehicles {
    class Logic;
    class Module_F : Logic
    {
        class AttributesBase { class Edit; class Combo; class ModuleDescription; };
    };
    class ModuleAliveBase : Module_F
    {
        class AttributesBase : AttributesBase { class ALiVE_ModuleSubTitle; };
        class ModuleDescription;
    };
        class ADDON : ModuleAliveBase
        {
                scope = 2;
                displayName = "$STR_ALIVE_ied";
                function = "ALIVE_fnc_iedInit";
                isGlobal = 2;
                isPersistent = 0;
                author = MODULE_AUTHOR;
                functionPriority = 130;
                icon = "x\alive\addons\mil_ied\icon_mil_ied.paa";
                picture = "x\alive\addons\mil_ied\icon_mil_ied.paa";
                class Attributes : AttributesBase
                {
                        // ---- General --------------------------------------------------------
                        class HDR_GENERAL : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_GENERAL"; displayName = "GENERAL"; };
                        class debug : Combo
                        {
                                property = "ALiVE_mil_ied_debug"; displayName = "$STR_ALIVE_IED_DEBUG"; tooltip = "$STR_ALIVE_IED_DEBUG_COMMENT"; defaultValue = """0""";
                                class Values { class Yes { name="Yes"; value=1; }; class No { name="No"; value=0; default=1; }; };
                        };
                        class persistence : Combo
                        {
                                property = "ALiVE_mil_ied_persistence"; displayName = "$STR_ALIVE_IED_PERSISTENCE"; tooltip = "$STR_ALIVE_IED_PERSISTENCE_COMMENT"; defaultValue = """0""";
                                class Values { class Yes { name="Yes"; value=1; }; class No { name="No"; value=0; default=1; }; };
                        };
                        class taor : Edit { property = "ALiVE_mil_ied_taor"; displayName = "$STR_ALIVE_IED_TAOR"; tooltip = "$STR_ALIVE_IED_TAOR_COMMENT"; defaultValue = """"""; };
                        class blacklist : Edit { property = "ALiVE_mil_ied_blacklist"; displayName = "$STR_ALIVE_IED_BLACKLIST"; tooltip = "$STR_ALIVE_IED_BLACKLIST_COMMENT"; defaultValue = """"""; };
                        class AI_Triggerable : Combo
                        {
                                property = "ALiVE_mil_ied_AI_Triggerable"; displayName = "$STR_ALIVE_IED_AI_TRIGGER"; tooltip = "$STR_ALIVE_IED_AI_TRIGGER_COMMENT"; defaultValue = """0""";
                                class Values { class No{name="No";value=0;default=1;}; class Yes{name="Yes";value=1;}; };
                        };
                        class integrationChoice
                        {
                                property    = "ALiVE_mil_ied_integrationChoice";
                                displayName = "Integration";
                                tooltip     = "Who handles IED arming and detonation. The dropdown is populated from Cfg3rdPartyIEDs at Eden-open time - only mods that are actually loaded right now appear. Auto uses the first detected mine-mode integration; Force ALiVE keeps ALiVE's pipeline regardless; Defer to <mod> uses that specific mod's mode. See RPT for detection details at mission start.";
                                control     = "ALiVE_IntegrationChoice";
                                defaultValue = """_auto""";
                        };
                        // ---- IED Threat -----------------------------------------------------
                        class HDR_IED : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_IED"; displayName = "IED THREAT"; };
                        class IED_Threat : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Threat"; displayName = "$STR_ALIVE_ied_IED_Threat"; tooltip = "$STR_ALIVE_ied_IED_Threat_COMMENT"; defaultValue = """0""";
                                class Values { class None{name="None";value=0;default=1;}; class Low{name="Low";value=50;}; class Med{name="Medium";value=100;}; class High{name="High";value=200;}; class Extreme{name="Extreme";value=350;}; };
                        };
                        class IED_Starting_Threat : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Starting_Threat"; displayName = "$STR_ALIVE_ied_IED_Starting_Threat"; tooltip = "$STR_ALIVE_ied_IED_Starting_Threat_COMMENT"; defaultValue = """0""";
                                class Values { class None{name="None";value=0;default=1;}; class Low{name="Low";value=50;}; class Med{name="Medium";value=100;}; class High{name="High";value=200;}; class Extreme{name="Extreme";value=350;}; };
                        };
                        class IED_Detection : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Detection"; displayName = "$STR_ALIVE_ied_IED_Detection"; tooltip = "$STR_ALIVE_ied_IED_Detection_COMMENT"; defaultValue = """1""";
                                class Values { class None{name="None";value=0;}; class Text{name="Text";value=1;default=1;}; class Audio{name="Audio";value=2;}; };
                        };
                        class IED_Detection_Device : Edit { property = "ALiVE_mil_ied_IED_Detection_Device"; displayName = "$STR_ALIVE_IED_IED_Detection_Device"; tooltip = "$STR_ALIVE_IED_IED_Detection_Device_COMMENT"; defaultValue = """MineDetector"""; };
                        // ---- Suicide Bombers ------------------------------------------------
                        class HDR_BOMBER : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_BOMBER"; displayName = "SUICIDE BOMBERS"; };
                        class Bomber_Threat : Combo
                        {
                                property = "ALiVE_mil_ied_Bomber_Threat"; displayName = "$STR_ALIVE_ied_Bomber_Threat"; tooltip = "$STR_ALIVE_ied_Bomber_Threat_COMMENT"; defaultValue = """0""";
                                class Values { class None{name="None";value=0;default=1;}; class Low{name="Low";value=10;}; class Med{name="Medium";value=20;}; class High{name="High";value=30;}; class Extreme{name="Extreme";value=50;}; };
                        };
                        class Bomber_Type : Edit { property = "ALiVE_mil_ied_Bomber_Type"; displayName = "$STR_ALIVE_IED_Bomber_Type"; tooltip = "$STR_ALIVE_IED_BOMBER_TYPE_COMMENT"; defaultValue = """"""; };
                        class Bomber_Vest : Edit { property = "ALiVE_mil_ied_Bomber_Vest"; displayName = "$STR_ALIVE_IED_Bomber_Vest"; tooltip = "$STR_ALIVE_IED_BOMBER_VEST_COMMENT"; defaultValue = """V_ALiVE_Suicide_Vest"""; };
                        // ---- Vehicle-Borne IED ----------------------------------------------
                        class HDR_VBIED : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_VBIED"; displayName = "VEHICLE-BORNE IED"; };
                        class VB_IED_Threat : Combo
                        {
                                property = "ALiVE_mil_ied_VB_IED_Threat"; displayName = "$STR_ALIVE_ied_VB_IED_Threat"; tooltip = "$STR_ALIVE_ied_VB_IED_Threat_COMMENT"; defaultValue = """0""";
                                class Values { class None{name="None";value=0;default=1;}; class Low{name="Low";value=10;}; class Med{name="Medium";value=20;}; class High{name="High";value=50;}; class Extreme{name="Extreme";value=70;}; };
                        };
                        class VB_IED_Side : Combo
                        {
                                property = "ALiVE_mil_ied_VB_IED_Side"; displayName = "$STR_ALIVE_ied_VB_IED_Side"; tooltip = "$STR_ALIVE_ied_VB_IED_Side_COMMENT"; defaultValue = """CIV""";
                                class Values { class Civ{name="CIV";value="CIV";default=1;}; class East{name="EAST";value="EAST";}; class West{name="WEST";value="WEST";}; class Ind{name="IND";value="GUER";}; };
                        };
                        class Locs_IED : Combo
                        {
                                property = "ALiVE_mil_ied_Locs_IED"; displayName = "$STR_ALIVE_ied_Locs_IED"; tooltip = "$STR_ALIVE_ied_Locs_IED_COMMENT"; defaultValue = """0""";
                                class Values { class Random{name="Random";value=0;default=1;}; class Occupied{name="Enemy Occupied";value=1;}; class Unoccupied{name="Unoccupied";value=2;}; };
                        };
                        // ---- Engineer Challenge ---------------------------------------------
                        class HDR_ENGINEER : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_ENGINEER"; displayName = "ENGINEER CHALLENGE"; };
                        class IED_Engineer_Challenge : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Challenge";
                                displayName = "Engineer Challenge";
                                tooltip = "If No, engineers (mine detector / Explosive Specialist / CBA EOD trait) are fully immune to IED proximity detonation (legacy behaviour). If Yes, engineers accumulate trip pressure based on distance, stance, movement speed and skill - careless approach can detonate the IED before they defuse.";
                                defaultValue = """1""";
                                class Values { class No{name="No";value=0;}; class Yes{name="Yes";value=1;default=1;}; };
                        };
                        class IED_Engineer_Trip_Base : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Trip_Base";
                                displayName = "Trip Rate";
                                tooltip = "Base per-tick (0.5s) trip-pressure increment for engineers. Scaled by distance, stance, speed and skill. Higher = IEDs detonate sooner under careless approach.";
                                defaultValue = """0.02""";
                                class Values
                                {
                                        class Gentle { name="Gentle (0.01)"; value=0.01; };
                                        class Default { name="Default (0.02)"; value=0.02; default=1; };
                                        class Aggressive { name="Aggressive (0.04)"; value=0.04; };
                                        class Brutal { name="Brutal (0.08)"; value=0.08; };
                                };
                        };
                        class IED_Engineer_Trip_ThresholdMin : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Trip_ThresholdMin";
                                displayName = "Trip Threshold Min";
                                tooltip = "Lower bound of the per-IED randomized trip threshold. Each IED rolls its own threshold in [Min, Max] on creation. Lower = quicker to trip.";
                                defaultValue = """0.7""";
                                class Values
                                {
                                        class Low { name="Low (0.5)"; value=0.5; };
                                        class Default { name="Default (0.7)"; value=0.7; default=1; };
                                        class High { name="High (1.0)"; value=1.0; };
                                        class VHigh { name="Very High (1.5)"; value=1.5; };
                                };
                        };
                        class IED_Engineer_Trip_ThresholdMax : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Trip_ThresholdMax";
                                displayName = "Trip Threshold Max";
                                tooltip = "Upper bound of the per-IED randomized trip threshold. Must be >= Min; if Max < Min the threshold is constant at Min.";
                                defaultValue = """1.3""";
                                class Values
                                {
                                        class Low { name="Low (1.0)"; value=1.0; };
                                        class Default { name="Default (1.3)"; value=1.3; default=1; };
                                        class High { name="High (1.8)"; value=1.8; };
                                        class VHigh { name="Very High (2.5)"; value=2.5; };
                                };
                        };
                        class IED_Engineer_Decay_Rate : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Decay_Rate";
                                displayName = "Trip Decay Rate";
                                tooltip = "Per-tick (0.5s) decay of accumulated trip pressure once an engineer leaves the IED's proximity radius. Higher = retreating resets pressure faster.";
                                defaultValue = """0.01""";
                                class Values
                                {
                                        class Slow { name="Slow (0.005)"; value=0.005; };
                                        class Default { name="Default (0.01)"; value=0.01; default=1; };
                                        class Fast { name="Fast (0.02)"; value=0.02; };
                                        class Instant { name="Instant (0.05)"; value=0.05; };
                                };
                        };
                        class IED_Engineer_Disarm_BaseTime : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Disarm_BaseTime";
                                displayName = "Disarm Base Time";
                                tooltip = "Seconds required to disarm an IED at skill 1.0 (scales up to 1.5x at skill 0, floored at 50%% of base). The IED remains vulnerable to detonation throughout this window.";
                                defaultValue = """60""";
                                class Values
                                {
                                        class Fast { name="Fast (30s)"; value=30; };
                                        class Default { name="Default (60s)"; value=60; default=1; };
                                        class Slow { name="Slow (90s)"; value=90; };
                                        class VSlow { name="Very Slow (120s)"; value=120; };
                                        class Brutal { name="Brutal (180s)"; value=180; };
                                };
                        };
                        class IED_Engineer_Disarm_NewDeviceBase : Combo
                        {
                                property = "ALiVE_mil_ied_IED_Engineer_Disarm_NewDeviceBase";
                                displayName = "Wire-Guess Threshold";
                                tooltip = "Baseline threshold for the 'new device' wire-guess minigame. Effective trigger rate: ~10%% at skill 1.0, ~25%% at skill 0, clamped [0.70, 0.90]. Lower value = wire-guess fires more often.";
                                defaultValue = """0.75""";
                                class Values
                                {
                                        class Often { name="Often (0.60)"; value=0.60; };
                                        class Default { name="Default (0.75)"; value=0.75; default=1; };
                                        class Rare { name="Rare (0.85)"; value=0.85; };
                                        class VRare { name="Very Rare (0.95)"; value=0.95; };
                                };
                        };
                        // ---- Object Classes -------------------------------------------------
                        class HDR_CLASSES : ALiVE_ModuleSubTitle { property = "ALiVE_mil_ied_HDR_CLASSES"; displayName = "OBJECT CLASSES"; };
                        class roadIEDClasses : Edit { property = "ALiVE_mil_ied_roadIEDClasses"; displayName = "$STR_ALIVE_IED_ROAD_IED_CLASSES"; tooltip = "$STR_ALIVE_IED_CLASSES_COMMENT"; defaultValue = """ALIVE_IEDUrbanSmall_Remote_Ammo,ALIVE_IEDLandSmall_Remote_Ammo,ALIVE_IEDUrbanBig_Remote_Ammo,ALIVE_IEDLandBig_Remote_Ammo"""; };
                        class urbanIEDClasses : Edit { property = "ALiVE_mil_ied_urbanIEDClasses"; displayName = "$STR_ALIVE_IED_URBAN_IED_CLASSES"; tooltip = "$STR_ALIVE_IED_CLASSES_COMMENT"; defaultValue = """ALIVE_IEDUrbanSmall_Remote_Ammo,ALIVE_IEDUrbanBig_Remote_Ammo,Land_JunkPile_F,Land_GarbageContainer_closed_F,Land_GarbageBags_F,Land_Tyres_F,Land_GarbagePallet_F,Land_Basket_F,Land_Sack_F,Land_Sacks_goods_F,Land_Sacks_heap_F,Land_BarrelTrash_F"""; };
                        class clutterClasses : Edit { property = "ALiVE_mil_ied_clutterClasses"; displayName = "$STR_ALIVE_IED_CLUTTER_CLASSES"; tooltip = "$STR_ALIVE_IED_CLASSES_COMMENT"; defaultValue = """Land_JunkPile_F,Land_GarbageContainer_closed_F,Land_GarbageBags_F,Land_Tyres_F,Land_GarbagePallet_F,Land_Basket_F,Land_Sack_F,Land_Sacks_goods_F,Land_Sacks_heap_F,Land_BarrelTrash_F"""; };
                        class ModuleDescription : ModuleDescription {};
                };
        };
        class Thing;
        class ALiVE_IED : Thing { author="ALiVE Mod Team"; _generalMacro="ALiVE_IED"; model="\A3\Weapons_F\empty.p3d"; icon="iconObject"; vehicleClass="Objects"; destrType="DestructTent"; cost=250; ace_minedetector_detectable=1; };
        class ALIVE_IEDUrbanSmall_Remote_Ammo : ALiVE_IED { scope=2; scopeCurator=2; displayName=""; model="\A3\Weapons_F\Explosives\IED_urban_small"; };
        class ALIVE_IEDLandSmall_Remote_Ammo : ALIVE_IEDUrbanSmall_Remote_Ammo { model="\A3\Weapons_F\Explosives\IED_land_small"; };
        class ALIVE_IEDUrbanBig_Remote_Ammo : ALIVE_IEDUrbanSmall_Remote_Ammo { model="\A3\Weapons_F\Explosives\IED_urban_big"; };
        class ALIVE_IEDLandBig_Remote_Ammo : ALIVE_IEDUrbanSmall_Remote_Ammo { model="\A3\Weapons_F\Explosives\IED_land_big"; };
        class ALIVE_DemoCharge_Remote_Ammo : ALIVE_IEDUrbanSmall_Remote_Ammo { model="\A3\Weapons_F\explosives\c4_charge_small"; };
        class ALIVE_SatchelCharge_Remote_Ammo : ALIVE_IEDUrbanSmall_Remote_Ammo { model="\A3\Weapons_F\Explosives\satchel"; };
};
