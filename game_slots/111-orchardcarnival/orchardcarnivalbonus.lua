--果园狂欢模块
module('OrchardCarnival',package.seeall)

--果园狂欢Bonus游戏
function PlayBonusGame(orchardcarnivalInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取本次Bonus的结果
    local playResult = orchardcarnivalInfo.bres[1]
    table.remove(orchardcarnivalInfo.bres,1)
    -- 增加Bonus游戏次数
    orchardcarnivalInfo.bonus.times = orchardcarnivalInfo.bonus.times + 1
    local winScore = playResult.mul * orchardcarnivalInfo.betMoney
    orchardcarnivalInfo.bonus.tWinScore = orchardcarnivalInfo.bonus.tWinScore + winScore
    -- 返回数据
    local res = GetResInfo(uid, orchardcarnivalInfo, gameType, nil, {})
    -- 判断是否结算
    if orchardcarnivalInfo.bonus.times >= orchardcarnivalInfo.bonus.totalTimes then
        if orchardcarnivalInfo.bonus.tWinScore > 0 then
            if orchardcarnivalInfo.free.totalTimes ~= -1 then
                orchardcarnivalInfo.free.tWinScore = orchardcarnivalInfo.free.tWinScore + orchardcarnivalInfo.bonus.tWinScore
                res.features.free.tWinScore = orchardcarnivalInfo.free.tWinScore
                if orchardcarnivalInfo.free.times >= orchardcarnivalInfo.free.totalTimes then
                    -- 获取奖励
                    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, orchardcarnivalInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ORCHARDCARNIVAL)
                    orchardcarnivalInfo.free.totalTimes = -1                                     -- 总次数
                    orchardcarnivalInfo.free.times = 0                                           -- 游玩次数
                    orchardcarnivalInfo.free.tWinScore = 0                                       -- 已经赢得的钱
                end
            else
                -- 获取奖励
                BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, orchardcarnivalInfo.bonus.tWinScore, Const.GOODS_SOURCE_TYPE.ORCHARDCARNIVAL)
            end
        end
    end
    -- 发送结果数据
    res.features.bonus.iconId = playResult.iconId
    res.winScore = winScore
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        orchardcarnivalInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='bonus',iconid = playResult.iconId,mul = playResult.mul,totalTimes=orchardcarnivalInfo.bonus.totalTimes,lackTimes=orchardcarnivalInfo.bonus.totalTimes-orchardcarnivalInfo.bonus.times,tWinScore=orchardcarnivalInfo.bonus.tWinScore},
        {}
    )
    if orchardcarnivalInfo.bonus.times >= orchardcarnivalInfo.bonus.totalTimes then
        orchardcarnivalInfo.bonus.totalTimes = -1                                     -- 总次数
        orchardcarnivalInfo.bonus.times = 0                                           -- 游玩次数
        orchardcarnivalInfo.bonus.tWinScore = 0                                       -- 已经赢得的钱
        orchardcarnivalInfo.bres = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,orchardcarnivalInfo)
    return res
end

-- 预计算bonus
function AheadBonus(uid,gameType,datainfo)
    -- 增加本次Bonus预计算游玩次数
    datainfo.bonus.times = datainfo.bonus.times + 1
    -- 纯随机
    local probability = {}
    local allResult = {}
    for i, v in ipairs(OrchardCarnival['table_111_bonus_'..gameType]) do
        if v.pro > 0 then
            table.insert(probability, v.pro)
            table.insert(allResult, {v.pro, {iconId = v.id, mul = v.mul}})
        end
    end
    -- 获取随机后的结果
    local playResult = math.random(probability, allResult)[2]
    -- 保存本次随机的结果
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,playResult)
    -- 循环添加已经随机出现的结果  获取总奖励
    local tWinScore = 0
    for i, v in ipairs(datainfo.bres) do
        tWinScore = tWinScore + (v.mul * datainfo.betMoney)
    end
    local lackTimes = datainfo.bonus.totalTimes - datainfo.bonus.times
    return tWinScore,lackTimes
end