
-- 获取任务列表
Net.CmdGetTaskListDaysTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskListDaysTaskCmd_S"

	local uid = laccount.Id
	DaysTaskMgr.GetTaskList(uid)

end

-- 领取指定任务奖励
Net.CmdGetTaskRewardDaysTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskRewardDaysTaskCmd_S"
	if cmd.data == nil or cmd.data.taskId == nil then
		res["data"] = {
			errno = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local taskId = cmd.data.taskId
	local uid = laccount.Id

	DaysTaskMgr.GetTaskReward(uid, taskId)
end

--请求领取通行证奖励
Net.CmdGetPassRewardTask_C = function(cmd, laccount)

	local res = {}
	res["do"] = "Cmd.CmdGetPassRewardTask_S"
	if cmd.data == nil or cmd.data.level == nil then
		res["data"] = {
			errno = 1,
			desc = "参数有误",
		}
		return res
	end

	local uid = laccount.Id
    local level = cmd.data.level
    local getType = cmd.data.getType
    DaysTaskMgr.GetPassTaskReward(uid, level, getType)

end

--请求花宝石完成任务
Net.CmdUseDiamondFinishTask_C = function(cmd, laccount)
    local uid = laccount.Id
    DaysTaskMgr.UseDiamondFinishTask(uid, cmd.data.taskId)
end


--请求浇花
Net.CmdReqWaterFlowerTask_C = function(cmd, laccount)

	local res = {}
	res["do"] = "Cmd.CmdReqWaterFlowerTask_S"
	if cmd.data == nil or cmd.data.flowerId == nil or cmd.data.flowerType == nil  then
		res["data"] = {
			errno = 1,
			desc = "参数有误",
		}
		return res
	end
    local uid = laccount.Id
    DaysTaskMgr.ReqWaterFlower(uid, cmd.data.flowerType, cmd.data.flowerId)
end

-- 前往 做任务
Net.CmdToDoDaysTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ToDoDaysTaskCmd_S"
	if cmd.data == nil or cmd.data.gameId == nil then
		res["data"] = {
			errno = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local gameId = cmd.data.gameId
	local uid = laccount.Id

	local ret, desc, subGameId, roomType = DaysTaskMgr.GetCorrectToGo(uid, gameId)
	res["data"] = {
		errno = ret,
		desc = desc,
		gameId = gameId,
		subGameId = subGameId, 
		roomType = roomType
	}
	return res
end

--请求购买2倍加速卡
Net.CmdReqBuyFastBuffTask_C = function(cmd, laccount)
	local uid = laccount.Id
    DaysTaskMgr.ReqBuyFastBuff(uid)
end

--请求领取通行证保险箱奖励
Net.CmdGetPassBoxReward_C = function(cmd, laccount)
    DaysTaskMgr.GetPassBoxReward(laccount.Id)
end
