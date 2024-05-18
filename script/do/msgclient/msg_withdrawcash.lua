-- 请求兑换信息
Net.CmdUserWithdrawCashInfoRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserWithdrawCashInfoReturnSgnCmd_S"
	local uid = laccount.Id
	local withdrawCashData = WithdrawCash.CmdUserWithdrawCashInfoGet(uid)
	res["data"] = withdrawCashData
	return res
end

-- 用户兑换操作
Net.CmdUserWithdrawCashRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserWithdrawCashInfoReturnSgnCmd_S"
	local uid = laccount.Id
	local dinheiro = cmd.data.dinheiro
	local type = cmd.data.type
	local withdrawCashData = WithdrawCash.CmdUserWithdrawCashRequest(uid, dinheiro, type)
	res["data"] = withdrawCashData
	return res
end

-- 用户兑换历史记录
Net.CmdUserWithdrawCashHistoryRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserWithdrawCashHistoryReturnSgnCmd_S"
	local uid = laccount.Id
	local withdrawCashData = WithdrawCash.CmdUserWithdrawCashHistoryRequest(uid, dinheiro)
	res["data"] = withdrawCashData
	return res
end

-- 用户兑换CPF
Net.CmdUserWithdrawCashCPFRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserWithdrawCashCPFReturnSgnCmd_S"
	local uid = laccount.Id
	local telephone = cmd.data.telephone
	local email = cmd.data.email
	local cpf = cmd.data.cpf
	local name = cmd.data.name
	local chavePix = cmd.data.chavePix
	local flag = cmd.data.flag			-- 0 是只有真实姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
	local withdrawCashData = WithdrawCash.CmdUserWithdrawCashCPFRequest(uid, cpf, name, flag, chavePix, email, telephone)
	res["data"] = withdrawCashData
	return res
end

-- 用户单独绑定CPF
Net.CmdUserWithdrawCashOnlyCPFRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserWithdrawCashOnlyCPFReturnSgnCmd_S"
	local uid = laccount.Id
	local cpf = cmd.data.cpf
	local withdrawCashData = WithdrawCash.ChangeWithdrawcashCpfInfo(uid, nil, cpf)
	res["data"] = withdrawCashData
	return res
end