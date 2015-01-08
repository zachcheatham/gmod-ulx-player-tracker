local function playerAuthed(ply, steamID)
	ulx.PlayerTracker.updatePlayer(ply, steamID)
end
hook.Add("PlayerAuthed", "PlayerConnectionTracker", playerAuthed)

local function onConnected(firstConnect)
	ulx.PlayerTracker.createTables()
	if firstConnect then
		ulx.PlayerTracker.transferOldDatabase()
	end
end
hook.Add("ZCore_MySQL_Connected", "PlayerTrackerConnected", onConnected)