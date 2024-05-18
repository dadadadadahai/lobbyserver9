local zoneKey = go.config().GetConfigStr("zone_key")
local gameId = tonumber(string.split(zoneKey, ":")[1])
GameId = "G"..gameId
NUMBER_GAMEID = gameId
module('BenChiBaoMaInitMgr', package.seeall)

--数据库初始化
function DBReady()
	unilight.info("奔驰宝马初始化数据库调用")

	unilight.createdb("chehangrankctr", "_id") 	-- 用于控制车行排行榜啥时候开启
	unilight.createdb("chehangrank", "key")		-- 车行排行榜
end

--服务器启动后要做的事
function StartOver()
	unilight.info("奔驰宝马启动调用")
	-- 处理 数据库配置表
	ZONETYPE = go.getconfigint("zone_type")

	-- 房间配置信息(纯利、抽水、彩金   默认抽水 0.02)
	chessroominfodb.InitUnifiedRoomInfoDb(go.gamezone.Gameid, 0, nil, nil, nil, nil, 0, 0.02)

	-- 表格处理一下
	LotteryCtl.Init()

	-- 机器人相关信息 初始化(在房间初始化之前)
	RobotMgr.Init()
	
	-- 房间数据 初始化 
	RoomMgr.Init()

	-- 初始化上庄相关内容
	BankerRoomMgr.Init()

	-- 获取该游戏服的区id
	ZoneId = go.gamezone.Zoneid

end


--服务器关闭后要做的事
function StopOver()
	unilight.info("奔驰宝马服务器关闭调用")
end

--处理玩家掉线的情况
function AccountDisconnect(roomuser)
	if roomuser == nil then
		unilight.error("调用断线 但是roomuser为nil")
		return 
	end
	local uid = roomuser.Id
	local roomId = RoomMgr.GetRoomId(uid)
	if roomId ~= nil then
		-- 如果是庄家掉线当前 不申请下庄
		if RoomMgr.IsBanker(uid) == false then
			RoomMgr.CancelBanker(uid)
		end
		-- 当前从游戏中断开 
		local ret = RoomMgr.LeaveRoom(uid, true)
	else
		-- 当前从选场回去（暂时不存在选场 先放着） 置空大厅监控信息
		local userData = UserInfo.GetUserDataById(uid)
		IntoGameMgr.ClearUserCurStatus(userData)
	end
end

--初始化定时器
function InitTimer()
	unilight.info("初始化定时器")
end