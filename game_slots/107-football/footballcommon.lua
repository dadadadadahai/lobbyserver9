-- 足球游戏模块
module('Football', package.seeall)
-- 足球所需数据库表名称
DB_Name = "game107football"
-- 足球所需配置表信息
Table_Base = import "table/game/107/table_football_hanglie"                        -- 基础行列
Table_WinLines = import "table/game/107/table_football_payline"                    -- 中奖线
-- Table_NormalSpin = import "table/game/107/table_football_normalspin"               -- 普通棋盘
Table_PayTable = import "table/game/107/table_football_paytable"                   -- 中奖倍率
Table_MulW = import "table/game/107/table_football_wMul"                           -- W倍数
Table_NumW = import "table/game/107/table_football_wNum"                           -- W个数

-- JACKPOT所需数据配置表
table_107_jackpot_chips   = import 'table/game/107/table_107_jackpot_chips'
table_107_jackpot_add_per = import 'table/game/107/table_107_jackpot_add_per'
table_107_jackpot_bomb    = import 'table/game/107/table_107_jackpot_bomb'
table_107_jackpot_bet     = import 'table/game/107/table_107_jackpot_bet'
table_107_jackpot_scale   = {}
table_107_jackpot_scale[1] = import 'table/game/107/table_107_jackpot_scale1'
table_107_jackpot_scale[2] = import 'table/game/107/table_107_jackpot_scale2'
table_107_jackpot_scale[3] = import 'table/game/107/table_107_jackpot_scale3'
LineNum = Table_Base[1].linenum
-- 足球特殊元素ID
W = 90
Jackpot = 100

-- 足球通用配置
DataFormat = {3,3,3}                                                                   -- 棋盘规格
RandomIconList = {1,2,3,4}                                                                  -- 随机图标列表
GameId = 107

-- 构造数据存档
function Get(gameType,uid)
    -- 获取足球模块数据库信息
    local footballInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(footballInfo) then
        footballInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,footballInfo)
    end
    if gameType == nil then
        return footballInfo
    end
    -- 没有初始化房间信息
    if table.empty(footballInfo.gameRooms[gameType]) then
        footballInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            iconsAttachData = {}, -- 结算时面板图标上的附加显示数据
        }
        unilight.update(DB_Name,uid,footballInfo)
    end
    return footballInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取足球模块数据库信息
    local footballInfo = unilight.getdata(DB_Name, uid)
    footballInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,footballInfo)
end

-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,footballInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 生成返回数据
    local res = {}
    local jackpotTringerPoints = {}
    -- 普通游戏
    local betInfo = {
        betindex = footballInfo.betIndex,
        betchips = footballInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    local boards,rtp = CreateChessData(uid,gameId,gameType,betInfo)
    -- 棋盘数据
    res.boards = table.clone(boards)
    -- 足球每回合清空上一轮的W位置
    footballInfo.iconsAttachData[footballInfo.betIndex] = {}
    -- 修改棋盘信息 W元素替换
    ChangBoards(uid, GameId, gameType, res.boards, boards,footballInfo.iconsAttachData[footballInfo.betIndex],rtp)
    local jackFill
    -- 是否可以获取jackpot
    if #footballInfo.iconsAttachData[footballInfo.betIndex] <= 9 - table_107_jackpot_scale[gameType][#table_107_jackpot_scale[gameType]].iconNum then
        -- 获得奖励
        local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, footballInfo.betIndex)
        jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],bSucess,GameId)
        -- 获得奖池奖励
        if bSucess then
            -- 如果中Jackpot则让他不中奖
            local iconIdList = chessutil.NotRepeatRandomNumbers(1,4,4)
            local changNum = 0
            -- 遍历修改棋盘前两列图标 保证其不中奖
            boards[1][2] = iconIdList[1]
            boards[2][1] = iconIdList[2]
            boards[2][3] = iconIdList[3]
            boards[3][2] = iconIdList[4]
            -- 增加jackpot返回
            res.jackpotChips = jackpotChips
            -- 修改棋盘信息
            local insertList = {}
            -- 遍历棋盘信息寻找可以插入的点
            for colIndex, colValue in ipairs(boards) do
                for rowIndex, rowValue in ipairs(colValue) do
                    -- 非W元素则可以替换
                    if rowValue ~= W then
                        table.insert(insertList,{colNum = colIndex, rowNum = rowIndex})
                    end
                end
            end
            -- 随机替换位置
            local insertListRandomIndex = chessutil.NotRepeatRandomNumbers(1,#insertList,iconNum)
            for i, v in ipairs(insertListRandomIndex) do
                boards[insertList[v].colNum][insertList[v].rowNum] = Jackpot
                res.boards[insertList[v].colNum][insertList[v].rowNum] = Jackpot
                table.insert(jackpotTringerPoints,{line = insertList[v].colNum, row = insertList[v].rowNum})
            end
        end
    else
        jackFill = gamecommon.FillJackPotIcon:New(#DataFormat,DataFormat[1],false,GameId)
    end
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,Table_WinLines,Table_PayTable,wilds,nowild)
    for _, v in ipairs(winlines) do
        for _, value in ipairs(v.winpos) do
            jackFill:FillExtraIcon(value[1],value[2])
        end
    end
    -- 遍历棋盘排除替换特殊图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if boards[colNum][rowNum] == W then
                jackFill:FillExtraIcon(colNum,rowNum)
            end
        end
    end
    jackFill:CreateFinalChessData(res.boards,Jackpot)

    -- 中奖金额
    res.winScore = 0
    local addScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        addScore = v.mul * footballInfo.betMoney / Table_Base[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end
    local mul = GetRewardMul(footballInfo.iconsAttachData[footballInfo.betIndex])
    res.winScore = res.winScore * mul
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    footballInfo.boards[footballInfo.betIndex] = boards
    res.jackpotTringerPoints = {jackpotTringerPoints}
    return res
end
-- 根据W元素修改棋盘信息
function ChangBoards(uid, gameId, gameType, oldBoards, boards, iconsAttachData,rtp)
    -- -- 循环上升W位置
    -- for i, v in ipairs(iconsAttachData) do
    --     v.rowNum = v.rowNum + 1
    -- end
    -- -- 删除信息初始下标
    -- local point = 1
    -- -- 如果超出棋盘则删除信息
    -- while(point <= #iconsAttachData) do
    --     if iconsAttachData[point].rowNum > 3 then
    --         table.remove(iconsAttachData,point)
    --     else
    --         point = point + 1
    --     end
    -- end
    -- 判断本次是否需要添加w元素
    local probability = {}
    local allResult = {}
    for i, v in ipairs(Football['table_football_wNum_'..gameType]) do
        -- local controlvalue = gamecommon.GetControlPoint(uid)
        -- local rtp = gamecommon.GetModelRtp(GameId,gameType,controlvalue)
        local pro = v.pro
        if rtp ~= 100 then
            pro = v["pro_"..tostring(rtp)]
        end
        if pro > 0 then
            table.insert(probability, pro)
            table.insert(allResult, {pro, v.colNum})
        end
    end
    -- 获取本列随即后的W个数
    local colNum = math.random(probability, allResult)[2]
    colNum = GmProcess(uid, gameId, gameType, colNum)
    local colList = chessutil.NotRepeatRandomNumbers(1,3,colNum)
    for i, v in ipairs(colList) do
        table.insert(iconsAttachData,{colNum = v, rowNum = math.random(DataFormat[v]), iconId = W})
    end
    -- 循环替换棋盘
    for i, v in ipairs(iconsAttachData) do
        boards[v.colNum][v.rowNum] = v.iconId
    end

    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(oldBoards,Table_WinLines,Table_PayTable,wilds,nowild)

    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        -- 循环判断中奖线
        for _, winpos in ipairs(v.winpos) do
            for _, value in ipairs(iconsAttachData) do
                if value.colNum == winpos[1] and value.rowNum == winpos[2] then
                    oldBoards[value.colNum][value.rowNum] = GetNoIconIdRandom(v.ele)
                end
            end
        end
    end
end
-- 获取非传入的图标ID随机
function GetNoIconIdRandom(iconId)
    local maxWhileNum = 10
    local whileNum = 0
    while true do
        whileNum = whileNum + 1
        local randomIconId = RandomIconList[math.random(#RandomIconList)]
        if iconId ~= randomIconId then
            return randomIconId
        else
            if whileNum >= maxWhileNum then
                return randomIconId
            end
        end
    end
end
-- 生成棋盘
function CreateChessData(uid,gameId,gameType,betInfo)
    local boards = {}
    local spin,rtp = gamecommon.GetSpin(uid,gameId,gameType,betInfo)
    for colNum = 1, #DataFormat do
        for rowNum = 1, DataFormat[colNum] do
            if table.empty(boards[colNum]) then
                boards[colNum] = {}
            end
            -- 如果是随机第二种棋盘内容
            if (colNum == 2 and rowNum ~= 2) or (rowNum == 2 and colNum ~= 2) then
                boards[colNum][rowNum] = spin[math.random(#spin)].c2
            else
                boards[colNum][rowNum] = spin[math.random(#spin)].c1
            end
        end
    end
    return boards,rtp
end

-- 包装返回信息
function GetResInfo(uid, footballInfo, gameType, jackpot)
    -- 克隆数据表
    footballInfo = table.clone(footballInfo)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 模块信息
    local boards = {}
    if table.empty(footballInfo.boards[footballInfo.betIndex]) == false then
        boards = {footballInfo.boards[footballInfo.betIndex]}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = Table_Base[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,Table_Base[1].linenum),
        -- 下注索引
        betIndex = footballInfo.betIndex,
        -- 全部下注金额
        payScore = footballInfo.betMoney,
        -- 已赢的钱
        -- winScore = footballInfo.winScore,
        -- 附加面板数据
        iconsAttachData = {footballInfo.iconsAttachData[footballInfo.betIndex]},
        -- 面板格子数据
        boards = boards,
        features={jackpot = jackpot},
    }
    return res
end