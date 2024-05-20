-- 红包雨相关gm请求

-- 请求红包雨详情
GmSvr.PmdRequestRedEnvelopeRainPmd_C = function(cmd, laccount)
    -- 红包雨发放日志
    if cmd.data.optype == 1 then
        local filter = unilight.gt('_id',0)
        -- 根据发放时间段判断
        if cmd.data.periodstart ~= nil and cmd.data.periodstart > 0 and cmd.data.periodend ~= nil and cmd.data.periodend > 0 then
            filter = unilight.a(filter,unilight.a(unilight.eq("startTime",cmd.data.periodstart),unilight.le("endTime",cmd.data.periodend)))
        end
        -- 根据发放时间判断
        if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" and cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.a(unilight.ge("datetime",starttime),unilight.le("datetime",endtime)))
        end
        local order = unilight.desc("datetime")
        local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(redRain.DB_GrantLog_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
        if table.empty(logInfos) then
            local res = {
                data = {
                    maxpage = 0,
                    perpage = cmd.data.perpage,
                    curpage = cmd.data.curpage,
                    dataall = {},
                    all = {
                        receivegold = 0,
                        receivenum = 0
                    },
                }
            }
            return res
        end
        local infoNum = unilight.startChain().Table(redRain.DB_GrantLog_Name).Filter(filter).Count()
        local maxpage = math.ceil(infoNum/cmd.data.perpage)
        local res = {
            data = {
                batch = cmd.data.batch,
                code = cmd.data.code,
                maxpage = maxpage,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                dataall = {},
                all = {},
            }
        }
        res.data.all.receivegold = 0
        res.data.all.receivenum = 0
        for _, logInfo in ipairs(logInfos) do
            table.insert(res.data.dataall,{
                periodstart     = logInfo.startTime,                                            -- 时间段开始时间
                periodend       = logInfo.endTime,                                              -- 时间段结束时间
                datetime        = chessutil.FormatDateGet(logInfo.datetime,"%Y-%m-%d"),         -- 发放时间
                receivenum      = logInfo.receivenum,                                           -- 领取数量
                grantgold       = logInfo.grantgold,                                            -- 总金额
            })
            -- 统计合计数量
            res.data.all.receivegold = res.data.all.receivegold + logInfo.grantgold
            res.data.all.receivenum = res.data.all.receivenum + logInfo.receivenum
            -- res.data.all.receivegold = res.data.all.receivegold + logInfo.receivenum
            -- res.data.all.receivenum = res.data.all.receivenum + 1
        end
        return res
    elseif cmd.data.optype == 2 then
        -- 领取日志
        local filter = unilight.gt('_id',0)
        -- 根据发放时间段判断
        if cmd.data.periodstart ~= nil and cmd.data.periodstart > 0 and cmd.data.periodend ~= nil and cmd.data.periodend > 0 then
            filter = unilight.a(filter,unilight.a(unilight.eq("startTime",cmd.data.periodstart),unilight.le("endTime",cmd.data.periodend)))
        end
        -- 根据发放时间判断
        if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" and cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.a(unilight.ge("datetime",starttime),unilight.le("datetime",endtime)))
        end
        local order = unilight.desc("datetime")
        local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(redRain.DB_GetLog_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
        if table.empty(logInfos) then
            local res = {
                data = {
                    maxpage = 0,
                    perpage = cmd.data.perpage,
                    curpage = cmd.data.curpage,
                    datauser = {},
                    all = {
                        receivegold = 0,
                        receivenum = 0
                    },
                }
            }
            return res
        end
        local infoNum = unilight.startChain().Table(redRain.DB_GrantLog_Name).Filter(filter).Count()
        local maxpage = math.ceil(infoNum/cmd.data.perpage)
        local res = {
            data = {
                batch = cmd.data.batch,
                code = cmd.data.code,
                maxpage = maxpage,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                datauser = {},
                all = {},
            }
        }
        res.data.all.receivegold = 0
        res.data.all.receivenum = 0

        for _, logInfo in ipairs(logInfos) do
            table.insert(res.data.datauser,{
                charid          = logInfo.charid,                                               -- 玩家ID
                datetime        = chessutil.FormatDateGet(logInfo.datetime),                    -- 发放时间
                periodstart     = logInfo.startTime,                                            -- 时间段开始时间
                periodend       = logInfo.endTime,                                              -- 时间段结束时间
                gold            = logInfo.gold,                                                 -- 总金额
            })
            -- 统计合计数量
            res.data.all.receivegold = res.data.all.receivegold + logInfo.gold
            res.data.all.receivenum = res.data.all.receivenum + 1
        end
        return res
    end
end