module('TaskMgr', package.seeall)  
-- 任务状态机
TASK_STATUS_UNSTART  = 0
TASK_STATUS_PROGRESS = 1
TASK_STATUS_COMPLETE = 2 
TASK_STATUS_RECEIVED = 3 

-- 表名
TABLE_NAME = "usertaskinfo" 
MapTaskProcess = {}

-- 这里统一添加活动处理函数回调
function TaskProcessFunctionInfo()
	MapTaskProcess[1] = TaskUserBetLottery           -- 进行20盘游戏 
	MapTaskProcess[2] = TaskShareInFriendgroup       -- 进行分享朋友圈一次
	MapTaskProcess[3] = TaskUserBetLottery           -- 进行货品30秒20盘 
	MapTaskProcess[4] = TaskBeBankerNbrOverThreshold -- 当庄家连续几次奖励 
	MapTaskProcess[5] = TaskChipsOverThreshold       -- 金币达到值奖励金币 
	MapTaskProcess[6] = TaskShareInFriendgroup       -- 进行分享朋友圈10次
	MapTaskProcess[7] = TaskOneRecharge              -- 任意充值送话费 
	MapTaskProcess[8] = TaskLoginOverThreshold       -- 连续登陆超过几天 
	MapTaskProcess[9] = TaskUserBetLottery           -- 进行50盘火拼30秒 
	MapTaskProcess[10] = TaskChipsOverThreshold      -- 金币达到值奖励金币 
	MapTaskProcess[11] = TaskOneRecharge             -- 任意充值送话费 
	MapTaskProcess[12] = TaskChipsOverThreshold      -- 金币达到值奖励金币 
end

-- 获取玩家已完成的任务情况
function UserTaskStatusGet(uid)
	TaskProcessFunctionInfo()
	local taskInfo = unilight.getdata(TABLE_NAME, uid)

	-- 对没有task信息的加上
	local bUpdate = false
	if table.empty(taskInfo) then
		bUpdate = true
		taskInfo = {
			_id = uid,
			uid = uid,
			taskindex = 1, -- 初始化时，从第一个活动开始
		}
	end

	if bUpdate == true then 
		unilight.savedata(TABLE_NAME, taskInfo)
	end

	taskInfo, bUpdate = AddTask(taskInfo)
	if bUpdate == true then 
		unilight.savedata(TABLE_NAME, taskInfo)
	end
	return taskInfo
end

-- 用来初始化动态增加活动相关数据表
function AddTask(taskInfo)
	local taskIndex = taskInfo.taskindex
	local bUpdate = false
	for id, task in ipairs(TableTaskConfig) do
		if taskInfo[task.id] == nil then
			bUpdate = true
			taskInfo[task.id] = {
				taskid = task.id,
				taskstatus = TASK_STATUS_UNSTART,
				breceived = false,
				begintimestamp = 0,
				tasklog = {}, -- 有的任务需要用到做任务的记录
			}
		end
	end

	-- 这里可能会出现动太加活动，这个时候就要把taskindex动态变化一点
	if taskInfo[taskIndex] ~= nil then
		if taskInfo[taskIndex].taskstatus == TASK_STATUS_UNSTART then
			bUpdate = true
			taskInfo[taskIndex].taskstatus = TASK_STATUS_PROGRESS
			taskInfo[taskIndex].begintimestamp = os.time()
		end
	end

	return taskInfo, bUpdate
end

-- 对外调用，返回当前任务列表
function CmdUserTaskInfoListGet(uid)
	local taskInfo = UserTaskStatusGet(uid)
	local resTaskInfo = {}
	local bUpdate = false
	local taskIndex = taskInfo.taskindex

	for id, task in ipairs(TableTaskConfig) do
		local subTaskInfo = taskInfo[task.id]
		local resSubTaskInfo = MapTaskProcess[task.id].CmdTaskInfoGet(uid, subTaskInfo)
		if resSubTaskInfo.taskStatus ~= subTaskInfo.taskstatus then
			bUpdate = true
			taskInfo[task.id].taskstatus = resSubTaskInfo.taskStatus

		end
		resTaskInfo[task.id] = resSubTaskInfo
	end

	if bUpdate == true then
		unilight.savedata(TABLE_NAME, taskInfo)
	end
	return resTaskInfo, taskInfo
end

-- 对外调用，当状态请求做任务
function CmdUserDoTaskRequire(uid, taskId)
	local taskList, taskInfo = CmdUserTaskInfoListGet(uid)	
	local subTaskInfo = taskInfo[taskId]	
	local resTaskInfo = taskList[taskId]
	if subTaskInfo == nil then
		return false, "taskId is null"
	end
	if taskInfo.taskindex ~= taskId then
		return false, "当前可完成的任务不正确，可完成的是" .. taskInfo.taskindex
	end
	if MapTaskProcess[taskId].CmdDoTask == nil then
		return false, "做任务失败"
	end

	local bOk, subTaskInfo, resTaskInfo = MapTaskProcess[taskId].CmdDoTask(uid, subTaskInfo, taskId)
	if bOk ~= true then
		return false, "做任务失败"
	end
	taskInfo[taskId] = subTaskInfo
	unilight.savedata(TABLE_NAME, taskInfo)
	return true, "ok", resTaskInfo
end

--
-- 对外调用，当状态为完成时，领取奖励
function CmdUserTaskRewardReceive(uid, taskId)
	local taskList, taskInfo = CmdUserTaskInfoListGet(uid)	
	local subTaskInfo = taskInfo[taskId]	
	local resTaskInfo = taskList[taskId]
	if subTaskInfo == nil then
		unilight.error("subTaskInfo is null")
		return false, "taskis is null"
	end

	if taskInfo.taskindex ~= taskId then
		unilight.error("当前可完成的任务不对 可完成任务是" .. taskInfo.taskindex .. "   请求领取的任务id" .. taskId )
		return false, "当前可完成的任务不正确，可完成的是" .. taskInfo.taskindex
	end

	local bOk, remainder, reward = TaskRewardReceive(uid, subTaskInfo)
	if bOk == true then
		-- 本任务状态更新
		taskInfo[taskId].breceived = true	
		taskInfo[taskId].taskstatus = TASK_STATUS_RECEIVED 
		resTaskInfo.taskStatus = TASK_STATUS_RECEIVED
		resTaskInfo.subTaskCompletedNbr = resTaskInfo.subTaskAllNbr
		-- 更新到下一个任务
		taskInfo.taskindex = taskId + 1
		if taskInfo[taskId+1] ~= nil then
			taskInfo[taskId+1].taskstatus = TASK_STATUS_PROGRESS
			taskInfo[taskId+1].begintimestamp = os.time()
		end
		unilight.savedata(TABLE_NAME, taskInfo)
		return true, "ok", resTaskInfo, remainder, reward 
	end

	return false, "领取失败", subTaskInfo
end

function TaskRewardReceive(uid, taskInfo)
	if taskInfo.taskstatus == TASK_STATUS_COMPLETE and taskInfo.breceived == false then
		local taskId = taskInfo.taskid
		local rewardCfg = TableTaskConfig[taskId].reward
		local rewardGoods = {}
		for i, rewardInfo in ipairs(rewardCfg) do
			local goodId = rewardInfo.goodId
			local goodNum = rewardInfo.goodNum
			local rewardItem = {
				goodId = goodId,
				goodNum = goodNum,
			}

			-- 物品获取调用统一接口
			BackpackMgr.GetRewardGood(uid, goodId, goodNum, Const.GOODS_SOURCE_TYPE.TASK)
			
			table.insert(rewardGoods, rewardItem)
		end

		local remainder = chessuserinfodb.RUserChipsGet(uid) 

		return true, remainder, rewardGoods 
	end
	return false
end
