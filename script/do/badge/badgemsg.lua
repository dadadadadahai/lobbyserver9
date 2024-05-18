--场景消息
Net.CmdBadgeInfoRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.BadgeInfoRequestSgnCmd_S"
	local badgeData = Badge.BadgeInfo(uid)
	res["data"] = badgeData
	return res
end

--领取消息
Net.CmdBadgeGetRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.BadgeGetRequestSgnCmd_S"
	local badgeData = Badge.GetBadgeReward(uid)
	res["data"] = badgeData
	return res
end