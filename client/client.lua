local pedCount = 0
local Authorize = false
local BrokenWagonsCleared = false

TriggerServerEvent('CheckSteamHex')

RegisterNetEvent('SteamHexAuthorized')
AddEventHandler('SteamHexAuthorized', function(isAuthorized)
    if isAuthorized then
        Authorize = true
    else
        Authorize = false
    end
end)

local function CleanUpDeadNPCs()
    pedCount = 0

    for ped in EnumeratePeds() do
        if not IsPedAPlayer(ped) and IsPedDeadOrDying(ped, true) then
            if Config.ClearOnlyDeadHumanPed then
                if IsPedHuman(ped) then
                    pedCount = pedCount + 1
                    DeleteEntity(ped)
                end
            else
                pedCount = pedCount + 1
                DeleteEntity(ped)
            end
        end
    end
end

function EnumeratePeds()
    return coroutine.wrap(function()
        local pedHandle, ped = FindFirstPed()
        local success
        repeat
            coroutine.yield(ped)
            success, ped = FindNextPed(pedHandle)
        until not success
        EndFindPed(pedHandle)
    end)
end

local function CleanUpBrokenWagons()
    if not Config.ClearBrokenWagons then
        return
    end

	BrokenWagonsCleared = false

    local WagonList = GetGamePool('CVehicle')
    local wagon, driver, horse = nil, nil, nil

    for _, wagon in ipairs(WagonList) do
        if IsEntityAVehicle(wagon) and IsVehicleStopped(wagon) and not IsEntityAMissionEntity(wagon) then
            horse = Citizen.InvokeNative(0xA8BA0BAE0173457B, wagon, 0)
            if horse ~= 0 and IsPedWalking(horse) then
                driver = Citizen.InvokeNative(0x2963B5C1637E8A27, wagon)
                if driver ~= PlayerPedId() then
                    if driver ~= 0 then
                        DeleteEntity(driver)
                    end
					Citizen.InvokeNative(0x3BCF32FF37EA9F1D, vehicle) -- RemoveVehiclePropSets
                    Citizen.InvokeNative(0xE31C0CB1C3186D40, vehicle) -- RemoveVehicleLightPropSets
                    DeleteEntity(wagon)
					BrokenWagonsCleared = true
                end
            end
        end
    end
end

CreateThread(function()
    while Config.AutomaticClear do
        Wait(Config.AutomaticClearTime * 60 * 1000)
        CleanUpDeadNPCs()

		if Config.ClearBrokenWagons then
			CleanUpBrokenWagons()
			if Config.Debug and BrokenWagonsCleared then
				print("[Automatic] Broken Wagons Cleared")
			end
		end

        if Config.ClearChat then
            TriggerEvent('chat:clear')
            if Config.Debug then
                print("Chat Cleared")
            end
        end

		if Config.Debug then
			print(("[Automatic] Number of dead NPCs cleared: %d"):format(pedCount))
		end
    end
end)

RegisterCommand(Config.ManualClearCommand, function()
	if Authorize then
		if Config.ManualClear then
			CleanUpDeadNPCs()

		if Config.ClearBrokenWagons then
			CleanUpBrokenWagons()
			if Config.Debug and BrokenWagonsCleared then
				print("[Manual] Broken Wagons Cleared")
			end
		end

        if Config.ClearChat then
            TriggerEvent('chat:clear')
            if Config.Debug then
                print("Chat Cleared")
            end
        end

			if Config.Debug then
				print(("[Manual] Number of dead NPCs cleared: %d"):format(pedCount))
			end
		end
	else
		print("[System] You are not authorized to use this command")
	end
end, false)