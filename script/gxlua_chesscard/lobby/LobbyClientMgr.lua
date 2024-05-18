-- 与大厅通讯 相关接口
module('ChessToLobbyMgr', package.seeall)

-- 筹码警告阈值
CHIPS_WARN_THRESHOLD = 1000

-----------------------------------------淘金---------------------------------------------

-- 检测是否筹码不足 需要向大厅发送警告(这里只是获取警告数据 并不直接发送)
function CheckSendChipsWarnToLobby(uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid) 
	if table.empty(userInfo) then
		unilight.error("script/gxlua_chesscard/lobby/chesstolobbymgr.lua err userinfo is null")
		return 
	end
	-- 身上的钱 包括三部分 筹码+
	local chips = userInfo.property.chips + userInfo.property.bankerchips + userInfo.bank.chips

	if chips < CHIPS_WARN_THRESHOLD then 
		local data = {
			uid 		= uid,
			remainder 	= chips,
		}	 
		return data
	end
end

-- 向大厅发送筹码警告
function SendChipsWarnToLobby(bankruptInfo)
	if bankruptInfo == nil then
		return 
	end
	for i,data in ipairs(bankruptInfo) do
		SendCmdToLobby("Cmd.SendChipsWarnLobbyCmd_C",data)
	end
end

-----------------------------------------麻将---------------------------------------------
-- 麻将大厅使用 通知大厅当前房间解散
function SendRemoveRoomToLobby(roomId, hostTip, redPack)
	local data = {
		roomId = roomId,
		hostTip = hostTip,
		redPack = redPack,
	}
	return SendCmdToLobby("Cmd.SendRemoveRoomLobbyCmd_C",data)
end

-- 麻将大厅使用 有玩家离开房间 
function SendLeaveRoomToLobby(uid,roomid)
	local data = {
		uid 	= uid,
		roomId 	= roomid,
	}
	return SendCmdToLobby("Cmd.SendLeaveRoomLobbyCmd_C",data)
end

-- 麻将大厅使用 有玩家进入房间
function SendEnterRoomToLobby(roomId, uid, pos)
	local data = {
		roomId 	= roomId,
		uid 	= uid,
		pos 	= pos,
	}
	return SendCmdToLobby("Cmd.SendEnterRoomLobbyCmd_C",data)
end
function SendCmdToLobby(doinfo,data)
	if go.lobby == nil then
		return false
	end
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	local s = table2json(send)
	local ret = go.lobby.SendString(s)
	-- go.lobby.Info("SendCmdToLobby:" .. s)
	return ret
end

-----------------------------------------风驰---------------------------------------------
-- 风驰大厅使用 让大厅去广播
function SendBroadToLobby(uid, nickName, bMan, chatPos, chatType, brdInfo)
	local data = {
		uid 		= uid,
		nickName 	= nickName,
		bMan 		= bMan,
		chatPos 	= chatPos,
		chatType 	= chatType,
		brdInfo 	= brdInfo,
	}
	return SendCmdToLobby("Cmd.SendBroadLobbyCmd_C",data)
end

