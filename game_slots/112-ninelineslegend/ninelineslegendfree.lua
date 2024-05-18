--九线传奇模块
module('NineLinesLegend',package.seeall)

--九线传奇免费游戏
function PlayFreeGame(ninelineslegendInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    ninelineslegendInfo.boards = {}
    -- 增加免费游戏次数
    ninelineslegendInfo.free.times = ninelineslegendInfo.free.times + 1
    -- 中奖金额
    local winScoreList = {}
    -- 生成免费棋盘和结果
    local resultGame,ninelineslegendInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,ninelineslegendInfo,ninelineslegendInfo.betMoney,GetBoards,AheadBonus)
    -- 重置Bonus次数
    ninelineslegendInfo.bonus.times = 0
    ninelineslegendInfo.free.tWinScore = ninelineslegendInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, ninelineslegendInfo, gameType, resultGame.tringerPoints, nil, resultGame.collect)
    -- 判断是否结算
    if ninelineslegendInfo.free.times >= ninelineslegendInfo.free.totalTimes then
        if ninelineslegendInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, ninelineslegendInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.NINELINESLEGEND)
        end
    end
    -- 缓存Collect的金额
    -- if table.empty(resultGame.collect) == false then
    --     res.winScore = resultGame.winScore - resultGame.collect.tWinScore
    -- else
    --     res.winScore = resultGame.winScore
    -- end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
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
        {type='free',chessdata = resultGame.boards,totalTimes=ninelineslegendInfo.free.totalTimes,lackTimes=ninelineslegendInfo.free.totalTimes-ninelineslegendInfo.free.times,tWinScore=ninelineslegendInfo.free.tWinScore},
        {}
    )
    if ninelineslegendInfo.free.times >= ninelineslegendInfo.free.totalTimes then
        ninelineslegendInfo.free.totalTimes = -1                                     -- 总次数
        ninelineslegendInfo.free.times = 0                                           -- 游玩次数
        ninelineslegendInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    ninelineslegendInfo.collect = nil
    SaveGameInfo(uid,gameType,ninelineslegendInfo)
    return res
end
