
-- 进入房间
Net.CmdEnterRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.EnterRoomCmd_S" 
	if cmd.data == nil or cmd.data.roomId == nil then
		res["data"] = {
			ret  = 1,
			desc = "参数不完整",
		}
		return res
	end
	local roomId  	= cmd.data.roomId
	local uid 		= laccount.Id

	-- 判断是否可以进入房间
	local bOk = RoomMgr.CheckCouldEnter(uid, roomId)
	if bOk == false then
		res["data"] = {
			ret  =  2,
			desc = "进入的房间不存在",
		}
		unilight.error("进入的房间不存在 :" .. roomId)
		return res 
	end	

	-- 接入某个大厅了 就必须经过大厅检测
	local zoneType = go.getconfigint("zone_type") 
	if zoneType ~= nil and zoneType ~= 0 then 
		local userData=UserInfo.GetUserDataById(uid)
		local ret = IntoGameMgr.CheckIntoGame(userData)
		if ret == false then
			res["data"]={
				ret 	= 2,
				desc 	= "未经过大厅检测 不允许进入房间"
			}		
			return res 	
		end
	end

	-- 进入房间
	local roomInfo, roomBet, bankerInfo, lotteryHistorys, bankerList = RoomMgr.EnterRoom(laccount, uid, roomId)

	-- 返回给玩家房间基本信息
	res["data"] = {
		ret 			= 0,
		desc 			= "玩家进入房间成功",
		roomInfo 		= roomInfo,
		roomBet 		= roomBet,
		bankerInfo 		= bankerInfo,
		lotteryHistorys = lotteryHistorys,
		bankerList 		= bankerList,
	}
	unilight.info("玩家 ".. uid .. "  允许进入房间" ..roomId)
	return res 
end

-- 离开房间
Net.CmdLeaveRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.LeaveRoomCmd_S" 
	local uid = laccount.Id 
	-- 判断是否在房间
	local roomId = RoomMgr.GetRoomId(uid)
	if roomId == nil then
		res["data"] = {
			ret  = 1,
			desc = "该玩家并未进入房间"
		}
		return res	
	end	

	-- 如果当前在坐庄 则 不许离开房间
	local roomInfo  = RoomMgr.MapRoom[roomId]
	local bankerUid = roomInfo.betInfo.bankerInfo.uid
	if bankerUid == uid then
		res["data"] = {
			ret  = 2,
			desc = "当前在庄上不能离开房间"
		}
		return res			
	end

	-- 先下庄（如果只是在队中 则 直接离队）
	RoomMgr.CancelBanker(uid)

	-- 离开房间
	local ret, desc = RoomMgr.LeaveRoom(uid)
	res["data"] = {
		ret  = ret,
		desc = desc
	}
	return res	
end

-- 下注请求
Net.CmdBetRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.BetRoomCmd_S"
	if cmd.data == nil or cmd.data.betReq == nil or table.len(cmd.data.betReq) == 0 then
		res["data"] = {
			ret  = 1,
			desc = "参数不完整",
		}
		return res
	end	
	local uid 	 = laccount.Id
	local betReq = cmd.data.betReq
	local roomId, laccount, seatId = RoomMgr.GetRoomId(uid)
	if roomId == nil then
		res["data"] = {
			ret  = 2,
			desc = "玩家未进入房间",
		}
		return res	
	end	

	local roomInfo = RoomMgr.MapRoom[roomId]
	if roomInfo.status ~= RoomMgr.ENUM_GAME_STATUS.BET then 
		res["data"] = {
			ret  = 3,
			desc = "当前不在下注时间",
		}
		return res	
	end

	if RoomMgr.IsBanker(uid) then
		res["data"] = {
			ret  = 4,
			desc = "当前您为店长不能下注",
		}
		return res
	end

	--条件检测通过后 投注申请
	local ret, desc, remainder, betRes, roomBet, userBet = RoomMgr.BetReq(uid, roomId, betReq)

	-- 失败了单独回复
	if ret ~= 0 then
		res["data"] = {
			ret  = ret,
			desc = desc,
		}		
		return res
	end

	-- 当前房间投注 和 玩家投注 由于可能投注多个的原因 因此 可能需要返回多个数据
	local isBet = {}
	for i,v in ipairs(betRes) do
		isBet[v.betId] = true
	end

	local tempRoomBet = {}
	for i,v in ipairs(roomBet) do
		if isBet[i] then
			table.insert(tempRoomBet, v)
		end
	end
	local tempUserBet = {}
	for i,v in ipairs(userBet) do
		if isBet[i] then
			table.insert(tempUserBet, v)
		end
	end

	-- 成功了则 广播
	local doInfo = "Cmd.BetRoomCmd_Brd"
	local doData = {
		uid 		= uid,
		betInfo 	= betRes,
		remainder 	= remainder,
		roomBet 	= tempRoomBet,
		userBet 	= tempUserBet,
	}
	RoomMgr.CmdMsgBrd(doInfo, doData, roomId)
end

-- 上庄请求
Net.CmdApplyBankerRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ApplyBankerRoomCmd_S" 

	if cmd.data == nil or cmd.data.bankerChips == nil then
		res["data"] = {
			ret  = 1,
			desc = "参数不完整",
		}
		return res
	end
	local uid 	 = laccount.Id 
	local roomId = RoomMgr.GetRoomId(uid)
	if roomId == nil then
		res["data"] = {
			ret  = 2,
			desc = "未进入房间",
		}
		return res	
	end		
	local bankerChips = cmd.data.bankerChips

	if bankerChips < TableBankerConfig[1].chips then
		res["data"] = {
			ret  = 3,
			desc = "低于最少上庄金币",
		}
		return res
	end
	
	local userInfo = chessuserinfodb.RUserLoginGet(uid)
	if userInfo.property.chips < bankerChips then
		res["data"] = {
			ret  = 4,
			desc = "玩家金币不足",
		}
		return res
	end

	-- 将以多少钱上庄 临时记录在TempBankChips 中
	RoomMgr.TempBankChips[uid] = bankerChips

	-- 正式添加到上庄列表
	local bOk, index = BankerRoomMgr.UserApply(roomId, uid)
	unilight.debug("玩家申请上庄成功：" .. uid)
	-- 组装庄家信息给前端（区分-- 真实玩家、系统、机器人）
	local bankerInfo = BankerRoomMgr.ConsructBankerInfo(uid, 0, index)
	-- 广播
	local doInfo = "Cmd.ApplyBankerRoomCmd_Brd"
	local doData = {
		bankerInfo = bankerInfo,
	}
	RoomMgr.CmdMsgBrd(doInfo, doData, roomId)
end

-- 下庄请求
Net.CmdCancelBankerRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.CancelBankerRoomCmd_S" 
	local uid = laccount.Id 
	unilight.info("有玩家取消上庄:" .. uid)

	RoomMgr.CancelBanker(uid)

	local isBanker = RoomMgr.IsBanker(uid)
	local desc = "申请下庄成功"
	if isBanker then
		desc = "申请下庄成功,本轮结束即可下庄"
	end

	res["data"] = {
		ret 	 	= 0,
		desc 		= desc,	
		isBanker 	= RoomMgr.IsBanker(uid),
	}
	return res
end

-- 上庄列表获取
Net.CmdGetBankerListRoomCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetBankerListRoomCmd_S" 
	local uid = laccount.Id 
	local roomId = RoomMgr.GetRoomId(uid)
	if roomId == nil then
		res["data"] = {
			ret 	= 1,
			desc 	= "玩家不在房间内"
		}
		return res	
	end	

	local bankerList = RoomMgr.GetBankerList(roomId)

	res["data"] = {
		ret 		= 0,
		desc 		= "获取上庄列表成功",
		bankerList 	= bankerList,
	}
	return res
end




-- gm控制输赢
GmSvr = GmSvr or {}
GmSvr.GmLotteryControl_C = function(cmd, laccount)
	local res = {}
	res["do"] = "GmLotteryControl_S" 
	res["data"] = {}

	if cmd.data == nil or cmd.data.roomId == nil or cmd.data.control == nil then
		res.data.retcode = 1 
		res.data.retdesc = "参数没有带入"
		return res
	end
	unilight.info("debug 收到gm控制开奖命令" .. table.tostring(cmd.data))
	local ret, desc = RoomMgr.GmControl(tonumber(cmd.data.roomId), cmd.data.control)
	res.data.retcode = ret 
	res.data.retdesc = desc
	return res
end
