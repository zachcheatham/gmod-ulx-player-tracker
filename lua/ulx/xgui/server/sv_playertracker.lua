local DATA_CHUNK_SIZE = 60
local DATA_NAMES_CHUNK_SIZE = 100
local RECENT_PLAYERS_SIZE = 100

ulx.PlayerTracker.xgui = {}
local recentPlayers = false

-- Grabs players who are activated and have permissions to view playertracker
local function getReadyPlayers()
	local players = {}

	for _, v in pairs(player.GetAll()) do
		if xgui.readyPlayers[v:UniqueID()] and v:query("xgui_playertracker") then
			table.insert(players , v)
		end
	end
	
	return players
end

-- Used to remove unnecessary player data and formats certain items before sending it
local function preparePlayerData(data)
	local newData = table.Copy(data)

	newData.steamid = nil
	if newData.owner_steamid == 0 then
		newData.owner_steamid = nil
	end
	
	return newData
end

-- Removes the oldest player from the recent players table
local function removeOldestRecent()
	local oldestSteamID
	local oldestTimestamp
	
	for steamID, playerData in pairs(recentPlayers) do
		if not oldestTimestamp or playerData.last_seen < oldestTimestamp then
			oldestSteamID = steamID
			oldestTimestamp = playerData.last_seen
		end
	end
	
	readyPlayers[oldestSteamID] = nil
end

function ulx.PlayerTracker.xgui.addPlayer(steamID, playerData)
	-- Send out to admins
	local t = {}
	t[steamID] = preparePlayerData(playerData)
	local sendPlys = getReadyPlayers()
	if #sendPlys > 0 then
		//print "AddPlayer"
		//PrintTable(sendPlys)	
		xgui.addData(sendPlys, "playertracker", t)
	end
	
	-- Insert into local recents table
	if recentPlayers and not recentPlayers[steamID] then
		recentPlayers[steamID] = t[steamID]
		
		local recentTableOverflow = table.Count(readPlayers) - RECENT_PLAYERS_SIZE
		
		if recentTableOverflow > 1 then
			ServerLog("[PlayerTracker] Warning: Recent players table has an overflow greater than one. This is a sign of a programming error!")
		end
		
		while recentTableOverflow > 0 do
			removeOldestRecent()
			recentTableOverflow = recentTableOverflow - 1
		end
	end
end

local function getRecents()
	if not recentPlayers then
		ulx.PlayerTracker.fetchRecentPlayers(function(players)
			recentPlayers = {}
			for _, v in ipairs(players) do
				recentPlayers[v.steamid] = preparePlayerData(v)
			end

			-- This is causing dupes
			/*local sendPlys = getReadyPlayers()
			if #sendPlys > 0 then
				xgui.addData(sendPlys, "playertracker", recentPlayers)
			end*/
		end)
		
		recentPlayers = {} -- Make this not false because xgui tends to call this function multiple times in a row
		return {}
	else
		return recentPlayers
	end
end
--hook.Add("ZCore_MySQL_Connected", "XGUI_GetPlayers", getRecents)

local function search(ply, args)
	local searchID = args[1]
	table.remove(args, 1)
	
	local exactMatch = args[1] == "1"
	table.remove(args, 1)

	local searchTerm = ""
	for _, v in ipairs(args) do
		searchTerm = searchTerm .. " " .. v
	end
	
	ulx.PlayerTracker.search(searchTerm, exactMatch, function(data)
		local chunk = {}
		for _, v in ipairs(data) do
			chunk[v.steamid] = preparePlayerData(v)
			
			if table.Count(chunk) >= DATA_CHUNK_SIZE then
				ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
				chunk = {}
			end
		end
		
		ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
		ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchCompleted", searchID)
	end)	
end

local function getNames(ply, args)
	local steamID = ""
	for _, v in ipairs(args) do
		steamID = steamID .. v
	end
	
	ulx.PlayerTracker.fetchNames(steamID, function(names)
		local chunk = {}
		for _, v in ipairs(names) do
			table.insert(chunk, v)
			
			if table.Count(chunk) >= DATA_NAMES_CHUNK_SIZE then
				ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.recievedNames", steamID, chunk)
				chunk = {}
			end
		end
		
		ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.recievedNames", steamID, chunk)
	end)
end

local function init()
	ULib.ucl.registerAccess("xgui_playertracker", "admin", "Allows admins to view player tracker.", "XGUI")

	xgui.addDataType("playertracker", getRecents, "xgui_playertracker", DATA_CHUNK_SIZE, 0)
	
	xgui.addCmd("pt_search", search)
	xgui.addCmd("pt_names", getNames)
end

xgui.addSVModule("playertracker", init)