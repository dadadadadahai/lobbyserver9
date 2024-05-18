module('gameDetaillog',package.seeall)
Table = 'gameMatchLog'      --游戏对局日志
DayTable = 'gameDayStatistics'      --按天统计
prcentRtpMap = {}


local table_parameter_parameter = import 'table/table_parameter_parameter'
local table_stock_tax = import 'table/table_stock_tax'
local table_game_list = import 'table/table_game_list'
--获取一个唯一id
-- local gogalBetChip,gogalWin = 0,0
--[[
    sTime 开始时间
    eTime 结束时间
    betChip 下注金币
    bChip  开始前金币
    aChip  开始后金币
    winmul 赢倍数
    tax 手续费
    gamechessinfo 游戏详细信息  
    [   slots
        type={
            free,respin,normal.......
        }
        {type,chessdata,}
    ]
    jackpotinfo 爆池详细信息
]]
--游戏详细日志记录
--库存影响
function SaveDetailGameLog(uid,sTime,gameId,gameType,betChip,bChip,aChip,tax,gamechessinfo,jackpotinfo)
    local userinfo = unilight.getdata('userinfo',uid)
    if gamechessinfo.chessdata~=nil then
        gamechessinfo.chessdata = nil
    end
    local data={
        _id = go.newObjectId(),
        uid = uid,
        sTime = sTime,
        eTime = os.time(),
        gameId = gameId,
        gameType = gameType,
        betChip = betChip,
        bChip = bChip,
        aChip = aChip,
        tax = tax,
        gamechessinfo = gamechessinfo,
        jackpotinfo = jackpotinfo,
        table = 'gameMatchLog',
    }
    if userinfo.property.totalRechargeChips>0 or true then
        print('unilight.savedatasyn true')
        if unilight.getdebuglevel() > 0 then
            unilight.savedatasyn(Table,data)
        else
            go.logRpc.SaveLogData(json.encode(encode_repair(data)))
        end
    end
    local tbetchip = 0
    if type(betChip)=='table' then
        for _, value in ipairs(betChip) do
            tbetchip = tbetchip + value
        end
    else
        tbetchip = betChip
    end
    local sysWinScore=0
    local gamecount= 1
    if gameId==201 and gamechessinfo.type=='getMoney' then
        gamecount=0
    end
    if gameId==201 and gamechessinfo.type=='normal' and gamechessinfo.isFirst==false then
        tbetchip=0
    end
    if gamechessinfo.type~='normal' and gamechessinfo.type~='FanBei' and gamechessinfo.type~='normalRespin' then
        tbetchip = 0
    end
    if gamechessinfo.type=='bonus' then
        tbetchip = 0
    end
    if gamechessinfo.type=='freeNormal' then
        tbetchip = 0
    end

    --bchip=500 下注前的钱 , aChip 422 下注后的钱  betChip = 100
    if aChip-bChip<0 then
        if aChip-bChip>-tbetchip then
            sysWinScore = math.abs(aChip-bChip+tbetchip)
        else
            sysWinScore =0
        end
    else
        sysWinScore = math.abs(aChip-bChip+tbetchip)
    end
    --记录系统级流水
    updateRoomFlow(gameId,gameType,tax,gamecount,tbetchip,sysWinScore,userinfo)
    local gameIds={101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150}
    for _, value in ipairs(gameIds) do
        if value==gameId then
            userinfo.gameData.slotsCount = userinfo.gameData.slotsCount + 1
            unilight.update('userinfo',userinfo._id,userinfo)
            break
        end
    end
    toBetCoin(userinfo,tbetchip)
    -- 流水返利
    rebate.AddRebateListChips(data._id,uid,tbetchip)
    rebate.IsValidinVite(uid)
    rebate.IsFreeValidinVite(uid)
    -- nvipmgr.AddLostGold(uid,tbetchip,sysWinScore)
    if userinfo.property.totalRechargeChips > 0 then
        DayBetMoney.AddDayBetMoney(uid,tbetchip)
    end
    if tbetchip > 0 then
        nTask.AddTaskNum(uid,5,1)
    end
    if sysWinScore > 0 then
        nTask.AddTaskNum(uid,6,sysWinScore)
        nTask.AddTaskNum(uid,7,math.floor(sysWinScore/tbetchip))
    end
end
--记录房间流水
function updateRoomFlow(gameId,gameType,tax,gamecount,tbetchip,sysWinScore,userinfo)
    --if userinfo.property.totalRechargeChips<=0 then
     --   return
   -- end
    local subplatid = 1
    local keyval = gameId*1000000+ unilight.getzoneid() * 1000 + subplatid * 10 + gameType
    local type = 2   --非付费

    if userinfo.property.presentChips>0 then
        type=CodingPlayerType(userinfo)
    elseif userinfo.property.totalRechargeChips>0 and userinfo.property.totalRechargeChips<=3000 then
        type=4 --低充值玩家
    elseif userinfo.property.totalRechargeChips>3000 then
        type=1 --其余玩家
    end
    
    local curdaytimestamp = chessutil.ZeroTodayTimestampGet()
    local online = annagent.GetOnlineNumByGameId(gameId, gameType)

    if unilight.getdebuglevel() > 0 then
        local sdata =  unilight.getByFilter(DayTable,unilight.a(unilight.eq('keyval',keyval),unilight.eq('daytimestamp',curdaytimestamp),unilight.eq('type',type)),1)
        if table.empty(sdata) then
            --需要插入
            local idata={
                _id = go.newObjectId(),
                keyval = keyval,            --游戏id*10000+gameType 10109
                gameId = gameId,
                gameType = gameType,
                daytimestamp = curdaytimestamp,--当日零点时间戳
                tax = tax,                  --当日总抽水
                gamecount = gamecount,      --当日总游戏次数
                tchip = tbetchip,    --当日总下注
                -- twin = aChip - bChip,    --当日总输赢
                twin = sysWinScore,             --玩家赢的钱
                tAttenuation = 0,            --累计衰减值,抽水值
                type=type,                  --1受库存影响， 2不受库存影响
                online = online,                 --在线玩家数量
                subplatid = subplatid,      --子渠道id 
                classType = table_game_list[gameId * 10000 + gameType].gameType, --游戏类别
            }
            -- SetBetWin(gameId,gameType,type,tbetchip,sysWinScore)
            unilight.savedata(DayTable,idata)
        else
            local idata = sdata[1]
            idata.tax = idata.tax + tax
            idata.gamecount = idata.gamecount + gamecount
            idata.tchip = idata.tchip + tbetchip
            idata.twin = idata.twin + sysWinScore
            idata.online = online
            -- idata['']=nil
            --执行更新
            tbetchip = idata.tchip
            sysWinScore = idata.twin
            -- SetBetWin(gameId,gameType,type,tbetchip,sysWinScore)
            unilight.savedata(DayTable,idata)
        end
        if type==1 then
            prcentRtpMap[keyval] = {daytimestamp=curdaytimestamp,tchip=tbetchip,twin=sysWinScore}
        end
        --插入日志服
    else
        --需要插入
        local idata={
            _id = go.newObjectId(),
            keyval = keyval,            --游戏id*10000+gameType 10109
            gameId = gameId,
            gameType = gameType,
            daytimestamp = curdaytimestamp,--当日零点时间戳
            tax = tax,                  --当日总抽水
            gamecount = gamecount,      --当日总游戏次数
            tchip = tbetchip,    --当日总下注
            twin = sysWinScore,             --玩家赢的钱
            tAttenuation = 0,            --累计衰减值,抽水值
            type=type,                  --1受库存影响， 2不受库存影响
            online = online,                 --在线玩家数量
            subplatid = subplatid,      --子渠道id 
            classType = table_game_list[gameId * 10000 + gameType].gameType, --游戏类别
            table=DayTable,
        }
        go.logRpc.SaveLogData(json.encode(encode_repair(idata)))
        if type==1 then
            if prcentRtpMap[keyval]==nil then
                prcentRtpMap[keyval] = {daytimestamp=curdaytimestamp,tchip=tbetchip,twin=sysWinScore}
                local sdata =  unilight.getByFilter(DayTable,unilight.a(unilight.eq('keyval',keyval),unilight.eq('daytimestamp',curdaytimestamp),unilight.eq('type',1)),1)
                if table.empty(sdata)==false then
                    local idata = sdata[1]
                    prcentRtpMap[keyval] = {daytimestamp=curdaytimestamp,tchip=idata.tchip+tbetchip,twin=idata.twin+sysWinScore}
                    return
                end
            end
            local obj  = prcentRtpMap[keyval]
            if obj.daytimestamp==curdaytimestamp then
                prcentRtpMap[keyval].tchip = prcentRtpMap[keyval].tchip + tbetchip
                prcentRtpMap[keyval].twin = prcentRtpMap[keyval].twin+sysWinScore
            else
                prcentRtpMap[keyval] = {daytimestamp=curdaytimestamp,tchip=tbetchip,twin=sysWinScore}
            end
        end
    end
end


--记录累计衰减值
function AttenuationVal(gameId,gameType,rdecval)

end
