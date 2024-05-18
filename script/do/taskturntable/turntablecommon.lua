module('TaskTurnTable', package.seeall) 
local tableMailConfig = import "table/table_mail_config"
-- 游玩转盘
function PlayTurnTable(uid)
    local taskturntableInfo = GetTaskTurnTableInfo(uid)
    if taskturntableInfo.turnTableNum < 1 then
        local res = {
            errno = 1,
            turnTableId = 0,
            desc = "转盘次数不足"
        }
        return res
    end
    taskturntableInfo.turnTableNum = taskturntableInfo.turnTableNum - 1
    local turnTableId = Table_TaskTurnTablePro[gamecommon.CommRandInt(Table_TaskTurnTablePro, 'pro'..taskturntableInfo.turnTableProType)].ID
    if Table_TaskTurnTablePro[turnTableId].type == 1 then
        -- 增加收集进度
        taskturntableInfo.collect[Table_TaskTurnTablePro[turnTableId].desc] = taskturntableInfo.collect[Table_TaskTurnTablePro[turnTableId].desc] or 0
        taskturntableInfo.collect[Table_TaskTurnTablePro[turnTableId].desc] = taskturntableInfo.collect[Table_TaskTurnTablePro[turnTableId].desc] + 1
        AddLog(taskturntableInfo,Table_TaskTurnTablePro[turnTableId].desc,100)
    elseif Table_TaskTurnTablePro[turnTableId].type == 2 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, tonumber(Table_TaskTurnTablePro[turnTableId].desc), Const.GOODS_SOURCE_TYPE.TASKTURNTABLE)
        local userinfo = unilight.getdata('userinfo',uid)
        userinfo.property.totalturntablechips = userinfo.property.totalturntablechips + tonumber(Table_TaskTurnTablePro[turnTableId].desc)
        unilight.savedata('userinfo',userinfo)
        -- 发送邮件
        local mailInfo = {}
        local mailConfig = tableMailConfig[47]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = string.format(mailConfig.content,tonumber(Table_TaskTurnTablePro[turnTableId].desc)/100)
        mailInfo.type = 0
        mailInfo.attachment = {}
        mailInfo.extData = {}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        -- 添加日志
        AddLog(taskturntableInfo,'Normal',tonumber(Table_TaskTurnTablePro[turnTableId].desc))
    end
    unilight.savedata(DB_Name,taskturntableInfo)
    local res = {
        errno = 0,
        turnTableId = turnTableId,
        desc = "成功"
    }
    return res
end
-- 领取收集奖励
function GetCollectReward(uid)
    local taskturntableInfo = GetTaskTurnTableInfo(uid)
    for collectId, collectNum in pairs(taskturntableInfo.collect) do
        if collectId == "H" or collectId == "A" or collectId == "P" or collectId == "Y" then
            collectNum = collectNum - 1
            if collectId == "P" then
                collectNum = collectNum - 1
            end
            if collectNum < 0 then
                local res = {
                    errno = 1,
                    desc = "转盘收集字母个数不足"
                }
                return res
            end
        end
    end
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, 10000, Const.GOODS_SOURCE_TYPE.TASKTURNTABLE)
    local userinfo = unilight.getdata('userinfo',uid)
    userinfo.property.totalturntablechips = userinfo.property.totalturntablechips + 10000
    unilight.savedata('userinfo',userinfo)
    AddLog(taskturntableInfo,'Collect',10000)
	unilight.savedata(DB_Name,taskturntableInfo)
    local res = {
        errno = 0,
        desc = "成功"
    }
    return res
end
-- 添加日志
function AddLog(taskturntableInfo,getType,addChips)
	unilight.savedata(DB_Log_Name,{
		uid = taskturntableInfo._id,
		lastChangeTime = os.time(),                                     -- 转盘开启时间
		getType = getType,                                              -- 金额获取方式
		addCashNum = addChips,                                          -- 金额
	})
end