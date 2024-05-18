-- 每日签到模块
module('DaySign', package.seeall)
DaySign = DaySign or {}

-- 包装生成返回的签到总信息
function CmdUserMonthSignInfoGet(uid)
    local signInfo = DaySign.GetSignInfo(uid)
    local res = {
        errno = 0,
        desc = signInfo.desc,
        signScoreList = signInfo.signScoreList,
        signDay = signInfo.signDay,
        signFlag = signInfo.signFlag,
        time = signInfo.time,
    }
    return res
end
-- 玩家每日签到奖励
function CmdUserSignDayRequest(uid)
    local signInfo = DaySign.GetSignDays(uid)
    local res = {}
	res = {
		errno = 0,
		desc = signInfo.desc,
        score = signInfo.score,
        time = signInfo.time,
	}
    return res
end