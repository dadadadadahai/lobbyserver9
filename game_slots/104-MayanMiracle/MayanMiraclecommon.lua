module('MayanMiracle', package.seeall)
Table = 'game104MayanMiracle'
LineNum = 50
GameId = 104
-- table_MayanMirac_normalspin = import 'table/game/104/table_MayanMirac_normalspin'
table_MayanMiracle_freespin = import 'table/game/104/table_MayanMiracle_freespin'
table_MayanMiracle_other = import 'table/game/104/table_MayanMiracle_other'
table_MayanMiracle_zlowo = import 'table/game/104/table_MayanMiracle_zlowo'
table_MayanMiracle_znumr = import 'table/game/104/table_MayanMiracle_znumr'
table_MayanMiracle_pickn = import 'table/game/104/table_MayanMiracle_pickn'
table_MayanMiracle_paytable = import 'table/game/104/table_MayanMiracle_paytable'
table_MayanMiracle_payline = import 'table/game/104/table_MayanMiracle_payline'
table_MayanMiracle_pick = import 'table/game/104/table_MayanMiracle_pick'

table_MayanMiracle_W = {}

table_MayanMiracle_W[3] = import 'table/game/104/table_MayanMiracle_W3'
table_MayanMiracle_W[4] = import 'table/game/104/table_MayanMiracle_W4'
table_MayanMiracle_W[5] = import 'table/game/104/table_MayanMiracle_W5'
table_MayanMiracle_W[6] = import 'table/game/104/table_MayanMiracle_W6'
table_MayanMiracle_W[7] = import 'table/game/104/table_MayanMiracle_W7'

-- JACKPOT所需数据配置表
table_104_jackpot_chips   = import 'table/game/104/table_104_jackpot_chips'
table_104_jackpot_add_per = import 'table/game/104/table_104_jackpot_add_per'
table_104_jackpot_bomb    = import 'table/game/104/table_104_jackpot_bomb'
-- table_104_jackpot_scale   = import 'table/game/104/table_104_jackpot_scale'
table_104_jackpot_bet     = import 'table/game/104/table_104_jackpot_bet'

DataFormat = {4,4,4,4,4}
MaxNormalIconId = 9
Max = 9
Jackpot = 100
W = 90
S = 70
function Get(gameType, uid)
    local datainfo = unilight.getdata(Table, uid)
    -- 没有则初始化信息
    if table.empty(datainfo) then
        datainfo = {
            _id = uid, -- 玩家ID
            gameRooms = {}, -- 游戏类型
        }
        unilight.savedata(Table,datainfo)
    end
    if gameType == nil then
        return datainfo
    end

    -- local nuserinfo = unilight.getdata('userinfo', uid)
    -- local level = nuserinfo.property.level or 1
    -- if table.empty(datainfo) then
    --     datainfo = {
    --         _id = uid,
    --         betindex = 1,
    --         betMoney = 0,
    --         zRandLack = 0,
    --         zMapInfo = {},
    --         pick = {},
    --         free = {}
    --     }
    --     unilight.savedata(Table, datainfo)
    -- end
    -- if gmInfo.sfree==1 then
    --     level=10
    -- end
    -- return datainfo, level
    local nuserinfo = unilight.getdata('userinfo', uid)
    if table.empty(datainfo.gameRooms[gameType]) then
        datainfo.gameRooms[gameType] = {
            _id = uid,
            betindex = 1,
            betMoney = 0,
            boards = {},
            zRandLack = 0,
            -- zMapInfo = {},
            pick = {},
            free = {}
        }
        unilight.update(Table, uid, datainfo)
    end
    return datainfo.gameRooms[gameType]
end
-- 保存数据存档
function SaveGameInfo(uid,gameType,roomInfo)
    local datainfo = unilight.getdata(Table, uid)
    datainfo.gameRooms[gameType] = roomInfo
    unilight.update(Table,uid,datainfo)
end
function Normal(betIndex, gameType, datainfo, uid)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    local betConfig = gamecommon.GetBetConfig(gameType,LineNum)
    local betMoney = betConfig[betIndex]
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误'
        }
    end
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, chip, "玛雅玩法投注")
    if ok == false then
        return {
            errno = 1,
            desc = '金币不足不能玩游戏'
        }
    end
    gamecommon.ReqGamePoolBet(GameId, gameType, chip)
    datainfo.betindex = betIndex
    datainfo.betMoney = betMoney
    -- local result = CommonRotate(uid, false,datainfo,gameType)
    local result,datainfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,false,datainfo,chip,CommonRotate)
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines={}
    table.insert(winLines,result.winLines)
    local jackpot = {}
    -- 如果中了jackpot
    if result.jackpotChips ~= nil and result.jackpotChips > 0 then
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #result.jackpotTringerPoints, result.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = result.jackpotChips,
            tringerPoints = result.jackpotTringerPoints,
        }
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, result.jackpotChips, Const.GOODS_SOURCE_TYPE.MayanMiracle)
    end
    --构建返回
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        -- payScore = betMoney,
        payScore = chip,
        winScore = result.winScore,
        bAllLine = LineNum,
        winLines = winLines,
        boards = boards,
        extraData={
            -- zinfo = result.zinfo,
            rinfo = result.rinfo,
            dchessdata = result.dchessdata,
        },
        features = {
            bonus = PackPick(datainfo),
            free = PackFree(datainfo),
            jackpot = jackpot,
        }
    }
    -- datainfo.boards = boards
    datainfo.boards = {result.dchessdata}
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, result.winScore, Const.GOODS_SOURCE_TYPE.MayanMiracle)
    -- unilight.update(Table,uid,datainfo)
    SaveGameInfo(uid,gameType,datainfo)
    -- 兑换功能流水金额减少
    -- WithdrawCash.ReduceBet(uid, chip)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = result.chessdata},
        jackpot
    )
    return res
end
function Free(datainfo, gameType, uid)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)

    -- local result = CommonRotate(uid, true,datainfo,gameType)
    local result,datainfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,datainfo,datainfo.betMoney * LineNum,CommonRotate)
    local boards={}
    table.insert(boards,result.chessdata)
    local winLines={}
    table.insert(winLines,result.winLines)
    datainfo.free.tWinScore = datainfo.free.tWinScore + result.winScore
    datainfo.free.lackTimes = datainfo.free.lackTimes - 1
    local jackpot = {}
    -- 如果中了jackpot
    if result.jackpotChips ~= nil and result.jackpotChips > 0 then
        gamecommon.AddJackpotHisory(uid, GameId, gameType, #result.jackpotTringerPoints, result.jackpotChips)
        jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = result.jackpotChips,
            tringerPoints = result.jackpotTringerPoints,
        }
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, result.jackpotChips, Const.GOODS_SOURCE_TYPE.MayanMiracle)
    end
    --构建返回
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        -- payScore = datainfo.betMoney,
        payScore = datainfo.betMoney * LineNum,
        winScore = result.winScore,
        bAllLine = LineNum,
        winLines = winLines,
        boards = boards,
        extraData={
            -- zinfo = result.zinfo,
            rinfo = result.rinfo,
            dchessdata = result.dchessdata,
        },
        features = {
            bonus = PackPick(datainfo),
            free = PackFree(datainfo),
            jackpot = jackpot,
        }
    }
    res.features.free.tringerPoints = result.freeTringerPoints
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.MayanMiracle)
        datainfo.free={}
    end
    -- unilight.update(Table,uid,datainfo)
    -- datainfo.boards = boards
    datainfo.boards = {result.dchessdata}
    SaveGameInfo(uid,gameType,datainfo)
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = result.chessdata,totalTimes=datainfo.free.totalTimes,lackTimes=datainfo.free.lackTimes,tWinScore=datainfo.free.tWinScore},
        jackpot
    )
    return res
end
function Pick(datainfo, gameType, uid)
    local pcfg = table_MayanMiracle_pick[gamecommon.CommRandInt(table_MayanMiracle_pick,'gailv')]
    if pcfg.freenum>0 then
        datainfo.pick.tWinScore = datainfo.pick.tWinScore + pcfg.freenum
    else
        datainfo.pick.totalTimes = datainfo.pick.totalTimes + pcfg.picknum
        datainfo.pick.lackTimes = datainfo.pick.lackTimes + pcfg.picknum
    end
    datainfo.pick.lackTimes = datainfo.pick.lackTimes - 1
    if datainfo.pick.lackTimes<=0 then
        datainfo.free={totalTimes = datainfo.pick.tWinScore,lackTimes=datainfo.pick.tWinScore,tWinScore=0}
    end
    --构建返回
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        -- payScore = datainfo.betMoney,
        payScore = datainfo.betMoney * LineNum,
        winScore = 0,
        bAllLine = LineNum,
        winLines = {},
        boards = {},
        extraData={
            freenum = pcfg.freenum,
            picknum = pcfg.picknum,
        },
        features = {
            bonus = PackPick(datainfo),
            free = PackFree(datainfo),
            jackpot = {},
        }
    }
    if datainfo.pick.lackTimes<=0 then
        datainfo.pick={}
    end
    -- unilight.update(Table,uid,datainfo)
    datainfo.boards = {}
    SaveGameInfo(uid,gameType,datainfo)
    return res
end
function CommonRotate(uid,gameId,gameType, isfree, datainfo)
    -- datainfo.zMapInfo[datainfo.betindex] = datainfo.zMapInfo[datainfo.betindex] or {}
    local res = {
        chessdata = {},
        dchessdata = {},
        winLines = {},
        winScore = 0,
        zinfo = {},
        rinfo={},
        jackpotTringerPoints = {},
        jackpotChips = 0,
    }
    local betInfo = {
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney,
        gameId = gameId,
        gameType = gameType,
    }
    -- res.zinfo = datainfo.zMapInfo[datainfo.betindex]
    local spin = gamecommon.GetSpin(uid,GameId,gameType,betInfo)
    if isfree then
        spin = MayanMiracle['table_MayanMiracle_freespin_'..gameType]
    end
    local cols = {4, 4, 4, 4, 4}
    -- 生成棋盘
    res.chessdata = gamecommon.CreateSpecialChessData(cols, spin)
    GmProcess(uid, GameId, gameType, res.chessdata,datainfo)
    res.dchessdata = table.clone(res.chessdata)

    -- 可插入列表
    local insertList = {}
    local inserCol = {}
    local maxInserCol = {}
    -- 寻找棋盘中的可替换图标
    for colIndex, colValue in ipairs(res.dchessdata) do
        for rowIndex, rowValue in ipairs(colValue) do
            -- 只能替换普通图标
            if rowValue ~= W and rowValue ~= S then
                if insertList[colIndex] == nil then
                    insertList[colIndex] = {}
                    -- 如果他的前一列没有可替换图标则重置累计连续列数
                    if colIndex > 1 and insertList[colIndex - 1] == nil then
                        if #maxInserCol < #inserCol then
                            maxInserCol = inserCol
                        end
                        inserCol = {}
                    end
                    table.insert(inserCol,colIndex)
                end
                table.insert(insertList[colIndex],rowIndex)
            end
        end
    end
    if #maxInserCol < #inserCol then
        maxInserCol = inserCol
    end
    -- 奖池初始化数值
    local jackpotChips = 0
    local bSucess = false
    local iconNum = gamecommon.GetJackpotIconNum(GameId,gameType)
    res.jackpotChips = jackpotChips
    -- 判断是否有资格中Jackpot
    if iconNum > 0 and #maxInserCol >= iconNum then
        -- 获得奖励
        bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, datainfo.betindex)
        -- 获得奖池奖励
        if bSucess and #maxInserCol >= iconNum then
            -- 如果中Jackpot则让他不中奖
            local iconIdList = chessutil.NotRepeatRandomNumbers(1,MaxNormalIconId,2 * #res.dchessdata[1])
            local changNum = 0
            -- 遍历修改棋盘前两列图标 保证其不中奖
            for colNum = 1, 2 do
                for rowNum = 1, #res.dchessdata[colNum] do
                    changNum = changNum + 1
                    -- 替换图标
                    res.dchessdata[colNum][rowNum] = iconIdList[changNum]
                    res.chessdata[colNum][rowNum] = iconIdList[changNum]
                end
            end
            res.jackpotChips = jackpotChips
            local firstIndex = math.random(#DataFormat - iconNum + 1)
            -- 中奖 则替换图标
            for index = firstIndex, (firstIndex + iconNum - 1) do
                -- 随机行数
                local rowRandomIndex = math.random(#insertList[maxInserCol[index]])
                -- 替换图标
                res.chessdata[maxInserCol[index]][insertList[maxInserCol[index]][rowRandomIndex]] = Jackpot
                table.insert(res.jackpotTringerPoints,{line = maxInserCol[index], row = insertList[maxInserCol[index]][rowRandomIndex]})
            end 
        end
    end



    -- local zmap = {}
    -- -- 泡泡往上飘
    -- for index, value in ipairs(res.zinfo) do
    --     value[2] = value[2] + 1
    --     local str = value[1] .. '-' .. value[2]
    --     zmap[str] = 1
    -- end
    -- for i=#res.zinfo,1,-1 do
    --     if res.zinfo[i][2]>4 then
    --         table.remove(res.zinfo,i)
    --     end
    -- end
    -- -- 底部出现泡泡概率
    -- if math.random(10000) <= table_MayanMiracle_other[1].zgailv or gmInfo.respin==1 then
    --     local rcol = table_MayanMiracle_zlowo[gamecommon.CommRandInt(table_MayanMiracle_zlowo, 'gailv')].col
    --     table.insert(res.zinfo, {rcol, 1})
    --     zmap[rcol .. '-1'] = 1
    -- end
    local emptyPos = {}
    -- 触发免费位置
    local freeTringerPoints = {}
    local sNum = 0
    for col = 1, 5 do
        for row = 1, 4 do
            -- local str = col .. '-' .. row
            -- if zmap[str] == nil then
            --     table.insert(emptyPos, {col, row})
            -- end
            if res.chessdata[col][row]==S then
                sNum = sNum + 1
                table.insert(freeTringerPoints,{line = col, row = row})
            end
        end
    end
    -- local zlowbl = false -- 影响结算
    -- if datainfo.betindex > table_MayanMiracle_other[1].zlow then
    --     -- 不随机出
    --     zlowbl = true
    --     local randout = math.random(10000)
    --     datainfo.zRandLack = datainfo.zRandLack - 1
    --     if randout <= table_MayanMiracle_other[1].zoutgailv and datainfo.zRandLack <= 0 then
    --         datainfo.zRandLack = table_MayanMiracle_other[1].zjiange
    --         local zrnum = table_MayanMiracle_znumr[gamecommon.CommRandInt(table_MayanMiracle_znumr, 'gailv')].num
    --         if zrnum > #emptyPos then
    --             zrnum = #emptyPos
    --         end
    --         for i = 1, zrnum do
    --             -- 随机出wild
    --             local posindex = math.random(#emptyPos)
    --             local pos = emptyPos[posindex]
    --             table.remove(emptyPos, posindex)
    --             table.insert(res.zinfo, {pos[1], pos[2]})
    --             table.insert(res.rinfo,{pos[1], pos[2]})
    --         end
    --     end
    -- end
    local randout = math.random(10000)

    if gmInfo.bonus == 1 then
        randout = 10
    end

    datainfo.zRandLack = datainfo.zRandLack - 1
    -- if randout <= table_MayanMiracle_other[1].zoutgailv and datainfo.zRandLack <= 0 then
    local controlvalue = gamecommon.GetControlPoint(uid,betInfo)
    local rtp = gamecommon.GetModelRtp(uid,GameId,gameType,controlvalue)
    local zoutgailv = table_MayanMiracle_other[1].zoutgailv
    if rtp ~= 100 then
        zoutgailv = table_MayanMiracle_other[1]["zoutgailv_"..tostring(rtp)]
    end
    if randout <= zoutgailv and (not bSucess) then
        datainfo.zRandLack = table_MayanMiracle_other[1].zjiange
        local zrnum = table_MayanMiracle_znumr[gamecommon.CommRandInt(table_MayanMiracle_znumr, 'gailv')].num
        -- if zrnum > #emptyPos then
        --     zrnum = #emptyPos
        -- end
        local tableW = table_MayanMiracle_W[zrnum][gamecommon.CommRandInt(table_MayanMiracle_W[zrnum], 'pro')]
        for colNum = 1, 5 do
            local wPoints = chessutil.NotRepeatRandomNumbers(1,4,tableW['w'..colNum])
            for _, rowNum in ipairs(wPoints) do
                table.insert(res.zinfo, {colNum, rowNum})
                table.insert(res.rinfo, {colNum, rowNum})
            end
        end

        -- for i = 1, zrnum do
        --     -- 随机出wild
        --     local posindex = math.random(#emptyPos)
        --     local pos = emptyPos[posindex]
        --     table.remove(emptyPos, posindex)
        --     table.insert(res.zinfo, {pos[1], pos[2]})
        --     table.insert(res.rinfo,{pos[1], pos[2]})
        -- end
    end
    -- 根据wild信息填充棋盘
    FillChessdata(res.chessdata, res.dchessdata, res.zinfo)
    -- 判断是否中jackpot大奖


    
    --计算是否触发S
    if sNum>=3 then
        --触发pick
        if isfree==false then
            datainfo.pick={totalTimes=table_MayanMiracle_pickn[sNum].num,lackTimes=table_MayanMiracle_pickn[sNum].num,tWinScore=0,tringerPoints = freeTringerPoints}
        else
            datainfo.free.totalTimes = datainfo.free.totalTimes+ table_MayanMiracle_pickn[sNum].num
            datainfo.free.lackTimes = datainfo.free.lackTimes+ table_MayanMiracle_pickn[sNum].num
        end
        res.freeTringerPoints = freeTringerPoints
    end
    -- 计算棋盘
    local wild={}
    wild[W] = 1
    local nowild={}
    nowild[S] = 1
    local jackFill = gamecommon.FillJackPotIcon:New(5,4,bSucess,GameId)
    local resdata = gamecommon.WiningLineFinalCalc(res.dchessdata,table_MayanMiracle_payline,table_MayanMiracle_paytable,wild,nowild)
    for _, value in ipairs(resdata) do
        local betmoney = datainfo.betMoney
        
        -- if zlowbl then
            --     betmoney = math.floor(betmoney *(table_MayanMiracle_other[1].zrandgailv/100))
            -- end
            betmoney = math.floor(betmoney *(table_MayanMiracle_other[1].zrandgailv/100) * 100) / 100
            
            table.insert(res.winLines,{value.line,value.num,betmoney * value.mul,value.ele})
            res.winScore = res.winScore + betmoney * value.mul
            jackFill:PreWinData(value.winicon)
    end
    -- 遍历刨除S图标
    if table.empty(freeTringerPoints) == false then
        for _, v in ipairs(freeTringerPoints) do
            jackFill:FillExtraIcon(v.line,v.row)
        end
    end
    jackFill:CreateFinalChessData(res.chessdata,Jackpot)
    return res
end
function FillChessdata(chessdata, dchessdata, zinfo)
    for _, value in ipairs(zinfo) do
        dchessdata[value[1]][value[2]] = W
        -- if chessdata[value[1]][value[2]] == Max then
        --     -- 周围全部变wild
        --     ChangeWRound(value[1], value[2], dchessdata)
        -- end
    end
end
function ChangeWRound(col, row, dchessdata)
    local cols = {col - 1, col, col + 1}
    local rows = {row - 1, row, row + 1}
    for _, c in ipairs(cols) do
        if c > 0 and c <= 5 then
            for _, r in ipairs(rows) do
                if r > 0 and r <= 4 then
                    dchessdata[c][r] = W
                end
            end
        end
    end
end
