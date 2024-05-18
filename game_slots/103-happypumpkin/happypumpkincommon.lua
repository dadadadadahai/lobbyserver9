module('happypumpkin',package.seeall)
Table = 'game103happypumpkin'
GameId = 103
LineNum =25
table_103_other = import 'table/game/103/table_103_other'
table_103_normalspin = import 'table/game/103/table_103_normalspin'
table_103_freespin = import 'table/game/103/table_103_freespin'
table_103_paytable = import 'table/game/103/table_103_paytable'
table_103_payline = import 'table/game/103/table_103_payline'
table_103_jackpot_chips = import 'table/game/103/table_103_jackpot_chips'
table_103_jackpot_add_per = import 'table/game/103/table_103_jackpot_add_per'
table_103_jackpot_bomb = import 'table/game/103/table_103_jackpot_bomb'
-- table_103_jackpot_scale = import 'table/game/103/table_103_jackpot_scale'
table_103_jackpot_bet = import 'table/game/103/table_103_jackpot_bet'

W = 90
S = 70
A = 12
B = 11
C = 10
F = 7
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
            -- cnum = table_103_other[1].cs,
            -- nnum = table_103_other[1].cf,
            collectBet={}
        }
        rInfo.collectBet[rInfo.betindex] ={cnum =table_103_other[1].cs,nnum=table_103_other[1].cf}
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table,datainfos._id,datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo,datainfos
end
--普通模式
function Normal(gameId,gameType,betindex,datainfo,datainfos)
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "快乐南瓜玩法投注")
    if ok==false then
        return{
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    gamecommon.ReqGamePoolBet(gameId, gameType, chip)
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local sTime = os.time()
    -- local result = CommonRotate(datainfos._id,gameId,gameType,false,datainfo)
    local result,newdatainfo = gamecontrol.RealCommonRotate(datainfos._id,gameId,gameType,false,datainfo,chip,CommonRotate,nil)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot)==false then
        gamecommon.AddJackpotHisoryTypeOne(datainfos._id,GameId,gameType,result.jackpot.iconNum,result.jackpotChips)
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        gameId,
        gameType,
        chip,
        remainder+chip,
        remainder+result.winScore+result.jackpotChips,
        0,
        {type='normal',chessdata = result.chessdata},
        result.jackpot  
    )
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines ={}
    table.insert(winLines,result.winLines)
    local itemcollectbet = datainfo.collectBet[datainfo.betindex]
    local res={
        errno = 0,
        betIndex =betindex,
        bAllLine=LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = winLines,
        boards =boards,
        extraData={
            changeIcons = result.changeIcons,
            collectInfo = result.collectInfo,
            fNum = result.fNum,
            jackpotChips=result.jackpotChips,
        },
        features={
            free = datainfo.free,
            jackpot=result.jackpot,
        },
        collect = {
            curPro = itemcollectbet.cnum,
            talPro = itemcollectbet.nnum,
        },
    }
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore+result.jackpotChips, Const.GOODS_SOURCE_TYPE.HAPPYPUMPKIN)
    unilight.update(Table,datainfos._id,datainfos)
    return res
end
function Free(gameId,gameType,datainfo,datainfos)
    local chip = datainfo.betMoney * LineNum
    local sTime = os.time()
    local reschip =  chessuserinfodb.RUserChipsGet(datainfos._id)
    -- local result = CommonRotate(datainfos._id,gameId,gameType,true,datainfo)
    local result,newdatainfo = gamecontrol.RealCommonRotate(datainfos._id,gameId,gameType,true,datainfo,chip,CommonRotate,nil)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot)==false then
        gamecommon.AddJackpotHisoryTypeOne(datainfos._id,GameId,gameType,result.jackpot.iconNum,result.jackpotChips)
    end
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines ={}
    table.insert(winLines,result.winLines)
    local free = datainfo.free
    datainfo.free.lackTimes = datainfo.free.lackTimes - 1
    datainfo.free.tWinScore = datainfo.free.tWinScore + result.winScore
    local itemcollectbet = datainfo.collectBet[datainfo.betindex]
    if result.jackpotChips>0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.jackpotChips, Const.GOODS_SOURCE_TYPE.HAPPYPUMPKIN)
    end
    local res={
        errno = 0,
        betIndex =datainfo.betindex,
        bAllLine=LineNum,
        payScore = datainfo.betMoney*LineNum,
        winScore = result.winScore,
        winLines = winLines,
        boards =boards,
        extraData={
            changeIcons = result.changeIcons,
            collectInfo = result.collectInfo,
            fNum = result.fNum,
            mul = table_103_other[1].mul,
            jackpotChips=result.jackpotChips,
        },
        features={
            free = datainfo.free,
            jackpot=result.jackpot,
        },
        collect = {
            curPro = itemcollectbet.cnum,
            talPro = itemcollectbet.nnum,
        },
    }
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.HAPPYPUMPKIN)
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        gameId,
        gameType,
        datainfo.betMoney*LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        {type='free',chessdata = result.chessdata,totalTimes=free.totalTimes,lackTimes=free.lackTimes,tWinScore=free.tWinScore},
        result.jackpot
    )
    if datainfo.free.lackTimes<=0 then
        datainfo.free={}
    end
    unilight.update(Table,datainfos._id,datainfos)
    return res
end



function CommonRotate(uid,gameId,gameType,isfree,datainfo)
    local res={
        chessdata={},               --初始棋盘
        winLines={},
        winScore = 0,
        changeIcons={},
        collectInfo={},
        fNum = 0,
        jackpotChips=0,
        jackpot ={},
    }
    datainfo.collectBet[datainfo.betindex] = datainfo.collectBet[datainfo.betindex] or {cnum =table_103_other[1].cs,nnum=table_103_other[1].cf}
    local itemcollectBet = datainfo.collectBet[datainfo.betindex]
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    local spin = gamecommon.GetSpin(uid,gameId,gameType,betinfo)
    -- local spin = table_103_normalspin
    if isfree then
        -- spin = table_103_freespin
        spin = happypumpkin['table_103_freespin_'..gameType]
    end
    local cols ={3,3,3,3,3}
    res.chessdata = gamecommon.CreateSpecialChessData(cols,spin)
    GmProcess(uid,gameId,gameType,res.chessdata,datainfo)
    -- res.chessdata[2][2] = 10
    -- res.chessdata[1][2] = 12
    -- res.chessdata[3][1]  =11
    -- res.chessdata[4][1] = 12
    local dchessdata = ChangeWild(res.chessdata,res.changeIcons)
        --获得奖励
    local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(gameId, gameType, datainfo.betindex)
    --获得奖池奖励
    if bSucess and #res.changeIcons<=0 then
        res.jackpot={
            lackTimes = 0,
            totalTimes=1,
            tWinScore = jackpotChips,
            tringerPoints = {},
        }
        for col=1,iconNum do
            local row = math.random(3)
            res.chessdata[col][row] = J
            dchessdata[col][row] = J
            table.insert(res.jackpot.tringerPoints,{line=col,row=row})
        end
        local r1 = {1,2,3,4}
        local r2=  {5,6,8,9}
        for r=1,3 do
            local rd = math.random(#r1)
            local val = r1[rd]
            if res.chessdata[1][r] ~=J then
                res.chessdata[1][r] = val
                dchessdata[1][r] = val
            end
        end
        for r=1,3 do
            local rd = math.random(#r2)
            local val = r2[rd]
            if res.chessdata[2][r] ~=J then
                res.chessdata[2][r] = val
                dchessdata[2][r] = val
            end
        end
        for r=1,3 do
            local rd = math.random(#r1)
            local val = r2[rd]
            if res.chessdata[4][r] ~=J then
                res.chessdata[4][r] = val
                dchessdata[4][r] = val
            end
        end
        for r=1,3 do
            local rd = math.random(#r1)
            local val = r1[rd]
            if res.chessdata[5][r] ~=J then
                res.chessdata[5][r] = val
                dchessdata[5][r] = val
            end
        end
    else
        jackpotChips = 0
        bSucess=false
    end
    local wild={}
    wild[W] = 1
    local nowild={}
    nowild[S] = 1
    local fNum = 0              --本次收集的f图标数量
    local collectMap = {}
    local jackFill = gamecommon.FillJackPotIcon:New(5,3,bSucess,GameId)
    local sNum = 0
    for col=1,#res.chessdata do
        for row=1,#res.chessdata[col] do
            if res.chessdata[col][row]==S then
                jackFill:FillExtraIcon(col,row)
                sNum = sNum + 1
            elseif res.chessdata[col][row]==A or res.chessdata[col][row]==B or res.chessdata[col][row]==C then
                jackFill:FillExtraIcon(col,row)
            end
        end
    end
    local resdata = gamecommon.WiningLineFinalCalc(dchessdata,table_103_payline,table_103_paytable,wild,nowild)
    for _, value in ipairs(resdata) do
        local singleMoney = value.mul * datainfo.betMoney
        if isfree then
            singleMoney = singleMoney * table_103_other[1].mul
        end
        if value.num==5 then
            singleMoney = singleMoney/2
        end
        res.winScore = res.winScore + singleMoney
        table.insert(res.winLines,{value.line,value.num,singleMoney,value.ele})
        if value.ele==F then
            for _, val in ipairs(value.winpos) do
                local col,row=val[1],val[2]
                if dchessdata[col][row]==F then
                    local str=col..'-'..row
                    collectMap[str] = {col,row}
                    --table.insert(res.collectInfo,{col,row})
                    --fNum = fNum + 1
                end
            end

        end
        --排除中奖图标
        local linecfg = table_103_payline[value.line]
        for i=1,value.num do
            local row = math.floor(linecfg['I'..i]/10)
            local col = linecfg['I'..i]%10
            --print(value.line,row,col)
            jackFill:FillExtraIcon(col,row)
        end
    end
    jackFill:CreateFinalChessData(res.chessdata,J)
    for _, value in pairs(collectMap) do
        table.insert(res.collectInfo,{value[1],value[2]})
        fNum = fNum + 1
    end
    res.jackpotChips = jackpotChips
    --res.winScore = res.winScore + res.jackpotChips
    if isfree then
        datainfo.free.totalTimes =  datainfo.free.totalTimes + fNum
        datainfo.free.lackTimes =  datainfo.free.lackTimes + fNum
        if sNum>=3 then
            datainfo.free.totalTimes =  datainfo.free.totalTimes + 8
            datainfo.free.lackTimes =  datainfo.free.lackTimes + 8
        end
    else
        itemcollectBet.cnum = itemcollectBet.cnum + fNum
        if itemcollectBet.cnum>=itemcollectBet.nnum then
            itemcollectBet.cnum = itemcollectBet.nnum
            --触发免费
            datainfo.free = {totalTimes = itemcollectBet.cnum,lackTimes = itemcollectBet.cnum,tWinScore = 0 }
            itemcollectBet.cnum = 8
        elseif sNum>=3 then
            datainfo.free = {totalTimes = itemcollectBet.cnum,lackTimes = itemcollectBet.cnum,tWinScore = 0 }
            itemcollectBet.cnum = 8
        end
    end
    res.fNum = fNum
    return res
end
--变化wild处理
function ChangeWild(chessdata,changeIcons)
    local changemap={}
    changemap[C] = 1
    changemap[B] = 1
    for col = 1,#chessdata do
        for row=1,#chessdata[col] do
            if chessdata[col][row]==A then
                local left = col - 1
                local right = col + 1
                if chessdata[left]~=nil and chessdata[right]~=nil then
                    if changemap[chessdata[left][row]]~=nil and changemap[chessdata[right][row]]~=nil then
                        chessdata[left][row]=math.random(6)
                    end
                end
            end
        end
    end
    local dchessdata = table.clone(chessdata)
    for col = 1,#dchessdata do
        for row=1,#dchessdata[col] do
            if dchessdata[col][row]==A then
                local left = col - 1
                local right = col + 1
                if left>=1 then
                    ItemChange(col,row,left,dchessdata,changeIcons)
                end
                if right<=5 then
                    ItemChange(col,row,right,dchessdata,changeIcons)
                end
            end
        end
    end
    return dchessdata
end
function ItemChange(col,row,c,chessdata,changeIcons)
    if chessdata[c][row] == C then
        chessdata[col][row] = W
        table.insert(changeIcons,{col,row})
    elseif chessdata[c][row]==B then
        --整列变化
        for rt=1,3 do
            chessdata[col][rt] = W
            table.insert(changeIcons,{col,rt})
        end
    end
end