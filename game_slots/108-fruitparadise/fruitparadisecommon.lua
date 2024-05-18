-- 水果天堂游戏模块
module('FruitParadise', package.seeall)
-- 水果天堂所需数据库表名称
DB_Name = "game108fruitparadise"
-- 水果天堂所需配置表信息
Table_Base = import "table/game/108/table_fruit_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/108/table_fruit_payline"                    -- 中奖线
-- Table_NormalSpin = import "table/game/108/table_fruit_normalspin"               -- 普通棋盘
Table_FreeSpin = import "table/game/108/table_fruit_freespin"                   -- 免费棋盘
Table_PayTable = import "table/game/108/table_fruit_paytable"                   -- 中奖倍率
Table_Free = import "table/game/108/table_fruit_free"                           -- 触发免费

-- JACKPOT所需数据配置表
table_108_jackpot_chips   = import 'table/game/108/table_108_jackpot_chips'
table_108_jackpot_add_per = import 'table/game/108/table_108_jackpot_add_per'
table_108_jackpot_bomb    = import 'table/game/108/table_108_jackpot_bomb'
-- table_108_jackpot_scale   = import 'table/game/108/table_108_jackpot_scale'
table_108_jackpot_bet     = import 'table/game/108/table_108_jackpot_bet'

-- 水果天堂特殊元素ID
Jackpot = 100
W = 90
S = 70
LineNum = Table_Base[1].linenum
-- 水果天堂通用配置
GameId = 108
-- 替换图标
jackpotIconList = {}
jackpotIconList[1] = {1,2,3,4}
jackpotIconList[2] = {5,6,7,8}
DataFormat = {3,3,3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取水果天堂模块数据库信息
    local fruitparadiseInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(fruitparadiseInfo) then
        fruitparadiseInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,fruitparadiseInfo)
    end
    if gameType == nil then
        return fruitparadiseInfo
    end
    -- 没有初始化房间信息
    if table.empty(fruitparadiseInfo.gameRooms[gameType]) then
        fruitparadiseInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            -- 免费游戏信息
            free = {
                totalTimes = -1,                                    -- 总次数
                times = 0,                                          -- 游玩次数
                tWinScore = 0,                                      -- 已经赢得的钱
            },
        }
        unilight.update(DB_Name,uid,fruitparadiseInfo)
    end
    return fruitparadiseInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取水果天堂模块数据库信息
    local fruitparadiseInfo = unilight.getdata(DB_Name, uid)
    fruitparadiseInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,fruitparadiseInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,fruitparadiseInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    local jackpotTringerPoints = {}
    local jackpotChips = 0
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,FruitParadise['table_fruit_freespin_'..gameType])
    else
        -- 普通游戏
        local betInfo = {
            betindex = fruitparadiseInfo.betIndex,
            betchips = fruitparadiseInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    end
    -- 判断中奖池
    jackpotTringerPoints,jackpotChips = GetJackpot(boards,gameType,fruitparadiseInfo)
    GmProcess(uid, gameId, gameType, boards)
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,Table_WinLines,Table_PayTable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * fruitparadiseInfo.betMoney / Table_Base[1].linenum
        if v.num==5 then
            addScore = addScore/2
        end
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 未中奖池则插入假数据
    if jackpotChips <= 0 then
        local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],not table.empty(jackpotTringerPoints),GameId)
        for _, v in ipairs(winlines) do
            for _, value in ipairs(v.winpos) do
                jackFill:FillExtraIcon(value[1],value[2])
            end
            -- jackFill:PreWinData(v.winicon)
        end
        -- 遍历棋盘排除替换S图标
        for colNum = 1, #boards do
            for rowNum = 1, #boards[colNum] do
                -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
                if boards[colNum][rowNum] == S then
                    jackFill:FillExtraIcon(colNum,rowNum)
                end
            end
        end
        jackFill:CreateFinalChessData(boards,Jackpot)
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    fruitparadiseInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.jackpotTringerPoints = {jackpotTringerPoints}
    res.jackpotChips = jackpotChips
    if isFree then
        res.freeTringerPoints = GetFree(fruitparadiseInfo, true)
    else
        res.freeTringerPoints = GetFree(fruitparadiseInfo, false)
    end
    return res
end

function GetJackpot(boards,gameType,fruitparadiseInfo)
    -- 可插入列表
    local insertList = {}
    local inserCol = {}
    local maxInserCol = {}
    -- 寻找棋盘中的可替换图标
    for colIndex, colValue in ipairs(boards) do
        for rowIndex, rowValue in ipairs(colValue) do
            -- 只能替换普通图标
            if rowValue ~= W and rowValue ~= S then
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
    local jackpotTringerPoints = {}
    local bSucess = false
    local iconNum = gamecommon.GetJackpotIconNum(GameId,gameType)
    -- 判断是否有资格中Jackpot
    if iconNum > 0 and #maxInserCol >= iconNum then
        -- 获得奖励
        bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, fruitparadiseInfo.betIndex)
        -- 获得奖池奖励
        if bSucess and #maxInserCol >= iconNum then
            -- 如果中Jackpot则让他不中奖
            for colNum = 1, #boards do
                local changNum = 0
                local indexList = chessutil.NotRepeatRandomNumbers(1,#jackpotIconList[colNum%2+1],#jackpotIconList[colNum%2+1])
                local iconIdList = jackpotIconList[colNum%2+1]
                for rowNum = 1, #boards[colNum] do
                    changNum = changNum + 1
                    -- 替换图标
                    boards[colNum][rowNum] = iconIdList[indexList[changNum]]
                end
            end
            -- res.jackpotChips = jackpotChips
            local firstIndex = math.random(#DataFormat - iconNum + 1)
            -- 中奖 则替换图标
            for index = firstIndex, (firstIndex + iconNum - 1) do
                -- 随机行数
                local rowRandomIndex = math.random(#insertList[maxInserCol[index]])
                -- 替换其中的图标
                boards[maxInserCol[index]][insertList[maxInserCol[index]][rowRandomIndex]] = Jackpot
                table.insert(jackpotTringerPoints,{line = maxInserCol[index], row = insertList[maxInserCol[index]][rowRandomIndex]})
            end 
        end
    end
    return jackpotTringerPoints,jackpotChips
end

-- 判断是否触发免费
function GetFree(fruitparadiseInfo, isFree)
    -- 存在S列的个数
    local ColS = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #fruitparadiseInfo.boards, 1 do
        for rowNum = 1, #fruitparadiseInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if fruitparadiseInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                ColS = ColS + 1
                break
            end
        end
    end
    -- 循环判断S列数是否触发免费
    for i, v in ipairs(Table_Free) do
        if ColS == v.sNum then
            -- 免费中触发则增加次数
            if isFree then
                fruitparadiseInfo.free.totalTimes = fruitparadiseInfo.free.totalTimes + v.freeNum
            else
                -- 普通则触发免费
                fruitparadiseInfo.free.totalTimes = v.freeNum
            end
            return freeTringerPoints
        end
    end
end

-- 包装返回信息
function GetResInfo(uid, fruitparadiseInfo, gameType, freeTringerPoints, jackpot)
    -- 克隆数据表
    fruitparadiseInfo = table.clone(fruitparadiseInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(fruitparadiseInfo.boards) == false then
        boards = {fruitparadiseInfo.boards}
    end
    local free = {}
    if fruitparadiseInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = fruitparadiseInfo.free.totalTimes, -- 总次数
            lackTimes = fruitparadiseInfo.free.totalTimes - fruitparadiseInfo.free.times, -- 剩余游玩次数
            tWinScore = fruitparadiseInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = fruitparadiseInfo.betIndex,
        -- 全部下注金额
        payScore = fruitparadiseInfo.betMoney,
        -- 已赢的钱
        -- winScore = fruitparadiseInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,jackpot = jackpot},
    }
    return res
end