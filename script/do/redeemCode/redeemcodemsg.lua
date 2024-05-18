
--领取消息
Net.CmdRedeemCodeGetSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.RedeemCodeGetSgnCmd_S"
	local RedeemCodeData = RedeemCode.RedeemCodeGet(uid,cmd.data.redeemcodeId)


	-- -- 增加奖励
	-- BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, 1000, Const.GOODS_SOURCE_TYPE.REDEEMCODE)
	-- local RedeemCodeData = {
	-- 	rewardChips = 1000,
	-- }


	res["data"] = RedeemCodeData
	return res
end