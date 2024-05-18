-- 轮盘模块
module('Roulette', package.seeall)
Roulette = Roulette or {}
-- 轮盘模块数据表
Roulette.Table_RouletteMul = require "table/table_roulette_mul"
Roulette.Table_RouletteScore = require "table/table_roulette_score"
Roulette.Table_RoulettePer = require "table/table_roulette_per"
Roulette.Table_RouletteOther = require "table/table_roulette_other"
-- 通用库存
Stock = {}
Stock[1] = {}
Stock[1].Stock = Roulette.Table_RouletteOther[1].initRepertory                              -- 库存值
Stock[1].decval = 0                                                                         -- 累计库存衰减值
GameId = 1001
-- 获取轮盘信息
Roulette.GetRouletteInfo = function()
    -- local mulList = {}
    local scoreList = {}
    -- -- 循环添加轮盘倍数信息
    -- for i, v in ipairs(Roulette.Table_RouletteMul) do
    --     table.insert(mulList,v.mul)
    -- end
    -- 循环添加轮盘下注信息
    for i, v in ipairs(Roulette.Table_RouletteScore) do
        table.insert(scoreList,v.score)
    end
    local res = {
        errno = ErrorDefine.SUCCESS,
        -- desc = "获取轮盘信息成功",
        -- mulList = mulList,
        scoreList = scoreList,
    }
    return res
end
-- 获取轮盘结果
Roulette.GetRoulettePlay = function(uid, score)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 判断score是否合法
    if not Roulette.ScoreLegal(score) then
        local res = {
            errno = ErrorDefine.ERROR_PARAM,
            -- desc = "客户端传入参数错误 score不合法",
        }
        return res
    end
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, score, "轮盘游玩扣费")
    if ok == false then
        local res = {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
            -- desc = "当前余额不足",
        }
        return res
    end
    -- 随机轮盘结果
    local mul = Roulette.GetRandomMul(uid)
    -- 增加库存金额
    Stock[1].Stock = Stock[1].Stock + (score * (1 - Roulette.Table_RouletteOther[1].coefficientRepertory / 10000))
    --增加金额
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, mul * score, Const.GOODS_SOURCE_TYPE.ROULETTE)
    -- 减少库存金额
    Stock[1].Stock = Stock[1].Stock - (mul * score)
    local res = {
        errno = ErrorDefine.SUCCESS,
        -- desc = "游玩成功",
        mul = mul,
    }
    -- 增加库存衰减游戏次数
    gamecommon.AddGamesCount(1001,1)

    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        1,
        score,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',mul=mul},
        {}
    )

    return res
end
-- 随机出轮盘倍数
Roulette.GetRandomMul = function(uid)
    -- 随机本次普通节点的奖励
    local probability = {}
    local allResult = {}
    for i, v in ipairs(Roulette.Table_RouletteMul) do
        local pro = 0
        -- 系数影响类型(1、不影响 2、系数影响)
        if v.type == 1 then
            pro = v.pro
        elseif v.type == 2 then
            pro = v.pro * GetCoefficientRepertory(uid)
        end
        if pro > 0 then
            table.insert(probability, pro)
            table.insert(allResult, {pro, v.mul})
        end
    end
    -- 获取随机出的轮盘倍数
    return math.random(probability, allResult)[2]
end
-- 判断score合法性
Roulette.ScoreLegal = function(score)
    -- 循环数据表判断是否存在数值
    for i, v in ipairs(Roulette.Table_RouletteScore) do
        if v.score == score then
            return true
        end
    end
    return false
end
-- 轮盘充值回调
Roulette.ChargeCallBack = function(uid, shopId, backPrice)
    --只处理轮盘的充值信息
    if math.floor(shopId / 100) ~= 6 then
        return
    end
    local res = GetRoulettePlay(uid,backPrice)
    local send = {}
    send['do'] = "Cmd.UserRouletteReturnSgnCmd_S"
    send['data'] = res
    unilight.sendcmd(uid,send)
end
-- 获取库存系数
Roulette.GetCoefficientRepertory = function(uid)
    -- 如果库存金额小于配置表中最小的金额
    if Stock[1].Stock < Roulette.Table_RoulettePer[#Roulette.Table_RoulettePer].minPercentage then
        return 0
    end
    local coefficient = (Stock[1].Stock / Roulette.Table_RouletteOther[1].initRepertory) * 100
    for _, v in ipairs(Roulette.Table_RoulettePer) do
        if coefficient >= v.minPercentage and coefficient <= v.maxPercentage then
            return v.coefficient
        end
    end
    return Roulette.Table_RoulettePer[1].coefficient
end

--------------------------------------------------------    外部调用    --------------------------------------------------------

--[[
    获取库存详情
    return{
        targetStock     --目标库存
        Stock           --实际库存
        decPeriod       --衰减周期
        decRatio        --衰减比例
        type            --衰减方式 1局数 2分钟
    }
    错误返回nil
]]
function GetStockInfo()
    return{
        targetStock = Roulette.Table_RouletteOther[1].initRepertory,
        Stock = Stock[1].Stock,
        decPeriod = Roulette.Table_RouletteOther[1].per,
        decRatio = Roulette.Table_RouletteOther[1].decPercent,
        type = Roulette.Table_RouletteOther[1].type,
        decval = Stock[1].decval,  --累计衰减值
    }
end
function SetStockInfo(data)
    Roulette.Table_RouletteOther[1].initRepertory = data.tarstock
    Stock[1].Stock = data.srcstock
    Roulette.Table_RouletteOther[1].per = data.decaytime
    Roulette.Table_RouletteOther[1].decPercent = data.decayratio
    Roulette.Table_RouletteOther[1].type = data.decaytype
    return true
end