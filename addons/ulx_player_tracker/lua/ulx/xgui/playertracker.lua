xgui.prepareDataType("playertracker")

xplayertracker = xlib.makepanel{parent=xgui.null}
xplayertracker.isSearching = false
xplayertracker.searchID = ""
xplayertracker.searchData = {}

xplayertracker.search = xlib.maketextbox{x=5, y=5, w=150, text="Search...", selectall=true, parent=xplayertracker}
xplayertracker.search.OnEnter = function()
	if string.len(xplayertracker.search:GetValue()) > 0 then
		if string.len(xplayertracker.search:GetValue()) > 3 or xplayertracker.exactMatch:GetChecked() then
			xplayertracker.list:Clear()
			xgui.flushQueue("playertracker_populate")
			
			xplayertracker.isSearching = true
			xplayertracker.searchID = tostring(os.time())
			
			xplayertracker.loading:SetVisible(true)
			
			RunConsoleCommand("_xgui", "pt_search", xplayertracker.searchID, (xplayertracker.exactMatch:GetChecked() and "1" or "0"), xplayertracker.search:GetValue())
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

xplayertracker.loading = xlib.makelabel{x=430, y=8, label="Fetching Results...", parent=xplayertracker}
xplayertracker.loading:SetVisible(false)

xplayertracker.exactMatch = xlib.makecheckbox{x=160, y=8, label="Exact Match", parent=xplayertracker}

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
			
			return tonumber(dataTable[string.gsub(a:GetColumnText(2), "*", "")][timeKey]) < tonumber(dataTable[string.gsub(b:GetColumnText(2), "*", "")][timeKey])
		end)
	else
		table.sort(self.Sorted, function(a, b) 
			if (desc) then
				a, b = b, a
			end
			return a:GetColumnText(columnID) < b:GetColumnText(columnID)
		end)
	end
	
	self:SetDirty(true)
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
	
	local details = menu:AddOption("Details...", function()
		xplayertracker.showPlayerDetailsDialog(steamID, getPlayerData(steamID))
	end)
	details:SetIcon("icon16/information.png")
	details:SetTextInset(0,0)
	
	menu:AddSpacer()
	
	local profile = menu:AddOption("View Profile", function()
		local profileID = util.SteamIDTo64(steamID)
		gui.OpenURL("http://steamcommunity.com/profiles/" .. profileID)
	end)
	profile:SetIcon("icon16/application_go.png")
	profile:SetTextInset(0,0)
	
	local ban = menu:AddOption("Ban", function()
		local data = getPlayerData(steamID)
		xplayertracker.showBanWindow(data.name, steamID)
	end)
	ban:SetIcon("icon16/delete.png")
	ban:SetTextInset(0,0)
	
	menu:AddSpacer()
	
	local names = menu:AddOption("Accounts with Name", function()
		local data = getPlayerData(steamID)
		xplayertracker.search:SetValue(data.name)
		xplayertracker.exactMatch:SetChecked(true)
		xplayertracker.search.OnEnter()
	end)
	names:SetIcon("icon16/group_go.png")
	names:SetTextInset(0,0)
	
	local ips = menu:AddOption("Accounts on IP", function()
		local data = getPlayerData(steamID)
		xplayertracker.search:SetValue(data.ip)
		xplayertracker.search.OnEnter()
	end)
	ips:SetIcon("icon16/world_go.png")
	ips:SetTextInset(0,0)
	
	menu:Open()
end

xplayertracker.list.DoDoubleClick = function(self, i, line)
	local steamID = string.gsub(line:GetValue(2), "*", "")
	xplayertracker.showPlayerDetailsDialog(steamID, getPlayerData(steamID))
end

function xplayertracker.populate(players, fromSearch)
	if (fromSearch or false) == xplayertracker.isSearching then
		for steamID, player in pairs(players) do
			if not fromSearch then
				player = table.Merge(player, xgui.data.playertracker[steamID])
			end
		
			xgui.queueFunctionCall(xplayertracker.addPlayer, "playertracker_populate", steamID, player)
		end
	end
end

function xplayertracker.addPlayer(steamID, player)
	local theTime = os.time()
	local firstSeen = ""
	local lastSeen = ""
	
	if (theTime - player.first_seen) < 86400 then
		firstSeen = os.date("%I:%M %p", player.first_seen)
	else
		firstSeen = os.date("%x %I:%M %p", player.first_seen)
	end
	
	if (theTime - player.last_seen) < 86400 then
		lastSeen = os.date("%I:%M %p", player.last_seen)
	else
		lastSeen = os.date("%x %I:%M %p", player.last_seen)
	end
	
	xplayertracker.list:AddLine(player.name, ((not player.owner_steam_id or tonumber(player.owner_steam_id) == 0) and "" or "*") .. steamID, player.ip, firstSeen, lastSeen)
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
			local found = false
			for i, line in pairs(xplayertracker.list.Lines) do
				if string.gsub(line:GetValue(2), "*", "") == steamID then
					player = table.Merge(player, xgui.data.playertracker[steamID])
				
					local theTime = os.time()
					local firstSeen = ""
					local lastSeen = ""
					
					if (theTime - player.first_seen) < 86400 then
						firstSeen = os.date("%I:%M %p", player.first_seen)
					else
						firstSeen = os.date("%x %I:%M %p", player.first_seen)
					end
					
					if (theTime - player.last_seen) < 86400 then
						lastSeen = os.date("%I:%M %p", player.last_seen)
					else
						lastSeen = os.date("%x %I:%M %p", player.last_seen)
					end
				
					line:SetColumnText(1, player.name)
					line:SetColumnText(3, player.ip)
					line:SetColumnText(4, firstSeen)
					line:SetColumnText(5, lastSeen)
					
					found = true
					break
				end
			end
			
			if not found then
				local t = {}
				t[steamID] = player
				xplayertracker.populate(t)
			end
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

xgui.addModule("Players", xplayertracker, "icon16/user_green.png", "xgui_playertracker")

-- Copy pasta from xgui bans with name / steamID options
function xplayertracker.showBanWindow(name, steamID)
	local xgui_banwindow = xlib.makeframe{label="Ban " .. name, w=285, h=155, skin=xgui.settings.skin}
	xlib.makelabel{x=23, y=33, label="SteamID:", parent=xgui_banwindow}
	xlib.makelabel{x=28, y=58, label="Reason:", parent=xgui_banwindow}
	xlib.makelabel{x=10, y=83, label="Ban Length:", parent=xgui_banwindow}
	local reason = xlib.makecombobox{x=75, y=55, w=200, parent=xgui_banwindow, enableinput=true, selectall=true, choices=ULib.cmds.translatedCmds["ulx ban"].args[4].completes}
	local banpanel = ULib.cmds.NumArg.x_getcontrol(ULib.cmds.translatedCmds["ulx ban"].args[3], 2)
	banpanel:SetParent(xgui_banwindow)
	banpanel.interval:SetParent(xgui_banwindow)
	banpanel.interval:SetPos(200, 80)
	banpanel.val:SetParent(xgui_banwindow)
	banpanel.val:SetPos(75, 100)
	banpanel.val:SetWidth(200)

	local steamIDBox = xlib.maketextbox{x=75, y=30, w=200, selectall=true, disabled=true, parent=xgui_banwindow}
	steamIDBox:SetValue(steamID)
	
	xlib.makebutton{x=165, y=125, w=75, label="Cancel", parent=xgui_banwindow}.DoClick = function()
		xgui_banwindow:Remove()
	end
	xlib.makebutton{x=45, y=125, w=75, label="Ban!", parent=xgui_banwindow}.DoClick = function()
		local isOnline = false
		for k, v in ipairs(player.GetAll()) do
			if v:SteamID() == steamIDBox:GetValue() then
				isOnline = v
				break
			end
		end
		if not isOnline then
			RunConsoleCommand("ulx", "banid", steamIDBox:GetValue(), banpanel:GetValue(), reason:GetValue())
		else
			RunConsoleCommand("ulx", "ban", "$" .. ULib.getUniqueIDForPlayer(isOnline), banpanel:GetValue(), reason:GetValue())
		end
		xgui_banwindow:Remove()
	end
end