local playertracker = {}

function playertracker.getData()
	local result = sql.Query("SELECT * FROM `player_tracker`")
	
	local data = {}
	
	for i, v in ipairs(result) do
		if v.owner_steam_id == "0" then
			v.owner_steam_id = nil
		end
		
		if v.ip_2 == "NULL" then v.ip_2 = nil end
		if v.ip_3 == "NULL" then v.ip_3 = nil end
	
		data[v.steam_id] = v
		data[v.steam_id].steam_id = nil
	end
	
	return data
end

function playertracker.init()
	ULib.ucl.registerAccess("xgui_playertracker", "superadmin", "Allows the view of the player tracker.", "XGUI")

	xgui.addDataType("playertracker", playertracker.getData, "xgui_playertracker", 25, 0)
end

xgui.addSVModule("playertracker", playertracker.init)