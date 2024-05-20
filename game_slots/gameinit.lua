module('SlotsGameInitMgr', package.seeall) -- 


JACKPOT_ROBOT_FLAG = false
--大厅房间数据库初始化
function DBReady()
    -- 数据库加载完 就把数据库中有效的房间缓存出来 等游戏服认领
end


--服务器启动后要做的事
function StartOver()
        --注册游戏处理函数
	unilight.info("服务器启动调用")
    -- unilight.addtimer('racelamp.timer',20)
    -- racelamp.Init()
    gamecommon.RegGameNetCommand()
    unilight.addclocker('SlotsGameInitMgr.TwoSecCallback',0,2)
    -- gamestock.LoadStock()
    -- gamestockredis.InitStockToRedis()
    --实现slots奖池自动变化
    -- unilight.addclocker('gamecommon.JackNameTimeTicket',0,10)

    --每3分钟定时器
	-- unilight.addclocker("SlotsGameInitMgr.ThreeMinCallback", 0, 60 * 3)

    --每1分钟定时器
	-- unilight.addclocker("SlotsGameInitMgr.OneMinCallback", 0, 60)

    --每30s定时器
	-- unilight.addclocker("SlotsGameInitMgr.ThirtySecCallback", 0, 30)
    
    -- 初始化累计充值活动信息
	CumulativeRecharge.Init()
end
--服务器关闭后要做的事
function StopOver()
	unilight.info("slots服务器关闭调用")
    -- 保存奖池金额
    -- gamecommon.SaveJackpotStock()
    --保存缓存
    storecatch.FlushCatchToDb()
    --保存库存
    -- gamestock.FlushData()
end

function lobbyconnect()
    unilight.info("连接大厅成功")
    if JACKPOT_ROBOT_FLAG == false then
        -- lampgame.Init()
        --每1秒钟定时器
	    -- unilight.addclocker("gamecommon.JackpotRobot", 0, 1)
        JACKPOT_ROBOT_FLAG = true
    end
end
--两秒定时器
function TwoSecCallback()
    backRealtime.gameTimerToLobby()
end


--3分钟定时器
function ThreeMinCallback()
    -- 保存奖池金额
    gamecommon.SaveJackpotStock()

end

--1分钟定时器
function OneMinCallback()
    -- gamecommon.SaveSlotStockLog(true)
end

--30秒定时器
function ThirtySecCallback()
    -- gamecommon.SaveSlotStockLog(false)
    --保存slots下奖池信息
    gamecommon.SaveSlotsPoolInfoToRedis()
    --保存单机游戏参数
    gamecommon.SaveSinglePoolInfoToRedis()
end

--掉线处理
--处理玩家掉线的情况
function AccounDisconnect(roomuser)
	if roomuser == nil then
		unilight.error("调用断线 但是roomuser为nil")
		return 
	end
	local uid = roomuser.Id

end

Tcp = Tcp or {}
-- 断线重连 覆盖掉默认实现
Tcp.reconnect_login_ok = function(laccount)
    local uid = laccount.Id

    -- 模拟下获取
    local cmd = {
        data = {
            uid = uid,
            getIsCreate = true,
        }
    }

end 

Do.online_state_change_account = function(laccount,oldstate,newstate)
end

