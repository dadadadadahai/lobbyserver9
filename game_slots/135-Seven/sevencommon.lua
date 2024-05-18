-- 777游戏模块
module('Seven', package.seeall)
-- 777所需数据库表名称
DB_Name = "game135seven"
-- 777通用配置
GameId = 135
S = 70
W = 90
B = 6
DataFormat = {1,1,1}    -- 棋盘规格
Table_Base = import "table/game/135/table_135_hanglie"                        -- 基础行列
MaxNormalIconId = 5
MinSpecialIconId = 81
MaxSpecialIconId = 86
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取777模块数据库信息
    local sevenInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(sevenInfo) then
        sevenInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,sevenInfo)
    end
    if gameType == nil then
        return sevenInfo
    end
    -- 没有初始化房间信息
    if table.empty(sevenInfo.gameRooms[gameType]) then
        sevenInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            mulList = {}, -- 倍数列表
            sumMul = 1, -- 合计倍数
        }
        unilight.update(DB_Name,uid,sevenInfo)
    end
    return sevenInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取777模块数据库信息
    local sevenInfo = unilight.getdata(DB_Name, uid)
    sevenInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,sevenInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,sevenInfo)
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
        betindex = sevenInfo.betIndex,
        betchips = sevenInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    -- 生成异形棋盘
    if isFree then
        boards = gamecommon.CreateSpecialChessData(DataFormat,Seven['table_135_free_'..gameType])
    else
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    end
    -- 在中奖倍数之前修改棋盘满足配置表特殊情况
    -- 任意7 改为6  任意DE 改为7 任意图标 改为8
    local barIcon = 0
    local sevenIcon = 0
    local notSameFlag = false
    for col = 1, #DataFormat do
        -- 有空白直接退出不改变
        if boards[col][1] == 1000 then
            barIcon = 0
            sevenIcon = 0
            notSameFlag = false
            break
        elseif boards[col][1] == 1 or boards[col][1] == 2 then
            if boards[col - 1] ~= nil and boards[col - 1][1] ~= nil and boards[col][1] ~= boards[col - 1][1] then
                notSameFlag = true
            end
            barIcon = barIcon + 1
        elseif boards[col][1] == 3 or boards[col][1] == 4 or boards[col][1] == 5 then
            if boards[col - 1] ~= nil and boards[col - 1][1] ~= nil and boards[col][1] ~= boards[col - 1][1] then
                notSameFlag = true
            end
            sevenIcon = sevenIcon + 1
        end
    end
    -- 修改棋盘
    local winlinesboards = table.clone(boards)
    if notSameFlag and barIcon == 3 then
        winlinesboards[1][1] = 7
        winlinesboards[2][1] = 7
        winlinesboards[3][1] = 7
    elseif notSameFlag and sevenIcon == 3 then
        winlinesboards[1][1] = 6
        winlinesboards[2][1] = 6
        winlinesboards[3][1] = 6
    elseif notSameFlag and (barIcon > 0 or sevenIcon > 0) then
        winlinesboards[1][1] = 8
        winlinesboards[2][1] = 8
        winlinesboards[3][1] = 8
    end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(winlinesboards,table_135_payline,table_135_paytable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * sevenInfo.betMoney / table_135_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    local iconId = 0
    local iconMul = 0
    if table.empty(sevenInfo.free) then
        -- 生成最后一列棋盘
        local iconInfo = table_135_iconId[gamecommon.CommRandInt(table_135_iconId, 'pro')]
        iconId = iconInfo.iconId
        iconMul = iconInfo.mul
    else
        iconId = 86
    end
    if GmProcess() then
       iconId = 86
       iconMul = 0
    end
    -- 插入棋盘
    boards[#boards + 1] = {}
    table.insert(boards[#boards],iconId)
    
    -- 判断free
    if (table.empty(sevenInfo.free) and iconId == 86 and res.winScore > 0) then
        -- 随机免费次数
        local totalTimes = table_135_freeNum[gamecommon.CommRandInt(table_135_freeNum, 'pro')].num
        -- 初始化免费
        sevenInfo.free = {
            lackTimes = totalTimes,
            totalTimes = totalTimes,
            tWinScore = 0,
        }
    end

    if iconId == 84 or iconId == 85 then
        if res.winScore > 0 then
            res.winScore = res.winScore + sevenInfo.betMoney * iconMul
        else
            iconMul = 0
        end
    end
    if iconId == 81 or iconId == 82 or iconId == 83 then
        res.winScore = res.winScore * iconMul
    end

    -- 最后改变空白棋盘
    for col = 1, 4 do
        -- 有空白直接退出不改变
        if boards[col][1] == 1000 and col <= 3 then
            boards[col] = {math.random(MaxNormalIconId),math.random(MaxNormalIconId)}
        elseif boards[col][1] == 1000 and col == 4 then
            boards[col] = {math.random(MinSpecialIconId,MaxSpecialIconId),math.random(MinSpecialIconId,MaxSpecialIconId)}
        end
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    sevenInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.extraData = {
        iconMul = iconMul,
    }
    return res
end

-- 包装返回信息
function GetResInfo(uid, sevenInfo, gameType, tringerPoints)
    -- 克隆数据表
    sevenInfo = table.clone(sevenInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(sevenInfo.boards) == false then
        boards = {sevenInfo.boards}
    end
    local free = {}
    if not table.empty(sevenInfo.free) then
        free = {
            totalTimes = sevenInfo.free.totalTimes, -- 总次数
            lackTimes = sevenInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = sevenInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_135_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_135_hanglie[1].linenum),
        -- 下注索引
        betIndex = sevenInfo.betIndex,
        -- 全部下注金额
        payScore = sevenInfo.betMoney,
        -- 已赢的钱
        -- winScore = sevenInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={free = free},
        extraData = {
            mulList = sevenInfo.mulList,
            sumMul = sevenInfo.sumMul,
        }
    }
    return res
end