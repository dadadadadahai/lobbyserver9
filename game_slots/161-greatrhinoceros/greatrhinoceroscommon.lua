-- 大象游戏模块
module('GreatRhinoceros', package.seeall)
-- 大象所需数据库表名称
DB_Name = "game161GreatRhinoceros"
-- 大象通用配置
GameId = 161
S = 70
W = 90
U = 80
DataFormat = {3,3,3,3,3}    -- 棋盘规格
Table_Base = import "table/game/161/table_161_hanglie"                        -- 基础行列

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
    local GRInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(GRInfo) then
        GRInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,GRInfo)
    end
    if gameType == nil then
        return GRInfo
    end
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 没有初始化房间信息
    if table.empty(GRInfo.gameRooms[gameType]) then
        GRInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
        }
        unilight.update(DB_Name,uid,GRInfo)
    end
    return GRInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取老虎模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local GRInfo = unilight.getdata(DB_Name, uid)
    GRInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,GRInfo)
end


-- 包装返回信息
function GetResInfo(uid, GRInfo, gameType)
    -- 克隆数据表
    GRInfo = table.clone(GRInfo)
    -- 模块信息
    local boards = {}
    if table.empty(GRInfo.boards) == false then
        boards = GRInfo.boards
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_161_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_161_hanglie[1].linenum),
        -- 下注索引
        betIndex = GRInfo.betIndex,
        -- 全部下注金额
        payScore = GRInfo.betMoney,
        -- 已赢的钱
        -- winScore = GRInfo.winScore,
        winlines = GRInfo.winlines,
        -- 面板格子数据
        boards = boards,
        free = packFree(GRInfo)
    }
    return res
end
function packFree(datainfo)
    if table.empty(datainfo.free) then
        return {}
    end
    return{
        totalTimes=datainfo.free.totalTimes,
        lackTimes=datainfo.free.lackTimes,
        tWinScore = datainfo.free.tWinScore,
    }
end
function calc_S(boards)
	local sNum = 0
	for col = 1,5 do
		for row = 1,3 do
			local val = boards[col][row]
			if val == S then
				sNum = sNum + 1
			end
		end
	end
	return  sNum 
      
end 