-- 破产消息 相关处理

-- 领取破产补助
Net.CmdGetSubsidyBankruptcyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetSubsidyBankruptcyCmd_S"
	local uid = laccount.Id

	-- 领取破产补助
	local ret, desc, subsidy, remainder, surplus, nextTimes = BankRuptcyMgr.GetSubsidyBankruptcy(uid)

	res["data"] = {
		resultCode = ret,
		desc = desc,
		subsidy = subsidy,
		remainder = remainder,
		surplus = surplus,
		nextTimes = nextTimes,
	}

	return res
end

-- 单独请求 破产补助次数
Net.CmdGetSubsidyBankruptcyTimesCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetSubsidyBankruptcyTimesCmd_S"
	local uid = laccount.Id

	local ret, desc, surplus, all = BankRuptcyMgr.GetSubsidyBankruptcyTimes(uid)

	res["data"] = {
		resultCode = ret,
		desc = desc,
		surplus = surplus,
		all = all
	}

	return res
end