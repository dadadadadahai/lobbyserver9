module('TaskLoginOverThreshold', package.seeall)  

function CmdTaskInfoGet(uid, taskInfo)
	local taskId = taskInfo.taskid
	local conditionCfg = TableTaskConfig[taskId].taskCondition
	local subTaskAllNbr = 0
	local gameId = 0
	local condition = {}
	for i, v in ipairs(conditionCfg) do
		condition[v.key] = v.value	
	end
	local threshold = condition.loginNbr
	local resTask = {
		taskId = taskId,
		subTaskAllNbr = threshold,
		taskStatus = taskInfo.taskstatus,
	}
	
	if taskInfo.taskstatus == TaskMgr.TASK_STATUS_UNSTART then
		resTask.subTaskCompletedNbr = 0	
		return resTask
	end

	if taskInfo.taskstatus >= TaskMgr.TASK_STATUS_COMPLETE then
		resTask.subTaskCompletedNbr = threshold 
		return resTask
	end
	resTask.subTaskCompletedNbr = RecentLogintDayNumberGet(taskInfo)
	if resTask.subTaskCompletedNbr >= resTask.subTaskAllNbr then
		resTask.taskStatus = TaskMgr.TASK_STATUS_COMPLETE 
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr	
	else
		resTask.taskStatus = TaskMgr.TASK_STATUS_PROGRESS 
	end
	return resTask
end

function CmdDoTask(uid, taskInfo, taskData)
	local daySec = 60 * 60 * 24
	local index = math.floor(os.time()/daySec)
	taskInfo.tasklog[index] = 1
	local resTask = CmdTaskInfoGet(uid, taskInfo)
	return true, taskInfo, resTask
end

function RecentLogintDayNumberGet(taskInfo)
	local daySec = 60 * 60 * 24
	local taskLog = taskInfo.tasklog or {}
	local index = math.floor(os.time()/daySec)
	local count = 0
	while taskLog[index] ~= nil do 
		count = count + 1
		if count > 5 then
			break
		end
	end
	return count
end
