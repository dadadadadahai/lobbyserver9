GameId = 172
Do.dbready = function()
	-- 房间初始化表格数据
	unitimer.init(100) --初始化定时器（取出数据库缓存时 会调用到时间相关）

	-- 棋牌相关 基本db初始化 
	ChessDbInit.Init()

	-- 初始化代理商map
	-- ExchangeMgr.InitMapAgent()
	
	Const.GameTriggerEvent(Const.GAME_EVENT.DBREADY)

end
