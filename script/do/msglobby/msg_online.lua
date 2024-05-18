
--大厅请求在线玩家列表
Lby.CmdReqZoneOnlineListLobby_CS = function(cmd, lobbytask) 

    local onlineList = go.accountmgr.GetOnlineList()
    local uids = {}
    local gameOnlineNum = {}
    local gameOnlineList = {}
    for i=1, #onlineList do
        local userInfo = chessuserinfodb.RUserInfoGet(onlineList[i])
        local rechargeFlag = 2
        if userInfo.property.totalRechargeChips > 0 then
            rechargeFlag = 1
        end

        local gameInfo = userInfo.gameInfo
        local userInfo = {
            uid = onlineList[i],
            subGameId = gameInfo.subGameId,
            subGameType = gameInfo.subGameType,
            regFlag = userInfo.base.regFlag,
            rechargeFlag = rechargeFlag,
            subplatid  = userInfo.base.subplatid,
        }

        table.insert(uids, userInfo)

        gameOnlineNum[gameInfo.subGameId] = gameOnlineNum[gameInfo.subGameId] or {}
        gameOnlineNum[gameInfo.subGameId][gameInfo.subGameType] = gameOnlineNum[gameInfo.subGameId][gameInfo.subGameType] or 0
        gameOnlineNum[gameInfo.subGameId][gameInfo.subGameType] = gameOnlineNum[gameInfo.subGameId][gameInfo.subGameType] + 1
    end

    --转换成数组
    for subGameId, subGameOnlineList in pairs(gameOnlineNum) do
        for subGameType, onlineNum in pairs(subGameOnlineList)  do
            table.insert(gameOnlineList, {
                subGameId = subGameId,
                subGameType = subGameType,
                onlineNum   = onlineNum,
            })
        end
    end

    cmd.data.uids = uids
    cmd.data.gameOnlineNum = gameOnlineList
    unilight.success(lobbytask, cmd)
end 
