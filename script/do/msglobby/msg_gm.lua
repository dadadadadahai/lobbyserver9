--大厅请求修改库存
Lby.CmdEditStockNumCmd_S = function(cmd, lobbytask)
    local table_stock_tax = import "table/table_stock_tax"
    local stockNum = cmd.data.stockNum
    local gameId   = cmd.data.gameId
    local gameType = cmd.data.gameType
    local gameKey  = gameId * 10000 + gameType
    local taxPercent = cmd.data.taxPercent

    if gamestock.BackGetStock(gameId, gameType) ~= nil then
        gamestock.EditStock(gameId, gameType, stockNum)  --修改库存值

        local stockTaxConfig = table_stock_tax[gameKey]
        if stockTaxConfig ~= nil then
            stockTaxConfig.taxPercent = taxPercent
            unilight.info("gm修改抽水比例:"..taxPercent)
        end
        unilight.info("gm修改库存:"..stockNum)
        unilight.redis_sethashdata(Const.REDIS_HASH_NAME.STOCKNUM, tostring(gameKey), stockNum)

    else
        unilight.error("gm修改库存找不到游戏配置:"..gameId..", gametype="..gameType)
    end
end

--大厅请求修改系统rtp
Lby.CmdEditSysRtpCmd_S = function(cmd, lobbytask)
    local table_ctr_whole = import "table/table_ctr_whole"
    table_ctr_whole[1].wholeXs = cmd.data.sysRtp
    table_ctr_whole[2].wholeXs = cmd.data.regRtp
    unilight.info(string.format("gm设置系统rtp:"..cmd.data.sysRtp..", 非投放rtp:"..cmd.data.regRtp))
end

--大厅请求修改slots奖池信息
Lby.CmdEditSlotsPoolInfoCmd_S = function(cmd, lobbytask)
    local table_game_list = import "table/table_game_list"
    -- cmd.data {"fakepoolmin":30,"lowrechargertp":9700,"limitlow":0,"addrealpoolper":10,"fakepoolmax":40,"norechargertp":10000,"bomblooptime":10,"subgameid":112,"poolId":1,"subgametype":1,"rebatevalue":9900,"standardchips":120000,"realpoolchips":3000}
    local poolConfig = cmd.data
    local gameId     = poolConfig.subgameid
    local gameType   = poolConfig.subgametype
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    gameConfig.RTP4 = poolConfig.rebatevalue
    if (gameConfig.poolType == 1  or gameConfig.poolType == 0) then
        gamecommon.SetPoolConfig(gameId, gameType, poolConfig)
    elseif gameConfig.poolType == 3 then
        gamecommon.SetPoolConfigNew(gameId, gameType, poolConfig.poolId, poolConfig)
    elseif gameConfig.poolType == 5 then
        gamecommon.SetPoolConfig3(gameId, gameType, poolConfig)
    end
end

--大厅请求修改单机奖池信息
Lby.CmdEditSinglePoolInfoCmd_S = function(cmd, lobbytask)
    local table_game_list = import "table/table_game_list"
    -- {"fakepoolmin":30,"lowrechargertp":9700,"limitlow":0,"addrealpoolper":10,"fakepoolmax":40,"norechargertp":10000,"bomblooptime":10,"subgameid":112,"poolId":1,"subgametype":1,"rebatevalue":9900,"standardchips":120000,"realpoolchips":3000}

    local poolConfig = cmd.data
    local gameId     = poolConfig.subgameid
    local gameType   = poolConfig.subgametype
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    gamecommon.SetPoolConfig(gameId, gameType, poolConfig)
    gamecommon.GmSetHundredGameConfig(gameId, gameType, poolConfig)
end


