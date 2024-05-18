--渔夫模块
module('Fisherman',package.seeall)

--渔夫免费游戏
function PlayFreeGame(fishermanInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    fishermanInfo.boards = {}
    -- 增加免费游戏次数
    fishermanInfo.free.lackTimes = fishermanInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    -- 生成免费棋盘和结果
    local resultGame,fishermanInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,fishermanInfo,fishermanInfo.betMoney,GetBoards)
    fishermanInfo.free.tWinScore = fishermanInfo.free.tWinScore + resultGame.winScore
    -- 返回数据前判断是否结算  结算的时候判断收集进度
    if fishermanInfo.free.lackTimes <= 0 then
        -- 缓存以前的收集档次进度
        local oldCollectIndex = fishermanInfo.free.collect.collectIndex or 0
        -- 判断是否收集满 收集满需要增加免费次数
        for index, value in ipairs(table_126_collect) do
            -- 如果与配置表次数相同  则增加次数(次数相同代表第一次触发到这个收集进度)
            if fishermanInfo.free.collect.collectIndex < index and fishermanInfo.free.collect.collectNum >= value.collectNum then
                fishermanInfo.free.collect.collectIndex = index
            end
        end
        -- 如果收集档次有新增则增加数据
        if oldCollectIndex < fishermanInfo.free.collect.collectIndex then
            -- 收集进度每次只能上涨一个挡位
            fishermanInfo.free.collect.collectIndex = oldCollectIndex + 1
            fishermanInfo.free.totalTimes = fishermanInfo.free.totalTimes + table_126_collect[fishermanInfo.free.collect.collectIndex].freeNum
            fishermanInfo.free.lackTimes = fishermanInfo.free.lackTimes + table_126_collect[fishermanInfo.free.collect.collectIndex].freeNum
            fishermanInfo.free.collect.mul = table_126_collect[fishermanInfo.free.collect.collectIndex].mul
        end
    end
    -- 返回数据
    local res = GetResInfo(uid, fishermanInfo, gameType, resultGame.tringerPoints)
    -- 判断是否结算
    if fishermanInfo.free.lackTimes <= 0 then
        if fishermanInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, fishermanInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FISHERMAN)
        end
    end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fishermanInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=fishermanInfo.free.totalTimes,lackTimes=fishermanInfo.free.lackTimes,tWinScore=fishermanInfo.free.tWinScore},
        jackpot
    )
    if fishermanInfo.free.lackTimes <= 0 and table.empty(fishermanInfo.respin) then
        fishermanInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fishermanInfo)
    return res
end
