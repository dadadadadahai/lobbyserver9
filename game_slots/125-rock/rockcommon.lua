module('rockgame',package.seeall)
GameId = 125
LineNum = 20
Table = 'game125rockgame'
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
            gameType = 0,
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0,
            rocks = {},      --当前处理
            lastInfo={},
            tRocks={},      --收集到的量  下注索引
            curRocks={},        --当前收集量
            bonusres={},    --包含阶段
            collectres=0,
            epos={},
            bonusCollectInfo=0,
            collectLv = 1,
            bonusQueue = {},
            bonusWinScore = 0,
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]

    --lampgame.AddLampData(123,1,1,1)
    return datainfo, datainfos
end
--进入普通游戏
function Normal(gameId, gameType, betindex, datainfo, datainfos)
    print('betindex',betindex)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "宝石玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.collectLv = 1
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    datainfo.tRocks[betindex] = datainfo.tRocks[betindex] or {}
    datainfo.curRocks[betindex] = datainfo.curRocks[betindex] or {}
    datainfo.bonusWinScore =0
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, false, datainfo, chip, CommonRotate)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo=newdatainfo
    local boards={}
    table.insert(boards,result.chessdata)
    result.winScore = result.winScore - result.aHeadBonusWinScore
    datainfo.bonusWinScore = result.winScore
    local bonus =  getPackBonusInfo(datainfo)
    local winScore = 0
    if table.empty(bonus)==false then
        bonus.type = 0
    else
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore,
        Const.GOODS_SOURCE_TYPE.ROCKSGAME)
        winScore = result.winScore
        datainfo.bonusWinScore = 0
    end
    datainfo.rocks = result.rocks
    -- 执行加入
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        gameId,
        gameType,
        chip,
        remainder+chip,
        remainder+winScore,
        0,
        {type='normal' },
        {}
    )
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = result.winScore,
        boards = boards,
        features={
            bonus = bonus,
        },
        collect={
            rocks = datainfo.rocks,
            tRocks = datainfo.tRocks[betindex],
        },
        extraData = {
            disInfo = result.disInfo,
            epos = eposToArray(result.epos)
        }
    }
    return res
end
--处理bonus消息
function Bonus(gameType,datainfo,datainfos)
    local bonusObj = {}
    local ttype = 1
    bonusObj = datainfo.bonusQueue[1]
    local result,type = bonusObj.result,bonusObj.type
    local lastInfo = result.lastInfo
    table.sort(datainfo.rocks,function (a, b)
        return a<b
    end)
    table.remove(datainfo.rocks,1)
    datainfo.epos = lastInfo.bepos
    local boards={}
    table.insert(boards,result.chessdata)
    local bonus = getPackBonusInfo(datainfo,type)
    if bonus.IsCollect==1 then
        datainfo.collectres = 0
        datainfo.tRocks[datainfo.betindex] = {}
    end
    --添加可能的进度
    collectCurRocks(result.rocks,datainfo.rocks)
    --添加可能的收集
    collectCurRocks(result.rocks,datainfo.tRocks[datainfo.betindex])
    bonus.tWinScore = result.winScore + datainfo.bonusWinScore
    datainfo.bonusWinScore = bonus.tWinScore
    local achip =  chessuserinfodb.RUserChipsGet(datainfos._id)
    table.remove(datainfo.bonusQueue,1)
    if table.empty(datainfo.bonusQueue) then
        bonus.lackTimes = 0
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, bonus.tWinScore,
        Const.GOODS_SOURCE_TYPE.ROCKSGAME)
        datainfo.bonusWinScore = 0
    end
    for _,value in ipairs(result.disInfo) do
        value.clearPos = nil
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        GameId,
        gameType,
        0,
        achip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        {type='bonus' },
        {}
    )
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = result.winScore,
        boards = boards,
        features={
            bonus = bonus,
        },
        collect={
            rocks = datainfo.rocks,
            tRocks = datainfo.tRocks[datainfo.betindex],
            -- collectNum = datainfo.bonusCollectNum,
        },
        extraData = {
            disInfo = result.disInfo,
            epos = eposToArray(datainfo.epos)
        }
    }
    return res
end
--根据当前顺序计算rocks
function reCalcRocks(datainfo)
    local bonusres = datainfo.bonusres
    local rocks = {}
    if table.empty(bonusres)==false then
        for _,value in ipairs(bonusres) do
            type = value.type
            table.insert(rocks,80+type)
        end
    end
    return rocks
end
--获取bonus流程
--组装成bonus信息
function getPackBonusInfo(datainfo,type)
    local lv = 0
    if table.empty(datainfo.bonusQueue)==false then
        return{
            totalTimes = 1,
            lackTimes=1,
            type = datainfo.bonusQueue[1].type,
            tWinScore = 0,
            lv = lv,
            -- latestChessdata=datainfo.bonusres[1].latestChessdata
            IsCollect = datainfo.bonusQueue[1].IsCollect,
        }
    end
    return {}
end


function eposToArray(epos)
    local split = function (str,reps)
        local resultStrList = {}
        string.gsub(str,'[^'..reps..']+',function (w)
            table.insert(resultStrList,w)
        end)
        return resultStrList
    end
    local arrays = {}
    for key,value in pairs(epos) do
        local pos = split(key,'_')
        local col,row = tonumber(pos[1]),tonumber(pos[2])
        table.insert(arrays,{pos={col,row},iconId=value})
    end
    return arrays
end
function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local result={
        chessdata  ={},
        winScore = 0,
        disInfo = {},
        aHeadBonusWinScore=0,
        rocks={},           --返回的宝石数量,当前收集到宝石数量
        epos={},        --当把epos
        lastInfo = {}
    }
    --当前把总的触发量
    local allRocks={}
    local ePos=FillU(8,8)
    local cols = {8,8,8,8,8,8,8,8}
    local spin = {}
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameId = gameId,
        gameType = gameType,
    }
    spin = gamecommon.GetSpin(uid, gameId, gameType,betinfo)
    local chessdata,lastColRow = gamecommon.CreateSpecialChessData(cols,spin)
    -- chessdata={
    --     {4,4,6,7,5,3,2,6},
    --     {4,4,5,2,5,5,1,5},
    --     {2,4,2,5,3,6,7,4},
    --     {1,6,3,4,6,6,6,3},
    --     {7,5,2,3,6,6,5,2},
    --     {6,4,2,2,7,5,4,1},
    --     {5,3,6,5,6,4,3,3},
    --     {4,2,6,7,5,2,3,3},
    -- }
    local res = NewOneceLogic(uid,gameId,gameType,isfree,ePos,chessdata,lastColRow,spin,datainfo)
    result.chessdata = res.chessdata
    result.winScore = res.winScore
    result.disInfo = res.disInfo
    result.rocks = res.rocks
    result.epos = res.lastInfo.bepos
    result.aHeadBonusWinScore = 0
    result.lastInfo = res.lastInfo
    --总的收集量
    allRocks = table.clone(result.rocks)
    table.sort(allRocks,function (a, b)
        return a<b
    end)
    --收集到的量
    local tRocks = table.clone(datainfo.tRocks[datainfo.betindex])
    --添加当前收集量
    collectCurRocks(result.rocks,datainfo.curRocks[datainfo.betindex])
    --添加累计收集量
    collectCurRocks(result.rocks,datainfo.tRocks[datainfo.betindex])
    --添加局部变量收集
    collectCurRocks(result.rocks,tRocks)
    local newResult = result
    --进行bonus预计算
    if table.empty(allRocks)==false then
        while #allRocks>0 do
            local bonusType = allRocks[1]-80
            print('bonusType=',bonusType)
            table.remove(allRocks,1)
            newResult = BonusHead(uid,gameType,bonusType,newResult.lastInfo,datainfo.bonusQueue,datainfo)
            result.aHeadBonusWinScore  = result.aHeadBonusWinScore  + newResult.winScore
            datainfo.bonusQueue[#datainfo.bonusQueue].IsCollect = 0
            if table.empty(newResult.rocks)==false then
                --添加allRocks
                for _, value in ipairs(newResult.rocks) do
                    table.insert(allRocks,value)
                end
                table.sort(allRocks,function (a, b)
                    return a<b
                end)
                --添加虚拟收集
                collectCurRocks(newResult.rocks,tRocks)
            end
        end
        --判断是否可触发收集
        if #tRocks>=5 then
            tRocks = {}
            newResult = BonusHead(uid,gameType,math.random(1,5),newResult.lastInfo,datainfo.bonusQueue,datainfo)
            result.aHeadBonusWinScore  = result.aHeadBonusWinScore  + newResult.winScore
            datainfo.bonusQueue[#datainfo.bonusQueue].IsCollect = 1
            if table.empty(newResult.rocks)==false then
                for _, value in ipairs(newResult.rocks) do
                    table.insert(allRocks,value)
                end
                table.sort(allRocks,function (a, b)
                    return a<b
                end)
                --添加虚拟收集
                collectCurRocks(newResult.rocks,tRocks)
                while #allRocks>0 do
                    local bonusType = allRocks[1]-80
                    table.remove(allRocks,1)
                    newResult = BonusHead(uid,gameType,bonusType,newResult.lastInfo,datainfo.bonusQueue,datainfo)
                    result.aHeadBonusWinScore  = result.aHeadBonusWinScore  + newResult.winScore
                    datainfo.bonusQueue[#datainfo.bonusQueue].IsCollect = 0
                    if table.empty(newResult.rocks)==false then
                        --添加allRocks
                        for _, value in ipairs(newResult.rocks) do
                            table.insert(allRocks,value)
                        end
                        table.sort(allRocks,function (a, b)
                            return a<b
                        end)
                        --添加虚拟收集
                        collectCurRocks(newResult.rocks,tRocks)
                    end
                end
            end
        end
    end
    result.winScore = result.winScore + result.aHeadBonusWinScore
    return result
end

--执行一次性逻辑
--不产生epos
function OneceLogic(uid, gameId, gameType, isfree,epos,chessdata,lastColRow,spin,datainfo)
    -- local res={
    --     chessdata  ={},
    --     winScore = 0,
    --     jackpotChips = 0,
    --     disInfo = {},
    --     collectNum = 0,
    --     isSellte = false,
    --     aHeadBonusWinScore=0,
    --     aHeadCollectWinScore = 0,
    --     rocks={},           --返回的宝石数量
    --     lastInfo={},
    -- }
    -- local betMoney = datainfo.betMoney
    -- local disInfo,resultChessdata  = LogicProcess(chessdata,lastColRow,spin)
    -- for _, value in ipairs(datainfo.rocks) do
    --     table.insert(res.rocks,value)
    -- end
    -- --统计消除收集量
    -- local bepos = table.clone(epos)
    -- for _,value in ipairs(disInfo) do
    --     local clearPos = value.clearPos
    --     for _,pos in ipairs(clearPos) do
    --         local col,row = pos[1],pos[2]
    --         local keystr = col..'_'..row
    --         if epos[keystr]~=nil then
    --             -- table.insert(datainfo.rocks,epos[keystr])
    --             table.insert(res.rocks,epos[keystr])
    --             epos[keystr]=nil
    --         end
    --         -- res.collectNum =  res.collectNum + 1
    --     end
    -- end
    -- local isSellte  =true
    -- local winScore = 0
    -- for _,value in ipairs(disInfo) do
    --     local infos = value.infos
    --     for _,info in ipairs(infos) do
    --         winScore = winScore + math.floor(info.mul*betMoney)
    --     end
    -- end
    -- res.lastInfo={
    --     chessdata = table.clone(resultChessdata),
    --     lastColRow = lastColRow,
    --     winScore = winScore,
    --     epos = table.clone(epos),
    --     bepos=bepos,
    -- }
    -- res.isSellte = isSellte
    -- res.winScore = winScore
    -- res.chessdata = chessdata
    -- res.disInfo = disInfo
    -- return res
end
--处理收集
