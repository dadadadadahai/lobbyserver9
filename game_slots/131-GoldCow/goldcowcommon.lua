-- 金牛游戏模块
module('GoldCow', package.seeall)
-- 金牛所需数据库表名称
DB_Name = "game131goldcow"
-- 金牛通用配置
GameId = 131
S = 70
W = 90
B = 6
DataFormat = {3,4,3}    -- 棋盘规格
Table_Base = import "table/game/131/table_131_hanglie"                        -- 基础行列
MaxNormalIconId = 6
LineNum = Table_Base[1].linenum
-- 构造数据存档
function SetGameMold(uid,demo)
    local goldcowInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(goldcowInfo) then
        goldcowInfo = {
            _id = uid, -- 玩家ID
            demo = demo or 0 ,
            gameRooms = {}, -- 游戏类型
        }
    end
    goldcowInfo.demo = demo or 0
    unilight.savedata(DB_Name,goldcowInfo)
end
function GetGameMold(uid)
    local goldcowInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(goldcowInfo) then
        goldcowInfo = {
            _id = uid, -- 玩家ID
            demo = 0,
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,goldcowInfo)
    end
    return goldcowInfo.demo or 0 
end
function IsDemo(uid)
    return GetGameMold(uid)  == 1
end
function AddDemoNums(uid)
    local goldcowInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(goldcowInfo) then
        dump("nogoldcowInfo")
        return 
    end 
    goldcowInfo.demonum =  goldcowInfo.demonum  and (goldcowInfo.demonum  + 1 ) or 1
    unilight.savedata(DB_Name,goldcowInfo)
    if goldcowInfo.demonum % 50 == 0 then 
        gamecommon.SendGlobalMsgTip(uid,{type = Const.MSGTIP.DEMO})
    end 
end

function Get(gameType,uid)
    -- 获取金牛模块数据库信息
    local goldcowInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(goldcowInfo) then
        goldcowInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,goldcowInfo)
    end
    if gameType == nil then
        return goldcowInfo
    end
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 没有初始化房间信息
    if table.empty(goldcowInfo.gameRooms[gameType]) then
        goldcowInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            bonusFlag = false, -- 金牛模式
            mulFlag = false, -- 十倍
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,goldcowInfo)
    end
    return goldcowInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 获取金牛模块数据库信息
    local goldcowInfo = unilight.getdata(DB_Name, uid)
    goldcowInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,goldcowInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,goldcowInfo)
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
        betindex = goldcowInfo.betIndex,
        betchips = goldcowInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    -- 生成异形棋盘
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    -- 随机是否触发福牛模式
    if goldcowInfo.bonusFlag == true or (math.random(10000) <= table_131_bonusPro[1].pro) or GmProcess("Free") then
        goldcowInfo.bonusFlag = true
        -- 初始化保底数量
        goldcowInfo.miniNum = goldcowInfo.miniNum or 0
        goldcowInfo.miniNum = goldcowInfo.miniNum + 1
        local iconId = table_131_bonusIconPro[gamecommon.CommRandInt(table_131_bonusIconPro, 'pro')].iconId
        boards = gamecommon.CreateSpecialChessData(DataFormat,GoldCow['table_131_free_'..gameType])
        -- 替换第一列和第三列
        local colNum = {1,3}
        for _, col in ipairs(colNum) do
            for row = 1, DataFormat[col] do
                boards[col][row] = iconId
            end
        end
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(boards,table_131_payline,table_131_paytable,wilds,nowild)
        -- 如果本轮中奖判断是否够保底
        if table.empty(winlines) == false and goldcowInfo.miniNum < 10 then
            local minimumGuaranteeFlag , resboards = GetMinimumGuarantee(gameType, goldcowInfo,winlines, uid)
            if minimumGuaranteeFlag then
                boards = resboards
                goldcowInfo.miniNum = 0
            end
        end
        if goldcowInfo.miniNum >= 10 then
            boards = {{1,1,1},{1,2,2,2},{1,1,1}}  
            goldcowInfo.miniNum = 0
        end
    end
    -- 十倍是否触发
    local fullIconFlag = false
    -- 随机本次是否十倍   没有触发福牛模式才进行下面的判断
    if (not goldcowInfo.bonusFlag) and (math.random(10000) <= table_131_mulPro[1].pro or GmProcess("Bonus"))  then
        fullIconFlag = true
        local iconId = table_131_mulIcon[gamecommon.CommRandInt(table_131_mulIcon, 'pro')].iconId
        for col = 1, #DataFormat do
            for row = 1, DataFormat[col] do
                boards[col][row] = iconId
            end
        end
    end


    -- GmProcess(uid, gameId, gameType, boards)

    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_131_payline,table_131_paytable,wilds,nowild)

    -- 假中奖
    if (not goldcowInfo.bonusFlag) and (not fullIconFlag) and #winlines == 0 then
        -- 判断是否假中奖
        if math.random(10000) <= table_131_mulPro[1].spuriousPro or GmProcess("False") then
            local iconId = table_131_mulIcon[gamecommon.CommRandInt(table_131_mulIcon, 'pro')].iconId
            -- 前两列相同图标
            for col = 1, #DataFormat - 1 do
                for row = 1, DataFormat[col] do
                    boards[col][row] = iconId
                end
            end

            local col = DataFormat[#DataFormat]
            for row = 1, DataFormat[col] do
                -- 随机出最后一列图标ID
                local endIconId = math.random(MaxNormalIconId)
                while iconId == endIconId do
                    endIconId = math.random(MaxNormalIconId)
                end
                -- 替换最后一列不同图标
                boards[col][row] = endIconId
            end
        end
    end

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * goldcowInfo.betMoney / table_131_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    -- 十倍判断
    local firstIconId = 0
    local mulFlag = true
    for col = 1, #DataFormat do
        for row = 1, DataFormat[col] do
            if firstIconId == 0 and boards[col][row] ~= W then
                firstIconId = boards[col][row]
            end
            if boards[col][row] ~= W and boards[col][row] ~= firstIconId then
                mulFlag = false
                break
            end
        end
    end
    -- 增加获奖金额
    if mulFlag then
        res.winScore = res.winScore * 10
    end
    goldcowInfo.mulFlag = mulFlag
    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    goldcowInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    -- 棋盘附加数据
    res.iconsAttachData = goldcowInfo.iconsAttachData
    res.extraData = {
        bonusFlag = goldcowInfo.bonusFlag,  -- 福牛是否触发
        fullIconFlag = goldcowInfo.mulFlag,             -- 十倍是否触发
    }
    return res
end

-- 判断FreeRespin中途是否满足保底
function GetMinimumGuarantee(gameType, goldcowInfo,reswinlines, uid)
    local winScore = 0
    local deficiencyMul = 10
    local userInfo = unilight.getdata('userinfo',uid)
    -- 计算中奖线金额
    for k, v in ipairs(reswinlines) do
        local addScore = v.mul * goldcowInfo.betMoney / table_131_hanglie[1].linenum
        winScore = winScore + addScore
    end
    if winScore / goldcowInfo.betMoney >= deficiencyMul then
        return false, {}
    end
    -- 获取倍数列表
    local mulList = {}
    local mulRandomList = {}
    
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}

    for i = 1, 10 do
        -- 重新随机
        local iconId = table_131_bonusIconPro[gamecommon.CommRandInt(table_131_bonusIconPro, 'pro')].iconId
        local boards = gamecommon.CreateSpecialChessData(DataFormat,GoldCow['table_131_free_'..gameType])
        -- 替换第一列和第三列
        local colNum = {1,3}
        for _, col in ipairs(colNum) do
            for row = 1, DataFormat[col] do
                boards[col][row] = iconId
            end
        end
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(boards,table_131_payline,table_131_paytable,wilds,nowild)
        local winScore = 0
        -- 计算中奖线金额
        for k, v in ipairs(winlines) do
            local addScore = v.mul * goldcowInfo.betMoney / table_131_hanglie[1].linenum
            winScore = winScore + addScore
        end
        local mulFlag = true
        -- 十倍判断
        local firstIconId = 0
        for col = 1, #DataFormat do
            for row = 1, DataFormat[col] do
                if firstIconId == 0 and boards[col][row] ~= W then
                    firstIconId = boards[col][row]
                end
                if boards[col][row] ~= W and boards[col][row] ~= firstIconId then
                    mulFlag = false
                    break
                end
            end
        end
        -- 增加获奖金额
        if mulFlag then
            winScore = winScore * 10
        end
        -- 计算本轮倍数
        local mul = winScore / goldcowInfo.betMoney
        -- 如果满足中途的最小保底 则直接返回
        if mul == deficiencyMul then
            if chessuserinfodb.GetAHeadTolScore(uid) + goldcowInfo.betMoney * mul < userInfo.point.chargeMax then
                -- 返回保底数据
                return true ,boards

            else
                return false, {}
            end
        end
        table.insert(mulRandomList,{boards = boards,mul = mul,winScore = winScore})
    end

    -- 十次随机后选择最接近的保底倍数
    table.sort(mulRandomList, function(a, b)
        return deficiencyMul - a.mul > deficiencyMul - b.mul
    end)
    for id, value in ipairs(mulRandomList) do
        if value.mul >= deficiencyMul then
            -- 返回保底数据
            if chessuserinfodb.GetAHeadTolScore(uid) + goldcowInfo.betMoney * value.mul < userInfo.point.chargeMax then
                -- 返回保底数据
                return true, value.boards

            else
                return false, {}
            end
        end
    end
    if chessuserinfodb.GetAHeadTolScore(uid) + goldcowInfo.betMoney * mulRandomList[1].mul < userInfo.point.chargeMax then

        -- 返回保底数据
        return true, mulRandomList[1].boards

    else
        return false, {}
    end
end

-- 包装返回信息
function GetResInfo(uid, goldcowInfo, gameType, tringerPoints)
    -- 克隆数据表
    goldcowInfo = table.clone(goldcowInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(goldcowInfo.boards) == false then
        boards = {goldcowInfo.boards}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_131_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_131_hanglie[1].linenum),
        -- 下注索引
        betIndex = goldcowInfo.betIndex,
        -- 全部下注金额
        payScore = goldcowInfo.betMoney,
        -- 已赢的钱
        -- winScore = goldcowInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = goldcowInfo.iconsAttachData,
        extraData = {
            bonusFlag = goldcowInfo.bonusFlag,  -- 福牛是否触发
            mulFlag = goldcowInfo.mulFlag,  -- 十倍是否触发
        }
    }
    return res
end