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
                displayName = "$STR_ALIVE_AMBCP";
                function = "ALIVE_fnc_AMBCPInit";
                author = MODULE_AUTHOR;
                functionPriority = 80;
                isGlobal = 1;
                icon = "x\alive\addons\amb_civ_placement\icon_civ_AMBCP.paa";
                picture = "x\alive\addons\amb_civ_placement\icon_civ_AMBCP.paa";
                class Attributes : AttributesBase
                {
                        class debug : Combo { property = "ALiVE_amb_civ_placement_debug"; displayName = "$STR_ALIVE_AMBCP_DEBUG"; tooltip = "$STR_ALIVE_AMBCP_DEBUG_COMMENT"; defaultValue = """false"""; class Values { class Yes{name="Yes";value=true;}; class No{name="No";value=false;default=1;}; }; };
                        class taor : Edit { property = "ALiVE_amb_civ_placement_taor"; displayName = "$STR_ALIVE_AMBCP_TAOR"; tooltip = "$STR_ALIVE_AMBCP_TAOR_COMMENT"; defaultValue = """"""; };
                        class blacklist : Edit { property = "ALiVE_amb_civ_placement_blacklist"; displayName = "$STR_ALIVE_AMBCP_BLACKLIST"; tooltip = "$STR_ALIVE_AMBCP_BLACKLIST_COMMENT"; defaultValue = """"""; };
                        class sizeFilter : Combo
                        {
                                property = "ALiVE_amb_civ_placement_sizeFilter";
                                displayName = "$STR_ALIVE_AMBCP_SIZE_FILTER";
                                tooltip = "$STR_ALIVE_AMBCP_SIZE_FILTER_COMMENT";
                                defaultValue = """250""";
                                class Values
                                {
                                    class NONE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_NONE"; value = "0"; };
                                    class VERYSMALL { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_VERYSMALL"; value = "160"; };
                                    class SMALL { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_SMALL"; value = "250"; default = 1; };
                                    class MEDIUM { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_MEDIUM"; value = "400"; };
                                    class LARGE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_LARGE"; value = "700"; };
                                    class VERYSMALL_INVERSE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_VERYSMALL_INVERSE"; value = "-160"; };
                                    class SMALL_INVERSE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_SMALL_INVERSE"; value = "-250"; };
                                    class MEDIUM_INVERSE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_MEDIUM_INVERSE"; value = "-400"; };
                                    class LARGE_INVERSE { name = "$STR_ALIVE_AMBCP_SIZE_FILTER_LARGE_INVERSE"; value = "-700"; };
                                };
                        };
                        class priorityFilter : Combo
                        {
                                property = "ALiVE_amb_civ_placement_priorityFilter";
                                displayName = "$STR_ALIVE_AMBCP_PRIORITY_FILTER";
                                tooltip = "$STR_ALIVE_AMBCP_PRIORITY_FILTER_COMMENT";
                                defaultValue = """0""";
                                class Values
                                {
                                    class NONE { name = "$STR_ALIVE_AMBCP_PRIORITY_FILTER_NONE"; value = "0"; default = 1; };
                                    class LOW { name = "$STR_ALIVE_AMBCP_PRIORITY_FILTER_LOW"; value = "10"; };
                                    class MEDIUM { name = "$STR_ALIVE_AMBCP_PRIORITY_FILTER_MEDIUM"; value = "30"; };
                                    class HIGH { name = "$STR_ALIVE_AMBCP_PRIORITY_FILTER_HIGH"; value = "40"; };
                                };
                        };
                        class faction : Edit { property = "ALiVE_amb_civ_placement_faction"; displayName = "$STR_ALIVE_AMBCP_FACTION"; tooltip = "$STR_ALIVE_AMBCP_FACTION_COMMENT"; defaultValue = """CIV_F"""; };
                        class placementMultiplier : Combo
                        {
                                property = "ALiVE_amb_civ_placement_placementMultiplier";
                                displayName = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER";
                                tooltip = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER_COMMENT";
                                defaultValue = """0.5""";
                                class Values
                                {
                                    class LOW { name = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER_LOW"; value = "0.5"; default = 1; };
                                    class MEDIUM { name = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER_MEDIUM"; value = "1"; };
                                    class HIGH { name = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER_HIGH"; value = "1.5"; };
                                    class EXTREME { name = "$STR_ALIVE_AMBCP_PLACEMENT_MULTIPLIER_EXTREME"; value = "4"; };
                                };
                        };
                        class ambientVehicleAmount : Combo
                        {
                                property = "ALiVE_amb_civ_placement_ambientVehicleAmount";
                                displayName = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT";
                                tooltip = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT_COMMENT";
                                defaultValue = """0.2""";
                                class Values
                                {
                                    class NONE { name = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT_NONE"; value = "0"; };
                                    class LOW { name = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT_LOW"; value = "0.2"; default = 1; };
                                    class MEDIUM { name = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT_MEDIUM"; value = "0.6"; };
                                    class HIGH { name = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_AMOUNT_HIGH"; value = "1"; };
                                };
                        };
                        class ambientVehicleFaction : Edit { property = "ALiVE_amb_civ_placement_ambientVehicleFaction"; displayName = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_FACTION"; tooltip = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_FACTION_COMMENT"; defaultValue = """CIV_F"""; };
                        class initialdamage : Combo { property = "ALiVE_amb_civ_placement_initialdamage"; displayName = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_DAM"; tooltip = "$STR_ALIVE_AMBCP_AMBIENT_VEHICLE_DAM_COMMENT"; defaultValue = """false"""; class Values { class No{name="No";value=false;default=1;}; class Yes{name="Yes";value=true;}; }; };
                        class ModuleDescription : ModuleDescription {};
                };
                class ModuleDescription
                {
                    description[] = {"$STR_ALIVE_AMBCP_COMMENT","","$STR_ALIVE_AMBCP_USAGE"};
                    sync[] = {"ALiVE_mil_OPCOM","ALiVE_mil_CQB"};
                    class ALiVE_mil_OPCOM { description[] = {"$STR_ALIVE_OPCOM_COMMENT","","$STR_ALIVE_OPCOM_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                    class ALiVE_mil_CQB { description[] = {"$STR_ALIVE_CQB_COMMENT","","$STR_ALIVE_CQB_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                };
        };
};
