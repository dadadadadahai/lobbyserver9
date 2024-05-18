
-- 大厅 向  游戏服 发来的回复
Lby.CmdSendEnterRoomLobbyCmd_S= function(cmd)
	local uid = cmd.data.uid
	local laccount = go.accountmgr.GetAccountById(uid)
	if cmd.data.ret and cmd.data.ret ~=0 then
		local room = RoomInfo.GlobalRoomInfoMap[cmd.data.roomId]
		if room then
			room:Destroy()
		end
		UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc=cmd.data.desc},laccount)
		UserInfo.SendCmd("Cmd.EnterMahjongCmd_S",{resultCode=2,},laccount)--这里不确定是否要加
		return
	end
	local userInfo = UserInfo.GetUserInfoById(uid)   
	if userInfo ~= nil then
		userInfo:Error("请求创建返回时发现已经在房间了:"..userInfo.state.seat.owner.id)
		return
	end
	local room = RoomInfo.GlobalRoomInfoMap[cmd.data.roomId]
	if room == nil and cmd.data.roomData then
		local roomdata = json2table(cmd.data.roomData)
		room = RoomInfo.CreateRoom(roomdata)
	end
	if room == nil then
		UserInfo.SendCmd("Cmd.SysMessageMahjongCmd_S",{desc="进入房间失败"},laccount)
		userInfo:SendCmdToMe("Cmd.EnterMahjongCmd_S",{resultCode=2,})--这里不确定是否要加
		return
	end
	if laccount == nil then
		room:Error("请求创建返回时发现玩家已下线:"..uid)
		return
	end
	userInfo = UserInfo.UserIntoRoom(room, laccount) 
	local ret = room:DoEnterMahjong(userInfo)
	if ret == false then
		userInfo:SendCmdToMe("Cmd.EnterMahjongCmd_S",{resultCode=1,})
		return
	end
end

Lby.CmdCreateRoomRoomLobbyCmd_S= function(cmd)
	print("CmdCreateRoomRoomLobbyCmd_S=="..table2json(cmd))
	local uid = cmd.data.uid
	local userdata = nil
	if cmd.data.userDataList then
		for k,v in pairs(cmd.data.userDataList) do
			local tempuserdata = json2table(v)
			tempuserdata = UserInfo.CreateUserData(tempuserdata.uid,tempuserdata)
			userdata = tempuserdata
		end
	else
		userdata = UserInfo.CreateUserData(uid,json2table(cmd.data.userData))
	end
	local data = {
		uid = uid,
		roomId = cmd.data.roomId,
		flag = cmd.data.flag,
	}
	if cmd.data.roomId ~= 0 then
		local room = RoomInfo.GlobalRoomInfoMap[cmd.data.roomId]
		if room == nil then
			local roomdata = json2table(cmd.data.roomData)
			room = RoomInfo.CreateRoom(roomdata)
		end
		if room == nil then
			data.ret = 1
			data.desc = "创建房间失败"
			ChessToLobbyMgr.SendCmdToLobby("Cmd.CreateRoomRoomLobbyCmd_C",data)
			return 
		end
		if cmd.data.winDiamond then
			room.data.winDiamond = cmd.data.winDiamond
		end
		if cmd.data.needDiamond then
			room.data.needDiamond = cmd.data.needDiamond
		end
		room.data.hostType = cmd.data.hostType
		room.data.sendFlower = cmd.data.sendFlower --扣费
	else
		userdata.roomdata = {}
		if cmd.data.winDiamond then
			userdata.roomdata.winDiamond = cmd.data.winDiamond
		end
		if cmd.data.needDiamond then
			userdata.roomdata.needDiamond = cmd.data.needDiamond
		end
		if cmd.data.exercise then
			userdata.roomdata.exercise = cmd.data.exercise
		end
		userdata.roomdata.hostType = cmd.data.hostType
		userdata.roomdata.sendFlower = cmd.data.sendFlower --扣费
	end
	ChessToLobbyMgr.SendCmdToLobby("Cmd.CreateRoomRoomLobbyCmd_C",data)
end

Lby.CmdUserDiamondChangeLobbyCmd_S = function(cmd)
	local userInfo = UserInfo.GetUserInfoById(cmd.data.uid)   
	if userInfo ~= nil then
		userInfo:Info("钻石发生变化:"..userInfo.data.mahjong.diamond .. ":" .. cmd.data.diamond .. ":" .. cmd.data.change)
		userInfo.data.mahjong.card = cmd.data.card or userInfo.data.mahjong.card
		userInfo.data.mahjong.diamond = cmd.data.diamond or userInfo.data.mahjong.diamond
		return
	end
end

Lby.CmdChangeUserNbrLobbyCmd_CS = function(cmd)
	local room = RoomInfo.GlobalRoomInfoMap[cmd.data.roomId]
	if room ~= nil then
		room:Info("改变房间人数设置:"..room.data.usernbr .. ":" .. cmd.data.userNbr)
		if room.data.usernbr == cmd.data.userNbr then
			return
		end
		if room:ChangeUserNbr(cmd.data.userNbr) == false then
			ChessToLobbyMgr.SendCmdToLobby("Cmd.ChangeUserNbrLobbyCmd_CS",cmd.data)
		end
	else
		unilight.error("ChangeUserNbrLobbyCmd_CS err 找不到房间:"..cmd.data.roomId)
	end
end

Lby.CmdUserDiamondWinLobbyCmd_CS = function(cmd)
	local userInfo = UserInfo.GetUserInfoById(cmd.data.uid)   
	if userInfo ~= nil then
		if cmd.data.ret then
			userInfo:SendFailToMe("已经在房间,不能再次进入")
		else
			if not cmd.data.typ or cmd.data.typ == 1 then --TODO
			elseif cmd.data.typ ==2 then
			elseif cmd.data.typ ==3 then
			elseif cmd.data.typ ==4 then
			end
			if cmd.data.change > 0 then
				userInfo:SendFailToMe("获得钻石:"..cmd.data.change)
			else
				userInfo:SendFailToMe("扣除钻石:"..cmd.data.change)
			end
		end
		userInfo:Info("输赢钻石:"..cmd.data.change)
		return
	end
end

-- 大厅主动通知游戏解散房间
Lby.CmdActiveRemoveLobbyCmd_S = function(cmd)
	if cmd.data == nil or cmd.data.roomId == nil then
		unilight.error("大厅通知游戏服解散房间 参数有误")
		return
	end
	local roomId = cmd.data.roomId
	-- 各自游戏服解散逻辑自己实现
	if RoomInfo ~= nil and RoomInfo.LobbyActiveRemove ~= nil and type(RoomInfo.LobbyActiveRemove) == "function" then
		unilight.debug("大厅通知游戏服解散房间 已交由各自游戏服处理")
		RoomInfo.LobbyActiveRemove(roomId)
	else
		unilight.warn("大厅通知游戏服解散房间 当前游戏服未实现该函数:RoomInfo.LobbyActiveRemove")
	end
end
Lby.CmdUserCardChangeLobbyCmd_CS = function(cmd)
	local userInfo = UserInfo.GetUserInfoById(cmd.data.uid)   
	if userInfo ~= nil then
		if cmd.data.ret then
			userInfo:SendFailToMe("已经在房间,不能再次进入")
		else
			if not cmd.data.typ or cmd.data.typ == 1 then --TODO
			elseif cmd.data.typ ==2 then
			elseif cmd.data.typ ==3 then
			elseif cmd.data.typ ==4 then
			end
			if cmd.data.change > 0 then
				userInfo:SendFailToMe("获得房卡:"..cmd.data.change)
			else
				userInfo:SendFailToMe("扣除房卡:"..cmd.data.change)
			end
		end
		userInfo:Info("输赢钻石:"..cmd.data.change)
		return
	end
end
