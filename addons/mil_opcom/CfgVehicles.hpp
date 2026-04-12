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
                displayName = "$STR_ALIVE_OPCOM";
                function = "ALIVE_fnc_OPCOMInit";
                author = MODULE_AUTHOR;
                functionPriority = 180;
                isGlobal = 1;
                icon = "x\alive\addons\mil_opcom\icon_mil_opcom.paa";
                picture = "x\alive\addons\mil_opcom\icon_mil_opcom.paa";
                class Attributes : AttributesBase
                {
                        // ---- General --------------------------------------------------------
                        class HDR_GENERAL : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_GENERAL"; displayName = "GENERAL"; };
                        class debug : Combo
                        {
                                property = "ALiVE_mil_opcom_debug";
                                displayName = "$STR_ALIVE_OPCOM_DEBUG";
                                tooltip = "$STR_ALIVE_OPCOM_DEBUG_COMMENT";
                                defaultValue = """false""";
                                class Values
                                {
                                    class Yes { name = "Yes"; value = true; };
                                    class No { name = "No"; value = false; default = 1; };
                                };
                        };
                        class persistent : Combo
                        {
                                property = "ALiVE_mil_opcom_persistent";
                                displayName = "$STR_ALIVE_OPCOM_PERSISTENT";
                                tooltip = "$STR_ALIVE_OPCOM_PERSISTENT_COMMENT";
                                defaultValue = """false""";
                                class Values
                                {
                                    class No { name = "No"; value = false; default = 1; };
                                    class Yes { name = "Yes"; value = true; };
                                };
                        };
                        class customName : Edit
                        {
                                property = "ALiVE_mil_opcom_customName";
                                displayName = "$STR_ALIVE_OPCOM_NAME";
                                tooltip = "$STR_ALIVE_OPCOM_NAME_COMMENT";
                                defaultValue = """""";
                        };

                        // ---- Control Type ---------------------------------------------------
                        class HDR_CONTROL : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_CONTROL"; displayName = "CONTROL TYPE"; };
                        class controltype : Combo
                        {
                                property = "ALiVE_mil_opcom_controltype";
                                displayName = "$STR_ALIVE_OPCOM_CONTROLTYPE";
                                tooltip = "$STR_ALIVE_OPCOM_CONTROLTYPE_COMMENT";
                                defaultValue = """invasion""";
                                class Values
                                {
                                    class invasion { name = "Invasion"; value = "invasion"; default = 1; };
                                    class occupation { name = "Occupation"; value = "occupation"; };
                                    class asymmetric { name = "Asymmetric"; value = "asymmetric"; };
                                };
                        };
                        class asym_occupation : Combo
                        {
                                property = "ALiVE_mil_opcom_asym_occupation";
                                displayName = "$STR_ALIVE_OPCOM_OCCUPATION";
                                tooltip = "$STR_ALIVE_OPCOM_OCCUPATION_COMMENT";
                                defaultValue = """-100""";
                                class Values
                                {
                                    class unused { name = "Unused"; value = -100; default = 1; };
                                    class low { name = "Low"; value = 25; };
                                    class medium { name = "Medium"; value = 50; };
                                    class high { name = "High"; value = 75; };
                                    class extreme { name = "Extreme"; value = 100; };
                                };
                        };
                        class roadblocks : Combo
                        {
                                property = "ALiVE_mil_opcom_roadblocks";
                                displayName = "$STR_ALIVE_OPCOM_ROADBLOCKS";
                                tooltip = "$STR_ALIVE_OPCOM_ROADBLOCKS_COMMENT";
                                defaultValue = """1""";
                                class Values
                                {
                                    class Yes { name = "Yes"; value = 1; default = 1; };
                                    class No { name = "No"; value = 0; };
                                };
                        };
                        class reinforcements : Combo
                        {
                                property = "ALiVE_mil_opcom_reinforcements";
                                displayName = "$STR_ALIVE_OPCOM_REINFORCEMENTS";
                                tooltip = "$STR_ALIVE_OPCOM_REINFORCEMENTS_COMMENT";
                                defaultValue = """0.9""";
                                class Values
                                {
                                    class Constant { name = "Constant"; value = "0.9"; default = 1; };
                                    class Blocked { name = "Packets"; value = "0.75"; };
                                    class Seldom { name = "Seldom"; value = "0.5"; };
                                };
                        };
                        class intelchance : Combo
                        {
                                property = "ALiVE_mil_opcom_intelchance";
                                displayName = "$STR_ALIVE_OPCOM_INTELCHANCE";
                                tooltip = "$STR_ALIVE_OPCOM_INTELCHANCE_COMMENT";
                                defaultValue = """0""";
                                class Values
                                {
                                    class none { name = "None"; value = 0; default = 1; };
                                    class seldom { name = "seldom"; value = 5; };
                                    class often { name = "often"; value = 10; };
                                };
                        };

                        // ---- Factions -------------------------------------------------------
                        class HDR_FACTIONS : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_FACTIONS"; displayName = "FACTIONS"; };
                        class faction1 : Combo
                        {
                                property = "ALiVE_mil_opcom_faction1";
                                displayName = "$STR_ALIVE_OPCOM_FACTION";
                                tooltip = "$STR_ALIVE_OPCOM_FACTION_COMMENT";
                                defaultValue = """BLU_F""";
                                class Values
                                {
                                    class NATO { name = "NATO"; value = "BLU_F"; default = 1; };
                                    class NATOPACIFIC { name = "NATO (Pacific)"; value = "BLU_T_F"; };
                                    class NATO_CTRG { name = "NATO (CTRG)"; value = "BLU_CTRG_F"; };
                                    class IRAN { name = "CSAT"; value = "OPF_F"; };
                                    class IRANPACIFIC { name = "CSAT (Pacific)"; value = "OPF_T_F"; };
                                    class GREEKARMY { name = "AAF"; value = "IND_F"; };
                                    class SYNDIKAT { name = "Syndikat"; value = "IND_C_F"; };
                                    class REBELS_BLU { name = "REBELS BLU"; value = "BLU_G_F"; };
                                    class REBELS_OPF { name = "REBELS RED"; value = "OPF_G_F"; };
                                    class NONE { name = "NONE"; value = "NONE"; };
                                };
                        };
                        class faction2 : Combo
                        {
                                property = "ALiVE_mil_opcom_faction2";
                                displayName = "$STR_ALIVE_OPCOM_FACTION";
                                tooltip = "$STR_ALIVE_OPCOM_FACTION_COMMENT";
                                defaultValue = """NONE""";
                                class Values
                                {
                                    class NATO { name = "NATO"; value = "BLU_F"; };
                                    class NATOPACIFIC { name = "NATO (Pacific)"; value = "BLU_T_F"; };
                                    class NATO_CTRG { name = "NATO (CTRG)"; value = "BLU_CTRG_F"; };
                                    class IRAN { name = "CSAT"; value = "OPF_F"; };
                                    class IRANPACIFIC { name = "CSAT (Pacific)"; value = "OPF_T_F"; };
                                    class GREEKARMY { name = "AAF"; value = "IND_F"; };
                                    class SYNDIKAT { name = "Syndikat"; value = "IND_C_F"; };
                                    class REBELS_BLU { name = "REBELS BLU"; value = "BLU_G_F"; };
                                    class REBELS_OPF { name = "REBELS RED"; value = "OPF_G_F"; };
                                    class NONE { name = "NONE"; value = "NONE"; default = 1; };
                                };
                        };
                        class faction3 : Combo
                        {
                                property = "ALiVE_mil_opcom_faction3";
                                displayName = "$STR_ALIVE_OPCOM_FACTION";
                                tooltip = "$STR_ALIVE_OPCOM_FACTION_COMMENT";
                                defaultValue = """NONE""";
                                class Values
                                {
                                    class NATO { name = "NATO"; value = "BLU_F"; };
                                    class NATOPACIFIC { name = "NATO (Pacific)"; value = "BLU_T_F"; };
                                    class NATO_CTRG { name = "NATO (CTRG)"; value = "BLU_CTRG_F"; };
                                    class IRAN { name = "CSAT"; value = "OPF_F"; };
                                    class IRANPACIFIC { name = "CSAT (Pacific)"; value = "OPF_T_F"; };
                                    class GREEKARMY { name = "AAF"; value = "IND_F"; };
                                    class SYNDIKAT { name = "Syndikat"; value = "IND_C_F"; };
                                    class REBELS_BLU { name = "REBELS BLU"; value = "BLU_G_F"; };
                                    class REBELS_OPF { name = "REBELS RED"; value = "OPF_G_F"; };
                                    class NONE { name = "NONE"; value = "NONE"; default = 1; };
                                };
                        };
                        class faction4 : Combo
                        {
                                property = "ALiVE_mil_opcom_faction4";
                                displayName = "$STR_ALIVE_OPCOM_FACTION";
                                tooltip = "$STR_ALIVE_OPCOM_FACTION_COMMENT";
                                defaultValue = """NONE""";
                                class Values
                                {
                                    class NATO { name = "NATO"; value = "BLU_F"; };
                                    class NATOPACIFIC { name = "NATO (Pacific)"; value = "BLU_T_F"; };
                                    class NATO_CTRG { name = "NATO (CTRG)"; value = "BLU_CTRG_F"; };
                                    class IRAN { name = "CSAT"; value = "OPF_F"; };
                                    class IRANPACIFIC { name = "CSAT (Pacific)"; value = "OPF_T_F"; };
                                    class GREEKARMY { name = "AAF"; value = "IND_F"; };
                                    class SYNDIKAT { name = "Syndikat"; value = "IND_C_F"; };
                                    class REBELS_BLU { name = "REBELS BLU"; value = "BLU_G_F"; };
                                    class REBELS_OPF { name = "REBELS RED"; value = "OPF_G_F"; };
                                    class NONE { name = "NONE"; value = "NONE"; default = 1; };
                                };
                        };
                        class factions : Edit
                        {
                                property = "ALiVE_mil_opcom_factions";
                                displayName = "$STR_ALIVE_OPCOM_FACTIONS";
                                tooltip = "$STR_ALIVE_OPCOM_FACTIONS_COMMENT";
                                defaultValue = """""";
                        };

                        // ---- Objectives & Recruitment ----------------------------------------
                        class HDR_OBJ : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_OBJ"; displayName = "OBJECTIVES & RECRUITMENT"; };
                        class simultanObjectives : Edit
                        {
                                property = "ALiVE_mil_opcom_simultanObjectives";
                                displayName = "$STR_ALIVE_OPCOM_SIMULTAN";
                                tooltip = "$STR_ALIVE_OPCOM_SIMULTAN_COMMENT";
                                defaultValue = """10""";
                                typeName = "NUMBER";
                        };
                        class minAgents : Edit
                        {
                                property = "ALiVE_mil_opcom_minAgents";
                                displayName = "$STR_ALIVE_OPCOM_MINAGENTS";
                                tooltip = "$STR_ALIVE_OPCOM_MINAGENTS_COMMENT";
                                defaultValue = """2""";
                                typeName = "NUMBER";
                        };
                        class asymForceLimit : Edit
                        {
                                property = "ALiVE_mil_opcom_asymForceLimit";
                                displayName = "$STR_ALIVE_OPCOM_ASYM_FORCE_LIMIT";
                                tooltip = "$STR_ALIVE_OPCOM_ASYM_FORCE_LIMIT_COMMENT";
                                defaultValue = """-1""";
                                typeName = "NUMBER";
                        };
                        class recruitCycleMin : Edit
                        {
                                property = "ALiVE_mil_opcom_recruitCycleMin";
                                displayName = "$STR_ALIVE_OPCOM_RECRUIT_CYCLE_MIN";
                                tooltip = "$STR_ALIVE_OPCOM_RECRUIT_CYCLE_MIN_COMMENT";
                                defaultValue = """30""";
                                typeName = "NUMBER";
                        };
                        class recruitCycleMax : Edit
                        {
                                property = "ALiVE_mil_opcom_recruitCycleMax";
                                displayName = "$STR_ALIVE_OPCOM_RECRUIT_CYCLE_MAX";
                                tooltip = "$STR_ALIVE_OPCOM_RECRUIT_CYCLE_MAX_COMMENT";
                                defaultValue = """60""";
                                typeName = "NUMBER";
                        };
                        class recruitAttemptLimit : Edit
                        {
                                property = "ALiVE_mil_opcom_recruitAttemptLimit";
                                displayName = "$STR_ALIVE_OPCOM_RECRUIT_ATTEMPT_LIMIT";
                                tooltip = "$STR_ALIVE_OPCOM_RECRUIT_ATTEMPT_LIMIT_COMMENT";
                                defaultValue = """0""";
                                typeName = "NUMBER";
                        };
                        class recruitSuccessChance : Edit
                        {
                                property = "ALiVE_mil_opcom_recruitSuccessChance";
                                displayName = "$STR_ALIVE_OPCOM_RECRUIT_SUCCESS_CHANCE";
                                tooltip = "$STR_ALIVE_OPCOM_RECRUIT_SUCCESS_CHANCE_COMMENT";
                                defaultValue = """50""";
                                typeName = "NUMBER";
                        };
                        class taskProfileCountOverrides : Edit
                        {
                                property = "ALiVE_mil_opcom_taskProfileCountOverrides";
                                displayName = "$STR_ALIVE_OPCOM_TASK_PROFILE_COUNT_OVERRIDES";
                                tooltip = "$STR_ALIVE_OPCOM_TASK_PROFILE_COUNT_OVERRIDES_COMMENT";
                                defaultValue = """""";
                        };
                        class taskProfileTypeOverrides : Edit
                        {
                                property = "ALiVE_mil_opcom_taskProfileTypeOverrides";
                                displayName = "$STR_ALIVE_OPCOM_TASK_PROFILE_TYPE_OVERRIDES";
                                tooltip = "$STR_ALIVE_OPCOM_TASK_PROFILE_TYPE_OVERRIDES_COMMENT";
                                defaultValue = """""";
                        };

                        // ---- Hostility ------------------------------------------------------
                        class HDR_HOSTILITY : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_HOSTILITY"; displayName = "HOSTILITY"; };
                        class hostilityPresenceMultiplier : Edit
                        {
                                property = "ALiVE_mil_opcom_hostilityPresenceMultiplier";
                                displayName = "$STR_ALIVE_OPCOM_HOSTILITY_PRESENCE_MULTIPLIER";
                                tooltip = "$STR_ALIVE_OPCOM_HOSTILITY_PRESENCE_MULTIPLIER_COMMENT";
                                defaultValue = """1""";
                                typeName = "NUMBER";
                        };
                        class hostilityInstallationMultiplier : Edit
                        {
                                property = "ALiVE_mil_opcom_hostilityInstallationMultiplier";
                                displayName = "$STR_ALIVE_OPCOM_HOSTILITY_INSTALLATION_MULTIPLIER";
                                tooltip = "$STR_ALIVE_OPCOM_HOSTILITY_INSTALLATION_MULTIPLIER_COMMENT";
                                defaultValue = """1""";
                                typeName = "NUMBER";
                        };
                        class hostilityInstallationInterval : Edit
                        {
                                property = "ALiVE_mil_opcom_hostilityInstallationInterval";
                                displayName = "$STR_ALIVE_OPCOM_HOSTILITY_INSTALLATION_INTERVAL";
                                tooltip = "$STR_ALIVE_OPCOM_HOSTILITY_INSTALLATION_INTERVAL_COMMENT";
                                defaultValue = """10""";
                                typeName = "NUMBER";
                        };

                        // ---- Civic State (Hearts & Minds) -----------------------------------
                        class HDR_CIVIC : ALiVE_ModuleSubTitle { property = "ALiVE_mil_opcom_HDR_CIVIC"; displayName = "CIVIC STATE (HEARTS & MINDS)"; };
                        class civicRecruitmentMultiplier : Edit
                        {
                                property = "ALiVE_mil_opcom_civicRecruitmentMultiplier";
                                displayName = "Civic Pressure Recruitment Multiplier";
                                tooltip = "Scales how strongly the civic-state model slows insurgent recruitment in contested settlements.";
                                defaultValue = """1""";
                                typeName = "NUMBER";
                        };
                        class civicInstallationMultiplier : Edit
                        {
                                property = "ALiVE_mil_opcom_civicInstallationMultiplier";
                                displayName = "Civic Pressure Installation Multiplier";
                                tooltip = "Scales how strongly civic pressure weakens installation-driven hostility drift toward insurgents.";
                                defaultValue = """1""";
                                typeName = "NUMBER";
                        };
                        class civicRetaliationChance : Edit
                        {
                                property = "ALiVE_mil_opcom_civicRetaliationChance";
                                displayName = "Civic Retaliation Chance";
                                tooltip = "Base percent chance for insurgent retaliation after Hearts and Minds success in improving settlements. Use 0 to disable.";
                                defaultValue = """0""";
                                typeName = "NUMBER";
                        };
                        class civicRetaliationIntensity : Edit
                        {
                                property = "ALiVE_mil_opcom_civicRetaliationIntensity";
                                displayName = "Civic Retaliation Intensity";
                                tooltip = "Scales the severity of insurgent backlash against improving settlements.";
                                defaultValue = """1""";
                                typeName = "NUMBER";
                        };

                        class ModuleDescription : ModuleDescription {};
                };
                class ModuleDescription
                {
                    description[] = {"$STR_ALIVE_OPCOM_COMMENT","","$STR_ALIVE_OPCOM_USAGE"};
                    sync[] = {"ALiVE_civ_placement","ALiVE_civ_placement_custom","ALiVE_mil_placement","ALiVE_mil_intelligence","ALiVE_mil_logistics"};
                    class ALiVE_civ_placement { description[] = {"$STR_ALIVE_CP_COMMENT","","$STR_ALIVE_CP_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                    class ALiVE_civ_placement_custom { description[] = {"$STR_ALIVE_CPC_COMMENT","","$STR_ALIVE_CPC_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                    class ALiVE_mil_placement { description[] = {"$STR_ALIVE_MP_COMMENT","","$STR_ALIVE_MP_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                    class ALiVE_mil_logistics { description[] = {"$STR_ALIVE_ML_COMMENT","","$STR_ALIVE_ML_USAGE"}; position=0; direction=0; optional=1; duplicate=1; };
                };
        };

        class Item_Base_F;
        class Item_ItemALiVEPhoneOld: Item_Base_F
        {
            scope = 2; scopeCurator = 2;
            displayName = "Mobile Phone (Old)";
            author = "ALiVE Mod Team"; vehicleClass = "Items";
            class TransportItems { class ItemALiVEPhoneOld { name = "ItemALiVEPhoneOld"; count = 1; }; };
        };
        class Vest_Base_F;
        class Vest_V_ALiVE_Suicide_Belt: Vest_Base_F
        {
            scope = 2; scopeCurator = 2;
            displayName = "Suicide Belt";
            author = "ALiVE Mod Team"; vehicleClass = "ItemsVests";
            class TransportItems { class V_ALiVE_Suicide_Belt { name = "V_ALiVE_Suicide_Belt"; count = 1; }; };
        };
};
