-- 积分榜消息相关处理

-- 玩家积分榜进入所需数据
Net.CmdHotNewsInfoRequestHnsCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.HotNewsInfoReturnHnsCmd_S"
	local uid = laccount.Id
	local hotNewsInfo = HotNews.HotNewsInfoGet(uid)
	res["data"] = {
		activityList = hotNewsInfo.activityList,
	}
	return res
end