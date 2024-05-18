
--挑战

--201 获取挑战数据
Net.CmdGetMissionTablesCmd_C =function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local challengeInfo = {}
    challengeInfo = challengeMgr.GetMissionTables(uid)
    res["do"] = "Cmd.GetMissionTablesCmd_S"
    res["data"]=challengeInfo
	return res
end
--202玩子游戏 
Net.CmdPlayGamesCmd_C = function(cmd, laccount)

    local res = {}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = challengeMgr.PlayChallengeGame(uid,pos)
    res["do"] = "Cmd.PlayGamesCmd_S"
    local data ={
        gameInfo ={},
        diamonds =0,
    }
    for key, value in pairs(challengeInfo.games) do
        if value.pos ==pos then
            data.gameInfo = value
        end
    end
    data.diamonds = challengeInfo.diamonds

    res["data"]=data
	return res


end
--203花钱通过 子游戏任务 
Net.CmdBuyGameCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = challengeMgr.BuyTaskFinsh(uid,pos)
    res["do"] = "Cmd.BuyGameCmd_S"
    local data ={
        gameInfo ={},
        diamonds =0,
    }
    for key, value in pairs(challengeInfo.games) do
        if value.pos ==pos then
            data.gameInfo = value
        end
    end

    data.diamonds = challengeInfo.diamonds
    res["data"]=data
	return res
end




--204 领取子游戏任务奖励  
Net.CmdGetTaskRewardCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = challengeMgr.GetTaskReward(uid,pos)
    res["do"] = "Cmd.GetTaskRewardCmd_S"
    local data ={
        gameInfo ={},
        diamonds =0,
    }

    for key, value in pairs(challengeInfo.games) do
        if value.pos ==pos then
            data.gameInfo = value
        end
    end
    data.diamonds = challengeInfo.diamonds
    res["data"]=data
	return res
end

--205 领取钻石奖励 
Net.CmdGetDiamonRewardCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = challengeMgr.GetDiamonReward(uid,pos)
    res["do"] = "Cmd.GetDiamonRewardCmd_S"
    local data ={
        rewards={}
    }
    data.rewards = challengeInfo
    res["data"]=data
	return res
end



--206 排名展示及6级免费玩珍珠游戏界面
Net.CmdGetpearlRankShowCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = challengeMgr.pearlRankShow(uid,pos)
    res["do"] = "Cmd.GetpearlRankShowCmd_S"
    res["data"]=challengeInfo
	return res
end
