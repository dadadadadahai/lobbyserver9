-- 生肖龙游戏模块
module('Dragon', package.seeall)
-- 生肖龙所需数据库表名称
DB_Name = "game134dragon"
-- 生肖龙通用配置
GameId = 134
S = 70
W = 90
B = 6
DataFormat = {3,3,3}    -- 棋盘规格
Table_Base = import "table/game/134/table_134_hanglie"                        -- 基础行列
MaxNormalIconId = 6
LineNum = Table_Base[1].linenum
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
    if datainfo.demonum % 5 == 0 then 
        gamecommon.SendGlobalMsgTip(uid,{type = Const.MSGTIP.DEMO})
    end 
end
-- 构造数据存档
function Get(gameType,uid)
    -- 获取生肖龙模块数据库信息
    local dragonInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(dragonInfo) then
        dragonInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,dragonInfo)
    end
    if gameType == nil then
        return dragonInfo
    end
    -- 没有初始化房间信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    if table.empty(dragonInfo.gameRooms[gameType]) then
        dragonInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            mulList = {}, -- 倍数列表
            sumMul = 1, -- 合计倍数
        }
        unilight.update(DB_Name,uid,dragonInfo)
    end
    return dragonInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取生肖龙模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local dragonInfo = unilight.getdata(DB_Name, uid)
    dragonInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,dragonInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,dragonInfo)
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
        betindex = dragonInfo.betIndex,
        betchips = dragonInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    -- 生成异形棋盘
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    local bonusFlag = false
    local firstFlag = false
    -- 随机是否触发福牛模式
    if (not table.empty(dragonInfo.free)) or (math.random(10000) <= table_134_freePro[1].pro) or isFree or GmProcess("Free") then
        bonusFlag = true
        if table.empty(dragonInfo.free) then
            firstFlag = true
            -- 初始化免费数据
            dragonInfo.free = {
                lackTimes = 7,
                totalTimes = 8,
                tWinScore = 0,
            }
        end
        boards = gamecommon.CreateSpecialChessData(DataFormat,Dragon['table_134_free_'..gameType])
    end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_134_payline,table_134_paytable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * dragonInfo.betMoney / table_134_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 每一句初始化倍数
    dragonInfo.mulList = {}
    dragonInfo.sumMul = 1
    -- 随机额外倍数
    if table.empty(dragonInfo.free) then
        -- 普通模式随机
        local mul = table_134_normalMul[gamecommon.CommRandInt(table_134_normalMul, 'pro')].mul
        table.insert(dragonInfo.mulList,mul)
        dragonInfo.sumMul = mul
    else
        -- 特殊模式随机
        local mulInfo = table_134_freeMul[gamecommon.CommRandInt(table_134_freeMul, 'pro')]
        -- 随机显示
        local randomPoints = chessutil.NotRepeatRandomNumbers(1, 3, 3)
        for _, point in ipairs(randomPoints) do
            if mulInfo['mul'..point] > 0 then
                table.insert(dragonInfo.mulList,mulInfo['mul'..point])
            end
        end
        dragonInfo.sumMul = mulInfo.sumMul
    end
    if dragonInfo.sumMul > 0 then
        res.winScore = res.winScore * dragonInfo.sumMul
    end
    if table.empty(dragonInfo.free) == false then
        dragonInfo.free.tWinScore = dragonInfo.free.tWinScore + res.winScore
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    dragonInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.extraData = {
        mulList = dragonInfo.mulList,
        sumMul = dragonInfo.sumMul,
        bonusFlag = bonusFlag,
        firstFlag = firstFlag,
    }
    return res
end

-- 包装返回信息
function GetResInfo(uid, dragonInfo, gameType, tringerPoints)
    -- 克隆数据表
    dragonInfo = table.clone(dragonInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(dragonInfo.boards) == false then
        boards = {dragonInfo.boards}
    end
    local free = {}
    if not table.empty(dragonInfo.free) then
        free = {
            totalTimes = dragonInfo.free.totalTimes, -- 总次数
            lackTimes = dragonInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = dragonInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_134_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_134_hanglie[1].linenum),
        -- 下注索引
        betIndex = dragonInfo.betIndex,
        -- 全部下注金额
        payScore = dragonInfo.betMoney,
        -- 已赢的钱
        -- winScore = dragonInfo.winScore,
        -- 独立调用定义
        features={free = free},
        -- 面板格子数据
        boards = boards,
        extraData = {
            mulList = dragonInfo.mulList,
            sumMul = dragonInfo.sumMul,
        }
    }
    return res
end

function packFree(datainfo)
    if table.empty(datainfo.free) then
        return {}
    end
    return{
        totalTimes=8,
        lackTimes=datainfo.free.lackTimes,
        tWinScore = datainfo.free.tWinScore,
    }
end