// ----------------------------------------------------------------------------
// Cfg3DEN custom attribute controls for mil_ied
//
// ALiVE_IntegrationChoice:
//   Dynamic Combo attribute whose items are populated at Eden-panel-open
//   time from two sources:
//     1. Two special meta-choices always present:
//          "_auto"         -> "Auto (detect)"
//          "_force_alive"  -> "Force ALiVE handling"
//     2. One "Defer to: <displayName>" item per Cfg3rdPartyIEDs entry whose
//        cfgPatchesName addon is actually loaded right now (isClass CfgPatches
//        check). The ALiVE_Vanilla_A3 baseline entry is hidden from the
//        dropdown since it's always present and not a meaningful authority.
//
//   Stored attribute value is the string data token:
//     "_auto", "_force_alive", or a registry className (e.g. "ACE_Explosives").
//
//   The runtime resolver in fnc_IED.sqf reads the stored choice and picks
//   "alive" or "mine" accordingly; if the user saved a choice for a mod
//   they've since unloaded, the resolver falls back to the Auto rule with
//   a diag_log warning.
// ----------------------------------------------------------------------------

class Cfg3DEN {
    class Attribute {
        class Combo; // BI base class - single-select combo box
        class ALiVE_IntegrationChoice: Combo {
            attributeLoad = "\
                private _ctrl = (_this controlsGroupCtrl 100);\
                lbClear _ctrl;\
                private _specials = [['_auto', 'Auto (detect)'], ['_force_alive', 'Force ALiVE handling']];\
                {\
                    _x params ['_data', '_label'];\
                    private _idx = _ctrl lbAdd _label;\
                    _ctrl lbSetData [_idx, _data];\
                } forEach _specials;\
                private _registry = configFile >> 'Cfg3rdPartyIEDs';\
                if (isClass _registry) then {\
                    for '_i' from 0 to (count _registry - 1) do {\
                        private _entry = _registry select _i;\
                        if (isClass _entry) then {\
                            private _cn = configName _entry;\
                            private _cp = getText (_entry >> 'cfgPatchesName');\
                            if (_cn != 'ALiVE_Vanilla_A3' && _cp != '' && {isClass (configFile >> 'CfgPatches' >> _cp)}) then {\
                                private _dn = getText (_entry >> 'displayName');\
                                private _idx = _ctrl lbAdd format ['Defer to: %1', _dn];\
                                _ctrl lbSetData [_idx, _cn];\
                            };\
                        };\
                    };\
                };\
                private _value = _this getVariable 'value';\
                if (isNil '_value' || {typeName _value != 'STRING' || _value == ''}) then { _value = '_auto'; };\
                private _selIdx = 0;\
                for '_i' from 0 to (lbSize _ctrl - 1) do {\
                    if ((_ctrl lbData _i) == _value) exitWith { _selIdx = _i; };\
                };\
                _ctrl lbSetCurSel _selIdx;\
            ";
            attributeSave = "\
                private _ctrl = (_this controlsGroupCtrl 100);\
                private _sel = lbCurSel _ctrl;\
                if (_sel < 0) then { '_auto' } else { _ctrl lbData _sel }\
            ";
        };
    };
};
