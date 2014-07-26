local DATA_CHUNK_SIZE = 60

ulx.playertracker.xgui = {}

local function getReadyPlayers()
	local players = {}

	for _, v in pairs(player.GetAll()) do
		if xgui.readyPlayers[v:UniqueID()] and v:query("xgui_playertracker") then
			table.insert(players , v)
		end
	end
	
	return players
end

local function prepareData(data)
	local newData = table.Copy(data)

	newData.steam_id = nil
	if newData.owner_steam_id == 0 then
		newData.owner_steam_id = nil
	end
	
	return newData
end

function ulx.playertracker.xgui.getData()
	local data = ulx.playertracker.sql.fetchRecentPlayers()
	
	for k, v in pairs(data) do
		data[k] = prepareData(v)
	end
	
	return data
end

function ulx.playertracker.xgui.sendDataUpdate(steamID, data)
	local t = {}
	t[steamID] = prepareData(data)
	
	local sendPlys = getReadyPlayers()
	if #sendPlys > 0 then
		xgui.addData(sendPlys, "playertracker", t)
	end
end

function ulx.playertracker.xgui.search(ply, args)
	local searchID = args[1]
	table.remove(args, 1)
	
	local exactMatch = args[1] == "1"	
	table.remove(args, 1)

	local searchTerm = ""
	for _, v in ipairs(args) do
		searchTerm = searchTerm .. " " .. v
	end
	
	local data = ulx.playertracker.sql.doSearch(searchTerm, exactMatch)
	
	local chunk = {}
	for k, v in pairs(data) do
		chunk[k] = prepareData(v)
		
		if table.Count(chunk) >= DATA_CHUNK_SIZE then
			ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
			chunk = {}
		end
	end
	
	ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchRecievedData", searchID, chunk)
	ULib.queueFunctionCall(ULib.clientRPC, ply, "xplayertracker.searchCompleted", searchID)
end

function ulx.playertracker.xgui.init()
	ULib.ucl.registerAccess("xgui_playertracker", "admin", "Allows the view of the player tracker.", "XGUI")

	xgui.addDataType("playertracker", ulx.playertracker.xgui.getData, "xgui_playertracker", DATA_CHUNK_SIZE, 0)
	
	xgui.addCmd("pt_search",ulx.playertracker.xgui.search)
	--xgui.addCmd("pt_names", playertracker.getnames)
end

xgui.addSVModule("playertracker", ulx.playertracker.xgui.init)