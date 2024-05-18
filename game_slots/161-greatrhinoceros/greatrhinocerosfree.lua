--大象模块
module('GreatRhinoceros',package.seeall)

--大象免费游戏
function PlayFreeGame(GreatRhinocerosInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    GreatRhinocerosInfo.boards = {}
    -- 增加免费游戏次数
    GreatRhinocerosInfo.free.lackTimes = GreatRhinocerosInfo.free.lackTimes - 1
    -- 如果没有数据则直接返回
    if table.empty(GreatRhinocerosInfo.free.freeInfo) then
        -- 获取奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, GreatRhinocerosInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.GREATRHINOCEROS)
        GreatRhinocerosInfo.free = {}
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,GreatRhinocerosInfo)
        local res = {
            errno = 1,
        }
        return res
    end
    -- 生成免费棋盘和结果
    local freeInfo = GreatRhinocerosInfo.free.freeInfo[1]
    table.remove(GreatRhinocerosInfo.free.freeInfo,1)
    local winScore = GreatRhinocerosInfo.betgold * freeInfo.winMul * freeInfo.wMul
    GreatRhinocerosInfo.free.wildNum = freeInfo.wildNum
    GreatRhinocerosInfo.free.wMul = freeInfo.wMul
    -- 增加累计金额
    GreatRhinocerosInfo.free.tWinScore = GreatRhinocerosInfo.free.tWinScore + winScore

    -- 返回数据
    local res = GetResInfo(uid, GreatRhinocerosInfo, gameType, {})
    -- 判断是否结算
    if GreatRhinocerosInfo.free.lackTimes <= 0 then
        if GreatRhinocerosInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, GreatRhinocerosInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.GREATRHINOCEROS)
        end
    end
    res.winScore = winScore
    res.winPoints = freeInfo.winPoints
    res.boards = {freeInfo.boards}
    res.extraData = {}
    for _, value in ipairs(freeInfo.winEle) do
        value.score = value.mul * GreatRhinocerosInfo.betMoney
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
        GreatRhinocerosInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = freeInfo.boards,totalTimes=GreatRhinocerosInfo.free.totalTimes,lackTimes=GreatRhinocerosInfo.free.lackTimes,tWinScore=GreatRhinocerosInfo.free.tWinScore},
        {}
    )
    if GreatRhinocerosInfo.free.lackTimes <= 0 then
        GreatRhinocerosInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,GreatRhinocerosInfo)
    return res
end