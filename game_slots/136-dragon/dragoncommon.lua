module('dragon',package.seeall)
local Table='game136dragon'
LineNum=1
function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
    -- if tableEmpty(datainfo) then
        datainfo={
            _id=uid,
            betindex = 1,
            betMoney = 0,
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end


function Normal(gameType,betindex,datainfo)
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "龙玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local mul = 0
    local imageType  = table_136_imagePro[gamecommon.CommRandInt(table_136_imagePro,'pro')].type
    local uid = datainfo._id
    local tmpType =  GmProcess(uid,gameType,{})
    print('tmpType',tmpType)
    if tmpType>0 then
        imageType = tmpType
    end
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,dragon,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local winScore = chip*realMul
    --一次性回送
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.Dragon) 
    local boards = {
        [1] = backData.before.dis[1].chessdata
    }
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        extraData=backData,
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
        { type = 'normal',imageType=imageType},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end