private["_worldName"];
 _worldName = tolower(worldName);
 ["SETTING UP MAP: mef_alaska2035"] call ALiVE_fnc_dump;
 ALIVE_Indexing_Blacklist = [];
 ALIVE_airBuildingTypes = [];
 ALIVE_militaryParkingBuildingTypes = [];
 ALIVE_militarySupplyBuildingTypes = [];
 ALIVE_militaryHQBuildingTypes = [];
 ALIVE_militaryAirBuildingTypes = [];
 ALIVE_civilianAirBuildingTypes = [];
 ALiVE_HeliBuildingTypes = [];
 ALIVE_militaryHeliBuildingTypes = [];
 ALIVE_civilianHeliBuildingTypes = [];
 ALIVE_militaryBuildingTypes = [];
 ALIVE_civilianPopulationBuildingTypes = [];
 ALIVE_civilianHQBuildingTypes = [];
 ALIVE_civilianPowerBuildingTypes = [];
 ALIVE_civilianCommsBuildingTypes = [];
 ALIVE_civilianMarineBuildingTypes = [];
 ALIVE_civilianRailBuildingTypes = [];
 ALIVE_civilianFuelBuildingTypes = [];
 ALIVE_civilianConstructionBuildingTypes = [];
 ALIVE_civilianSettlementBuildingTypes = [];
 if(tolower(_worldName) == "mef_alaska2035") then {
[ALIVE_mapBounds, worldName, 21000] call ALIVE_fnc_hashSet;
ALIVE_militaryBuildingTypes = ALIVE_militaryBuildingTypes + ["ca\buildings\hangar_2.p3d","ca\buildings\budova4.p3d","ca\buildings\budova2.p3d","ca\buildings2\farm_cowshed\farm_cowshed_c.p3d","ca\buildings2\farm_cowshed\farm_cowshed_b.p3d","ca\buildings2\farm_cowshed\farm_cowshed_a.p3d"];
ALIVE_civilianSettlementBuildingTypes = ALIVE_civilianSettlementBuildingTypes + ["ca\buildings\sara_domek_kovarna.p3d","ca\buildings\dum_rasovna.p3d","ca\buildings\budova5.p3d","ca\buildings\dum_zboreny.p3d","ca\buildings\zalchata.p3d","ca\buildings\sara_domek_hospoda.p3d","ca\buildings\vysilac_fm.p3d","ca\buildings\sara_domek_podhradi_1.p3d","ca\buildings\sara_domek_zluty.p3d","ca\buildings\domek_rosa.p3d","ca\buildings\sara_hasic_zbroj.p3d","ca\buildings\sara_domek_ruina.p3d","ca\buildings\bouda3.p3d"];
};
