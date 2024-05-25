-- 老鼠游戏模块
module('Mouse', package.seeall)

function PlayNormalGame(mouseInfo,uid,betIndex,gameType)

    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    mouseInfo.iconsAttachData = {}
    -- 保存下注档次
    mouseInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_133_hanglie[1].linenum)
    local betgold = betConfig[mouseInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_133_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 只有普通扣费 买免费触发的普通不扣费
    if mouseInfo.bonusFlag == false then
        -- 扣除金额
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "老鼠下注扣费")
        if ok == false then
            local res = {
                errno = 1,
                desc = "当前余额不足"
            }
            return res
        end
    end
    mouseInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local cimageType = nil
    if  mouseInfo.bonusFlag  then
        cimageType = 2
    end

    local resultGame,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,cimageType,Mouse,{betchip=betgold,betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    
    -- 保存棋盘数据
    mouseInfo.boards = resultGame.boards
    resultGame.winScore = realMul *payScore
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.MOUSE)
    end
        -- 整理中奖线数据
    for _, winline in ipairs(resultGame.reswinlines[1]) do
        winline[3] = winline[3] * betgold
    end
    -- 返回数据
    local res = GetResInfo(uid, mouseInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.reswinlines
    res.extraData = resultGame.extraData
    res.isfake =resultGame.isfake
    mouseInfo.bonusFlag = resultGame.extraData.bonusFlag
    -- 如果中了福牛模式
    if mouseInfo.bonusFlag then
        -- 未中奖则保存福牛模式进度
        if res.winScore > 0 then
            mouseInfo.bonusFlag = false
        end
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,mouseInfo)
    -- 增加后台历史记录

    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        mouseInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type=  'normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end

function PlayNormalGameDemo(mouseInfo,uid,betIndex,gameType)
    -- 清理棋盘附加信息
    mouseInfo.iconsAttachData = {}
    -- 保存下注档次
    mouseInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_133_hanglie[1].linenum)
    local betgold = betConfig[mouseInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_133_hanglie[1].linenum                                   -- 全部下注金额
    -- 只有普通扣费 买免费触发的普通不扣费
    if mouseInfo.bonusFlag == false then
        -- 扣除金额
        local _, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "老鼠下注扣费")
        if ok == false then
            local res = {
                errno = 1,
                desc = "当前余额不足"
            }
            return res
        end
    end
    mouseInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local cimageType = nil
    if  mouseInfo.bonusFlag  then
        cimageType = 2
    end

    local resultGame,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,cimageType,Mouse,{betchip=betgold,demo = IsDemo(uid),betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    
    -- 保存棋盘数据
    mouseInfo.boards = resultGame.boards
    resultGame.winScore = realMul *payScore
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, resultGame.winScore, Const.GOODS_SOURCE_TYPE.MOUSE)
    end
        -- 整理中奖线数据
    for _, winline in ipairs(resultGame.reswinlines[1]) do
        winline[3] = winline[3] * betgold
    end
    -- 返回数据
    local res = GetResInfo(uid, mouseInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.reswinlines
    res.extraData = resultGame.extraData
    res.isfake =resultGame.isfake
    mouseInfo.bonusFlag = resultGame.extraData.bonusFlag
    -- 如果中了福牛模式
    if mouseInfo.bonusFlag then
        -- 未中奖则保存福牛模式进度
        if res.winScore > 0 then
            mouseInfo.bonusFlag = false
        end
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,mouseInfo)
   
    return res
end