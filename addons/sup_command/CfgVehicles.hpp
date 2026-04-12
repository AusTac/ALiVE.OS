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
                displayName = "$STR_ALIVE_SCOM";
                function = "ALIVE_fnc_emptyInit";
                functionPriority = 151;
                isGlobal = 2;
                icon = "x\alive\addons\sup_command\icon_sup_command.paa";
                picture = "x\alive\addons\sup_command\icon_sup_command.paa";
                author = MODULE_AUTHOR;
        };
};
