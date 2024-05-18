--五龙争霸模块
module('FiveDragons',package.seeall)

--五龙争霸免费游戏
function PlayFreeGame(fivedragonsInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    fivedragonsInfo.boards = {}
    -- 增加免费游戏次数
    fivedragonsInfo.free.times = fivedragonsInfo.free.times + 1
    -- 免费高额迭代获取结果
    local fivedragonsInfo,resultGame,winScore,winPoints,tringerPoints = RefreshBoards(uid,fivedragonsInfo,gameType)
    -- 缓存winScore加入bonus的金币
    if table.empty(resultGame.bonus) == false and resultGame.bonus.tWinScore > 0 then
        winScore = winScore - resultGame.bonus.tWinScore
    end
    fivedragonsInfo.free.tWinScore = fivedragonsInfo.free.tWinScore + winScore
    if not table.empty(resultGame.bonus) then
        fivedragonsInfo.free.tWinScore = fivedragonsInfo.free.tWinScore + resultGame.bonus.tWinScore
    end
    -- 返回数据
    local res = GetResInfo(uid, fivedragonsInfo, gameType, tringerPoints, nil)
    -- 判断是否结算
    if fivedragonsInfo.free.times >= fivedragonsInfo.free.totalTimes then
        if fivedragonsInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, fivedragonsInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FIVEDRAGONS)
        end
    end
    res.winScore = winScore
    res.winPoints = winPoints
    res.features.bonus = resultGame.bonus
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fivedragonsInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=fivedragonsInfo.free.totalTimes,lackTimes=fivedragonsInfo.free.totalTimes-fivedragonsInfo.free.times,tWinScore=fivedragonsInfo.free.tWinScore},
        {}
    )
    if fivedragonsInfo.free.times >= fivedragonsInfo.free.totalTimes then
        fivedragonsInfo.free.totalTimes = -1                                     -- 总次数
        fivedragonsInfo.free.times = 0                                           -- 游玩次数
        fivedragonsInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fivedragonsInfo)
    return res
end


-- 选择免费次数界面返回
function ChooseFreeGame(fivedragonsInfo,uid,gameType,choose)
    if choose <=0 or choose > #Table_FreeChoose then
        return
    end
    fivedragonsInfo.free.choose = choose
    for _, v in ipairs(Table_FreeChoose) do
        if v.FreeCode == "W"..choose then
            -- print(v.FreeCode)
            -- print(v.FreeNum)
            fivedragonsInfo.free.totalTimes = v.FreeNum
            break
        end
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fivedragonsInfo)
    -- 返回数据
    local res = GetResInfo(uid, fivedragonsInfo, gameType, nil, nil)
    return res
end

-- 针对免费的高额倍数迭代
function RefreshBoards(uid,fivedragonsInfo,gameType)
    local whileNum = 0
    local maxWhileNum = 10
    -- 循环调用
    while true do
        whileNum = whileNum + 1
        local cloneInfo = table.clone(fivedragonsInfo)
        -- 生成免费棋盘和结果
        local resultGame,cloneInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,cloneInfo,cloneInfo.betMoney,GetBoards)
        -- 如果倍数小于100倍 返回结果
        if resultGame.winScore / cloneInfo.betMoney < (require 'table/table_parameter_parameter')[19+(gameType-1)].Parameter then
            return cloneInfo,resultGame,resultGame.winScore,resultGame.winPoints,resultGame.tringerPoints
        end
        if whileNum >= maxWhileNum then
            return cloneInfo,resultGame,resultGame.winScore,resultGame.winPoints,resultGame.tringerPoints
        end
    end
end