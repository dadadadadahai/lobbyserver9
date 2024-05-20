module('Const', package.seeall)
--公共的全局变量定义


-----------------------------------------子游戏自定义加载---------------------------
--子游戏事件类型
GAME_EVENT = {
    LOAD_SCRIPT_PATH     = 0,      --加载脚本
    INIT                 = 1,     --初始化调用
    DBREADY              = 2,      --加载数据库
    START_OVER           = 3,      --启动完成调用
    STOP_OVER            = 4,      --停服调用
    TIME_INIT            = 5,      --初始化定时器
    ACCOUNT_DISCONNECT   = 6,      --用户掉线
    LOBBY_CONNECT        = 7,      --大厅连接成功事件
}

--子游戏类型，为了使用同一套代码
GAME_TYPE = {
    STATISIC        = 1000,     --数据统计
    LOBBY           = 1001,     --大厅
    SLOTS           = 1002,     --slots游戏
    FOOTBAL         = 1003,     --足球
    WORLDCUP        = 1004,     --世界杯
    CACHTA          = 1005,     --cacheta
    CACA_NIQUELS    = 1006,     --CACA-NIQUELS
    KindQueen      =1007,   --国王王后
}

--子游戏加载路径
GAME_PATH  = {
    [1000] = {"game_statisic", "game_common"},         --数据统计
    [1001] = {"game_lobby_room", "game_common"},            --大厅房加载本目录
    [1002] = {"game_slots"},                 --slots游戏目录
    [1003] = {"game_longhu"},                --龙虎斗加载目录
    [1004] = {"game_worldcup"},              --世界杯
    [1005] = {"game_rocket"},                --火箭
    [1006] = {'game_Truco'},              --特鲁科
    [100]  = {"game_benchibaoma"},                     --奔驰宝马测试
    [1007] = {'game_kindqueen'},          --国王王后
}

--子游戏数据库初始化调用(没有可不填)
GAME_DB_INIT = {
    [1001]            = "LobbyRoomInitMgr.DBReady",         --大厅房间
    [100]             = "BenChiBaoMaInitMgr.DBReady",          --奔驰宝马
}

--子游戏启动后调用(没有可不填)
GAME_START_OVER = {
    [1000]            = "StatisicMgr.StartOver",           --数据统计
    [1001]            = "LobbyRoomInitMgr.StartOver",           --大厅房间
    [1002]            = 'SlotsGameInitMgr.StartOver',
    [1003]            = 'LongHu.StartOver',                 --龙虎斗
    [1004]            = 'WorldCup.StartOver',                   --世界杯
    [1005]            = 'rocket.StartOver',         --火箭
    [1006]            = 'Truco.StartOver',          --特鲁科
    [1007]            ='KindQueen.StartOver',          --国王王后
    [100]             = "BenChiBaoMaInitMgr.StartOver",            --奔驰宝马
}

--子游戏关闭服务器时调用 (没有可不填)
GAME_STOP_OVER= {
    [1001]            = "LobbyRoomInitMgr.StopOver",           --大厅房间
    [1002]            = "SlotsGameInitMgr.StopOver",           --slots房间
    [100]             = "BenChiBaoMaInitMgr.StopOver",         --奔驰宝马
}

--子游戏定时器初始化调用(没有可不填)
GAME_TIME_INIT= {
    [1001]            = "LobbyRoomInitMgr.StopOver",           --大厅房间
    [100]             = "BenChiBaoMaInitMgr.InitTimer",            --奔驰宝马
}

--子游戏用户掉线(没有可不填)
GAME_ACCOUNT_DISCONNECT = {
    [100]             = "BenChiBaoMaInitMgr.AccountDisconnect",         --奔驰宝马
    [1002]            = "SlotsGameInitMgr.AccounDisconnect",              --slost玩家掉线
    [1003]              ='LongHu.Drop',                 --龙虎斗
    [1004]            = 'WorldCup.Drop',                --世界杯
    [1005]          ='rocket.Drop',         --火箭
    [1006]            = 'Truco.Drop',          --特鲁科
    [1007]            ='KindQueen.Drop',          --国王王后
}

--大厅连接成功事件(没有可不填)
GAME_LOBBY_CONNECT = {
    [1002] =            "SlotsGameInitMgr.lobbyconnect",
    [1003] =            'LongHu.lobbyconnect',
    [1004] =            'WorldCup.lobbyconnect',
    [1005] =            "rocket.lobbyconnect",           
}

--子游戏触发事件
function GameTriggerEvent(eventType, ...)
    	--子游戏自定义启动后调用
	local zoneKey = go.config().GetConfigStr("zone_key")
	local gameId = tonumber(string.split(zoneKey, ":")[1])
    --事件对应处理
    local eventFun = {
        [GAME_EVENT.DBREADY]              = GAME_DB_INIT,         --加载数据库
        [GAME_EVENT.START_OVER]           = GAME_START_OVER,      --启动完成调用
        [GAME_EVENT.STOP_OVER]            = GAME_STOP_OVER,       --停服调用
        [GAME_EVENT.TIME_INIT]            = GAME_TIME_INIT,       --初始化定时器
        [GAME_EVENT.ACCOUNT_DISCONNECT]   = GAME_ACCOUNT_DISCONNECT,   --用户掉线
        [GAME_EVENT.LOBBY_CONNECT]        = GAME_LOBBY_CONNECT,   --用户掉线
    }
    if eventFun[eventType] == nil then
        unilight.error("找不到的游戏自定义事件"..eventType)
        return
    end

    local callbackFun = eventFun[eventType][gameId]
	if callbackFun ~= nil then
		loadstring("return "..callbackFun)()(unpack(arg))
	end

end
