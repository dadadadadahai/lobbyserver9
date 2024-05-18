module('TaskShareInFriendgroup', package.seeall)  

function CmdTaskInfoGet(uid, taskInfo)
	local taskId = taskInfo.taskid
	local conditionCfg = TableTaskConfig[taskId].taskCondition
	local subTaskAllNbr = 0
	local gameId = 0
	local condition = {}
	for i, v in ipairs(conditionCfg) do
		condition[v.key] = v.value	
	end
	local share = condition.share	
	local resTask = {
		taskId = taskId,
		subTaskAllNbr = share,
		taskStatus = taskInfo.taskstatus,
	}
	-- 当活动没有开始时
	if taskInfo.taskstatus == TaskMgr.TASK_STATUS_UNSTART then
		resTask.subTaskCompletedNbr = 0	
		return resTask
	end

	if taskInfo.taskstatus >= TaskMgr.TASK_STATUS_COMPLETE then
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr 
		return resTask
	end

	-- 查看活动最新的状态
	local taskLog = taskInfo.tasklog	
	if #taskLog > 0 then
		resTask.taskStatus = TaskMgr.TASK_STATUS_COMPLETE 
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr	
	else
		resTask.subTaskCompletedNbr = 0 
		resTask.taskStatus = TaskMgr.TASK_STATUS_PROGRESS 
	end
	return resTask
end

function CmdDoTask(uid, taskInfo, taskData)
	taskInfo.tasklog = taskInfo.tasklog or {}
	table.insert(taskInfo.tasklog, os.time())
	local resTask = CmdTaskInfoGet(uid, taskInfo)
	return true,  taskInfo, resTask 
end
