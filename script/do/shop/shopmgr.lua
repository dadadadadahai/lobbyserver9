module("ShopMgr", package.seeall)

tableShopConfig = import "table/table_shop_config"
tableParameterParameter= import "table/table_parameter_parameter"
tableItemConfig = import "table/table_item_config"
tableShopSpin = import "table/table_shop_superspin"
tableActivityRecharge = import "table/table_activity_recharge"
tableShopStamp = import "table/table_shop_stamp"

table_shop_discount = import "table/table_shop_discount"
table_recharge_plat  = import "table/table_recharge_plat"
table_mail_config = import "table/table_mail_config"
table_shop_discount_day = import "table/table_shop_discount_day"
table_shop_refresh = import "table/table_shop_refresh"
table_shop_discounts = import "table/table_shop_discounts"

DB_GLOBAL_NAME = "global"

DISCOUNT_TYPE_LIST = {2,5}      --首充特惠类型
HISTORY_MAX_COUNT  = 20              --充值历史记录


DISCOUNT_DAY          = tableParameterParameter[11].Parameter        --商城特惠礼包间隔天数
DISCOUNT_FIRST_SHOPID = tableParameterParameter[12].Parameter        --商城特惠首次购买商品id
DISCOUNT_SECOND_SHOPID = tableParameterParameter[22].Parameter        --商城特惠二次购买商品id
UPLOAD_TIME           = tableParameterParameter[14].Parameter        --上传时间限制

--初始化玩家初始充值信息
function InitRechargeInfo(uid)
	local rechargeInfo = {
		--shopType = shopType,	--商城类型
		_id = uid,
		rechargeCount = {},		--充值次数
        historyInfo = {},       --充值记录
        discountInfo = {
            lastDayNo   = 0,      --上次购买时间, 特惠刷新用
            firstShopId = DISCOUNT_FIRST_SHOPID,      --首充id
            isFirstBuy  = 0,      --是否有购买过首充
            firstBuyTime=  0,   --购买首充的时间
            firstMoney=0,       --首充金额
            secondShopId = DISCOUNT_SECOND_SHOPID,      --2充首充id
            isSecondBuy  = 0,      --是否有购买过2充
            buyShopIds  = {},     --已经购买特惠列表
            dayRebate   = {},     --特惠每日返利{[501] = {lastDay = 上次奖励天数, remainNum = 剩余次数}
            limitInfo   = {},     --限时礼包{isBuy = 0, lastDay = 上次购买天数, shopId = 商品id}
        }

	}
	return rechargeInfo

end


--获得商城物品列表
--@param discountId  要使用的优惠券id
function GetShopTypeItemList(uid, shopType, discountId)
	--为了获得总购买次数
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	if rechargeInfo == nil then
		rechargeInfo = InitRechargeInfo(uid)
		unilight.savedata("rechargeinfo", rechargeInfo)
	end

    if rechargeInfo.discountInfo.isSecondBuy == nil then
        rechargeInfo.discountInfo.secondShopId = DISCOUNT_SECOND_SHOPID      --2充首充id
        rechargeInfo.discountInfo.isSecondBuy  = 0      --是否有购买过2充
		unilight.savedata("rechargeinfo", rechargeInfo)
    end

    local dbDiscountInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.SHOP_DISCOUNT)
    --特惠礼包,每3天换一个
    local discountInfo = rechargeInfo.discountInfo

    --计算特惠商品id
    if discountInfo.isSecondBuy == 1 then
        if discountInfo.lastDayNo ~= dbDiscountInfo.lastDayNo then
            discountInfo.buyShopIds = {}
            discountInfo.lastDayNo = dbDiscountInfo.lastDayNo
            unilight.savedata("rechargeinfo", rechargeInfo)
        end
    end





	--计算需要显示的商品
	local shopTypeList = {}
    local shopList = GetShopListByType(shopType)
	for k, v in pairs(shopList) do
		-- if v.shopType == shopType then
			-- local bShow = userInfo.property.vipExp >= v.vipOpen and userInfo.property.vipExp <= v.vipClose
            local bShow = true
			if bShow then
				local shopInfo = {
					shopId = v.ID,
					-- AllBuyCount = rechargeInfo.rechargeCount[v.ID] or 0,		--所有人购买次数
					price = v.price,											--购买价格
					originMoney = 0, 			                                --原始价格
					finalMoney  = 0, 			                                --最终价格
				}
                if #v.shopGoods > 0 then
                    shopInfo.originMoney = v.shopGoods[1].goodNum
                    shopInfo.finalMoney = chessuserinfodb.GetChipsAddition(uid, v.shopGoods[1].goodNum)
                end
                if shopInfo.shopId == 101 then
                    if userInfo.property.totalRechargeChips == 0 then
                        table.insert(shopTypeList,shopInfo)
                    end
                elseif  shopInfo.shopId == 111 then
                    if userInfo.property.totalRechargeChips > 0 then
                        table.insert(shopTypeList,shopInfo)
                    end
                else
                    table.insert(shopTypeList,shopInfo)
                end
                
			end
		-- end
	end

	return shopTypeList
end

-- 购买商品(仅用于金币购买 rmb购买走充值流程)
function BuyGoods(uid, shopId, orderInfo)
    orderInfo = orderInfo or {}
    -- orderInfo.backPrice = orderInfo.backPrice or 0

	local res = {}
	res["do"] = "Cmd.BuyGoodsShopCmd_S"

	local tableShop = tableShopConfig[shopId]
	if tableShop == nil then
		unilight.info("当前购买商品id有误：" .. shopId)
		res["data"] = {
			ret = 2,
			desc = "当前购买商品id有误"
		}

        unilight.sendcmd(uid, res)
		return 1

	end
    --方便测试
    if orderInfo.backPrice == nil then
        orderInfo.backPrice = tableShop.price
        orderInfo.shopId = shopId
        orderInfo.uid = uid
    end




	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
	if rechargeInfo == nil then
		rechargeInfo = InitRechargeInfo(uid)
	end
    
    --保存购买次数

	rechargeInfo.rechargeCount[shopId] = rechargeInfo.rechargeCount[shopId] or 0
	rechargeInfo.rechargeCount[shopId] = rechargeInfo.rechargeCount[shopId] + 1

    local discountInfo = rechargeInfo.discountInfo

    local dbDiscountInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.SHOP_DISCOUNT)
    --发送充值记录到日志服
    gameDetaillog.toChargeOrder(uid,orderInfo.backPrice)
    --首充
    -- if shopId == DISCOUNT_FIRST_SHOPID then
    --     if discountInfo.isFirstBuy == 1 then
    --         unilight.info(string.format("玩家:%d, 重复购买首充:%d", uid, shopId))
    --         return 1
    --     end
    --     --首充时间

    -- end

    --2充
    -- if shopId == DISCOUNT_SECOND_SHOPID then
    --     if discountInfo.isSecondBuy == 1 then
    --         unilight.info(string.format("玩家:%d, 重复购买2充:%d", uid, shopId))
    --         return 1
    --     end
    --     discountInfo.isSecondBuy = 1
    -- end

    -- if table.find(dbDiscountInfo.discountShopIds, shopId) then
    --     if table.find(discountInfo.buyShopIds, shopId) then
    --         unilight.info(string.format("玩家:%d, 重复购买特惠:%d", uid, shopId))
    --         return 1
    --     end

    --     table.insert(discountInfo.buyShopIds, shopId)
    -- end
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    if userInfo.property.totalRechargeChips == 0 then
        --玩家首充
        discountInfo.firstBuyTime = os.time()
        discountInfo.firstMoney = orderInfo.backPrice
    end

    --不能放在后面，这里面涉及脚本多防止刷错
    local addChips = UserInfo.UserRecharge(uid, shopId, orderInfo)

    -- 商品奖励
    local summary = {}
    local totalChips =  0
    if shopId == 801 or shopId == 802 then
        if orderInfo.backPrice >=50000 then  --充值奖励
            orderInfo.backPrice = math.floor(orderInfo.backPrice + orderInfo.backPrice*0.008)
        elseif orderInfo.backPrice >=20000 then 
            orderInfo.backPrice = math.floor(orderInfo.backPrice + orderInfo.backPrice*0.007)
        elseif orderInfo.backPrice >=10000 then 
            orderInfo.backPrice = math.floor(orderInfo.backPrice + orderInfo.backPrice*0.006)
        elseif orderInfo.backPrice >=5000 then 
            orderInfo.backPrice = math.floor(orderInfo.backPrice + orderInfo.backPrice*0.005)
        end 
        orderInfo.realPrice =  orderInfo.backPrice
        summary = BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, orderInfo.backPrice, Const.GOODS_SOURCE_TYPE.SHOP, summary)
        totalChips = totalChips + orderInfo.backPrice
    else
        for _, goodsInfo in pairs(tableShop.shopGoods) do
            summary = BackpackMgr.GetRewardGood(uid, goodsInfo.goodId, goodsInfo.goodNum, Const.GOODS_SOURCE_TYPE.SHOP, summary)
            totalChips = totalChips + goodsInfo.goodNum
        end
    end

	-- 获取物品 汇总整理返回
	local shopItem = {}
	for k,v in pairs(summary) do
		local item = {
			goodId 	= k,
			goodNum = v,
		}
        -- ID为1的奖励需要增加附加赠送的金额
        if item.goodId == 1 then
            item.goodNum = item.goodNum + addChips
        end
		table.insert(shopItem, item)
	end

	-- 剩余筹码
	local remainder = chessuserinfodb.RUserChipsGet(uid)
    local bUpload   = 0

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    -- if (os.time() - userInfo.status.registertimestamp) < UPLOAD_TIME then
        -- bUpload = 1
    -- end

    --上报条件
    -- if userInfo.property.totalRechargeChips >= 5000  or  userInfo.status.rechargeNum > 1 then
        bUpload = 1
    -- end

	res["data"] = {
		ret 		= 0,
		desc 		= "购买商品成功",
		remainder	= remainder,
		shopItem	= shopItem,
		shopId      = shopId,
        orderId     = orderInfo._id or "",
        payPrice    = orderInfo.backPrice or 0,
        payType     = Const.RECHARGE_TYPE[orderInfo.payType] or "Pix00",
        bUpload     = bUpload,
	}




    --保存下充值历史记录
    local historyInfo = rechargeInfo.historyInfo
    --移除最前面的一条数据
    if table.len(historyInfo) >= HISTORY_MAX_COUNT then
        table.remove(historyInfo, 1)
    end


    if tableShop.shopType == Const.SHOP_TYPE.SAVINGPOT then
        totalChips = cofrinho.GetCofrinInfo(uid).latestRecvGold
    end
    
    ---------------------------------------- 801版本随机充值金额 ----------------------------------------
    totalChips = orderInfo.backPrice
    ---------------------------------------- 801版本随机充值金额 ----------------------------------------

    -- table.insert(historyInfo, 
    --     {
    --         chips = totalChips,         --充值获得金币
    --         sourceType = Const.GOODS_SOURCE_TYPE.SHOP,           --充值来源
    --         order = orderInfo._id or "",    --订单编号
    --         status = 1,                 --级别
    --         timestamp = os.time() ,     --时间截
    --         shopId    = shopId,         --商品id
    --         payType = orderInfo.payType,    --支付类型
    --         backPrice = orderInfo.backPrice, --实际支付值
    --     })

    
    --购买的是超值特惠，每天要赠送银币
    -- if table_shop_discount_day[shopId] ~= nil then
    --     discountInfo.dayRebate[shopId] = {lastDayNo = 0, remainNum = table_shop_discount_day[shopId].dayNum, timestamp = os.time()} 
    -- end

	unilight.savedata("rechargeinfo", rechargeInfo)
    --推着一下特惠信息
    --SendDisCountInfoToMe(uid)
    --检查特惠邮件奖励
    CheckDiscountReward(uid)

	-- 返回 
    unilight.sendcmd(uid, res)
    -- CmdGetRechargeHistory(uid)
    --发送下邮件
    local mailConfig = table_mail_config[19]
    local mailInfo = {}
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content, orderInfo.backPrice / 100, chessutil.FormatDateGet(nil, "%d/%m/%Y %H:%M:%S"))
    print("===========================================")
    print(orderInfo.backPrice/100)
    print(string.format(mailConfig.content, orderInfo.backPrice / 100, chessutil.FormatDateGet(nil, "%d/%m/%Y %H:%M:%S")))
    print(mailInfo.content)
    mailInfo.type = 0
    mailInfo.attachment = rewardList
    mailInfo.extData = {configId=mailConfig.ID}
    ChessGmMailMgr.AddGlobalMail(mailInfo)

    --充值结束再处理下
    UserInfo.UserRechargeEnd(uid, shopId, orderInfo)
    return 0
end


--根据商城类型+金额获得shopId
function GetShopIdByTypeMoney(shopType, price)
    local shopList = GetShopListByType(shopType)
	for k, shopConfig in pairs(shopList) do
        if shopConfig.price ==  price then
            return shopConfig.ID
        end
    end
end


--商城特惠充值id随机
function GetShopDiscountRandomShopId(shopType)
    local shopList = GetShopListByType(shopType)

    local probability   = {}
    local allResult     = {}
    for _, shopConfig in pairs(shopList) do
        table.insert(probability, 10)
        table.insert(allResult, shopConfig.ID)

    end
    local shopId = math.random(probability, allResult)
    return shopId
end


--发送特惠信息
function SendDisCountInfoToMe(uid)
    
    GetShopTypeItemList(uid, 2)
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    local dbDiscountInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.SHOP_DISCOUNT)
    local discountInfo = rechargeInfo.discountInfo
    --重置下二充id
    discountInfo.secondShopId = DISCOUNT_SECOND_SHOPID      --2充首充id
    unilight.savedata("rechargeinfo", rechargeInfo)
	local res = {}
	res["do"] = "Cmd.DiscountInfoShopCmd_S"
    res.data = {
        bFirstBuy  = discountInfo.isFirstBuy, 	--是否已购买
        firstShopId = discountInfo.firstShopId,
        bSecondBuy  = discountInfo.isSecondBuy, 	--2充是否已购买
        secondShopId = discountInfo.secondShopId,
        buyDiscountShopIds = discountInfo.buyShopIds, 
        discountShopIds = dbDiscountInfo.discountShopIds,   --
        shopConfig = {},                         --商城配置
        discountConfig = {}                     --打折配置
    }

    --首充配置
	local tableShop = tableShopConfig[discountInfo.firstShopId]
    table.insert(res.data.shopConfig, tableShop)
    --2充配置
	local tableShop = tableShopConfig[discountInfo.secondShopId]
    table.insert(res.data.shopConfig, tableShop)
    for _, shopId in pairs(dbDiscountInfo.discountShopIds) do
        local tableShop = tableShopConfig[shopId]
        table.insert(res.data.shopConfig, tableShop)
    end
    for _, v in pairs(table_shop_discount_day) do
        table.insert(res.data.discountConfig, v)
    end

    unilight.sendcmd(uid, res)
end


--发送限时特惠礼包
function SendLimitDiscountInfoToMe(uid)
    CalcLimitDiscountInfo(uid)
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    local discountLimitInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.LIMIT_DISCOUNT)
    local limitInfo = rechargeInfo.discountInfo.limitInfo

	local res = {}
	res["do"] = "Cmd.DiscountLimitInfoShopCmd_S"
    res.data = {
        shopId = limitInfo.shopId, 
        isBuy  = limitInfo.isBuy,
        endTime    = discountLimitInfo.endTime,
        openTime = discountLimitInfo.openTime,
    } 
    unilight.sendcmd(uid, res)
end

--限时活动是否开启
function CheckLimitDiscountIsOpen()
    local discountLimitInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.LIMIT_DISCOUNT)
    local curTime = os.time()
    if curTime >= discountLimitInfo.openTime and curTime < discountLimitInfo.endTime then
        return true
    end
    return false
end


--计算个人限时特惠
function CalcLimitDiscountInfo(uid)
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    local discountLimitInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.LIMIT_DISCOUNT)

    local limitInfo = rechargeInfo.discountInfo.limitInfo
    local curDayNo = chessutil.GetMorningDayNo()
    if table.empty(limitInfo) then
            limitInfo.lastDayNo = curDayNo                       --上次刷新天数
            limitInfo.shopId    = discountLimitInfo.shopId       --商品id
            limitInfo.isBuy     = 0                              --是否购买
        unilight.savedata("rechargeinfo", rechargeInfo)
    end

    if limitInfo.lastDayNo ~= curDayNo then
            limitInfo.lastDayNo = curDayNo                       --上次刷新天数
            limitInfo.shopId    = discountLimitInfo.shopId       --商品id
            limitInfo.isBuy     = 0                              --是否购买
        unilight.savedata("rechargeinfo", rechargeInfo)
    end
end

--检测是否有特惠邮件奖励
function CheckDiscountReward(uid)
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    if rechargeInfo == nil then 
        return 
    end 
    local discountInfo = rechargeInfo.discountInfo

    local bSucess = false
    local curDayNo  = chessutil.GetMorningDayNo()
    for shopId, rewardInfo in pairs(discountInfo.dayRebate) do
         if rewardInfo.lastDayNo ~= curDayNo and rewardInfo.remainNum > 0 then
             rewardInfo.remainNum = rewardInfo.remainNum - 1
             rewardInfo.lastDayNo = curDayNo
             local discounConfig = table_shop_discount_day[shopId]
             if discounConfig ~= nil  then
                 local mailConfig = table_mail_config[discounConfig.mailId]
                 local shopConfig = tableShopConfig[shopId]

                 local mailInfo = {}
                 mailInfo.charid = uid
                 mailInfo.subject = mailConfig.subject
                 mailInfo.content = string.format(mailConfig.content, shopConfig.price / 100, chessutil.FormatDateGet(rewardInfo.timestamp, "%d/%m/%Y %H:%M:%S"))
                 mailInfo.type = 0
                 if shopConfig.shopType == 2 then
                     local idx = table.len(discounConfig.dayRewards) - rewardInfo.remainNum 
                     mailInfo.attachment = {{itemId=discounConfig.dayRewards[idx].goodId, itemNum=discounConfig.dayRewards[idx].goodNum}}
                     --赠送金币
                     mailInfo.extData = {configId=mailConfig.ID, isPresentChips = 1}
                 else
                     mailInfo.attachment = {{itemId=discounConfig.dayRewards[1].goodId, itemNum=discounConfig.dayRewards[1].goodNum}}
                     mailInfo.extData = {configId=mailConfig.ID}
                 end
                 ChessGmMailMgr.AddGlobalMail(mailInfo)
                 bSucess = true
             end
         end
     end
    if bSucess then
        unilight.savedata("rechargeinfo", rechargeInfo)
    end
end


--刷新特惠商品信息
function RefreshDiscountShop()
    local discountInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.SHOP_DISCOUNT)
    if table.empty(discountInfo) then
        -- 需要初始化
        local lastId, discountShopIds = CalcDiscountShop(0)
        discountInfo = {
            _id = Const.GLOBAL_DB_TYPE.SHOP_DISCOUNT,
            discountShopIds = discountShopIds,
            lastDayNo = chessutil.GetMorningDayNo(),
            lastId    = lastId,          --上一次生成的ID,不能重复
        }
        unilight.savedata(DB_GLOBAL_NAME, discountInfo)
    end

    local curDayNo = chessutil.GetMorningDayNo()
    local diffDay = math.abs(curDayNo - discountInfo.lastDayNo)
    if diffDay >= DISCOUNT_DAY  then
        local lastId, discountShopIds = CalcDiscountShop(discountInfo.lastId)
        discountInfo.discountShopIds = discountShopIds 
        discountInfo.lastDayNo = curDayNo
        discountInfo.lastId = lastId
        unilight.savedata(DB_GLOBAL_NAME, discountInfo)
    end
end


--判断刷新限时特惠
function RefreshGlobalLimitDiscountShop()
    local curDayNo = chessutil.GetMorningDayNo()
    local discountInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.LIMIT_DISCOUNT)
    if table.empty(discountInfo) then
        -- 需要初始化
        local lastId, openTime, endTime = CalcLimitDiscountShop(0)
        discountInfo = {
            _id = Const.GLOBAL_DB_TYPE.LIMIT_DISCOUNT,
            shopId = lastId,
            openTime = openTime,
            endTime = endTime,
            lastDayNo = curDayNo,
        }
        unilight.savedata(DB_GLOBAL_NAME, discountInfo)
    end

    if discountInfo.lastDayNo ~= curDayNo then
        local lastId, openTime, endTime = CalcLimitDiscountShop(discountInfo.shopId)
        discountInfo.shopId = lastId
        discountInfo.openTime = openTime
        discountInfo.endTime = endTime
        discountInfo.lastDayNo = curDayNo
        unilight.savedata(DB_GLOBAL_NAME, discountInfo)
    end
end

--生成特惠商品信息
function CalcDiscountShop(lastId)

    while true do
        local probability = {}
        local allResult = {}
        for k, v in pairs(table_shop_discount) do
            table.insert(probability, 100)
            table.insert(allResult, v.ID)
        end
        local randomId  = math.random(probability, allResult)
        if randomId ~= lastId then
            local discountConfig = table_shop_discount[randomId]
            unilight.info("每天重新生成特惠商品id:"..table2json(discountConfig))
            return randomId, {discountConfig.shopId1, discountConfig.shopId2, discountConfig.shopId3}
        end
    end
end

--生成限时特惠商品信息
function CalcLimitDiscountShop(lastId)
    local shopRefreshConfig = table_shop_refresh[1]
    local shopType = shopRefreshConfig.shopType
    local shopList = GetShopListByType(shopType)
    local randomId = 0
    while true do
        local probability = {}
        local allResult = {}
        for k, v in pairs(shopList) do
            table.insert(probability, 100)
            table.insert(allResult, v.ID)
        end
        randomId  = math.random(probability, allResult)
        if randomId ~= lastId then
            break
        else
            unilight.info("每天重新生成限时特惠商品重复:lastId:"..lastid..", randomId:"..randomId)
        end
    end

    --开启时间
    local openTime = 0
    --结束时时间
    local endTime = 0
    --刷新时间类型
    --指定时间
    if shopRefreshConfig.timeType == 1 then
        openTime = chessutil.GetTimeByFormat(shopRefreshConfig.fixOpenTime)
    else
    --随机时间
        openTime = chessutil.GetTimeByFormat(math.random(shopRefreshConfig.randOpenMin, shopRefreshConfig.randOpenMax))
    end

    --持续时间
    --指定
    if shopRefreshConfig.durationType == 1 then
        endTime = openTime + shopRefreshConfig.fixDurationTime
    else
    --随机
        endTime = openTime + math.random(shopRefreshConfig.randTimeMin, shopRefreshConfig.randTimeMax)
    end

    unilight.info(string.format("每天重新生成限时特惠商品id:%d, 开启时间小时:%s, 结束时间:%s", randomId, chessutil.FormatDateGet(openTime), chessutil.FormatDateGet(endTime)))
    return randomId, openTime, endTime
end

--获得充值记录
function CmdGetRechargeHistory(uid)

	local res = {}
	res["do"] = "Cmd.GetHistoryShopCmd_S"
	res.data = {}
    local historyInfo = {}

    -- local orderList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Filter(unilight.eq("uid", uid)).OrderBy(unilight.desc("subTime")).Limit(20))
    -- _id; #订单ID
    -- uid  #玩家id
    -- subTime #订单提交时间
    -- shopId #商品id
    -- subPrice #提交金额
    -- fee #fee手续费
    -- backTime #回调时间
    -- backPrice #回调金额
    -- payType #支付方式
    -- order_no #支付平台,订单id
    -- status #订单状态, #订单状态 0 已提交 1 已支付， 2，已发放
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    local orderList = rechargeInfo.historyInfo
    for _, orderInfo in ipairs(orderList) do
        local tableShop = tableShopConfig[orderInfo.shopId]
        table.insert(historyInfo, {
                    chips      = orderInfo.backPrice,   --充值获得金币
                    sourceType = Const.RECHARGE_TYPE[orderInfo.payType] or "Pix100",   --充值来源
                    order      = orderInfo.order or "",   --订单编号
                    status     = orderInfo.status,   --级别
                    timestamp  = orderInfo.timestamp,   --时间截
                    shopId     = orderInfo.shopId,
            })

    end
    res.data.historyInfo = historyInfo
    unilight.sendcmd(uid, res)
end


--获得充值渠道
function CmdGetRechargePlat(uid)
	local res = {}
	res["do"] = "Cmd.ReqRechargePlatShopCmd_S"
	res.data = {}
    res.data.platIds = {}
    for _, v in ipairs(table_recharge_plat) do
        if v.status == 1 then
            table.insert(res.data.platIds, {platId = v.platId,platName = v.desc}) 
        end
    end
    unilight.sendcmd(uid, res)
end


--是否存在历史订单
function IsExistHistoryOrder(uid, orderId)
    local isFind = false 
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    if rechargeInfo==nil then
        return isFind
    end
    local orderList = rechargeInfo.historyInfo
    for _, orderInfo in ipairs(orderList) do
        if orderInfo.order == orderId then
            isFind = true
            break
        end
    end
    return isFind
end

--
--清除过期的历史记录
function CleanHistoryInfo(uid)
	local rechargeInfo = unilight.getdata("rechargeinfo", uid)     --数据库获取内容
    local historyInfo = rechargeInfo.historyInfo
    --移除7天前的订单记录
    local tenDayTime = 7 * 86400 
    local orderidList = {}
    for i, historyOrderInfo in pairs(historyInfo) do
        if os.time()  - historyOrderInfo.timestamp >  tenDayTime then
            table.insert(orderidList,historyOrderInfo.order)
        end
    end

    for _, orderId  in pairs(orderidList) do
        for i, historyOrderInfo in pairs(historyInfo) do
            if historyOrderInfo.order == orderId then
                table.remove(historyInfo, i)
                break
            end
        end
    end

    unilight.savedata("rechargeinfo", rechargeInfo)
end