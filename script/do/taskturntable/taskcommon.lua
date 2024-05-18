module('TaskTurnTable', package.seeall) 
Table_TaskTurnTablePro = require "table/table_taskturntable_pro"
Table_TaskTurnTableTask = require "table/table_taskturntable_task"
DB_Name  = "taskturntable"
DB_Log_Name  = "taskturntablelog"
TaskTypes = {
	Login = 1,
	Recharge = 2,
}
-- 获取信息
function GetTaskTurnTableInfo(uid)
	-- 获取任务转盘模块数据库信息
	local taskturntableInfo = unilight.getdata(DB_Name, uid)
	-- 是否改变
	local isChange = false
	-- 没有则初始化信息
	if table.empty(taskturntableInfo) then
		taskturntableInfo = {
			_id = uid,
			taskList = GetTaskTableList(),
			collect = {},
			turnTableNum = 0,		-- 转盘次数
			turnTableProType = 1,	--目前共有 1 2 3 三种类型 默认1防止未初始化报错
			lastChangeTime = chessutil.ZeroTodayTimestampGet(),		--上一次更新时间
		}
		taskturntableInfo.collect['H'] = 0
		taskturntableInfo.collect['A'] = 0
		taskturntableInfo.collect['P'] = 0
		taskturntableInfo.collect['Y'] = 0
		unilight.savedata(DB_Name,taskturntableInfo)
	end
	-- 判断任务是否需要刷新
	if chessutil.DateDayDistanceByTimeGet(taskturntableInfo.lastChangeTime,chessutil.ZeroTodayTimestampGet()) > 0 then
		taskturntableInfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
		for _, taskinfo in ipairs(taskturntableInfo.taskList) do
			if taskinfo.isReset == 1 then
				taskinfo.taskvalue = 0
				taskinfo.status = 0
			end
		end
		-- 判断如果长度不同则需要添加配置表任务
		if #taskturntableInfo.taskList < #Table_TaskTurnTableTask then
			for id = #taskturntableInfo.taskList, #Table_TaskTurnTableTask do
				local taskinfo = Table_TaskTurnTableTask[id]
				local taskmaxvalue = 1
				table.insert(taskturntableInfo.taskList,{taskid = id, taskType = taskinfo.type, taskvalue = 0, taskmaxvalue = taskmaxvalue, isReset = taskinfo.isReset, isUse = taskinfo.isUse, status = 0})
			end
		end
		isChange = true
	end
	-- 检测任务开启关闭
	for _, taskinfo in ipairs(taskturntableInfo.taskList) do
		if taskinfo.isUse ~= Table_TaskTurnTableTask[taskinfo.taskid].isUse then
			isChange = true
		end
		taskinfo.isUse = Table_TaskTurnTableTask[taskinfo.taskid].isUse
	end
	if isChange then
		unilight.savedata(DB_Name,taskturntableInfo)
	end
	return taskturntableInfo
end
--读取配置表中的任务信息
function GetTaskTableList()
	local taskList = {}
	for id, taskinfo in ipairs(Table_TaskTurnTableTask) do
		local taskmaxvalue = 1
		-- if taskinfo.type == TaskTypes.Recharge then
		-- 	local points = string.find(taskinfo.desc,"充值R$")
		-- 	if points ~= nil then
		-- 		taskmaxvalue = tonumber(string.sub(taskinfo.desc,points)) * 100
		-- 	else
		-- 		taskmaxvalue = 1
		-- 	end
		-- end
		table.insert(taskList,{taskid = id, taskType = taskinfo.type, taskvalue = 0, taskmaxvalue = taskinfo.taskmaxvalue, isReset = taskinfo.isReset, isUse = taskinfo.isUse, status = 0,text = taskinfo.text})
	end
	return taskList
end
-- 轮盘任务中充值任务进度增加接口
function AddRechargeTask(uid,addNum)
	local taskturntableInfo = GetTaskTurnTableInfo(uid)
	for _, taskinfo in ipairs(taskturntableInfo.taskList) do
		if taskinfo.taskType == TaskTypes.Recharge then
			taskinfo.taskvalue = taskinfo.taskvalue + addNum
			if taskinfo.taskvalue > taskinfo.taskmaxvalue then
				taskinfo.taskvalue = taskinfo.taskmaxvalue
			end
		end
	end
	unilight.savedata(DB_Name,taskturntableInfo)
end
-- 轮盘任务中登陆任务进度增加接口
function AddLoginTask(uid)
	local isChange = false
	local taskturntableInfo = GetTaskTurnTableInfo(uid)
	for _, taskinfo in ipairs(taskturntableInfo.taskList) do
		if taskinfo.taskType == TaskTypes.Login and taskinfo.taskvalue == 0 then
			taskinfo.taskvalue = taskinfo.taskvalue + 1
			isChange = true
		end
	end
	if isChange then
		unilight.savedata(DB_Name,taskturntableInfo)
	end
end
-- 轮盘任务领取
function GetTaskRewards(uid,taskid)
	local taskturntableInfo = GetTaskTurnTableInfo(uid)
	for _, taskinfo in ipairs(taskturntableInfo.taskList) do
		if taskid == taskinfo.taskid then
			if taskinfo.taskvalue < taskinfo.taskmaxvalue then
				local res = {
					errno = 1,
					desc = "任务进度未满足"
				}
				return res
			end
			if taskinfo.status > 0 then
				local res = {
					errno = 1,
					desc = "任务奖励已经领取过"
				}
				return res
			end
			-- 更改任务状态为已领取
			taskinfo.status = 1
		end
	end
	taskturntableInfo.turnTableNum = taskturntableInfo.turnTableNum + 1
	unilight.savedata(DB_Name,taskturntableInfo)
	local res = {
		errno = 0,
		desc = "领取成功"
	}
	return res
end