-- 九线传奇游戏模块
module('NineLinesLegend', package.seeall)

function PlayNormalGame(ninelineslegendInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    ninelineslegendInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[ninelineslegendInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                                    -- 全部下注金额
    -- 特殊模式触发图标位置
    -- -- jackpot发送客户端的数据表
    -- local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "九线传奇下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    ninelineslegendInfo.betMoney = payScore
    gamecommon.NameReqGamePoolBet(GameId, gameType, payScore)
    -- 生成普通棋盘和结果
    local resultGame,ninelineslegendInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,ninelineslegendInfo,ninelineslegendInfo.betMoney,GetBoards,AheadBonus)
    -- 重置Bonus次数
    ninelineslegendInfo.bonus.times = 0
    if table.empty(resultGame.collect) == false and resultGame.collect.tWinScore > 0 then
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.collect.tWinScore, Const.GOODS_SOURCE_TYPE.NINELINESLEGEND)
    end


    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.NINELINESLEGEND)
    end
    -- 保存数据库信息
    ninelineslegendInfo.collect = nil
    SaveGameInfo(uid,gameType,ninelineslegendInfo)
    -- 返回数据
    local res = GetResInfo(uid, ninelineslegendInfo, gameType, resultGame.tringerPoints, nil, resultGame.collect)
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
        ninelineslegendInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        {}
    )
    return res
end