module('beautydisco',package.seeall)
function PackBonus(datainfo)
    if table.empty(datainfo.bonus) then
        return {}
    end
    return {
        totalTimes = datainfo.bonus.totalTimes,
        lackTimes = datainfo.bonus.lackTimes,
        tWinScore = datainfo.bonus.tWinScore,
        -- extraData={
        --     pools = datainfo.bonus.pools,
        -- }
    }
end