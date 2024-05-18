module('KindQueen', package.seeall)
--[[
    牌型定义
]]
PokerType = {
    BaoZi = 6,
    ShunJin = 5,
    ShunZi = 4,
    JinHua = 3,
    DuiZi = 2,
    SanPai = 1,
}
function Settle(Table)
    local res = {
        guowang = {}, --国王的牌型
        wanghou = {}, --王后的牌型
        guowangType = 0,
        wanghouType = 0,
        winPos = 0, --1国王赢 2王后赢 3和
    }
    local StockPercent = Table.Stock / table_sessions[Table.RoomId].initStock * 100
    -- 0 随机 1系统赢 2系统输
    local sysWin = 0
    local stockcfg = table_stock[#table_stock]
    for i, v in ipairs(table_stock) do
        if StockPercent >= v.stockLow and StockPercent <= v.stockUp then
            stockcfg = v
            break
        end
    end
    if StockPercent > table_stock[1].stockUp then
        stockcfg = table_stock[1]
    end
    -- local RealManBet = Table.RealManBet
    if Table.Stock <= 0 then
        sysWin = 1
    else
        --进入随机
        local r = math.random(100)
        if r <= stockcfg.gailv then
            if stockcfg.ID >= 4 then
                sysWin = 1
            else
                sysWin = 2
            end
        end
    end
    local poker1, poker2 = {}, {}
    -- local pokerFuncs = { createLeopard, createShunJIn, createShun, createJinHua, createPair, createScatterCard }
    if sysWin == 0 then
        --纯随机状态
        --先随概率1
        local cfggailv1 = table_gailv1[gamecommon.CommRandInt(table_gailv1, 'gailv')]
        --判断是否出和
        -- local hegailv   = math.random(10000)
        -- if hegailv <= cfggailv1.hegailv then
        --     --产生和牌
        --     poker1, poker2 = CreateHe(pokerFuncs[cfggailv1.ID])
        --     res.guowang = poker1
        --     res.wanghou = poker2
        -- else
        --随机国王还是王后
        local winPos    = table_gailv2[gamecommon.CommRandInt(table_gailv2, 'gailv')].ID
        --产生不是和的牌型
        poker1, poker2  = CreateNotHe(cfggailv1.ID)
        if winPos == 1 then
            res.guowang = poker1
            res.wanghou = poker2
        else
            res.guowang = poker2
            res.wanghou = poker1
        end
        -- end
    elseif sysWin == 1 then
        --系统赢
        local winScore = math.abs(Table.RealManBet[1] - Table.RealManBet[3])
        local maxType = 0
        for index, value in ipairs(table_gailv1) do
            if winScore - Table.RealManBet[2] * value.mul > 0 then
                maxType = value.ID
                break
            end
        end
        poker1, poker2 = CreateNotHe(maxType)
        if Table.RealManBet[1] > Table.RealManBet[3] then
            res.guowang = poker2
            res.wanghou = poker1
        elseif Table.RealManBet[1] < Table.RealManBet[3] then
            res.guowang = poker1
            res.wanghou = poker2
        else
            local pokers = {poker1,poker2}
            local pokerIndex  = math.random(#pokers)
            res.guowang = pokers[pokerIndex]
            table.remove(pokers,pokerIndex)
            res.wanghou = pokers[1]
        end
    elseif sysWin == 2 then
        --系统输
        local winScore = math.abs(Table.RealManBet[1] - Table.RealManBet[3])
        local maxType = 0
        for index, value in ipairs(table_gailv1) do
            if winScore + Table.RealManBet[2] * value.mul <= Table.Stock then
                maxType = value.ID
                break
            end
        end
        poker1, poker2 = CreateNotHe(maxType)
        if Table.RealManBet[1] > Table.RealManBet[3] then
            res.guowang = poker1
            res.wanghou = poker2
        elseif Table.RealManBet[1] < Table.RealManBet[3] then
            res.guowang = poker2
            res.wanghou = poker1
        else
            local pokers = {poker1,poker2}
            local pokerIndex  = math.random(#pokers)
            res.guowang = pokers[pokerIndex]
            table.remove(pokers,pokerIndex)
            res.wanghou = pokers[1]
        end
    end
    --执行结算
    local result, resType = Compare(res.guowang, res.wanghou)
    res.guowangType = resType.poker1Type
    res.wanghouType = resType.poker2Type
    res.winPos = result
    local cardType = res.guowangType
    if res.winPos == 3 then
        cardType = res.wanghouType
    end
    table.insert(Table.HisTory, { areaIndex = res.winPos, cardType = cardType })
    if #Table.HisTory > 50 then
        table.remove(Table.HisTory, 1)
    end
    print("结算结果", res.winPos, res.guowangType, res.wanghouType)
    return res
end

--执行结算
function SellteResult(result, Table)
    local res = {
        guowang = result.guowang,
        wanghou = result.wanghou,
        guowangType = result.guowangType,
        wanghouType = result.wanghouType,
        rval = result.winPos,
        leftSit = {},
        rightSit = {},
    }
    local winPokerType = result.guowangType  --胜利方的牌型
    if result.winPos == 3 then
        winPokerType = result.wanghouType
    end
    local mulcfg = { 6, 5, 4, 3, 2, 1 }
    local mul = table_gailv1[mulcfg[winPokerType]].mul
    local mapWin = {}
    local mapAreaWin = {}
    local realWin = 0  --实际玩家赢取

    for k, v in pairs(Table.PlayMap) do
        local betChip = 0
        for _, bet in ipairs(v.bets) do
            betChip = betChip + bet
        end
        local rchip = 0
        if v.IsRobot == false then
            rchip = chessuserinfodb.RUserChipsGet(k)
        end
        if betChip > 0 then
            mapAreaWin[k] = { 0, 0, 0 }
            local winScore = 0
            if result.winPos == 2 then
                winScore = v.bets[1] * 0.5
                winScore = winScore + v.bets[3] * 0.5
                mapAreaWin[k][2] = winScore
            else
                winScore = v.bets[result.winPos] * 2
                mapAreaWin[k][result.winPos] = winScore
            end
            --判断牌型赔付区
            mapAreaWin[k][2] = mapAreaWin[k][2] + v.bets[2] * mul
            winScore = winScore + v.bets[2] * mul
            local tax = 0
            if winScore > 0 then
                if v.IsRobot == false then
                    realWin = realWin + winScore
                end
                local aWinScore = math.floor(winScore * (1 - table_other[Table.RoomId].tax / 100))
                tax = winScore - aWinScore
                winScore = aWinScore
                if v.IsRobot == false then
                    -- print('k='..k..',winscore='..winScore)
                    BackpackMgr.GetRewardGood(k, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.KindQueen)
                    local rtchip = winScore - betChip
                    if rtchip > 0 then
                        WithdrawCash.AddBet(k, rtchip)
                    elseif rtchip < 0 then
                        rtchip = math.abs(rtchip)
                        cofrinho.AddCofrinho(k, rtchip)
                    end
                end
                mapWin[k] = winScore
            else
                --纯输
                if v.IsRobot == false then
                    cofrinho.AddCofrinho(k, betChip)
                end
            end

            if v.IsRobot then
                SettleRecord(k, betChip, winScore, v.nickname, v.headurl, Table.robot:GetGold(k))
            else
                SettleRecord(k, betChip, winScore, v.nickname, v.headurl, chessuserinfodb.RUserChipsGet(k))
            end
            if v.IsRobot == false then
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
                    { type = 'normal', guowang = result.guowang, wanghou = result.wanghou },
                    {}
                )
            end
        end
        v.bets = { 0, 0, 0 }
        if v.isDrop and v.IsRobot == false then
            Table.PlayMap[k] = nil
            local userData = chessuserinfodb.GetUserDataById(k)
            IntoGameMgr.ClearUserCurStatus(userData)
            gamecommon.UserLogoutGameInfo(k, GameId, Table.RoomId)
            UserLeavel(k, Table.RoomId)
        end
    end
    local rebotWinScoreMap = {}
    --构建机器人调用
    for key, value in pairs(mapWin) do
        local uinfo = Table.PlayMap[key]
        if uinfo ~= nil and uinfo.IsRobot then
            rebotWinScoreMap[key] = value
        end
    end
    local sideWinMap = {}
    for _, value in ipairs(Table.leftSit) do
        if mapAreaWin[value.uid] ~= nil and sideWinMap[value.uid] == nil then
            sideWinMap[value.uid] = mapAreaWin[value.uid]
        end
    end
    for _, value in ipairs(Table.rightSit) do
        if mapAreaWin[value.uid] ~= nil and sideWinMap[value.uid] == nil then
            sideWinMap[value.uid] = mapAreaWin[value.uid]
        end
    end
    local sideWinArray = {}
    for key, value in pairs(sideWinMap) do
        table.insert(sideWinArray, { uid = key, winScore = value })
    end
    Table.robot:ChangeToSettle(rebotWinScoreMap)
    FinRecord(Table)
    res.leftSit = Table.leftSit
    res.rightSit = Table.rightSit
    res.sideWinArray = sideWinArray
    local sdata = {}
    sdata['do'] = 'Cmd.KindQueenSettleCmd_S'
    sdata['data'] = res
    for k, v in pairs(Table.PlayMap) do
        if mapAreaWin[k] ~= nil then
            res.winScore = mapAreaWin[k]
        else
            res.winScore = { 0, 0, 0 }
        end
        if v.IsRobot == false then
            unilight.sendcmd(k, sdata)
        end
    end
    --改变库存
    local tableTolChip = 0
    for i, v in ipairs(Table.RealManBet) do
        tableTolChip = tableTolChip + v
    end
    --库存变化
    Table.Stock = Table.Stock + (tableTolChip - realWin)
    Table.TableBets = { 0, 0, 0 }
    Table.RealManBet = { 0, 0, 0 }
    Table.OtherTableBets = { 0, 0, 0 }
end

--产生不是和的牌型
function CreateNotHe(pokindex)
    local pokerFuncs = { createLeopard, createShunJIn, createShun, createJinHua, createPair, createScatterCard }
    local rindex = math.random(pokindex, #pokerFuncs)
    while true do
        local poker1, Type1 = pokerFuncs[pokindex]()
        local poker2, Type2 = pokerFuncs[rindex]()
        --直接比较大小
        local res = Compare(poker1, poker2)
        if res == 1 then
            return poker1, poker2
        elseif res == 3 then
            return poker2, poker1
        end
    end
end

--产生和的牌型
function CreateHe(pokerFunc)
    local poker1, Type = pokerFunc()
    --使点数相等
    local poker2 = table.clone(poker1)
    if Type == PokerType.ShunJin or Type == PokerType.JinHua then
        --poker2花色相同,但和poker1不同
        local colors = { 1, 2, 3, 4 }
        for index, value in ipairs(colors) do
            if poker1[1][2] == value then
                table.remove(colors, index)
                break
            end
        end
        local color = gamecommon.ReturnArrayRand(colors)
        for index, value in ipairs(poker2) do
            poker2[index][2] = color
        end
    elseif Type == PokerType.ShunZi or Type == PokerType.DuiZi or Type == PokerType.SanPai then
        --poker1的花色map
        local colorMap = {}
        local sameColor = 0
        local sameColorIndex = 0
        for _, value in ipairs(poker1) do
            colorMap[value[1]] = colorMap[value[1]] or {}
            colorMap[value[1]][value[2]] = colorMap[value[1]][value[2]] or 0
            colorMap[value[1]][value[2]] = colorMap[value[1]][value[2]] + 1
        end
        for index, value in ipairs(poker2) do
            local tmpcolors = { 1, 2, 3, 4 }
            for i, k in ipairs(tmpcolors) do
                if colorMap[value[1]][k] ~= nil then
                    table.remove(tmpcolors, i)
                end
            end
            if index <= 2 or sameColorIndex == 0 then
                local tmpcolor = gamecommon.ReturnArrayRand(tmpcolors)
                if sameColor == tmpcolor then
                    sameColorIndex = sameColorIndex + 1
                else
                    sameColor = tmpcolor
                    sameColorIndex = 0
                end
                poker2[index][2] = tmpcolor
            else
                --tmpcolor 排除 sameColor
                for i, k in ipairs(tmpcolors) do
                    if k == sameColor then
                        table.remove(tmpcolors, i)
                        break
                    end
                end
                poker2[index][2] = gamecommon.ReturnArrayRand(tmpcolors)
            end
        end
    end
    return poker1, poker2
end

--比较两副牌的大小
--[[
    1 2 3   1 大 2和 3大
    {poker1Type,poker2Type}
]]
function Compare(poker1o, poker2o)
    local poker1 = table.clone(poker1o)
    local poker2 = table.clone(poker2o)
    table.sort(poker1, function(a, b)
        return a[1] < b[1]
    end)
    table.sort(poker2, function(a, b)
        return a[1] < b[1]
    end)
    local poker1Type = JudgePokerType(poker1)
    local poker2Type = JudgePokerType(poker2)
    local resPokerType = {
        poker1Type = poker1Type,
        poker2Type = poker2Type,
    }
    local resResult = 0
    if poker1Type > poker2Type then
        resResult = 1
    elseif poker1Type < poker2Type then
        resResult = 3
    else
        --牌型一样的判断
        for i = 1, 3 do
            if poker1[i][1] == 1 then
                poker1[i][1] = 14
            end
            if poker2[i][1] == 1 then
                poker2[i][1] = 14
            end
        end
        table.sort(poker1, function(a, b)
            return a[1] > b[1]
        end)
        table.sort(poker2, function(a, b)
            return a[1] > b[1]
        end)
        for i = 1, 3 do
            if poker1[i][1] > poker2[i][1] then
                resResult = 1
                break
            elseif poker1[i][1] < poker2[i][1] then
                resResult = 3
                break
            end
        end
        if resResult == 0 then
            resResult = 2
        end
    end
    return resResult, resPokerType
end

--[[
    判断牌型
]]
function JudgePokerType(poker)
    local numMap = {}
    local colorMap = {}
    --点数是否连续
    local isNumContinue = true
    local latestNum = 0
    for _, value in ipairs(poker) do
        numMap[value[1]] = numMap[value[1]] or 0
        numMap[value[1]] = numMap[value[1]] + 1
        colorMap[value[2]] = colorMap[value[2]] or 0
        colorMap[value[2]] = colorMap[value[2]] + 1
        if isNumContinue then
            if latestNum == 0 then
                latestNum = value[1]
            else
                if latestNum == 1 and value[1] == 12 then
                    latestNum = value[1]
                else
                    latestNum = latestNum + 1
                end
                if value[1] ~= latestNum then
                    isNumContinue = false
                end
            end
        end
    end
    local maxNum = 0
    local maxColor = 0
    for key, value in pairs(numMap) do
        if value > maxNum then
            maxNum = value
        end
    end
    for key, value in pairs(colorMap) do
        if value > maxColor then
            maxColor = value
        end
    end
    if maxNum == 3 then
        return PokerType.BaoZi
    end
    if isNumContinue then
        if maxColor == 3 then
            return PokerType.ShunJin
        else
            return PokerType.ShunZi
        end
    end
    if maxColor == 3 then
        return PokerType.JinHua
    end
    if maxNum == 2 then
        return PokerType.DuiZi
    end
    return PokerType.SanPai
end

--产生豹子牌型
function createLeopard()
    local pokerNum = math.random(13)
    local color = { 1, 2, 3, 4 }
    local poker = { {}, {}, {} }
    for i = 1, 3 do
        local rcolorIndex = math.random(#color)
        poker[i] = { pokerNum, color[rcolorIndex] }
        table.remove(color, rcolorIndex)
    end
    return poker, PokerType.BaoZi
end

--产生顺金牌型
function createShunJIn()
    --产生一个中间数
    local midNum = math.random(2, 13)
    local highNum, lowNum = midNum + 1, midNum - 1
    if highNum > 13 then
        highNum = 1
    end
    local color = math.random(4)
    local poker = { {
        lowNum, color
    }, {
        midNum, color
    }, {
        highNum, color
    } }
    return poker, PokerType.ShunJin
end

--产生顺子
function createShun()
    --产生一个中间数
    local midNum = math.random(2, 13)
    local highNum, lowNum = midNum + 1, midNum - 1
    if highNum > 13 then
        highNum = 1
    end
    local color = { 1, 2, 3, 4 }

    local poker = { {
        lowNum, gamecommon.ReturnArrayRand(color)
    }, {
        midNum, gamecommon.ReturnArrayRand(color)
    }, {
        highNum, gamecommon.ReturnArrayRand(color)
    } }
    return poker, PokerType.ShunZi
end

--产生金花牌型
function createJinHua()
    local midNum = math.random(2, 13)
    local highNum, lowNum = midNum + 1, midNum - 1
    if highNum > 13 then
        highNum = 1
    end
    local numArray = {}
    for i = 1, 13 do
        if i ~= midNum and i ~= highNum and i ~= lowNum then
            table.insert(numArray, i)
        end
    end
    local color = math.random(4)
    local poker = { {
        gamecommon.ReturnArrayRand(numArray), color
    }, {
        midNum, color
    }, {
        gamecommon.ReturnArrayRand(numArray), color
    } }
    return poker, PokerType.JinHua
end

--产生对子牌型
function createPair()
    local pairNum = math.random(1, 13)
    local color = { 1, 2, 3, 4 }
    local numArray = {}
    for i = 1, 13 do
        if i ~= pairNum then
            table.insert(numArray, i)
        end
    end
    local poker = { {
        pairNum, gamecommon.ReturnArrayRand(color),
    }, {
        pairNum, gamecommon.ReturnArrayRand(color),
    }, {
        gamecommon.ReturnArrayRand(numArray), math.random(4)
    } }
    return poker, PokerType.DuiZi
end

--产生散牌类型
function createScatterCard()
    local numArray = {}
    for i = 1, 13 do
        table.insert(numArray, i)
    end
    local onePoker = { gamecommon.ReturnArrayRand(numArray), math.random(4) }
    local twoPoker = { gamecommon.ReturnArrayRand(numArray), math.random(4) }
    local threePoker = { gamecommon.ReturnArrayRand(numArray), 0 }
    if onePoker[2] == twoPoker[2] then
        local colors = {}
        for i = 1, 4 do
            if i ~= onePoker[2] then
                table.insert(colors, i)
            end
        end
        threePoker[2] = gamecommon.ReturnArrayRand(colors)
    else
        threePoker[2] = math.random(4)
    end
    return {
        onePoker,
        twoPoker,
        threePoker
    }, PokerType.SanPai
end
