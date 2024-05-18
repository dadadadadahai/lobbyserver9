-- 处理奖券相关
module("GiftCouponMgr", package.seeall)

LEN_PHONE 	= 11
LEN_ADDR	= 50

-- 数据初始化
function Init(uid)
	local giftCouponInfo = {
		uid		= uid,
		records = {}
	}
	return giftCouponInfo
end

-- 奖券兑换
function Exchange(uid, exchangeId, exchangeNbr)
	-- 当前奖券
	local coupon = chessuserinfodb.RUserGiftCouponsGet(uid)

	-- 
	local exchangeInfo = nil
	for i,v in ipairs(TableShopConfig) do
		if v.shopId == exchangeId then
			exchangeInfo = v
			break
		end
	end
	if exchangeInfo == nil then
		return 2, "奖券兑换id有误"
	end

	-- 判断奖券是否足够
	if coupon < exchangeInfo.price then
		return 3, "当前奖券不足"
	end

	-- 获取物品
	local tableGoodInfo = TableGoodsConfig[exchangeInfo.shopGoods.goodId]
	BackpackMgr.GetRewardGood(uid, exchangeInfo.shopGoods.goodId, exchangeInfo.shopGoods.goodNum, Const.GOODS_SOURCE_TYPE.GIFTCOUPON)

	-- 扣除奖券
	coupon = chessuserinfodb.WGiftCouponsChange(uid, 2, exchangeInfo.price)

	-- 记录
	local record = {
		exchangeId 		= exchangeId,
		exchangeName	= tableGoodInfo.goodName,
		giftCoupon 		= exchangeInfo.price,
		exchangeTime	= os.date("%Y-%m-%d %H:%M", os.time()),
	}
	local giftCouponInfo = unilight.getdata("giftcoupon", uid)
	if giftCouponInfo == nil then
		giftCouponInfo = Init(uid)
	end
	table.insert(giftCouponInfo.records, record)
	unilight.savedata("giftcoupon", giftCouponInfo)

	return 0, "奖券兑换成功", coupon, exchangeInfo.shopGoods	
end

-- 获取兑换记录
function GetRecords(uid)
	local giftCouponInfo = unilight.getdata("giftcoupon", uid)
	if giftCouponInfo == nil then
		giftCouponInfo = Init(uid)
		unilight.savedata("giftcoupon", giftCouponInfo)
	end	
	return 0, "获取兑换记录成功", giftCouponInfo.records
end

-- 0xxxxxxx - 	0, 1 byte
-- 110yxxxx - 192, 2 byte
-- 1110yyyy - 225, 3 byte
-- 11110zzz - 240, 4 byte
-- 获取指定字节长度
function GetByteLen(char)
	if not char then
		print("not char")
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end	
end

-- 获取字符串长度
function GetStringLen(str)
	local len = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		currentIndex = currentIndex + GetByteLen(char)
		len = len +1
	end
	return len	
end

-- 获取个人资料
function GetPersonalData(uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local personalData = {
		name 		= userInfo.base.name,
		phoneNbr 	= userInfo.base.phonenbr,
		-- qq 			= userInfo.base.qq,
		-- zipCode 	= userInfo.base.zipcode,
		-- addr 		= userInfo.base.addr,
	}
	return 0, "获取个人资料成功", personalData
end

-- 设置个人资料
function SetPersonalData(uid, personalData)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- 判断手机号 是否符合要求
	if personalData.phoneNbr ~= nil then
		local phoneNbr_str = tostring(personalData.phoneNbr)
		if GetStringLen(phoneNbr_str) ~= LEN_PHONE then
			return 2, "手机号长度不符合要求"  
		end
	end

	-- 判断地址长度是否过长
	if personalData.addr ~= nil then
		if GetStringLen(personalData.addr) > LEN_ADDR then
			return 3, "地址长度超过50"
		end
	end

	-- 赋值
	userInfo.base.name 		= personalData.name
	userInfo.base.phonenbr 	= personalData.phoneNbr
	-- userInfo.base.qq 		= personalData.qq
	-- userInfo.base.zipcode 	= personalData.zipCode
	-- userInfo.base.addr 		= personalData.addr

	-- 存档
	chessuserinfodb.WUserInfoUpdate(uid, userInfo)

	return 0 ,"设置个人资料成功", personalData
end