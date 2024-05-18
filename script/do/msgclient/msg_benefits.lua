-- 救济金消息   相关处理

-- 玩家大厅请求协议
Net.CmdUserBenefitsInfoRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.UserBenefitsInfoReturnBenefitsCmd_S"
    local uid = laccount.Id
    local benefitsInfo = Benefits.CmdUserBenefitsInfoGet(uid)
    res["data"] = {
        cashRouletteRefreshTime = benefitsInfo.cashRouletteRefreshTime,
        goldTreasureChestRefreshTime = benefitsInfo.goldTreasureChestRefreshTime,
        silverTreasureChestRefreshTime = benefitsInfo.silverTreasureChestRefreshTime,
        cashRouletteNbr = benefitsInfo.cashRouletteNbr,
        amplificationInfo = benefitsInfo.amplificationInfo,
        noobGuide = benefitsInfo.noobGuide,
        vipBonusCoefficient = benefitsInfo.vipBonusCoefficient,
    }
    return res
end
-- 玩家访问领奖功能页面客户端请求
Net.CmdAccessPrizeRequestBenefitsCmd_C = function(cmd, laccount)
    
    local res = {}
    res["do"] = "Cmd.AccessPrizeReturnBenefitsCmd_S"
    local uid = laccount.Id
    local benefitsInfo = Benefits.BenefitsAccessPrize(uid)
    res["data"] = {
        cashRouletteMinPrize = benefitsInfo.cashRouletteMinPrize,
        cashRouletteMaxPrize = benefitsInfo.cashRouletteMaxPrize,
        goldTreasureChestMinPrize = benefitsInfo.goldTreasureChestMinPrize,
        goldTreasureChestMaxPrize = benefitsInfo.goldTreasureChestMaxPrize,
        silverTreasureChestMinPrize = benefitsInfo.silverTreasureChestMinPrize,
        silverTreasureChestMaxPrize = benefitsInfo.silverTreasureChestMaxPrize,
        clubCoefficient = benefitsInfo.clubCoefficient,
    }
    return res
end
-- 玩家新手引导完成请求
Net.CmdNoobGuideRequestBenefitsCmd_C = function(cmd, laccount)
    local uid = laccount.Id
    Benefits.NoobGuide(uid)
end
-- 玩家进入现金轮盘时发送的相关信息
Net.CmdCashRouletteInfoRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.CashRouletteInfoReturnBenefitsCmd_S"
    local uid = laccount.Id
    local cashRouletteInfo = CashRoulette.PlayCashRouletteInfo(uid)
    -- 如果付费返回付费相关信息 否则返回免费信息
    if whetherPay then
        res["data"] = {
            vipBonusCoefficient = cashRouletteInfo.vipBonusCoefficient,
            cashRouletteRewardListPoint = cashRouletteInfo.cashRouletteRewardListPoint,
            basedAmount = cashRouletteInfo.basedAmount,
            clubCoefficient = cashRouletteInfo.clubCoefficient,
            scoreboardLevel = cashRouletteInfo.scoreboardLevel,
            finalAmount = cashRouletteInfo.finalAmount,
            
            advancedRouleteRatio = cashRouletteInfo.advancedRouleteRatio,
            advancedRouletePurchaseAmount = cashRouletteInfo.advancedRouletePurchaseAmount,
            whetherPay = cashRouletteInfo.whetherPay,
            gameProgress = cashRouletteInfo.gameProgress,
            shopId = cashRouletteInfo.shopId,
            levelXS = cashRouletteInfo.levelXS,
        }
        return res
    end
    res["data"] = {
        vipBonusCoefficient = cashRouletteInfo.vipBonusCoefficient,
        amplificationRatio = cashRouletteInfo.amplificationRatio,
        cashRouletteRewardListPoint = cashRouletteInfo.cashRouletteRewardListPoint,
        basedAmount = cashRouletteInfo.basedAmount,
        clubCoefficient = cashRouletteInfo.clubCoefficient,
        scoreboardLevel = cashRouletteInfo.scoreboardLevel,
        finalAmount = cashRouletteInfo.finalAmount,
        advancedRouleteRatio = cashRouletteInfo.advancedRouleteRatio,
        advancedRouletePurchaseAmount = cashRouletteInfo.advancedRouletePurchaseAmount,
        whetherPay = cashRouletteInfo.whetherPay,
        gameProgress = cashRouletteInfo.gameProgress,
        shopId = cashRouletteInfo.shopId,
        levelXS = cashRouletteInfo.levelXS,
    }
    return res
end
-- 现金轮盘开始转动
Net.CmdCashRouletteTurnRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.CashRouletteTurnReturnBenefitsCmd_S"
    local uid = laccount.Id
    CashRoulette.CashRouletteTurn(uid)
    res["data"] = {

    }
    return res
end
-- 现金轮盘旋转结束玩家确认领取奖励
Net.CmdCashRouletteGetRewardsRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.CashRouletteGetRewardsReturnBenefitsCmd_S"
    local uid = laccount.Id
    local cashRouletteInfo = CashRoulette.CashRouletteGetRewards(uid)
    res["data"] = {
        advancedRouleteRatio = cashRouletteInfo.advancedRouleteRatio,
        advancedRouletePurchaseAmount = cashRouletteInfo.advancedRouletePurchaseAmount,
        shopId = cashRouletteInfo.shopId
    }
    return res
end
-- 现金轮盘完全退出
Net.CmdCashRouletteEndRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.CashRouletteEndReturnBenefitsCmd_S"
    local uid = laccount.Id
    local cashRouletteInfo = CashRoulette.EndCashRoulette(uid)
    res["data"] = {
        cashRouletteOtherReward = cashRouletteInfo.cashRouletteOtherReward,
        cashRouletteRefreshTime = cashRouletteInfo.cashRouletteRefreshTime,
    }
    return res
end
-- 现金宝箱领取
Net.CmdCashTreasureChestInfoRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.CashTreasureChestInfoReturnBenefitsCmd_S"
    local uid = laccount.Id
    local cashTreasureChestCategory = cmd.data.cashTreasureChestCategory
    local cashTreasureChestInfo = CashTreasureChest.CashTreasureChestGetRewards(uid, cashTreasureChestCategory)
    res["data"] = {
        treasureChestRefreshTime = cashTreasureChestInfo.treasureChestRefreshTime,
        basedAmount = cashTreasureChestInfo.basedAmount,
        vipBonusCoefficient = cashTreasureChestInfo.vipBonusCoefficient,
        amplificationRatio = cashTreasureChestInfo.amplificationRatio,
        clubCoefficient = cashTreasureChestInfo.clubCoefficient,
        finalAmount = cashTreasureChestInfo.finalAmount,
        scoreboardLevel = cashTreasureChestInfo.scoreboardLevel,
    }
    return res
end
-- 玩家进入超级奖金游戏界面客户端请求
Net.CmdSuperBonusInfoRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.SuperBonusInfoReturnBenefitsCmd_S"
    local uid = laccount.Id
    local currentNumber = cmd.data.currentNumber
    local superBonusInfo = SuperBonus.SuperBonusInfoGet(uid, currentNumber)
    res["data"] = {
        firstMessage = superBonusInfo.firstMessage,
        bonusCoefficient = superBonusInfo.bonusCoefficient,
        bonusNbr = superBonusInfo.bonusNbr,
        whetherPay = superBonusInfo.whetherPay,
        basedAmount = superBonusInfo.basedAmount,
        currentNumber = superBonusInfo.currentNumber,
        gameProgress = superBonusInfo.gameProgress,
        shopId = superBonusInfo.shopId,
        payMaxAmount = superBonusInfo.payMaxAmount,
        payNbr = superBonusInfo.payNbr,
        maxFinalAmount = superBonusInfo.maxFinalAmount,
    }
    return res
end
-- 超级奖金领取时客户端请求
Net.CmdSuperBonusReceiveRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.SuperBonusReceiveReturnBenefitsCmd_S"
    local uid = laccount.Id
    local superBonusInfo = SuperBonus.SuperBonusGetReward(uid)
    res["data"] = {
        finalAmount = superBonusInfo.finalAmount,
        basedCoefficient = superBonusInfo.basedCoefficient,
        vipBonusCoefficient = superBonusInfo.vipBonusCoefficient,
        otherCoefficient = superBonusInfo.otherCoefficient,
        basedAmount = superBonusInfo.basedAmount,
    }
    return res
end
-- 超级奖金奖励客户端请求
Net.CmdSuperBonusRewardRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.SuperBonusRewardReturnBenefitsCmd_S"
    local uid = laccount.Id
    local superBonusInfo = SuperBonus.PlayerGetReward(uid)
    res["data"] = {
        basedAmount = superBonusInfo.basedAmount,
    }
    return res
end
-- 超级奖金游玩确认关闭客户端请求
Net.CmdSuperBonusCloseRequestBenefitsCmd_C = function(cmd, laccount)
    local res = {} 
    res["do"] = "Cmd.SuperBonusCloseReturnBenefitsCmd_S"
    local uid = laccount.Id
    local superBonusInfo = SuperBonus.CloseSuperBonus(uid)
    res["data"] = {
        currentNumber = superBonusInfo.currentNumber,
    }
    return res
end