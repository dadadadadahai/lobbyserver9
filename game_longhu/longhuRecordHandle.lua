module('LongHu', package.seeall)
local singleGames = {}
function sortChild(as, startIndex, tmpvalue)
    table.sort(tmpvalue, function(a, b)
        return a.winnum > b.winnum
    end)
    for index, value in ipairs(tmpvalue) do
        as[startIndex + (index - 1)] = value
    end
end

--计算处理,记录值
function SettleRecord(uid, betchip, winscore, nickname, headurl, score)
    table.insert(singleGames, {
        uid = uid,
        bet = betchip,
        win = winscore,
        nickname = nickname,
        headurl = headurl,
        score = score
    })
end

--最终结算
function FinRecord(Table)
    if table.empty(singleGames) then
        return
    end
    table.insert(Table.latelyRecord, singleGames)
    singleGames = {}
    if #Table.latelyRecord >= 20 then
        table.remove(Table.latelyRecord, 1)
    end
    --统计排行榜
    local uMap = {}
    for _, value in ipairs(Table.latelyRecord) do
        for _, kuval in ipairs(value) do
            --总下注，总赢取，胜利场次
            uMap[kuval.uid] = uMap[kuval.uid] or
                { bet = 0, win = 0, winnum = 0, nickname = kuval.nickname, headurl = kuval.headurl, score = kuval.score }
            uMap[kuval.uid].bet = uMap[kuval.uid].bet + kuval.bet
            uMap[kuval.uid].win = uMap[kuval.uid].win + kuval.win
            if kuval.win > kuval.bet then
                uMap[kuval.uid].winnum = uMap[kuval.uid].winnum + 1
            end
        end
    end
    --完成统计 计入排行榜
    local tmpuinfoArrays = {}
    for key, value in pairs(uMap) do
        table.insert(tmpuinfoArrays,
            {
                uid = key,
                bet = value.bet,
                win = value.win,
                winnum = value.winnum,
                nickname = value.nickname,
                headurl = value.headurl,
                score = value.score
            })
    end
    --进行排序
    table.sort(tmpuinfoArrays, function(a, b)
        return a.bet > b.bet
    end)
    --
    local startIndex = 1
    local ele = 0
    local tmpvalue = {}
    for index, value in ipairs(tmpuinfoArrays) do
        if ele == 0 then
            ele = value.bet
            startIndex = index
            table.insert(tmpvalue, value)
        elseif ele == value.bet then
            table.insert(tmpvalue, value)
        else
            if #tmpvalue > 1 then
                --进行排序
                sortChild(tmpuinfoArrays, startIndex, tmpvalue)
            end
            ele = value.bet
            tmpvalue = {}
            startIndex = index
            table.insert(tmpvalue, value)
        end
    end
    local GetForNum = function(max, realNum)
        local a = max
        if a > realNum then
            a = realNum
        end
        return a
    end
    Table.betRank = {}
    for i = 1, GetForNum(50, #tmpuinfoArrays) do
        local val = tmpuinfoArrays[i]
        table.insert(Table.betRank,
            {
                uid = val.uid,
                nickname = val.nickname,
                bet = val.bet,
                win = val.win,
                winnum = val.winnum,
                headurl = val.headurl,
                score = val.score
            })
    end
    --赢钱最多
    table.sort(tmpuinfoArrays, function(a, b)
        return a.win > b.win
    end)
    -- for index, value in ipairs(tmpuinfoArrays) do
    --     print(value.uid,value.win,Table.robot:GetGold(value.uid))
    -- end
    -- for _, value in ipairs(tmpuinfoArrays) do
    --     print(value.uid,value.win)
    -- end
    Table.leftSit = {}
    local leftMap = {}
    -- for i=1,GetForNum(3,#tmpuinfoArrays) do
    --     local val = tmpuinfoArrays[i]
    --     table.insert(Table.leftSit,{uid=val.uid,nickname=val.nickname,bet=val.bet,win=val.win,winnum=val.winnum,headurl=val.headurl,score=Table.robot:GetGold(val.uid)})
    -- end
    local realNum = 0
    for index, val in ipairs(tmpuinfoArrays) do
        local uinfo = Table.PlayMap[val.uid]
        if uinfo ~= nil then
            local score = 0
            if uinfo.IsRobot then
                score = Table.robot:GetGold(val.uid)
            else
                score = chessuserinfodb.RUserChipsGet(val.uid)
            end
            if score > 10000 then
                -- print(val.uid,val.win)
                table.insert(Table.leftSit,
                    {
                        uid = val.uid,
                        nickname = val.nickname,
                        bet = val.bet,
                        win = val.win,
                        winnum = val.winnum,
                        headurl = val.headurl,
                        score = score
                    })
                realNum = realNum + 1
                leftMap[val.uid] = 1
                if realNum >= 3 then
                    break
                end
            end
        end
    end
    --赢的局数最多
    table.sort(tmpuinfoArrays, function(a, b)
        return a.winnum > b.winnum
    end)
    Table.rightSit = {}
    realNum = 0
    for index, val in ipairs(tmpuinfoArrays) do
        local uinfo = Table.PlayMap[val.uid]
        if uinfo ~= nil then
            local score = 0
            if uinfo.IsRobot then
                score = Table.robot:GetGold(val.uid)
            else
                score = chessuserinfodb.RUserChipsGet(val.uid)
            end
            if leftMap[val.uid] == nil and score > 10000 then
                table.insert(Table.rightSit,
                    {
                        uid = val.uid,
                        nickname = val.nickname,
                        bet = val.bet,
                        win = val.win,
                        winnum = val.winnum,
                        headurl = val.headurl,
                        score = score
                    })
                realNum = realNum + 1
                if realNum >= 3 then
                    break
                end
            end
        end
    end
    -- print(table2json(Table.leftSit))
end
