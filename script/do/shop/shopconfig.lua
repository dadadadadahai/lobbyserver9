module("ShopMgr", package.seeall)
tableShopConfig = import "table/table_shop_config"

shopTypeList = {}
--按商品类型初始化表
function InitConfig()
    for _, shopConfig in pairs(tableShopConfig) do
        local shopId = shopConfig.ID
        local shopType = shopConfig.shopType
        if shopTypeList[shopType] == nil then
            shopTypeList[shopType] = {}
        end
        shopTypeList[shopType][shopId] = shopConfig 
    end
end


--根据类型获得商品列表
function GetShopListByType(shopType)
    return shopTypeList[shopType]
end

InitConfig()
