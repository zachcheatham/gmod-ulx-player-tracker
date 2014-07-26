ulx.playertracker = {}

local function removePortFromIP(address)
	local i = string.find(address, ":")
	if not i then return address end
	return string.sub(address, 1, i-1)
end

function ulx.playertracker.updatePlayer(ply, steamID)
	if not IsValid(ply) then return end

	local ip = removePortFromIP(ply:IPAddress())
	local curTime = os.time()

	local tracked = ulx.playertracker.sql.fetchPlayer(steamID)
	
	if tracked then
		ulx.playertracker.sql.playerHeartbeat(steamID)
		tracked.last_seen = curTime
	
		if tracked.name ~= ply:Nick() then
			ulx.fancyLog("#T last joined with the name #s", ply, tracked.name)
			tracked.name = ply:Nick()
		
			ulx.playertracker.sql.recordName(steamID, tracked.name)
		end
	
		if tracked.ip ~= ip then
			tracked.ip_3 = tracked.ip_2
			tracked.ip_2 = tracked.ip
			tracked.ip = ip
			
			ulx.playertracker.sql.recordAddress(steamID, tracked.ip, tracked.ip_2, tracked.ip_3)
		end
		
		ulx.playertracker.xgui.sendDataUpdate(steamID, tracked)
	else
		local data = {}
		data.name = ply:Nick()
		data.ip = ip
		data.first_seen = curTime
		data.last_seen = curTime
		
		ulx.playertracker.sql.createPlayer(steamID, data)
		ulx.playertracker.xgui.sendDataUpdate(steamID, data)
	end	

	if not tracked or tracked.owner_steam_id ~= 0 then
		ulx.playertracker.updateFamilyShareInfo(ply)
	end
end

-- Hooks
local function playerAuthed(ply, steamID)
	ULib.queueFunctionCall(ulx.playertracker.updatePlayer, ply, steamID)
end
hook.Add("PlayerAuthed", "PlayerConnectionTracker", playerAuthed)