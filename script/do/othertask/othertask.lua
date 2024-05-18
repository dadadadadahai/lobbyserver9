--其它任务
module("OtherTaskMgr", package.seeall)

local table_task_firstpay = import ("table/table_task_firstpay")
local table_task_config   = import ("table/table_task_config")
local table_parameter_parameter = import ("table/table_parameter_parameter")



TABLE_DB_NAME = "taskother" 
-- 任务状态枚举
TASK_STATUS  = {
	DOING    = 1, -- 任务进行中
	DONE     = 2, -- 已完成
	RECIEVED = 3, -- 已领取奖励
}

TASK_MAIN_TYPE = {
    OTHER    = 9,       --其它任务
}

TASK_TYPE = {
    RECHARGE  = 1,      --充值
    VIP_LEVEL = 2,      --vip等级
    WITHDRAW  = 3,      --提现
    INVITE    = 4,      --邀请
}


--数据存档结构
function UserTaskConstuct(uid)
	local userTasks   = {
		uid           = uid,			    -- 玩家id
        totalChips    = 0,                  --任务总金币
        lastChips     = 0,                  --充值前的金币
        isLook        = 0,                  --是否有观看动画
        nMul          = 0,                  --倍数
		taskList = {                        --任务列表
        },			
	}

    --初始化其它任务
    for taskId, taskConfig in pairs(table_task_config) do
        if taskConfig.taskClass == TASK_MAIN_TYPE.OTHER then
            table.insert(userTasks.taskList, {
                taskId = taskId,            --任务id
                curNum = 0,                 --完成条件1
                twoNum = 0,                 --完成条件2, 特殊任务用，例邀请玩家8名，其中4名玩家充值
                status = TASK_STATUS.DOING,
            })
        end

    end
    --老玩家全部完成
    local userInfo = chessuserinfodb.RUserInfoGet(uid)   
    if userInfo.status.rechargeNum  > 0 then
        for _, taskInfo in pairs(userTasks.taskList) do
            taskInfo.status = TASK_STATUS.RECIEVED
        end
        unilight.info(string.format("玩家:%d, 首次任务时为老玩家，全部已领取", uid))
    end
	return userTasks
end

--首充计算任务总金币
function CalcOtherTaskChips(uid, chips)

    chips = math.floor(chips)
    local totalChips = 0
	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end

    --默认1倍，防止客户端卡死
    userTasks.nMul =  1
    --金币少于1000
    local minChips = table_parameter_parameter[27].Parameter
    local randomMin = table_parameter_parameter[28].Parameter
    local randomMax = table_parameter_parameter[29].Parameter
    if chips < minChips then
        totalChips = math.random(randomMin, randomMax)
        userTasks.nMul =  1
    else
        for id, chipsConfig in ipairs(table_task_firstpay) do
            if chips >= chipsConfig.chipsMin and chips <= chipsConfig.chipsMax then
                totalChips = math.floor(chipsConfig.nMul * chips)
                userTasks.nMul =  chipsConfig.nMul
            end
        end
    end

    if userTasks.totalChips > 0 then
        unilight.error(string.format("玩家:%d, 重复初始化任务金币:%d", uid, totalChips))
    end

    unilight.info(string.format("玩家:%d, 初始化任务金币:%d", uid, totalChips))
    userTasks.totalChips = totalChips
    userTasks.lastChips  = chips

    unilight.savedata(TABLE_DB_NAME, userTasks)
    GetTaskListInfo(uid)
end

--设置任务动画已观看
function SetAlreadyLook(uid)

	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end
    userTasks.isLook  = 1
    unilight.savedata(TABLE_DB_NAME, userTasks)
    unilight.info(string.format("玩家:%d, 任务设置已观看", uid))
    GetTaskListInfo(uid)
end



--获得任务信息
function GetTaskListInfo(uid)
	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
        unilight.savedata(TABLE_DB_NAME, userTasks)
    end
	local send = {}
	send["do"] = "Cmd.GetTaskListOtherTask_S"
    local data = {}
    data.taskList = {}
    data.totalChips = userTasks.totalChips
    data.nMul       = userTasks.nMul
    data.lastChips  = userTasks.lastChips
    data.isLook     = userTasks.isLook
    for k, v in ipairs(userTasks.taskList) do
        local tmpData = table.clone(v)
        local taskConfig = table_task_config[tmpData.taskId]
        tmpData.chips = math.floor(userTasks.totalChips * taskConfig.addChipsPer / 10000 )
        table.insert(data.taskList, tmpData)
    end
    send.data = data
    unilight.sendcmd(uid, send)
end

--添加任务完成次数
--params @uid 玩家id
--       @taskType 任务类型
--       @num 完成次数
--       @subNum 子完成次数, 特殊任务有两个完成条 
function AddTaskNum(uid, taskType, num, subNum)
	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
        unilight.savedata(TABLE_DB_NAME, userTasks)
    end

    local bUpdate = false
    for _, taskInfo in pairs(userTasks.taskList)   do
        local taskConfig = table_task_config[taskInfo.taskId]
        --是否满足条件
        if taskConfig ~= nil and taskConfig.taskType == taskType and taskInfo.status == TASK_STATUS.DOING then
            if num ~= nil then
                --vip等级直接设置等级
                if taskConfig.taskType == TASK_TYPE.VIP_LEVEL then
                    taskInfo.curNum = num
                --邀请接设置人数
                elseif taskConfig.taskType == TASK_TYPE.INVITE then
                    taskInfo.curNum = num
                else
                    taskInfo.curNum = taskInfo.curNum + 1
                end

                if taskInfo.curNum > taskConfig.finishNum then
                    taskInfo.curNum = taskConfig.finishNum
                end
            end

            if subNum ~= nil then
                taskInfo.twoNum = taskInfo.twoNum + 1
                if taskInfo.twoNum > taskConfig.finishNum2 then
                    taskInfo.twoNum = taskConfig.finishNum2
                end
            end
            unilight.info(string.format("玩家:%d, 增加任务id:%d, 进度1:(%d:%d), 进度2:(%d:%d)", uid, taskInfo.taskId, taskInfo.curNum, taskConfig.finishNum, taskInfo.twoNum, taskConfig.finishNum2 ))
            --邀请任务特殊处理下
            if taskConfig.taskType == TASK_TYPE.INVITE then
                if taskInfo.curNum >= taskConfig.finishNum and taskInfo.twoNum >= taskConfig.finishNum2 and taskInfo.status == TASK_STATUS.DOING then
                    taskInfo.status = TASK_STATUS.DONE
                    unilight.info(string.format("玩家:%d, 完成任务id:%d", uid, taskInfo.taskId))
                end
            else
                if taskInfo.curNum >= taskConfig.finishNum and taskInfo.status == TASK_STATUS.DOING then
                    taskInfo.status = TASK_STATUS.DONE
                    unilight.info(string.format("玩家:%d, 完成任务id:%d", uid, taskInfo.taskId))
                end
            end
            bUpdate = true
        end
    end

    if bUpdate then
        unilight.savedata(TABLE_DB_NAME, userTasks)
        GetTaskListInfo(uid)
    end
end


--获得奖励
function GetTaskReward(uid, taskId)

    local send = {}
	send["do"] = "Cmd.GetRewardOtherTask_S"
    send.data = {
        errno = 0,
        desc = "领取成功"
    }

	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    local taskInfo 
    for _, curTaskInfo in pairs(userTasks.taskList) do
        if taskId == curTaskInfo.taskId then
            taskInfo = curTaskInfo 
            break
        end
    end

    if taskInfo == nil then
        send.data = {
            errno = 2,
            desc  = "找不到任务配置"
        }
        unilight.sendcmd(uid, send)
        return
    end

    if taskInfo.status ~= TASK_STATUS.DONE then
        send.data = {
            errno = 2,
            desc  = "重复领取"
        }
        unilight.sendcmd(uid, send)
        return
    end

    taskInfo.status = TASK_STATUS.RECIEVED
    unilight.savedata(TABLE_DB_NAME, userTasks)

    local taskConfig = table_task_config[taskId]

    local chips = math.floor(userTasks.totalChips * taskConfig.addChipsPer / 10000 )
    send.data.rewardItem = {}

    table.insert(send.data.rewardItem, {goodId=Const.GOODS_ID.GOLD, goodNum=chips})

    for k, v in pairs(send.data.rewardItem) do
        BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
        chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, v.goodNum, "任务赠送")
    end
    -- send.data = data
    unilight.sendcmd(uid, send)
end



