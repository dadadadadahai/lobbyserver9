module('StatisicMgr', package.seeall) -- 

table_stock_tax = import "table/table_stock_tax"
table_rank_robot = import "table/table_rank_robot"
table_rank_robot_pro = import "table/table_rank_robot_pro"
table_robot_config = import "table/table_robot_config"

rank_robot_list = {}

--大厅房间数据库初始化
function DBReady()
end


--服务器启动后要做的事
function StartOver()
    local CYCLE_TEN = 10
	local CYCLE_MIN = 60
	local CYCLE_HOUR = 3600
	local CYCLE_DAY = CYCLE_HOUR * 24

	--每天0点定时器
	unilight.addclocker("StatisicMgr.ZeroHourCallback", 0, CYCLE_DAY)
	--每天1小时点定时器
	unilight.addclocker("StatisicMgr.HourCallback", 0, CYCLE_HOUR)
	--每天10秒
	unilight.addclocker("StatisicMgr.TenSecCallback", 0, CYCLE_TEN)
	--每天60秒
	unilight.addclocker("StatisicMgr.OneMinCallback", 0, CYCLE_MIN)
end

--0点定时器
function ZeroHourCallback()
	--0点要计算下前一天的数据
    -- DayStatisticsMgr.DayChipsStatics(-1)
end

--30秒定时器
function ThirtySecCallback()
end

--10秒定时器
function TenSecCallback()
    -- DayStatisticsMgr.DayChipsStatics()
end

--2秒定时器
function TwoSecCallback()
end

--每分钟定时器
function OneMinCallback()
    -- DayStatisticsMgr.DayChipsStatics()
end

--3分钟定时器
function ThreeMinCallback()
end

--10分钟定时器
function TenMinCallback()
end


--1小时定时器
function HourCallback()
end





--服务器关闭后要做的事
function StopOver()

end
