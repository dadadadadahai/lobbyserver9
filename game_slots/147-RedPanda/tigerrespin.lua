-- 老虎游戏模块
module('RedPanda', package.seeall)
--老虎Respin游戏
function PlayRespinGame(redpandaInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 获取本次Respin的结果
    redpandaInfo.respin = table.clone(redpandaInfo.bres[1])
    table.remove(redpandaInfo.bres,1)
    redpandaInfo.boards = redpandaInfo.respin.boards

    -- 生成中奖线
    local winlines = {}
    winlines[1] = {}
    redpandaInfo.winlines = redpandaInfo.respin.winlines or winlines

    -- 返回数据
    local res = GetResInfo(uid, redpandaInfo, gameType, nil, {})
    -- 判断是否结算
    if redpandaInfo.respin.lackTimes <= 0 then
        res.features.respin.tWinScore = redpandaInfo.respin.tWinScore or 0
        if redpandaInfo.respin.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, redpandaInfo.respin.tWinScore, Const.GOODS_SOURCE_TYPE.TIGER)
        end
    end

    -- 游戏未结算金额为0
    res.winScore = 0
    res.winlines = redpandaInfo.winlines
    -- respin模式固定发false
    -- res.bigWinIcon = bigWinIcon
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        redpandaInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='respin',chessdata = redpandaInfo.respin.boards,totalTimes=redpandaInfo.respin.totalTimes,lackTimes=redpandaInfo.respin.lackTimes,tWinScore=redpandaInfo.respin.tWinScore},
        {}
    )
    if redpandaInfo.respin.lackTimes <= 0 then
        redpandaInfo.respin = {}
        redpandaInfo.bres = {}
    end
    res.boards = {redpandaInfo.boards}
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,redpandaInfo)
    return res
end

-- 计算respin最终棋盘
function RespinFinalBoards(redpandaInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    local boards = {}
    local respinIconId = table_147_respinicon[gamecommon.CommRandInt(table_147_respinicon, 'pro')].iconId
    -- 空白图标判断
    local blankIconFlag = false
    local respinMul = 1
    local bigWinIcon = -1
    
    for col = 1,#DataFormat do
        if boards[col] == nil then
            boards[col] = {}
        end
        for row = 1,DataFormat[col] do
            local iconId = table_147_respin[gamecommon.CommRandInt(table_147_respin, 'pro')].result

            if GmProcess().free == true then
                iconId = 2
            end
            if respinIconId > 4 then
                if iconId == 1 then
                    boards[col][row] = 0
                    blankIconFlag = true
                elseif iconId == 2 then
                    boards[col][row] = respinIconId
                elseif iconId == 3 then
                    boards[col][row] = W
                end
            else
                boards[col][row] = respinIconId
            end
        end
    end
    -- 获取中奖线
    local reswinlines = {}
    reswinlines[1] = {}


    if respinIconId <= 4 then
        local wildNum = math.random(0,3)
        local wildPoint = chessutil.NotRepeatRandomNumbers(1, 6, wildNum)
        table.sort(wildPoint)
        local insertPoint = 1
        for col = 2, 3 do
            for row = 1,DataFormat[col] do
                if insertPoint == wildPoint then
                    boards[col][row] = W
                end
                insertPoint = insertPoint + 1
            end
        end
    end


    -- 中奖金额
    local winScore = 0
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_147_payline,table_147_paytable,wilds,nowild)
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * redpandaInfo.betMoney / table_147_hanglie[1].linenum
        winScore = winScore + addScore
        table.insert(reswinlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 如果填满则奖励*10
    if IsAllWinPoints(reswinlines[1]) then
        respinMul = 10
        winScore = winScore * respinMul
        bigWinIcon = respinIconId
    end

    local res = {
        respinIconId = respinIconId,
        boards = boards,
        winScore = winScore,
        winlines = reswinlines,
        respinMul = respinMul,
        bigWinIcon = bigWinIcon,
    }
    return res
end

-- 预计算respin
function AheadRespin(datainfo,respinFinalResult)
    local finalBoards = respinFinalResult.boards
    local respinMul = respinFinalResult.respinMul
    local respinIconId = respinFinalResult.respinIconId
    local bigWinIcon = respinFinalResult.bigWinIcon
    local tWinScore = respinFinalResult.winScore
    local winlines = respinFinalResult.winlines

    local maxChangeNum = 0
    local changeBoardsPoints = {}
    for col = 1,#DataFormat do
        if changeBoardsPoints[col] == nil then
            changeBoardsPoints[col] = {}
        end
        for row = 1,DataFormat[col] do
            changeBoardsPoints[col][row] = 0
            if finalBoards[col][row] ~= 0 then
                maxChangeNum = maxChangeNum + 1
            end
        end
    end
    local respin = {}
    respin.totalTimes = 0
    respin.times = 0
    -- 剩余可修改个数
    local changeNum = 0
    while true do
        respin.totalTimes = respin.totalTimes + 1
        respin.times = respin.times + 1
        respin.respinMul = respinMul
        respin.tWinScore = 0
        respin.respinIconId = respinIconId
        respin.bigWinIcon = bigWinIcon
        respin.boards = {}
        
        -- 本轮是否有修改
        local changeFlag = false
        for col = 1,#DataFormat do
            if respin.boards[col] == nil then
                respin.boards[col] = {}
            end
            for row = 1,DataFormat[col] do

                -- 最终棋盘有数据才进行下一步逻辑
                if finalBoards[col][row] ~= 0 then
                    -- 如果不是第一个未修改的 则判断是否这一个图标本轮需要添加
                    if changeFlag == true and changeBoardsPoints[col][row] == 0 then
                        if math.random(10000) <= 5000 then
                            -- 减少可插入位置个数
                            changeNum = changeNum + 1
                            -- 添加修改状态
                            changeBoardsPoints[col][row] = 1
                            -- 添加棋盘状态
                            respin.boards[col][row] = finalBoards[col][row]
                        else
                            respin.boards[col][row] = 0
                        end
                    else
                        -- 如果未修改 则判断状态是需要修改的
                        if changeBoardsPoints[col][row] == 0 then
                            -- 减少可插入位置个数
                            changeNum = changeNum + 1
                            changeFlag = true
                        end
                        -- 添加修改状态
                        changeBoardsPoints[col][row] = 1
                        -- 添加棋盘状态
                        respin.boards[col][row] = finalBoards[col][row]
                    end
                else
                    -- 添加修改状态
                    changeBoardsPoints[col][row] = 1
                    -- 添加棋盘状态
                    respin.boards[col][row] = finalBoards[col][row]
                end
            end
        end
        -- 保存本次随机的结果
        datainfo.bres = datainfo.bres or {}


        -- 生成过程中奖线
        local reswinlines = {}
        reswinlines[1] = {}
        -- 获取W元素
        local wilds = {}
        wilds[W] = 1
        local nowild = {}
        -- 计算中奖倍数
        local courseWinLines = gamecommon.WiningLineFinalCalc(respin.boards,table_147_payline,table_147_paytable,wilds,nowild)
        -- 计算中奖线金额
        for k, v in ipairs(courseWinLines) do
            local addScore = v.mul * datainfo.betMoney / table_147_hanglie[1].linenum
            table.insert(reswinlines[1], {v.line, v.num, addScore,v.ele})
        end

        respin.winlines = reswinlines

        if not changeFlag then
            respin.tWinScore = tWinScore
            -- respin.winlines = winlines
            table.insert(datainfo.bres,table.clone(respin))
            for _, respinInfo in ipairs(datainfo.bres) do
                -- 修改总次数
                respinInfo.totalTimes = respin.totalTimes
                respinInfo.lackTimes = respin.totalTimes - respinInfo.times
            end
            break
        end
        -- 最后一轮添加总金额
        if changeNum == maxChangeNum and maxChangeNum == 9 then
            respin.tWinScore = tWinScore
            respin.winlines = winlines
        end
        table.insert(datainfo.bres,table.clone(respin))
        -- 如果没有修改则跳出
        if changeNum == maxChangeNum and maxChangeNum == 9  then
            for _, respinInfo in ipairs(datainfo.bres) do
                -- 修改总次数
                respinInfo.totalTimes = respin.totalTimes
                respinInfo.lackTimes = respin.totalTimes - respinInfo.times
            end
            break
        end
        
    end
    -- 获取本次Respin的结果
    datainfo.respin = table.clone(datainfo.bres[1])
    table.remove(datainfo.bres,1)
    datainfo.boards = datainfo.respin.boards
end