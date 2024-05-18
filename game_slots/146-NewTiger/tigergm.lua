-- 老虎游戏模块
module('NewTiger', package.seeall)
function GmProcess(boards)
    local res = {}
    res.bonus = false
    res.respin = false
    res.free = false
    if gmInfo.respin==1 then
        res.respin = true
    end
    if gmInfo.free==1 then
        res.respin = true
        res.free = true
    end
    if gmInfo.bonus==1 then
        res.bonus = true
    end
    if table.empty(boards) == false and gmInfo.bonus==1 then
        boards[1][1] = 3
        boards[1][2] = 4
        boards[1][3] = 3
        boards[2][1] = 3
        boards[2][2] = 4
        boards[2][3] = 3
        boards[3][1] = 3
        boards[3][2] = 4
        boards[3][3] = 3
    end
    if table.empty(boards) == false and gmInfo.collect==1 then
        boards[1][1] = 3
        boards[1][2] = 3
        boards[1][3] = 3
        boards[2][1] = 3
        boards[2][2] = 3
        boards[2][3] = 3
        boards[3][1] = 3
        boards[3][2] = 3
        boards[3][3] = 3
    end
    return res
end