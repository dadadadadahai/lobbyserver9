-- 糖果连连碰游戏模块
module('CandyTouch', package.seeall)
-- 糖果连连碰所需数据库表名称
DB_Name = "game129candytouch"
-- 糖果连连碰通用配置
GameId = 129
S = 70
U = 80
W = 90
NormalIconList = {1,2,3,4,5,10,11,12,13}
DataFormat = {7,7,7,7,7,7,7}    -- 棋盘规格
Table_Base = import "table/game/129/table_129_hanglie"                        -- 基础行列
LineNum = Table_Base[1].linenum
-- 构造数据存档
function Get(gameType,uid)
    -- 获取糖果连连碰模块数据库信息
    local candytouchInfo = unilight.getdata(DB_Name, uid)
    -- 没有则初始化信息
    if table.empty(candytouchInfo) then
        candytouchInfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(DB_Name,candytouchInfo)
    end
    if gameType == nil then
        return candytouchInfo
    end
    -- 没有初始化房间信息
    if table.empty(candytouchInfo.gameRooms[gameType]) then
        candytouchInfo.gameRooms[gameType] = {
            betIndex = 1, -- 当前玩家下注下标
            betMoney = 0, -- 当前玩家下注金额
            boards = {}, -- 当前模式游戏棋盘
            free = {}, -- 免费游戏信息
            iconsAttachData = {}, -- 附加数据 iconB:棋盘B图标信息(位置、倍数)
            BuyFreeNumS = 0,
            -- collect = {}, -- 收集信息
        }
        unilight.update(DB_Name,uid,candytouchInfo)
    end
    return candytouchInfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    -- 获取糖果连连碰模块数据库信息
    local candytouchInfo = unilight.getdata(DB_Name, uid)
    candytouchInfo.gameRooms[gameType] = roomInfo
    unilight.update(DB_Name,uid,candytouchInfo)
end
-- 生成棋盘
function GetBoards(uid,gameId,gameType,isFree,candytouchInfo)
    -- 获取W元素
    local wilds = {}
    wilds[W] = 1
    local nowild = {}
    -- 生成返回数据
    local result={
        boards  ={},
        winScore = 0,
        disInfo = {},
        lastInfo = {}
    }
    local spin = {}
    local betInfo={
        betindex = candytouchInfo.betindex,
        betchips = candytouchInfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    spin = gamecommon.GetSpin(uid, gameId, gameType,betInfo)
    local chessdata,lastColRow = gamecommon.CreateSpecialChessData(DataFormat,spin)
    if isFree then
        chessdata,lastColRow = gamecommon.CreateSpecialChessData(DataFormat,CandyTouch['table_129_free_'..gameType])
    end
    -- -----------------------Test----------------------------
    -- chessdata[1][1] = 3
    -- chessdata[1][2] = 3
    -- chessdata[1][3] = 3
    -- chessdata[1][4] = 3
    -- chessdata[1][5] = 3
    -- chessdata[1][6] = 3
    -- chessdata[1][7] = 3
    -- -----------------------Test----------------------------
    local res = NewOneceLogic(uid,gameId,gameType,isFree,chessdata,lastColRow,spin,candytouchInfo)
    result.tringerPoints = {}
    if isFree then
        -- 棋盘数据保存数据库对象中 外部调用后保存数据库
        candytouchInfo.boards = res.chessdata
        result.tringerPoints.freeTringerPoints = GetFree(candytouchInfo, true)
    else
        -- 如果购买了免费则必须触发免费
        if candytouchInfo.BuyFreeNumS ~= nil and candytouchInfo.BuyFreeNumS > 0 then
            -- 如果购买免费则让他不中奖
            while res.winScore > 0 do
                chessdata,lastColRow = gamecommon.CreateSpecialChessData(DataFormat,spin)
                res = NewOneceLogic(uid,gameId,gameType,isFree,chessdata,lastColRow,spin,candytouchInfo)
            end
            -- 随机出免费图标插入第几列
            local freeIconLines = chessutil.NotRepeatRandomNumbers(1,#res.chessdata,candytouchInfo.BuyFreeNumS)
            -- 遍历插入S图标位置
            for _, freeIconLine in ipairs(freeIconLines) do
                res.chessdata[freeIconLine][math.random(#res.chessdata[freeIconLine])] = S
            end
            -- 重置购买免费状态
            candytouchInfo.BuyFreeNumS = 0
        else
            -- 没有购买免费的情况下判断是否没有中奖 没有中奖则插入假S图标
            if res.winScore == 0 then
                if math.random(10000) <= 1000 then
                    local sNum = math.random(2)
                    local cols = chessutil.NotRepeatRandomNumbers(1,#DataFormat,sNum)
                    local rows = chessutil.NotRepeatRandomNumbers(1,DataFormat[1],sNum)
                    -- 插入假图标
                    for index = 1, sNum do
                        res.chessdata[cols[index]][rows[index]] = S
                    end
                end
            end
        end
        -- 棋盘数据保存数据库对象中 外部调用后保存数据库
        candytouchInfo.boards = res.chessdata
        result.tringerPoints.freeTringerPoints = GetFree(candytouchInfo, false)
    end
    result.boards = res.chessdata
    result.winScore = res.winScore
    result.disInfo = res.disInfo
    result.lastInfo = res.lastInfo
    return result
end

-- 判断是否触发免费
function GetFree(candytouchInfo, isFree)
    -- 存在S列的个数
    local sNum = 0
    -- 触发免费位置
    local freeTringerPoints = {}
    -- 遍历棋盘判断S个数
    for colNum = 1, #candytouchInfo.boards do
        for rowNum = 1, #candytouchInfo.boards[colNum] do
            -- 如果这个位置存在S图标 则S列的次数+1 直接跳转下一列
            if candytouchInfo.boards[colNum][rowNum] == S then
                table.insert(freeTringerPoints,{line = colNum, row = rowNum})
                sNum = sNum + 1
                break
            end
        end
    end
    local freeInfoIndex = 0
    for index, value in ipairs(table_129_freenum) do
        -- 判断是否触发免费
        if sNum >= value.sNum then
            freeInfoIndex = index
        else
            break
        end
    end
    if freeInfoIndex == 0 then
        return {}
    end
    -- 免费中触发则增加次数
    if isFree then
        candytouchInfo.free.totalTimes = candytouchInfo.free.totalTimes + table_129_freenum[freeInfoIndex].freeNum
        candytouchInfo.free.lackTimes = candytouchInfo.free.lackTimes + table_129_freenum[freeInfoIndex].freeNum
    else
        -- 普通则触发免费初始化
        candytouchInfo.free.totalTimes = table_129_freenum[freeInfoIndex].freeNum           -- 总次数
        candytouchInfo.free.lackTimes = table_129_freenum[freeInfoIndex].freeNum            -- 剩余游玩次数
        candytouchInfo.free.tWinScore = 0                                               -- 已经赢得的钱
    end
    return freeTringerPoints
end


--购买免费
function BuyFree(candytouchInfo,uid,betIndex,gameType)
    if table.empty(candytouchInfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    -- 保存下注档次
    candytouchInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_129_hanglie[1].linenum)
    local betgold = betConfig[candytouchInfo.betIndex]                                                       -- 单注下注金额
    local payScore = betgold * table_129_hanglie[1].linenum                                                 -- 全部下注金额

    -- 随机购买配置表档次
    local buyFreeInfo = table_129_freenum[gamecommon.CommRandInt(table_129_freenum, 'pro')]

    -- 购买金额为下注金额一百倍
    payScore = payScore * buyFreeInfo.buyMul
    -- 执行扣费
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,payScore ,"糖果连连碰购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    --入库存
    SuserId.uid = uid
    local addscore =  payScore*(10000-gamestock.GetTaxXs(GameId,gameType))/10000
    local userinfo = unilight.getdata('userinfo', uid)
    local  xTax = payScore - addscore
    -- if userinfo.property.totalRechargeChips>0 and userinfo.point.IsNormal==1 then
    --     gamecommon.IncSelfStockNumByType(GameId, gameType, addscore)
    -- end

    -- 设置购买免费的图标个数
    candytouchInfo.BuyFreeNumS = buyFreeInfo.sNum


    -- 保存数据库信息
    SaveGameInfo(uid,gameType,candytouchInfo)
    --记录系统级流水
    gameDetaillog.updateRoomFlow(GameId,gameType,0,1,payScore,0,userinfo)
    WithdrawCash.ResetWithdawTypeState(uid,0)
    return {
        errno = 0,
    }
end



-- 包装返回信息
function GetResInfo(uid, candytouchInfo, gameType, tringerPoints)
    -- 克隆数据表
    candytouchInfo = table.clone(candytouchInfo)
    tringerPoints = tringerPoints or {}
    -- 模块信息
    local boards = {}
    if table.empty(candytouchInfo.boards) == false then
        boards = {candytouchInfo.boards}
    end
    local free = {}
    if not table.empty(candytouchInfo.free) then
        free = {
            totalTimes = candytouchInfo.free.totalTimes, -- 总次数
            lackTimes = candytouchInfo.free.lackTimes, -- 剩余游玩次数
            tWinScore = candytouchInfo.free.tWinScore, -- 总共已经赢得的钱
            tringerPoints = {tringerPoints.freeTringerPoints} or {},
        }
    end
    local res = {
        errno = 0,
        -- 是否满线
        bAllLine = table_129_hanglie[1].linenum,
        -- 获取玩家下注金额范围 下注配置
        betConfig = gamecommon.GetBetConfig(gameType,table_129_hanglie[1].linenum),
        -- 下注索引
        betIndex = candytouchInfo.betIndex,
        -- 全部下注金额
        payScore = candytouchInfo.betMoney,
        -- 已赢的钱
        -- winScore = candytouchInfo.winScore,
        -- 面板格子数据
        boards = boards,
        -- 附加面板数据
        iconsAttachData = candytouchInfo.iconsAttachData,
        -- 独立调用定义
        features={free = free},
        extraData = {
            doubleMaps = candytouchInfo.doubleMaps
        }
    }
    return res
end