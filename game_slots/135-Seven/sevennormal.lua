-- 777游戏模块
module('Seven', package.seeall)

function PlayNormalGame(sevenInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    sevenInfo.iconsAttachData = {}
    -- 保存下注档次
    sevenInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_135_hanglie[1].linenum)
    local betgold = betConfig[sevenInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_135_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "777下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    sevenInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,sevenInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,sevenInfo,sevenInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    sevenInfo.boards = resultGame.boards
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.SEVEN)
    end
    -- 返回数据
    local res = GetResInfo(uid, sevenInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.extraData = resultGame.extraData
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,sevenInfo)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        sevenInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end