module('CumulativeRecharge', package.seeall)
table_cRecharge_time = require 'table/table_cRecharge_time'
table_cRecharge_reward = require 'table/table_cRecharge_reward'
local tableMailConfig = import "table/table_mail_config"
Table = 'cumulativerecharge'
function Get(uid)
    local datainfo = unilight.getdata(Table,uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            rechargeChips = 0,                      -- 活动充值金额
            taskList = initTaskList(),              -- 任务列表
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end

-- 初始化任务列表
function initTaskList()
    local taskList = {}
    for _, taskinfo in ipairs(table_cRecharge_reward) do
        -- 已经充值  任务需要总充值 任务奖励  任务领取状态 0 未领取 1 可领取 2 已领取
        table.insert(taskList,{totalRechargeChips = taskinfo.rechargeChips,rewardChips = taskinfo.rewardChips,status = 0})
    end
    return taskList
end

-- 返回页面信息
function GetInfo(uid)
    -- 每一个玩家都可以判断是否需要更新活动
    Init()
    local datainfo = Get(uid)
    local changeFlag = false
    for _, taskinfo in ipairs(datainfo.taskList) do
        if datainfo.rechargeChips >= taskinfo.totalRechargeChips and taskinfo.status == 0 then
            taskinfo.status = 1
            changeFlag = true
        end
    end
    if changeFlag then
        unilight.savedata(Table,datainfo)
    end
    local activityTime = GetActivityOpenTime()
    local res = {
        initTime = activityTime.initTime,
        endTime = activityTime.endTime,
        nextTime = activityTime.nextTime,
        rechargeChips = datainfo.rechargeChips,
        taskList = datainfo.taskList,
    }
    return res
end

-- 领取任务奖励
function GetTaskReward(uid,taskId)
    local datainfo = Get(uid)
    if datainfo.taskList[taskId] == nil then
        return
    end
    if datainfo.taskList[taskId].totalRechargeChips > datainfo.rechargeChips then
        return
    else
    end
    if datainfo.taskList[taskId].status ~= 1 then
        return
    end
    -- 改变状态
    datainfo.taskList[taskId].status = 2
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.taskList[taskId].rewardChips, Const.GOODS_SOURCE_TYPE.CUMULATIVERECHARGE)
    -- 保存统计
    local userInfo = unilight.getdata('userinfo',uid)
    userInfo.property.totalactivitychips = userInfo.property.totalactivitychips + datainfo.taskList[taskId].rewardChips
    unilight.savedata('userinfo',userInfo)
    -- 添加日志信息
    local activityTime = GetActivityOpenTime()
    AddLog(uid,activityTime.initTime,activityTime.endTime,1,datainfo.rechargeChips,0,0,datainfo.taskList[taskId].rewardChips)

    WithdrawCash.AddBet(uid,datainfo.taskList[taskId].rewardChips)
    local mailInfo = {}
    local mailConfig = tableMailConfig[43]
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,datainfo.taskList[taskId].rewardChips/100)
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
    local res = {
        reward = datainfo.taskList[taskId].rewardChips,
        taskId = taskId,
    }
    unilight.savedata(Table,datainfo)
    return res
end

-- 获取任务是否开启  开启时间结束时间
function GetActivityOpenTime()
    local initTime = 0
    local endTime = 0
    if os.time() >= ActivityInitTime and os.time() < ActivityEndTime then
        initTime = ActivityInitTime
        endTime = ActivityEndTime
        
    end
    local res = {
        initTime = initTime,
        endTime = endTime,
        nextTime = ActivityNextTime,
    }
    return res
end
-- 增加任务进度
function AddTaskNum(uid,addNum)
    local datainfo = Get(uid)
    datainfo.rechargeChips = datainfo.rechargeChips + addNum
    unilight.savedata(Table,datainfo)
    
    -- 增加任务进度时更新表进度
    local filter = unilight.eq("uid",uid)
    -- 根据发放时间判断
    local activityTime = GetActivityOpenTime()
    local starttime = activityTime.initTime
    local endtime = activityTime.endTime
    filter = unilight.a(filter,unilight.a(unilight.eq("starttime",starttime),unilight.eq("endtime",endtime)))
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table('generalactivitielog').Filter(filter))
    for _, logInfo in ipairs(logInfos) do
        logInfo.totalRecharge = datainfo.rechargeChips
    end
    unilight.savebatch("generalactivitielog",logInfos)
end

-- 增加日志信息
function AddLog(uid,startTime,endtime,type,totalRecharge,totalBet,totalInvite,chips)
    local datainfo = {
        uid = uid,                          -- 玩家id
        starttime = startTime,              -- 活动开始时间
        endtime = endtime,                  -- 活动结束时间
        type = type,                        -- 活动名称 1.累计充值活动
        totalRecharge = totalRecharge,      -- 累计充值
        totalBet = totalBet,                -- 累计下注
        totalInvite = totalInvite,          -- 累计邀请
        chips = chips,                      -- 发放金额
        datetime = os.time(),               -- 领取时间
    }
    unilight.savedata("generalactivitielog",datainfo)
end