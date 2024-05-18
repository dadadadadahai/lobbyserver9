-- 点球大战游戏模块
module('PenaltyKick', package.seeall)
-- 点球大战所需数据库表名称
DB_Name = "game201penaltykick"
-- 点球大战所需配置表信息
table_201_sessions = import 'table/game/201/table_penaltykick_sessions'
table_201_percentage = import 'table/game/201/table_penaltykick_per'
table_201_other = import 'table/game/201/table_penaltykick_other'
table_201_pro = import 'table/game/201/table_penaltykick_pro'

-- 点球大战特殊元素ID
W = 90
Jackpot = 100
LineNum = 1
-- 点球大战通用配置
DataFormat = {3,3,3}                                                                        -- 棋盘规格
GameId = 201
-- 通用库存
Stock = {}                                                                                  -- 库存
Extraction = {}                                                                             -- 抽水
Attenuation = {}                                                                            -- 累计衰减
AttenuationType = table_201_other[1].attenuationMode                                        -- 库存衰减方式 1按局数 2按分钟
GamePlayNumber = 0                                                                          -- 游戏游玩局数

-- 构造数据存档
function Get(gameType,uid)
    -- 获取点球大战模块数据库信息
    local penaltykickInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(penaltykickInfo) then
        penaltykickInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,penaltykickInfo)
    end
    if gameType == nil then
        return penaltykickInfo
    end
    -- 没有初始化房间信息
    if table.empty(penaltykickInfo.gameRooms[gameType]) then
        penaltykickInfo.gameRooms[gameType] = {
            betIndexList = {1,2,3}, -- 当前玩家下注下标
            winScore = 0, -- 玩家赢得的金钱
            payScore = 0, -- 玩家初始下注的金钱
            noCommissionWinScore = 0, -- 没有手续费的赢钱
            peopleType = 1, -- 玩家球员类型
        }
        unilight.update(DB_Name,uid,penaltykickInfo)
    end
    -- if Stock[gameType]==nil then
    --     Stock[gameType] = table_201_sessions[gameType].initStock
    -- end
    return penaltykickInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取点球大战模块数据库信息
    local penaltykickInfo = unilight.getdata(DB_Name, uid)
    penaltykickInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,penaltykickInfo)
end
-- 游玩游戏逻辑
function PlayGames(penaltykickInfo,uid,betIndex,betIndexList,peopleType,mul,gameType)
    -- 判断玩家是否充值
    if chessuserinfodb.GetChargeInfo(uid) <= 0 then
        return{
            errno = ErrorDefine.NO_RECHARGE,
            desc='需要充值才能游玩',
            param = table_201_sessions[gameType].betCondition,
        }
    end
    -- 判断金币是否足够
    if chessuserinfodb.RUserChipsGet(uid)<table_201_sessions[gameType].betCondition then
        return{
            errno=ErrorDefine.NOT_ENOUGHTCHIPS,
            param = table_201_sessions[gameType].betCondition,
        }
    end
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 更新数据信息
    penaltykickInfo.peopleType = peopleType or penaltykickInfo.peopleType
    betIndex = betIndex or {}
    if #betIndexList ~= 3 then
        return{
            errno = ErrorDefine.ERROR_PARAM,
            desc='参数错误'
        }
    end
    for i, v in ipairs(betIndexList) do
        if not (v <= #table_201_other[1].betconfig and v >= 1) then
            return{
                errno = ErrorDefine.ERROR_PARAM,
                desc='参数错误'
            }
        end
    end
    local isFirst = false
    if penaltykickInfo.winScore == 0 then
        if AttenuationType == 1 then
            GamePlayNumber = GamePlayNumber + 1
        end
        local payScore = 0                                           -- 全部下注金额
        -- 循环增加下注金额
        -- for _, index in ipairs(penaltykickInfo.betIndex) do
            --     payScore = payScore + (table_201_other[1].betconfig[index] or 0)
            -- end
        -- 增加下注金额
        payScore = table_201_other[1].betconfig[betIndexList[betIndex]]
        -- jackpot发送客户端的数据表
        local jackpot = {}
        -- 扣除金额
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "点球大战下注扣费")
        if ok == false then
            local res = {
                errno = 1,
                desc = "当前余额不足"
            }
            return res
        end
        isFirst = true
        penaltykickInfo.payScore = payScore
        penaltykickInfo.winScore = payScore
    end
    -- 获取系数
    local coefficient = 1
    -- 如果超出配置范围 系数为最大系数
    if Stock[gameType] >= table_201_sessions[1].initStock * table_201_percentage[1].maxPercentage / 100 then
        coefficient = table_201_percentage[1].coefficient
    end
    for i, v in ipairs(table_201_percentage) do
        if Stock[gameType] >= table_201_sessions[1].initStock * v.minPercentage / 100 and Stock[gameType] <= table_201_sessions[1].initStock * v.maxPercentage / 100 then
            coefficient = v.coefficient
        end
    end
    local pro = 0
    -- 获取概率
    for i, v in ipairs(table_201_pro) do
        if v.mul == mul then
            pro = v.pro * coefficient
        end
    end
    if (Stock[gameType] - (mul * penaltykickInfo.winScore)) <= 0 then
        pro = 0
    end
    -- 如果是第一次下注需要增加库存
    if isFirst then
        Stock[gameType] = Stock[gameType] + penaltykickInfo.payScore
    end
    -- 判断是否中奖
    if math.random(10000) <= pro then
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            penaltykickInfo.winScore,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            math.ceil((penaltykickInfo.winScore * mul) * table_201_other[1].extraction / 100),
            {type='normal',isFirst = isFirst,mul = mul,tWinScore = math.floor((penaltykickInfo.winScore * mul) * (1 - table_201_other[1].extraction / 100))},
            {}
        )
        -- 中奖了使用中奖逻辑
        -- if penaltykickInfo.noCommissionWinScore == 0 then
        --     -- 第一次中奖减少库存
        --     Stock[gameType] = Stock[gameType] - penaltykickInfo.noCommissionWinScore
        -- else
        -- end
        if penaltykickInfo.noCommissionWinScore == 0 then
            penaltykickInfo.noCommissionWinScore = penaltykickInfo.winScore * mul
            Stock[gameType] = Stock[gameType] - penaltykickInfo.noCommissionWinScore
        else
            Stock[gameType] = Stock[gameType] - (penaltykickInfo.noCommissionWinScore * mul - penaltykickInfo.noCommissionWinScore)
            penaltykickInfo.noCommissionWinScore = penaltykickInfo.noCommissionWinScore * mul
        end
        penaltykickInfo.winScore = math.floor((penaltykickInfo.winScore * mul) * (1 - table_201_other[1].extraction / 100))
    else
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            penaltykickInfo.winScore,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',isFirst = isFirst,mul = mul,tWinScore = 0 - penaltykickInfo.winScore},
            {}
        )
        cofrinho.AddCofrinho(uid,penaltykickInfo.payScore)
        -- 未中奖判断是否需要增加库存
        Stock[gameType] = Stock[gameType] + penaltykickInfo.noCommissionWinScore
        penaltykickInfo.winScore = 0
        penaltykickInfo.payScore = 0
        penaltykickInfo.noCommissionWinScore = 0
        if AttenuationType == 1 then
            AttenuationStock()
        end
    end
    table.sort(betIndexList)
    penaltykickInfo.betIndexList = betIndexList
    -- 返回数据
    local res = GetResInfo(uid, penaltykickInfo)
    return res
end
-- 取钱逻辑
function GetMoney(penaltykickInfo,uid,betIndexList,peopleType,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- -- 减少库存
    -- Stock[gameType] = Stock[gameType] - penaltykickInfo.noCommissionWinScore
    table.sort(betIndexList)
    penaltykickInfo.betIndexList = betIndexList
    penaltykickInfo.peopleType = peopleType
    -- 增加累计抽水
    Extraction[gameType] = Extraction[gameType] + (penaltykickInfo.noCommissionWinScore - penaltykickInfo.winScore)
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, penaltykickInfo.winScore, Const.GOODS_SOURCE_TYPE.FOOTBALL)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        penaltykickInfo.winScore,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='getMoney'},
        {}
    )
    -- 返回数据
    local res = GetResInfo(uid, penaltykickInfo)
    -- 取完钱重置金额
    penaltykickInfo.winScore = 0
    penaltykickInfo.payScore = 0
    penaltykickInfo.noCommissionWinScore = 0
    if AttenuationType == 1 then
        AttenuationStock()
    end
    return res
end
-- 包装返回信息
function GetResInfo(uid, penaltykickInfo)
    -- 模块信息
    local res = {
        errno = 0,
        -- 下注索引
        betIndexList = penaltykickInfo.betIndexList,
        -- 已赢的钱
        winScore = penaltykickInfo.winScore,
        -- 初始下注的钱(目前用于提现)
        payScore = penaltykickInfo.payScore,
        -- 球员类型
        peopleType = penaltykickInfo.peopleType,
    }
    return res
end
function AttenuationStock()
    -- 如果是按照局数衰减
    if AttenuationType == 1 then
        if GamePlayNumber >= table_201_other[1].attenuationPeriod then
            GamePlayNumber = 0
            for i = 1, #Stock, 1 do
                Attenuation[i] = Attenuation[i] + (Stock[i] - Stock[i] * (1 - (table_201_other[1].attenuationExtraction / 100)))
                Stock[i] = math.floor(Stock[i] * (1 - (table_201_other[1].attenuationExtraction / 100)))
            end
        end
    elseif AttenuationType == 2 then
        for i = 1, #Stock, 1 do
            Attenuation[i] = Attenuation[i] + (Stock[i] - Stock[i] * (1 - (table_201_other[1].attenuationExtraction / 100)))
            Stock[i] = math.floor(Stock[i] * (1 - (table_201_other[1].attenuationExtraction / 100)))
        end
    end
end
-- 初始化库存
function StockInit()
    for i = 1, #table_201_sessions do
        Stock[i] = table_201_sessions[i].initStock
        Extraction[i] = 0
        Attenuation[i] = 0
    end
end
----------------------------------------------------    库存衰减公共调用    --------------------------------------------------
function ChangeAttenuationType(attenuationType)
    if attenuationType ~= nil and (attenuationType == 1 or attenuationType == 2) then
        if AttenuationType == 2 and attenuationType == 1 then
            unilight.stoptimer(PenaltyKick.Timer)
        end
        if AttenuationType == 1 and attenuationType == 2 then
            GamePlayNumber = 0
	        PenaltyKick.Timer = unilight.addtimer("PenaltyKick.AttenuationStock", PenaltyKick.table_201_other[1].attenuationPeriod * 60)
        end
        AttenuationType = attenuationType
    elseif attenuationType == nil and AttenuationType == 2 then
        PenaltyKick.Timer = unilight.addtimer("PenaltyKick.AttenuationStock", PenaltyKick.table_201_other[1].attenuationPeriod * 60)
    end
end