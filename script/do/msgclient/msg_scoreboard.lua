-- 积分榜消息相关处理

-- 玩家积分榜进入所需数据
Net.CmdScoreBoardInfoRequestScbCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ScoreBoardInfoReturnScbCmd_S"
	local uid = laccount.Id
	local scoreBoardInfo = ScoreBoard.ScoreBoardInfoGet(uid)
	res["data"] = {
		startTime = scoreBoardInfo.startTime,
		endTime = scoreBoardInfo.endTime,
		goldCoin = scoreBoardInfo.goldCoin,
		lowestScore = scoreBoardInfo.lowestScore,
		useGem = scoreBoardInfo.useGem,
		rankId = scoreBoardInfo.rankId,
		level = scoreBoardInfo.level,
		rewardList = scoreBoardInfo.rewardList,
		score = scoreBoardInfo.score,
	}
	return res
end

-- 玩家购买BUFF请求
Net.CmdScoreBoardBuyBuffRequestScbCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ScoreBoardBuyBuffReturnScbCmd_S"
	local uid = laccount.Id
	local scoreBoardInfo = ScoreBoard.ScoreBoardGetBuff(uid)
	res["data"] = {
		successBuyBuff = scoreBoardInfo.successBuyBuff,
		useGem = scoreBoardInfo.useGem,
	}
	return res
end

-- 排行榜结算主动下发
Net.CmdScoreBoardTheEndRequestaScbCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ScoreBoardTheEndReturnScbCmd_S"
	local uid = laccount.Id
	local scoreBoardInfo = ScoreBoard.EndScoreBoardGetReward(uid)
	res["data"] = {
		canReward = scoreBoardInfo.canReward,
		level = scoreBoardInfo.level,
		oldLevel = scoreBoardInfo.oldLevel,
		goldCoin = scoreBoardInfo.goldCoin,
		rewardList = scoreBoardInfo.rewardList,
		oldRankInfo = scoreBoardInfo.oldRankInfo,
	}
	return res
end

-- 玩家增加积分请求 测试
Net.CmdScoreBoardAddScoreRequestScbCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ScoreBoardAddScoreReturnScbCmd_S"
	local uid = laccount.Id
	local bet = cmd.data.bet
	local type = cmd.data.type
	ScoreBoard.AddScore(uid,bet,type)
	res["data"] = {
	}
	return res
end
