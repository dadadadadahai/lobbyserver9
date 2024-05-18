-- 渔夫游戏模块
module('Fisherman', package.seeall)
-- 渔夫所需数据库表名称
DB_Name = "game126fisherman"
-- 渔夫通用配置
GameId = 126
S = 70
W = 90
B = 6
DataFormat = {3,3,3,3,3}    -- 棋盘规格
Table_Base = import "table/game/126/table_126_hanglie"                        -- 基础行列
MaxNormalIconId = 10
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取渔夫模块数据库信息
    local fishermanInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(fishermanInfo) then
        fishermanInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,fishermanInfo)
    end
    if gameType == nil then
        return fishermanInfo
    end
    -- 没有初始化房间信息
    if table.empty(fishermanInfo.gameRooms[gameType]) then
        fishermanInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            BuyFreeNumS = 0, -- 是否购买免费:购买出来的免费图标个数
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,fishermanInfo)
    end
    return fishermanInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取渔夫模块数据库信息
    local fishermanInfo = unilight.getdata(DB_Name, uid)
    fishermanInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,fishermanInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,fishermanInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    -- B元素内容
    local iconB
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,Fisherman['table_126_freespin_'..gameType])
    else
        -- 普通游戏
        local betInfo = {
            betindex = fishermanInfo.betIndex,
            betchips = fishermanInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        -- 如果购买了免费则必须触发免费
        if fishermanInfo.BuyFreeNumS > 0 then
            -- 如果购买免费则让他不中奖
            local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,2 * #boards[1])
            -- 随机出免费图标插入第几列
            local freeIconLines = chessutil.NotRepeatRandomNumbers(1,#boards,fishermanInfo.BuyFreeNumS)
            -- 棋盘遍历进度
            local changNum = 0
            -- 遍历棋盘
            for colNum = 1, #boards do
                for rowNum = 1, #boards[colNum] do
                    -- 棋盘遍历进度自增长
                    changNum = changNum + 1
                    -- 如果是在前两列图标 保证其不中奖
                    if colNum <= 2 then
                        -- 替换图标
                        boards[colNum][rowNum] = iconIdList[changNum]
                    elseif colNum > 2  then
                        if boards[colNum][rowNum] == W or boards[colNum][rowNum] == S then
                            -- 替换图标
                            boards[colNum][rowNum] = math.random(MaxNormalIconId)
                        end
                    end
                end
            end
            -- 遍历插入S图标位置
            for _, freeIconLine in ipairs(freeIconLines) do
                boards[freeIconLine][math.random(#boards[freeIconLine])] = S
            end

            -- 重置购买免费状态
            fishermanInfo.BuyFreeNumS = 0
        end
    end

    GmProcess(uid, gameId, gameType, boards)
    -- 判断棋盘中是否有Wild元素
    EffectB(fishermanInfo,boards,isFree)

    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_126_payline,table_126_paytable,wilds,nowild)

    -- 判断棋盘B元素内容
    iconB = SetIconB(fishermanInfo,boards,isFree)
    -- 插入棋盘信息
    fishermanInfo.iconsAttachData = iconB
    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * fishermanInfo.betMoney / table_126_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    fishermanInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    -- 计算B图标中将金额
    for _, value in ipairs(iconB) do
        if value.winFlag == true then
            if fishermanInfo.wildNum > 0 then
                res.winScore = res.winScore + fishermanInfo.betMoney * value.mul * value.addMul * fishermanInfo.wildNum
            else
                res.winScore = res.winScore + fishermanInfo.betMoney * value.mul * value.addMul
            end
        end
    end
    res.winScore = math.floor(res.winScore)
    res.tringerPoints.freeTringerPoints = GetFree(fishermanInfo)
    return res
end

-- 判断是否触发免费
function GetFree(fishermanInfo)
    -- 存在S列的个数
    local sNum = 0
    -- 免费游戏次数
    local freeNum = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #fishermanInfo.boards do
        for rowNum = 1, #fishermanInfo.boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if fishermanInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                sNum = sNum + 1
            end
        end
    end
    -- 判断是否触发免费
    for _, v in ipairs(table_126_freenum) do
        if sNum == v.iconNum then
            freeNum = v.freeNum
            break
        end
    end
    if freeNum > 0 then
        -- 触发免费初始化
        fishermanInfo.free.totalTimes = freeNum                                                                                     -- 总次数
        fishermanInfo.free.lackTimes = freeNum                                                                                      -- 剩余游玩次数
        fishermanInfo.free.tWinScore = 0                                                                                            -- 已经赢得的钱
        fishermanInfo.free.endPlayTime = 0                                                                                          -- 已经结束后游玩的局数
        fishermanInfo.free.collect = {totalCollectNum = table_126_collect[#table_126_collect].collectNum,collectNum = 0,mul = 1,collectIndex = 0}    -- 收集进度
        return freeTringerPoints
    end
end

-- 随机B元素内容
function SetIconB(fishermanInfo,boards,isFree)
    local iconB = {}
    -- 遍历棋盘替换B图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            if boards[colNum][rowNum] == B then
                -- 按权重随机图标ID
                local iconId = table_126_bpro[gamecommon.CommRandInt(table_126_bpro, 'pro')].iconId
                -- 替换图标
                boards[colNum][rowNum] = iconId
                -- 添加图标倍数
                local mul = table_126_bmul[gamecommon.CommRandInt(table_126_bmul, 'pro'..iconId)].mul
                -----------------------------  看客户端是否需要winFlag
                if isFree then
                    if fishermanInfo.wildNum > 0 then
                        table.insert(iconB,{line = colNum,row = rowNum,mul = mul,addMul = fishermanInfo.free.collect.mul,winFlag = true})
                    else
                        table.insert(iconB,{line = colNum,row = rowNum,mul = mul,addMul = fishermanInfo.free.collect.mul,winFlag = false})
                    end
                else
                    if fishermanInfo.wildNum > 0 then
                        table.insert(iconB,{line = colNum,row = rowNum,mul = mul,addMul = 1,winFlag = true})
                    else
                        table.insert(iconB,{line = colNum,row = rowNum,mul = mul,addMul = 1,winFlag = false})
                    end
                end
            end
        end
    end
    return iconB
end

-- B元素生效
function EffectB(fishermanInfo,boards,isFree)
    fishermanInfo.wildNum = 0
    -- 对棋盘中W元素个数统计
    for _, colValue in ipairs(boards) do
        for _, iconId in ipairs(colValue) do
            if iconId == W then
                fishermanInfo.wildNum = fishermanInfo.wildNum + 1
                -- 如果是免费还要增加收集次数
                if isFree then
                    FreeCollectW(fishermanInfo)
                end
            end
        end
    end
end

-- 免费中W收集
function FreeCollectW(fishermanInfo)
    -- 如果还未收集满则触发增加收集次数和判断集满次数对比
    if fishermanInfo.free.collect.collectNum < fishermanInfo.free.collect.totalCollectNum then
        fishermanInfo.free.collect.collectNum = fishermanInfo.free.collect.collectNum + 1
        -- -- 判断是否收集满 收集满需要增加免费次数
        -- for _, value in ipairs(table_126_collect) do
        --     -- 如果与配置表次数相同  则增加次数(次数相同代表第一次触发到这个收集进度)
        --     if fishermanInfo.free.collect.collectNum == value.collectNum then
        --         fishermanInfo.free.totalTimes = fishermanInfo.free.totalTimes + value.freeNum
        --         fishermanInfo.free.lackTimes = fishermanInfo.free.lackTimes + value.freeNum
        --     end
        -- end
    end
end

--购买免费
function BuyFree(fishermanInfo,uid,betIndex,gameType)
    if table.empty(fishermanInfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    -- 保存下注档次
    fishermanInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_126_hanglie[1].linenum)
    local betgold = betConfig[fishermanInfo.betIndex]                                                       -- 单注下注金额
    local payScore = betgold * table_126_hanglie[1].linenum                                                 -- 全部下注金额

    -- 随机购买配置表档次
    local buyFreeInfo = table_126_buyfree[gamecommon.CommRandInt(table_126_buyfree, 'pro')]

    -- priceMul = 100,
    --     sNum = 4,

    -- 购买金额为下注金额一百倍
    payScore = payScore * buyFreeInfo.priceMul
    -- 执行扣费
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,payScore ,"渔夫购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    --入库存
    SuserId.uid = uid
    local addscore =  payScore*(10000-gamestock.GetTaxXs(GameId,gameType))/10000
    local userinfo = unilight.getdata('userinfo', uid)
    local  xTax = payScore - addscore
    -- if userinfo.property.totalRechargeChips>0 and userinfo.point.IsNormal==1 then
    --     gamecommon.IncSelfStockNumByType(GameId, gameType, addscore)
    -- end

    -- 设置购买免费的图标个数
    fishermanInfo.BuyFreeNumS = buyFreeInfo.sNum


    -- 保存数据库信息
    SaveGameInfo(uid,gameType,fishermanInfo)
    --记录系统级流水
    gameDetaillog.updateRoomFlow(GameId,gameType,0,1,payScore,0,userinfo)
    WithdrawCash.ResetWithdawTypeState(uid,0)
    return {
        errno = 0,
    }
end

-- 包装返回信息
function GetResInfo(uid, fishermanInfo, gameType, tringerPoints)
    -- 克隆数据表
    fishermanInfo = table.clone(fishermanInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(fishermanInfo.boards) == false then
        boards = {fishermanInfo.boards}
    end
    local free = {}
    if not table.empty(fishermanInfo.free) then
        free = {
            totalTimes = fishermanInfo.free.totalTimes, -- 总次数
            lackTimes = fishermanInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = fishermanInfo.free.tWinScore, -- 总共已经赢得的钱
            collect = fishermanInfo.free.collect, -- 收集进度
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_126_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_126_hanglie[1].linenum),
        -- 下注索引
        betIndex = fishermanInfo.betIndex,
        -- 全部下注金额
        payScore = fishermanInfo.betMoney,
        -- 已赢的钱
        -- winScore = fishermanInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = fishermanInfo.iconsAttachData,
        -- 独立调用定义
        features={free = free},
    }
    return res
end