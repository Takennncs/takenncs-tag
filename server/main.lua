SharedObject = nil
AdminPlayers = {}
local Callbacks = {}

if Config.Framework == 'QBCORE' then
    SharedObject = exports['qb-core']:GetCoreObject()
    for _, group in pairs(SharedObject.Config.Server.Permissions) do
        ExecuteCommand(("add_ace qbcore.%s tag.%s allow"):format(group, group))
        ExecuteCommand(("add_ace group.%s tag.%s allow"):format(group, group))
    end
end

RegisterNetEvent('takenncs-tag:callback_request')
AddEventHandler('takenncs-tag:callback_request', function(name, requestId, ...)
    local src = source
    if Callbacks[name] then
        Callbacks[name](src, function(...)
            TriggerClientEvent('takenncs-tag:callback_response', src, name, requestId, ...)
        end, ...)
    end
end)

function registerCallback(name, cb)
    Callbacks[name] = cb
end

local function GetSteamID(src)
    local ids = GetPlayerIdentifiers(src)
    for _, id in pairs(ids) do
        if string.sub(id, 1, 6) == "steam:" then
            return id
        end
    end
    return "UnknownSteam"
end

RegisterCommand('tag', function(source, args)
    if Config.Framework ~= 'QBCORE' then return end

    if AdminPlayers[source] == nil then
        for _, group in pairs(SharedObject.Config.Server.Permissions) do
            if IsPlayerAceAllowed(source, "tag." .. group) then
                local steamID = GetSteamID(source)
                AdminPlayers[source] = { source = source, qbcore = group, steamName = steamID }
                break
            end
        end
        TriggerClientEvent('QBCore:Notify', source, 'Tag on', 'success')
    else
        AdminPlayers[source] = nil
        TriggerClientEvent('QBCore:Notify', source, 'Tag off', 'error')
    end

    TriggerClientEvent('takenncs-tag:set_admins', -1, AdminPlayers)
end)

registerCallback('getAdminsPlayers', function(source, cb)
    cb(AdminPlayers)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if AdminPlayers[src] then
        AdminPlayers[src] = nil
        TriggerClientEvent('takenncs-tag:set_admins', -1, AdminPlayers)
    end
end)
