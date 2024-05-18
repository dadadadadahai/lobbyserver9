module('nTask',package.seeall)
UserTable ='userinfo'
Table = 'ntask'
DB_Log_Name = 'ntasklog'
table_task_config = require 'table/table_task_config'
table_task_dayNum = require 'table/table_task_dayNum'
table_shop_num = require 'table/table_shop_num'
local tableMailConfig = import "table/table_mail_config"
function Get(uid)
    local datainfo = unilight.getdata(Table,uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            initTime = 0,                   -- 初始化时间
            endTime = 0,                    -- 结束时间
            totalChips = 0,                 -- 总共可领取金额
            lackChips = 0,                  -- 剩余可领取金额
            signList = {},                  -- 签到天数列表             内有status 0未领取  1  已领取
            taskList = {},                  -- 任务列表                 内有status 0未完成  1  已完成未领取  2已领取
            lastChangeTime = 0,             -- 最后更新时间
        }
        unilight.savedata(Table,datainfo)
    end
    -- 判断任务更新
    if table.empty(datainfo.taskList) == false and datainfo.initTime ~= 0 and chessutil.DateDayDistanceByTimeGet(datainfo.lastChangeTime, chessutil.ZeroTodayTimestampGet()) > 0 then
        datainfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
        -- 重置任务列表
        datainfo.taskList = {}
        -- 生成剩余奖励数值
        local proportion = 0
        for _, taskinfo in ipairs(table_task_config) do
            if taskinfo.taskClass == 1 then
                proportion = proportion + taskinfo.addChipsPer
                if taskinfo.taskType == 6 then
                    -- 初始化任务列表
                    table.insert(datainfo.taskList,{time = 0,totalTime = taskinfo.finishNum * (datainfo.totalChips * (taskinfo.addChipsPer / 10000)),chips = math.floor(datainfo.totalChips * (taskinfo.addChipsPer / 10000)),status = 0,taskType = taskinfo.taskType,totalTime2 = taskinfo.finishNum2})
                else
                    -- 初始化任务列表
                    table.insert(datainfo.taskList,{time = 0,totalTime = taskinfo.finishNum,chips = datainfo.totalChips * (taskinfo.addChipsPer / 10000),status = 0,taskType = taskinfo.taskType,totalTime2 = taskinfo.finishNum2})
                end
            end
        end
        -- 再额外增加万分之一百
        if chessutil.DateDayDistanceByTimeGet(datainfo.initTime, chessutil.ZeroTodayTimestampGet()) == 29 then
            proportion = proportion * (table_task_dayNum[1].dayNum - 1 - chessutil.DateDayDistanceByTimeGet(datainfo.initTime, chessutil.ZeroTodayTimestampGet()))
        else
            proportion = proportion * (table_task_dayNum[1].dayNum - 1 - chessutil.DateDayDistanceByTimeGet(datainfo.initTime, chessutil.ZeroTodayTimestampGet())) + 100
        end
        datainfo.lackChips = datainfo.totalChips * (proportion / 10000)
        -- 最后一天 最后两个任务奖励增加
        if datainfo.endTime == datainfo.initTime then
            local addChips = datainfo.totalChips * (50 / 10000)
            datainfo.taskList[#datainfo.taskList].chips = datainfo.taskList[#datainfo.taskList].chips + addChips
            datainfo.taskList[#datainfo.taskList - 1].chips = datainfo.taskList[#datainfo.taskList - 1].chips + addChips
            -- 最后一天金额直接归零
            datainfo.lackChips = 0
        end
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end

-- 返回任务信息
function GetTaskInfoCmd_C(uid)
    local datainfo = Get(uid)
    local res={
        errno = 0,
        lackChips = datainfo.lackChips,         -- 剩余可领取金额
        signList = datainfo.signList,           -- 签到列表
        taskList = datainfo.taskList,           -- 任务列表
        initTime = datainfo.initTime,           -- 初始化时间
        endTime = datainfo.endTime,             -- 结束时间
    }
    return res
end

-- 领取签到奖励
function nTaskSignCmd_C(uid)
    local datainfo = Get(uid)
    -- 判断是否允许签到
    if table.empty(datainfo.signList) then
        local res = {
            errno = 1,
            chips = 0,                              -- 奖励金额
            signList = datainfo.signList,           -- 签到列表
        }
        return res
    end
    -- 获取当前天数
    local dayNum = chessutil.DateDayDistanceByTimeGet(datainfo.initTime, chessutil.ZeroTodayTimestampGet()) + 1
    if table.empty(datainfo.signList[dayNum]) then
        local res = {
            errno = 1,
            chips = 0,                              -- 奖励金额
            signList = datainfo.signList,           -- 签到列表
        }
        return res
    end
    -- 如果已经领取则返回
    if datainfo.signList[dayNum].status > 0 then
        local res = {
            errno = 1,
            chips = 0,                              -- 奖励金额
            signList = datainfo.signList,           -- 签到列表
        }
        return res
    end
    datainfo.signList[dayNum].status = 1
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.signList[dayNum].chips, Const.GOODS_SOURCE_TYPE.NTASK)
    local userinfo = unilight.getdata('userinfo',uid)
    userinfo.property.totalntaskchips = userinfo.property.totalntaskchips + datainfo.signList[dayNum].chips
    unilight.savedata('userinfo',userinfo)
    -- 增加日志
    AddLog(uid,1,datainfo.signList[dayNum].chips)
    WithdrawCash.AddBet(uid, datainfo.signList[dayNum].chips * 3)
    local mailInfo = {}
    local mailConfig = tableMailConfig[42]
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,datainfo.signList[dayNum].chips/100)
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
    unilight.savedata(Table,datainfo)
    local res = {
        errno = 0,
        chips = datainfo.signList[dayNum].chips,-- 奖励金额
        signList = datainfo.signList,           -- 签到列表
    }
    return res
end

-- 领取任务奖励
function nTaskRewardCmd_C(uid,taskid)
    local datainfo = Get(uid)
    if table.empty(datainfo.taskList[taskid]) then
        local res = {
            errno = 1,
            chips = 0,                              -- 奖励金额
            taskList = datainfo.taskList,           -- 任务列表
        }
        return res
    end
    if datainfo.taskList[taskid].status ~= 1 then
        local res = {
            errno = 1,
            chips = 0,                              -- 奖励金额
            taskList = datainfo.taskList,           -- 任务列表
        }
        return res
    end
    datainfo.taskList[taskid].status = 2
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.taskList[taskid].chips, Const.GOODS_SOURCE_TYPE.NTASK)
    local userinfo = unilight.getdata('userinfo',uid)
    userinfo.property.totalntaskchips = userinfo.property.totalntaskchips + datainfo.taskList[taskid].chips
    unilight.savedata('userinfo',userinfo)
    -- 增加日志
    AddLog(uid,2,datainfo.taskList[taskid].chips)
    WithdrawCash.AddBet(uid, datainfo.taskList[taskid].chips * 3)
    local mailInfo = {}
    local mailConfig = tableMailConfig[42]
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,datainfo.taskList[taskid].chips/100)
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
    unilight.savedata(Table,datainfo)
    local res = {
        errno = 0,
        chips = datainfo.taskList[taskid].chips,-- 奖励金额
        taskList = datainfo.taskList,           -- 任务列表
    }
    return res
end

-- 判断是否初始化
function TaskInit(uid,rechargeNum)
    -- 判断满足状态
    if rechargeNum < table_shop_num[1].num then
        return
    end

    local chips = 0
    for id = 1, #table_shop_num do
        -- 如果是配置表最后一列额外判断
        if id == #table_shop_num then
            if rechargeNum >= table_shop_num[id].num then
                chips = math.floor(table_shop_num[id].num * (table_shop_num[id].pro / 100))
                break 
            end
        elseif rechargeNum >= table_shop_num[id].num and rechargeNum < table_shop_num[id + 1].num then
            chips = math.floor(table_shop_num[id].num * (table_shop_num[id].pro / 100))
            break
        end
    end

    if chips == 0 then
        return
    end

    local datainfo = Get(uid)
    -- 判断是否是第一次满足要求
    if datainfo.totalChips == 0 and datainfo.initTime == 0 then
        datainfo.totalChips = chips
        -- 生成剩余奖励数值
        local proportion = 0
        for _, taskinfo in ipairs(table_task_config) do
            if taskinfo.taskClass == 1 then
                proportion = proportion + taskinfo.addChipsPer
                if taskinfo.taskType == 6 then
                    -- 初始化任务列表
                    table.insert(datainfo.taskList,{time = 0,totalTime = math.floor(datainfo.totalChips * (taskinfo.addChipsPer / 10000)),chips = math.floor(datainfo.totalChips * (taskinfo.addChipsPer / 10000)),status = 0,taskType = taskinfo.taskType,totalTime2 = taskinfo.finishNum2})
                else
                    -- 初始化任务列表
                    table.insert(datainfo.taskList,{time = 0,totalTime = taskinfo.finishNum,chips = datainfo.totalChips * (taskinfo.addChipsPer / 10000),status = 0,taskType = taskinfo.taskType,totalTime2 = taskinfo.finishNum2})
                end
            end
        end
        -- 再额外增加万分之一百
        proportion = proportion * (table_task_dayNum[1].dayNum - 1) + 100
        datainfo.lackChips = chips * (proportion / 10000)
        datainfo.initTime = chessutil.ZeroTodayTimestampGet()
        datainfo.endTime = chessutil.ZeroTodayTimestampGet() + 3600 * 24 * table_task_dayNum[1].dayNum
        datainfo.lastChangeTime = chessutil.ZeroTodayTimestampGet()
        -- 初始化签到列表
        for daynum = 1, table_task_dayNum[1].dayNum do
            table.insert(datainfo.signList,{status = 0,chips = chips * (table_task_dayNum[1].pro / 10000)})
        end
        unilight.savedata(Table,datainfo)
        -- 主动推送初始化信息
        local send = {}
        send["do"] = "Cmd.ActivateTaskInfoCmd_S"
        send['data'] = nTask.GetTaskInfoCmd_C(uid)
        unilight.sendcmd(uid, send)
    end
end

-- 添加任务进度
function AddTaskNum(uid,taskType,addNum)
    local datainfo = Get(uid)
    if datainfo.initTime == 0 or datainfo.endTime == 0 or datainfo.totalChips == 0 then
        return
    end
    local isChange = false
    for _, taskinfo in ipairs(datainfo.taskList) do
        if taskinfo.taskType == taskType then
            if taskType == 7 then
                if addNum >= taskinfo.totalTime2 and taskinfo.status == 0 then
                    taskinfo.time = taskinfo.time + 1
                    if taskinfo.time >= taskinfo.totalTime then
                        taskinfo.time = taskinfo.totalTime
                        taskinfo.status = 1
                    end
                    isChange = true
                end                
            else
                if taskinfo.status == 0 then
                    taskinfo.time = taskinfo.time + addNum
                    if taskinfo.time >= taskinfo.totalTime then
                        taskinfo.time = taskinfo.totalTime
                        taskinfo.status = 1
                    end
                    isChange = true
                end
            end
        end
    end
    if isChange then
        unilight.savedata(Table,datainfo)
    end
end

-- 添加日志记录
function AddLog(uid,type,gold)
    local datainfo = {
        uid = uid,
        datetime = os.time(),
        type = type,
        gold = gold,
    }
    unilight.savedata(DB_Log_Name,datainfo)
end