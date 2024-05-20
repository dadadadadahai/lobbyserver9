-- 投注统计相关gm请求
local table_shop_config = import "table/table_shop_config"
local table_recharge_plat = import "table/table_recharge_plat"
local table_withdraw_plat = import "table/table_withdraw_plat"
local table_autoControl_nc = import "table/table_autoControl_nc"
local table_autoControl_cz = import "table/table_autoControl_cz"
local table_autoControl_dc = import "table/table_autoControl_dc"
local table_stock_tax  = import "table/table_stock_tax"
local table_stock_xs_1 = import "table/table_stock_xs_1"
local table_stock_xs_2 = import "table/table_stock_xs_2"
local table_stock_xs_3 = import "table/table_stock_xs_3"
local table_stock_recharge_lv = import "table/table_stock_recharge_lv"
local table_stock_play_limit = import "table/table_stock_play_limit"
local table_recharge_reward = import "table/table_recharge_reward"
local table_game_list = import "table/table_game_list"
local table_parameter_parameter = import "table/table_parameter_parameter"
local table_mail_config = import "table/table_mail_config"
local table_stock_single = import "table/table_stock_single"


-- 请求投注统计详情
GmSvr.PmdRequestBettingDetailGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	if cmd.data == nil then
		unilight.error("请求投注统计详情 有误")
		return res
	end
	local uid 		= cmd.data.charid
	local dealerId 	= cmd.data.dealerid
	local startTime = cmd.data.starttime
	local endTime 	= cmd.data.endtime
	local subGameId = cmd.data.subgameid
	local curPage 	= cmd.data.curpage
	local perPage 	= cmd.data.perpage
	local openSource= cmd.data.opensource
	local gmId 		= cmd.data.gmid

	if startTime == 0 then
		startTime = os.time() - 24*60*60
	end
	if endTime == 0 then
		endTime = os.time()
	end

	if curPage == 0 then
		curPage = 1
	end

	local staticInfo 	= nil
	local maxPage 		= nil

	if uid ~= 0 then
		-- 指定玩家
		staticInfo, maxPage = chessprofitbet.CmdGamePlayInfoGetByGameIdUidBetween(uid, subGameId, startTime, endTime, (curPage-1)*perPage, perPage, openSource)

	elseif dealerId ~= 0 then
		-- 指定庄家
		staticInfo, maxPage = chessprofitbet.CmdGameBankerInfoGetByGameIdUidBetween(dealerId, subGameId, startTime, endTime, (curPage-1)*perPage, perPage, openSource)
	else
		-- 获取所有玩家
		staticInfo, maxPage = chessprofitbet.CmdStaticInfoGetByGameIdBetween(subGameId, startTime, endTime, (curPage-1)*perPage, perPage, openSource)
	end
	local betDatas = {}
	for i,v in ipairs(staticInfo) do
		-- 投注记录
		if v.type == 1 then
			local betData = {
				id 			= i,
				roundid 	= v.roundid, 					-- 无 已补
				recordtime 	= v.timestamp,
				charid 		= v.uid,
				charname	= v.nickname or "老数据无名字", -- 暂无 后续补充
				winlosenum  = v.profitchips,				-- 无需减去betChips
				totalnum 	= v.remainder,					-- 暂无 后续补充
				dealerid	= nil,							-- 无 待补
				dealernum	= nil,							-- 无 待补
				opensource 	= v.opensource,					-- 开奖来源
				dealerremain= nil,
				dealername	= nil,
			}
			-- 如果存在 投注详情 及 开奖结果 则 返回
			if v.detail ~= nil then
				local betdetail, lotterydetail = ChessGmStaticMgr.GetDetail(subGameId, v.detail)
				betData.betdetail 		= betdetail
				betData.lotterydetail 	= lotterydetail
			end
			table.insert(betDatas, betData)
		else
			local betData = {
				id 			= i,
				roundid 	= v.roundid,
				recordtime 	= v.timestamp,
				charid 		= nil,
				charname	= "",
				winlosenum  = nil,
				totalnum 	= nil,
				dealerid	= v.uid,
				dealernum	= v.profitchips or (v.remainderbankerchips - v.carrybankerchips),
				opensource  = v.opensource,
				dealerremain= v.remainderbankerchips + (v.remainder or 0),
				dealername	= v.nickname,
			}
			table.insert(betDatas, betData)
		end
	end

	res.data.maxpage = maxPage
	res.data.data 	 = betDatas

	unilight.info("请求投注统计详情 成功")
	return res
end

-- 请求投注输赢排行榜
GmSvr.PmdRequestWinningListGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	if cmd.data == nil then
		unilight.error("请求投注输赢排行榜 有误")
		return res
	end
	local uid 		= cmd.data.charid
	local starttime = os.time() - cmd.data.timestamp
	local endtime 	= os.time()
	local subgameid = cmd.data.subgameid
	local curpage 	= cmd.data.curpage
	local perpage 	= cmd.data.perpage
	local gmid 		= cmd.data.gmid

	-- 不应该出现的（默认为3小时吧）
	if cmd.data.timestamp == 0 then
		starttime = os.time() - 3*3600
	end

	if curpage == 0 then
		curpage = 1
	end

    local count = unilight.chainResponseSequence(unilight.startChain().Table("userprofitbet").Aggregate('{"$match":{"gameid":{"$eq":' .. subgameid .. '}, "timestamp":{ "$gt" : ' .. starttime .. ', "$lte" : ' .. endtime .. '}}}','{"$group":{"_id":"$uid"}}','{"$group":{"_id":1, "count":{"$sum":1}}}'))
    count = (count[1] and count[1].count) or 0

    local info = unilight.chainResponseSequence(unilight.startChain().Table("userprofitbet").Aggregate('{"$match":{"gameid":{"$eq":' .. subgameid .. '}, "timestamp":{ "$gt" : ' .. starttime .. ', "$lte" : ' .. endtime .. '}}}','{"$group":{"_id":"$uid", "profit":{"$sum":"$profitchips"}}}','{"$sort":{"profit":-1}}').Skip((curpage-1)*perpage).Limit(perpage))

    info = info or {}
    local winningInfos = {}
    for i,v in ipairs(info) do
        local winningInfo = {
            id              = (curpage-1)*perpage + i,
            charid          = v._id,
            charname        = nil,
            viplevel        = 0,
            isonline        = 2,            -- 2表示离线 默认离线
            totalnum        = v.profit,
            curnum          = 0,
        }
        table.insert(winningInfos, winningInfo)
    end

    -- 获取isonline数据
    local onlineInfo = go.accountmgr.GetOnlineList()
    local onlineMap  = {}
    for i=1,#onlineInfo do
        onlineMap[onlineInfo[i]] = true
    end

    -- 填充curnum isonline
    for i,v in ipairs(winningInfos) do
        -- 玩家在线
        if onlineMap[v.charid] then
                v.isonline = 1
        end

        -- 填充curnum
        local userInfo = chessuserinfodb.RUserDataGet(v.charid, true)
        v.curnum = userInfo.property.chips
        v.charname= userInfo.base.nickname
    end
	-- 返回恰当的数据
	res.data.maxpage = math.ceil(count/perpage)
	res.data.data 	 = winningInfos

	unilight.info("请求投注输赢排行榜 成功")
	return res
end

-- 查询转账红包相关
GmSvr.PmdRequestRedPacketsGmUserPmd_CS = function(cmd, laccount)
	local res = cmd

	if cmd.data == nil then
		unilight.info("查询转账红包数据有误")
		return
	end

	local srcuid 		= cmd.data.srcuid
	local desuid 		= cmd.data.desuid
	local starttime 	= cmd.data.starttime
	local endtime 		= cmd.data.endtime
	local packetcode 	= cmd.data.packetcode
	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage

	if endtime == 0 then
		endtime = os.time()
	end

	if curpage == 0 then
		curpage = 1
	end

	local datas = {}
	local maxpage = 0
	-- 默认查询当前兑换码
	if packetcode ~= "" then
		local info = unilight.getdata("lobbyExchange", packetcode)
		if info ~= nil then
			local receiveTime = chessutil.TimeByDateGet(info.receivedate)
			local data = {
				id = info.exchangeorder,
				srcuid = info.srcuid,
				srcnickname = info.srcnickname or "老红包数据 暂无名字",
				desuid = info.dstuid,
				desnickname = info.dstnickname or "老红包数据 暂无名字",
				money = info.chips,
				recordtime = receiveTime,
			}
			table.insert(datas, data)
		end
	else
		local filter = nil
		-- 均空 获取全部转账信息
		if srcuid == 0 and desuid == 0 then
			filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""))
		-- 该玩家发起 的 所有转账信息
		elseif srcuid ~= 0 and desuid == 0 then
			filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""), unilight.eq("srcuid", srcuid))
		-- 该玩家接收 的 所有转账信息
		elseif srcuid == 0 and desuid ~= 0 then
			filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""), unilight.eq("dstuid", desuid))
		-- 定向发送 的 转账信息
		else
			filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""), unilight.eq("srcuid", srcuid), unilight.eq("dstuid", desuid))
		end

		-- 时间过滤
		filter = unilight.a(filter, unilight.ge("receivetime", starttime), unilight.le("receivetime", endtime))

		local infoNum = unilight.startChain().Table("lobbyExchange").Filter(filter).Count()
		maxpage = math.ceil(infoNum/perpage)

		local info = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter).OrderBy(unilight.asc("receivetime")).Skip((curpage-1)*perpage).Limit(perpage))

		for i,v in ipairs(info) do
			local data = {
				id 			= v.exchangeorder,
				srcuid 		= v.srcuid,
				srcnickname = v.srcnickname or "老红包数据 暂无名字",
				desuid 		= v.dstuid,
				desnickname = v.dstnickname or "老红包数据 暂无名字",
				money 		= v.chips,
				recordtime 	= v.receivetime,
			}
			table.insert(datas, data)
		end
	end

	res.data.maxpage 	= maxpage
	res.data.data 		= datas

	unilight.info("请求转账红包相关信息 成功")
	return res
end

-- 查询具体玩家金币变动
GmSvr.PmdRequestUserItemsHistoryListGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil

    if cmd.data.charid == 0 then
        cmd.data.retcode = 1 
        cmd.data.retdesc =  "错误的玩家id"
        return cmd
    end

    local data = cmd.data
    local orderBy = unilight.desc("timestamp")
    if data.querytype ~= nil and data.querytype == 2  then
        orderBy = unilight.asc("timestamp")
    end

    filter = unilight.ge('uid',0)

    --角色id
    if data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", data.charid))
    end

    --货币类型
    if data.optype > 0 then
        filter = unilight.a(filter,unilight.eq("itemid", data.optype))
    end

    --时间
    if data.begintime > 0 and data.endtime > 0 then
        filter = unilight.a(filter,unilight.ge('timestamp',data.begintime), unilight.le('timestamp',data.endtime))
    end

    --变动类型
    if data.changetype > 0 then
        --消耗
        if data.changetype == 1 then
            filter = unilight.a(filter,unilight.lt("diff", 0))
        --获得
        else
            filter = unilight.a(filter,unilight.gt("diff", 0))
        end
    end

    local allNum = unilight.startChain().Table("newItemsHistory").Filter(filter).Count()
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("newItemsHistory").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))


    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        if data.querytype ~= nil and data.querytype == 2  then
            table.insert(datas,
            {
                charid    = info.uid,
                -- itemid    = info.itemid, -- // 道具名称,不填默认为货币,或者问策划道具表要
                balance   = info.balance, -- // 当前余额(操作后)
                -- diff      = info.diff, --; // 本次操作变化量
                timestamp = info.timestamp, -- // 操作时间,unixtime unitme.Time.Sec()
                chipswithdraw = info.chipsWithdraw or 0,  --提现金额
                totalrechargechips = info.totalRechargeChips or 0,  --充值金额
                cancovertchips = info.canCovertChips or 0,  --可兑换额度
            }
            )
        else

            table.insert(datas,
            {
                charid    = info.uid,
                charname  = userInfo.base.nickname,
                itemid    = info.itemid, -- // 道具名称,不填默认为货币,或者问策划道具表要
                balance   = info.balance, -- // 当前余额(操作后)
                diff      = info.diff, --; // 本次操作变化量
                timestamp = info.timestamp, -- // 操作时间,unixtime unitme.Time.Sec()
                desc      = info.desc, --; // 操作描述
                chipswithdraw = info.chipsWithdraw or 0,  --提现金额
                totalrechargechips = info.totalRechargeChips or 0,  --充值金额
            }
            )

        end
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd

end

-- 请求麻将游戏记录
GmSvr.PmdLobbyGameHistoryGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	if cmd.data == nil then
		unilight.error("请求麻将游戏记录 有误")
		return res
	end
	local uid 		= cmd.data.charid
	local startTime = cmd.data.starttime
	local endTime 	= cmd.data.endtime
	local subGameId = cmd.data.subgameid
	local curPage 	= cmd.data.curpage
	local perPage 	= cmd.data.perpage

	if startTime == 0 then
		startTime = os.time() - 24*60*60
	end
	if endTime == 0 then
		endTime = os.time()
	end

	if curPage == 0 then
		curPage = 1
	end

	local ret, desc, curPage, maxPage, gameHistroys = HistoryMgr.GetGameHistoryByGm(uid, subGameId, startTime, endTime, curPage, perPage)
	res.data.maxpage = maxPage
	res.data.data 	 = gameHistroys

	unilight.info("请求麻将游戏记录 成功")
	return res
end

-- 请求麻将游戏记录详情
GmSvr.PmdLobbyGameDetailHistoryGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	if cmd.data == nil then
		unilight.error("麻将游戏记录详情 有误")
		return res
	end
	local globalRoomId = cmd.data.groomid

	local ret, desc, roundHistorys = HistoryMgr.GetHistroyDetailByGlobalRoomIdGm(globalRoomId)

	res.data.maxpage = maxPage
	res.data.data 	 = roundHistorys

	unilight.info("麻将游戏记录详情 成功")
	return res
end

------------------------------------------------------
-- 为了应对香港查询相关
LoginClientTask.PlatQueryGamerecordSdkPmd_CS =function(task, cmd)
	if ChessDbInit.isNotStatistics == false then
		unilight.info("PlatQueryGamerecordSdkPmd_CS this is lobby not for statatics")
		return
	end
	unilight.info("LoginClientTask PlatQueryGamerecodrdSdkPmd_S".. cmd.String())
	local platAccount = cmd.GetData().GetPlataccount()
	local platId = cmd.GetData().GetPlatid()
    local perPage = cmd.GetPerpage()
    local curPage = cmd.GetCurpage()
    local startTime = cmd.GetStart()
    local endTime = cmd.GetEnd()
	if endTime == 0 then
		endTime = os.time()
	end
   	if platAccount ~= "" and platId ~= 0 then
        local userInfo =chessuserinfodb.RUserInfoGetByPlatidPlataccount(platId, platAccount)
        if userInfo == nil then
            unilight.error("玩家不存在")
	        task.SendCmd(cmd)
            return
        end
		task.SendCmd(QueryUserGameRecord(userInfo, cmd, perPage, curPage, startTime, endTime))
        return
	else
		local platList = {}
    		for i, v in ipairs(cmd.GetPlatid()) do
			table.insert(platList, v)
		end
		if table.len(platList) ~= 0 then
			cmd = (QueryPlatGameRecord(platList, cmd, perPage, curPage, startTime, endTime))
			task.SendCmd(cmd)
			return
		end
	end
	task.SendCmd(cmd)
end
function GameRecordConstruct(cmd, staticInfo, maxPage, userInfo)
    local gameRecordList = {}
    for i, v in ipairs(staticInfo) do
        local gameRecordItem = {
            charid = v.uid,
            charname = v.nickname,
            platid=v.platid,
            sceneid=v.gameid,
            roomid = v.roundid,
            bet = v.betchips,
            payout = v.profitchips+v.betchips,
	        chips = v.remainder,
            profit=v.profitchips,
            time = v.time,
        }
        local a = go.buildProto("*Pmd.GameRecord", json.encode(gameRecordItem))
        table.insert(gameRecordList, a)
    end
    cmd.Maxpage = maxPage
    cmd.Rdata = gameRecordList
    return cmd

end
function QueryUserGameRecord(userInfo, cmd, perPage, curPage, startTime, endTime)
    local uid = userInfo.uid
    local staticInfo, maxPage = chessprofitbet.CmdGamePlayInfoGetByUidBetween(uid, startTime, endTime, (curPage-1)*perPage, perPage)
    return GameRecordConstruct(cmd, staticInfo, maxPage, userInfo)
end

function QueryPlatGameRecord(platList, cmd, perPage, curPage, startTime, endTime)
    local staticInfo, maxPage = chessprofitbet.CmdPlayInfoGetByPlatidList(platList, startTime, endTime, (curPage-1)*perPage, perPage)
    return GameRecordConstruct(cmd, staticInfo, maxPage)
end

-- 查询某个玩家列表相关信息
LoginClientTask.PlatQueryUserListSdkPmd_CS=function(task, cmd)
	if ChessDbInit.isNotStatistics == false then
		unilight.info("PlatQueryUserListSdkPmd_CS this is lobby not for statatics")
		return
	end

    local platAccount = cmd.GetData().GetPlataccount()
	local platId = cmd.GetData().GetPlatid()
    local perPage = cmd.GetPerpage()
    local curPage = cmd.GetCurpage()
   	if platAccount ~= "" and platId ~= 0 then
        local userInfo =chessuserinfodb.RUserInfoGetByPlatidPlataccount(platId, platAccount)
        if userInfo == nil then
            unilight.error("PlatQueryUserListSdkPmd_CS uid is null" .. platId .. ":".. platAccount)
	        task.SendCmd(cmd)
            return
        end
		cmd = QueryUserInfo(userInfo, cmd)
		unilight.info("send QueryPlatUserInfo " .. cmd.String())
		task.SendCmd(cmd)
        return
    end

    -- 查询平台相关的玩家具体信息
    local platList = {}
    for i, v in ipairs(cmd.GetPlatid()) do
        table.insert(platList, v)
    end
    if table.len(platList) ~= 0 then
	    cmd = QueryPlatUserInfo(platList, cmd, perPage, curPage)
	    unilight.info("send QueryPlatUserInfo " .. cmd.String())
	    task.SendCmd(cmd)
        return
    end

end

function GetPlatUserInfo(v)
    local platUserInfo = {
            charid = v.uid,
            platid = v.base.platid,
            charname = v.base.nickname,
            plataccount = v.base.plataccount,
            createtime = v.status.registertime,
            lastlogin = v.status.lastlogintime,
            lastloginip = "8.8.8.8",
            balance = v.property.chips,
    }
    return platUserInfo
end

function QueryUserInfo(userInfo, cmd)
        local rdata = {}
        local a = go.buildProto("*Pmd.PlatUserInfo", json.encode(GetPlatUserInfo(userInfo)))
        table.insert(rdata, a)
        cmd.Rdata = gameRecordList
        return cmd
end

function QueryPlatUserInfo(platList, cmd, perPage, curPage)
    local userInfoList, maxPage = chessprofitbet.CmdUserInfoGetByPlatidList(platList, (curPage-1)*perPage, perPage)
    local rdata = {}
    for i, v in ipairs(userInfoList) do
        local a = go.buildProto("*Pmd.PlatUserInfo", json.encode(GetPlatUserInfo(v)))
        table.insert(rdata, a)
    end
    cmd.Rdata = rdata
    cmd.Maxpage = maxPage
    return cmd
end

LoginClientTask.PlatQueryPlatReportSdkPmd_CS=function(task, cmd)
	if ChessDbInit.isNotStatistics == false then
		unilight.info("PlatQueryPlatReportSdkPmd_CS this is lobby not for statatics")
		return
	end

	unilight.info("rev From LoginClientTask PlatQueryPlatReportSdkPmd_CS ".. cmd.String())

    local startTime = cmd.GetStart()
    local endTime = cmd.GetEnd()

    -- 当不确定时间时，就找今天的数据
    if endTime == 0 then
	    endTime = os.time()
	    startTime = endTime - 10*24*60*60
    end
    local startDay = chessutil.FormatDayGet2(startTime)
    local endDay = chessutil.FormatDayGet2(endTime)

    local platList = {}
    local rdata = {}
    for i, platId in ipairs(cmd.GetPlatid()) do
	    local dau, betusers, bet, payout, profit= chessprofitbet.QueryPlatUserBetByPlatId(platId, startDay, endDay)
	    local percent = 0
	    if bet ~= 0 then
		    percent = tonumber(profit/bet)
	    end
        local platData = {
            platid = platId,
            subplatid = platId,
            dau = dau,
            betusers= betusers,
	        betnum = bet,
	        bet = bet,
            payout = payout,
            profit = profit,
            percent = percent,
        }
        local a = go.buildProto("*Pmd.PlatReport", json.encode(platData))
        table.insert(rdata, a)
    end

    cmd.Rdata = rdata
    task.SendCmd(cmd)
end

LoginClientTask.PlatQueryPlatDailySdkPmd_CS=function(task, cmd)
	if ChessDbInit.isNotStatistics == false then
		unilight.info("PlatQueryPlatDailySdkPmd_CSthis is lobby not for statatics")
		return
	end

	unilight.info("Rev From LoginClientTask PlatQueryPlatDailySdkPmd_CS".. cmd.String())
    local startTime = cmd.GetStart()
    local endTime = cmd.GetEnd()

    -- 当不确定时间时，就找今天的数据
    if endTime == 0 then
	    endTime = os.time()
	    startTime = endTime - 10*24*60*60
    end

    local startDay = chessutil.FormatDayGet2(startTime)
    local endDay = chessutil.FormatDayGet2(endTime)

    local rdata = {}
    for i, platId in ipairs(cmd.GetPlatid()) do
	    local data = chessprofitbet.QueryPlatDayUserBetByPlatId(platId, startDay, endDay)
	    for i, v in ipairs(data) do
	        local percent = 0
	        if v.bet ~= 0 then
		        percent = tonumber(v.profit/v.bet)
	        end
            local platData = {
                platid = platId,
                subplatid = platId,
                dau = v.dau,
                betusers= v.betusers,
	            betnum = v.bet,
	            bet = v.bet,
                payout = v.payout,
                profit = v.profit,
                percent = percent,
            }
            local a = go.buildProto("*Pmd.PlatDailyData", json.encode(platData))
            table.insert(rdata, a)
	    end
    end

    cmd.Rdata = rdata
    task.SendCmd(cmd)
end


--查找订单数据
GmSvr.PmdGameOrderListGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    --计算创建订单金额
    -- local filterStr2 = '"userinfo.base.regFlag":{"$gt":' .. 0 .. '}'
    -- if cmd.data.regflag > 0 then
    --     filterStr2 = '"userinfo.base.regFlag":{"$eq":' .. cmd.data.regflag .. '}'
    -- end
    local tmp=''
    if cmd.data.regflag > 0 then
        tmp=',"regFlag":'..cmd.data.regflag
    end
    local filterStr1 = '"uid":{"$gte":0}'..tmp
    if cmd.data.subplatid > 0 then
        filterStr1 = '"subplatid":{"$eq":' .. cmd.data.subplatid .. '}'..tmp
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filterStr1 = filterStr1 .. ', "subTime":{"$gte":' .. starttime .. ', "$lt":'..endtime..'}'
    end

    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "sum":{"$sum":"$subPrice"}}}'))
    local allrecharge = 0
    --[[
    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"subPrice":1}}', '{"$group":{"_id":null, "sum":{"$sum":"$subPrice"}}}' ))
    ]]
    if table.len(info)  > 0  then
        allrecharge = info[1].sum
    end

    --等待支付金额
    local tmpFilterStr = filterStr1 .. ', "status":{"$eq":' .. 0 .. '}'
    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$subPrice"}}}'))
    local waitpay = 0
    --[[
    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{"status":0}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"subPrice":1}}','{"$group":{"_id":null, "sum":{"$sum":"$subPrice"}}}'  ))
    ]]
    if table.len(info) > 0 then
        waitpay = info[1].sum
    end

    --已支付金额
    local tmpFilterStr = filterStr1 .. ', "status":{"$eq":' .. 2 .. '}'
    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$backPrice"}}}'))
    local alreadypay = 0
    --[[
    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{"status":2}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"backPrice":1}}','{"$group":{"_id":null, "sum":{"$sum":"$backPrice"}}}'  ))
    ]]
    if table.len(info) > 0 then
        alreadypay = info[1].sum
    end

    local filter = unilight.gt("uid", 0)
    local filterStr = '"uid":{"$gt":' .. 0 .. '}'
    if cmd.data.regflag>0 then
        filter = unilight.a(filter,unilight.eq("regFlag", cmd.data.regflag))
    end
    if cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
        filterStr = filterStr .. ', "uid":{"$eq":' .. cmd.data.charid .. '}'
    end
    if string.len(cmd.data.charname) > 0 then
        filter = unilight.a(filter, unilight.eq("nickname", cmd.data.charname))
        filterStr = filterStr .. ', "nickname":{"$eq":' .. cmd.data.charname .. '}'
    end
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter, unilight.ge("subTime", starttime), unilight.le("subTime", endtime))
        filterStr = filterStr .. ', "subTime":{"$gte":' .. starttime .. ', "$lt":'..endtime..'}'
    end

	if cmd.data.status < 100 then
        filter = unilight.a(filter, unilight.eq("status", cmd.data.status))
        filterStr = filterStr .. ', "status":{"$eq":' .. cmd.data.status .. '}'
	end

    if cmd.data.rechargetype > 0 then
        filter = unilight.a(filter, unilight.eq("shopType", cmd.data.rechargetype))
        filterStr = filterStr .. ', "shopType":{"$eq":' .. cmd.data.rechargetype .. '}'
    end

    if string.len(cmd.data.gameorder) > 0 then
        filter = unilight.a(filter, unilight.eq("_id", cmd.data.gameorder))
        filterStr = filterStr .. ', "_id":{"$eq":' .. cmd.data.gameorder .. '}'
    end

    if string.len(cmd.data.platorder) > 0 then
        filter = unilight.a(filter, unilight.eq("platorder", cmd.data.platorder))
        filterStr = filterStr .. ', "platorder":{"$eq":' .. cmd.data.platorder .. '}'
    end

    if cmd.data.subplatid > 0 then
        filter = unilight.a(filter, unilight.eq("subplatid", cmd.data.subplatid))
    end

    local allNum = 0
    local allNum 	= unilight.startChain().Table("orderinfo").Filter(filter).Count()
    -- local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter(filter).OrderBy(unilight.desc("subTime")).Skip((curpage-1)*perpage).Limit(perpage))
    --[[
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{'..filterStr ..'}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}','{"$group":{"_id":null, "sum":{"$sum":1}}}'  ))
    ]]
    -- if table.len(infos) > 0 then
        -- allNum = infos[1].sum
    -- end

	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter(filter).OrderBy(unilight.desc("subTime")).Skip((curpage-1)*perpage).Limit(perpage))

    --[[
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{'..filterStr ..'}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0, "userinfo.base":0}}',  '{"$sort": {"subTime": -1}}', '{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}' ))
    ]]

    maxpage = math.ceil(allNum/perpage)

    for i, info in ipairs(infos) do

        local userInfo = chessuserinfodb.RUserDataGet(info.uid)
        local shopConfig = table_shop_config[info.shopId]
        local goodNum  = 0
        local diamondNum = 0
        if shopConfig.shopGoods ~= nil then
            for _, goodInfo in pairs(shopConfig.shopGoods) do
                if goodInfo.goodId == Const.GOODS_ID.GOLD_BASE then
                    goodNum = goodNum + goodInfo.goodNum
                elseif goodInfo.goodId == Const.GOODS_ID.DIAMOND then
                    diamondNum = diamondNum + goodInfo.goodNum
                end

            end
        end
        if goodNum == 0 then
            goodNum = info.chips or 0
        end
        table.insert(datas,
        {
            createtime = chessutil.FormatDateGet(info.subTime),      --订单提交时间
            charid     = info.uid,          --玩家id
            charname   = userInfo.base.nickname, --玩家名称
            gameorder  = info._id,          --我的订单id
            platorder  = info.order_no,     --第三方订单id
            money      = info.backPrice,    --支付金额
            status     = info.status,       --订单状态
            chips      = goodNum,    --充值金额
            rechargetype = info.shopType,               --充值类型
            silver     = diamondNum,           --银币数量
            regflag    = userInfo.base.regFlag, --注册来源, 1.投放 2.非投放
            totalrechargechips  = userInfo.property.totalRechargeChips,--     //累计充值
            totalcovertchips       = userInfo.status.chipsWithdraw, --    //累计兑换金额
            promotionwithdrawchips = userInfo.status.promoteWithdaw, --     //累计推广兑换金额
            curChips               = info.curChips or 0,       --当前金币
            payType               = info.payType or "",       --当前渠道
        }
        )
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.allrecharge = allrecharge
    cmd.data.waitpay     = waitpay
    cmd.data.alreadypay = alreadypay
    return cmd
end

--gm查询对局日志
GmSvr.PmdStGameHundredRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filterStr = ""
    local filter    = nil
    -- if cmd.data.charid == 0 then
        -- cmd.data.retcode = 1
        -- cmd.data.retdesc =  "错误的玩家id"
        -- return cmd
    -- end
    if cmd.data.charid > 0 then
        if filter ~= nil then
            filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
        else
            filter = unilight.eq("uid", cmd.data.charid)
            filterStr = '"uid":{"$eq":' .. cmd.data.charid .. '}'
        end

    end
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        if filter ~= nil then
            filter = unilight.a(filter, unilight.ge("sTime", starttime), unilight.le("sTime", endtime))
            filterStr = filterStr .. ", " .. '"sTime":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
        else
            filter = unilight.a(unilight.ge("sTime", starttime), unilight.le("sTime", endtime))
            filterStr = '"sTime":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
        end
    end

    if cmd.data.subgameid > 0 then

        if filter ~= nil then
            filter = unilight.a(filter, unilight.eq("gameId", cmd.data.subgameid))
            filterStr = filterStr .. ", " .. '"gameId":{"$eq":' .. cmd.data.subgameid .. '}'
        else
            filter = unilight.a(unilight.eq("gameId", cmd.data.subgameid))
            filterStr = '"gameId":{"$eq":' .. cmd.data.subgameid .. '}'
        end
    end

    if cmd.data.subgametype > 0 then

        if filter ~= nil then
            filter = unilight.a(filter, unilight.eq("gameType", cmd.data.subgametype))
            filterStr = filterStr .. ", " .. '"gameType":{"$eq":' .. cmd.data.subgametype .. '}'
        else
            filter = unilight.a(unilight.eq("gameType", cmd.data.subgametype))
            filterStr = '"gameType":{"$eq":' .. cmd.data.subgametype .. '}'
        end

    end
    local totalwinlose = 0
    local beginInfo = unilight.chainResponseSequence(unilight.startChain().Table("gameMatchLog").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":1, "count":{"$sum":"$aChip"}}}'))
    local endInfo  = unilight.chainResponseSequence(unilight.startChain().Table("gameMatchLog").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":1, "count":{"$sum":"$bChip"}}}'))

    if table.len(beginInfo) > 0 and table.len(endInfo)  > 0 then
        totalwinlose = endInfo[1].count - beginInfo[1].count
    end
	local allNum 	= unilight.startChain().Table("gameMatchLog").Filter(filter).Count()
	local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("gameMatchLog").Filter(filter).OrderBy(unilight.desc("_id")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)

    for i, info in ipairs(infos) do

        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        local gameConfig = gamecommon.GetGameConfig(info.gameId, info.gameType)
        local poolchips = 0
        local poolId = 0
        if  info.jackpotinfo ~= nil and info.jackpotinfo.tWinScore ~= nil then
            poolchips = info.jackpotinfo.tWinScore
            poolId = info.jackpotinfo.poolId
        end
        table.insert(datas,
            {
                charid         = info.uid, -- //玩家id
                charname       = userInfo.base.nickname, -- //玩家名称
                subgamename    = gameConfig.subGameId,  --//进入游戏名称
                subgametype    = info.gameType, --//游戏场次
                begintime      = chessutil.FormatDateGet(info.sTime),    --//开始时间
                endtime        = chessutil.FormatDateGet(info.eTime),    --//结束时间
                bet            = info.betChip,  --    //下注
                carrychips     = info.bChip, -- //携带金币
                endchips       = info.aChip, --//结束后金币
                winlosechips   = info.aChip - info.bChip, -- //输赢金币
                lotteryicon    = json.encode(info.gamechessinfo), -- //开奖图标
                lotterymul     = info.winmul or 0,  --//开奖倍数
                handingfee     = info.tax, -- //手续费
                poolburstlevel = poolId, -- //爆池等级
                poolburstchips = poolchips,-- //爆池金币
                logid          = info._id, --日志id(暂时不用)
            }
            )
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.totalwinlose = totalwinlose
    return cmd
end


--救济金日志
GmSvr.PmdStBenefitRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil
    if cmd.data.charid > 0 then
        if filter ~= nil then
            filter = unilight.a(filter,unilight.eq("_id", cmd.data.charid))
        else
            filter = unilight.eq("_id", cmd.data.charid)
        end
    end
    if string.len(cmd.data.charname) > 0 then
        if filter ~= nil then
            filter = unilight.a(filter, unilight.eq("nickname", cmd.data.charname))
        else
            filter = unilight.eq("nickname", cmd.data.charname)
        end
    end
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        if filter ~= nil then
            filter = unilight.a(filter, unilight.ge("recvTime", starttime), unilight.le("recvTime", endtime))
        else
            filter = unilight.a(unilight.ge("recvTime", starttime), unilight.le("recvTime", endtime))
        end
    end


	local allNum 	= unilight.startChain().Table("benefitLog").Filter(filter).Count()
	local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("benefitLog").Filter(filter).OrderBy(unilight.desc("sTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)

    for i, info in ipairs(infos) do

        local userInfo = chessuserinfodb.RUserDataGet(info._id, true)
        table.insert(datas,
            {
                charid      = info._id, -- //玩家id
                charname    = userInfo.base.nickname,  --//玩家名称
                chips       = info.chip,--  //领取金额
                timestamp   = chessutil.FormatDateGet(info.recvTime), --; //领取时间
            }
            )
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end


--签到日志
GmSvr.PmdStSignInRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil
    local userInfo
    if cmd.data.charid > 0 then
        if filter ~= nil then
            filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
        else
            filter = unilight.eq("uid", cmd.data.charid)
        end
        userInfo = chessuserinfodb.RUserDataGet(cmd.data.charid, true)
    elseif string.len(cmd.data.charname) > 0 then
        if filter ~= nil then
            filter = unilight.a(filter, unilight.RegEx("nickname", cmd.data.charname))
        else
            filter = unilight.RegEx("base.nickname",cmd.data.charname)
        end
    else
        filter = unilight.gt("uid", 0)
    end


    local allNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
    maxpage = math.ceil(allNum/perpage)
    local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
    for i,userInfo in ipairs(userInfos) do
        local totalchips = 0
        if table.len(userInfo.daySign) > 0 then
            for datetime, chips in pairs(userInfo.daySign) do
                totalchips = totalchips + chips
            end

            for datetime,chips  in pairs(userInfo.daySign) do
                table.insert(datas,
                    {
                        charid         = userInfo.uid, --//玩家id
                        charname       = userInfo.base.nickname, --; //玩家名称
                        neweststage    = table.len(userInfo.daySign),--; //最新阶段
                        chips          = chips,-- //领取金额
                        timestamp      = datetime,-- //领取时间
                        allchips       = totalchips,-- //累计领取金额
                    }
                    )
            end

        end
    end







    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end

--存钱罐日志
GmSvr.PmdStPiggyBankRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil
    if cmd.data.charid > 0 then
        if filter ~= nil then
            filter = unilight.a(filter,unilight.eq("_id", cmd.data.charid))
        else
            filter = unilight.eq("_id", cmd.data.charid)
        end
    end
    if string.len(cmd.data.charname) > 0 then
        if filter ~= nil then
            filter = unilight.a(filter, unilight.eq("nickname", cmd.data.charname))
        else
            filter = unilight.eq("nickname", cmd.data.charname)
        end
    end
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)

        if filter ~= nil then
            filter = unilight.a(filter, unilight.ge("settleTime", starttime), unilight.le("settleTime", endtime))
        else
            filter = unilight.a(unilight.ge("settleTime", starttime), unilight.le("settleTime", endtime))
        end
    end
	local allNum 	= unilight.startChain().Table("cofrinho").Filter(filter).Count()
	local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("cofrinho").Filter(filter).OrderBy(unilight.desc("settleTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)

    for i, info in ipairs(infos) do

        local userInfo = chessuserinfodb.RUserDataGet(info._id, true)
        table.insert(datas,
            {
                charid         = info._id, --; //玩家id
                charname       = userInfo.base.nickname, --; //玩家名称
                yesterdaywinlose   = info.beforlost or 0, --; //前日输赢
                silverchips    = info.curSilver or 0,  --; //银色存钱罐存储金额
                silverstatus   = info.silverRecv, --; //银色存钱罐领取状态
                goldchips      = info.curGold or 0, --; //金色存钱罐存储金额
                goldstatus     = info.goldRecv, --; //金币存钱罐领取状态
                timestamp      = chessutil.FormatDateGet(info.settleTime), --; //日期
            }
            )
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end


--输赢统计
GmSvr.PmdStWinLoseRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("gameId", 0)
    if cmd.data.subgameid > 0 then
        filter = unilight.a(filter,unilight.eq("gameId", cmd.data.subgameid))
    end

    if cmd.data.subgametype > 0 then
        filter = unilight.a(filter,unilight.eq("gameType", cmd.data.subgametype))
    end


    --查询玩家类型
    if cmd.data.usertype > 0 then
        filter = unilight.a(filter,unilight.eq("type", cmd.data.usertype))
    end

    if cmd.data.subplatid >  0 then
        filter = unilight.a(filter, unilight.eq("subplatid", cmd.data.subplatid))
    end

    print("========================================")
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter, unilight.ge("daytimestamp", starttime), unilight.le("daytimestamp", endtime))
    end
    print("========================================")
	local allNum 	= unilight.startChain().Table("gameDayStatistics").Filter(filter).Count()
    local orderBy   ={unilight.desc("daytimestamp"), unilight.desc("gamecount")}
    print("========================================")
	local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Filter(filter).OrderBy(unpack(orderBy)).Skip((curpage-1)*perpage).Limit(perpage))
    print("========================================")
    
    maxpage = math.ceil(allNum/perpage)

    local allgamecount = 0
    local allbet       = 0 --; //总下注
    local allpayout    = 0 --; //总赔付
    local allprofit    = 0 --; //总盈利
    local allpump      = 0 --; //总抽水
    for i, info in ipairs(infos) do
        -- local gameConfig = gamecommon.GetGameConfig(info.gameId, info.gameType)
        allgamecount = allgamecount + info.gamecount
        allbet = allbet + info.tchip
        allpayout = allpayout + info.twin
        -- allpump = allpump + info.tax
        allprofit = allprofit + (info.tchip - info.twin)
        allpump = allpump + info.tax
        local bFind = false
        --数据合并
        for _, v in pairs(datas) do
            if v.timestamp == info.daytimestamp and v.subgamename == info.gameId and v.subgametype == info.gameType and v.usertype == info.type then
                v.allbet = v.allbet + info.tchip --; //总下注
                v.allpayout = v.allpayout + info.twin --; //总赔付
                v.allprofit = v.allprofit + (info.tchip - info.twin) --; //总盈利
                v.allpump   = v.allpump + info.tax --; //总抽水
                v.allgamecount = v.allgamecount + info.gamecount  --游戏次数
                bFind = true
                break
            end
        end



        if bFind == false then
            table.insert(datas,
            {
                subgamename  = info.gameId,--  //游戏名字
                subgametype  = info.gameType, --; //游戏场次
                maxonline    = info.online, --//游戏峰值人数
                allgamecount = info.gamecount, --; //游戏总次数
                rtp          = 0, --todo等待填充; //游戏rtp
                allbet       = info.tchip, --; //总下注
                allpayout    = info.twin, --; //总赔付
                allprofit    = info.tchip - info.twin, --; //总盈利
                allpump      = info.tax, --; //总抽水
                timestamp    = chessutil.FormatDateGet(info.daytimestamp), --;//时间
                usertype     = info.type or 0,       --玩家类型
            }
            )
        end
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    cmd.data.allgamecount = allgamecount --; //游戏总次数
    cmd.data.allbet       = allbet --; //总下注
    cmd.data.allpayout    = allpayout --; //总赔付
    cmd.data.allprofit    = allprofit --; //总盈利
    cmd.data.allpump      = allpump --; //总抽水
    return cmd
end

--充值渠道操作
GmSvr.PmdStReqRechargePlatInfoGmUserPmd_CS = function(cmd, laccount)
	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local optype = cmd.data.optype
    local reqtype = cmd.data.reqtype
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    --支付
    if reqtype == 1 then

        --查询列表
        if optype == 1 then
            for _, v in ipairs(table_recharge_plat) do
                table.insert(datas, {
                        id     = v.ID,      --编号
                        platid = v.platId, --//平台id
                        status = v.status, --//是否启用， 1启用，0禁用
                        platname = v.desc, --//渠道名称
                    })
            end
            --修改渠道状态
        elseif optype == 2 then
            for _, v in ipairs(table_recharge_plat) do
                if v.ID == cmd.data.id then
                    v.status = cmd.data.status
                end
            end
        end
    --提现
    elseif reqtype ==2 then

        --查询列表
        if optype == 1 then
            for _, v in ipairs(table_withdraw_plat) do
                table.insert(datas, {
                        id     = v.ID,      --编号
                        platid = v.platId, --//平台id
                        status1 = v.status1, --//金币提现是否启用， 1启用，0禁用
                        status2 = v.status2, --//推广是否启用， 1启用，0禁用
                        platname = v.desc, --//渠道名称
                    })
            end
            --修改金币渠道状态
        elseif optype == 2 then
            for _, v in ipairs(table_withdraw_plat) do
                if v.ID == cmd.data.id then
                    v.status1 = cmd.data.status
                end
            end
            --修改推广渠道状态
        elseif optype == 4 then
            for _, v in ipairs(table_withdraw_plat) do
                if v.ID == cmd.data.id then
                    v.status2 = cmd.data.status
                end
            end
            --修改提现直接通过的上限值
        elseif optype == 3 then
            -- 上限值
            WithdrawCash.parameterConfig[35].Parameter = cmd.data.cashoutauto
        end

    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
	cmd.data.cashoutauto        = WithdrawCash.parameterConfig[35].Parameter
    return cmd

end

--推广奖励日志
GmSvr.PmdStPromoteLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if cmd.data.charid == 0 then
        cmd.data.retcode = 0
        cmd.data.retdesc =  "请输入正确的玩家id"
        return cmd
    end
    local dateFormat = "%Y%m%d"
    local starttime = 0 
    local endtime = 0

    local filter = unilight.gt("uid", 0)
    if cmd.data.charid > 0 then
        filter = unilight.a(filter, unilight.eq("uid", cmd.data.charid))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        starttime = tonumber(os.date(dateFormat, starttime))
        endtime   = tonumber(os.date(dateFormat, endtime))
        -- filter = unilight.a(filter,unilight.ge('bindTime',starttime), unilight.le('bindTime',endtime))
    end

    local totalRechargeChips = 0
    local totalBetChips = 0
	local allNum = unilight.startChain().Table("rebateItem").Filter(filter).Count()
	local infos  = unilight.chainResponseSequence(unilight.startChain().Table("rebateItem").Filter(filter).OrderBy(unilight.desc("bindTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    --[[
    "_id": ObjectId("63eb25d5f9e0014014006383"),
    "uid": NumberInt("1004148"),
    "parentid": NumberInt("1004266"),
    "lev": NumberInt("1"),
    "price": NumberInt("1000"),
    "rebatechip": NumberInt("50"),
    "orderno": "123123123123",
    "addTime": NumberLong("1675763979")
    ]]
    for i, info in ipairs(infos) do
        local bSucess = true
        if starttime > 0 and endtime > 0  then
            if info.lastupdatetime ~= nil then
                if starttime <= tonumber(info.lastupdatetime) and tonumber(info.lastupdatetime) < endtime then
                    bSucess = true
                else
                    bSucess = false
                end
            else
                bSucess = false
            end
        end
        if bSucess then
            totalRechargeChips = totalRechargeChips + info.chip or 0
            totalBetChips = totalBetChips + info.tbetchip or 0
            table.insert(datas,
            {
                charid         = info.childId, --    //下线玩家id
                level          = info.lev, --    //下线级别
                rechargechips  = info.tchip or 0, --    //下线充值总金额
                rechargerebate = info.chip or 0,    --//下线充值返利
                betchips       = info.betchip or 0, --    //下线投注总额
                chipsrebate    = info.tbetchip or 0,--    //下线金币返利
                datetime       = info.lastupdatetime or "", --    //统计时间
            }
            )
        end
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    cmd.data.total_recharge_chips = totalRechargeChips -- //充值返利总额
    cmd.data.total_bet_chips      = totalBetChips -- //投注返利总额
    return cmd
end

--自动点控预警
GmSvr.PmdStAutoPunishControlWarnGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
    local data = cmd.data
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if data.optype == 0 then

        local filter = unilight.a(unilight.gt("gameInfo.gameId", 0), unilight.gt("property.totalRechargeChips", 0))

        if data.charid > 0 then
            filter = unilight.a(filter,unilight.eq("uid", data.charid))
        end

        --点控值查询
        if data.controlvalue > 0 then
            filter = unilight.a(filter,unilight.eq("point.controlvalue", data.controlvalue))
        else
        --默认有点控值的玩家
            filter = unilight.a(filter,unilight.gt("point.autocontroltype", 0))
        end

        --是否充值查询
        if data.rechargetype > 0 then
            --已充值
            if data.rechargetype == 1 then
                filter = unilight.a(filter,unilight.gt("property.totalRechargeChips", 0))
            else
            --未充值
                filter = unilight.a(filter,unilight.eq("property.totalRechargeChips", 0))
            end
        end

        --控制类型
        if data.controltype > 0 then
            filter = unilight.a(filter,unilight.eq("point.autocontroltype", data.controltype))
        end

        --渠道id
        if data.subplatid > 0 then
            filter = unilight.a(filter,unilight.eq("base.subplatid", data.subplatid))
        end

        local orderBy = unilight.asc("point.autocontrolvalue")

        local allNum 	= unilight.startChain().Table("userinfo").Filter(filter).Count()
        local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do
            local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
            local withdrawcashInfo = WithdrawCash.GetWithdrawcashInfo(info.uid)
            local controlvalue = info.point.controlvalue
            if info.point.autocontroltype == 1 then
                controlvalue = info.point.autocontrolvalue
            end
            table.insert(datas,
            {
                charid              = info.uid, --;   //玩家id
                charname            = info.base.nickname, --   //玩家名称
                totalrechargechips  = info.property.totalRechargeChips,--     //累计充值
                totalcovertchips       = userInfo.status.chipsWithdraw, --    //累计兑换金额
                promotionwithdrawchips = userInfo.status.promoteWithdaw, --     //累计推广兑换金额
                chips                  = info.property.chips, --     //当前金币
                controlvalue           = controlvalue, --     //点控值
                time                   = chessutil.FormatDateGet(info.point.autocontroltime), --     //点控生成时间
                controltype            = info.point.autocontroltype,        --控制类型
            }
            )
        end
        cmd.data.retcode = 0
        cmd.data.retdesc =  "操作成功"

        cmd.data.maxpage      = maxpage
        cmd.data.datas        = datas
        return cmd
    --修改
    elseif data.optype == 1 then
        for _, userdata in pairs(cmd.data.datas) do
            local userInfo = chessuserinfodb.RUserDataGet(userdata.charid, true)
            --恢复默认自动
            if userdata.controlvalue == 0 then
                userInfo.point.autocontroltype  = 0
                userInfo.point.controlvalue = 0
                UserInfo.SaveUserData(userInfo)
            else
                userInfo.point.controlvalue =  userdata.controlvalue
                userInfo.point.autocontroltime  = os.time()
                userInfo.point.autocontroltype  = 2
                UserInfo.SaveUserData(userInfo)
            end
        end

        cmd.data.retcode = 0
        cmd.data.retdesc =  "操作成功"
        return cmd
    end
end

--自动点控配置
GmSvr.PmdStAutoControlInfoGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
    local data = cmd.data
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    --非充值列表获取
    if data.optype == 1 then

        for i, info in pairs(table_autoControl_nc) do
            table.insert(datas,
            {
                id          = info.ID, --    //编号id
                rechargemin = info.conditionMin, --   金币下限
                rechargemax = info.conditionMax, --   金币上限
                autocontrolvalue = info.control, --  点控值
            }
            )
        end

    -- 非充值修改
    elseif data.optype == 2 then

        for i, info in pairs(table_autoControl_nc) do
            if info.ID == data.id then
                info.conditionMin = data.datas[1].rechargemin
                info.conditionMax = data.datas[1].rechargemax
                info.control      = data.datas[1].autocontrolvalue
            end
        end

    -- 非充值删除
    elseif data.optype == 3 then

        for i, info in pairs(table_autoControl_nc) do
            if info.ID == data.id then
                table_autoControl_nc[i] = nil
                break
            end
        end

    -- 非充值新值
    elseif data.optype == 4 then
        local maxN = 0
        for k, v in pairs(table_autoControl_nc) do
            if v.ID > maxN then
                maxN = v.ID
            end
        end
        maxN = maxN + 1

        local info = {
                ID        = maxN,  --    //编号id
                condition = data.datas[1].chips, --    //金币数量
                control   = data.datas[1].autocontrolvalue, --    //自动点控值
        }
        table_autoControl_nc[maxN] = info

    -- 充值查找
    elseif data.optype == 5 then
        --[[
        ID = 1,
        condition1 = 4.0,
        condition10 = 2.0,
        condition2 = 3.8,
        condition3 = 3.6,
        condition4 = 3.4,
        condition5 = 3.2,
        condition6 = 3.0,
        condition7 = 2.8,
        condition8 = 2.6,
        condition9 = 2.4,
        control = 9500,
        --]]
        for i, info in pairs(table_autoControl_cz) do
            local data = {

                id               = info.ID,--     //玩家id
                autocontrolvalue = info.control, --    //自动点控值
                regflag           = info.ID,
                rechargemuls = {},              --充值倍数
            }
            local index = 1
            while true do
                if info["condition"..index] == nil  then
                    break
                end
                table.insert(data.rechargemuls, info["condition"..index])
                index = index + 1

            end

            table.insert(datas, data)
        end

    -- 充值修改
    elseif data.optype == 6 then
        local newdata = data.datas[1]
        for i, info in pairs(table_autoControl_cz) do
            if info.ID == data.id then
                -- info.ID          = newdata.id,               --    //玩家id
                info.control     = newdata.autocontrolvalue --    //自动点控值
                for k, v in ipairs(newdata.rechargemuls)  do
                    if info["condition"..k] ~= nil then
                        info["condition"..k] = v
                    end
                end
            end
        end
    --充值删除
    elseif data.optype == 7 then
        local newdata = data.datas[1]
        for i, info in pairs(table_autoControl_cz) do
            if info.ID == data.id then
                table_autoControl_cz[i] = nil
            end
        end
    --充值新增
    elseif data.optype == 8 then

        local maxN = 0
        for k, v in pairs(table_autoControl_cz) do
            if v.ID > maxN then
                maxN = v.ID
            end
        end
        maxN = maxN + 1
        local newdata = data.datas[1]
        local info = {
                ID     = maxN,               --    //玩家id
                control     = newdata.autocontrolvalue, --    //自动点控值
                condition1  = newdata.rechargemul1,       --    //充值金币倍数1
                condition2  = newdata.rechargemul2,       --    //充值金币倍数2
                condition3  = newdata.rechargemul3,       --;    //充值金币倍数3
                condition4  = newdata.rechargemul4,       --;    //充值金币倍数4
                condition5  = newdata.rechargemul5,       --;    //充值金币倍数5
                condition6  = newdata.rechargemul6,       --;    //充值金币倍数6
                condition7  = newdata.rechargemul7,       --;    //充值金币倍数7
                condition8  = newdata.rechargemul8,       --;    //充值金币倍数8
                condition9  = newdata.rechargemul9,       --;    //充值金币倍数9
                condition10 = newdata.rechargemul10,      --;    //充值金币倍数10
        }
        table_autoControl_cz[maxN] = info

    --查看充值档次
    elseif data.optype == 9 then

        for i, info in pairs(table_autoControl_dc) do
            table.insert(datas,
            {
                id               = info.ID,--     //玩家id
                rechargemin      = info.chargeLimit,  --充值下线
                rechargemax      = info.chargeMax,      --充值上限
            }
            )
        end
    --修改充值档次
    elseif data.optype == 10 then
        local newdata = data.datas[1]
        for i, info in pairs(table_autoControl_dc) do
            if info.ID == data.id then
                -- info.ID          = newdata.id,               --    //玩家id
                info.chargeLimit     = newdata.rechargemin --    //充值下线
                info.chargeMax  = newdata.rechargemax       --    //充值上限
            end
        end
    end

	local sortFun = function(a, b)
		return a.id< b.id
	end
    table.sort(datas, sortFun)

    cmd.data.maxpage      = maxpage
    cmd.data.datas        = datas
    return cmd
end


--足球抽奖券日志
GmSvr.PmdStFootbalCouponLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil

    local data = cmd.data

    filter = unilight.ge('uid',0)

    if data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", data.charid))
    end

    --抽奖档次
    if data.lotteryid > 0 then
        filter = unilight.a(filter,unilight.eq("spinIndex", data.lotteryid))
    end

    --转盘类型
    if data.optype > 0 then
        filter = unilight.a(filter,unilight.eq("rouletteType", data.optype))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('time',starttime), unilight.le('time',endtime))
    end

    local allNum = unilight.startChain().Table("roulette_history").Filter(filter).Count()
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("roulette_history").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))

	-- local allNum 	= unilight.startChain().Table("rebatelog").Filter(filter).Count()
	-- local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("rebatelog").Filter(filter).OrderBy(unilight.desc("addTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    --[[
    ]]
    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        table.insert(datas,
        {
            charid    = info.uid,
            charname  = userInfo.base.nickname, --    //玩家名字
            lotteryid = info.spinIndex, --;    //抽奖id1~5
            optype    = info.rouletteType, --;    //变动类型(消耗/获得) 1消耗, 2获得
            winsilver = info.score, --    //中奖金额(银币)
            optime    = chessutil.FormatDateGet(info.time), --;    //变动时间
        }
        )
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.datas        = datas
    return cmd
end


--老虎机抽奖日志
GmSvr.PmdStSlotsLotterylogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil

    local data = cmd.data

    filter = unilight.ge('uid',0)

    --[[
    if data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", data.charid))
    end

    --抽奖档次
    if data.lotteryid > 0 then
        filter = unilight.a(filter,unilight.eq("spinIndex", data.lotteryid))
    end

    --转盘类型
    if data.optype > 0 then
        filter = unilight.a(filter,unilight.eq("rouletteType", data.optype))
    end

    --时间
    if data.begintime > 0 and data.endtime > 0 then
        filter = unilight.a(filter,unilight.ge('time',begintime), unilight.le('time',endtime))
    end

    local allNum = unilight.startChain().Table("roulette_history").Filter(filter).Count()
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("roulette_history").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
    ]]

	-- local allNum 	= unilight.startChain().Table("rebatelog").Filter(filter).Count()
	-- local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("rebatelog").Filter(filter).OrderBy(unilight.desc("addTime")).Skip((curpage-1)*perpage).Limit(perpage))
    local allNum, infos = DaySign.GetDaySignHistory(data.charid, data.cointype, data.begintime, data.endtime, curpage, perpage)

    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        table.insert(datas,
        {
            charid   = info.uid,
            charname = userInfo.base.nickname, --    //玩家名字
            cointype = info.daysignType, --    //货币类型(1,金币, 2银币)
            coinnum  = info.score, --    //奖励数量
            wintime  = info.time, --    //中奖时间
        }
        )
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.datas        = datas
    return cmd
end



--vip奖励领取日志
GmSvr.PmdStVipRewardlogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil

    local data = cmd.data

    filter = unilight.ge('uid',0)

    --角色id
    if data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", data.charid))
    end

    --奖励类型
    if data.gettype > 0 then
        filter = unilight.a(filter,unilight.eq("type", data.gettype))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('time',starttime), unilight.le('time',endtime))
    end

    local allNum = unilight.startChain().Table("watervipLog").Filter(filter).Count()
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("watervipLog").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))

	-- local allNum 	= unilight.startChain().Table("rebatelog").Filter(filter).Count()
	-- local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("rebatelog").Filter(filter).OrderBy(unilight.desc("addTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    --[[
    ]]
    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        table.insert(datas,
        {
            charid    = info.uid,
            charname  = userInfo.base.nickname, --    //玩家名字
            rewardviplevel  = info.level, --    //领取时vip级别
            gettype   = info.type, --    //奖励来源(1.每日, 2.每周, 3.每月, 4.特殊)
            getchips   = info.chip, --    //领取金币
            gettime    = chessutil.FormatDateGet(info.time), --    //领取时间
        }
        )
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.datas        = datas
    return cmd
end


--周卡奖励领取日志
GmSvr.PmdStWeekCardlogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = nil

    local data = cmd.data

    filter = unilight.ge('uid',0)

    -- local allNum, infos = WeeklyCard.GetWeeklyCardHistory(data.charid, data.gettype, data.begintime, data.endtime, curpage, perpage)
        -- local logvipweek = {
            -- uid = uid,                          --用户ID
            -- recvStage = 7-(endDays-nowDays),    --领取阶段
            -- recvMoney = daymoney,               --领取金额
            -- recvTime = timenow,                 --领取时间
            -- weekLevel = datainfo.weekLevel,     --周卡级别
        -- }


	local allNum 	= unilight.startChain().Table("weekCardLog").Filter(filter).Count()
	local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("weekCardLog").Filter(filter).OrderBy(unilight.desc("recvTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    --[[
    ]]
    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)
        local totalChips = 0

        local filterStr = '"uid":{"$eq":' .. info.uid .. '}'
        local taotalInfo = unilight.chainResponseSequence(unilight.startChain().Table("weekCardLog").Aggregate('{"$match":{'..filterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$recvMoney"}}}'))
        if table.len(taotalInfo) > 0 then
            totalChips = taotalInfo[1].sum
        end
        table.insert(datas,
        {
            charid    = info.uid,
            charname  = userInfo.base.nickname, --    //玩家名字
            level      = info.weekLevel, --;   //周卡级别(v1-v5)
            stage      = info.recvStage, --;   //领取阶段(1-7)
            chips      = info.recvMoney, --   //领取金额
            totalchips = totalChips, --   //累计累取金额
            gettime    = info.recvTime,   --领取时间
        }
        )
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.datas        = datas
    return cmd
end

--充值提现排行
GmSvr.PmdStRechargeWithdrawRankGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end
    local filterStr = nil

    -- if cmd.data.charid > 0 then
        -- filterStr = filterStr or ""
        -- filterStr = '"status.registertimestamp":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
    -- end

    local filterStr2 = '"userinfo.base.regFlag":{"$gt":' .. 0 .. '}'
    if cmd.data.regflag > 0 then
        filterStr2 = '"userinfo.base.regFlag":{"$eq":' .. cmd.data.regflag .. '}'
    end

    if cmd.data.subplatid  > 0 then
        filterStr2 = filterStr2 .. ', "userinfo.base.subplatid":{"$eq":' .. cmd.data.subplatid .. '}'
    end


    local starttime = 0
    local endtime = 0

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
    end

    --充值排名
    if cmd.data.optype == 1 then
        filterStr = '"status":{"$eq":' .. 2 .. '}'
        local filter =  unilight.eq("status", 2)
        if cmd.data.regflag > 0 then
            filter = unilight.a(filter,unilight.eq("regFlag", cmd.data.regflag))
        end

        if starttime > 0 and endtime > 0 then
            filterStr = filterStr .. ", ".. '"backTime":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
            filter = unilight.a(filter,unilight.gt("backTime", starttime), unilight.lt("backTime", endtime))
        end

        local result = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{' .. filterStr .. '}}',
        '{"$group":{"_id":"$uid"}}',
        '{"$group":{"_id":null,"count":{"$sum":1}}}'
        ))
        local allNum = result[1].count
        -- local allNum = 0
        -- local infos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":"$uid", "sum":{"$sum":1}}}', '{"$group":{"_id":1, "sum":{"$sum":1}}}'))
        -- local infos = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{' .. filterStr .. '}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}'
        -- ,'{"$match":{'..filterStr2..'}}', '{"$group":{"_id":1, "sum":{"$sum":1}}}'))
        -- if table.len(infos) > 0 then
            -- allNum = infos[1].sum
        -- end

        -- local infos = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{' .. filterStr .. '}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}'
        -- ,'{"$match":{'..filterStr2..'}}','{"$group":{"_id":"$uid", "total":{"$sum":"$backPrice"}, "count":{"$sum":1}}}',
        -- '{"$sort": {"total":-1}}','{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}' ))

        local infos = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{' .. filterStr .. '}}',
        '{"$group":{"_id":"$uid", "total":{"$sum":"$backPrice"}, "count":{"$sum":1}}}',
        '{"$sort": {"total":-1}}','{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}' ))

        maxpage = math.ceil(allNum/perpage)


        for i, info in ipairs(infos)  do
            local userInfo = chessuserinfodb.RUserDataGet(info._id, true)

            filterStr = '"state":{"$eq":' .. 6 .. '}'..", " .. '"uid":{"$eq":' .. info._id .. '}'
            if starttime > 0 and endtime > 0 then
                filterStr = filterStr .. ", ".. '"timestamp":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
            end
            local counInfo = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":"$uid", "total":{"$sum":"$dinheiro"}, "count":{"$sum":1}}}'))
            local withdrawmoney = 0
            local withdrawnum = 0
            if table.len(counInfo) > 0 then
                withdrawmoney = counInfo[1].total
                withdrawnum   = counInfo[1].count
            end


            table.insert(datas,
            {
                charid         = info._id, --; //玩家id
                charname       = userInfo.base.nickname, --; //玩家名称
                loginip          = userInfo.status.lastLoginIp, --    //登陆ip
                rechargemoney    = info.total, --    //充值金额
                rechargenum      = info.count, --    //充值次数
                withdrawmoney    = withdrawmoney, --    //提现金额
                withdrawnum      = withdrawnum, --;    //抽现次数
                lastlogintime    = userInfo.status.lastlogintime,   --最后登陆时间
                regtime          = userInfo.status.registertime ,  --注册时间
                regflag          = userInfo.base.regFlag,           --注册来源
                logintimestamp        = userInfo.status.logintimestamp ,  --登陆时间(排序用)
                regtimestamp          = userInfo.status.registertimestamp ,  --注册时间(排序用)
                chips            = userInfo.property.chips,--身上携带金币
                totalrecharge    = userInfo.property.totalRechargeChips,   --//总充值金额
                totalwithdraw    = userInfo.status.chipsWithdraw,   --//总提现金额
            }
            )
        end
    --提现排名
    elseif cmd.data.optype == 2 then

        local filter =  unilight.eq("state", 6)
        filterStr = '"state":{"$eq":' .. 6 .. '}'
        if starttime > 0 and endtime > 0 then
            filterStr = filterStr .. ", ".. '"timestamp":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
            filter = unilight.a(filter,unilight.gt("timestamp", starttime), unilight.lt("timestamp", endtime))
        end

        --platid 正式包 1 分享包101
        if cmd.data.regflag > 0 then
            filter = unilight.a(filter,unilight.eq("regFlag", cmd.data.regflag))
        end
        
        if starttime > 0 and endtime > 0 then
        end
        local result = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{' .. filterStr .. '}}',
        '{"$group":{"_id":"$uid"}}',
        '{"$group":{"_id":null,"count":{"$sum":1}}}'
        ))
        local allNum = result[1].count
        -- local allNum = unilight.startChain().Table("withdrawcash_order").Filter(filter).Count()
        -- local allNum = 0
        -- local infos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{' .. filterStr .. '}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}'
        -- ,'{"$match":{'..filterStr2..'}}','{"$group":{"_id":1, "sum":{"$sum":1}}}'))
        -- if table.len(infos) > 0 then
            -- allNum = infos[1].sum
        -- end
        maxpage = math.ceil(allNum/perpage)

        local infos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{' .. filterStr .. '}}',
        '{"$group":{"_id":"$uid", "total":{"$sum":"$dinheiro"}, "count":{"$sum":1}}}',
        '{"$sort": {"total":-1}}','{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}' ))


        for i, info in ipairs(infos)  do
            local userInfo = chessuserinfodb.RUserDataGet(info._id, true)
            filterStr = '"status":{"$eq":' .. 2 .. '}' ..", "..'"uid":{"$eq":' .. info._id .. '}'
            if starttime > 0 and endtime > 0 then
                filterStr = filterStr .. ", ".. '"backTime":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
            end
            local counInfo = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":null, "total":{"$sum":"$backPrice"}, "count":{"$sum":1}}}'))
            local rechargemoney = 0
            local rechargenum = 0
            if table.len(counInfo) > 0 then
                rechargemoney = counInfo[1].total
                rechargenum   = counInfo[1].count
            end

            local userInfo = chessuserinfodb.RUserDataGet(info._id, true)
            table.insert(datas,
            {
                charid         = info._id, --; //玩家id
                charname       = userInfo.base.nickname, --; //玩家名称
                loginip          = userInfo.status.lastLoginIp, --    //登陆ip
                rechargemoney    = rechargemoney, --    //充值金额
                rechargenum      = rechargenum, --    //充值次数
                withdrawmoney    = info.total, --    //提现金额
                withdrawnum      = info.count, --;    //抽现次数
                lastlogintime    = userInfo.status.lastlogintime,   --最后登陆时间
                regtime          = userInfo.status.registertime ,  --注册时间
                regflag          = userInfo.base.regFlag,           --注册来源
                logintimestamp        = userInfo.status.logintimestamp ,  --登陆时间(排序用)
                regtimestamp          = userInfo.status.registertimestamp ,  --注册时间(排序用)
                chips            = userInfo.property.chips,--身上携带金币
                totalrecharge    = userInfo.property.totalRechargeChips,   --//总充值金额
                totalwithdraw    = userInfo.status.chipsWithdraw,   --//总提现金额
            }
            )
        end
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

    --找不到其它排序方式
    if cmd.data.ordertype == 1 then
        -- orderBy = '"userinfo[1].status.registertimestamp":-1'
        table.sort(datas, function(a,b) return a.regtimestamp > b.regtimestamp end)
    elseif cmd.data.ordertype == 2 then
        table.sort(datas, function(a,b) return a.logintimestamp > b.logintimestamp end)
        -- orderBy = '"userinfo[1].status.logintimestamp":-1'
    end

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end


--邮件日志
GmSvr.PmdRequestMailRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if cmd.data.optype == 1 then
        for _, mail in pairs(cmd.data.data) do
            local uid = mail.recvid
            local mailId = mail.id

            local filter = unilight.eq("_id", uid)
            local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("usermailinfo").Filter(filter))

            local mailInfo = unilight.getdata("usermailinfo", uid)

            for i, maildata in ipairs(mailInfo.maildata) do
                if maildata.id == mailId then
                    table.remove(mailInfo.maildata, i)
                    break
                end
            end
            unilight.savedata("usermailinfo", mailInfo)

        end

    else

        local filter = unilight.gt("_id", 0)

        if cmd.data.recvid > 0 then
            filter = unilight.a(filter,unilight.eq("_id", cmd.data.recvid))
        end

        local allNum 	= unilight.startChain().Table("usermailinfo").Filter(filter).Count()
        local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("usermailinfo").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do
            local userInfo = chessuserinfodb.RUserDataGet(info._id, true)
            -- local maildata = {
            -- }
            --[[
            "isRead": false,
            "subject": "Recarregar com sucesso",
            "charid": 1005819,
            "content": "Parabéns!Seus R$100 recarregados foram creditados com sucesso em 13/03/2023 14:14:42,aproveite seus jogos.",
            "id": 100402,
            "type": 0,
            "overTime": 1679292882,
            "extData": {
                "configId": 19
            },
            "mailType": 1,
            "recordtime": 1678688082,
            ]]
            for _, mailInfo in ipairs(info.maildata) do
                local attachment = {}
                local attachments = mailInfo.attachment or {}
                for _, attachmentInfo in ipairs(attachments) do
                    table.insert(attachment, {itemid=attachmentInfo.itemId, itemnum=attachmentInfo.itemNum})
                end
                local state = 0
                if mailInfo.isRead  == false then
                    state = 1
                end
                table.insert(datas, {
                    id       = mailInfo.id, --
                    subject	 = mailInfo.subject, -- // 邮件标题
                    content	 = mailInfo.content, -- // 邮件内容
                    attachment	= attachment, -- // 邮件附件，道具构成的字符串，由逗号分隔,"type*id*num,type*id*num"
                    state		= state, -- // 附件状态，0没有附件，1附件已领取，2附件未领取
                    ts			= mailInfo.recordtime, -- // 时间戳
                    optype		= mailInfo.mailType, -- // 邮件类型，1系统邮件，2个人邮件
                    recvid		= info._id, -- // 收件人ID
                    recvname	= userInfo.base.nickname,--  // 收件人昵称
                })

            end
            -- table.insert(datas,
            -- {
            -- charid   = info.uid, --;   //玩家id
            -- charname = userInfo.base.nickname, --   //玩家名称
            -- maildata = maildata,
            -- }
            -- )
        end

        local sortFun = function(a, b)
            return a.ts > b.ts
        end

        table.sort(datas, sortFun)

    end


    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end

--提现率
GmSvr.PmdStWithdrawPercentGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local reqType       = cmd.data.reqtype
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if string.len(cmd.data.begintime) == 0 or string.len(cmd.data.endtime) == 0 then
        unilight.info("PmdStWithdrawPercentGmUserPmd_CS 参数错误")
        return cmd
    end

    --如果只查一天需要查这些档次
    local query_data = {
        {0,     1000},
        {1001,  2000},
        {2001,  3000},
        {3001,  4000},
        {4001,  5000},
        {5001,  6000},
        {6001,  7000},
        {7001,  8000},
        {8001,  9000},
        {9001,  10000},
        {10001, 20000},
        {20001, 50000},
        {50001, 100000},
        {100001,500000},
        {500001,1000000},
        {1000001,9999999999},
    }

    local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
    local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)

    local daySeconds = 24 * 60 * 60         --一天的秒数
    local diffDay = math.floor((endtime - starttime) / daySeconds)
    local dayList = {}
    table.insert(dayList, chessutil.ZeroTodayTimestampGetByTime(starttime)) --当前天
    for i=1,  diffDay do
        local curDayTime = starttime  + (i * daySeconds)
        table.insert(dayList, chessutil.ZeroTodayTimestampGetByTime(curDayTime))
    end

    local totalwithdrawmoney = 0        --总提现金额
    local totalrechargemoney = 0        --总充值金额
    local totalrechargenum   = 0        --总充值人数
    local totalwithdrawnum   = 0        --总提现人数

    local totalRecharge = cmd.data.ignorerechargechips
    local rechargeMin = cmd.data.rechargemin
    local rechargeMax= cmd.data.rechargemax
    if rechargeMax == 0 then
        rechargeMax = 9999999999
    end
    --只查一天要特殊处理,查询所有档次
    if table.len(dayList) == 1 then
        local dayTime = dayList[1]
        unilight.info("查询时间1:"..chessutil.FormatDateGet(dayTime))
        local dayStartTime = dayTime
        local dayEndTime = dayTime  + daySeconds
        for _, rechargeInfo in ipairs(query_data) do
            rechargeMin = rechargeInfo[1]
            rechargeMax = rechargeInfo[2]

            local filterStr ='"totalRechargeChips":{"$gte":'..rechargeMin..',"$lte":'..rechargeMax..'}'

            if cmd.data.regflag > 0  then
                local regFlag = cmd.data.regflag
                local dayDinheiro = 0
                local dayRecharge = 0
                local withdrawNum = 0       --提现人数
                local rechargeNum = 0       --充值人数

                dayDinheiro, dayRecharge, withdrawNum, rechargeNum = ChessGmUserInfoMgr.GetPlayerWithdrawData(reqType, rechargeMin, rechargeMax, regFlag, dayStartTime, dayEndTime)

                totalwithdrawmoney = totalwithdrawmoney + dayDinheiro
                totalrechargemoney = totalrechargemoney + dayRecharge
                totalrechargenum   = totalrechargenum + rechargeNum
                totalwithdrawnum   = totalwithdrawnum + withdrawNum

                -- if dayDinheiro > 0 or dayRecharge > 0 then
                table.insert(datas, {
                    date                = chessutil.FormatDateGet(dayTime, "%Y-%m-%d"), --    //日期
                    withdrawmoney       = dayDinheiro, --    //当日提现金额
                    rechargemoney       = dayRecharge, --    //当日充值总额
                    -- withdrawpercent     = math.floor((dayDinheiro / dayRecharge) * 100) , --    //当日提现率
                    withdrawpercent     = 0 , --    //当日提现率
                    regflag             = regFlag,
                    rechargemin         = rechargeMin,  --最小充值
                    rechargemax         = rechargeMax,  --最大充值
                    rechargenum         = rechargeNum,  --充值人数
                    withdrawnum         = withdrawNum,  --提现人数

                })
            else
                --查询投放和非投放
                for regFlag = 1, 2 do
                    local dayDinheiro = 0
                    local dayRecharge = 0
                    local withdrawNum = 0       --提现人数
                    local rechargeNum = 0       --充值人数

                    dayDinheiro, dayRecharge, withdrawNum, rechargeNum = ChessGmUserInfoMgr.GetPlayerWithdrawData(reqType, rechargeMin, rechargeMax, regFlag, dayStartTime, dayEndTime)

                    totalwithdrawmoney = totalwithdrawmoney + dayDinheiro
                    totalrechargemoney = totalrechargemoney + dayRecharge
                    totalrechargenum   = totalrechargenum + rechargeNum
                    totalwithdrawnum   = totalwithdrawnum + withdrawNum

                    -- if dayDinheiro > 0 or dayRecharge > 0 then
                    table.insert(datas, {
                        date                = chessutil.FormatDateGet(dayTime, "%Y-%m-%d"), --    //日期
                        withdrawmoney       = dayDinheiro, --    //当日提现金额
                        rechargemoney       = dayRecharge, --    //当日充值总额
                        -- withdrawpercent     = math.floor((dayDinheiro / dayRecharge) * 100) , --    //当日提现率
                        withdrawpercent     = 0 , --    //当日提现率
                        regflag             = regFlag,
                        rechargemin         = rechargeMin,  --最小充值
                        rechargemax         = rechargeMax,  --最大充值
                        rechargenum         = rechargeNum,  --充值人数
                        withdrawnum         = withdrawNum,  --提现人数

                    })
                    -- end

                end
            end
        end
    else

        for i=#dayList, 1, -1 do
            local dayTime = dayList[i]
            unilight.info("查询时间2:"..chessutil.FormatDateGet(dayTime))
            local dayStartTime = dayTime
            local dayEndTime = dayTime  + daySeconds

            local regFlag = 0
            local info = nil

            local dayDinheiro = 0       --当日提现
            local dayRecharge = 0       --当日充值
            local withdrawNum = 0       --提现人数
            local rechargeNum = 0       --充值人数

            local filterStr ='"totalRechargeChips":{"$gte":'..rechargeMin..',"$lte":'..rechargeMax..'}'

            if cmd.data.subplatid > 0 then
                filterStr = filterStr .. ', "subplatid":{"$eq":' .. cmd.data.subplatid .. '}'
            end

            if cmd.data.regflag > 0  then
                local regFlag = cmd.data.regflag
                dayDinheiro, dayRecharge, withdrawNum, rechargeNum = ChessGmUserInfoMgr.GetPlayerWithdrawData(reqType, rechargeMin, rechargeMax, regFlag, dayStartTime, dayEndTime)

                totalwithdrawmoney = totalwithdrawmoney + dayDinheiro
                totalrechargemoney = totalrechargemoney + dayRecharge
                totalrechargenum   = totalrechargenum + rechargeNum
                totalwithdrawnum   = totalwithdrawnum + withdrawNum

                -- if dayRecharge > 0 or  dayDinheiro > 0 then
                table.insert(datas, {
                    date                = chessutil.FormatDateGet(dayTime, "%Y-%m-%d"), --    //日期
                    withdrawmoney       = dayDinheiro, --    //当日提现金额
                    rechargemoney       = dayRecharge, --    //当日充值总额
                    -- withdrawpercent     = math.floor((dayDinheiro / dayRecharge) * 100) , --    //当日提现率
                    withdrawpercent     = 0 , --    //当日提现率
                    regflag             = regFlag,
                    rechargemin         = rechargeMin,  --最小充值
                    rechargemax         = rechargeMax,  --最大充值
                    rechargenum         = rechargeNum,  --充值人数
                    withdrawnum         = withdrawNum,  --提现人数
                })
                -- end

            else
                --查询投放和非投放
                for regFlag = 1, 2 do
                    local dayDinheiro = 0       --当日提现
                    local dayRecharge = 0       --当日充值
                    local withdrawNum = 0       --提现人数
                    local rechargeNum = 0       --充值人数
                    dayDinheiro, dayRecharge, withdrawNum, rechargeNum = ChessGmUserInfoMgr.GetPlayerWithdrawData(reqType, rechargeMin, rechargeMax, regFlag, dayStartTime, dayEndTime)

                    totalwithdrawmoney = totalwithdrawmoney + dayDinheiro
                    totalrechargemoney = totalrechargemoney + dayRecharge
                    totalrechargenum   = totalrechargenum + rechargeNum
                    totalwithdrawnum   = totalwithdrawnum + withdrawNum

                    -- if dayDinheiro > 0 or dayRecharge > 0 then
                    table.insert(datas, {
                        date                = chessutil.FormatDateGet(dayTime, "%Y-%m-%d"), --    //日期
                        withdrawmoney       = dayDinheiro, --    //当日提现金额
                        rechargemoney       = dayRecharge, --    //当日充值总额
                        -- withdrawpercent     = math.floor((dayDinheiro / dayRecharge) * 100) , --    //当日提现率
                        withdrawpercent     = 0 , --    //当日提现率
                        regflag             = regFlag,
                        rechargemin         = rechargeMin,  --最小充值
                        rechargemax         = rechargeMax,  --最大充值
                        rechargenum         = rechargeNum,  --充值人数
                        withdrawnum         = withdrawNum,  --提现人数
                    })
                    -- end

                end
            end

            -- info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{"state":6, "timestamp":{"$gte":' .. dayStartTime ..' , "$lte":' .. dayEndTime .. '}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
            -- maxpage = math.ceil(allNum/perpage)

            -- local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{"status":2, "subTime":{"$gte":' .. dayStartTime ..' , "$lte":' .. dayEndTime .. '}}','{"$group":{"_id":null, "sum":{"$sum":"$backPrice"}}}'))
            -- maxpage = math.ceil(allNum/perpage)
            -- if table.len(info)  > 0  then
            -- dayRecharge = info[1].sum
            -- end


            maxpage = 1
        end
    end

    --查询推广提现忽略投放标志
    -- unilight.info('starttime endtime',starttime,endtime)
    local tmpFilterStr = '"orderType":2,"state":{"$in":[6, 3]}'
    tmpFilterStr = tmpFilterStr .. ', "timestamp":{"$gte":' .. starttime ..' , "$lt":' .. endtime .. '}'
    local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
    '{"$match":{'..tmpFilterStr..'}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
    local dayDinheiro ,withdrawNum =0,0
    if table.len(info) > 0 then
        dayDinheiro = info[1].sum
    end
    info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{'..tmpFilterStr..'}}', '{"$group":{"_id":"$uid"}}', '{"$group":{"_id":null, "sum":{"$sum":1}}}'  ))
    if table.len(info) > 0 then
        withdrawNum = info[1].sum
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.datas        = datas
    cmd.data.totalwithdrawmoney = totalwithdrawmoney+dayDinheiro
    cmd.data.totalrechargemoney = totalrechargemoney
    cmd.data.totalrechargenum  = totalrechargenum
    cmd.data.totalwithdrawnum  = totalwithdrawnum+withdrawNum
    cmd.data.totaladwwithrawmoney = dayDinheiro  --推广总提现
    cmd.data.totaladwithdrawnum = withdrawNum   --推广提现人数
    return cmd
end


--游戏进出日志
GmSvr.PmdStGameEnterOutRecordGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("uid", 0)

    if cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
    end

    if cmd.data.subgameid > 0 then
        filter = unilight.a(filter,unilight.eq("subGameId", cmd.data.subgameid))
    end

    if cmd.data.subgametype > 0 then
        filter = unilight.a(filter,unilight.eq("subGameType", cmd.data.subgametype))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('beginTime',starttime), unilight.le('beginTime',endtime))
    end

	local allNum 	= unilight.startChain().Table("gameInOutLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("gameInOutLog").Filter(filter).OrderBy(unilight.desc("beginTime")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)

        -- _id = go.newObjectId(),
        -- uid = uid,
        -- beginTime = gameInfo.intoTime,              -- 进入时间
        -- endTime = os.time(),                        -- 退出时间
        -- subGameId = gameInfo.subGameId,             --子游戏id
        -- subGameType = gameInfo.subGameType,         --子游戏场次
        -- loginChips = gameInfo.loginChips,           --进入时金币
        -- logoutChips = gameInfo.logoutChips,         --退出时金币

        table.insert(datas, {
            charid     = info.uid, -- //玩家id
            charname   = userInfo.base.nickname, -- //玩家名称
            entertime  = chessutil.FormatDateGet(info.beginTime), -- //进入时间
            enterchips  = info.loginChips, -- //进入金币
            outchips    = info.logoutChips, -- //退出金币
            changechips = info.logoutChips - info.loginChips, -- //金币变化
            subgameid   = info.subGameId, -- //进入游戏名称
            subgametype = info.subGameType, -- //游戏场次
            leveltime  = chessutil.FormatDateGet(info.endTime), -- //退出 时间
        })

    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end




--库存信息每个游戏一个库存模式
--[[
GmSvr.PmdStSlotsStockTaxGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
    local data = cmd.data
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    --获得库存
    if data.optype == 1 then
        -- local slotsStockList = unilight.getAll("slotsStock")

        -- _id = gameKey,                        --唯一key
        -- gameId   = gameId,                    --游戏id
        -- gameType = gameType,                         --场次id
        -- ZoneId = unilight.getzoneid(),        --zoneId
        -- stockNum = stockConfig.initStock,             --初始库存
        for k, v in pairs(table_stock_tax) do
            local gameKey = v.gameId * 10000 + v.gameType
            curStockNum = unilight.redis_gethashdata_Str(Const.REDIS_HASH_NAME.STOCKNUM, tostring(gameKey))
            if curStockNum == "" then
                curStockNum = 0
            else
                curStockNum = tonumber(curStockNum)
            end

            local tmpdata =
            {
                id                  = v.ID,               --//库存唯一id
                taxpercent          = v.taxPercent,    --抽水比例
                curstocknum         = curStockNum,          --当前库存
                initstocknum        = v.initStock,     --初始库存
                subgametype         = v.gameType,          --游戏类型
                subgameid           = v.gameId,            --游戏id
            }
            if data.subgameid ~= 0 and data.subgametype ~= 0 then
                if v.gameId == data.subgameid and v.gameType == data.subgametype  then
                    table.insert(datas, tmpdata)
                end
            elseif data.subgameid ~= 0 then
                if data.subgameid == v.gameId then
                    table.insert(datas, tmpdata)
                end
            elseif data.subgametype ~= 0  then
                if data.subgametype == v.gameType then
                    table.insert(datas, tmpdata)
                end
            else
                table.insert(datas, tmpdata)
            end

        end
        -- for _, gameConfig in pairs(table_game_list) do
            -- local curStocknum = gamestock.BackGetStock(gameConfig.subGameId,gameConfig.roomType)
            -- if  curStocknum ~= nil and table_stock_tax[gameConfig.ID] then
                -- local tmpdata =
                -- {
                    -- id                  = gameConfig.ID,               --//库存唯一id
                    -- taxpercent          = table_stock_tax[gameConfig.ID].taxPercent,    --抽水比例
                    -- curstocknum         = curStocknum,          --当前库存
                    -- initstocknum        = 0,     --初始库存
                    -- subgametype         = gameConfig.roomType,          --游戏类型
                    -- subgameid           = gameConfig.subGameId,            --游戏id
                -- }
                -- table.insert(datas, tmpdata)
            -- end
        -- end


    -- 修改库存
    elseif data.optype == 2 then
        local data = data.datas[1]
        -- info.taxPercent = data.datas[1].taxpercent
        local stockTaxConfig = table_stock_tax[data.id]
        if stockTaxConfig ~= nil then
            stockTaxConfig.taxPercent = data.taxpercent
        end
        -- gamecommon.SetStockNumByType(data.id, data.curstocknum)

        local res = {}
        res["do"] = "Cmd.EditStockNumCmd_S"
        res["data"] = {
            id       = data.id,
            gameId   = stockTaxConfig.gameId,
            gameType = stockTaxConfig.gameType,
            stockNum = data.curstocknum,
            taxPercent = data.taxpercent,
        }

        if unilight.getdebuglevel() > 0 then
            RoomInfo.BroadcastToAllZone("Cmd.EditStockNumCmd_S", res["data"])
        else
            local gameKey = stockTaxConfig.gameId * 10000 + stockTaxConfig.gameType
            local gameConfig = table_game_list[gameKey] 
            if gameConfig ~= nil then
                for _, zoneId in pairs(gameConfig.rechargeZone) do
                    local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(gameConfig.gameId, zoneId)
                    if zoneInfo ~= nil then
                        zoneInfo:SendCmdToMe("Cmd.EditStockNumCmd_S", res["data"])
                    end
                end
            end
        end

    end

	local sortFun = function(a, b)
		return a.id< b.id
	end
    table.sort(datas, sortFun)

    cmd.data.maxpage      = maxpage
    cmd.data.datas        = datas
    return cmd
end
]]

--库存按场次区分
GmSvr.PmdStSlotsStockTaxGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
    local data = cmd.data
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    --获得库存
    if data.optype == 1 then
        -- local slotsStockList = unilight.getAll("slotsStock")

        -- _id = gameKey,                        --唯一key
        -- gameId   = gameId,                    --游戏id
        -- gameType = gameType,                         --场次id
        -- ZoneId = unilight.getzoneid(),        --zoneId
        -- stockNum = stockConfig.initStock,             --初始库存
        for k, v in pairs(table_stock_single) do
            local tmpdata =
            {
                id                  = v.ID,               --//库存唯一id
                taxpercent          = v.taxPercent,    --抽水比例
                curstocknum         = gamecommon.GetStockNumByType(v.ID),          --当前库存
                initstocknum        = v.initStock,     --初始库存
                subgametype         = v.gameType,          --游戏类型
                subgameid           = v.gameId,            --游戏id
            }

            if data.subgameid ~= 0 and data.subgametype ~= 0 then
                if v.gameId == data.subgameid and v.gameType == data.subgametype  then
                    table.insert(datas, tmpdata)
                end
            elseif data.subgameid ~= 0 then
                if data.subgameid == v.gameId then
                    table.insert(datas, tmpdata)
                end
            elseif data.subgametype ~= 0  then
                if data.subgametype == v.gameType then
                    table.insert(datas, tmpdata)
                end
            else
                table.insert(datas, tmpdata)
            end

        end


    -- 修改库存
    elseif data.optype == 2 then
        local data = data.datas[1]
        -- info.taxPercent = data.datas[1].taxpercent
        local stockTaxConfig = table_stock_single[data.id]
        stockTaxConfig.taxPercent = data.taxpercent
        gamecommon.SetStockNumByType(data.id, data.curstocknum)
    end

    cmd.data.maxpage      = maxpage
    cmd.data.datas        = datas
    return cmd
end


--库存调整系数
GmSvr.PmdStSlotsStockXSGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
    local data = cmd.data
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

    local  table_stock_xs
    if cmd.data.subgametype == 1 then
        table_stock_xs = table_stock_xs_1
    elseif cmd.data.subgametype == 2 then
        table_stock_xs = table_stock_xs_2
    elseif cmd.data.subgametype == 3 then
        table_stock_xs = table_stock_xs_3
    elseif cmd.data.subgametype == 4 then
        table_stock_xs = table_stock_recharge_lv
    elseif cmd.data.subgametype == 5 then
        table_stock_xs = table_stock_play_limit

    end
    --获得数据
    if data.optype == 1 then

        for i, info in ipairs(table_stock_xs) do
            --充值玩家档次
            if cmd.data.subgametype == 4 then
                table.insert(datas,
                {
                    id          = info.ID, --    //编号
                    rechargemin = info.chargeMin, --    //充值下限
                    rechargemax = info.chargeMax, --    //充值上限
                    rtpxs       = info.rtp, --    //库存系数
                }
                )
            --充值玩家上限
            elseif cmd.data.subgametype == 5 then

                local data = {
                    id               = info.ID,--     //编号
                    rechargemuls = {},              --充值倍数
                    controlvalue     = info.control   --控制值
                }
                local index = 1
                while true do
                    if info["condition"..index] == nil  then
                        break
                    end
                    table.insert(data.rechargemuls, info["condition"..index])
                    index = index + 1

                end
                table.insert(datas, data)
            --存库调整系数
            else
                table.insert(datas,
                {
                    id         = info.ID, --    //编号
                    stockmin   = info.stockMin, --    //库存下限
                    stockmax   = info.stockMax, --    //库存上限
                    rtpxs      = info.rtpXS, --    //库存系数
                }
                )
            end
        end

    -- 修改库存
    elseif data.optype == 2 then

        for i, info in pairs(table_stock_xs) do

            if info.ID == data.datas[1].id then

                if cmd.data.subgametype == 4 then
                    info.chargeMin  = data.datas[1].rechargemin
                    info.chargeMax = data.datas[1].rechargemax
                    info.rtp    = data.datas[1].rtpxs --//库存系数
                elseif cmd.data.subgametype == 5 then
                    info.control = data.datas[1].controlvalue
                    for k, v in ipairs(data.datas[1].rechargemuls)  do
                        if info["condition"..k] ~= nil then
                            info["condition"..k] = v
                        end
                    end
                else
                    info.stockMin  = data.datas[1].stockmin
                    info.stockMax = data.datas[1].stockmax
                    info.stockMin = data.datas[1].stockmin
                    info.rtpXS    = data.datas[1].rtpxs --//库存系数
                end
            end
        end
    end

    cmd.data.maxpage      = maxpage
    cmd.data.datas        = datas
    return cmd
end

--库存日志
GmSvr.PmdStSlotsStockLogGmUserPmd_CS = function(cmd, laccount)
	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}
	if curpage == 0 then
		curpage = 1
	end
    local filter = unilight.eq("gameType", cmd.data.subgametype)
    filter = unilight.a(filter,unilight.eq('gameId',cmd.data.subgameid))
    -- if cmd.data.subgameid > 0 then
        -- filter = unilight.a(filter,unilight.eq('gameId',cmd.data.subgameid))
    -- end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
    end

	local allNum 	= unilight.startChain().Table("slotsStockLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("slotsStockLog").Filter(filter).OrderBy(unilight.asc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do

        -- optional uint32  subgametype = 1; //场次
        -- optional string  datetime    = 2; //时间
		-- optional uint32  stocknum    = 9; //库存值

        table.insert(datas, {
            subgametype = info.gameType,
            datetime    = chessutil.FormatDateGet(info.timestamp),
            stocknum    = info.stockNum,
        })

    end
    local gameKey = cmd.data.subgameid * 10000 + cmd.data.subgametype
    local stockConfig = table_stock_single[cmd.data.subgametype]
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    cmd.data.initstock = stockConfig.initStock

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end

--抽水日志
GmSvr.PmdStSlotsTaxLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("gameType", 0)
    if cmd.data.subgametype > 0 then
        filter = unilight.a(filter,unilight.eq('gameType',cmd.data.subgametype))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('daytimestamp',starttime), unilight.le('daytimestamp',endtime))
    end

	local allNum 	= unilight.startChain().Table("gameBetPumpInfo").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("gameBetPumpInfo").Filter(filter).OrderBy(unilight.desc("daytimestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do

        --数据合并
        local bFind = false
        for _, v in pairs(datas) do
            if v.daytimestamp == info.daytimestamp and v.subgametype == info.gameType  and v.taxpercent == info.taxPercent then
                v.totaltaxchips = v.totaltaxchips + info.betDump --; //抽水总金额
                v.totalbetnum   = v.totalbetnum + info.betNum -- //投注总次数
                v.totalbetchips = v.totalbetchips + info.tbet -- //投注总金额
                bFind = true
                break
            end
        end

        if bFind == false then

            local payout = 0            --总赔付
            --特殊处理下非充值库存
            if info.gameType == 100 then
                local filterStr = '"daytimestamp":{"$eq":' .. info.daytimestamp .. '}'..", "..'"gameType":{"$eq":' .. 1 .. '}'..", "..'"type":{"$eq":' .. 2 .. '}'
                local taotalInfo = unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Aggregate('{"$match":{'..filterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$twin"}}}'))
                if table.len(taotalInfo) > 0 then
                    payout = taotalInfo[1].sum
                end
            else
                local filterStr = '"daytimestamp":{"$eq":' .. info.daytimestamp .. '}'..", "..'"gameType":{"$eq":' .. info.gameType .. '}'..", "..'"type":{"$eq":' .. 1 .. '}'
                local taotalInfo = unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Aggregate('{"$match":{'..filterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$twin"}}}'))
                if table.len(taotalInfo) > 0 then
                    payout = taotalInfo[1].sum
                end
            end
            table.insert(datas, {
                datetime      = chessutil.FormatDateGet(info.daytimestamp, "%Y-%m-%d"),-- //时间
                subgametype   = info.gameType, -- //场次
                taxpercent    = info.taxPercent, -- //抽水比例
                totaltaxchips = info.betDump, -- //抽水总金额
                totalbetnum   = info.betNum, -- //投注总次数
                totalbetchips = info.tbet, -- //投注总金额
                totalpayoutchips = payout, -- //总赔付
                daytimestamp = info.daytimestamp,   --//时间截
            })
        end

    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end


--充值玩家活跃留存日志
GmSvr.PmdStRechargeRetentionLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    -- local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
    if cmd.data.endtime == "" then
        cmd.data.retcode = 1
        cmd.data.retdesc =  "时间格式错误"
        return cmd
    end

    local begintime   = chessutil.TimeByDateGet(cmd.data.endtime)
    local endtime   = begintime + 86400
    local filter = unilight.a(unilight.ge('status.logintimestamp',begintime), unilight.le('status.logintimestamp',endtime),unilight.gt('property.totalRechargeChips',0) )

    --登陆活跃数
    local loginActiveNum = unilight.startChain().Table("userinfo").Filter(filter).Count()

    --充值大于提现数 + 携带金币
    local rechargeGtWithdraw = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate(
    '{"$match":{"$expr": {"$and": [{"$gt": ["$property.totalRechargeChips", {"$add": ["$status.chipsWithdraw", "$property.chips"]}]}, {"$gte": ["$status.logintimestamp", '..begintime..']}, {"$lt": ["$status.logintimestamp", '..endtime..']} ] } }}','{"$group":{"_id":null, "sum":{"$sum":1}}}'))
    if table.len(info)  > 0  then
        rechargeGtWithdraw = info[1].sum
    end
    -- 充值大于提现玩家登陆时间晚于当天数量
        -- optional uint32  recharge_gt_withdraw_gt_today = 3; //充值大于提现玩家登陆时间晚于当天数量
        -- optional uint32  recharge_lt_withdraw          = 4; //充值小于提现玩家数量
        -- optional uint32  recharge_lt_withdraw_gt_today = 5; //充值小于提现玩登陆时间晚于当天家数量
    local rechargeGtWithdrawGtToday = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate(
    '{"$match":{"$expr": {"$and": [{"$gt": ["$property.totalRechargeChips", {"$add": ["$status.chipsWithdraw", "$property.chips"]}]},  {"$gte": ["$status.logintimestamp", '..endtime..']} ] } }}','{"$group":{"_id":null, "sum":{"$sum":1}}}'))
    if table.len(info)  > 0  then
        rechargeGtWithdrawGtToday = info[1].sum
    end
    -- 充值小于提现玩家数量
    local rechargeLtWithdraw = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate(
    '{"$match":{"$expr": {"$and": [{"$lt": ["$property.totalRechargeChips", {"$add": ["$status.chipsWithdraw", "$property.chips"]}]}, {"$gte": ["$status.logintimestamp", '..begintime..']}, {"$lt": ["$status.logintimestamp", '..endtime..']} ] } }}','{"$group":{"_id":null, "sum":{"$sum":1}}}'))
    if table.len(info)  > 0  then
        rechargeLtWithdraw = info[1].sum
    end
    -- 充值小于提现玩登陆时间晚于当天家数量

    local rechargeLtWithdrawLtToday = 0
    local info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate(
    '{"$match":{"$expr": {"$and": [{"$lt": ["$property.totalRechargeChips", {"$add": ["$status.chipsWithdraw", "$property.chips"]}]},  {"$gte": ["$status.logintimestamp", '..endtime..']} ] } }}','{"$group":{"_id":null, "sum":{"$sum":1}}}'))
    if table.len(info)  > 0  then
        rechargeLtWithdrawLtToday = info[1].sum
    end
    -- print(loginActiveNum, rechargeGtWithdraw,rechargeGtWithdrawGtToday ,rechargeLtWithdraw,rechargeLtWithdrawLtToday  )

    table.insert(datas, {
        recharge_active               = loginActiveNum, -- //充值活跃玩家数量
        recharge_gt_withdraw          = rechargeGtWithdraw, --; //充值大于提现玩家数量
        recharge_gt_withdraw_gt_today = rechargeGtWithdrawGtToday, --; //充值大于提现玩家登陆时间晚于当天数量
        recharge_lt_withdraw          = rechargeLtWithdraw, -- //充值小于提现玩家数量
        recharge_lt_withdraw_gt_today = rechargeLtWithdrawLtToday, --; //充值小于提现玩登陆时间晚于当天家数量
    })

    maxpage = 1


    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end

--充值兑换日志
GmSvr.PmdRechargeExchangeLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("opType", 0)
    if cmd.data.optype > 0 then
        filter = unilight.a(filter,unilight.eq('opType',cmd.data.optype))
    end

    if cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq('uid',cmd.data.charid))
    end

    if cmd.data.subplatid > 0 then
        filter = unilight.a(filter,unilight.eq('subplatid',cmd.data.subplatid))
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
    end

	local allNum 	= unilight.startChain().Table("rechargeWithdrawLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Filter(filter).OrderBy(unilight.asc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do

        -- _id                = go.newObjectId(),
        -- timestamp          = os.time(),
        -- uid                = uid,
        -- curChips           = userInfo.property.chips,
        -- opType             = opType,
        -- opChips            = chips,
        -- rechargeNum        = userInfo.status.rechargeNum,
        -- totalRechargeChips = userInfo.property.totalRechargeChips,
        -- chipsWithdrawNum   = userInfo.status.chipsWithdrawNum,
        -- chipsWithdraw      = userInfo.status.chipsWithdraw,

        table.insert(datas, {
            id            = info._id, --; //编号
            timedate      = chessutil.FormatDateGet(info.timestamp), -- //时间字符串
            charid        = info.uid, -- //玩家id
            curchips      = info.curChips, --; // 当前金币
            type          = info.opType, -- //类型1充值，2是兑换
            opchips       = info.opChips, --; //充值兑换金额
            rechargenum   = info.rechargeNum, --; //充值次数
            totalrecharge = info.totalRechargeChips, --; //累计充值
            exchangenum   = info.chipsWithdrawNum, -- //兑换次数
            totalexchange = info.chipsWithdraw, --; //累计兑换金额
        })

    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end



--充值兑换日志
GmSvr.PmdRechargeRewardGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local data          = cmd.data
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if unilight.islobbyserver()  == false then
        cmd.data.retcode = 1
        cmd.data.retdesc =  "请在大厅服务器进行操作"
        return cmd
    end

    --查询数据
    if data.optype == 1 then
        for k, v in ipairs(table_recharge_reward) do
        -- ID = 4,
        -- chipsMax = 70000,
        -- chipsMin = 30000,
        -- rechargeMax = 999999999,
        -- rechargeMin = 5000001,
            table.insert(datas, {
                id            = v.ID, --; //编号
                rechargemin   = v.rechargeMin, --; //充值下限
                rechargemax   = v.rechargeMax,--  //充值上限
                chipsmin      = v.chipsMin, -- //金币下限
                chipsmax      = v.chipsMax, -- //金币上限
            })
        end
    --发放奖励
    elseif data.optype == 2 then
        for _, id in pairs(data.opvalue) do
            local rewardInfo = table_recharge_reward[id]
            local filter = unilight.a(unilight.ge("property.totalRechargeChips", rewardInfo.rechargeMin), unilight.le("property.totalRechargeChips", rewardInfo.rechargeMax))
            if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
                local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
                local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
                filter = unilight.a(filter, unilight.gt("status.logintimestamp", starttime), unilight.lt("status.logintimestamp", endtime))
            end

            local infos  = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Limit(100000))

            --当天0点时间截
            local endTime = chessutil.ZeroTodayTimestampGet()
            --上前7天时间截
            local beginTime = endTime - 7 * 86400
            for i, userInfo in ipairs(infos) do
                local randChips = math.random(rewardInfo.chipsMin, rewardInfo.chipsMax)
                local randChips = randChips * 100
                if rewardInfo.addPerMin ~= nil and rewardInfo.addPerMax ~= nil then
                    local randPer = math.random(rewardInfo.addPerMin, rewardInfo.addPerMax)
                    --获得指定时间的充值
                    local totalRecharge = chessuserinfodb.GetRechargeByTime(userInfo.uid, beginTime, endTime)
                    local addChips = 0
                    if totalRecharge > 0 then
                        addChips = math.floor(totalRecharge * randPer *0.000001) * 100
                    end
                    -- print("加成", userInfo.uid, totalRecharge, randPer, addChips)
                    randChips = randChips + addChips
                end

                UserInfo.AddOfflineReward(userInfo.uid, Const.GOODS_SOURCE_TYPE.RECHARGE_REWARD, Const.GOODS_ID.GOLD, randChips, true, {rewardId = id})
            end
        end
    --导出电话号码
    elseif data.optype == 3 then
        local phonenums = {}
        for _, id in pairs(data.opvalue) do
            local rewardInfo = table_recharge_reward[id]
            local filter = unilight.a(unilight.ge("property.totalRechargeChips", rewardInfo.rechargeMin), unilight.le("property.totalRechargeChips", rewardInfo.rechargeMax))
            if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
                local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
                local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
                filter = unilight.a(filter, unilight.gt("status.logintimestamp", starttime), unilight.lt("status.logintimestamp", endtime))
            end
            local infos  = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Limit(100000))

            for i, userInfo in ipairs(infos) do
                if string.len(userInfo.base.phoneNbr) > 0 then
                    table.insert(phonenums,
                    "55" .. userInfo.base.phoneNbr
                    )
                end
            end
        end
        table.insert(datas, phonenums)
    --修改数据
    elseif data.optype == 4 then
        for _, info in pairs(cmd.data.data) do
            for k, v in ipairs(table_recharge_reward) do
                if v.ID == info.id then
                    -- v.rechargeMin = info.rechargemin --; //充值下限
                    -- v.rechargeMax = info.rechargemax--  //充值上限
                    v.chipsMin    = info.chipsmin -- //金币下限
                    v.chipsMax    = info.chipsmax -- //金币上限
                    break
                end
            end
        end

    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end

--玩家专属奖励日志
GmSvr.PmdPlayerRechargeRewardLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("uid", 0)
    local filterStr1 = '"uid":{"$gt":' .. 0 .. '}'

    if cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq('uid',cmd.data.charid))
        filterStr1 = filterStr1 .. ', "uid":{"$eq":' .. cmd.data.charid .. '}'
    end

    if cmd.data.gettype > 0 then
        filter = unilight.a(filter,unilight.eq('isGet',cmd.data.gettype))
        filterStr1 = filterStr1 .. ', "isGet":{"$eq":' .. cmd.data.gettype .. '}'
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
        filterStr1 = filterStr1 .. ', "timestamp":{"$gt":' .. starttime .. ', "$lte" : ' .. endtime .. '}'
    end

    if cmd.data.rewardid > 0 then
        filter = unilight.a(filter,unilight.eq('rewardId',cmd.data.rewardid))
        filterStr1 = filterStr1 .. ', "rewardId":{"$eq":' .. cmd.data.gettype .. '}'
    end

    local totalChips = 0
    local getChips  = 0
    local noGetChips = 0

    --所有
    local info = unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "sum":{"$sum":"$chips"}}}'))
    if table.len(info)  > 0  then
        totalChips = info[1].sum
    end

    --未领取
    local filterStr2 = filterStr1 .. ', "isGet":{"$eq":' .. 1 .. '}'
    local info = unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Aggregate('{"$match":{'..filterStr2..'}}','{"$group":{"_id":null, "sum":{"$sum":"$chips"}}}'))
    if table.len(info)  > 0  then
        noGetChips = info[1].sum
    end

    local filterStr3 = filterStr1 .. ', "isGet":{"$eq":' .. 2 .. '}'
    local info = unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Aggregate('{"$match":{'..filterStr3..'}}','{"$group":{"_id":null, "sum":{"$sum":"$chips"}}}'))
    if table.len(info)  > 0  then
        getChips = info[1].sum
    end

	local allNum 	= unilight.startChain().Table("exclusiveRewardLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Filter(filter).OrderBy(unilight.asc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        -- _id                = go.newObjectId(),      --唯一id
        -- timestamp          = os.time(),             --发放时间
        -- uid                = uid,                   --玩家id
        -- isGet              = 1,                     --是否领取(1未领取， 2已领取)
        -- rewardId           = params.rewardId,       --奖励类型
        -- chips              = goodNum,               --发放金币
        -- getTime            = 0,                     --领取时间
        -- isOver             = 0,                     --是否过期(0未过期，1已过期)
        -- globalId           = globalId,              --全局id
        -- totalChips = totalChips + info.chips
        -- if info.isGet == 2 then
            -- getChips = getChips + info.chips
        -- end
--
        -- if info.isGet ==  1 and info.isOver == 0 then
            -- noGetChips = noGetChips + info.chips
        -- end

        local getTime = ""
        if info.getTime > 0 then
            getTime = chessutil.FormatDateGet(info.getTime)
        end

        local userInfo = chessuserinfodb.RUserDataGet(info.uid, true)

        table.insert(datas, {
            uid           = info.uid,                               -- //玩家id
            totalrecharge = userInfo.property.totalRechargeChips,   -- //累计充值
            totalexchange = userInfo.status.chipsWithdraw,          -- //累计兑换金额
            sendtime      = chessutil.FormatDateGet(info.timestamp),-- //发放时间
            gettime       = getTime,                                -- //领取时间
            rewardId      = info.rewardId,                          -- //充值区间id
            chips         = info.chips,                             -- //发放金币
            isget         = info.isGet,                             -- //领取状态，1未领取， 2已领取
        })
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.totalchips = totalChips
    cmd.data.getchips   = getChips
    cmd.data.nogetchips = noGetChips

    return cmd
end

--短信玩家回归数据
GmSvr.PmdSmsPlayerReturnInfoGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    if table.len(cmd.data.phonenum) <= 0 then
        cmd.data.retcode = 1
        cmd.data.retdesc =  "没有指定手机号码"
        return cmd
    end
    local starttime , endtime = 0, 0

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
    else
        cmd.data.retcode = 2
        cmd.data.retdesc =  "未指定查询时间"
        return cmd
    end

    -- optional uint32  player_num       = 1; //回归玩家人数
    -- optional uint32  percent_recharge = 2; //充值率
    -- optional uint32  avg_recharge     = 3; //平均充值
    -- optional uint32  total_recharge   = 4; //总充值
    -- optional uint32  total_withdraw   = 5; //总提现
    local data            = {}
    data.player_num       = 0
    data.total_recharge   = 0
    data.total_withdraw   = 0
    data.percent_recharge = 0
    data.avg_recharge     = 0
    data.recharge_num     = 0
    data.withdraw_num     = 0
    data.query_num        = 0

    local filterStr1 = '"timestamp":{"$gt":' .. starttime .. ', "$lte" : ' .. endtime .. '}'
    --手机号码太长，分段一下每组50个的查询
    local phoneNbrMap = {}
    local query_num = 0
    for _, phoneNbr in pairs(cmd.data.phonenum) do
        query_num = query_num + 1
        phoneNbrMap[query_num%50] = phoneNbrMap[query_num%50] or {}
        table.insert(phoneNbrMap[query_num%50], phoneNbr)
    end

    for _, phoneNbrs in pairs(phoneNbrMap) do
        local filter = nil
        for _, phoneNbr in pairs(phoneNbrs) do
            data.query_num = data.query_num + 1
            phoneNbr = string.gsub(phoneNbr, "55", "", 1)
            if filter == nil then
                filter = unilight.eq("base.phoneNbr", phoneNbr)
            else
                filter = unilight.o(filter, unilight.eq("base.phoneNbr", phoneNbr))
            end
        end

        local filter2 = unilight.a(unilight.gt("status.logintimestamp", starttime), unilight.lt("status.logintimestamp", endtime))
        filter = unilight.a(filter, filter2)

        --付费人数
        local payNum = 0
        local infos            = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter))
        for i, info in ipairs(infos) do
            data.player_num = data.player_num + 1

            local tmpFilterStr = filterStr1 .. ', "uid":{"$eq":' .. info.uid .. '}'
            --查充值
            local tmpFilterStr2 = tmpFilterStr .. ', "opType":{"$eq":' .. 1 .. '}'
            local info = unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Aggregate('{"$match":{'..tmpFilterStr2..'}}','{"$group":{"_id":null, "sum":{"$sum":"$opChips"}}}'))
            if table.len(info) > 0 then
                data.total_recharge = data.total_recharge + info[1].sum
                data.recharge_num = data.recharge_num + 1
            end

            --查提现
            local tmpFilterStr2 = tmpFilterStr .. ', "opType":{"$eq":' .. 2 .. '}'
            local info = unilight.chainResponseSequence(unilight.startChain().Table("rechargeWithdrawLog").Aggregate('{"$match":{'..tmpFilterStr2..'}}','{"$group":{"_id":null, "sum":{"$sum":"$opChips"}}}'))
            if table.len(info) > 0 then
                data.total_withdraw = data.total_withdraw + info[1].sum
                data.withdraw_num = data.withdraw_num + 1
            end
        end

    end



    table.insert(datas, data)
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    cmd.data.phonenum = {}

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.totalchips = totalChips
    cmd.data.getchips   = getChips
    cmd.data.nogetchips = noGetChips

    return cmd
end



--输赢统计
GmSvr.PmdStWinLoseStatisticsGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local data          = cmd.data
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("gameId", 0)
    local filterStr1 = '"gameId":{"$gt":' .. 0 .. '}'
    if data.gametype > 0 then
        filter = unilight.a(filter, unilight.eq("classType", data.gametype))
        filterStr1 = filterStr1 ..', "classType":{"$eq":' .. data.gametype .. '}'
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter, unilight.ge("daytimestamp", starttime), unilight.le("daytimestamp", endtime))
        filterStr1 = filterStr1..', "daytimestamp":{"$gt":' .. starttime .. ', "$lte":' .. endtime ..'}'
    end

    if data.subgameid > 0 then
        filter = unilight.a(filter, unilight.eq("gameId", data.subgameid))
        filterStr1 = filterStr1 ..', "gameId":{"$eq":' .. data.subgameid .. '}'
    end

    if data.subgametype > 0 then
        filter = unilight.a(filter, unilight.eq("gameType", data.subgametype))
        filterStr1 = filterStr1 ..', "gameType":{"$eq":' .. data.subgametype .. '}'
    end

    if data.stocktype > 0 then
        filter = unilight.a(filter, unilight.eq("type", data.stocktype))
        filterStr1 = filterStr1 ..', "type":{"$eq":' .. data.stocktype .. '}'
    end

    local allbet       = 0 --; //总下注
    local allpayout    = 0 --; //总赔付
    local info = unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":null, "allbet":{"$sum":"$tchip"}, "allpayout":{"$sum":"$twin"}}}'))
    if table.len(info)  > 0  then
        allbet = info[1].allbet
        allpayout = info[1].allpayout
    end

    local info = unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"$daytimestamp"}}','{"$group":{"_id":"null", "allnum":{"$sum":1}}}'))
    local allNum = 0
    if table.len(info) > 0 then
        allNum = info[1].allnum
    end

    maxpage = math.ceil(allNum/perpage)

    local infos = unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"$daytimestamp", "allbet":{"$sum":"$tchip"}, "allpayout":{"$sum":"$twin"}}}', '{"$sort": {"_id": -1}}', '{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}'))

    -- local orderBy   ={unilight.desc("daytimestamp"), unilight.desc("gamecount")}
	-- local allNum 	= unilight.startChain().Table("gameDayStatistics").Filter(filter).Count()
	-- local infos 		= unilight.chainResponseSequence(unilight.startChain().Table("gameDayStatistics").Filter(filter).OrderBy(unpack(orderBy)).Skip((curpage-1)*perpage).Limit(perpage))



    for i, info in ipairs(infos) do
        -- local gameConfig = gamecommon.GetGameConfig(info.gameId, info.gameType)
        --[[
        local bFind = false
        local gameType = table_game_list[info.gameId * 10000 + 1].gameType
        --数据合并
        for _, v in pairs(datas) do
            if v.timestamp == info.daytimestamp then
                v.allbet = v.allbet + info.tchip --; //总下注
                v.allpayout = v.allpayout + info.twin --; //总赔付
                -- v.allprofit = v.allprofit + (info.tchip - info.twin) --; //总盈利
                -- v.allpump   = v.allpump + info.tax --; //总抽水
                -- v.allgamecount = v.allgamecount + info.gamecount  --游戏次数
                bFind = true
                break
            end
        end

        if bFind == false then
            ]]

            table.insert(datas,
            {
                timestamp    = info._id, --;//时间截
                datetime     = chessutil.FormatDateGet(info._id, "%Y-%m-%d"),-- //时间
                allbet       = info.allbet, --; //总下注
                allpayout    = info.allpayout, --; //总赔付
            }
            )
        --end
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.allbet      = allbet
    cmd.data.allpayout   = allpayout
    return cmd
end


--每日货币统计
GmSvr.PmdGameDayChipsStatisicGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end


    local filter = unilight.gt("daytimestamp", 0)
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('daytimestamp',starttime), unilight.le('daytimestamp',endtime))
    end

	local allNum 	= unilight.startChain().Table("gameDayChipsStatisicLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("gameDayChipsStatisicLog").Filter(filter).OrderBy(unilight.desc("daytimestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        table.insert(datas, {
            datetime           = chessutil.FormatDateGet(info.daytimestamp); --//时间
            noRechargeAllChips = info.noRechargeAllChips; --//非充值玩家总金币
            rechargeAllChips   = info.rechargeAllChips; --充值玩家总金币
            totalStock         = info.totalStock; --当日总库存
            rechargeChips      = info.rechargeChips; --当日总充值金币
            withdrawChips      = info.withdrawChips; --当日总现现
            presentChips       = info.presentChips; --当日总赠送
        })
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    return cmd
end

--每日货币统计
GmSvr.PmdStDayRechargeStatisticGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end


    local filter = unilight.gt("dayNum", 0)
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('dayNum',starttime), unilight.le('dayNum',endtime))
    end

	local allNum 	= unilight.startChain().Table("DayRechargeStatistic").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("DayRechargeStatistic").Filter(filter).OrderBy(unilight.desc("dayNum")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        table.insert(datas, {
            datetime = chessutil.FormatDateGet(info.dayNum), --//时间
            pay1     = info.pay1,                                  --1充人数
            pay2     = info.pay2,                                  --2充人数
            pay3     = info.pay3,                                  --3充人数
            pay4     = info.pay4,                                  --4充人数
        })
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    return cmd
end

--配表数据查询修改
GmSvr.PmdStExcelHotupGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local reqtype       = cmd.data.reqtype
    local optype        = cmd.data.optype
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local table_info_config = {
        --假金币配置(表名称, 要修改的字段, 字段类型)
        [1] = {tableName = "table_auto_pointLimit", fieldNames = {"chargeLow1", "chargeUp1", "rtp1", "rtpMul1", "visualRtp", "visualMul", "visualGold", "visualBetMul", "visualKillRtp", "visualKillMul" }, fieldType = "int"}, 
        --可提现金币配置 
        [2] = {tableName = "table_auto_addPro", fieldNames = {"noAddPro", "minAdd", "maxAdd", "score", "addRandomMin", "addRandomMax" }, fieldType = "int"}, 
    }

    local table_info =  table_info_config[reqtype]
    if table_info == nil then
        cmd.data.retcode = 2
        cmd.data.retdesc =  "请求类型错误"
        return cmd
    end

    local table_custome_config =  import("table/"..table_info.tableName)

    --查询
    if optype == 1 then

        for id, config in ipairs(table_custome_config) do
            local intDatas = {}
            for _, filedName in ipairs(table_info.fieldNames) do
                table.insert(intDatas, config[filedName] )
            end
            table.insert(datas, {
                id       = id,            --配置id
                intdatas = intDatas,    --整型配置
            })
        end
    --修改
    else
        for _, data in pairs(cmd.data.data) do
            local excelConfig = table_custome_config[data.id]
            if excelConfig == nil then
                cmd.data.retcode = 2
                cmd.data.retdesc =  "请求类型错误"
                return cmd
            end
            for index, value in ipairs(data.intdatas) do
                excelConfig[table_info.fieldNames[index]] = value
            end

        end
    end
    
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = 1
	cmd.data.data        = datas

    return cmd
end


--爆池记录
GmSvr.PmdStUserJackpotLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end


    local filter = unilight.gt("uid", 0)
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
    end

    if cmd.data.uid > 0 then
        filter = unilight.a(filter,unilight.eq('uid',cmd.data.uid))
    end

    if cmd.data.subgameid > 0 then
        filter = unilight.a(filter,unilight.eq('gameId',cmd.data.subgameid))
    end

    if cmd.data.subgametype > 0 then
        filter = unilight.a(filter,unilight.eq('gameType',cmd.data.subgametype))
    end

	local allNum 	= unilight.startChain().Table("gameJackpotLog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("gameJackpotLog").Filter(filter).OrderBy(unilight.desc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        table.insert(datas, {
            datetime = chessutil.FormatDateGet(info.timestamp), --//时间
            uid      = info.uid, --          //玩家id
            gameId   = info.gameId, --          //游戏id
            gameType = info.gameType, --          //游戏场次
            chips    = info.chips, --          //爆池金币
        })
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    return cmd
end

--分享奖励
GmSvr.PmdStUserImageUploadGmUserPmd_CS = function(cmd, laccount)
    print('GmData',table2json(cmd.data))
	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local imagetype = cmd.data.imagetype
	local maxpage = 0
	local datas = {}
    local tableName = 'user_image_upload'
    if imagetype==2 then
        tableName = 'user_image_addDesktop'
    end
	if curpage == 0 then
		curpage = 1
	end
    if cmd.data.optype == 0 then
        local filter = unilight.gt("_id", 0)
        if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
        end

        if cmd.data.uid > 0 then
            filter = unilight.a(filter,unilight.eq('_id',cmd.data.uid))
        end

        if cmd.data.status > 0 then
            filter = unilight.a(filter,unilight.eq('status',cmd.data.status))
        end


        local orderBy   ={unilight.asc("status"), unilight.desc("timestamp")}
        local allNum 	= unilight.startChain().Table(tableName).Filter(filter).Count()
        local infos 	= unilight.chainResponseSequence(unilight.startChain().Table(tableName).Filter(filter).OrderBy(unpack(orderBy)).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do

            local cpfInfo = WithdrawCash.ChangeWithdrawcashCpfInfo(info._id, "", "", "")
            table.insert(datas, {
                datetime  = chessutil.FormatDateGet(info.timestamp), --//时间
                uid       = info._id, --          //玩家id
                imagedata = info.imgData,       --图片信息
                status    = info.status,        --领取状态
                realname  = cpfInfo.name,       --真实姓名
            })
        end
    else

        for _, data  in pairs(cmd.data.data) do
            local info = unilight.getdata(tableName, data.uid)
            if info == nil then
                cmd.data.retcode = 2
                cmd.data.retdesc =  "玩家uid错误"
                return cmd
            end
            if info.status == 2 then
                cmd.data.retcode = 2
                cmd.data.retdesc =  "玩家已经发放过奖励"
                return cmd
            end

            if cmd.data.status == 3 then
                info.status = 3
                local mailId=29
                if imagetype==2 then
                    mailId = 32
                end
                --已拒绝要重置下玩家上传状态
                --失败通知
                local mailConfig = table_mail_config[mailId]
                local mailInfo = {}
                mailInfo.charid = data.uid
                mailInfo.subject = mailConfig.subject
                mailInfo.content = mailConfig.content
                mailInfo.type = 0
                mailInfo.attachment = {}
                ChessGmMailMgr.AddGlobalMail(mailInfo)

                --清除下上传记录
                unilight.delete(tableName, data.uid)
            else
                --成功
                info.status = 2
                unilight.savedata(tableName, info)
                local awardId=30
                local mailId=28
                if imagetype==2 then
                    awardId = 32
                    mailId = 31
                end
                --发放奖励
                local goodNum = table_parameter_parameter[awardId].Parameter
                local mailConfig = table_mail_config[mailId]
                local mailInfo = {}
                mailInfo.charid = data.uid
                mailInfo.subject = mailConfig.subject
                mailInfo.content = mailConfig.content
                mailInfo.type = 0
                mailInfo.attachment = {{itemId=Const.GOODS_ID.GOLD, itemNum=goodNum}}
                mailInfo.extData = {isPresentChips = 1}
                ChessGmMailMgr.AddGlobalMail(mailInfo)
            end
        end

    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    return cmd
end


--推广日志
GmSvr.PmdStWithdrawLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end
    local totalChips = 0
    local totalNum   = 0

    local totalValidNum = 0
    local totalValidChips = 0
    local totalRechargeNum = 0
    local totalRechargeChips = 0


    --推广现金日志
    if cmd.data.reqtype == 0 then

        local filter = unilight.gt("parentid", 0)
        if cmd.data.uid > 0 then
            filter = unilight.a(filter,unilight.eq('parentid',cmd.data.uid))
        end

if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.ge('addTime',starttime), unilight.le('addTime',endtime))
        end

        local allNum 	= unilight.startChain().Table("rebatelog").Filter(filter).Count()
        local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("rebatelog").Filter(filter).OrderBy(unilight.desc("addTime")).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do
            totalChips = totalChips + info.rebatechip
            table.insert(datas, {
                datetime = chessutil.FormatDateGet(info.addTime), --//时间
                uid      = info.uid, --          //玩家id
                chips    = info.rebatechip, --          //金额数量
            })
        end


    --推广现金奖励日志
    elseif  cmd.data.reqtype == 1 then
        local filter = unilight.gt("uid", 0)

        if cmd.data.uid > 0 then
            filter = unilight.a(filter,unilight.eq('uid',cmd.data.uid))
        end

        if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
        end

        local allNum 	= unilight.startChain().Table("nchiplog").Filter(filter).Count()
        local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("nchiplog").Filter(filter).OrderBy(unilight.desc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do
            totalChips = totalChips + info.todayFlowingChips
            table.insert(datas, {
                datetime = chessutil.FormatDateGet(info.timestamp), --//时间
                uid      = info.uid, --          //玩家id
                chips    = info.todayFlowingChips, --          //金额数量
            })
        end
    --有效玩家日志
    elseif  cmd.data.reqtype == 2 then
        local filter = unilight.gt("uid", 0)


        if cmd.data.uid > 0 then
            filter = unilight.a(filter,unilight.eq('uid',cmd.data.uid))

            local filterStr1 = '"_id":{"$eq":' .. cmd.data.uid .. '}'
            local info = unilight.chainResponseSequence(unilight.startChain().Table("validinvite").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"null", "freeNum":{"$sum":"$validinViteFreeNum"}, "rechargeNum":{"$sum":"$validinViteNum"}}}'))
            if table.len(info)  > 0  then
                totalValidNum    = info[1].rechargeNum
                totalRechargeNum = info[1].freeNum
            end

            local filterStr1 = '"uid":{"$eq":' .. cmd.data.uid .. '}'

            if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
                local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
                local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
                filter = unilight.a(filter,unilight.ge('addTime',starttime), unilight.le('addTime',endtime))
                filterStr1 = filterStr1 .. ', "addTime":{"$gte":' .. starttime .. ', "$lt":'..endtime..'}'
            end

            local infos = unilight.chainResponseSequence(unilight.startChain().Table("validinvitelog").Aggregate('{"$match":{'..filterStr1..'}}','{"$group":{"_id":"$type", "sum":{"$sum":"$addChips"}}}'))
            for _, info in ipairs(infos)  do
                --现金
                if info._id == 1 then
                    totalRechargeChips = totalRechargeChips + info.sum
                    --金币
                elseif info._id == 2 then
                    totalValidChips = totalValidChips + info.sum
                end
            end
        end

        if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
            local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
            local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.ge('addTime',starttime), unilight.le('addTime',endtime))
        end



        local allNum 	= unilight.startChain().Table("validinvitelog").Filter(filter).Count()
        local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("validinvitelog").Filter(filter).OrderBy(unilight.desc("addTime")).Skip((curpage-1)*perpage).Limit(perpage))

        maxpage = math.ceil(allNum/perpage)
        for i, info in ipairs(infos) do
            totalChips = totalChips + info.addChips
            table.insert(datas, {
                datetime = chessutil.FormatDateGet(info.addTime), --//时间
                uid      = info.uid, --          //玩家id
                chips    = info.addChips, --          //金额数量
                rewardtype = info.type, --类型1现金、2金币
            })
        end
    end




    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas
    cmd.data.totalchips  = totalChips

    cmd.data.total_valid_num      = totalValidNum -- //有效玩家总数
    cmd.data.total_valid_chips    = totalValidChips -- //有效玩家奖励金币总额
    cmd.data.total_recharge_num   = totalRechargeNum -- //有效充值玩家总数
    cmd.data.total_recharge_chips = totalRechargeChips -- //有效玩家现金奖励总额

    return cmd
end

--邮件日志
GmSvr.PmdStMailLogGmUserPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end


    local filter = unilight.gt("uid", 0)
    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime))
    end

    if cmd.data.uid > 0 then
        filter = unilight.a(filter,unilight.eq('uid',cmd.data.uid))
    end


	local allNum 	= unilight.startChain().Table("maillog").Filter(filter).Count()
	local infos 	= unilight.chainResponseSequence(unilight.startChain().Table("maillog").Filter(filter).OrderBy(unilight.desc("timestamp")).Skip((curpage-1)*perpage).Limit(perpage))

    maxpage = math.ceil(allNum/perpage)
    for i, info in ipairs(infos) do
        table.insert(datas, {
            datetime = chessutil.FormatDateGet(info.timestamp), --//时间
            uid      = info.uid, --          //玩家id
            gmid     = info.gmId, --          //gmid
            subject  = info.subject, --          //主题
            content  = info.content,        --内容
            chips    = info.chips, --          //金币
        })
    end

    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"

	cmd.data.maxpage      = maxpage
	cmd.data.data        = datas

    return cmd
end
