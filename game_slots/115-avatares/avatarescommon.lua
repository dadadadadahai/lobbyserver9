-- 阿凡达游戏模块
module('Avatares', package.seeall)
-- 阿凡达所需数据库表名称
DB_Name = "game115avatares"
-- 阿凡达所需配置表信息
Table_Base = import "table/game/115/table_115_hanglie"                         -- 基础行列
Table_FreeSpin = import "table/game/115/table_115_freespin"                    -- 免费棋盘
Table_WinLines = import "table/game/115/table_115_payline"                     -- 中奖线
Table_PayTable = import "table/game/115/table_115_paytable"                    -- 中奖倍率
Table_Other = import "table/game/115/table_115_other"                          -- 其他配置
LineNum = Table_Base[1].linenum
-- 阿凡达特殊元素ID
W = 90
S = 70

-- 阿凡达通用配置
GameId = 115

DataFormat = {6,6,6}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取阿凡达模块数据库信息
    local avataresInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(avataresInfo) then
        avataresInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,avataresInfo)
    end
    if gameType == nil then
        return avataresInfo
    end
    -- 没有初始化房间信息
    if table.empty(avataresInfo.gameRooms[gameType]) then
        avataresInfo.gameRooms[gameType] = {
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
        unilight.update(DB_Name,uid,avataresInfo)
    end
    return avataresInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取阿凡达模块数据库信息
    local avataresInfo = unilight.getdata(DB_Name, uid)
    avataresInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,avataresInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,avataresInfo)
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
        boards = gamecommon.CreateSpecialChessData(DataFormat,Avatares['table_115_freespin_'..gameType])
        GmProcess(uid, gameId, gameType, boards)
    else
        -- 普通游戏
        local betInfo = {
            betindex = avataresInfo.betIndex,
            betchips = avataresInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
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
        local addScore = v.mul * avataresInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    -- 遍历中奖线保存W图标位置
    res.iconsAttachData = {}
    for _, v in ipairs(winlines) do
        for index = 1, 3 do
            local icons = {}
            local wFlag = false
            local iconId = v.iconval[index]
            if iconId == W then
                wFlag = true
                -- 适配客户端 需要行列对调
                icons.line = v.winpos[index][2]
                icons.row = v.winpos[index][1]
                for i = 1, 3 do
                    if v.iconval[i] ~= W then
                        icons.icon = v.iconval[i]
                        break
                    end
                end
            end
            if wFlag then
                table.insert(res.iconsAttachData,icons)
            end
        end
    end

    -- 棋盘数据
    res.boards = table.clone(boards)
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    avataresInfo.boards = boards
    res.freeTringerPoints,res.iconsAttachData = GetFree(avataresInfo,isFree,res.iconsAttachData)
    if table.empty(res.iconsAttachData) == false then
        for _, v in ipairs(res.iconsAttachData) do
            avataresInfo.boards[v.row][v.line] = v.icon
        end
    end
    return res
end
-- 判断免费
function GetFree(avataresInfo,isFree,iconsAttachData)
    local ColB = 0
    -- 遍历棋盘判断S个数
    for rowNum = 1, #avataresInfo.boards[1] do
        -- 触发免费位置
        local freeTringerPoints = {}
        local attachData = table.clone(iconsAttachData)
        -- 存在S列的个数
        ColB = 0
        for colNum = 1, #avataresInfo.boards do
            -- 如果这个位置存在B图标 则B列的次数+1 直接跳转下一列
            if avataresInfo.boards[colNum][rowNum] == S then
                -- 适配客户端 需要行列对调
                table.insert(freeTringerPoints,{line = rowNum, row = colNum})
                ColB = ColB + 1
            elseif avataresInfo.boards[colNum][rowNum] == W then
                -- 适配客户端 需要行列对调
                table.insert(freeTringerPoints,{line = rowNum, row = colNum})
                table.insert(attachData,{line = rowNum,row = colNum,icon = S})
                ColB = ColB + 1
            end
        end
        -- 判断是否触发Bonus
        if ColB >= 3 then
            if isFree then
                avataresInfo.free.totalTimes = avataresInfo.free.totalTimes + Table_Other[1].FreeNum
            else
                avataresInfo.free.totalTimes = Table_Other[1].FreeNum
            end
            -- 如果成功触发免费则修改W元素
            return freeTringerPoints,attachData
        end
    end
    -- 没有原样返回
    return {},iconsAttachData
end
-- 包装返回信息
function GetResInfo(uid, avataresInfo, gameType, tringerPoints)
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    avataresInfo = table.clone(avataresInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(avataresInfo.boards) == false then
        boards = {avataresInfo.boards}
    end
    local free = {}
    if avataresInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = avataresInfo.free.totalTimes, -- 总次数
            lackTimes = avataresInfo.free.totalTimes - avataresInfo.free.times, -- 剩余游玩次数
            tWinScore = avataresInfo.free.tWinScore, -- 总共已经赢得的钱
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
        betIndex = avataresInfo.betIndex,
        -- 全部下注金额
        payScore = avataresInfo.betMoney,
        -- 已赢的钱
        -- winScore = avataresInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free},
    }
    return res
end
