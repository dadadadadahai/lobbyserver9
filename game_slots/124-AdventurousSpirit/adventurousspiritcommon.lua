-- 冒险精神游戏模块
module('AdventurousSpirit', package.seeall)
-- 冒险精神所需数据库表名称
DB_Name = "game124adventurous"
-- 冒险精神通用配置
GameId = 124
S = 70
U = 80
W = 90
B = 9
NormalIconList = {1,2,3,4,5,10,11,12,13}
DataFormat = {3,3,3,3,3}    -- 棋盘规格
Table_Base = import "table/game/124/table_124_hanglie"                        -- 基础行列
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取冒险精神模块数据库信息
    local adventurousInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(adventurousInfo) then
        adventurousInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,adventurousInfo)
    end
    if gameType == nil then
        return adventurousInfo
    end
    -- 没有初始化房间信息
    if table.empty(adventurousInfo.gameRooms[gameType]) then
        adventurousInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,adventurousInfo)
    end
    return adventurousInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取冒险精神模块数据库信息
    local adventurousInfo = unilight.getdata(DB_Name, uid)
    adventurousInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,adventurousInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,adventurousInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 初始棋盘
    local boards = {}
    -- 生成返回数据
    local res = {}
    -- 免费U元素生成的B元素位置上之前的图标ID
    local oldIconList = {}
    -- 触发位置
    res.tringerPoints = {}
    -- 清理无用信息
    if table.empty(adventurousInfo.free.endPlayPoint) == false then
        adventurousInfo.free.endPlayPoint = {}
    end
    -- B元素内容
    local iconB
    if isFree then
        -- 免费游戏
        boards = gamecommon.CreateSpecialChessData(DataFormat,AdventurousSpirit['table_124_freespin_'..gameType])
        local wildFlagGM,wildPoint = GmProcess(uid, gameId, gameType, boards)
        -- 判断是否插入Wild元素
        if wildFlagGM == false then
            adventurousInfo.wildCol,adventurousInfo.wildRow = SetRandomWild(boards)
        else
            adventurousInfo.wildCol = wildPoint[1]
            adventurousInfo.wildRow = wildPoint[2]
        end

        -- 判断U元素是否生效(所有图标插入后 最后判断U图标)
        oldIconList,res.tringerPoints.freeTringerPoints = FreeIconU(adventurousInfo,boards,adventurousInfo.wildCol,adventurousInfo.wildRow)
    else
        -- 普通游戏
        local betInfo = {
            betindex = adventurousInfo.betIndex,
            betchips = adventurousInfo.betMoney,
            gameId = gameId,
            gameType = gameType,
        }
        boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
        NormalIconU(boards)
        GmProcess(uid, gameId, gameType, boards)
    end
    
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_124_payline,table_124_paytable,wilds,nowild)

    -- 判断棋盘B元素内容
    iconB = SetIconB(adventurousInfo,boards,isFree,adventurousInfo.wildCol,adventurousInfo.wildRow)
    -- 插入棋盘信息
    adventurousInfo.iconsAttachData.iconB = iconB
    adventurousInfo.iconsAttachData.oldIconList = oldIconList
    -- 中奖金额
    res.winScore = 0
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * adventurousInfo.betMoney / table_124_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    adventurousInfo.boards = boards
    -- 棋盘数据
    res.boards = boards

    if isFree then
        -- 计算B图标中将金额
        for _, value in ipairs(iconB) do
            if value.winFlag == true then
                res.winScore = res.winScore + adventurousInfo.betMoney * value.mul * value.addMul
            end
        end
        -- 同步收集进度里的倍数
        for _, value in ipairs(adventurousInfo.free.collect) do
            -- 如果收集满了并且没有同步倍数则同步
            if value.collectNum >= value.totalCollectNum and value.mul == 1 then
                for _, tableInfo in ipairs(table_124_collect) do
                    if value.iconId == tableInfo.iconId then
                        value.mul = tableInfo.mul
                        break
                    end
                end
            end
        end
    else
        res.tringerPoints.freeTringerPoints = GetFree(adventurousInfo)
    end
    
    -- 判断免费棋盘是否结束
    if isFree and adventurousInfo.free.lackTimes <= 0 then
        adventurousInfo.free.endPlayTime = adventurousInfo.free.endPlayTime + 1
        if adventurousInfo.free.endPlayTime >= table_124_freeend[1].maxEndNum or math.random(10000) < table_124_freeend[1].pro then
            -- 如果结束 图腾放到W位置
            adventurousInfo.free.endPlayPoint = {colNum = adventurousInfo.wildCol,rowNum = adventurousInfo.wildRow}
            res.freeEndFlag = true
        else
            -- 未结束
            while true do
                local colNum = math.random(#DataFormat)
                local rowNum = math.random(DataFormat[colNum])
                -- 如果没在Wild元素位置上则使用此结果
                if not (adventurousInfo.wildCol == colNum and adventurousInfo.wildRow == rowNum) then
                    adventurousInfo.free.endPlayPoint = {colNum = colNum,rowNum = rowNum}
                    break
                end
            end
            res.freeEndFlag = false
        end
    end
    return res
end

-- 判断是否触发免费
function GetFree(adventurousInfo)
    -- 存在S列的个数
    local sNum = 0
    -- 免费游戏次数
    local freeNum = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    local PointS = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #adventurousInfo.boards do
        for rowNum = 1, #adventurousInfo.boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if adventurousInfo.boards[colNum][rowNum] == S then
                table.insert(PointS,{line = colNum, row = rowNum})
                sNum = sNum + 1
            elseif adventurousInfo.boards[colNum][rowNum] == U then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                freeNum = freeNum + table_124_unum[1].freeNum
            end
        end
    end
    -- 判断是否触发免费
    if freeNum == 0 then
        for _, v in ipairs(table_124_freenum) do
            if sNum == v.iconNum then
                freeNum = v.freeNum
                -- S触发免费了的话将触发位置添加到中奖位置中
                for _, point in ipairs(PointS) do
                    table.insert(freeTringerPoints,{line = point.line, row = point.row})
                end
                break
            end
        end
    end
    if freeNum > 0 then
        -- 触发免费初始化
        adventurousInfo.free.totalTimes = freeNum           -- 总次数
        adventurousInfo.free.lackTimes = freeNum            -- 剩余游玩次数
        adventurousInfo.free.tWinScore = 0                  -- 已经赢得的钱
        adventurousInfo.free.endPlayTime = 0                -- 已经结束后游玩的局数
        adventurousInfo.free.collect = {}                   -- 收集进度
        for _, v in ipairs(table_124_collect) do
            table.insert(adventurousInfo.free.collect,{iconId = v.iconId,totalCollectNum = v.collectNum,collectNum = 0,
                        mul = 1,infoMul = v.mul,addFreeMin = v.addFreeMin,addFreeMax = v.addFreeMax})
        end
        return freeTringerPoints
    end
end

-- 免费游戏随机生成W元素
function SetRandomWild(boards)
    local col = math.random(#DataFormat)
    local row = math.random(DataFormat[col])
    boards[col][row] = W
    return col,row
end

-- 随机B元素内容
function SetIconB(adventurousInfo,boards,isFree,wildCol,wildRow)
    local iconB = {}
    -- 遍历棋盘替换B图标
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            if boards[colNum][rowNum] == B then
                -- 按权重随机图标ID
                local iconId = table_124_bpro[gamecommon.CommRandInt(table_124_bpro, 'pro')].iconId
                -- 替换图标
                boards[colNum][rowNum] = iconId
                -- 如果是免费并且在Wild周围的B元素才会有奖励 否则没有
                if isFree and FreeEffectB(wildCol,wildRow,colNum,rowNum) then
                    -- 添加图标倍数
                    local mul = table_124_bfreemul[gamecommon.CommRandInt(table_124_bfreemul, 'pro'..iconId)].mul
                    local addMul = FreeCollectB(adventurousInfo,iconId)
                    table.insert(iconB,{col = colNum,row = rowNum,mul = mul,addMul = addMul,winFlag = true})
                else
                    -- 添加图标倍数
                    local mul = table_124_bmul[gamecommon.CommRandInt(table_124_bmul, 'pro'..iconId)].mul
                    local addMul = 1
                    -- 遍历查询对应图标ID收集进度
                    if table.empty(adventurousInfo.free.collect) == false then
                        for index, value in ipairs(adventurousInfo.free.collect) do
                            -- 根据数据库返回缓存的倍数
                            if value.iconId == iconId then
                                addMul = value.mul
                                break
                            end
                        end
                    end
                    table.insert(iconB,{col = colNum,row = rowNum,mul = mul,addMul = addMul,winFlag = false})
                end

            end
        end
    end
    return iconB
end


-- 普通中U元素随机
function NormalIconU(boards)
    -- 判断是否添加U  1 添加 0 不添加
    local flagU = table_124_normalu[gamecommon.CommRandInt(table_124_normalu, 'pro')].flagU
    if flagU == 0 then
        return
    end

    -- 如果购买免费则让他不中奖
    local iconIdListPoints = chessutil.NotRepeatRandomNumbers(1,#NormalIconList,2 * #boards[1])
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
                boards[colNum][rowNum] = NormalIconList[NormalIconList[iconIdListPoints[changNum]]]
            elseif boards[colNum][rowNum] == S then
                boards[colNum][rowNum] = NormalIconList[math.random(1,#NormalIconList)]
            end
        end
    end
    local randomRow = math.random(1,#boards[3])
    boards[3][randomRow] = U
end

-- 免费中U元素逻辑
function FreeIconU(adventurousInfo,boards,wildCol,wildRow)
    local addIconNum = 0
    local canInsertList = {}
    local oldIconList = {}
    local tringerPoints = {}
    -- 遍历棋盘查询U图标 顺便查询可插入位置
    for colNum = 1, #boards do
        for rowNum = 1, #boards[colNum] do
            -- 如果此位置可以插入
            if boards[colNum][rowNum] ~= W and boards[colNum][rowNum] ~= U and boards[colNum][rowNum] ~= B then
                table.insert(canInsertList,{colNum = colNum,rowNum = rowNum})
            end
            if boards[colNum][rowNum] == U then
                table.insert(tringerPoints,{line = colNum, row = rowNum})
                -- 填充棋盘
                addIconNum = table_124_freeu[gamecommon.CommRandInt(table_124_freeu, 'pro')].addIconNum
            end
        end
    end
    -- 如果可插入个数不足  则全部插入
    if addIconNum > #canInsertList then
        for _, v in ipairs(canInsertList) do
            -- 留存旧图标
            table.insert(oldIconList,{colNum = v.colNum,rowNum = v.rowNum,iconId = boards[v.colNum][v.rowNum]})
            -- 替换图标
            boards[v.colNum][v.rowNum] = B
        end
    else
        -- 生成插入位置
        local insertList = chessutil.NotRepeatRandomNumbers(1, #canInsertList, addIconNum)
        for _, inserPoint in ipairs(insertList) do
            -- 留存旧图标
            table.insert(oldIconList,{colNum = canInsertList[inserPoint].colNum,rowNum = canInsertList[inserPoint].rowNum,iconId = boards[canInsertList[inserPoint].colNum][canInsertList[inserPoint].rowNum]})
            -- 替换图标
            boards[canInsertList[inserPoint].colNum][canInsertList[inserPoint].rowNum] = B
        end
    end
    return oldIconList,tringerPoints
end

-- 免费中B元素生效
function FreeEffectB(wildCol,wildRow,colNum,rowNum)
    -- 判断是否生效
    if math.abs(wildCol - colNum) <= 1 and math.abs(wildRow - rowNum) <= 1 then
        return true
    end
    return false
end

-- 免费中B收集
function FreeCollectB(adventurousInfo,iconId)
    local addMul = 1
    -- 遍历查询对应图标ID收集进度
    for index, value in ipairs(adventurousInfo.free.collect) do
        -- 根据数据库返回缓存的倍数
        if value.iconId == iconId then
            addMul = value.mul
        end
        -- 如果还未收集满则触发增加收集次数和判断集满次数对比
        if value.iconId == iconId and value.collectNum < value.totalCollectNum then
            value.collectNum = value.collectNum + 1
            -- 判断是否收集满 收集满需要增加免费次数
            if value.collectNum == value.totalCollectNum then
                local addFreeNum = math.random(value.addFreeMin,value.addFreeMax)
                -- 如果是在免费结算中触发则需要重置一下剩余次数
                if adventurousInfo.free.lackTimes < 0 then
                    adventurousInfo.free.lackTimes = 0
                end
                -- 增加的免费次数不能高于初始次数
                if adventurousInfo.free.lackTimes + addFreeNum > adventurousInfo.free.totalTimes then
                    adventurousInfo.free.lackTimes = adventurousInfo.free.totalTimes
                else
                    adventurousInfo.free.lackTimes = adventurousInfo.free.lackTimes + addFreeNum
                end
            end
        end
    end
    return addMul
end





-- 包装返回信息
function GetResInfo(uid, adventurousInfo, gameType, tringerPoints,freeEndFlag)
    freeEndFlag = freeEndFlag or false
    -- 克隆数据表
    adventurousInfo = table.clone(adventurousInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(adventurousInfo.boards) == false then
        boards = {adventurousInfo.boards}
    end
    local free = {}
    if not table.empty(adventurousInfo.free) then
        local collect = {}
        for _, value in ipairs(adventurousInfo.free.collect) do
            table.insert(collect,{
                iconId = value.iconId, -- 收集图标
                mul = value.infoMul, -- 收集成功后倍数
                collectNum = value.collectNum, -- 当前收集个数
                totalCollectNum = value.totalCollectNum -- 总共收集个数
            })
        end
        free = {
            totalTimes = adventurousInfo.free.totalTimes, -- 总次数
            lackTimes = adventurousInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = adventurousInfo.free.tWinScore, -- 总共已经赢得的钱
            endPlayTime = adventurousInfo.free.endPlayTime, -- 已经结束后游玩的局数
            freeEndFlag = freeEndFlag, -- 是否已经结束
            collect = collect, -- 收集进度
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
        -- if adventurousInfo.free.endPlayTime > 0 then
        --     free.lackTimes = 1
        -- end
        if table.empty(adventurousInfo.free.endPlayPoint) == false then
            free.endPlayPoint = adventurousInfo.free.endPlayPoint -- 结束的时候图腾位置
        end
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_124_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_124_hanglie[1].linenum),
        -- 下注索引
        betIndex = adventurousInfo.betIndex,
        -- 全部下注金额
        payScore = adventurousInfo.betMoney,
        -- 已赢的钱
        -- winScore = adventurousInfo.winScore,
        -- W元素存在位置
        wildCol = adventurousInfo.wildCol,
        wildRow = adventurousInfo.wildRow,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = adventurousInfo.iconsAttachData,
        -- 独立调用定义
        features={free = free},
    }
    return res
end