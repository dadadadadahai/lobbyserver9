-- 火焰连击游戏模块
module('FireCombo', package.seeall)

function PlayNormalGame(firecomboInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    firecomboInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[firecomboInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                                    -- 全部下注金额
    -- 特殊模式触发图标位置
    -- -- jackpot发送客户端的数据表
    -- local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "火焰连击下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    firecomboInfo.betMoney = payScore
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    local resultGame,firecomboInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,firecomboInfo,firecomboInfo.betMoney,GetBoards)
    if table.empty(resultGame.collect) == false and resultGame.collect.tWinScore > 0 then
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.collect.tWinScore, Const.GOODS_SOURCE_TYPE.FIRECOMBO)
    end
    local jackpot = {}
    -- 如果触发Jackpot
    if resultGame.jackpotChips > 0 then
        -- gamecommon.AddJackpotHisory(uid, GameId, gameType, #resultGame.bowTringerPoints, resultGame.jackpotChips + resultGame.collect.tWinScore)
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #resultGame.bowTringerPoints, resultGame.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotChips,
            tringerPoints = resultGame.jackpotTringerPoints,
        }
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.FIRECOMBO)
        -- gamecommon.ReducePoolChips(GameId,gameType,resultGame.jackpotChips + resultGame.collect.tWinScore)
    end

    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.FIRECOMBO)
    end
    -- 保存数据库信息
    firecomboInfo.collect = nil
    SaveGameInfo(uid,gameType,firecomboInfo)
    -- 返回数据
    local res = GetResInfo(uid, firecomboInfo, gameType, resultGame.tringerPoints, jackpot, resultGame.collect)
    -- 缓存Collect的金额
    -- if table.empty(resultGame.collect) == false then
    --     res.winScore = resultGame.winScore - resultGame.collect.tWinScore
    -- else
    --     res.winScore = resultGame.winScore
    -- end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    -- 兑换功能流水金额减少
    -- WithdrawCash.ReduceBet(uid, payScore)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        firecomboInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        {}
    )
    return res
end