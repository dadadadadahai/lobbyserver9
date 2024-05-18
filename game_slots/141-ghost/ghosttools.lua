module('ghost', package.seeall)

function InitFree(f, winScore, datainfo)
    if table.empty(f) then
        return {}
    else
        --构建结构体
        datainfo.free = {
            totalTimes = f.totalTimes,
            lackTimes = f.lackTimes,
            tWinScore = winScore,
            res = f.res,
            --手动具体调用时维护
            AddMul = 0,
        }
        return GetFreeInfo(datainfo)
    end
end

--回去一次free信息
function GetFreeInfo(datainfo)
    local free = datainfo.free
    if table.empty(free) then
        return {}
    else
        return {
            totalTimes = free.totalTimes,
            lackTimes = free.lackTimes,
            tWinScore = free.tWinScore,
            AddMul = free.AddMul,
        }
    end
end
