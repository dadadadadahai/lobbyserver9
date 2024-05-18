module('ActivityMgr', package.seeall)  

local tableActivityOpenTime = import("table/table_activity_open_time")

--获得当前开放的活动ID,只能获得一个id
function GetOpenActivityID()
    local curTime = os.time()
    for _, activityConfig in ipairs(tableActivityOpenTime) do
        local beginTime = chessutil.TimeByDateGet(activityConfig.startTime)
        local endTime   = chessutil.TimeByDateGet(activityConfig.endTime)
        if curTime >= beginTime and curTime < endTime then
            return activityConfig.activityID,beginTime,endTime
            --return 0,os.time(),0
        end
    end
    return 0,0,0
end

--获得当前开放的活动配表编号
function GetOpenActivityNumber()
    local curTime = os.time()
    for id, activityConfig in ipairs(tableActivityOpenTime) do
        local beginTime = chessutil.TimeByDateGet(activityConfig.startTime)
        local endTime   = chessutil.TimeByDateGet(activityConfig.endTime)
        if curTime >= beginTime and curTime < endTime then
            return id,beginTime,endTime
            --return 0,os.time(),0
        end
    end
    return 0,0,0
end
