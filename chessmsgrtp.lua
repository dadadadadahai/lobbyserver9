-- 玩家RTP系数
GmSvr.PmdRequestControllerUserPmd_C_CS = function(cmd, laccount)
    local filter = unilight.gt('_id',0)
    -- 根据玩家ID判断
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("_id",cmd.data.charid))
    end
    -- local order = unilight.desc("datetime")
    -- local userInfos = unilight.chainResponseSequence(unilight.startChain().Table('userinfo').Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    local userInfos = unilight.chainResponseSequence(unilight.startChain().Table('userinfo').Filter(filter).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    if table.empty(userInfos) then
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
    -- 插入信息
    for _, userInfo in ipairs(userInfos) do
        table.insert(res.data.datas,{
            charid     = userInfo.uid,                                            -- 玩家ID
            enterchips       = userInfo.endTime,                                              -- 进入携带金币
            curchips        = chessutil.FormatDateGet(userInfo.datetime,"%Y-%m-%d"),         -- 当前金币
            changechips      = userInfo.receivenum,                                           -- 金币变化
            gameid       = userInfo.grantgold,                                            -- 当前游戏
            gametype       = userInfo.grantgold,                                            -- 游戏类型
            controlvalue       = userInfo.grantgold,                                            -- 点控值
            totalrechargechips       = userInfo.property.totalRechargeChips,                                            -- 总充值金币数量
            totalcovertchips       = userInfo.status.chipsWithdraw,                                            -- 累计兑换金额(不包含推广)
            regflag       = userInfo.grantgold,                                            -- 注册来源 1.投放， 2.非投放
            betMoney       = userInfo.grantgold,                                            -- 当前下注金额
            rtpxs       = userInfo.grantgold,                                            -- rtp系数
            maxmul       = userInfo.grantgold,                                            -- 最终最大倍数
            time       = userInfo.grantgold,                                            -- 点控时长
            timedate       = userInfo.grantgold,                                            -- 点控开始时间
        })
    end
    return res
end