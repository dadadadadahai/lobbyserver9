-- 阿拉丁模块相关

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