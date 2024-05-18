-- 卡车游戏模块
module('CrazyTruck', package.seeall)

function PlayFreeGame(crazytruckInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)

    -- 增加免费游戏次数
    crazytruckInfo.free.times = crazytruckInfo.free.times + 1
    -- 生成普通棋盘和结果
    local resultGame,crazytruckInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,crazytruckInfo,crazytruckInfo.betMoney,GetBoards)
    crazytruckInfo.free.tWinScore = crazytruckInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, crazytruckInfo, gameType, nil, nil, resultGame.points)
    -- 判断是否结算
    if crazytruckInfo.free.times >= crazytruckInfo.free.totalTimes then
        if crazytruckInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, crazytruckInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.CRAZYTRUCK)
        end
    end
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        crazytruckInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=crazytruckInfo.free.totalTimes,lackTimes=crazytruckInfo.free.totalTimes-crazytruckInfo.free.times,tWinScore=crazytruckInfo.free.tWinScore},
        {}
    )
    if crazytruckInfo.free.times >= crazytruckInfo.free.totalTimes then
        crazytruckInfo.free.totalTimes = -1                                     -- 总次数
        crazytruckInfo.free.times = 0                                           -- 游玩次数
        crazytruckInfo.free.tWinScore = 0                                       -- 本轮已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,crazytruckInfo)
    return res
end