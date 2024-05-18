-- 水果机器游戏模块
module('FruitMachine', package.seeall)
-- 水果机器所需数据库表名称
DB_Name = "game114fruitmachine"
-- 水果机器所需配置表信息
Table_Base = import "table/game/114/table_114_hanglie"                         -- 基础行列
Table_WinLines = import "table/game/114/table_114_payline"                     -- 中奖线
Table_NormalSpin = import "table/game/114/table_114_normalspin"                -- 普通棋盘
Table_FreeSpin = import "table/game/114/table_114_freespin"                    -- 免费棋盘
Table_PayTable = import "table/game/114/table_114_paytable"                    -- 中奖倍率
Table_JackpotIcon = import "table/game/114/table_114_jackpoticon"              -- jackpot图标
Table_Jackpot = import "table/game/114/table_114_jackpot"                      -- jackpot奖池
Table_Bonus1 = import "table/game/114/table_114_bonus1"                        -- 转盘1
Table_Bonus2 = import "table/game/114/table_114_bonus2"                        -- 转盘2
Table_Bonus3 = {}
Table_Bonus3[1] = import "table/game/114/table_114_bonus3free"                 -- 转盘3免费
Table_Bonus3[2] = import "table/game/114/table_114_bonus3reward"               -- 转盘3奖励

LineNum = Table_Base[1].linenum

-- 水果机器特殊元素ID
Jackpot = {}
Jackpot[1] = 101    -- MINOR
Jackpot[2] = 102    -- MAJOR
Jackpot[3] = 103    -- GRAND
W = 90
B = 80
-- 最大普通ID
MaxNormalIconId = 7

-- 水果机器通用配置
GameId = 114

DataFormat = {3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取水果机器模块数据库信息
    local fruitmachineInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(fruitmachineInfo) then
        fruitmachineInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,fruitmachineInfo)
    end
    if gameType == nil then
        return fruitmachineInfo
    end
    -- 没有初始化房间信息
    if table.empty(fruitmachineInfo.gameRooms[gameType]) then
        fruitmachineInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            -- 免费游戏信息
            free = {
                totalTimes = -1,                                    -- 总次数
                times = 0,                                          -- 游玩次数
                tWinScore = 0,                                      -- 已经赢得的钱
            },
            bonus = {
                totalTimes = -1,                                    -- 总次数
                times = 0,                                          -- 游玩次数
                spinTotalTimes = 0,                                 -- 第三个转盘的总次数
                spinTimes = 0,                                      -- 第三个转盘的游玩次数
                tWinScore = 0,                                      -- 已经赢得的钱
                bonusType = 0,                                      -- 转盘类型
            }
        }
        unilight.update(DB_Name,uid,fruitmachineInfo)
    end
    return fruitmachineInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取水果机器模块数据库信息
    local fruitmachineInfo = unilight.getdata(DB_Name, uid)
    fruitmachineInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,fruitmachineInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,fruitmachineInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[B] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,FruitMachine['table_114_freespin_'..gameType])
        GmProcess(uid, gameId, gameType, boards)
    else
        -- 普通游戏
        local betInfo = {
            betindex = fruitmachineInfo.betIndex,
            betchips = fruitmachineInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        res.jackpotResult = GetJackpot(boards,gameType,fruitmachineInfo.betIndex)
        GmProcess(uid, gameId, gameType, boards)
    end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,Table_WinLines,Table_PayTable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * fruitmachineInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    if not isFree then
        local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],false,GameId)
        for _, v in ipairs(winlines) do
            jackFill:PreWinData(v.winicon)
        end
        -- 遍历棋盘排除替换S图标
        for colNum = 1, #boards do
            for rowNum = 1, #boards[colNum] do
                -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
                if boards[colNum][rowNum] == B then
                    jackFill:FillExtraIcon(colNum,rowNum)
                end
            end
        end
        jackFill:CreateFinalChessData(boards,Jackpot[math.random(#Jackpot)])
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    fruitmachineInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.tringerPoints = {}
    res.tringerPoints.bonusTringerPoints = GetBonus(fruitmachineInfo)
    return res
end
-- 判断是否触发Bonus
function GetBonus(fruitmachineInfo)
    -- 存在S列的个数
    local ColB = 0
    -- 触发免费位置
    local bonusTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #fruitmachineInfo.boards do
        for rowNum = 1, #fruitmachineInfo.boards[colNum] do
            -- 如果这个位置存在B图标 则B列的次数+1 直接跳转下一列
            if fruitmachineInfo.boards[colNum][rowNum] == B then
                table.insert(bonusTringerPoints,{line = colNum, row = rowNum})
                ColB = ColB + 1
                break
            end
        end
    end
    -- 判断是否触发Bonus
    if ColB >= 3 then
        fruitmachineInfo.bonus.totalTimes = 1
        return bonusTringerPoints
    end
end
-- 判断是否触发Jackpot
function GetJackpot(boards,gameType,betIndex)
    local poolId,jackpotscore = gamecommon.NameGetGamePoolChips(GameId,gameType,betIndex)
    local iconId = 0
    for _, v in ipairs(Table_JackpotIcon) do
        if v.jackpot == poolId then
            iconId = v.iconId
            break
        end
    end
    local jackpotTringerPoints = {}
    -- 如果中奖更改棋盘
    if iconId ~= 0 then
        -- 如果中Jackpot则让他不中奖
        local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,2 * #boards[1])
        local changNum = 0
        -- 遍历修改棋盘前两列图标 保证其不中奖
        for colNum = 1, 2 do
            for rowNum = 1, #boards[colNum] do
                changNum = changNum + 1
                -- 替换图标
                boards[colNum][rowNum] = iconIdList[changNum]
            end
        end
        -- 插入Jackpot中奖图标
        local winLinePoint = math.random(#Table_WinLines)
        for i = 1, 3 do
            local rowNum = math.floor(Table_WinLines[winLinePoint]['I'..i] / 10)
            local colNum = Table_WinLines[winLinePoint]['I'..i] % 10
            table.insert(jackpotTringerPoints,{line = colNum, row = rowNum})
            boards[colNum][rowNum] = iconId
        end
    end
    local playResult = {jackpot = poolId,jackpotscore = jackpotscore,jackpotTringerPoints = jackpotTringerPoints}
    return playResult
end
-- function GetJackpot(boards)
--     -- 纯随机
--     local probability = {}
--     local allResult = {}
--     local jackpotTringerPoints = {}
--     for i, v in ipairs(Table_JackpotIcon) do
--         if v.pro > 0 then
--             table.insert(probability, v.pro)
--             table.insert(allResult, {v.pro, {iconId = v.iconId,jackpot = v.jackpot}})
--         end
--     end
--     -- 获取随机后的结果
--     local playResult = math.random(probability, allResult)[2]
--     playResult = GmProcess(boards, playResult)
--     if playResult.iconId ~= 0 and playResult.jackpot ~= 0 then
--         -- 如果中Jackpot则让他不中奖
--         local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,2 * #boards[1])
--         local changNum = 0
--         -- 遍历修改棋盘前两列图标 保证其不中奖
--         for colNum = 1, 2 do
--             for rowNum = 1, #boards[colNum] do
--                 changNum = changNum + 1
--                 -- 替换图标
--                 boards[colNum][rowNum] = iconIdList[changNum]
--             end
--         end
--         -- 插入Jackpot中奖图标
--         local winLinePoint = math.random(#Table_WinLines)
--         for i = 1, 3 do
--             local rowNum = math.floor(Table_WinLines[winLinePoint]['I'..i] / 10)
--             local colNum = Table_WinLines[winLinePoint]['I'..i] % 10
--             table.insert(jackpotTringerPoints,{line = colNum, row = rowNum})
--             boards[colNum][rowNum] = playResult.iconId
--         end
--     end
--     playResult.jackpotTringerPoints = jackpotTringerPoints
--     return playResult
-- end
-- 包装返回信息
function GetResInfo(uid, fruitmachineInfo, gameType, tringerPoints, jackpot)
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    fruitmachineInfo = table.clone(fruitmachineInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(fruitmachineInfo.boards) == false then
        boards = {fruitmachineInfo.boards}
    end
    local free = {}
    if fruitmachineInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = fruitmachineInfo.free.totalTimes, -- 总次数
            lackTimes = fruitmachineInfo.free.totalTimes - fruitmachineInfo.free.times, -- 剩余游玩次数
            tWinScore = fruitmachineInfo.free.tWinScore, -- 总共已经赢得的钱
        }
    end
    local bonus = {}
    if fruitmachineInfo.bonus.totalTimes ~= -1 then
        bonus = {
            totalTimes = fruitmachineInfo.bonus.totalTimes, -- 总次数
            lackTimes = fruitmachineInfo.bonus.totalTimes - fruitmachineInfo.bonus.times, -- 剩余游玩次数
            tWinScore = fruitmachineInfo.bonus.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.bonusTringerPoints} or {},
            bonusType = fruitmachineInfo.bonus.bonusType,
            spinTotalTimes = fruitmachineInfo.bonus.spinTotalTimes,                                  -- 总次数
            spinTimes = fruitmachineInfo.bonus.spinTimes,                                        -- 游玩次数
        }
    end
    if bonus.bonusType == 1 then       -- 如果是增加免费次数
        local boards = {}
        for i, v in ipairs(Table_Bonus3[1]) do
            table.insert(boards,v.freeNum)
        end
        bonus.boards = boards
    elseif bonus.bonusType == 2 then   -- 如果是增加金额
        local boards = {}
        for i, v in ipairs(Table_Bonus3[2]) do
            table.insert(boards,v.mul * fruitmachineInfo.betMoney)
        end
        bonus.boards = boards
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = fruitmachineInfo.betIndex,
        -- 全部下注金额
        payScore = fruitmachineInfo.betMoney,
        -- 已赢的钱
        -- winScore = fruitmachineInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,bonus = bonus,jackpot = jackpot,},
    }
    return res
end
