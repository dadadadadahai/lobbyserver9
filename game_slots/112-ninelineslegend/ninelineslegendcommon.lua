-- 九线传奇游戏模块
module('NineLinesLegend', package.seeall)
-- 九线传奇所需数据库表名称
DB_Name = "game112ninelineslegend"
-- 九线传奇所需配置表信息
Table_Base = import "table/game/112/table_112_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/112/table_112_payline"                    -- 中奖线
Table_NormalSpin = import "table/game/112/table_112_normalspin"               -- 普通棋盘
Table_FreeSpin = import "table/game/112/table_112_freespin"                   -- 免费棋盘
Table_PayTable = import "table/game/112/table_112_paytable"                   -- 中奖倍率
Table_FreeNum = import "table/game/112/table_112_freenum"                     -- 免费游戏游玩次数
Table_Bonus = import "table/game/112/table_112_bonus"                         -- Bonus小游戏其中图标概率
Table_NormalBow = import "table/game/112/table_112_normalbow"                 -- bow 普通棋盘触发
Table_FreeBow = import "table/game/112/table_112_freebow"                     -- bow 免费棋盘触发
Table_Jackpot = import "table/game/112/table_112_jackpot"                     -- jackpot奖池
LineNum = Table_Base[1].linenum

-- 九线传奇特殊元素ID
Bow = 100
W = 90
B = 80
S = 70
-- 最大普通ID
MaxNormalIconId = 7

-- 九线传奇通用配置
GameId = 112

DataFormat = {3,3,3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取九线传奇模块数据库信息
    local ninelineslegendInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(ninelineslegendInfo) then
        ninelineslegendInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,ninelineslegendInfo)
    end
    if gameType == nil then
        return ninelineslegendInfo
    end
    -- 没有初始化房间信息
    if table.empty(ninelineslegendInfo.gameRooms[gameType]) then
        ninelineslegendInfo.gameRooms[gameType] = {
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
                jackpotId = 0,                                      -- 奖池ID
                jackpotScore = 0,                                   -- 奖池金额
            }
        }
        unilight.update(DB_Name,uid,ninelineslegendInfo)
    end
    return ninelineslegendInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取九线传奇模块数据库信息
    local ninelineslegendInfo = unilight.getdata(DB_Name, uid)
    ninelineslegendInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,ninelineslegendInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,ninelineslegendInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,NineLinesLegend['table_112_freespin_'..gameType])
        GmProcess(uid, gameId, gameType, boards)
        res.bowInfo,res.bowTringerPoints = GetFreeBow(boards)
    else
        -- 普通游戏
        local betInfo = {
            betindex = ninelineslegendInfo.betIndex,
            betchips = ninelineslegendInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        GetJackpot(boards,gameType,ninelineslegendInfo)
        GmProcess(uid, gameId, gameType, boards)
        res.bowInfo,res.bowTringerPoints = GetNormalBow(boards,uid,gameType,betInfo)
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
        local addScore = v.mul * ninelineslegendInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    ninelineslegendInfo.boards = boards
    -- 棋盘数据
    res.boards = boards

    res.collect = {}

    res.tringerPoints = {}
    if isFree then
        res.tringerPoints.freeTringerPoints = GetFree(ninelineslegendInfo, true)
        res.tringerPoints.bonusTringerPoints = GetBonus(ninelineslegendInfo)

        local mul = 0
        for i = 1, res.bowInfo.bowNum do
            mul = mul + Table_FreeBow[1].mul
        end
        if mul > 0 then
            res.collect = {
                totalTimes = 1, -- 总次数
                lackTimes = 0, -- 剩余游玩次数
                -- tWinScore = (mul * ninelineslegendInfo.betMoney) + ninelineslegendInfo.betMoney, -- 总共已经赢得的钱
                tWinScore = mul * ninelineslegendInfo.betMoney, -- 总共已经赢得的钱
                mul = mul,
                tringerPoints = {res.bowTringerPoints} or {},
            }
            -- 增加总金额
            ninelineslegendInfo.free.tWinScore = ninelineslegendInfo.free.tWinScore + res.collect.tWinScore
        end
    else
        res.tringerPoints.freeTringerPoints = GetFree(ninelineslegendInfo)
        res.tringerPoints.bonusTringerPoints = GetBonus(ninelineslegendInfo)

        local mul = math.random(res.bowInfo.minMul, res.bowInfo.maxMul)
        if mul > 0 then
            res.collect = {
                totalTimes = 1, -- 总次数
                lackTimes = 0, -- 剩余游玩次数
                tWinScore = mul * ninelineslegendInfo.betMoney, -- 总共已经赢得的钱
                mul = mul,
                tringerPoints = {res.bowTringerPoints} or {},
            }
        end
    end
    ninelineslegendInfo.collect = res.collect
    -- 特殊模式金额累加计算
    if table.empty(res.collect) == false then
        res.specialWin = res.collect.tWinScore
    end
    return res
end
-- 判断是否触发免费
function GetFree(ninelineslegendInfo, isFree)
    -- 存在S列的个数
    local ColS = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 2, 4 do
        for rowNum = 1, #ninelineslegendInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if ninelineslegendInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                ColS = ColS + 1
                break
            end
        end
    end
    -- 判断是否触发免费
    if ColS >= 3 then
        -- -- 纯随机
        -- local probability = {}
        -- local allResult = {}
        -- for i, v in ipairs(Table_FreeNum) do
        --     if v.pro > 0 then
        --         table.insert(probability, v.pro)
        --         table.insert(allResult, {v.pro, v.freeNum})
        --     end
        -- end
        -- -- 免费游戏次数随机
        -- ninelineslegendInfo.free.totalTimes = math.random(probability, allResult)[2]
        -- 免费游戏次数随机
        ninelineslegendInfo.free.totalTimes = Table_FreeNum[gamecommon.CommRandInt(Table_FreeNum, 'pro')].freeNum
        return freeTringerPoints
    end
end
-- 判断是否触发Jackpot
function GetJackpot(boards,gameType,ninelineslegendInfo)
    local poolId,jackpotscore = gamecommon.NameGetGamePoolChips(GameId,gameType,ninelineslegendInfo.betIndex)
    -- local tringerPoints = {}
    -- 如果中奖更改棋盘
    if poolId ~= 0 then
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
        -- local winLinePoint = math.random(#Table_WinLines)
        for colNum = 2, 4 do
            local bFlag = false
            for rowNum = 1, DataFormat[colNum] do
                if boards[colNum][rowNum] == B then
                    bFlag = true
                    break
                end
            end
            if bFlag == false then
                local rowNum = math.random(DataFormat[colNum])
                -- local rowNum = math.floor(Table_WinLines[winLinePoint]['I'..i] / 10)
                -- local colNum = Table_WinLines[winLinePoint]['I'..i] % 10
                -- table.insert(tringerPoints,{line = colNum, row = rowNum})
                boards[colNum][rowNum] = B
            end
        end
        -- 插入Jackpot中奖图标
        ninelineslegendInfo.bonus.totalTimes = 1
        ninelineslegendInfo.bonus.jackpotId = poolId
        ninelineslegendInfo.bonus.jackpotScore = jackpotscore
        -- ninelineslegendInfo.bonus.tringerPoints = tringerPoints
    end
end
-- 判断是否触发Bonus
function GetBonus(ninelineslegendInfo)
    -- 存在S列的个数
    local ColB = 0
    -- 触发免费位置
    local bonusTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 2, 4 do
        for rowNum = 1, #ninelineslegendInfo.boards[colNum], 1 do
            -- 如果这个位置存在B图标 则B列的次数+1 直接跳转下一列
            if ninelineslegendInfo.boards[colNum][rowNum] == B then
                table.insert(bonusTringerPoints,{line = colNum, row = rowNum})
                ColB = ColB + 1
                break
            end
        end
    end
    -- 判断是否触发Bonus
    if ColB >= 3 then
        ninelineslegendInfo.bonus.totalTimes = 1
        return bonusTringerPoints
    end
end

-- 触发普通Bow
function GetNormalBow(boards,uid,gameType,betInfo)
    -- 生成一个用来缓存计算替换用的棋盘
    local changeBoards = table.clone(boards)
    -- 纯随机
    -- local probability = {}
    -- local allResult = {}
    local tringerPoints = {}
    local controlvalue = gamecommon.GetControlPoint(uid,betInfo)
    local rtp = gamecommon.GetModelRtp(uid,GameId,gameType,controlvalue)
    -- for i, v in ipairs(NineLinesLegend['table_112_normalbow_'..gameType]) do
    --     local pro = v.pro
    --     if rtp ~= 100 then
    --         pro = v["pro_"..tostring(rtp)]
    --     end
    --     if pro > 0 then
    --         table.insert(probability, pro)
    --         table.insert(allResult, {pro, v})
    --     end
    -- end
    -- -- 随机bow信息
    -- local bowInfo = math.random(probability, allResult)[2]

    local pro = 'pro'
    if rtp ~= 100 then
        pro ="pro_"..tostring(rtp)
    end
    -- 随机bow信息
    local bowInfo = NineLinesLegend['table_112_normalbow_'..gameType][gamecommon.CommRandInt(NineLinesLegend['table_112_normalbow_'..gameType], pro)]

    -- 如果随机到的是0个bow个数 直接返回
    if bowInfo.bowNum == 0 then
        return bowInfo,tringerPoints
    end
    -- 如果为无效图标则插入不中奖位置
    if bowInfo.minMul == 0 and bowInfo.maxMul == 0 then
        -- 获取W元素
        local wilds = {}
        wilds[W] = 1
        local nowild = {}
        nowild[S] = 1
        nowild[B] = 1
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(changeBoards,Table_WinLines,Table_PayTable,wilds,nowild)
        -- 寻找棋盘可插入位置
        for _, winlinesInfo in ipairs(winlines) do
            -- 替换中奖线对应棋盘位置
            for i = 1, winlinesInfo.num do
                local info = Table_WinLines[winlinesInfo.line]['I'..i]
                changeBoards[info % 10][math.floor(info / 10)] = -1
            end
        end
        -- 可插入位置
        local insertPoint = {}
        -- 遍历修改后的棋盘判断可插入位置
        for colNum = 1, #changeBoards do
            for rowNum = 1, #changeBoards[colNum] do
                if changeBoards[colNum][rowNum] ~= -1 and changeBoards[colNum][rowNum] ~= S and changeBoards[colNum][rowNum] ~= B then
                    -- 添加可插入位置信息
                    table.insert(insertPoint,{colNum = colNum,rowNum = rowNum})
                end
            end
        end

        -- 如果可以插入
        if bowInfo.bowNum <= #insertPoint then
            local pointList = chessutil.NotRepeatRandomNumbers(1,#insertPoint,bowInfo.bowNum)
            -- 替换棋盘图标
            for _, v in ipairs(pointList) do
                boards[insertPoint[v].colNum][insertPoint[v].rowNum] = Bow
                table.insert(tringerPoints,{line = insertPoint[v].colNum, row = insertPoint[v].rowNum})
            end
        else
            -- 需要插入的数量大于可插入位置 则所有可插入位置全部插入Bow图标
            for _, v in ipairs(insertPoint) do
                boards[v.colNum][v.rowNum] = Bow
                table.insert(tringerPoints,{line = v.colNum, row = v.rowNum})
            end
        end
    else
        -- 有效图标则让他不中奖
        local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,6)
        local changNum = 0
        -- 遍历修改棋盘前两列图标 保证其不中奖
        for colNum = 1, 2 do
            for rowNum = 1, #boards[colNum] do
                changNum = changNum + 1
                -- 替换图标
                boards[colNum][rowNum] = iconIdList[changNum]
            end
        end
        -- 添加BOW图标
        local changePoints = chessutil.NotRepeatRandomNumbers(1,3 * 5,bowInfo.bowNum)
        for _, v in ipairs(changePoints) do
            local colNum = math.ceil(v / DataFormat[1])
            local rowNum = (v % DataFormat[1])
            if v % DataFormat[1] == 0 then
                rowNum = DataFormat[1]
            end
            -- 替换图标
            boards[colNum][rowNum] = Bow
            table.insert(tringerPoints,{line = colNum, row = rowNum})
        end
    end
    return bowInfo, tringerPoints
end

-- 触发免费Bow
function GetFreeBow(boards)
    -- 棋盘中的BOW图标数量
    local bowInfo = {}
    local tringerPoints = {}
    bowInfo.bowNum = 0
    -- 遍历棋盘判断BOW个数
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            if boards[colNum][rowNum] == Bow then
                bowInfo.bowNum = bowInfo.bowNum + 1
                table.insert(tringerPoints,{line = colNum, row = rowNum})
            end
        end
    end
    return bowInfo, tringerPoints
end

-- 包装返回信息
function GetResInfo(uid, ninelineslegendInfo, gameType, tringerPoints, jackpot, collect)
    collect = collect or {}
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    ninelineslegendInfo = table.clone(ninelineslegendInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(ninelineslegendInfo.boards) == false then
        boards = {ninelineslegendInfo.boards}
    end
    local free = {}
    if ninelineslegendInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = ninelineslegendInfo.free.totalTimes, -- 总次数
            lackTimes = ninelineslegendInfo.free.totalTimes - ninelineslegendInfo.free.times, -- 剩余游玩次数
            tWinScore = ninelineslegendInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local bonus = {}
    if ninelineslegendInfo.bonus.totalTimes ~= -1 then
        bonus = {
            totalTimes = ninelineslegendInfo.bonus.totalTimes, -- 总次数
            lackTimes = ninelineslegendInfo.bonus.totalTimes - ninelineslegendInfo.bonus.times, -- 剩余游玩次数
            tWinScore = ninelineslegendInfo.bonus.tWinScore, -- 总共已经赢得的钱
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
        betIndex = ninelineslegendInfo.betIndex,
        -- 全部下注金额
        payScore = ninelineslegendInfo.betMoney,
        -- 已赢的钱
        -- winScore = ninelineslegendInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,bonus = bonus,jackpot = jackpot,collect = collect,},
    }
    return res
end
