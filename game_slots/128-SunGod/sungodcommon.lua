-- 太阳神游戏模块
module('SunGod', package.seeall)
-- 太阳神所需数据库表名称
DB_Name = "game128sungod"
-- 太阳神通用配置
GameId = 128
S = 70
W = 90
DataFormat = {6,6,6,6,6,6}    -- 棋盘规格
Table_Base = import "table/game/128/table_128_hanglie"                        -- 基础行列
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取太阳神模块数据库信息
    local sungodInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(sungodInfo) then
        sungodInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,sungodInfo)
    end
    if gameType == nil then
        return sungodInfo
    end
    -- 没有初始化房间信息
    if table.empty(sungodInfo.gameRooms[gameType]) then
        sungodInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘




        }
        unilight.update(DB_Name,uid,sungodInfo)
    end
    return sungodInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取太阳神模块数据库信息
    local sungodInfo = unilight.getdata(DB_Name, uid)
    sungodInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,sungodInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,sungodInfo)

    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}

    -- 普通游戏
    local betInfo = {
        betindex = sungodInfo.betIndex,
        betchips = sungodInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    res.respinFlag = false
    
    GmProcess(uid, gameId, gameType, boards)
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_128_payline,table_128_paytable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * sungodInfo.betMoney / table_128_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    sungodInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.winScore = math.floor(res.winScore)
    return res
end



-- 生成整个棋盘数据
function GetBoardsSpinList(uid,gameId,gameType,isFree,sungodInfo)
    -- 普通游戏
    local betInfo = {
        betindex = sungodInfo.betIndex,
        betchips = sungodInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }

    -- 棋盘随机配置文件
    local spinConfig = gamecommon.GetSpin(uid,gameId,gameType,betInfo)
    if isFree then
        spinConfig = SunGod['table_128_freespin_'..gameType]
    end

    local boards,lastColRow = gamecommon.CreateSpecialChessData(DataFormat,spinConfig)
    -- 结果数据列表
    local resultInfoList = {}
    -- 第一个棋盘数据
    local firstBoards = table.clone(boards)
    -- 总中奖倍数
    local endFlag = EliminateProcess(boards, lastColRow, resultInfoList, sungodInfo.betMoney, uid, gameType, spinConfig)
    while endFlag do
        endFlag = EliminateProcess(boards, lastColRow, resultInfoList, sungodInfo.betMoney, uid, gameType, spinConfig)
    end
    local winScore = 0
    for _, value in ipairs(disInfo) do
        for _, v in ipairs(value.info) do
            winScore = winScore + v.winScore
        end
    end

end

-- 消除执行过程
function EliminateProcess(boards, lastColRow, resultInfoList, betMoney, uid, gameType, spinConfig)
    -- 消除是否结束
    local endFlag = false
    -- 棋盘中对应ID中奖状态
    local statMap = {}
    -- 遍历棋盘
    for colNum = 1, #DataFormat do
        -- 连续图标的ID
        local continueIconId = boards[colNum][1]
        local continueIconNum = 0
        for rowNum = 1, DataFormat[colNum] do
            if table.empty(statMap[boards[colNum][rowNum]]) then
                statMap[boards[colNum][rowNum]] = {num = 0,endColNum = colNum}
            end
            -- 统计本列连续图标个数
            if boards[colNum][rowNum] == continueIconId then
                continueIconNum = continueIconNum + 1
            else
                -- 如果当前图标与上一排不同 则要判断上面连续图标是否需要分组
                local groupIconNum = math.random(continueIconNum)
                -- 根据总组数分组
                GetIconGroup(continueIconNum,groupIconNum)

            end
            statMap[boards[colNum][rowNum]].num = statMap[boards[colNum][rowNum]].num + 1
            -- 如果前一列有盖图标 则最终相邻列数加1
            if statMap[boards[colNum][rowNum]].endColNum == colNum - 1 then
                statMap[boards[colNum][rowNum]].endColNum = colNum
            end
        end
    end



    return endFlag
end

-- 图标分组
function GetIconGroup(iconNum,groupNum)
    local iconList = {}
    for i = 1, groupNum do
        table.insert(iconList,{1})
    end
    -- 往固定长度的分组之中插入多余图标
    for i = 1, iconNum - groupNum do
        table.insert(iconList[math.random(groupNum)],1)
    end

end





-- 包装返回信息
function GetResInfo(uid, sungodInfo, gameType, tringerPoints)
    -- 克隆数据表
    sungodInfo = table.clone(sungodInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(sungodInfo.boards) == false then
        boards = {sungodInfo.boards}
    end
    local respin = {}
    if not table.empty(sungodInfo.respin) then
        respin = {
            totalTimes = sungodInfo.respin.totalTimes, -- 总次数
            lackTimes = sungodInfo.respin.lackTimes, -- 剩余游玩次数
            tWinScore = sungodInfo.respin.tWinScore, -- 总共已经赢得的钱
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_126_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_126_hanglie[1].linenum),
        -- 下注索引
        betIndex = sungodInfo.betIndex,
        -- 全部下注金额
        payScore = sungodInfo.betMoney,
        -- 已赢的钱
        -- winScore = sungodInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={respin = respin},
    }
    return res
end