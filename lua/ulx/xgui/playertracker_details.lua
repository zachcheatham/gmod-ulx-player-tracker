local currentDialog = nil

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
	currentDialog = xlib.makeframe{label="Details", w=281, h=273, skin=xgui.settings.skin}
	currentDialog.steamID = steamID
	
	local propSheet = xlib.makepropertysheet({x=0, y=0, w=281, h=273, parent=currentDialog})
	currentDialog.btnClose:MoveToFront()
	
	local detailsPanel = xlib.makepanel{parent=xgui.null}
	propSheet:AddSheet("Details", detailsPanel)
	
	local nameLabel = xlib.makelabel{label="Name:", x=22, y=8, parent=detailsPanel}
	local nameBox = xlib.maketextbox{x=55, y=5, w=160, text=data.name, parent=detailsPanel}
	nameBox:SetEditable(false)
	local nameCopyButton = xlib.makebutton{x=220, y=5, h=20, w=40, label="Copy", parent=detailsPanel}
	nameCopyButton.DoClick = function()
		copyText(nameBox)
	end
	
	local steamIDLabel = xlib.makelabel{label="Steam ID:", x=5, y=33, parent=detailsPanel}
	local steamIDBox = xlib.maketextbox{x=55, y=30, w=160, text=steamID, parent=detailsPanel}
	steamIDBox:SetEditable(false)
	local steamIDCopyButton = xlib.makebutton{x=220, y=30, h=20, w=40, label="Copy", parent=detailsPanel}
	steamIDCopyButton.DoClick = function()
		copyText(steamIDBox)
	end
	
	local profileIDLabel = xlib.makelabel{label="Profile ID:", x=5, y=58, parent=detailsPanel}
	local profileIDBox = xlib.maketextbox{x=55, y=55, w=160, text=util.SteamIDTo64(steamID), parent=detailsPanel}
	profileIDBox:SetEditable(false)
	local profileIDCopyButton = xlib.makebutton{x=220, y=55, h=20, w=40, label="Copy", parent=detailsPanel}
	profileIDCopyButton.DoClick = function()
		copyText(profileIDBox)
	end
	
	local firstSeenLabel = xlib.makelabel{label="First Seen:  " .. os.date("%x %I:%M %p", data.first_seen), x=5, y=80, parent=detailsPanel}
	local lastSeenLabel = xlib.makelabel{label="Last Seen:  " .. os.date("%x %I:%M %p", data.last_seen), x=5, y=98, parent=detailsPanel}

	local ipList = xlib.makelistview{x=5, y=118, w=210, h=73, multiselect=false, parent=detailsPanel}
	ipList:SetName("List")
	ipList:AddColumn("Recent IP Addresses")
	ipList:AddLine(data.ip)
	ipList:AddLine(data.ip_2)
	ipList:AddLine(data.ip_3)
	local ipCopyButton = xlib.makebutton{x=220, y=118, h=20, w=40, label="Copy", parent=detailsPanel}
	ipCopyButton.DoClick = function()
		copyText(ipList)
	end
	
	local familyShareLabel = xlib.makelabel{label="Family Sharing Owner:", x=5, y=196, parent=detailsPanel}
	local familyShareBox = xlib.maketextbox{x=5, y=212, w=210, text=(data.owner_steamid or "N/A"), parent=detailsPanel}
	familyShareBox:SetEditable(false)
	local familyShareCopyButton = xlib.makebutton{x=220, y=212, h=20, w=40, label="Copy", parent=detailsPanel}
	familyShareCopyButton.DoClick = function()
		copyText(familyShareBox)
	end
	
	local namesPanel = xlib.makepanel{parent=xgui.null}
	propSheet:AddSheet("Names", namesPanel)
	
	currentDialog.namesList = xlib.makelistview{multiselect=false, parent=namesPanel}
	currentDialog.namesList:SetName("List")
	currentDialog.namesList:Dock(FILL)
	currentDialog.namesList:AddColumn("Name")
	currentDialog.namesList:AddColumn("Time")
	
	RunConsoleCommand("_xgui", "pt_names", steamID)
end

function xplayertracker.recievedNames(steamID, data)
	if currentDialog and currentDialog.steamID == steamID then
		for _, name in ipairs(data) do
			xgui.queueFunctionCall(xplayertracker.addName, "playertracker_recievenames", name)
		end
	end
end

function xplayertracker.addName(name)
	if currentDialog then
		local timeString = ""
		if (os.time() - name.timestamp) < 86400 then
			timeString = os.date("%I:%M %p", name.timestamp)
		else
			timeString = os.date("%x %I:%M %p", name.timestamp)
		end
	
		currentDialog.namesList:AddLine(name.name, timeString)
	end
end