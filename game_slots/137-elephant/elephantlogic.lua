module('Elephant', package.seeall)
local iconRealId = 1
local freeNum = 0
--执行大象图库
function StartToImagePool(imageType)
    if imageType == 1 then
        return Normal()
    else
        --跑免费图库
        return Free()
    end
end

function Free()
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}

    local elephantInfo = {
        betMoney = 1,
        free = {
            totalTimes = freeNum,
            lackTimes = freeNum,
            tWinScore = 0,
            wildNum = 0,
        }
    }
    while true do
        if elephantInfo.free.lackTimes <= 0 then
            break
        end
        elephantInfo.free.lackTimes = elephantInfo.free.lackTimes - 1
        -- 生成异形棋盘
        boards = gamecommon.CreateSpecialChessData(DataFormat,Elephant['table_137_free'])
    
        -- 计算中奖倍数
        local winPoints,winMuls  = gamecommon.SpecialAllLineFinal(boards,wilds,nowild,table_137_paytable)
        -- 中奖金额
        res.winScore = 0
        -- 获取中奖线
        res.winPoints = {}
        res.winPoints[1] = winPoints
        local wMul = 1
        res.tringerPoints.wildPoints = {}
        local wNum = 0
        -- 统计W个数
        for col = 1, #boards do
            for row = 1, #boards[col] do
                if boards[col][row] == W then
                    table.insert(res.tringerPoints.wildPoints,{line = col, row = row})
                    wNum = wNum + 1
                end
            end
        end
        elephantInfo.free.wildNum = elephantInfo.free.wildNum + wNum
        -- 根据W个数匹配倍数
        wMul = math.floor(elephantInfo.free.wildNum / NeedAddWildNum) * OneAddWildMul
        -- 保底1倍
        if wMul == 0 then
            wMul = 1
        end
        if wMul > MaxWildMul then
            wMul = MaxWildMul
        end
        -- 中奖金额
        local winScore = 0
        -- 触发位置
        res.tringerPoints = {}
        -- 计算中奖线金额
        for i, v in ipairs(winMuls) do
            if v.ele ~= S then
                res.winScore = res.winScore + v.mul * elephantInfo.betMoney / Table_Base[1].linenum
            else
                res.winScore = res.winScore + v.mul * elephantInfo.betMoney
            end
        end
        res.winScore = res.winScore * wMul
        elephantInfo.free.tWinScore = elephantInfo.free.tWinScore + res.winScore
    end
    res.elephantInfo = elephantInfo
    return res,elephantInfo.free.tWinScore / elephantInfo.betMoney,2
end

function Normal()
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    -- 生成异形棋盘
    boards = gamecommon.CreateSpecialChessData(DataFormat,table_137_free)
    local elephantInfo = {
        betMoney = 1,
        free = {},
    }
    -- 计算中奖倍数
    local winPoints,winMuls  = gamecommon.SpecialAllLineFinal(boards,wilds,nowild,table_137_paytable)
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winPoints = {}
    res.winPoints[1] = winPoints

    local wMul = 1
    
    -- 触发位置
    res.tringerPoints = {}
    -- res.tringerPoints.wildPoints = {}
    for i, v in ipairs(winMuls) do
        if v.ele ~= S then
            res.winScore = res.winScore + v.mul * elephantInfo.betMoney / Table_Base[1].linenum
        else
            res.winScore = res.winScore + v.mul * elephantInfo.betMoney
        end
    end
    res.winScore = res.winScore * wMul
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    elephantInfo.boards = boards
    -- 判断是否中Free
    res.tringerPoints.freeTringerPoints = GetFree(elephantInfo)
    -- 棋盘数据
    res.boards = boards
    res.freeNum = elephantInfo.free.totalTimes or 0
    freeNum = res.freeNum
    local imageType = 1
    if res.freeNum > 0 then
        imageType = 2
    end
    res.elephantInfo = elephantInfo
    return res, res.winScore / elephantInfo.betMoney, imageType
end