module("levelmgr", package.seeall)
Level=Level or {}
Table_Name = "userLevel"
Table_Userinfo="userinfo"
TableLevelAward = import "table/table_role_level_award"
TableLevelAward2 = import "table/table_role_level_award2"[6]
TableLevelUp = import "table/table_role_levelup"
TableLevelXisu = import "table/table_role_level_xisu"
-- TableLevelGame=import "table/Tablelevelgame"
-- TablelevelGold=import "table/TablelevelGold"
local initLevel=1
local levelLine = 6             --等级分界变量
local bufAdd = 0                --暂时定义BUF为1
local AWARDENUM={}              --定义奖励枚举类型
--金币奖励类型
AWARDENUM.COIN  =   1
--限时等级
AWARDENUM.LIMITTIMELV  =   2
--小游戏奖励
AWARDENUM.LITTLEGAME  =   3
--VIP奖励
AWARDENUM.VIP  =   4
--俱乐部
AWARDENUM.CLUB  =   5
-- 获取玩家等级信息,并进行奖励处理
function CmdGetLevelInfo(uid)
    local levelInfo = GetLevelInfo(uid)
    local nUserinfo = unilight.getdata(Table_Userinfo,uid)
    return handleLevel(nUserinfo,levelInfo)   --处理奖励过程
end
--获取宝箱奖励
function GetBoxAwardCmd(uid)
    local res={}
    local levelInfo = GetLevelInfo(uid)
    local nUserinfo  = unilight.getdata('userinfo',uid)
    --初始化一次宝箱
    handleBox(nUserinfo,levelInfo,true)
    local infos={}
    for index, value in ipairs(levelInfo.boxs) do
        local items={
            level=value.level,
            list={
                goodId = value.list.goodId,
                goodNum = value.list.goodNum
            },
            status=value.status,
        }
        table.insert(infos,items)
    end

    res={
        errno=0,
        desc='success',
        gameTime=levelInfo.boxTime,
        infos=infos,
        sGameId=levelInfo.sGameId,
    }
    return res
end
--领取宝箱奖励
function GetRecvBoxAwardCmd(data,uid)
    local index = data.index
    if index<=0 then
        return{errno  =1,desc='参数错误'}
    end
    local res={
        errno =1
    }
    local levelInfo = unilight.getdata(Table_Name, uid)     --数据库获取内容
    local nUserInfo = unilight.getdata(Table_Userinfo,uid)
    local curLevel=nUserInfo.property.level
    if table.empty(levelInfo.boxs)==false  then
        local box =  levelInfo.boxs[index]
        if table.empty(box)==false and box.status == 0 and curLevel>=box.level then
            local summary ={}
            BackpackMgr.GetRewardGood(uid,box.list.goodId, box.list.goodNum, Const.GOODS_SOURCE_TYPE.BOX,summary)
            box.status=1
            unilight.update(Table_Name,levelInfo._id,levelInfo)
            local reward = {}
            for key, value in pairs(summary) do
                table.insert(reward,{goodId=key,goodNum=value})
            end
            res={
                errno =0,
                reward = reward,
                index = index,
            }
        end
        --判断三个宝箱是否全部领取完
        --Level.InsertNewSmallGame
        if levelInfo.boxs[1].status==1 and levelInfo.boxs[2].status==1 and levelInfo.boxs[3].status==1 then
            --初始化小游戏
            res.sGameId=Level.InsertNewSmallGame(levelInfo)
            --触发小游戏玩法
            Level.SendSGameMail(levelInfo,res.sGameId)
        end
        if res.errno ==0 then
            return res
        end
    end
    res={
        errno=1,
        desc='领取失败'
    }
    return res
end
--处理消息
function handleLevel(nUserinfo,levelInfo)
    local isupdate= false
    while true do
       --local index=IsUpLevel(levelInfo.level,levelInfo.xp)
       local index=IsUpLevel(nUserinfo.property.level,nUserinfo.property.exp)
       if index<0 then
            break
       end
       --去掉经验
       nUserinfo.property.exp = nUserinfo.property.exp - TableLevelUp[index].Exp
       --处理奖励信息
       nUserinfo.property.level = nUserinfo.property.level+1
       levelInfo=awardHandlde(nUserinfo,levelInfo)
       levelInfo=handleBox(nUserinfo,levelInfo,false)
       --俱乐部积分处理
       clubmgr.ClubScoreAdd(nUserinfo._id,nUserinfo.property.level,Const.CLUB_ADD_TYPE.GRADE)
       isupdate = true
    end
    local tmprs = levelInfo.rs
    levelInfo.rs={}
    if isupdate==true then
        unilight.update(Table_Name,nUserinfo._id,levelInfo)
    end
    unilight.update(Table_Userinfo,nUserinfo._id,nUserinfo)
    --实际奖励入库处理
    awardUpdateDataBase(nUserinfo._id,tmprs)
    
    return {
        errno=0,
        desc='success',
        _id = levelInfo._id,
        xp  =   nUserinfo.property.exp,
        level = nUserinfo.property.level,
        gain  = levelInfo.gain,
        vip   = nUserinfo.property.vipExp,
        club  = clubmgr.GetClubScore(levelInfo._id),
        rs=tmprs
    }
end
--数据入库处理
function awardUpdateDataBase(uid,reward)
    for k, v in pairs(reward) do
        if v.type==AWARDENUM.COIN then  --金币奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, v.val, Const.GOODS_SOURCE_TYPE.LEVEL)
        elseif v.type==AWARDENUM.VIP then --vip积分奖励处理
            --levelInfo.vip = levelInfo.vip+v.val
            vipCoefficientMgr.ExpCoefficientForVip(uid,v.val)
        end
    end
    return levelInfo
end

--处理奖励信息
function awardHandlde(nUserinfo,levelInfo)
    ------------------------------------------------------------------------------------
    local mlevel = nUserinfo.property.level
    --计算金币奖励
    if mlevel<=levelLine then
        local rs= {}
        rs.status = 1
        rs.type = AWARDENUM.COIN
        rs.val = mlevel*TableLevelAward2.XiSuA     --暂时没有计算BUFF
        rs.time = 0
        table.insert(levelInfo.rs,rs)
    else
        local rs= {}
        rs.status = 1
        rs.type = AWARDENUM.COIN
        rs.val = (mlevel*TableLevelAward2.XiSuB-TableLevelAward2.XiSuC)  --暂时没有计算BUFF
        rs.time = 0
        table.insert(levelInfo.rs,rs)
    end
    ------------------------------------------------------------------------------------
    --处理vip信息,每5级有一个积分
    local mod = math.fmod(mlevel, 5)
    if mod==0 then
        ------------------------------------------------------------------------------------
        --vip加分
        local rs= {}
        rs.status = 1
        rs.type = AWARDENUM.VIP     --vip加分
        rs.val = TableLevelAward2.VipPoint
        rs.time = 0
        table.insert(levelInfo.rs,rs)
        --调用外部加入VIP积分
        --vipCoefficientMgr.ExpCoefficientForVip(levelInfo._id, TableLevelAward2.VipPoint)
        ------------------------------------------------------------------------------------
        --俱乐部积分处理
        --极限处理
        if mlevel>=TableLevelAward[#TableLevelAward].lv then
            local rs= {}
            rs.status = 1
            rs.type = AWARDENUM.CLUB     --俱乐部加分
            rs.val = TableLevelAward[#TableLevelAward].BasePoint
            rs.time = 0
            table.insert(levelInfo.rs,rs)
        else
            for i=1,#TableLevelAward-1 do
                if mlevel>=TableLevelAward[i].lv and mlevel<TableLevelAward[i+1].lv then
                    local rs= {}
                    rs.status = 1
                    rs.type = AWARDENUM.CLUB     --俱乐部加分
                    rs.val = TableLevelAward[i].BasePoint
                    rs.time = 0
                    table.insert(levelInfo.rs,rs)
                    break
                end
            end
        end
    end
    ------------------------------------------------------------------------------------
    return levelInfo
end
--处理是否应该有宝箱奖励部分  IsGet  是否是客户端主动点击
function handleBox(nUserinfo,levelInfo,IsGet)
    local mlevel = nUserinfo.property.level
    local nowlong = os.time()       --获取当前时间戳
    local isNeedSsend =false        --是否需要服务器反推
    --判断是否需要重新计算宝箱奖励
    if table.empty(levelInfo.boxs)  or nowlong>=levelInfo.boxTime then
        levelInfo.boxTime=0
        levelInfo.boxs={}
        levelInfo.sGameId=0
        local boxindex= levelInfo.boxindex
        local showLevel=0
        local box1=0
        local box2=0
        local box3=0
        if boxindex<=12 then
            showLevel=boxindex*15+5
            box1=boxindex*15+1*5+4
            box2=boxindex*15+2*5+4
            box3=boxindex*15+3*5+4
        else
            showLevel=boxindex*30-190
            box1=boxindex*30+1*10-190
            box2=boxindex*30+2*10-190
            box3=boxindex*30+3*10-190
        end
        if mlevel>=showLevel then
            isNeedSsend=true
            
            local TableLevelGame = Level.table_rolegame_game[1]
            --满足出现等级
            levelInfo.boxindex=levelInfo.boxindex+1
            --levelInfo.boxTime=nowlong+120*60
            levelInfo.boxTime=nowlong+Level.table_rolegame_game[1].SX*60
            for i = 1, 3, 1 do
                levelInfo.boxs[i]={}
            end
            --构建宝箱类型
            if boxindex==1 then
                --首次宝箱
                levelInfo.boxs[1].level = box1
                levelInfo.boxs[1].list={}
                levelInfo.boxs[1].list=packBoxAward(TableLevelGame.scjl1)
                levelInfo.boxs[1].status=0

                levelInfo.boxs[2].level = box2
                levelInfo.boxs[2].list={}
                levelInfo.boxs[2].list=packBoxAward(TableLevelGame.scjl2)
                levelInfo.boxs[2].status=0

                levelInfo.boxs[3].level = box3
                levelInfo.boxs[3].list={}
                levelInfo.boxs[3].list=packBoxAward(TableLevelGame.scjl3)
                levelInfo.boxs[3].status=0
            else
                levelInfo.boxs[1].level = box1
                levelInfo.boxs[1].list={}
                levelInfo.boxs[1].list=packBoxAward(TableLevelGame.cqjl1)
                levelInfo.boxs[1].status=0

                levelInfo.boxs[2].level = box2
                levelInfo.boxs[2].list={}
                levelInfo.boxs[2].list=packBoxAward(TableLevelGame.cqjl2)
                levelInfo.boxs[2].status=0

                levelInfo.boxs[3].level = box3
                levelInfo.boxs[3].list={}
                levelInfo.boxs[3].list=packBoxAward(TableLevelGame.cqjl3)
                levelInfo.boxs[3].status=0
            end
            boxindex=boxindex+1
        end
        unilight.update('userLevel',levelInfo._id,levelInfo)
    end
    --推送自动领取宝箱
    if table.empty(levelInfo.boxs) == false then
        local isupdate=false
        for index, value in ipairs(levelInfo.boxs) do
            if mlevel >= value.level and value.status == 0 then
                isupdate=true
                local send = {}
                send['do'] = 'Cmd.GetRecvBoxAwardCmd_S'
                send['data'] = Level.AutoRecvBoxAwardCmd(index,levelInfo,nUserinfo)
                if table.empty(send['data'])==false then
                    unilight.sendcmd(nUserinfo._id, send)
                end
            end
        end
        if isupdate then
            unilight.update('userLevel',levelInfo._id,levelInfo)
        end
    end
    if isNeedSsend and IsGet==false then
        --构成等级箱子出现,需要反推
        local send={}
        send['do']='Cmd.levelNewBoxArriveCmd_S'
        send['data']={
            errno = 0,
        }
        unilight.sendcmd(nUserinfo._id,send)
    end
    return levelInfo
end
--读取配置奖励宝箱返回
function packBoxAward(itemBoxCfg)
    local res={}
    res={
        goodId = itemBoxCfg[1].goodId,
        goodNum = itemBoxCfg[1].goodNum
    }
    return res
end
--判断是否需要升级 如有需要返回索引
function IsUpLevel(nLevel,nXp)
    local index = 1
    if nLevel>1 then
        index =  binarySearch(nLevel,TableLevelUp)
        index=index+1
    end
    local nextXp = TableLevelUp[index].Exp
    if nXp>=nextXp then
        return index
    else
        return -1
    end
end
-- 二分法查找 返回索引
function binarySearch( nLevel, t )
    local minIndex = 1  -- 数组最小下标，lua默认从1开始
    local maxIndex = #t-1 -- 数组最大下标
    local num = nLevel -- 要查找的值，请使用（value）
    local d = t
    local index = -1
    while true do
        index = math.floor( ( minIndex + maxIndex ) /2) -- 计算数组中间元素下标
        if num >= d[index].level and num<d[index+1].level then
            return index
        elseif num < d[index].level then
            maxIndex = index - 1
        else
            minIndex = index + 1
        end
    end
    return index
end



----------------------------------------------------公开接口----------------------------------------------------------------------------------------
--增加经验接口
function AddExp(exp,uid)
    if exp>0 then
        local levelInfo = GetLevelInfo(uid)
        local nUserinfo = unilight.getdata(Table_Userinfo,uid)
        if BuffMgr.GetBuffByBuffId(uid,Const.BUFF_TYPE_ID.PASS_CHECK)~=nil then
            --有通行证BUF,20%
            exp = exp*(1+0.2)
        end
        nUserinfo.property.exp=nUserinfo.property.exp+exp
        handleLevel(nUserinfo,levelInfo)   --处理奖励过程
        return 1
    end
    return 0
end
--获取等级加成系数对外接口,获取失败返回1
function GetXs(uid)
    local nUserinfo = unilight.getdata(Table_Userinfo,uid)
    local nLevel = nUserinfo.property.level or 0
    if nLevel<=0 then
        nUserinfo.property.level=1
        nLevel=1
        unilight.update(Table_Userinfo,uid,nUserinfo)
    end
    local index = binarySearch(nLevel,TableLevelXisu)
    if index==-1 then
        return 1
    else
        return TableLevelXisu[index].Level_XiSu
    end
end