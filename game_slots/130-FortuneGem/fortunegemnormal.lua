-- 财富宝石游戏模块
module('FortuneGem', package.seeall)

function PlayNormalGame(fortunegemInfo,uid,betIndex,gameType,isAdditional)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    fortunegemInfo.iconsAttachData = {}
    -- 保存下注档次
    fortunegemInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_130_hanglie[1].linenum)
    local betgold = betConfig[fortunegemInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_130_hanglie[1].linenum                                   -- 全部下注金额
    local payMul = 1
    if isAdditional then
        payMul = 1.5
    end

    local jackpot = {}

    -- 只有普通扣费 买免费触发的普通不扣费
    if fortunegemInfo.BuyFreeNumS == 0 then
        -- 扣除金额
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, math.ceil(payScore * payMul), "财富宝石下注扣费")
        if ok == false then
            local res = {
                errno = 1,
                desc = "当前余额不足"
            }
            return res
        end
    end
    fortunegemInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,fortunegemInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,isAdditional,fortunegemInfo,fortunegemInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    fortunegemInfo.boards = resultGame.boards
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.FORTUNEGEM)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fortunegemInfo)
    -- 返回数据
    local res = GetResInfo(uid, fortunegemInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.wildCol = resultGame.wildCol
    res.wildRow = resultGame.wildRow
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fortunegemInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end