module('LuckyPlayer', package.seeall) 

table_luckyplayer_chips = import "table/table_luckyplayer_chips"
DB_Log_Name = 'luckyplayerlog'
local tableMailConfig = import "table/table_mail_config"
UserList = {}
-- 发放奖励
function GetInviteRouletteInfo(min,max,batch)
    -- 请求发放奖励
    if table.empty(UserList) then
        return false
    end
    -- 范例     一组[452***12 R$99.99, ]
    local mailFormat = ""
    for id, user in ipairs(UserList) do
        local addChips = math.random(min,max)
        -- 增加奖励
        BackpackMgr.GetRewardGood(user._id, Const.GOODS_ID.GOLD, addChips, Const.GOODS_SOURCE_TYPE.LUCKYPLAYER)
        -- 保存统计
        local userInfo = unilight.getdata('userinfo',user._id)
        userInfo.property.totalluckplayerchips = userInfo.property.totalluckplayerchips + addChips
        unilight.savedata('userinfo',userInfo)
        WithdrawCash.AddBet(user._id, addChips)
        -- 添加日志
        local logInfo = {
            uid         = user._id,                                                     -- 玩家id
            batch   	= batch,                                                        -- 发放批次
            date   	    = os.time(),                                                    -- 发放时间
            phone 		= unilight.getdata('userinfo',user._id).base.plataccount,       -- 手机号
            allcharge 	= user.sumPrice or 0,                                           -- 近1月累计充值
            gold 		= addChips,                                                     -- 发放金额
        }
        unilight.savedata(DB_Log_Name,logInfo)
        -- 组装邮件信息
        local userid = ""
        if string.len(tostring(user._id)) >= 5 then
            userid = userid..string.sub(tostring(user._id), 1, 3)
            userid = userid.."***"
            userid = userid..string.sub(tostring(user._id), -2, -1)
        else
            userid = userid..tostring(user._id)
        end
        if id == #UserList then
            mailFormat = mailFormat..userid.." R$"..tostring(addChips/100)
        else
            mailFormat = mailFormat..userid.." R$"..tostring(addChips/100)..", "
        end
    end
    -- 发送邮件                                     ----------------------------- 全局发送 -----------------------------
    local mailInfo = {}
    local mailConfig = tableMailConfig[45]
    -- mailInfo.charid = _id
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,#UserList,mailFormat)
    mailInfo.type = 2
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
    -- 清空数据
    UserList = {}
    return true
end

-- 满足条件人数
function GetPlayerCount(begintime,endtime,lowcharge,topcharge)
    -- 支付完成已经下发
    local filter = '"status":{"$eq":2}'
    if begintime ~= nil and begintime ~= '' and endtime ~= nil and endtime ~= '' then

        -- 满足时间
        filter = filter..',"backTime":{"$gte":'..begintime..', "$lte":'..endtime..'}'
    end
    if lowcharge ~= nil and lowcharge ~= '' and topcharge ~= nil and topcharge ~= '' then
        UserList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{'..filter..'}}','{"$group":{"_id":"$uid", "sumPrice":{"$sum":"$backPrice"}}}','{"$match":{"sumPrice": {"$gte":'..lowcharge..', "$lte":'..topcharge..'}}}'))
        return table.len(UserList)
    else
        UserList = unilight.chainResponseSequence(unilight.startChain().Table("orderinfo").Aggregate('{"$match":{'..filter..'}}','{"$group":{"_id":"$uid"}}'))
        return table.len(UserList)
    end
end