module("levelmgr", package.seeall)
Level=Level or {}
Level.table_rolegame_game = import 'table/table_rolegame_game'
Level.table_rolegame_goldbase = import 'table/table_rolegame_goldbase'
--等级模块小游戏处理
Table_Name = "userLevel"
Table_Userinfo="userinfo"
--获取初始界面显示信息
function SGameMainInfoCmd_C(data,uid)
    local sGameId = data.sGameId
    local levelInfo = GetLevelInfo(uid)
    local res={}
    local sObj = Level.GetSGame(levelInfo,sGameId)
    if table.empty(sObj) then
        return{
            errno=1,
            desc='参数错误'
        }
    end
    if sObj.num<Level.table_rolegame_game[1].cishu then
        --免费计算
        res={
            errno=0,
            G=Level.table_rolegame_goldbase[1].mianfeibase*6,
            M = Level.table_rolegame_goldbase[6].mianfeibase*6
        }
        res.G = chessuserinfodb.GetChipsAddition(uid, res.G)
        res.M = chessuserinfodb.GetChipsAddition(uid, res.M)
    else
        res={
            errno=0,
            G=Level.table_rolegame_goldbase[1].fufeibase*6,
            M = Level.table_rolegame_goldbase[6].fufeibase*6
        }
        res.G = chessuserinfodb.GetChipsAddition(uid, res.G)
        res.M = chessuserinfodb.GetChipsAddition(uid, res.M)
    end
    return res
end
--初始化小游戏场景
function InitSmallGameCmd(data,uid)
    local sGameId = data.sGameId
    local levelInfo = GetLevelInfo(uid)
    local sObj = Level.GetSGame(levelInfo,sGameId)
    if table.empty(sObj) then
        return {
            errno  =1,
            desc='小游戏请求非法'
        }
    end
    local nowTime = os.time()
    if nowTime>=sObj.sTime+24*3600 then
        Level.DelSGame(levelInfo,sGameId)
        return {
            errno  =1,
            desc='小游戏超过时限'
        }
    end
    local res={}
    --判断是否符合触发小游戏资格
    --判断3个宝箱是否领取完毕及时间是否到期
    local bl=true
    if bl then
        --读取配置初始化游戏
        local num = sObj.num
        --unilight.debug('index='..tostring(index)..',boxindex='..tostring(levelInfo.boxindex))
        --初始化记录序列
         local fruitprice={}
         local payFruitPrice={}
         --免费时候初始化的金币数量
        for i = 1, #Level.table_rolegame_goldbase do
            fruitprice[i] = Level.table_rolegame_goldbase[i].mianfeibase
            fruitprice[i] = chessuserinfodb.GetChipsAddition(uid, fruitprice[i])
        end

        for i = 1, #Level.table_rolegame_goldbase do
            payFruitPrice[i] = Level.table_rolegame_goldbase[i].fufeibase
            payFruitPrice[i] = chessuserinfodb.GetChipsAddition(uid, fruitprice[i])
        end
         local ispay = 0
         if num>=3 then
            ispay = 1
            if num%3==0 and levelInfo.ispaynum>=1 then
                ispay = 1
            elseif num%3==0 then
                ispay = 0
            end
         end
         num = num %3
        
         --读取配置初始化场景
         local SGInfo={
            gamenum=Level.table_rolegame_game[1].cishu,
            upperLeftId = Level.table_rolegame_game[1].shangcjl1[1].goodId,
            upperLeftnum=Level.table_rolegame_game[1].shangcjl1[1].goodNum ,
            upperRightId=Level.table_rolegame_game[1].zhongcjl2[1].goodId ,
            upperRightnum=Level.table_rolegame_game[1].zhongcjl2[1].goodNum,
            middleLeftVal=Level.table_rolegame_game[1].xiaczengjia     ,
            middleMiddletVal=Level.table_rolegame_game[1].xiacengfeil,
            middleRightval=Level.table_rolegame_game[1].xiacjbbs,
            playednum=num,
            fruitprice=fruitprice,
            payFruitPrice=payFruitPrice,
            tmpresult = sObj.tmpresult,
            ispay = ispay,
         }
         
         res={
            errno=0,
            desc='success',
            sg=SGInfo,
         }
         return res
    end
    res={
        errno=1,
        desc='不符合小游戏触发条件'
    }
    return res
end
--玩小游戏拉动play
function PlayBoxGameCmd(data,uid)
    local levelInfo = GetLevelInfo(uid)     --数据库获取内容，等级模块数据库
    local sGameId = data.sGameId
    local sObj = Level.GetSGame(levelInfo,sGameId)
    if table.empty(sObj) then
        return {
            errno  =1,
            desc='小游戏请求非法'
        }
    end
    local nowTime = os.time()
    if nowTime >= sObj.sTime + 24 * 3600 then
        Level.DelSGame(levelInfo, sGameId)
        return {
            errno = 1,
            desc  = '小游戏超过时限'
        }
    end
    local resdata = {}
    if table.empty(sObj.tmpresult) == false and sObj.tmpresult.isupper ~= nil then
        resdata = {
            errno = 0,
            desc = 'success',
            res = {
                upper = sObj.tmpresult.isupper,
                middle = sObj.tmpresult.ipsmiddle,
                lowGold = sObj.tmpresult.lowGold,
                lowindex = sObj.tmpresult.lowindex,
                preAdd = sObj.tmpresult.preAdd,
            },
            currGold = chessuserinfodb.RUserChipsGet(uid)
        }
        return resdata
    end
    local num = sObj.num or 0
    local ispay = 0
    --判断是否需要执行扣费
    if num >= Level.table_rolegame_game[1].cishu and num % Level.table_rolegame_game[1].cishu == 0 then
        if levelInfo.ispaynum == 0 then
            return { errno = 1, desc = '需要购买' }
        end
        sObj.tmpresult = {}
        sObj.tmpresult.preAdd = 1
        ispay = 1
        levelInfo.ispaynum = levelInfo.ispaynum - 1

    end
    resdata = {
        errno = 0,
        desc = 'success',
        res = {},
        currGold = chessuserinfodb.RUserChipsGet(uid)
    }
    local res = {
        upper = 0,
        middle = 0,
        lowGold = 0,
        lowindex = 0,
        preAdd = sObj.tmpresult.preAdd,
    }
    --执行随机金币
    local lowGold, lowindex = randGetIndexGold(ispay)
    res.lowGold = lowGold
    res.lowindex = lowindex
    local upperrandom = math.random(100)
    local lowerrandom = math.random(100)
    if upperrandom <= Level.table_rolegame_game[1].shangc or true then
        res.upper = 1
    end
    if lowerrandom <= Level.table_rolegame_game[1].zhongc then
        res.middle = 1
    end
    resdata.res = res
    sObj.num = num + 1
    --更新数据库
    sObj.tmpresult.isupper = res.upper
    sObj.tmpresult.ipsmiddle = res.middle
    sObj.tmpresult.lowGold = res.lowGold
    sObj.tmpresult.lowindex = res.lowindex
    sObj.tmpresult.preAdd = sObj.tmpresult.preAdd
    unilight.update(Table_Name, levelInfo._id, levelInfo)
    return resdata

end
--动画渲染完毕消息
function PlayBoxFinallyGameCmd(data,uid)
    --拉取数据
    local levelInfo = unilight.getdata(Table_Name, uid)     --数据库获取内容，等级模块数据库
    local sGameId = data.sGameId
    local sObj = Level.GetSGame(levelInfo,sGameId)
    if table.empty(sObj) then
        return {
            errno  =1,
            desc='小游戏请求非法'
        }
    end
    local resdata={}
    if table.empty(sObj.tmpresult) then
        resdata={
            errno=1,
            desc='游戏错误'
        }
        return resdata
    end
    local tmpresult=sObj.tmpresult or nil
    if tmpresult==nil then
        resdata={
            errno=1,
            desc='游戏错误'
        }
        return resdata
    end
    local resultGold=tmpresult.lowGold
    local twoGold=0
    local twoindex= 0
    local TableLevelGame = Level.table_rolegame_game[1]
    local upperleftinfo={}
    local upperrightinfo={}
    --如果判断了上层中奖信息
    if tmpresult.isupper==1 then
        local ojid=0
        local ojnum=0

        if data.upperIndex==1 then
             ojid= TableLevelGame.shangcjl1[1].goodId
             ojnum=TableLevelGame.shangcjl1[1].goodNum
             --upperleftinfo = ItemRandomMgr.GetRandomGroupByRandId(uid, ojid, nUserInfo.property.level , Const.GOODS_SOURCE_TYPE.BOX)
             local rupperleftinfo ={}
             rupperleftinfo = BackpackMgr.GetRewardGood(uid,ojid, ojnum, Const.GOODS_SOURCE_TYPE.BOX, rupperleftinfo)
             for key, value in pairs(rupperleftinfo) do
                table.insert(upperleftinfo,{goodId = key,goodNum=value})
             end
        else
            ojid= TableLevelGame.zhongcjl2[1].goodId
            ojnum=TableLevelGame.zhongcjl2[1].goodNum
            BackpackMgr.GetRewardGood(uid, ojid, ojnum, Const.GOODS_SOURCE_TYPE.BOX)
            table.insert(upperrightinfo,{goodId = ojid,goodNum=ojnum})
        end
    end
    if tmpresult.ipsmiddle==1 then
        if data.middleIndex==1 then
            tmpresult.preAdd = tmpresult.preAdd or 1
            tmpresult.preAdd = tmpresult.preAdd *(1+TableLevelGame.lowerGold/100)
            resultGold = tmpresult.lowGold*(1+TableLevelGame.lowerGold/100)*tmpresult.preAdd
        elseif data.middleIndex==2 then
            local num = sObj.num-1
            local ispay=0
            if num>TableLevelGame.cishu then
                ispay=1
            end
            twoGold,twoindex=randGetIndexGold(ispay)
        elseif data.middleIndex==3 then
            resultGold = resultGold*TableLevelGame.xiacjbbs/100
        end
    end
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, resultGold+twoGold, Const.GOODS_SOURCE_TYPE.LEVEL)
    resdata={
        errno=0,
        desc='success',
        twoinfo={index=twoindex,gold = twoGold},
        finallGold=twoGold+resultGold,
        currGold=chessuserinfodb.RUserChipsGet(uid),
        upperleftinfo=upperleftinfo,
        upperrightinfo=upperrightinfo,
        preAdd = tmpresult.preAdd,
    }
    local oldupperleftinfo = sObj.tmpresult.upperleftinfo or {}
    local oldupperrightinfo = sObj.tmpresult.upperrightinfo or {}
    local oldTGold = sObj.tmpresult.finallGold or 0
    sObj.tmpresult={}
    sObj.tmpresult.upperleftinfo =oldupperleftinfo
    sObj.tmpresult.upperrightinfo=oldupperrightinfo
    local num = sObj.num
    if num%3~=0 then
        if table.empty(resdata.upperleftinfo)==false then
            for index, value in ipairs(resdata.upperleftinfo) do
                sameOjAdd(sObj.tmpresult.upperleftinfo,value.goodId,value.goodNum)
            end
        end
        if table.empty(resdata.upperrightinfo)==false then
            for index, value in ipairs(resdata.upperrightinfo) do
                sameOjAdd(sObj.tmpresult.upperrightinfo,value.goodId,value.goodNum)
            end
        end
        sObj.tmpresult.preAdd = resdata.preAdd
        sObj.tmpresult.finallGold =oldTGold +resdata.finallGold
    else
        sObj.tmpresult={}
    end
    unilight.update(Table_Name,levelInfo._id,levelInfo)
    return resdata
    --chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, TableLevelGame.pay, "等级小游戏扣费")
end
--购物篮返回中了第几个购物篮
function randGetIndexGold(isPay)
    local TablelevelGold = Level.table_rolegame_goldbase
    local randnum = math.random(100)
    local pt=0
    local index=6
    for i = 1, 6, 1 do
        pt=pt+TablelevelGold[i].gail
        if randnum<=pt then
            index=i
            break
        end
    end
    if isPay==0 then
        --不付费
        return TablelevelGold[index].mianfeibase,index
    else
        return TablelevelGold[index].fufeibase,index
    end
end
--相同数据合并
function sameOjAdd(datas,goodId,goodNum)
    for index, value in ipairs(datas) do
        if value.goodId==goodId then
            value.goodNum = value.goodNum+goodNum
            return
        end
    end
    table.insert(datas,{goodId = goodId,goodNum = goodNum})
end