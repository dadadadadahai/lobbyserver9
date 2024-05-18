module('DaySign',package.seeall)

DB_Name_History = "daysign_history"
--[[
desc: 后台查看每日抽奖日志
params: 
    @uid                    玩家id
    @daysignType            每日抽奖类型(1、金币奖励 2、银币奖励)
    @startTime              startTime 时间区间查询 开始时间
    @endTime                startTime 时间区间查询 结束时间
    @page                   分页查询    第几页 
    @line                   分页查询    每页几行
--]]
function GetDaySignHistory(uid, daysignType, startTime, endTime, page, line)
    local daysignHistoryInfos = nil
    local filter = unilight.ge('uid',0)
    if uid > 0 then
        filter = unilight.a(filter,unilight.eq('uid', uid))
    end
    if daysignType > 0 then
        filter = unilight.a(filter,unilight.eq('daysignType', daysignType))
    end
    if startTime > 0 and endTime > 0 then
        -- 如果后台根据ID、类型和时间判断
        local filterTimes = unilight.a(unilight.ge('time',startTime), unilight.le('time',endTime))
        filter = unilight.a(filter, filterTimes)
    end
    local orderBy = unilight.desc("time")

    local allNum = unilight.startChain().Table(DB_Name_History).Filter(filter).Count()
    -- print(allNum)
    daysignHistoryInfos = unilight.chainResponseSequence(unilight.startChain().Table(DB_Name_History).Filter(filter).OrderBy(orderBy).Skip(line * (page-1)).Limit(line))
    return allNum, daysignHistoryInfos
end

-- 添加历史记录
DaySign.SetHistory = function(uid,daysignType,score)
    local daysignHistoryInfos = {
        uid = uid,                      -- 玩家ID
        daysignType = daysignType,      -- 每日抽奖类型(1、金币奖励 2、银币奖励)
        score = score,                  -- 奖励金额
        time = os.time(),               -- 奖励时间
    }
    unilight.savedata(DB_Name_History,daysignHistoryInfos)
end
