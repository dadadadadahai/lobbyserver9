--gm测试指令
local tableItemConfig = import"table/table_item_config"
GmCmd.GetGmlevel = function(info, laccount)
    return unilight.getdebuglevel()
end

--增加道具数量
--[[
返回值说明: 返回nil成功，其它返回错误字符串提示客户端
]]
GmCmd.AddItem = function(laccount, map)
    local uid = laccount.Id
    local itemId = tonumber(map["id"])
    local num    = tonumber(map["num"]) or 1
    if tableItemConfig[itemId] == nil then
        return "找不到道具id:"..itemId
    end
    BackpackMgr.GetRewardGood(uid, itemId, num, Const.GOODS_SOURCE_TYPE.GM_COMMAND)
    return nil
end

GmCmd.DelItem = function(laccount, map)
    local uid = laccount.Id
    local itemId = tonumber(map["id"])
    local num    = tonumber(map["num"])
    if tableItemConfig[itemId] == nil then
        return "找不到道具id:"..itemId
    end
    local ret , res = BackpackMgr.UseItem(uid, itemId, num, "gm命令删除")
    if ret ~= true then
        return res
    end
    return nil
end

GmCmd.GetItemNum = function(laccount, map)
    local uid = laccount.Id
    local itemId = tonumber(map["id"])
    local remainNum = BackpackMgr.GetItemNumByGoodId(uid, itemId) 
    return string.format("道具:%s, 剩余数量:%d",itemId, remainNum)
end


--增加buff
GmCmd.AddBuff = function(laccount, map)
    local uid = laccount.Id
    local buffId = tonumber(map["id"])
    local time    = tonumber(map["time"])
    BuffMgr.AddBuff(uid, buffId, time )
    return nil
end


--删除buff
GmCmd.DelBuff = function(laccount, map)
    local uid = laccount.Id
    local buffId = tonumber(map["id"])
    BuffMgr.RemoveBuffByBuffId(uid, buffId)
    return nil
end


--加钱
GmCmd.AddMoney = function(laccount, map)
    local uid = laccount.Id
    local moneyType = tonumber(map["type"])
    local num = tonumber(map["num"]) 
    local goodId = 0
    --金币
    if moneyType == Const.GOODS_ID.GOLD then
        goodId = Const.GOODS_ID.GOLD_BASE
    elseif moneyType == Const.GOODS_ID.DIAMOND then
        goodId = Const.GOODS_ID.DIAMOND
    else
        --默认金币
        goodId = Const.GOODS_ID.GOLD_BASE
    end
    BackpackMgr.GetRewardGood(uid, goodId, num, Const.GOODS_SOURCE_TYPE.GM_COMMAND)
    return nil
end

--赛季任务加积分
GmCmd.AddTaskPoint = function(laccount, map)
    local uid = laccount.Id
    local point = tonumber(map["num"])
    if point == nil then
        return "积分不正确"
    end
    DaysTaskMgr.AddPassPoint(uid, point)
end

--每日任务增加任务点数
GmCmd.AddTaskNum = function(laccount, map)
    local uid      = laccount.Id
    local taskType = tonumber(map["type"]) --1.普通任务， 2.赛季任务
    local num      = tonumber(map["num"])
    DaysTaskMgr.AddTaskNum(uid, taskType, num)
end

--购买商城商品
GmCmd.BuyShop = function(laccount, map)
    local uid      = laccount.Id
    local shopId = tonumber(map["id"]) --商品id
    ShopMgr.BuyGoods(uid, shopId)
end

-- 增加积分榜积分
GmCmd.ScoreBoardAddScore = function(laccount, map)
    local uid      = laccount.Id
    local bet = tonumber(map["bet"]) --赌注
    local type = tonumber(map["type"]) --类型 type 1:金杯 2:银杯 3:铜杯
    ScoreBoard.AddScore(uid,bet,type)
end

--游戏设置gm命令
GmCmd.GameGmSetCommon = function(laccount, map)
    GmCmd.GameGmResetCommon(laccount,map)
    local uid     = laccount.Id
    local opType  
    local opValue 
    if map["free"] ~= nil then
        opType = "free"
        opValue = tonumber(map["free"])
    elseif map["sfree"] ~= nil then
        opType = "sfree"
        opValue = tonumber(map["sfree"])
    elseif map["respin"] ~= nil then
        opType = "respin"
        opValue = tonumber(map["respin"])
    elseif map["collect"] ~= nil then
        opType = "collect"
        opValue = tonumber(map["collect"])
    elseif map["bonus"] ~= nil then
        opType = "bonus"
        opValue = tonumber(map["bonus"])
    elseif map["jackpot"] ~= nil then
        opType = "jackpot"
        opValue = tonumber(map["jackpot"])
    end
    local gameId = tonumber(map["game"])            --可选，自己调试时使用
    local ret     = gamecommon.CmdGmSetCommand(uid, opType, opValue, gameId)
    return ret
end

--获得游戏当前gm设置
GmCmd.GameGmGetCommon = function(laccount, map)
    local uid      = laccount.Id
    local gameId   = tonumber(map["game"])
    return gamecommon.CmdGmGetCommand(uid, gameId)
end

--重置游戏gm命令
GmCmd.GameGmResetCommon = function(laccount, map)
    local uid      = laccount.Id
    local gameId   = tonumber(map["game"])
    return gamecommon.CmdGmResetCommand(uid, gameId)
end



--进入调试模式
GmCmd.StartDebug = function(laccount, map)
    require("LuaPanda").start("127.0.0.1", 8818)
end

--退出调试模式
GmCmd.StopDebug = function(laccount, map)
    require("LuaPanda").disconnect()
end

-- 红包雨发红包
GmCmd.RedRain = function(laccount, map)
    redRain.GM()
end
-- 红包雨发红包
GmCmd.NewTask = function(laccount, map)
    nTask.GM(laccount.Id)
end
-- 徽章增加今日下注
GmCmd.AddDayBetMoney = function(laccount, map)
    local uid = laccount.Id
    local num    = tonumber(map["num"]) or 1
    DayBetMoney.AddDayBetMoney(uid,num)
end

--[[
测试功能，不用提交
]]
GmCmd.Test = function(laccount, map)
    local uid = laccount.Id
    -- Net.CmdFindPlayerLobbyCmd_C({data={uidList={1001077}}}, laccount)

   -- Net.CmdGetListRankCmd_C({data={rankType=4,startIndex=1,endIndex=10}},laccount)
   --获取挑战数据
   --Net.CmdGetMissionTablesCmd_C ({}, laccount)
   --模拟完成子游戏任务，每次访问，任务进程加 100000000
   --Net.CmdPlayGamesCmd_C({data={pos=1}}, laccount)
   --花绿钻完成挑战任务
   --Net.CmdBuyGameCmd_C({data={pos=2}}, laccount)
   --领取奖励 物品
  -- Net.CmdGetTaskRewardCmd_C({data={pos=1}}, laccount)

   --Net.CmdGetDiamonRewardCmd_C({data={pos=1}}, laccount)
   --珍珠小游戏
   --Net.CmdGetPearlGameInfoCmd_C({data={ids=500}}, laccount)

    --Net.CmdPlayQuestDialCmd_C ({}, laccount)

    -- Net.CmdGetFavouriteGameCmd_C ({}, laccount)
    -- Net.CmdGetLatelyPlayGameCmd_C ({}, laccount)
    -- Net.CmdGetGuessYouLikeGameCmd_C ({}, laccount)

      --Net.CmdEnterSceneGame_C({data={gameId=213, msg="hello"}}, laccount)
    --bonus玩法
    --Net.CmdGameOprateGame_C({data={gameId=213, betIndex=1,reqType=9,extraData={index =1}}}, laccount)
    --普通玩法
    --Net.CmdGameOprateGame_C({data={gameId=213, betIndex=1,reqType=1,extraData={index =1}}}, laccount)
    --转盘玩法
    --Net.CmdGameOprateGame_C({data={gameId=213, betIndex=1,reqType=2}}, laccount)
    --免费游戏玩法
    --Net.CmdGameOprateGame_C({data={gameId=213, betIndex=1,reqType=3,extraData={index =1}}}, laccount)


     --Net.CmdEnterSceneGame_C({data={gameId=215, msg="hello"}}, laccount)
    --bonus玩法
     --Net.CmdGameOprateGame_C({data={gameId=215, betIndex=1,reqType=9,extraData={index =1}}}, laccount)
    --普通玩法
    --Net.CmdGameOprateGame_C({data={gameId=215, betIndex=1,reqType=1}}, laccount)
    --转盘玩法
   -- Net.CmdGameOprateGame_C({data={gameId=215, betIndex=1,reqType=2,extraData={index =7}}}, laccount)
    --免费游戏玩法
    --Net.CmdGameOprateGame_C({data={gameId=215, betIndex=1,reqType=3,extraData={index =1}}}, laccount)













    --白头鹰测试
    --Net.CmdEnterSceneGame_C({data={gameId=281, msg="hello"}}, laccount)
        --普通玩法
    --Net.CmdGameOprateGame_C({data={gameId=281, betIndex=1,reqType=1}}, laccount)

    --311神秘埃及测试
    --Net.CmdEnterSceneGame_C({data={gameId=311, msg="hello"}}, laccount)
        --普通玩法
    --Net.CmdGameOprateGame_C({data={gameId=311, betIndex=1,reqType=1}}, laccount)

    -- Net.CmdReqGetOfflineRewardListLobbyCmd_CS({data={sourceType=50}}, laccount)
    -- Net.CmdReqGetOfflineRewardLobbyCmd_CS({data={sourceType=50}}, laccount)
    
    --311神秘面莎测试
    -- Net.CmdEnterSceneGame_C({data={gameId=215, msg="hello"}}, laccount)
        --普通玩法
    -- Net.CmdGameOprateGame_C({data={gameId=215, betIndex=1,reqType=1,extraData={index =9}}}, laccount)
--      local cols = {1,1,1}

--      local chessdata =  gamecommon.CreateSpecialChessData(cols,treasurehuntmgr.table_treasurehunt_slot)
--      chessdata[1][1]=111
--      chessdata[2][1]=111
--      chessdata[3][1]=111


--      local wild ={}
--     wild[115] =1
 local data = {
     data = {
         rankType = 10801 ,
         startIndex = 1,
         endIndex = 50,
     }
 }

    Net.CmdGetListRankCmd_C(data, laccount)

--    local ss = slotGameBelnd(chessdata,wild,107)
 return nil
end


--判断小游戏中奖
function slotGameBelnd(chessdata,wild,cid)
    local res ={
        type =1,--类型  1 为倍数奖励 。  2 中JACKPOT奖励 ，
        mul = 1,
        iconid = 0,     --只转换115ID
        zjid = 0,           --中奖ID 
    }
            --判断有几个wild 
            --判断非WILD 元素。三个是否一样。 
    local filename=0
    local type = 0

    --位置转换 
    local colid = 10
    colid = colid+cid

    --判断是否中三个WIld奖励 
    for col = 1, #chessdata do
        if wild[chessdata[col][1]] ==nil then
            type=0
            break
        end
        type = 2

    end
    --如果是三个115中奖
    if type==2 then
        --这里的mul 是大奖的 poolid。  1 2 3 4 5
        for index, value in ipairs(treasurehuntmgr.table_treasurehun_slot_prize) do
            if cid == value.iconid then
                res.mul = value.djid
            end
            
        end
      
        --开始转换ID 。
        if cid <109 then
            res.iconid = colid
        else
            local idd = gamecommon.CommRandInt(treasurehuntmgr.table_treasurehun_109,'rate')
            res.iconid = treasurehuntmgr.table_treasurehun_109[idd].iconId
        end
        res.type = 1
        res.zjid = treasurehuntmgr.table_treasurehunt_stype[1].ID
        print("1111111111111111111..............",table2json(res))

        return res         
        
    end
    
    --判断是否三个普通元素中奖 包含WILD
    local three = false
    for col = 1, #chessdata do
        three = false
        if col==1 then
            filename = chessdata[col][1]
        elseif wild[filename] and col==2 then    
            filename = chessdata[col][1]
        elseif wild[filename] and col==3 then    
            filename = chessdata[col][1]
            three = true
        elseif filename == chessdata[col][1] or wild[chessdata[col][1]]  then 
            three = true
        else
            break    
        end
    end
    --三个元素中奖
    if three then
                --获取 元素中奖倍数
        local mul  = 0
        for index, value in ipairs(treasurehuntmgr.table_treasurehunt_slot_pl) do
            if value.iconid ==  filename then
                mul = value.l3
                break
            end
        end
        res.type = 1

        res.mul = mul
        for index, value in ipairs(treasurehuntmgr.table_treasurehunt_stype) do
            if value.iconid == filename then
                res.zjid = value.ID
                break
            end
        end

        --如果有WILID元素则转换ID 
        local  wnum = 0
        for col = 1, #chessdata do
            if wild[chessdata[col][1]]~= nil  then    
                 wnum = wnum+1
            end

        end

        if  wnum>0 then
            if cid <109 then
                res.iconid = colid
            else
                local idd = gamecommon.CommRandInt(treasurehuntmgr.table_treasurehun_109,'rate')
                res.iconid = treasurehuntmgr.table_treasurehun_109[idd].iconId
            end
        end

                print("2222222222222222..............",table2json(res))

        return res

    end
    
--其他中奖判断 ， 是否有WILD和110元素中奖
    local  wnum = 0
    --判断有几个110
    local num110 = 0
    for col = 1, #chessdata do
        if wild[chessdata[col][1]]~= nil  then    
             wnum = wnum+1
        end
        if chessdata[col][1] == 110  then
            filename = 110
            num110 = num110+1
         end
    end
    --如果有WILD 则转换ID 并计算倍数
    if wnum>0 or num110>0  then
        if wnum>0  then
            if cid <109 then
                res.iconid = colid
                for index, value in ipairs(treasurehuntmgr.table_treasurehun_slot_prize) do
                    if cid == value.iconid then
                        res.mul = value.mul
                    end
                    
                end
            else
                local idd = gamecommon.CommRandInt(treasurehuntmgr.table_treasurehun_109,'rate')
                res.iconid = treasurehuntmgr.table_treasurehun_109[idd].iconId
                local mul = treasurehuntmgr.table_treasurehun_109[idd].mul
                res.mul = mul
            end
            res.zjid = 9
        end

                    --如果有110元素则进行计算 
            if num110>0 then
                num110 = num110+wnum
                local plid ='l'
                plid= plid..num110


                local config =  treasurehuntmgr.table_treasurehunt_slot_pl[5]
                local mul = config[plid]
                print("33333333333333333333333............mul..",mul)

                
                for index, value in ipairs(treasurehuntmgr.table_treasurehunt_stype) do

                    if  value.iconid == 110 and value.num == num110 then
                        res.zjid = value.ID
                        break
                    end
                end
                res.mul = mul

            end
            print("33333333333333333333333..............",table2json(res))

    return res

    end
    print("44444444444444444444444444..............",table2json(res))


    return res

end




















--注册GM命令
--[[
GmCmd.AddItem: 协议名
"additem": 客户端输入的gm命令名称
"additem id=3 num=1000": 命令帮助
true: 执行完后是否通知客户端
]]
if unilight.getdebuglevel()>0 then
    go.gmcommand.AddLuaCommand(GmCmd.AddItem, "additem", "additem id=60002 num=1", true)
    go.gmcommand.AddLuaCommand(GmCmd.DelItem, "delitem", "delitem id=3 num=1000", true)
    go.gmcommand.AddLuaCommand(GmCmd.GetItemNum, "getitemnum", "getitemnum id=3", true)
    go.gmcommand.AddLuaCommand(GmCmd.AddBuff, "addbuff", "addbuff id=3 time=1000", true)
    go.gmcommand.AddLuaCommand(GmCmd.DelBuff, "delbuff", "delbuff id=3", true)
    go.gmcommand.AddLuaCommand(GmCmd.AddMoney, "addmoney", "addmoney type=1 num=1000", true)
    go.gmcommand.AddLuaCommand(GmCmd.Test, "test", "test x=x", true)
    go.gmcommand.AddLuaCommand(GmCmd.AddTaskPoint, "addtaskpoint", "addtaskpoint num=100", true)
    go.gmcommand.AddLuaCommand(GmCmd.AddTaskNum, "addtasknum", "addtasknum type=1 num=100", true)
    go.gmcommand.AddLuaCommand(GmCmd.BuyShop, "buyshop", "buyshop id=1", true)
    go.gmcommand.AddLuaCommand(GmCmd.StartDebug, "startdebug", "", true)
    go.gmcommand.AddLuaCommand(GmCmd.StartDebug, "debug", "", true)
    go.gmcommand.AddLuaCommand(GmCmd.StopDebug, "stopdebug", "", true)
    go.gmcommand.AddLuaCommand(GmCmd.GameGmSetCommon, "setgame", "setgame free=1", true)
    go.gmcommand.AddLuaCommand(GmCmd.GameGmGetCommon, "getgame", "getgame", true)
    go.gmcommand.AddLuaCommand(GmCmd.GameGmResetCommon, "resetgame", "resetgame", true)
    go.gmcommand.AddLuaCommand(GmCmd.RedRain, "redrain", "", true)
    go.gmcommand.AddLuaCommand(GmCmd.AddDayBetMoney, "addDayBetMoney", "addDayBetMoney num=1000", true)
    go.gmcommand.AddLuaCommand(GmCmd.NewTask, "ntask", "", true)
end

--请求神像信息
GmCmd.GetGod = function (laccount,map)
    local uid  = laccount.Id
    local msg =Net.CmdGetGodStatueInfoCmd_C({},laccount)
    -- print(table2json(msg))
    -- local godInfo = godstatueMgr.CmdGetGodStatueInfo(uid)
    -- print(table2json(godInfo))
    return nil
end
--请求pickGame
GmCmd.GetPick = function (laccount,map)
    local uid  = laccount.Id
    local pickGameInfo = godstatueMgr.CmdGetPickGameInfo(uid)
    print(table2json(pickGameInfo))
    return nil
end

--请求抽奖
GmCmd.openBox = function (laccount,map)
    local uid  = laccount.Id
    local pos = tonumber(map["pos"])
    local pickGameInfo = godstatueMgr.CmdOpenBoxPickGame(uid,pos)
    print(table2json(pickGameInfo))
    return nil
end
--神像升级
GmCmd.godLv = function (laccount,map)
    local uid = laccount.Id
    local type = tonumber(map["type"])
    local pickGameInfo = godstatueMgr.CmdUpLvGodStatue(uid,type)
    print(table2json(pickGameInfo))
end

--领取奖励
GmCmd.getReward = function (laccount,map)
    local uid = laccount.Id
    local type = tonumber(map["type"])
    local pickGameInfo = godstatueMgr.GetReceive(uid)
    print(table2json(pickGameInfo))
end
go.gmcommand.AddLuaCommand(GmCmd.ScoreBoardAddScore, "ScoreBoardAddScore", "ScoreBoardAddScore bet=1000000 type=1", true)
--增加团队礼物
GmCmd.addTeamGift = function (laccount,map)
    local uid = laccount.Id
    local goodId = tonumber(map["goodId"])
    local goodNum = tonumber(map['goodNum'])
    local type = tonumber(map['type'])
    local sid = tonumber(map['sid']) or uid
    local teaminfo = teammgr.Team.GetTeamInfo(uid)
    local rewards ={}
    table.insert(rewards,{goodId=goodId,goodNum=goodNum,tm=os.time()})
    teammgr.Team.AddGoldGift(teaminfo,sid,rewards,type,1024)
end
go.gmcommand.AddLuaCommand(GmCmd.addTeamGift, "addTeamGift", "addTeamGift goodId goodNum type", true)

--增加经验值
GmCmd.addExp = function (laccount,map)
    local uid = laccount.Id
    local exp = tonumber(map["exp"])
    levelmgr.AddExp(exp,uid)
end
go.gmcommand.AddLuaCommand(GmCmd.addExp, "addExp", "addExp exp", true)
--增加到特定经验,对宝箱小游戏进行特殊处理
GmCmd.addLevelTo = function (laccount,map)
    local uid = laccount.Id
    local level = tonumber(map['level'])
    local levelinfo =  levelmgr.GetLevelInfo(uid)
    local nUserInfo = unilight.getdata('userinfo',uid)
    nUserInfo.property.level = level
    unilight.update('userinfo',nUserInfo._id,nUserInfo)
    levelmgr.handleBox(nUserInfo,levelinfo,false)
end
go.gmcommand.AddLuaCommand(GmCmd.addLevelTo, "addLevelTo", "addLevelTo level", true)


--请求探索数据
GmCmd.questInfo = function (laccount,map)
    local uid = laccount.Id
    local questInfo = {}
    questInfo = questMgr.GetQuestInfo(uid)
    print(table2json(questInfo))
end


--探索过关
GmCmd.playerQuestGame = function (laccount,map)
    local uid = laccount.Id
    local questInfo = {}
    questInfo = questMgr.playerQuestGame(uid,1)
    print(table2json(questInfo))
end


GmCmd.TEST=function (laccount,map)
   --排行榜结算
   local res = RankModuleMgr.SellteRank(Const.RANK_TYPE.CATCHFISH)
   print(table2json(res))
end
go.gmcommand.AddLuaCommand(GmCmd.TEST, "TEST", "TEST", true)

GmCmd.GetHot = function (laccount,map)
    local uid = laccount.Id
    local gameInfo ={}
    gameInfo = hallMgr.hottestGame(1)
    
end


GmCmd.Gethall = function (laccount,map)
    local uid = laccount.Id
    local gameInfo ={}
    gameInfo = hallMgr.userHallGame(uid)
    
end

--设置手机绑定验证码
GmCmd.SetPhone = function (laccount,map)
    local uid = laccount.Id
    local phoneNbr = map['num']
    local verifyNbr = "111111"
    unilight.redis_setdata(phoneNbr, verifyNbr)
    unilight.redis_setexpire(phoneNbr, 60 * 10)
    
end


go.gmcommand.AddLuaCommand(GmCmd.SetPhone, "setphone", "setphone num=13111111111", true)
go.gmcommand.AddLuaCommand(GmCmd.GetGod, "getgod", "getgod", true)
go.gmcommand.AddLuaCommand(GmCmd.GetPick, "getpick", "getpick ", true)
go.gmcommand.AddLuaCommand(GmCmd.openBox, "openbox", "openbox pos=1", true)
go.gmcommand.AddLuaCommand(GmCmd.getReward, "getReward", "getReward", true)
go.gmcommand.AddLuaCommand(GmCmd.godLv, "godLv", "godLv type=1", true)


go.gmcommand.AddLuaCommand(GmCmd.questInfo, "questInfo", "questInfo pos=1", true)

go.gmcommand.AddLuaCommand(GmCmd.playerQuestGame, "playerQuestGame", "playerQuestGame pos=1", true)
go.gmcommand.AddLuaCommand(GmCmd.GetHot, "getHot", "getHot", true)
go.gmcommand.AddLuaCommand(GmCmd.Gethall, "Gethall", "Gethall", true)
--存钱罐加入金币 10%
GmCmd.AddCofrinho =function (laccount,map)
    local uid = laccount.Id
    local gold = tonumber(map['gold'])
    cofrinho.AddCofrinho(uid,gold)
end
--存钱罐结算触发
GmCmd.SettleCofrinho =function (laccount,map)
    local uid = laccount.Id
    local datainfo = unilight.getdata('cofrinho',uid)
    datainfo.settleTime = 0
    cofrinho.Settle(datainfo)
end
go.gmcommand.AddLuaCommand(GmCmd.AddCofrinho, "AddCofrinho", "AddCofrinho gold=1", true)
go.gmcommand.AddLuaCommand(GmCmd.SettleCofrinho, "SettleCofrinho", "SettleCofrinho", true)
--VIP充值回调
GmCmd.ChangeVipCallBack = function (laccount,map)
    local uid = laccount.Id
    local shopId = tonumber(map['shopId'])
    nvipmgr.ChangeVipCallBack(uid,shopId)
end
go.gmcommand.AddLuaCommand(GmCmd.ChangeVipCallBack, "ChangeVipCallBack", "ChangeVipCallBack shopId=1", true)
