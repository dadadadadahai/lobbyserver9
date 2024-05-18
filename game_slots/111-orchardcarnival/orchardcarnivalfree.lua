--果园狂欢模块
module('OrchardCarnival',package.seeall)

--果园狂欢免费游戏
function PlayFreeGame(orchardcarnivalInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    orchardcarnivalInfo.boards = {}
    -- 增加免费游戏次数
    orchardcarnivalInfo.free.times = orchardcarnivalInfo.free.times + 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,orchardcarnivalInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,orchardcarnivalInfo,orchardcarnivalInfo.betMoney,GetBoards,AheadBonus)
    -- 重置Bonus次数
    orchardcarnivalInfo.bonus.times = 0
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
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.ORCHARDCARNIVAL)
    end
    orchardcarnivalInfo.free.tWinScore = orchardcarnivalInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, orchardcarnivalInfo, gameType, resultGame.tringerPoints, jackpot)
    -- 判断是否结算
    if orchardcarnivalInfo.free.times >= orchardcarnivalInfo.free.totalTimes and table.empty(resultGame.tringerPoints.bonusTringerPoints) then
        if orchardcarnivalInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, orchardcarnivalInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ORCHARDCARNIVAL)
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
        orchardcarnivalInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=orchardcarnivalInfo.free.totalTimes,lackTimes=orchardcarnivalInfo.free.totalTimes-orchardcarnivalInfo.free.times,tWinScore=orchardcarnivalInfo.free.tWinScore},
        jackpot
    )
    if orchardcarnivalInfo.free.times >= orchardcarnivalInfo.free.totalTimes and table.empty(resultGame.tringerPoints.bonusTringerPoints) then
        orchardcarnivalInfo.free.totalTimes = -1                                     -- 总次数
        orchardcarnivalInfo.free.times = 0                                           -- 游玩次数
        orchardcarnivalInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,orchardcarnivalInfo)
    return res
end
