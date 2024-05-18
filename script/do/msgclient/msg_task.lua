-- 请求任务列表 
function TestTask()
end

Net.CmdUserTaskListRequestTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserTaskListReturnTaskCmd_S"
	local uid = laccount.Id
	local taskInfo = TaskMgr.CmdUserTaskInfoListGet(uid)
	res["data"] = {
		resultCode = 0, 
		desc = "ok", 
		taskInfo = taskInfo,
	}
	return res
end

-- 请求做任务 
Net.CmdUserDoTaskRequestTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserDoTaskReturnTaskCmd_S"
	if cmd.data == nil or cmd.data.taskId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不完整",
		}
		return res
	end
	local taskId = cmd.data.taskId
	local uid = laccount.Id

	local bOk, desc, taskInfo = TaskMgr.CmdUserDoTaskRequire(uid, taskId)
	if bOk ~= true then
		res["data"] = {
			resultCode = 2,
			desc = desc, 
		}
		return res
	end

	res["data"] = {
		resultCode = 0,
		taskInfo = taskInfo,
	}
	return res
end

-- 任务已完成领取任务奖励
Net.CmdUserTaskRewardRequestTaskCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserTaskRewardReturnTaskCmd_S"
	if cmd.data == nil or cmd.data.taskId == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不完整",
		}
		return res
	end
	local taskId = cmd.data.taskId
	local uid = laccount.Id
	local bOk, desc, taskInfo, remainder, reward = TaskMgr.CmdUserTaskRewardReceive(uid, taskId)
	if bOk ~= true then
		res["data"] = {
			resultCode = 2,
			desc = desc, 
		}
		return res
	end
	
	res["data"] = {
		resultCode = 0,
		desc = desc,
		taskInfo = taskInfo,
		remainder = remainder,
		reward = reward,
	}
	return res
end


--获得其它任务列表
Net.CmdGetTaskListOtherTask_C = function(cmd, laccount)
	local uid = laccount.Id
	OtherTaskMgr.GetTaskListInfo(uid)
end

--获得任务奖励
Net.CmdGetRewardOtherTask_C = function(cmd, laccount)
	local uid = laccount.Id
    local taskId = cmd.data.taskId 
	OtherTaskMgr.GetTaskReward(uid, taskId)
end

--首充动画已观看，告诉服务器
Net.CmdAlreadyLookOtherTask_C = function(cmd, laccount)
	local uid = laccount.Id
	OtherTaskMgr.SetAlreadyLook(uid)
end
