
--场景消息
Net.CmdTeamRebateInfoRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.TeamRebateInfoRequestSgnCmd_S"
	local TeamRebateData = TeamRebate.TeamRebateInfo(uid)
	res["data"] = TeamRebateData
	return res
end
--领取消息
Net.CmdTeamRebateGetRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.TeamRebateGetRequestSgnCmd_S"
	local TeamRebateData = TeamRebate.TeamRebateGet(uid)
	res["data"] = TeamRebateData
	return res
end