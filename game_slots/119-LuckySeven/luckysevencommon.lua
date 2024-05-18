-- 幸运七游戏模块
module('LuckySeven', package.seeall)
-- 幸运七所需数据库表名称
DB_Name = "game119luckyseven"
-- 幸运七通用配置
GameId = 119
W = 90
LineNum = 1
DataFormat = {1,1,1,1,1,1,1}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取幸运七模块数据库信息
    local luckysevenInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(luckysevenInfo) then
        luckysevenInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,luckysevenInfo)
    end
    if gameType == nil then
        return luckysevenInfo
    end
    -- 没有初始化房间信息
    if table.empty(luckysevenInfo.gameRooms[gameType]) then
        luckysevenInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
        }
        unilight.update(DB_Name,uid,luckysevenInfo)
    end
    return luckysevenInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取幸运七模块数据库信息
    local luckysevenInfo = unilight.getdata(DB_Name, uid)
    luckysevenInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,luckysevenInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,luckysevenInfo)
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
        betindex = luckysevenInfo.betIndex,
        betchips = luckysevenInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    GmProcess(uid, gameId, gameType, boards)
    local success = false
    -- 获得奖池奖励
    local bSucess, jackpotNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, luckysevenInfo.betIndex)
    res.jackpotChips = jackpotChips or 0
    -- -- 添加奖池图标
    -- if bSucess then
    --     -- 中奖 则替换图标
    --     -- 替换图标
    --     for colNum = 1, jackpotNum do
    --         boards[colNum][DataFormat[1]] = 3
    --     end
    --     -- 后面让他不中奖
    --     boards[jackpotNum + 1][DataFormat[1]] = 1
    -- end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_119_payline,table_119_paytable,wilds,nowild)
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * luckysevenInfo.betMoney / table_119_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    if table.empty(res.winlines[1]) == false then
        for col = 1,res.winlines[1][1][2] do
            if boards[col][1] == W then
                res.winScore = res.winScore * 2
            end
        end
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    luckysevenInfo.boards = boards
    -- 棋盘数据
    res.boards = boards

    return res
end

-- 包装返回信息
function GetResInfo(uid, luckysevenInfo, gameType, jackpot)
    jackpot = jackpot or {}
    -- 克隆数据表
    luckysevenInfo = table.clone(luckysevenInfo)
    -- 模块信息
    local boards = {}
    if table.empty(luckysevenInfo.boards) == false then
        boards = {luckysevenInfo.boards}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_119_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_119_hanglie[1].linenum),
        -- 下注索引
        betIndex = luckysevenInfo.betIndex,
        -- 全部下注金额
        payScore = luckysevenInfo.betMoney,
        -- 已赢的钱
        -- winScore = luckysevenInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={jackpot = jackpot},
    }
    return res
end