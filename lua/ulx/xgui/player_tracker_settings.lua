local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }

plist:Add(xlib.makelabel{label="Steam API Key (Requried for Family Sharing detection)"})
plist:Add(xlib.makelabel{label="Warning: Everyone with access to these settings can\nview this!"})
local apibox = plist:Add(xlib.maketextbox{})
apibox.OnValueChange = function(self, value)
    net.Start("ulx_playertracker_steamapikey_write")
    net.WriteString(value)
    net.SendToServer()
end
plist:Add(xlib.makelabel{label="Press enter to save!\n"})

net.Receive("ulx_playertracker_steamapikey", function()
    apibox:SetText(net.ReadString())
end)
net.Start("ulx_playertracker_steamapikey")
net.SendToServer()

plist:Add(xlib.makecheckbox{label="Announce when players connect with a new name", repconvar="ulx_playertrackernamealert"})
plist:Add(xlib.makecheckbox{label="Prevent ban-evasion using Family Sharing", repconvar="ulx_playertrackerfsevadeban"})
--plist:Add(xlib.makecheckbox{label="Prevent ban-evasion using current IP Addresses", repconvar="ulx_playertracker_ipevadeban"})

xgui.addSubModule("ULX Player Tracker", plist, "ulx playertrackersteamapikey", "server")
