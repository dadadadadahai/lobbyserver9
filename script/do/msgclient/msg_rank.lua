
-- 获取排行榜列表
Net.CmdGetListRankCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetListRankCmd_S"
	local uid = laccount.Id

    local rankType = cmd["data"].rankType
    local startIndex = cmd["data"].startIndex
    local endIndex = cmd["data"].endIndex

    if cmd["data"] == nil or type(rankType) ~= "number" or 
    type(startIndex) ~= "number" or type(endIndex) ~= "number" then
        res["data"] = {
            errno = 1,
            desc = "数据出错"
        }
        return res
    end


    if startIndex > endIndex then
        res["data"] = {
            errno = 2,
            desc = "数据出错"
        }
        return res
    end

    --不在大厅，要转到大厅请求下
    if unilight.getgameid() ~= Const.GAME_TYPE.LOBBY then
        cmd.data.uid = uid
        ChessToLobbyMgr.SendCmdToLobby("Cmd.GetListRankCmd_C", cmd.data)
        return
    end

    local nodeList = RankListMgr:ReqGetData(rankType)

    if nodeList == nil then
        res["data"] = {
            errno = 3,
            desc = "数据rankType出错"
        }
        return res
    end
    local data = {}
    data.rankList = {}
    --填充我的排名信息
    local rankList = RankListMgr:GetRankList(rankType)
    if rankList ~= nil then
        local selfNode = rankList:GetNode(uid)
        if selfNode ~= nil then
            data.myRankInfo = {
                uid = selfNode:GetUid(),
                value = selfNode:GetLastValue(),
                rank = selfNode:GetRank(),
                rankInfo = selfNode:GetRankInfo(),
            } 
        else
            --特殊处理下slots信息
            if rankType == Const.RANK_TYPE.SLOTS_WIN_CHIPS then
                local userInfo = chessuserinfodb.RUserInfoGet(uid)
                data.myRankInfo = {
                    uid = uid,
                    value = userInfo.property.slotsWins,
                    rank = 0,
                    rankInfo = {},
                } 
            end

        end
            --实时刷新下自己的值
            if rankType == Const.RANK_TYPE.SLOTS_WIN_CHIPS then
                local userInfo = chessuserinfodb.RUserInfoGet(uid)
                data.myRankInfo.value = userInfo.property.slotsWins
            end
    end

    if startIndex > Const.RANK.SHOW_COUNT then
        return res
    end

    if endIndex > Const.RANK.SHOW_COUNT then
        endIndex = Const.RANK.SHOW_COUNT
    end

    --填充排名信息
    for index=startIndex, endIndex do
        local node = nodeList[index]
        if node == nil then 
            --unilight.error("GetListRankCmd_C 找不到index:"..index)
            res.data = data
            return res
        end
        local rankInfo = {
            uid = node:GetUid(),
            value = node:GetLastValue(),
            rank = node:GetRank(),
            rankInfo = node:GetRankInfo(),
        }
        table.insert(data.rankList, rankInfo)
    end
    res.data = data

	return res
end

-- 领取大赢家排行榜奖励
Net.CmdGetWinChipsRankRewardCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetWinChipsRankRewardCmd_S"

	-- 领取大赢家奖励
	local ret, desc, chips, remainder = RankMgr.GetWinChipsRankInfo(uid)

	res["data"] = {
		resultCode 	= ret, 
		desc 		= desc,
		chips 		= chips, 
		remainder 	= remainder, 
	}
	return res
end
