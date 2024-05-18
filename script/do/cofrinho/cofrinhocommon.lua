module('cofrinho',package.seeall)
Table = 'cofrinho'
table_cofrinho_cfg = import 'table/table_cofrinho_cfg'
function Get(uid)
    local datainfo = unilight.getdata(Table,uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            goldRecv = 0,       --待领取金币
            tChange = 0,        --总共转换
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end
--获取存钱罐基础信息
function GetcofrinhoInfoCmd_C(uid,data)
    local datainfo = Get(uid)
    local res={
        errno = 0,
        goldRecv = datainfo.goldRecv,
    }
    return res
end
--领取金币
function RecvSilverCmd_C(uid,data)
    local datainfo = Get(uid)
    local realGold = 0
    if datainfo.goldRecv>0 then
        realGold = datainfo.goldRecv
        datainfo.goldRecv=0
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, realGold, Const.GOODS_SOURCE_TYPE.COFRINHO)
        unilight.update(Table,datainfo._id,datainfo)
    end
    return{
        errno=0,
        goldRecv = datainfo.goldRecv,
        realGold=realGold,
    }
end
-- --结算处理
-- function Settle(datainfo)
--     local lastSellteDay = chessutil.GetMorningDayNo(datainfo.settleTime)
--     local nowDays = chessutil.GetMorningDayNo(os.time())
--     print(datainfo.settleTime,lastSellteDay,nowDays)
--     if nowDays-lastSellteDay==1 then
--         datainfo.settleTime = os.time()
--         datainfo.silverRecv = datainfo.curSilver
--         datainfo.beforlost = datainfo.curSilver
--         datainfo.curSilver= 0
--         if datainfo.silverRecv>table_cofrinho_other[1].silverLimit then
--             datainfo.silverRecv = table_cofrinho_other[1].silverLimit
--         end
--         datainfo.goldRecv = datainfo.curGold
--         datainfo.curGold = 0
--         if datainfo.goldRecv<table_cofrinho_other[1].goldLow then
--             datainfo.goldRecv=0
--         end
--         local goodId = 401
--         -- local goldCharge = datainfo.goldRecv/2
--         local goldCharge = math.floor(datainfo.goldRecv*(table_cofrinho_other[1].goldPrice/100))
--         goldCharge = math.floor(goldCharge/100)
--         goldCharge = goldCharge*100
--         --反推金猪结算
--         local sendres={}
--         sendres['do'] = 'Cmd.CofrinhoSettleCmd_S'
--         sendres['data']={
--             errno = 0,
--             goldRecv = datainfo.goldRecv,
--             silverRecv = datainfo.silverRecv,
--             curGold = datainfo.curGold,
--             curSilver = datainfo.curSilver,
--             goldCharge = goldCharge,
--             goodId = goodId,
--         }
--         unilight.sendcmd(datainfo._id,sendres)
--         unilight.update(Table,datainfo._id,datainfo)
--     elseif nowDays-lastSellteDay~=0 then
--         datainfo.settleTime = os.time()
--         datainfo.silverRecv = 0
--         datainfo.beforlost = 0
--         datainfo.curSilver = 0
--         datainfo.goldRecv = 0
--         datainfo.curGold = 0
--         unilight.update(Table,datainfo._id,datainfo)
--     end
-- end