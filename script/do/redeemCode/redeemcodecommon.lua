module('RedeemCode', package.seeall)
DB_Name = 'redeemcode'
DB_Log_Name = 'redeemcodelog'
local tableMailConfig = import "table/table_mail_config"
-- 领取
function RedeemCodeGet(uid,redeemcodeId)
    -- 玩家信息
    local redeemcodeInfo = unilight.getdata(DB_Name,redeemcodeId)
    if table.empty(redeemcodeInfo) or os.time() > redeemcodeInfo.expiretime or redeemcodeInfo.lackTime <= 0 then
        return
    end
    -- 玩家领取日志信息
    local redeemcodelogInfo = unilight.getdata(DB_Log_Name,uid)
    -- 相同批次标识
    local sameBatchFlag = false
    -- 获取当前日志数据
    local filter = unilight.a(unilight.eq("uid", uid))
    local logInfos = unilight.chainResponseSequence(unilight.startChain().Table(DB_Log_Name).Filter(filter))
	for _,logInfo in ipairs(logInfos) do
		if logInfo.redeemcodeInfo.redeemcodeId == redeemcodeId then
            -- 判断玩家是否本次领取过了
            return
        elseif logInfo.redeemcodeInfo.batch == redeemcodeInfo.batch then
            -- 如果ID不同但是批次相同 添加标识
            sameBatchFlag = true
        end
	end
    -- 判断是否同批次领取过了
    if redeemcodeInfo.batchtype == 0 and sameBatchFlag then
        return
    end
    -- 添加领取日志
    local logInfo = {
        uid = uid,                                  -- 玩家ID
        getTime = os.time(),                        -- 领取时间
        redeemcodeInfo = redeemcodeInfo,            -- 兑换码信息
    }
    -- 减少可领取次数
    redeemcodeInfo.lackTime = redeemcodeInfo.lackTime - 1
    -- 保存信息
    unilight.savedata(DB_Name,redeemcodeInfo)
    -- 保存日志
    unilight.savedata(DB_Log_Name,logInfo)
    -- 增加奖励
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, redeemcodeInfo.gold, Const.GOODS_SOURCE_TYPE.REDEEMCODE)
    -- 保存统计
    local userInfo = unilight.getdata('userinfo',uid)
    userInfo.property.totalredeemcodechips = userInfo.property.totalredeemcodechips + redeemcodeInfo.gold
    unilight.savedata('userinfo',userInfo)
    WithdrawCash.AddBet(uid, redeemcodeInfo.gold)
    local mailInfo = {}
    local mailConfig = tableMailConfig[46]
    mailInfo.charid = uid
    mailInfo.subject = mailConfig.subject
    mailInfo.content = string.format(mailConfig.content,redeemcodeInfo.gold/100)
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
    local res = {
        rewardChips = redeemcodeInfo.gold,
    }
    return res
end
-- 生成一个兑换码
function CreateRedeemCode()
    -- 6-8位随机字母数字 字母都小写
    local redeemCodeString = ''
    -- 随机个数
    -- local longNum = math.random(6,8)
    local longNum = 5
    -- 随机字母个数
    local letterNum = math.random(longNum)
    local stringList = {}
    for i = 1, longNum do
        if i <= letterNum then
            -- 随机字母ASCII码
            local letterAscii = math.random(97,122)
            table.insert(stringList,string.char(letterAscii))
        else
            table.insert(stringList,tostring(math.random(9)))
        end
    end
    -- 生成字符串
    local randomList = chessutil.NotRepeatRandomNumbers(1,#stringList,#stringList)
    for _, point in ipairs(randomList) do
        redeemCodeString = redeemCodeString..stringList[point]
    end
    return redeemCodeString
end
-- 后台添加兑换码
function AddRedeemCode(data)
    local redeemCodeData = {}
    for num = 1, data.codenum do
        local codedata = {
            _id = CreateRedeemCode(),                   -- 兑换码ID
            batch = data.batch,                         -- 兑换码批次
            initTime = os.time(),                       -- 生成时间
            lackTime = data.coderepeatcount,            -- 单个礼包码剩余可使用次数
            totalTime = data.coderepeatcount,           -- 单个礼包码可重复使用次数
            batchtype = data.batchtype,                 -- 同一玩家是否可以多次领取同一批次的不同礼包码  0 不能 1 能
            gold = data.gold,                           -- 金额
            expiretime = data.expiretime,               -- 过期时间
        }
        -- 查询是否存在相同兑换码ID
        local datainfo = unilight.getdata(DB_Name,codedata._id)
        if table.empty(datainfo) then
            -- 没有相同的则添加
            table.insert(redeemCodeData, codedata)
        elseif os.time() > datainfo.expiretime + 7 * 24 * 3600 then
            -- 如果过期了直接替换
            unilight.delete(DB_Name, codedata._id)
            -- 删除后重新插入
            table.insert(redeemCodeData, codedata)
        else
            -- 相同进度减一重新随机
            num = num - 1
        end
    end
    unilight.savebatch(DB_Name, redeemCodeData)
end