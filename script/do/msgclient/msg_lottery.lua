
-- 玩家彩票类别 （ 0、玩家自选 1、玩家随机 ）
Optional_Lottery = 0
Random_Lottery = 1

-- 请求彩票信息
Net.CmdUserLotteryInfoRequestLtyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserLotteryInfoReturnLtyCmd_S"
	local uid = laccount.Id
	local lotteryInfo = Lottery.CmdUserLotteryInfoGet(nil,uid)
	res["data"] = {
		lotteryNbrList = lotteryInfo.lotteryNbrList,
		jackpotRecord = lotteryInfo.jackpotRecord,
		historicalAllRecords = lotteryInfo.historicalAllRecords,
		historicalStatisticalRecords = lotteryInfo.historicalStatisticalRecords,
		lotteryDate = lotteryInfo.lotteryDate,
		startTime = lotteryInfo.startTime,
		endTime = lotteryInfo.endTime,
	}
	return res
end

-- 用户使用彩票
Net.CmdUserLotteryRequestLtyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserLotteryReturnLtyCmd_S"
	local uid = laccount.Id
	local flag = cmd.data.flag
	local lotteryNbr = nil
	local residueLotteryNbr = nil
	if flag == Random_Lottery then
		residueLotteryNbr, lotteryNbr = Lottery.GetLotteryNumbers(uid)
	end

	if flag == Optional_Lottery then
		local lotteryRedNbr = cmd.data.lotteryNbr.redNbr
		local lotteryWhiteNbr = cmd.data.lotteryNbr.whiteNbr
		residueLotteryNbr, lotteryNbr = Lottery.GetLotteryNumbers(uid, lotteryRedNbr, lotteryWhiteNbr)
	end

	res["data"] = {
		residueLotteryNbr = residueLotteryNbr,
		lotteryNbr = lotteryNbr,
	}
	return res
end
