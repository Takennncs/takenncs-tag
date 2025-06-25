local currentAdminPlayers = {}
local visibleAdmins = {}
local closeAdmins = {}
local Callbacks = {}

RegisterNetEvent('takenncs-tag:callback_response')
AddEventHandler('takenncs-tag:callback_response', function(name, requestId, ...)
    if Callbacks[requestId] then
        Callbacks[requestId](...)
        Callbacks[requestId] = nil
    end
end)

function callCallback(name, cb, ...)
    local requestId = math.random(100000,999999)
    Callbacks[requestId] = cb
    TriggerServerEvent('takenncs-tag:callback_request', name, requestId, ...)
end


RegisterNetEvent('takenncs-tag:set_admins')
AddEventHandler('takenncs-tag:set_admins', function(admins)
    currentAdminPlayers = admins
    for id in pairs(visibleAdmins) do
        if not admins[id] then
            visibleAdmins[id] = nil
        end
    end
end)

CreateThread(function()
    TriggerServerEvent('takenncs-tag:requestAdmins')
end)

RegisterNetEvent('takenncs-tag:sendAdmins')
AddEventHandler('takenncs-tag:sendAdmins', function(admins)
    currentAdminPlayers = admins
end)

CreateThread(function()
    while true do
        Wait(Config.NearCheckWait or 1000)
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        for _, admin in pairs(currentAdminPlayers) do
            local playerId = GetPlayerFromServerId(admin.source)
            if playerId ~= -1 then
                local adminPed = GetPlayerPed(playerId)
                local adminCoords = GetEntityCoords(adminPed)
                local distance = #(adminCoords - pedCoords)
                if distance < 40 then
                    visibleAdmins[admin.source] = admin
                else
                    visibleAdmins[admin.source] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        closeAdmins = {}

        for _, admin in pairs(visibleAdmins) do
            local playerId = GetPlayerFromServerId(admin.source)
            if playerId ~= -1 then
                local adminPed = GetPlayerPed(playerId)
                local label

                if admin.permission then
                    label = Config.GroupLabels.ESX[1][admin.permission]
                elseif admin.group then
                    label = Config.GroupLabels.ESX[2][admin.group]
                elseif admin.qbcore then
                    label = Config.GroupLabels.QBCore[1][admin.qbcore]
                end

                if label then
                    local steamLabel = admin.steamName or "UNKNOWN"
                    local icon = " " 

                    local fullLabel = icon .. steamLabel .. " - " .. label

                    closeAdmins[playerId] = {
                        ped = adminPed,
                        label = fullLabel,
                        source = admin.source,
                        self = admin.source == GetPlayerServerId(PlayerId()),
                    }
                end
            end
        end
    end
end)


CreateThread(function()
    while true do
        if next(closeAdmins) then
            Wait(0)
            for _, info in pairs(closeAdmins) do
                if info.label and (not info.self or Config.SeeOwnLabel) then
                    local coords = GetEntityCoords(info.ped)
                    if coords then
                        draw3DText(coords + (Config.Offset or vector3(0,0,1)), info.label, { size = Config.TextSize or 0.8, color = {r=255, g=165, b=0, a=255} })
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)

function draw3DText(pos, text, options)
    options = options or {}
    local color = options.color or { r = 255, g = 165, b = 0, a = 255 }
    local size = options.size or 0.5 

    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - pos)
    if dist < 1.0 then dist = 1.0 end

    local scale = (size / dist) * 1.5 
    local fov = (1 / GetGameplayCamFov()) * 100
    local finalScale = scale * fov

    SetDrawOrigin(pos.x, pos.y, pos.z, 0)
    SetTextProportional(1)
    SetTextScale(0.0 * finalScale, 0.35 * finalScale)  
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)

    SetTextColour(255, 255, 255, color.a / 5)
    DrawText(0.01, 0.01)

    ClearDrawOrigin()
end
