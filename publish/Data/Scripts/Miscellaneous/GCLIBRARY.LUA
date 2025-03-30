-- Sleep() doesn't work for me :(
function wait(seconds)
	local t = GetCurrentTime.Frame()
	while t + seconds <= GetCurrentTime.Frame() do -- nothing
	end
end

function table_contains(tbl, x)
	found = false
	for _, v in pairs(tbl) do
		if v == x then
			found = true
			break
		end
	end
	return found
end

function Add_Unit(unit_type, player)
	Reinforce_Unit(Find_Object_Type(unit_type), false, player, true, true)
end

indigenous = {"HUTT_CIVILIAN", "IMPERIAL_ELITE_GUARD", "TWILEK_FEMALE", "SAND_PERSON_SNIPER_A", "SAND_PERSON_SNIPER_B",
				"JAWA_SCOUT", "WOOKIE_WARRIOR", "WOOKIE_WARRIOR_UNARMED", "EWOK_HUNTER", "CIVILIAN_INDEPENDENT_AI",
				"GUNGAN_WARRIOR", "DUST_DEVIL", "DESERT_SKETTO", "RANCOR", "WAMPA", "DATHOMIR_NIGHT_SISTER",
				"PYNGANI_WARRIOR", "GEONOSIAN", "IMPERIAL_GUARD_SPAWNER", "SULLUST_CAVE_COMPLEX_ENTRY",
				"JAWA_SANDCRAWLER", "WOOKIEE_HOUSE", "SANDPEOPLE_DWELLING", "VORNSKR_WOLF_INDIG", "PIRATE_GROUND_BASE_1"}

function Is_Indigenous(unit)
	local type_name = unit.Get_Type().Get_Name()
	return
		string.find(type_name, "_SPAWN") or string.find(type_name, "_CIV") or string.find(type_name, "_INDIGENOUS") or
			table_contains(indigenous, type_name)
end

function Change_Control_Indigenous(player, battle_participants)
	local player_unit_list = Find_All_Objects_Of_Type("Infantry | Structure")
	for k, unit in pairs(player_unit_list) do
		-- if unit is indigenous and its owner is not battle participant, change owner to third player
		if Is_Indigenous(unit) and not battle_participants[unit.Get_Owner()] then
			unit.Change_Owner(player)
		end
	end
end

reinforcement_points_types = {"REINFORCEMENT_POINT_PLUS1_CAP", "REINFORCEMENT_POINT_PLUS2_CAP", "REINFORCEMENT_POINT_PLUS3_CAP",
						"REINFORCEMENT_POINT_PLUS4_CAP", "REINFORCEMENT_POINT_PLUS5_CAP","REINFORCEMENT_POINT_PLUS10_CAP"}

function Get_All_Reinforcement_Points()
	local reinforcement_points = {}
	
	return reinforcement_points
end

function Change_Control_Landing_Zones(player, battle_participants)
	for _, point in pairs(reinforcement_points_types) do
		local cap_points = Find_All_Objects_Of_Type(point)
		for k, landing_zone in pairs(cap_points) do
			local nearest_enemy_unit = Find_Nearest(landing_zone, player, false)
			-- prevent LZ being given to the third player if it's too close to the enemy
			if not battle_participants[landing_zone.Get_Owner()] and landing_zone.Get_Distance(nearest_enemy_unit) > 125 then
				landing_zone.Change_Owner(player)
			end
		end
	end
end

function Spawn_Units(player)
	if StringCompare(Get_Game_Mode(), "Space") then
		Add_Unit("Z95_Headhunter_Squadron", player)
		Add_Unit("VWing_Squadron_P", player)
		Add_Unit("Pirate_Fighter_Squadron", player)
		Add_Unit("Merchant_Freighter", player)
		Add_Unit("Merchant_Freighter", player)
		if GameRandom.Get_Float() < 0.1 then
			Add_Objective("Our sensors have detected presense of a medium-size pirate fleet in the system!", true)
			Add_Unit("IPV1_System_Patrol_Craft", player)
			Add_Unit("IPV1_System_Patrol_Craft", player)
			Add_Unit("Pirate_Frigate", player)
			Add_Unit("Pirate_Frigate", player)
			Add_Unit("Jedi_Cruiser", player)
		end
		-- eastern egg
		if GameRandom.Get_Float() < 0.01 then
			Add_Unit("Death_Star", player)
		end
	else
		Add_Unit("Mandalorian_Indigenous_Company", player)
		Add_Unit("Noghri_Indigenous_Company", player)
		Add_Unit("Kashyyyk_Wookie_War_Party", player)
		Add_Unit("Sandpeople_War_Party", player)
		if GameRandom.Get_Float() < 0.25 then
			Add_Objective("We have reports of mandalorians who were hired to fight against us!", true)
			Add_Unit("Mandalorian_Indigenous_Company", player)
			Add_Unit("Mandalorian_Indigenous_Company", player)
			Add_Unit("Mandalorian_Indigenous_Company", player)
			Add_Unit("Mandalorian_Indigenous_Company", player)
			Add_Unit("Mandalorian_Indigenous_Company", player)
			Add_Unit("Mandalorian_Indigenous_Company", player)
		end
	end
end

function Apply_3rd_Player_Game_Mode(player, battle_participants)
	Add_Objective("It's possible that the third player is participating in the battle, be cautious!", true)
	FogOfWar.Reveal_All(player)
	Change_Control_Landing_Zones(player, battle_participants)
	Change_Control_Indigenous(player, battle_participants)
	Spawn_Units(player)
end

function Has_Valid_Units(player)
	local player_unit_list = Find_All_Objects_Of_Type(player)
	local has_valid_units = false
	for k, unit in pairs(player_unit_list) do
		if (unit.Is_Selectable()) and not Is_Indigenous(unit) then
			has_valid_units = true
			break
		end
	end
	return has_valid_units
end

-- printing unit: Add_Objective(tostring(nearest_enemy_unit.Get_Type().Get_Name()), false)

function Reveal_For_Specators()
	wait(25)
	local underworld = Find_Player("Underworld")
	local rebel = Find_Player("Rebel")
	local empire = Find_Player("Empire")
	local is_underworld_present = Has_Valid_Units(underworld)
	local is_rebel_present = Has_Valid_Units(rebel)
	local is_empire_present = Has_Valid_Units(empire)
	local battle_participants = {}
	local third_player = nil
	if not is_underworld_present then
		battle_participants[rebel] = true
		battle_participants[empire] = true
		third_player = underworld
	end
	if not is_rebel_present then
		battle_participants[underworld] = true
		battle_participants[empire] = true
		third_player = rebel
	end
	if not is_empire_present then
		battle_participants[underworld] = true
		battle_participants[rebel] = true
		third_player = empire
	end

	if third_player then
		Apply_3rd_Player_Game_Mode(third_player, battle_participants)
	end
end
