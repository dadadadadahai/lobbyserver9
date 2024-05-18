--one second timer


function InitTimer()
    local table_parameter_parameter= import "table/table_parameter_parameter"
	local CYCLE_HOUR = 3600
	local CYCLE_DAY = CYCLE_HOUR * 24
	local CYCLE_WEEKLY = CYCLE_DAY * 7
	local CYCLE_MIN = 60
    local POOL_TICK = table_parameter_parameter[13].Parameter        --奖池间隔时间
    -- local POOL_TICK = 10        --奖池间隔时间

	--每天0点定时器
	unilight.addclocker("ZeroHourCallback", 0, CYCLE_DAY)
    --每1秒钟定时器
	unilight.addclocker("OneSecCallback", 0, 1)
    --每5秒钟定时器
	unilight.addclocker("FiveSecCallback", 0, 5)
    --每10秒钟定时器
	unilight.addclocker("TenSecCallback", 0, 10)
    --每分钟定时器
	unilight.addclocker("OneMinCallback", 0, CYCLE_MIN)
    --奖池间隔时间
    -- unilight.addclocker("gamecommon.GamePoolsTick", 0, POOL_TICK)
	--每天3点检测上下分 是否正常
	--unilight.addclocker("ChessGmStaticMgr.UpDownChipsWarn", 3*3600, CYCLE_DAY)

	--玩家的等级达到LV8时，每周一下午四点都会进行衰减经验
	--unilight.addclocker("vipCoefficientMgr.DampingVipExpForVLight", 16 * 3600,CYCLE_WEEKLY)


end


--每日零晨0点钟定时器
function ZeroHourCallback()
	-- 每天4点判断 存储彩票大奖数据
	-- Lottery.CreateGrandPrize()
	-- 每天4点救济金清空增幅器点数
	-- Benefits.ClearAmplificationNbr()
	--每天四点判断积分榜是否结算刷新
	-- ScoreBoard.EndScoreBoard()
	--团队排行榜计算是否应该结算
	-- teammgr.TeamSellet()
	--结算三个小游戏
	-- RankModuleMgr.StartSellte()

	-- 兑换提现模块重置所有人的服务费用
	-- WithdrawCash.ResetServiceCharge()
	-- 兑换提现模块清除多于30天的历史记录
	-- WithdrawCash.ClearHistory()

end

--每秒钟定时器
function OneSecCallback()
    -- gamecommon.GamePoolsTenTick()
	gamecommon.JackpotClocker()
	gamecommon.JackpotClocker3()
    local onlineList = go.accountmgr.GetOnlineList()
    for i=1, #onlineList do
        UserInfo.Loop(onlineList[i])
    end
end

--每分钟定时器
function OneMinCallback()
    local onlineList = go.accountmgr.GetOnlineList()
    for i=1, #onlineList do
        UserInfo.OneMin(onlineList[i])
    end
    gamecommon.GamePoolOneMinTick()
end

--每5秒钟定时器
function FiveSecCallback()
    --[[
    local onlineList = go.accountmgr.GetOnlineList()
    for i=1, #onlineList do
        UserInfo.FiveSec(onlineList[i])
    end
    ]]
end

--10秒钟定时器
function TenSecCallback()
    -- gamecommon.GamePoolsTenTick()
    local onlineList = go.accountmgr.GetOnlineList()
    for i=1, #onlineList do
        UserInfo.TenSec(onlineList[i])
    end
end


function ClockerOneSeondPerMininute()
 	unilight.debug("ClockerOneSeondPerMininute")
end

function resetWorldRank()
	unilight.cleardb("lastweekrank")
	local complexQuery = unilight.startChain().Table("lastweekrank").Insert(unilight.startChain().Table("ranking"))
	local record = unilight.chainResponseSequence(complexQuery)
	if record == nil then
		unilight.error("lastweekrank db failed.")
		return
	end

	return record
end
