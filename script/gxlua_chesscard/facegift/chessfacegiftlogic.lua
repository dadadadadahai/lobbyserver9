module('chessfacegiftlogic', package.seeall)

-- 结果码 0表示成功 1表示失败
RET_SUCC = 0
RET_FAIL = 1

function CmdGive(uid, roomId, giftId, revSet, costType)
	costType = costType or 0

	local usrInfo = chessuserinfodb.RUserBaseInfoGet(chessuserinfodb.RUserInfoGet(uid))
	local userChips = 0
	if costType == 0 then
		userChips = usrInfo.bankChips
	else
		userChips = usrInfo.remainder
	end

	if TableFaceGift[giftId] == nil then
		return RET_FAIL, "表情礼物不存在"
	end
	local set = {}
	for k,v in pairs(revSet) do
		if v == uid then return RET_FAIL, "没有玩家可赠送" end
		if v > 0 then table.insert(set, v) end
	end

	local cost = TableFaceGift[giftId].cost
	cost = cost * table.len(set)
	if cost == 0 then
		return RET_FAIL, "没有玩家可赠送"
	end

	if userChips < cost then
		return RET_FAIL, "银行存款不足 赠送失败"
	end
	local remainder = 0
	if costType == 0 then
		remainder = chessuserinfodb.WBankChipsChange(uid, 2, cost)
	else
		remainder = chessuserinfodb.WChipsChange(uid, 2, cost, "送礼消耗")
	end
	-- 赠送广播
	local doInfo = "Cmd.GiveFaceGiftCmd_Brd"
	local doData = {
		uid = uid,
		giftId = giftId,
		userSet = set,
		remainder = remainder,
	}
	roomUtil.CmdMsgBrd(doInfo, doData, roomId)
	return RET_SUCC
end
