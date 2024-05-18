module('LongHu',package.seeall)
function Settle(Table)
    local res={
        kong=0,
        hu = 0,
        rval = 0,           --1 龙赢 2和 3虎赢
        winScore = 0,       --玩家赢的钱
    }
    -- Table.Stock=30000
    local StockPercent = Table.Stock/table_205_sessions[Table.RoomId].initStock*100
    -- 0 随机 1系统赢 2系统输
    local sysWin = 0
    local stockcfg = table_205_stock[#table_205_stock]
    for i, v in ipairs(table_205_stock) do
        if StockPercent>=v.stockLow and StockPercent<=v.stockUp then
            stockcfg = v
            break
        end
    end
    if StockPercent>table_205_stock[1].stockUp then
        stockcfg = table_205_stock[1]
    end
    local RealManBet = Table.RealManBet
    if Table.Stock<=0 then
        sysWin = 1
    else
        --进入随机
        local r = math.random(100)
        if r<=stockcfg.gailv then
            if stockcfg.ID>=4 then
                sysWin = 1
            else
                sysWin = 2
            end
        end
    end
    local wins={}           --各个区域赢之后系统要赔付的钱
    for i=1,3 do
        wins[i] = RealManBet[i] * table_205_gailv[i].mul
        if Table.Stock-wins[i]<0 then
            sysWin=1
        end
    end 
    wins[2] = wins[2]  + math.floor(RealManBet[1]*table_205_other[Table.RoomId].backPercent/100) + math.floor(RealManBet[3]*table_205_other[Table.RoomId].backPercent/100)
    --系统赢
    local Index = 1
    if sysWin==0 then
        --随机产生
        Index = table_205_gailv[gamecommon.CommRandInt(table_205_gailv,'gailv')].ID
    elseif sysWin==1 then
        Index = sysWinRand(wins,RealManBet)
    elseif sysWin==2 then
        Index = sysLostRand(wins,RealManBet)
    end
    -- print('sysWin='..sysWin..',index='..Index..',stockcfg='..stockcfg.ID..',StockPercent='..StockPercent)
    res.winScore = wins[Index]
    print('sysWin',sysWin,table2json(wins),Index,Table.Stock,table2json(RealManBet))
    -- Index = 2
    if Index==1 then
        --虎赢
        res.long,res.hu = CreateBigSmall()
    elseif Index==2 then
        --和
        res.hu,res.long = CreateEq()
    else
        --龙赢
        res.hu,res.long = CreateBigSmall()
    end
    res.rval = GetFinall(res.long,res.hu)
    -- print(string.format('stock=%d,syswin=%d,StockPercent=%d,ID=%d',Table.Stock,sysWin,StockPercent,stockcfg.ID))
    return res
end
--系统赢判定函数
function sysWinRand(wins,RealManBet)
    local realArrays={}
    local realSys = 0
    local readTmp={}
    local tolBet = 0
    for i=1,3 do
        tolBet = tolBet + RealManBet[i]
    end
    readTmp[1] = tolBet - wins[1]
    if readTmp[1]>0 then
        table.insert(realArrays,1)
    end
    readTmp[2] = tolBet - wins[2]
    if readTmp[2]>0 then
        table.insert(realArrays,2)
    end
    readTmp[3] = tolBet - wins[3]
    if readTmp[3]>0 then
        table.insert(realArrays,3)
    end
    if table.empty(realArrays) then
        min = readTmp[1]
        for i=2,3 do
            if min> readTmp[i] then
                min = readTmp[i]
            end
        end
        for i=1,3 do
            if min==readTmp[i] then
                table.insert(realArrays,i)
            end
        end
    end
    print('#realArrays',#realArrays,table2json(readTmp))
    return realArrays[math.random(#realArrays)]
end
--系统输判定函数
function sysLostRand(wins,RealManBet)
    local realArrays={}
    local realSys = 0
    local readTmp={}
    readTmp[1] = RealManBet[2]+RealManBet[3] - wins[1]
    if readTmp[1]<=0 then
        table.insert(realArrays,1)
    end
    readTmp[2] = RealManBet[1] + RealManBet[3] - wins[2]
    if readTmp[2]<=0 then
        table.insert(realArrays,2)
    end
    readTmp[3] = RealManBet[1] + RealManBet[2] - wins[3]
    if readTmp[3]<=0 then
        table.insert(realArrays,3)
    end
    if table.empty(realArrays) then
        min = readTmp[1]
        for i=2,3 do
            if min> readTmp[i] then
                min = readTmp[i]
            end
        end
        for i=1,3 do
            if min==readTmp[i] then
                table.insert(realArrays,i)
            end
        end
    end
    print('#realArrays',#realArrays)
    return realArrays[math.random(#realArrays)]
end




function SellteResult(result,Table)
   local res={
        long = result.long,
        hu = result.hu,
        rval = result.rval,
        winScore = 0,
        leftSit={},
        rightSit={},
   }
   local mapWin={}
   local mul={2,9,2}
   local realWin = 0            --实际玩家赢取
   local mapAreaWin = {}
   for k, v in pairs(Table.PlayMap) do
        local betChip = 0
        for _, bet in ipairs(v.bets) do
            betChip = betChip + bet
        end
        local rchip = 0
        if v.IsRobot==false then
            rchip =  chessuserinfodb.RUserChipsGet(k)
        end
        mapAreaWin[k] = {0,0,0}         --区域和退费
        if betChip>0 then
            local winScore = v.bets[result.rval]*mul[result.rval]
            -- mapAreaWin[k][result.rval] = winScore
            if result.rval==2 then
                if v.bets[1]>0 then
                    -- winScore = math.floor(v.bets[1]*(table_205_other[Table.RoomId].backPercent/100))
                    mapAreaWin[k][1] = math.floor(v.bets[1]*(table_205_other[Table.RoomId].backPercent/100))
                    if v.IsRobot==false then
                        Table.Stock=Table.Stock  - mapAreaWin[k][1]
                    end
                elseif v.bets[3]>0 then
                    -- winScore = math.floor(v.bets[3]*(table_205_other[Table.RoomId].backPercent/100))
                    mapAreaWin[k][3] = math.floor(v.bets[3]*(table_205_other[Table.RoomId].backPercent/100))
                    if v.IsRobot==false then
                        Table.Stock=Table.Stock  - mapAreaWin[k][3]
                    end
                end
            end
            local tax = 0
            if winScore>0 then
                if v.IsRobot==false then
                    realWin = realWin + winScore
                end
                local aWinScore = math.floor(winScore*(1-table_205_other[Table.RoomId].tax/100))
                tax = winScore - aWinScore
                winScore = aWinScore
                if v.IsRobot==false then
                    -- print('k='..k..',winscore='..winScore)
                    BackpackMgr.GetRewardGood(k, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.LongHu)
                    local rtchip = winScore - betChip
                    if rtchip>0 then
                        WithdrawCash.AddBet(k,rtchip)
                    elseif rtchip<0 then
                        rtchip = math.abs(rtchip)
                        cofrinho.AddCofrinho(k,rtchip)
                    end
                end
                mapWin[k] = winScore
            else
                --纯输
                if v.IsRobot==false then
                    cofrinho.AddCofrinho(k,betChip)
                end
            end
            local returnChip = ReturnChipCalc(mapAreaWin[k])
            if v.IsRobot==false then
                print('returnChip='..returnChip)
            end
            if returnChip>0 and v.IsRobot==false then
                BackpackMgr.GetRewardGood(k, Const.GOODS_ID.GOLD, returnChip, Const.GOODS_SOURCE_TYPE.LongHu)
            end
            if v.IsRobot then
                SettleRecord(k,betChip,winScore,v.nickname,v.headurl,Table.robot:GetGold(k))
            else
                SettleRecord(k,betChip,winScore,v.nickname,v.headurl,chessuserinfodb.RUserChipsGet(k))
            end
            if v.IsRobot==false then

                Table.tax = Table.tax + tax
                --记录日志
                gameDetaillog.SaveDetailGameLog(
                    k,
                    os.time(),
                    GameId,
                    Table.RoomId,
                    v.bets,
                    rchip + betChip,
                    chessuserinfodb.RUserChipsGet(k),
                    tax,
                    {type='normal',long = result.long,hu=result.hu},
                    {}
                )
            end
        end
        v.bets={0,0,0}
        if v.isDrop and v.IsRobot==false then
            Table.PlayMap[k]=nil
            local userData = chessuserinfodb.GetUserDataById(k)
            IntoGameMgr.ClearUserCurStatus(userData)
            gamecommon.UserLogoutGameInfo(k, GameId, Table.RoomId)
            UserLeavel(k,Table.RoomId)
        end
    end
    local rebotWinScoreMap ={}
    --构建机器人调用
    for key, value in pairs(mapWin) do
        local uinfo = Table.PlayMap[key]
        if uinfo~=nil and uinfo.IsRobot then
            rebotWinScoreMap[key] = value + ReturnChipCalc(mapAreaWin[key])
        end
    end
    local sideWinMap={}
    for _, value in ipairs(Table.leftSit) do
        if mapWin[value.uid]~=nil and sideWinMap[value.uid]==nil then
            sideWinMap[value.uid] =mapWin[value.uid]
        end
    end
    for _, value in ipairs(Table.rightSit) do
        if mapWin[value.uid]~=nil and sideWinMap[value.uid]==nil then
            sideWinMap[value.uid] = mapWin[value.uid]
        end
    end
    local sideWinArray = {}
    for key, value in pairs(sideWinMap) do
        table.insert(sideWinArray,{uid=key,winScore = value})
    end
    Table.robot:ChangeToSettle(rebotWinScoreMap)
    FinRecord(Table)
    res.leftSit = Table.leftSit
    res.rightSit = Table.rightSit
    res.sideWinArray=sideWinArray
    local sdata={}
    sdata['do'] = 'Cmd.LongHuSettleCmd_S'
    sdata['data'] = res
    for k, v in pairs(Table.PlayMap) do
        if mapWin[k]~=nil then
            res.winScore = mapWin[k]
            res.draw = ReturnChipCalc(mapAreaWin[k])
        else
            res.winScore = 0
        end
        if v.IsRobot==false then
            unilight.sendcmd(k,sdata)
        end
    end
    --改变库存
    local tableTolChip = 0
    for i, v in ipairs(Table.RealManBet) do
        tableTolChip = tableTolChip + v
    end
    --库存变化
    Table.Stock = Table.Stock + (tableTolChip - realWin)
    Table.TableBets = {0,0,0}
    Table.RealManBet ={0,0,0}
    Table.OtherTableBets = {0,0,0}
end



--产生大小牌面 返回1大 2小
function CreateBigSmall()
    while true do
        local one,two={math.random(4),math.random(13)},{math.random(4),math.random(13)}
        if one[2]>two[2] then
            return one,two
        elseif one[2]<two[2] then
            return two,one
        else
            --值相同
            if one[1]>two[1] then
                return one,two
            elseif one[1]<two[1] then
                return two,one
            end
        end
    end
end
--产生和牌
function CreateEq()
    local sameColour = math.random(4)
    local samePoint = math.random(13)
    return {sameColour,samePoint},{sameColour,samePoint}
end
--判断结果
--1 龙 2 和 3虎
function GetFinall(long,hu)
    if long[2]>hu[2] then
        return 1
    elseif long[2]<hu[2] then
        return 3
    else
        if long[1]>hu[1] then
            return 1
        elseif long[1]<hu[1] then
            return 3
        else
            return 2
        end
    end
end

--[[
    就算和局退费
]]
function ReturnChipCalc(mapAreaWin)
    local chip = 0
    for _, value in ipairs(mapAreaWin) do
        chip =chip + value
    end
    return chip
end