module('rockgame',package.seeall)
function CollectHead(uid,gameType,lastInfo,datainfo)
    local tWinScore = 0
    for type=1,5 do
        local result = BonusHead(uid, gameType, type, lastInfo, datainfo.collectres,datainfo)
        lastInfo = result.lastInfo
        tWinScore = tWinScore + result.winScore
    end
    return tWinScore
end
function collectCurRocks(rocks,rockres)
    for _, value in ipairs(rocks) do
        local isFind=false
        for _, v in ipairs(rockres) do
            if v==value then
                isFind = true
                break
            end
        end
        if isFind==false then
            table.insert(rockres,value)
        end
    end
end
--单独添加
function collectAddRockSingle(rocks,type)
    local bFind=false
    for _,value in ipairs(rocks) do
        if value==type then
            bFind=true
            break
        end
    end
    if bFind==false then
        table.insert(rocks,type)
        table.sort(rocks,function (a, b)
            return a<b
        end)
    end
end