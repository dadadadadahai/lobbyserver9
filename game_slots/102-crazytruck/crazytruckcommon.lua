-- 卡车游戏模块
module('CrazyTruck', package.seeall)
-- 卡车所需数据库表名称
DB_Name = "game102truck"
-- 卡车所需配置表信息
Table_Base = import "table/game/102/table_truck_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/102/table_truck_winline"                       -- 普通中奖线/respin中奖线共用
-- Table_NormalSpin = import "table/game/102/table_truck_normalspin"               -- 普通棋盘
-- Table_FreeSpin = import "table/game/102/table_truck_freespin"                   -- 免费棋盘
Table_PayTable = import "table/game/102/table_truck_paytable"                   -- 中奖倍率
Table_Collect = import "table/game/102/table_truck_collect"                     -- 收集触发W
Table_Free = import "table/game/102/table_truck_free"                           -- 免费触发
-- JACKPOT所需数据配置表
table_102_jackpot_chips   = import 'table/game/102/table_102_jackpot_chips'
table_102_jackpot_add_per = import 'table/game/102/table_102_jackpot_add_per'
table_102_jackpot_bomb    = import 'table/game/102/table_102_jackpot_bomb'
-- table_102_jackpot_scale   = import 'table/game/102/table_102_jackpot_scale'
table_102_jackpot_bet     = import 'table/game/102/table_102_jackpot_bet'
-- 卡车特殊元素ID
W = 90
Jackpot = 100
-- 卡车通用配置
ColFree = {1,3,5}                                                                          -- 触发免费游戏的列
ChangeIcons = {11,10,9,8,7}                                                                -- 免费游戏中可以替换成连续的图标列表 同时也是每一列对应的收集图标
DataFormat = {3   ,3,3,3,3}                                                                   -- 棋盘规格
GameId = 102
-- 构造数据存档
function Get(gameType,uid)
    -- 获取卡车模块数据库信息
    local crazytruckInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(crazytruckInfo) then
        crazytruckInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,crazytruckInfo)
    end
    if gameType == nil then
        return crazytruckInfo
    end
    -- 没有初始化房间信息
    if table.empty(crazytruckInfo.gameRooms[gameType]) then
        crazytruckInfo.gameRooms[gameType] = {
            -- _id = uid, -- 玩家ID
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            -- iconsAttachData = {}, -- 结算时面板图标上的附加显示数据
            collect = {}, 
            free = { -- 免费游戏
                totalTimes = -1, -- 总次数
                times = 0, -- 游玩次数
                tWinScore = 0, -- 本轮已经赢得的钱
                -- extraData = {},
            },
        }
        -- 初始化收集
        for betIndex = 1, #gamecommon.GetBetConfig(gameType,Table_Base[1].linenum) do
            crazytruckInfo.gameRooms[gameType].collect[betIndex] = {
                curPro = {0,0,0,0,0}, -- 当前收集量
                talPro = {}, -- 总共需要收集的量
                -- points = {}, -- 本次收集到的点
            }
            -- 循环添加需要收集的量
            for i, v in ipairs(Table_Collect) do
                crazytruckInfo.gameRooms[gameType].collect[betIndex].talPro[i] = v.collectNum
            end
        end
        unilight.update(DB_Name,uid,crazytruckInfo)
    end
    return crazytruckInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 构造数据存档
    -- Get(gameType,uid)
    -- 获取卡车模块数据库信息
    local crazytruckInfo = unilight.getdata(DB_Name, uid)
    crazytruckInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,crazytruckInfo)
end
-- 判断是否触发免费
function GetFree(crazytruckInfo)
    local sNum = 0
    local tringerPoints = {}
    local freePoints = {}
    local freeFlag = false
    local freeNum = 0
    for i, v in ipairs(Table_Free) do
        freeFlag,freePoints = GetFreeIcon(crazytruckInfo.boards, v.iconId)
        -- 如果中奖次数相加
        if freeFlag == true then
            freeNum = freeNum + v.freeNum
            table.insert(tringerPoints,freePoints)
            freeFlag = false
        end
    end
    -- 判断是否触发免费
    if freeNum > 0 then
        -- 普通模式触发变更为免费模式
        crazytruckInfo.free.totalTimes = freeNum
    end
    return tringerPoints
end

-- 判断棋盘对应列中中是否有当前图标
function GetFreeIcon(boards, iconId)
    -- 触发免费的对应图标个数
    local freeIconNum = 0
    local tringerPoints = {}
    -- 循环列数
    for id, colId in ipairs(ColFree) do
        -- 循环行数
        for rowIndex, rowValue in ipairs(boards[colId]) do
            if rowValue == iconId then
                freeIconNum = freeIconNum + 1
                table.insert(tringerPoints,{line=colId,row=rowIndex})
                break
            end
        end
    end
    -- 判断是否满足免费
    if freeIconNum == #ColFree then
        return true,tringerPoints
    end
    return false,{}
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,crazytruckInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- nowild[S] = 1
    -- 初始棋盘
    local boards = {}
    local changeIconPoints = {}
    local jackpotTringerPoints = {}
    local jackpotChips = 0
    local res = {}
    local points
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,CrazyTruck['table_truck_freespin_'..gameType])
        boards,points = AddCollect(boards,crazytruckInfo,isFree,uid,gameType)
        changeIconPoints = ChangeIcon(boards)
        -- 棋盘数据
        res.boards = table.clone(boards)
        for _, v in ipairs(changeIconPoints) do
            res.boards[v.colNum][v.rowNum] = v.iconId
        end
        GetWildIcon(boards,crazytruckInfo)
    else
        -- 普通游戏
        local betInfo = {
            betindex = crazytruckInfo.betIndex,
            betchips = crazytruckInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        boards,points = AddCollect(boards,crazytruckInfo,isFree,uid,gameType)
        GmProcess(uid, gameId, gameType, boards,crazytruckInfo)
        jackpotTringerPoints,jackpotChips = GetJackpot(boards,gameType,crazytruckInfo)
        -- 棋盘数据
        res.boards = table.clone(boards)
        -- 棋盘数据未添加W元素的棋盘临时缓存在对象中 用于免费判断 后覆盖
        crazytruckInfo.boards = res.boards
        GetWildIcon(boards,crazytruckInfo)
    end
    
    if not isFree then
        -- 获取判断是否中免费
        res.tringerPoints = {}
        res.tringerPoints.freeTringerPoints = GetFree(crazytruckInfo)
    end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalcNoOne(boards,Table_WinLines,Table_PayTable,wilds,nowild)

    if not isFree then
        -- 普通游戏下随机填充Jackpot图标
        local jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],not table.empty(jackpotTringerPoints),GameId)
        -- 判断触发免费并且抛出触发免费的S图标被Jackpot图标替换
        for _, freePoints in ipairs(res.tringerPoints.freeTringerPoints) do
            for _, v in ipairs(freePoints) do
                jackFill:FillExtraIcon(v.line,v.row)
            end
        end
        -- 抛出中奖图标
        for _, v in ipairs(winlines) do
            for _, winpot in ipairs(v.winpos) do
                jackFill:FillExtraIcon(winpot[1],winpot[2])
            end
            -- jackFill:PreWinData(v.winpos)
        end
        for _, v in ipairs(points) do
            jackFill:FillExtraIcon(v.colNum,v.rowNum)
        end
        jackFill:CreateFinalChessData(res.boards,Jackpot)
    end


    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        res.winScore = res.winScore + v.mul * crazytruckInfo.betMoney / Table_Base[1].linenum
        table.insert(res.winlines[1], {v.line, v.num, v.mul * crazytruckInfo.betMoney / Table_Base[1].linenum,v.firstindex,v.ele})
    end

    -- 生成返回数据
    res.changeIconPoints = changeIconPoints                             -- 免费替换图标
    res.jackpotTringerPoints = {jackpotTringerPoints}                   -- 触发jackpot的图标位置
    res.jackpotChips = jackpotChips                                     -- 触发jackpot的图标获取的金钱
    res.points = points                                                 -- 本次收集的有效图标
    -- 判断是否触发免费
    res.tringerPoints = {}
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    crazytruckInfo.boards = boards
    return res
end

function GetJackpot(boards,gameType,crazytruckInfo)
    -- 可插入列表
    local insertList = {}
    local inserCol = {}
    local maxInserCol = {}
    local jackpotTringerPoints = {}
    -- 寻找棋盘中的可替换图标
    for colIndex, colValue in ipairs(boards) do
        for rowIndex, rowValue in ipairs(colValue) do
            -- 只能替换普通图标
            if rowValue ~= W and rowValue ~= S then
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
    -- 判断是否有资格中Jackpot
    if iconNum > 0 and #maxInserCol >= iconNum then
        -- 获得奖励
        bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, crazytruckInfo.betIndex)
        -- 获得奖池奖励
        if bSucess and #maxInserCol >= iconNum then
            local firstIndex = math.random(#DataFormat - iconNum + 1)
            -- 中奖 则替换图标
            for index = firstIndex, (firstIndex + iconNum - 1) do
                -- 随机行数
                local rowRandomIndex = math.random(1,#insertList[maxInserCol[index]])
                -- 循环替换每一列其中的图标
                -- for _, rowIndex in ipairs(rowRandomIndex) do
                    boards[maxInserCol[index]][insertList[maxInserCol[index]][rowRandomIndex]] = Jackpot
                    table.insert(jackpotTringerPoints,{line = maxInserCol[index], row = insertList[maxInserCol[index]][rowRandomIndex]})
                -- end
            end
        end
    end
    return jackpotTringerPoints,jackpotChips
end
-- 变更W信息
function GetWildIcon(boards, crazytruckInfo)
    for colIndex = 1, #crazytruckInfo.collect[crazytruckInfo.betIndex].curPro do
        if crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[colIndex] >= crazytruckInfo.collect[crazytruckInfo.betIndex].talPro[colIndex] then
            -- 循环对应列数
            for rowIndex = 1, #boards[colIndex] do
                -- 替换其中的下标为W图标
                boards[colIndex][rowIndex] = W
            end
            -- 减少收集次数
            crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[colIndex] = crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[colIndex] - crazytruckInfo.collect[crazytruckInfo.betIndex].talPro[colIndex]
        end
    end
end
-- 判断是否增加收集信息
function AddCollect(boards,crazytruckInfo,isFree,uid,gameType)
    local curPro = table.clone(crazytruckInfo.collect[crazytruckInfo.betIndex].curPro)
    local points = {}
    local flag = true
    -- 遍历棋盘
    for i, v in ipairs(Table_Collect) do
        for rowIndex = 1, #boards[v.colNum] do
            -- 如果是有效收集图标
            if boards[v.colNum][rowIndex] == v.iconId then
                -- 增加收集次数
                curPro[v.colNum] = curPro[v.colNum] + 1
                table.insert(points,{colNum = v.colNum, rowNum = rowIndex})
            end
        end
        -- 判断是否需要重新随机
        if curPro[v.colNum] < v.collectNum then
            flag = false
        end
    end
    if flag then
        if isFree then
            boards = gamecommon.CreateSpecialChessData(DataFormat,Table_FreeSpin)
        else
            local betInfo = {
                betindex = crazytruckInfo.betIndex,
                betchips = crazytruckInfo.betMoney,
                gameId = GameId,
                gameType = gameType,
            }
            boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,GameId,gameType,betInfo))
        end
        return AddCollect(boards,crazytruckInfo,isFree,uid,gameType)
    end
    crazytruckInfo.collect[crazytruckInfo.betIndex].curPro = curPro
    return boards,points
end
-- 包装返回信息
function GetResInfo(uid, crazytruckInfo, gameType, tringerPoints, jackpot, points)
    points = points or {}
    -- 触发特殊游戏的图标位置
    tringerPoints = tringerPoints or {}
    -- 奖池
    jackpot = jackpot or {}
    -- 克隆数据表
    crazytruckInfo = table.clone(crazytruckInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local free = {}
    if crazytruckInfo.free.totalTimes ~= -1 then
        free = {
            totalTimes = crazytruckInfo.free.totalTimes, -- 总次数
            lackTimes = crazytruckInfo.free.totalTimes - crazytruckInfo.free.times, -- 剩余游玩次数
            tWinScore = crazytruckInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = tringerPoints.freeTringerPoints or {},
        }
    end
    local boards = {}
    if table.empty(crazytruckInfo.boards) == false then
        boards = {crazytruckInfo.boards}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = crazytruckInfo.betIndex,
        payScore = crazytruckInfo.betMoney,                                           -- 全部下注金额
        -- 已赢的钱
        -- winScore = crazytruckInfo.winScore,
        -- 收集
        collect = crazytruckInfo.collect[crazytruckInfo.betIndex],
        -- 附加面板数据
        -- iconsAttachData = crazytruckInfo.iconsAttachData,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free, jackpot = jackpot},
    }
    res.collect.points = points

    return res
end
-- 免费游戏变更棋盘
function ChangeIcon(boards)
    -- 需要修改的图标位置
    local changeIconPoints = {}
    -- 循环棋盘中的每一行数据
    for rowNum = 1, 3, 1 do
        -- 列数只到第三列 因为四列五列出的首个可改变图标无用
        for colNum = 1, 3, 1 do
            local breakFlag = false
            for _, changeIconId in ipairs(ChangeIcons) do
                if boards[colNum][rowNum] == changeIconId then
                    -- 找到对应图标 然后从后往前判断是否还有非相邻图标
                    for col = 5, colNum + 2, -1 do
                        -- 如果是有效图标
                        if boards[col][rowNum] == changeIconId then
                            for changColNum = col - 1, colNum + 1, -1 do
                                table.insert(changeIconPoints,{colNum = changColNum, rowNum = rowNum, iconId = boards[changColNum][rowNum]})
                                -- 改变中间棋盘图标ID
                                boards[changColNum][rowNum] = changeIconId
                            end
                            breakFlag = true
                            break
                        end
                    end
                end
                if breakFlag then
                    break
                end
            end
            if breakFlag then
                break
            end
        end
    end
    return changeIconPoints
end
