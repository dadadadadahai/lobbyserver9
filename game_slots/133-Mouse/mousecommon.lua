-- 老鼠游戏模块
module('Mouse', package.seeall)
-- 老鼠所需数据库表名称
DB_Name = "game133mouse"
-- 老鼠通用配置
GameId = 133
S = 70
W = 90
B = 6
DataFormat = {3,3,3}    -- 棋盘规格
Table_Base = import "table/game/133/table_133_hanglie"                        -- 基础行列
MaxNormalIconId = 6
LineNum = Table_Base[1].linenum
-- 构造数据存档
-- 构造数据存档
function SetGameMold(uid,demo)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        datainfo = {
            _id = uid, -- 玩家ID
            demo = demo or 0 ,
            gameRooms = {}, -- 游戏类型
        }
    end
    datainfo.demo = demo or 0
    unilight.savedata(DB_Name,datainfo)
end
function GetGameMold(uid)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        datainfo = {
            _id = uid, -- 玩家ID
            demo = 0,
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,datainfo)
    end
    return datainfo.demo or 0 
end
function IsDemo(uid)
    return GetGameMold(uid)  == 1
end
function AddDemoNums(uid)
    local datainfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        dump("nodatainfo")
        return 
    end 
    datainfo.demonum =  datainfo.demonum  and (datainfo.demonum  + 1 ) or 1
    unilight.savedata(DB_Name,datainfo)
    if datainfo.demonum % 50 == 0 then 
        gamecommon.SendGlobalMsgTip(uid,{type = Const.MSGTIP.DEMO})
    end 
end
function Get(gameType,uid)
    -- 获取老鼠模块数据库信息
    local mouseInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(mouseInfo) then
        mouseInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,mouseInfo)
    end
    if gameType == nil then
        return mouseInfo
    end
    local gameType = IsDemo(uid) and gameType*10 or gameType
    -- 没有初始化房间信息
    if table.empty(mouseInfo.gameRooms[gameType]) then
        mouseInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            wildNum = 0, -- 棋盘是否有W图标
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            bonusFlag = false, -- 老鼠模式
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,mouseInfo)
    end
    return mouseInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取老鼠模块数据库信息
    local gameType = IsDemo(uid) and gameType*10 or gameType
    local mouseInfo = unilight.getdata(DB_Name, uid)
    mouseInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,mouseInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,mouseInfo)
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
        betindex = mouseInfo.betIndex,
        betchips = mouseInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    -- 生成异形棋盘
    boards = gamecommon.CreateSpecialChessData(DataFormat,gamecommon.GetSpin(uid,gameId,gameType,betInfo))
    -- 随机是否触发福牛模式
    if mouseInfo.bonusFlag == true or (math.random(10000) <= table_133_bonus[1].pro) or GmProcess("Free") then
        mouseInfo.bonusFlag = true
        -- 初始化保底数量
        mouseInfo.miniNum = mouseInfo.miniNum or 0
        mouseInfo.miniNum = mouseInfo.miniNum + 1
        boards = gamecommon.CreateSpecialChessData(DataFormat,Mouse['table_133_free_'..gameType])
        -- 替换第二列
        local colNum = {2}
        for _, col in ipairs(colNum) do
            for row = 1, DataFormat[col] do
                boards[col][row] = W
            end
        end
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(boards,table_133_payline,table_133_paytable,wilds,nowild)
        -- 如果本轮中奖判断是否够保底
        if table.empty(winlines) == false and mouseInfo.miniNum < 10 then
            local minimumGuaranteeFlag , resboards = GetMinimumGuarantee(gameType, mouseInfo,winlines, uid)
            if minimumGuaranteeFlag then
                boards = resboards
                mouseInfo.miniNum = 0
            end
        end
        if mouseInfo.miniNum >= 10 then
            boards = {{1,1,1},{1,2,2},{1,1,1}}
            mouseInfo.miniNum = 0
        end
    end
    
    -- 计算中奖倍数
    local winlines = gamecommon.WiningLineFinalCalc(boards,table_133_payline,table_133_paytable,wilds,nowild)

    -- 中奖金额
    res.winScore = 0
    -- 触发位置
    res.tringerPoints = {}
    -- 获取中奖线
    res.winlines = {}
    res.winlines[1] = {}
    -- 计算中奖线金额
    for k, v in ipairs(winlines) do
        local addScore = v.mul * mouseInfo.betMoney / table_133_hanglie[1].linenum
        res.winScore = res.winScore + addScore
        table.insert(res.winlines[1], {v.line, v.num, addScore,v.ele})
    end

    -- 棋盘数据保存数据库对象中 外部调用后保存数据库
    mouseInfo.boards = boards
    -- 棋盘数据
    res.boards = boards
    -- 棋盘附加数据
    res.iconsAttachData = mouseInfo.iconsAttachData
    res.extraData = {
        bonusFlag = mouseInfo.bonusFlag,  -- bonus是否触发
    }
    return res
end

-- 判断FreeRespin中途是否满足保底
function GetMinimumGuarantee(gameType, mouseInfo,reswinlines, uid)
    local winScore = 0
    local deficiencyMul = 10
    local userInfo = unilight.getdata('userinfo',uid)
    -- 计算中奖线金额
    for k, v in ipairs(reswinlines) do
        local addScore = v.mul * mouseInfo.betMoney / table_133_hanglie[1].linenum
        winScore = winScore + addScore
    end
    if winScore / mouseInfo.betMoney >= deficiencyMul then
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
        local boards = gamecommon.CreateSpecialChessData(DataFormat,Mouse['table_133_free_'..gameType])
        -- 替换第一列和第三列
        local colNum = {1,3}
        for _, col in ipairs(colNum) do
            for row = 1, DataFormat[col] do
                boards[col][row] = W
            end
        end
        -- 计算中奖倍数
        local winlines = gamecommon.WiningLineFinalCalc(boards,table_133_payline,table_133_paytable,wilds,nowild)
        local winScore = 0
        -- 计算中奖线金额
        for k, v in ipairs(winlines) do
            local addScore = v.mul * mouseInfo.betMoney / table_133_hanglie[1].linenum
            winScore = winScore + addScore
        end
        -- 计算本轮倍数
        local mul = winScore / mouseInfo.betMoney
        -- 如果满足中途的最小保底 则直接返回
        if mul == deficiencyMul then
            if chessuserinfodb.GetAHeadTolScore(uid) + mouseInfo.betMoney * mul < userInfo.point.chargeMax then
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
            if chessuserinfodb.GetAHeadTolScore(uid) + mouseInfo.betMoney * value.mul < userInfo.point.chargeMax then
                -- 返回保底数据
                return true, value.boards

            else
                return false, {}
            end
        end
    end
    if chessuserinfodb.GetAHeadTolScore(uid) + mouseInfo.betMoney * mulRandomList[1].mul < userInfo.point.chargeMax then

        -- 返回保底数据
        return true, mulRandomList[1].boards

    else
        return false, {}
    end
end

-- 包装返回信息
function GetResInfo(uid, mouseInfo, gameType)
    -- 克隆数据表
    mouseInfo = table.clone(mouseInfo)
    -- 模块信息
    local boards = {}
    if table.empty(mouseInfo.boards) == false then
        boards = {mouseInfo.boards}
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_133_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_133_hanglie[1].linenum),
        -- 下注索引
        betIndex = mouseInfo.betIndex,
        -- 全部下注金额
        payScore = mouseInfo.betMoney,
        -- 已赢的钱
        -- winScore = mouseInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = mouseInfo.iconsAttachData,
        extraData = {
            bonusFlag = mouseInfo.bonusFlag,  -- 福牛是否触发
        }
    }
    return res
end