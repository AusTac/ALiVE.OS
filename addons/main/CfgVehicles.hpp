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

        // Forward declarations for vanilla A3 control classes used by
        // the ALiVE_FactionChoiceMulti / ALiVE_HiddenAttribute custom
        // attributes below. These are top-level engine controls, not
        // Cfg3DEN attribute bases - a forward decl is all rapify needs
        // to accept them as inheritance targets.
        class ctrlControlsGroupNoScrollbars;
        class ctrlListBox;
        class ctrlStatic;

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

        // Multi-select faction listbox - tall Cfg3DEN attribute that
        // renders as a multi-row listbox with Ctrl+click toggle and
        // shift+click range-select semantics (LB_MULTI style).
        //
        // Pattern: inherit ctrlControlsGroupNoScrollbars (NOT BI's
        // Combo). Attribute panel slot height is taken from the
        // outer h here; explicit child positions inside `controls`
        // (note lowercase, NOT Controls) lay out the listbox. ACE3
        // Arsenal's Cfg3DEN attribute uses this same pattern - the
        // only known way to ship a tall multi-row Cfg3DEN attribute,
        // since Combo / Edit / Title bases enforce a single-row slot
        // and silently ignore any h override.
        //
        // The three variants below differ only in attributeLoad's
        // side-allowlist parameter; they inherit everything else
        // from _Base.
        class ALiVE_FactionChoiceMulti_Base: ctrlControlsGroupNoScrollbars {
            // Forward decl of ctrlControlsGroupNoScrollbars doesn't
            // pull through the body's default properties (type, style,
            // colorBackground, etc), so they need to be set explicitly
            // here. type = 15 = CT_CONTROLS_GROUP_NO_SCROLLBARS is the
            // critical one - without it, Eden treats this as a bare
            // CT_STATIC and never descends into `class controls`,
            // causing the inner listbox to not exist (Load handler
            // reports "listbox control (IDC 100) not found").
            //
            // Layout: Eden does NOT auto-render the per-attribute
            // displayName as a row label for custom controlsGroup
            // attributes (only for simple Combo / Edit / Checkbox
            // bases), so we render the field label ourselves via a
            // Title sub-control positioned in the row's left column.
            // The listbox sits in the right (value) column to align
            // with where standard Eden value controls would.
            type  = 15;
            style = 0;
            idc   = -1;
            x = 0;
            y = 0;
            // Outer width spans the full standard Eden attribute row
            // so children can align with where other attributes' labels
            // and value controls sit.
            // Outer height includes 5 grid units of bottom padding so
            // the next attribute below has breathing room without an
            // excessive gap.
            w = "130 * (pixelW * pixelGrid * 0.5)";
            h = "55 * (pixelH * pixelGrid * 0.5)";
            colorBackground[] = {0, 0, 0, 0};
            colorText[]       = {1, 1, 1, 1};
            text   = "";
            font   = "RobotoCondensed";
            sizeEx = "pixelH * pixelGrid * 2.2";

            // controlsGroup engine expects VScrollbar / HScrollbar
            // sub-classes even on the "NoScrollbars" variant - empty
            // blocks silence the RPT warnings.
            class VScrollbar {};
            class HScrollbar {};

            class controls {
                // Title (field label) - sits in the left column of
                // the row, vertically centred against the listbox to
                // its right. Right-aligned text matches Eden's
                // convention for attribute labels (style = 1 = ST_RIGHT).
                // Tooltip on hover with explicit colors so it's
                // legible (Eden's default attribute tooltip is too
                // transparent).
                class Title: ctrlStatic {
                    idc      = 101;
                    type     = 0;
                    style    = 1;
                    x        = 0;
                    y        = 0;
                    w        = "48 * (pixelW * pixelGrid * 0.5)";
                    h        = "5 * (pixelH * pixelGrid * 0.5)";
                    colorBackground[] = {0, 0, 0, 0};
                    colorText[]       = {1, 1, 1, 0.9};
                    text     = "Override Factions:";
                    font     = "RobotoCondensed";
                    sizeEx   = "pixelH * pixelGrid * 2.0";
                    tooltip  = "Pick one or more factions for this AI Commander to control. Left-click = replace selection. Ctrl+click = toggle individual item (multi-select). Shift+click = select range.";
                    tooltipColorShade[] = {0, 0, 0, 1};
                    tooltipColorText[]  = {1, 1, 1, 1};
                    tooltipColorBox[]   = {0, 0, 0, 1};
                };

                class List: ctrlListBox {
                    idc = 100;
                    type = 5;            // CT_LISTBOX
                    style = 16 + 0x20;   // ST_FRAME + LB_MULTI
                    // Right column: aligns flush with the standard
                    // Eden value column (where Combo / Edit inputs on
                    // adjacent rows begin), fills to the
                    // controlsGroup's right edge.
                    x = "48 * (pixelW * pixelGrid * 0.5)";
                    y = 0;
                    w = "82 * (pixelW * pixelGrid * 0.5)";
                    h = "50 * (pixelH * pixelGrid * 0.5)";

                    color[]                  = {1, 1, 1, 1};
                    colorText[]              = {1, 1, 1, 1};
                    colorBackground[]        = {0, 0, 0, 0.5};
                    // Selection background follows the user's GUI
                    // background colour (Options > Game > Layout >
                    // Background colour) so the highlight always
                    // matches the Eden window-title chrome whatever
                    // the player has picked. Defaults preserve the
                    // previous orange-yellow look for users who
                    // haven't customised. Black text for contrast.
                    colorSelect[]            = {0, 0, 0, 1};
                    colorSelect2[]           = {0, 0, 0, 1};
                    colorSelectBackground[]  = {
                        "(profilenamespace getvariable ['GUI_BCG_RGB_R',1])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.62])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_B',0])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_A',1])"
                    };
                    colorSelectBackground2[] = {
                        "(profilenamespace getvariable ['GUI_BCG_RGB_R',1])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.62])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_B',0])",
                        "(profilenamespace getvariable ['GUI_BCG_RGB_A',1])"
                    };
                    colorDisabled[]          = {1, 1, 1, 0.25};
                    colorShadow[]            = {0, 0, 0, 0.5};

                    // Solid black tooltip background + matching black
                    // border for legibility (Eden's default attribute
                    // tooltip is too transparent; yellow border was
                    // visually distracting).
                    tooltipColorShade[] = {0, 0, 0, 1};
                    tooltipColorText[]  = {1, 1, 1, 1};
                    tooltipColorBox[]   = {0, 0, 0, 1};

                    // Listbox text and row height matched up to other
                    // Eden dialog controls without being so small the
                    // selected items appear shrunk.
                    font     = "RobotoCondensed";
                    sizeEx   = "pixelH * pixelGrid * 2.0";
                    rowHeight = "pixelH * pixelGrid * 2.4";
                    period   = 1.2;

                    // ListBox engine expects these even when unused -
                    // empty defaults silence RPT warnings.
                    soundSelect[] = {"", 0, 0};
                    maxHistoryDelay = 1.0;

                    class ListScrollBar {
                        color[]         = {1, 1, 1, 0.6};
                        colorActive[]   = {1, 1, 1, 1};
                        colorDisabled[] = {1, 1, 1, 0.3};
                        arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
                        arrowFull  = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
                        border     = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
                        thumb      = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
                    };
                };
            };
        };

        class ALiVE_FactionChoiceMulti: ALiVE_FactionChoiceMulti_Base {
            attributeLoad = "[_this, [0,1,2,3], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";
        };

        class ALiVE_FactionChoiceMulti_Military: ALiVE_FactionChoiceMulti_Base {
            attributeLoad = "[_this, [0,1,2], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";
        };

        class ALiVE_FactionChoiceMulti_Civilian: ALiVE_FactionChoiceMulti_Base {
            attributeLoad = "[_this, [3], 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiLoad.sqf'";
            attributeSave = "[_this, 'factions'] call compile preprocessFileLineNumbers '\x\alive\addons\main\fnc_edenFactionChoiceMultiSave.sqf'";
        };

        // Hidden attribute - renders zero UI (h = 0, empty controls).
        // Used by legacy attributes that need to round-trip SQM data
        // through their `expression` without surfacing in the panel.
        // Same ctrlControlsGroupNoScrollbars substrate + same explicit
        // engine-property defaults as ALiVE_FactionChoiceMulti_Base
        // above (forward decl doesn't pull them through).
        class ALiVE_HiddenAttribute: ctrlControlsGroupNoScrollbars {
            type  = 15;
            style = 0;
            idc   = -1;
            x = 0;
            y = 0;
            w = 0;
            h = 0;
            colorBackground[] = {0, 0, 0, 0};
            colorText[]       = {1, 1, 1, 1};
            text   = "";
            font   = "RobotoCondensed";
            sizeEx = "pixelH * pixelGrid * 1.6";
            // Eden expects attributeLoad / attributeSave on every
            // attribute control; hidden attributes do nothing for
            // either (the SQM-saved value is applied via the per-
            // attribute `expression` at module init, no UI to
            // populate or read back). Empty handlers silence the
            // RPT warnings.
            attributeLoad = "";
            attributeSave = "";
            class VScrollbar {};
            class HScrollbar {};
            class controls {};
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
            class ALiVE_HiddenAttribute : Default
            {
                control = "ALiVE_HiddenAttribute";
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
