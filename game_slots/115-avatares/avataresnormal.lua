-- 阿凡达游戏模块
module('Avatares', package.seeall)

function PlayNormalGame(avataresInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    avataresInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum)
    local betgold = betConfig[avataresInfo.betIndex]                                               -- 单注下注金额
    local payScore = betgold * Table_Base[1].linenum                                                    -- 全部下注金额
    -- 特殊模式触发图标位置
    local tringerPoints = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "阿凡达下注扣费")
    if ok == false then
        local res = {
            error = 1,
            desc = "当前余额不足"
        }
        return res
    end
    avataresInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    local resultGame,avataresInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,avataresInfo,avataresInfo.betMoney,GetBoards)
    tringerPoints.freeTringerPoints = resultGame.freeTringerPoints

    if resultGame.winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.AVATARES)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,avataresInfo)
    -- 返回数据
    local res = GetResInfo(uid, avataresInfo, gameType, tringerPoints)
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    res.iconsAttachData = resultGame.iconsAttachData
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        avataresInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        {}
    )
    return res
end