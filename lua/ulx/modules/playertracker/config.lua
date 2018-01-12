ULib.ucl.registerAccess("ulx playertrackersteamapikey", ULib.ACCESS_SUPERADMIN, _, "Cvar")
local apikeycvar = CreateConVar("ulx_playertrackersteamapikey", "", FCVAR_PROTECTED, "Steam API Key (Required for Family Sharing Detection)")

util.AddNetworkString("ulx_playertracker_steamapikey_write")
util.AddNetworkString("ulx_playertracker_steamapikey")

local hiddenSettings = {}

net.Receive("ulx_playertracker_steamapikey_write", function(len, ply)
    if ply:query("ulx playertrackersteamapikey") then
        apikeycvar:SetString(net.ReadString())

        hiddenSettings["steamapikey"] = apikeycvar:GetString()
        ULib.fileWrite("data/ulx/playertracker.txt", ULib.makeKeyValues(hiddenSettings))

        net.Start("ulx_playertracker_steamapikey")
        net.WriteString(apikeycvar:GetString())
        net.Send(ZCore.ULX.getPlayersWithPermission("ulx playertrackersteamapikey"))
    end
end)

net.Receive("ulx_playertracker_steamapikey", function(len, ply)
    if ply:query("ulx playertrackersteamapikey") then
        net.Start("ulx_playertracker_steamapikey")
        net.WriteString(apikeycvar:GetString())
        net.Send(ply)
    end
end)

if file.Exists("ulx/playertracker.txt", "data") then
    hiddenSettings = ULib.parseKeyValues(ULib.fileRead("data/ulx/playertracker.txt"))
else
    ULib.fileWrite("data/ulx/playertracker.txt", ULib.makeKeyValues(hiddenSettings))
end
apikeycvar:SetString(hiddenSettings["steamapikey"] or "")

ulx.convar("playertrackernamealert", 1, "Announce when players connect with a new name.", ULib.ACCESS_SUPERADMIN)
ulx.convar("playertrackerfsevadeban", 0, "Family Sharing ban evasion protection", ULib.ACCESS_SUPERADMIN)
--ulx.convar("playertrackeripevadeban", 0, "IP Address ban evasion protection", ULib.ACCESS_SUPERADMIN)
