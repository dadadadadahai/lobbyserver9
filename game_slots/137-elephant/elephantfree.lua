--大象模块
module('Elephant',package.seeall)

--大象免费游戏
function PlayFreeGame(elephantInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    elephantInfo.boards = {}
    -- 增加免费游戏次数
    elephantInfo.free.lackTimes = elephantInfo.free.lackTimes - 1
    -- 如果没有数据则直接返回
    if table.empty(elephantInfo.free.freeInfo) then
        -- 获取奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, elephantInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ELEPHANT)
        elephantInfo.free = {}
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,elephantInfo)
        local res = {
            errno = 1,
        }
        return res
    end
    -- 生成免费棋盘和结果
    local freeInfo = elephantInfo.free.freeInfo[1]
    table.remove(elephantInfo.free.freeInfo,1)
    local winScore = elephantInfo.gold * freeInfo.winMul * freeInfo.wMul
    elephantInfo.free.wildNum = freeInfo.wildNum
    elephantInfo.free.wMul = freeInfo.wMul
    -- 增加累计金额
    elephantInfo.free.tWinScore = elephantInfo.free.tWinScore + winScore

    -- 返回数据
    local res = GetResInfo(uid, elephantInfo, gameType, {})
    -- 判断是否结算
    if elephantInfo.free.lackTimes <= 0 then
        if elephantInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, elephantInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.ELEPHANT)
        end
    end
    res.winScore = winScore
    res.winPoints = freeInfo.winPoints
    res.boards = {freeInfo.boards}
    res.extraData = {}
    for _, value in ipairs(freeInfo.winEle) do
        value.score = value.mul * elephantInfo.betMoney
        value.mul = nil
    end
    res.extraData.winEle = freeInfo.winEle
    res.extraData.wMul = freeInfo.wMul
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        0,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = freeInfo.boards,totalTimes=elephantInfo.free.totalTimes,lackTimes=elephantInfo.free.lackTimes,tWinScore=elephantInfo.free.tWinScore},
        {}
    )
    if elephantInfo.free.lackTimes <= 0 then
        elephantInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,elephantInfo)
    return res
end
