--九线传奇模块
module('NineLinesLegend',package.seeall)

--九线传奇Bonus游戏
function PlayBonusGame(ninelineslegendInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取本次Bonus的结果
    local playResult = ninelineslegendInfo.bres[1]
    table.remove(ninelineslegendInfo.bres,1)
    -- 增加Bonus游戏次数
    ninelineslegendInfo.bonus.times = ninelineslegendInfo.bonus.times + 1

    local winScore = 0
    local jackpot = {}
    if playResult.mul == 0 then
        jackpot ={
            lackTimes = 0,
            totalTimes = 1,
            poolId = playResult.jackpot,
            tWinScore = ninelineslegendInfo.bonus.jackpotScore,
        }
        -- 中了奖池
        winScore = ninelineslegendInfo.bonus.jackpotScore
        local userinfo =  unilight.getdata('userinfo',uid)
        gamecommon.AddJackpotHisory(uid,GameId,gameType,0,jackpot.tWinScore,{pool = jackpot.poolId})
    else
        winScore = playResult.mul * ninelineslegendInfo.betMoney
    end

    ninelineslegendInfo.bonus.tWinScore = ninelineslegendInfo.bonus.tWinScore + winScore
    -- 返回数据
    local res = GetResInfo(uid, ninelineslegendInfo, gameType, nil, {})
    -- 判断是否结算
    if ninelineslegendInfo.bonus.times >= ninelineslegendInfo.bonus.totalTimes then
        if ninelineslegendInfo.bonus.tWinScore > 0 then
            if ninelineslegendInfo.free.totalTimes ~= -1 then
                ninelineslegendInfo.free.tWinScore = ninelineslegendInfo.free.tWinScore + ninelineslegendInfo.bonus.tWinScore
            else
                -- 获取奖励
                BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, ninelineslegendInfo.bonus.tWinScore, Const.GOODS_SOURCE_TYPE.NINELINESLEGEND)
            end
        end
    end
    -- 发送结果数据
    if playResult.mul == 0 then
        res.features.bonus.jackpot = playResult.jackpot
    else
        res.features.bonus.mul = playResult.mul
    end
    res.winScore = winScore
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        ninelineslegendInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='bonus',mul = playResult.mul,totalTimes=ninelineslegendInfo.bonus.totalTimes,lackTimes=ninelineslegendInfo.bonus.totalTimes-ninelineslegendInfo.bonus.times,tWinScore=ninelineslegendInfo.bonus.tWinScore},
        jackpot
    )
    if ninelineslegendInfo.bonus.times >= ninelineslegendInfo.bonus.totalTimes then
        ninelineslegendInfo.bonus.totalTimes = -1                                     -- 总次数
        ninelineslegendInfo.bonus.times = 0                                           -- 游玩次数
        ninelineslegendInfo.bonus.tWinScore = 0                                       -- 已经赢得的钱
        ninelineslegendInfo.bonus.jackpotId = 0                                       -- 奖池ID
        ninelineslegendInfo.bonus.jackpotScore = 0                                    -- 奖池金额
        ninelineslegendInfo.bres = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,ninelineslegendInfo)
    return res
end

-- 预计算bonus
function AheadBonus(uid,gameType,datainfo)
    -- 增加本次Bonus预计算游玩次数
    datainfo.bonus.times = datainfo.bonus.times + 1
    -- 纯随机
    local probability = {}
    local allResult = {}
    local playResult
    if datainfo.bonus.jackpotId == 0 then
        -- for i, v in ipairs(NineLinesLegend['table_112_bonus_'..gameType]) do
        --     if v.pro > 0 then
        --         table.insert(probability, v.pro)
        --         table.insert(allResult, {v.pro, {jackpot = v.jackpot, mul = v.mul}})
        --     end
        -- end
        -- -- 获取随机后的结果
        -- playResult = math.random(probability, allResult)[2]
        -- 获取随机后的结果
        local bonusInfo = NineLinesLegend['table_112_bonus_'..gameType][gamecommon.CommRandInt(NineLinesLegend['table_112_bonus_'..gameType], 'pro')]
        playResult = {jackpot = bonusInfo.jackpot, mul = bonusInfo.mul}
    else
        playResult = {jackpot = datainfo.bonus.jackpotId, mul = 0}
    end

    -- 保存本次随机的结果
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,playResult)
    -- 循环添加已经随机出现的结果  获取总奖励
    local tWinScore = 0
    for i, v in ipairs(datainfo.bres) do
        tWinScore = tWinScore + (v.mul * datainfo.betMoney)
    end
    -- 增加bonus结算金额
    if datainfo.bonus.jackpotScore > 0 then
        tWinScore = tWinScore + datainfo.bonus.jackpotScore
    end
    local lackTimes = datainfo.bonus.totalTimes - datainfo.bonus.times
    return tWinScore,lackTimes
end