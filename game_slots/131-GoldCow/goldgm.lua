module('GoldCow',package.seeall)
function GmProcess(flag)
    if gmInfo.free==1 and flag == "Free" then
        return true
    end
    if gmInfo.bonus==1 and flag == "Bonus" then
        return true
    end
    if gmInfo.respin==1 and flag == "False" then
        return true
    end
    return false
end