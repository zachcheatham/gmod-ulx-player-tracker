ulx.PlayerTracker = {}

include("playertracker/config.lua")
include("playertracker/mysql.lua")
include("playertracker/data.lua")
include("playertracker/familysharing.lua")

local function removePortFromIP(address)
	local i = string.find(address, ":")
	if not i then return address end
	return string.sub(address, 1, i-1)
end

function ulx.PlayerTracker.updatePlayer(ply, steamID)
	if not IsValid(ply) then return end

	local ip = removePortFromIP(ply:IPAddress())
	local curTime = os.time()

	ulx.PlayerTracker.fetchPlayer(steamID, function(playerData)
		-- My name is DarkRP and I use nicknames
		local currentName = (GetConVarString("gamemode") == "darkrp") and ply:SteamName() or ply:Name()
		
		if playerData then
			local escapedName = ""
			local nameChange = false
			local ipChange = false
			
			playerData.last_seen = curTime
		
			if playerData.name ~= currentName then
				if ulx.PlayerTracker.config.namechangealert then
					ULib.tsay(_, string.format("%s last joined with the name %s", currentName, playerData.name))
				end
				
				nameChange = true
				playerData.name = currentName
				
				escapedName = ulx.PlayerTracker.sql.escapeStr(playerData.name, true)
				ulx.PlayerTracker.insertName(steamID, escapedName)
			end
		
			if playerData.ip ~= ip then
				ipChange = true
				playerData.ip_3 = playerData.ip_2
				playerData.ip_2 = playerData.ip
				playerData.ip = ip
			end
			
			ulx.PlayerTracker.savePlayerUpdate(steamID, (nameChange and escapedName or false), (ipChange and playerData.ip or false), (ipChange and playerData.ip_2 or false), (ipChange and playerData.ip_3 or false))
			ulx.PlayerTracker.xgui.addPlayer(steamID, playerData)
		else
			local data = {}
			data.name = currentName
			data.ip = ip
			data.first_seen = curTime
			data.last_seen = curTime
			
			ulx.PlayerTracker.createPlayer(steamID, data)
			ulx.PlayerTracker.xgui.addPlayer(steamID, data)
		end	

		if not playerData or playerData.owner_steamid ~= 0 then
			ulx.PlayerTracker.updateFamilyShareInfo(ply)
		elseif playerData and playerData.owner_steamid and playerData.owner_steamid ~= 0 then
			ulx.PlayerTracker.checkBanEvasion(ply, playerData.owner_steamid)
		end
	end)
end
hook.Add("PlayerAuthed", "PlayerConnectionTracker", ulx.PlayerTracker.updatePlayer)