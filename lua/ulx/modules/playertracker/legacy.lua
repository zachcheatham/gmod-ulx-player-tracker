local function updateExistingPlayer(localPlayerData, remotePlayerData)
	local queryStr = "UPDATE `player_tracker` SET "
	local hasUpdate = false
	
	if localPlayerData.last_seen > remotePlayerData.last_seen then
		queryStr = queryStr .. "`name` = '" .. ZCore.MySQL.escapeStr(localPlayerData.name) .. "', `last_seen` = " .. localPlayerData.last_seen
		hasUpdate = true
	end
	
	if localPlayerData.first_seen < remotePlayerData.first_seen then
		queryStr = queryStr .. (hasUpdate and ", " or "") .. "`first_seen` = " .. ZCore.MySQL.escapeStr(localPlayerData.first_seen)
		hasUpdate = true
	end
	
	if hasUpdate then
		queryStr = queryStr .. " WHERE `steamid` = '" .. remotePlayerData.steamid .. "'"
		ZCore.MySQL.query(queryStr)
	end
end

local function insertPlayer(playerData)
	playerData.ip = string.Replace(playerData.ip, "'", "")

	if playerData.ip_2 then
		playerData.ip_2 = "'" .. string.Replace(playerData.ip_2, "'", "") .. "'"
	else
		playerData.ip_2 = "NULL"
	end
	
	if playerData.ip_3 then
		playerData.ip_3 = "'" .. string.Replace(playerData.ip_3, "'", "") .. "'"
	else
		playerData.ip_3 = "NULL"
	end
	
	if playerData.owner_steam_id and playerData.owner_steam_id ~= 0 then
		playerData.owner_steam_id = "'" .. playerData.owner_steam_id .. "'"
	else
		playerData.owner_steam_id = "NULL"
	end

	local queryStr = [[
		INSERT INTO `player_tracker`
			(
				`steamid`,
				`name`,
				`owner_steamid`,
				`ip`,
				`ip_2`,
				`ip_3`,
				`first_seen`,
				`last_seen`
			)
			
			VALUES(
				']] .. playerData.steam_id .. [[',
				']] .. ZCore.MySQL.escapeStr(playerData.name) .. [[',
				]] .. playerData.owner_steam_id .. [[,
				']] .. playerData.ip .. [[',
				]] .. playerData.ip_2 .. [[,
				]] .. playerData.ip_3 .. [[,
				]] .. playerData.first_seen .. [[,
				]] .. playerData.last_seen .. [[
			)
	]]
	
	ZCore.MySQL.query(queryStr)
end

local function updateExistingName(localNameData, remoteNameData)
	if localNameData.timestamp > remoteNameData.timestamp then
		local queryStr = "UPDATE `player_tracker_names` SET `timestamp` = " .. localNameData.timestamp .. " WHERE `steamid` = '" .. remoteNameData.steamid .. "' AND `name` = '" .. ZCore.MySQL.escapeStr(remoteNameData.name) .. "'"
		ZCore.MySQL.query(queryStr)
	end
end

local function insertName(nameData)
	local queryStr = [[
		REPLACE INTO `player_tracker_names`
			(
				`steamid`,
				`name`,
				`timestamp`
			)
			VALUES(
				']] .. nameData.steam_id .. [[',
				']] .. ZCore.MySQL.escapeStr(nameData.name) .. [[',
				]] .. nameData.timestamp .. [[
			)
	]]
	
	ZCore.MySQL.query(queryStr)
end

function ulx.PlayerTracker.transferOldDatabase()
	if sql.TableExists("player_tracker") then
		ServerLog("[PlayerTracker] Detected old database. Preparing to transfer...\n")
		
		local players = sql.Query("SELECT * FROM `player_tracker`")
		for _, player in ipairs(players) do		
			player = ZCore.MySQL.cleanSQLRow(player)
			
			local playerQuery = "SELECT * FROM `player_tracker` WHERE `steamid` = '" .. player.steam_id .. "'"
			
			ZCore.MySQL.queryRow(playerQuery, function(data)
				if data then
					updateExistingPlayer(player, ZCore.MySQL.cleanSQLRow(data))
				else
					insertPlayer(player)
				end
			end)
		end
		
		local names = sql.Query("SELECT * FROM `player_tracker_names`")
		for _, name in ipairs(names) do		
			name = ZCore.MySQL.cleanSQLRow(name)
			
			local nameQuery = "SELECT * FROM `player_tracker_names` WHERE `steamid` = '" .. name.steam_id .. "' AND `name` LIKE '" .. ZCore.MySQL.escapeStr(name.name) .. "'"
			
			ZCore.MySQL.queryRow(nameQuery, function(data)			
				if data then
					updateExistingName(name, ZCore.MySQL.cleanSQLRow(data))
				else
					insertName(name)
				end
			end)
		end
		
		sql.Query("DELETE FROM `player_tracker`")
		sql.Query("DROP TABLE `player_tracker`")
		sql.Query("DELETE FROM `player_tracker_names`")
		sql.Query("DROP TABLE `player_tracker_names`")

		ServerLog("[PlayerTracker] Completed. Old database wiped! Server will probably lag now while all the queries finish!!!\n")
		ServerLog("[PlayerTracker] DO NOT KILL THE SERVER DURING THIS PROCESS!\n")
	end
end

ulx.PlayerTracker.transferOldDatabase()