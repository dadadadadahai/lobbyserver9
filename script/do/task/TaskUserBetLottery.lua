module('TaskUserBetLottery', package.seeall)  
-- 统一接口更新最新的状态
function CmdTaskInfoGet(uid, taskInfo)
	local taskId = taskInfo.taskid
	local conditionCfg = TableTaskConfig[taskId].taskCondition
	local subTaskAllNbr = 0
	local gameId = 0
	local condition = {}
	for i, v in ipairs(conditionCfg) do
		condition[v.key] = v.value	
	end

	subTaskAllNbr = condition.betNbr	
	gameId = condition.gameId

	local resTask = {
		taskId = taskId,
		subTaskAllNbr = subTaskAllNbr,
		taskStatus = taskInfo.taskstatus,
	}
	-- 当活动没有开始时
	if taskInfo.taskstatus == TaskMgr.TASK_STATUS_UNSTART then
		resTask.subTaskCompletedNbr = 0	
		return resTask
	end
	-- 当状态为完成或者已领取
	if taskInfo.taskstatus >= TaskMgr.TASK_STATUS_COMPLETE then
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr
		return resTask
	end
	local timestamp = taskInfo.begintimestamp	
	-- 计算玩家赢取，或者下注次数
	if gameId == 0 or gameId == nil then
		resTask.subTaskCompletedNbr = chessprofitbet.CmdAllGamePlayNmuberGetByUid(uid, timestamp)	
	else
		resTask.subTaskCompletedNbr = chessprofitbet.CmdGamePlayNmuberGetByGameIdUid(uid, gameId, timestamp)	
	end
	if resTask.subTaskCompletedNbr >= resTask.subTaskAllNbr then
		resTask.taskStatus = TaskMgr.TASK_STATUS_COMPLETE 
		resTask.subTaskCompletedNbr = resTask.subTaskAllNbr	
	else
		resTask.taskStatus = TaskMgr.TASK_STATUS_PROGRESS 
	end
	return resTask
end
