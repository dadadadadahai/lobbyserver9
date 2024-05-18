module('WorldCup',package.seeall)
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
        decval = 0,         --累计衰减值
    }
    错误返回nil
]]
function GetStockInfo(gameType)
    local TableStock = MapRoom[gameType]
    if TableStock==nil then
        return nil
    end
    print('GetStockInfo decval='..TableStock.decval)
    return{
        targetStock = table_206_sessions[gameType].initStock,
        Stock = TableStock.Stock,
        taxRatio = table_206_other[gameType].tax,
        decPeriod = table_206_other[gameType].per,
        decRatio = table_206_other[gameType].decPercent,
        type = table_206_other[gameType].type,
        tTax = TableStock.tax,
        decval = TableStock.decval,  --累计衰减值
    }
end
--[[
    获取库存详情
   
        targetStock     --目标库存
        Stock           --实际库存
        taxRatio        --抽水比例
        decPeriod       --衰减周期
        decRatio        --衰减比例
        type            --衰减方式
    
    错误返回
]]
function SetStockInfo(gameType,data)
    local TableStock = MapRoom[gameType]
    if TableStock==nil then
        return false
    end
    table_206_other[gameType].type = data.type
    table_206_other[gameType].initStock =data.targetStock
    TableStock.Stock =data.Stock
    table_206_other[gameType].tax = data.taxRatio
    table_206_other[gameType].per = data.decPeriod
    table_206_other[gameType].decPercent = data.decRatio
    return true
end