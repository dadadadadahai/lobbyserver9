-- 阿波罗模块
module('Apollo',package.seeall)
-- 足球所需数据库表名称
DB_Name = "game122apollo"
GameId = 122
Table_Base = import "table/game/122/table_122_hanglie"                        -- 基础行列
LineNum = Table_Base[1].linenum
-- 特殊图标
Jackpot = 100
W = 90
U = 80
S = 70
-- 普通图标
RespinBoards = {1,2,3,4,5,6,7,8,9,10,70,90,100}
-- 最大普通ID
MaxNormalIconId = 10
-- 棋盘规格
DataFormat = {3,3,3,3,3}

-- 构造数据存档
function Get(gameType,uid)
    -- 获取足球模块数据库信息
    local apolloInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(apolloInfo) then
        apolloInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,apolloInfo)
    end
    if gameType == nil then
        return apolloInfo
    end
    -- 没有初始化房间信息
    if table.empty(apolloInfo.gameRooms[gameType]) then
        apolloInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            respin = {}, -- Respin游戏信息
            bres = {}, -- 预结算
            iconsAttachData = {}, -- 附加数据
        }
        unilight.update(DB_Name,uid,apolloInfo)
    end
    return apolloInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取足球模块数据库信息
    local apolloInfo = unilight.getdata(DB_Name, uid)
    apolloInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,apolloInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,apolloInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    nowild[U] = 1
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,Apollo['table_122_freespin_'..gameType])
    else
        -- 普通游戏
        local betInfo = {
            betindex = apolloInfo.betIndex,
            betchips = apolloInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    end
    GmProcess(uid, gameId, gameType, boards)
    -- 判断Jackpot
    local jackpotData = GetJackpot(gameType,apolloInfo,boards)
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_122_payline,table_122_paytable,wilds,nowild)
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * apolloInfo.betMoney / table_122_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    
    -- 填充Jackpot图标
    FillJackPotBoards(jackpotData.bSucess,winlines,boards)

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    apolloInfo.boards = boards

    -- 棋盘数据
    res.boards = boards
    res.jackpotTringerPoints = {jackpotData.jackpotTringerPoints}
    res.jackpotChips = jackpotData.jackpotChips
    res.tringerPoints = {}
    if isFree then
        res.tringerPoints.freeTringerPoints = GetFree(apolloInfo, true)
    else
        res.tringerPoints.freeTringerPoints = GetFree(apolloInfo, false)
    end
    GetRespin(apolloInfo)
    return res
end

-- 判断是否触发免费
function GetFree(apolloInfo, isFree)
    -- 存在S列的个数
    local sNum = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, 5 do
        for rowNum = 1, #apolloInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if apolloInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                sNum = sNum + 1
                -- break
            end
        end
    end
    -- 判断是否触发免费
    if sNum >= table_122_freenum[1].iconNum then
        -- 免费中触发则增加次数
        if isFree then
            apolloInfo.free.totalTimes = apolloInfo.free.totalTimes + table_122_freenum[1].freeNum
            apolloInfo.free.lackTimes = apolloInfo.free.lackTimes + table_122_freenum[1].freeNum
        else
            -- 普通则触发免费初始化
            apolloInfo.free.totalTimes = table_122_freenum[1].freeNum           -- 总次数
            apolloInfo.free.lackTimes = table_122_freenum[1].freeNum            -- 剩余游玩次数
            apolloInfo.free.tWinScore = 0                                               -- 已经赢得的钱
        end
        return freeTringerPoints
    end
end

-- 判断是否触发Respin
function GetRespin(apolloInfo)
    -- 存在S列的个数
    local rNum = 0
    -- 触发Respin位置
    local iconsAttachData = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, 5 do
        local firstFlag = true
        for rowNum = 1, #apolloInfo.boards[colNum], 1 do
            -- 如果这个位置存在B图标 则B列的次数+1 直接跳转下一列
            if apolloInfo.boards[colNum][rowNum] == U then
                -- 随机Respin倍数
                local mul = table_122_umul[gamecommon.CommRandInt(table_122_umul, 'pro')].mul
                -- 保存数据
                table.insert(iconsAttachData,{line = colNum, row = rowNum,score = mul * apolloInfo.betMoney})
                rNum = rNum + 1
                -- break
            end
        end
    end
    -- 判断是否触发Respin   触发需要初始化
    if rNum >= 6 then
        apolloInfo.respin.totalTimes = 3                                            -- 总次数
        apolloInfo.respin.lackTimes = 3                                             -- 剩余游玩次数
        -- apolloInfo.respin.totalTimes = Apollo['table_122_other'][1].respinNum       -- 总次数
        -- apolloInfo.respin.lackTimes = Apollo['table_122_other'][1].respinNum        -- 剩余游玩次数
        apolloInfo.respin.tWinScore = 0                                             -- 已经赢得的钱
        apolloInfo.respin.iconsAttachData = table.clone(iconsAttachData)            -- 结算时面板图标上的附加显示数据
        apolloInfo.respin.finallyNum = table_122_respin[gamecommon.CommRandInt(table_122_respin, 'j' .. rNum)].num  -- 最终U图标数量
        apolloInfo.respin.boards = table.clone(apolloInfo.boards)                   -- 保存本轮棋盘数据
        -- return iconsAttachData
    end
    -- 保存附加数据
    apolloInfo.iconsAttachData = table.clone(iconsAttachData)
end

function GetJackpot(gameType,apolloInfo,boards)
    local res = {}
    res.jackpotTringerPoints = {}
    -- 可插入列表
    local insertList = {}
    -- local inserCol = {}
    -- local maxInserCol = {}
    -- 寻找棋盘中的可替换图标
    local breakFlag = false
    for colIndex, colValue in ipairs(boards) do
        for rowIndex, rowValue in ipairs(colValue) do
            -- 只能替换普通图标
            if rowValue ~= W and rowValue ~= S and rowValue ~= U then
                -- 如果他的前一列没有可替换图标则重置累计连续列数
                if colIndex > 1 and insertList[colIndex - 1] == nil then
                    breakFlag = true
                    break
                end
                if insertList[colIndex] == nil then
                    insertList[colIndex] = {}
                end
                table.insert(insertList[colIndex],rowIndex)
            end
        end
        if breakFlag then
            break
        end
    end
    -- if #maxInserCol < #inserCol then
    --     maxInserCol = inserCol
    -- end

    -- 奖池初始化数值
    local jackpotChips = 0
    res.bSucess = false
    local iconNum = gamecommon.GetJackpotIconNum(GameId,gameType)
    res.jackpotChips = jackpotChips
    -- 判断是否有资格中Jackpot
    if iconNum > 0 and #insertList >= iconNum then
        -- 获得奖池奖励
        res.bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, apolloInfo.betIndex)
        -- 添加奖池图标
        if res.bSucess then
            -- 如果中Jackpot则让他不中奖
            local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,2 * #boards[1])
            local changNum = 0
            -- 遍历修改棋盘前两列图标 保证其不中奖
            for colNum = 1, 2 do
                for rowNum = 1, #boards[colNum] do
                    changNum = changNum + 1
                    -- 替换图标
                    boards[colNum][rowNum] = iconIdList[changNum]
                end
            end
            res.jackpotChips = jackpotChips
            -- local firstIndex = math.random(#DataFormat - iconNum + 1)
            -- 中奖 则替换图标
            for index = 1, iconNum do
                -- 随机行数
                local rowRandomIndex = 1
                print(table2json(insertList))
                if #insertList[index] > 1 then
                    rowRandomIndex = math.random(#insertList[index])
                end
                -- 替换图标
                boards[index][insertList[index][rowRandomIndex]] = Jackpot
                table.insert(res.jackpotTringerPoints,{line = index, row = insertList[rowRandomIndex]})
            end
        end
    end
    return res
end

-- 填充Jackpot图标
function FillJackPotBoards(bSucess,winlines,boards)
    -- 填充Jackpot图标
    local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],bSucess,GameId)
    for _, v in ipairs(winlines) do
        jackFill:PreWinData(v.winicon)
    end
    -- 遍历棋盘排除替换S图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if boards[colNum][rowNum] == S or boards[colNum][rowNum] == U then
                jackFill:FillExtraIcon(colNum,rowNum)
            end
        end
    end
    jackFill:CreateFinalChessData(boards,Jackpot)
end


-- 包装返回信息
function GetResInfo(uid, apolloInfo, gameType, tringerPoints, jackpot)
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    apolloInfo = table.clone(apolloInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(apolloInfo.boards) == false then
        boards = {apolloInfo.boards}
    end
    local free = {}
    if not table.empty(apolloInfo.free) then
        free = {
            totalTimes = apolloInfo.free.totalTimes, -- 总次数
            lackTimes = apolloInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = apolloInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local respin = {}
    if not table.empty(apolloInfo.respin) then
        respin = {
            totalTimes = apolloInfo.respin.totalTimes, -- 总次数
            lackTimes = apolloInfo.respin.lackTimes, -- 剩余游玩次数
            tWinScore = apolloInfo.respin.tWinScore, -- 总共已经赢得的钱
            -- tringerPoints = {tringerPoints.respinTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_122_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_122_hanglie[1].linenum),
        -- 下注索引
        betIndex = apolloInfo.betIndex,
        -- 全部下注金额
        payScore = apolloInfo.betMoney,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = apolloInfo.iconsAttachData,
        -- 独立调用定义
        features={free = free,respin = respin,jackpot = jackpot},
    }
    return res
end
