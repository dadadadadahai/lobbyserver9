module('WorldCup',package.seeall)
--结算计算函数
function Settle(Table)
    local res={
        position = 0,
        nId = 0,
        mul = 0,
        winScore = 0,           --用户赢的钱
    }
    local StockPercent = Table.Stock/table_206_sessions[Table.RoomId].initStock*100
    -- 0 随机 1系统赢 2系统输
    local sysWin = 0
    local stockcfg = table_206_stock[#table_206_stock]
    for i, v in ipairs(table_206_stock) do
        if StockPercent>=v.stockLow and StockPercent<=v.stockUp then
            stockcfg = v
            break
        end
    end
    if StockPercent>table_206_stock[1].stockUp then
        stockcfg = table_206_stock[1]
    end
    --local TableBets = Table.TableBets       --桌子区域下注信息
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
    for i=1,8 do
        wins[i] = RealManBet[i] * table_206_gailv[i].mul
        if Table.Stock-wins[i]<0 then
            sysWin=1
        end
    end
    if sysWin==0 then
        --纯随机
        local tcfg = table_206_gailv[gamecommon.CommRandInt(table_206_gailv,'gailv')]
        res.mul = tcfg.mul
        res.nId = tcfg.ID
    elseif sysWin==1 then
        --系统赢
        local minScore = wins[1]
        local minPos = {}       --最小的位置
        for _, v in ipairs(wins) do
            if v<minScore then
                minScore = v
            end
        end
        for i, v in ipairs(wins) do
            if v==minScore then
                table.insert(minPos,i)
            end
        end
        res.nId = minPos[math.random(#minPos)]
        res.mul = table_206_gailv[res.nId].mul
    else
        --系统输
        local maxScore = wins[1]
        local maxpos = {}       --最小的位置
        for _, v in ipairs(wins) do
            if v>maxScore then
                maxScore = v
            end
        end
        for i, v in ipairs(wins) do
            if v==maxScore then
                table.insert(maxpos,i)
            end
        end
        res.nId = maxpos[math.random(#maxpos)]
        res.mul = table_206_gailv[res.nId].mul
    end
    local positionPools={}
    for i, v in ipairs(Maps) do
        if v==res.nId then
            table.insert(positionPools,i)
        end
    end
    res.position = positionPools[math.random(#positionPools)]
    res.winScore = wins[res.nId]
    return res
end
--进行结算处置
function SellteResult(result,Table)
    local res={
        position = result.position,
        nId = result.nId,
        mul = result.mul,
        frontEight = {},
        uinfo ={},
        leftSit={},
        rightSit={},
    }
    local tmpWin ={}
    local mapWin={}
    local realWin = 0            --实际玩家赢取
    for k, v in pairs(Table.PlayMap) do
        local betChip = 0
        for i, bet in ipairs(v.bets) do
            betChip = betChip + bet
        end
        local rchip = 0
        if v.IsRobot==false then
            rchip =  chessuserinfodb.RUserChipsGet(k)
        end
        if betChip>0 then
            local winScore = v.bets[result.nId]*result.mul
            local tax = 0
            if winScore>0 then
                if v.IsRobot==false then
                    realWin = realWin + winScore
                end
                --扣税
                local aWinScore = math.floor(winScore*(1-table_206_other[Table.RoomId].tax/100))
                tax = winScore - aWinScore
                winScore = aWinScore
                if v.IsRobot==false then
                    BackpackMgr.GetRewardGood(k, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.WorldCup)
                end
                table.insert(tmpWin,{k,winScore})
                mapWin[k] = winScore
            end
            if v.IsRobot then
                SettleRecord(k,betChip,winScore,v.nickname,v.headurl,Table.robot:GetGold(k))
            else
                SettleRecord(k,betChip,winScore,v.nickname,v.headurl,chessuserinfodb.RUserChipsGet(k))
            end
            if v.IsRobot==false then
                local rtchip = winScore - betChip
                if rtchip>0 then
                    -- WithdrawCash.AddBet(k,rtchip)
                elseif rtchip<0 then
                    rtchip = math.abs(rtchip)
                    cofrinho.AddCofrinho(k,rtchip)
                end
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
                    {
                    type='normal',
                    position = result.position,
                    nId = result.nId,
                    mul = result.mul,},
                    {}
                )
            end
            v.bets={0,0,0,0,0,0,0,0}
            if v.isDrop and v.IsRobot==false then
                Table.PlayMap[k]=nil
                local userData = chessuserinfodb.GetUserDataById(k)
                IntoGameMgr.ClearUserCurStatus(userData)
                gamecommon.UserLogoutGameInfo(k, GameId, Table.RoomId)
                UserLeavel(k,Table.RoomId)
            end
        end
    end
    local rebotWinScoreMap ={}
    --构建机器人调用
    for key, value in pairs(mapWin) do
        local uinfo = Table.PlayMap[key]
        if uinfo~=nil and uinfo.IsRobot then
            rebotWinScoreMap[key] = value
        end
    end
    local sideWinMap={}
    for _, value in ipairs(Table.leftSit) do
        if mapWin[value.uid]~=nil and sideWinMap[value.uid]==nil then
            sideWinMap[value.uid] = mapWin[value.uid]
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
    --进行排序
    table.sort(tmpWin,function(a,b)
        return a[2]>b[2]
    end)
    for i=1,8 and #tmpWin do
        local uinfo = Table.PlayMap[tmpWin[i][1]]
        table.insert(res.frontEight,{headurl=uinfo.headurl,nickname=uinfo.nickname,winScore=tmpWin[i][2]})
    end
    res.leftSit = Table.leftSit
    res.rightSit = Table.rightSit
    res.sideWinArray=sideWinArray
    local sdata={}
    sdata['do'] = 'Cmd.WorldCupSettleCmd_S'
    sdata['data'] = res
    for k, v in pairs(Table.PlayMap) do
        if mapWin[k]~=nil then
            res.uinfo={
                winScore = mapWin[k]
            }
        else
            res.uinfo={winScore=0}
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
    Table.Stock = Table.Stock + (tableTolChip -realWin )
    Table.TableBets = {0,0,0,0,0,0,0,0}
    Table.RealManBet ={0,0,0,0,0,0,0,0}
    Table.OtherTableBets = {0,0,0,0,0,0,0,0}
end