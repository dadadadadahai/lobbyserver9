-- 果园狂欢游戏模块
module('OrchardCarnival', package.seeall)
-- 果园狂欢所需数据库表名称
DB_Name = "game111orchardcarnival"
-- 果园狂欢所需配置表信息
Table_Base = import "table/game/111/table_111_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/111/table_111_payline"                    -- 中奖线
Table_NormalSpin = import "table/game/111/table_111_normalspin"               -- 普通棋盘
Table_FreeSpin = import "table/game/111/table_111_freespin"                   -- 免费棋盘
Table_PayTable = import "table/game/111/table_111_paytable"                   -- 中奖倍率
Table_Other = import "table/game/111/table_111_other"                         -- 其他信息
Table_Bonus = import "table/game/111/table_111_bonus"                         -- Bonus小游戏其中图标概率


-- JACKPOT所需数据配置表
table_111_jackpot_chips   = import 'table/game/111/table_111_jackpot_chips'
table_111_jackpot_add_per = import 'table/game/111/table_111_jackpot_add_per'
table_111_jackpot_bomb    = import 'table/game/111/table_111_jackpot_bomb'
-- table_111_jackpot_scale   = import 'table/game/111/table_111_jackpot_scale'
table_111_jackpot_bet     = import 'table/game/111/table_111_jackpot_bet'
LineNum = Table_Base[1].linenum
-- 果园狂欢特殊元素ID
Jackpot = 100
W = 90
B = 80
S = 70

-- 果园狂欢通用配置
GameId = 111
MaxNormalIconId = 7
DataFormat = {3,3,3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取果园狂欢模块数据库信息
    local orchardcarnivalInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(orchardcarnivalInfo) then
        orchardcarnivalInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,orchardcarnivalInfo)
    end
    if gameType == nil then
        return orchardcarnivalInfo
    end
    -- 没有初始化房间信息
    if table.empty(orchardcarnivalInfo.gameRooms[gameType]) then
        orchardcarnivalInfo.gameRooms[gameType] = {
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
                tWinScore = 0,                                      -- 已经赢得的钱
            }
        }
        unilight.update(DB_Name,uid,orchardcarnivalInfo)
    end
    return orchardcarnivalInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取果园狂欢模块数据库信息
    local orchardcarnivalInfo = unilight.getdata(DB_Name, uid)
    orchardcarnivalInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,orchardcarnivalInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,orchardcarnivalInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    nowild[B] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    local jackpotTringerPoints = {}
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,OrchardCarnival['table_111_freespin_'..gameType])
    else
        -- 普通游戏
        local betInfo = {
            betindex = orchardcarnivalInfo.betIndex,
            betchips = orchardcarnivalInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    end
    GmProcess(uid, gameId, gameType, boards)
    -- 可插入列表
    local insertList = {}
    local inserCol = {}
    local maxInserCol = {}
    -- 寻找棋盘中的可替换图标
    for colIndex, colValue in ipairs(boards) do
        for rowIndex, rowValue in ipairs(colValue) do
            -- 只能替换普通图标
            if rowValue ~= W and rowValue ~= S and rowValue ~= B then
                if insertList[colIndex] == nil then
                    insertList[colIndex] = {}
                    -- 如果他的前一列没有可替换图标则重置累计连续列数
                    if colIndex > 1 and insertList[colIndex - 1] == nil then
                        if #maxInserCol < #inserCol then
                            maxInserCol = inserCol
                        end
                        inserCol = {}
                    end
                    table.insert(inserCol,colIndex)
                end
                table.insert(insertList[colIndex],rowIndex)
            end
        end
    end
    if #maxInserCol < #inserCol then
        maxInserCol = inserCol
    end

    -- 奖池初始化数值
    local jackpotChips = 0
    local bSucess = false
    local iconNum = gamecommon.GetJackpotIconNum(GameId,gameType)
    res.jackpotChips = jackpotChips
    -- 判断是否有资格中Jackpot
    if iconNum > 0 and #maxInserCol >= iconNum then
        -- 获得奖池奖励
        bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, orchardcarnivalInfo.betIndex)
        -- 添加奖池图标
        if bSucess and #maxInserCol >= iconNum then
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
            res.jackpotChips = jackpotChips
            local firstIndex = math.random(#DataFormat - iconNum + 1)
            -- 中奖 则替换图标
            for index = firstIndex, (firstIndex + iconNum - 1) do
                -- 随机行数
                local rowRandomIndex = math.random(#insertList[maxInserCol[index]])
                -- 替换图标
                boards[maxInserCol[index]][insertList[maxInserCol[index]][rowRandomIndex]] = Jackpot
                table.insert(jackpotTringerPoints,{line = maxInserCol[index], row = insertList[maxInserCol[index]][rowRandomIndex]})
            end
        end
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
        local addScore = v.mul * orchardcarnivalInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    
    -- 填充Jackpot图标
    local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],bSucess,GameId)
    for _, v in ipairs(winlines) do
        jackFill:PreWinData(v.winicon)
    end
    -- 遍历棋盘排除替换S图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if boards[colNum][rowNum] == S or boards[colNum][rowNum] == B then
                jackFill:FillExtraIcon(colNum,rowNum)
            end
        end
    end
    jackFill:CreateFinalChessData(boards,Jackpot)
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    orchardcarnivalInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.jackpotTringerPoints = {jackpotTringerPoints}
    res.tringerPoints = {}
    if isFree then
        res.tringerPoints.freeTringerPoints = GetFree(orchardcarnivalInfo, true)
        res.tringerPoints.bonusTringerPoints = GetBonus(orchardcarnivalInfo)
    else
        res.tringerPoints.freeTringerPoints = GetFree(orchardcarnivalInfo, false)
        res.tringerPoints.bonusTringerPoints = GetBonus(orchardcarnivalInfo)
    end
    return res
end
-- 判断是否触发免费
function GetFree(orchardcarnivalInfo, isFree)
    -- 存在S列的个数
    local ColS = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 2, 4 do
        for rowNum = 1, #orchardcarnivalInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if orchardcarnivalInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                ColS = ColS + 1
                break
            end
        end
    end
    -- 判断是否触发免费
    if ColS >= 3 then
        -- 免费中触发则增加次数
        if isFree then
            orchardcarnivalInfo.free.totalTimes = orchardcarnivalInfo.free.totalTimes + math.random(Table_Other[1].minFreeNum,Table_Other[1].maxFreeNum)
        else
            -- 普通则触发免费
            orchardcarnivalInfo.free.totalTimes = math.random(Table_Other[1].minFreeNum,Table_Other[1].maxFreeNum)
        end
        return freeTringerPoints
    end
end
-- 判断是否触发Bonus
function GetBonus(orchardcarnivalInfo)
    -- 存在S列的个数
    local ColB = 0
    -- 触发免费位置
    local bonusTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 2, 4 do
        local firstFlag = true
        for rowNum = 1, #orchardcarnivalInfo.boards[colNum], 1 do
            -- 如果这个位置存在B图标 则B列的次数+1 直接跳转下一列
            if orchardcarnivalInfo.boards[colNum][rowNum] == B then
                table.insert(bonusTringerPoints,{line = colNum, row = rowNum})
                if firstFlag then
                    ColB = ColB + 1
                    firstFlag = false
                end
                -- break
            end
        end
    end
    -- 判断是否触发Bonus
    if ColB >= 3 then
        orchardcarnivalInfo.bonus.totalTimes = Table_Other[1].bonusNum
        return bonusTringerPoints
    end
end

-- 包装返回信息
function GetResInfo(uid, orchardcarnivalInfo, gameType, tringerPoints, jackpot)
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- if orchardcarnivalInfo.bres == nil then
    --     orchardcarnivalInfo.bres = {}
    -- end
    -- 克隆数据表
    orchardcarnivalInfo = table.clone(orchardcarnivalInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(orchardcarnivalInfo.boards) == false then
        boards = {orchardcarnivalInfo.boards}
    end
    local free = {}
    if orchardcarnivalInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = orchardcarnivalInfo.free.totalTimes, -- 总次数
            lackTimes = orchardcarnivalInfo.free.totalTimes - orchardcarnivalInfo.free.times, -- 剩余游玩次数
            tWinScore = orchardcarnivalInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local bonus = {}
    if orchardcarnivalInfo.bonus.totalTimes ~= -1 then
        bonus = {
            totalTimes = orchardcarnivalInfo.bonus.totalTimes, -- 总次数
            -- lackTimes = orchardcarnivalInfo.bonus.totalTimes - orchardcarnivalInfo.bonus.times, -- 剩余游玩次数
            lackTimes = #orchardcarnivalInfo.bres, -- 剩余游玩次数
            tWinScore = orchardcarnivalInfo.bonus.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.bonusTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = orchardcarnivalInfo.betIndex,
        -- 全部下注金额
        payScore = orchardcarnivalInfo.betMoney,
        -- 已赢的钱
        -- winScore = orchardcarnivalInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,bonus = bonus,jackpot = jackpot},
    }
    return res
end
