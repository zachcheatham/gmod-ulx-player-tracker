local function onConnected(firstConnect)
	ulx.PlayerTracker.createTables()
end
hook.Add("ZCore_MySQL_Connected", "PlayerTrackerConnected", onConnected)