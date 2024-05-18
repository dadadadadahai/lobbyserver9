--果园狂欢模块
module('Apollo',package.seeall)

--果园狂欢免费游戏
function PlayFreeGame(apolloInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    apolloInfo.boards = {}
    -- 增加免费游戏次数
    apolloInfo.free.lackTimes = apolloInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,apolloInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,apolloInfo,apolloInfo.betMoney,GetBoards)
    -- 重置Respin次数
    if not table.empty(apolloInfo.respin) then
        apolloInfo.respin.lackTimes = apolloInfo.respin.totalTimes
    end
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
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.APOLLO)
    end
    apolloInfo.free.tWinScore = apolloInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, apolloInfo, gameType, resultGame.tringerPoints, jackpot)
    -- 判断是否结算
    if apolloInfo.free.lackTimes <= 0 and table.empty(apolloInfo.respin) then
        if apolloInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, apolloInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.APOLLO)
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
        apolloInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=apolloInfo.free.totalTimes,lackTimes=apolloInfo.free.lackTimes,tWinScore=apolloInfo.free.tWinScore},
        jackpot
    )
    if apolloInfo.free.lackTimes <= 0 and table.empty(apolloInfo.respin) then
        apolloInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,apolloInfo)
    return res
end
