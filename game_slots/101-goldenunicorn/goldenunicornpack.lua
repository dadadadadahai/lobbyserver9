module('goldenunicorn',package.seeall)
function PackFree(datainfo)
    if table.empty(datainfo.free) then
        return {}
    end
    return{
        totalTimes = datainfo.free.totalTimes,
        lackTimes = datainfo.free.lackTimes,
        tWinScore = datainfo.free.tWinScore,
    }
end
function PackBonus(datainfo)
    if table.empty(datainfo.bonus) then
        return {}
    end
    return{
        totalTimes = datainfo.bonus.totalTimes,
        lackTimes = datainfo.bonus.lackTimes,
        tWinScore = datainfo.bonus.tWinScore,
        extraData={
            --chessdata = datainfo.bonus.chessdata,
            tmul = datainfo.bonus.tmul,
        }
    }
end