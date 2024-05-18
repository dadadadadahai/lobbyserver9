--阿波罗模块
module('Apollo',package.seeall)

--果园狂欢Respin游戏
function PlayRespinGame(apolloInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取本次Respin的结果
    apolloInfo.respin = table.clone(apolloInfo.bres[1])
    table.remove(apolloInfo.bres,1)
    apolloInfo.boards = apolloInfo.respin.boards
    -- 保存棋盘附加数据
    apolloInfo.iconsAttachData = table.clone(apolloInfo.respin.iconsAttachData)
    -- 返回数据
    local res = GetResInfo(uid, apolloInfo, gameType, nil, {})
    -- 判断是否结算
    if apolloInfo.respin.lackTimes <= 0 then
        for _, v in ipairs(apolloInfo.respin.iconsAttachData) do
            apolloInfo.respin.tWinScore = apolloInfo.respin.tWinScore + v.score
        end
        res.features.respin.tWinScore = apolloInfo.respin.tWinScore
        if apolloInfo.respin.tWinScore > 0 then
            if not table.empty(apolloInfo.free) then
                apolloInfo.free.tWinScore = apolloInfo.free.tWinScore + apolloInfo.respin.tWinScore
                res.features.free.tWinScore = apolloInfo.free.tWinScore
                if apolloInfo.free.lackTimes <= 0 then
                    -- 获取奖励
                    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, apolloInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.APOLLO)
                    apolloInfo.free = {}
                end
            else
                -- 获取奖励
                BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, apolloInfo.respin.tWinScore, Const.GOODS_SOURCE_TYPE.APOLLO)
            end
        end
    end

    -- 游戏未结算金额为0
    res.winScore = 0

    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        apolloInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='respin',iconsAttachData = apolloInfo.respin.iconsAttachData,totalTimes=apolloInfo.respin.totalTimes,lackTimes=apolloInfo.respin.lackTimes,tWinScore=apolloInfo.respin.tWinScore},
        {}
    )
    if apolloInfo.respin.lackTimes <= 0 then
        apolloInfo.respin = {}
        apolloInfo.bres = {}
        apolloInfo.iconsAttachData={}
    end
    res.boards = {apolloInfo.boards}
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,apolloInfo)
    return res
end
-- 预计算respin
function AheadRespin(uid,gameType,datainfo)
    -- 增加本次Respin预计算游玩次数
    datainfo.respin.lackTimes = datainfo.respin.lackTimes - 1
    -- 剩余Respin图标个数
    local residueNum = datainfo.respin.finallyNum - #datainfo.respin.iconsAttachData
    -- 本轮开始前U图标数量
    local curnum = 0
    local emptyPos = {}
    -- 生成虚拟棋盘
    for col = 1, #datainfo.respin.boards do
        for row = 1, #datainfo.respin.boards[col] do
            if datainfo.respin.boards[col][row] == U then
                curnum = curnum + 1
            else
                datainfo.respin.boards[col][row] = RespinBoards[math.random(#RespinBoards)]
                table.insert(emptyPos, { col, row })
            end
        end
    end

    -- 根据概率判断本轮是否增加图标
    local addPro = 0
    if datainfo.respin.lackTimes > 0 then
        addPro = (residueNum / datainfo.respin.lackTimes) * 100
    end
    if math.random(100) <= addPro then
        -- 本次添加Respin图标个数
        local realnum = math.floor(residueNum / datainfo.respin.lackTimes)
        if realnum <= 0 then
            realnum = 1
        end
        datainfo.respin.lackTimes = datainfo.respin.totalTimes
        -- 插入Respin图标
        for i = 1, realnum do
            local curPos = gamecommon.ReturnArrayRand(emptyPos)
            datainfo.respin.boards[curPos[1]][curPos[2]] = U
            local mul = table_122_umul[gamecommon.CommRandInt(table_122_umul, 'pro')].mul
            table.insert(datainfo.respin.iconsAttachData,{line = curPos[1], row = curPos[2],score = mul * datainfo.betMoney})
        end
    end

    -- 保存本次随机的结果
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,table.clone(datainfo.respin))

    -- 获取总奖励
    local tWinScore = 0
    for i, v in ipairs(datainfo.respin.iconsAttachData) do
        tWinScore = tWinScore + v.score
    end
    return tWinScore,datainfo.respin.lackTimes
end