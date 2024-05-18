-- 老虎游戏模块
module('Tiger', package.seeall)
function GmProcess(imageType)
    if gmInfo.sfree > 0 then
        return gmInfo.sfree
    end
    return imageType
end