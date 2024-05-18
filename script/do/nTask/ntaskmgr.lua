--消息处理函数
Net.CmdGetnTaskInfoCmd_C=function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.GetnTaskInfoCmd_S"
	local uid = laccount.Id
    res['data'] = nTask.GetTaskInfoCmd_C(uid)
    return res
end

--签到
Net.CmdnTaskSignCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.nTaskSignCmd_S"
	local uid = laccount.Id
    res['data'] = nTask.nTaskSignCmd_C(uid)
    return res
end

--任务奖励
Net.CmdnTaskRewardCmd_C = function (cmd,laccount)
    local res = {}
	res["do"] = "Cmd.nTaskRewardCmd_S"
	local uid = laccount.Id
    res['data'] = nTask.nTaskRewardCmd_C(uid,cmd.data.taskId)
    return res
end