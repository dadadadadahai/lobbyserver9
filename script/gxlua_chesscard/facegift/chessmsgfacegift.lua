
-- 赠送表情礼物
Net.CmdGiveFaceGiftCmd_C = function(cmd, laccount)
	local res = {}
	local data = cmd.data
	res["do"] = "Cmd.GiveFaceGiftCmd_S"

	if data.giftId == nil or data.roomId == nil or data.roomId <= 0 then
		res["data"] = {
			resultCode = 1,
			desc = "参数错误",
		}
		return res
	end
	local uid = laccount.Id
	local roomId = data.roomId
	local sendType = data.sendType or 0 
	if sendType == 1 then
		data.revSet = roomUtil.CmdRoomUserUidGet(roomId, uid) 			
	end

	if data.revSet == nil or table.empty(data.revSet) then
		res["data"] = {
			resultCode = 2,
			desc = "送礼玩家数目为0",
		}
		return res
	end

	local ret, desc = chessfacegiftlogic.CmdGive(uid, data.roomId, data.giftId, data.revSet, data.costType)
	if ret ~= 0 then
		res["data"] = {
		resultCode = ret,
		desc = desc,
	}
	return res
	end
end
