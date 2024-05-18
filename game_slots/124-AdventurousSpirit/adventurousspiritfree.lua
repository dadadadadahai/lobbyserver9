--冒险精神模块
module('AdventurousSpirit',package.seeall)

--冒险精神免费游戏
function PlayFreeGame(adventurousInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    adventurousInfo.boards = {}
    -- 增加免费游戏次数
    adventurousInfo.free.lackTimes = adventurousInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,adventurousInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,adventurousInfo,adventurousInfo.betMoney,GetBoards)
    adventurousInfo.free.tWinScore = adventurousInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, adventurousInfo, gameType, resultGame.tringerPoints, resultGame.freeEndFlag)
    -- 判断是否结算
    if resultGame.freeEndFlag == true or adventurousInfo.free.endPlayTime >= table_124_freeend[1].maxEndNum then
        if adventurousInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, adventurousInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ADVENTUROUSSPIRIT)
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
        adventurousInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=adventurousInfo.free.totalTimes,lackTimes=adventurousInfo.free.lackTimes,tWinScore=adventurousInfo.free.tWinScore},
        jackpot
    )
    if resultGame.freeEndFlag == true or adventurousInfo.free.endPlayTime >= table_124_freeend[1].maxEndNum then
        adventurousInfo.wildCol = nil
        adventurousInfo.wildRow = nil
        adventurousInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,adventurousInfo)
    return res
end
