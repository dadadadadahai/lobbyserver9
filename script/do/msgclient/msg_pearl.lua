--珍珠小游戏

--206 获取 小游戏数据 
Net.CmdGetPearlGameInfoCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids

    local challengeInfo = {}
    challengeInfo = pearlmgr.GetPearlInfo(uid,ids)
    res["do"] = "Cmd.GetPearlGameInfoCmd_S"
        local infos={}
        for index, value in pairs(challengeInfo.pearlInfo) do
            table.insert(infos,{pos=value.pos, goodNum = value.goodNum, type  = value.type})
        end

        local data ={
            pearlInfos=infos,
            special1=challengeInfo.special1,
            special2=challengeInfo.special2,
            special3=challengeInfo.special3,
            special4=challengeInfo.special4,
            totalwin=challengeInfo.totalwin,
            rewardpos=ids,
            multi = challengeInfo.multi
        }

    res["data"]=data
	return res
end

--207 玩小游戏 
Net.CmdplayPearlGamesCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids
    local pos = cmd.data.pos
    local challengeInfo = {}
    challengeInfo = pearlmgr.playPearl(uid,ids,pos)
    res["do"] = "Cmd.playPearlGamesCmd_S"
    res["data"]=challengeInfo
	return res
end

--208领取奖励
Net.CmdGetPearlRewardCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local ids = cmd.data.ids

    local challengeInfo = {}
    challengeInfo = pearlmgr.GetPearlReward(uid,ids)
    res["do"] = "Cmd.GetPearlRewardCmd_S"
        local data ={
            totalwin=challengeInfo.totalwin;
            status=challengeInfo.status;
        }
    res["data"]=data
	return res
end
