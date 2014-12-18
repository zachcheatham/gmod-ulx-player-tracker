ulx.PlayerTracker = {}

include("playertracker/data.lua")
include("playertracker/hooks.lua")
include("playertracker/familysharing.lua")
include("playertracker/legacy.lua")

function ulx.PlayerTracker.updatePlayer(ply, steamID)
	if not IsValid(ply) then return end

	local ip = ZCore.Util.removePortFromIP(ply:IPAddress())
	local curTime = os.time()

	ulx.PlayerTracker.fetchPlayer(steamID, function(playerData)
		-- My name is DarkRP and I use nicknames
		local currentName = (GetConVarString("gamemode") == "darkrp") and ply:SteamName() or ply:Name()
		
		if playerData then
			local escapedName = ""
			local nameChange = false
			local ipChange = false
			
			playerData.last_seen = curTime
		
			print("CURRENT NAME: " .. currentName)
			print("LAST NAME: " .. playerData.name)
		
			if playerData.name ~= currentName then
				ULib.tsay({}, string.format("%s last joined with the name %s", currentName, playerData.name))
				
				nameChange = true
				playerData.name = currentName
				
				escapedName = ZCore.MySQL.escapeStr(playerData.name, true)
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

		if not playerData or playerData.owner_steam_id ~= 0 then
			ulx.PlayerTracker.updateFamilyShareInfo(ply)
		end
	end)
end