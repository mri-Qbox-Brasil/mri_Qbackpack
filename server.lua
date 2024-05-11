QBCore = exports[config.FrameworkResource]:GetCoreObject()

local loadFile = LoadResourceFile(GetCurrentResourceName(), "./IdList.json")
local IdList = json.decode(loadFile)

local function GenerateID(id)
    local id = math.random(1000000000,9999999999)
    for i = 1,#IdList,1 do
        while IdList[i] == id do
            id = math.random(1000000000,9999999999)
        end
    end
    IdList[#IdList+1] = id
    SaveResourceFile(GetCurrentResourceName(), "IdList.json", json.encode(IdList), 0)
    return(id)
end


if config.InvType == 'qb' then
    for i = 1,#config.Bags,1 do
        QBCore.Functions.CreateUseableItem(config.Bags[i].Item, function(source,item)
            if not item.info.id then
                local Player = QBCore.Functions.GetPlayer(source)
                local newitem = Player.PlayerData.items[item.slot]
                newitem.info.id = GenerateID() 
                exports[config.InvName]:SetInventory(source,Player.PlayerData.items)
                TriggerClientEvent('yaldabotit-backpack:client:OpenBag',source,newitem.info.id,i)
            else
            TriggerClientEvent('yaldabotit-backpack:client:OpenBag',source,item.info.id,i)
            end
        end)
    end
elseif config.InvType == 'ox' then
    for i = 1,#config.Bags,1 do
        QBCore.Functions.CreateUseableItem(config.Bags[i].Item, function(source,item)
            if not item.metadata.id then
                item.metadata.id = GenerateID() 
                exports[config.InvName]:SetMetadata(source, item.slot, item.metadata)
            end
            exports[config.InvName]:RegisterStash('Backpack'..tostring(item.metadata.id),'Mochila', config.Bags[i].Slots, config.Bags[i].InsideWeight)
            TriggerClientEvent('yaldabotit-backpack:client:OpenBag',source,item.metadata.id,i)
        end)
    end

    local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        print(json.encode(payload, { indent = true }))
        return false
    end, {
        print = true,
        itemFilter = {
            backpack1 = true,
            backpack2 = true,
            duffle1 = true
        },
        inventoryFilter = {
            '^Backpack[%w]+',
        }
    })
    
    local count = 0
    function countBackpacks()
        count = 0
        for i = 1, #config.Bags do
            local countBag = exports.ox_inventory:Search('count', config.Bags[i].Item)
            print(countBag)
            count = count + tonumber(countBag)
        end
        return count
    end

    AddEventHandler('onServerResourceStop', function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end
        ox_inventory:removeHooks()
    end)
end