xgui.prepareDataType("playertracker")
xgui.prepareDataType("playertracker_search")
xgui.prepareDataType("playertracker_names")

xplayertracker = xlib.makepanel{parent=xgui.null}
xplayertracker.isSearching = false
xplayertracker.searchID = ""
xplayertracker.searchData = {}

xlib.makelabel{x=410, y=8, label="Double click to view details.", parent=xplayertracker}

xplayertracker.loading = xlib.makelabel{x=160, y=8, label="Fetching Results...", parent=xplayertracker}
xplayertracker.loading:SetVisible(false)

xplayertracker.search = xlib.maketextbox{x=5, y=5, w=150, text="Search...", selectall=true, parent=xplayertracker}
xplayertracker.search.OnEnter = function()
	if string.len(xplayertracker.search:GetValue()) > 0 then
		if string.len(xplayertracker.search:GetValue()) > 0 then
			xplayertracker.list:Clear()
			xgui.flushQueue("playertracker_populate")
			
			xplayertracker.isSearching = true
			xplayertracker.searchID = tostring(os.time())
			
			xplayertracker.loading:SetVisible(true)
			
			RunConsoleCommand("_xgui", "pt_search", xplayertracker.searchID, xplayertracker.search:GetValue())
		else
			Derma_Query("That search would be too broad!", "Expensive Search Term", "Okay")
		end
	elseif xplayertracker.isSearching then
		xplayertracker.list:Clear()
		xgui.flushQueue("playertracker_populate")
	
		xplayertracker.isSearching = false
		xplayertracker.searchID = ""
		xplayertracker.searchData = {}
		
		xplayertracker.populate(xgui.data.playertracker)
	end
end

xplayertracker.list = xlib.makelistview{x=5, y=30, w=574, h=329, multiselect=false, parent=xplayertracker}
xplayertracker.list:AddColumn("Name")
xplayertracker.list:AddColumn("Steam ID")
xplayertracker.list:AddColumn("IP Address")
xplayertracker.list:AddColumn("First Seen")
xplayertracker.list:AddColumn("Last Seen")
xplayertracker.list.SortByColumn = function(self, columnID, desc)
	table.Copy(self.Sorted, self.Lines)	
	if columnID > 3 then
		table.sort(self.Sorted, function(a, b) 
			local dataTable = {}
			local timeKey = ""
			
			if xplayertracker.isSearching then
				dataTable = xplayertracker.searchData
			else
				dataTable = xgui.data.playertracker
			end
			
			if columnID == 4 then
				timeKey = "first_seen"
			else
				timeKey = "last_seen"
			end
			
			if (desc) then
				a, b = b, a
			end
			
			return dataTable[a:GetColumnText(2)][timeKey] < dataTable[b:GetColumnText(2)][timeKey]
		end)
	else
		table.sort(self.Sorted, function(a, b) 
			if (desc) then
				a, b = b, a
			end
			return a:GetColumnText(columnID) < b:GetColumnText(columnID)
		end)
	end
	
	self:SetDirty( true )
	self:InvalidateLayout()
end

local function getPlayerData(steamID)
	local data
	if xplayertracker.isSearching then
		data = xplayertracker.searchData[steamID]
	else
		data = xgui.data.playertracker[steamID]
	end
	
	return data
end

xplayertracker.list.OnRowRightClick = function(self, id, line)
	local steamID = string.gsub(line:GetValue(2), "*", "")
	
	local menu = DermaMenu()
	menu:AddOption("Details...", function()
		xplayertracker.showPlayerDetailsDialog(steamID, getPlayerData(steamID))
	end)
	menu:AddSpacer()
	menu:AddOption("View Profile", function()
		local profileID = util.SteamIDTo64(steamID)
		gui.OpenURL("http://steamcommunity.com/profiles/" .. profileID)
	end)
	menu:AddOption("Ban", function()
		
	end)
	menu:AddSpacer()
	menu:AddOption("Accounts on IP", function()
		
	end)
	menu:AddOption("Accounts with Name", function()
		
	end)
	menu:Open()
end

xplayertracker.list.DoDoubleClick = function(self, i, line)
	local steamID = string.gsub(line:GetValue(2), "*", "")
	xplayertracker.showPlayerDetailsDialog(steamID, getPlayerData(steamID))
end

function xplayertracker.populate(players, fromSearch)
	if (fromSearch or false) == xplayertracker.isSearching then
		for steamID, player in pairs(players) do
			xgui.queueFunctionCall(xplayertracker.addPlayer, "playertracker_populate", steamID, player)
		end
	end
end

function xplayertracker.addPlayer(steamID, player)
	local theTime = os.time()
	local firstSeen = ""
	local lastSeen = ""
	
	if (theTime - player.first_seen) < 1440 then
		firstSeen = os.date("%I:%M %p", player.first_seen)
	else
		firstSeen = os.date("%x %I:%M %p", player.first_seen)
	end
	
	if (theTime - player.last_seen) < 1440 then
		lastSeen = os.date("%I:%M %p", player.last_seen)
	else
		lastSeen = os.date("%x %I:%M %p", player.last_seen)
	end	
	
	xplayertracker.list:AddLine(player.name, (player.owner_steam_id and "*" or "") .. steamID, player.ip, firstSeen, lastSeen)
	xplayertracker.list:SortByColumn(5, true)
end

function xplayertracker.clear()
	if not xplayertracker.isSearching then
		xplayertracker.list:Clear()
	end
end

function xplayertracker.update(players)
	if not xplayertracker.isSearching then
		for steamID, player in pairs(players) do
			for i, line in pairs(xplayertracker.list.Lines) do
				if line.Columns[2] == steamID then
					line:SetColumnText(1, player.name)
					line:SetColumnText(3, player.ip)
					line:SetColumnText(4, os.date("%x", player.first_seen))
					line:SetColumnText(5, os.date("%x", player.last_seen))
					break
				end
			end
			
			local t = {}
			t[steamID] = player
			xplayertracker.populate(t)
		end
	end
end

xgui.hookEvent("playertracker", "process", xplayertracker.populate)
xgui.hookEvent("playertracker", "clear", xplayertracker.clear)
xgui.hookEvent("playertracker", "add", xplayertracker.update)

function xplayertracker.searchRecievedData(id, data)
	if id == xplayertracker.searchID then
		table.Merge(xplayertracker.searchData, data)
		xplayertracker.populate(data, true)
	end
end

function xplayertracker.searchCompleted(id)
	if id == xplayertracker.searchID then
		xplayertracker.loading:SetVisible(false)
	end
end

local function copyText(pnl)
	if pnl:GetClassName() == "TextEntry" then
		SetClipboardText(pnl:GetValue())
		ULib.tsay(_, '"' .. pnl:GetValue() .. '"' .. " has been copied to the clipboard.")
	elseif pnl:GetName() == "List" then
		local i = pnl:GetSelectedLine()
		if i then
			local value = pnl:GetLine(i):GetValue(1)
			if string.len(value) > 0 then
				SetClipboardText(value)
				ULib.tsay(_, '"' .. value .. '"' .. " has been copied to the clipboard.")
			end
		end
	end
end

function xplayertracker.showPlayerDetailsDialog(steamID, data)
	local window = xlib.makeframe{label="Details", w=265, h=263, skin=xgui.settings.skin}
	
	local nameLabel = xlib.makelabel{label="Name:", x=22, y=33, parent=window}
	local nameBox = xlib.maketextbox{x=55, y=30, w=160, text=data.name, parent=window}
	nameBox:SetEditable(false)
	local nameCopyButton = xlib.makebutton{x=220, y=30, h=20, w=40, label="Copy", parent=window}
	nameCopyButton.DoClick = function()
		copyText(nameBox)
	end
	
	local steamIDLabel = xlib.makelabel{label="Steam ID:", x=5, y=58, parent=window}
	local steamIDBox = xlib.maketextbox{x=55, y=55, w=160, text=steamID, parent=window}
	steamIDBox:SetEditable(false)
	local steamIDCopyButton = xlib.makebutton{x=220, y=55, h=20, w=40, label="Copy", parent=window}
	steamIDCopyButton.DoClick = function()
		copyText(steamIDBox)
	end
	
	local profileIDLabel = xlib.makelabel{label="Profile ID:", x=5, y=83, parent=window}
	local profileIDBox = xlib.maketextbox{x=55, y=80, w=160, text=util.SteamIDTo64(steamID), parent=window}
	profileIDBox:SetEditable(false)
	local profileIDCopyButton = xlib.makebutton{x=220, y=80, h=20, w=40, label="Copy", parent=window}
	profileIDCopyButton.DoClick = function()
		copyText(profileIDBox)
	end
	
	local firstSeenLabel = xlib.makelabel{label="First Seen:  " .. os.date("%x %I:%M %p", data.first_seen), x=5, y=105, parent=window}
	local lastSeenLabel = xlib.makelabel{label="Last Seen:  " .. os.date("%x %I:%M %p", data.last_seen), x=5, y=123, parent=window}

	local ipList = xlib.makelistview{x=5, y=143, w=210, h=73, multiselect=false, parent=window}
	ipList:SetName("List")
	ipList:AddColumn("Recent IP Addresses")
	ipList:AddLine(data.ip)
	ipList:AddLine(data.ip_2)
	ipList:AddLine(data.ip_3)
	local ipCopyButton = xlib.makebutton{x=220, y=143, h=20, w=40, label="Copy", parent=window}
	ipCopyButton.DoClick = function()
		copyText(ipList)
	end
	
	local familyShareLabel = xlib.makelabel{label="Family Sharing Owner:", x=5, y=221, parent=window}
	local familyShareBox = xlib.maketextbox{x=5, y=237, w=210, text=(data.owner_steam_id or "N/A"), parent=window}
	familyShareBox:SetEditable(false)
	local familyShareCopyButton = xlib.makebutton{x=220, y=237, h=20, w=40, label="Copy", parent=window}
	familyShareCopyButton.DoClick = function()
		copyText(familyShareBox)
	end
end

xgui.addModule("Players", xplayertracker, "icon16/user_green.png", "xgui_playertracker")