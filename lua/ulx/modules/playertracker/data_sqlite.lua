function ulx.PlayerTracker.fetchRecentPlayers(callback)
	local queryStr = "SELECT * FROM `player_tracker` ORDER BY `last_seen` DESC LIMIT 100"

    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Unable to fetch recent players. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    else
        local data = {}
        if result then
            data = ZCore.MySQL.cleanSQLArray(result)
        end
        callback(data)
    end
end

function ulx.PlayerTracker.fetchPlayer(steamID, callback)
	local queryStr = "SELECT * FROM `player_tracker` WHERE `steamid` = '" .. steamID .. "'"

    local result = sql.QueryRow(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Unable to fetch player. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    else
        if result then
            result = ZCore.MySQL.cleanSQLRow(result)
            PrintTable(result)
            callback(result)
        else
            callback(false)
        end
    end
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

    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Unable to perform search. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    else
        local data = {}
        if result then
            data = ZCore.MySQL.cleanSQLArray(result)
        end
        callback(data)
    end
end

function ulx.PlayerTracker.fetchNames(steamID, callback)
	local queryStr = "SELECT * FROM `player_tracker_names` WHERE `steamid` = '" .. steamID .. "'"

    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to fetch player names. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    else
        local data = {}
        if result then
            for i, v in ipairs(result) do
                table.insert(data, ZCore.MySQL.cleanSQLRow(v))
            end
        end
        callback(data)
    end
end

function ulx.PlayerTracker.createPlayer(steamID, data)
	local name = sql.SQLStr(data.name, true)

	local queryStr = "INSERT INTO `player_tracker` (`steamid`, `name`, `ip`, `first_seen`, `last_seen`) VALUES('" .. steamID .. "', '" .. name .. "', '" .. data.ip .. "', " .. data.first_seen .. ", " .. data.first_seen .. ")"
    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to insert new player. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    end

	queryStr = "INSERT INTO `player_tracker_names` (`steamid`, `name`, `timestamp`) VALUES ('" .. steamID .. "', '" .. name .. "', " .. data.first_seen .. ")"
    result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to insert player name on new player. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    end
end

function ulx.PlayerTracker.insertName(steamID, name)
    name = sql.SQLStr(name, true)
	local queryStr = "REPLACE INTO `player_tracker_names` (`steamid`, `name`, `timestamp`) VALUES('" .. steamID .. "', '" .. name .. "', " .. os.time() .. ")"

    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to insert player name. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    end
end

function ulx.PlayerTracker.savePlayerUpdate(steamID, name, ip1, ip2, ip3)
	local serverIP = sql.SQLStr(ZCore.Util.getServerIP(), true)

    if name then
        name = sql.SQLStr(name, true)
    end

	local queryStr = "UPDATE `player_tracker` SET `last_seen` = " .. os.time()

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

    local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to save player update. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    end
end

function ulx.PlayerTracker.setOwnerSteamID(steamID, ownerSteamID)
	local queryStr = "UPDATE `player_tracker` SET `owner_steamid` = '" .. ownerSteamID .. "' WHERE `steamid` = '" .. steamID .. "'"
	local result = sql.Query(queryStr)
    if result == false then
        local msg = "[PlayerTracker] Failed to save a family share owner. SQLite Error: " .. sql.LastError(result) .. "\n"
        ZCore.ULX.tsayPlayersWithPermission(msg, "ulx rcon")
        ErrorNoHalt(msg .. "\n")
    end
end

local function createTables()
    if not sql.TableExists("player_tracker") then
    	local queryStr = [[
    		CREATE TABLE `player_tracker` (
    			`steamid` varchar(20) NOT NULL,
    			`name` varchar(32) NOT NULL,
    			`owner_steamid` varchar(20) DEFAULT NULL,
    			`ip` varchar(15) NOT NULL,
    			`ip_2` varchar(15) DEFAULT NULL,
    			`ip_3` varchar(15) DEFAULT NULL,
    			`first_seen` int(10) NOT NULL,
    			`last_seen` int(10) NOT NULL,
    			PRIMARY KEY (`steamid`)
    		)
    	]]
        local result = sql.Query(queryStr)
        if not sql.TableExists("player_tracker") then
            error("Unable to create player_tracker table. SQL Error: " .. sql.LastError(result))
        end
    end

    if not sql.TableExists("player_tracker_name") then
    	local queryStr = [[
    		CREATE TABLE `player_tracker_names` (
    			`steamid` varchar(20) NOT NULL,
    			`name` varchar(32) NOT NULL,
    			`timestamp` int(10) NOT NULL,
    			PRIMARY KEY (`steamid`,`name`)
    		)
    	]]
        local result = sql.Query(queryStr)
        if not sql.TableExists("player_tracker_names") then
            error("Unable to create player_tracker_names table. SQL Error: " .. sql.LastError(result))
        end
    end
end
createTables()
