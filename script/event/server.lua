-- event on server

function StartOver()
	chessrechargemgr.Init()
	Timer.Init()
    -- 积分榜初始化判断
    -- ScoreBoard.EndScoreBoard()
    --初始化团队总榜
    --teammgr.Team.InitTolRank()

	Const.GameTriggerEvent(Const.GAME_EVENT.START_OVER)
    --统一启动缓存时效ttl刷新
    unilight.addclocker("unilight.Mongo_cache_ttl", 0, 60)
end

Server = Server or {}
Server.ServerStop = function ()
    --停服时保存下排行榜数据
    unilight.info("保存排行榜信息")
	Const.GameTriggerEvent(Const.GAME_EVENT.STOP_OVER)

    local onlineList = go.accountmgr.GetOnlineList()
    for i=1, #onlineList do
        UserInfo.ServerStop(onlineList[i])
    end
end
