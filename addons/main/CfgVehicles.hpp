#define MODULE_NAME ALiVE_require
#define MVAR(var) DOUBLES(MODULE_NAME,var)

// Add a game logic which does nothing except requires the addon in the mission.

class CfgFactionClasses {
    class Alive {
        displayName = "$STR_ALIVE_MODULE";
        priority = 0;
        side = 7;
    };
};

class Cfg3DEN
{
    class Attributes // Attribute UI controls are placed in this pre-defined class
    {
        // Base class templates
        class Default; // Empty template with pre-defined width and single line height
        class TitleWide: Default
        {
            class Controls
            {
                class Title;
            };
        }; // Template with full-width single line title and space for content below it

        // SubTitle header used by all ALiVE modules for section grouping
        class ALiVE_ModuleSubTitle: TitleWide
        {
            class Controls: Controls
            {
                class Title: Title
                {
                    style = 2;
                    colorText[] = {1,1,1,0.4};
                };
            };
        };

        class EditMulti3; // Forward declaration of native A3 multiline edit control

        // Multiline SQF code input — used for onEachSpawn hook fields across all placement modules.
        // Inherits the native EditMulti3 control directly.
        // A fully custom taller variant can be revisited once geometry is resolved.
        class ALiVE_EditMultilineSQF: EditMulti3
        {
        };

        class Combo; // Forward declaration of BI Combo attribute control

        // ALiVE_FactionChoice family:
        //   Dynamic faction-selection Combo shared across placement-style
        //   modules. Populated at Eden-panel-open time from loaded
        //   CfgFactionClasses entries grouped by side (OPFOR / BLUFOR /
        //   INDFOR / CIVILIAN) with the displayName + classname suffix
        //   shown to the user.
        //
        //   Three variants differ only in which sides their dropdown
        //   includes - the same Load / Save handlers serve all three,
        //   parameterized via an array passed alongside _this:
        //
        //     ALiVE_FactionChoice            sides 0/1/2/3 (all)
        //     ALiVE_FactionChoice_Military   sides 0/1/2 (no civilians)
        //     ALiVE_FactionChoice_Civilian   side 3 only
        //
        //   Modules pick the variant that matches their semantics:
        //     mil_*    -> Military    (mission-makers shouldn't pick a
        //                              civilian faction for an enemy
        //                              placement objective)
        //     civ_*    -> Civilian    (mission-makers shouldn't pick an
        //                              OPFOR faction for civilian
        //                              ambient population)
        //     generic  -> base ALiVE_FactionChoice (rare; only when
        //                              all-sides is genuinely intended)
        //
        //   Stored attribute value is the canonical faction classname
        //   STRING. Legacy SQMs whose stored string doesn't match any
        //   currently-loaded faction get an "(unrecognised) <value>"
        //   entry at the TOP of the dropdown so the value isn't lost.
        //   Case-insensitive matching on restore (closes #651).
        //
        //   attributeLoad / attributeSave live in separate .sqf files;
        //   see the rationale in mil_ied Cfg3DEN.hpp (preprocessor fights
        //   with multi-line strings on Windows CRLF).
        class ALiVE_FactionChoice: Combo {
            attributeLoad = "[_this, [0,1,2,3]] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceLoad.sqf'";
            attributeSave = "_this call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceSave.sqf'";
        };
        class ALiVE_FactionChoice_Military: Combo {
            attributeLoad = "[_this, [0,1,2]] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceLoad.sqf'";
            attributeSave = "_this call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceSave.sqf'";
        };
        class ALiVE_FactionChoice_Civilian: Combo {
            attributeLoad = "[_this, [3]] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceLoad.sqf'";
            attributeSave = "_this call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceSave.sqf'";
        };

        // ALiVE_FactionChoiceMulti family:
        //   Multi-select counterpart to ALiVE_FactionChoice. Same dynamic
        //   population (CfgFactionClasses + missionConfig, side filtered,
        //   civilian blacklist, Cfg3rdPartyFactions registry overrides,
        //   Phase 3c.1 inferability prediction) but with a multi-select
        //   ListBox at IDC 100 instead of a single-select Combo.
        //
        //   Built by inheriting BI's Combo attribute base (which is a
        //   controlsGroup with title + value child controls) and overriding
        //   the inner Value control's type (CT_LISTBOX=5 vs CT_COMBO=4)
        //   and style flag (LB_MULTI = 0x20 added to ST_FRAME = 16).
        //   This piggybacks on Combo's value-binding plumbing (attributeLoad/
        //   Save addressing IDC 100 via controlsGroupCtrl) without having
        //   to redefine the entire Cfg3DEN attribute framework from scratch.
        //
        //   Stored value is an SQF array literal STRING like
        //   `["BLU_F","OPF_F","IND_F"]`. Load handler also accepts CSV form
        //   `BLU_F,OPF_F` for backward compatibility with the old Edit-field
        //   pattern. Save always emits canonical array-literal form.
        //
        //   The third element of the load handler's invocation is the logic-
        //   variable name (default "factions"), allowing the same handler
        //   to serve modules whose attribute is named differently (e.g.
        //   "CQB_FACTIONS" for mil_cqb).
        //
        //   Three side-filter variants matching the single-select trio:
        //     ALiVE_FactionChoiceMulti           sides 0/1/2/3 (all)
        //     ALiVE_FactionChoiceMulti_Military  sides 0/1/2   (no civilians)
        //     ALiVE_FactionChoiceMulti_Civilian  side 3        (civilians only)
        //
        //   Modules pick the variant matching their semantics. mil_opcom
        //   uses _Military (an OPCOM faction list shouldn't include civilians).

        class ALiVE_FactionChoiceMulti: Combo {
            // Taller than the default Combo to accommodate ~10 rows of listbox.
            // 5 grid units for the title + 15 for the listbox = 20 total.
            h = "20 * GUI_GRID_H";
            attributeLoad = "[_this, [0,1,2,3], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";

            class Controls: Controls {
                class Title: Title {};
                class Value: Value {
                    // Override Combo's CT_COMBO (4) -> CT_LISTBOX (5).
                    // Combine ST_FRAME (16) with LB_MULTI (0x20 = 32) so the
                    // listbox renders as a bordered multi-select. Multi-select
                    // ListBox accepts Ctrl+click to toggle individual items
                    // and Shift+click to range-select.
                    type = 5;
                    style = 16 + 0x20;
                    h = "15 * GUI_GRID_H";
                    rowHeight = "1 * GUI_GRID_H";
                };
            };
        };

        class ALiVE_FactionChoiceMulti_Military: Combo {
            h = "20 * GUI_GRID_H";
            attributeLoad = "[_this, [0,1,2], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";

            class Controls: Controls {
                class Title: Title {};
                class Value: Value {
                    type = 5;
                    style = 16 + 0x20;
                    h = "15 * GUI_GRID_H";
                    rowHeight = "1 * GUI_GRID_H";
                };
            };
        };

        class ALiVE_FactionChoiceMulti_Civilian: Combo {
            h = "20 * GUI_GRID_H";
            attributeLoad = "[_this, [3], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";

            class Controls: Controls {
                class Title: Title {};
                class Value: Value {
                    type = 5;
                    style = 16 + 0x20;
                    h = "15 * GUI_GRID_H";
                    rowHeight = "1 * GUI_GRID_H";
                };
            };
        };
    };
    // Configuration of all objects
    class Object
    {
        // Categories collapsible in "Edit Attributes" window
        class AttributeCategories
        {
              // Category class, can be anything
              class State
              {
                    class Attributes
                    {
                          // Attribute class, can be anything
                          class ALiVE_OverrideLoadout
                          {
                                //--- Mandatory properties
                                displayName = "Override ALiVE ORBAT Loadout"; // Name assigned to UI control class Title
                                tooltip = " ALiVE ORBAT Creator units have scripted loadouts. Enable this to override this loadout."; // Tooltip assigned to UI control class Title
                                property = "ALiVE_OverrideLoadout"; // Unique config property name saved in SQM
                                control = "Checkbox"; // UI control base class displayed in Edit Attributes window, points to Cfg3DEN >> Attributes

                                // Expression called when applying the attribute in Eden and at the scenario start
                                // The expression is called twice - first for data validation, and second for actual saving
                                // Entity is passed as _this, value is passed as _value
                                // %s is replaced by attribute config name. It can be used only once in the expression
                                // In MP scenario, the expression is called only on server.
                                expression = "_this setVariable ['%s',_value];";

                                // Expression called when custom property is undefined yet (i.e., when setting the attribute for the first time)
                                // Entity is passed as _this
                                // Returned value is the default value
                                // Used when no value is returned, or when it's of other type than NUMBER, STRING or ARRAY
                                // Custom attributes of logic entities (e.g., modules) are saved always, even when they have default value
                                defaultValue = "false";

                                //--- Optional properties
                                condition = "objectControllable";
                                typeName = "BOOL"; // Defines data type of saved value, can be STRING, NUMBER or BOOL. Used only when control is "Combo", "Edit" or their variants
                          };
                    };
              };
        };
    };
};

class CfgVehicles {
    class Logic;
    class Module_F : Logic
    {
        class ArgumentsBaseUnits
        {
            class Units;
        };
        class AttributesBase
        {
            class Default;
            class Edit; // Default edit box (i.e., text input field)
            class Combo; // Default combo box (i.e., drop-down menu)
            class Checkbox; // Default checkbox (returned value is Bool)
            class CheckboxNumber; // Default checkbox (returned value is Number)
            class ModuleDescription; // Module description
        };
        class ModuleDescription
        {
            class AnyBrain;
        };
    };

    class ModuleAliveBase: Module_F {
        scope = 1;
        displayName = "EditorAliveBase";
        category = "Alive";
        class AttributesBase : AttributesBase
        {
            class ALiVE_ModuleSubTitle : Default
            {
                control = "ALiVE_ModuleSubTitle";
                defaultValue = "''";
            };
            class ALiVE_EditMulti3 : Default
            {
                control = "EditMulti3";
                defaultValue = "''";
            };
            class ALiVE_EditMulti5 : Default
            {
                control = "EditMulti5";
                defaultValue = "''";
            };
            class ALiVE_EditMultilineSQF : Default
            {
                control = "ALiVE_EditMultilineSQF";
                defaultValue = "''";
            };
        };
    };

    class ALiVE_require: ModuleAliveBase
    {
        scope = 2;
        displayName = "$STR_ALIVE_REQUIRES_ALIVE";
        icon = "x\alive\addons\main\icon_requires_alive.paa";
        picture = "x\alive\addons\main\icon_requires_alive.paa";
        functionPriority = 40;
        isGlobal = 2;
        function = "ALiVE_fnc_aliveInit";
        author = MODULE_AUTHOR;

        class Attributes: AttributesBase
        {
            class debug: Combo
            {
                    property =  MVAR(debug);
                    displayName = "$STR_ALIVE_DEBUG";
                    tooltip = "$STR_ALIVE_DEBUG_COMMENT";
                    defaultValue = """false""";
                    class Values
                    {
                            class Yes
                            {
                                    name = "Yes";
                                    value = "true";
                            };
                            class No
                            {
                                    name = "No";
                                    value = "false";
                            };
                    };
            };
            class ALiVE_Versioning: Combo
            {
                    property =  MVAR(ALiVE_Versioning);
                    displayName = "$STR_ALIVE_REQUIRES_ALIVE_VERSIONING";
                    tooltip = "$STR_ALIVE_REQUIRES_ALIVE_VERSIONING_COMMENT";
                    defaultValue = """warning""";
                    class Values
                    {
                            class warning
                            {
                                    name = "Warn players";
                                    value = "warning";
                            };
                            class kick
                            {
                                    name = "Kick players";
                                    value = "kick";
                            };
                    };
            };

            class ALiVE_AI_DISTRIBUTION: Combo
            {
                    property =  MVAR(ALiVE_AI_DISTRIBUTION);
                    displayName = "$STR_ALIVE_REQUIRES_ALIVE_AI_DISTRIBUTION";
                    tooltip = "$STR_ALIVE_REQUIRES_ALIVE_AI_DISTRIBUTION_COMMENT";
                    defaultValue = """false""";
                    class Values
                    {
                            class off
                            {
                                    name = "Server";
                                    value = "false";
                            };
                            class on
                            {
                                    name = "Headless clients";
                                    value = "true";
                            };
                    };
            };

            class ALiVE_DISABLESAVE: Combo
            {
                    property =  MVAR(ALiVE_DISABLESAVE);
                    displayName = "$STR_ALIVE_DISABLESAVE";
                    tooltip = "$STR_ALIVE_DISABLESAVE_COMMENT";
                    defaultValue = """true""";
                    class Values
                    {
                            class warning
                            {
                                    name = "Yes";
                                    value = "true";
                            };
                            class kick
                            {
                                    name = "No";
                                    value = "false";
                            };
                    };
            };
            class ALiVE_DISABLEMARKERS: Combo
            {
                    property =  MVAR(ALiVE_DISABLEMARKERS);
                    displayName = "$STR_ALIVE_DISABLEMARKERS";
                    tooltip = "$STR_ALIVE_DISABLEMARKERS_COMMENT";
                    typeName = "BOOL";
                    defaultValue = "false";
                    class Values
                    {
                            class Yes
                            {
                                    name = "Yes";
                                    value = 1;
                            };
                            class No
                            {
                                    name = "No";
                                    value = 0;
                            };
                    };
            };
            class ALiVE_DISABLEADMINACTIONS: Combo
            {
                    property =  MVAR(ALiVE_DISABLEADMINACTIONS);

                    displayName = "$STR_ALIVE_DISABLEADMINACTIONS";
                    tooltip = "$STR_ALIVE_DISABLEADMINACTIONS_COMMENT";
                    typeName = "BOOL";
                    defaultValue = "false";
                    class Values
                    {
                            class Yes
                            {
                                    name = "Yes";
                                    value = 1;
                            };
                            class No
                            {
                                    name = "No";
                                    value = 0;
                            };
                    };
            };
            class ALiVE_PAUSEMODULES: Combo
            {
                    property =  MVAR(ALiVE_PAUSEMODULES);
                    displayName = "$STR_ALiVE_PAUSEMODULES";
                    tooltip = "$STR_ALiVE_PAUSEMODULES_COMMENT";
                    typeName = "BOOL";
                    defaultValue = "false";
                    class Values
                    {
                            class Yes
                            {
                                    name = "Yes";
                                    value = 1;
                            };
                            class No
                            {
                                    name = "No";
                                    value = 0;
                            };
                    };
            };
            class ALiVE_GC_INTERVAL: Edit
            {
                    property =  MVAR(ALiVE_GC_INTERVAL);
                    displayName = "$STR_ALIVE_GC_INTERVAL";
                    tooltip = "$STR_ALIVE_GC_INTERVAL_COMMENT";
                    defaultValue = """300""";
            };
            class ALiVE_GC_THRESHHOLD: Edit
            {
                    property =  MVAR(ALiVE_GC_THRESHHOLD);
                    displayName = "$STR_ALIVE_GC_THRESHHOLD";
                    tooltip = "$STR_ALIVE_GC_THRESHHOLD_COMMENT";
                    defaultValue = """100""";
            };
            class ALiVE_GC_INDIVIDUALTYPES: Edit
            {
                    property =  MVAR(ALiVE_GC_INDIVIDUALTYPES);
                    displayName = "$STR_ALIVE_GC_INDIVIDUALTYPES";
                    tooltip = "$STR_ALIVE_GC_INDIVIDUALTYPES_COMMENT";
                    defaultValue = """""";
            };
            class ALiVE_TABLET_MODEL: Combo
            {
                property =  MVAR(ALiVE_TABLET_MODEL);
                displayName = "$STR_ALiVE_TABLET_MODEL";
                tooltip = "$STR_ALiVE_TABLET_MODEL_COMMENT";
                typeName = "STRING";
                defaultValue = """Tablet01""";
                class Values
                {
                    class Tablet01
                    {
                        name = "Tablet 1";
                        value = "Tablet01";
                    };
                    class MapBag01
                    {
                        name = "Mapbag 1";
                        value = "Mapbag01";
                    };
                };
            };
            class ModuleDescription: ModuleDescription{};
        };
        class ModuleDescription: ModuleDescription
        {
            //description = "$STR_ALIVE_REQUIRES_COMMENT"; // Short description, will be formatted as structured text
            description[] = {
                "$STR_ALIVE_REQUIRES_ALIVE",
                "",
                "$STR_ALIVE_REQUIRES_USAGE"
            };
            sync[] = {}; // Array of synced entities (can contain base classes)
        };
    };
};
