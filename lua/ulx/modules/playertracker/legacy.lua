local function updateExistingPlayer(localPlayerData, remotePlayerData, callback)
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
		ZCore.MySQL.query(queryStr, callback)
	else
		callback()
	end
end

local function insertPlayer(playerData, callback)
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
	
	ZCore.MySQL.query(queryStr, callback)
end

local function updateExistingName(localNameData, remoteNameData, callback)
	if localNameData.timestamp > remoteNameData.timestamp then
		local queryStr = "UPDATE `player_tracker_names` SET `timestamp` = " .. localNameData.timestamp .. " WHERE `steamid` = '" .. remoteNameData.steamid .. "' AND `name` = '" .. ZCore.MySQL.escapeStr(remoteNameData.name) .. "'"
		ZCore.MySQL.query(queryStr, callback)
	else
		callback()
	end
end

local function insertName(nameData, callback)
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
	
	ZCore.MySQL.query(queryStr, callback)
end

local nameQueue = {}
local playerQueue = {}

local totalPlayers = 0
local completedPlayers = 0
local totalNames = 0
local completedNames = 0

local function queueComplete()
	sql.Query("DELETE FROM `player_tracker`")
	sql.Query("DROP TABLE `player_tracker`")
	sql.Query("DELETE FROM `player_tracker_names`")
	sql.Query("DROP TABLE `player_tracker_names`")
	
	ULib.tsay(_, "[PlayerTracker] Completed transfer. Refreshing map...")
	ServerLog("[PlayerTracker] Completed transferring database.\n")
	
	--[[timer.Simple(2, function()
		RunConsoleCommand("ulx", "map", game.GetMap())
	end)]]--
end

local function processNameQueue()
	local key = table.GetFirstKey(nameQueue)
	local tables = table.GetFirstValue(nameQueue)
	table.remove(nameQueue, key)
	
	local function onCompletion()
		local lresult = sql.Query("DELETE FROM `player_tracker_names` WHERE `steam_id` = " .. sql.SQLStr(tables[1].steam_id) .. " AND `name` = " .. sql.SQLStr(tables[1].name))
		if lresult == false then
			ErrorNoHalt("[PlayerTracker] Warning: Unable to remove entry from legacy database: " .. sql.LastError())
		end
	
		completedNames = completedNames + 1
		
		if completedNames % 100 == 0 then
			ULib.tsay(_, "[PlayerTracker] Transferring names... (" .. completedNames .. "/" .. totalNames .. ")")
		end
		
		if completedNames == totalNames then
			queueComplete()
		else
			processNameQueue()
		end
	end
	
	if tables[2] then
		updateExistingName(tables[1], tables[2], onCompletion)
	else
		insertName(tables[1], onCompletion)
	end
end

local function processPlayerQueue()
	local key = table.GetFirstKey(playerQueue)
	local tables = table.GetFirstValue(playerQueue)
	table.remove(playerQueue, key)
	
	local function onCompletion()
		local lresult = sql.Query("DELETE FROM `player_tracker` WHERE `steam_id` = " .. sql.SQLStr(tables[1].steam_id))
		if lresult == false then
			ErrorNoHalt("[PlayerTracker] Warning: Unable to remove entry from legacy database: " .. sql.LastError())
		end
	
		completedPlayers = completedPlayers + 1
		if completedPlayers % 100 == 0 then
			ULib.tsay(_, "[PlayerTracker] Transferring players... (" .. completedPlayers .. "/" .. totalPlayers .. ")")
		end
		
		if completedPlayers == totalPlayers then
			if totalNames > 0 then
				ULib.tsay(_, "[PlayerTracker] Now transferring player names.")
				ServerLog("[PlayerTracker] Now transferring player names.\n")
				processNameQueue()
			else
				queueComplete()
			end
		else
			processPlayerQueue()
		end
	end
	
	if tables[2] then
		updateExistingPlayer(tables[1], tables[2], onCompletion)
	else
		insertPlayer(tables[1], onCompletion)
	end
end

local transferStarted = false
local function startQueue()
	if transferStarted then
		error("Attempted to start transfer a second time!\n")
		return
	end
	transferStarted = true
	
	--ULib.tsay(_, "[PlayerTracker] Beginning database transfer...")
	ServerLog("[PlayerTracker] Transfer started.\n")
	ServerLog("[PlayerTracker] Total Players: " .. totalPlayers .. "\n")
	ServerLog("[PlayerTracker] Total Names: " .. totalNames .. "\n")
	
	completedPlayers = 0
	completedNames = 0
	
	if totalPlayers > 0 then
		processPlayerQueue()
	elseif totalNames > 0 then
		processNameQueue()
	else
		queueComplete()
	end
end

function ulx.PlayerTracker.transferOldDatabase()
	if sql.TableExists("player_tracker") then
		ServerLog("[PlayerTracker] Detected old database. Preparing transfer...\n")
		
		local players = sql.Query("SELECT * FROM `player_tracker`")
		totalPlayers = players and table.Count(players) or 0
		
		local names = sql.Query("SELECT * FROM `player_tracker_names`")
		totalNames = names and table.Count(names) or 0
		
		if totalPlayers > 0 then
			for _, playerData in ipairs(players) do
				playerData = ZCore.MySQL.cleanSQLRow(playerData)
				
				local playerQuery = "SELECT * FROM `player_tracker` WHERE `steamid` = '" .. playerData.steam_id .. "'"
				ZCore.MySQL.queryRow(playerQuery, function(data)
					completedPlayers = completedPlayers + 1
					table.insert(playerQueue, {playerData, data})
					
					if completedPlayers == totalPlayers and completedNames == totalNames then
						startQueue()
					end
				end)
			end
		end
		
		if totalNames > 0 then
			for _, name in ipairs(names) do		
				name = ZCore.MySQL.cleanSQLRow(name)
				
				local nameQuery = "SELECT * FROM `player_tracker_names` WHERE `steamid` = '" .. name.steam_id .. "' AND `name` LIKE '" .. ZCore.MySQL.escapeStr(name.name) .. "'"
				ZCore.MySQL.queryRow(nameQuery, function(data)
					completedNames = completedNames + 1
					table.insert(nameQueue, {name, data})
					
					if completedPlayers == totalPlayers and completedNames == totalNames then
						startQueue()
					end
				end)
			end
		end
		
		if totalNames == 0 and totalPlayers == 0 then
			queueComplete()
		end
	end
end