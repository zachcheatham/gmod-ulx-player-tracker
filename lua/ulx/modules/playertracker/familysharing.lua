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
	if string.len(cvars.String("ulx_playertrackersteamapikey", "")) < 1 then
		ErrorNoHalt("[Player Tracker] You must set an API Key in the Player Tracker settings avaiable in XGUI to use Family Sharing detection!\n")
		return
	end

	local steamID = ply:SteamID()

	http.Fetch("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=" .. cvars.String("ulx_playertrackersteamapikey", "") .. "&steamid=" .. util.SteamIDTo64(steamID) .. "&appid_playing=4000&format=json",
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

                    if cvars.Bool("ulx_playertrackerfsevadeban") then
    					ulx.PlayerTracker.checkBanEvasion(ply, ownerID)
                    end
				end
			else
				ErrorNoHalt("Unable to track family sharing. Steam API returned http code " .. code .. ".\n")
			end
		end
	)
end
