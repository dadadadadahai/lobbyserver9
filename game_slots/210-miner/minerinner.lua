module('miner',package.seeall)
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
    local TableStock = StockMap[gameType]
    if TableStock==nil then
        return nil
    end
    return{
        targetStock = table_210_sessions[gameType].initStock,
        Stock = TableStock.Stock,
        taxRatio = table_210_other[gameType].tax,
        decPeriod = table_210_other[gameType].per,
        decRatio = table_210_other[gameType].decPercent,
        type = table_210_other[gameType].type,
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
    
    错误返回
]]
function SetStockInfo(gameType,data)
    local TableStock = StockMap[gameType]
    if TableStock==nil then
        return false
    end
    table_210_other[gameType].type = data.type
    table_210_sessions[gameType].initStock =data.targetStock
    TableStock.Stock =data.Stock
    table_210_other[gameType].tax = data.taxRatio
    table_210_other[gameType].per = data.decPeriod
    table_210_other[gameType].decPercent = data.decRatio
    return true
end