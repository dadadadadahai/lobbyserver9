--777模块
module('Seven',package.seeall)

--777免费游戏
function PlayFreeGame(sevenInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    sevenInfo.boards = {}
    -- 增加免费游戏次数
    sevenInfo.free.lackTimes = sevenInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,sevenInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,sevenInfo,sevenInfo.betMoney,GetBoards)
    sevenInfo.free.tWinScore = sevenInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, sevenInfo, gameType, resultGame.tringerPoints)
    -- 判断是否结算
    if sevenInfo.free.lackTimes <= 0 then
        if sevenInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, sevenInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.SEVEN)
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
        sevenInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=sevenInfo.free.totalTimes,lackTimes=sevenInfo.free.lackTimes,tWinScore=sevenInfo.free.tWinScore},
        jackpot
    )
    if sevenInfo.free.lackTimes <= 0 then
        sevenInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,sevenInfo)
    return res
end
