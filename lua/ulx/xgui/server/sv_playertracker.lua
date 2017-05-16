local DATA_CHUNK_SIZE = 60
local DATA_NAMES_CHUNK_SIZE = 100
local RECENT_PLAYERS_SIZE = 100

ulx.PlayerTracker.xgui = {}
local recentPlayers = {}

-- Grabs players who are activated and have permissions to view playertracker
local function getReadyPlayers()
	local players = {}

	if player.GetAll() then
		for _, v in pairs(player.GetAll()) do
			if xgui.readyPlayers[v:UniqueID()] and v:query("xgui_playertracker") then
				table.insert(players , v)
			end
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

local function removeOldRecents()
	local recentTableOverflow = table.Count(recentPlayers) - RECENT_PLAYERS_SIZE

    -- Remove old recents so we don't use up all our memory!
    -- Helps servers that don't change map often e.g. sandbox and darkrp
	while recentTableOverflow > 0 do
        local oldestSteamID
    	local oldestTimestamp

        -- Because our table is keyed by steamids, this is kinda inefficient
        -- although the outer loop should only run once per player join
    	for steamID, playerData in pairs(recentPlayers) do
    		if not oldestTimestamp or playerData.last_seen < oldestTimestamp then
    			oldestSteamID = steamID
    			oldestTimestamp = playerData.last_seen
    		end
    	end

    	recentPlayers[oldestSteamID] = nil
		recentTableOverflow = recentTableOverflow - 1
	end
end

-- Data should already be normalized coming into here (preparePlayerData)
local function addToRecents(steamID, playerData, removeOld)
    if removeOld == nil then removeOld = true end

    -- Just in case we're sent only part of some player data (Possible from Family Sharing)
    if recentPlayers[steamID] then
        table.Merge(recentPlayers[steamID], playerData)
    else
        recentPlayers[steamID] = playerData
    end

    if removeOld then
        removeOldRecents()
    end
end

function ulx.PlayerTracker.xgui.addPlayer(steamID, playerData)
	-- Send out to admins
	local t = {}
	t[steamID] = preparePlayerData(playerData)
	local sendPlys = getReadyPlayers()
	if #sendPlys > 0 then
		xgui.addData(sendPlys, "playertracker", t)
	end

    addToRecents(steamID, t[steamID])
end

-- Called to populate recent players
local function fetchRecents(firstConnect)
    -- Don't fetch players again on MySQL reconnect
    -- This would only occur when the server loses connection
    if firstConnect then
        ulx.PlayerTracker.fetchRecentPlayers(function(players)
            -- Save existing recents
            local oldRecents = recentPlayers

			recentPlayers = {}
			for _, v in ipairs(players) do
				recentPlayers[v.steamid] = preparePlayerData(v)
			end

            -- Merge queued updates in. Keeps us fresh.
            if table.Count(oldRecents) > 0 then
                for steamID, data in pairs(oldRecents) do
                    addToRecents(steamID, data, false)
                end
                removeOldRecents()
            end

            -- Send the fetched data to clients in the case that they've
            -- requested XGUI data before MySQL processed our query.
			local readyPlayers = getReadyPlayers()
			if #readyPlayers > 0 then
				xgui.addData(readyPlayers, "playertracker", recentPlayers)
			end
		end)
    end
end
hook.Add("ZCore_MySQL_Connected", "xgui_pt_fetchrecent", fetchRecents)

-- Called when an XGUI client requests the list of recent players
local function getRecentPlayers()
    return recentPlayers || {}
end

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
				ULib.queueFunctionCall(ULib.clientRPC, ply, "ulx.PlayerTracker.xgui.searchRecievedData", searchID, chunk)
				chunk = {}
			end
		end

		ULib.queueFunctionCall(ULib.clientRPC, ply, "ulx.PlayerTracker.xgui.searchRecievedData", searchID, chunk)
		ULib.queueFunctionCall(ULib.clientRPC, ply, "ulx.PlayerTracker.xgui.searchCompleted", searchID)
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
				ULib.queueFunctionCall(ULib.clientRPC, ply, "ulx.PlayerTracker.xgui.recievedNames", steamID, chunk)
				chunk = {}
			end
		end

		ULib.queueFunctionCall(ULib.clientRPC, ply, "ulx.PlayerTracker.xgui.recievedNames", steamID, chunk)
	end)
end

local function init()
	ULib.ucl.registerAccess("xgui_playertracker", "admin", "Allows admins to view player tracker.", "XGUI")

	xgui.addDataType("playertracker", getRecentPlayers, "xgui_playertracker", DATA_CHUNK_SIZE, 0)

	xgui.addCmd("pt_search", search)
	xgui.addCmd("pt_names", getNames)
end

xgui.addSVModule("playertracker", init)
