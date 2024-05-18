module('beautydisco',package.seeall)
Table = 'game105beautydisco'
GameId = 105
LineNum = 27
--BEAUTYDISCO

Table_Base = import 'table/game/105/table_105_hanglie'
table_105_normalspin = import 'table/game/105/table_105_normalspin'
table_105_other = import 'table/game/105/table_105_other'
table_105_sgame = import 'table/game/105/table_105_sgame'
table_105_paytable = import 'table/game/105/table_105_paytable'
table_105_payline = import 'table/game/105/table_105_payline'
Table_Jackpot = import "table/game/105/table_105_jackpot"
W = 90
U = 80
function Get(gameType,uid)
    --gamecommon.AddJackpotHisory(uid, GameId, gameType, 0 , 1000,{pool = 1})
    local datainfos = unilight.getdata(Table,uid)
    if table.empty(datainfos) then
        datainfos={
            _id = uid,
            roomInfo={},
            gameType = 0,
        }
        unilight.savedata(Table,datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0,
            bonus={},
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table,datainfos._id,datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo,datainfos
end
function Normal(uid,gameType,betindex,datainfo,datainfos)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney*LineNum
    if betMoney==nil or betMoney<=0 then
        return{
            errno=1,
            desc='下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "美女迪斯科玩法投注")
    if ok==false then
        return{
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local sTime = os.time()
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, GameId, gameType, false, datainfo, chip, CommonRotate,AheadBonus)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    local pools={}
    pools[1] = table_105_sgame[8].pmul * chip
    pools[2] = table_105_sgame[9].pmul * chip
    pools[3] = table_105_sgame[10].pmul * chip
    pools[4] = table_105_sgame[11].pmul * chip
    local boards={}
    table.insert(boards,result.chessdata)
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        GameId,
        gameType,
        chip,
        remainder+chip,
        remainder+result.winScore,
        0,
        {type='normal',chessdata = result.chessdata},
        {}
    )
    local res={
        errno = 0,
        betIndex =betindex,
        bAllLine=LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = result.winLines,
        boards =boards,
        extraData={
            pools=pools
        },
        features={
            bonus = PackBonus(datainfo),
        },
    }
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore,Const.GOODS_SOURCE_TYPE.BEAUTYDISCO)
    unilight.update(Table,datainfos._id,datainfos)
    return res
end

function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local res={
        chessdata={},
        winScore = 0,
        winLines={},
    }
    local chip = datainfo.betMoney * LineNum
    local pools={}
    pools[1] = table_105_sgame[8].pmul * chip
    pools[2] = table_105_sgame[9].pmul * chip
    pools[3] = table_105_sgame[10].pmul * chip
    pools[4] = table_105_sgame[11].pmul * chip
    local cols={3,3,3}
    -- local chessdata =gamecommon.CreateSpecialChessData(cols,table_105_normalspin)
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    local chessdata =gamecommon.CreateSpecialChessData(cols,gamecommon.GetSpin(uid,GameId,gameType,betinfo))
    GmProcess(uid, GameId, gameType, chessdata,datainfo)
    local sNum = 0
    for col=1,#chessdata do
        for row=1,#chessdata[col] do
            if chessdata[col][row]==U then
                sNum = sNum + 1
            end
        end
    end
    if sNum>=3 then
        datainfo.bonus = {totalTimes=table_105_other[1].snum,lackTimes=table_105_other[1].snum,tWinScore=0,pools = pools}
    end
    local wild={}
    wild[W] = 1
    local nowild={}
    nowild[U] = 1
    local winLines={}
    winLines[1]={}
    --进行中奖验证
    local resdata = gamecommon.WiningLineFinalCalc(chessdata,table_105_payline,table_105_paytable,wild,nowild)
    local winScore = 0
    for _, value in ipairs(resdata) do
        winScore = winScore + value.mul * datainfo.betMoney
        -- print('line='..value.line)
        table.insert(winLines[1],{value.line,value.num,value.mul * datainfo.betMoney,value.ele})
    end
    res.chessdata = chessdata
    res.winScore = winScore
    res.winLines = winLines
    return res
end
function AheadBonus(uid,gameType,datainfo)
    local tablencfg=beautydisco['table_105_sgame_'..gameType]
    local ncfg = tablencfg[gamecommon.CommRandInt(tablencfg,'gailv')]
    local nId = ncfg.ID
    local winScore = 0
    if nId==1 then
        --加次数
        datainfo.bonus.totalTimes = datainfo.bonus.totalTimes + ncfg.enum
        datainfo.bonus.lackTimes = datainfo.bonus.lackTimes + ncfg.enum
    elseif nId>=2 and nId<=7 then
        --直接给钱
        winScore = ncfg.mul * datainfo.betMoney * LineNum
        datainfo.bonus.tWinScore = datainfo.bonus.tWinScore + winScore
        -- BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.BEAUTYDISCO)
    else
        --奖池
        winScore = datainfo.bonus.pools[nId-7]
        datainfo.bonus.tWinScore = datainfo.bonus.tWinScore + winScore
        -- BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.BEAUTYDISCO)
        -- if nId-7>2 then
        --     local pooldict={4,3,2,1}
        --     gamecommon.AddJackpotHisory(datainfos._id, GameId, gameType, 0 , winScore,{pool =pooldict[nId-7] })
        --     --lampgame.AddLampData(datainfo._id,GameId,winScore,3+(nId-8))
        --     local userinfo =  unilight.getdata('userinfo',datainfos._id)
        --     lampgame.AddLampData(datainfos._id, userinfo.base.nickname ,GameId,winScore,3+(nId-8))
        -- end
    end
    datainfo.bonus.lackTimes = datainfo.bonus.lackTimes - 1
    datainfo.bonus.nId = nId
    datainfo.bonus.winScore = winScore
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,table.clone(datainfo.bonus))
    return datainfo.bonus.tWinScore,datainfo.bonus.lackTimes
end

function Bonus(gameType,datainfo,datainfos)
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(datainfos._id)
    datainfo.bonus = datainfo.bres[1]
    table.remove(datainfo.bres, 1)
    local bonus = datainfo.bonus
    local winScore = bonus.winScore
    local nId = bonus.nId
    if nId - 7 > 2 then
        local pooldict = { 4, 3, 2, 1 }
        gamecommon.AddJackpotHisory(datainfos._id, GameId, gameType, 0, winScore, { pool = pooldict[nId - 7] })
        --lampgame.AddLampData(datainfo._id,GameId,winScore,3+(nId-8))
        local userinfo = unilight.getdata('userinfo', datainfos._id)
        lampgame.AddLampData(datainfos._id, userinfo.base.nickname, GameId, winScore, 3 + (nId - 8))
    end
    local res={
        errno = 0,
        betIndex =datainfo.betindex,
        bAllLine=LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        extraData={
            nId = nId,
            pools = datainfo.bonus.pools,
        },
        features={
            bonus = PackBonus(datainfo),
        },
    }
    if datainfo.bonus.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.bonus.tWinScore,Const.GOODS_SOURCE_TYPE.BEAUTYDISCO)
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        GameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip+datainfo.bonus.tWinScore-winScore,
        reschip+datainfo.bonus.tWinScore,
        0,
        {type='bonus',nId = nId,pools=datainfo.bonus.pools,totalTimes=bonus.totalTimes,lackTimes=bonus.lackTimes,tWinScore=bonus.tWinScore},
        {}
    )
    if datainfo.bonus.lackTimes<=0 then
        
        datainfo.bonus={}
    end
    unilight.update(Table,datainfos._id,datainfos)
    return res
end
