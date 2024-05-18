--兔子模块
module('NewRabbit',package.seeall)

--兔子免费游戏
function PlayFreeGame(rabbitInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    rabbitInfo.boards = {}
    -- 增加免费游戏次数
    rabbitInfo.free.lackTimes = rabbitInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,rabbitInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,rabbitInfo,rabbitInfo.betMoney,GetBoards)
    rabbitInfo.free.tWinScore = rabbitInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, rabbitInfo, gameType, resultGame.tringerPoints, resultGame.freeEndFlag)
    -- 判断是否结算
    if rabbitInfo.free.lackTimes <= 0 then
        if rabbitInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, rabbitInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.RABBIT)
        end
    end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    res.extraData = resultGame.extraData
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        rabbitInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=rabbitInfo.free.totalTimes,lackTimes=rabbitInfo.free.lackTimes,tWinScore=rabbitInfo.free.tWinScore},
        jackpot
    )
    if rabbitInfo.free.lackTimes <= 0 then
        rabbitInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,rabbitInfo)
    return res
end
