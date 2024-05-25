module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

J = 100
S = 70
-- fruitparty2
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
    if Info.demonum % 5 == 0 then 
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


function calcSMul(sNum)
    if sNum==3 then
        return 6
    elseif sNum==4 then
        return 10
    elseif sNum==5 then
        return 20
	elseif sNum==6 then
		return 40
	elseif sNum==7 then
		return 200
    end
    return 0
end

function CalcFreeNum(sNum)
    if sNum==3 then
        return 10
    elseif sNum==4 then
        return 12
    elseif sNum==5 then
        return 15
	elseif sNum==6 then
		return 20
	elseif sNum==7 then
		return 25
    end
    return 0
end
