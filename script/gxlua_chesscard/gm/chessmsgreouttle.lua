-- 转盘相关gm请求

-- 请求转盘详情
GmSvr.PmdRequestTurntablePmd_CS = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("请求转盘生成 有误")
		return cmd
	end

    if cmd.data.optype == 1 then
        local filter = unilight.gt('uid',0)
        if cmd.data.charid ~= nil and cmd.data.charid ~= 0 then
            filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
        end
        local order = unilight.desc("dateTime")
        local inviterouletteInfoLogs = unilight.chainResponseSequence(unilight.startChain().Table(InviteRoulette.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
        local infoNum = unilight.startChain().Table(InviteRoulette.DB_Log_Name).Filter(filter).Count()
        filter = unilight.a(filter,unilight.eq("getType",-3))
        local totalInviteNum = unilight.startChain().Table(InviteRoulette.DB_Log_Name).Filter(filter).Count()
        local maxpage = math.ceil(infoNum/cmd.data.perpage)
        local res = {
            data = {
                batch = cmd.data.batch,
                code = cmd.data.code,
                maxpage = maxpage,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                dataspread = {},
                all = {
                    invite = totalInviteNum or 0
                }
            }
        }
        for _, inviterouletteInfoLog in ipairs(inviterouletteInfoLogs) do
            table.insert(res.data.dataspread,{
                charid   = inviterouletteInfoLog.uid,                                               -- 玩家id
                datetime = chessutil.FormatDateGet(inviterouletteInfoLog.lastChangeTime),           -- 转盘开启时间
                gettype  = inviterouletteInfoLog.getType,                                           -- 金额获取方式
                gold   	 = inviterouletteInfoLog.addCashNum,                                        -- 金额
                countnum = inviterouletteInfoLog.inviteNum,                                         -- 邀请人数
                goldall  = inviterouletteInfoLog.cashNum,                                           -- 转盘总额
                receivetime = chessutil.FormatDateGet(inviterouletteInfoLog.dateTime)               -- 当前时间
            })
        end
        return res
    elseif cmd.data.optype == 2 then
        -- 任务转盘
        local filter = unilight.gt('_id',0)
        local filterstr = '"_id":{"$gt":0}'
        if cmd.data.charid ~= nil and cmd.data.charid ~= 0 then
            filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
            filterstr = filterstr..',"uid":{"$eq":'..cmd.data.charid..'}'
        end
        -- 根据发放时间判断
        if cmd.data.begintime ~= nil and cmd.data.begintime ~= "" then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            filter = unilight.a(filter,unilight.ge("lastChangeTime",starttime))
            filterstr = filterstr..',"lastChangeTime":{"$gte":'..starttime..'}'
        end
        -- 根据发放时间判断
        if cmd.data.endtime ~= nil and cmd.data.endtime ~= "" then
            local endtime = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.le("lastChangeTime",endtime))
            filterstr = filterstr..',"lastChangeTime":{"$lte":'..endtime..'}'
        end
        local order = unilight.desc("lastChangeTime")
        local inviterouletteInfoLogs = unilight.chainResponseSequence(unilight.startChain().Table(TaskTurnTable.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
        local infoNum = unilight.startChain().Table(TaskTurnTable.DB_Log_Name).Filter(filter).Count()
        local maxpage = math.ceil(infoNum/cmd.data.perpage)

        local all = {
            invite      = 0;         --转盘总邀请
            truncount   = 0;         --累计转动次数
            receivegold = 0;         --累计获得金额
            counth   	= 0;         --获得H字母数量
            counta   	= 0;         --获得A字母数量
            countp   	= 0;         --获得P字母数量
            county   	= 0;         --获得Y字母数量
        }
        local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(TaskTurnTable.DB_Log_Name).Aggregate('{"$match":{'..filterstr..'}}',
        '{"$group":{"_id":{"getType":"$getType"},"addCashNum":{"$sum":"$addCashNum"},"sumcount":{"$sum":1}}}'))
        for _, info in ipairs(logInfos) do
            if all["count"..string.lower(info._id.getType)] ~= nil then
                all["count"..string.lower(info._id.getType)] = info.sumcount
            else
                all.receivegold = all.receivegold + info.addCashNum
            end
            all.truncount = all.truncount + info.sumcount
        end
        print(table2json(logInfos))
        local res = {
            data = {
                batch = cmd.data.batch,
                code = cmd.data.code,
                maxpage = maxpage,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                data = {},
                dataspread = {},
                all = all,
            }
        }
        for _, inviterouletteInfoLog in ipairs(inviterouletteInfoLogs) do
            table.insert(res.data.data,{
                charid   = inviterouletteInfoLog.uid,                                               -- 玩家id
                datetime = chessutil.FormatDateGet(inviterouletteInfoLog.lastChangeTime),           -- 转盘开启时间
                gettype  = inviterouletteInfoLog.getType,                                           -- 金额获取方式
                count    = inviterouletteInfoLog.addCashNum,                                        -- 金额
            })
        end
        return res
    end
end