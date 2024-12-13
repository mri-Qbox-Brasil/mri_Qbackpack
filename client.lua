QBCore = exports[config.FrameworkResource]:GetCoreObject()


local function GenderCheck()
    local PlayerPed = PlayerPedId()
    if IsPedModel(PlayerPed,"mp_m_freemode_01") then
        gender = 'male'
    elseif IsPedModel(PlayerPed,"mp_f_freemode_01") then
        gender = 'female'
    else
        gender = 'custom'
    end
    return(gender)
end

local function ItemCheck()
    local PlayerPed = PlayerPedId()
    local PlayerGender = GenderCheck()
    local CurrentBag = nil

    for i = 1, #config.Bags, 1 do
        if QBCore.Functions.HasItem(config.Bags[i].Item) then
            CurrentBag = i
            break
        end
    end

    if CurrentBag ~= nil then
        if PlayerGender == 'male' then
            SetPedComponentVariation(PlayerPed, 5, config.Bags[CurrentBag].ClothingMaleID, config.Bags[CurrentBag].MaleTextureID, 0)
        elseif PlayerGender == 'female' then
            SetPedComponentVariation(PlayerPed, 5, config.Bags[CurrentBag].ClothingFemaleID, config.Bags[CurrentBag].FemaleTextureID, 0)
        end
    else
        local CurrentDrawable, CurrentTexture = GetPedDrawableVariation(PlayerPed, 5), GetPedTextureVariation(PlayerPed, 5)
        local shouldReset = false

        for i = 1, #config.Bags, 1 do
            if (PlayerGender == 'male' and CurrentDrawable == config.Bags[i].ClothingMaleID and CurrentTexture == config.Bags[i].MaleTextureID) or
               (PlayerGender == 'female' and CurrentDrawable == config.Bags[i].ClothingFemaleID and CurrentTexture == config.Bags[i].FemaleTextureID) then
                shouldReset = true
                break
            end
        end

        if shouldReset then
            SetPedComponentVariation(PlayerPed, 5, 0, 0, 0)
        end
    end
end


if config.InvType == 'qb' then
    RegisterNetEvent('yaldabotit-backpack:client:OpenBag', function(ItemID,ItemInfo)
        TriggerEvent("inventory:client:SetCurrentStash", 'Backpack'..tostring(ItemID))
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', 'Backpack'..tostring(ItemID), {maxweight = config.Bags[ItemInfo].InsideWeight , slots = config.Bags[ItemInfo].Slots})
    end)
elseif config.InvType == 'ox' then
    RegisterNetEvent('yaldabotit-backpack:client:OpenBag', function(ItemID,ItemInfo)
        exports[config.InvName]:openInventory('stash', 'Backpack'..tostring(ItemID))
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    ItemCheck()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Wait(1000)
    ItemCheck()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    Wait(1000)
    ItemCheck()
end)

AddEventHandler('onResourceStart', function(resource)
	if GetCurrentResourceName() == resource then
        Wait(1000)
        ItemCheck()
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
        Wait(1000)
        ItemCheck()
	end
end)