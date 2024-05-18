--请求游戏场景数据
Net.CmdEnterSceneGame_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res["do"]="Cmd.EnterSceneGame_S"
    res["data"]={}
    local uid=laccount.Id
   
    local resdata=gamecommon.CmdEnterGame(cmd.data.gameId, uid, cmd.data)
    res["data"]=resdata
    --return res
end
Net.CmdBuyHighBetCmd_C=function (cmd,laccount)
    local uid = laccount.Id
    local res={}
    res["do"]="Cmd.EnterSceneGame_S"
    res["data"]={}
    local uid=laccount.Id
    local resdata=gamecommon.CmdBuyHighBetCmd(cmd.data.gameId, uid, cmd.data)
    res["data"]=resdata
    --return res
end
--请求游戏操作
Net.CmdGameOprateGame_C=function (cmd,laccount)
    --全局变量
    SuserId.uid = laccount.Id
    
    gamestockredis.loadStock(cmd.data.gameId,cmd.data.gameType)
    local uid = laccount.Id
    local res={}
    res["do"]="Cmd.GameOprateGame_S"
    local resdata=gamecommon.CmdGameOprate(cmd.data.gameId, uid, cmd.data)
    res["data"] = resdata
    local gameId = cmd.data.gameId
    local gameType = cmd.data.gameType
    if gamecommon.allGameManagers[gameId] ~= nil and gamecommon.allGameManagers[gameId].Get~=nil then
        local userInfo = unilight.getdata('userinfo', uid)
        local module = gamecommon.allGameManagers[gameId]
        --[[
            进行玩家数据统计
        ]]
        local unsettleInfo = userInfo.unsettleInfo or {}
        local key = gameId * 100 + gameType
        local gDataInfo = module.Get(gameType, uid)
        if gDataInfo ~= nil then
            local specialScene = { 'bonus', 'pick', 'free', 'respin', 'collect' }
            local btWinScore = unsettleInfo[key] or 0
            local atWinScore = 0
            local isExistSpecil = (gameId~=109)         --特殊处理
            for _, value in ipairs(specialScene) do
                if table.empty(gDataInfo[value]) ==false and gDataInfo[value].tWinScore ~= nil and gDataInfo[value].tWinScore > 0 then
                    local isNotOverTimes = false
                    if gDataInfo[value].times ~= nil then
                        isNotOverTimes = gDataInfo[value].times < gDataInfo[value].totalTimes
                    else
                        isNotOverTimes = gDataInfo[value].lackTimes > 0
                    end
                    if isNotOverTimes then
                        atWinScore = atWinScore + gDataInfo[value].tWinScore
                    end
                end
            end
            if isExistSpecil then
                print('unsettleInfo[key] = atWinScore',atWinScore)
                unsettleInfo[key] = atWinScore
                userInfo.unsettleInfo = unsettleInfo
                unilight.update('userinfo', uid, userInfo)
            end
        end
        --更新下下注金额
        local betMoney  = gamecommon.GetBetMoneyByGame(uid, gameId, gameType) 
        local lineNum   = gamecommon.GetGameLineNum(gameId)
        userInfo.property.betMoney = betMoney * lineNum
        unilight.update('userinfo', uid, userInfo)
    end
    --return res
 
    SuserId.uid = 0
end

--请求游戏操作
Net.CmdBuyFreeCmd_C=function (cmd,laccount)
    --全局变量
    SuserId.uid = laccount.Id

    gamestockredis.loadStock(cmd.data.gameId,cmd.data.gameType)
    local uid = laccount.Id
    local res={}
    res["do"]="Cmd.GameOprateGame_S"
    local resdata=gamecommon.CmdBuyFreeCmd(cmd.data.gameId, uid, cmd.data)
    res["data"] = resdata
    local gameId = cmd.data.gameId
    local gameType = cmd.data.gameType
    if gamecommon.allGameManagers[gameId] ~= nil and gamecommon.allGameManagers[gameId].Get~=nil then
        local userInfo = unilight.getdata('userinfo', uid)
        local module = gamecommon.allGameManagers[gameId]
        --[[
            进行玩家数据统计
        ]]
        local unsettleInfo = userInfo.unsettleInfo or {}
        local key = gameId * 100 + gameType
        local gDataInfo = module.Get(gameType, uid)
        if gDataInfo ~= nil then
            local specialScene = { 'bonus', 'pick', 'free', 'respin', 'collect' }
            local btWinScore = unsettleInfo[key] or 0
            local atWinScore = 0
            local isExistSpecil = (gameId~=109)         --特殊处理
            for _, value in ipairs(specialScene) do
                if table.empty(gDataInfo[value]) ==false and gDataInfo[value].tWinScore ~= nil and gDataInfo[value].tWinScore > 0 then
                    local isNotOverTimes = false
                    if gDataInfo[value].times ~= nil then
                        isNotOverTimes = gDataInfo[value].times < gDataInfo[value].totalTimes
                    else
                        isNotOverTimes = gDataInfo[value].lackTimes > 0
                    end
                    if isNotOverTimes then
                        atWinScore = atWinScore + gDataInfo[value].tWinScore
                    end
                end
            end
            if isExistSpecil then
                print('unsettleInfo[key] = atWinScore',atWinScore)
                unsettleInfo[key] = atWinScore
                userInfo.unsettleInfo = unsettleInfo
                unilight.update('userinfo', uid, userInfo)
            end
        end
        --更新下下注金额
        local betMoney  = gamecommon.GetBetMoneyByGame(uid, gameId, gameType) 
        local lineNum   = gamecommon.GetGameLineNum(gameId)
        userInfo.property.betMoney = betMoney * lineNum
        unilight.update('userinfo', uid, userInfo)
    end
    --return res

    SuserId.uid = 0
end


--改变下注
Net.CmdChangeBetCmd_C = function (cmd,laccount)
    local uid = laccount.Id
    gamecommon.CmdChangeBet(cmd.data.gameId,uid,cmd.data)
end


--请求jackpot历史记录
Net.CmdGetJackpotHistoryGame_C = function (cmd,laccount)
    local uid = laccount.Id
    gamecommon.SendJackpotHisoryToMe(uid, cmd.data.gameId, cmd.data.gameType)
end
