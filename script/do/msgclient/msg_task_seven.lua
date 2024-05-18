--七日任务相关协议

--获得任务列表
Net.CmdGetTaskListSevenTask_C = function(cmd, laccount)
    local uid = laccount.Id
    TaskSevenMgr.GetTaskListInfo(uid)
end


--领取任务奖励
Net.CmdGetRewardSevenTask_C = function(cmd, laccount)
    local uid = laccount.Id
    TaskSevenMgr.GetTaskReward(uid)
end

