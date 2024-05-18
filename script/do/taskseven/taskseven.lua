--七天任务
module("TaskSevenMgr", package.seeall)

local tableTaskSevenTime =  import "table/table_task_seven_time"
local tableTaskSevenConfig    =  import "table/table_task_seven_config"
local tableTaskConfig   = import "table/table_task_config"

tableTaskSevenConfig = tableTaskSevenConfig[1]

TABLE_DB_NAME = "taskseven" 
-- 任务状态枚举
TASK_STATUS  = {
	DOING    = 1, -- 任务进行中
	DONE     = 2, -- 已完成
	RECIEVED = 3, -- 已领取奖励
}

MAX_DAY = tableTaskSevenConfig.continueDay

--数据存档结构
function UserTaskConstuct(uid)
	local userTasks   = {
		_id           = uid,			    -- 玩家id
		sevenTaskInfo = {                   --七日任务信息
            curDay    = 0,                  --当前第几天
            status    = TASK_STATUS.DOING,  --当前任务状态
            curNum    = 0,                  --当前进度
            curTaskId    = 0,               --当前任务id
            lastDayNo  = 0,                 --上次刷新天ID,刷新时间用
        },			
	}
	return userTasks
end

--检测是否在活动期间
function CheckInActivity(uid)
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    local curTime = os.time()
    local diffDay = math.ceil((curTime - userInfo.status.registertimestamp) / 86400)
    local bOpen = false
    for k, v in pairs(tableTaskSevenTime) do
        local beginTime = chessutil.TimeByDateGet(v.beginTime)
        local endTime   = chessutil.TimeByDateGet(v.endTime)
        if curTime >= beginTime and curTime < endTime and diffDay >= v.regDayMin and diffDay <= v.regDayMax then
            bOpen = true
            break
        end
    end
    return bOpen
end


--获得任务信息
function GetTaskListInfo(uid)
	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
        unilight.savedata(TABLE_DB_NAME, userTasks)
    end
    local sevenTaskInfo = userTasks.sevenTaskInfo
    local curDayNo = chessutil.GetMorningDayNo()
    local bOpen = CheckInActivity(uid)
    if curDayNo ~= sevenTaskInfo.lastDayNo then

        --有天数的情况下
        if sevenTaskInfo.curDay ~= 0 then
            sevenTaskInfo.curDay = sevenTaskInfo.curDay + (curDayNo - sevenTaskInfo.lastDayNo)
            --大于最大天数，重置数据
            if sevenTaskInfo.curDay > MAX_DAY then
                sevenTaskInfo.curDay = 0
                sevenTaskInfo.status = TASK_STATUS.DOING
                sevenTaskInfo.curTaskId = 0
                sevenTaskInfo.curNum  = 0
            else
                sevenTaskInfo.curTaskId = tableTaskSevenConfig.taskList[sevenTaskInfo.curDay]
                sevenTaskInfo.status = TASK_STATUS.DOING
                sevenTaskInfo.curNum  = 0
            end
        end

        if bOpen then
            --第一天
            if sevenTaskInfo.curDay == 0 then
                sevenTaskInfo.curDay = 1
                sevenTaskInfo.curTaskId = tableTaskSevenConfig.taskList[sevenTaskInfo.curDay]
            end
        end

        sevenTaskInfo.lastDayNo = curDayNo
    end

    if sevenTaskInfo.curDay == 0 then
        return
    end
    unilight.savedata(TABLE_DB_NAME, userTasks)
	local send = {}
	send["do"] = "Cmd.GetTaskListSevenTask_S"
    local data = {}
    data.taskList = {}
    for k, v in ipairs(tableTaskSevenConfig.taskList) do
        table.insert(data.taskList, v)
    end
    data.taskId = sevenTaskInfo.curTaskId
    data.status = sevenTaskInfo.status
    data.curNum = sevenTaskInfo.curNum
    data.nextTime = chessutil.GetMorningDayNo2Time(sevenTaskInfo.lastDayNo + 1)
    data.curDay = sevenTaskInfo.curDay
    send.data = data
    unilight.sendcmd(uid, send)






end

--添加任务完成次数
function AddTaskNum(uid, taskId, num)
	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    local sevenTaskInfo = userTasks.sevenTaskInfo
    if sevenTaskInfo.curTaskId ~= taskId then
        return
    end
    local taskConfig = tableTaskConfig[taskId]
    sevenTaskInfo.curNum = sevenTaskInfo.curNum + num
    if sevenTaskInfo.curNum > taskConfig.finishNum then
        sevenTaskInfo.curNum = taskConfig.finishNum
    end

    if sevenTaskInfo.curNum >= taskConfig.finishNum and sevenTaskInfo.status == TASK_STATUS.DOING then
        sevenTaskInfo.status = TASK_STATUS.DONE
    end
    unilight.savedata(TABLE_DB_NAME, userTasks)
end


--获得奖励
function GetTaskReward(uid)

    local send = {}
	send["do"] = "Cmd.GetRewardSevenTask_S"
    send.data = {
        errno = 0,
        desc = "领取成功"
    }
    local data = {}

	local userTasks = unilight.getdata(TABLE_DB_NAME, uid)
    local sevenTaskInfo = userTasks.sevenTaskInfo
    if sevenTaskInfo.status ~= TASK_STATUS.DONE then
        if sevenTaskInfo.status == TASK_STATUS.DOING then
            send.data = {
                errno = 1,
                desc = "任务未完成"
            }
        else
            send.data = {
                errno = 2,
                desc = "不能重复领取"
            }
        end
        unilight.sendcmd(uid, send)
        return 
    end
    sevenTaskInfo.status = TASK_STATUS.RECIEVED
    unilight.savedata(TABLE_DB_NAME, userTasks)

    local taskConfig = tableTaskConfig[sevenTaskInfo.curTaskId]
    local data = {}
    data.rewardItem = {}
    for k, v in pairs(taskConfig.reward) do
        table.insert(data.rewardItem, {goodId=v.goodId, goodNum=v.goodNum})
    end

    for k, v in pairs(data.rewardItem) do
        BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
    end
    send.data = data
    unilight.sendcmd(uid, send)
end


