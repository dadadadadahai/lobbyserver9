
-- 获取排行榜列表
Net.CmdGetRankListRankCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetRankListRankCmd_S"
	local roomId  	= cmd.data.roomId

	if roomId == nil then
		res["data"] = {
			ret 	= 1,
			desc 	= "参数不足",
		}		
	end

	-- 进入房间
	local ret, desc, startTime, endTime, nextStartTime, nextEndTime, rankInfoList = RankMgr.GetRankInfoList(roomId)

	-- 返回给玩家房间基本信息
	res["data"] = {
		ret 			= ret,
		desc 			= desc,
		curStartTime 	= startTime,
		curEndTime 		= endTime,
		nextStartTime 	= nextStartTime,
		nextEndTime 	= nextEndTime,
		rankInfoList 	= rankInfoList,
	}
	return res 
end