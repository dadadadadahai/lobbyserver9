-- 足球游戏模块
module('Football', package.seeall)

function PlayNormalGame(footballInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    footballInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[footballInfo.betIndex]                                              -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                           -- 全部下注金额
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "足球下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    gamecommon.ReqGamePoolBet(GameId, gameType, payScore)
    footballInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,footballInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,footballInfo,footballInfo.betMoney,GetBoards)

    -- 下发游戏奖励
    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.FOOTBALL)
    end

    -- 如果中了jackpot
    if resultGame.jackpotChips ~= nil and resultGame.jackpotChips > 0 then
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #resultGame.jackpotTringerPoints[1], resultGame.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = resultGame.jackpotChips,
            tringerPoints = resultGame.jackpotTringerPoints,
        }
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.jackpotChips, Const.GOODS_SOURCE_TYPE.FOOTBALL)
    end

    -- 保存数据库信息
    SaveGameInfo(uid,gameType,footballInfo)
    -- 返回数据
    local res = GetResInfo(uid, footballInfo, gameType, jackpot)
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    -- res.iconsAttachData = {footballInfo.iconsAttachData}
    -- 兑换功能流水金额减少
    -- WithdrawCash.ReduceBet(uid, payScore)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        footballInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end

-- 判断奖励倍数
function GetRewardMul(iconsAttachData)
    local wNum = #iconsAttachData
    local mul = 1
    for i, v in ipairs(Table_MulW) do
        if wNum < v.wNum then
            break
        else
            mul = v.mul
        end
    end
    return mul
end