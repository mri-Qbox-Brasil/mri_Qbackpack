config = {}

config.FrameworkResource = 'qb-core' --Name of your qb-core resource
config.InvType = 'ox' --The type of inventory youre using (qb,ox)
config.InvName = 'ox_inventory' --The name of your qb-inventory resource (qb-inventory,lj-inventory,ox_inventory,etc...)

config.Bags = {

    { 
        ClothingMaleID = 82,
        MaleTextureID = 0,
        ClothingFemaleID = 82,
        FemaleTextureID = 0,
        InsideWeight = 100000, 
        Slots = 15, 
        Item = 'backpack1'
    },
    { 
        ClothingMaleID = 82,
        MaleTextureID = 6,
        ClothingFemaleID = 82,
        FemaleTextureID = 6,
        InsideWeight = 200000,
        Slots = 20, 
        Item = 'backpack2'
    },
    { 
        ClothingMaleID = 82,
        MaleTextureID = 4,
        ClothingFemaleID = 82,
        FemaleTextureID = 0,
        InsideWeight = 200000,
        Slots = 20, 
        Item = 'duffle1'
    },


}