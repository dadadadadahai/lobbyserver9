module('TaskChipsOverThreshold', package.seeall)  
-- 处理当筹码达到指定阈值时，奖励金币

function CmdTaskInfoGet(uid, taskInfo)
	local taskId = taskInfo.taskid
	local conditionCfg = TableTaskConfig[taskId].taskCondition
	local subTaskAllNbr = 0
	local gameId = 0
	local condition = {}
	for i, v in ipairs(conditionCfg) do
		condition[v.key] = v.value	
	end
	local threshold = condition.remainder	
	local subTaskAllNbr = threshold 
	local resTask = {
		taskId = taskId,
		subTaskAllNbr = threshold,
		taskStatus = taskInfo.taskstatus
	}

	if taskInfo.taskstatus == TaskMgr.TASK_STATUS_UNSTART then
		resTask.subTaskCompletedNbr = 0	
		return resTask
	end

	if taskInfo.taskstatus >= TaskMgr.TASK_STATUS_COMPLETE then
		resTask.subTaskCompletedNbr = threshold 
		return resTask
	end
	resTask.subTaskCompletedNbr = 0	
	local userInfo = chessuserinfodb.RUserInfoGet(uid) 
	if table.empty(userInfo) == false  then
		resTask.subTaskCompletedNbr = userInfo.max.maxchips	
	end
	if resTask.subTaskCompletedNbr >= resTask.subTaskAllNbr then
		resTask.taskStatus = TaskMgr.TASK_STATUS_COMPLETE 
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr	
	else
		resTask.taskStatus = TaskMgr.TASK_STATUS_PROGRESS 
	end
	return resTask
end
