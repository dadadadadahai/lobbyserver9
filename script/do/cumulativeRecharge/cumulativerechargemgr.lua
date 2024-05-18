Net.CmdGetCumulativeRechargeInfoCmd_C=function (cmd,laccount)
    local send={}
    local uid = laccount.Id
    send['do'] = 'Cmd.GetCumulativeRechargeInfoCmd_S'
    send['data'] = CumulativeRecharge.GetInfo(uid)
    return send
end
Net.CmdGetCumulativeRechargeRewardCmd_C=function (cmd,laccount)
    local send={}
    local uid = laccount.Id
    send['do'] = 'Cmd.GetCumulativeRechargeRewardCmd_S'
    send['data'] = CumulativeRecharge.GetTaskReward(uid,cmd.data.taskId)
    return send
end