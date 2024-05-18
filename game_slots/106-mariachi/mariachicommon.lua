module('mariachi',package.seeall)
--MARIACHI
Table='game106mariachi'
GameId = 106
LineNum = 25
table_106_normalspin = import 'table/game/106/table_106_normalspin'
table_106_freespin = import 'table/game/106/table_106_freespin'
table_106_other = import 'table/game/106/table_106_other'
table_106_T = import 'table/game/106/table_106_T'
table_106_freeset = import 'table/game/106/table_106_freeset'
table_106_sgame = import 'table/game/106/table_106_sgame'
table_106_payline = import 'table/game/106/table_106_payline'
table_106_paytable = import 'table/game/106/table_106_paytable'
table_106_jackpot_chips = import 'table/game/106/table_106_jackpot_chips'
table_106_jackpot_add_per = import 'table/game/106/table_106_jackpot_add_per'
table_106_jackpot_bomb = import 'table/game/106/table_106_jackpot_bomb'
-- table_106_jackpot_scale = import 'table/game/106/table_106_jackpot_scale'
table_106_jackpot_bet = import 'table/game/106/table_106_jackpot_bet'
table_106_TOut = import 'table/game/106/table_106_TOut'


-- w  90-99
W=90
U=80
S=70
S1=71   --女主变幻任意图标
J=100
function Get(gameType,uid)
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
            free={},
            pick={},
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table,datainfos._id,datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo,datainfos
end
function Normal(gameId, gameType,betindex,datainfo,datainfos)
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "墨西哥流浪乐队玩法投注")
    if ok==false then
        return{
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    gamecommon.ReqGamePoolBet(gameId, gameType, chip)
    -- local result = CommonRotate(datainfos._id,gameId, gameType,false,datainfo)
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, false, datainfo, chip, CommonRotate,AheadBonus)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot)==false then
        gamecommon.AddJackpotHisoryTypeOne(datainfos._id,GameId,gameType,result.jackpot.iconNum,result.jackpotChips)
    end
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines ={}
    table.insert(winLines,result.winLines)
    local res={
        errno = 0,
        betIndex =betindex,
        bAllLine=LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = winLines,
        boards =boards,
        tringerPoints=result.tringerPoints,
        extraData={
            icon71To = result.icon71To,
            jackpotChips=result.jackpotChips,
         },
        features={
            free = PackFree(datainfo),
            bonus = PackPick(datainfo),
            jackpot=result.jackpot,
        }
    }
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore + result.jackpotChips, Const.GOODS_SOURCE_TYPE.MARIACHI)
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        GameId,
        gameType,
        chip,
        remainder+chip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        {type='normal',chessdata = result.chessdata,icon71To=result.icon71To},
        result.jackpot
    )
    unilight.update(Table,datainfos._id,datainfos)
    return res
end
function Free(gameId, gameType,datainfo,datainfos)
    local chip = datainfo.betMoney*LineNum
    -- local result = CommonRotate(datainfos._id,gameId, gameType,true,datainfo)
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, true, datainfo, chip, CommonRotate,AheadBonus)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot)==false then
        gamecommon.AddJackpotHisoryTypeOne(datainfos._id,GameId,gameType,result.jackpot.iconNum,result.jackpotChips)
    end
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines ={}
    table.insert(winLines,result.winLines)
    datainfo.free.lackTimes = datainfo.free.lackTimes -1
    datainfo.free.tWinScore = datainfo.free.tWinScore + result.winScore
    if result.jackpotChips>0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.jackpotChips, Const.GOODS_SOURCE_TYPE.MARIACHI)
    end
    local res={
        errno = 0,
        betIndex =datainfo.betindex,
        bAllLine=LineNum,
        payScore = datainfo.betMoney*LineNum,
        winScore = result.winScore,
        winLines = winLines,
        boards =boards,
        tringerPoints=result.tringerPoints,
        extraData={
           icon71To = result.icon71To,
           jackpotChips=result.jackpotChips,
        },
        features={
            free = PackFree(datainfo),
            bonus = PackPick(datainfo),
            jackpot = result.jackpot,
        }
    }
    local rchip =  chessuserinfodb.RUserChipsGet(datainfos._id)
    if datainfo.free.lackTimes<=0 and table.empty(datainfo.pick) then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.MARIACHI)
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        GameId,
        gameType,
        datainfo.betMoney*LineNum,
        rchip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        {type='free',chessdata = result.chessdata,icon71To=result.icon71To,totalTimes=datainfo.free.totalTimes,lackTimes=datainfo.free.lackTimes,tWinScore = datainfo.free.tWinScore},
        result.jackpot
    )
    if datainfo.free.lackTimes<=0 then
        datainfo.free={}
    end
    unilight.update(Table,datainfos._id,datainfos)
    return res
end
function AheadBonus(uid,gameType,datainfo)
    local chip = datainfo.betMoney * LineNum
    local table_sgame = mariachi['table_106_sgame_'..gameType]
    local mul =  table_sgame[gamecommon.CommRandInt(table_sgame,'gailv')].mul
    datainfo.pick.tWinScore = chip*mul
    datainfo.pick.lackTimes = 0
    datainfo.pick.mul = mul
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,table.clone(datainfo.pick))
    local tWinScore,lackTimes = datainfo.pick.tWinScore,datainfo.pick.lackTimes
    return tWinScore,lackTimes
end


function Pick(gameType,datainfo,datainfos)
    datainfo.pick = datainfo.bres[1]
    local mul = datainfo.pick.mul
    table.remove(datainfo.bres,1)
    if table.empty(datainfo.free)==false then
        datainfo.free.tWinScore = datainfo.free.tWinScore + datainfo.pick.tWinScore
    end
    local boards = {}
    table.insert(boards,datainfo.pick.chessdata)
    local res={
        errno = 0,
        betIndex =datainfo.betindex,
        bAllLine=LineNum,
        payScore = datainfo.betMoney*LineNum,
        winScore = datainfo.pick.tWinScore,
        winLines = {},
        boards =boards,
        features={
            free = PackFree(datainfo),
            bonus = PackPick(datainfo),
        }
    }
    if datainfo.pick.lackTimes<=0 then
        local rchip = chessuserinfodb.RUserChipsGet(datainfos._id)
        if table.empty(datainfo.free) then
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.pick.tWinScore, Const.GOODS_SOURCE_TYPE.MARIACHI)
        else
            if datainfo.free.lackTimes<=0 then
                BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.MARIACHI)
                datainfo.free={}
            end
        end
        gameDetaillog.SaveDetailGameLog(
            datainfos._id,
            os.time(),
            GameId,
            gameType,
            datainfo.betMoney*LineNum,
            rchip,
            chessuserinfodb.RUserChipsGet(datainfos._id),
            0,
            {type='pick',winScore = datainfo.pick.tWinScore,mul=mul},
            {}
        )
        datainfo.pick={}
    end
    
    unilight.update(Table,datainfos._id,datainfos)
    return res
end
function CommonRotate(uid,gameId, gameType,isfree,datainfo)
    local res={
        chessdata={},               --初始棋盘
        winLines={},
        winScore = 0,
        icon71To=0,                 --71图标变化成多少
        tringerPoints={},           --图标触发位置
        jackpotChips=0,
        jackpot={},
    }
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    -- local spin = table_106_normalspin
    local spin = gamecommon.GetSpin(uid,gameId,gameType,betinfo)
    if isfree then
        -- spin = table_106_freespin
        spin = mariachi['table_106_freespin_'..gameType]
    end
    local cols={3,3,3,3,3}
    res.chessdata = gamecommon.CreateSpecialChessData(cols,spin)
    local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(gameId, gameType, datainfo.betindex)
    if bSucess then
        res.jackpot={
            lackTimes = 0,
            totalTimes=1,
            tWinScore = jackpotChips,
            tringerPoints = {},
        }
        for col=1,iconNum do
            local row = math.random(3)
            res.chessdata[col][row] = J
            table.insert(res.jackpot.tringerPoints,{line=col,row=row})
        end
        res.jackpotChips = jackpotChips
        --res.winScore = res.jackpotChips
        -- gamecommon.AddJackpotHisory(uid, gameId, gameType, iconNum, jackpotChips,{})
        -- --lampgame.AddLampData(uid,gameId,jackpotChips,1)
        -- local userinfo =  unilight.getdata('userinfo',uid)
        -- lampgame.AddLampData(uid, userinfo.base.nickname ,gameId,jackpotChips,1)
    end
    local jackFill = gamecommon.FillJackPotIcon:New(5,3,bSucess,GameId)
    GmProcess(uid, gameId, gameType, res.chessdata,datainfo)
    RandOutT(res.chessdata)
    local dchessdata = table.clone(res.chessdata)
    --检查s1图标替换
    for col=1,#res.chessdata do
        for row=1,#res.chessdata[col] do
            if res.chessdata[col][row]==S1 then
                if res.icon71To==0 then
                    --需要随机
                    res.icon71To = table_106_T[gamecommon.CommRandInt(table_106_T,'gailv')].iconid
                end
                dchessdata[col][row] = res.icon71To
            end
        end
    end
    local sNum,tringerPoints = CalcFree(dchessdata)
    res.tringerPoints = tringerPoints
    for _, value in ipairs(res.tringerPoints) do
        jackFill:FillExtraIcon(value.line,value.row)
    end
    local uNum = 0
    for col=1,#dchessdata do
        for row=1,#dchessdata[col] do
            if dchessdata[col][row]==U then
                uNum = uNum + 1
                jackFill:FillExtraIcon(col,row)
            elseif dchessdata[col][row]==S1 then
                jackFill:FillExtraIcon(col,row)
            end
        end
    end
    if sNum>=3 then
        local freenum  =table_106_freeset[sNum].fnum
        if isfree then
             datainfo.free.totalTimes = datainfo.free.totalTimes + freenum
             datainfo.free.lackTimes = datainfo.free.lackTimes + freenum
        else
            datainfo.free={totalTimes=freenum,lackTimes=freenum,tWinScore=0}
        end
    end
    if uNum>=3 then
        datainfo.pick={totalTimes=1,lackTimes=1,tWinScore = 0,chessdata=dchessdata}
    end
    local wild={}
    wild[W] = 1
    for i=1,9 do
        wild[W+i] = 1
    end
    local nowild={}
    nowild[S] = 1
    nowild[U] = 1
    local resdata = gamecommon.WiningLineFinalCalc(dchessdata,table_106_payline,table_106_paytable,wild,nowild)
    for _, value in ipairs(resdata) do
        if value.ele~=S then
            local sWin = value.mul * datainfo.betMoney
            if isfree then
                for _,v in ipairs(value.iconval) do
                    if wild[v]~=nil then
                        sWin = sWin *table_106_other[1].mul
                        break
                    end
                end
            end
            res.winScore = res.winScore + sWin
            table.insert(res.winLines,{value.line,value.num,sWin,value.ele})
        end
        jackFill:PreWinData(value.winicon)
    end
    if sNum>=3 then
        --判断s中奖
        local mul = table_106_paytable[S]['c'..sNum]
        res.winScore =res.winScore + datainfo.betMoney*LineNum*mul
    end
    jackFill:CreateFinalChessData(res.chessdata,J)
    return res
end
function CalcFree(chessdata)
    local tringerPoints={}
    local bFind=true
    local sNum = 0
    for col=1,#chessdata do
        if bFind==false then
            if sNum>=3 then
                return sNum,tringerPoints
            else
                sNum = 0
                tringerPoints = {}
            end
        end
        bFind = false
        for row=1,#chessdata[col] do
            if chessdata[col][row]==S then
                bFind = true
                sNum = sNum + 1
                table.insert(tringerPoints,{line=col,row=row})
                break
            end
        end
    end
    if sNum<3 then
        sNum = 0
        tringerPoints = {}
    end
    return sNum,tringerPoints
end
function RandOutT(chessdata)
    local tableRandPos={}
    for col=1,#chessdata do
        for row=1,#chessdata[col] do
            if chessdata[col][row]<70 then
                table.insert(tableRandPos,{col,row})
            end
        end
    end
    local randNum = table_106_TOut[gamecommon.CommRandInt(table_106_TOut,'gailv')].num
    for i=1,randNum do
        local posindex = math.random(#tableRandPos)
        local pos = tableRandPos[posindex]
        chessdata[pos[1]][pos[2]]=S1
        table.remove(tableRandPos,posindex)
    end
end