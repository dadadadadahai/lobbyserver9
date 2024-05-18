-- 金牛游戏模块
module('Leopard', package.seeall)

function PlayNormalGame(leopardInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    leopardInfo.iconsAttachData = {}
    -- 保存下注档次
    leopardInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_148_hanglie[1].linenum)
    local betgold = betConfig[leopardInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_148_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    local bonusFlag = leopardInfo.bonusFlag
    -- 只有普通扣费 买免费触发的普通不扣费
    if leopardInfo.bonusFlag == false then
        -- 扣除金额
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "金牛下注扣费")
        if ok == false then
            local res = {
                errno = 1,
                desc = "当前余额不足"
            }
            return res
        end
    end
    leopardInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,leopardInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,leopardInfo,leopardInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    leopardInfo.boards = resultGame.boards
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.GOLDCOW)
    end
    -- 返回数据
    local res = GetResInfo(uid, leopardInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.extraData = resultGame.extraData
    -- 如果中了福牛模式
    if leopardInfo.bonusFlag then
        -- 未中奖则保存福牛模式进度
        if res.winScore > 0 then
            leopardInfo.bonusFlag = false
        end
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,leopardInfo)
    -- 增加后台历史记录
    local type = 'normal'
    if bonusFlag then
        type = 'freeNormal'
    end
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        leopardInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type=type,chessdata = resultGame.boards},
        jackpot
    )
    return res
end