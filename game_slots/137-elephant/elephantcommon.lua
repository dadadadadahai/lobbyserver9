-- 大象游戏模块
module('Elephant', package.seeall)
-- 大象所需数据库表名称
DB_Name = "game137elephant"
-- 大象通用配置
GameId = 137
S = 70
W = 90
U = 80
DataFormat = {3,3,3,3,3}    -- 棋盘规格
Table_Base = import "table/game/137/table_137_hanglie"                        -- 基础行列
MaxNormalIconId = 6
NeedAddWildNum = 3          -- 免费中需要收集W个数
OneAddWildMul = 2           -- 免费中每次收集满增加倍数
MaxWildMul = 20             -- 免费中最多收集倍数上限
LineNum = Table_Base[1].linenum
-- 构造数据存档
function SetGameMold(uid,demo)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        datainfo = {
            _id = uid, -- 玩家ID
            demo = demo or 0 ,
            gameRooms = {}, -- 游戏类型
        }
    end
    datainfo.demo = demo or 0
    unilight.savedata(DB_Name,datainfo)
end
function GetGameMold(uid)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        datainfo = {
            _id = uid, -- 玩家ID
            demo = 0,
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,datainfo)
    end
    return datainfo.demo or 0 
end
function IsDemo(uid)
    return GetGameMold(uid)  == 1
end
function AddDemoNums(uid)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        dump("nodatainfo")
        return 
    end 
    datainfo.demonum =  datainfo.demonum  and (datainfo.demonum  + 1 ) or 1
    unilight.savedata(DB_Name,datainfo)
    if datainfo.demonum % 50 == 0 then 
        gamecommon.SendGlobalMsgTip(uid,{type = Const.MSGTIP.DEMO})
    end 
end

function Get(gameType,uid)
    -- 获取大象模块数据库信息
    local elephantInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(elephantInfo) then
        elephantInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,elephantInfo)
    end
    if gameType == nil then
        return elephantInfo
    end
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 没有初始化房间信息
    if table.empty(elephantInfo.gameRooms[gameType]) then
        elephantInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            -- iconsAttachData = {}, -- 附加数据
        }
        unilight.update(DB_Name,uid,elephantInfo)
    end
    return elephantInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取大象模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local elephantInfo = unilight.getdata(DB_Name, uid)
    elephantInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,elephantInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,elephantInfo)
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
        betindex = elephantInfo.betIndex,
        betchips = elephantInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }

    if isFree then
        boards = gamecommon.CreateSpecialChessData(DataFormat,Elephant['table_137_free'])
    else
        -- 生成异形棋盘
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    end

    -- 计算中奖倍数
    local winPoints,winMuls  = gamecommon.SpecialAllLineFinal(boards,wilds,nowild,Table_PayTable)
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winPoints = {}
    res.winPoints[1] = winPoints

    local wMul = 1
    res.tringerPoints.wildPoints = {}
    if isFree then
        local wNum = 0
        -- 统计W个数
        for col = 1, #boards do
            for row = 1, #boards[col] do
                if boards[col][row] == W then
                    table.insert(res.tringerPoints.wildPoints,{line = col, row = row})
                    wNum = wNum + 1
                end
            end
        end
        elephantInfo.free.wildNum = elephantInfo.free.wildNum + wNum
        -- 根据W个数匹配倍数
        wMul = math.floor(elephantInfo.free.wildNum / NeedAddWildNum) * OneAddWildMul
        -- 保底1倍
        if wMul == 0 then
            wMul = 1
        end
        if wMul > MaxWildMul then
            wMul = MaxWildMul
        end
    end

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    res.extraData = {}
    res.extraData.winEle = {}
    -- 计算中奖线金额
    local mul = 1
    for i, v in ipairs(winMuls) do
        if v.ele ~= S then
            res.winScore = res.winScore + v.mul * elephantInfo.betMoney / Table_Base[1].linenum
            
            res.extraData.winEle[v.ele] = res.extraData.winEle[v.ele] or 0
            res.extraData.winEle[v.ele] = res.extraData.winEle[v.ele] + v.mul * elephantInfo.betMoney / Table_Base[1].linenum
        else
            res.winScore = res.winScore + v.mul * elephantInfo.betMoney

            res.extraData.winEle[v.ele] = res.extraData.winEle[v.ele] or 0
            res.extraData.winEle[v.ele] = res.extraData.winEle[v.ele] + v.mul * elephantInfo.betMoney
        end
    end
    res.winScore = res.winScore * wMul
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    elephantInfo.boards = boards
    if not isFree then
        -- 判断是否中Free
        res.tringerPoints.freeTringerPoints = GetFree(elephantInfo)
    end
    -- 棋盘数据
    res.boards = boards
    -- 棋盘附加数据
    -- res.iconsAttachData = elephantInfo.iconsAttachData
    res.winMuls = winMuls
    return res
end

-- 判断是否触发免费
function GetFree(elephantInfo)
    local sNum = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 统计S个数
    for col = 1, #elephantInfo.boards do
        for row = 1, #elephantInfo.boards[col] do
            if elephantInfo.boards[col][row] == S then
                table.insert(freeTringerPoints,{line = col, row = row})
                sNum = sNum + 1
            end
        end
    end

    for i, sNumInfo in ipairs(table_137_freenum) do
        if sNum == sNumInfo.sNum then
            elephantInfo.free = {
                totalTimes = sNumInfo.freeNum,
                lackTimes = sNumInfo.freeNum,
                tWinScore = 0,
                wildNum = 0,
            }
            break
        end
    end
    return freeTringerPoints
end

-- 包装返回信息
function GetResInfo(uid, elephantInfo, gameType, tringerPoints)
    -- 克隆数据表
    elephantInfo = table.clone(elephantInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(elephantInfo.boards) == false then
        boards = {elephantInfo.boards}
    end
    local free = {}
    if not table.empty(elephantInfo.free) then
        free = {
            totalTimes = elephantInfo.free.totalTimes, -- 总次数
            lackTimes = elephantInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = elephantInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
            wildPoints = {tringerPoints.wildPoints} or {},
            wildNum = elephantInfo.free.wildNum,
            wMul = elephantInfo.free.wMul,
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_137_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_137_hanglie[1].linenum),
        -- 下注索引
        betIndex = elephantInfo.betIndex,
        -- 全部下注金额
        payScore = elephantInfo.betMoney,
        -- 已赢的钱
        -- winScore = elephantInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = elephantInfo.iconsAttachData,
        -- 独立调用定义
        features={free = free},
    }
    return res
end