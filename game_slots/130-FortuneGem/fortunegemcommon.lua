-- 财富宝石游戏模块
module('FortuneGem', package.seeall)
-- 财富宝石所需数据库表名称
DB_Name = "game130fortunegem"
-- 财富宝石通用配置
GameId = 130
S = 70
W = 90
B = 6
DataFormat = {3,3,3}    -- 棋盘规格
Table_Base = import "table/game/130/table_130_hanglie"                        -- 基础行列
MaxNormalIconId = 10
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取财富宝石模块数据库信息
    local fortunegemInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(fortunegemInfo) then
        fortunegemInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,fortunegemInfo)
    end
    if gameType == nil then
        return fortunegemInfo
    end
    -- 没有初始化房间信息
    if table.empty(fortunegemInfo.gameRooms[gameType]) then
        fortunegemInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            BuyFreeNumS = 0, -- 是否购买免费:购买出来的免费图标个数
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,fortunegemInfo)
    end
    return fortunegemInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取财富宝石模块数据库信息
    local fortunegemInfo = unilight.getdata(DB_Name, uid)
    fortunegemInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,fortunegemInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isAdditional,fortunegemInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    -- 普通游戏
    local betInfo = {
        betindex = fortunegemInfo.betIndex,
        betchips = fortunegemInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))

    -- GmProcess(uid, gameId, gameType, boards)

    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_130_payline,table_130_paytable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * fortunegemInfo.betMoney / table_130_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 权重判断
    local proString = 'pro'
    if isAdditional then
        proString = 'additionalPro'
    end
    -- 按权重随机出对应配置
    local rottleConfig = table_130_rottleConfig[gamecommon.CommRandInt(table_130_rottleConfig, proString)]
    -- 增加获奖金额
    res.winScore = res.winScore * rottleConfig.mul
    fortunegemInfo.iconsAttachData = {iconId = rottleConfig.iconId,mul = rottleConfig.mul}
    -- 组装最后一列棋盘
    GetLastColBoards(boards,fortunegemInfo.iconsAttachData,proString)
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    fortunegemInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    -- 棋盘附加数据
    res.iconsAttachData = fortunegemInfo.iconsAttachData
    return res
end

-- 生成最后一列棋盘
function GetLastColBoards(boards,iconsAttachData,proString)
    -- 按权重随机出对应配置
    local firstRowRottleConfig = table_130_rottleConfig[gamecommon.CommRandInt(table_130_rottleConfig, proString)]
    local lastRowRottleConfig = table_130_rottleConfig[gamecommon.CommRandInt(table_130_rottleConfig, proString)]
    -- 组成棋盘
    local colInfo = {firstRowRottleConfig.iconId,iconsAttachData.iconId,lastRowRottleConfig.iconId}
    table.insert(boards,colInfo)
end

-- 包装返回信息
function GetResInfo(uid, fortunegemInfo, gameType, tringerPoints)
    -- 克隆数据表
    fortunegemInfo = table.clone(fortunegemInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(fortunegemInfo.boards) == false then
        boards = {fortunegemInfo.boards}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_130_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_130_hanglie[1].linenum),
        -- 下注索引
        betIndex = fortunegemInfo.betIndex,
        -- 全部下注金额
        payScore = fortunegemInfo.betMoney,
        -- 已赢的钱
        -- winScore = fortunegemInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = fortunegemInfo.iconsAttachData,
    }
    return res
end