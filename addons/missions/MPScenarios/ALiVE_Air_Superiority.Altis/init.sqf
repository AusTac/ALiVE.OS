//waituntil {!isnil "ALiVE_SYS_LOGISTICS"};

waituntil {!isnil "ALiVE_autoGeneratedTasks"};
ALIVE_autoGeneratedTasks = ["Assassination","Assassination","DestroyVehicles","DestroyVehicles","DestroyVehicles","SabotageBuilding","SabotageBuilding","InsurgencyDestroyAssets","CSAR"];

if (hasInterface && {!isMultiplayer}) then {
    
    ["ALiVE | Air Superiority - Running ClientInit..."] call ALiVE_fnc_Dump;

    //Intro
    [] spawn {
        titleText ["The ALiVE Team presents...", "BLACK IN",9999];
        0 fadesound 0;

	waituntil {!isnull player};

        private ["_cam","_camx","_camy","_camz","_object"];

	_object = player;
	
	_object setCaptive true;

        _start = time;

        waituntil {(player getvariable ["alive_sys_player_playerloaded",false]) || ((time - _start) > 20)};
        
	sleep 10;
        
        _camx = getposATL player select 0;
        _camy = getposATL player select 1;
        _camz = getposATL player select 2;

        _cam = "camera" CamCreate [_camx -500 ,_camy + 500,_camz+450];

        _cam CamSetTarget player;
        _cam CameraEffect ["Internal","Back"];
        _cam CamCommit 0;

        _cam camsetpos [_camx -15 ,_camy + 15,_camz+3];

        titleText ["A L i V E   |   A I R   S U P E R I O R I T Y", "BLACK IN",10];
        10 fadesound 0.9;
        _cam CamCommit 20;
        sleep 5;
        sleep 15;
                
        _cam CameraEffect ["Terminate","Back"];
        CamDestroy _cam;

        sleep 1;

	_object setCaptive false;

        _title = "<t size='1.5' color='#68a7b7' shadow='1'>SABOTAGE</t><br/>";
        _text = format["%1<t>FARP has been established southeast of the main island! Arsenal and Garage is available!</t>",_title];

        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;

        sleep 10;

        _title = "<t size='1.5' color='#68a7b7' shadow='1'>SABOTAGE</t><br/>";
        _text = format["%1<t>Disable AAA installations along the coastline to minimize the opposing ground-to-air threat!</t>",_title];

        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;

        sleep 10;

        _title = "<t size='1.5' color='#68a7b7' shadow='1'>SABOTAGE</t><br/>";
        _text = format["%1<t>Enemy forces are inbound to the BLUFOR FAOB! Keeping up operational effectiveness has top priority!</t>",_title];

        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;

        sleep 10;

        _title = "<t size='1.5' color='#68a7b7' shadow='1'>SABOTAGE</t><br/>";
        _text = format["%1<t>Special objectives will be issued through the ALiVE task system if available! Be aware that this mission is persistent!</t>",_title];

        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;        
    };
};