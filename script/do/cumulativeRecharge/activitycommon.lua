module('CumulativeRecharge', package.seeall)
DB_GLOBAL_NAME = "global"
ActivityInitTime = 0
ActivityEndTime = 0
ActivityNextTime = 0
local oneDayTime = 24 * 60 * 60
-- 初始化活动信息
function Init()
    if os.time() < ActivityNextTime then
        return
    end
    local activityInfo = unilight.getdata(DB_GLOBAL_NAME,Const.GLOBAL_DB_TYPE.CUMULATIVERECHARGE)
    local isChange = false
    if table.empty(activityInfo) then
        activityInfo = {
            _id = Const.GLOBAL_DB_TYPE.CUMULATIVERECHARGE,
            initTime = os.time(),
            endTime = os.time() + (table_cRecharge_time[1].sustainDay * oneDayTime),
        }
        activityInfo.nextTime = chessutil.ZeroTodayTimestampGetByTime(activityInfo.endTime + (math.random(table_cRecharge_time[1].minIntervalDay,table_cRecharge_time[1].maxIntervalDay) * oneDayTime))
        isChange = true
    end
    -- 活动结束本轮活动信息清零
    if os.time() > activityInfo.endTime then
        activityInfo.initTime = 0
        activityInfo.endTime = 0
        isChange = true
    end
    -- 判断是否需要任务开启
    if os.time() >= activityInfo.nextTime then
        activityInfo.initTime = activityInfo.nextTime
        activityInfo.endTime = activityInfo.initTime + (table_cRecharge_time[1].sustainDay * oneDayTime)
        activityInfo.nextTime = chessutil.ZeroTodayTimestampGetByTime(activityInfo.endTime + (math.random(table_cRecharge_time[1].minIntervalDay,table_cRecharge_time[1].maxIntervalDay) * oneDayTime))
        isChange = true
    end
    if isChange then
        unilight.savedata(DB_GLOBAL_NAME,activityInfo)
    end
    ActivityInitTime = activityInfo.initTime
    ActivityEndTime = activityInfo.endTime
    ActivityNextTime = activityInfo.nextTime
end