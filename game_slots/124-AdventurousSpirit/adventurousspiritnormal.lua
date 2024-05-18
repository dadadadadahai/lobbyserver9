-- 冒险精神游戏模块
module('AdventurousSpirit', package.seeall)

function PlayNormalGame(adventurousInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    adventurousInfo.iconsAttachData = {}
    -- 保存下注档次
    adventurousInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_124_hanglie[1].linenum)
    local betgold = betConfig[adventurousInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_124_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "冒险精神下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    adventurousInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,adventurousInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,adventurousInfo,adventurousInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    adventurousInfo.boards = resultGame.boards
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.ADVENTUROUSSPIRIT)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,adventurousInfo)
    -- 返回数据
    local res = GetResInfo(uid, adventurousInfo, gameType, resultGame.tringerPoints)
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
        adventurousInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end