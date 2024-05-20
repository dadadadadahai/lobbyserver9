module("ChessGmUserInfoMgr", package.seeall)

-- 通过玩家id获取 玩家信息
function GetUserInfo(uid, userInfo)
	if userInfo ~= nil then
		uid = userInfo.uid
	end
	ChessGmUserInfoMgr.CheckUserPunish(uid, Const.BAN_TYPE.CONTROL)
	userInfo = userInfo or chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		return 2, "角色不存在"
	end
    local withdrawcashInfo = WithdrawCash.GetWithdrawcashInfo(uid)
    local cpfInfo = WithdrawCash.ChangeWithdrawcashCpfInfo(uid, "", "", "")
	


	local data              = {}
	data.charname           = userInfo.base.nickname
	data.plataccount        = userInfo.base.plataccount
	data.charid             = userInfo.uid
	data.lastofftime        = chessutil.FormatDateGet(userInfo.status.logoutTime)             --上次离线时间
    data.logintime          = userInfo.status.logintime             --登陆时间
	data.createtime         = userInfo.status.registertime          --注册时间
	data.isonline           = 0                                     --是否在线
	data.gmlevel            = 0                                     --gm等级
	data.profession         = 0                                     --职业
	data.money              = 0                                     --x币
	data.totalwin           = 0                                     --总共赢次数
    data.cpf                = cpfInfo.cpf                     		--巴西个税号
    data.savingpot_silver   = 0                                     --存钱罐银总提现 todo等待白云兴
    data.savingpot_gold     = 0                                     --存钱罐金总提现todo等待白云兴
    data.viplevel           = userInfo.property.vipLevel            --vip等级
    data.registip           = userInfo.status.registerIp            --注册ip
    data.lastloginip        = userInfo.status.lastLoginIp           --上次登陆ip
    data.lastloginimei      = userInfo.status.lastLoginImei         --上次登陆机器码
    data.registersrc        = userInfo.status.registerSrc           --注册来源
    data.loginnum           = userInfo.status.loginNum              --登陆次数
    data.totalrechargechips = userInfo.property.totalRechargeChips  --总充值金币
    data.signnum            = 0               --签到次数
    data.banstatus          = 0                                     --封号状态
    data.realname           = cpfInfo.name                          --真实姓名
    data.mail               = cpfInfo.chavePix                      --提现mail
    data.logouttime         = chessutil.FormatDateGet(userInfo.status.logoutTime)            --离线时间
    data.riskflag           = userInfo.status.riskFlag              --风险标识
    data.traceinfo          = userInfo.status.traceInfo             --追踪信息
    data.controlvalue       = userInfo.point.controlvalue           --点控值
    data.phonenum           = userInfo.base.phoneNbr                --手机号码
    data.totalcovertchips   = userInfo.status.chipsWithdraw --; //累计兑换金额(不包含推广)
    data.cancovertchips     = withdrawcashInfo.cancovertchips --; //可兑换额度
    data.parentinviter      = chessuserinfodb.GetParentUid(uid, true) --; //玩家上级ID
    data.inviternum         = userInfo.status.childNum or 0 -- //下级总人数
    data.promotionchips     = chessuserinfodb.GetRebateChips(uid) --; //推广收入余额 
    data.promotionwithdrawchips = userInfo.status.promoteWithdaw -- //推广提现累计金额 
    data.money            = userInfo.property.diamond      --当前银币
    data.chipwithdrawnum        = userInfo.status.chipsWithdrawNum  -- //金币提现次数
    data.promotewithdrawnum     = userInfo.status.promoteWithdawNum --  //推广提现次数
    data.chipwithdraw           = userInfo.status.chipsWithdraw-- //金币提现金额
    data.promotewithdraw        = userInfo.status.promoteWithdaw-- //推广提现金额
    data.rechargenum            = userInfo.status.rechargeNum -- //充值次数
    local transSilver, transGold = cofrinho.GetTchange(uid)
    data.goldrecovertnum        = transSilver or 0 -- //银币累计兑换值
    data.transgold              = transGold or 0 -- //转换金币
    data.chavepix               = withdrawcashInfo.chavePix or ""   -- pix
    data.regflag                = userInfo.base.regFlag or 2        --投放来源
    data.subplatid              = userInfo.base.subplatid           --子渠道id
    data.kill_chips_max         = "" -- //上限点杀
	data.isdownapk				= 0
	data.cashoutrunning			= cpfInfo.statement									-- 提现需要打完的流水
	data.cashoutphonenum		= cpfInfo.telephone									-- 提现的CPF-手机号
	data.cashoutemail			= cpfInfo.email										-- 提现的CPF-邮箱
	data.rewardactivities		= userInfo.property.totalbadgechips					-- 等级签到金币
	data.redenveloperain		= userInfo.property.totalredrainchips				-- 红包雨金币
	data.lossrebate				= userInfo.property.totallossrebatechips			-- 损失返利金币
	data.redemptioncode			= userInfo.property.totalredeemcodechips			-- 兑换码金币
	data.vipreward				= userInfo.property.totalvipchips					-- vip奖励金币
	data.activities				= userInfo.property.totalactivitychips				-- 活动领取金币
	data.luckyuser				= userInfo.property.totalluckplayerchips			-- 幸运玩家领取金币
	data.invitergold			= userInfo.property.totalvalidinvitechips			-- 邀请返利金币
	data.inviterteamgold		= userInfo.property.totalteamrebatechips			-- 团队返利金币
	data.turntable				= userInfo.property.totalturntablechips				-- 普通转盘金币
	data.rewardactivites	 	= userInfo.property.totalntaskchips					-- 新任务金币
	data.autocontroltype = userInfo.point.autocontroltype
	local inviteroulettelogInfo = InviteRoulette.GetInviteRouletteRechargeInfo(uid)
	data.turninviternum			= inviteroulettelogInfo.rechargeUserNum
	data.turninvitergold		= inviteroulettelogInfo.inviterRechargeNum
	data.presentChips 			= userInfo.property.presentChips					-- 假金币


	-- 判断玩家是否下载过APK
	if userInfo.status.loginPlatIds ~= nil then
		for _, loginPlatId in ipairs(userInfo.status.loginPlatIds) do
			-- if loginPlatId == 3 or loginPlatId == 4 then
			if userInfo.status.loginPlatIds[1] <= 2 and (loginPlatId == 3 or loginPlatId == 4) then
				data.isdownapk = 1
				break
			end
		end
	end
	if userInfo.base.imei ~= nil then
		data.imei = userInfo.base.imei
		data.osname = userInfo.base.osname
	end
    if ChessGmUserInfoMgr.CheckUserPunish(uid, 3) then
        data.banstatus  = 1
    end

	local laccount = go.accountmgr.GetAccountById(uid)
	if laccount ~= nil then
		if laccount.LastActiveTime > 0 then
			data.isonline = 1 
		end
		data.gmlevel = laccount.GetGmlevel()
	end

    data.glodnum         = userInfo.property.chips

	-- data.bankglodnum     = userInfo.bank.chips
    data.slotscount      = userInfo.gameData.slotsCount or 0
    data.rtpxs           = userInfo.point.cTolxs or 0 --rtp系数
    data.maxmul          = userInfo.point.maxMul or 0 --最大倍数
    data.slotsbet        = userInfo.gameData.slotsBet or 0 --//slots总押注
    data.slotswin        = userInfo.gameData.slotsWin or 0-- //slots总返现
    data.hundrebet       = userInfo.gameData.hundreBet or 0-- //百人总押注
    data.hunderwin       = userInfo.gameData.hunderWin or 0-- //百人总返现
    data.presentchips    = userInfo.property.presentChips or 0 --赠送金币
    data.freecontroltype = userInfo.point.FreeControlType or 0 --//0 未初始化 1玩家处于放分 2玩家处于收分
    data.nochargemax     = userInfo.point.noChargeMax or 0--//高点
    data.nochargemin     = userInfo.point.noChargeMin or 0-- //低点
    data.chargemax       = userInfo.point.chargeMax   or 0  --最大金币上限
	data.chargeMax = userInfo.point.chargeMax or 0
	data.rtp = 0
	data.statement = cpfInfo.statement			
	--判断玩家在线状态
	local onlineUserInfo =  backRealtime.lobbyOnlineUserManageMap[uid]
	if onlineUserInfo~=nil then
		local rInfo = onlineUserInfo.rInfo
		data.chargeMax = rInfo.chargeMax
		data.totalrechargechips = rInfo.totalRechargeChips
		data.controlvalue = rInfo.controlvalue
		data.rtp = rInfo.rtp
		data.autocontroltype = rInfo.autocontroltype
		data.statement = rInfo.statement
		data.slotsbet = rInfo.slotsBet
		data.slotswin = rInfo.slotsWin
	end

    --[[
	-- 填充 玩家已发送未被领取的红包总金额
	local notRecv = 0
	-- 由于该账号用于发送新手礼包 所以数据量过大 直接过滤
	if uid ~= 20916796 then
		-- 获取所有 发送并未被领取的红包记录
		local filter = unilight.a(unilight.eq("srcuid", uid), unilight.eq("bok", 0))
		local sendRecord = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter)) or {}
		for i,v in ipairs(sendRecord) do
			notRecv = notRecv + v.chips
		end
	end
	data.notrecv = notRecv
    ]]

	return 0, "获取玩家信息成功" , data
end

-- 通过玩家id获取 玩家vip信息
function GetUserVipInfo(uid, userInfo)
	if userInfo ~= nil then
		uid = userInfo.uid
	end
	ChessGmUserInfoMgr.CheckUserPunish(uid, Const.BAN_TYPE.CONTROL)
	userInfo = userInfo or chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		return 2, "角色不存在"
	end
	-- local vipUpdateInfo = nvipmgr.GetVipDetailInfo(uid)
    -- local vipInfo = nvipmgr.GetVipDetailInfo(uid)
    local updatetime = 0
	local weeklevel = 0
	local weekoverday = 0
	local weekgetchips = 0
    local convertchips = WithdrawCash.QueryTotalWithdrawal(uid)
    -- local vipInfo = nvipmgr.GetVipCardInfo(uid) or {}                         --vip信息
    local vipInfo = nvipmgr.Get(uid)

    local endDays = chessutil.GetMorningDayNo(weekoverday)
    local nowDays = chessutil.GetMorningDayNo(os.time())

    local weekTotalChips = 0

    local filterStr = '"uid":{"$eq":' .. uid .. '}'
    local taotalInfo = unilight.chainResponseSequence(unilight.startChain().Table("weekCardLog").Aggregate('{"$match":{'..filterStr..'}}','{"$group":{"_id":null, "sum":{"$sum":"$recvMoney"}}}'))
    if table.len(taotalInfo) > 0 then
        weekTotalChips = taotalInfo[1].sum
    end

	local data              = {}
	data.charname           = userInfo.base.nickname
	data.charid             = uid
    data.viplevel           = userInfo.property.vipLevel
    data.updatetime         = vipInfo.updatetime or 0          --升级时间
    data.weeklevel          = weeklevel or 0           --周卡级别
    data.weekoverday        = endDays - nowDays         --周卡剩余时间
    data.weekgetchips       = weekTotalChips        --周卡领取金额
    data.rechargechips      = userInfo.property.totalRechargeChips                     --累计充值金额
    data.convertchips       = convertchips or 0         --累计提现金额

    data.daychips            = vipInfo.day or 0 --   //每日累计领取金额
    data.weekchips           = vipInfo.week or 0 --   //每周累计累取金额
    data.monthchips          = vipInfo.month or 0 --   //每月累计领取金额
    data.specialchips        = vipInfo.other or 0 --   //特殊累计领取金额
    data.weeklevel           = vipInfo.weekLevel or 0 --周卡级别
    return 0, "获取玩家vip信息成功" , data
end


-- 通过玩家id获取 玩家vip信息
function GetUserOnlineInfo(uid, userInfo)
	if userInfo ~= nil then
		uid = userInfo.uid
	end
    ChessGmUserInfoMgr.CheckUserPunish(uid, Const.BAN_TYPE.CONTROL)
	userInfo = userInfo or chessuserinfodb.RUserInfoGet(uid)
	local withdrawcashInfo = WithdrawCash.GetWithdrawcashInfo(uid)
	if userInfo == nil then
		return 2, "角色不存在"
	end
	local data              = {}
    local gameInfo = userInfo.gameInfo
    data.charid              = uid--    //玩家id
    data.charname            = userInfo.base.nickname    --//玩家名字
    data.enterchips          = gameInfo.loginChips    --//进入携带金币
    data.curchips            = userInfo.property.chips    --//当前金币
    data.changechips         = userInfo.property.chips - gameInfo.loginChips    --//金币变化
    data.viplevel            = userInfo.property.vipLevel    --//vip等级
    data.gameid              = gameInfo.subGameId    --//当前游戏
    data.gametype            = gameInfo.subGameType    --//游戏类型
    data.jointime            = chessutil.FormatDateGet(gameInfo.intoTime)    --//进入时间
    data.joinip              = userInfo.status.lastLoginIp   --//进入ip
    data.controlvalue        = userInfo.point.controlvalue
    data.cancovertchips     = withdrawcashInfo.cancovertchips --; //可兑换额度
    data.totalrechargechips =  userInfo.property.totalRechargeChips  --总充值金币
    data.totalcovertchips   = userInfo.status.chipsWithdraw --; //累计兑换金额(不包含推广)
    data.promotionwithdrawchips = userInfo.status.promoteWithdaw -- //推广提现累计金额 
    data.rechargenum         = userInfo.status.rechargeNum -- //充值次数
    data.chipswithdrawnum    = userInfo.status.chipsWithdrawNum -- //金币提现次数
    data.promotewithdrawnum  = userInfo.status.promoteWithdawNum --推广提现 
    data.regflag             = userInfo.base.regFlag or 2        --投放来源
    data.betMoney            = userInfo.property.betMoney --当前下注金额
    data.subplatid           = userInfo.base.subplatid     --子渠道id
    data.kill_chips_max         = "" -- //上限点杀
    data.slotscount          = userInfo.gameData.slotsCount or 0  --游戏局数
    data.rtpxs = userInfo.point.cTolxs or 0 --rtp系数
    data.maxmul = userInfo.point.maxMul or 0 --最大倍数
    data.slotsbet               = userInfo.gameData.slotsBet or 0 --//slots总押注
    data.slotswin               = userInfo.gameData.slotsWin or 0-- //slots总返现
    data.hundrebet              = userInfo.gameData.hundreBet or 0-- //百人总押注
    data.hunderwin              = userInfo.gameData.hunderWin or 0-- //百人总返现
    -- 玩家携带金币>=chargeMax时，后台显示“上限3倍点杀”
    if userInfo.property.chips >= userInfo.point.chargeMax and userInfo.property.totalRechargeChips < 10000 then
        data.kill_chips_max = "上限3倍80杀"
    elseif userInfo.property.chips >= userInfo.point.chargeMax and userInfo.property.totalRechargeChips >= 10000 then
        data.kill_chips_max = "上限5倍90杀"
    end
    data.kill_low_charge        = "" --低充值第一次杀
    -- isMiddleKill = 1时，后台显示“低充值第一次5倍点杀”
    if userInfo.point.isMiddleKill == 1 then
        data.kill_low_charge = "低充值第1次7倍80杀"
    end
    data.kill_charge            = "" -- //充值点杀
    -- rangeId=1-4，时，后台显示“任意充值后8倍85点杀”
    -- rangeId=6，时，后台显示“任意充值后随机局数1倍点杀”
    -- if userInfo.point.rangeId >= 1 and userInfo.point.rangeId <= 4 then
    --     data.kill_charge = "任意充值7倍80杀"
    -- elseif userInfo.point.rangeId == 6 then
    --     data.kill_charge = "任意充值随机1倍杀"
    -- end
    data.kill_trigger           = "" -- //触发杀
    local killXs = userInfo.point.killXs or 0
    local chargeMax = userInfo.point.chargeMax or 0
    local killTakeEffect = userInfo.point.killTakeEffect or 0
    local desStr = string.format("(解除:%.2f,当前刀:%d,总刀:%d,触发:%.2f)",(chargeMax * killXs  / 100) , userInfo.point.killNum or 0, userInfo.point.killMaxNum or 0, (chargeMax * killTakeEffect /10000/100) )
    data.kill_trigger = desStr
	if userInfo.point.killNum ~= nil and userInfo.point.killXs ~= nil then
		if userInfo.point.killNum == 1 and userInfo.point.killXs ~= 0 then
			data.kill_trigger   = "5倍70杀"..desStr -- //触发杀
		elseif userInfo.point.killNum == 1 and userInfo.point.killXs == 0 then
            data.kill_trigger   = "第1次点杀结束"..desStr -- //触发杀
		elseif userInfo.point.killNum == 2 and userInfo.point.killXs ~= 0 then
			data.kill_trigger   = "5倍70杀"..desStr -- //触发杀
		elseif userInfo.point.killNum == 2 and userInfo.point.killXs == 0 then
			data.kill_trigger   = "第2次点杀结束"..desStr -- //触发杀
		elseif userInfo.point.killNum == 3 and userInfo.point.killXs ~= 0 then
			data.kill_trigger   = "5倍70杀"..desStr -- //触发杀
		elseif userInfo.point.killNum == 3 and userInfo.point.killXs == 0 then
			data.kill_trigger   = "第3次点杀结束"..desStr -- //触发杀
		elseif userInfo.point.killNum == 4 and userInfo.point.killXs ~= 0 then
			data.kill_trigger   = "5倍70杀"..desStr -- //触发杀
		elseif userInfo.point.killNum == 4 and userInfo.point.killXs == 0 then
			data.kill_trigger   = "第4次点杀结束"..desStr  -- //触发杀
		elseif userInfo.point.killNum >= 5 and userInfo.point.killXs ~= 0 then
			data.kill_trigger   = "5倍70杀"..desStr -- //触发杀
		elseif userInfo.point.killNum >= 5 and userInfo.point.killXs == 0 then
			data.kill_trigger   = string.format("第%d次点杀结束", userInfo.point.killNum)..desStr -- //触发杀
		end
	end

    return 0, "获取在线玩家信息成功" , data
end

-- 通过注册、登录、金币范围查询(如果同一组范围一个不存在的话默认查询8小时内 500金币范围)
function SearchByRange(starttime, endtime, lstime, letime, mincoin, maxcoin, curpage, perpage, ranktype)
	-- 只选一边的 另一边补默认值
	if starttime ~= 0 or endtime ~= 0 then
		if starttime == 0 then
			starttime = endtime - 8*3600
		elseif endtime == 0 then
			endtime = starttime + 8*3600
		end
	end
	-- 只选一边的 另一边补默认值
	if lstime ~= 0 or letime ~= 0 then
		if lstime == 0 then
			lstime = letime - 8*3600
		elseif letime == 0 then
			letime = lstime + 8*3600
		end
	end
	-- 只选一边的 另一边补默认值
	if mincoin ~= 0 or maxcoin ~= 0 then
		if mincoin == 0 then
			mincoin = maxcoin - 500
		elseif maxcoin == 0 then
			maxcoin = mincoin + 500
		end
	end

	local filter = nil
	local filterStr = nil
	-- 通过注册时间筛选
	if starttime ~= 0 then
		filter = unilight.a(unilight.ge("status.registertimestamp", starttime), unilight.le("status.registertimestamp", endtime))
		filterStr = '"status.registertimestamp":{"$gte":' .. starttime .. ', "$lte":' .. endtime .. '}'
	end

	-- 通过登录时间筛选
	if lstime ~= 0 then
		if filter == nil then
			filter = unilight.a(unilight.ge("status.logintimestamp", lstime), unilight.le("status.logintimestamp", letime))
			filterStr = '"status.logintimestamp":{"$gte":' .. lstime .. ', "$lte":' .. letime .. '}'
		else
			filter = unilight.a(filter, unilight.ge("status.logintimestamp", lstime), unilight.le("status.logintimestamp", letime))
			filterStr = filterStr .. ", " .. '"status.logintimestamp":{"$gte":' .. lstime .. ', "$lte":' .. letime .. '}'
		end
	end

	local zoneType = go.getconfigint("zone_type") 

	-- 通过筹码筛选
	if mincoin ~= 0 then
		if zoneType == 4 then
			if filter == nil then
				filter = unilight.a(unilight.ge("mahjong.diamond", mincoin), unilight.le("mahjong.diamond", maxcoin))
				filterStr = '"mahjong.diamond":{"$gte":' .. mincoin .. ', "$lte":' .. maxcoin .. '}'
			else
				filter = unilight.a(filter, unilight.ge("mahjong.diamond", mincoin), unilight.le("mahjong.diamond", maxcoin))
				filterStr = filterStr .. ", " .. '"mahjong.diamond":{"$gte":' .. mincoin .. ', "$lte":' .. maxcoin .. '}'
			end
		else
			if filter == nil then
				filter = unilight.a(unilight.ge("property.chips", mincoin), unilight.le("property.chips", maxcoin))
				filterStr = '"property.chips":{"$gte":' .. mincoin .. ', "$lte":' .. maxcoin .. '}'
			else
				filter = unilight.a(filter, unilight.ge("property.chips", mincoin), unilight.le("property.chips", maxcoin))
				filterStr = filterStr .. ", " .. '"property.chips":{"$gte":' .. mincoin .. ', "$lte":' .. maxcoin .. '}'
			end
		end
	end	

	-- 检测是否存在排行榜
	local order = nil
	if ranktype ~= 0 then
		if ranktype == 1 then
			if zoneType == 4 then
				order = unilight.asc("mahjong.diamond")
			else
				order = unilight.asc("property.chips")
			end
		else
			if zoneType == 4 then
				order = unilight.desc("mahjong.diamond")
			else
				order = unilight.desc("property.chips")
			end
		end
	end


	local infoNum = unilight.startChain().Table("userinfo").Filter(filter).Count()
	maxpage = math.ceil(infoNum/perpage)

	local info = nil

	if order ~= nil then
		-- 获取排行榜
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(order).Skip((curpage-1)*perpage).Limit(perpage))
	else
        local orderBy = unilight.desc("status.registertime")
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).OrderBy(orderBy).Skip((curpage-1)*perpage).Limit(perpage))
	end

	local datas = {}
	for i,v in ipairs(info) do
		local ret, _, data = GetUserInfo(nil, v)
		if ret == 0 then
			table.insert(datas, data)
		end		
	end

	-- 如果获取排行榜数据的话 那么还返回当前范围内玩家总数 总币值 
	if order ~= nil then
		local temp = nil
		if filterStr == nil then
			if zoneType == 4 then
				temp = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$group":{"_id":1, "all":{"$sum":"$mahjong.diamond"}}}'))
			else
				temp = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$group":{"_id":1, "all":{"$sum":"$property.chips"}}}'))
			end
		else
			if zoneType == 4 then
				temp = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":1, "all":{"$sum":"$mahjong.diamond"}}}'))
			else
				temp = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{' .. filterStr .. '}}','{"$group":{"_id":1, "all":{"$sum":"$property.chips"}}}'))
			end
		end
		local allChipsNum = 0
		
		if temp ~= nil then
			allChipsNum = temp[1].all
		end

		unilight.info("infoNum:" .. infoNum .. " allChipsNum:" .. allChipsNum)

		return datas, maxpage, infoNum, allChipsNum
	else
		return datas, maxpage
	end
end


-- 处罚
function PunishUser(data)
	local charid 	= data.charid
	local ptype 	= data.ptype
	local taskid	= data.taskid

    --封ip和设备要特殊处理下
    if ptype == Const.BAN_TYPE.IP or ptype == Const.BAN_TYPE.IMEI then
        charid = data.punishvalue
        data.charid = charid
    end

	if charid == nil or ptype == nil then
		return 1, "处罚失败，参数有误"
	end

    --如果结束时间为0 则默认 实际禁言时长 1年
	-- if data.endTime == 0 then
		-- if data.starttime < os.time() then
			-- data.endTime = os.time() + 365*24*3600
		-- else
			-- data.endTime = data.starttime + 365*24*3600
		-- end
	-- end
    --点控结束时间按秒数来
    if ptype == Const.BAN_TYPE.CONTROL then
        data.starttime = os.time()
        data.endtime = os.time() + data.endtime
    end

	local userPunishInfo = unilight.getdata("userpunishinfos", charid)
	if userPunishInfo == nil then
		userPunishInfo = {
			charid  = charid,
			infos 	= {}
		}
		unilight.savedata("userpunishinfos", userPunishInfo)
	end

    --1禁言，2踢下线，3封号，4点控，5追踪

    -- 如果该玩家 已经有 该类别的处罚  
    if CheckUserPunish(charid, ptype) then
        return 2, "当前玩家 存在该类型有效处罚 请先解除老的处罚后再次操作"
    end
    -- 点控值
    if ptype == Const.BAN_TYPE.CONTROL then
        local userInfo = chessuserinfodb.RUserInfoGet(charid)
		if userInfo==nil then
			return 2,"无法查找该玩家"
		end
        userInfo.point.controlvalue = tonumber(data.punishvalue)
		userInfo.point.autocontroltype = 2
        unilight.info(string.format("玩家:%d, 增加点控值:%d", charid, data.punishvalue))
        chessuserinfodb.WUserInfoUpdate(charid, userInfo)
		--通知到具体的游戏服处理
		local laccount = go.roomusermgr.GetRoomUserById(userInfo._id)
		if laccount==nil and backRealtime.lobbyOnlineUserManageMap[userInfo._id]~=nil then
			local tonlineU = backRealtime.lobbyOnlineUserManageMap[userInfo._id].zone
			if tonlineU~=nil then
				--分发到游戏服
				tonlineU:SendCmdToMe('Cmd.PunishUserToGameCmd_S',{
					uid=userInfo._id,
					punishvalue=userInfo.point.controlvalue,
				})
			end
		end
    --追踪
    elseif ptype == Const.BAN_TYPE.TRACE then
        local userInfo = chessuserinfodb.RUserInfoGet(charid)
        userInfo.status.traceInfo = data.reason
        unilight.info(string.format("玩家:%d, 增加追踪:%s", charid, data.punishvalue))
        chessuserinfodb.WUserInfoUpdate(charid, userInfo)

    --踢下线
    elseif ptype == Const.BAN_TYPE.LOGOUT then 
        UserInfo.KickUserLogout(charid, ErrorDefine.GM_KICK_USER)
    --封号
    elseif ptype == Const.BAN_TYPE.ACCOUNT then
        UserInfo.KickUserLogout(charid, ErrorDefine.GM_BAN_USER)
    end
    -- 新处罚 存入汇总处罚列表
    unilight.savedata("punishinfos", data)

    -- 把当前处罚 也记录在玩家处罚信息上
    userPunishInfo.infos[ptype] = taskid
    unilight.savedata("userpunishinfos", userPunishInfo)

    return 0, "处罚成功"
end

-- 删除处罚
function DeletePunishUser(taskid)
	-- 处罚列表中 查找该处罚
	local punishInfo = unilight.getdata("punishinfos", taskid)
	if punishInfo == nil then
		unilight.info("处罚删除失败 当前不存在该处罚 :" .. taskid)
		return 1	
	end

	local userPunishInfo = unilight.getdata("userpunishinfos", punishInfo.charid)
    if punishInfo.ptype == Const.BAN_TYPE.CONTROL then
        local userInfo = chessuserinfodb.RUserInfoGet(punishInfo.charid)
        userInfo.point.controlvalue = 0
		userInfo.point.autocontroltype = 0
        unilight.info(string.format("玩家:%d, 删除点控值", punishInfo.charid))
		chessuserinfodb.WUserInfoUpdate(punishInfo.charid, userInfo)
    elseif punishInfo.ptype == Const.BAN_TYPE.TRACE then
        local userInfo = chessuserinfodb.RUserInfoGet(punishInfo.charid)
        userInfo.status.traceInfo = ""
        unilight.info(string.format("玩家:%d, 删除追踪", punishInfo.charid))
		chessuserinfodb.WUserInfoUpdate(punishInfo.charid, userInfo)
    end


	-- 清除 各人处罚信息记录
	userPunishInfo.infos[punishInfo.ptype] = nil
	unilight.savedata("userpunishinfos", userPunishInfo)

	-- 清除 处罚列表 数据
	unilight.delete("punishinfos", taskid)

	unilight.info("处罚删除成功：" .. taskid)
	return 0	
end

-- 获取处罚列表
function GetPunishList(charid)
	local taskInfos = {}
	-- 查询所有玩家
	if charid == 0 then
		taskInfos = unilight.getAll("punishinfos")
	-- 查询指定玩家 
	else
		local userPunishInfo = unilight.getdata("userpunishinfos", charid)
		for k,v in pairs(userPunishInfo.infos) do
			local taskInfo = unilight.getdata("punishinfos", v)
			table.insert(taskInfos, taskInfo)
		end
	end	
	return taskInfos
end

-- 检测某玩家 是否 有该项有效惩罚
function CheckUserPunish(uid, ptype)
	-- 暂时只支持 自言自语 封号处理
	-- if ptype ~= 3  then
		-- return false
	-- end
	local string_desc = {[2]="踢下线", [3]="封号处理", [4]="点控处理", [5]="追踪处理", [6]="封ip", [7]="封设备"}
	-- 该玩家是否被惩罚 
	local isPunish = false
	local userPunishInfo = unilight.getdata("userpunishinfos", uid)
    if userPunishInfo == nil then
        userPunishInfo = { 
            charid = uid,
            infos  = {}
        }   
        unilight.savedata("userpunishinfos", userPunishInfo)
    end 
	-- 是否存在 处罚
	if userPunishInfo.infos[ptype] ~= nil then
		local punishInfo = unilight.getdata("punishinfos", userPunishInfo.infos[ptype])
		-- 找到 处罚信息
		if punishInfo ~= nil then
			local startTime = punishInfo.starttime
			local endTime 	= punishInfo.endtime
			local curTime 	= os.time()
			if curTime >= startTime and curTime <= endTime then

				unilight.info("当前玩家被"  .. string_desc[ptype] .. "  uid:" .. uid .. "	解禁日期:" .. chessutil.FormatDateGet(endTime) .. "	原因:" .. punishInfo.reason)
				isPunish = true
			-- 该处罚信息 已过期 则删除
			elseif curTime > endTime then
				ChessGmUserInfoMgr.DeletePunishUser(userPunishInfo.infos[ptype])
                --删除特殊的处罚
                -- 点控值
                if ptype == Const.BAN_TYPE.CONTROL then
                    local userInfo = chessuserinfodb.RUserInfoGet(uid)
                    userInfo.point.controlvalue = 0
					userInfo.point.autocontroltype = 0
                    unilight.info(string.format("玩家:%d, 时间到了， 删除点控值", uid))
					chessuserinfodb.WUserInfoUpdate(uid, userInfo, true)
                    --追踪
                elseif ptype == Const.BAN_TYPE.TRACE then
                    local userInfo = chessuserinfodb.RUserInfoGet(uid)
                    userInfo.status.traceInfo = data.punishvalue
                    unilight.info(string.format("玩家:%d, 时间到删除追踪", uid))
					chessuserinfodb.WUserInfoUpdate(uid, userInfo, true)
                end

			end
		-- 该处罚信息 不存在 则清除无效信息
		else
			userPunishInfo.infos[ptype] = nil 
			unilight.savedata("userpunishinfos", userPunishInfo)
		end
	end
	return isPunish
end

--获得玩家提现率数据
function GetPlayerWithdrawData(reqType, rechargeMin, rechargeMax, regFlag, dayStartTime, dayEndTime)

    local dayDinheiro = 0       --当日提现
    local dayRecharge = 0       --当日充值
    local withdrawNum = 0       --提现人数
    local rechargeNum = 0       --充值人数

    local filterStr ='"totalRechargeChips":{"$gte":'..rechargeMin..',"$lte":'..rechargeMax..'}'

    local tmpFilterStr = filterStr .. ', "regFlag":{"$eq":' .. regFlag .. '}'

    -- tmpFilterStr = tmpFilterStr .. ', "state":{"$eq":' .. 6 .. '}'
    tmpFilterStr = tmpFilterStr .. ', "state":{"$in":[6, 3]}'
    if reqType == 0 then
        tmpFilterStr = tmpFilterStr .. ', "timestamp":{"$gte":' .. dayStartTime ..' , "$lt":' .. dayEndTime .. '}'
    else
        tmpFilterStr = tmpFilterStr .. ', "regTime":{"$gte":' .. dayStartTime ..' , "$lt":' .. dayEndTime .. '}'
    end
    info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
    '{"$match":{'..tmpFilterStr..'}}', '{"$group":{"_id":null, "sum":{"$sum":"$dinheiro"}}}'  ))
    if table.len(info) > 0 then
        dayDinheiro = info[1].sum
    end

    local info = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Aggregate(
    '{"$match":{'..tmpFilterStr..'}}', '{"$group":{"_id":"$uid"}}', '{"$group":{"_id":null, "sum":{"$sum":1}}}'  ))
    if table.len(info) > 0 then
        withdrawNum = info[1].sum
    end

    local tmpFilterStr = filterStr .. ', "regFlag":{"$eq":' .. regFlag .. '}'
    tmpFilterStr = tmpFilterStr .. ', "status":{"$eq":' .. 2 .. '}'
    if reqType == 0 then
        tmpFilterStr = tmpFilterStr .. ', "backTime":{"$gte":' .. dayStartTime ..' , "$lt":' .. dayEndTime .. '}'
    else
        tmpFilterStr = tmpFilterStr .. ', "regTime":{"$gte":' .. dayStartTime ..' , "$lt":' .. dayEndTime .. '}'
    end
    info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{'..tmpFilterStr.. '}}','{"$group":{"_id":null, "sum":{"$sum":"$backPrice"}}}'  ))
    if table.len(info) > 0 then
        dayRecharge = info[1].sum
    end

    local info = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate(
    '{"$match":{'..tmpFilterStr.. '}}','{"$group":{"_id":"$uid" }}', '{"$group":{"_id":null, "sum":{"$sum":1}}}'  ))
    if table.len(info) > 0 then
        rechargeNum = info[1].sum
    end

    return  dayDinheiro, dayRecharge, withdrawNum, rechargeNum

end
