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
                displayName = "$STR_ALIVE_spotrep";
                function = "ALIVE_fnc_emptyInit";
                functionPriority = 43;
                isGlobal = 2;
                icon = "x\alive\addons\sys_spotrep\icon_sys_spotrep.paa";
                picture = "x\alive\addons\sys_spotrep\icon_sys_spotrep.paa";
                author = MODULE_AUTHOR;
        };
};
