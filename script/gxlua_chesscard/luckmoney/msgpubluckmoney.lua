-- 公共红包消息处理

-- 发送红包
Net.CmdSendLuckMoneyPubCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.SendLuckMoneyPubCmd_S"
	if cmd.data == nil or cmd.data.chips == nil  or cmd.data.number == nil or cmd.data.bless == nil or cmd.data.number > cmd.data.chips then
		res["data"] = {
			resultCode = TableServerReturnCode[3].id,
			desc = TableServerReturnCode[3].desc,
		}
		return res
	end

	local uid = laccount.Id

	-- 判断是否在房间
	local roomId = RoomMgr.CmdRoomIdGet(uid)
	if roomId == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[6].id,
			desc = TableServerReturnCode[6].desc,
		}
		return res	
	end	

	local data = cmd.data
	local chips = data.chips
	local number = data.number
	local bless = data.bless or ""
	local uid = laccount.Id

	local bOk, remainder = PubLuckMoneyMgr.CmdSendLuckMoney(uid, roomId, chips, number, bless)
	if bOk == true then 
		res["data"] = {
			resultCode = TableServerReturnCode[1].id,
			desc = TableServerReturnCode[1].desc,
			remainder = remainder, 
		}
	else
		res["data"] = {
			resultCode = TableServerReturnCode[7].id,
			desc = TableServerReturnCode[7].desc,
			remainder = remainder, 
		}
	end
	return res
end

-- 领取红包
Net.CmdGetLuckMoneyPubCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetLuckMoneyPubCmd_S"
	if cmd.data == nil or  cmd.data._id == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[3].id,
			desc = TableServerReturnCode[3].desc,
		}
		return res
	end
	local data = cmd.data
	local _id = data._id
	local uid = laccount.Id

	local ret, sendInfo, money, remainder, bless = PubLuckMoneyMgr.CmdGetLuckMoney(uid, _id)

	res["data"] = {
		resultCode = TableServerReturnCode[ret].id,
		desc = TableServerReturnCode[ret].desc,
		sendInfo = sendInfo,
		get = money,
		remainder = remainder,
		_id = _id,
		bless = bless,
	}
	return res
end

-- 获取指定红包详情 （只包含 领取信息）
Net.CmdGetInfoLuckMoneyPubCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetInfoLuckMoneyPubCmd_S"

	if cmd.data == nil or cmd.data._id == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[3].id,
			desc = TableServerReturnCode[3].desc,
		}
		return res
	end

	local _id = cmd.data._id

	local ret, getInfo = PubLuckMoneyMgr.CmdLuckMoneyGetById(_id) 
	res["data"] = {
		resultCode = TableServerReturnCode[ret].id,
		desc = TableServerReturnCode[ret].desc,
		getInfo = getInfo,
	}
	return res
end


-- 获取红包记录
Net.CmdGetRecordLuckMoneyPubCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	local res = {}
	res["do"] = "Cmd.GetRecordLuckMoneyPubCmd_S"

	local SendluckMoney, rcvLuckMoney = PubLuckMoneyMgr.GetRecordLuckMoneyPub(uid)

	res["data"] = {
		luckMoneyRev = rcvLuckMoney,
		luckMoneySnd = SendluckMoney,
	}
	return res
end


