module('hallMgr', package.seeall)  

--游戏配置档
tableGames = import"table/table_game_list"

--热门游戏
DB_HOTTEST_GAMES="hallGameInfo"
--统计所有玩家玩过的游戏-
DB_USER_PLAY_GAMES="hallUserInfo"


--统一添加游戏统计
function statiSticsGames(uid,gameId)
    addHottestGame(gameId)
    addSlefGame(uid,gameId)
end

function GetHallQuckGames(uid)
    local hottest= {}
    local favourite={}
    local latelyPlay={}
    local guess={}


    hottest= hottestGame(uid)
    favourite,latelyPlay,guess=userHallGame(uid)


	local laccount = go.accountmgr.GetAccountById(uid)
    local send={}
    send["do"] = "Cmd.GetHallQuckGamesCmd_S"
    local data = {
        hottestGame = hottest,
        favouriteGame = favourite,
        latelyPlayGame = latelyPlay,
        guessYouLike = guess,
    }
    data.gameTbls = gameInfo
    send["data"]=data
    unilight.success(laccount,send)

    
end





--添加热门游戏统计
function addHottestGame(gameId)
    local gameInfo=unilight.getdata(DB_HOTTEST_GAMES,gameId)
    if gameInfo == nil then
        --初始化热门游戏统计
        gameInfo = hottestGameInit(gameId)
    end
    gameInfo.num = gameInfo.num+1

    unilight.savedata(DB_HOTTEST_GAMES,gameInfo)

    return gameInfo 
end 

--添加个人游戏次数
function  addSlefGame(uid,gameId)
    --获取个人游戏列表
    local selfInfo =unilight.getdata(DB_USER_PLAY_GAMES,uid)

    if selfInfo == nil then
        --初始化个人游戏列表
        selfInfo =  selfGameInit(uid)
    end
    local count = math.random(1,20)     --随机一个次数。假数据

    selfInfo.gameInfo[gameId] = selfInfo.gameInfo[gameId] or {gameId=gameId,num = 0,lastTime = os.time()}
    selfInfo.gameInfo[gameId].num = selfInfo.gameInfo[gameId].num+count
    unilight.savedata(DB_USER_PLAY_GAMES,selfInfo)

end

--个人游戏 登陆下发
function userHallGame(uid)
        --获取个人游戏列表
        local selfInfo =unilight.getdata(DB_USER_PLAY_GAMES,uid)
        if selfInfo == nil then
            --初始化个人游戏列表
            for index, value in pairs(tableGames) do
                addSlefGame(uid,value.ID)
            end

        end

    
        ----经常玩的游戏
        local favourite=favourite(uid)
        --最后玩的游戏
        local latelyPlay=latelyPlay(uid)
        --推荐的游戏
        local guess=guessYouLike(uid)


        return favourite,latelyPlay,guess
end


--热门游戏排序登陆下发
function hottestGame(uid)
        --如果热门游戏为空，去读配置档进行初始化
        for index, value in pairs(tableGames) do
            local gamesInfo = unilight.getdata(DB_HOTTEST_GAMES,value.ID)
            if gamesInfo == nil  then
                local game =  hottestGameInit(value.ID)
                unilight.savedata(DB_HOTTEST_GAMES,game)
            end
        end

    local filter = unilight.gt("_id", 0)
	local gameInfo = unilight.chainResponseSequence(unilight.startChain().Table("hallGameInfo").Filter(filter).OrderBy(unilight.desc("num")).Limit(6)) or {}

    local games={}
    local i=1
    for index, value in ipairs(gameInfo) do
        if i>6 then
            break
            
        end
        local info ={
            gameId = value._id,
            num = value.num
        }
        table.insert(games,info)
        i = i + 1

    end

	-- local laccount = go.accountmgr.GetAccountById(uid)
    -- local send={}
    -- send["do"] = "Cmd.GethottestGameCmd_S"
    -- local data = {
    --     gameTbls = {}
    -- }
    -- data.gameTbls = gameInfo
    -- send["data"]=data
    -- unilight.success(laccount,send)

    return games

end



--初始化热门游戏 

function checkGameInit()
    for index, value in pairs(tableGames) do
        local gamesInfo = unilight.getdata(DB_HOTTEST_GAMES,value.ID)
        if gamesInfo == nil  then
            hottestGameInit(value.ID)
        end
    end
    
end


function selfGameInit(uid)
    local userInfo ={
        _id =uid,
        gameInfo ={}
    }   
    return userInfo
end

function hottestGameInit(id)
    local count = math.random(1,1000)     --随机一个次数。假数据
    local game={
        _id = id,
        num = count
    }
    return game
    
end

--根据热门游戏规则 返回玩家玩过最多的六款游戏

--经常玩的游戏
function favourite(uid)

    local filter =unilight.eq("_id", uid)
    local chain = unilight.startChain().Table("hallUserInfo").Filter(filter)
    local userList = unilight.chainResponseSequence(chain)
    if #userList <1 then
        return
    end
    local tab = userList[1].gameInfo
    local gameInfo ={}

    table.sort(tab,function (a, b)
        if a.num > b.num then 
            --按num排序
            return ture
             elseif a.num==b.num then
                 return a.lastTime > b.lastTime
             end
            return flase

    end)
    local i =1
    for index, value in ipairs(tab) do
        if i>6 then
            break
        end
        local game = {
            gameId = value.gameId,
            num  = value.num
        }
        table.insert(gameInfo,game)
        i = i + 1
    end

    -- local laccount = go.accountmgr.GetAccountById(uid)
    -- local send={}
    -- send["do"] = "Cmd.GetFavouriteGameCmd_S"
    -- local data = {
    --     gameTbls = {}
    -- }
    -- data.gameTbls = gameInfo
    -- send["data"]=data
    -- unilight.success(laccount,send)

    return gameInfo

end


--最后玩的游戏
function latelyPlay(uid)

    local filter =unilight.eq("_id", uid)
    local chain = unilight.startChain().Table("hallUserInfo").Filter(filter)
    local userList = unilight.chainResponseSequence(chain)
    if #userList <1 then
        return
    end
    local tab = userList[1].gameInfo
    local gameInfo ={}

    table.sort(tab,function (a, b)
        if a.lastTime > b.lastTime then
            --按时间排序
            return ture
             elseif a.lastTime==b.lastTime then
                 return a.num > b.num
             end
            return flase

    end)
    local i =1
    for index, value in ipairs(tab) do
        if i>6 then
            break
        end
        local game ={
            gameId = value.gameId,
            num = value.num
        }
        table.insert(gameInfo,game)
        i = i + 1

    end
    
    -- local laccount = go.accountmgr.GetAccountById(uid)
    -- local send={}
    -- send["do"] = "Cmd.GetLatelyPlayGameCmd_S"
    -- local data = {
    --     gameTbls = {}
    -- }
    -- data.gameTbls = gameInfo
    -- send["data"]=data
    -- unilight.success(laccount,send)

    return gameInfo

end


--猜你喜欢的游戏
function guessYouLike(uid)

    local i=1
    local gameInfo={}
    for index, value in pairs(tableGames) do
        if i>6 then
            break
        end
        local va={
            gameId = value.ID,
            num=0
        }

        table.insert(gameInfo,va)
        i = i + 1

    end
    -- local laccount = go.accountmgr.GetAccountById(uid)
    -- local send={}
    -- send["do"] = "Cmd.guessYouLikeGameCmd_S"
    -- local data = {
    --     gameTbls = {}
    -- }
    -- data.gameTbls = gameInfo
    -- send["data"]=data
    -- unilight.success(laccount,send)

    return gameInfo


end