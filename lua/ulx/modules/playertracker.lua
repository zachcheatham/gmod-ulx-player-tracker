local USE_MYSQL = false

ulx.PlayerTracker = {}

include("playertracker/config.lua")
if USE_MYSQL then
    include("playertracker/data_mysql.lua")
else
    include("playertracker/data_sqlite.lua")
end
include("playertracker/familysharing.lua")

local function updatePlayer(ply, steamID)
	if not IsValid(ply) then return end

	local ip = ZCore.Util.removePortFromIP(ply:IPAddress())
	local curTime = os.time()

	ulx.PlayerTracker.fetchPlayer(steamID, function(playerData)
		-- My name is DarkRP and I use nicknames
		local currentName = (GetConVarString("gamemode") == "darkrp") and ply:SteamName() or ply:Name()
		
		if playerData then
			local nameChange = false
			local ipChange = false

			playerData.last_seen = curTime

			if playerData.name ~= currentName then
                if cvars.Bool("ulx_playertrackernamealert") then
				    ULib.tsay(_, string.format("%s last joined with the name %s", currentName, playerData.name))
                end

				nameChange = true
				playerData.name = currentName

				ulx.PlayerTracker.insertName(steamID, currentName)
			end

			if playerData.ip ~= ip then
				ipChange = true
				playerData.ip_3 = playerData.ip_2
				playerData.ip_2 = playerData.ip
				playerData.ip = ip
			end

			ulx.PlayerTracker.savePlayerUpdate(steamID, (nameChange and currentName or false), (ipChange and playerData.ip or false), (ipChange and playerData.ip_2 or false), (ipChange and playerData.ip_3 or false))
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
hook.Add("PlayerAuthed", "PlayerConnectionTracker", updatePlayer)
