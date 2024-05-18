module('chessrechargemgr', package.seeall)

local table_shop_config = import "table/table_shop_config"
-- 初始化
function Init()
	-- 创建订单数据表，
	unilight.createdb("gameorder", "gameorder")
	unilight.createdb("orderinfo", "_id")
	gameOrderIdx = 1

	-- 金币充值相关map
	MapRmb2RechargeId 		= {}			-- rmb 		to 	rechargeid
	MapShopId2RechargeId 	= {}			-- shopid 	to 	rechargeid
	MapRechargeId2ShopId 	= {}			-- rechargeid 	to 	shopid

	-- rmb道具相关map
	MapShopIdToPayId 		= {}			
	MapPayIdToShopId 		= {}

	-- 金币充值、rmb道具 均存在
	MapShopIdToRmb   		= {}

	local index = 0			-- 用于标记 rechageid
	for i,v in ipairs(TableShopConfig) do
		-- 金币商城
		if v.shopType == 1 then
			index = index + 1 
			MapRmb2RechargeId[v.price] 		= index
			MapShopId2RechargeId[v.shopId] 	= index 
			MapRechargeId2ShopId[index]		= v.shopId
			MapShopIdToRmb[v.shopId] 		= v.price
		-- 道具商城
		elseif v.shopType == 2 then
			-- 需rmb直接购买的道具
			if v.priceType == 1 then
				MapShopIdToPayId[v.shopId] = v.iapppayId
				MapPayIdToShopId[v.iapppayId] = v.shopId
				MapShopIdToRmb[v.shopId] = v.price
			end
		end
	end
end

-- 订单创建
function CreateGameOrder(uid)
	-- 由gameid + uid + platid + os.timer + gameOrderIdx组成
	local strGameid = "AAA"
	local strUid = string.format("%08d", tonumber(uid)) 
	local strTimer = string.format("%010d", go.time.Sec())
	local strIdx = string.format("%05d", gameOrderIdx)
	local gameOrder = tostring(strGameid) .. strUid .. strTimer .. strIdx
	
	gameOrderIdx = gameOrderIdx + 1
	return gameOrder
end

-- 所有平台支付统一管理入口
function CmdCreatePlatOrderRequest(laccount, rev)
	local uid = laccount.Id
	laccount = go.accountmgr.GetAccountById(uid)
	local platId = laccount.JsMessage.GetPlatid()
	local gameOrder = CreateGameOrder(uid)
	local goodId = tonumber(rev.goodid)
	local goodNum = tonumber(rev.goodnum) or 1 

	-- 由于 当前goodid 可能为金币充值（rechargeid） 也可能为 rmb道具购买(shopid)
	local shopId 	= MapRechargeId2ShopId[goodId] or goodId
	local tempRmb 	= MapShopIdToRmb[shopId] 

	local rmb = tempRmb * goodNum
	if rmb == nil or rmb == 0 then
		local desc = "充值参数有误， goodid 找不到对应的充值参数 " .. table.tostring(rev)
		return false, desc 
	end
	local payPlatId = tonumber(rev.payplatid) or 0
	local roleId = uid 
	local roleName = laccount.JsMessage.GetNickname() 
	local originalMoney = rmb 
	local orderMoney = rmb 
	local goodName = tostring(rev.goodname)or ""
	local goodDesc = tostring(rev.gooddesc) or ""
	local redirectUrl = tostring(rev.redirecturl) or ""
	local extData = tostring(rev.extdata) or ""
	
	-- 道具goodid 与 支付平台 对应 的id 不一致 要对应修改
	goodId = MapShopIdToPayId[goodId] or goodId
	 
	-- 充值
	local log = "创建订单： uid " .. uid .. "  platId: " .. platId .. "  以分为单位充值金额为： " .. rmb
	laccount.CreatePlatOrderByPayPlatid(gameOrder, roleName, goodName, redirectUrl, goodDesc, extData, roleId, originalMoney, orderMoney, goodId, goodNum, payPlatId)
	return true, "ok"
end

-- 所有第三方平台支付积分信息请求
function CmdRequestQueryPlatPoint(laccount)
	unilight.info("玩家" .. laccount.Id .. "查询第三方平台积分")
	laccount.QueryPoint()
end

-- 从第三方兑入
function CmdRequestRedeemPlatPoint(laccount, goodId, rmb, extData)
	local uid = laccount.Id
	local gameOrder = CreateGameOrder(uid)
	local platOrder = gameOrder
	extData = tostring(extData) or ""
	local log = "从第三方兑入 rmb为元"
	if goodId == 1000 then
		log = "从cc365兑入，rmb为对方的币"	
	end
	UserRechargeCreateOrderLog(gameOrder, platOrder, uid, 10000, rmb,log) 
	laccount.RedeemPoint(rmb, goodId, gameOrder, extData)	
end

-- 从第三方兑出
function CmdRequestRedeemBackPlatPoin(laccount, point, rmb, extData)
	local uid = laccount.Id
	local gameOrder = CreateGameOrder(uid)
	local platOrder = gameOrder
	extData = tostring(extData) or ""
	UserRechargeCreateOrderLog(gameOrder, platOrder, uid, 10000, rmb, "从第三方兑出")
	laccount.RedeemBackPoint(rmb, point, gameOrder, extData)
end

-- 查询玩家共充值金额
function CmdUserSumRechargeGetByUid(uid)
	local sumRecharge = 0
	local resList = unilight.chainResponseSequence(unilight.startChain().Table("gameorder").Filter(unilight.a(unilight.eq("uid", uid), unilight.eq("bok", 1))))	
	for i, v in ipairs(resList) do
		sumRecharge = sumRecharge + v.rmb*100
	end
	return sumRecharge
end

-- 查询玩家指定时间内共充值金额(单位 -- 元)
function CmdUserSumRechargeGetByUid(uid, timestamp1, timestamp2)
	local sumRecharge = 0
	local resList = unilight.chainResponseSequence(unilight.startChain().Table("gameorder").Filter(unilight.a(unilight.eq("uid", uid), unilight.eq("bok", 1), unilight.gt("timestamp", timestamp1), unilight.lt("timestamp", timestamp2))))	
	for i, v in ipairs(resList) do
		sumRecharge = sumRecharge + v.rmb
	end
	return sumRecharge
end

-- 查询玩家从某个时间开始充值次数
function CmdUserRechargeNumberGetByUid(uid, timeStamp)
	if timeStamp == nil then
		timeStamp = 0
	end
	local filter = unilight.a(unilight.eq("uid", uid), unilight.eq("bok", 1), unilight.gt("timestamp", timeStamp))
	local number = unilight.startChain().Table("gameorder").Filter(filter).Count()	
	return number
end


--检查是否有新订单发放奖励
function CheckOrderDelivery()

    --[[
    _id; #订单ID
    uid  #玩家id 
    subTime #订单提交时间
    shopId #商品id
    subPrice #提交金额
    fee #fee手续费
    backTime #回调时间
    backPrice #回调金额
    payType #支付方式
    order_no #支付平台,订单id
    status #订单状态, #订单状态 0 已提交 1 已支付， 2，已发放
    ]]
	local orderList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter(unilight.eq("status", Const.ORDER_STATUS.PAY)))	
    for _, orderInfo in pairs(orderList) do

        --在大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        if laccount ~= nil then
            orderInfo.status = Const.ORDER_STATUS.DELIVERY
            --增加一个当前金币
            orderInfo.curChips = chessuserinfodb.RUserChipsGet(orderInfo.uid)
            unilight.savedata("orderinfo", orderInfo )
            if ShopMgr.IsExistHistoryOrder(orderInfo.uid, orderInfo._id) == false then
				ShopMgr.BuyGoods(orderInfo.uid, orderInfo.shopId, orderInfo)
            end
        else
			-- print('other info')
            --在其它进程
            local userInfo = chessuserinfodb.RUserInfoGet(orderInfo.uid, true)
            local gameInfo = userInfo.gameInfo
            local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(gameInfo.gameId, gameInfo.zoneId)
			-- print('gameInfo.gameId',gameInfo.gameId,gameInfo.zoneId)
            if zoneInfo ~= nil then
                zoneInfo:SendCmdToMe("Cmd.ReqUserRechargeLobby_CS",orderInfo)
            end
        end
    end

end
--充值分发 new
function CheckOrderDeliveryNew(uid,orderId)
	local laccount = go.roomusermgr.GetRoomUserById(uid)
	if laccount ~= nil then
		local orderList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter( unilight.a(unilight.eq("status", Const.ORDER_STATUS.PAY),unilight.eq("_id",orderId))))	
		if #orderList>0 then
			local orderInfo = orderList[1]
			ShopMgr.BuyGoods(orderInfo.uid, orderInfo.shopId, orderInfo)
			orderInfo.status = Const.ORDER_STATUS.DELIVERY
			unilight.savedata("orderinfo", orderInfo )
		end
	end
end
--玩家上线检查订单
function userLoginCheckOrder(uid)
	local laccount = go.roomusermgr.GetRoomUserById(uid)
	if laccount ~= nil then
		local orderList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter( unilight.a(unilight.eq("status", Const.ORDER_STATUS.PAY),unilight.eq("uid",uid))))	
		for _, orderInfo in pairs(orderList) do
			ShopMgr.BuyGoods(orderInfo.uid, orderInfo.shopId, orderInfo)
			orderInfo.status = Const.ORDER_STATUS.DELIVERY
			unilight.savedata("orderinfo", orderInfo )
		end
	end
end



--保存充值兑换相关日志
function SaveRechargeWithdrawLog(uid, opType, chips)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)

    -- optional string  id            = 1; //编号
    -- optional string  timedate      = 2; //时间字符串
    -- optional uint32  charid        = 3; //玩家id
    -- optional uint32  curchips      = 4; // 当前金币
    -- optional uint32  type          = 5; //类型1充值，2是兑换
    -- optional uint32  opchips       = 6; //充值兑换金额
    -- optional uint32  rechargenum   = 7; //充值次数
    -- optional uint32  totalrecharge = 8; //累计充值
    -- optional uint32  exchangenum   = 9; //兑换次数
    -- optional uint32  totalexchange = 10; //累计兑换金额
    local data={
        _id                = go.newObjectId(),
        timestamp          = os.time(),
        uid                = uid,
        curChips           = userInfo.property.chips,
        opType             = opType,
        opChips            = chips,
        rechargeNum        = userInfo.status.rechargeNum,               --充值次数
        totalRechargeChips = userInfo.property.totalRechargeChips,      --总充值
        chipsWithdrawNum   = userInfo.status.chipsWithdrawNum,          --提现次数
        chipsWithdraw      = userInfo.status.chipsWithdraw,             --提现金额
        subplatid          = userInfo.base.subplatid,                   --子渠道id
        killNum            = userInfo.point.killNum,                    --点杀次数
        slotsCount         = userInfo.gameData.slotsCount or 0,         --游戏局数
    }
    unilight.savedata("rechargeWithdrawLog", data )

end

--保存1到4充数据
function SaveDayRechargeLog(uid)

    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local firstPayTime = userInfo.status.firstPayTime
    if firstPayTime == 0 then firstPayTime = os.time() end
    local curDayTimestamp = chessutil.ZeroTodayTimestampGet(firstPayTime)
	local dayPayInfo = unilight.getdata("DayRechargeStatistic", curDayTimestamp)
    if table.empty(dayPayInfo) then
        dayPayInfo = {
            dayNum = curDayTimestamp,                --天数
            pay1   = 0,                     --首充人数
            pay2   = 0,                     --2充人数
            pay3   = 0,                     --3充人数
            pay4   = 0,                     --4充人数
        }
    end
    local rechargeNum = userInfo.status.rechargeNum
    if rechargeNum == 1 then
        dayPayInfo.pay1 = dayPayInfo.pay1 + 1
    elseif rechargeNum == 2 then
        dayPayInfo.pay2 = dayPayInfo.pay2 + 1
    elseif rechargeNum == 3 then
        dayPayInfo.pay3 = dayPayInfo.pay3 + 1
    elseif rechargeNum == 4 then
        dayPayInfo.pay4 = dayPayInfo.pay4 + 1
    end

    unilight.savedata("DayRechargeStatistic", dayPayInfo)


end

--增加当天充值的订单最大充值，加快查询速度
function UpdateOrderDayRecharge(uid, userInfo)
    userInfo = userInfo or chessuserinfodb.RUserDataGet(uid)
    local beginTime = chessutil.ZeroTodayTimestampGet()
    local endTime   = beginTime + 86400
    local filter = unilight.eq("status", Const.ORDER_STATUS.DELIVERY)
    filter = unilight.a(filter, unilight.eq("uid", uid) )
    filter = unilight.a(filter, unilight.ge("backTime", beginTime), unilight.lt("backTime", endTime))
	local orderList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter(filter))
    for _, orderInfo in pairs(orderList) do
        orderInfo.totalRechargeChips = userInfo.property.totalRechargeChips
        orderInfo.regTime = userInfo.status.registertimestamp 
        unilight.savedata("orderinfo", orderInfo )
        unilight.info("玩家:"..uid..", 更新订单总金额:"..orderInfo.totalRechargeChips)
    end
end

--增加当天提现订单最大充值，加快查询
function UpdateWithdrawOrderDayRecharge(uid, userInfo)

    userInfo = userInfo or chessuserinfodb.RUserDataGet(uid)
    local beginTime = chessutil.ZeroTodayTimestampGet()
    local endTime   = beginTime + 86400
    local filter = unilight.eq("state", WithdrawCash.STATE_SUCCESS_FINISH)
    filter = unilight.a(filter, unilight.eq("uid", uid) )
    filter = unilight.a(filter, unilight.ge("finishTimes", beginTime), unilight.lt("finishTimes", endTime))
	local orderList = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(filter))	
    for _, orderInfo in pairs(orderList) do
        orderInfo.totalRechargeChips = userInfo.property.totalRechargeChips
        orderInfo.regTime = userInfo.status.registertimestamp 
        unilight.savedata("withdrawcash_order", orderInfo )
        unilight.info("玩家:"..uid..", 更新提现订单总金额:"..orderInfo.totalRechargeChips)
    end
end
