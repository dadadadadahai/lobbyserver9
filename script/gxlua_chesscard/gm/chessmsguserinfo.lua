-- 请求同步玩家的屏幕

GmCmd.SendUserSceneToMe = function(cmd, laccount)
    local peerUid = cmd
    local data = RoomMgr.UserRoomInfoGetByUid(peerUid)
    local res = {} 
    res["Do"] = "Cmd.RoomEnter_S"
    local bOk, lotteryedId, roomInfo, userInfo, bankerInfo, bankerConfig = RoomMgr.CmdRoomEnter(uid, roomId, laccount)
    if bOk == false then
        res["data"] = { 
            desc = "进入房间失败"
        }   
        return res 
    end 

    res["data"] = { 
        resultCode = 0,
        lotteryedId = lotteryedId,
        roomInfo = roomInfo,
        userInfo = userInfo,
        bankerInfo = bankerInfo,
        bankerConfig = bankerConfig,
    }   
    return res
end

-- 
GmSvr.SmdHttpGmCommandLoginSmd_SC = function(cmd, laccount)
	unilight.info(table.tostring(cmd))
end

-- 获取玩家金币
GmSvr.PmdRequestUserInfoGmUserPmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "ReturnUserInfoGmUserPmd_S" 
	res["data"] = {}
    --pid   cpf 查询
	if cmd.data == nil or ((cmd.data.charid == nil or cmd.data.charid == 0) and (cmd.data.charname == nil or cmd.data.charname == "") and (cmd.data.pid == nil or cmd.data.pid == "")) then
		res.data.retcode = 1
		res.data.retdesc = "参数为空"
		return res
	end
    -- 默认uid
    local uid = 0
    -- 如果两个参数都写入
    if cmd.data.charid ~= nil and cmd.data.charid ~= 0 and cmd.data.charname ~= nil and cmd.data.charname ~= "" then
        local filter = unilight.eq("base.plataccount", cmd.data.charname)
        local dbinfo = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter))[1]
        if dbinfo == nil or dbinfo._id == nil then
            res.data.retcode = 1
            res.data.retdesc = "角色不存在"
            return res
        end
        uid = dbinfo._id
        if uid ~= cmd.data.charid then
            res.data.retcode = 1
            res.data.retdesc = "角色不存在"
            return res
        end
    -- 如果是根据UID查询
    elseif cmd.data.charid ~= nil and cmd.data.charid ~= 0 then
        uid = cmd.data.charid
    elseif cmd.data.charname ~= nil and cmd.data.charname ~= "" then
        local filter = unilight.eq("base.plataccount", cmd.data.charname)
        local dbinfo = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter))[1]
        if dbinfo == nil or dbinfo._id == nil then
            res.data.retcode = 1
            res.data.retdesc = "角色不存在"
            return res
        end
        uid = dbinfo._id
    elseif cmd.data.pid ~= nil or cmd.data.pid ~= "" then
        local filter = unilight.eq("cpf", cmd.data.pid)
        local dbinfo = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash").Filter(filter))[1]
        if dbinfo == nil or dbinfo._id == nil then
            res.data.retcode = 1
            res.data.retdesc = "角色不存在"
            return res
        end
        uid = dbinfo._id
    end
    local ret, desc, data = ChessGmUserInfoMgr.GetUserInfo(uid)
    



    if ret ~= 0 then
        res.data.retcode = ret
        res.data.retdesc = desc
        return res
    end
    res.data.data = data
    res.data.retcode = 0
    res.data.charid = uid
	return res
end

-- 修改玩家金币
GmSvr.PmdRequestModifyUserInfoGmUserPmd_C = function(cmd, laccount)
    unilight.info(string.format("gm修改玩家信息:%s",table2json(cmd)))
	local res = {}
	res["do"] = "ReturnModifyUserInfoGmUserPmd_S" 
	res["data"] = {}
	if cmd.data == nil or cmd.data.optype == nil or cmd.data.charid == nil then
		res.data.retcode = 1 
		res.data.retdesc = "参数类型没有带入"
		return res
	end
    res.data.retcode = 0 
    res.data.retdesc = "操作成功"
    local uid = cmd.data.charid
	local opType = cmd.data.optype
	local changeType = cmd.data.changetype or 0
    local onlineInfo = backRealtime.lobbyOnlineUserManageMap[uid]
    if onlineInfo==nil then
        --不在线
        UserInfo.playerModifyInfo(uid,opType,changeType,cmd)
    else
        local data={
            uid=uid,
            opType=opType,
            changeType=changeType,
            cmd=cmd
        }
        onlineInfo.zone:SendCmdToMe('Cmd.RequestModifyUserInfoGmUserLobby_CS',data)
    end
    return res
end
-- 玩家处罚(处罚相关操作 均使用 charid 代替 uid)
-- 处罚操作 ptype：1警告，2禁言，3自言自语，4关禁闭，5踢下线，6封号 (暂时只做 3自言自语)
GmSvr.PmdPunishUserGmUserPmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "ReturnPunishUserGmUserPmd_S" 

	local ret, desc = ChessGmUserInfoMgr.PunishUser(cmd.data.data)

	res["data"] = {
		retcode = ret,
		retdesc = desc,
		taskid	= cmd.data.data.taskid,
		gmid 	= cmd.data.data.gmid
	}
	return res
end

-- 删除处罚 
GmSvr.PmdDeletePunishUserGmUserPmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "ReturnDeletePunishUserGmUserPmd_S" 
	res["data"] = {}

	local taskid = cmd.data.taskid
	local gameid = cmd.data.gameid
	local zoneid = cmd.data.zoneid
	local gmid 	 = cmd.data.gmid

	if taskid == nil then
		res["data"] = {
			retcode = 1,
			zoneid 	= zoneid,
			gmid 	= gmid
		}	
		return res	
	end

	local ret = ChessGmUserInfoMgr.DeletePunishUser(taskid)

	res["data"] = {
		retcode = ret,
		zoneid 	= zoneid,
		gmid 	= gmid
	}	
	return res
end

-- 获取当前处罚列表 （当前只允许通过charid查询）
GmSvr.PmdRequestPunishListGmUserPmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "ReturnPunishListGmUserPmd_S" 
	res["data"] = {}

	local gameid 		= cmd.data.gameid
	local zoneid 		= cmd.data.zoneid
	local charid 		= cmd.data.charid
	local charname 		= cmd.data.charname
	local ptype 		= cmd.data.ptype
	local gmid 			= cmd.data.gmid
	local recordtime 	= cmd.data.recordtime

	local taskInfos = ChessGmUserInfoMgr.GetPunishList(charid)

	res["data"] = {
		data 	= taskInfos,
		gmid 	= gmid
	}	
	return res
end


-- 获取在线玩家列表
GmSvr.PmdRequestOnlineUserInfoGmUserPmd_CS= function(cmd, laccount)
	local res = cmd

	local charid 		= cmd.data.charid
	local charname 		= cmd.data.charname or ""
	local isonline 		= cmd.data.isonline
	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local isagent 		= cmd.data.isagent
	local starttime 	= cmd.data.starttime
	local endtime 		= cmd.data.endtime
	local lstime 		= cmd.data.lstime
	local letime	 	= cmd.data.letime
	local mincoin	 	= cmd.data.mincoin
	local maxcoin	 	= cmd.data.maxcoin
	local ranktype 		= cmd.data.ranktype -- 排序 结果排序类型，0注册时间， 1金币, 2.累计充值， 3.充值次数， 4. 推广提现， 5.金币提现， 6.推广提现次数， 7.金币提现次数
    local phonenum      = cmd.data.phonenum
    local account      = cmd.data.account
    local cpf = cmd.data.cpf

	if curpage == 0 then
		curpage = 1
	end

    local filter = unilight.gt("uid", 0)

    --总注册
    local registerAll = unilight.startChain().Table("userinfo").Filter(unilight.field("uid").Gt(0)).Count()

	local datas = {}
	local maxpage = 0
    local orderBy = unilight.desc("status.registertime")
    --金币
    if ranktype == 1 then
        orderBy = unilight.desc("property.chips")
    --累计充值
    elseif ranktype == 2 then
        orderBy = unilight.desc("property.totalRechargeChips")
    --充值次数
    elseif ranktype == 3 then
        orderBy = unilight.desc("status.rechargeNum")
    --推广提现
    elseif ranktype == 4 then
        orderBy = unilight.desc("status.promoteWithdaw")
    --金币提现
    elseif ranktype == 5 then
        orderBy = unilight.desc("status.chipsWithdaw")
    --推广提现次数
    elseif ranktype == 6 then
        orderBy = unilight.desc("status.promoteWithdawNum")
    --金币提现次数
    elseif ranktype == 7 then
        orderBy = unilight.desc("status.chipsWithdawNum")
    end

	-- 根据玩家id 查指定玩家数据
	if charid ~= 0 then
		unilight.info("收到根据id查询玩家信息" .. charid)
		local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(charid)
		if ret == 0 then
			table.insert(datas, data)
			maxpage = 1
		end
	-- 根据昵称查询
	elseif charname ~= "" and charname ~= "0" then
		unilight.info("收到根据昵称查询玩家信息" .. charname)
		local userInfoNum = unilight.startChain().Table("userinfo").Filter(unilight.RegEx("base.nickname",charname)).Count()
		maxpage = math.ceil(userInfoNum/perpage)
 		local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(unilight.RegEx("base.nickname",charname)).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
		for i,v in ipairs(userInfos) do
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(v.uid)
			if ret == 0 then
				table.insert(datas, data)
			end			
		end
	-- 根据账号查询
	elseif account ~= "" and account ~= "0" then
		unilight.info("收到根据昵称查询玩家信息" .. account)
		local userInfoNum = unilight.startChain().Table("userinfo").Filter(unilight.RegEx("base.plataccount",account)).Count()
		maxpage = math.ceil(userInfoNum/perpage)
 		local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(unilight.RegEx("base.plataccount",account)).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
		for i,v in ipairs(userInfos) do
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(v.uid)
			if ret == 0 then
				table.insert(datas, data)
			end			
		end
    --根据电话号码查询
    elseif phonenum ~= ""  then
		unilight.info("收到根据电话查询玩家信息:" .. phonenum)

        filter = unilight.a(filter,unilight.eq("base.phoneNbr", phonenum))
		local userInfoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
		maxpage = math.ceil(userInfoNum/perpage)
 		local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
		for i,v in ipairs(userInfos) do
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(v.uid)
			if ret == 0 then
				table.insert(datas, data)
			end			
		end
    --根据CPF查询
    elseif cpf ~= nil and cpf ~= ""  then
		unilight.info("收到根据CPF查询玩家信息:" .. cpf)

        filter = unilight.a(filter,unilight.eq("base.cpf", cpf))
		local userInfoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
		maxpage = math.ceil(userInfoNum/perpage)
 		local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
		for i,v in ipairs(userInfos) do
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(v.uid)
			if ret == 0 then
				table.insert(datas, data)
			end			
		end

	-- 6个新增范围选项 只要有一个 则走以下查询方案
	-- elseif starttime ~= 0 or endtime ~= 0 or lstime ~= 0 or letime ~= 0 or mincoin ~= 0 or maxcoin ~= 0 or ranktype ~= 0 then
		-- datas, maxpage = ChessGmUserInfoMgr.SearchByRange(starttime, endtime, lstime, letime, mincoin, maxcoin, curpage, perpage, ranktype)

	-- 查询当前在线玩家(0不区分状态 1在线 2离线 )
	elseif isonline == 0 then
		unilight.info("收到根据查询离线玩家信息")

        local filter = unilight.gt("uid", 0)
        --游客
        if cmd.data.usertype == 1 then
            filter = unilight.a(filter,unilight.eq("base.phoneNbr", ""))
        --绑定
        elseif cmd.data.usertype == 2 then
            filter = unilight.a(filter,unilight.neq("base.phoneNbr", ""))
        --查询有下级玩家
        elseif cmd.data.usertype == 3 then
            filter = unilight.a(filter,unilight.gt("status.childNum", 0))
            orderBy = unilight.desc("status.childNum")
        --充值玩家
        elseif cmd.data.usertype == 4 then
            filter = unilight.a(filter,unilight.eq("property.totalRechargeChips", 0))
        --非充值玩家
        elseif cmd.data.usertype == 5 then
            filter = unilight.a(filter,unilight.gt("property.totalRechargeChips", 0))
        end

        if cmd.data.regip ~= "" then
            filter = unilight.a(filter,unilight.eq("status.registerIp", cmd.data.regip))
        end

        if cpf ~= nil and cpf ~= "" then
            filter = unilight.a(filter,unilight.eq("base.cpf", cpf))
        end

        if string.len(cmd.data.starttime) > 0 and string.len(cmd.data.endtime) > 0 then
            local starttime = chessutil.TimeByDateGet(cmd.data.starttime)
            local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
            filter = unilight.a(filter,unilight.ge("status.registertimestamp", starttime))
            filter = unilight.a(filter,unilight.le("status.registertimestamp", endtime))
        end

        if cmd.data.regflag > 0  then
            filter = unilight.a(filter,unilight.eq("base.regFlag", cmd.data.regflag))
        end

        --渠道查询
        if cmd.data.subplatid > 0 then
            filter = unilight.a(filter,unilight.eq("base.subplatid", cmd.data.subplatid))
        end

        registerAll = unilight.startChain().Table("userinfo").Filter(filter).Count()
		local userInfoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
		maxpage = math.ceil(userInfoNum/perpage)
 		local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
		for i,v in ipairs(userInfos) do
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(v.uid)
			if ret == 0 then
				table.insert(datas, data)
			end			
		end
        -- 计算下载APK玩家总数量
        local apkNumFilter = unilight.o(unilight.eq("status.loginPlatIds.1", 3),
                                        unilight.a(unilight.eq("status.loginPlatIds.1", 1),unilight.eq("status.loginPlatIds.2", 3)),
                                        unilight.a(unilight.eq("status.loginPlatIds.1", 2),unilight.eq("status.loginPlatIds.2", 3)),
                                        unilight.a(unilight.eq("status.loginPlatIds.1", 1),unilight.eq("status.loginPlatIds.2", 2),unilight.eq("status.loginPlatIds.3", 3)),
                                        unilight.a(unilight.eq("status.loginPlatIds.1", 2),unilight.eq("status.loginPlatIds.2", 1),unilight.eq("status.loginPlatIds.3", 3)))
        filter = unilight.a(filter,apkNumFilter)
        res.data.isDownApkNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
    --查询在线玩家
    elseif isonline == 1 then
		unilight.info("收到根据查询在线玩家信息")
        local game_zone_online_list = annagent.GetOnlineUids()
        local uids = {}
        local lobbyuids = {}
        for gameId, zone_online_list in pairs(game_zone_online_list) do
            for zoneId, online_list in pairs(zone_online_list) do
                for _, userInfo in ipairs(online_list) do
                    --大厅人数单独统计
                    if gameId == Const.GAME_TYPE.LOBBY then
                        table.insert(lobbyuids, userInfo.uid)
                    else
                        if data.subgameid > 0  then
                            if data.subgametype ~= nil and data.subgametype > 0 then 
                                if data.subgameid == userInfo.subGameId and data.subgametype == userInfo.subGameType then
                                    table.insert(uids, userInfo.uid)
                                end
                            else
                                if data.subgameid == userInfo.subGameId then
                                    table.insert(uids, userInfo.uid)
                                end
                            end
                        else
                            table.insert(uids, userInfo.uid)
                        end
                    end

                end
            end
        end

        table.sort(uids)
		maxpage = math.ceil(#uids/perpage)

		for i=(curpage-1)*perpage + 1, curpage*perpage do
			if i > #uids then
				break
			end
			local ret, _, data = ChessGmUserInfoMgr.GetUserInfo(uids[i])
			if ret == 0 then
				table.insert(datas, data)
			end
		end
	end
    res.data.isDownApkNum = res.data.isDownApkNum or 0
	res.data.maxpage = maxpage
	res.data.data = datas
    cmd.data.registernum  = registerAll
	return res
end

GmSvr.PmdLobbyChgUserPwdGmUserPmd_CS = function(cmd, laccount)
	unilight.info("收到gm修改密码请求" .. table.tostring(cmd))
	local account = cmd.data.account
	local newPassword = cmd.data.passwd
	local uid = tonumber(account)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		cmd.data.retcode = 1 
		cmd.data.retdesc =  "帐号不存在" 
		return cmd
	end
	uniplatform.modifyaccountpassword(uid, newPassword, uid)
	cmd.data.retcode = 0
	return cmd
end

-- --查询vip列表
-- GmSvr.PmdStRequestVipListInfoPmd_CS = function(cmd, laccount)

-- 	local curpage 		= cmd.data.curpage
-- 	local perpage 		= cmd.data.perpage
-- 	local maxpage = 0
-- 	local datas = {}

-- 	if curpage == 0 then
-- 		curpage = 1
-- 	end

--     local filter = nil
--     if cmd.data.charid ~= 0 then
--         filter = unilight.eq("uid", cmd.data.charid)
--     elseif cmd.data.charname ~= "" then
--         filter = unilight.RegEx("base.nickname", cmd.data.charname)
--     elseif cmd.data.viplevel  ~= 0 then
--         filter = unilight.eq("property.vipLevel", cmd.data.viplevel)
-- 	else
-- 		filter = unilight.gt("property.vipLevel", 0)
--     end
--     local allNum = unilight.startChain().Table("userinfo").Filter(filter).Count()

--     maxpage = math.ceil(allNum/perpage)
--     local userInfos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
--     for i,v in ipairs(userInfos) do
--         local ret, _, data = ChessGmUserInfoMgr.GetUserVipInfo(v.uid)
--         if ret == 0 then
--             table.insert(datas, data)
--         end			
--     end

--     filter = unilight.gt("property.vipLevel", 0)

--     local vipNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
--     cmd.data.viptotalnum = vipNum
-- 	cmd.data.maxpage = maxpage
-- 	cmd.data.datas = datas
-- 	return cmd

-- end

--兑换审核
GmSvr.PmdStRequestConvertVerifyPmd_CS = function(cmd, laccount)


	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local optype  = cmd.data.optype
    local opvalue = cmd.data.opvalue
    local filter =  unilight.gt("uid", 0)
    local filterStr = '"uid":{"$gt":' .. 0 .. '}'


    local filterStr2 = '"userinfo.base.regFlag":{"$gt":' .. 0 .. '}'
    if cmd.data.regflag > 0 then
        filterStr2 = '"userinfo.base.regFlag":{"$eq":' .. cmd.data.regflag .. '}'
    end

    local filterStr1 = '"uid":{"$gte":' .. 0 .. '}'
    if cmd.data.subplatid > 0 then
        filterStr1 = '"subplatid":{"$eq":' .. cmd.data.subplatid .. '}'
    end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filterStr1 = filterStr1 .. ', "timestamp":{"$gte":' .. starttime .. ', "$lt":'..endtime..'}'
    end

    if cmd.data.subplatid > 0 then
        filterStr1 = filterStr1 .. ', "subplatid":{"$eq":' .. cmd.data.subplatid .. '}'
        filter =  unilight.a(filter, unilight.eq("subplatid", cmd.data.subplatid))
    end

    if cmd.data.ordertype > 0 then
        filter =  unilight.a(filter, unilight.eq("orderType", cmd.data.ordertype))
        filterStr1 = filterStr1 .. ', "orderType":{"$eq":' .. cmd.data.ordertype .. '}'
    end

    --拉取列表
    if optype == 1 then

        --全部成功提现金额
        local tmpFilterStr = filterStr1 .. ', "state":{"$in":['.. 6 .. ', '.. 3 ..']}'
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{"state":6}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
        ]]
        local successchips = 0
        if table.len(info)  > 0  then
            successchips = info[1].sum
        end

        --待审核
        local tmpFilterStr = filterStr1 .. ', "state":{"$eq":' .. 1 .. '}'
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{"state":1}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
        ]]
        local waitcheckchips = 0
        if table.len(info)  > 0  then
            waitcheckchips = info[1].sum
        end

        --审核中
        local tmpFilterStr = filterStr1 .. ', "state":{"$eq":' .. 5 .. '}'
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{"state":5}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
        ]]
        local checkchips = 0
        if table.len(info)  > 0  then
            checkchips = info[1].sum
        end

        --全部失败提现金额
        local tmpFilterStr = filterStr1 .. ', "state":{"$eq":' .. 7 .. '}'
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{"state":7}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
        ]]
        local failchips = 0
        if table.len(info)  > 0  then
            failchips = info[1].sum
        end

        --全部失败提现金额
        local tmpFilterStr = filterStr1 .. ', "state":{"$eq":' .. 2 .. '}'
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate('{"$match":{'..tmpFilterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'))
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{"state":2}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
        ]]
        local refusechips = 0
        if table.len(info)  > 0  then
            refusechips = info[1].sum
        end

        local orderBy   ={unilight.desc("timestamp")}
        if cmd.data.charid ~= 0 then
            filter =  unilight.a(filter, unilight.eq("uid", cmd.data.charid))
            -- filterStr1 = filterStr1 .. ', "uid":{"$eq":' .. cmd.data.charid .. '}'
        end

        if cmd.data.orderid ~= 0 then
            filter =  unilight.a(filter, unilight.eq("_id", cmd.data.orderid))
            -- filterStr1 = filterStr1 .. ', "_id":{"$eq":' .. cmd.data.orderid .. '}'
        end
        if cmd.data.status ~= 0 then
            filter =  unilight.a(filter, unilight.eq("state", cmd.data.status))
            -- filterStr1 = filterStr1 .. ', "state":{"$eq":' .. cmd.data.status .. '}'
        else
            filter =  unilight.a(filter, unilight.neq("state", WithdrawCash.STATE_IGNORE))
            -- filterStr1 = filterStr1 .. ', "state":{"$ne":' .. WithdrawCash.STATE_IGNORE .. '}'
        end

        if cmd.data.cpf ~= "" then
            filter =  unilight.a(filter, unilight.eq("cpf", cmd.data.cpf))
            -- filterStr1 = filterStr1 .. ', "cpf":{"$eq":"' .. cmd.data.cpf .. '"}'
        end
        if cmd.data.realname ~= "" then
            filter =  unilight.a(filter, unilight.eq("name", cmd.data.realname))
            -- filterStr1 = filterStr1 .. ', "name":{"$eq":"' .. cmd.data.realname .. '"}'
        end

    if string.len(cmd.data.begintime) > 0 and string.len(cmd.data.endtime) > 0 then
        local starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        local endtime   = chessutil.TimeByDateGet(cmd.data.endtime)
        filter = unilight.a(filter,unilight.a(unilight.ge('timestamp',starttime), unilight.le('timestamp',endtime)))
    end
        --[[
        uid = uid,                                                          -- 玩家ID
        orderType = orderType,                                              -- 订单类型     1 兑换提现  2 推广提现
        name = withdrawCashInfo.name,                                       -- 玩家姓名
        cpf = withdrawCashInfo.cpf,                                         -- CPF
        chavePix = withdrawCashInfo.chavePix,                               -- chavePix
        chavePixNum = withdrawCashInfo.flag,                                -- chavePix类型  0 只有姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
        moedas = moedas,                                                    -- 消耗金币
        dinheiro = dinheiro,                                                -- 提现金额
        times = chessutil.FormatDateGet(),                                  -- 订单申请时间
        state = STATE_WAIT_REVIEW,                                          -- 订单当前状态 1.待审核， 2.已拒绝 3.兑换成功, 4.兑换失败, 5.审核中, 6.订单完成
        orderId = "",                                                       -- 平台订单号
        channel = "",                                                       -- 通道名
        --]]


        local allNum = 0
        local allNum = unilight.startChain().Table("withdrawcash_order").Filter(filter).Count()
        --[[
        local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{'.. filterStr ..'}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}', '{"$group":{"_id":null, "sum":{"$sum":1}}}'  ))
        ]]
        -- if table.len(info) > 0 then
            -- allNum = info[1].sum
        -- end
        maxpage = math.ceil(allNum/perpage)

        --[[
        local covertInfos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
        '{"$match":{'.. filterStr ..'}}','{"$lookup":{"from":"userinfo","localField":"uid", "foreignField":"_id", "as":"userinfo" }}','{"$match":{'..filterStr2..'}}','{"$project":{"userinfo.daySign":0, "userinfo.shareInfo":0, "userinfo.point":0, "userinfo.status":0,"userinfo.superSale":0,"userinfo.gameInfo":0, "userinfo.savingPot":0,"userinfo.property":0}}',  '{"$sort": {"times": -1}}', '{"$skip": '..(curpage-1)*perpage..'}', '{"$limit": '..perpage..'}'))
        ]]
        local covertInfos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(filter).OrderBy(unpack(orderBy)).Skip((curpage-1)*perpage).Limit(perpage))
        local point = 1
        for i,covertInfo in ipairs(covertInfos) do

            local userInfo = chessuserinfodb.RUserInfoGet(covertInfo.uid)
            local withdrawcashInfo = WithdrawCash.GetWithdrawcashInfo(covertInfo.uid)
            local cpfInfo = WithdrawCash.ChangeWithdrawcashCpfInfo(covertInfo.uid, "", "", "")
			local nickName = ""
			local cpf      = cpfInfo.cpf
            local realName = cpfInfo.name
			if userInfo ~= nil then
				nickName = userInfo.base.nickname
			end
            local phoneNum = ""
            local mail     = ""

            if covertInfo.chavePixNum == 1 then
                phoneNum = covertInfo.chavePix
            elseif covertInfo.chavePixNum == 2 then
                mail = covertInfo.chavePix
            end

            local finishtime = ""
            if covertInfo.finishTimes ~= nil and covertInfo.finishTimes > 0 then
                finishtime = chessutil.FormatDateGet(covertInfo.finishTimes)
            end
            -- local platname = ""
            -- if covertInfo.payPlatId ~= nil and covertInfo.payPlatId ~= 0 then
            --     local table_withdraw_plat = import "table/table_withdraw_plat"
            --     if table_withdraw_plat[covertInfo.payPlatId] ~= nil then
            --         platname = table_withdraw_plat[covertInfo.payPlatId].desc
            --     end
            -- end
            local platname = covertInfo.paytype or ""
            local info = {

                orderid      = covertInfo._id,     --兑换编号
                time         = chessutil.FormatDateGet(covertInfo.timestamp),    --兑换时间
                charid       = covertInfo.uid,   --玩家id
                charname     = nickName,    		   --玩家姓名
                realname     = realName,         --玩家真实姓名 
                cfp          = cpf,    				   --cpf信息
                orderchips   = covertInfo.dinheiro,    --兑换订单金额
                consumechips = covertInfo.moedas,      --消耗金币
                status       = covertInfo.state,    --状态
                ordertype    = covertInfo.orderType,  --兑换类型
                phonenum     = phoneNum,     --//电话号码
                email        = mail ;   --//邮箱
                typeMap      = covertInfo.chavePixNum or "",  --  //通道类型 1.CPF 2.电话 3邮箱
                totalrechargechips   = userInfo.property.totalRechargeChips,-- //总充值
                totalcovertchips    = userInfo.status.chipsWithdraw, --累计兑换金额(不包含推广)
                promotionwithdrawchips = userInfo.status.promoteWithdaw,  --推广提现累计金额
                regflag      = userInfo.base.regFlag,         --注册来源
                finishtime   = finishtime, --提现成功时间
                platname     = platname,   --提现渠道
            }
            if covertInfo.state == 1 then
                table.insert(datas, point, info)
                point = point + 1
            else
                table.insert(datas, info)
            end
        end

        cmd.data.maxpage = maxpage
        cmd.data.datas = datas
        cmd.data.successchips = successchips
        cmd.data.checkchips = checkchips
        cmd.data.waitcheckchips = waitcheckchips
        cmd.data.failchips = failchips
        cmd.data.refusechips = refusechips
        return cmd
    --同意、拒绝
    elseif optype == 2 then
        filter =  unilight.eq("_id", cmd.data.orderid)
        local covertInfos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(filter))	
        if table.len(covertInfos) == 0 then
            cmd.data.retcode = 1 
            cmd.data.retdesc =  "找不到订单:" ..cmd.data.orderid
            return cmd
        end

        if unilight.islobbyserver()  == false then
            cmd.data.retcode = 1 
            cmd.data.retdesc =  "请在大厅服务器进行操作"
            return cmd
        end

        local covertInfo = covertInfos[1]
        --只允许操作，忽略的订单和等等的订单
        if covertInfo.state == WithdrawCash.STATE_WAIT_REVIEW or 
            covertInfo.state == WithdrawCash.STATE_IGNORE or 
            covertInfo.state == WithdrawCash.STATE_UNDER_REVIEW then
            --同意
            if opvalue == 0 then
                WithdrawCash.ChangeState(cmd.data.orderid, WithdrawCash.STATE_UNDER_REVIEW)
                unilight.info(string.format("gm同意玩家提现成功: orderid=%s",cmd.data.orderid))
            elseif opvalue == 1 then
                --拒绝
                WithdrawCash.ChangeState(cmd.data.orderid, WithdrawCash.STATE_REFUSE)

                unilight.info(string.format("gm拒绝玩家提现: orderid=%s",cmd.data.orderid))
                --忽略(只有初始状态才可以忽略)
            elseif opvalue == 2 and covertInfo.state == WithdrawCash.STATE_WAIT_REVIEW then
                WithdrawCash.ChangeState(cmd.data.orderid, WithdrawCash.STATE_IGNORE)
                unilight.info(string.format("gm忽略玩家提现: orderid=%s",cmd.data.orderid))
            end
            cmd.data.retcode = 0 
            cmd.data.retdesc =  "操作成功"
            return cmd
        else

            cmd.data.retcode = 1 
            cmd.data.retdesc =  "订单状态必须为待审核、拒绝、审核中"
            return cmd
        end
    end


end


--在线玩家信息
GmSvr.PmdStRequestOnlineListInfoPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
    local data = cmd.data
	local maxpage = 0
	local datas = {}

	-- if curpage == 0 then
	-- 	curpage = 1
	-- end
    --回送数据
    local lobbyonline = 0       --大厅在线人数
    local curonline = 0         --当前在线人数
    local gameonline = 0        --游戏在线人数
    local datas={}
    --投放标志
    local regflag = data.regflag
    --1 充值玩家  2非充值玩家
    local rechargeflag = data.rechargeflag
    local checkAdd=function(rInfo)
       if regflag>0 then
            if rInfo.regFlag~=regflag then
                return false
            end
       end
       if rechargeflag==1 then
            if rInfo.totalRechargeChips<=0 then
                return false
            end
       elseif rechargeflag==2 then
            if rInfo.totalRechargeChips>0 then
                return false
            end
       end
       return true
    end
    for uid,uValue in pairs(backRealtime.lobbyOnlineUserManageMap) do
        if uValue.zone.gameid==1001 then
            lobbyonline=lobbyonline+1
        else
            local zone = uValue.zone
            local rInfo = uValue.rInfo
            local zoneId =  zone.zoneid
            local subgameid = math.floor(zoneId/100)
            if checkAdd(rInfo) then
                table.insert(datas,{
                    uid=rInfo.uid,
                    chips = rInfo.chips,
                    totalRechargeChips=rInfo.totalRechargeChips,
                    chargeMax = rInfo.chargeMax,
                    statement=rInfo.statement,
                    totalWithdrawal=rInfo.totalWithdrawal,
                    rtp=rInfo.rtp,
                    autocontroltype=rInfo.autocontroltype,
                    controlvalue=rInfo.controlvalue,
                    subgameid=subgameid,
                    enterchip=uValue.enterchip,
                    regFlag=rInfo.regFlag,
                })
            end
            gameonline=gameonline+1
        end
        curonline=curonline+1
    end
    --datas 按充值金额排序
    table.sort(datas,function(a,b)
        return a.totalRechargeChips>b.totalRechargeChips
    end)
    local skip = (curpage-1)*perpage
    local endNum = skip + perpage
    skip = skip+1
    if endNum>#datas then
        endNum = #datas
    end
    local resdata={}
    for i=skip,endNum do
        table.insert(resdata,datas[i])
    end
    maxpage = math.ceil(#datas/perpage)
    --执行返回
    cmd.data.retcode = 0 
    cmd.data.retdesc =  "操作成功"
	cmd.data.maxpage      = maxpage
	cmd.data.datas        = resdata
	cmd.data.curonline    = curonline
    cmd.data.lobbyonline  = lobbyonline
    cmd.data.todayonline  = 0
    cmd.data.yestedayline = 0
    cmd.data.registernum  = unilight.startChain().Table("userinfo").Count()

    return cmd

    -- local todayOnline, yestedayOnline = annagent.GetOnlineInfo()
    -- local registerAll = unilight.startChain().Table("userinfo").Filter(unilight.field("uid").Gt(0)).Count()
    

    -- ----------------------
    -- -- local game_zone_online_list = annagent.GetOnlineUids()
    -- -- local game_zone_online_list = unilight.redis_getdata(Const.REDIS_HASH_NAME.ONLINE_INFO)
    -- local game_zone_online_list = unilight.redis_getdata(Const.REDIS_HASH_NAME.ONLINE_INFO)
    -- if game_zone_online_list == "" then
    --     game_zone_online_list = {}
    -- else
    --     game_zone_online_list = json2table(game_zone_online_list)
    -- end

    -- local uids = {}
    -- local lobbyuids = {}
    -- for gameId, zone_online_list in pairs(game_zone_online_list) do
    --     for zoneId, online_list in pairs(zone_online_list) do
    --         for _, userInfo in ipairs(online_list) do
    --             --大厅人数单独统计
    --             if gameId == Const.GAME_TYPE.LOBBY then
    --                 table.insert(lobbyuids, userInfo.uid)
    --             else
    --                 local newInfo = {}

    --                 --查询具体游戏
    --                 if data.subgameid > 0  then
    --                     newInfo.subGameId = data.subgameid
    --                 end
    --                 --查询初中高级场
    --                 if data.gametype > 0 then 
    --                     newInfo.subGameType = data.gametype
    --                 end

    --                 if data.regflag > 0  then
    --                     newInfo.regFlag = data.regflag
    --                 end

    --                 if data.rechargeflag > 0 then
    --                     newInfo.rechargeFlag = data.rechargeflag
    --                 end

    --                 if data.subplatid > 0 then
    --                     newInfo.subplatid = data.subplatid
    --                 end

    --                 if table.empty(newInfo) then
    --                     table.insert(uids, userInfo.uid)
    --                 else
    --                     local bFind = true
    --                     for k, v in pairs(newInfo) do
    --                         if userInfo[k] ~= v then
    --                             bFind = false
    --                             break
    --                         end
    --                     end

    --                     if bFind then
    --                         table.insert(uids, userInfo.uid)
    --                     end
    --                 end

    --             end

    --         end
    --     end
    -- end

    -- table.sort(uids)

    -- --查找指定玩家
    -- if cmd.data.charid ~= nil and cmd.data.charid > 0 then
    --     for _, uid in pairs(uids) do
    --         if uid == cmd.data.charid then
    --             local ret, _, data = ChessGmUserInfoMgr.GetUserOnlineInfo(uid)
    --             if ret == 0 then
    --                 table.insert(datas, data)
    --             end
    --             break
    --         end
    --     end
    -- else
    --     maxpage = math.ceil(#uids/perpage)
    --     for i=(curpage-1)*perpage + 1, curpage*perpage do
    --         if i > #uids then
    --             break
    --         end
    --         local ret, _, data = ChessGmUserInfoMgr.GetUserOnlineInfo(uids[i])
    --         if ret == 0 then
    --             table.insert(datas, data)
    --         end
    --     end

    -- end

    -- --[[
    -- local onlineinfo = go.gameonlineinfo
    -- local totalOnlineNum  = 0

    -- for gameId, onlineNum  in pairs(onlineinfo) do
    --     totalOnlineNum = totalOnlineNum + onlineNum
    -- end
    -- ]]

    -- cmd.data.retcode = 0 
    -- cmd.data.retdesc =  "操作成功"

	-- cmd.data.maxpage      = maxpage
	-- cmd.data.datas        = datas
	-- cmd.data.curonline    = table.len(uids)
    -- cmd.data.lobbyonline  = table.len(lobbyuids)
    -- cmd.data.todayonline  = todayOnline
    -- cmd.data.yestedayline = yestedayOnline
    -- cmd.data.registernum  = registerAll
    -- return cmd
end


--查找下级
GmSvr.PmdStPlayerPromoteInfoGmUserPmd_CS = function(cmd, laccount)
	if cmd.data == nil or cmd.data.charid == nil or cmd.data.charid <= 0 then
		unilight.error("下级ID未输入 有误")
		return cmd
	end
    local filter = unilight.gt('uid',0)
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
    end
    local order = unilight.desc("initTime")
    local infoNum = unilight.startChain().Table('userinfo').Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            newuser = 0,
            activeuser = 0,
            childrechargenum = 0,
            childwithdrawnum = 0,
            data = {},
        }
    }
    -- 查找下级
    local childinfos = unilight.chainResponseSequence(unilight.startChain().Table('rebateItem').Filter(filter))
    -- 遍历信息
    for _, childinfo in ipairs(childinfos) do
        -- 查找下级玩家数据
        local filter = unilight.eq('_id',childinfo.childId)
        local userinfo = unilight.chainResponseSequence(unilight.startChain().Table('userinfo').Filter(filter))[1]
        -- 查到下级插入数据
        if table.empty(userinfo) == false then
            -- 下级类型 默认未提供过
            local usertype = 3
            if userinfo.status.onlyRegister == 2 and userinfo.status.onlyPlayerRegister == 0 then
                usertype = 2
            elseif userinfo.status.onlyRegister == 0 and userinfo.status.onlyPlayerRegister == 2 then
                usertype = 1
                res.data.activeuser = res.data.activeuser + 1
            elseif userinfo.status.onlyRegister == 2 and userinfo.status.onlyPlayerRegister == 2 then
                usertype = 1
                res.data.activeuser = res.data.activeuser + 1
            end
            table.insert(res.data.data,{
                charid          = userinfo._id,                                                                 -- 下级id
                usertype        = usertype,                                                                     -- 下级类型 3.未返利用户, 1.活跃用户，2.新用户,
                betchips        = userinfo.gameData.slotsBet,                                                   -- 下线下注金额
                rechargechips   = userinfo.property.totalRechargeChips,                                         -- 下线充值金额
                withdrawmoney   = tostring(userinfo.status.chipsWithdraw + userinfo.status.promoteWithdaw),     -- 下线提现金额
                bindstamp       = chessutil.FormatDateGet(childinfo.bindTime),                                  -- 下线绑定日期
                totalrebate     = childinfo.totalrebate or 0,                                                   -- 下线总返利   充值+团队
            })
            res.data.childrechargenum = res.data.childrechargenum + userinfo.property.totalRechargeChips
            res.data.childwithdrawnum = res.data.childwithdrawnum + userinfo.status.chipsWithdraw + userinfo.status.promoteWithdaw
        end
    end
    return res
end

--查询周卡列表
GmSvr.PmdStRequestWeekInfoGmPmd_CS = function(cmd, laccount)

	local curpage 		= cmd.data.curpage
	local perpage 		= cmd.data.perpage
	local maxpage = 0
	local datas = {}

	if curpage == 0 then
		curpage = 1
	end

    local DB_Name = "weeklycard"

    local filter = unilight.o(unilight.gt("silverTotalBuyNum", 0), unilight.gt("goldTotalBuyNum", 0))
    if cmd.data.charid ~= 0 then
        filter = unilight.a(unilight.eq("_id", cmd.data.charid))
    end

    local allNum = unilight.startChain().Table(DB_Name).Filter(filter).Count()

    maxpage = math.ceil(allNum/perpage)
    local userInfos = unilight.chainResponseSequence(unilight.startChain().Table(DB_Name).Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
    for i,v in ipairs(userInfos) do
        local cardInfo = WeeklyCard.GetPlayerWeeklyCardInfo(v._id)
        local userInfo = chessuserinfodb.RUserInfoGet(v._id)
	
        table.insert(datas, {
            charid              = v._id,  --    //玩家id
            charname            = userInfo.base.nickname, --    //玩家名字 
            silverendtime       = cardInfo.silverFailureTime, --    //银卡失效日期
            silverrecharge      = cardInfo.silverTotalBuyNum, --    //银卡累计充值金额 
            silvergetchips      = cardInfo.silverTotalGetNum, --   //银卡累计领取金额 
            goldendtime         = cardInfo.goldFailureTime, --   //金卡失效日期
            goldrecharge        = cardInfo.goldTotalBuyNum, --    //金卡累计充值金额
            goldgetchips        = cardInfo.goldTotalGetNum, --    //金卡累计领取金额 
            goldbuytime       = v.silverBuyTime, --    //金卡购买时间
            silverbuytime         = v.goldBuyTime, --   //银卡购买时间
        })
    end

    --总共人数
    filter = unilight.gt("goldTotalBuyNum", 0)
    local allgoldbuy = unilight.startChain().Table(DB_Name).Filter(filter).Count()
    filter = unilight.gt("silverTotalBuyNum", 0)
    local allsilverbuy = unilight.startChain().Table(DB_Name).Filter(filter).Count()

    --当前人数
    filter = unilight.eq("goldBuyFlag", true)
    local curgoldbuy = unilight.startChain().Table(DB_Name).Filter(filter).Count()
    filter = unilight.eq("silverBuyFlag", true)
    local cursilverbuy = unilight.startChain().Table(DB_Name).Filter(filter).Count()

    cmd.data.silverbuynum         = allsilverbuy --    银卡购买总人数         
    cmd.data.goldbuynum           = allgoldbuy --    金卡购买总人数         
    cmd.data.silvercurnum         = cursilverbuy --  当前银卡人数
    cmd.data.goldcurnum           = curgoldbuy --    当前金卡人数

    cmd.data.viptotalnum = vipNum
	cmd.data.maxpage = maxpage
	cmd.data.datas = datas
	return cmd

end
