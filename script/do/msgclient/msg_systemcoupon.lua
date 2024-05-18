



-- 玩家数据库系统优惠券相关信息初始化
Net.CmdSystemCouponInfoGet_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.SystemCouponInfoGet_S"
	local uid = laccount.Id
	local systemCouponInfo = SystemCoupon.SystemCouponInfoGet(uid)
	res["data"] = {
		systemCouponInfo = systemCouponInfo
	}
	return res
end

-- 玩家优惠券时间管理
Net.CmdTimeCoupon_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.TimeCoupon_S"
	local uid = laccount.Id
	local systemCouponInfo = SystemCoupon.TimeCoupon(uid)
	res["data"] = {
		systemCouponInfo = systemCouponInfo
	}
	return res
end

-- 玩家使用优惠券
Net.CmdUseSystemCoupons_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UseSystemCoupons_S"
	local uid = laccount.Id
	local coupons = {31136,30013,31235}
	local systemCouponInfo = SystemCoupon.UseSystemCoupons(uid,coupons)
	res["data"] = {
		systemCouponInfo = systemCouponInfo
	}
	return res
end