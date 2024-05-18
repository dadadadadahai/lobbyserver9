--幸运转盘模块
module('LuckyWheel',package.seeall)

--幸运转盘免费游戏
function PlayFreeGame(luckywheelInfo,uid,gameType)
    local table_116_freespin = LuckyWheel['table_116_freespin_'..gameType]
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取本次Bonus的结果
    local resultGame
    if table.empty(luckywheelInfo.bres) then
        -- 纯随机
        resultGame = table_116_freespin[gamecommon.CommRandInt(table_116_freespin,'pro')]
    else
        resultGame = luckywheelInfo.bres[1]
        table.remove(luckywheelInfo.bres,1)
    end
    resultGame = GmProcess(uid, gameId, gameType, table_116_freespin, resultGame)
    -- 增加免费游戏次数
    luckywheelInfo.free.lackTimes = luckywheelInfo.free.lackTimes - 1
    -- 保存棋盘ID
    luckywheelInfo.boardsId = resultGame.no
    local winScore = 0
    if resultGame.type == FreeType then
        local _,_,addNum = string.find(resultGame.content, "[*](%d+)")
        luckywheelInfo.free.totalTimes = luckywheelInfo.free.totalTimes + tonumber(addNum)
        luckywheelInfo.free.lackTimes = luckywheelInfo.free.lackTimes + tonumber(addNum)
    elseif resultGame.type == AllType then
        for _, info in ipairs(table_116_freespin) do
            if info.type == GoldType then
                winScore = winScore + luckywheelInfo.betMoney * tonumber(info.content)
            elseif info.type == FreeType then
                local _,_,addNum = string.find(info.content, "[*](%d+)")
                luckywheelInfo.free.totalTimes = luckywheelInfo.free.totalTimes + tonumber(addNum)
                luckywheelInfo.free.lackTimes = luckywheelInfo.free.lackTimes + tonumber(addNum)
            end
        end
    elseif resultGame.type == GoldType then
        winScore = luckywheelInfo.betMoney * tonumber(resultGame.content)
    end
    luckywheelInfo.free.tWinScore = luckywheelInfo.free.tWinScore + winScore
    -- 返回数据
    local res = GetResInfo(uid, luckywheelInfo, gameType)
    res.winScore = winScore
    -- 判断是否结算
    if luckywheelInfo.free.lackTimes <= 0 then
        if luckywheelInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, luckywheelInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.LUCKYWHEEL)
        end
    end
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        luckywheelInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boardsId,totalTimes=luckywheelInfo.free.totalTimes,lackTimes=luckywheelInfo.free.lackTimes,tWinScore=luckywheelInfo.free.tWinScore},
        {}
    )
    if luckywheelInfo.free.lackTimes <= 0 then
        luckywheelInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,luckywheelInfo)
    return res
end

-- 预计算Free
function AheadFree(uid,gameType,datainfo)
    -- 增加本次Bonus预计算游玩次数
    datainfo.free.lackTimes = datainfo.free.lackTimes - 1
    local table_116_freespin = LuckyWheel['table_116_freespin_'..gameType]
    -- 纯随机
    local boardsInfo = table_116_freespin[gamecommon.CommRandInt(table_116_freespin,'pro')]
    -- 保存本次随机的结果
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,boardsInfo)

    -- 增加游玩次数
    if boardsInfo.type == FreeType then
        local _,_,addNum = string.find(boardsInfo.content, "[*](%d+)")
        datainfo.free.totalTimes = datainfo.free.totalTimes + tonumber(addNum)
        datainfo.free.lackTimes = datainfo.free.lackTimes + tonumber(addNum)
    elseif boardsInfo.type == AllType then
        for _, info in ipairs(table_116_freespin) do
            if info.type == GoldType then
            elseif info.type == FreeType then
                local _,_,addNum = string.find(info.content, "[*](%d+)")
                datainfo.free.totalTimes = datainfo.free.totalTimes + tonumber(addNum)
                datainfo.free.lackTimes = datainfo.free.lackTimes + tonumber(addNum)
            end
        end
    end

    -- 循环已经随机出现的结果  获取总奖励
    local tWinScore = 0
    for i, v in ipairs(datainfo.bres) do
        -- 本轮赢得的钱
        local winScore = 0
        if v.type == AllType then
            for _, info in ipairs(table_116_freespin) do
                if info.type == GoldType then
                    winScore = winScore + datainfo.betMoney * tonumber(info.content)
                end
            end
        elseif v.type == GoldType then
            winScore = datainfo.betMoney * tonumber(v.content)
        end
        tWinScore = tWinScore + winScore
    end
    local lackTimes = datainfo.free.lackTimes
    return tWinScore,lackTimes
end