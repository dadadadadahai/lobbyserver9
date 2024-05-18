-- 用于解析 游戏服 通知大厅的消息

-- 用于打印日志map (后续新增游戏内扣费项 则下面两个均需添加)
MapDiamondChangeTypeStr = {"钻石输赢", "喇叭扣费", "送花扣费", "练习场扣费", "比赛场输赢"}
MapDiamondChangeType 	= {
	ItemStatistics.ENUM_STATIC_TYPE.GBL,
	ItemStatistics.ENUM_STATIC_TYPE.SNA,
	ItemStatistics.ENUM_STATIC_TYPE.FLW,
	ItemStatistics.ENUM_STATIC_TYPE.PRA,
	ItemStatistics.ENUM_STATIC_TYPE.MTC,
}

-- 游戏服准备就绪 通知大厅
Zone.CmdCreateRoomRoomLobbyCmd_C= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdCreateRoomRoomLobbyCmd_C:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId()..", cmd="..table2json(cmd))
	local laccount = go.accountmgr.GetAccountById(cmd.data.uid)

	-- ret 如果为非0数字 则表示有误
	if (cmd.data.ret ~= nil and cmd.data.ret ~= 0) or cmd.data.desc then
		RoomInfo.SendFailToUser(cmd.data.desc,laccount)
		if cmd.data.uid ~= nil and cmd.data.roomId ~= nil and cmd.data.desc ~= nil then
			unilight.error("游戏服创建房间后回调 返回错误:"..cmd.data.uid .. ":" .. cmd.data.roomId .. ":" .. cmd.data.desc)
		else
			unilight.error("游戏服创建房间后回调 返回错误:")
		end
		return
	end

	-- 如果为练习场 可能返回值不存在roomId
	if cmd.data.flag == RoomInfo.ENUM_CREATE_FLAG.PRACT then
		local room = RoomInfo.GetRoomInfoById(cmd.data.roomId)
		local data = {
			errno       = 0,
			desc        = "sucess",
			gameId 		= zonetask.GetGameId(),
			zoneId 		= zonetask.GetZoneId(),
			roomId 		= room.id,
			globalRoomId	= room.data.globalroomid,
			lobbyId     = room.data.lobbyId,
		}
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S", data, laccount)	
	else
		if cmd.data.uid == nil or cmd.data.roomId == nil then
			unilight.error("游戏服创建房间后回调 返回参数错误")
			return
		end

		local room = RoomInfo.GetRoomInfoById(cmd.data.roomId)
		if room == nil then
			RoomInfo.SendFailToUser("游戏服创建房间后回调 返回时发现房间不存在了",laccount)
			unilight.error("游戏服创建房间后回调 返回时发现房间不存在了"..cmd.data.uid .. ":" .. cmd.data.roomId)
			return
		end

		room.state.zoneInfo = ZoneInfo.GlobalZoneInfoMap[zonetask.GetId()]

		local data = {
			gameId 		= room.data.gameId,
			zoneId 		= zonetask.GetZoneId(),
			roomId 		= room.id,
			globalRoomId	= room.data.globalroomid,
			-- shareInfo 	= ShareMgr.GetShareInfoByRoom(room, nil, cmd.data.uid)
		}
		print("CmdCreateRoomRoomLobbyCmd_C roomdata="..table2json(room.data))
		if cmd.data.flag == RoomInfo.ENUM_CREATE_FLAG.CREATE then
			RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S", data, laccount)
		elseif cmd.data.flag == RoomInfo.ENUM_CREATE_FLAG.RETURN then
			RoomInfo.SendCmdToUser("Cmd.ReturnRoomCmd_S", data, laccount)
		elseif cmd.data.flag == RoomInfo.ENUM_CREATE_FLAG.ENTER then
			RoomInfo.SendCmdToUser("Cmd.EnterRoomCmd_S", data, laccount)
		elseif cmd.data.flag == RoomInfo.ENUM_CREATE_FLAG.CONTINUE then
			RoomInfo.SendCmdToUser("Cmd.CreateRoomCmd_S", data, laccount)

			-- 如果是续局操作 则 需要广播给其他玩家数据
			local userData = UserInfo.GetUserDataById(cmd.data.uid)
			local preGlobalRoomData = RoomInfo.GetGlobalRoomData(userData.mahjong.play[#userData.mahjong.play])
			-- 给其他玩家发送 是否加入新房间 
			for otherUid,_ in pairs(preGlobalRoomData.history.position) do
				if otherUid ~= preGlobalRoomData.owner then
					-- 检测是否已经在其他正常房间了
					local preRoom = RoomInfo.GetRoomByLobbyIdUid(preGlobalRoomData.lobbyId, otherUid)
					if preRoom == nil then
						-- 没有合适房间的玩家 则给其推送
						local otherAccount = go.accountmgr.GetAccountById(otherUid)
						if otherAccount ~= nil then
							local info = {
								roomId = room.id,
								owner  = userData.base.nickname
							}
							unilight.info("owner: " .. cmd.data.uid .. " 给玩家 uid:" .. otherUid .. " 发送续局请求")
							RoomInfo.SendCmdToUser("Cmd.ApplyContinuePlayRoomCmd_Brd",info,otherAccount)
						end
					end
				end
			end
		end
	end
end

-- 有玩家进入房间
Zone.CmdSendEnterRoomLobbyCmd_C= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdSendEnterRoomLobbyCmd_C:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	local res = {}
	res["do"] = "Cmd.SendEnterRoomLobbyCmd_S"
	res["data"] = {
		uid = cmd.data.uid
	}

	if cmd.data == nil or cmd.data.roomId == nil or cmd.data.uid == nil or cmd.data.pos == nil then
		local desc = "玩家进入房间数据有误"
		unilight.error(desc)
		res.data.ret 	= 1
		res.data.desc 	= desc
		return res
	end

	local roomId 	= cmd.data.roomId
	local uid 		= cmd.data.uid
	local pos 		= cmd.data.pos

	local room = RoomInfo.GetRoomInfoById(roomId)
	if room == nil then
		local desc = "玩家进入房间 当前正常运行的房间 不存在该房间：" .. roomId
		unilight.info(desc)
		res.data.ret 	= 2
		res.data.desc 	= desc
		return res
	end

	if room.state.zoneInfo == nil then
		room.state.zoneInfo = ZoneInfo.GlobalZoneInfoMap[zonetask.GetId()]
	else
		if room.state.zoneInfo.zoneid ~= zonetask.GetZoneId() then
			local desc = "该玩家进入区服不对 应该为:" .. room.state.zoneInfo.zoneid .. "实际为:" .. zonetask.GetZoneId()
			unilight.info(desc)
			res.data.ret 	= 3
			res.data.desc 	= desc
			return res
		end
	end

	local len = table.len(room.data.history.position)

	-- 房间内座位不够了
	if len >= room.data.usernbr then
		if room.data.history.position[uid] == nil then
			local desc = "房间人数已满：" .. roomId
			unilight.info(desc)
			res.data.ret 	= 4
			res.data.desc 	= desc
			return res		
		end
	else
		if room.data.history.position[uid] == nil then
			-- 新人进去 

			-- 玩家房间缓存添加
			RoomInfo.SetMapUid2RommData(room.data.lobbyId, uid, room)

			-- room 人数改变
			room.data.history.position[uid] = pos
			len = len + 1

			-- 如果满人 且未扣过钱 则扣钱吧 （这里暂时没有考虑异常情况 正常是不会出现钱扣不到的）
			if room.data.isfree ~= true and room.data.hasDecrease == nil and len == room.data.usernbr and room.data.paytype ~= 3 then
				RoomInfo.DeductRoomCharge(room)
			end
		end
	end

	-- 如果当前已满人 则检测 房主是否在其中 如果不在 则其可以继续创建房间了
	if len == room.data.usernbr and room.data.sendcancreate ~= true then
		if room.data.history.position[room.data.owner] == nil then
			local userData = UserInfo.GetUserDataById(room.data.owner)
			local laccount = go.accountmgr.GetAccountById(room.data.owner)
			if laccount ~= nil then
				local data = {
					roomId 	= roomId,
					diamond = userData.mahjong.diamond,
				}
				RoomInfo.SendCmdToUser("Cmd.CanCreateRoomCmd_Brd",data,laccount)
				unilight.info("玩家在线 通知玩家:" .. room.data.owner .. "创建的房间 roomId:" .. roomId .. "已有其他玩家满人在游戏了 房主可开启新房间")
			else
				unilight.info("玩家离线 不用通知:" .. room.data.owner .. "创建的房间 roomId:" .. roomId .. "已有其他玩家满人在游戏了 房主可开启新房间")
			end

			-- 缓存map中也清掉该玩家数据
			RoomInfo.RemoveMapUid2RommData(room.data.lobbyId, room.data.owner)

			-- 标记下 已经发送过 这个广播了
			room.data.sendcancreate = true
		end
	end

	if len == 1 then
		-- 数据库中 最后一个玩家离开时刻缓存
		room.data.allleavetime = nil

		-- 事件终止
		if room.state.eventEmpytTimeOut ~= nil then
			room.state.eventEmpytTimeOut:Stop()
			room.state.eventEmpytTimeOut = nil
		end
		-- debug
		unilight.info("房间第一个玩家进入 置空销毁倒计时:" .. roomId)
	end
end

-- 有玩家离开房间 
Zone.CmdSendLeaveRoomLobbyCmd_C= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdSendLeaveRoomLobbyCmd_C:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	if cmd.data == nil or cmd.data.uid == nil or cmd.data.roomId == nil then
		unilight.error("游戏服通知大厅 有玩家离开房间数据有误")
		return 
	end

	local uid 		= cmd.data.uid
	local roomId 	= cmd.data.roomId

	local room = RoomInfo.GlobalRoomInfoMap[roomId]
	if room == nil then
		unilight.error("玩家离开房间 当前大厅不存在该房间 roomid:" .. roomId)
		return
	end
	local userRoom = RoomInfo.GetRoomByLobbyIdUid(room.data.lobbyId, uid)
	if userRoom == nil then
		unilight.error("玩家离开房间 当前玩家不在房间中 uid:" .. uid)
		return		
	end
	if userRoom ~= room then
		unilight.error("玩家离开房间 玩家离开的房间和其实际所在房间不一致 uid:" .. uid .. " leave:" .. roomId .. "	realy:" .. userRoom.data.roomid)
		return			
	end

	local len = table.len(room.data.history.position)

	-- 只有房间内并未开始过游戏 房间所属才有可能变化
	if len < room.data.usernbr then
		-- 房主特殊处理 如果为房间回到大厅的话缓存还依然存在
		if room.data.owner ~= uid then
			-- 玩家房间缓存置空
			RoomInfo.RemoveMapUid2RommData(room.data.lobbyId, uid)
		end

		-- room 人数改变
		room.data.history.position[uid] = nil
		len = len - 1
	end

	-- 最后一个玩家离开时 需要开始房间销毁倒计时
	if len == 0 then
		-- 数据库中 最后一个玩家离开时刻缓存
		room.data.allleavetime = os.time()

		-- 新起事件 等待销毁
		room.state.eventEmpytTimeOut = NewUniEventClass(RoomClass.EventEmptyTimeOut, RoomInfo.ALL_LEAVE_OVERDUE, 1, room)

		-- debug
		unilight.info("房间最后一个玩家离开 开始销毁倒计时:" .. room.id)
	end

	-- 该玩家离开 如果还在大厅的话 直接推送一下个人信息 （存在冗余 目的为了防止服务器响应过慢引起的数据异常 其实就是为了刷新 返回房间这个状态)
	local laccount = go.accountmgr.GetAccountById(uid)
	if laccount ~= nil then
		local userdata = UserInfo.GetUserDataById(uid)
		local data = {
			userInfo = UserInfo.GetUserDataBaseInfo(userdata),
		}

		-- 玩家返回大厅的时候 是否还在该房间中
		if RoomInfo.GetRoomByLobbyIdUid(room.data.lobbyId, uid) ~= nil then
			data.isCreate = true
		else
			data.isCreate = false
		end
		RoomInfo.SendCmdToUser("Cmd.UserInfoGetLobbyCmd_S", data, laccount)
		unilight.info("玩家离开游戏时 主动推送一下玩家个人数据(可能存在冗余)")
	end
end

-- 房间销毁
Zone.CmdSendRemoveRoomLobbyCmd_C= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdSendRemoveRoomLobbyCmd_C:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	if cmd.data == nil or cmd.data.roomId == nil then
		return 
	end

	-- 房间销毁
	RoomInfo.RemoveRoom(cmd.data.roomId, cmd.data.hostTip)

	-- debug
	unilight.info("游戏内玩家主动销毁房间:" .. cmd.data.roomId)
end

-- 每局战绩
Zone.CmdUserRoundResultLobbyCmd_C= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdUserRoundResultLobbyCmd_C:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	if cmd.data == nil or cmd.data.roomId == nil or cmd.data.detailData == nil then
		unilight.info("游戏服通知大厅每局战绩 参数有误")
		return 
	end

	if type(cmd.data.detailData) ~= "string" then
		unilight.error("游戏服通知大厅每局战绩 detailData不为string")
		return		
	end

	local detail = json2table(cmd.data.detailData)
	if type(detail) ~= "table" then
		unilight.error("游戏服通知大厅每局战绩 detailData解析后不为table")
		return
	end

	local room = RoomInfo.GetRoomInfoById(cmd.data.roomId)
	if room == nil then
		unilight.error("游戏服通知大厅每局战绩 大厅中没有该房间:" .. cmd.data.roomId)
		return
	end

	-- 局数自增
	room.data.curgamenbr = room.data.curgamenbr + 1

	-- 战绩汇总
	for i=1, room.data.usernbr do
		if room.data.history.statistics[i] == nil then
			room.data.history.statistics[i] = table.clone(detail.statistics[i])
		else
			room.data.history.statistics[i].integral = (room.data.history.statistics[i].integral or 0) + detail.statistics[i].integral
		end
		local uid = detail.statistics[i].uid
		UserInfo.AddUserPlayNumData(uid, 1, room.data.lobbyId)
	end

	-- 详情增添
	table.insert(room.data.history.detail, detail)

	-- debug
	unilight.info("游戏服通知大厅每局战绩:" .. cmd.data.roomId .. "	globalroomid:" .. room.data.globalroomid .. "	第" .. room.data.curgamenbr .. "局")
end

-- 修改房间人数 提前开局
Zone.CmdChangeUserNbrLobbyCmd_CS= function(cmd,zonetask)
	unilight.info("收到游戏服数据:CmdChangeUserNbrLobbyCmd_CS:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	local res = cmd
	if cmd.data == nil or cmd.data.uid == nil or cmd.data.roomId == nil or cmd.data.userNbr == nil then
		unilight.info("游戏服通知大厅修改房间人数 参数有误")
		res.data.ret = 1
		res.data.desc = "游戏服通知大厅修改房间人数 参数有误"
		return res
	end

	local uid 		= cmd.data.uid
	local roomId 	= cmd.data.roomId
	local userNbr 	= cmd.data.userNbr

	local room = RoomInfo.GetRoomInfoById(roomId)
	if room == nil then
		unilight.error("游戏服通知大厅修改房间人数 大厅中没有该房间:" .. roomId)
		res.data.ret = 2
		res.data.desc = "游戏服通知大厅修改房间人数 大厅中没有该房间:" .. roomId
		return res
	end

	if userNbr >= room.data.usernbr then
		unilight.error("游戏服通知大厅修改房间人数 不能增加人数")
		res.data.ret = 3
		res.data.desc = "游戏服通知大厅修改房间人数 不能增加人数"
		return res
	end

	local curUserNbr = table.len(room.data.history.position)
	if room.data.usernbr == curUserNbr then
		unilight.error("游戏服通知大厅修改房间人数 该房间人数已满")
		res.data.ret = 4
		res.data.desc = "游戏服通知大厅修改房间人数 该房间人数已满"
		return res
	end

	if userNbr < curUserNbr then
		unilight.error("游戏服通知大厅修改房间人数 该房间人数已超过" .. userNbr .. "人")
		res.data.ret = 5
		res.data.desc = "游戏服通知大厅修改房间人数 该房间人数已超过" .. userNbr .. "人"
		return res
	end

	local newDiamondCost = 0
 	-- 从表格中获取 当前类型的房间 所需支付钻石数 大厅统一读取游戏读数据库 并存档 游戏服同时使用该数据 不易出错。
	local costTableInfo = RoomInfo.MapTableRoomCost[room.data.lobbyId] or RoomInfo.MapTableRoomCost[1]
	if room.data.paytype == 1 or room.data.paytype == 3 then
		-- 房主支付/大赢家支付
		newDiamondCost = costTableInfo[userNbr][room.data.gamenbr].diamondcost
	elseif room.data.paytype == 2 then
		-- 均摊模式
		newDiamondCost = costTableInfo[userNbr][room.data.gamenbr].averdiamondcost
	end

	-- 假定 换人数后 所有玩家足够扣费
	local enough = true

	-- 房间不免费 且 人数变化时 需要检测 变化后 是否游戏内玩家足够扣费
	if room.data.isfree ~= true and room.data.hasDecrease == nil then
		if room.data.paytype == 1 then
			-- 房主支付
			local userData = UserInfo.GetUserDataById(room.data.owner)
			local cur = 0
		    -- 江西客家消耗房卡
		    if room.data.lobbyId == 7 then
		        cur = userData.mahjong.card
		    else
		        cur = userData.mahjong.diamond
		    end
			if cur < newDiamondCost then
				enough = false
			end
		elseif room.data.paytype == 2 or room.data.paytype == 3 then
			-- 均摊支付／大赢家支付  则 需要校验所有的玩家筹码
			for uid,_ in pairs(room.data.history.position) do
				local userData = UserInfo.GetUserDataById(uid)
				local cur = 0
			    -- 江西客家消耗房卡
			    if room.data.lobbyId == 7 then
			        cur = userData.mahjong.card
			    else
			        cur = userData.mahjong.diamond
			    end
				if cur < newDiamondCost then
					enough = false
					break
				end
			end
		end
	end

	-- 换后 有玩家不够支付 因此不允许提前开房
	if enough ~= true then
		unilight.error("游戏服通知大厅修改房间人数 有玩家不够扣费 更换人数失败")
		res.data.ret = 6
		res.data.desc = "游戏服通知大厅修改房间人数 有玩家不够扣费 更换人数失败"
		return res		
	end

	room:Debug("房间人数发生变化:" .. room.data.usernbr .."-->" ..userNbr)
	room.data.usernbr = userNbr
	room.data.diamondcost = newDiamondCost

	-- 人数发生变化后 如果人数等于当前人数 则 提前开局 需要在此扣费
	if userNbr == curUserNbr then
		if room.data.isfree ~= true and room.data.hasDecrease == nil and room.data.paytype ~= 3 then
			RoomInfo.DeductRoomCharge(room)
		end	
	end
	return res
end

-- 游戏服通知大厅玩家砖石变动
Zone.CmdUserDiamondWinLobbyCmd_CS= function(cmd,zonetask)
	local res = cmd
	unilight.info("收到游戏服数据:CmdUserDiamondWinLobbyCmd_CS:" .. zonetask.GetGameId() .. ":" .. zonetask.GetZoneId())
	if cmd.data == nil or cmd.data.uid == nil or cmd.data.change == nil then
		unilight.error("游戏服通知大厅玩家钻石变动 参数有误")
		res.data.ret = 1
		res.data.desc = "游戏服通知大厅玩家钻石变动 参数有误"
		return res
	end

	local uid 		= cmd.data.uid
	local change 	= cmd.data.change
	local typ 		= cmd.data.typ or 1 --没传默认兼容老模式练习场输赢
	local needSend 	= cmd.data.needSend


	local ret, desc, diamond = nil
	if change < 0 then
		ret, desc, diamond = UserInfo.CommonChangeUserDiamond(uid, 2, -change, nil, MapDiamondChangeTypeStr[typ], MapDiamondChangeType[typ], typ)
		if ret == 0 then
			-- debug
			unilight.info("游戏服通知大厅玩家" .. MapDiamondChangeTypeStr[typ] .. " uid:" .. uid .. "	change:" .. change .. "	remainder" .. diamond)
		else
			res.data.ret = 2
			res.data.desc = desc
			unilight:error("游戏服通知大厅玩家" .. MapDiamondChangeTypeStr[typ] .. " 扣钻失败  uid:" .. uid .. " change:" .. change)
		end
	elseif change > 0 then
		ret, desc, diamond = UserInfo.CommonChangeUserDiamond(uid, 1, change, nil, MapDiamondChangeTypeStr[typ], MapDiamondChangeType[typ], typ)
		if ret == 0 then
			-- debug
			unilight.info("游戏服通知大厅玩家" .. MapDiamondChangeTypeStr[typ] .. " uid:" .. uid .. "	change:" .. change .. "	remainder" .. diamond)
		else
			res.data.ret = 3
			res.data.desc = desc
			unilight:error("游戏服通知大厅玩家" .. MapDiamondChangeTypeStr[typ] .. " 加钻失败  uid:" .. uid .. " change:" .. change)
		end
	end

	-- 练习场上面的接口是找不到合适地方发送砖石变化的 所以需要在这里手动发送
	if needSend == 1 then
		RoomInfo.SendDiamondChange(nil, uid, diamond, change, zonetask)	
	end
	return res
end

