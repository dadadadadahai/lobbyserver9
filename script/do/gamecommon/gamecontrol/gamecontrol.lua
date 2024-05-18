module('gamecontrol',package.seeall)
local table_parameter_parameter= import "table/table_parameter_parameter"
local table_stock_tax = import 'table/table_stock_tax'
local table_auto_betUp = import 'table/table_auto_betUp'
local table_auto_pointN = import 'table/table_auto_pointN'
local table_auto_bxs = import 'table/table_auto_bxs'
local table_autoControl_dc = import 'table/table_autoControl_dc'
local table_auto_highcfg = import 'table/table_auto_highcfg'
local sgameFuncMap = {}
--[[
    游戏特殊玩法注册
]]
function RegisterSgameFunc(gameId,playingType,sgameFunc)
    sgameFuncMap[gameId] = sgameFuncMap[gameId] or {}
    sgameFuncMap[gameId][playingType] = sgameFunc
end
function RealCommonRotate(_id,gameId, gameType, isfree, datainfo,chip,func,sgameFunc)
    local userinfo = unilight.getdata('userinfo',_id)

    --获取累计充值
    local totalRechargeChips = userinfo.property.totalRechargeChips
    if userinfo.point.rangeId~=nil and userinfo.point.rangeId==6 and userinfo.point.rangeControlGames==0 then
        local chips =chessuserinfodb.GetAHeadTolScore(_id)
        local x2 = math.random(table_auto_highcfg[1].x2low,table_auto_highcfg[1].x2up)/100
        if chips>totalRechargeChips*table_auto_highcfg[1].x1*x2 - userinfo.status.chipsWithdraw then
            userinfo.point.rangeControlGames = math.random(table_auto_highcfg[1].x3low,table_auto_highcfg[1].x3up)
        end
    end
    if userinfo.point.rangeControlGames~=nil and userinfo.point.rangeControlGames>0 then
        userinfo.point.pointMaxMul = 1
        userinfo.point.rangeControlGames = userinfo.point.rangeControlGames - 1
    end
    --充值玩家,非充值玩家
    local res,tmp = nocharge_user(_id,gameId,gameType,isfree,datainfo,chip,totalRechargeChips,func,sgameFunc)
    if userinfo.point.rangeId~=nil and userinfo.point.rangeId==6 and userinfo.point.rangeControlGames==0 then
        userinfo.point.pointMaxMul = 0
        userinfo.point.rangeId = 0
    end
    return res,tmp
end
--非充值玩家
function nocharge_user(_id,gameId,gameType,isfree,datainfo,chip,totalRechargeChips,func,sgameFunc)
    local getBetIndex = function ()
        if datainfo.betindex==nil then
            return datainfo.betIndex
        end
        return datainfo.betindex
    end
    local tmpdatainfo = table.clone(datainfo)
    local betinfo={
        betindex = getBetIndex(),
        betchips = chip,
        gameId = gameId,
        gameType = gameType,
    }
    local controlvalue = gamecommon.GetControlPoint(_id,betinfo)
    --获取当前金币
    local result = {}
     --数据记录
    local dataRecord = {}
    result = func(_id, gameId, gameType, isfree, tmpdatainfo)
    local userinfo = unilight.getdata('userinfo',_id)
    PlayMaxMul(_id,chip,totalRechargeChips,gameType,datainfo)
    --预先计算不中奖金额
    local aHeadWinscore = AheadBonusPickWinScore(_id,gameId,gameType,tmpdatainfo,datainfo,sgameFunc)
    --当次中奖金额
    local curWinscore,jackpotChips, freeWinScore= CurResultTwinScore(result,tmpdatainfo,datainfo)
    --控制玩家不触发
    local firstControlLow = ControlLow(controlvalue,tmpdatainfo,datainfo)
    --控制玩家当前中奖额度不超过多少倍
    local maxmulAllow = IsAllowMaxMul(gameId,aHeadWinscore,curWinscore,jackpotChips,freeWinScore,chip,gameType,userinfo)
    table.insert(dataRecord,{result,tmpdatainfo,datainfo,curWinscore,aHeadWinscore,firstControlLow,jackpotChips,freeWinScore})
    
    local whileNum = 0
    local maxWhileNum = 10
    local maxchipfunc
    if totalRechargeChips<=0 then
        maxchipfunc = FreeUserMaxChips
    else
        maxchipfunc = ChargeUserMaxChip
    end
    local isWhile = false
    --非充值玩家不允许超过的最大金币
    while true do
        if (GameSingleMaxMul(curWinscore,chip) or firstControlLow or maxmulAllow or maxchipfunc(_id,chip,aHeadWinscore + curWinscore,tmpdatainfo,datainfo,totalRechargeChips) or (result.isReRotate~=nil and result.isReRotate)) or isWhile then
            --执行循环
            local param=nil
            if table.empty(tmpdatainfo.Param)==false then
                param = tmpdatainfo.Param
            end
            tmpdatainfo = table.clone(datainfo)
            tmpdatainfo.Param = param
            result = func(_id, gameId, gameType, isfree, tmpdatainfo)
            PlayMaxMul(_id,chip,totalRechargeChips,gameType,datainfo)
            aHeadWinscore = AheadBonusPickWinScore(_id,gameId,gameType,tmpdatainfo,datainfo,sgameFunc)
            --当次中奖金额
            curWinscore,jackpotChips,freeWinScore = CurResultTwinScore(result,tmpdatainfo,datainfo)
            --判断是否触发特殊
            firstControlLow = ControlLow(controlvalue,tmpdatainfo,datainfo)
            maxmulAllow = IsAllowMaxMul(gameId,aHeadWinscore,curWinscore,jackpotChips,freeWinScore,chip,gameType,userinfo)
            whileNum=whileNum+1
            table.insert(dataRecord,{result,tmpdatainfo,datainfo,curWinscore,aHeadWinscore,firstControlLow,jackpotChips,freeWinScore})
            if isWhile==false then
                isWhile=true
            end
            -- print('while while',whileNum,curWinscore + aHeadWinscore)
            if whileNum>=maxWhileNum then
                break
            end
        else
            break
        end
    end
    table.sort(dataRecord,function (a, b)
        return a[4]+a[5]>b[4]+a[5]
    end)
    local isOk = false
    local dataRecordIndex = 1
    for index, value in ipairs(dataRecord) do
        isOk =  IsAllowMaxMul(gameId,value[4],value[5],value[7],value[8],chip,gameType,userinfo) or maxchipfunc(_id,chip,value[4]+value[5],value[2],value[3],totalRechargeChips)
        if controlvalue<10000 then
            isOk = isOk or value[6]
        end
        -- print('1',value[1].isSucces~=nil and value[1].isSucces)
        -- print('2',value[1].isReRotate==nil or value[1].isReRotate==false)
        -- print('3',isOk)
        if (isOk==false and ((value[1].isReRotate==nil or value[1].isReRotate==false) or (value[1].isSucces~=nil and value[1].isSucces))) then
            result = value[1]
            tmpdatainfo = value[2]
            dataRecordIndex=index
            break
        end
    end
    if isOk then
        table.sort(dataRecord,function (a, b)
            return a[4]+a[5]<b[4]+a[5]
        end)
        --不满足结果求解
        for index,value in ipairs(dataRecord) do
            local specialScene = {'free','bonus','pick','respin'}
            local isSpecial = false
            for _,v in ipairs(specialScene) do
                if IsCreateNewPlayingGame(v,value[2],value[3]) then
                    isSpecial = true
                    break
                end
            end
            if isSpecial==false then
                result = value[1]
                tmpdatainfo = value[2]
                dataRecordIndex=index
                break
            end
        end
    end
    local d = dataRecord[dataRecordIndex]
    local specialWin=0
    if result.specialWin~=nil then
        specialWin = result.specialWin
    end
    local twinscore = result.winScore+d[5] + specialWin
    local nochangeStock = {
        [109] = 1
    }
    local stockGameType = gameType
    local specialScene = {'bonus','pick','free','respin'}
    local isnew = false 
    for _, value in ipairs(specialScene) do
        isnew = isnew or IsCreateNewPlayingGame(value,tmpdatainfo,d[3])
    end
    local addscore = 0
    local xTax = 0
    if IsGameInPlayingGame(tmpdatainfo)==false or isnew then
        --进行数据统计
        userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + chip
    else
        chip = 0
    end
    if nochangeStock[gameId]==nil then
        userinfo.gameData.slotsWin = userinfo.gameData.slotsWin + twinscore + d[7]
        gamestock.RawStock(gameId,gameType,chip,twinscore,userinfo)
    end
    -- print('curStock',gamestock.GetStock(gameId,gameType))
    return result,tmpdatainfo
end
--[[
    根据下注档次，充值系统等确定玩家最大可中倍数
]]
function PlayMaxMul(uid,betchip,totalRechargeChips,gameType,datainfo)
    local getBetIndex = function ()
        if datainfo.betindex==nil then
            return datainfo.betIndex
        end
        return datainfo.betindex
    end
    local chips =chessuserinfodb.GetAHeadTolScore(uid)
    local userinfo = unilight.getdata('userinfo',uid)
    local condition = 0
    for key, value in pairs(table_autoControl_dc) do
        if totalRechargeChips >= value.chargeLimit and totalRechargeChips <= value.chargeMax then
            condition = key
            break
        end
    end
    if condition <= 0 then
        condition = #table_autoControl_dc
    end
    local mul = table_parameter_parameter[19].Parameter
    for index, value in ipairs(table_auto_betUp) do
        if value.stageId==gameType and getBetIndex()==value.betIndex then
            mul = value.mul
            break
        end
    end
    
    local mul1 = 0
    local selfMul = userinfo.point.pointMaxMul or 0
    if mul>mul1 and mul1>0 then
        mul = mul1
    end
    if mul>selfMul and selfMul>0 then
        mul = selfMul
    end
    if userinfo.point.MiddleMul~=nil and userinfo.point.MiddleMul>0 and userinfo.point.MiddleMul<mul then
        mul = userinfo.point.MiddleMul
    end
    userinfo.point.maxMul = mul
    print('userinfo.point.maxMul',userinfo.point.maxMul)
end

--[[
    aHeadWinscore 预计算的中奖金额
    curWinscore 当前中中奖金额  
    判断是否超过库存值
]]
function IsAllowMaxMul(gameId,aHeadWinscore,curWinscore,jackpotChips,freeWinScore,chip,gameType,userinfo)
    local freeExtMapGame ={}
    freeExtMapGame[121] = 1
    freeExtMapGame[126] = 1
    freeExtMapGame[129] = 1
    local maxmul = table_parameter_parameter[19+(gameType-1)].Parameter
    local maxchips = table_parameter_parameter[36].Parameter
    -- print('userinfo.point.maxMul',userinfo.point.maxMul)
    if userinfo.point.maxMul==nil or userinfo.point.maxMul<=0 then
        if aHeadWinscore>maxmul*chip then
            return true
        end
        if curWinscore-jackpotChips>maxmul*chip then
            return true
        end
        if curWinscore-jackpotChips>maxchips then
            return true
        end
    else
        if aHeadWinscore>userinfo.point.maxMul*chip then
            return true
        end
        if freeExtMapGame[gameId]~=nil and freeWinScore>0 then
            if freeWinScore>=chip*200 then
                return true
            end
        elseif freeWinScore>userinfo.point.maxMul*chip then
            return true
        elseif curWinscore-jackpotChips>userinfo.point.maxMul*chip then
           return true
        elseif curWinscore-jackpotChips>maxchips then
            return true
        end
    end
    --库存变化影响
    -- if userinfo.point.IsNormal==1 then
    --     local curstock  = gamestock.GetStock(gameId,gameType)
    --     if (curWinscore-jackpotChips+aHeadWinscore)>curstock then
    --         print('stock true')
    --         return true
    --     end
    -- end
    return false
end
--[[
    判断是否触发了新玩法
]]
function IsCreateNewPlayingGame(playingType,tmpdatainfo,datainfo)
    if (table.empty(tmpdatainfo[playingType])==false and table.empty(datainfo[playingType])) or ((table.empty(datainfo[playingType]) == false and datainfo[playingType].totalTimes == -1) and (table.empty(tmpdatainfo[playingType]) == false and tmpdatainfo[playingType].totalTimes ~= -1)) then
        return true
    end
    return false
end
--[[
    判断当前游戏是否在特殊玩法中
]]
function IsGameInPlayingGame(datainfo)
    local specialScene = {'bonus','pick','free','respin'}
    for _, value in ipairs(specialScene) do
        if table.empty(datainfo[value])==false and datainfo[value].totalTimes~=nil and  datainfo[value].totalTimes>0 then
            return true,datainfo[value].tWinScore,value
        end
    end
    return false,0,''
end
--[[
    预先计算首次产生bonus,pick到结束产生的总奖励
]]
function AheadBonusPickWinScore(uid,gameId,gameType,tmpdatainfo,datainfo,sgameFunc)
    local realSgameFunc = nil
    local specialScene = {'free','bonus','pick','respin'}
    for _, value in ipairs(specialScene) do
        -- if table.empty(tmpdatainfo[value])==false and table.empty(datainfo[value]) then
        if (IsCreateNewPlayingGame(value,tmpdatainfo,datainfo)) then
            local gameIdMap =  sgameFuncMap[gameId]
            if gameIdMap~=nil then
                local tmpfunc = gameIdMap[value]
                if tmpfunc~=nil then
                    realSgameFunc = tmpfunc
                end
            end
            if realSgameFunc~=nil then
               --首次触发,执行预计算
                local val = table.clone(tmpdatainfo[value])
                while true do
                    local tWinScore,lackTimes = realSgameFunc(uid,gameType,tmpdatainfo)
                    if lackTimes<=0 then
                        tmpdatainfo[value] = val
                        -- print('AheadBonusPickWinScore',tWinScore)
                        return tWinScore
                    end
                end
            end
        end
    end
    -- print('AheadBonusPickWinScore',0)
    return 0
end
--[[
    计算当次结果的总奖励金币
]]
function CurResultTwinScore(result,tmpdatainfo,datainfo)
    local specialScene = {'bonus','pick','free','collect'}
    local isSpecil =false
    local winScore=  0
    local freeWinScore = 0
    for _, value in ipairs(specialScene) do
        -- if table.empty(tmpdatainfo[value])==false then
        if table.empty(tmpdatainfo[value])==false and  tmpdatainfo[value].tWinScore ~= nil and tmpdatainfo[value].totalTimes > 0 then
            local tmpTWinScore = tmpdatainfo[value].tWinScore+result.winScore
            if value=='free'then
                freeWinScore = tmpTWinScore
            end
            if table.empty(datainfo[value])==false and datainfo[value].tWinScore==tmpTWinScore then
                isSpecil=true
                tmpTWinScore = 0
            end
            winScore = winScore + tmpTWinScore
        end
    end
    local jackpotChips = 0
    if winScore<=0 and isSpecil==false then
        winScore = result.winScore
    end
    if result.specialWin~=nil then
        winScore = winScore + result.specialWin
        -- print('result.aHeadWin',result.specialWin)
    end
    --判断本次是否中jackpot
    if result.jackpotChips~=nil and result.jackpotChips>0 then
        winScore = winScore + result.jackpotChips
        jackpotChips=result.jackpotChips
        if result.jackpot~=nil and result.jackpot.lineWin~=nil then
            jackpotChips = jackpotChips - result.jackpot.lineWin
        end
    end
    print('CurResultTwinScore',winScore)
    -- print('freeWinScore',freeWinScore)
    return winScore,jackpotChips,freeWinScore
end
--[[
    是否超过游戏允许的最大倍数
]]
function GameSingleMaxMul(winScore,betChip)
    -- if winScore>betChip*MaxMul then
    --     print('GameSingleMaxMul')
    --     return true
    -- end
    return false
end
--[[
    控制玩家不触发
]]
function ControlLow(control,tmpdatainfo,datainfo)
    -- local specialScene = {'bonus','pick','free'}
    -- for _, value in ipairs(specialScene) do
    --     -- if table.empty(tmpdatainfo[value])==false and table.empty(datainfo[value]) then
    --     if (table.empty(tmpdatainfo[value])==false and table.empty(datainfo[value])) or ((table.empty(datainfo[value]) == false and datainfo[value].totalTimes == -1) and (table.empty(tmpdatainfo[value]) == false and tmpdatainfo[value].totalTimes ~= -1)) then
    --         if control<10000 then
    --             return true
    --         end
    --     end
    -- end
    return false
end
--[[
    免费玩家不允许超过最大的金币上限
]]
function FreeUserMaxChips(_id,chip,winScore,tmpdatainfo,datainfo,totalRechargeChips)
    local chips =chessuserinfodb.GetAHeadTolScore(_id)
    local userinfo = unilight.getdata('userinfo',_id)
    if chips>userinfo.point.chargeMax then
        return false
    end
    if chips+winScore>userinfo.point.chargeMax then
        if winScore>chip then
            return true
        end
        if IsCreateNewPlayingGame('free',tmpdatainfo,datainfo) then
            -- print('no pass chargeMax free')
            return true
        end
    end
    return false
end
--[[
    玩家不能超过chargeMax
]]
function ChargeUserMaxChip(_id, chip,winScore,tmpdatainfo,datainfo,totalRechargeChips)
    local chips =chessuserinfodb.GetAHeadTolScore(_id)
    local userinfo = unilight.getdata('userinfo',_id)
    if userinfo.point.chargeMax~=nil and userinfo.point.chargeMax>0 then
        -- print('userinfo.point.chargeMax',userinfo.point.chargeMax)
        if userinfo.point.isMiddleKill~=nil and userinfo.point.isMiddleKill==1 then
            if chips>userinfo.point.chargeMax then
                return false
            end
            if chips + winScore>userinfo.point.chargeMax then
                if winScore>chip then
                    print('winScore>chip True')
                    return true
                end
            end
        else
            if chips>userinfo.point.chargeMax then
                return false
            end
            if chips + winScore>userinfo.point.chargeMax then
                if winScore>chip then
                    print('winScore>chip True')
                    return true
                end
            end
        end
    end
    return false
end
