private["_worldName"];
 _worldName = tolower(worldName);
 ["SETTING UP MAP: pja314"] call ALiVE_fnc_dump;
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
 if(tolower(_worldName) == "pja314") then {
ALIVE_Indexing_Blacklist = ALIVE_Indexing_Blacklist + ["ca\buildings2\ind_tank\ind_tanksmall.p3d","ca\buildings\misc\plot_rust_vrat_o.p3d","ca\structures\ind_quarry\ind_hammermill.p3d","ca\buildings2\a_statue\a_statue02.p3d"];
ALIVE_militaryBuildingTypes = ALIVE_militaryBuildingTypes + [];
ALIVE_militaryParkingBuildingTypes = ALIVE_militaryParkingBuildingTypes + [];
ALIVE_militarySupplyBuildingTypes = ALIVE_militarySupplyBuildingTypes + [];
ALIVE_militaryHQBuildingTypes = ALIVE_militaryHQBuildingTypes + [];
ALIVE_airBuildingTypes = ALIVE_airBuildingTypes + [];
ALIVE_militaryAirBuildingTypes = ALIVE_militaryAirBuildingTypes + [];
ALIVE_civilianAirBuildingTypes = ALIVE_civilianAirBuildingTypes + [];
ALIVE_heliBuildingTypes = ALIVE_heliBuildingTypes + [];
ALIVE_militaryHeliBuildingTypes = ALIVE_militaryHeliBuildingTypes + [];
ALIVE_civilianHeliBuildingTypes = ALIVE_civilianHeliBuildingTypes + [];
ALIVE_civilianPopulationBuildingTypes = ALIVE_civilianPopulationBuildingTypes + ["a3\structures_f\households\house_small01\u_house_small_01_v1_f.p3d","ca\buildings\kulna.p3d","a3\structures_f\households\house_shop01\i_shop_01_v3_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v3_f.p3d","a3\structures_f\households\house_small02\i_house_small_02_v2_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v1_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v2_f.p3d","ca\buildings2\ind_workshop01\ind_workshop01_03.p3d","ca\buildings2\ind_workshop01\ind_workshop01_01.p3d","ca\buildings\hangar_2.p3d","ca\structures\shed_ind\shed_ind02.p3d","a3\structures_f\households\house_shop02\u_shop_02_v1_f.p3d","ca\structures\house\housev2\housev2_02_interier.p3d","ca\buildings\hut06.p3d","a3\structures_f\households\house_small02\i_house_small_02_v1_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v1_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v3_f.p3d","ca\structures\barn_w\barn_w_01.p3d","ca\buildings2\a_generalstore_01\a_generalstore_01a.p3d","a3\structures_f\households\house_big01\i_house_big_01_v2_f.p3d","a3\structures_f\households\house_shop01\i_shop_01_v2_f.p3d","a3\structures_f\households\house_shop01\i_shop_01_v1_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v1_dam_f.p3d","ca\buildings2\ind_workshop01\ind_workshop01_l.p3d","ca\buildings2\farm_cowshed\farm_cowshed_b.p3d","ca\buildings2\farm_cowshed\farm_cowshed_c.p3d","ca\buildings2\farm_cowshed\farm_cowshed_a.p3d","ca\structures\barn_w\barn_w_02.p3d","a3\structures_f\households\house_big02\i_house_big_02_v2_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v1_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v1_dam_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v3_f.p3d","ca\buildings2\ind_workshop01\ind_workshop01_04.p3d","ca\structures\house\housev2\housev2_04_interier.p3d","ca\buildings2\ind_garage01\ind_garage01.p3d","ca\structures\house\a_office01\a_office01.p3d","ca\structures\mil\mil_guardhouse.p3d","ca\structures\house\a_fuelstation\a_fuelstation_build.p3d","ca\buildings\hlidac_budka.p3d","ca\buildings2\shed_wooden\shed_wooden.p3d","a3\structures_f\households\addons\i_garage_v2_f.p3d","a3\structures_f\households\house_big01\u_house_big_01_v1_f.p3d","a3\structures_f\households\house_big02\u_house_big_02_v1_f.p3d","a3\structures_f\households\house_big02\u_house_big_02_v1_dam_f.p3d","a3\structures_f\households\house_small02\i_house_small_02_v3_f.p3d","ca\structures\house\housev\housev_1i4.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v1_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v3_f.p3d","a3\structures_f\households\stone_shed\i_stone_shed_v2_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v2_dam_f.p3d","ca\buildings2\a_pub\a_pub_01.p3d","ca\structures\house\a_hospital\a_hospital.p3d","ca\buildings2\a_generalstore_01\a_generalstore_01.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v1_dam_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v2_f.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v3_f.p3d","a3\structures_f\households\stone_shed\i_stone_shed_v3_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v3_dam_f.p3d","ca\buildings2\barn_metal\barn_metal.p3d","a3\structures_f\households\house_small02\u_house_small_02_v1_f.p3d","a3\structures_f\households\slum\slum_house02_f.p3d","a3\structures_f\households\house_small03\i_house_small_03_v1_f.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v1_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v1_dam_f.p3d","a3\structures_f\households\slum\slum_house03_f.p3d","ca\structures\house\a_stationhouse\a_stationhouse.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v2_f.p3d"];
ALIVE_civilianHQBuildingTypes = ALIVE_civilianHQBuildingTypes + ["ca\structures\house\a_office01\a_office01.p3d","ca\structures\mil\mil_guardhouse.p3d","ca\buildings2\a_pub\a_pub_01.p3d","ca\structures\house\a_hospital\a_hospital.p3d","ca\structures\house\a_stationhouse\a_stationhouse.p3d"];
ALIVE_civilianSettlementBuildingTypes = ALIVE_civilianSettlementBuildingTypes + ["a3\structures_f\households\house_small01\u_house_small_01_v1_f.p3d","ca\buildings2\shed_small\shed_w02.p3d","ca\buildings2\shed_small\shed_m01.p3d","ca\buildings\kulna.p3d","ca\buildings2\shed_small\shed_w01.p3d","a3\structures_f\households\house_shop01\i_shop_01_v3_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v3_f.p3d","ca\buildings2\misc_waterstation\misc_waterstation.p3d","ca\buildings2\ind_shed_02\ind_shed_02_main.p3d","ca\buildings2\shed_small\shed_m02.p3d","ca\buildings2\ind_shed_02\ind_shed_02_end.p3d","a3\structures_f\households\house_small02\i_house_small_02_v2_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v1_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v2_f.p3d","ca\buildings\trafostanica_velka.p3d","ca\buildings2\shed_small\shed_w03.p3d","ca\buildings2\ind_workshop01\ind_workshop01_03.p3d","ca\buildings2\ind_workshop01\ind_workshop01_01.p3d","ca\buildings2\ind_tank\ind_tankbig.p3d","ca\buildings\hangar_2.p3d","ca\structures\shed_ind\shed_ind02.p3d","ca\buildings2\misc_powerstation\misc_powerstation.p3d","a3\structures_f\households\house_shop02\u_shop_02_v1_f.p3d","ca\structures\house\housev2\housev2_02_interier.p3d","ca\buildings\hut06.p3d","a3\structures_f\households\house_small02\i_house_small_02_v1_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v1_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v3_f.p3d","ca\structures\shed\shed_small\shed_w4.p3d","ca\structures\barn_w\barn_w_01.p3d","ca\buildings2\shed_small\shed_m03.p3d","ca\buildings2\a_generalstore_01\a_generalstore_01a.p3d","a3\structures_f\households\house_big01\i_house_big_01_v2_f.p3d","ca\buildings2\ind_shed_01\ind_shed_01_end.p3d","ca\buildings2\ind_shed_01\ind_shed_01_main.p3d","a3\structures_f\households\house_shop01\i_shop_01_v2_f.p3d","a3\structures_f\households\house_shop01\i_shop_01_v1_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v1_dam_f.p3d","ca\buildings2\ind_workshop01\ind_workshop01_l.p3d","ca\buildings2\farm_cowshed\farm_cowshed_b.p3d","ca\buildings2\farm_cowshed\farm_cowshed_c.p3d","ca\buildings2\farm_cowshed\farm_cowshed_a.p3d","ca\structures\barn_w\barn_w_02.p3d","a3\structures_f\households\house_big02\i_house_big_02_v2_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v1_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v1_dam_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v3_f.p3d","ca\buildings2\houseblocks\houseblock_a\houseblock_a1_1.p3d","ca\buildings2\houseblocks\houseblock_c\houseblock_c4.p3d","ca\buildings2\ind_workshop01\ind_workshop01_04.p3d","ca\buildings2\houseblocks\houseblock_a\houseblock_a3.p3d","ca\structures\house\housev2\housev2_04_interier.p3d","ca\buildings2\ind_workshop01\ind_workshop01_02.p3d","ca\buildings2\ind_garage01\ind_garage01.p3d","ca\structures\house\a_office01\a_office01.p3d","ca\structures\mil\mil_guardhouse.p3d","ca\structures\house\a_fuelstation\a_fuelstation_feed.p3d","ca\structures\house\a_fuelstation\a_fuelstation_shed.p3d","ca\structures\house\a_fuelstation\a_fuelstation_build.p3d","ca\buildings\repair_center.p3d","ca\buildings2\church_01\church_01.p3d","ca\buildings2\farm_wtower\farm_wtower.p3d","ca\buildings\hlidac_budka.p3d","ca\structures\ind_sawmill\ind_sawmill.p3d","ca\structures\house\housev2\housev2_03.p3d","ca\buildings\komin.p3d","ca\buildings2\shed_wooden\shed_wooden.p3d","ca\structures\ind_sawmill\ind_sawmillpen.p3d","ca\structures\ind_quarry\ind_quarry.p3d","a3\structures_f\households\addons\i_garage_v2_f.p3d","a3\structures_f\households\house_big01\u_house_big_01_v1_f.p3d","a3\structures_f\households\house_big02\u_house_big_02_v1_f.p3d","a3\structures_f\households\house_big01\d_house_big_01_v1_f.p3d","a3\structures_f\households\house_big02\u_house_big_02_v1_dam_f.p3d","a3\structures_f\households\house_small02\d_house_small_02_v1_f.p3d","a3\structures_f\households\house_small02\i_house_small_02_v3_f.p3d","ca\structures\house\housev\housev_1i4.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v1_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v3_f.p3d","a3\structures_f\households\stone_shed\i_stone_shed_v2_f.p3d","a3\structures_f\households\house_small01\i_house_small_01_v2_dam_f.p3d","a3\structures_f\households\wip\unfinished_building_01_f.p3d","ca\buildings2\houseblocks\houseblock_c\houseblock_c5.p3d","ca\buildings2\houseblocks\houseblock_a\houseblock_a2_1.p3d","ca\buildings2\a_pub\a_pub_01.p3d","ca\buildings2\houseblocks\houseblock_a\houseblock_a1_2.p3d","ca\buildings2\houseblocks\houseblock_b\houseblock_b2.p3d","ca\buildings2\houseblocks\houseblock_b\houseblock_b5.p3d","ca\buildings2\houseblocks\houseblock_b\houseblock_b6.p3d","ca\buildings2\houseblocks\houseblock_b\houseblock_b4.p3d","ca\structures\house\a_hospital\a_hospital.p3d","ca\buildings2\ind_workshop01\ind_workshop01_box.p3d","a3\structures_f\households\wip\unfinished_building_02_f.p3d","ca\buildings2\a_generalstore_01\a_generalstore_01.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v1_dam_f.p3d","a3\structures_f\households\stone_shed\i_stone_shed_v1_dam_f.p3d","a3\structures_f\households\stone_small\i_stone_housesmall_v2_f.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v3_f.p3d","a3\structures_f\households\stone_shed\i_stone_shed_v3_f.p3d","a3\structures_f\households\house_big02\i_house_big_02_v3_dam_f.p3d","ca\buildings2\barn_metal\barn_metal.p3d","ca\structures\house\church_02\church_02.p3d","a3\structures_f\households\addons\i_garage_v1_dam_f.p3d","a3\structures_f\households\house_small02\u_house_small_02_v1_f.p3d","a3\structures_f\households\slum\slum_house02_f.p3d","a3\structures_f\households\slum\slum_house01_f.p3d","a3\structures_f\households\house_small03\i_house_small_03_v1_f.p3d","ca\structures\house\church_03\church_03.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v1_f.p3d","a3\structures_f\households\house_small01\u_house_small_01_v1_dam_f.p3d","a3\structures_f\households\house_big01\i_house_big_01_v1_dam_f.p3d","a3\structures_f\households\slum\slum_house03_f.p3d","ca\structures\house\a_stationhouse\a_stationhouse.p3d","ca\buildings2\houseblocks\houseblock_c\houseblock_c2.p3d","ca\buildings2\houseblocks\houseblock_c\houseblock_c3.p3d","ca\buildings2\houseblocks\houseblock_b\houseblock_b3.p3d","ca\buildings2\houseblocks\houseblock_a\houseblock_a1.p3d","a3\structures_f\households\stone_big\i_stone_housebig_v2_f.p3d","ca\structures\house\church_05r\church_05r.p3d","a3\structures_f\households\stone_small\d_stone_housesmall_v1_f.p3d","a3\structures_f\households\stone_big\d_stone_housebig_v1_f.p3d"];
ALIVE_civilianPowerBuildingTypes = ALIVE_civilianPowerBuildingTypes + ["ca\buildings\trafostanica_velka.p3d","ca\buildings2\misc_powerstation\misc_powerstation.p3d"];
ALIVE_civilianCommsBuildingTypes = ALIVE_civilianCommsBuildingTypes + [];
ALIVE_civilianMarineBuildingTypes = ALIVE_civilianMarineBuildingTypes + [];
ALIVE_civilianRailBuildingTypes = ALIVE_civilianRailBuildingTypes + [];
ALIVE_civilianFuelBuildingTypes = ALIVE_civilianFuelBuildingTypes + ["ca\structures\house\a_fuelstation\a_fuelstation_feed.p3d","ca\structures\house\a_fuelstation\a_fuelstation_shed.p3d","ca\structures\house\a_fuelstation\a_fuelstation_build.p3d"];
ALIVE_civilianConstructionBuildingTypes = ALIVE_civilianConstructionBuildingTypes + ["a3\structures_f\households\wip\unfinished_building_01_f.p3d","a3\structures_f\households\wip\unfinished_building_02_f.p3d"];
};
