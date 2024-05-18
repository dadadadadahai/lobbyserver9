-- 幸运七游戏模块
module('LuckySeven', package.seeall)

function PlayNormalGame(luckysevenInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 保存下注档次
    luckysevenInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_119_hanglie[1].linenum)
    local betgold = betConfig[luckysevenInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_119_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "幸运七下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    luckysevenInfo.betMoney = payScore
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    local resultGame,luckysevenInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,luckysevenInfo,luckysevenInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    luckysevenInfo.boards = resultGame.boards
    -- 增加jackpot奖励
    if resultGame.jackpotChips > 0 then
        -- gamecommon.AddJackpotHisory(uid, GameId, gameType, #DataFormat, resultGame.jackpotChips + resultGame.winScore)
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #DataFormat, resultGame.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotChips,
            -- tringerPoints = resultGame.jackpotTringerPoints,
        }
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.LUCKYSEVEN)
        -- 只有一条线 奖池扣除除了爆池百分比的还需要扣除棋盘倍数的
        -- gamecommon.ReducePoolChips(GameId,gameType,resultGame.jackpotChips + resultGame.winScore)
    end
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.LUCKYSEVEN)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,luckysevenInfo)
    -- 返回数据
    local res = GetResInfo(uid, luckysevenInfo, gameType, jackpot)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        luckysevenInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end