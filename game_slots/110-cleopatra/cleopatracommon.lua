module('cleopatra', package.seeall)
Table = 'game110cleopatra'
LineNum = 1
GameId = 110
table_110_normalspin = import 'table/game/110/table_110_normalspin'
table_110_mul = import 'table/game/110/table_110_mul'
table_110_paytable = import 'table/game/110/table_110_paytable'
table_110_jackpot_chips = import 'table/game/110/table_110_jackpot_chips'
table_110_jackpot_add_per = import 'table/game/110/table_110_jackpot_add_per'
table_110_jackpot_bomb = import 'table/game/110/table_110_jackpot_bomb'
-- table_110_jackpot_scale = import 'table/game/110/table_110_jackpot_scale'
table_110_jackpot_bet = import 'table/game/110/table_110_jackpot_bet'
table_mul_gamety1 = import 'table/game/110/table_mul_gamety1'
table_mul_gamety2 = import 'table/game/110/table_mul_gamety2'
table_mul_gamety3 = import 'table/game/110/table_mul_gamety3'
J = 100
-- CLEOPATRA
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
            gameType = 0,
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo, datainfos
end
-- 普通拉动
function Normal(gameId,gameType, betindex, datainfo, datainfos, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    --print('betconfig='..json.encode(betconfig))
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local sTime = os.time()
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip,
        "宙斯1玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    gamecommon.ReqGamePoolBet(gameId, gameType, chip)
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, GameId, gameType, false, datainfo, chip, CommonRotate,nil)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot)==false then
        gamecommon.AddJackpotHisoryTypeOne(datainfos._id,GameId,gameType,result.jackpot.iconNum,result.jackpotChips)
    end
    local winScore =  result.winScore
    -- 执行加入
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        gameId,
        gameType,
        chip,
        remainder+chip,
        remainder+winScore+result.jackpotChips,
        0,
        {type='normal',chessdata = result.chessdata,disInfo=result.disInfo,zmul =result.mulcfg.ID },
        result.jackpot
    )
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore+result.jackpotChips, Const.GOODS_SOURCE_TYPE.CLEOPATRA)
    unilight.update(Table, datainfos._id, datainfos)
    local boards={}
    table.insert(boards,result.chessdata)
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        winLines = {},
        boards = boards,
        iconsAttachData = result.iconsAttachData,
        features={
            jackpot=result.jackpot,
        },
        extraData = {
            disInfo = result.disInfo,
        }
    }
    return res
end
function CommonRotate(uid,gameId, gameType,isfree,datainfo)
    local chip = datainfo.betMoney * LineNum
    local res={
        chessdata = {}, --初始棋盘
        winScore = 0,
        tringerPoints = {},
        jackpotChips = 0,
        jackpot = {},
        disInfo={},
        mulcfg={},
        iconsAttachData={},
        tmul = 0,
    }
    local cols = {5, 5, 5, 5, 5, 5}
    -- local chessdata, lastColRow = gamecommon.CreateSpecialChessData(cols, table_110_normalspin)
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    local cfg,rtp = gamecommon.GetSpin(uid,GameId,gameType,betinfo)
    local chessdata, lastColRow = gamecommon.CreateSpecialChessData(cols,cfg)
    local emptyPos= {}
    for col=1,#chessdata do
        for row=1,#chessdata[col] do
            if chessdata[col][row]<100 then
                table.insert(emptyPos,{col,row})
            end
        end
    end
    if gmInfo.free==1 then
        for col=1,6 do
            local row = math.random(5)
            chessdata[col][row] = 10
        end
    end
    -- 判断出不出倍数图标
    local mulcfg={}
    local table_num = cleopatra['table_mul_gamety'..gameType]
    local table_mul = cleopatra['table_110_mul_'..gameType]
    local num = 0
    local fieldName = 'gailv'..rtp
    local tmptable_mul = table.clone(table_mul)
    if gmInfo.sfree==1 then
        -- mulcfg = table_mul[math.random(2,#table_mul)]
        num = 5
    else
        num = table_num[gamecommon.CommRandInt(table_num,fieldName)].num
        -- num = 4
    end
    for i=1,num do
        local sIndex = gamecommon.CommRandInt(tmptable_mul,fieldName)
        local mcc = tmptable_mul[sIndex]
        -- table.remove(tmptable_mul,sIndex)
        table.insert(mulcfg,mcc)
        -- res.tmul = res.tmul + mcc.ID
    end
    local iconsAttachData = {}
    local jackpot  = {}
    local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(gameId, gameType, datainfo.betindex)
    -- bSucess=true
    -- iconNum = 14
    -- jackpotChips = 5000
    if bSucess then
        jackpot ={
            lackTimes = 0,
            totalTimes=1,
            tWinScore = jackpotChips,
            tringerPoints  = {},
        }
        for i=1,iconNum do
            if #emptyPos>0 then
                local index = math.random(#emptyPos)
                local c,r = emptyPos[index][1],emptyPos[index][2]
                chessdata[c][r] = J
                table.remove(emptyPos,index)
                table.insert(jackpot.tringerPoints,{line=c,row=r})
            end
        end
        local randIcons = {}
        for icon=1,9 do
            for n=1,7 do
                table.insert(randIcons,icon)
            end
        end
        for c=1,#chessdata do
            for r=1,#chessdata[c] do
                if chessdata[c][r]~=J then
                    chessdata[c][r] = gamecommon.ReturnArrayRand(randIcons)
                end
            end
        end
    else
        jackpotChips = 0
    end
    -- --棋盘非中奖图标填充
    -- if bSucess==false then
    --     FillNoWinIconJack(chessdata,iconsAttachData)
    -- end
    local jackfill = gamecommon.FillJackPotIcon:New(6,5,bSucess,gameId)
    local jackNum = jackfill.num
    -- 统计各个图标数量
    local disInfo = {} -- 每步消除的id信息和倍数信息{chessdata=,info={iconid,mul,winScore},{},{}}
    local jnum = 0
    local fbl = IsExistEliminate(chessdata)
    if fbl then
        jnum = math.floor(jackNum*0.7)
    else
        jnum = jackNum
    end
    if jackNum>0 then
        for i=1,jnum do
             local opos =  gamecommon.ReturnArrayRand(emptyPos)
             chessdata[opos[1]][opos[2]] = J
        end
    end
    if table.empty(mulcfg)==false then
        local mulnum = math.random(0,#mulcfg)
        -- mulnum = 0
        for i=1,mulnum do
            local opos =  gamecommon.ReturnArrayRand(emptyPos)
            chessdata[opos[1]][opos[2]] = mulcfg[1].iconid
            table.insert(iconsAttachData,{line = opos[1],
            row = opos[2],
            data = {
                mul = mulcfg[1].mul
            }})
            table.remove(mulcfg,1)
        end
    end
    local EliminateInfo={
        jackNum = jackNum-jnum,
        mulcfg=mulcfg,
    }
    local dchessdata = table.clone(chessdata)
    -- 总中奖倍数
    local bl = EliminateProcess(chessdata, lastColRow, disInfo, chip, uid, gameType,cfg,EliminateInfo)
    while bl do
        bl = EliminateProcess(chessdata, lastColRow, disInfo, chip, uid, gameType,cfg,EliminateInfo)
    end
    local winScore = 0
    for _, value in ipairs(disInfo) do
        for _, v in ipairs(value.info) do
            winScore = winScore + v.winScore
        end
    end
    for _, v in ipairs(iconsAttachData) do
        res.tmul = res.tmul + v.data.mul
    end
    for _, value in ipairs(disInfo) do
        for _,v in ipairs(value.iconsAttachData) do
            res.tmul = res.tmul + v.data.mul
        end
    end
    if res.tmul>0 then
        winScore = winScore*res.tmul
    end
    res.chessdata=dchessdata
    res.winScore = winScore
    res.jackpotChips = jackpotChips
    res.jackpot = jackpot
    res.disInfo=disInfo
    -- res.mulcfg = mulcfg
    res.iconsAttachData = iconsAttachData
    return res
end
-- 消除执行过程
function EliminateProcess(chessdata, lastColRow, disInfo, chip, uid, gameType,cfg,EliminateInfo)
    local statMap = {}
    for col = 1, #chessdata do
        for row = 1, #chessdata[col] do
            statMap[chessdata[col][row]] = statMap[chessdata[col][row]] or 0
            statMap[chessdata[col][row]] = statMap[chessdata[col][row]] + 1
        end
    end 
    local bl = false
    local zidMap = {}
    local info = {}
    for key, val in pairs(statMap) do
        if table_110_paytable[key] ~= nil then
            local paytablekey = table_110_paytable[key]
            local paymul,rval = GetMul(paytablekey,val)
            if paymul ~= nil and paymul > 0 then
                -- 需要消除
                bl = true
                zidMap[key] = 1
                table.insert(info, {
                    iconid = key,
                    mul = paymul,
                    winScore = math.floor(paymul * chip),
					val=rval,
                })
            end
        end
    end
    -- if bl==false then
    --     if statMap[J]~=nil and statMap[J]>=8 then
    --         zidMap[J] = 1
    --         table.insert(info, {
    --             iconid = J,
    --             mul = 0,
    --             winScore = 0,
    --             val = J,
    --         })
    --         bl=true
    --     end
    -- end
    if bl then
        -- 执行消除 输出棋盘
        gamecommon.Eliminate(chessdata, zidMap)
        -- gamecommon.FillZeroChess(chessdata, lastColRow, table_110_normalspin)
        local iconsAttachData = gamecommon.FillZeroChess(chessdata, lastColRow,cfg,EliminateInfo)
        table.insert(disInfo, {
            chessdata = table.clone(chessdata),
            info = info,
            iconsAttachData = iconsAttachData,
        })
    end
    return bl
end
function GetMul(paytablekey,valnum)
    local colobj = {5,6,7,8,11,14,17,21}
    if valnum<colobj[1] then
        return 0,0
    elseif valnum>=colobj[8] then
        return paytablekey['c'..colobj[8]],colobj[8]
    end
    for i=1,7 do
        local colvalmin = colobj[i]
        local colvalmax = colobj[i+1]
        if valnum>=colvalmin and valnum<colvalmax then
            return paytablekey['c'..colvalmin],colvalmin
        end
    end
end

--判断是否有消除
function IsExistEliminate(chessdata)
    local statMap = {}
    for col = 1, #chessdata do
        for row = 1, #chessdata[col] do
            statMap[chessdata[col][row]] = statMap[chessdata[col][row]] or 0
            statMap[chessdata[col][row]] = statMap[chessdata[col][row]] + 1
        end
    end 
    local bl = false
    local zidMap = {}
    local info = {}
    for key, val in pairs(statMap) do
        if table_110_paytable[key] ~= nil then
            local paytablekey = table_110_paytable[key]
            local paymul,rval = GetMul(paytablekey,val)
            if paymul ~= nil and paymul > 0 then
                -- 需要消除
                bl = true
                zidMap[key] = 1
            end
        end
    end
    return bl
end
