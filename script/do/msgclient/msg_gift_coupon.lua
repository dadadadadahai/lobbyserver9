-- 处理奖券相关协议

-- 兑换奖券
Net.CmdExchangeGiftCouponCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	local res = {}
	res["do"] = "Cmd.ExchangeGiftCouponCmd_S"

	if cmd.data == nil or cmd.data.exchangeId == nil or cmd.data.exchangeNbr == nil then
		res["data"] = {
			ret 	= 1,
			desc 	= "参数有误" 
		}
		return res
	end

	local ret, desc, remainder, exchangeGood = GiftCouponMgr.Exchange(uid, cmd.data.exchangeId, cmd.data.exchangeNbr)
	res["data"] = {
		ret 					= ret,
		desc					= desc,
		surplusGiftCoupon		= remainder,
		exchangeGood 			= exchangeGood, 
	}
	return res
end

-- 获取个人资料
Net.CmdGetPersonalDataGiftCouponCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	local res = {}
	res["do"] = "Cmd.GetPersonalDataGiftCouponCmd_S"

	local ret, desc, personalData = GiftCouponMgr.GetPersonalData(uid)
	res["data"] = {
		ret 			= ret,
		desc			= desc,
		personalData 	= personalData, 
	}
	return res
end

-- 设置个人资料
Net.CmdSetPersonalDataGiftCouponCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	local res = {}
	res["do"] = "Cmd.SetPersonalDataGiftCouponCmd_S"

	if cmd.data == nil or cmd.data.personalData == nil then
		res["data"] = {
			ret 	= 1,
			desc 	= "参数有误" 
		}
		return res
	end

	local ret, desc, personalData = GiftCouponMgr.SetPersonalData(uid, cmd.data.personalData)
	res["data"] = {
		ret 			= ret,
		desc			= desc,
		personalData 	= personalData, 
	}
	return res
end

-- 获取兑换记录
Net.CmdGetRecordsGiftCouponCmd_C = function(cmd, laccount)
	local uid = laccount.Id

	local res = {}
	res["do"] = "Cmd.GetRecordsGiftCouponCmd_S"

	local ret, desc, exchangeRecords = GiftCouponMgr.GetRecords(uid)
	res["data"] = {
		ret 				= ret,
		desc				= desc,
		exchangeRecords 	= exchangeRecords, 
	}
	return res
end