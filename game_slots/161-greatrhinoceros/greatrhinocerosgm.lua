module('GreatRhinoceros',package.seeall)
function GmProcess()
    if gmInfo.free==1 then
        return true
    end
    return false
end