function ulx.PlayerTracker.createTables()
	local queryStr = [[
		CREATE TABLE IF NOT EXISTS `player_tracker` (
			`steamid` varchar(20) NOT NULL,
			`name` varchar(32) NOT NULL,
			`owner_steamid` varchar(20) DEFAULT NULL,
			`ip` varchar(15) NOT NULL,
			`ip_2` varchar(15) DEFAULT NULL,
			`ip_3` varchar(15) DEFAULT NULL,
			`last_server` varchar(22) DEFAULT NULL,
			`first_seen` int(10) NOT NULL,
			`last_seen` int(10) NOT NULL,
			PRIMARY KEY (`steamid`)
		)
	]]
	ulx.PlayerTracker.sql.query(queryStr)
	
	queryStr = [[
		CREATE TABLE IF NOT EXISTS `player_tracker_names` (
			`steamid` varchar(20) NOT NULL,
			`name` varchar(32) NOT NULL,
			`timestamp` int(10) NOT NULL,
			PRIMARY KEY (`steamid`,`name`)
		)
	]]
	ulx.PlayerTracker.sql.query(queryStr)
end

function ulx.PlayerTracker.fetchRecentPlayers(callback)
	local queryStr = "SELECT * FROM `player_tracker` WHERE `last_server` = '" .. ulx.PlayerTracker.sql.escapeStr(ulx.PlayerTracker.Util.getServerIP()) .. "' ORDER BY `last_seen` DESC LIMIT 100"
	
	ulx.PlayerTracker.sql.query(queryStr, function(data)
		callback(data)
	end)
end

function ulx.PlayerTracker.fetchPlayer(steamID, callback)
	local queryStr = "SELECT * FROM `player_tracker` WHERE `steamid` = '" .. steamID .. "'"
	
	ulx.PlayerTracker.sql.queryRow(queryStr, function(data)
		callback(data)
	end)
end

function ulx.PlayerTracker.search(searchTerm, exactMatch, callback)
	searchTerm = sql.SQLStr(searchTerm:gsub("^%s*(.-)%s*$", "%1"), true)

	local queryStr
	
	if ULib.isValidSteamID(searchTerm) then
		queryStr = "SELECT * FROM `player_tracker` WHERE `steamid` = '" .. searchTerm .. "' OR `owner_steamid` = '" .. searchTerm .. "'"
	elseif ULib.isValidIP(searchTerm) then
		queryStr = "SELECT * FROM `player_tracker` WHERE `ip` = '" .. searchTerm .. "' OR `ip_2` = '" .. searchTerm .. "' OR `ip_3` = '" .. searchTerm .. "'"
	elseif exactMatch then
		queryStr = "SELECT * FROM `player_tracker` WHERE `name` LIKE '" .. searchTerm .. "'"
	else
		queryStr = "SELECT * FROM `player_tracker` WHERE `name` LIKE '%" .. searchTerm .. "%'"
	end
	
	ulx.PlayerTracker.sql.query(queryStr, function(data)	
		callback(data)
	end)
end

function ulx.PlayerTracker.fetchNames(steamID, callback)
	local queryStr = "SELECT * FROM `player_tracker_names` WHERE `steamid` = '" .. steamID .. "'"
	
	ulx.PlayerTracker.sql.query(queryStr, function(data)
		local result = {}
		for _, v in ipairs(data) do
			table.insert(result, ulx.PlayerTracker.sql.cleanSQLRow(v))
		end
		callback(result)
	end)
end

function ulx.PlayerTracker.createPlayer(steamID, data)
	local name = sql.SQLStr(data.name, false)

	local queryStr = "INSERT INTO `player_tracker` (`steamid`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', " .. name .. ", '" .. data.ip .. "', " .. data.first_seen .. ", " .. data.first_seen .. ")"
	ulx.PlayerTracker.sql.query(queryStr)
	
	queryStr = "INSERT INTO `player_tracker_names` (`steamid`, `name`, `timestamp`) VALUES ('" .. steamID .. "', " .. name .. ", " .. data.first_seen .. ")"
	ulx.PlayerTracker.sql.query(queryStr)
end

function ulx.PlayerTracker.insertName(steamID, name)
	local queryStr = "REPLACE INTO `player_tracker_names` (`steamid`, `name`, `timestamp`) VALUES('" .. steamID .. "', '" .. name .. "', " .. os.time() .. ")"
	ulx.PlayerTracker.sql.query(queryStr)
end

-- WARNING: name needs to be sql escaped before going into this function
function ulx.PlayerTracker.savePlayerUpdate(steamID, name, ip1, ip2, ip3)
	local serverIP = ulx.PlayerTracker.sql.escapeStr(ulx.PlayerTracker.Util.getServerIP())
	local queryStr = "UPDATE `player_tracker` SET `last_seen` = " .. os.time() .. ", `last_server` = '" .. serverIP .. "'"

	if name then
		queryStr = queryStr .. ", `name` = '" .. name .. "'"
	end
	
	if ip1 then
		queryStr = queryStr .. ", `ip` = '" .. ip1 .. "'"
	end

	if ip2 then
		queryStr = queryStr .. ", `ip_2` = '" .. ip2 .. "'"
	end

	if ip3 then
		queryStr = queryStr .. ", `ip_3` = '" .. ip3 .. "'"
	end
	
	queryStr = queryStr .. " WHERE `steamid` = '" .. steamID .. "'"

	ulx.PlayerTracker.sql.query(queryStr)
end

function ulx.PlayerTracker.setOwnerSteamID(steamID, ownerSteamID)
	local queryStr = "UPDATE `player_tracker` SET `owner_steamid` = '" .. ownerSteamID .. "' WHERE `steamid` = '" .. steamID .. "'"
	ulx.PlayerTracker.sql.query(queryStr)
end