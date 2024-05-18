-- 请求轮盘信息
Net.CmdUserTaskTurnTableInfoRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.UserTaskTurnTableInfoReturnSgnCmd_S"
	local taskTurnTableData = TaskTurnTable.CmdUserTaskTurnTableInfoGet(uid)
	res["data"] = taskTurnTableData
	return res
end
-- 请求任务奖励
Net.CmdUserTaskTurnTableGetTaskRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.UserTaskTurnTableGetTaskReturnSgnCmd_S"
	local taskTurnTableData = TaskTurnTable.CmdUserTaskTurnTableGetTaskRequest(uid,cmd.data.taskid)
	res["data"] = taskTurnTableData
	return res
end
-- 请求轮盘结果
Net.CmdUserTaskTurnTablePlayRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.UserTaskTurnTablePlayReturnSgnCmd_S"
	local taskTurnTableData = TaskTurnTable.CmdUserTaskTurnTablePlayRequest(uid)
	res["data"] = taskTurnTableData
	return res
end
-- 请求收集奖励
Net.CmdUserTaskTurnTableCollectRequestSgnCmd_C = function(cmd, laccount)
	local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.UserTaskTurnTableCollectReturnSgnCmd_S"
	local taskTurnTableData = TaskTurnTable.CmdUserTaskTurnTableCollectRequest(uid)
	res["data"] = taskTurnTableData
	return res
end