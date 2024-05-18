module('TaskTurnTable', package.seeall) 

-- 获取转盘面板信息
function CmdUserTaskTurnTableInfoGet(uid)
    local taskTurnTableData = GetTaskTurnTableInfo(uid)
    local taskList = {}
    for _, taskinfo in ipairs(taskTurnTableData.taskList) do
        -- 重新组装任务进度 只有0/1
        local taskvalue = 0
        local taskmaxvalue = 1
        if taskinfo.taskvalue >= taskinfo.taskmaxvalue then
            taskvalue = 1
        end
        table.insert(taskList,{
            taskid = taskinfo.taskid,
            -- taskType = taskinfo.taskType,
            taskvalue = taskvalue,
            taskmaxvalue = taskmaxvalue,
            status = taskinfo.status,
            text = taskinfo.text,
        })
    end
    local res = {
		errno = 0,
        taskList = taskList,
        collect = taskTurnTableData.collect,
        turnTableNum = taskTurnTableData.turnTableNum,
	}
    return res
end

-- 获取任务奖励
function CmdUserTaskTurnTableGetTaskRequest(uid,taskid)
    local taskTurnTableData = GetTaskRewards(uid,taskid)
    local res = {
        errno = taskTurnTableData.errno,
	}
    return res
end

-- 获取转盘游玩结果
function CmdUserTaskTurnTablePlayRequest(uid)
    local res = {}
    local taskTurnTableData = TaskTurnTable.PlayTurnTable(uid)
	res = {
		errno = taskTurnTableData.errno,
        turnTableId = taskTurnTableData.turnTableId,
	}
    return res
end

-- 获取转盘收集奖励
function CmdUserTaskTurnTableCollectRequest(uid)
    local res = {}
    local taskTurnTableData = TaskTurnTable.GetCollectReward(uid)
	res = {
		errno = taskTurnTableData.errno,
	}
    return res
end