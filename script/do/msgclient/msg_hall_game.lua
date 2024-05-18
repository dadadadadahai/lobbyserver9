--大厅快捷页

--1请求热门游戏
Net.CmdGethottestGameCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    local gameInfo=hallMgr.hottestGame(uid)


    local send={}
    send["do"] = "Cmd.GethottestGameCmd_S"
    local data = {
        gameTbls = {}
    }
    data.gameTbls = gameInfo
    send["data"]=data
    return send


end



--2、 获取我喜欢玩的游戏
Net.CmdGetFavouriteGameCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    local gameInfo=hallMgr.favourite(uid)

    local send={}
    send["do"] = "Cmd.GetFavouriteGameCmd_S"
    local data = {
        gameTbls = {}
    }
    data.gameTbls = gameInfo
    send["data"]=data
    return send


end

--3、获取	我最后玩的游戏
Net.CmdGetLatelyPlayGameCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    local gameInfo=hallMgr.latelyPlay(uid)
    local send={}
    send["do"] = "Cmd.GetLatelyPlayGameCmd_C"
    local data = {
        gameTbls = {}
    }
    data.gameTbls = gameInfo
    send["data"]=data
    return send


end


--4、获取推荐游戏
Net.CmdGetGuessYouLikeGameCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    local gameInfo=hallMgr.latelyPlay(uid)
    local send={}
    send["do"] = "Cmd.GetGuessYouLikeGameCmd_S"
    local data = {
        gameTbls = {}
    }
    data.gameTbls = gameInfo
    send["data"]=data
    return send


end

--5 获取全部数据 
Net.CmdGetHallQuckGamesCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    hallMgr.GetHallQuckGames(uid)
end