-- 徽章等级相关gm请求
-- 请求徽章等级满足要求的个数
GmSvr.PmdRequestLossRebatePmd_C = function(cmd, laccount)
    local filter = unilight.gt('uid',0)
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid",cmd.data.charid))
    end
    -- 根据发放时间判断
    if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        filter = unilight.a(filter,unilight.ge("datetime",starttime))
    end
    -- 根据发放时间判断
    if cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
        local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.le("datetime",endtime))
    end
    local order = unilight.desc("datetime")
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(LossRebate.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                receivegold = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table(LossRebate.DB_Log_Name).Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            data = {},
        }
    }
    res.data.receivegold = 0
    res.data.receivenum = 0
    for _, logInfo in ipairs(logInfos) do
        table.insert(res.data.data,{
            charid          = logInfo.uid,                                                  -- uid
            datetime        = chessutil.FormatDateGet(logInfo.datetime),                    -- 领取时间
            netloss         = logInfo.newloss,                                              -- 净损失金额
            receivegold     = logInfo.receivegold,                                          -- 领取返利金额
        })
        -- 统计合计数量
        res.data.receivegold = res.data.receivegold + logInfo.receivegold
        res.data.receivenum = res.data.receivenum + 1
    end
    return res
end