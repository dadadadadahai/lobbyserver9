
-- 获取任务列表
Net.CmdGetTaskListTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskListTaskCmd_S"

	local uid = laccount.Id
	local userTasks = TaskMgr.GetTaskList(uid)

	res["data"] = {
		resultCode = 0,
		desc = "获取任务列表成功",
		taskInfo = userTasks,
	}
	return res
end

-- 领取指定任务奖励
Net.CmdGetTaskRewardTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetTaskRewardTaskCmd_S"
	if cmd.data == nil or cmd.data.taskId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误",
		}
		return res
	end
	
	local taskId = cmd.data.taskId
	local uid = laccount.Id

	local ret, desc, userTasks, remainder, reward = TaskMgr.GetTaskReward(uid, taskId)
	res["data"] = {
		resultCode = ret,
		desc = desc,
		taskInfo = userTasks,
		remainder = remainder, 
		reward = reward
	}
	return res
end