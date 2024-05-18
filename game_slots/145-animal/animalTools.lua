module('animal',package.seeall)
function packFree(datainfo)
    if table.empty(datainfo.free) then
        return {}
    end
    return {
        totalTimes=datainfo.free.totalTimes,
        lackTimes=datainfo.free.lackTimes,
        tWinScore = datainfo.free.tWinScore,
    }
end