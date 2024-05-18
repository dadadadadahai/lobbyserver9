module('corpse', package.seeall)
-- function PackPick(datainfo)
--     if table.empty(datainfo.pick) then
--         return{}
--     end
--     local picks={}
--     for _, value in ipairs(datainfo.pick) do
--         local tmp={
--             totalTimes = value.totalTimes,
--             lackTimes = value.lackTimes,
--             tWinScore = value.tWinScore,
--             extraData={
--                 chessdata = value.chessdata,
--                 mul = value.mul,
--                 type = value.type,
--             }
--         }
--         table.insert(picks,tmp)
--     end
--     return picks
-- end
function PackBonus(datainfo)
    if table.empty(datainfo.bonus) then
        return {}
    end
    local value = datainfo.bonus
    local tmp = {
        totalTimes = value.totalTimes,
        lackTimes = value.lackTimes,
        tWinScore = value.tWinScore,
        extraData = {
            mul = value.mul,
            chessdata = value.chessdata,
            type = value.type,
            baseWin = value.baseWin,
            isNewBonus = value.isNewBonus,
        }
    }
    return tmp
end
