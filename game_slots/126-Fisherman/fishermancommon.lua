module('Fisherman', package.seeall)
Table = 'game126fisherman'
LineNum = 10
GameId = 126


J = 100
S = 70
-- Fisherman
-- 构造数据存档
function SetGameMold(uid,demo)
    local Info = unilight.getdata(Table, uid)
    -- 没有则初始化信息
    if table.empty(Info) then
        Info = {
            _id = uid, -- 玩家ID
            demo = demo or 0 ,
            gameRooms = {}, -- 游戏类型
        }
    end
    Info.demo = demo or 0
    unilight.savedata(Table,Info)
end
function GetGameMold(uid)
    local Info = unilight.getdata(Table, uid)
    -- 没有则初始化信息
    if table.empty(Info) then
        Info = {
            _id = uid, -- 玩家ID
            demo = 0,
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(Table,Info)
    end
    return Info.demo or 0 
end
function IsDemo(uid)
    return GetGameMold(uid)  == 1
end
function AddDemoNums(uid)
    local Info = unilight.getdata(Table, uid)
    -- 没有则初始化信息
    if table.empty(Info) then
        dump("noInfo")
        return 
    end 
    Info.demonum =  Info.demonum  and (Info.demonum  + 1 ) or 1
    unilight.savedata(Table,Info)
    if Info.demonum % 50 == 0 then 
        gamecommon.SendGlobalMsgTip(uid,{type = Const.MSGTIP.DEMO})
    end 
end
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(Table,datainfos)
    end
    if gameType == nil then
        return datainfos
    end
     -- 没有初始化房间信息
     local gameType = IsDemo(uid) and gameType*10 or gameType
     if table.empty(datainfos.gameRooms[gameType]) then
        datainfos.gameRooms[gameType] = {
            betindex = 1,
            betMoney = 0,
            free={},            --免费模式
            isInHight=false ,        --是否处于高下注模式 0:不是 1:是
         }
         unilight.update(Table,uid,datainfos)
     end
     return datainfos.gameRooms[gameType]

end

-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取兔子模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local Info = unilight.getdata(Table, uid)
    Info.gameRooms[gameType] = roomInfo
    unilight.update(Table,uid,Info)
end

--购买高中奖率
function BuyHighBet(highLevel,datainfo,gameType,uid)
    datainfo.isInHight = highLevel
    SaveGameInfo(uid, gameType,datainfo)
    return {
        errno = 0,
        isInHight=highLevel,
    }
end


-- 包装返回信息
function GetResInfo(uid, datainfo, gameType)
    -- 克隆数据表
    datainfo = table.clone(datainfo)
    -- 模块信息
    local boards = {}
    if table.empty(datainfo.boards) == false then
        boards = datainfo.boards
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_126_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_126_hanglie[1].linenum),
        -- 下注索引
        betIndex = datainfo.betIndex,
        -- 全部下注金额
        payScore = datainfo.betMoney,
        -- 已赢的钱
        -- winScore = datainfo.winScore,
        winlines = datainfo.winlines,
        -- 面板格子数据
        boards = boards,
        free = packFree(datainfo)
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
        FreeInfo = datainfo.free.FreeInfo,
    }
end

function GetLevelmul(Level)
	if Level == 4 then 
		return 10
	elseif Level ==3 then 
		return 3
	elseif Level == 2 then 
		return 2
	else 
		return 1
	end 
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

function calc_W(boards)
	local sNum = 0
	for col = 1,5 do
		for row = 1,3 do
			local val = boards[col][row]
			if val == W then
				sNum = sNum + 1
			end
		end
	end
	return  sNum 
      
end 

function check_is_to_free(boards)
	local sNum = calc_S(boards)
	return  sNum >= 3
end 

function calc_free_nums(sNum)
    if sNum==3 then
        return 10
    elseif sNum==4 then
        return 15
    elseif sNum==5 then
        return 20
    end
    return 0
end
