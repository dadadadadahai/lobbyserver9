module("godstatueMgr",package.seeall)

--pickGame15 个箱子配置（id：序号，type(或者goodId):物品类型或者物品ID，能够准确识别的,num:物品数量， rate：权重）
tablePickGameConfig = import"table/table_pick_game_config"
--翻箱子基本配置(其他配置)，比如 免费游戏次数，翻倍金币，消耗宝石等
tablePickGameBaseConfig = import"table/table_god_other_config"

--神像升级道具配置 （id：序号，type:类型，lv:等级，need:需求数量，rate:权重）
tableGodStatueLvItemConfig = import"table/table_god_badege_config"
--神像基础配置 (id，等级，type,buffId )
tableGodStatueBaseConfig = import"table/table_god_statue_config"
tableItemConfig    = import "table/table_item_config"
--数据库相关表
--神像表
DB_GODSTATUE_NAME="godStatueInfo"
--pickGame表
DB_PICKGAME_NAME = "pickGameInfo"
--左边神像类型
GOD_BADEGE_LEFT_TYPE = 1
--右边神像类型
GOD_BADEGE_RIGHT_TYPE = 2

--左边神像等级上限
LEFT_MAX_LV=3
--右边神像集合
RIGHT_MAX_LV=3

--初始化神像数据库
function GodStatueInfoToDataInit(uid)
    local godStatueInfo={
        _id=uid,            
        leftGodLv=0,                                --左边神像等级
        rightGodLv=0,                               --右边神像等级
        lastFlushTime = 0,                          --上次刷新时间
        freeCount=tablePickGameBaseConfig[1].freeCount, --免费游戏次数
        buyCount=#tablePickGameBaseConfig[1].buyCount,      --购买游戏次数
        leftPickCount=0,                            --翻箱子次数
        leftBadege=GetBadegeInit(1,1),              --左边神像道具
        rightBadge=GetBadegeInit(2,1),               --右边神像徽章道具
        state = 1,                                   --是否可以玩
        temp ={}                                    --临时记录获取的道具，领取奖励后要清空

    }
    return godStatueInfo
    
end

--初始化神像道具
function GetBadegeInit(type,lv)
    --循环配置档，1 为左边神像道具，2为右边神像道具
    local badegeInfo={}
    for key, value in ipairs(tableGodStatueLvItemConfig) do
        if lv==value.lv then
            if type==value.type then
                local info = {
                    id = value.badegeId,
                    type = value.type,
                    lv = value.lv,
                    need = value.need,
                    num = 0,
                    rate = value.rate
                }
                table.insert(badegeInfo,info)
            end
        end

    end
    return badegeInfo
end


--初始化pickGame数据库
function PickGameInfoToDataInit(uid)
    local pickGameInfo={
        _id = uid,
        items={},                --已经抽中的
        buyItems ={},             --需要付费抽取的
        showItems ={}             --展示物品  
    }
    for i=1, 15 do
        local item={}
        table.insert(pickGameInfo.items,item)
    end
    return pickGameInfo
    
end


-- 请求神像数据
function CmdGetGodStatueInfo(uid)
    local godStatueInfo = unilight.getdata(DB_GODSTATUE_NAME, uid)
    if godStatueInfo == nil then
        godStatueInfo = GodStatueInfoToDataInit(uid)
        unilight.savedata(DB_GODSTATUE_NAME, godStatueInfo)
    end

    local curDayNo = chessutil.GetMorningDayNo()
    if godStatueInfo.lastFlushTime == 0 or godStatueInfo.lastFlushTime ~= curDayNo then
    --判断是否凌晨四点，过了就刷新
        GetReceive(uid)
         godStatueInfo.freeCount=tablePickGameBaseConfig[1].freeCount --免费游戏次数
         godStatueInfo.buyCount=#tablePickGameBaseConfig[1].buyCount --购买游戏次数
         godStatueInfo.lastFlushTime = curDayNo
         godStatueInfo.leftPickCount=0
         godStatueInfo.state=1
        unilight.savedata(DB_GODSTATUE_NAME, godStatueInfo)
        unilight.savedata(DB_PICKGAME_NAME,PickGameInfoToDataInit(uid))
	 end
 
    return godStatueInfo
    
end

-- 请求神像升级
function CmdUpLvGodStatue(uid,badgeType)
    --获取神像信息 
    local godStatueInfo = unilight.getdata(DB_GODSTATUE_NAME, uid)
    if godStatueInfo == nil then
        godStatueInfo = GodStatueInfoToDataInit(uid)
        unilight.savedata(DB_GODSTATUE_NAME, godStatueInfo)
    end
    --检查神像道具
    local badgeInfo ={}
    local statueBoolean = false
    if badgeType  ==GOD_BADEGE_LEFT_TYPE then
        --判断左边神像等级是否是最大等级
        if godStatueInfo.leftGodLv>=LEFT_MAX_LV then
            unilight.error("左边神像已到最大等级")
            return 
        end

        badgeInfo = godStatueInfo.leftBadege
        statueBoolean = true
    else
        --判断右边神像等级是否是最大等级
        if godStatueInfo.rightGodLv>=RIGHT_MAX_LV then
            unilight.error("右边神像已到最大等级")
            return 
        end
        badgeInfo = godStatueInfo.rightBadge
    end
    for key, value in pairs(badgeInfo) do

        if value.num<1 then
            --判断数量是否足够
            unilight.error("神像徽章不足")
            return 
        end
    end
    --重置神像道具 
    local buffLv = 0
    if statueBoolean then
        godStatueInfo.leftGodLv =godStatueInfo.leftGodLv+1
        godStatueInfo.leftBadege= GetBadegeInit(badgeType, godStatueInfo.leftGodLv)
        buffLv = godStatueInfo.lv
    else
        godStatueInfo.rightGodLv = godStatueInfo.rightGodLv+1
        godStatueInfo.rightBadge= GetBadegeInit(badgeType, godStatueInfo.rightGodLv)
        buffLv = godStatueInfo.lv

    end
    unilight.savedata(DB_GODSTATUE_NAME,godStatueInfo)

    --添加神像BUFF
    -- local buffId = 0
    -- for index, value in ipairs(tableGodStatueBaseConfig) do
    --     if value.type == badgeType then
    --         if value.lv== buffLv then
    --             buffId =value.buffId
    --         end
    --     end
    -- end
    
    -- BuffMgr.AddBuff(uid,buffId,longTimds)

    return godStatueInfo

end

--神像升级 奖励 
function isUpReward(uid,lv,ty)
    local reward ={}
    for index, value in ipairs(tableGodStatueBaseConfig) do
        if value.lv == lv and ty == value.type then
            --开始发奖
            for key, va in pairs(value.goods) do

                local re = BackpackMgr.GetRewardGood(uid, va.goodId, va.goodNum, Const.GOODS_SOURCE_TYPE.GODSTATUE)

                for inde, vals in pairs(re) do
                    local su ={
                        goodId = inde,
                        goodNum = vals
                    }
                    table.insert(reward,su)

                end

            end
        end
    end
    return reward

    
end

-- 请求pickGame游戏数据
function CmdGetPickGameInfo(uid)
    local pickGameInfo = unilight.getdata(DB_PICKGAME_NAME,uid)

    if pickGameInfo ==nil then
        pickGameInfo = PickGameInfoToDataInit(uid)
        unilight.savedata(DB_PICKGAME_NAME,pickGameInfo)
    end
    
    return pickGameInfo
end

-- pickGame开箱子
function CmdOpenBoxPickGame(uid,pos)
    --读取 神像数据
    local godStatueInfo = unilight.getdata(DB_GODSTATUE_NAME,uid)
    if godStatueInfo == nil then
        godStatueInfo = GodStatueInfoToDataInit(uid)
        unilight.savedata(DB_GODSTATUE_NAME, godStatueInfo)
    end
    --读取pickGame游戏数据
    local pickGameInfo = unilight.getdata(DB_PICKGAME_NAME,uid)
    if pickGameInfo ==nil then
        pickGameInfo = PickGameInfoToDataInit(uid)
        unilight.savedata(DB_PICKGAME_NAME,pickGameInfo)
    end
    if godStatueInfo.leftPickCount>=3 then
        unilight.error("翻箱子次数已用完，请购买游戏次数:"..uid)
        return
    end
    --获取配置档权重，随机出奖励物品
    local id=0
    local goodId=0
    local goodNum=0
    if  godStatueInfo.freeCount==0 then
        local buyItems =pickGameInfo.buyItems
        if pickGameInfo.buyItems == nil then
            buyItems = OpenBuyPickGameByRate(uid,2)
        end

       local buyI  = GetPickGameRanomBuy(buyItems)


        --根据随机出来下标， 从配置档读取物品ID
        goodId = buyI.goodId
        --从配置档读取出物品数量
        goodNum = buyI.goodNum

        table.remove(pickGameInfo.buyItems,id)
    else
        id = GetPickGameRanomByRate(tablePickGameConfig)
            --根据随机出来下标， 从配置档读取物品ID
        goodId = tablePickGameConfig[id].goods[1].goodId
        --从配置档读取出物品数量
        goodNum = tablePickGameConfig[id].goods[1].goodNum
    end
    local isUp = false
    local update ={}
    local ty =0
    local rew={}
    local isTemp = false


    if goodId ==1 then
        rew = GetGodStatueRanomByRate(uid)
         goodId =  rew.id
        --如果是添加神像道具 ，则判断是否升级
        if godStatueInfo.temp[goodId]~=nil then
             isTemp = true
        end
        if rew.type==1 then
            update= updateGodLV(goodId,godStatueInfo.leftBadege,isTemp)
        else
            update =updateGodLV(goodId,godStatueInfo.rightBadge,isTemp)
        end
        godStatueInfo.temp[goodId] = goodId
        goodId = update[1].ids
        goodNum = update[1].nums
        isUp = update [1].isc
        ty = rew.type

    end


    local free =false
    if godStatueInfo.buyCount>=3 then
        free = true                   --是否免费
    end
    --生成获得的物品
    local item={
        goodId = goodId,                    --物品ID
        goodNum = goodNum,                --物品数量
        pos = pos,                      --物品位置
        rate = tablePickGameConfig.rate,--物品权重
        receive=0,                       --物品是否领取
        isFree = free,                   --true免费 flase收费
        isCan = isUp,                    --是否升级
        type = ty                        --左还是右
     }
    pickGameInfo.items[pos] = item
    unilight.savedata(DB_PICKGAME_NAME,pickGameInfo)

    godStatueInfo.leftPickCount = godStatueInfo.leftPickCount+1
    if godStatueInfo.leftPickCount==3 then
        godStatueInfo.freeCount=0
    end
    unilight.savedata(DB_GODSTATUE_NAME,godStatueInfo)

    return pickGameInfo
    
end


--判断神像是否升级，或者转为金卷
function updateGodLV(goodId,statueInfo,isTemp)
    --判断该物品是否重复 ，或是否升级 
    local item={}
    local i =1
    local isc = false

    for key, value in pairs(statueInfo) do
        if value.id == goodId  then
            if value.num>0 or  isTemp then
                local itemconfig = tableItemConfig[goodId]
                local id    = tonumber(itemconfig.para2)   --奖券颜色
                local num   = tonumber(itemconfig.para1)     --兑换的数量
                local items={
                    ids = id,
                    nums = num,
                }
                table.insert(item,items)
                return item
            end
            i = i+1
        end
        
        if value.num>0 then
            i = i+1
        end

        
    end

    if i==6 then
        isc = true

    end
    local items = {
        ids = goodId,
        nums = 1,
        isc = isc
    }
    table.insert(item,items)
    return item

    
end

--领取奖励
function GetReceive(uid)
    local pickGameInfo = unilight.getdata(DB_PICKGAME_NAME,uid)
    if pickGameInfo==nil then
        return
    end

    local items = pickGameInfo.items
    if items ==nil then
        unilight.error("没有奖励物品")
    end
    local receiveItem = {
        godLv= {},
        goods ={}
    }
    local godlv ={
        lv ={},
        godReward  = {}
       }

    for key, value in pairs(items) do
        if value.receive==0 then
            value.receive=1
            local num =0
            if value.isFree then
                num = value.goodNum
            else
                num = value.goodNum*tablePickGameBaseConfig[1].multiple
            end
            --给玩家身上添加物品
             BackpackMgr.GetRewardGood(uid, value.goodId, num, Const.GOODS_SOURCE_TYPE.GODSTATUE)
             
             local goods={
                goodId = value.goodId,
                goodNum = num,
                isCan = value.isCan
             }
             table.insert(receiveItem.goods,goods)

             if value.isCan then

               local badegeInfo =  CmdUpLvGodStatue(uid,value.type)
               local godReward =  {}
               local left_old=0
               local left_new=0
               local right_old=0
               local right_new=0

                if value.type==1 then
                    left_old = badegeInfo.leftGodLv-1
                    left_new = badegeInfo.leftGodLv
                    godReward = isUpReward(uid,badegeInfo.leftGodLv,value.type)
                else
                    right_old = badegeInfo.rightGodLv-1
                    right_new = badegeInfo.rightGodLv
                    godReward = isUpReward(uid,badegeInfo.rightGodLv,value.type)
                end

            
                       local lv ={
                        left_old_lv=left_old,              --左边神像升级前等级
                        left_new_lv=left_new,              --左边神像升级后等级
                        right_old_lv=right_old,            --右边神像升级前等级
                        right_new_lv=right_new,             --右边神像升级后等级
                       }
                       table.insert(godlv.lv,lv)
                       table.insert(godlv.godReward,godReward)
                
             end
        end
    end
    receiveItem.godLv = godlv

    unilight.savedata(DB_PICKGAME_NAME,pickGameInfo)

    -- 升级神像 

    local godstatueInfo = unilight.getdata(DB_GODSTATUE_NAME,uid)
    godstatueInfo.state=0
    godstatueInfo.temp={}
    unilight.savedata(DB_GODSTATUE_NAME,godstatueInfo)
    return receiveItem


end


--开始付费随机宝箱物品
function  GetPickGameRanomBuy(tablePickGameConfig)
    local sum=0
--    for i = 1,#tablePickGameConfig do
--        sum =sum+tablePickGameConfig[i].rate
--    end

    for key, value in pairs(tablePickGameConfig) do
        sum =sum+value.rate
    end

    local compareWeight = math.random(1,sum)
    local ids=1

    for key, value in pairs(tablePickGameConfig) do
        sum  = sum - value.rate
        if sum < compareWeight then
            return value
        end

    end
 --   while sum>0 do
 --       sum  = sum - tablePickGameConfig[ids].rate
  --      if sum < compareWeight then
   --         return ids
  --      end
   --     ids = ids+1
  --  end

    return nil

end

--开始随机宝箱物品
function  GetPickGameRanomByRate(tablePickGameConfig)
    local sum=0
--    for i = 1,#tablePickGameConfig do
--        sum =sum+tablePickGameConfig[i].rate
--    end

    for key, value in pairs(tablePickGameConfig) do
        sum =sum+value.rate
    end

    local compareWeight = math.random(1,sum)
    local ids=1

    for key, value in pairs(tablePickGameConfig) do
        sum  = sum - value.rate
        if sum < compareWeight then
            return key
        end

    end
 --   while sum>0 do
 --       sum  = sum - tablePickGameConfig[ids].rate
  --      if sum < compareWeight then
   --         return ids
  --      end
   --     ids = ids+1
  --  end

    return nil

end

--获取付费宝箱信息
function OpenBuyPickGameByRate(uid,type)
    local pickGameInfo = unilight.getdata(DB_PICKGAME_NAME,uid)
    local pos =1
    if pickGameInfo.showItem == nil then
        for i = 1, 15, 1 do
        --获取配置档权重，随机出奖励物品
        local id = GetPickGameRanomByRate(tablePickGameConfig)
        --根据随机出来下标， 从配置档读取物品ID
        local goodId = tablePickGameConfig[id].goods[1].goodId
        --从配置档读取出物品数量
        local goodNum = tablePickGameConfig[id].goods[1].goodNum
        if pickGameInfo.items[pos].id ==nil  then
                        --生成获得的物品
            local item={
                goodId = goodId,
                goodNum = goodNum,
                pos = pos,
                rate = tablePickGameConfig[pos].rate,
                receive=0,                       --物品是否领取
                isFree = false
            }

            pickGameInfo.buyItems[pos] = item
            pickGameInfo.showItems[pos] = item

         else
            pickGameInfo.showItems[pos] = pickGameInfo.items[pos]
       end
        pos = pos+1
        end
    end
    unilight.savedata(DB_PICKGAME_NAME,pickGameInfo)

    if type==1 then

        return pickGameInfo.showItems
    else
        return pickGameInfo.buyItems
    end


    
end

--添加神像道具
function addGodStatueBadeg(uid, itemId, sourceType)
    local statueInfo= unilight.getdata(DB_GODSTATUE_NAME,uid)
    if statueInfo ==nil then
        statueInfo = GodStatueInfoToDataInit(uid)
    end
    local leftInfo = statueInfo.leftBadege
    local rightInfo = statueInfo.rightBadge
    local flag = false
    local info = {}

    for key, value in pairs(leftInfo) do
        if value.id == itemId then
            flag=true
            info = value
            break
        end    
    end

    for key, value in pairs(rightInfo) do
        if value.id == itemId then
            flag=true
            info = value
            break
        end    
    end
    --if not(leftInfo[itemId] and rightInfo[itemId] ) then
    if not flag then
        unilight.error("没有找到该物品")
        return
    end
    local isGold = false
    
    if info~=nil then
        if info.num>0  then
            isGold =true
        else
            info.num=info.num+1    
        end
            
    end


    unilight.savedata(DB_GODSTATUE_NAME,statueInfo)
    if isGold then
        local itemconfig = tableItemConfig[itemId]
        local goodId    = tonumber(itemconfig.para2)   --奖券颜色
        local goodNum      = tonumber(itemconfig.para1)     --兑换的数量
        BackpackMgr.GetRewardGood(uid, goodId, goodNum, Const.GOODS_SOURCE_TYPE.GODSTATUE)

    end
    
end 

--pidkGame随机神像道具
function GetGodStatueRanomByRate(uid)
    --     --读取pickGame游戏数据
    local statueInfo= unilight.getdata(DB_GODSTATUE_NAME,uid)


    --判断是否有一边升级，如果有一边升级 ，则只随机另外一边的数据
    local badegeConfig = {}
    local pos=1
    if statueInfo.leftGodLv == statueInfo.rightGodLv  then

        for key, value in pairs(statueInfo.leftBadege) do
            badegeConfig[pos]=value
            pos=pos+1
        end
        for key, value in pairs(statueInfo.rightBadge) do
            badegeConfig[pos]=value
            pos=pos+1
        end
         
    elseif statueInfo.leftGodLv > statueInfo.rightGodLv then
        for key, value in pairs(statueInfo.rightBadge) do
            badegeConfig[pos]=value
            pos=pos+1
        end
    else
        for key, value in pairs(statueInfo.leftBadege) do
            badegeConfig[pos]=value
            pos=pos+1
        end
    end

    local sum=0
    for key, value in pairs(badegeConfig) do
        sum = sum+value.rate
    end


    local compareWeight = math.random(1,sum)
    local ids=1
    while sum>0 do
        sum  = sum - badegeConfig[ids].rate
        if sum < compareWeight then
            return badegeConfig[ids]
        end
        ids = ids+1
    end

    return nil

end




-- pickGame购买次数
function CmdBuyPickGameCount(uid) 
    --获取游戏购买过的次数  
    local godStatueInfo = unilight.getdata(DB_GODSTATUE_NAME,uid)
    if godStatueInfo.freeCount>=1 then
        unilight.error("免费次数没用完:"..uid)
        return
    end
    local buyNum = tablePickGameBaseConfig[1].buyCount


    if godStatueInfo.buyCount==0 then
        unilight.error("已达最大购买次数"..uid)
        return
    end
    --消耗金额数量
    local gold = buyNum[3-godStatueInfo.buyCount+1]    
    --剩余购买次数
    godStatueInfo.buyCount = godStatueInfo.buyCount-1

    --扣除金额
  -- BackpackMgr.UseItem(uid,2,gold,"双王之战购买游戏次数")
    godStatueInfo.leftPickCount = 0
    unilight.savedata(DB_GODSTATUE_NAME,godStatueInfo)

    return godStatueInfo.buyCount

end


