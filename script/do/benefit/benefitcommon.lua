module('benefit',package.seeall)
table_nvip_level = import 'table/table_nvip_level'
Table = 'benefit'
TableLog = 'benefitLog'
--BENEFIT
function Get(uid)
    local datainfo = unilight.getdata(Table,uid)
    if table.empty(datainfo) then
        datainfo={
            _id=uid,
            recvTime = 0,
            -- recvMoney = 0,
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end
--获取救济金基本信息
function GetBenefitInfoCmd_C(uid,data)
    local datainfo = Get(uid)
    local vipLevel = nvipmgr.GetVipLevel(uid)
    local money = 0
    for _,value in ipairs(table_nvip_level) do
        if value.vipLevel==vipLevel then
            money = value.money
            break
        end
    end
    if money==0 and vipLevel>=table_nvip_level[#table_nvip_level].vipLevel then
        money = table_nvip_level[#table_nvip_level].money
    end
    -- money = money * 100
    local updateTime = os.time()
    if datainfo.recvTime == 0 then
        updateTime = 0
    else
        updateTime = chessutil.ZeroTodayTimestampGet(datainfo.recvTime) + (3600 * 24)
    end
    return{
        errno = 0,
        money = money,
        recvTime = datainfo.recvTime,
        updateTime = updateTime,
    }
end
--领取救济金
function RecvBenefitCmd_C(uid,data)
    local datainfo = Get(uid)
    local lastDay = chessutil.GetMorningDayNo(datainfo.recvTime)
    local nowDay = chessutil.GetMorningDayNo(os.time())
    if nowDay==lastDay then
        return {
            errno = ErrorDefine.BENEFIT_RECVED,
            -- desc='已领取过救济金'
        }
    end
    local chips 	= chessuserinfodb.RUserChipsGet(uid)
    if chips>=200 then
        return{
            errno = ErrorDefine.BENEFIT_GTMIN,
            -- desc='余额大于最低领取金额'
        }
    end
    local vipLevel = nvipmgr.GetVipLevel(uid)
    local money = 0
    for _,value in ipairs(table_nvip_level) do
        if value.vipLevel==vipLevel then
            money = value.money
            break
        end
    end
    if money==0 and vipLevel>=table_nvip_level[#table_nvip_level].vipLevel then
        money = table_nvip_level[#table_nvip_level].money
    end
    -- money = money*100
    --WithdrawCash.AddBet(uid, money)
    datainfo.recvTime = os.time()
    -- 赠送金币
    chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, money, "救济金")
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, money, Const.GOODS_SOURCE_TYPE.BENEFIT)
    unilight.update(Table,datainfo._id,datainfo)
    --保存日志
    local log = {_id = uid,recvTime = datainfo.recvTime,chip=money}
    unilight.savedata(TableLog,log)
    local updateTime = os.time()
    if datainfo.recvTime == 0 then
        updateTime = 0
    else
        updateTime = chessutil.ZeroTodayTimestampGet(datainfo.recvTime) + (3600 * 24)
    end
    return{
        errno = 0,
        money = money,
        recvTime = datainfo.recvTime,
        updateTime = updateTime
    }
end