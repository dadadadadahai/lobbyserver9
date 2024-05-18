-- 水果机器游戏模块
module('FruitMachine', package.seeall)

function PlayNormalGame(fruitmachineInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    fruitmachineInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[fruitmachineInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                                    -- 全部下注金额
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "水果机器下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    fruitmachineInfo.betMoney = payScore
    gamecommon.NameReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    local resultGame,fruitmachineInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,fruitmachineInfo,fruitmachineInfo.betMoney,GetBoards,AheadBonus)
    -- 重置Bonus次数
    fruitmachineInfo.bonus.times = 0
    -- 增加jackpot奖励
    if resultGame.jackpotResult.jackpotTringerPoints ~= {} and resultGame.jackpotResult.jackpot > 0 then
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotResult.jackpotscore,
            tringerPoints = resultGame.jackpotResult.jackpotTringerPoints,
            jackpot = resultGame.jackpotResult.jackpot
        }
        local userinfo =  unilight.getdata('userinfo',uid)
        gamecommon.AddJackpotHisory(uid, GameId, gameType, 0, jackpot.tWinScore, {pool = jackpot.jackpot})
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, jackpot.tWinScore, Const.GOODS_SOURCE_TYPE.FRUITMACHINE)
    end
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.FRUITMACHINE)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fruitmachineInfo)
    -- 返回数据
    local res = GetResInfo(uid, fruitmachineInfo, gameType, resultGame.tringerPoints, jackpot)
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
        fruitmachineInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end