module('corpse',package.seeall)
LineNum=30
GameId = 123
Table='game123corpse'
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
            bonus={},
            bresbonus={},
            normalScore = 0,
            normalChip = 0,
            addMulNum = 0,      --翻倍次数
            baseWin = 0,
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "万圣节玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    gamecommon.NameReqGamePoolBet(GameId, gameType, chip)
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, false, datainfo, chip, CommonRotate)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo=newdatainfo
    local boards = {}
    table.insert(boards, result.chessdata)
    local winLines = {}
    table.insert(winLines, result.winLines)
    local bonus = PackBonus(datainfo)
    if table.empty(bonus)==false then
        bonus.tringerPoints = {}
        for _, value in ipairs(datainfo.bonus.tringerPoints) do
            local tmp={}
            for _, v in ipairs(value) do
                table.insert(tmp,{line=v[1],row=v[2]})
            end
            table.insert(bonus.tringerPoints,tmp)
        end
    end
    if table.empty(result.jackpot)==false then
        result.winScore = result.winScore + result.jackpot.lineWin
        -- gamecommon.DecPool(result.jackpot.lineWin,result.jackpot.tWinScore-result.jackpot.lineWin,4,gameId,gameType)
        result.jackpot.tWinScore = result.jackpot.tWinScore -result.jackpot.lineWin
        gamecommon.DecPool(result.jackpot.lineWin,result.jackpot.tWinScore,4,gameId,gameType)
        gamecommon.AddJackpotHisory(datainfos._id,GameId,gameType,0,result.jackpot.tWinScore,{pool = 4})
        -- lampgame.AddRobotJackpotHistory({gameId=gameId,gameType=gameType,chips=result.jackpot.tWinScore,jackpotNum=0,extData={pool=4}})
        -- lampgame.AddTypeThreeRobot(gameId,6,result.jackpot.tWinScore)
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = winLines,
        boards = boards,
        features = {
            bonus = bonus,
            jackpot = result.jackpot,
        },
    }
    if result.jackpotChips>0 then
        result.jackpotChips = result.jackpotChips - result.jackpot.lineWin
    end
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.jackpotChips,Const.GOODS_SOURCE_TYPE.CORPSE)
    local winScore = result.winScore
    if table.empty(bonus)==false then
        winScore = 0
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        gameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfos._id)+winScore,
        0,
        { type = 'normal', chessdata = result.chessdata },
        result.jackpot
    )
    datainfo.normalChip = chip
    if table.empty(bonus)==false and bonus.extraData.type~=2 and bonus.extraData.type~=4 then
        datainfo.normalScore = result.winScore
    end
    if table.empty(bonus) then
        datainfo.normalScore = result.winScore
    end
    datainfo.addMulNum = 0
    unilight.update(Table, datainfos._id, datainfos)
    return res
end
function Bonus(pos,gameType, datainfo, datainfos)
    local reschip = chessuserinfodb.RUserChipsGet(datainfos._id)
    local bonus = datainfo.bonus
    local bres = datainfo.bresbonus[1]
    local nId = bres.nId
    bonus.lackTimes=bres.lackTimes
    bonus.tWinScore = bres.tWinScore
    bonus.isNewBonus = bres.isNewBonus
    if bonus.type==1 and pos==nil then
        return{
            errno = ErrorDefine.ERROR_POSERROR
        }
    end
    if bonus.type==1 then
        local col,row = pos[1],pos[2]
        if bonus.chessdata[col][row]==nil or bonus.chessdata[col][row]~=0 then
            return {
                errno = ErrorDefine.ERROR_POSERROR
            }
        end
        bonus.chessdata[col][row] = nId
    end
    if bonus.lackTimes<=0 then
        -- BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, bonus.tWinScore,Const.GOODS_SOURCE_TYPE.CORPSE)
        datainfo.normalScore = datainfo.normalScore + bonus.tWinScore
    end
    local winScore = 0
    if bonus.lackTimes<=0 then
        winScore = datainfo.normalScore
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        GameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(datainfos._id)+winScore,
        0,
        { type = 'bonus', nId = nId, tWinScore = bonus.tWinScore, lackTimes = bonus.lackTimes,
            totalTimes = bonus.totalTimes, ptype = bonus.type },
        {}
    )
    local ps = PackBonus(datainfo)
    ps.extraData.nId = nId
    --回送消息
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = 0,
        boards = {},
        features = {
            bonus = ps,
        },
    }
    if bonus.lackTimes<=0 then
        datainfo.bonus={}
    end
    unilight.update(Table, datainfos._id, datainfos)
    table.remove(datainfo.bresbonus,1)
    return res
end
--[[
    预先计算pickinfo产生的奖金
]]
function aHeadPickCalc(pickinfo,datainfo)
    local tmpbres = {}
    local tmppcikinfo = table.clone(pickinfo)
    local pgailv = corpse['table_123_p'..pickinfo.type..'gailv']
    while tmppcikinfo.lackTimes>0 do
        if tmppcikinfo.type==3 and tmppcikinfo.isNewBonus~=nil and tmppcikinfo.isNewBonus==true then
            pgailv = table_123_p3bonus
        end
        tmppcikinfo.lackTimes = tmppcikinfo.lackTimes - 1
        if tmppcikinfo.lackTimes<=0 and tmppcikinfo.type==1 then
            tmppcikinfo.nId = 0
        else
            local pcfg = pgailv[gamecommon.CommRandInt(pgailv,'gailv')]
            tmppcikinfo.nId = pcfg.ID
            if tmppcikinfo.type==2 then
                tmppcikinfo.tWinScore = tmppcikinfo.tWinScore + pcfg.mul*tmppcikinfo.baseWin
            elseif tmppcikinfo.type==3 and pcfg.mul<=0 then
                tmppcikinfo.isNewBonus = true
                tmppcikinfo.lackTimes = tmppcikinfo.lackTimes + 1
                tmppcikinfo.totalTimes = tmppcikinfo.totalTimes + 1
            else
                tmppcikinfo.tWinScore = tmppcikinfo.tWinScore + pcfg.mul*datainfo.betMoney*tmppcikinfo.mul
            end
        end
        table.insert(tmpbres,table.clone(tmppcikinfo))
    end
    return tmpbres,tmppcikinfo.tWinScore
end
--[[
    预先计算bonus
]]
function aHeadBonus(bonusinfo,datainfo)
    local tmpbres = {}
    local tmpbonus = table.clone(bonusinfo)
    local bonuscfg = table_123_bonusgailv[gamecommon.CommRandInt(table_123_bonusgailv,'gailv')]
    tmpbonus.nId = bonuscfg.ID
    tmpbonus.tWinScore=tmpbonus.tWinScore + bonuscfg.mul*tmpbonus.baseWin
    tmpbonus.lackTimes = tmpbonus.lackTimes - 1
    table.insert(tmpbres,tmpbonus)
    return tmpbres,tmpbonus.tWinScore
end
--通用旋转
function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local res = {
        chessdata = {}, --初始棋盘
        winLines = {},
        winScore = 0,
        tringerPoints = {},
        jackpotChips = 0,
        jackpot = {},
        specialWin = 0,
        isReRotate = false,
        isSucces=false,
        winPoints={},
    }
    local spin = {}
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    spin = gamecommon.GetSpin(uid, gameId, gameType,betinfo)
    local isReNum = false
    if datainfo.Param~=nil and datainfo.Param.reRotateNum>=7 then
        -- print('isReNum')
        res.isSucces = true
        spin = table_123_noWin
        datainfo.Param.reRotateNum=0
    end
    local cols = { 3, 3, 3, 3, 3 }
    res.chessdata = gamecommon.CreateSpecialChessData(cols, spin)
    local paylineIndex=  0
    local money =  table_jackpot_scale[2].iconMul*datainfo.betMoney*LineNum
    local jackpotchip =0
    if (datainfo.Param==nil or datainfo.Param.jackpotNum<7) and res.isSucces==false then
        jackpotchip =  gamecommon.IsWinJackPot(money,4,10,gameId,gameType)
    else
        datainfo.Param.jackpotNum=0
    end
    if jackpotchip>0 then
        for col=1,#res.chessdata do
            for row=1,#res.chessdata[col] do
                res.chessdata[col][row]=math.random(1,3)
            end
        end
        res.jackpot={
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = jackpotchip,
            lineWin = money,
            tringerPoints ={} ,
        }
        res.jackpotChips = jackpotchip
        local tmpPos={}
        for LineNo, rows in ipairs(table_123_payline) do
            local I = 1
            local num = 0
            while rows['I'..I]~=nil do
                local rs=rows['I'..I]
                I = I + 1
                if rs~=0 then
                    num = num + 1
                end
            end
            if num>3 then
                table.insert(tmpPos,LineNo)
            end
        end
        paylineIndex = tmpPos[math.random(1,#tmpPos)]
        local payline = table_123_payline[paylineIndex]
        for i=1,4 do
            local c,r = GetLineColAndRow(payline['I'..i])
            -- print(c,r)
            res.chessdata[c][r] = 73
            table.insert(res.jackpot.tringerPoints,{line=c,row=r})
        end
    end
    -- res.chessdata={{80,80,1},{72,2,2},{3,80,70},{80,71,2},{3,80,80}}
    GmProcess(uid,gameType,res.chessdata)
    --判断中奖
    local winLines,winScore,winLinesInfo = WinningLineInfo(datainfo.betMoney, res.chessdata)
    -- if jackpotchip>0 then
    --     table.insert(winLines,{paylineIndex,4,money,73,1})
    -- end
    local specialWin = {}
    for index, value in ipairs(winLinesInfo) do
        --判断pick1 是否中奖
        local p1info=IsPick1Win(value,datainfo)
        if table.empty(p1info)==false then
            table.insert(specialWin,{type=1,pinfo=p1info,winPoints=value.winPoints})
        end
        local p2info=IsPick2Win(value,datainfo)
        if table.empty(p2info)==false then
            table.insert(specialWin,{type=2,pinfo=p2info,winPoints=value.winPoints})
        end
        local p3info=IsPick3Win(value,datainfo)
        if table.empty(p3info)==false then
            table.insert(specialWin,{type=3,pinfo=p3info,winPoints=value.winPoints})
        end
        local p4info=IsBonus(value,datainfo)
        if table.empty(p4info)==false then
            table.insert(specialWin,{type=4,pinfo=p4info,winPoints=value.winPoints})
        end
        if value.winId==73 and value.num==4 and jackpotchip<=0 then
            res.isReRotate = true
            break
        elseif value.winId==81 and value.num==5 then
            res.isReRotate=true
            break
        elseif value.winId==100 and value.num>=4 then
            res.isReRotate=true
            break
        end
    end

    local typeMap = {}
    local typeNum = 0
    local t = {}
    for _, value in ipairs(specialWin) do
        if typeMap[value.type]==nil then
            typeNum = typeNum + 1
            typeMap[value.type] = value
            if typeNum>1 then
                -- res.isReRotate = true
                -- datainfo.Param =datainfo.Param or {reRotateNum = 0}
                -- datainfo.Param.reRotateNum = datainfo.Param.reRotateNum + 1
                break
            end
            t = value.pinfo
            t.tringerPoints={}
            t.baseWin = winScore
            table.insert(t.tringerPoints,value.winPoints)
        else
            t.mul = t.mul + value.pinfo.mul
            table.insert(t.tringerPoints,value.winPoints)
        end
    end
    if typeNum>1 then
        res.isReRotate =true
        datainfo.Param =datainfo.Param or {reRotateNum = 0,jackpotNum=0}
        datainfo.Param.reRotateNum = datainfo.Param.reRotateNum + 1
    elseif typeNum==1 then
        -- datainfo.Param = nil
        local bresbonus={}
        if t.type<4 then
            bresbonus,res.specialWin =aHeadPickCalc(t,datainfo)
        else
            bresbonus,res.specialWin = aHeadBonus(t,datainfo)
        end
        datainfo.bonus = t
        datainfo.bresbonus = bresbonus
        if t.type==2 or t.type==4 then
            res.specialWin = res.specialWin - winScore
        end
    elseif typeNum<=1 then
        datainfo.Param=datainfo.Param or {reRotateNum = 0,jackpotNum=0}
        datainfo.Param.reRotateNum=0
    end
    if table.empty(res.jackpot)==false then
        datainfo.Param =datainfo.Param or {reRotateNum=0,jackpotNum = 0}
        datainfo.Param.jackpotNum = datainfo.Param.jackpotNum + 1
    else
        datainfo.Param = datainfo.Param or {reRotateNum=0,jackpotNum = 0}
        datainfo.Param.jackpotNum = 0
    end
    res.winLines = winLines
    if jackpotchip>0 then
        res.winScore = winScore - money
    else
        res.winScore = winScore
    end
    -- print('winScore',res.winScore)
    return res
end
--[[
    pick1是否中奖
]]
function IsPick1Win(value,datainfo)
    if value.winId==72 then
        -- print(value.winId,value.isContinuous,value.isVertical)
        if value.isContinuous>=4 then
            --触发横向pick1
            local num = table_123_p1num[gamecommon.CommRandInt(table_123_p1num,'gailv')].num
            local chessdata = {}
            for col=1,4 do
                chessdata[col] = {}
                for row=1,3 do
                    chessdata[col][row] = 0
                end
            end
            local pickinfo = {totalTimes=num,lackTimes=num,tWinScore=0,type=1,mul = 2,chessdata=chessdata}
            -- table.insert(datainfo.pick,pickinfo)
            --[[
                执行预先pick计算
            ]]
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- print('bonus 72 4',tmpawin)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        elseif value.isContinuous==3 then
            --触发纵向pick1
            local num = table_123_p1num[gamecommon.CommRandInt(table_123_p1num,'gailv')].num
            local chessdata = {}
            for col=1,4 do
                chessdata[col] = {}
                for row=1,3 do
                    chessdata[col][row] = 0
                end
            end
            local pickinfo = {totalTimes=num,lackTimes=num,tWinScore=0,type=1,mul = 1,chessdata=chessdata}
            -- table.insert(datainfo.pick,pickinfo)
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- print('bonus 72 3',tmpawin)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        end
    end
    return {}
end
--[[
    pick2是否中奖
]]
function IsPick2Win(value,datainfo)
    if value.winId==73 or value.winId==70 then
        if value.isVertical==1 then
            -- local mul = 200
            -- if value.winId==70 then
            --     mul = 50
            -- end
            local pickinfo = {totalTimes=1,lackTimes=1,tWinScore=0,type=2,mul =0}
            -- table.insert(datainfo.pick,pickinfo)
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        end
    end
    return {}
end
--[[
    pick3是否中奖
]]
function IsPick3Win(value,datainfo)
    if value.winId==71 then
        local pickinfo = {}
        -- print(value.num,value.isContinuous)
        if value.isContinuous==5 then
            pickinfo = {totalTimes=1,lackTimes=1,tWinScore=0,type=3,mul =3,isNewBonus=false}
            -- table.insert(datainfo.pick,pickinfo)
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- print('tmpawin',tmpawin)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        elseif value.isContinuous==4 then
            pickinfo = {totalTimes=1,lackTimes=1,tWinScore=0,type=3,mul =2,isNewBonus=false}
            -- table.insert(datainfo.pick,pickinfo)
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- print('tmpawin',tmpawin)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        elseif value.isContinuous==3 and value.isMiddle==false then
            pickinfo = {totalTimes=1,lackTimes=1,tWinScore=0,type=3,mul =1,isNewBonus=false}
            -- table.insert(datainfo.pick,pickinfo)
            -- local tmpbres,tmpawin = aHeadPickCalc(pickinfo,datainfo)
            -- print('tmpawin',tmpawin)
            -- table.insert(datainfo.brespick,tmpbres)
            return pickinfo
        end
    end
    return {}
end
--[[
    判断bonus是否中奖
]]
function IsBonus(value,datainfo)
    if value.winId==81 or value.winId==80 then
        if value.num==3 and value.isVertical==1 then
            -- local mul = 250
            -- if value.winId==80 then
            --     mul = 70
            -- end
            local bonusinfo = {totalTimes=1,lackTimes=1,tWinScore=0,mul = 0,type=4}
            -- table.insert(datainfo.bonus,bonusinfo)
            -- local tmpbres,tmpawin = aHeadBonus(bonusinfo,datainfo)l
            -- table.insert(datainfo.bresbonus,tmpbres)
            return bonusinfo
        end
    end
    return {}
end
