module("DayStatisticsMgr", package.seeall)

local table_stock_tax = import("table/table_stock_tax")
local table_stock_single = import ("table/table_stock_single")
local daySec = 86400

--统计每日货币
function DayChipsStatics(dayNum)
    dayNum = dayNum or 0

    --非充值玩家金币总数
    local filterStr1 = '"property.totalRechargeChips":{"$eq":' .. 0 .. '}'
    local noRechargeAllChips = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"null", "allchips":{"$sum":"$property.chips"} }}'))
    if table.len(info) > 0 then
        noRechargeAllChips = info[1].allchips
    end

    --充值玩家金币总数
    local filterStr1 = '"property.totalRechargeChips":{"$gt":' .. 0 .. '}'
    local rechargeAllChips = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"null", "allchips":{"$sum":"$property.chips"} }}'))
    if table.len(info) > 0 then
        rechargeAllChips = info[1].allchips
    end


    --每日赠送金币
    local beginTime = chessutil.ZeroTodayTimestampGet() + (dayNum * daySec)
    local endTime = beginTime + 86400
    local filterStr1 = '"opType":{"$eq":' .. 3 .. '}'
    filterStr1 = filterStr1 .. ', "timestamp":{"$gte":' .. beginTime .. ', "$lte" : ' .. endTime .. '}'
    local presentChips = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "sum":{"$sum":"$opChips"}}}'))
    if table.len(info) > 0 then
        presentChips = info[1].sum
    end

    --每日充值金币
    local filterStr1 = '"opType":{"$eq":' .. 1 .. '}'
    filterStr1 = filterStr1 .. ', "timestamp":{"$gte":' .. beginTime .. ', "$lte" : ' .. endTime .. '}'
    local  rechargeChips = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "sum":{"$sum":"$opChips"}}}'))
    if table.len(info) > 0 then
        rechargeChips = info[1].sum
    end

    --每日提现
    local filterStr1 = '"opType":{"$eq":' .. 2 .. '}'
    filterStr1 = filterStr1 .. ', "timestamp":{"$gte":' .. beginTime .. ', "$lte" : ' .. endTime .. '}'
    local  withdrawChips = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "sum":{"$sum":"$opChips"}}}'))
    if table.len(info) > 0 then
        withdrawChips = info[1].sum
    end

    --库存值
    local totalStock = 0
    for k, v in pairs(table_stock_single) do
        local stockNum = gamecommon.GetStockNumByType(v.ID)
        totalStock = totalStock + stockNum
    end

    unilight.info("每日数据统计: 充值玩家总金币:%d, 非充值玩家总金币:%d, 库存金币:%d, 每日充值金币:%d, 每日提现:%d, 每日赠送:%d", noRechargeAllChips, rechargeAllChips, totalStock, rechargeChips, withdrawChips, presentChips)

    local curDayTimestamp = chessutil.ZeroTodayTimestampGet()
    local data={
        daytimestamp       = curDayTimestamp,        --今天0点时间截
        noRechargeAllChips = noRechargeAllChips,     --非充值玩家总金币
        rechargeAllChips   = rechargeAllChips,       --充值玩家总金币
        totalStock         = totalStock,             --当日总库存
        rechargeChips      = rechargeChips,          --当日总充值金币
        withdrawChips      = withdrawChips,          --当日总现现
        presentChips       = presentChips,           --当日总赠送
    }
    unilight.savedata("gameDayChipsStatisicLog", data )

end
