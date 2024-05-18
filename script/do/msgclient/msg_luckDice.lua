--骰子游戏

--206 获取骰子 小游戏数据 
Net.CmdGetDiceGameInfoCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids

    local challengeInfo = {}
    challengeInfo = dicemgr.GetDicelInfo(uid,ids)
    res["do"] = "Cmd.GetDiceGameInfoCmd_S"
    local data ={
        ids =cmd.data.ids,
        multi = challengeInfo.multi
    }

    res["data"]=data
	return res
end

--玩骰子游戏
Net.CmdPlayLuckyDiceCmd_C = function (cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids

    local challengeInfo = {}
    challengeInfo = dicemgr.playLuckyDice(uid,ids)
    res["do"] = "Cmd.PlayLuckyDiceCmd_S"
    res["data"]=challengeInfo
	return res
end

--领取奖励
Net.CmdGetDiceRewardCmd_C = function (cmd,laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids
    local challengeInfo = {}
    challengeInfo = dicemgr.GetDiceReward(uid,ids)
    res["do"] = "Cmd.GetDiceRewardCmd_S"
    res["data"]=challengeInfo
	return res
    
end