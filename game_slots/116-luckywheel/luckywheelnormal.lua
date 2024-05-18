-- 幸运转盘游戏模块
module('LuckyWheel', package.seeall)

function PlayNormalGame(luckywheelInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    luckywheelInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,LineNum)
    local betgold = betConfig[luckywheelInfo.betIndex]                                              -- 单注下注金额
    local payScore = betgold * LineNum                                                              -- 全部下注金额
    -- 特殊模式触发图标位置
    local tringerPoints = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "幸运转盘下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    luckywheelInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,luckywheelInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,luckywheelInfo,luckywheelInfo.betMoney,GetBoards)
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,luckywheelInfo)
    -- 返回数据
    local res = GetResInfo(uid, luckywheelInfo, gameType, tringerPoints)
    res.winScore = resultGame.winScore
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.LUCKYWHEEL)
    end
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        luckywheelInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boardsId},
        {}
    )
    return res
end