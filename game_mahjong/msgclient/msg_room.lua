-- 处理麻将 进入座间游戏逻辑 
-- 进入麻将房间
Net.CmdEnterMahjongCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	local data = cmd.data
	local roomId = data.roomId or 0
	local userInfo = UserInfo.GetUserInfoById(uid)   
	local room = RoomInfo.GetRoomInfoById(roomId)
	local roomInfoData = nil
	data.globalRoomId = data.globalRoomId or 0
	if unilight.getdebuguser and unilight.getdebuguser() == "WHJ" then
		data.gameId = data.gameId or 177 -- go.gamezone.Gameid
	else
		data.gameId = data.gameId or go.gamezone.Gameid
	end
	if data.robotNum == nil then
		if roomId == 0 then
			data.robotNum = 3
		else
			data.robotNum = 0
		end
	end
	if userInfo ~= nil then --新进入非练习场
		userInfo.state.laccount = laccount
		room = userInfo.state.seat.owner
		local ret = room:DoEnterMahjong(userInfo)
		if ret == false then
			userInfo:SendCmdToMe("Cmd.EnterMahjongCmd_S",{resultCode=1,})
		end
		return --不管是否成功进入直接返回
	end
	if roomId > 0 then
		if room == nil then
			if unilight.getdebuglevel() == 0 and unilight.getgameid() ~= 4055 then --release下,如果大厅没起,就返回错误,debug版本下可以当练习场创建,暂时写死江西宁都,WHJ
				UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc="进入房间失败,大厅还未创建"},laccount)
				UserInfo.SendCmd("Cmd.EnterMahjongCmd_S",{resultCode=1,},laccount)
				laccount.Error("进入房间失败,大厅还未创建:"..roomId .. ":" .. data.globalRoomId .. ":" .. data.gameId)
				return
			end
			data.globalRoomId = roomId
			roomInfoData = RoomInfo.CreateRandomRoomData(data.globalRoomId,roomId, data.gameId,uid)
		end
	else
		roomId = RoomInfo.GetRandomRoomId(uid)
		room = RoomInfo.GetRoomInfoById(roomId)
		if room == nil then
			data.globalRoomId = roomId
			roomInfoData = RoomInfo.CreateRandomRoomData(data.globalRoomId,roomId, data.gameId,uid)
		end
	end
	if room == nil then
		if roomInfoData == nil  then
			UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc="房间数据查找失败"},laccount)
			UserInfo.SendCmd("Cmd.EnterMahjongCmd_S",{resultCode=1,},laccount)
			laccount.Error("房间数据查找失败,需要通知大厅错误处理:" .. roomId .. "," .. data.globalRoomId)
			return
		end
		room = RoomInfo.CreateRoom(roomInfoData)
		if room == nil then
			UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc="创建房间失败"},laccount)
			UserInfo.SendCmd("Cmd.EnterMahjongCmd_S",{resultCode=1,},laccount)
			laccount.Error("创建房间失败,需要通知大厅错误处理:" .. roomId .. "," .. data.globalRoomId)
			return
		end
		room.state.maxRobotNum = data.robotNum --临时测试用
		room:Info("创建新房间:" .. roomId .. "," .. data.globalRoomId .. "," .. uid)
	end

	if userInfo == nil then
		if unilight.getdebuglevel() > 0 then
			-- 测试使用
			local userdata = UserInfo.GetUserDataById(uid)
			if userdata == nil then
				UserInfo.CreateUserData(uid)
			end
		end
		userInfo = UserInfo.UserIntoRoom(room, laccount) 
	end
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc="进入房间时找不到玩家信息"},laccount)
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		room:Error("进入房间时找不到玩家信息:" .. uid)
		return
	end
	userInfo.state.laccount = laccount
	room = userInfo.state.seat.owner
	if room.id ~= roomId then
		userInfo:SendFailToMe("进入已有房间")
		userInfo:Error("发现请求进入房间和已有房间不一致,准备进入已有房间:" .. roomId .. "," .. room.id)
	end
	
	userInfo.state.lat = data.lat
	userInfo.state.lng = data.lng

	local ret = room:DoEnterMahjong(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.EnterMahjongCmd_S",{resultCode=1,})
		return
	elseif unilight.getdebuglevel() > 0 then
		if data.handCardInitId then
			userInfo.state.seat.base = TableHandCardInit[data.handCardInitId]
			userInfo:Debug("启用初始牌库:"..userInfo.state.seat.base.name)
		end
	end
	if room:IsLearnRooom() == false then
		ChessToLobbyMgr.SendEnterRoomToLobby(roomId, uid,userInfo.state.seat.id)
	end
end
Do.CmdSoundSet_C = function (cmd, laccount)
	--laccount.Error("暂时不用了") //但是客户端有超时问题,就先回个echo
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil or not userInfo.state then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		return 
	end
	userInfo:SendCmdToMe("Cmd.ClientEchoMahjongCmd_SC",{})
end

Net.CmdServerEchoMahjongCmd_SC = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil or not userInfo.state then
		return 
	end
	userInfo.state.notifyMsg = nil
	userInfo.state.notifyMsgEvent = nil
end
Net.CmdClientEchoMahjongCmd_SC = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil or not userInfo.state then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		return 
	end
	userInfo:SendCmdToMe("Cmd.ClientEchoMahjongCmd_SC",{})
end
Net.PmdOnlineStateLoginUserPmd_CS = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil or not userInfo.state then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		return 
	end
	if cmd.data.state == 3 and userInfo.state.onlineState == 1 then
		userInfo.state.onlineState = cmd.data.state
		userInfo:BroadcastOnlineState()
	elseif cmd.data.state == 1 and userInfo.state.onlineState == 3 then
		userInfo.state.onlineState = cmd.data.state
		userInfo:BroadcastOnlineState()
	elseif cmd.data.state == 4 and userInfo.state.onlineState == 1 then
		userInfo.state.onlineState = cmd.data.state
		userInfo:BroadcastOnlineState()
	elseif cmd.data.state == 1 and userInfo.state.onlineState == 4 then
		userInfo.state.onlineState = cmd.data.state
		userInfo:BroadcastOnlineState()
	end
end
-- 离开麻将房间
Net.CmdLeaveMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		--UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求离开找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = userInfo.state.seat.owner:DoLeaveRoom(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.LeaveMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求准备
Net.CmdReadyStartMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求准备找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = userInfo.state.seat.owner:DoReadyStart(userInfo, data.type)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.ReadyStartMahjongCmd_S",{resultCode=1,})
	else
		userInfo:SendCmdToMe("Cmd.ReadyStartMahjongCmd_S",{resultCode=0,})
	end
end

-- 开局漂分
Net.CmdReqPiaoMahjongCmd_C = function(cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家请求漂分找不到uid:"..uid.."没有上桌")
		return
	end
	local ret = userInfo.state.seat.owner:StartMultiPiao(userInfo, data.multiPiao)
	if ret ~= true then
		userInfo:SendCmdToMe("Cmd.ReqPiaoMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求出牌
Net.CmdOutCardMahjongCmd_C = function (cmd, laccount)
	local uid = laccount.Id
	local data = cmd.data
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	userInfo:Info("玩家请求出牌:"..data.thisId)
	local bok = userInfo.state.seat.owner:DoOutCard(userInfo, data.thisId, data.isSkyListen)
	if bok ~= true and bok ~= 0 then
		if bok == false then
			bok = 1 --这里为了兼容,恶心下自己
		end
		userInfo:Error("玩家请求出牌失败:"..data.thisId)
		userInfo:SendCmdToMe("Cmd.OutCardMahjongCmd_S",{resultCode=bok,thisId=data.thisId,})
	end
end

-- 请求亮牌
Net.CmdShowCardMahjongCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	local data = cmd.data
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		unilight.error("玩家请求亮牌 uid:"..uid.." 没有上桌")
		return 
	end
	userInfo:Info("玩家请求亮牌 uid:"..uid)
	local ret = userInfo.state.seat:DoShowCard(userInfo, data.triCard)
	if ret ~= true then
		userInfo:Error("玩家请求亮牌失败 uid:"..uid)
		userInfo:SendCmdToMe("Cmd.ShowCardMahjongCmd_S",{resultCode=1,})
	end
end

Net.CmdSkyListenCmd_C = function(cmd, laccount)

end

-- 取消操作牌
Net.CmdCancelOpMahjongCmd_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	local ret = nil
	if userInfo.state.seat.owner.DoJudgeCancelOperate then
		ret = userInfo.state.seat.owner:DoJudgeCancelOperate(userInfo)
	else
		ret = userInfo.state.seat.owner:DoCancelOperate(userInfo)
	end
	if ret ~= true then
		userInfo:SendCmdToMe("Cmd.CancelOpMahjongCmd_S",{resultCode=1,})
		userInfo:Error("玩家请求取消操作失败")
	end
end

-- 送礼
Net.CmdSendGiftMahjongCmd_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求送礼 uid:"..uid.." 没有上桌")
		return 
	end
	local bok = userInfo.state.seat.owner:DoSendGift(userInfo,cmd.data)
	if bok ~= true then
		userInfo:SendCmdToMe("Cmd.SendGiftMahjongCmd_S",{resultCode=1,})
		userInfo:Error("送礼失败")
	end
end

-- 语音聊天
Net.CmdVoiceChat_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	local bok = userInfo.state.seat.owner:DoVoiceChat(userInfo,cmd.data)
	if bok ~= true then
		userInfo:SendCmdToMe("Cmd.VoiceChat_S",{resultCode=1,})
		userInfo:Error("语音发送失败")
	end
end

-- 语音聊天记录
Net.CmdVoiceChatRecord_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	local bok = userInfo.state.seat.owner:DoVoiceChatRecord(userInfo,cmd.data)
	if bok ~= true then
		userInfo:SendCmdToMe("Cmd.VoiceChatRecord_S",{resultCode=1,})
		userInfo:Error("送礼失败")
	end
end

--
Net.CmdCommonChat_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	local bok = userInfo.state.seat.owner:DoCommonChat(userInfo,cmd.data)
	if bok ~= true then
		userInfo:SendCmdToMe("Cmd.CommonChat_S",{resultCode=1,})
		userInfo:Error("送礼失败")
	end
end
-- GM指令
Net.CmdHeapCardGmMahjongCmd_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	if unilight.getdebuglevel() > 0 then
		local data = {
			cardSet = userInfo.state.seat.owner:GetHeapCard(),
			cardButton = userInfo.state.seat.owner:GetInitHandCardButton(),
		}
		userInfo:SendCmdToMe("Cmd.HeapCardGmMahjongCmd_S",data)
	else
		userInfo:SendFailToMe("GM权限不够,不允许操作")
		userInfo:Error("GM权限不够,不允许操作")
	end
end

Net.CmdChangeCardGmMahjongCmd_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求出牌 uid:"..uid.." 没有上桌")
		return 
	end
	if unilight.getdebuglevel() > 0 then
		local tid = cmd.data.cardButtonId
		--local tid = 4
		--if TableHandCardInit[tid] then
		if tid and TableHandCardInit[tid] then
			local base = TableHandCardInit[tid]
			userInfo:Info("准备切换牌型:"..base.name)
			local tempCache = {}
			for k,v in pairs(userInfo.state.seat.handCard) do
				local add = true
				for i,v1 in ipairs(base.card) do
					if v1 == v.base.thisid or v1 == v.base.baseid or v1 == v.base.type then
						add = false
					end
				end
				if add then
					table.insert(tempCache,k)
				end
			end
			for i,v in ipairs(tempCache) do
				userInfo.state.seat.owner:DoChangeCardGmMahjongCmd(userInfo,v,base.card[i])
			end
			local data = {
				cardSet = userInfo.state.seat.owner:GetHeapCard(),
				cardButton = userInfo.state.seat.owner:GetInitHandCardButton(),
			}
			userInfo:SendCmdToMe("Cmd.HeapCardGmMahjongCmd_S",data)
		else
			userInfo.state.seat.owner:DoChangeCardGmMahjongCmd(userInfo,cmd.data.oldCardId,cmd.data.newCardId)
		end
	else
		userInfo:SendFailToMe("GM权限不够,不允许操作")
		userInfo:Error("GM权限不够,不允许操作")
	end
end

--开局操作（起手小胡）
Net.CmdStartNewRoundOpCmd_C = function(cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家请求起手小胡找不到uid:"..uid.." 没有上桌")
		return
	end
	userInfo.state.seat.owner:DoStartSmallWin(userInfo)
end

--请求补张
Net.CmdSupplyCardMahjongCmd_C = function(cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		unilight.error("玩家请求补张找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = userInfo.state.seat.owner:DoJudgeOperate(userInfo, data, 3)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.SupplyCardMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求原缺
Net.CmdOriginalLackOpCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家请求原缺找不到uid:"..uid.." 没有上桌")
		return
	end
	userInfo.state.seat.owner:DoOriginalLack(userInfo)
end

-- 请求定缺
Net.CmdEnsureLackOpCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家请求原缺找不到uid:"..uid.." 没有上桌")
		return
	end

	if cmd.data == nil or cmd.data.cardType == nil or cmd.data.cardType <= 0 or cmd.data.cardType > 3 then
		userInfo:SendFailToMe("请求定缺数据有误")
		return
	end

	userInfo.state.seat.owner:DoEnsureLack(userInfo, cmd.data.cardType)
end

-- 请求杠牌
Net.CmdBarCardMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求杠牌找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = nil
	if userInfo.state.seat.owner.DoJudgeOperate then
		ret = userInfo.state.seat.owner:DoJudgeOperate(userInfo, data, 2)
	else
		ret = userInfo.state.seat.owner:DoBarCard(userInfo, data.thisId)
	end
	if ret == false then
		userInfo:SendCmdToMe("Cmd.BarCardMahjongCmd_S",{resultCode=1,})
	end
end

--杠牌操作(胡/取消)
Net.CmdBarOpMahjongCmd_C = function(cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家杠牌操作找不到uid:"..uid.." 没有上桌")
		return 
	end
	userInfo.state.seat.owner:DoBarOp(userInfo, data.opType)
end

-- 请求吃牌
Net.CmdEatCardMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求碰牌找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = nil
	if userInfo.state.seat.owner.DoJudgeOperate then
		ret = userInfo.state.seat.owner:DoJudgeOperate(userInfo, data, 7)
	else
		ret = userInfo.state.seat.owner:DoEatCard(userInfo, data.one, data.two)
	end
	if ret == false then
		userInfo:SendCmdToMe("Cmd.EatCardMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求碰牌
Net.CmdTouchCardMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求碰牌找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = nil
	if userInfo.state.seat.owner.DoJudgeOperate then
		ret = userInfo.state.seat.owner:DoJudgeOperate(userInfo, data, 6)
	else
		ret = userInfo.state.seat.owner:DoTouchCard(userInfo, data.thisId)
	end
	if ret == false then
		userInfo:SendCmdToMe("Cmd.TouchCardMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求胡牌
Net.CmdWinMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("玩家请求碰牌找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = nil
	if userInfo.state.seat.owner.DoJudgeOperate then
		ret = userInfo.state.seat.owner:DoJudgeOperate(userInfo, data, 1)
	else
		ret = userInfo.state.seat.owner:DoWinCard(userInfo)
	end
	if ret == false then
		userInfo:SendCmdToMe("Cmd.WinMahjongCmd_S",{resultCode=1,})
	end
end

-- 海底漫游
Net.CmdSeaRoamMahjongCmd_C = function(cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		unilight.error("玩家请求海底漫游找不到uid:"..uid.." 没有上桌")
		return 
	end
	userInfo.state.seat.owner:DoSeaRoam(userInfo, data.opType)
end
-- 请求切换房间人数
Net.CmdRequestChangeUserNbrRoom_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("请求解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoRequestChangeUserNbr(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.RequestChangeUserNbrRoom_C",{resultCode=1,})
	end
end

-- 回应切换房间人数
Net.CmdReturnChangeUserNbrRoom_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("请求解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoReturnChangeUserNbr(userInfo,cmd.data.isAgree)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.ReturnChangeUserNbrRoom_C",{resultCode=1,})
	end
end
-- 请求解散房间
Net.CmdRequestDissolveRoom_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("请求解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoDissolveRoom(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.RequestDissolveRoom_S",{resultCode=1,})
	end
end

-- 回应解散房间
Net.CmdReplyDissolveRoom_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("回应解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoReplyDissolveRoom(userInfo,cmd)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.ReplyDissolveRoom_S",{resultCode=1,})
	end
end

-- 托管 1 取消托管 0
Net.CmdHostMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("回应解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoHostMahjong(userInfo,cmd)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.HostMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求听牌数量
Net.CmdListenObjMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("回应解散房间找不到uid:"..uid)
		return 
	end
	local ret = userInfo.state.seat.owner:DoListenObjMahjong(userInfo,cmd)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.ListenObjMahjongCmd_S",{resultCode=1,})
	end
end

-- 换桌
Net.CmdChangeRoomMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)
	if userInfo == nil then
		UserInfo.SendCmd("Cmd.LeaveMahjongCmd_Brd", {uid=uid,},laccount)
		unilight.error("请求换桌找不到uid:"..uid)
	end
	local ret = userInfo.state.seat.owner:DoChangeRoomMahjong(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.ChangeRoomMahjongCmd_S",{resultCode=1,})
	end
end

-- 请求排行榜
Net.CmdGetRankingListRoomCmd_C = function (cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetRankingListRoomCmd_S"

	local uid = laccount.Id
	local roomId = roomUtil.CmdRoomIdGet(uid)
	if roomId == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[5].id,
			desc = TableServerReturnCode[5].desc,
		}
		return res
	end

	local ret, rankInfoList = roomSpecUtil.CmdRankingListGet(roomId)
	if ret ~= nil and ret ~= TableServerReturnCode[1].id then
		res["data"] = {
			resultCode = TableServerReturnCode[ret+1].id,
			desc = TableServerReturnCode[ret+1].desc,
		}
		return res
	end
	local doInfo = "Cmd.GetRankingListRoomCmd_S"
	local doData = {
		resultCode = TableServerReturnCode[ret + 1].id,
		desc = TableServerReturnCode[ret + 1].desc,
		roomId = roomId,
		rankInfo = rankInfoList
	}
	roomUtil.CmdCheckMsgMe(uid, doInfo, doData)
end

-- 请求踢人
Net.CmdKickMahjongCmd_C = function (cmd, laccount)
	local res = {}
	res["do"] = "Cmd.KickMahjongCmd_S"

	local uid = cmd.data.uid
	local kickUid = cmd.data.kickUid
	local ret = roomUtil.CmdKick(kickUid, uid)
	if ret ~= nil then
		res["data"] = {
			resultCode = TableServerReturnCode[ret + 1].id,
			desc = TableServerReturnCode[ret + 1].desc,
		}
		return res
	end
end

-- 请求资料面板信息
Net.CmdGetPersonalPanel_C = function (cmd, laccount)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		unilight.error("Net.CmdGetPersonalPanel_C uid:"..uid.." 没有上桌")
		return 
	end
	local requestInfo = userInfo.state.seat.owner:GetPlayInfoById(cmd.data.uid)   
	if requestInfo == nil then
		userInfo:SendFailToMe("未找到要请求用户信息的人")
		return 
	end
	userInfo:SendCmdToMe("Cmd.GetPersonalPanel_S",{userInfo=requestInfo:GetBaseInfo(),})
end

-- 查看总成绩
Net.CmdFinalScoreMahjongCmd_C = function (cmd, laccount)
	local data = cmd.data
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		unilight.error("玩家请求准备找不到uid:"..uid.." 没有上桌")
		return 
	end
	local ret = userInfo.state.seat.owner:DoFinalScore(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.FinalScoreMahjongCmd_S",{resultCode=1,})
	end
end

GmCmd.SendUserSceneToMe = function (cmd, laccount)
	roomSpecUtil.CmdObserve(laccount.Id, cmd)
end

Net.CmdEcho = function(cmd, laccount)
	unilight.info("****************机器人上线了laccount:" .. laccount.Id)
	unilight.info("*****************:"..laccount.GetUid() .. laccount.GetThirdNickName() .. laccount.GetThirdFaceUrl() .. laccount.GetThirdPlatId())
end
if JsonCompressClass == nil then
	CreateClass("JsonCompressClass")
end
JsonCompressClass:SetClassName("JM")
function JsonCompressClass:GetId()
	return self.owner.id
end
function JsonCompressClass:GetName()
	return self.owner.name
end
function JsonCompressClass:GetIndexByValue(tbl,value)
	for k,v in ipairs(tbl.msglist) do
		if v == value then
			return k
		end
	end
	return nil
end
function JsonCompressClass:GetValueByIndex(tbl,index)
	for k,v in ipairs(tbl.msglist) do
		if k == index then
			return v
		end
	end
	return nil
end
function JsonCompressClass:Update(oldata,newdata)
	for k,v in ipairs(newdta.msglist) do
		local oldindex = self:GetIndexByValue(olddata,v)
		if oldindex then
			oldata[oldindex] = v
		else
			self:Error("找不到要更新的信息:" .. table.tostring(v))
		end
	end
end
function JsonCompressClass:Compress(send)
	local index = self:GetIndexByValue(self.data,send["do"])
	if index then
		send["do"] = index
	end
	if self.data.omit == 1 then
		send = table.omit(send)
	end
	return send
end
function JsonCompressClass:DeCompress(rev)
	local value = self:GetValueByIndex(self.data,rev["do"])
	if value then
		rev["do"] = value
	end
	return rev
end
Net.CmdJsonCompressNullUserPmd_CS = function(cmd, laccount)
	--unilight.error("defaultJsonCompress.data.key:" .. defaultJsonCompress.data.key .. ":" .. cmd.data.key)
	local uid = laccount.Id
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo == nil then
		unilight.error("PmdJsonCompressNullUserPmd_CS找不到uid:"..uid)
		return 
	end
	if not cmd.data.add or cmd.data.add == 0 or not userInfo.state.jsonCompress then
		userInfo.state.jsonCompress = JsonCompressClass:New()
		userInfo.state.jsonCompress.owner = userInfo
		if not cmd.data.msglist then --兼容老产品
			userInfo.state.jsonCompress.data = table.clone(cmd.data) --这里必须clone,否则会有引用问题
			userInfo.state.jsonCompress.data.msglist = defaultJsonCompress.data.msglist
			if defaultJsonCompress.data.key ~= cmd.data.key then
				cmd.data.msglist = defaultJsonCompress.data.msglist
				cmd.data.key = defaultJsonCompress.data.key
			end
			userInfo.state.seat.last_JsonCompressNullUserPmd_CS = table.clone(cmd.data)
			userInfo:SendCmdToMe("Cmd.JsonCompressNullUserPmd_CS",cmd.data)
		else
			userInfo.state.jsonCompress.data = cmd.data
		end
	else
		--userInfo.state.jsonCompress.Update(self.data,data)
	end
end
defaultJsonCompress = JsonCompressClass:New()
defaultJsonCompress.data = {msglist={
		    "Cmd.OutCardMahjongCmd_Brd",		--	1
		    "Cmd.OutCardMahjongCmd_S",		--	2
		    "Cmd.SelfCardMahjongCmd_S",		--	3
		    "Cmd.ReadyStartMahjongCmd_Brd",		--	4
		    "Cmd.ReadyStartMahjongCmd_S",		--	5
		    "Cmd.BarOutCardMahjongCmd_Brd",		--	6
		    "Cmd.BarCardMahjongCmd_Brd",		--	7
		    "Cmd.SendCardMahjongCmd_Brd",		--	8
		    "Cmd.SendCardMahjongCmd_S",		--	9
		    "Cmd.SetBankerMahjongCmd_Brd",		--	10
		    "Cmd.EnterMahjongCmd_Brd",		--	11
		    "Cmd.EnterMahjongCmd_S",		--	12
		    "Cmd.FinalScoreMahjongCmd_Brd",		--	13
		    "Cmd.GetPersonalPanel_S",		--	14
		    "Cmd.HostMahjongCmd_Brd",		--	15
		    "Cmd.SysMessageMahjongCmd_S",		--	16
		    "Cmd.TouchCardMahjongCmd_Brd",		--	17
		    "Cmd.OnlineStateMahjongCmd_Brd",		--	18
		    "Cmd.BarCardMahjongCmd_S",		--	19
		    "Cmd.BarDealCardMahjongCmd_Brd",		--	20
		    "Cmd.ReConnectMahjongCmd_S",		--	21
		    "Cmd.BarDealCardMahjongCmd_S",		--	22
		    "Cmd.BarDiceMahjongCmd_Brd",		--	23
		    "Cmd.ReplyDissolveRoom_Brd",		--	24
		    "Cmd.RequestChangeUserNbrRoom_Brd",		--	25
		    "Cmd.RequestChangeUserNbrRoom_C",		--	26
		    "Cmd.RequestDissolveRoom_Brd",		--	27
		    "Cmd.RequestDissolveRoom_S",		--	28
		    "Cmd.ReturnChangeUserNbrRoom_C",		--	29
		    "Cmd.SeaFloorCardMahjongCmd_Brd",		--	30
		    "Cmd.SeaRoamTurnMahjongCmd_Brd",		--	31
		    "Cmd.BirdMahjongCmd_Brd",		--	32
		    "Cmd.CancelOpMahjongCmd_S",		--	33
		    "Cmd.CommonChat_Brd",		--	34
		    "Cmd.SendGiftMahjongCmd_Brd",		--	35
		    "Cmd.EatCardMahjongCmd_Brd",		--	36
		    "Cmd.EatCardMahjongCmd_S",		--	37
		    "Cmd.ShowChangeUserNbrRoom_S",		--	38
		    "Cmd.StartMahjongCmd_Brd",		--	39
		    "Cmd.StartNewRoundOpCmd_Brd",		--	40
		    "Cmd.StartNewRoundOpCmd_S",		--	41
		    "Cmd.StartNewRoundOpTimeCmd_Brd",		--	42
		    "Cmd.SuccessDissolveRoom_Brd",		--	43
		    "Cmd.SupplyCardMahjongCmd_Brd",		--	44
		    "Cmd.SupplyCardMahjongCmd_S",		--	45
		    "Cmd.LeaveMahjongCmd_Brd",		--	46
		    "Cmd.LeaveMahjongCmd_S",		--	47
		    "Cmd.TouchCardMahjongCmd_S",		--	48
		    "Cmd.VoiceChat_Brd",		--	49
		    "Cmd.WinCardMahjongCmd_Brd",		--	50
		    "Cmd.WinMahjongCmd_S",		--	51
		    "Cmd.BarCardMahjongCmd_C",		--	52
		    "Cmd.BarOpMahjongCmd_C",		--	53
		    "Cmd.CancelOpMahjongCmd_C",		--	54
		    "Cmd.CommonChat_C",		--	55
		    "Cmd.EatCardMahjongCmd_C",		--	56
		    "Cmd.EnterMahjongCmd_C",		--	57
		    "Cmd.GetPersonalPanel_C",		--	58
		    "Cmd.HostMahjongCmd_C",		--	59
		    "Cmd.LeaveMahjongCmd_C",		--	60
		    "Cmd.OutCardMahjongCmd_C",		--	61
		    "Cmd.ReadyStartMahjongCmd_C",		--	62
		    "Cmd.ReplyDissolveRoom_C",		--	63
		    "Cmd.RequestDissolveRoom_C",		--	64
		    "Cmd.SeaRoamMahjongCmd_C",		--	65
		    "Cmd.SendGiftMahjongCmd_C",		--	66
		    "Cmd.ServerEchoMahjongCmd_SC",		--	67
		    "Cmd.SoundSet_C",		--	68
		    "Cmd.StartNewRoundOpCmd_C",		--	69
		    "Cmd.SupplyCardMahjongCmd_C",		--	70
		    "Cmd.TouchCardMahjongCmd_C",		--	71
		    "Cmd.VoiceChat_C",		--	72
		    "Cmd.CashChickenCmd_Brd",		--	73
		    "Cmd.WinMahjongCmd_C",		--	74
		    "Cmd.ClientEchoMahjongCmd_SC",	--	75
}}
defaultJsonCompress.data.key = go.md5(json.encode(defaultJsonCompress.data.msglist))
--unilight.error("defaultJsonCompress.data.key:"..defaultJsonCompress.data.key .. ":" ..json.encode(defaultJsonCompress.data.msglist))
