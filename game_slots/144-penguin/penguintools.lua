module('penguin',package.seeall)

function packFree(datainfo)
    if table.empty(datainfo.free) then
        return{}
    end
    return {
        totalTimes=datainfo.free.totalTimes,
        lackTimes=datainfo.free.lackTimes,
        tWinScore=datainfo.free.tWinScore,
        extraData={
            blueMul=datainfo.free.blueMul,
            blueNum=datainfo.free.blueNum,
            purpleMul=datainfo.free.purpleMul,
            purpleNum=datainfo.free.purpleNum,
        }
    }
end