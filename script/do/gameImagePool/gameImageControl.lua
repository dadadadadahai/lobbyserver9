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
function RealCommonRotate(_id,gameId,gameType,imageType,gameObj,param)
    local betchip = param.betchip

    local userinfo = unilight.getdata('userinfo',_id)
    local totalRechargeChips = userinfo.property.totalRechargeChips
    userinfo.point.chargeMax = 100000000
    userinfo.point.maxMul = 4000
    local controlvalue = gamecommon.GetControlPoint(_id,param)
    -- --获取rtp
   local rtp = gamecommon.GetModelRtp(_id, gameId, gameType, controlvalue)
   if gameId ==131  or gameId ==127 then 
        local betIndex = param.betIndex
        local betrtptable = gameObj['table_'..gameId..'_betrtp']
        rtp =  betrtptable[gamecommon.CommRandInt(betrtptable,'bet'..betIndex)].bet_level
        unilight.info('@@@@betrtptablertp', rtp) 
        --local rtptable = gameObj['table_'..gameId..'_rtpswitch']
       -- local rtp = 200 --没充值的直接走200
       -- if totalRechargeChips >0 then 
       --  rtp =  rtptable[gamecommon.CommRandInt(rtptable,'pro')].type
        --end 
   end 
--    if  gameId ==127 then 
--       rtp = 100
--    end 
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
    if imageType == 1 then 
        index1 = index1 + 1
    end 
    if imageType == 2 then 
        index2 = index2 + 1
    end 
    if imageType == 3 then 
        index3 = index3 + 1
    end 
    unilight.info('index1 index2   index3 ',index1,index2,index3)
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