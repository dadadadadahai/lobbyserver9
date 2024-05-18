-- 糖果连连碰游戏模块
module('CandyTouch', package.seeall)

function PlayNormalGame(candytouchInfo,uid,betIndex,gameType,isBuyFree)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    candytouchInfo.iconsAttachData = {}
    -- 保存下注档次
    candytouchInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_129_hanglie[1].linenum)
    local betgold = betConfig[candytouchInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_129_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    if isBuyFree then
        -- 随机购买配置表档次
        local buyFreeInfo = table_129_freenum[gamecommon.CommRandInt(table_129_freenum, 'pro')]
        -- 购买金额为下注金额一百倍
        payScore = payScore * buyFreeInfo.buyMul
        -- 设置购买免费的图标个数
        candytouchInfo.BuyFreeNumS = buyFreeInfo.sNum
    end

    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "糖果连连碰下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    candytouchInfo.betMoney = betgold * table_129_hanglie[1].linenum
    -- 生成普通棋盘和结果
    local resultGame,candytouchInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,candytouchInfo,candytouchInfo.betMoney,GetBoards)
    -- 保存棋盘数据
    candytouchInfo.boards = resultGame.boards
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.ADVENTUROUSSPIRIT)
    end

    -- 返回数据
    local res = GetResInfo(uid, candytouchInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.extraData = {
        disInfo = resultGame.disInfo,
        doubleMaps = table.clone(candytouchInfo.doubleMaps)
    }
    candytouchInfo.doubleMaps = {}
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,candytouchInfo)
    -- res.lastInfo = resultGame.lastInfo
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        candytouchInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end