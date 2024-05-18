-- 五龙争霸游戏模块
module('FiveDragons', package.seeall)

function PlayNormalGame(fivedragonsInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    fivedragonsInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[fivedragonsInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                                    -- 全部下注金额
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "五龙争霸下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    fivedragonsInfo.betMoney = payScore
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    local resultGame,fivedragonsInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,fivedragonsInfo,fivedragonsInfo.betMoney,GetBoards)

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
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.FIVEDRAGONS)
    end
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.FIVEDRAGONS)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fivedragonsInfo)
    -- 返回数据
    local res = GetResInfo(uid, fivedragonsInfo, gameType, resultGame.tringerPoints, jackpot)
    res.winScore = resultGame.winScore
    res.winPoints = resultGame.winPoints
    res.boards = {resultGame.boards}
    -- 兑换功能流水金额减少
    -- WithdrawCash.ReduceBet(uid, payScore)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fivedragonsInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end