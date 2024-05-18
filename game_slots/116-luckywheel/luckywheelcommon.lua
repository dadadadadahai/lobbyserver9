-- 幸运转盘游戏模块
module('LuckyWheel', package.seeall)
-- 幸运转盘所需数据库表名称
DB_Name = "game116avatares"
-- 幸运转盘所需配置表信息
-- Table_FreeSpin = import "table/game/116/table_116_freespin"                    -- 免费棋盘
LineNum = 1
GoldType = 1
FreeType = 2
AllType = 3
GameId = 116
LineNum = 1
DataFormat = {6,6,6}                                                                            -- 棋盘规格
-- 构造数据存档
function Get(gameType,uid)
    -- 获取幸运转盘模块数据库信息
    local luckywheelInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(luckywheelInfo) then
        luckywheelInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,luckywheelInfo)
    end
    if gameType == nil then
        return luckywheelInfo
    end
    -- 没有初始化房间信息
    if table.empty(luckywheelInfo.gameRooms[gameType]) then
        luckywheelInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boardsId = 0, -- 当前模式游戏棋盘下标
            -- 免费游戏信息
            free = {
            },
        }
        unilight.update(DB_Name,uid,luckywheelInfo)
    end
    return luckywheelInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取幸运转盘模块数据库信息
    local luckywheelInfo = unilight.getdata(DB_Name, uid)
    luckywheelInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,luckywheelInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,luckywheelInfo)
    local table_116_freespin = LuckyWheel['table_116_freespin_'..gameType]
    -- 生成返回数据
    local res = {}
    res.winScore = 0
    if isFree then

        local userinfo = unilight.getdata('userinfo',uid)
        --获取当前金币
        local chips = chessuserinfodb.GetAHeadTolScore(userinfo._id)
        --获取累计充值
        local totalRechargeChips = userinfo.property.totalRechargeChips
        -- 本次最低获取金额
        local minScore = luckywheelInfo.betMoney * tonumber(table_116_freespin[15].content)
        if totalRechargeChips <= 0 and ((chips + luckywheelInfo.free.tWinScore + minScore) + luckywheelInfo.free.lackTimes * minScore) >= (import "table/table_parameter_parameter")[15].Parameter  then
            res.boardsInfo = table_116_freespin[15]
        else
            res.boardsInfo = table_116_freespin[gamecommon.CommRandInt(table_116_freespin,'pro')]
        end
        if userinfo.property.totalRechargeChips - userinfo.status.chipsWithdraw<=0 then
            if res.boardsInfo.type == FreeType then
                -- 一轮免费总共能中奖金额
                local freetWinScore = luckywheelInfo.betMoney * tonumber(table_116_freespin[15].content) * 10

                -- 累计获取金额
                local tWinScore = luckywheelInfo.free.tWinScore
                -- 剩余次数
                local lackTimes = luckywheelInfo.free.lackTimes
                -- 本次金额
                -- local winScore = luckywheelInfo.betMoney * tonumber(res.boardsInfo.content)
                -- 如果当前金额+累计获取金额+(剩余次数 * 单次最低金额)+本次金额 大于等于 阈值
                if chips + tWinScore + (lackTimes * minScore) + freetWinScore >= (import "table/table_parameter_parameter")[18].Parameter then
                    res.boardsInfo = table_116_freespin[15]
                end
            else
                -- 累计获取金额
                local tWinScore = luckywheelInfo.free.tWinScore
                -- 剩余次数
                local lackTimes = luckywheelInfo.free.lackTimes
                -- 本次金额
                local winScore = luckywheelInfo.betMoney * tonumber(res.boardsInfo.content)
                -- 如果当前金额+累计获取金额+(剩余次数 * 单次最低金额)+本次金额 大于等于 阈值
                if chips + tWinScore + (lackTimes * minScore) + winScore >= (import "table/table_parameter_parameter")[18].Parameter then
                    res.boardsInfo = table_116_freespin[15]
                end
            end
        end
        res.boardsInfo = GmProcess(uid, gameId, gameType, table_116_freespin, res.boardsInfo)
        if res.boardsInfo.type == FreeType then
            local _,_,addNum = string.find(res.boardsInfo.content, "[*](%d+)")
            luckywheelInfo.free.totalTimes = luckywheelInfo.free.totalTimes + tonumber(addNum)
            luckywheelInfo.free.lackTimes = luckywheelInfo.free.lackTimes + tonumber(addNum)
        elseif res.boardsInfo.type == AllType then
            for _, info in ipairs(table_116_freespin) do
                if info.type == GoldType then
                    res.winScore = res.winScore + luckywheelInfo.betMoney * tonumber(info.content)
                elseif info.type == FreeType then
                    local _,_,addNum = string.find(info.content, "[*](%d+)")
                    luckywheelInfo.free.totalTimes = luckywheelInfo.free.totalTimes + tonumber(addNum)
                    luckywheelInfo.free.lackTimes = luckywheelInfo.free.lackTimes + tonumber(addNum)
                end
            end
        elseif res.boardsInfo.type == GoldType then
            res.winScore = luckywheelInfo.betMoney * tonumber(res.boardsInfo.content)
        end
    else
        -- 普通游戏
        -- res.boardsInfo = table_116_freespin[gamecommon.CommRandInt(table_116_freespin,'pro')]
        local betInfo = {
            betindex = luckywheelInfo.betIndex,
            betchips = luckywheelInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        local spin = gamecommon.GetSpin(uid,gameId,gameType,betInfo)
        res.boardsInfo = spin[gamecommon.CommRandInt(spin,'pro')]
        res.boardsInfo = GmProcess(uid, gameId, gameType, spin, res.boardsInfo)
        if res.boardsInfo.type == FreeType then
            local _,_,addNum = string.find(res.boardsInfo.content, "[*](%d+)")
            luckywheelInfo.free.totalTimes = tonumber(addNum)
            luckywheelInfo.free.lackTimes = luckywheelInfo.free.totalTimes      -- 剩余游玩次数
            luckywheelInfo.free.tWinScore = 0                                   -- 已经赢得的钱
        elseif res.boardsInfo.type == GoldType then
            res.winScore = luckywheelInfo.betMoney * tonumber(res.boardsInfo.content)
        end
    end
    -- 保存棋盘数据
    luckywheelInfo.boardsId = res.boardsInfo.no
    return res
end
-- 包装返回信息
function GetResInfo(uid, luckywheelInfo, gameType)
    -- 克隆数据表
    luckywheelInfo = table.clone(luckywheelInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    local res = {
        errno = 0,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,LineNum),
        -- 下注索引
        betIndex = luckywheelInfo.betIndex,
        -- 全部下注金额
        payScore = luckywheelInfo.betMoney,
        -- 已赢的钱
        -- winScore = luckywheelInfo.winScore,
        -- 面板格子数据
        boards = {{luckywheelInfo.boardsId}},
        -- 独立调用定义
        features={free = luckywheelInfo.free},
    }
    return res
end
