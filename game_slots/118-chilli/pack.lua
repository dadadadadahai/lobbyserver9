module('chilli', package.seeall)
--[[
    组装respin会送消息
]]
function PackRespin(datainfo)
    if table.empty(datainfo.respin) then
        return {}
    end
    local respin = datainfo.respin
    local tWinScore = 0
    if respin.lackTimes<=0 then
        tWinScore = respin.tWinScore
    end
    return{
        totalTimes = respin.totalTimes,
        lackTimes = respin.lackTimes,
        tWinScore = tWinScore,
        extraData={
            -- chessdata = respin.chessdata,
            iconsAttachData = respin.iconsAttachData
        }
    }
end