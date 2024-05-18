--处理来自游戏的消息

--游戏通增大厅加历史记录
Zone.CmdReqHistoryInfoGame_CS = function(cmd, zonetask) 
    -- -- print("大厅11111111111111111="..table2json(cmd))
    -- local gameId = cmd.data.gameId
    -- local gameType = cmd.data.gameType
    -- -- local gameKey = gameId * 10000 + gameType

    -- --通知游戏做广播操作
    -- RoomInfo.BroadcastToAllZone("Cmd.ReqHistoryInfoGame_CS", cmd.data)
end 

--奖池排行榜更新
Zone.CmdJackpotRankInfoGame_CS = function(cmd, zonetask) 
    -- local jackpotInfo = {
        -- headUrl    = userInfo.base.headurl,
        -- nickName   = userInfo.base.nickname,
        -- chips      = chips,
        -- jackpotNum = jackpotNum,
        -- extData    = extData,
        -- uid        = uid,
    -- }
    -- local data = cmd.data
    -- local gameId     = data.gameId
    -- local gameType   = data.gameType
    -- local rankValue  = data.rankValue --排名值
    -- local nickName   = data.nickName  --玩家名字
    -- local jackpotMul = data.jackpotNum or 1   --jackpot图标数
    -- if jackpotMul == 1 then
    --     unilight.info("jackpot数量1:"..table2json(data))
    -- end
    -- local betMul     = data.betMul    --下注倍数
    -- local timestamp  = data.timestamp --时间
    -- local uid        = data.uid
    -- local chips      = data.chips  --奖池金额

    -- local rankKey = gameId * 100 + gameType   
    -- local rankList = RankListMgr:GetRankList(rankKey)
    -- if rankList == nil then
    --     unilight.error("jackpot 排行榜不存在的类型:"..rankKey)
    --     return
    -- end
    -- --如果小于上一次值则不更新
    -- local selfNode = rankList:GetNode(uid)
    -- if selfNode ~= nil then
    --         local lastValue = selfNode:GetLastValue()
    --         if rankValue < lastValue then
    --             -- unilight.info("奖池值小于上次，不更新: lastValue="..lastValue..", rankValue="..rankValue)
    --             return
    --         end
    -- end

    -- --更新排行榜
    -- local rankInfo = {}
    -- --用户名字
    -- rankInfo.name       = nickName      --玩家名字
    -- rankInfo.jackpotMul = jackpotMul    --jackpot倍数(倍数)
    -- -- rankInfo.timestamp = timestamp     --时间截
    -- rankInfo.chips     = chips         --奖池金额
    -- rankInfo.sortMaxValue = timestamp  --排序规则最大
    -- -- dump(rankInfo, "rankInfo")

    -- RankListMgr:UpdateRankNode(rankKey, uid, rankInfo, rankValue)
    -- --todo每次要刷新, 感觉有性能问题
    -- RankListMgr:SortRankByRankType(rankKey)

    -- --------------test
    
    -- if false then
    --     if gameId == 108 and gameType == 1 then
    --         dump(data, "108")
    --         RankListMgr:SaveToDB()
    --     end
    -- end
    -----------------------

end

--游戏内玩家请求排行榜
Zone.CmdGetListRankCmd_C = function(cmd, zonetask) 
    -- local rankType = cmd.data.rankType
    -- local startIndex = cmd.data.startIndex
    -- local endIndex = cmd.data.endIndex

    -- local nodeList = RankListMgr:ReqGetData(rankType)

	-- local res = {}
	-- res["do"] = "Cmd.GetListRankCmd_S"

    -- local data = {}
    -- data.uid = cmd.data.uid
    -- data.rankList = {}
    -- --填充我的排名信息
    -- local rankList = RankListMgr:GetRankList(rankType)
    -- if rankList == nil then
    --     unilight.error("游戏内请求排行榜找不到类型:"..rankType)
    --     return
    -- end
    -- if rankList ~= nil then
    --     local selfNode = rankList:GetNode(uid)
    --     if selfNode ~= nil then
    --         data.myRankInfo = {
    --             uid = selfNode:GetUid(),
    --             value = selfNode:GetLastValue(),
    --             rank = selfNode:GetRank(),
    --             rankInfo = selfNode:GetRankInfo(),
    --         } 
    --     end
    -- end

    -- if startIndex > Const.RANK.SHOW_COUNT then
    --     unilight.info("排行榜超过最大长度:"..rankType)
    --     return res
    -- end

    -- if endIndex > Const.RANK.SHOW_COUNT then
    --     endIndex = Const.RANK.SHOW_COUNT
    -- end

    -- --填充排名信息
    -- for index=startIndex, endIndex do
    --     local node = nodeList[index]
    --     if node == nil then 
    --         --unilight.error("GetListRankCmd_C 找不到index:"..index)
    --         res.data = data
    --         unilight.success(zonetask, res)
    --         return
    --     end
    --     local rankInfo = {
    --         uid = node:GetUid(),
    --         value = node:GetLastValue(),
    --         rank = node:GetRank(),
    --         rankInfo = node:GetRankInfo(),
    --     }
    --     table.insert(data.rankList, rankInfo)
    -- end
    -- res.data = data
    -- unilight.success(zonetask, res)
end

--消息转换到后台
Zone.CmdReqForwardToMonitor_CS = function(cmd, zonetask)
    -- unilight.info("CmdReqForwardToMonitor_CS = %s", table2json(cmd))
    go.buildProtoFwdServer(cmd.data.msgName, table2json(cmd.data.msg), "MS")
end
