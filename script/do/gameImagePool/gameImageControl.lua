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
local index = 0
function RealCommonRotate(_id,gameId,gameType,imageType,gameObj,param)
    local betchip = param.betchip

    local userinfo = unilight.getdata('userinfo',_id)
    local totalRechargeChips = userinfo.property.totalRechargeChips
    userinfo.point.chargeMax = 100000000
    userinfo.point.maxMul = 4000
    local controlvalue = gamecommon.GetControlPoint(_id,param)
    -- --获取rtp
   local rtp = gamecommon.GetModelRtp(_id, gameId, gameType, controlvalue)
   if gameId ==131 then 
        local betindex = param.betindex
        local betrtptable = gameObj['table_'..gameId..'_betrtp']
        rtp =  betrtptable[gamecommon.CommRandInt(betrtptable,'bet'..betindex)].bet_level
        --local rtptable = gameObj['table_'..gameId..'_rtpswitch']
       -- local rtp = 200 --没充值的直接走200
       -- if totalRechargeChips >0 then 
       --  rtp =  rtptable[gamecommon.CommRandInt(rtptable,'pro')].type
        --end 
   end 
    local imagePro = string.format("table_%d_imagePro",gameId)
    if imageType==nil then
        imageType = gameObj[imagePro][gamecommon.CommRandInt(gameObj[imagePro],'gailv'..rtp)].type
        local sfree = gameObj.gmInfo.sfree
        if sfree>0 then
            imageType = sfree
        end
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
    unilight.info('gameId.imageType.realMul',gameId,imageType,realMul)
    if gameId == 161 then
        if imageType == 1 then
            local curmuls = {7.25,0.5,24,0,0,0.5,0.25,3.5,0,8.25,1.75,0,0,0.5,0,0,0.25,0,7.5,0,0,1,0,0.5,0,0,7.5,0,0.5,0.25,0.5,0.5,5,0,5,13,0,2,0,0.75,0,0,2.75,0,1,0,0,0.25,7.5,0.5,0.5,0,20,0,0,2.5,0,4,0,8,0,0.5,0.25,0,1.5,0.5,0,0,7,0,3,0,0,0,0,1,0.25,0,0,0,0,0.5,6,4.25,1,0.25,0.25,0,0.5,0,1.5,1,0.25,2.5,0.5,0,0,0,0,0.5,4,2,0,0.25,0,0,0,2,1,0,0,0,0,0,0.25,0,0,0.25,0,9.5,1.5,0.5,0,0.5,3.5,1.5,0,45,0.5,0,0,20,0,0,0,0,0,1,0.5,1,0,1.5,0.75,12.5,0.5,0,0,0,0,2,0,0,0,0.5,9,0.5,0,1.25,4,0,0,0,0,0.5,1.5,5,0,3,0.75,30,0,0,0,4,0,0.5,0,0,0,0,0,0,7.5,3,0.75,0.5,0,0,2,2.25,3,5,0,1,0.25,0.25,0,0.5,0,0.5,0,0,0,1,0,1.5,0,0,4,1,4,0,0,0,0,12,1,0,4,1.25,0.5,6,0,15.5,0.5,1.25,0,0,0.25,4,0,0,0,16,10.5,0,0.5,7,5.5,0.75,15,0,0,0,0.5,3,4,2,0.25,2.5,1,0.5,0,0,0,4,1,0,0.5,0,0,0,0.5,5,0,0,1,0,0.5,2,30,0,2,0,0,0,0.5,0,0.5,0,0,0,0,2,0,0,1.25,8,0,2.5,0,0,4,2,0,0,4.5,0.75,0.5,0,2,0,0,10.5,0,0,0,0,0,0,0,0,0,4.25,0.5,2,2.5,0.5,0,6,0,1,6,0,0,0,30.5,2,0.5,0,0,2,0.25,0,0,1.5,0.5,0,0,1,0,0,0,0,0.5,0,3,0,0,0,4,0,0,0,7.5,0,0,0,0,0,0,0,3,0,0,2.5,0.5,0,4,0,0,0,2,0,0,1,1,6,0,0,0,0,1.25,1.5,0,0,0,1.5,1,0,20,0,7,0,2.5,2,0,4.5,0,5.25,4,0,0.75,0,1.25,0,2.5,0,0,0,16,1,1.25,0,0.5,0,0,0,0,2,0,0,16,4,6,0,0,4,0,0.5,0.5,1.25,0.5,0,2,6,2,0.5,0,0.5,0.5,0.5,0,1,0,0,2.5,2.5,0.5,0,1,0,0,0,0,0,0.25,0,0.25,1.75,0,0,0.5,0,0,2,1,0,3,0,4,0,0,0,1,4,0,0,0.75,0,0,0,2,0,1,0,2,1.25,2.75,2.75,0,0,0,0,2,0.75,10,0,0,0.25,1,0,0.5,2.75,0.5,0,12,0,1,0,2.5,0,0,0,0,2,0,8,11.5,0,1,8.25,0.75,0,0,0,0.5,0.5,2.25,15,7,0,0.5,0.5,0,16,0,0,2,0.25,6,0,0,2.5,0,0,0,23,0,5,1,0.5,4,0.75,0.5,0,0,1,2,17,0.25,0.25,0,1.5,1,0,7,0,8,4,0,0,8.5,0,0.5,0,0.5,2.5,0,0,0,0,5.5,1,0,0,0,9,6,5.25,2.75,30,0,0,0.5,0,1.25,4,0,0.5,2,0,0,0,0,0,0,0.5,0,1.5,0,0,15,0.5,12.5,7,1,0,0.5,0,0,1,0.5,1,0,0,11.5,0,0,0,0,0,0,0,0,0,6.5,4,0.25,6,0.5,1,0,1.5,0,0,0,1,0.5,40,1.25,0,3,0,0,0,0,0,7,1,2,0,6.25,5,0,0,0.5,10.5,7.5,1.25,11,9,0,0.5,0.5,0,0,1,1,2,1,0,1.5,10,0,0,0,0,0,2.25,2.5,0,1.5,10,2.25,0,0,1,0.5,3,2,0,0.5,0,0,0,0,1,0.25,0,15,0.25,0,0.5,0,2,0.5,1.5,0,0,8.5,0.5,0,0,0.25,20,0.75,0,0.25,0,3,1,0,0,0.5,1,0.25,1,0,7.5,0,1.5,0.25,1,2.5,0,0,0,0.25,2.75,16,0.25,9,0,0,0,0.5,0,0,11,0.5,0.25,2.5,0,2,0,0,0.5,3.75,0.5,0,0,1,8,0,0,1.5,0,0,15.25,0,0.25,0,0.75,1,0.5,0,0,4,5,0.5,0,0,12,0,1,0.5,0,0,0,4.5,0.5,0,0,0.5,0,1,1.5,2.5,0.5,0.5,0,5,4,0,0,10.25,0,0,5,0,0,21,0,0,0.5,0,1,0,0,2.5,1.5,1,0,0,0,0,0,0.25,0,0,1.25,0,0.75,0.25,0.75,0.25,0,0,0,0.5,0,0,1,1,0,0,0,0,0.5,0.5,0,0,2.5,0,0,0,0,1,3,8,0,0,20,0,4,2,0,2.5,1,0,0,0,0,2.5,0,2,1,0,0,2,0,3,2.5,0,1,0,1.25,1,0,0.25,0.25,0,0.25,1,0.5,0,3,0.5,40,0,0,0,0,0,0.75,1,0,0,0,1,0,0,4.5,2.25,5,0.25,1,0,1.75,1.5,0,0,0.5,0,10,0,2,0.75,0,2.5,2.5,1.75,0,0,0,0,2,0,1.5,0.5,1.75,0.5,0,0,0,0,20,2.25,0,0,0,0,0.5,1.5,1.5,2.5,1,0,25.5,2,1.75,0,30,0,0,0,0,1.5,0,0,0.25,0,0.25,0,0,0.5,0,0,0.75,1,1,0,1,1,0,0,0,5,0}
            realMul = curmuls[math.random(#curmuls)]
        end
        if imageType == 2 then
            local curmuls = {}
            realMul = curmuls[math.random(curmuls)]
        end

    end
    
    local jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
    if jsonstr=='' then
        unilight.info('norealmuljsonstr==',realMul,imageType)
        realMul = 0
        jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
        if jsonstr=='' then
            unilight.info('imageType,jsonstr==',realMul,imageType)
            imageType = 1
            jsonstr=go.ImagePools.GetOnePool(gameId,imageType,realMul)
        end
    end
    unilight.info('realMul',realMul)
    unilight.info('jsonstr',jsonstr)
    local jsonobj = json.decode(jsonstr)
    userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + betchip
    userinfo.gameData.slotsWin = userinfo.gameData.slotsWin + math.floor(realMul * betchip/gameObj.LineNum)
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