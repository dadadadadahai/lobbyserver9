module('PenaltyKick',package.seeall)
--[[
    获取库存详情
    return{
        targetStock     --目标库存
        Stock           --实际库存
        taxRatio        --抽水比例
        decPeriod       --衰减周期
        decRatio        --衰减比例
        type            --衰减方式 1局数 2分钟
        tTax            --累计抽水
    }
    错误返回nil
]]
function GetStockInfo(gameType)
    if Stock[gameType]== nil or Extraction[gameType] == nil or Attenuation[gameType] == nil then
        return nil
    end

    return{
        targetStock = table_201_sessions[gameType].initStock,
        Stock = Stock[gameType],
        taxRatio = table_201_other[1].extraction,
        decPeriod = table_201_other[1].attenuationPeriod,
        decRatio = table_201_other[1].attenuationExtraction,
        type = AttenuationType,
        tTax = Extraction[gameType],
        decval = Attenuation[gameType],  --累计衰减值
    }
end
--[[
    获取库存详情
   
        targetStock     --目标库存
        Stock           --实际库存
        taxRatio        --抽水比例
        decPeriod       --衰减周期
        decRatio        --衰减比例
    
    错误返回
]]
function SetStockInfo(gameType,data)
    if Stock[gameType]==nil then
        return nil
    end
    
    table_201_sessions[gameType].initStock =data.targetStock
    Stock[gameType] =data.Stock
    table_201_other[1].extraction = data.taxRatio
    table_201_other[1].attenuationPeriod = data.decPeriod
    table_201_other[1].attenuationExtraction = data.decRatio
    -- AttenuationType = data.type
    ChangeAttenuationType(data.type)
    return true
end
