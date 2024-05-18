-- 阿波罗游戏模块
module('Apollo', package.seeall)

function PlayNormalGame(apolloInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    apolloInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_122_hanglie[1].linenum)
    local betgold = betConfig[apolloInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * table_122_hanglie[1].linenum                                                    -- 全部下注金额
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "经典老虎机下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    apolloInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,apolloInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,apolloInfo,apolloInfo.betMoney,GetBoards)
    -- 重置Bonus次数
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

    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.APOLLO)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,apolloInfo)
    -- 返回数据
    local res = GetResInfo(uid, apolloInfo, gameType, resultGame.tringerPoints, jackpot)
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
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
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end
