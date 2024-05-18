module('mariachi',package.seeall)
function PackFree(datainfo)
    if table.empty(datainfo.free) then
        return{}
    end
    return{
        totalTimes=datainfo.free.totalTimes,
        lackTimes=datainfo.free.lackTimes,
        tWinScore=datainfo.free.tWinScore,
    }
end
function PackPick(datainfo)
    if table.empty(datainfo.pick) then
        return{}
    end
    return{
        totalTimes=datainfo.pick.totalTimes,
        lackTimes=datainfo.pick.lackTimes,
        tWinScore=datainfo.pick.tWinScore,
    }
end