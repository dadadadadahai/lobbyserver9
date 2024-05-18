module('chesstcplib', package.seeall)

-- room
function TcpRoomCreate(laccount)
	local room = go.roommgr.CreateRoom()
	room.Owner = laccount
	return room
end

function TcpRoomDestroy(room)
	local id = room.Id
	go.roommgr.DestroyRoom(id)
end

-- addUserToRoom
function TcpUserRoomIn(room, laccount)
	local oldAccount = room.Rum.GetRoomUserById(laccount.Id)
	if oldAccount ~= nil then
		TcpUserRoomOut(room, oldAccount)
	end
	laccount.RoomCur = room
	return room.Rum.AddRoomUser(laccount)
end

function TcpUserRoomOut(room, laccount)
	local oldAccount = room.Rum.GetRoomUserById(laccount.Id)
	if oldAccount ~= nil then
		room.Rum.RemoveRoomUser(oldAccount)
	end
	return true
end

-- broadcast
function TcpRoomInfoBrd(room, doinfo, data)
	local msg = MsgConstruct(doinfo, data)
	room.BroadcastString(msg)
end

function TcpRoomInfoBrdExceptMe(room, laccount, doinfo, data)
	local msg = MsgConstruct(doinfo, data)
	local  uid = laccount.GetId()
	room.BroadcastStringExceptMe(msg, uid)
end

function TcpRoomInfoBrdExceptOne(room, uid, doinfo, data)
	local msg = MsgConstruct(doinfo, data)
	room.BroadcastStringExceptMe(msg, uid)
end


function MsgConstruct(doinfo, data)
	local brd = {}
	brd["do"] = doinfo
	brd["data"] = data

	local msg = json.encode(brd)
	return msg
end

function TcpRoomUserLogout(roomuser)
	--if nil == roomuser then return
	--TODO:增加相应逻辑
end

function TcpLaccountGet(uid)
	return go.roomusermgr.GetRoomUserById(uid)
end

-- 提供了一个tcp单发接口
function TcpMsgSendToMe(uid, doinfo, data)
	local res = {}
	res["do"] = doinfo
	res["data"] = data
	local tcpAccount = go.roomusermgr.GetRoomUserById(uid)
	if tcpAccount == nil then
		--unilight.info("TcpMsgSendToMe :uid tcpAccount is null")
		return false
	end
	unilight.success(tcpAccount, res)
end

function TcpMsgSendEveryOne(doinfo, data)
	local msg = MsgConstruct(doinfo, data)
	go.roomusermgr.BroadcastString(msg)
end

--tcp demo
Do.TestTcpReq = function(req, laccount)
	local cmd = unilight.getreq(req)
	local res = {}
	res["do"] = "Cmd.TestTcpRes"
	res["data"] = "testTcp"
	-- testRoomCreate
	local room = Tcp.TcpRoomCreate(laccount)
	-- RoomBroadCast
	TcpUserRoomIn(room, laccount)				--create之后还需将该玩家加入房间
	TcpRoomInfoBrd(room, res["do"], res["data"])	--群发接口
	--return

	unilight.success(laccount, res) --success下函数包装了json.encode 无需手动调用
end
