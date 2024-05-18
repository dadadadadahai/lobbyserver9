-- 单独处理红包模块逻辑
-- 红包发送请求
Net.CmdPri_LuckMoneySend_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.Pri_LuckMoneySend_S"
	if cmd.data == nil or cmd.data.chips == nil or cmd.data.uidReceive == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[3].id,
			desc = TableServerReturnCode[3].desc,
		}
		return res
	end
	if table.empty(res) == false then
		return res
	end
	local data = cmd.data
	local uidRev = data.uidReceive
	local chips = data.chips
	local bless = data.bless or ""
	local userInfo = chessuserinfodb.RUserInfoGet(uidRev)
	if userInfo == nil then
		res["data"] = {
			resultCode = 1, 
			desc = "目标玩家不存在",
		}
		return res
	end
	local uid = laccount.Id
	local bOk, luckMoney = Pri_LuckMoneyMgr.CmdSendLuckMoney(uid, uidRev, chips, bless)
	luckMoney = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
	if bOk == false then
		res["data"] = {
			resultCode = TableServerReturnCode[7].id,
			desc = uid .. TableServerReturnCode[7].desc,
		}
		return res
	end

	-- 检查目标用户是否在线，在线就推送
	local send = {}
	send["do"] = "Cmd.Pri_LuckMoneySend_Brd"	
	send["data"] = {
		luckMoney = luckMoney
	}
	unilight.success(laccount, send)

	local laccoutRev = go.roomusermgr.GetRoomUserById(uidRev) 
	if laccoutRev ~= nil and uidRev ~= uid then
		unilight.success(laccoutRev, send)
	else
		unilight.info("给玩家发的红包，但是对方不在线" .. uidRev)
	end
	
	res["data"] = {
		resultCode = TableServerReturnCode[1].id,
		desc = TableServerReturnCode[1].desc,
		remainder = luckMoney.sendInfo.remainder, 
	}
	return res
end

-- 玩家领取
Net.CmdPri_LuckMoneyReceive_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.Pri_LuckMoneyReceive_Brd"
	if cmd.data == nil or cmd.data.luckMoney == nil or cmd.data.luckMoney._id == nil then
		res["data"] = {
			resultCode = TableServerReturnCode[3].id,
			desc = TableServerReturnCode[3].desc,
		}
		return res
	end
	local data = cmd.data
	local _id = data.luckMoney._id
	local uid = laccount.Id
	local bOk, remainder, luckMoney = Pri_LuckMoneyMgr.CmdRevceiveLuckMoney(uid, _id)
	if bOk == false then
		res["data"] = {
			resultCode = 1,
			desc = "已领取过，或红包不存在",
		}
		return res
	end
	
	luckMoney = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
	res["data"] = {
		resultCode = TableServerReturnCode[1].id,
		desc = TableServerReturnCode[1].desc,
		luckMoney = luckMoney,
		remainder = remainder,
		uid = uid,
	}
	-- 要通知已被推送
	local laccoutSnd = go.roomusermgr.GetRoomUserById(luckMoney.sendInfo.uid) 
	if laccoutSnd ~= nil and luckMoney.sendInfo.uid ~= uid then
		unilight.success(laccoutSnd, res)
	end
	return res
end

-- 玩家查询
Net.CmdPri_LuckMoneyRecord_C = function(cmd, laccount)
	local uid = laccount.Id
	local res = {}
	res["do"] = "Cmd.Pri_LuckMoneyRecord_S"
	local luckMoneyRev, luckMoneyWat, luckMoneySnd, luckMoneyRtn = Pri_LuckMoneyMgr.CmdCheckLuckMoney(uid)
	local luckMoneyRevClient = {} 
	for id, luckMoney in ipairs(luckMoneyRev)do
		local luckMoneyClient = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
		table.insert(luckMoneyRevClient, luckMoneyClient)
	end
	local luckMoneyRtnClient = {} 
	for id, luckMoney in ipairs(luckMoneyRtn)do
		local luckMoneyClient = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
		table.insert(luckMoneyRtnClient, luckMoneyClient)
	end
	local luckMoneySndClient = {} 
	for id, luckMoney in ipairs(luckMoneySnd)do
		local luckMoneyClient = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
		table.insert(luckMoneySndClient, luckMoneyClient)
	end
	local luckMoneyWatClient = {} 
	for id, luckMoney in ipairs(luckMoneyWat)do
		local luckMoneyClient = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
		table.insert(luckMoneyWatClient, luckMoneyClient)
	end
	res["data"] = {
		luckMoneyWat = luckMoneyWatClient,
		luckMoneySnd = luckMoneySndClient,
		luckMoneyRev = luckMoneyRevClient,
		luckMoneyRtn = luckMoneyRtnClient,
	}
	return res
end

Net.CmdPri_LuckMoneyQueryOne_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.Pri_LuckMoneyQueryOne_S"

	if cmd.data == nil or cmd.data._id == nil then
		res["data"] = {
			resultCode = 1,
			desc = "缺少红包_id"
		}
	end
	local _id = cmd.data._id
	local bOk, luckMoney = Pri_LuckMoneyMgr.CmdLuckMoneyGetById(_id) 
	if bOk == false then
		res["data"] = {
			resultCode = 1,
			desc = "红包不存在"
		}
	end
	local luckMoney = Pri_LuckMoneyMgr.LuckMoneyConstuct(luckMoney) 
	res["data"] = {
			resultCode = 0,
			desc = "ok", 
			luckMoney = luckMoney,
	}	
	return res
end
