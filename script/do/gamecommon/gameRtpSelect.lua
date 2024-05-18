module('gamecommon', package.seeall)
table_autoControl_nc1 = import 'table/table_autoControl_nc1'
table_autoControl_nc2 = import 'table/table_autoControl_nc2'
table_autoControl_nc3 = import 'table/table_autoControl_nc3'
table_autoControl_nc4 = import 'table/table_autoControl_nc4'
table_autoControl_nc5 = import 'table/table_autoControl_nc5'
table_autoControl_nc6 = import 'table/table_autoControl_nc6'
table_autoControl_nc7 = import 'table/table_autoControl_nc7'
table_autoControl_cz = import 'table/table_autoControl_cz'
table_autoControl_dc = import 'table/table_autoControl_dc'
table_autoControl_pp = import 'table/table_autoControl_pp'
table_autoControl_chargeLow = import 'table/table_autoControl_chargeLow'
table_autoControl_zero = import 'table/table_autoControl_zero'
table_autoControl_chargeLow1 = import 'table/table_autoControl_chargeLow1'
table_autoControl_chargeLow2 = import 'table/table_autoControl_chargeLow2'
table_autoControl_chargeLow3 = import 'table/table_autoControl_chargeLow3'
table_autoControl_chargeLow4 = import 'table/table_autoControl_chargeLow4'
table_autoControl_chargeLow5 = import 'table/table_autoControl_chargeLow5'
table_autoControl_chargeLow6 = import 'table/table_autoControl_chargeLow6'
table_autoControl_chargeLow7 = import 'table/table_autoControl_chargeLow7'
table_autoControl_chargeLow8 = import 'table/table_autoControl_chargeLow8'
table_autoControl_chargeLow9 = import 'table/table_autoControl_chargeLow9'
table_autoControl_chargeLow10 = import 'table/table_autoControl_chargeLow10'
table_autoControl_chargeLow11 = import 'table/table_autoControl_chargeLow11'
table_autoControl_chargeLow12 = import 'table/table_autoControl_chargeLow12'
table_autoControl_chargeLow13 = import 'table/table_autoControl_chargeLow13'
table_autoControl_chargeLow14 = import 'table/table_autoControl_chargeLow14'
table_autoControl_lowCha = import 'table/table_autoControl_lowCha'
table_parameter_parameter = import 'table/table_parameter_parameter'
table_stock_recharge_lv = import 'table/table_stock_recharge_lv'
table_stock_xs_1 = import 'table/table_stock_xs_1'
table_stock_xs_2 = import 'table/table_stock_xs_2'
table_stock_xs_3 = import 'table/table_stock_xs_3'
table_stock_xs_100 = import 'table/table_stock_xs_100'
tabl_stock_play_limit = import 'table/table_stock_play_limit'
table_auto_firstauto = import 'table/table_auto_firstauto'
table_auto_range = import 'table/table_auto_range'
table_auto_highcfg = import 'table/table_auto_highcfg'
table_auto_pointxs = import 'table/table_auto_pointxs'
table_auto_bxs  = import 'table/table_auto_bxs'
table_auto_pointN = import 'table/table_auto_pointN'
table_auto_pointLimit = import 'table/table_auto_pointLimit'
table_auto_hfix = import 'table/table_auto_hfix'
table_auto_JF = import 'table/table_auto_JF'
local table_auto_noCUL = import 'table/table_auto_noCUL'
--[[
    获取控制系数
]]
function GetControlPoint(uid,betinfo)
    local userinfo           = unilight.getdata('userinfo', uid)
    local controlvalue       = userinfo.point.controlvalue
    local autocontrolvalue   = userinfo.point.autocontrolvalue
    local autocontroltype    = userinfo.point.autocontroltype
    -- autocontroltype = 2
    -- controlvalue = 9000
    --获取当前金币
    local chips              = chessuserinfodb.GetAHeadTolScore(uid)
    local slotsCount         = userinfo.gameData.slotsCount
    --获取累计充值
    local totalRechargeChips = userinfo.property.totalRechargeChips
    --充值次数
    local rechargeNum        = userinfo.status.rechargeNum
    --总提现数
    local chipsWithdraw      = userinfo.status.chipsWithdraw
    local control            = 0
    userinfo.point.isInControl = 0
    --非充值玩家
    if totalRechargeChips <= 0 then
        control = SelectControlCfg(chips, slotsCount, userinfo)
        userinfo.point.IsNormal = 0
    else
        --充值玩家,库存影响
        control = SelectRechargeControlCfg(userinfo, chips, totalRechargeChips, chipsWithdraw,betinfo)
    end
    if autocontroltype == 2 and controlvalue < 10000 then
        userinfo.point.chargeMax = 1
        userinfo.point.isInControl = 1
        -- print('userinfo.point.chargeMax',userinfo.point.chargeMax)
        unilight.update('userinfo', userinfo._id, userinfo)
    elseif autocontroltype==2 and controlvalue>10000 then
        userinfo.point.chargeMax = 0
        unilight.update('userinfo', userinfo._id, userinfo)
    end
    if autocontroltype ~= 0 and control == 0 then
        userinfo.point.autocontroltype = 0
        userinfo.point.autocontrolvalue = 0
        userinfo.point.autocontroltime = os.time()
        unilight.update('userinfo', userinfo._id, userinfo)
    elseif autocontroltype == 0 and control > 0 then
        userinfo.point.autocontroltype = 1
        userinfo.point.autocontrolvalue = control
        userinfo.point.autocontroltime = os.time()
        controlvalue = control
        unilight.update('userinfo', userinfo._id, userinfo)
    elseif autocontroltype == 1 and control ~= autocontrolvalue then
        userinfo.point.autocontrolvalue = control
        controlvalue = control
        userinfo.point.autocontroltime = os.time()
        unilight.update('userinfo', userinfo._id, userinfo)
    elseif autocontroltype == 1 and control == autocontrolvalue then
        controlvalue = control
    end
    return controlvalue, totalRechargeChips, userinfo
end

--充值玩家RTP其实影响
function SelectRechargeControlCfg(userinfo, chips, totalRechargeChips, chipsWithdraw,betinfo)
    local rtp = 10000
    local condition = 0
    if totalRechargeChips<=0 and userinfo.point.isChargeHandle==1 then
        totalRechargeChips = 1000
    end
    for key, value in pairs(table_autoControl_dc) do
        if totalRechargeChips >= value.chargeLimit and totalRechargeChips <= value.chargeMax then
            condition = key
            break
        end
    end
    if condition <= 0 then
        condition = #table_autoControl_dc
    end
    --计算最大允许上限值
    gameKillComm.CalcChargeMax(chips,condition,userinfo)
    if userinfo.point.chargeMax < 0 then
        --零流水玩家
        userinfo.point.chargeMax = 1
        userinfo.point.isInControl = 1
    end
    userinfo.point.MiddleMul = 0
    local roomKey = betinfo.gameId * 10000 + betinfo.gameType
    --玩家默认受库存影响
    userinfo.point.IsNormal = 1
    if userinfo.property.totalRechargeChips<=4000 then
        --低充值玩家
        rtp = table_game_list[roomKey].lowChargeRtp
        userinfo.point.IsNormal = 0
        userinfo.point.isInControl = 1
    else
        rtp = gamestock.GetStockRtp(betinfo.gameId,betinfo.gameType)
    end
    --执行刀
    -- local killRtp =  gameKillComm.EnterKill(chips,userinfo,betinfo)
    if userinfo.point.MiddleChageMax>0 and userinfo.point.MiddleChageMax<userinfo.point.chargeMax then
        userinfo.point.chargeMax = userinfo.point.MiddleChageMax
    end
    -- if killRtp>0 then
    --     rtp = killRtp
    --     print('killRtp',rtp)
    -- end
    --超过上限控制
    local rtp1 = PassChargeKill(userinfo,chips)
    if rtp1>0 then
        rtp = rtp1
        print('ChargeMaxRtp',rtp)
    end
    --打码
    -- local tmprtp,mul = ChargeUserPlayChips(betinfo,userinfo)
    -- if tmprtp>0 then
    --     userinfo.point.pointMaxMul = mul
    --     rtp = tmprtp
    --     userinfo.point.IsNormal = 0
    --     userinfo.point.isInControl = 1
    --     print('PlayCode',rtp)
    -- end
    return rtp
end
--超过上限控制
function PassChargeKill(userinfo,chips)
    local rtp,ID = 0,0
    userinfo.point.pointMaxMul = 0
    local totalRechargeChips = userinfo.property.totalRechargeChips
    for ID,value in ipairs(table_auto_pointLimit) do
        if totalRechargeChips>=value.chargeLow1 and totalRechargeChips<=value.chargeUp1 and chips>userinfo.point.chargeMax then
            rtp = value.rtp1
            userinfo.point.pointMaxMul = value.rtpMul1
            userinfo.point.isInControl = 1
            break
        end
    end
    return rtp
end
--付费玩家需要打码量
function ChargeUserPlayChips(betinfo,userinfo)
    local rtp,mul = 0,0
    if userinfo.property.presentChips>0 or userinfo.property.isInPresentChips==1 then
        local totalRechargeChips = userinfo.property.totalRechargeChips
        for _,value in ipairs(table_auto_pointLimit) do
            if totalRechargeChips>=value.chargeLow1 and totalRechargeChips<=value.chargeUp1 then
                rtp = value.visualKillRtp
                if betinfo.gameId==127 or betinfo.gameId==131 or betinfo.gameId== 132 then
                    mul = value.pointMul
                else
                    mul = value.visualKillMul
                end
                break
            end
        end
    end
    return rtp,mul
end
--非充值用户
function SelectControlCfg(chips, slotsCount, userinfo)
    local index = userinfo.point.FreeControlIndex
    userinfo.point.chargeMax = table_auto_noCUL[index].chargeMax
    if chips>=userinfo.point.chargeMax then
        userinfo.point.isInControl = 1
        userinfo.point.MiddleMul =1
        return 9000
    end
    if slotsCount<=5 then
        return 20000
    end
    if userinfo.point.FreeControlType==0 then
        userinfo.point.noChargeMax = math.random(table_auto_noCUL[index].winLow,table_auto_noCUL[index].winUp)
        userinfo.point.noChargeMin = math.random(table_auto_noCUL[index].lostLow,table_auto_noCUL[index].lostUp)
        
        userinfo.point.FreeControlType = 1
    end
    if chips>=userinfo.point.noChargeMax then
        --进入刀逻辑
        userinfo.point.FreeControlType = 2
        userinfo.point.isInControl = 1
        --随机下限
        userinfo.point.noChargeMin = math.random(table_auto_noCUL[index].lostLow,table_auto_noCUL[index].lostUp)
    elseif userinfo.point.FreeControlType ==2 and chips<=userinfo.point.noChargeMin then
        if index<#table_auto_noCUL then
            index = index + 1
            userinfo.point.FreeControlIndex = userinfo.point.FreeControlIndex + 1
        end
        userinfo.point.noChargeMax = math.random(table_auto_noCUL[index].winLow,table_auto_noCUL[index].winUp)
        userinfo.point.FreeControlType = 1
    end
    if userinfo.point.FreeControlType==1 then
        userinfo.point.MiddleMul = table_auto_noCUL[index].winMul
        local rtp = 10000
        if chips>=0 and chips<2000 then
            rtp = table_auto_noCUL[index].r1
        elseif chips>=2000 and chips<4000 then
            rtp = table_auto_noCUL[index].r2
        elseif chips>=4000 and chips<6000 then
            rtp = table_auto_noCUL[index].r3
        elseif chips>=6000 and chips<8000 then
            rtp = table_auto_noCUL[index].r4
        elseif chips>=8000 and chips<10000 then
            rtp = table_auto_noCUL[index].r5
        elseif chips>=10000 and chips<12000 then
            rtp = table_auto_noCUL[index].r6
        elseif chips>=12000 and chips<14000 then
            rtp = table_auto_noCUL[index].r7
        elseif chips>=14000 and chips<20000 then
            rtp = table_auto_noCUL[index].r8
        elseif chips>=20000 and chips<999999999999 then
            rtp = table_auto_noCUL[index].r9
        end
        return rtp
    else
        userinfo.point.MiddleMul = table_auto_noCUL[index].lostMul
        -- userinfo.point.isInControl = 1
        return table_auto_noCUL[index].lostRtp
    end
end
--RTP选择
--[[
    200 50 100          三种控制模型
]]
function GetModelRtp(uid, gameId, gameType, controlvalue)
    --获取房间库存RTP
    local userinfo = unilight.getdata('userinfo',uid)
    local tolXs = 1
    tolXs = tolXs * controlvalue / 10000    --获取当前金币
    userinfo.point.cTolxs = tolXs
    if tolXs>=1.5 then
        local gte1Model = {
            { rtp = 200, gailv = (tolXs - 1.5)*2 },
            { rtp = 150, gailv = 1- ((tolXs - 1.5)*2)},
        }
        local rtpmodel = gte1Model[CommRandFloat(gte1Model, 'gailv')]
        return rtpmodel.rtp
    elseif tolXs>=1 and tolXs<1.5 then
        local gte1Model = {
            { rtp = 150, gailv = (tolXs - 1)*2 },
            { rtp = 100, gailv = 1- ((tolXs - 1)*2)},
        }
        local rtpmodel = gte1Model[CommRandFloat(gte1Model, 'gailv')]
        return rtpmodel.rtp
    elseif tolXs>=0.75 and tolXs<1 then
        local gte1Model = {
            { rtp = 100, gailv = (tolXs - 0.75)*4 },
            { rtp = 75, gailv = 1- ((tolXs - 0.75)*4)},
        }
        local rtpmodel = gte1Model[CommRandFloat(gte1Model, 'gailv')]
        return rtpmodel.rtp
    elseif tolXs<0.75 then
        local gte1Model = {
            { rtp = 75, gailv = (tolXs - 0.5)*4 },
            { rtp = 50, gailv = 1- ((tolXs - 0.5)*4)},
        }
        local rtpmodel = gte1Model[CommRandFloat(gte1Model, 'gailv')]
        return rtpmodel.rtp
    end
end
--[[
    betinfo={
        betindex,betchips   --下注档次,下注具体值
    }
]]
function GetSpin(uid, gameId, gameType,betinfo)
    local controlvalue, totalRechargeChips, userinfo = GetControlPoint(uid,betinfo)
    local rtp                                       = 0
    rtp                                             = GetModelRtp(uid, gameId, gameType, controlvalue)
    print('rtp=' .. rtp .. ',controlvalue=' .. controlvalue)
    local spin = ''
    if rtp == 100 then
        spin = string.format('table_%d_normalspin_%d', gameId, gameType)
    else
        spin = string.format('table_%d_normalspin_%d_%d', gameId, rtp, gameType)
    end
    --返回
    local importstr = string.format('table/game/%d/%s', gameId, spin)
    -- print('Rtp',rtp)
    return import(importstr), rtp
end

--提现系数重随
function CashOutRtpRandom(uid)
    
end

--充值系数重随
function RechageRtpRandom(uid,shopId,backPrice)
    --充值系数处理
    -- gameKillComm.ChargeRandomKill(uid)
    --拉起生效万分比
    -- gameHelp.ChargeBack(uid,backPrice)
end
--判断当前转轴用户是否处在点控中
function IsRotateInControl()
    -- print('IsRotateInControl')
    if SuserId==nil or SuserId.uid==0 then
        -- print('SuserId==nil')
        return false
    end
    local userinfo = unilight.getdata('userinfo',SuserId.uid)
    -- print('userinfo.point.isInControl',userinfo.point.isInControl)
    if userinfo.point.isInControl == 1 then
        return true
    end
    return false
end