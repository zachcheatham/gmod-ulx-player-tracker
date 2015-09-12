require("mysqloo")

ulx.PlayerTracker.sql = {}

local database = nil
local connected = false
local previouslyConnected = false
local queryCache = {}

local function connect()
	if not mysqloo then Error("[PlayerTracker] MySQLOO isn't installed properly. Unable to use MySQL functions.\n") end
	
	ServerLog("[PlayerTracker] Connecting to MySQL...\n")
	database = mysqloo.connect(ulx.PlayerTracker.config.mysql.host, ulx.PlayerTracker.config.mysql.user, ulx.PlayerTracker.config.mysql.pass, ulx.PlayerTracker.config.mysql.db)

	if timer.Exists("ptracker_sql_connection_state") then timer.Destroy("ptracker_sql_connection_state") end
	
	database.onConnectionFailed = function(_, msg)
		ErrorNoHalt("[PlayerTracker] Failed to connect to MySQL! " .. tostring(msg) .. "\n")
		if previouslyConnected then
			ServerLog("[PlayerTracker] Attempting MySQL reconnect in 30 seconds.\n")
			timer.Simple(30, connect)
		end
	end
	
	database.onConnected = function()
		connected = true
		ServerLog("[PlayerTracker] Connected to MySQL.\n")

		for _, query in ipairs(queryCache) do
			ulx.PlayerTracker.sql.query(query[1], query[2])
		end
		table.Empty(queryCache)
		
		timer.Create("ptracker_sql_connection_state", 60, 0, function()
			if (database and database:status() == mysqloo.DATABASE_NOT_CONNECTED) then
				connected = false
				ErrorNoHalt("[PlayerTracker] Lost connection to MySQL! Attempting reconnect...\n")
				connect()
			end
		end)
		
		ulx.PlayerTracker.createTables()
		previouslyConnected = true
	end
	
	database:connect()
end
connect() 

function ulx.PlayerTracker.sql.query(sql, callback)
	if not connected then
		table.insert(queryCache, {sql, callback})
	else
		local q = database:query(sql)
		function q:onSuccess(data)
			if callback then
				callback(ZCore.MySQL.cleanSQLArray(data), q:lastInsert())
			end
		end
		
		function q:onError(err)
			if err == "MySQL server has gone away" then
				table.insert(queryCache, {sql, callback})
			else
				ErrorNoHalt("[PlayerTracker] Query failed: " .. err .. ". Query:\n" ..  sql .. "\n")
			end
		end
		
		q:start()
	end
end

function ulx.PlayerTracker.sql.queryRow(sql, callback)
	ulx.PlayerTracker.sql.query(sql, function(data)
		if table.Count(data) > 0 then
			callback(ulx.PlayerTracker.sql.cleanSQLRow(data[1]))
		else
			callback(false)
		end
	end)
end

function ulx.PlayerTracker.sql.escapeStr(str)
	return database:escape(tostring(str))
end

function ulx.PlayerTracker.sql.cleanSQLArray(data)
	if not type(data) == "table" then return data end
	
	local newData = {}
	
	for k, v in pairs(data) do
		newData[k] = ulx.PlayerTracker.sql.cleanSQLRow(v)
	end
	
	return newData
end

function ulx.PlayerTracker.sql.cleanSQLRow(data)
	if not data then return data end

	local newData = table.Copy(data)
	
	-- REMOVE NULLS
	local toRemove = {}
	for k,v in pairs(newData) do
		if v == "NULL" then
			table.insert(toRemove, k)
		end
	end
	
	for _,k in ipairs(toRemove) do
		newData[k] = nil
	end
	
	-- TURN NUMBERS INTO NUMBERS!
	for k,v in pairs(newData) do
		if tonumber(v) ~= nil then
			newData[k] = tonumber(v)
		end
	end
	
	return newData
end