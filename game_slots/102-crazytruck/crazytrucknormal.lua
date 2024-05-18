-- 卡车游戏模块
module('CrazyTruck', package.seeall)

function PlayNormalGame(crazytruckInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 玩家等级
    -- local level = userInfo.property.level or 1
    crazytruckInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[crazytruckInfo.betIndex]                                              -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                           -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "卡车下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    crazytruckInfo.betMoney = payScore
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    -- local resultGame = GetBoards(uid, crazytruckInfo,false,GameId, gameType)
    local resultGame,crazytruckInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,crazytruckInfo,crazytruckInfo.betMoney,GetBoards)
    -- 如果中奖
    local bSucess = false
    if table.empty(resultGame.jackpotTringerPoints) == false then
        bSucess = true
    end
    crazytruckInfo.boards = resultGame.boards
    -- 增加jackpot奖励
    if resultGame.jackpotTringerPoints ~= nil and resultGame.jackpotChips > 0 then
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #resultGame.jackpotTringerPoints[1], resultGame.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotChips,
            tringerPoints = resultGame.jackpotTringerPoints,
        }
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.CRAZYTRUCK)
    end
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.CRAZYTRUCK)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,crazytruckInfo)
    -- 返回数据
    local res = GetResInfo(uid, crazytruckInfo, gameType, resultGame.tringerPoints, jackpot, resultGame.points)
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
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end