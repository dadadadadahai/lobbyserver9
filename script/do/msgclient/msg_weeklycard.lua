-- -- 请求签到信息
-- Net.CmdUserWeeklyCardInfoRequestSgnCmd_C = function(cmd, laccount)
-- 	local res = {}
-- 	res["do"] = "Cmd.UserWeeklyCardInfoReturnSgnCmd_S"
-- 	local uid = laccount.Id
-- 	local signData = WeeklyCard.GetWeeklyCardInfo(uid)
-- 	res["data"] = signData
-- 	return res
-- end

-- -- 用户今日签到
-- Net.CmdUserWeeklyCardRequestSgnCmd_C = function(cmd, laccount)
-- 	local res = {}
-- 	res["do"] = "Cmd.UserWeeklyCardReturnSgnCmd_S"
-- 	local uid = laccount.Id
-- 	local cardType = cmd.data.cardType
-- 	local signData = WeeklyCard.GetWeeklyCardReward(uid, cardType)
-- 	res["data"] = signData
-- 	return res
-- end
-- -- 用户今日签到
-- Net.CmdUserWeeklyCardShopRequestSgnCmd_C = function(cmd, laccount)
-- 	local signData = WeeklyCard.ChargeCallBack(laccount.Id,601)
-- end