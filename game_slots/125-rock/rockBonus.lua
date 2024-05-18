module('rockgame', package.seeall)
-- function BonusProcess(type, lastInfo, datainfo)
--     table.insert(datainfo.bonusArray, { lastInfo = lastInfo, type = type })
-- end
--bonus预结算
function BonusHead(uid, gameType, type, lastInfo, cacheRes,datainfo)
    local result = {}
    if type == 1 then
        --重随棋牌
        local epos = lastInfo.epos
        local cols = { 8, 8, 8, 8, 8, 8, 8, 8 }
        local betinfo = {
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameId = GameId,
            gameType = gameType,
        }
        local latestChessdata = table.clone(lastInfo.chessdata)
        local spin = gamecommon.GetSpin(uid, GameId, gameType, betinfo)
        local chessdata, lastColRow = gamecommon.CreateSpecialChessData(cols, spin)
        result = NewOneceLogic(uid, GameId, gameType, false, epos, chessdata, lastColRow, spin,datainfo)
        table.insert(cacheRes, { result = result, type = 1,latestChessdata=latestChessdata})
    elseif type == 2 then
        --把一个图标全部变成wild
        local epos = lastInfo.epos
        local chessdata = lastInfo.chessdata
        local latestChessdata = table.clone(lastInfo.chessdata)
        local lastColRow = lastInfo.lastColRow
        local iconNumMap = CalcIconNum(chessdata)
        local keyGailvCfg = {}
        for key, num in pairs(iconNumMap) do
            if table_125_u2[key] ~= nil then
                table.insert(keyGailvCfg, { iconId = key, gailv = table_125_u2[key].gailv })
            end
        end
        --取随机图标变wild
        local chargeToId = keyGailvCfg[gamecommon.CommRandInt(keyGailvCfg, 'gailv')].iconId
        for col = 1, #chessdata do
            for row = 1, #chessdata[col] do
                if chessdata[col][row] == chargeToId then
                    chessdata[col][row] = 90
                end
            end
        end
        local betinfo = {
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameId = GameId,
            gameType = gameType,
        }
        local spin = gamecommon.GetSpin(uid, GameId, gameType, betinfo)
        result = NewOneceLogic(uid, GameId, gameType, false, epos, chessdata, lastColRow, spin,datainfo)
        table.insert(cacheRes, { result = result, type = 2,chargeToId=chargeToId,latestChessdata=latestChessdata})
    elseif type == 3 then
        --随机变一个2*2的图标格子
        local epos = lastInfo.epos
        local chessdata = lastInfo.chessdata
        local latestChessdata = table.clone(lastInfo.chessdata)
        local lastColRow = lastInfo.lastColRow
        local ID = table_125_u3[gamecommon.CommRandInt(table_125_u3, 'gailv')].ID
        local squarePos,rIconId = RandToSquare(1, ID, chessdata)
        local betinfo = {
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameId = GameId,
            gameType = gameType,
        }
        local spin = gamecommon.GetSpin(uid, GameId, gameType, betinfo)
        result = NewOneceLogic(uid, GameId, gameType, false, epos, chessdata, lastColRow, spin,datainfo)
        table.insert(cacheRes, { result = result, type = 3,squarePos=squarePos,rIconId=rIconId,latestChessdata=latestChessdata })
    elseif type == 4 then
        local ID = table_125_u4[gamecommon.CommRandInt(table_125_u4, 'gailv')].ID
        local iType, iNum = 0, 0
        if ID == 1 then
            iType = 2
            iNum = 1
        elseif ID == 2 then
            iType = 3
            iNum = 1
        elseif ID == 3 then
            iType = 4
            iNum = 1
        elseif ID == 4 then
            iType = 2
            iNum = 2
        elseif ID == 5 then
            iType = 3
            iNum = 2
        elseif ID == 6 then
            iType = 4
            iNum = 2
        end
        local epos = lastInfo.epos
        local chessdata = lastInfo.chessdata
        local latestChessdata = table.clone(lastInfo.chessdata)
        local lastColRow = lastInfo.lastColRow
        local squarePos,rIconId = RandToSquare(iType, iNum, chessdata)
        local betinfo = {
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameId = GameId,
            gameType = gameType,
        }
        local spin = gamecommon.GetSpin(uid, GameId, gameType, betinfo)
        result = NewOneceLogic(uid, GameId, gameType, false, epos, chessdata, lastColRow, spin,datainfo)
        table.insert(cacheRes, { result = result, type = 4,squarePos=squarePos,rIconId=rIconId,latestChessdata=latestChessdata })
    else
        local num = table_125_u5[gamecommon.CommRandInt(table_125_u5, 'gailv')].num
        local chessdata = lastInfo.chessdata
        local latestChessdata = table.clone(lastInfo.chessdata)
        local epos = lastInfo.epos
        local lastColRow = lastInfo.lastColRow
        local col, row = 8, 8
        local chargeToRange = {}
        for i = 1, num do
            local rcol = math.random(col)
            local rrow = math.random(row)
            chessdata[rcol][rrow] = 90
            table.insert(chargeToRange,{rcol,rrow})
        end
        local betinfo = {
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameId = GameId,
            gameType = gameType,
        }
        local spin = gamecommon.GetSpin(uid, GameId, gameType, betinfo)
        result = NewOneceLogic(uid, GameId, gameType, false, epos, chessdata, lastColRow, spin,datainfo)
        table.insert(cacheRes, { result = result, type = 5,chargeToRange=chargeToRange,latestChessdata=latestChessdata })
    end
    return result
end
--随机变化方形模块区域
function RandToSquare(type, num, chessdata)
    local squarePos={}
    local lenwid = 0
    if type == 1 then
        lenwid = 2
    elseif type == 2 then
        lenwid = 3
    elseif type == 3 then
        lenwid = 4
    else
        lenwid = 5
    end
    --要变化的其实点坐标
    local posChangeCenter = {}
    local col, row = 8, 8
    for i = 1, num do
        local rcol = math.random(8)
        local rrow = math.random(8)
        local posstr = rcol .. '_' .. rrow
        posChangeCenter[posstr] = { rcol, rrow }
    end
    local tableChangePos = {}
    for _, value in pairs(posChangeCenter) do
        local c, r = value[1], value[2]
        local hors = {} --横坐标
        local vers = {} --竖坐标
        if c - lenwid < 0 then
            for i = 1, lenwid do
                table.insert(hors, c + i - 1)
            end
        else
            for i = 1, lenwid do
                table.insert(hors, c - i + 1)
            end
        end
        if r - lenwid < 0 then
            for i = 1, lenwid do
                table.insert(vers, r + i - 1)
            end
        else
            for i = 1, lenwid do
                table.insert(vers, r - i + 1)
            end
        end
        for rc = 1, lenwid do
            for rw = 1, lenwid do
                local pos = { hors[rc], vers[rw] }
                table.insert(tableChangePos, pos)
            end
        end
    end
    local rIconId = 0
    while true do
        local pos = tableChangePos[math.random(#tableChangePos)]
        rIconId = chessdata[pos[1]][pos[2]]
        if rIconId ~= 90 then
            break
        end
    end
    for _, value in ipairs(tableChangePos) do
        local c, r = value[1], value[2]
        chessdata[c][r] = rIconId
        table.insert(squarePos,{c,r})
    end
    return squarePos,rIconId
end

--计算每个图标的个数
function CalcIconNum(chessdata)
    local iconNumMap = {}
    for col = 1, #chessdata do
        for row = 1, #chessdata[col] do
            local iconId = chessdata[col][row]
            if iconId ~= 90 then
                iconNumMap[iconId] = iconNumMap[iconId] or 0
                iconNumMap[iconId] = iconNumMap[iconId] + 1
            end
        end
    end
    return iconNumMap
end
