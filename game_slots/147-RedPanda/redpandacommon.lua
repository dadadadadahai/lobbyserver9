-- 老虎游戏模块
module('RedPanda', package.seeall)
-- 老虎所需数据库表名称
DB_Name = "game147redpanda"
-- 老虎通用配置
GameId = 147
S = 70
W = 90
B = 6
DataFormat = {3,3,3}    -- 棋盘规格
Table_Base = import "table/game/147/table_147_hanglie"                        -- 基础行列
MaxNormalIconId = 10
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取老虎模块数据库信息
    local redpandaInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(redpandaInfo) then
        redpandaInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,redpandaInfo)
    end
    if gameType == nil then
        return redpandaInfo
    end
    -- 没有初始化房间信息
    if table.empty(redpandaInfo.gameRooms[gameType]) then
        redpandaInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            respin = {}, -- respin游戏信息
        }
        unilight.update(DB_Name,uid,redpandaInfo)
    end
    return redpandaInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取老虎模块数据库信息
    local redpandaInfo = unilight.getdata(DB_Name, uid)
    redpandaInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,redpandaInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,redpandaInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- respin中奖金额
    res.respinWinScore = 0
    res.bigWinIcon = -1
    -- 判断是否中respin
    if GmProcess().respin == true or math.random(10000) <= table_147_respinpro[1].pro then
        -- 中了respin
        local respinFinalResult = RespinFinalBoards(redpandaInfo)
        local userInfo = unilight.getdata('userinfo',uid)
        -- 判断是否触发保底机制
        if respinFinalResult.winScore / redpandaInfo.betMoney < 15 then
            local respinResultList = {}
            for i = 1, 10 do
                table.insert(respinResultList,RespinFinalBoards(redpandaInfo))
            end
            -- 对结果列表排序
            table.sort(respinResultList,function(a,b)
                return a.winScore > b.winScore
            end)
            for _, value in ipairs(respinResultList) do
                if value.winScore / redpandaInfo.betMoney >= 15 then
                    if chessuserinfodb.GetAHeadTolScore(uid) + redpandaInfo.betMoney * respinFinalResult.winScore >= userInfo.point.chargeMax then
                        break
                    end
                    respinFinalResult = value
                    break
                end
            end
        end

        -- 防止超出控制 提前增加respin金额判断
        res.winScore = res.winScore + respinFinalResult.winScore
        res.respinWinScore = respinFinalResult.winScore
        -- 本轮respin出现的图标ID
        res.respinMul = respinFinalResult.respinMul
        res.respinIconId = respinFinalResult.respinIconId
        res.bigWinIcon = respinFinalResult.bigWinIcon
        AheadRespin(redpandaInfo,respinFinalResult)
        -- 预计算金额
        local aHeadBonusWinScore = 0
        boards = redpandaInfo.boards
        res.respinFlag = true
        redpandaInfo.winlines = redpandaInfo.respin.winlines or res.winlines
        res.winlines = redpandaInfo.winlines
    else
        -- 普通游戏
        local betInfo = {
            betindex = redpandaInfo.betIndex,
            betchips = redpandaInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        GmProcess(boards)

        -- 十倍是否触发
        local fullIconFlag = false
        -- 随机本次是否十倍   没有触发福牛模式才进行下面的判断
        if math.random(10000) <= table_147_mulPro[1].pro or GmProcess().bonus  then
            fullIconFlag = true
            local iconId = table_147_mulIcon[gamecommon.CommRandInt(table_147_mulIcon, 'pro')].iconId
            for col = 1, #DataFormat do
                for row = 1, DataFormat[col] do
                    boards[col][row] = iconId
                end
            end
        end

        res.respinFlag = false
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(boards,table_147_payline,table_147_paytable,wilds,nowild)
        -- 计算中奖线金额
        for k, v in ipairs(winlines) do
            local addScore = v.mul * redpandaInfo.betMoney / table_147_hanglie[1].linenum
            res.winScore = res.winScore + addScore
            table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
        end

        -- 如果棋盘填满则需要*10
        local blankIconFlag = false
        local firstIcon = 0
        for col = 1,#DataFormat do
            for row = 1,DataFormat[col] do
                -- 缓存第一个不是空白和W的图标
                if firstIcon == 0 and boards[col][row] ~= 0 and boards[col][row] ~= W then
                    firstIcon = boards[col][row]
                end
                if boards[col][row] ~= firstIcon and boards[col][row] ~= W then
                    blankIconFlag = true
                end
            end
        end
        if not blankIconFlag then
            res.bigWinIcon = firstIcon
        end
        if IsAllWinPoints(res.winlines[1]) then
            local respinMul = 10
            res.winScore = res.winScore * respinMul
            res.bigWinIcon = 0
        end
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    redpandaInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    res.winScore = math.floor(res.winScore)
    return res
end

-- 判断是否全部中奖
function IsAllWinPoints(winlines)
    if table.empty(winlines) then
        return false
    end
    -- 初始化一个对应的中奖图标棋盘
    local winPointsBoards = {}
    for col = 1,#DataFormat do
        for row = 1,DataFormat[col] do
            if winPointsBoards[col] == nil then
                winPointsBoards[col] = {}
            end
            winPointsBoards[col][row] = 0
        end
    end
    -- 遍历是否中奖
    for _, winline in ipairs(winlines) do
        -- 对应的中奖列配置
        local pointInfo = table_147_payline[winline[1]]
        -- 根据配置和中奖的数量修改对应中奖棋盘种的数据
        for num = 1, winline[2] do
            local point = pointInfo["I"..num]
            winPointsBoards[math.floor(point/10)][point%10] = winPointsBoards[math.floor(point/10)][point%10] + 1
        end
    end
    for col = 1,#DataFormat do
        for row = 1,DataFormat[col] do
            if winPointsBoards[col][row] == 0 then
                return false
            end
        end
    end
    return true
end

-- 包装返回信息
function GetResInfo(uid, redpandaInfo, gameType, tringerPoints)
    -- 克隆数据表
    redpandaInfo = table.clone(redpandaInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(redpandaInfo.boards) == false then
        boards = {redpandaInfo.boards}
    end
    local respin = {}
    if not table.empty(redpandaInfo.respin) then
        respin = {
            totalTimes = redpandaInfo.respin.totalTimes, -- 总次数
            lackTimes = redpandaInfo.respin.lackTimes, -- 剩余游玩次数
            tWinScore = redpandaInfo.respin.tWinScore, -- 总共已经赢得的钱
            respinIconId = redpandaInfo.respin.respinIconId, -- 总共已经赢得的钱
            respinMul = redpandaInfo.respin.respinMul, -- 总共已经赢得的钱
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_147_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_147_hanglie[1].linenum),
        -- 下注索引
        betIndex = redpandaInfo.betIndex,
        -- 全部下注金额
        payScore = redpandaInfo.betMoney,
        -- 已赢的钱
        -- winScore = redpandaInfo.winScore,
        winlines = redpandaInfo.winlines,
        -- 面板格子数据
        boards = boards,
        -- 独立调用定义
        features={respin = respin},
        respin = respin,
    }
    return res
end