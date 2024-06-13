-- 老虎游戏模块
module('diamond', package.seeall)
-- 老虎所需数据库表名称
DB_Name = "game163diamond"
-- 老虎通用配置
GameId = 163
S = 70
W = 90

DataFormat = {3,3,3,3,3}    -- 棋盘规格
Table_Base = import "table/game/163/table_163_hanglie"                        -- 基础行列
LineNum = Table_Base[1].linenum
-- 构造数据存档
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
    -- 获取老虎模块数据库信息
    local diamondInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(diamondInfo) then
        diamondInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,diamondInfo)
    end
    if gameType == nil then
        return diamondInfo
    end
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 没有初始化房间信息
    if table.empty(diamondInfo.gameRooms[gameType]) then
        diamondInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
        }
        unilight.update(DB_Name,uid,diamondInfo)
    end
    return diamondInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取老虎模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local diamondInfo = unilight.getdata(DB_Name, uid)
    diamondInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,diamondInfo)
end


-- 包装返回信息
function GetResInfo(uid, diamondInfo, gameType)
    -- 克隆数据表
    diamondInfo = table.clone(diamondInfo)
    -- 模块信息
    local boards = {}
    if table.empty(diamondInfo.boards) == false then
        boards = diamondInfo.boards
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_163_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_163_hanglie[1].linenum),
        -- 下注索引
        betIndex = diamondInfo.betIndex,
        -- 全部下注金额
        payScore = diamondInfo.betMoney,
        -- 已赢的钱
        -- winScore = diamondInfo.winScore,
        winlines = diamondInfo.winlines,
        -- 面板格子数据
        boards = boards,
    }
    return res
end