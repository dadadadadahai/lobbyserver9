module('moneyPig',package.seeall)

local Table='game140moneyPig'
LineNum = 1

function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "金钱猪")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_140_imagePro[gamecommon.CommRandInt(table_140_imagePro,'pro')].type
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,moneyPig,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})

    local winScore = chip*realMul
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.Dragon) 
    local boards={[1]=backData.chessdata}
    local winLines={
        -- [1]={1,backData.firstIconId,realMul/backData.addMul,3}
        [1]={}
    }
    if winScore>0 then
        table.insert(winLines[1],{1,backData.firstIconId,realMul/backData.addMul,3})
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        winlines = winLines,
        extraData={
            imageType=imageType
        }
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