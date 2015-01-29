local STEAM_API_KEY = "***REMOVED***" -- YOU MUST PROVIDE A STEAM API KEY IN ORDER TO TRACK FAMILY SHARING (This one is currently Zach's)

function ulx.PlayerTracker.checkBanEvasion(ply, ownerID)
	if ULib.bans[ownerID] then
		local ban = ULib.bans[ownerID]
		
		local banLength = tonumber(ban.unban)
		local newBanLength = (banLength == 0) and 0 or (math.ceil((banLength - os.time()) / 60))
		local newBanReason = "Ban evasion attempt. (Family sharing owner " .. ownerID .. " is banned)"
		
		if IsValid(ply) then
			RunConsoleCommand("ulx", "ban", ply:Nick(), newBanLength, newBanReason)
		else
			RunConsoleCommand("ulx", "banid", ply:SteamID(), newBanLength, newBanReason)
		end
	end
end

function ulx.PlayerTracker.updateFamilyShareInfo(ply)
	if not STEAM_API_KEY or string.len(STEAM_API_KEY) < 1 then
		ErrorNoHalt("You must set STEAM_API_KEY in ulx_player_tracker/lua/ulx/modules/playertracker_familyshare.lua to track family sharing.\n")
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
				else
					ownerID = 0
				end
				
				ulx.PlayerTracker.setOwnerSteamID(steamID, ownerID)

				if ownerID ~= 0 then
					local data = {owner_steam_id = ownerID}
					ulx.PlayerTracker.xgui.addPlayer(steamID, data)
					ulx.PlayerTracker.checkBanEvasion(ply, ownerID)
				end
			else
				ErrorNoHalt("Unable to track family sharing. Steam API returned http code " .. code .. ".\n")
			end
		end
	)
end