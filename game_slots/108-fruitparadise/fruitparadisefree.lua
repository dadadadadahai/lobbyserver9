--水果天堂模块
module('FruitParadise',package.seeall)

--水果天堂免费游戏
function PlayFreeGame(fruitparadiseInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    fruitparadiseInfo.boards = {}
    -- 增加免费游戏次数
    fruitparadiseInfo.free.times = fruitparadiseInfo.free.times + 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,fruitparadiseInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,fruitparadiseInfo,fruitparadiseInfo.betMoney,GetBoards,Table_Base[1].linenum)
    -- 增加jackpot奖励
    if resultGame.jackpotChips ~= nil and resultGame.jackpotChips > 0 then
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #resultGame.jackpotTringerPoints[1], resultGame.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotChips,
            tringerPoints = resultGame.jackpotTringerPoints,
        }
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.FRUITPARADISE)
    end
    fruitparadiseInfo.free.tWinScore = fruitparadiseInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, fruitparadiseInfo, gameType, resultGame.freeTringerPoints, jackpot)
    -- 判断是否结算
    if fruitparadiseInfo.free.times >= fruitparadiseInfo.free.totalTimes then
        if fruitparadiseInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, fruitparadiseInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FRUITPARADISE)
        end
    end

    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fruitparadiseInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=fruitparadiseInfo.free.totalTimes,lackTimes=fruitparadiseInfo.free.totalTimes-fruitparadiseInfo.free.times,tWinScore=fruitparadiseInfo.free.tWinScore},
        jackpot
    )
    if fruitparadiseInfo.free.times >= fruitparadiseInfo.free.totalTimes then
        fruitparadiseInfo.free.totalTimes = -1                                     -- 总次数
        fruitparadiseInfo.free.times = 0                                           -- 游玩次数
        fruitparadiseInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fruitparadiseInfo)
    return res
end
