QBCore = exports[config.FrameworkResource]:GetCoreObject()

local function GenderCheck(ped)
    if IsPedModel(ped, "mp_m_freemode_01") then
        return "Male"
    elseif IsPedModel(ped, "mp_f_freemode_01") then
        return "Female"
    end
    return "custom"
end

local function ItemCheck()
    local PlayerPed = PlayerPedId()
    local PlayerGender = GenderCheck(PlayerPed)

    for k, v in pairs(config.Bags) do
        local componentID = v["ComponentId"] or 5
        local CurrentDrawable, CurrentTexture =
            GetPedDrawableVariation(PlayerPed, componentID),
            GetPedTextureVariation(PlayerPed, componentID)
        if
            (CurrentDrawable == v[string.format("Clothing%sID", PlayerGender)] and
                CurrentTexture == v[string.format("%sTextureID", PlayerGender)])
         then
            SetPedComponentVariation(PlayerPed, componentID, 0, 0, 0)
            break
        end
    end

    if PlayerGender == "custom" then
        return
    end

    for k, v in pairs(config.Bags) do
        local componentID = v["ComponentId"] or 5
        if QBCore.Functions.HasItem(v.Item) then
            SetPedComponentVariation(
                PlayerPed,
                componentID,
                v[string.format("Clothing%sID", PlayerGender)],
                v[string.format("%sTextureID", PlayerGender)],
                0
            )
            break
        end
    end
end

if config.InvType == "qb" then
    RegisterNetEvent(
        "mri_Qbackpack:client:OpenBag",
        function(ItemID, ItemInfo)
            TriggerEvent("inventory:client:SetCurrentStash", "Backpack" .. tostring(ItemID))
            TriggerServerEvent(
                "inventory:server:OpenInventory",
                "stash",
                "Backpack" .. tostring(ItemID),
                {maxweight = config.Bags[ItemInfo].InsideWeight, slots = config.Bags[ItemInfo].Slots}
            )
        end
    )
elseif config.InvType == "ox" then
    RegisterNetEvent(
        "mri_Qbackpack:client:OpenBag",
        function(ItemID, ItemInfo)
            exports[config.InvName]:openInventory("stash", "Backpack" .. tostring(ItemID))
        end
    )
end

RegisterNetEvent(
    "QBCore:Client:OnPlayerLoaded",
    function()
        Wait(1000)
        ItemCheck()
    end
)

RegisterNetEvent(
    "QBCore:Player:SetPlayerData",
    function()
        Wait(1000)
        ItemCheck()
    end
)

AddEventHandler(
    "onResourceStart",
    function(resource)
        if GetCurrentResourceName() == resource then
            Wait(1000)
            ItemCheck()
        end
    end
)
