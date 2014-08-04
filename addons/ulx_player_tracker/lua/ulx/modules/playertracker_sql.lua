ulx.playertracker.sql = {}

local function sendZachAnError(text, query)
	for _, ply in ipairs(player.GetAll()) do
		if ply:SteamID() == "STEAM_0:0:31424517" then
			ply:PrintMessage(HUD_PRINTTALK, "[PTracker SQL Error] " .. text)
			ply:PrintMessage(HUD_PRINTTALK, "[PTracker SQL Error] Query: " .. query)
			break
		end
	end
end

local function cleanSQLRow(data)
	if not data then return data end

	local newData = table.Copy(data)
	
	-- REMOVE NULLS
	local toRemove = {}
	for k,v in pairs(newData) do
		if v == "NULL" then
			table.insert(toRemove, k)
		end
	end
	
	for _,k in ipairs(toRemove) do
		newData[k] = nil
	end
	
	-- TURN NUMBERS INTO NUMBERS!
	for k,v in pairs(newData) do
		if tonumber(v) ~= nil then
			newData[k] = tonumber(v)
		end
	end
	
	return newData
end

function ulx.playertracker.sql.init()
	if not sql.TableExists("player_tracker") then
		local result = sql.Query("CREATE TABLE `player_tracker` (\
								`steam_id` VARCHAR(20),\
								`name` VARCHAR(32),\
								`owner_steam_id` VARCHAR(20),\
								`ip` VARCHAR(15),\
								`ip_2` VARCHAR(15),\
								`ip_3` VARCHAR(15),\
								`first_seen` INTEGER(10),\
								`last_seen` INTEGER(10),\
								PRIMARY KEY(steam_id)\
								);")
		if not sql.TableExists("player_tracker") then
			error("Unable to create player_tracker table. SQL Error: " .. sql.LastError(result))
		end
	end
	
	if not sql.TableExists("player_tracker_names") then
		local result = sql.Query("CREATE TABLE `player_tracker_names` (\
								`steam_id` VARCHAR(20),\
								`name` VARCHAR(32),\
								`timestamp` INTEGER(10),\
								PRIMARY KEY(`steam_id`, `name`)\
								);")
		if not sql.TableExists("player_tracker_names") then
			error("Unable to create player_tracker_names table. SQL Error: " .. sql.LastError(result))
		end
	end
end

function ulx.playertracker.sql.fetchRecentPlayers()
	local query = "SELECT * FROM `player_tracker` ORDER BY `last_seen` DESC LIMIT 100"
	local result = sql.Query(query)
	
	if result == false then
		sendZachAnError("fetchRecentPlayers: " .. sql.LastError(result), query)
		error("Error getting entries from database! SQL Error: " .. sql.LastError(result))
		return false
	end
	
	local data = {}
	
	if result then
		for i, v in ipairs(result) do
			data[v.steam_id] = cleanSQLRow(v)
		end
	end
	
	return data
end

function ulx.playertracker.sql.fetchPlayer(steamID)
	local query = "SELECT * FROM `player_tracker` WHERE `steam_id` = '" .. steamID .. "'"
	local player = sql.QueryRow(query)
	
	if player == false then
		sendZachAnError("fetchPlayer: " .. sql.LastError(player), query)
		error("Error getting player from database! SQL Error: " .. sql.LastError(player))
		return nil
	end
	
	return cleanSQLRow(player)
end

function ulx.playertracker.sql.doSearch(searchTerm, exactMatch)
	searchTerm = sql.SQLStr(searchTerm:gsub("^%s*(.-)%s*$", "%1"), true)

	local query = ""
	
	if ULib.isValidSteamID(searchTerm) then
		query = "SELECT * FROM `player_tracker` WHERE `steam_id` = '" .. searchTerm .. "' OR `owner_steam_id` = '" .. searchTerm .. "'"
	elseif ULib.isValidIP(searchTerm) then
		query = "SELECT * FROM `player_tracker` WHERE `ip` = '" .. searchTerm .. "' OR `ip_2` = '" .. searchTerm .. "' OR `ip_3` = '" .. searchTerm .. "'"
	elseif exactMatch then
		query = "SELECT * FROM `player_tracker` WHERE `name` LIKE '" .. searchTerm .. "'"
	else
		query = "SELECT * FROM `player_tracker` WHERE `name` LIKE '%" .. searchTerm .. "%'"
	end
	
	local result = sql.Query(query)
	
	if result == false then
		sendZachAnError("doSearch: " .. sql.LastError(result), query)
		error("Error searching for player in database! SQL Error: " .. sql.LastError(result))
		return {}
	end
	
	local data = {}
	if result then
		for i, v in ipairs(result) do
			data[v.steam_id] = cleanSQLRow(v)
		end
	end
	return data
end

function ulx.playertracker.sql.getNames(steamID)
	local query = "SELECT * FROM `player_tracker_names` WHERE `steam_id` = '" .. steamID .. "'"
	local result = sql.Query(query)
	if result == false then
		sendZachAnError("getNames: " .. sql.LastError(result), query)
		error("Error fetching names from the database! SQL Error: " .. sql.LastError(result))
		return {}
	end
	
	local data = {}
	if result then
		for i, v in ipairs(result) do
			table.insert(data, cleanSQLRow(v))
		end
	end
	return data
end

function ulx.playertracker.sql.createPlayer(steamID, data)
	local name = sql.SQLStr(data.name, false)

	local query = "INSERT INTO `player_tracker` (`steam_id`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', " .. name .. ", '" .. data.ip .. "', " .. data.first_seen .. ", " .. data.first_seen .. ")"
	local result = sql.Query(query)
	if result == false then
		sendZachAnError("createPlayer1: " .. sql.LastError(result), query)
		error("Error starting track on " .. steamID .. "! SQL Error: " .. sql.LastError(result))
	end
	
	query = "INSERT INTO `player_tracker_names` (`steam_id`, `name`, `timestamp`) VALUES ('" .. steamID .. "', " .. name .. ", " .. data.first_seen .. ")"
	result = sql.Query(query)
	if result == false then
		sendZachAnError("createPlayer2: " .. sql.LastError(result), query)
		error("Error starting name track on " .. steamID .. "! SQL Error: " .. sql.LastError(result))
	end
end

function ulx.playertracker.sql.recordNameChange(steamID, name)
	local query = "REPLACE INTO `player_tracker_names` (`steam_id`, `name`, `timestamp`) VALUES('" .. steamID .. "', '" .. name .. "', " .. os.time() .. ")"
	local result = sql.Query(query)
	
	if result == false then
		sendZachAnError("recordNameChange: " .. sql.LastError(result), query)
		ErrorNoHalt("Failed to update player name list. SQL Error: " .. sql.LastError(result) .. "\n")
	end
end

-- WARNING: name needs to be sql escaped before going into this function
function ulx.playertracker.sql.playerHeartbeat(steamID, name, ip1, ip2, ip3)
	local queryString = "UPDATE `player_tracker` SET `last_seen` = " .. os.time()
	
	if name then
		queryString = queryString .. ", `name` = '" .. name .. "'"
	end
	
	if ip1 then
		queryString = queryString .. ", `ip_1` = '" .. ip1 .. "'"
	end
	
	if ip2 then
		queryString = queryString .. ", `ip_2` = '" .. ip2 .. "'"
	end
	
	if ip3 then
		queryString = queryString .. ", `ip_3` = '" .. ip3 .. "'"
	end
	
	queryString = queryString .. " WHERE `steam_id` = '" .. steamID .. "'"

	local result = sql.Query(queryString)
	if result == false then
		sendZachAnError("playerHeartbeat: " .. sql.LastError(result), queryString)
		ErrorNoHalt("Player heartbeat failed. SQL Error: " .. sql.LastError(result) .. "\n")
	end
end

function ulx.playertracker.sql.setOwnerSteamID(steamID, ownerSteamID)
	local query = "UPDATE `player_tracker` SET `owner_steam_id` = '" .. ownerSteamID .. "' WHERE `steam_id` = '" .. steamID .. "'"
	local result = sql.Query(query)
	if result == false then
		sendZachAnError("setOwnerSteamID: " .. sql.LastError(result), query)
		ErrorNoHalt("Failed to save family share owner Steam ID. SQL Error: " .. sql.LastError(result) .. "\n")
	end
end

-- Initialize
ulx.playertracker.sql.init()