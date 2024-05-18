--糖果连连碰模块
module('CandyTouch',package.seeall)

--糖果连连碰免费游戏
function PlayFreeGame(candytouchInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    candytouchInfo.boards = {}
    -- 增加免费游戏次数
    candytouchInfo.free.lackTimes = candytouchInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,candytouchInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,candytouchInfo,candytouchInfo.betMoney,GetBoards)
    candytouchInfo.free.tWinScore = candytouchInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, candytouchInfo, gameType, resultGame.tringerPoints)
    -- 判断是否结算
    if candytouchInfo.free.lackTimes <= 0 then
        if candytouchInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, candytouchInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ADVENTUROUSSPIRIT)
        end
    end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    res.extraData = {
        disInfo = resultGame.disInfo,
        doubleMaps = candytouchInfo.doubleMaps
    }
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        candytouchInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=candytouchInfo.free.totalTimes,lackTimes=candytouchInfo.free.lackTimes,tWinScore=candytouchInfo.free.tWinScore},
        jackpot
    )
    if candytouchInfo.free.lackTimes <= 0 then
        candytouchInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,candytouchInfo)
    return res
end
