local STEAM_API_KEY = "***REMOVED***" -- YOU MUST PROVIDE A STEAM API KEY IN ORDER TO TRACK FAMILY SHARING

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
end

local function checkFamilyShareBan(ply, ownerID)
	if ULib.bans[ownerID] then
		local ban = ULib.bans[ownerID]
		
		local newBanLength = math.ceil((ban.unban - os.time()) / 60)
		local newBanReason = "Family Sharing owner (" .. ownerID .. ") is banned"
		
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

local function updatePlayer(ply, steamID)
	local ip = removePortFromIP(ply:IPAddress())
	local name = sql.SQLStr(ply:Nick(), false)
	local curTime = os.time()

	local tracked = sql.QueryRow("SELECT * FROM `player_tracker` WHERE `steam_id` = '" .. steamID .. "'")
	
	if tracked then
		if tracked.name ~= ply:Nick() then
			local result = sql.Query("UPDATE `player_tracker` SET `name` = " .. name .. " WHERE `steam_id` = '" .. steamID .. "'")
			
			if result == false then
				ErrorNoHalt("Failed to update player name. SQL Error: " .. sql.LastError(result) .. "\n")
			end
			
			ulx.fancyLog("#T last joined with the name #s", ply, tracked.name)
			tracked.name = ply:Nick()
		end
	
		if tracked.ip ~= ip then			
			sql.Query("UPDATE `player_tracker` SET `ip` = '" .. ip .. "', `ip_2` = '" .. tracked.ip .. "', `ip_3` = '" .. tracked.ip_2 .. "' WHERE `steam_id` = '" .. steamID .. "'")
		end
		
		tracked.last_seen = curTime
		sql.Query("UPDATE `player_tracker` SET `last_seen` = " .. curTime .. " WHERE `steam_id` = '" .. steamID .. "'")
	
		if tracked.owner_steam_id ~= "0" then
			updateOwnerId(ply)
		end
	else
		local result = sql.Query("INSERT INTO `player_tracker` (`steam_id`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', " .. name .. ", '" .. ip .. "', " .. curTime .. ", " .. curTime ..")")

		if result == false then
			error("Error starting track on " .. steamID .. "! SQL Error: " .. sql.LastError(result))
		end
	
		-- Check family sharing
		updateOwnerId(ply)
	end	
end

-- Hooks
local function playerAuthed(ply, steamID, uniqueID)
	updatePlayer(ply, steamID)
end
hook.Add("PlayerAuthed", "ptracker_trackconnect", playerAuthed)

-- Initialize
initDatabase()