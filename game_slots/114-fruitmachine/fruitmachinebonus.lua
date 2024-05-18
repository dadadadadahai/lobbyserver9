--水果机器模块
module('FruitMachine',package.seeall)

--水果机器Bonus游戏
function PlayBonusGame(fruitmachineInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)

    local bonus = fruitmachineInfo.bres[1]

    -- 如果是第一个转盘
    if fruitmachineInfo.bonus.bonusType == 0 then
        -- 保存数据
        fruitmachineInfo.bonus = bonus
        table.remove(fruitmachineInfo.bres,1)
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,fruitmachineInfo)
        -- 返回数据
        local res = GetResInfo(uid, fruitmachineInfo, gameType, nil, {})
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            fruitmachineInfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='bonus',bonusNum = 1,bonusType = fruitmachineInfo.bonus.bonusType},
            {}
        )
        return res
    elseif fruitmachineInfo.bonus.spinTotalTimes == 0 then      -- 第二个转盘
        -- 保存数据
        fruitmachineInfo.bonus = bonus
        table.remove(fruitmachineInfo.bres,1)
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,fruitmachineInfo)
        -- 返回数据
        local res = GetResInfo(uid, fruitmachineInfo, gameType, nil, {})
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            fruitmachineInfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='bonus',bonusNum = 2,bonusType = fruitmachineInfo.bonus.bonusType,tWinScore=fruitmachineInfo.bonus.spinTotalTimes},
            {}
        )
        return res
    end

    -- 保存数据
    fruitmachineInfo.bonus = bonus
    table.remove(fruitmachineInfo.bres,1)

    -- 返回数据
    local res = GetResInfo(uid, fruitmachineInfo, gameType, nil, {})
    -- 判断是否结算
    if fruitmachineInfo.bonus.spinTimes >= fruitmachineInfo.bonus.spinTotalTimes then
        res.features.bonus.lackTimes = 0
        if fruitmachineInfo.bonus.bonusType == 2 and fruitmachineInfo.bonus.tWinScore > 0 then
            if fruitmachineInfo.free.totalTimes == -1 then
                -- 获取奖励
                BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, fruitmachineInfo.bonus.tWinScore, Const.GOODS_SOURCE_TYPE.FRUITMACHINE)
            else          
                fruitmachineInfo.free.tWinScore = fruitmachineInfo.free.tWinScore + fruitmachineInfo.bonus.tWinScore
                res.features.free.tWinScore = fruitmachineInfo.free.tWinScore
            end
        elseif fruitmachineInfo.bonus.bonusType == 1 then
            if fruitmachineInfo.free.totalTimes == -1 then
                fruitmachineInfo.free.totalTimes = fruitmachineInfo.bonus.tWinScore
                
                res.features.free.totalTimes = fruitmachineInfo.free.totalTimes
                res.features.free.lackTimes = fruitmachineInfo.free.totalTimes
                res.features.free.tWinScore = 0
            else
                fruitmachineInfo.free.totalTimes = fruitmachineInfo.free.totalTimes + fruitmachineInfo.bonus.tWinScore
                
                res.features.free.totalTimes = fruitmachineInfo.free.totalTimes
                res.features.free.lackTimes = fruitmachineInfo.free.totalTimes - fruitmachineInfo.free.times
                res.features.free.tWinScore = fruitmachineInfo.free.tWinScore
            end
        end
    end
    local mul = 0
    local freeNum = 0
    if fruitmachineInfo.bonus.bonusType == 2 then
        mul = fruitmachineInfo.bonus.winScore / fruitmachineInfo.betMoney
    else
        freeNum = fruitmachineInfo.bonus.winScore
    end
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        fruitmachineInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='bonus',bonusNum = 3,bonusType = fruitmachineInfo.bonus.bonusType,freeNum = freeNum,mul = mul,totalTimes=fruitmachineInfo.bonus.spinTotalTimes,lackTimes=fruitmachineInfo.bonus.spinTotalTimes-fruitmachineInfo.bonus.spinTimes,tWinScore=fruitmachineInfo.bonus.tWinScore},
        {}
    )
    if fruitmachineInfo.bonus.spinTimes >= fruitmachineInfo.bonus.spinTotalTimes then
        fruitmachineInfo.bonus.totalTimes = -1                                      -- 总次数
        fruitmachineInfo.bonus.times = 0                                            -- 游玩次数
        fruitmachineInfo.bonus.spinTotalTimes = 0                                   -- 总次数
        fruitmachineInfo.bonus.spinTimes = 0                                        -- 游玩次数
        fruitmachineInfo.bonus.tWinScore = 0                                        -- 已经赢得的钱
        fruitmachineInfo.bonus.bonusType = 0                                        -- 转盘类型
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fruitmachineInfo)
    return res
end

-- 预计算bonus
function AheadBonus(uid,gameType,datainfo)

    -- 如果是第一个转盘
    if datainfo.bonus.bonusType == 0 then
        -- 纯随机
        local probability = {}
        local allResult = {}
        for i, v in ipairs(Table_Bonus1) do
            if v.pro > 0 then
                table.insert(probability, v.pro)
                table.insert(allResult, {v.pro, v.state})
            end
        end
        -- 获取随机后的结果
        datainfo.bonus.bonusType = math.random(probability, allResult)[2]
        -- 保存本次随机的结果
        datainfo.bres = datainfo.bres or {}
        table.insert(datainfo.bres,table.clone(datainfo.bonus))
        return 0,datainfo.bonus.totalTimes - datainfo.bonus.times
    elseif datainfo.bonus.spinTotalTimes == 0 then      -- 第二个转盘
        local userinfo = unilight.getdata('userinfo',uid)
        --获取累计充值
        local totalRechargeChips = userinfo.property.totalRechargeChips
        if totalRechargeChips <= 0 and datainfo.bonus.bonusType == 2 then
            datainfo.bonus.spinTotalTimes = Table_Bonus2[1].num
        else
            -- 纯随机
            local probability = {}
            local allResult = {}
            for i, v in ipairs(Table_Bonus2) do
                if v.pro > 0 then
                    table.insert(probability, v.pro)
                    table.insert(allResult, {v.pro, v.num})
                end
            end
            -- 获取随机后的结果
            datainfo.bonus.spinTotalTimes = math.random(probability, allResult)[2]
        end
        -- 保存本次随机的结果
        datainfo.bres = datainfo.bres or {}
        table.insert(datainfo.bres,table.clone(datainfo.bonus))
        return 0,datainfo.bonus.totalTimes - datainfo.bonus.times
    end
    -- 增加Bonus游戏次数
    datainfo.bonus.spinTimes = datainfo.bonus.spinTimes + 1
    -- 纯随机
    local probability = {}
    local allResult = {}
    for i, v in ipairs(Table_Bonus3[datainfo.bonus.bonusType]) do
        if v.pro > 0 then
            table.insert(probability, v.pro)
            table.insert(allResult, {v.pro, v})
        end
    end
    -- 获取随机后的结果
    local playResult = math.random(probability, allResult)[2]
    local winScore = 0
    if datainfo.bonus.bonusType == 1 then       -- 如果是增加免费次数 不处理
        winScore = playResult.freeNum
        datainfo.bonus.winScore = winScore
    elseif datainfo.bonus.bonusType == 2 then   -- 如果是增加金额    增加赢取金额
        winScore = playResult.mul * datainfo.betMoney
        datainfo.bonus.winScore = winScore
    end

    datainfo.bonus.tWinScore = datainfo.bonus.tWinScore + winScore

    -- 保存本次随机的结果
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,table.clone(datainfo.bonus))
    -- 循环添加已经随机出现的结果  获取总奖励
    local lackTimes = datainfo.bonus.totalTimes - datainfo.bonus.times
    if datainfo.bonus.spinTimes >= datainfo.bonus.spinTotalTimes then
        lackTimes = 0
    end
    return datainfo.bonus.tWinScore,lackTimes
end