module('gameImagePool',package.seeall)
local table_autoControl_dc = import 'table/table_autoControl_dc'
local table_parameter_parameter = import 'table/table_parameter_parameter'
local table_auto_betUp = import 'table/table_auto_betUp'
--图库数据
--[[
    [gameId]={
        [type] = [mul] = info
    }
]]
math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
local poolMap={}
function loadPool(gameId)
    go.ImagePools.LoadImagePool(gameId,unilight.get_mongodb())
end

--[[
    gameObj 游戏模块
    param {betchip 押注值
    }
]]
local index1 = 0
local index2 = 0
local index3 = 0
local rmdayu0  = 0
local rmdayu1  = 0
function RealCommonRotate(_id,gameId,gameType,imageType,gameObj,param)
    local betchip = param.betchip
    local demo = param.demo
    local userinfo = unilight.getdata('userinfo',_id)
    local totalRechargeChips = userinfo.property.totalRechargeChips
    userinfo.point.chargeMax = 100000000
    userinfo.point.maxMul = 40000
    local controlvalue = gamecommon.GetControlPoint(_id,param)
    -- --获取rtp
   local rtp = gamecommon.GetModelRtp(_id, gameId, gameType, controlvalue)
   if not demo  then 
        local betIndex = param.betIndex
        local betrtptable = gameObj['table_'..gameId..'_betrtp']
        rtp =  betrtptable[gamecommon.CommRandInt(betrtptable,'bet'..betIndex)].bet_level
        unilight.info('@@@@betrtptablertp', rtp) 
        --local rtptable = gameObj['table_'..gameId..'_rtpswitch']
       -- local rtp = 200 --没充值的直接走200
       -- if totalRechargeChips >0 then 
       --  rtp =  rtptable[gamecommon.CommRandInt(rtptable,'pro')].type
        --end 
   else
        rtp = 200 
   end
    local imagePro = string.format("table_%d_imagePro",gameId)
    if imageType==nil then
        imageType = gameObj[imagePro][gamecommon.CommRandInt(gameObj[imagePro],'gailv'..rtp)].type
        -- local sfree = gameObj.gmInfo.sfree
        -- if sfree>0 then
        --     imageType = sfree
        -- end
    end

    --就计算玩家当前允许的最大倍数 改变了userinfo.point.maxMul的值
    -- getPlayerMaxMul(userinfo,betchip,totalRechargeChips,gameType,gameObj)
    --开始拼装配置表
    local tmpPoolConfig = {}
    local tableconfig = string.format('table_%d_rtp',gameId)
    local mulField =  string.format('type%d_%d',imageType,rtp)
    local gailvFiel = string.format('type%d_gailv%d',imageType,rtp)
    local tableOjconfig = gameObj[tableconfig]
    for _, value in ipairs(tableOjconfig) do
        if value[mulField]<=userinfo.point.maxMul and value[mulField]>=0 then
            table.insert(tmpPoolConfig,{
                mul = value[mulField],
                gailv = value[gailvFiel]
            })
        end
    end
    --执行随机    

    unilight.info('userinfo.point.maxMul',userinfo.point.maxMul,tableconfig,imageType,rtp,mulField,gailvFiel,#tmpPoolConfig)
    local realMul = 0
    if #tmpPoolConfig>0 then
        realMul=tmpPoolConfig[gamecommon.CommRandInt(tmpPoolConfig,'gailv')].mul
    else
        imageType=1
    end
    if gameId == 164    then 
        local curealmul = {100,2,1,5,15,12,8,25,50,0,3,4,10}
        realMul =curealmul[math.random(#curealmul)]
    end 
    if gameId == 163    then 
        local curealmul = {5,5,20,0,0,5,55,5,0,0,0,5,45,0,10,5,0,10,0,0,55,10,0,5,30,10,25,0,0,0,0,0,0,0,0,10,0,15,0,0,0,0,0,45,5,15,0,0,0,20,0,5,15,0,5,0,0,0,10,0,5,5,25,10,0,0,5,15,5,40,10,0,30,0,55,0,0,5,0,40,0,10,0,0,10,25,5,5,0,0,0,0,0,0,0,0,0,0,75,0,5,0,0,15,0,5,10,5,5,0,10,10,0,0,5,0,10,0,15,0,20,0,10,0,0,5,0,0,0,0,0,0,5,10,0,0,0,5,40,0,15,0,40,0,40,40,0,0,5,0,0,0,0,0,10,5,0,10,10,10,0,45,5,0,0,0,5,0,25,0,10,5,0,5,10,0,45,0,0,20,0,0,0,5,10,10,0,15,0,10,0,5,0,0,0,0,50,0,5,15,0,0,0,5,0,0,0,0,0,5,0,0,10,0,0,5,5,5,0,20,0,20,10,10,90,10,0,0,0,5,10,0,0,15,0,10,20,0,5,0,0,5,90,15,0,5,0,15,0,5,0,30,0,0,0,0,10,0,20,0,0,0,0,0,0,10,5,5,0,0,0,0,5,10,0,0,0,10,10,20,0,30,5,0,10,60,0,0,0,0,0,10,0,0,10,0,0,10,15,0,45,0,0,0,40,0,0,10,10,10,0,30,10,5,0,10,0,45,0,0,0,0,10,45,0,5,10,0,0,30,0,5,0,5,0,10,0,20,0,0,20,0,5,35,5,5,0,0,0,5,15,0,0,0,15,0,15,0,10,10,90,0,0,0,0,0,55,5,0,5,0,5,5,0,100,0,0,0,0,15,10,0,0,5,5,0,15,0,15,20,0,5,0,5,10,10,25,0,0,15,0,0,10,5,0,0,0,0,5,50,0,10,25,5,5,0,5,15,20,0,0,0,5,0,10,0,5,0,0,15,5,10,0,0,15,0,10,0,0,0,0,5,0,10,10,45,0,10,5,5,0,10,0,20,0,10,0,70,0,0,5,0,5,0,20,0,0,50,0,0,40,0,0,0,10,0,0,0,0,0,0,15,0,0,75,0,15,0,0,10,0,0,5,10,5,30,5,15,10,5,0,5,0,5,20,5,0,0,0,40,0,5,10,5,10,5,10,0,0,0,0,15,10,0,0,0,10,0,0,0,0,10,0,0,10,0,0,0,5,0,0,5,100,10,0,10,0,0,10,0,10,0,5,0,0,10,0,0,10,5,5,10,15,0,5,0,5,0,10,25,25,0,0,0,5,0,5,0,5,0,0,20,0,15,30,0,10,0,5,20,80,0,0,0,5,0,0,5,0,0,0,30,15,0,20,5,0,15,0,0,25,0,5,10,20,65,10,0,5,5,0,10,15,5,0,20,5,10,0,5,0,0,10,0,10,0,0,15,0,30,0,10,0,0,40,10,0,30,0,0,0,5,20,5,10,0,0,20,0,50,5,0,0,0,0,5,0,0,0,15,0,0,0,0,0,0,0,0,5,10,0,0,0,10,5,0,0,0,0,20,0,0,40,0,0,0,0,0,0,0,5,0,5,10,0,0,5,0,10,0,0,0,0,5,0,15,5,10,25,5,0,5,10,0,5,0,5,5,5,35,0,40,0,0,5,0,10,10,0,0,40,15,0,0,0,0,10,0,0,0,10,0,10,5,5,15,0,80,0,5,0,5,5,10,5,0,0,20,0,10,0,0,5,10,0,0,0,115,0,0,0,0,5,0,0,0,0,0,0,20,10,0,0,10,0,0,10,5,0,0,5,0,50,0,5,0,10,0,15,20,0,0,0,5,10,5,10,0,5,0,45,0,0,50,5,0,30,0,5,0,20,5,145,15,0,5,30,30,5,10,10,15,15,0,0,5,0,50,0,0,40,0,20,5,0,5,40,0,5,5,10,10,0,10,0,10,15,0,0,10,0,0,5,0,0,5,0,0,5,5,0,0,15,45,0,0,0,0,0,35,10,0,10,5,10,40,0,0,15,5,10,5,0,0,0,5,0,10,0,5,10,0,10,0,0,5,20,0,90,0,5,10,15,0,0,20,10,10,0,30,30,0,0,5,0,0,0,0,0,5,10,0,30,0,0,10,10,5,10,0,5,0,5,5,50,0,0,5,0,0,5,0,0,10,10,0,0,0,0,10,15,0,10,0,0,40,10,15,0,0,5,0,5,40,10,0,10,55,5,0,5,0,0,5,5,10,0,10,5,0}
         realMul =curealmul[math.random(#curealmul)]
    end
    if gameId == 126    then 
        local curealmul = {0,0.2,0.4,0.5,0.6,0.7,0.8,1,1.2,1.4,2,2.2,2.4,2.5,2.9,3,3.5,4,4.4,5,5.2,5.5,5.7,6,6.5,7.6,10,10.2,11}
        realMul =curealmul[math.random(#curealmul)]
    end 
    unilight.info('gameId.imageType.realMul',gameId,imageType,realMul)
    

    local jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
    if jsonstr=='' then
        unilight.info('norealmul imageType==',realMul,imageType)
        realMul = 0
        jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
        if jsonstr=='' then 
            unilight.info('RRRnorealmul imageType==',realMul,imageType)
            imageType = 1
            jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
        end
    end
    if imageType == 1 then 
        index1 = index1 + 1
    end 
    if imageType == 2 then 
        index2 = index2 + 1
    end 
    if imageType == 3 then 
        index3 = index3 + 1
    end 
    if realMul > 0 then 
        rmdayu0 = rmdayu0 + 1
        if realMul > 1 then 
            rmdayu1 = rmdayu1 +1 
        end 
    end 

    unilight.info('index1 index2   index3 rmdayu0 rmdayu1 ',index1,index2,index3,rmdayu0,rmdayu1)
    unilight.info('realMul',realMul)
    unilight.info('imageType',imageType)
    unilight.info('jsonstr',jsonstr)
    local jsonobj = json.decode(jsonstr)
    if not demo  then 
        userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + betchip
        if gameId == 137 then 
            userinfo.gameData.slotsWin = userinfo.gameData.slotsWin + math.floor(realMul * betchip)
        else
            userinfo.gameData.slotsWin = userinfo.gameData.slotsWin + math.floor(realMul * betchip*gameObj.LineNum)
        end 
    end 
    return jsonobj,realMul,imageType
end
--取出0倍图库
function getZeroImagePool(gameId)
    local jsonstr=go.ImagePools.GetOnePool(gameId,1,0)
    local jsonobj = json.decode(jsonstr)
    return jsonobj,0
end




function getPlayerMaxMul(userinfo,betchip,totalRechargeChips,gameType,gameObj)
    local chips =chessuserinfodb.GetAHeadTolScore(userinfo._id)
    local condition = 0
    for key, value in pairs(table_autoControl_dc) do
        if totalRechargeChips >= value.chargeLimit and totalRechargeChips <= value.chargeMax then
            condition = key
            break
        end
    end
    if condition <= 0 then
        condition = #table_autoControl_dc
    end
    local mul = table_parameter_parameter[20].Parameter
    local mul1 = 0
    local selfMul = userinfo.point.pointMaxMul or 0
    if mul>mul1 and mul1>0 then
        mul = mul1
    end
    if mul>selfMul and selfMul>0 then
        mul = selfMul
    end
    if userinfo.point.MiddleMul~=nil and userinfo.point.MiddleMul>0 and userinfo.point.MiddleMul<mul then
        mul = userinfo.point.MiddleMul
    end
    --计算玩家最大允许金币值
    --玩家最高上限
    --userinfo.point.chargeMax
    local chargeMaxMul = userinfo.point.chargeMax/betchip
    if mul>chargeMaxMul then
        mul = chargeMaxMul
    end
    userinfo.point.maxMul = mul
end