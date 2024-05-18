module('TaskBeBankerNbrOverThreshold', package.seeall)  
-- 处理玩家坐庄相关奖励

function CmdTaskInfoGet(uid, taskInfo)
	local taskId = taskInfo.taskid
	local conditionCfg = TableTaskConfig[taskId].taskCondition
	local subTaskAllNbr = 0
	local gameId = 0
	local condition = {}
	for i, v in ipairs(conditionCfg) do
		condition[v.key] = v.value	
	end
	local threshold = condition.banker	
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
	local gameId = condition.gameId
	local timeStamp = taskInfo.begintimestamp
	resTask.subTaskCompletedNbr = chessprofitbet.CmdGameBankerNmuberGetByGameIdUid(uid, gameId, timeStamp) 
	if resTask.subTaskCompletedNbr >= resTask.subTaskAllNbr then
		resTask.taskStatus = TaskMgr.TASK_STATUS_COMPLETE 
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr	
	else
		resTask.subTaskCompletedNbr = 0 
		resTask.taskStatus = TaskMgr.TASK_STATUS_PROGRESS 
	end
	return resTask
end
