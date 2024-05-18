-- 轮盘模块
module('Roulette', package.seeall)
Roulette = Roulette or {}

-- 获取转盘面板信息
function CmdUserRouletteInfoGet()
    local rouletteInfo = Roulette.GetRouletteInfo()
    local res = {
		errno = 0,
		-- desc = rouletteInfo.desc,
        -- mulList = rouletteInfo.mulList,
        scoreList = rouletteInfo.scoreList,
	}
    return res
end

-- 获取转盘游玩结果
function CmdUserRoulettePlayRequest(uid, score)
    local res = {}
    local rouletteInfo = Roulette.GetRoulettePlay(uid, score)
	res = {
		errno = rouletteInfo.errno,
		-- desc = rouletteInfo.desc,
        mul = rouletteInfo.mul,
	}
    return res
end