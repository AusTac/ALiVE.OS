#include "script_component.hpp"

//To be enabled when ZEUS is stable
PREPMAIN(ZEUSinit);
[] call ALIVE_fnc_ZEUSinit;

// 3DEN faction-sync validator registration lives in XEH_preInit - postInit
// doesn't fire in pure Eden-editor mode (no scenario = no post-init).

//Automated tests (define in script_mod.hpp)
#ifdef AUTOMATED_TESTS
[AUTOMATED_TESTS] spawn {

        //Wait for game to run
        waituntil {time > 0};

        {
            if !([_x] call ALiVE_fnc_isModuleAvailable) then {
                private _test = execVM format["\x\alive\addons\%1\tests\test.sqf",_x];
                waituntil {scriptdone _test};
            } else {
                ["Automated Tests: %1 already existing! Exiting test...",_x] call ALiVE_fnc_dumpH;
            };
        } foreach _this;
};
#endif