--生肖龙模块
module('Dragon',package.seeall)

--生肖龙免费游戏
function PlayFreeGame(dragonInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    dragonInfo.boards = {}
    -- 增加免费游戏次数
    dragonInfo.free.lackTimes = dragonInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 获取免费预计算信息
    local freeInfo = dragonInfo.free.freeinfo[1]
    table.remove(dragonInfo.free.freeinfo,1)
    -- 整理中奖线数据
    for _, winline in ipairs(freeInfo.reswinlines[1]) do
        winline[3] = winline[3] * dragonInfo.betMoney / table_134_hanglie[1].linenum
    end
    -- 生成免费棋盘和结果
    dragonInfo.boards = freeInfo.boards
    dragonInfo.mulList = freeInfo.mulList
    dragonInfo.sumMul = freeInfo.sumMul
    local winScore = freeInfo.winMul * dragonInfo.betMoney / table_134_hanglie[1].linenum
    dragonInfo.free.tWinScore = dragonInfo.free.tWinScore + winScore
    -- 返回数据
    local res = GetResInfo(uid, dragonInfo, gameType, {})
    -- 判断是否结算
    if dragonInfo.free.lackTimes <= 0 then
        if dragonInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, dragonInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.DRAGON)
        end
    end
    res.boards = {dragonInfo.boards}
    res.winScore = winScore
    res.winlines = freeInfo.reswinlines
    res.extraData = {
        mulList = freeInfo.mulList,
        sumMul = freeInfo.sumMul,
    }
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        dragonInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = freeInfo.boards,totalTimes=dragonInfo.free.totalTimes,lackTimes=dragonInfo.free.lackTimes,tWinScore=dragonInfo.free.tWinScore},
        jackpot
    )
    if dragonInfo.free.lackTimes <= 0 then
        dragonInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,dragonInfo)
    return res
end
