--处理获取Vip信息
local tableMailConfig   = require "table/table_mail_config"

Net.CmdVipInfoCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.VipInfoCmd_S"
    local uid = laccount.Id

    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    --获取vip的配置表数据
    tableVipConfig = require "table/table_vip_coefficient"

    --下一等级vip所需的总经验
    local nextScore = tableVipConfig[userInfo.property.vipLevel + 1]["vipScore"]
    local buffId = Const.BUFF_TYPE_ID.VIP_LIMIT
    --获取vip限时体验卡的剩余时间
    local remainTime = vipCoefficientMgr.RemainTimeForLimitVip(uid, buffId)
    if remainTime > 0 then
        res["data"] = {
            vipLevel = userInfo.property.vipLevel,
            curVipExp = userInfo.property.vipExp,
            nextLevelExp = nextScore,
            vipLimitCardLevel = userInfo.property.vipLevel + 1,
            vipLimitCardRemainingTime = remainTime,
            desc = "ok"
        }
    else
        res["data"] = {
            vipLevel = userInfo.property.vipLevel,
            curVipExp = userInfo.property.vipExp,
            nextLevelExp = nextScore,
            desc = "体验卡过期或不存在",
        }
    end
    return res
end

--处理粉丝页奖励的领取
Net.CmdVipFansRewardCmd_C = function(cmd, laccount)
    local fensRewardConfig = require "table/table_vip_week_basedata"
    local res = {}
    res["do"] = "VipFansRewardCmd_S"
    local uid = laccount.Id
    --获取玩家数据
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local lastTime = userInfo.property.lastVipFensRewardGetTime
    if os.time() - lastTime < fensRewardConfig[1]["intervalDay"] * 24 * 3600 and lastTime > 0 then
        --领奖时间未到
        res["data"] = {
            desc = "领奖时间未到"
        }
    elseif os.time() - lastTime >= fensRewardConfig[1]["intervalDay"] and os.time() - lastTime > (fensRewardConfig[1]["intervalDay"] + fensRewardConfig[1]["validDay"]) * 24 * 3600 and lastTime > 0 then
        --超过领奖期限
        res["data"] = {
            desc = "超过领奖期限"
        }
    elseif os.time() - lastTime >= fensRewardConfig[1]["intervalDay"] and os.time() - lastTime <= (fensRewardConfig[1]["intervalDay"] + fensRewardConfig[1]["validDay"]) * 24 * 3600 and lastTime > 0 then
        res["data"] = {
            desc = "领取粉丝奖励成功",
        }
        --发送邮件
        local mailInfo = {}
        
        local mailConfig = tableMailConfig[7]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = mailConfig.content
        mailInfo.type = 0 --0是个人邮件
        mailInfo.attachment = {}
        mailInfo.extData = {configId=mailConfig.ID}
        for _, rewardInfo in pairs(fensRewardConfig[1]["fansReward"]) do
            table.insert(mailInfo.attachment,{itemId=rewardInfo.goodId, itemNum=rewardInfo.goodNum})
        end
        ChessGmMailMgr.AddGlobalMail(mailInfo)

        userInfo.property.lastVipFensRewardGetTime = os.time()--设置奖励领取时间
        chessuserinfodb.WUserInfoUpdate(uid, userInfo)
    end

    return res
end