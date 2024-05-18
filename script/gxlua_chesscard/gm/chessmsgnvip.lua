-- 徽章等级相关gm请求
-- 请求徽章等级满足要求的个数
GmSvr.PmdStRequestVipListInfoPmd_CS = function(cmd, laccount)
    if cmd.data.optype == 1 then
        return GetVipUserList(cmd, laccount)
    elseif cmd.data.optype == 2 then
        return GetVipUserRewardList(cmd, laccount)
    end
end

-- 获取VIP玩家列表
function GetVipUserList(cmd, laccount)
    local filter = unilight.gt('_id',0)
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("_id",cmd.data.charid))
    end
    -- 根据领取内容判断
    if cmd.data.viplevel ~= nil and cmd.data.viplevel >= 0 then
        filter = unilight.a(filter,unilight.eq("property.vipLevel",cmd.data.viplevel))
    end
    local order = unilight.desc("property.vipLevel")
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table('userinfo').Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                datas = {},
                receivegold = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table('userinfo').Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            datas = {},
        }
    }
    -- res.data.receivegold = 0
    res.data.viptotalnum = infoNum
    for _, logInfo in ipairs(logInfos) do
        table.insert(res.data.datas,{
            charid          = logInfo.uid,                                                          -- uid
            viplevel        = logInfo.property.vipLevel,                                            -- VIP等级
            rechargechips   = logInfo.property.totalRechargeChips,                                  -- 总充值
            convertchips    = logInfo.status.chipsWithdraw + logInfo.status.promoteWithdaw,         -- 总提现
            betchips        = logInfo.property.betMoney,                                            -- 总下注
        })
        -- 统计合计数量
        -- res.data.receivegold = res.data.receivegold + logInfo.gold
        -- res.data.viptotalnum = res.data.viptotalnum + 1
    end
    return res
end

-- 获取VIP奖励领取日志
function GetVipUserRewardList(cmd, laccount)
    local filter = unilight.gt('uid',0)
    -- 根据玩家ID
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid",cmd.data.charid))
    end
    -- 根据领取内容判断
    if cmd.data.viplevel ~= nil and cmd.data.viplevel >= 0 then
        filter = unilight.a(filter,unilight.eq("level",cmd.data.viplevel))
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
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(nvipmgr.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(logInfos) then
        local res = {
            data = {
                maxpage = 0,
                perpage = cmd.data.perpage,
                curpage = cmd.data.curpage,
                reward = {},
                viptotalreward = 0,
                viptotalnum = 0,
            }
        }
        return res
    end
    local infoNum = unilight.startChain().Table(nvipmgr.DB_Log_Name).Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            reward = {},
            viptotalreward = 0,
            viptotalnum = 0,
        }
    }
    for _, logInfo in ipairs(logInfos) do
        table.insert(res.data.reward,{
            charid          = logInfo.uid,                                              -- uid
            viplevel        = logInfo.level,                                            -- VIP等级
            date            = chessutil.FormatDateGet(logInfo.datetime),                -- 领取时间
            content         = logInfo.content,                                          -- 领取内容
            gold            = logInfo.gold,                                             -- 领取金额
        })
        -- 统计合计数量
        res.data.viptotalreward = res.data.viptotalreward + logInfo.gold
        res.data.viptotalnum = res.data.viptotalnum + 1
    end
    return res
end