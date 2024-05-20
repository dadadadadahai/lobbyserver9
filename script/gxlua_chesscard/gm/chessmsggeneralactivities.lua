-- 通用活动相关gm请求
GmSvr.PmdRequestGeneralActivitiesPmd_C = function(cmd, laccount)
    if cmd.data.optype == 1 then
        return GetActiviteGather(cmd, laccount)
    elseif cmd.data.optype == 2 then
        return GetActiviteReward(cmd, laccount)
    end
end

-- 参与活动按玩家汇总
function GetActiviteGather(cmd, laccount)
    -- local filter = unilight.gt('_id',0)
    local filter = '"_id":{"$gt":0}'
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        -- filter = unilight.a(filter,unilight.eq("uid",cmd.data.charid))
        filter = filter..',"uid":{"$eq":'..cmd.data.charid..'}'
    end
    -- 根据领取内容判断
    if cmd.data.activity ~= nil and cmd.data.activity > 0 then
        -- filter = unilight.a(filter,unilight.eq("type",cmd.data.activity))
        filter = filter..',"type":{"$eq":'..cmd.data.activity..'}'
    end
    local order = unilight.desc("starttime")
    -- local logInfos = unilight.chainResponseSequence(unilight.startChain().Table('generalactivitielog').Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table("generalactivitielog").Aggregate('{"$match":{'..filter..'}}',
    '{"$group":{"_id":{"uid":"$uid","starttime":"$starttime","endtime":"$endtime","type":"$type"},"totalRecharge":{"$sum":"$totalRecharge"},"totalInvite":{"$sum":"$totalInvite"},"totalBet":{"$sum":"$totalBet"},"chips":{"$sum":"$chips"}}}',
    '{"$sort":{"_id.starttime":-1,"_id.endtime":-1}}',
    '{"$skip":'..(cmd.data.curpage-1)*cmd.data.perpage..'}',
    '{"$limit":'..cmd.data.perpage..'}'))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                totalcharge = 0,
                totalbet = 0,
                totalinvite = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table('generalactivitielog').Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            data = {},
            totalcharge = 0,
            totalbet = 0,
            totalinvite = 0,
        }
    }
    -- 中间缓存
    local infoMap = {}
    for _, logInfo in ipairs(logInfos) do
        if infoMap[logInfo._id.uid..logInfo._id.starttime..logInfo._id.endtime] == nil then
            infoMap[logInfo._id.uid] = {
            charid          = logInfo._id.uid,                                          -- 玩家id
            starttime       = chessutil.FormatDateGet(logInfo._id.starttime),           -- 活动开始时间
            endtime         = chessutil.FormatDateGet(logInfo._id.endtime),             -- 活动结束时间
            activity        = logInfo._id.type,                                         -- 活动名称 1.累计充值活动
            allcharge       = logInfo.totalRecharge,                                -- 累计充值
            allbet          = logInfo.totalBet,                                     -- 累计下注
            allinvite       = logInfo.totalInvite,                                  -- 累计邀请
            gold            = logInfo.chips,                                        -- 发放金额
            }
        else

        end
        table.insert(res.data.data,{
            charid          = logInfo._id.uid,                                          -- 玩家id
            starttime       = chessutil.FormatDateGet(logInfo._id.starttime),           -- 活动开始时间
            endtime         = chessutil.FormatDateGet(logInfo._id.endtime),             -- 活动结束时间
            activity        = logInfo._id.type,                                         -- 活动名称 1.累计充值活动
            allcharge       = logInfo.totalRecharge,                                -- 累计充值
            allbet          = logInfo.totalBet,                                     -- 累计下注
            allinvite       = logInfo.totalInvite,                                  -- 累计邀请
            gold            = logInfo.chips,                                        -- 发放金额
        })
        -- 统计合计数量
        res.data.totalcharge = res.data.totalcharge + logInfo.totalRecharge
        res.data.totalbet = res.data.totalbet + logInfo.totalBet
        res.data.totalinvite = res.data.totalinvite + logInfo.totalInvite
    end
    return res
end

-- 活动领取明细
function GetActiviteReward(cmd, laccount)
    local filter = unilight.gt('_id',0)
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid",cmd.data.charid))
    end
    -- 根据领取内容判断
    if cmd.data.activity ~= nil and cmd.data.activity > 0 then
        filter = unilight.a(filter,unilight.eq("type",cmd.data.activity))
    end
    -- 根据开始时间判断
    if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        filter = unilight.a(filter,unilight.ge("datetime",starttime))
    end
    -- 根据结束时间判断
    if cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
        local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.le("datetime",endtime))
    end
    local order = unilight.desc("starttime")
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table('generalactivitielog').Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                totalcharge = 0,
                totalbet = 0,
                totalinvite = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table('generalactivitielog').Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            data = {},
            totalcharge = 0,
            totalbet = 0,
            totalinvite = 0,
        }
    }
    for _, logInfo in ipairs(logInfos) do
        table.insert(res.data.data,{
            charid          = logInfo.uid,                                          -- 玩家id
            starttime       = chessutil.FormatDateGet(logInfo.starttime),           -- 活动开始时间
            endtime         = chessutil.FormatDateGet(logInfo.endtime),             -- 活动结束时间
            activity        = logInfo.type,                                         -- 活动名称 1.累计充值活动
            allcharge       = logInfo.totalRecharge,                                -- 累计充值
            allbet          = logInfo.totalBet,                                     -- 累计下注
            allinvite       = logInfo.totalInvite,                                  -- 累计邀请
            gold            = logInfo.chips,                                        -- 发放金额
            datetime        = chessutil.FormatDateGet(logInfo.datetime),            -- 领取时间
        })
        -- 统计合计数量
        res.data.totalcharge = res.data.totalcharge + logInfo.totalRecharge
        res.data.totalbet = res.data.totalbet + logInfo.totalBet
        res.data.totalinvite = res.data.totalinvite + logInfo.totalInvite
    end
    return res
end