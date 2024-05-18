--水果机器模块
module('FruitMachine',package.seeall)

--水果机器免费游戏
function PlayFreeGame(fruitmachineInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    fruitmachineInfo.boards = {}
    -- 增加免费游戏次数
    fruitmachineInfo.free.times = fruitmachineInfo.free.times + 1
    -- 生成免费棋盘和结果
    local resultGame,fruitmachineInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,fruitmachineInfo,fruitmachineInfo.betMoney,GetBoards,AheadBonus)
    -- 重置Bonus次数
    fruitmachineInfo.bonus.times = 0
    fruitmachineInfo.free.tWinScore = fruitmachineInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, fruitmachineInfo, gameType, resultGame.tringerPoints, nil)
    -- 判断是否结算
    if fruitmachineInfo.free.times >= fruitmachineInfo.free.totalTimes then
        if fruitmachineInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, fruitmachineInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FRUITMACHINE)
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
        fruitmachineInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=fruitmachineInfo.free.totalTimes,lackTimes=fruitmachineInfo.free.totalTimes-fruitmachineInfo.free.times,tWinScore=fruitmachineInfo.free.tWinScore},
        {}
    )
    if fruitmachineInfo.free.times >= fruitmachineInfo.free.totalTimes then
        fruitmachineInfo.free.totalTimes = -1                                     -- 总次数
        fruitmachineInfo.free.times = 0                                           -- 游玩次数
        fruitmachineInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fruitmachineInfo)
    return res
end