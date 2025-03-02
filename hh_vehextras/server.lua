local QBCore = exports['qb-core']:GetCoreObject()

local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GeneratePlate()
	local plate = tostring(GetRandomNumber(1)) .. GetRandomLetter(2) .. tostring(GetRandomNumber(3)) .. GetRandomLetter(2)
	local result = exports.oxmysql:scalarSync('SELECT plate FROM player_vehicles WHERE plate=@plate', {['@plate'] = plate})
	if result then
		plate = tostring(GetRandomNumber(1)) .. GetRandomLetter(2) .. tostring(GetRandomNumber(3)) .. GetRandomLetter(2)
	end
	return plate:upper()
end
  
function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
	  return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
	  return ''
	end
end
  
function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
	  return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
	  return ''
	end
end




QBCore.Commands.Add("givecar", "Give Vehicle to Players (Admin Only)", {{name="id", help="Player ID"}, {name="model", help="Vehicle Model, for example: t20"}, {name="plate", help="Custom Number Plate (Leave to assign random) , for example: ABC123"}}, false, function(source, args)
    local ply = QBCore.Functions.GetPlayer(source)
    local veh = args[2]
    local plate = args[3]
    local tPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if plate == nil or plate == "" then plate = GeneratePlate() end
    if veh ~= nil and args[1] ~= nil then
        TriggerClientEvent('hhfw:client:givecar', args[1], veh, plate)
	TriggerClientEvent("QBCore:Notify", source, "You gave vehilce to "..tPlayer.PlayerData.charinfo.firstname.." "..tPlayer.PlayerData.charinfo.lastname.." Vehicle :"..veh.." With Plate : "..plate, "success", 8000)
    else 
        TriggerClientEvent('QBCore:Notify', source, "Incorrect Format", "error")
    end
end, "god")

RegisterCommand("givecar", function(source, args)
    -- If the source is > 0, then that means it must be a player.
	local ply = QBCore.Functions.GetPlayer(source)
	local veh = args[2]
	local plate = args[3]
	local tPlayer = QBCore.Functions.GetPlayer(tonumber(args[1]))
	if plate == nil or plate == "" then plate = GeneratePlate() end
	if veh ~= nil and args[1] ~= nil then
		TriggerClientEvent('hhfw:client:givecar', args[1], veh, plate)
	end
end, false)

RegisterServerEvent('hhfw:server:SaveCar')
AddEventHandler('hhfw:server:SaveCar', function(mods, vehicle, hash, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = exports.oxmysql:executeSync('SELECT plate FROM player_vehicles WHERE plate=@plate', {['@plate'] = plate})
    if result[1] == nil then
        exports.oxmysql:execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @state)', {
            ['@license'] = Player.PlayerData.license,
            ['@citizenid'] = Player.PlayerData.citizenid,
            ['@vehicle'] = vehicle.model,
            ['@hash'] = vehicle.hash,
            ['@mods'] = json.encode(mods),
            ['@plate'] = plate,
            ['@state'] = 0
        })
        TriggerClientEvent('QBCore:Notify', src, 'The vehicle is now yours!', 'success', 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, 'This vehicle is already yours..', 'error', 3000)
    end
end)



-------------Transfer Vehicle-------------


QBCore.Commands.Add("transfercar", "Transfer Vehicle to Other Player (Must Be in Vehicle)", {{name="id", help="Player ID"}}, false, function(source, args)
    local id = args[1]
    local plate = args[2]
    if id ~= nil then
        TriggerClientEvent('hhfw:client:transferrc', source, id)
    else 
        TriggerClientEvent('QBCore:Notify', source, "Please Provide ID", "error")
    end
end)


RegisterServerEvent('hhfw:GiveRC')
AddEventHandler('hhfw:GiveRC', function(player, target, plate)
    local src = source
	local xPlayer = QBCore.Functions.GetPlayer(player)
	local tPlayer = QBCore.Functions.GetPlayer(target)
    
    exports.oxmysql:executeSync("SELECT * FROM `player_vehicles` WHERE `plate` = '"..plate.."' AND `citizenid` = '"..xPlayer.PlayerData.citizenid.."'", function(result)
        if result[1] ~= nil and next(result[1]) ~= nil then
            if plate == result[1].plate then
                exports.oxmysql:execute('DELETE FROM player_vehicles WHERE plate=@plate AND vehicle=@vehicle', {['@plate'] = plate, ['@vehicle'] = result[1].vehicle})
                exports.oxmysql:execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @state)', {
                    ['@steam'] = tPlayer.PlayerData.license,
                    ['@citizenid'] = tPlayer.PlayerData.citizenid,
                    ['@vehicle'] = result[1].vehicle,
                    ['@hash'] = GetHashKey(result[1].vehicle),
                    ['@mods'] = json.encode(result[1].mods),
                    ['@plate'] = result[1].plate,
                    ['@state'] = 0
                })
                TriggerClientEvent("QBCore:Notify", player, "You gave registration paper to "..tPlayer.PlayerData.charinfo.firstname.." "..tPlayer.PlayerData.charinfo.lastname, "error", 8000)
                TriggerClientEvent("QBCore:Notify", target, "You received registration paper from "..xPlayer.PlayerData.charinfo.firstname.." "..xPlayer.PlayerData.charinfo.lastname, "success", 8000)     
            else
                TriggerClientEvent("QBCore:Notify", src, "You dont't own this vehicle", "error", 5000)
            end
        else
            TriggerClientEvent("QBCore:Notify", src, "You dont't own this vehicle", "error", 5000)
        end
    end)
end)