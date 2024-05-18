-- Nado消息     相关处理

-- 玩家进入Nado机器页面请求
Net.CmdNadoInfoRequestNadoCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.NadoInfoReturnNadoCmd_s"
    local uid = laccount.Id
    local nadoInfo = Nado.NadoInfoGet(uid)
    res["data"] = {
        residueNadoNbr = nadoInfo.residueNadoNbr,
        nadoRewardList = nadoInfo.nadoRewardList,
    }
    return res
end
-- 玩家游玩Nado机器请求
Net.CmdNadoPlayRequestNadoCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.NadoPlayReturnNadoCmd_S"
    local uid = laccount.Id
    local skip = cmd.data.skip
    local nadoInfo = Nado.NadoPlay(uid, skip)
    if table.empty(nadoInfo) then
        return
    end
    res["data"] = {
        nadoRewardList = nadoInfo.nadoRewardList,
        residueNadoNbr = nadoInfo.residueNadoNbr,
    }
    return res
end
-- 玩家领取Nado机器奖励请求
Net.CmdNadoGetRewardRequestNadoCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.NadoGetRewardReturnNadoCmd_S"
    local uid = laccount.Id
    local nadoInfo = Nado.NadoGetReward(uid)
    res["data"] = {
        nadoRewardList = nadoInfo.nadoRewardList,
        residueNadoNbr = nadoInfo.residueNadoNbr,
        chips = nadoInfo.chips,
    }
    return res
end
