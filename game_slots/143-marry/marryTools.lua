module('marry',package.seeall)

function PackFree(datainfo)
    if table.empty(datainfo.free) then
        return{}
    else
        return{
            totalTimes=datainfo.free.totalTimes,
            lackTimes=datainfo.free.lackTimes,
            tWinScore=datainfo.free.tWinScore,
        }
    end
end