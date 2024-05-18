module('dragontriger',package.seeall)
local Table='game139dragontriger'
LineNum = 1
function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            betindex = 1,
            betMoney = 0,
        }
        unilight.savedata(Table, datainfo)
    end
    return datainfo
end

function Normal(gameType,betindex,datainfo)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney*2
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "龙虎玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,1,dragontriger,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local winScore = chip*realMul
    local boards={
        [1] = backData.board1.chessdata,
        [2] = backData.board2.chessdata,
    }

    -- local winLines={
    --     [1] = {1,backData.board1.rIconId,backData.board1.mul,3},
    --     [2] = {1,backData.board2.rIconId,backData.board2.mul,3},
    -- }
    local winLines={[1]={},[2]={}}
    if backData.board1.mul>0 then
        table.insert(winLines[1],{1,3,backData.board1.mul,3})
    end
    if backData.board2.mul>0 then
        table.insert(winLines[2],{1,3,backData.board2.mul,3})
    end
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.dragontriger)
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        winlines = winLines,
    }
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfo._id)+winScore,
        0,
        { type = 'normal',imageType=1},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end


function NormalType1(gameType,betindex,datainfo)
     local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "龙虎玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,2,dragontriger,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local winScore = chip*realMul
    local boards={
        [1] = backData.board1.chessdata,
        [2] = {},
    }
    local winLines={
        [1] = {{1,3,backData.board1.mul,3}},
        [2] = {},
    }
    local winScore = chip*realMul
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.dragontriger)
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        winlines = winLines,
    }
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfo._id)+winScore,
        0,
        { type = 'normal',imageType=2},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end


function NormalType2(gameType,betindex,datainfo)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
   local betMoney = betconfig[betindex]
   local chip = betMoney
   if betMoney == nil or betMoney <= 0 then
       return {
           errno = 1,
           desc = '下注参数错误',
       }
   end
   --执行扣费
   local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "龙虎玩法投注")
   if ok == false then
       return {
           errno = ErrorDefine.CHIPS_NOT_ENOUGH,
       }
   end
   datainfo.betMoney = betMoney
   datainfo.betindex = betindex
   local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,3,dragontriger,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
   local winScore = chip*realMul
   local boards={
    [1] = {},
    [2] = backData.board2.chessdata,
}
local winLines={
    [1] = {},
    [2] = {{1,3,backData.board2.mul,3}},
}
   local winScore = chip*realMul
   BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.dragontriger)
   local res = {
       errno = 0,
       betIndex = betindex,
       payScore = chip,
       winScore = winScore,
       boards = boards,
       winlines = winLines,
   }
   gameDetaillog.SaveDetailGameLog(
       datainfo._id,
       os.time(),
       GameId,
       gameType,
       chip,
       remainder + chip,
       chessuserinfodb.RUserChipsGet(datainfo._id)+winScore,
       0,
       { type = 'normal',imageType=3},
       {}
   )
   unilight.update(Table, datainfo._id, datainfo)
   return res
end