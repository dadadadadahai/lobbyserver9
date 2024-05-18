-- 火焰连击游戏模块
module('FireCombo', package.seeall)
-- 火焰连击所需数据库表名称
DB_Name = "game117firecombo"
-- 火焰连击所需配置表信息
Table_Base = import "table/game/117/table_117_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/117/table_117_payline"                    -- 中奖线
-- Table_NormalSpin = import "table/game/117/table_117_normalspin"               -- 普通棋盘
-- Table_FreeSpin = import "table/game/117/table_117_freespin"                   -- 免费棋盘
Table_PayTable = import "table/game/117/table_117_paytable"                   -- 中奖倍率
Table_FreeNum = import "table/game/117/table_117_freenum"                     -- 免费游戏游玩次数
-- Table_NormalU = import "table/game/117/table_117_normalu"                 -- bow 普通棋盘触发
Table_FreeU = import "table/game/117/table_117_freeu"                     -- bow 免费棋盘触发
Table_Jackpot = import "table/game/117/table_117_jackpot"                     -- jackpot奖池
LineNum = Table_Base[1].linenum

-- 火焰连击特殊元素ID
U = 80
Jackpot = 100
FreeU = 81
W = 90
S = 70
-- 最大普通ID
MaxNormalIconId = 7

-- 火焰连击通用配置
GameId = 117

DataFormat = {3,3,3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取火焰连击模块数据库信息
    local firecomboInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(firecomboInfo) then
        firecomboInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,firecomboInfo)
    end
    if gameType == nil then
        return firecomboInfo
    end
    -- 没有初始化房间信息
    if table.empty(firecomboInfo.gameRooms[gameType]) then
        firecomboInfo.gameRooms[gameType] = {
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
        unilight.update(DB_Name,uid,firecomboInfo)
    end
    return firecomboInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取火焰连击模块数据库信息
    local firecomboInfo = unilight.getdata(DB_Name, uid)
    firecomboInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,firecomboInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,firecomboInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    local success = false
    local jackpotChips = 0
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,FireCombo['table_117_freespin_'..gameType])
        GmProcess(uid, gameId, gameType, boards)
        res.bowInfo,res.bowTringerPoints = GetFreeU(boards)
    else
        -- 普通游戏
        local betInfo = {
            betindex = firecomboInfo.betIndex,
            betchips = firecomboInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        -- success,res.bowInfo,res.bowTringerPoints,jackpotChips = GetJackpot(boards,gameType,firecomboInfo)
        GmProcess(uid, gameId, gameType, boards)
        -- if success == false then
        res.bowInfo,res.bowTringerPoints = GetNormalU(boards,uid,gameType,betInfo)
        -- end
        success,res.jackpotTringerPoints,jackpotChips = GetJackpot(boards,gameType,firecomboInfo)
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
        local addScore = v.mul * firecomboInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    res.jackpotChips = jackpotChips
    if not isFree then
        -- 填充Jackpot图标
        local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],success,GameId)
        for _, v in ipairs(winlines) do
            jackFill:PreWinData(v.winicon)
        end
        -- 遍历棋盘排除替换S图标
        for colNum = 1, #boards do
            for rowNum = 1, #boards[colNum] do
                -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
                if boards[colNum][rowNum] == S or boards[colNum][rowNum] == U then
                    jackFill:FillExtraIcon(colNum,rowNum)
                end
            end
        end
        jackFill:CreateFinalChessData(boards,Jackpot)
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    firecomboInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.collect = {}

    res.tringerPoints = {}
    if isFree then
        res.tringerPoints.freeTringerPoints = GetFree(firecomboInfo, true)

        local mul = 0
        for i = 1, res.bowInfo.bowNum do
            mul = mul + Table_FreeU[1].mul
        end
        if mul > 0 then
            res.collect = {
                totalTimes = 1, -- 总次数
                lackTimes = 0, -- 剩余游玩次数
                -- tWinScore = (mul * firecomboInfo.betMoney) + firecomboInfo.betMoney, -- 总共已经赢得的钱
                tWinScore = mul * firecomboInfo.betMoney, -- 总共已经赢得的钱
                mul = mul,
                tringerPoints = {res.bowTringerPoints} or {},
            }
            -- 特殊模式金额累加计算
            res.specialWin=res.collect.tWinScore
            -- 增加总金额
            firecomboInfo.free.tWinScore = firecomboInfo.free.tWinScore + res.collect.tWinScore
        end
    else
        res.tringerPoints.freeTringerPoints = GetFree(firecomboInfo)

        local mul = math.random(res.bowInfo.minMul, res.bowInfo.maxMul)
        if mul > 0 then
            res.collect = {
                totalTimes = 1, -- 总次数
                lackTimes = 0, -- 剩余游玩次数
                tWinScore = mul * firecomboInfo.betMoney, -- 总共已经赢得的钱
                mul = mul,
                tringerPoints = {res.bowTringerPoints} or {},
            }
            -- 特殊模式金额累加计算
            res.specialWin=res.collect.tWinScore
        end
    end
    firecomboInfo.collect = res.collect
    return res
end
-- 判断是否触发免费
function GetFree(firecomboInfo, isFree)
    -- 存在S列的个数
    local ColS = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #firecomboInfo.boards do
        for rowNum = 1, #firecomboInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if firecomboInfo.boards[colNum][rowNum] == S then
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
        -- firecomboInfo.free.totalTimes = math.random(probability, allResult)[2]
        -- 免费游戏次数随机
        firecomboInfo.free.totalTimes = Table_FreeNum[gamecommon.CommRandInt(Table_FreeNum, 'pro')].freeNum
        return freeTringerPoints
    end
end
-- 判断是否触发Jackpot
function GetJackpot(boards,gameType,firecomboInfo)
    local bSucess,jackpotNum, jackpotChips = gamecommon.GetGamePoolChips(GameId,gameType,firecomboInfo.betIndex)
    local tringerPoints = {}
    -- local bowInfo = FireCombo['table_117_normalu_'..gameType][1]
    -- 如果中奖更改棋盘
    if bSucess then
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
        for colNum = 1, jackpotNum do
            local rowNum = math.random(DataFormat[colNum])
            table.insert(tringerPoints,{line = colNum, row = rowNum})
            boards[colNum][rowNum] = Jackpot
        end
        -- local addPoints = chessutil.NotRepeatRandomNumbers(1,15,jackpotNum)
        -- for _, v in ipairs(addPoints) do
        --     local colNum = math.ceil(v / DataFormat[1])
        --     local rowNum = (v % DataFormat[1])
        --     if v % DataFormat[1] == 0 then
        --         rowNum = DataFormat[1]
        --     end
        --     table.insert(tringerPoints,{line = colNum, row = rowNum})
        --     boards[colNum][rowNum] = Jackpot
        -- end
        -- 填充信息
        -- for _, v in ipairs(FireCombo['table_117_normalu_'..gameType]) do
        --     if jackpotNum == v.bowNum then
        --         bowInfo = v
        --     end
        -- end
    end
    return bSucess,tringerPoints,jackpotChips
end

-- 触发普通U
function GetNormalU(boards,uid,gameType,betInfo)
    -- 生成一个用来缓存计算替换用的棋盘
    local changeBoards = table.clone(boards)
    -- 纯随机
    -- local probability = {}
    -- local allResult = {}
    local tringerPoints = {}
    
    local controlvalue = gamecommon.GetControlPoint(uid,betInfo)
    local rtp = gamecommon.GetModelRtp(uid,GameId,gameType,controlvalue)
    -- for i, v in ipairs(FireCombo['table_117_normalu_'..gameType]) do
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
    local bowInfo = FireCombo['table_117_normalu_'..gameType][gamecommon.CommRandInt(FireCombo['table_117_normalu_'..gameType], pro)]
    
    ----------------------------------------------------------------------- Test -----------------------------------------------------------------------
    bowInfo = GmProcess(uid, gameId, gameType, boards, bowInfo)
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
                if changeBoards[colNum][rowNum] ~= -1 and changeBoards[colNum][rowNum] ~= S and changeBoards[colNum][rowNum] ~= B and changeBoards[colNum][rowNum] ~= Jackpot then
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
                boards[insertPoint[v].colNum][insertPoint[v].rowNum] = U
                table.insert(tringerPoints,{line = insertPoint[v].colNum, row = insertPoint[v].rowNum})
            end
        else
            -- 需要插入的数量大于可插入位置 则所有可插入位置全部插入U图标
            for _, v in ipairs(insertPoint) do
                boards[v.colNum][v.rowNum] = U
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
            boards[colNum][rowNum] = U
            table.insert(tringerPoints,{line = colNum, row = rowNum})
        end
    end
    return bowInfo, tringerPoints
end

-- 触发免费U
function GetFreeU(boards)
    -- 棋盘中的BOW图标数量
    local bowInfo = {}
    local tringerPoints = {}
    bowInfo.bowNum = 0
    -- 遍历棋盘判断BOW个数
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            if boards[colNum][rowNum] == FreeU then
                bowInfo.bowNum = bowInfo.bowNum + 1
                table.insert(tringerPoints,{line = colNum, row = rowNum})
            end
        end
    end
    return bowInfo, tringerPoints
end

-- 包装返回信息
function GetResInfo(uid, firecomboInfo, gameType, tringerPoints, jackpot, collect)
    collect = collect or {}
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    firecomboInfo = table.clone(firecomboInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(firecomboInfo.boards) == false then
        boards = {firecomboInfo.boards}
    end
    local free = {}
    if firecomboInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = firecomboInfo.free.totalTimes, -- 总次数
            lackTimes = firecomboInfo.free.totalTimes - firecomboInfo.free.times, -- 剩余游玩次数
            tWinScore = firecomboInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = firecomboInfo.betIndex,
        -- 全部下注金额
        payScore = firecomboInfo.betMoney,
        -- 已赢的钱
        -- winScore = firecomboInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,jackpot = jackpot,collect = collect,},
    }
    return res
end
