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
                scope = 1;
                displayName = "$STR_ALIVE_ADMINACTIONS";
                function = "ALIVE_fnc_emptyInit";
                author = MODULE_AUTHOR;
                functionPriority = 42;
                isGlobal = 2;
                icon = "x\alive\addons\sys_adminactions\icon_sys_adminactions.paa";
                picture = "x\alive\addons\sys_adminactions\icon_sys_adminactions.paa";
                class Attributes : AttributesBase
                {
                        class ghost : Combo { property = "ALiVE_sys_adminactions_ghost"; displayName = "$STR_ALIVE_ADMINACTIONS_GHOST"; tooltip = "$STR_ALIVE_ADMINACTIONS_GHOST_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class teleport : Combo { property = "ALiVE_sys_adminactions_teleport"; displayName = "$STR_ALIVE_ADMINACTIONS_TELEPORT"; tooltip = "$STR_ALIVE_ADMINACTIONS_TELEPORT_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class mark_units : Combo { property = "ALiVE_sys_adminactions_mark_units"; displayName = "$STR_ALIVE_ADMINACTIONS_MARK_UNITS"; tooltip = "$STR_ALIVE_ADMINACTIONS_MARK_UNITS_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class profile_debug : Combo { property = "ALiVE_sys_adminactions_profile_debug"; displayName = "$STR_ALIVE_ADMINACTIONS_PROFILES_DEBUG"; tooltip = "$STR_ALIVE_ADMINACTIONS_PROFILES_DEBUG_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class profiles_create : Combo { property = "ALiVE_sys_adminactions_profiles_create"; displayName = "$STR_ALIVE_ADMINACTIONS_CREATE_PROFILES"; tooltip = "$STR_ALIVE_ADMINACTIONS_CREATE_PROFILES_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class agent_debug : Combo { property = "ALiVE_sys_adminactions_agent_debug"; displayName = "$STR_ALIVE_ADMINACTIONS_AGENT_DEBUG"; tooltip = "$STR_ALIVE_ADMINACTIONS_AGENT_DEBUG_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class console : Combo { property = "ALiVE_sys_adminactions_console"; displayName = "$STR_ALIVE_ADMINACTIONS_CONSOLE"; tooltip = "$STR_ALIVE_ADMINACTIONS_CONSOLE_COMMENT"; defaultValue = """1"""; class Values { class Yes{name="Yes";value=1;default=1;}; class No{name="No";value=0;}; }; };
                        class ModuleDescription : ModuleDescription {};
                };
                class ModuleDescription
                {
                    description[] = {"$STR_ALIVE_ADMINACTIONS_COMMENT","","$STR_ALIVE_ADMINACTIONS_USAGE"};
                };
        };
};
