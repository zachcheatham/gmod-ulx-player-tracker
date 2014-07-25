local DATA_CHUNK_SIZE = 60

local playertracker = {}

function playertracker.getData()
	local result = sql.Query("SELECT * FROM `player_tracker` ORDER BY `last_seen` DESC LIMIT 100")
	local data = {}
	
	if result == false then
		error("Error getting entries from database! SQL Error: " .. sql.LastError(result))
	elseif result then
		for i, v in ipairs(result) do
			if v.owner_steam_id == "0" then
				v.owner_steam_id = nil
			end
			
			if v.ip_2 == "NULL" then v.ip_2 = nil end
			if v.ip_3 == "NULL" then v.ip_3 = nil end
			if v.owner_steam_id == "NULL" then v.owner_steam_id = nil end

			data[v.steam_id] = v
			data[v.steam_id].steam_id = nil
		end
	end	
	
	return data
end

function playertracker.search(ply, args)
	local searchID = args[1]
	table.remove(args, 1)

	local searchTerm = ""
	for _, v in ipairs(args) do
		searchTerm = searchTerm .. " " .. v
	end
	searchTerm = sql.SQLStr(searchTerm:gsub("^%s*(.-)%s*$", "%1"), true)

	local result = false
	
	if ULib.isValidSteamID(searchTerm) then
		result = sql.Query("SELECT * FROM `player_tracker` WHERE `steam_id` = '" .. searchTerm .. "' OR `owner_steam_id` = '" .. searchTerm .. "' ORDER BY `last_seen`")
	elseif ULib.isValidIP(searchTerm) then
		result = sql.Query("SELECT * FROM `player_tracker` WHERE `ip` = '" .. searchTerm .. "' OR `ip_2` = '" .. searchTerm .. "' OR `ip_3` = '" .. searchTerm .. "' ORDER BY `last_seen`")
	else
		result = sql.Query("SELECT * FROM `player_tracker` WHERE `name` LIKE '%" .. searchTerm .. "%' ORDER BY `last_seen`")
	end
	
	if result == false then
		error("Error searching for player in database! SQL Error: " .. sql.LastError(result))
	end
	
	local data = {}
	
	if result then
		for _, v in ipairs(result) do
			if v.owner_steam_id == "0" then
				v.owner_steam_id = nil
			end
			
			if v.ip_2 == "NULL" then v.ip_2 = nil end
			if v.ip_3 == "NULL" then v.ip_3 = nil end
			if v.owner_steam_id == "NULL" then v.owner_steam_id = nil end

			data[v.steam_id] = v
			data[v.steam_id].steam_id = nil
		end
	end
	
	local chunk = {}
	for k, v in pairs(data) do
		chunk[k] = v
		
		if table.Count(chunk) >= DATA_CHUNK_SIZE then
			ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
			chunk = {}
		end
	end
	
	ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
	ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchCompleted", searchID)
end

function playertracker.init()
	ULib.ucl.registerAccess("xgui_playertracker", "admin", "Allows the view of the player tracker.", "XGUI")

	xgui.addDataType("playertracker", playertracker.getData, "xgui_playertracker", DATA_CHUNK_SIZE, 0)
	
	xgui.addCmd("pt_search", playertracker.search)
	xgui.addCmd("pt_names", playertracker.getnames)
end

xgui.addSVModule("playertracker", playertracker.init)