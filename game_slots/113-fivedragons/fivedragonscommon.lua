-- 五龙争霸游戏模块
module('FiveDragons', package.seeall)
-- 五龙争霸所需数据库表名称
DB_Name = "game113fivedragons"
-- 五龙争霸所需配置表信息
Table_Base = import "table/game/113/table_113_hanglie"                         -- 基础行列
Table_NormalSpin = import "table/game/113/table_113_normalspin"                -- 普通棋盘
Table_FreeSpin = import "table/game/113/table_113_freespin"                    -- 免费棋盘
Table_PayTable = import "table/game/113/table_113_paytable"                    -- 中奖倍率
Table_EFree = import "table/game/113/table_113_efree"                          -- 免费出E倍数
Table_FreeChoose = import "table/game/113/table_113_freechoose"                -- 免费选择
LineNum = Table_Base[1].linenum
Table_FreeW = {}                                                                -- 免费出W
Table_FreeW[1] = import "table/game/113/table_113_freew1"                      -- 免费W1
Table_FreeW[2] = import "table/game/113/table_113_freew2"                      -- 免费W2
Table_FreeW[3] = import "table/game/113/table_113_freew3"                      -- 免费W3
Table_FreeW[4] = import "table/game/113/table_113_freew4"                      -- 免费W4
Table_FreeW[5] = import "table/game/113/table_113_freew5"                      -- 免费W5

-- JACKPOT所需数据配置表
table_113_jackpot_chips   = import 'table/game/113/table_113_jackpot_chips'
table_113_jackpot_add_per = import 'table/game/113/table_113_jackpot_add_per'
table_113_jackpot_bomb    = import 'table/game/113/table_113_jackpot_bomb'
-- table_113_jackpot_scale   = import 'table/game/113/table_113_jackpot_scale'
table_113_jackpot_bet     = import 'table/game/113/table_113_jackpot_bet'

ColE = {1,5}                                                                    -- E在免费需要满足的列数

-- 五龙争霸特殊元素ID
Jackpot = 100
W = 90
B = 80
S = 70
E = 7

-- 五龙争霸通用配置
GameId = 113
MaxNormalIconId = 11
DataFormat = {3,3,3,3,3}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取五龙争霸模块数据库信息
    local fivedragonsInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(fivedragonsInfo) then
        fivedragonsInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,fivedragonsInfo)
    end
    if gameType == nil then
        return fivedragonsInfo
    end
    -- 没有初始化房间信息
    if table.empty(fivedragonsInfo.gameRooms[gameType]) then
        fivedragonsInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            -- 免费游戏信息
            free = {
                totalTimes = -1,                                    -- 总次数
                times = 0,                                          -- 游玩次数
                tWinScore = 0,                                      -- 已经赢得的钱
                mul = 0,                                            -- 倍数
                choose = 0,                                         -- 选择的结果
            },
        }
        unilight.update(DB_Name,uid,fivedragonsInfo)
    end
    return fivedragonsInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取五龙争霸模块数据库信息
    local fivedragonsInfo = unilight.getdata(DB_Name, uid)
    fivedragonsInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,fivedragonsInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,fivedragonsInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    nowild[S] = 1
    -- 初始棋盘
    local boards = {}
    local bonus = {}
    local jackpotTringerPoints = {}
    local jackpotFlag = false
    -- 生成返回数据
    local res = {}
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,FiveDragons['table_113_freespin_'..gameType])
        GmProcess(uid, gameId, gameType, boards)
        bonus = GetFreeE(boards,fivedragonsInfo.betMoney)
    else
        -- 普通游戏
        local betInfo = {
            betindex = fivedragonsInfo.betIndex,
            betchips = fivedragonsInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        -- 可插入列表
        local insertList = {}
        local inserCol = {}
        local maxInserCol = {}
        -- 寻找棋盘中的可替换图标
        for colIndex, colValue in ipairs(boards) do
            for rowIndex, rowValue in ipairs(colValue) do
                -- 只能替换普通图标
                if rowValue ~= W and rowValue ~= S and rowValue ~= B then
                    if insertList[colIndex] == nil then
                        insertList[colIndex] = {}
                        -- 如果他的前一列没有可替换图标则重置累计连续列数
                        if colIndex > 1 and insertList[colIndex - 1] == nil then
                            if #maxInserCol < #inserCol then
                                maxInserCol = inserCol
                            end
                            inserCol = {}
                        end
                        table.insert(inserCol,colIndex)
                    end
                    table.insert(insertList[colIndex],rowIndex)
                end
            end
        end
        if #maxInserCol < #inserCol then
            maxInserCol = inserCol
        end
        -- 奖池初始化数值
        local jackpotChips = 0
        local bSucess = false
        local iconNum = gamecommon.GetJackpotIconNum(GameId,gameType)
        res.jackpotChips = jackpotChips
        -- 判断是否有资格中Jackpot
        if iconNum > 0 and #maxInserCol >= iconNum then
            -- 获得奖励
            bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, fivedragonsInfo.betIndex)
            -- 获得奖池奖励
            if bSucess and #maxInserCol >= iconNum then
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
                jackpotFlag = true
                res.jackpotChips = jackpotChips
                local firstIndex = math.random(#DataFormat - iconNum + 1)
                -- 中奖 则替换图标
                for index = firstIndex, (firstIndex + iconNum - 1) do
                    -- 随机行数
                    local rowRandomIndex = math.random(#insertList[maxInserCol[index]])
                    -- 替换图标
                    boards[maxInserCol[index]][insertList[maxInserCol[index]][rowRandomIndex]] = Jackpot
                    table.insert(jackpotTringerPoints,{line = maxInserCol[index], row = insertList[maxInserCol[index]][rowRandomIndex]})
                end 
            end
        end
        GmProcess(uid, gameId, gameType, boards)
    end

    -- 计算中奖倍数
    local winPoints,winMuls  = gamecommon.SpecialAllLineFinal(boards,wilds,nowild,table_137_paytable)
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winPoints = {}
    res.winPoints[1] = winPoints
    -- 计算中奖线金额
    local mul = 1
    local randomFlag = true
    for i, v in ipairs(winMuls) do
        if v.ele ~= S then
            res.winScore = res.winScore + v.mul * fivedragonsInfo.betMoney / Table_Base[1].linenum
        else
            res.winScore = res.winScore + v.mul * fivedragonsInfo.betMoney
        end
    end

    if isFree then
        -- 根据W元素改变中奖金额
        local probability = {}
        local allResult = {}
        for i, v in ipairs(Table_FreeW[fivedragonsInfo.free.choose]) do
            if v.pro > 0 then
                table.insert(probability, v.pro)
                table.insert(allResult, {v.pro, v.mul})
            end
        end
        -- 获取本列随即后的W个数
        local mul = math.random(probability, allResult)[2]
        fivedragonsInfo.free.mul = mul
        res.winScore = res.winScore * mul
    end

    local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],jackpotFlag,GameId)
    for i, v in ipairs(winPoints) do
        jackFill:FillExtraIcon(v[1],v[2])
    end
    -- 遍历棋盘排除替换S图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if boards[colNum][rowNum] == S or boards[colNum][rowNum] == B or boards[colNum][rowNum] == E then
                jackFill:FillExtraIcon(colNum,rowNum)
            end
        end
    end
    jackFill:CreateFinalChessData(boards,Jackpot)
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    fivedragonsInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.winMuls = winMuls
    res.bonus = bonus
    -- 缓存winScore加入bonus的金币
    if table.empty(bonus) == false and bonus.tWinScore > 0 then
        res.winScore = res.winScore + bonus.tWinScore
    end
    res.jackpotTringerPoints = {jackpotTringerPoints}
    res.tringerPoints = {}
    if isFree then
        res.tringerPoints.freeTringerPoints = GetFree(fivedragonsInfo, true)
    else
        res.tringerPoints.freeTringerPoints = GetFree(fivedragonsInfo)
    end
    return res
end
-- 判断是否触发免费
function GetFree(fivedragonsInfo, isFree)
    -- 存在S列的个数
    local ColS = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #fivedragonsInfo.boards do
        local sFlag = false
        for rowNum = 1, #fivedragonsInfo.boards[colNum], 1 do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if fivedragonsInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                ColS = ColS + 1
                sFlag = true
                break
            end
        end
        -- 如果这一列没有出现S则统计最多连续列数
        if sFlag == false then
            break
        end
    end
    -- 判断是否触发免费
    if ColS >= 3 then
        if isFree then
            for _, v in ipairs(Table_FreeChoose) do
                if v.FreeCode == "W"..fivedragonsInfo.free.choose then
                    fivedragonsInfo.free.totalTimes = fivedragonsInfo.free.totalTimes + v.FreeNum
                    break
                end
            end
        else
            -- 触发免费选择界面
            fivedragonsInfo.free.totalTimes = 0
            return freeTringerPoints
        end
    end
end
-- 判断免费棋盘是否中E图标
function GetFreeE(boards,betMoney)
    -- 判断E的列数
    local ColENum = 0
    local bonus = {}
    -- 触发免费位置
    local bonusTringerPoints = {}
    -- 遍历棋盘
    for _, colNum in ipairs(ColE) do
        for rowNum, v in ipairs(boards[colNum]) do
            if v == E then
                ColENum = ColENum + 1
                table.insert(bonusTringerPoints,{line = colNum, row = rowNum})
                break
            end
        end
    end
    -- 如果触发红包
    if ColENum >= #ColE then
        -- 根据W元素改变中奖金额
        local probability = {}
        local allResult = {}
        for i, v in ipairs(Table_EFree) do
            if v.pro > 0 then
                table.insert(probability, v.pro)
                table.insert(allResult, {v.pro, v.mul})
            end
        end
        -- 获取本列随即后的W个数
        local mul = math.random(probability, allResult)[2]
        bonus.totalTimes = 1
        bonus.lackTimes = 0
        bonus.tWinScore = betMoney * mul
        bonus.mul = mul
        bonus.tringerPoints = bonusTringerPoints
        return bonus
    end
    bonus = {}
end
-- 包装返回信息
function GetResInfo(uid, fivedragonsInfo, gameType, tringerPoints, jackpot)
    jackpot = jackpot or {}
    tringerPoints = tringerPoints or {}
    -- 克隆数据表
    fivedragonsInfo = table.clone(fivedragonsInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(fivedragonsInfo.boards) == false then
        boards = {fivedragonsInfo.boards}
    end
    local free = {}
    if fivedragonsInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = fivedragonsInfo.free.totalTimes, -- 总次数
            lackTimes = fivedragonsInfo.free.totalTimes - fivedragonsInfo.free.times, -- 剩余游玩次数
            tWinScore = fivedragonsInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = tringerPoints.freeTringerPoints or {},
            extraData = {
                mul = fivedragonsInfo.free.mul,
                choose = fivedragonsInfo.free.choose,
            }
        }
    end
    -- local bonus = {}
    -- if fivedragonsInfo.bonus.totalTimes ~= -1 then
    --     bonus = {
    --         totalTimes = fivedragonsInfo.bonus.totalTimes, -- 总次数
    --         lackTimes = fivedragonsInfo.bonus.totalTimes - fivedragonsInfo.bonus.times, -- 剩余游玩次数
    --         tWinScore = fivedragonsInfo.bonus.tWinScore, -- 总共已经赢得的钱
    --         tringerPoints = {tringerPoints.bonusTringerPoints} or {},
    --     }
    -- end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = fivedragonsInfo.betIndex,
        -- 全部下注金额
        payScore = fivedragonsInfo.betMoney,
        -- 已赢的钱
        -- winScore = fivedragonsInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free,jackpot = jackpot},
    }
    return res
end