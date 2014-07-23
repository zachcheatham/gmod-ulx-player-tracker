xgui.prepareDataType("playertracker")

local xplayertracker = xlib.makepanel{parent=xgui.null}

xplayertracker.list = xlib.makelistview{x=5, y=30, w=574, h=329, multiselect=false, parent=xplayertracker}
xplayertracker.list:AddColumn("Name")
xplayertracker.list:AddColumn("Steam ID")
xplayertracker.list:AddColumn("IP Address")
xplayertracker.list:AddColumn("First Seen")
xplayertracker.list:AddColumn("Last Seen")
xplayertracker.list.DoDoubleClick = function(self, i, item)
	local steamID = item:GetValue(2)
	local data = xgui.data.playertracker[steamID]
	xgui.showPlayerDetailsDialog(steamID, data)
end

xlib.makelabel{x=410, y=8, label="Double click to view details.", parent=xplayertracker}

xplayertracker.search = xlib.maketextbox{x=5, y=5, w=150, text="Search...", selectall=true, parent=xplayertracker}

xplayertracker.search.OnEnter = function()
	xplayertracker.list:Clear()
	xgui.flushQueue("playertracker_populate")
	xplayertracker.populate(nil, true)
end

function xplayertracker.populate(players, doSearch)
	if not doSearch then
		for steamID, player in pairs(players) do
			xgui.queueFunctionCall(xplayertracker.addPlayer, "playertracker_populate", steamID, player)
		end
	else
		local searchTerm = xplayertracker.search:GetValue()
		local searchType = 0
		if searchTerm == "Search..." or string.len(searchTerm) == 0 then
			searchType = 3
		elseif ULib.isValidSteamID(searchTerm) then
			searchType = 1
		elseif ULib.isValidIP(searchTerm) then
			searchType = 2
		end
		
		for steamID, player in pairs(xgui.data.playertracker) do
			if searchType == 3 then
				xplayertracker.addPlayer(steamID, player)
			elseif searchType == 0 and (string.find(player.name, searchTerm)) then
				xplayertracker.addPlayer(steamID, player)
			elseif searchType == 1 and (steamID == searchTerm or player.owner_steam_id == searchTerm) then
				xplayertracker.addPlayer(steamID, player)
			elseif searchType == 2 and (player.ip == searchTerm or ((player.ip_2 and player.ip_2 == searchTerm) or (player.ip_3 and player_ip_3 == searchTerm))) then
				xplayertracker.addPlayer(steamID, player)
			end
		end
	end
end

function xplayertracker.addPlayer(steamID, player)
	xplayertracker.list:AddLine(player.name, (player.owner_steam_id and "*" or "") .. steamID, player.ip, os.date("%x", player.first_seen), os.date("%x", player.last_seen))
end

function xplayertracker.clear()
	xplayertracker.search:SetText("Search...")
	xplayertracker.list:Clear()
end

function xplayertracker.update(players)
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
		
		if xplayertracker.search:GetValue() == "" or xplayertracker.search:GetValue() == "Search..." then
			local t = {}
			t[steamID] = player
			xplayertracker.populate(t)
		end
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

function xgui.showPlayerDetailsDialog(steamID, data)
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

xgui.hookEvent("playertracker", "process", xplayertracker.populate)
xgui.hookEvent("playertracker", "clear", xplayertracker.clear)
xgui.hookEvent("playertracker", "add", xplayertracker.update)
xgui.addModule("Players", xplayertracker, "icon16/user_green.png", "xgui_playertracker")