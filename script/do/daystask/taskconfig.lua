--任务配置信息
module('DaysTaskMgr', package.seeall)

local tablePassTask     = import "table/table_task_pass"
local tableTaskTime     = import "table/table_task_time"


passTaskVerConfig = {}
--按版本整理任务模块
function InitPassTaskConfig()
    for _, taskConfig in pairs(tablePassTask) do
        if passTaskVerConfig[taskConfig.version] == nil then
            passTaskVerConfig[taskConfig.version] = {}
        end
        table.insert(passTaskVerConfig[taskConfig.version], taskConfig)
    end

    --按等级等低到高排下序
    for version, passTaskCondfig in pairs(passTaskVerConfig)  do
        table.sort(passTaskCondfig, function(taskA,taskB) return taskA.level < taskB.level end)
    end
end

--获得指定版本任务配置
function GetPassTaskListByVersion(round)
    local version = GetCurrentVersion(round)
    return passTaskVerConfig[version]
end

--获得当前期
function GetCurrentRound()
    local curTime = os.time()
    local confRound = 0
    for k, v in pairs(tableTaskTime) do
        local beginTime = chessutil.TimeByDateGet(v.beginTime)
        local endTime   = chessutil.TimeByDateGet(v.endTime)
        if curTime >= beginTime and curTime < endTime then
            confRound = v.quarter
            break
        end
    end
    return confRound
end


--获得当前版本
function GetCurrentVersion(curRound)
    local taskTimeConfig = tableTaskTime[curRound]
    return taskTimeConfig.version
end


--根据期数获得结束时间
function GetPassEndTimeByRound(curRound)
    local taskTimeConfig = tableTaskTime[curRound]
    return taskTimeConfig.endTime
end


--获得最大通行证积分
function GetPassMaxPoint(version)
     local passTaskList = passTaskVerConfig[version]
     return passTaskList[#passTaskList].needNum
end



--启动时初始化下配置
InitPassTaskConfig()
