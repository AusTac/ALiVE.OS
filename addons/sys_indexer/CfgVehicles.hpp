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
                displayName = "$STR_ALIVE_INDEXER";
                function = "ALIVE_fnc_indexerInit";
                functionPriority = 1;
                isGlobal = 1;
                isPersistent = 1;
                icon = "x\alive\addons\sys_indexer\icon_sys_indexer.paa";
                picture = "x\alive\addons\sys_indexer\icon_sys_indexer.paa";
                class Attributes : AttributesBase
                {
                        class customStatic : Combo
                        {
                                property = "ALiVE_sys_indexer_customStatic";
                                displayName = "$STR_ALIVE_INDEXER_STATICDATA";
                                tooltip = "$STR_ALIVE_INDEXER_STATICDATA_COMMENT";
                                defaultValue = """1""";
                                class Values
                                {
                                    class Yes { name = "Yes"; value = 1; default = 1; };
                                    class No { name = "No"; value = 0; };
                                };
                        };
                        class mapPath : Edit
                        {
                                property = "ALiVE_sys_indexer_mapPath";
                                displayName = "$STR_ALIVE_INDEXER_MAPPATH";
                                tooltip = "$STR_ALIVE_INDEXER_MAPPATH_COMMENT";
                                defaultValue = """@CustomMap\Addons\custom_map.pbo""";
                        };
                        class customMapBound : Edit
                        {
                                property = "ALiVE_sys_indexer_customMapBound";
                                displayName = "$STR_ALIVE_INDEXER_MAPBOUND";
                                tooltip = "$STR_ALIVE_INDEXER_MAPBOUND_COMMENT";
                                defaultValue = """0""";
                                typeName = "NUMBER";
                        };
                        class OS : Combo
                        {
                                property = "ALiVE_sys_indexer_OS";
                                displayName = "$STR_ALIVE_INDEXER_OS";
                                tooltip = "$STR_ALIVE_INDEXER_OS_COMMENT";
                                defaultValue = """0""";
                                class Values
                                {
                                    class Win7 { name = "Windows 7"; value = 0; default = 1; };
                                    class Win10 { name = "Windows 10"; value = 1; };
                                };
                        };
                        class ModuleDescription : ModuleDescription {};
                };
        };
};
