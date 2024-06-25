-- 老虎游戏模块
module('GreatRhinoceros', package.seeall)
function GmProcess(imageType)
    if gmInfo.sfree > 0 then
        return gmInfo.sfree
    end
    return imageType
end