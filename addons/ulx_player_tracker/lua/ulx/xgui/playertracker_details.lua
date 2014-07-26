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