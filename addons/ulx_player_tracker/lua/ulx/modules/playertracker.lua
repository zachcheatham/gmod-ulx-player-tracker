local STEAM_API_KEY = "***REMOVED***" -- YOU MUST PROVIDE A STEAM API KEY IN ORDER TO TRACK FAMILY SHARING (This one is currently Zach's)

-- Data functions
local function initDatabase()
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
								`first_used` INTEGER(10),\
								`last_used` INTEGER(10),\
								PRIMARY KEY(`steam_id`, `name`)\
								);")
		if not sql.TableExists("player_tracker_names") then
			error("Unable to create player_tracker_names table. SQL Error: " .. sql.LastError(result))
		end
	end
end

local function checkFamilyShareBan(ply, ownerID)
	if ULib.bans[ownerID] then
		local ban = ULib.bans[ownerID]
		
		local newBanLength = math.ceil((ban.unban - os.time()) / 60)
		local newBanReason = "Ban evasion attempt. (Family sharing owner " .. ownerID .. " is banned)"
		
		RunConsoleCommand("ulx", "ban", ply:Nick(), newBanLength, newBanReason)
	end
end

local function updateOwnerId(ply)
	if not STEAM_API_KEY or string.len(STEAM_API_KEY) < 1 then
		ErrorNoHalt("You must set STEAM_API_KEY in ulx_player_tracker/lua/ulx/modules/playertracker.lua to track family sharing.\n")
		return
	end
	
	local steamID = ply:SteamID()
	
	http.Fetch("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=" .. STEAM_API_KEY .. "&steamid=" .. util.SteamIDTo64(steamID) .. "&appid_playing=4000&format=json",
		function(body, len, headers, code)
			if code == 200 then
				local response = util.JSONToTable(body)
				local ownerID = response.response.lender_steamid

				if response.response.lender_steamid ~= "0" then
					ownerID = util.SteamIDFrom64(ownerID)
				end
				
				local result = sql.Query("UPDATE `player_tracker` SET `owner_steam_id` = '" .. ownerID .. "' WHERE `steam_id` = '" .. steamID .. "'")
			else
				ErrorNoHalt("Unable to track family sharing. Steam API returned http code " .. code .. ".\n")
			end
		end
	)
end

local function removePortFromIP(address)
	local i = string.find(address, ":")
	if not i then return address end
	return string.sub(address, 1, i-1)
end

local function getReadyPlayers()
	local players = {}

	for _, v in pairs(player.GetAll()) do
		if xgui.readyPlayers[v:UniqueID()] then
			table.insert(players , v)
		end
	end
	
	return players
end

local function updatePlayer(ply, steamID)
	local ip = removePortFromIP(ply:IPAddress())
	local name = sql.SQLStr(ply:Nick(), false)
	local curTime = os.time()

	local tracked = sql.QueryRow("SELECT * FROM `player_tracker` WHERE `steam_id` = '" .. steamID .. "'")

	if tracked then
		if tracked.name ~= ply:Nick() then
			ulx.fancyLog("#T last joined with the name #s", ply, tracked.name)
			tracked.name = ply:Nick()
		
			local result = sql.Query("UPDATE `player_tracker` SET `name` = " .. name .. " WHERE `steam_id` = '" .. steamID .. "'")
			if result == false then
				ErrorNoHalt("Failed to update player name. SQL Error: " .. sql.LastError(result) .. "\n")
			end
			
			result = sql.Query("INSERT OR IGNORE INTO `player_tracker_names` (`steam_id`, `name`, `first_used`, `last_used`) VALUES('" .. steamID .. "', " .. name .. ", " .. curTime .. ", " .. curTime .. ");\
								UPDATE `player_tracker_names` SET `last_used` = " .. curTime .. " WHERE `steam_id` = '" .. steamID .. "' AND `name` LIKE " .. name .. ";")
			
			if result == false then
				ErrorNoHalt("Failed to update player name list. SQL Error: " .. sql.LastError(result) .. "\n")
			end
		end
	
		if tracked.ip ~= ip then
			tracked.ip_3 = tracked.ip_2
			tracked.ip_2 = tracked.ip
			tracked.ip = ip
			sql.Query("UPDATE `player_tracker` SET `ip` = '" .. tracked.ip .. "', `ip_2` = '" .. tracked.ip_2 .. "', `ip_3` = '" .. tracked.ip_3 .. "' WHERE `steam_id` = '" .. steamID .. "'")
		end
		
		tracked.last_seen = curTime
		sql.Query("UPDATE `player_tracker` SET `last_seen` = " .. curTime .. " WHERE `steam_id` = '" .. steamID .. "'")
		
		-- UPDATE XGUI
		local t = {}
		t[steamID] = tracked
		t[steamID].steam_id = nil
		local sendPlys = getReadyPlayers()
		if #sendPlys > 0 then
			xgui.addData(sendPlys, "playertracker", t)
		end
	else
		local result = sql.Query("INSERT INTO `player_tracker` (`steam_id`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', " .. name .. ", '" .. ip .. "', " .. curTime .. ", " .. curTime .. ")")
		if result == false then
			error("Error starting track on " .. steamID .. "! SQL Error: " .. sql.LastError(result))
		end
		
		result = sql.Query("INSERT INTO `player_tracker_names` (`steam_id`, `name`, `first_used`, `last_used`) VALUES ('" .. steamID .. "', " .. name .. ", " .. curTime .. ", " .. curTime .. ")")
		if result == false then
			error("Error starting name track on " .. steamID .. "! SQL Error: " .. sql.LastError(result))
		end
		
		-- UPDATE XGUI
		local t = {}
		t[steamID] = {}
		t[steamID].name = ply:Nick()
		t[steamID].ip = ip
		t[steamID].first_seen = curTime
		t[steamID].last_seen = curTime
		
		local sendPlys = getReadyPlayers()
		if #sendPlys > 0 then
			xgui.addData(sendPlys, "playertracker", t)
		end
		
		updateOwnerId(ply)
	end	
end

-- Hooks
local function playerAuthed(ply, steamID)
	updatePlayer(ply, steamID)
end
hook.Add("PlayerAuthed", "PlayerConnectionTracker", playerAuthed)

-- Initialize
initDatabase()

function makeString(l)
	if l < 1 then return nil end -- Check for l < 1
	local s = "" -- Start string
	for i = 1, l do
			s = s .. string.char(math.random(32, 126)) -- Generate random number from 32 to 126, turn it into character and add to string
	end
	return s -- Return string
end

local function stressDatabase()
	for i=1,10000 do
		
		local steamID = "STEAM_0:0:" .. math.random(1,1000000000)
		local name = sql.SQLStr(makeString(32), false)
		local ipAddress = math.random(0,255) .. "." .. math.random(0,255) .. "." .. math.random(0,255) .. "." .. math.random(0,255)
		local first_seen = os.time()
		local last_seen = os.time()
		
		local result = sql.Query("INSERT INTO `player_tracker` (`steam_id`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', " .. name .. ", '" .. ipAddress .. "', " .. os.time() .. ", " .. os.time() .. ")")
		if result == false then
			ErrorNoHalt("SQL Error: " .. sql.LastError(result) .. "\n")
		end
		local result = sql.Query("INSERT INTO `player_tracker_names` (`steam_id`, `name`, `first_used`, `last_used`) VALUES('" .. steamID .. "', " .. name .. ", " .. os.time() .. ", " .. os.time() .. ")")
		if result == false then
			ErrorNoHalt("SQL Error 2: " .. sql.LastError(result) .. "\n")
		end
		
		if i % 100 == 0 then
			print ("Stress Test: " .. (i / 10000 * 100) .. "% done.")
		end
	end
end
concommand.Add("pt_stress", stressDatabase)