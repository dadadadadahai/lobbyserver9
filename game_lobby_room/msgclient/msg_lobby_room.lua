local table_game_list = import "table/table_game_list"
-- 查看当前正常连接的游戏服列表
Net.CmdGetNormalGameListRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	if cmd.data == nil or cmd.data.lobbyId == nil then
		RoomInfo.SendFailToUser("参数有误",laccount)
		RoomInfo.SendCmdToUser("Cmd.GetNormalGameListRoomCmd_S",{resultCode = 1},laccount)		
		return
	end

	local gameIdList = RoomInfo.GetNormalGameList(cmd.data.lobbyId, cmd.data.typ)
	-- local lastCreate = RoomInfo.GetLastCreate(cmd.data.lobbyId, uid)
	local data = {
		gameIdList = gameIdList,
		-- lastCreate = lastCreate
	}
	RoomInfo.SendCmdToUser("Cmd.GetNormalGameListRoomCmd_S", data, laccount)
end

-- 获取合适的练习场(同样需要通知游戏服准备好 然后等待回调)
Net.CmdGetPracticeGameInfoRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	if cmd.data == nil or cmd.data.lobbyId == nil then
		RoomInfo.SendFailToUser("参数有误",laccount)
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.ERROR_PARAM, desc= "参数有误"},laccount)		
		return
	end

	local lobbyId = cmd.data.lobbyId
	local lobbyTableInfo = table_game_list[lobbyId]
	if lobbyTableInfo == nil then
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.ERROR_PARAM, desc= "参数有误"},laccount)		
		return
	end
    local chips = chessuserinfodb.RUserChipsGet(uid)
    if chips <  lobbyTableInfo.limitLow then
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.CHIPS_NOT_ENOUGH, desc= "参数有误"},laccount)		
		return
    end

	-- 检测玩家当前是否已有所属房间 
	local preRoom = RoomInfo.GetRoomByLobbyIdUid(lobbyId, uid)
	if preRoom ~= nil then
		RoomInfo.SendFailToUser("当前已有所属房间,直接进入已有房间",laccount)
		-- 返回房间如果返回码为0 则表示游戏服并未准备好 需要等待游戏服回调回来 再处理
		local ret, gameId, zoneId, roomId, globalRoomId, shareInfo = RoomInfo.ReturnRoom(laccount, lobbyId)
		if ret ~= 0 then
			local data = {
				resultCode 	= ret,
				gameId 		= gameId,
				zoneId 		= zoneId,
				roomId 		= roomId,
				globalRoomId= globalRoomId,
				shareInfo 	= shareInfo,
			}
			RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S",data,laccount)
		end
		return
	end

	-- local level = cmd.data.level
	-- -- 如果表格中存在初中高 代表需要赌钻 如果前端没传 则默认使用第一个
	-- if table.empty(lobbyTableInfo.exerciseList) == false then
	-- 	level = level or 1
	-- 	if lobbyTableInfo.exerciseList[level] == nil then
	-- 		RoomInfo.SendFailToUser("参数有误",laccount)
	-- 		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = 2, desc = "参数有误"},laccount)		
	-- 		return			
	-- 	end		
	-- end

	-- 江西客家定时开放
	-- local ret = OpenPrac.CheckOpenPrac(lobbyId)
	-- if ret == false then
	-- 	RoomInfo.SendFailToUser("匹配场当前时间段暂不开放",laccount)
	-- 	RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{resultCode = 4},laccount)		
	-- 	return			
	-- end
	
	-- 往上提 不需要读两次mongo
	local userData = RoomInfo.GetUserDataForZone(uid)
	-- 如果当前练习场赌钻 则检测玩家钻石
	if level ~= nil then
		-- if userData.mahjong.diamond < RoomInfo.DIAMOND_LIMIT then
		-- 	RoomInfo.SendFailToUser("练习场赌钻 需要钻石" .. RoomInfo.DIAMOND_LIMIT .. "以上",laccount)
		-- 	RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S", {resultCode=3}, laccount)
		-- 	return			
		-- end 

		-- if userData.mahjong.diamond < lobbyTableInfo.exerciseList[level].minLimit then
		-- 	RoomInfo.SendFailToUser("练习场赌钻 当前钻石不允许进入该场次")
		-- 	RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S", {errno=3, desc = "当前钻石不允许进入该场次"}, laccount)
		-- 	return				
		-- end
	end

	local ret, gameId, zoneId = RoomInfo.IntoPracticeRoom(laccount, lobbyId, lobbyTableInfo.gameId)
	if ret ~= nil then
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S", {errno=ret, desc = "没有合适的区服"}, laccount)
		return
	end

	--构造房间默认参数
	cmd.data.lobbyId 	= cmd.data.lobbyId or 0
	cmd.data.gameId 	= gameId
	cmd.data.gameNbr 	= cmd.data.gameNbr or 0
	cmd.data.userNbr 	= cmd.data.userNbr or 0		-- 
	cmd.data.payType 	= cmd.data.payType or 1		-- 支付没传 默认房主支付
	cmd.data.hostTip 	= cmd.data.hostTip or 1		-- 房主小费没传 默认为1
	cmd.data.outTime    = 15 						-- 操作时间
	cmd.data.props      = {} 						-- 房间其余参数

	--是否创建房间
	if lobbyTableInfo.bCreateRoom == 1 then
		-- 创建房间
		local room = RoomInfo.CreateRoom(cmd, uid, true)

		-- 成功获取合适的练习场后 等待回调
		local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(gameId,zoneId)
		-- local data = {
		-- 	uid = uid,
		-- 	roomId = 0,
		-- 	userData = table2json(userData),
		-- 	userDataList = {table2json(userData)},
		-- 	flag 	 = RoomInfo.ENUM_CREATE_FLAG.PRACT,
		-- }

		local data = {
			uid = uid,
			roomId = room.id,
			roomData = table2json(room.data),
			userData = table2json(userData),
			userDataList = {table2json(userData)},
			flag 	 = RoomInfo.ENUM_CREATE_FLAG.PRACT,
		}

		-- 填充其他相关数据
		RoomInfo.FillOtherToCreateRoomData(data, 1, lobbyTableInfo)

		zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
	else
		--不创建房间直接返回合适的服务器地址


		local data = {
			errno       = 0,
			desc        = "sucess",
			gameId 		= gameId,
			zoneId 		= zoneId,
			roomId 		= 0,
			globalRoomId	= 0,
			lobbyId     = cmd.data.lobbyId,
		}
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S", data, laccount)
	end
end

-- 创建房间
Net.CmdCreateRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	if cmd.data == nil or cmd.data.lobbyId == nil or cmd.data.gameId == nil or cmd.data.gameNbr == nil then
		RoomInfo.SendFailToUser("参数有误,lobbyId和gameId都不能为空",laccount)
		RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S",{resultCode = 1},laccount)
		return 
	end
	cmd.data.lobbyId 	= cmd.data.lobbyId or 0
	cmd.data.gameId 	= cmd.data.gameId or 0
	cmd.data.gameNbr 	= cmd.data.gameNbr or 0
	cmd.data.userNbr 	= cmd.data.userNbr or 0		-- 
	cmd.data.payType 	= cmd.data.payType or 1		-- 支付没传 默认房主支付
	cmd.data.hostTip 	= cmd.data.hostTip or 1		-- 房主小费没传 默认为1

	-- 检测玩家当前是否已有所属房间 
	local preRoom = RoomInfo.GetRoomByLobbyIdUid(cmd.data.lobbyId, uid)
	if preRoom ~= nil then
		RoomInfo.SendFailToUser("当前已有所属房间,直接进入已有房间",laccount)
		-- 返回房间如果返回码为0 则表示游戏服并未准备好 需要等待游戏服回调回来 再处理
		local ret, gameId, zoneId, roomId, globalRoomId, shareInfo = RoomInfo.ReturnRoom(laccount, cmd.data.lobbyId)
		if ret ~= 0 then
			local data = {
				resultCode 	= ret,
				gameId 		= gameId,
				zoneId 		= zoneId,
				roomId 		= roomId,
				globalRoomId= globalRoomId,
				shareInfo 	= shareInfo,
			}
			RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S",data,laccount)
		end
		return
	end

	-- 玩家数据获取上移
	local userData = RoomInfo.GetUserDataForZone(uid, cmd.data)

	-- 如果当前赌钻 则检测玩家钻石（暂时没有需要 false忽略）
	if false then
		if userData.mahjong.diamond < RoomInfo.DIAMOND_LIMIT then
			RoomInfo.SendFailToUser("赌钻 需要钻石" .. RoomInfo.DIAMOND_LIMIT .. "以上",laccount)
			RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S", {resultCode=2}, laccount)
			return			
		end 
	end

	-- 校验参数是否有误 如果正确 则分配一个最合适的区服回来
	local ret, zoneId = RoomInfo.CheckCreateRoomPara(cmd,laccount)
	if ret ~= 0 then
		RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S",{resultCode = ret},laccount)
		return
	end

	-- local isFree = FreeGame.CheckInFreeGameTime(cmd.data.lobbyId, uid, cmd.data.gameId, cmd.data.userNbr)
	local isFree = true
	-- 不免费的情况下 才去判断扣费
	if isFree ~= true then
		if go.getconfigint("zone_type") == 4 then
			-- 检测钻石是否足够加入该类房间 
			local ret = UserInfo.CheckRoomCost(uid, cmd.data.userNbr, cmd.data.gameNbr, cmd.data.payType, nil, true, cmd.data.lobbyId)
			if ret == false then             
				if cmd.data.lobbyId == 7 then
					RoomInfo.SendFailToUser("房卡不足 请充值后再次尝试",laccount)
				else        
					RoomInfo.SendFailToUser("钻石不足 请充值后再次尝试",laccount)
				end
				RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S",{resultCode = 10},laccount)
				return
			end
		else
			unilight.error("服务器有bug 暂时麻将大厅还没考虑房卡模式:"..uid .. ":" .. cmd.data.gameId)
			return 
		end
	end

	-- 创建房间
	local room = RoomInfo.CreateRoom(cmd, uid, isFree)
	local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(cmd.data.gameId,zoneId)

	-- 最佳区服缓存起来 
	room.state.zoneInfo = zoneInfo

	local data = {
		uid = uid,
		roomId = room.id,
		roomData = table2json(room.data),
		userData = table2json(userData),
		userDataList = {table2json(userData)},
		flag 	 = RoomInfo.ENUM_CREATE_FLAG.CREATE,
	}

	local lobbyTableInfo = TableLobbyGameList[cmd.data.lobbyId]
	RoomInfo.FillOtherToCreateRoomData(data, 2, lobbyTableInfo)

	zoneInfo:SendCmdToMe("Cmd.CreateRoomRoomLobbyCmd_S",data)
end

-- 返回房间
Net.CmdReturnRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	if cmd.data == nil then
		RoomInfo.SendFailToUser("返回房间参数有误 lobbyId 为nil",laccount)
		RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S",{resultCode = 1},laccount)
		return 
	end	

	local lobbyId = cmd.data.lobbyId
	-- 返回房间如果返回码为0 则表示游戏服并未准备好 需要等待游戏服回调回来 再处理
	local ret, gameId, zoneId, roomId, globalRoomId, shareInfo = RoomInfo.ReturnRoom(laccount, lobbyId)
	-- 大于0代表有误 为nil代表直接正确回去 不需要等游戏服回调
	if ret ~= 0 then
		local data = {
			resultCode 		= ret,
			gameId 			= gameId,
			zoneId 			= zoneId,
			roomId 			= roomId,
			globalRoomId 	= globalRoomId,
			shareInfo 		= shareInfo,
		}
		RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S",data,laccount)
	end
end
	
-- 加入房间
Net.CmdEnterRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.roomId == nil then
		RoomInfo.SendFailToUser("参数有误",laccount)
		RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S",{resultCode = 1},laccount)
		return
	end

	local ret, gameId, zoneId, roomId, globalRoomId, shareInfo = RoomInfo.EnterRoom(laccount, cmd.data.roomId)
	-- 大于0代表有误 为nil代表直接正确回去 不需要等游戏服回调
	if ret ~= 0 then
		local data = {
			resultCode 		= ret,
			gameId 			= gameId,
			zoneId 			= zoneId,
			roomId 			= roomId,
			globalRoomId 	= globalRoomId,
			shareInfo 		= shareInfo,
		}
		RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S",data,laccount)
	end
end

-- 请求续局
Net.CmdApplyContinuePlayRoomCmd_C = function(cmd, laccount)
	local ret = RoomInfo.ApplyContinuePlay(laccount)
	if ret ~= 0 then
		local data = {
			resultCode = ret,
		}
		RoomInfo.SendCmdToUser("Cmd.ApplyContinuePlayRoomCmd_S",data,laccount)
	end
end

-- 请求录像
Net.CmdRequestRecordLobbyCmd_C = function(cmd, laccount)
	local globalRoomId 	= cmd.data.globalRoomId
	local roomId 		= cmd.data.roomId
	local curGameNbr 	= cmd.data.curGameNbr or 1
	local roomData 		= nil

	-- 如果不传唯一id 就自己去找
	if globalRoomId == nil then
		if roomId ~= nil then
 			local info = unilight.chainResponseSequence(unilight.startChain().Table("globalroomdata").Filter(unilight.eq("roomid", roomId)).OrderBy(unilight.desc("createtime")).Limit(1))
			roomData = info[1]
			globalRoomId = roomData.globalroomid
		end
	else
		roomData = RoomInfo.GetGlobalRoomData(globalRoomId)
	end

	if roomData == nil then
		RoomInfo.SendFailToUser("该房间回放记录已过期!",laccount)
		RoomInfo.SendCmdToUser("Cmd.ReturnRecordLobbyCmd_S",{resultCode=1},laccount)
		return
	end

	local record = laccount.GetRecord(globalRoomId..":"..curGameNbr)
	if record == nil or record == "" then
		RoomInfo.SendFailToUser("该房间回放记录已过期!",laccount)
		RoomInfo.SendCmdToUser("Cmd.ReturnRecordLobbyCmd_S",{resultCode=2},laccount)
		return		
	end

	-- 主视角获取
	local uid = laccount.Id
	if roomData.history.position[uid] == nil then
		uid = roomData.owner
		if roomData.history.position[uid] == nil and roomData.history.statistics[1] ~= nil then
			uid = roomData.history.statistics[1].uid
		end
	end
	if uid == nil then
		RoomInfo.SendFailToUser("该房间回放记录已过期!",laccount)
		RoomInfo.SendCmdToUser("Cmd.ReturnRecordLobbyCmd_S",{resultCode=3},laccount)
		return			
	end

	local data = {
		data 	= record,
		gameId 	= roomData.gameid,
		uid 	= uid,
	}
	RoomInfo.SendCmdToUser("Cmd.ReturnRecordLobbyCmd_S",data,laccount, true)
end

