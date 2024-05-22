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
            realMul = curmuls[math.random(#curmuls)]
        end

    end
    if gameId == 160 then
        if imageType == 1 then
            local curmuls = {0,0,1.95,0,0.65,0,0.65,0,0,10,0,0.75,0.25,0.65,0.65,0.4,0,1.15,10.75,0.65,0.65,0,0.65,1.15,0.25,0.25,0,0,0,0,0,0,0,0,0.25,1.15,0.4,0.65,0.75,0,0,0,0.25,0,0,0.4,0,0,0.25,0.4,0.65,0.65,0.25,0,0.9,0,0.65,0,0,0,0,1.65,0,0,0.9,0,0,0,0,0,0,0,0,0.9,0,10.4,0.4,0,0,0,10,1.15,0,0,0,0,0.25,0,1.15,0.25,0.75,0.4,0,0,0,0.25,0,0.4,1.15,0,0.25,0,0,0.65,0,0,0.25,0,0.9,0,0,0,0,0.65,0,0,0,0.65,0,0,0,0,0,0,0,0,0.4,0,0.25,0.4,0,0,0,0.65,0,0,0,0,0,11.65,12.15,0,0.4,0,0,0,0,1.65,0,0.65,1.15,0,1.65,0,0,0,10,11.65,0,0,10.8,0,0,10.9,0.65,0,0.4,0,1.15,1.15,11.15,0,0,0,0,0.65,0,0,0,0.25,0,0.25,0.25,0.75,0,1.65,0,0,0,0,0,0.75,0,0,0,0.65,0,1.15,0,0.4,0.5,0,10.65,0,0,0,0,10.65,1.9,1.15,0.4,0,0,0,0,0,0,0,0,0,4.75,0.9,0.4,0,0,0,1.15,0.25,25.65,0.75,0,0,0,0.65,0,0.25,0,0,0.65,0.25,0,0,0.25,0,0,1.15,0.65,0,0.25,0.25,0.65,0.75,10,0,0,0.75,0.4,0,0.4,0,0,0,0.4,25,0,0,0.4,0.4,0,0,0,0,10,0.4,10,0.65,0,0,0,0,0,0,0.4,0,0,0,0,1.15,0,0.4,0,0,0,0,1.4,0.4,25.4,0,0,0.25,0,0,0.4,0,0,0.65,0,0,0.65,0,0,0.9,0,0,0,12.55,0.65,0,0,0.25,0,0,1.15,0.9,0.75,0,0,0,0,0.25,0.65,0.9,0,0,0,0.4,0.25,0.65,0,0.25,0,0.25,0,0,0,0.65,0.4,0,0,0,0,0,1.15,0,0,0,0,0,0,0,0,0,0.4,0,0.25,0,0.65,0,0,0,0.4,0.9,0,0,0,0,0,0,0,0.4,0.25,0.25,0,0,0,0.25,0,11.4,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0.4,0.9,12.15,0.25,0,0.4,0,0,10.65,0.25,0.25,0,0.25,0,0,0,0.25,0,0,0,0.25,0.4,0,0.65,0.25,10.9,0,0,0,0.25,0,0,0,0,0,0,0,25.65,0.65,11.15,0,0,10,0,0.65,0,0.25,1.15,0,1.15,0,0,10,0.25,0,0.65,10,0.25,0.25,0,0.25,0,0,0.25,0.65,0.75,0,0,0.4,0.4,0,0,0,0,0,1.15,0.25,0,0.65,0.4,0.5,0,1.15,0,0,0.25,0.25,0,0,0.75,0,0,0.65,0,0.25,1.15,0,0,0,0.65,0.75,0.65,1.15,0,0.65,0,0,0,0.9,0.9,0.65,0.4,0,1.15,0,0,0,0,0,0,1.65,1.15,0,0,0.4,0.4,0,0,0,0.25,0,0,0.65,0,0,1.15,0,0,0,0,0,0.65,0,0,0,0,2.75,0,1.65,0,0.25,0.25,0,0,0,0,0,0.4,0.25,0,10,0.9,0.4,0,1.15,0.4,1.15,0,0.65,0.25,0.25,0,0,0,10,0,0,0.25,0.25,1.65,0,0,0.25,0,0,0,1.15,0.25,0,0,0,0,0,1.4,1.15,0.25,0,0.4,2.65,1.15,0,10.4,0,0,0.4,0,0,0,0,0.25,0,0.4,0,0.9,0,0,0.4,0,0,10.9,0,1.65,0,0.25,0.4,0,0,1.15,0,0.75,0,0,0.25,0,0,0,0,0.65,0.4,0.4,0.25,0,0,0.9,0,0,1.15,0,10,0,0,0,0,0.25,0.25,0,0,0.4,0,0,0.4,0,0.9,1.15,0,0,0,10,1.65,0,1.15,0,0,0,0,0,0.25,0.4,0,0.4,0,0,0,0,0,0,0,0,0,0,0.75,0,10.65,0.25,0,10.65,0,0,0,0,0.4,0,0,0,0,1.15,0,0.25,0,0,0,1.15,0,0,0,0.65,0,0.25,0.25,0,0,0,0.65,0,0,0,0,0,0.65,0.4,0,0,0.4,0.65,0,0,0,0,0,0,0,10.65,0,0,0,0,0,0.4,7.4,0.25,0,0.4,0,0.65,0,10.65,0.4,0.75,0,0,1.65,0,0,0,0,10,0,1.15,0,0,0,0.4,1.65,1.15,0,0.25,0,0.25,1.65,0.65,0.4,0.65,0.65,0,0,0,0.9,0,0.25,0,0,0.65,0.4,0.4,0.25,0,0,0,0,0,0,0,0.25,0,0.25,0.25,0.65,0,0,0,0,0,0,0.25,0,0,0,0,0,0,10,0.65,0.25,0,0,0,0,0,0.75,0,0,0.5,0,0,0,0,1.15,0,1.15,0,0,0.25,1.95,0.25,0,0,0,0,0,0,0.4,0,1.15,0,0.75,0.25,1.15,0.75,0,0.65,0,0,0,0,0,0.25,0,1.15,0,0.4,0,0.9,0,0,0,1.15,0,0,0.4,0,0,0,0,0.25,0.65,0,0,0,11.15,0.9,0,0,0.4,0.75,11.65,0,0,0,0,0.25,0,0.9,0,0.25,0,0,0,0,0.4,0,0.25,0.65,2.4,0,0.4,0.25,0,11.15,0.65,0,0,0.9,0,0,0.25,0,0.25,0.65,0,0,0.75,0.25,0,0,0.4,0.25,0,10.9,0.65,0,0,0.65,0,0.65,0,0.4,0.4,1.15,0,0.4,0,0,1.45,1.15,0,0.25,0,0,0,0,0,1.15,0.75,0.9,0,0.65,0,0,1.15,0,0,0,1.15,0,0,0,1.55,0,0.75,0,0,0,0,0.65,0,0,0.25,0,1.15,0,0,0.25,11.15,0.25,0,0.25,0,0.4} 
             realMul = curmuls[math.random(#curmuls)]
        end
        if imageType == 2 then
            local curmuls = {69.1,39.6,146.95,94.65,16,77.45,58.2,128.95,80.6,32.5,62.7,34.85,82.8,109.25,24.45,29.75,58.9,112.85,16.05,102.7,63.95,53.7,43.4,52,37.35,46.2,27.2,32.2,52.65,45.45,74.5,44.05,111.7,25.75,118.65,37.65,24.6,28.4,42.5,181.3,130,61.8,71.7,34.85,94.15,83.4,83.95,71.4,118.65,32.35,37.75,18.15,27.1,20,53,17.95,103.5,10,32.8,87.3,11.75,73.95,12.65,58.15,58.5,150.1,19.45,63.35,52.15,26.8,22.8,19.5,59.8,35.7,20.15,44.65,138.85,18.25,22.95,36.95,65.25,236.55,17.55,18.9,45.25,43.2,70.55,52.3,20.1,90.9,54.9,39.95,76.1,96.15,18.8,8.3,17.1,42.9,80.3,18.55,14.4,39,17.3,23.15,28.9,15.15,29.05,45.85,25.75,64.8,15.7,233.6,67.35,41.2,46,94.55,79.25,68.65,54.2,56.1,49.7,52.75,20.4,78.3,80.35,26.65,68.05,92.2,74,43.3,47.65,55.55,25.05,54.5,32.75,10.8,89.75,25.1,32.85,144.95,70.65,39.15,302.7,179.45,98.3,141.15,53.15,37.75,201.55,59.25,51.3,48.9,37.25,90.35,222.15,39.35,65.65,30.6,28.05,37.4,37.25,24.5,20.95,37.25,38.2,24.25,31.65,138.2,78.2,67.5,21.1,301.65,15.45,72.5,93.85,68.4,74.25,86.65,23.75,42.25,58.9,41.6,60.65,215.65,52.75,40.35,36.5,12.15,20.65,19.9,43.45,42.2,46,54.5,57.8,23.8,60,53.7,166.05,47.25,64.7,108.6,44.4,58,81.5,64.55,28.65,141.7,22,12.1,141.85,26.9,30.3,33.4,93.4,9,15.7,129.1,123.75,20.75,51.75,106.25,31.1,44.05,50,90.05,12.4,182.45,26,60.85,10.1,11.4,38.65,69.8,119.2,18.6,28.65,29.3,42.35,203.4,10.45,109.65,28.45,37.05,26,113.1,34.3,18.75,86.2,27.7,16.05,33.85,53.3,89.05,45.25,24.95,53.05,20,41.1,35.65,32.2,58.55,93.25,20.5,84.6,43.7,27.7,60.25,34.8,123.25,219.55,63.4,22.25,22.55,167.1,52.35,52.65,45.95,37.65,47.4,52.9,59.1,41.4,20.45,137.45,61,142.65,52.15,65.65,40.75,31.85,123.75,49.1,56.2,38.2,28.5,47.5,125.6,24.3,38.7,47.35,275.05,100.9,38,30.7,50.05,58.6,148.3,51.25,52.95,13.3,73,78.4,157.4,306,150.95,94.65,24.5,17.85,123.5,19.45,74.2,29.35,16.3,155.95,97.3,30.15,17.9,103.95,114,26.45,34.05,98.05,209.65,51.1,50.45,121.2,30.8,47.2,58.4,57.4,39.5,110.1,118.15,37.55,166.6,70.05,23.75,47.8,62.55,101.2,16.15,212.5,20.7,18.5,84.7,47.65,41.55,119.15,68.4,208.9,39.6,48.95,20.7,213.7,138.4,34.3,10.25,26.35,27.85,110.95,29.1,57.7,15.25,73.15,17.55,10.15,159.45,43.65,65.15,85.45,140.85,21.15,31.25,85.3,46.35,80.95,15.9,57.95,97.7,90.35,61.95,78.25,24.45,35.1,14.85,99.95,97.1,138.25,18.05,76.45,33.15,56.9,22.5,13.55,21.65,43.05,18.55,60.05,22.4,11.4,78,29.6,83,38.3,36.6,25.8,55.65,46.6,91.25,13,25.05,26.55,19.65,42.8,139.5,32.9,42,26.5,27.5,35.35,53.8,162.95,33.35,53.3,16.95,69,39.3,24.65,8.65,8.65,167.65,22.5,104.6,104.8,257.75,25.15,115.95,22.9,32.55,20.3,36.4,21.05,49.6,110,209.95,88.05,14.6,188.4,17.1,163.15,40.2,131.25,18.65,232,148.5,24.25,25.7,18.75,11.05,36.9,69.6,41.95,116.8,33.25,13.45,34.05,24.65,71.15,54.25,43.55,34.2,32.05,53.75,31.35,21.95,17.35,24.35,42,35.1,15.95,45.4,118.55,74.4,62.45,27.95,39.55,33.9,64.75,53.55,67.15,47.6,53.4,122.65,15.5,176.75,101.75,24.25,110.15,39,46.95,28.25,12.25,55.1,30.4,33.4,42.95,22.7,54.35,55.7,90.6,22.95,32.3,62.05,83.35,44.35,85.3,128.75,177.05,70.5,34.25,111.65,17.05,12.65,122.25,44.55,24.65,24.45,114.1,41.3,57.75,34.3,110.1,80.2,24.95,46.25,13.5,231.45,237.35,59.8,51,72.9,12.6,68.8,91.25,82.75,23.1,36,25.05,86.45,18.95,57.8,20.95,53.45,36.05,39.15,90.25,79.6,11,45.85,57,15,57.5,79.25,25.7,267.8,50.45,131.3,21.45,170.05,126.7,67.55,82.25,82.5,293.65,36.4,18.1,68.65,93.3,71.05,31.05,53.1,22.15,129.3,38.3,49.25,6.8,14.9,69.3,29.35,28.85,113.35,183.8,28.75,74.35,8.9,20.55,89.75,65.95,51.35,83.25,183.75,35.7,83.7,60.6,45.95,12.95,102.15,196.3,16.4,80.25,29.95,76.45,91.8,49.3,21.4,30.85,46.25,115.55,75.9,28.05,48.8,11.15,69.7,29.8,57.45,39.75,44,22.25,42.4,67.6,127.25,59.3,72.05,90.75,12.3,21,20.4,40,52.75,119.9,35.3,29.9,30.15,68.95,76.2,259.45,45.55,178.3,30.25,55.65,89.8,46.2,186.85,72.35,162.05,9.65,14.75,186,107.7,226.25,30.1,43.65,12.8,83.75,40.3,40.85,21.05,39.25,45.2,28.85,41.35,10.75,12.5,93.85,35.2,107.2,30.5,9.3,93.8,43.25,120.65,20.7,201.8,10.25,160,31.1,6.65,14.25,43.4,33.6,28.65,12.6,301.05,6.25,73.95,58.2,34.8,11.15,28.1,75.5,42.65,18.95,15.15,61.2,10.65,29.2,8.15,82,42.7,17.95,111.85,52.25,16,185.6,124.4,33.1,27.05,6.25,60.1,29.25,49.65,68.7,12.5,27.9,172.7,36.7,45.1,32,23.5,57,22.1,46.7,116.4,47.1,19.1,29,12.65,41.9,53.7,36,20.55,67.75,63.95,37.55,33.75,71.6,16.8,58.65,260.6,204.35,89.5,33.45,188.05,25.6,18.55,59.7,49.85,233.85,13.4,33.75,179.45,19.75,30.25,20.2,52.15,46.5,16.5,33.45,126.3,48.2,14.85,47.1,41.55,20.55,23.5,29.1,176,72,36.3,28.85,21.1,56.25,36.95,37.35,14.45,60.65,69.8,55.5,19.25,78.95,13.5,10.8,70.7,56.2,59.7,63,29.55,32.1,90.2,34.55,54.95,54.1,21.75,10.5,31.5,24.2,88.75,20.75,142.3,136.4,300.4,102.05,17.8,91.9,109.1,40.7,49,11.6,71.75,31.05,55,58,91.85,299.45,179,87.8,72,110.65,24.3,20.15,111.05,97.6,54.65,54.2,55.8,36.8,16.55,18.6,161.05,33.65,53.75,34.35,25.3,43.4,54.95,16.15,23.1,46.5,103.45,28.35,59.3,60.8,61.15,75.5,23.8,17.35,25.85,13.8,28.15,15,85.4,130.65,24.1,34.9,72.35,100.15,106.55,23.8,20.6,68.8,15.85,11,24.5,70.9,32.35,109.5,138.9,65.6,19.85,193,58.7,53.45,23.5,87.15,18.2,90.2,43.95,105.1,62.5,36.1,27.55,44.9,64.4,66,32.5,256.45,42.65,58.2,20.9,29.8,31.9,295.7,80.1,169.55,54.35,42.85,54.65,91.25,79.65,23.8,130.85,42.65,11.15,267.8,19.05,96,31,24.5,32.2,49.65,36,58.15,17.25,17.4,20.6,37.55,74.45,75.1,264.55,51.7,76.95,43.5,133.7,216.95,18,31.35,288.75,51.5,43.9,67,182.5,37.65,21,97.8,45.45,149.65,100.05,150.3,119.05,39.5,49.3,26.7,30.05,92.45,40,56.2,17,68.05,201.3,21.8,90.95,203.2,20.7,48.9,31.95,62.15,19,19.35,55.75,92.1,44.15,64.1,67.8,50.3,77.15,42.1,210.45,42.15,135.4,61,104.45,20.4,23.55,61.5,40.5,83.7,34.8,85.1,27.6}
            realMul = curmuls[math.random(#curmuls)]
        end
        if imageType == 3 then
            local curmuls = {70.55,76.3,49.5,34.2,21.05,91.1,24.15,97.15,33.05,45,76.15,197.4,64.5,27.95,62.05,37.35,163.2,142,31,177.2,114.25,55,28.45,27.3,8.65,29.65,60.1,202.6,41.95,19,43.4,64.55,140.3,56.2,35.05,41.35,14.3,93.85,65.55,57.65,13.85,66.75,57.4,116.25,194.45,14.25,56.55,21.2,11.8,55.6,64.75,14.5,16.15,101.15,38.1,15.95,117.2,37.95,17.05,188.55,110.05,57.1,125.05,35.2,37.8,53.4,70.5,21.85,28.65,9.9,63.15,18.2,37.25,81.8,64.4,61.1,62.4,28.95,51.9,29.75,41,34.5,80.85,89.75,42.05,11.05,25.55,221.7,65.8,113.85,36.55,11.7,186.9,29,18.55,12.35,16.6,157.1,63.8,69.4,114.4,27.4,79.25,183.8,61.2,33.35,80.1,114.2,112.15,85.15,90.35,17.45,16.85,46.05,47.2,18.5,20.45,256.45,48.95,94.3,44,41.55,87.55,47.85,102.5,36.05,46.5,291.9,94.8,24.15,128,20,51.45,99.25,37.25,10.75,24,34.7,94.3,166.25,71.4,23.8,18.2,46.1,33.4,54.25,24.2,51.2,24.2,77.35,35.95,102.3,25.5,21.5,126.25,51.45,80.2,32.6,61.65,15,26.7,42.3,60,156.05,22.2,96.9,151.65,36.35,8.15,49.7,104.6,69.5,88.6,155.95,43.75,136.9,17.95,39.05,35.5,17.85,62.45,39.25,34.65,145.95,50.8,127.8,50.5,31.85,82.45,291.85,16.65,51.25,61.95,221.4,32.15,217.25,17.9,18.7,18.25,91.1,21.7,36.45,15.9,66.75,63.6,97.8,28.5,131.6,109.05,50.7,27.2,46.7,39.8,21.7,80.4,57.75,88.5,35.4,26.8,37.9,95.7,17.75,28.65,35.05,48.15,60.25,51.4,70.2,71.45,61.8,33,150.85,31.95,62.35,55.4,48.7,24.65,125.35,76.05,257.5,53.4,71.55,33.9,171.1,24.85,38.4,52.5,78.85,25.9,34.45,11.1,27.25,103.7,47.65,16.2,58.35,299.8,60.35,20.25,24.75,53.45,22.5,44.85,127.35,45.8,15.4,76.95,93.15,52.7,77.5,241.3,25.35,33.2,31.95,19.4,98.25,35.1,40.25,81,22.65,183.55,31.1,63.5,148.7,32,36.9,30.65,54.05,63.6,102.8,114.45,32.3,54.15,58.2,26.65,153.15,81.3,77.8,28.9,36.7,45.15,25.75,116.3,18.5,53.8,242.65,60.9,242.25,25.65,43.45,123.15,64.9,110,50.2,44,28.25,73.55,50.2,32.9,56.35,46.55,44.25,17.15,76.1,23.8,103.45,24.55,35.2,41.8,73.75,16.85,12.2,62,22.8,18,85,27.55,6.65,55.95,11.8,57,39.35,9.95,42.2,47.85,78.65,54.1,27.2,31.25,66,142.05,54.8,40.4,21.2,81.75,68,14.05,37.7,12.3,28.1,12.2,139.25,81.15,12.6,55.65,87.4,113.65,36.1,30.7,20.6,54.05,141.6,27.6,14.45,36.05,113.45,100,28.5,40.25,16.8,26.35,39.1,44.2,106.4,44.1,27.8,75.25,117.75,91.55,51.8,17.7,38.1,26.25,31.4,50.1,131,77.9,25.3,44,10.8,37.1,14.7,8.3,86.7,112.5,158.9,85.55,296.8,79.4,77.3,76.85,67.45,21.4,38.05,80.7,84,105,34.2,25.65,84.8,216.8,78.9,36.45,93.6,47.1,246.7,31,28.8,29.35,53.4,44.25,76.45,51.95,22.7,26.7,26.4,14.65,46.45,17.5,56.3,21.15,70.25,24.45,86.95,45.1,28.15,52.7,93.9,120.05,104.25,46.7,34.2,64,24.95,13.4,20.4,76.6,88.3,39.2,49.3,28.35,18.25,9,100.25,108.7,49.4,48,66.95,39.4,47.05,235.5,12.5,76.85,9.2,60.35,15,41.8,55.45,45.25,25.1,84.5,35.45,29.55,56.65,46.5,68.8,85.1,33.8,19.55,28.2,88.45,73.95,59.05,252.2,126.1,36.35,10.35,62.1,28.05,20.7,38.2,32.4,43.6,70.3,40.3,68.95,26.3,33.9,43.4,106.4,85.7,76.9,18,305.95,108.35,96.45,115.7,92.25,69.7,70.3,65.9,38.85,46.8,27.75,40.4,82.8,41.6,34.35,44.9,148.5,51,42.75,92.55,37.45,16.1,21.95,88.65,41.7,275.2,27.35,229.9,203.55,241.45,23.85,104.3,25.25,65.45,30.1,48.5,55.5,41.7,112.25,28.85,274.65,64.05,81.1,12.55,64.75,68.6,41.1,82.7,44.1,91.65,115.1,31.35,9.15,132.45,60.65,41.4,132.6,10.65,22.3,25.6,310.15,68.65,147.55,109.95,74.6,57.1,13.1,68.45,63.85,168.35,91.65,58.3,272.3,43,86.65,114.3,38.4,115.7,26.95,28.3,55.2,27.95,54.9,87.2,17.2,17.75,103.8,67.2,102.75,44.8,14.75,18.5,24.05,27.65,122.45,9.55,15,178.8,45.15,90.2,117.6,138.7,26.7,19.05,66.4,199.55,22.95,150.5,30.25,9.7,34.15,13.6,72.4,31.75,33.5,48.2,27.9,126.75,86.25,27.65,37.4,29.45,58.35,30.4,43.55,17.9,51.55,21,146.65,24.65,66.9,21.3,41.2,35.6,26.1,11,21.85,269.6,33.15,7.9,16,14.2,151.5,42.85,79.75,131.65,21.7,21.45,47.35,106.9,34.3,53.5,150.8,57.9,68.05,131.7,39.7,172.5,75.75,171.2,30.9,76.55,30.9,32.05,11.4,203.5,46,6.65,70.2,121.05,43,39.75,21.7,32.5,49.75,24.55,62.7,39.9,207.8,155.55,38.45,36.85,33.3,70.5,25.2,132.7,32.25,27,27.15,202.75,56.3,121.1,118.6,40.05,32.8,18.9,146.75,27.25,73.35,110.2,26.65,121.45,78.75,11,74,65.25,42.15,26.5,25.05,87.85,21,100.5,32.05,50.1,74.95,133,26.7,111.25,28.4,137.25,102.3,22.75,33.9,106.35,52.35,11.55,139.45,47.85,27.2,40.05,9.2,84.45,50.15,11.4,71.3,89.15,20.2,42.7,86.7,83.85,44.5,40.05,19.9,15.2,20.05,101.4,22.65,33.2,56.35,30.5,47.8,27.6,15.8,38.25,31.9,18.95,9.5,68,150.9,42.55,109,220.95,49.8,15.7,119.8,53.5,37.05,16.95,46.9,58.9,24.7,47.55,92.35,190.8,92.15,29.4,27.3,22.8,51.6,105.05,29.1,29.6,32.6,52.85,32.25,48,105,22,125.45,39.65,44.55,20.3,27.25,24.1,7.6,20.5,34.5,20.9,99.15,37.9,14.8,304.75,43.7,65.1,151.8,35.45,81.6,35.95,37.05,38.85,207.85,74.2,26.5,111.35,99.85,170.1,113.15,96.5,25.45,130.9,31.65,30.95,42.6,273,85,30.05,70.45,35.75,56.05,18.75,147.95,13.5,84.05,120.45,94.45,31.55,86.65,86.9,39.9,72.95,40.3,29.9,47.6,269.2,26.8,87.9,41.85,38.85,152.25,9.75,17.75,164.3,68.7,126.5,186.05,70.4,276.7,87.55,35.35,153.55,17.75,21,63.75,29.8,68.2,17.55,31.5,46.15,62.15,81,32.75,34.15,18.7,51.45,14.05,198.2,63.2,59.2,12.75,56.35,23.5,113.45,41.45,25.45,91,86.1,53.1,21.5,30.45,21.65,72.85,84.65,30.25,64.65,85.55,236.55,40,58.4,24.1,71.4,108.85,65.2,45.55,73.25,61.1,90.85,22.3,49.9,23.85,97.45,58.6,16.75,28.25,158.2,24.55,33.7,215.9,40.9,37.65,71.5,76.1,26.5,26.05,47.9,71.4,20.3,36.7,228.4,39.35,55.9,26.8,75.15,35.75,62.4,65.75,87.25,38.15,27.2,29.65,28.65,15.25,154,40.45,194.5,31.9,75.45,137.6,44.55,31.65,9.4,30.45,50.05,13.25,17,19.9,58.8,22.55,61.7,25.85,27.15,29.1,39.1,56.3,123.7,60,47.35,50.1,114.95,64.85,32,53.45,225.9,59.55,28.1,15.8,46.6,14.25,51.2,23.7,81,39.75,15.25,23.8,70.3,33.4,11.45,33}
            realMul = curmuls[math.random(#curmuls)]
        end
    end
    if gameId == 162 then
        if imageType == 1 then
            local curmuls = {0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0.2,0,0,0,0,0,0,0,0.4,0.5,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0.25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0.2,0,0,0,0,0,0.2,0,0,0.4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0.2,0,0.2,0,0.5,0,0.25,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0.2,0,0,0,0,0,0,0,0.25,0,0,0.2,0,0,0,0,0.2,0,0,0,0,0,0,0.2,0,0,0,0.5,0.2,0,0,0,0,0.2,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0.2,0,0,0,0,0,0,0,0,0,0,0.45,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0.25,0,0.25,0,0,0,0,0,0,0,0,0.2,0,0,0,0.2,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0.5,0,0,0.2,0,0,0,0.4,0,0,0,0,0,0.3,0,0,0,0,0,0,0,0,0,0,0,0,0.4,0.25,0,0,0,0,0.2,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0.2,0.3,0,0,0.8,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0.45,0,0,0,0,0.25,0,0,0,0,0,0,0,0.45,0,0,0,0,0,0,0,0,0.2,0.25,0,0,0,0,0,0,0,0,0,0.4,0,0,0,0,0,0.4,0.2,0,0.2,0,0,0,0,0,0,0,0.2,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0.2,0,0,0.2,0.4,0.2,0,0,0,0,0,0,0,0,0,0.25,0,0.25,0,0,0,0,0,0.2,0,0,0,0,0.2,0,0,0,0,0.2,0,0,0,0.45,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0.5,0.2,0.2,0,0,0.25,0.2,0,0,0,0.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0.5,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.45,0.2,0,0,0,0.2,0,0,0,0.25,0,0,0.2,0,0.5,0,0,0,0.2,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0.3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0.2,0,0.45,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.7,0,0,0.2,0.2,0,0.2,0,0,0,0,0,0,0,0.2,0,0,0.2,0,0,0,0,0.2,0,0,0.5,0,0.4,0,0,0.2,0,0,0.2,0,0,0,0,0.2,0.3,0,0,0.4,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.25,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0.45,0,0,0.4,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0.2,0,0.25,0,0,0,0,0,0,0,0,0,0,0.2,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0.2,0,0.2,0,0,0,0,0,0.4,0,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0.2,0.4,0,0.2,0.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0.2,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0.2,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.2,0,0.2,0,0.2,0,0,0,0,0,0.2,0.25,0,0.2,0,0,0,0,0,0.5,0,0,0,0,0.2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
                 realMul = curmuls[math.random(#curmuls)]
        end
        if imageType == 2 then
            local curmuls = {50.4,40.2,41.1,15,68.3,35.9,73.6,25.95,73.4,36.6,93.55,37.7,82.75,60.75,44.35,72.6,77.3,67.2,41.6,118.1,22.45,88.6,140,22.45,30.8,39.4,47.25,124.65,45.6,36.45,97.45,39.75,18.85,59.65,55.3,69.75,47.35,46.05,74.95,33.3,27.85,109.15,14.75,66.55,40.8,32.65,17.3,215.2,83.35,91.9,19.05,113.4,84.1,34.55,23.9,88.85,29.1,199,64.05,35.05,45.65,62.15,52.5,63.65,33.65,176.3,56.55,231.8,94.75,15.9,68.55,36.7,28,84.9,101.05,79.95,19.05,37.9,45.45,24.95,47.15,37.85,66.05,84.2,16.65,83.2,58.7,45.35,112.75,35.05,24.65,158.3,51.7,77.85,47.75,37.85,59.7,43.95,49.25,55.7,43.05,52.65,49,49.65,95.35,41.2,303.7,39.4,59.65,16.45,71.05,200.9,45.85,82.6,301.45,30.1,41.05,31.15,24.75,41.65,120.6,21.35,96,108.6,49.65,178.65,17.9,34.35,47.65,103.7,143.85,80.75,167.35,38.55,47.95,16.5,92.25,28.1,42.6,49.05,252.25,31.75,42.05,191.95,41.45,58.65,29.8,32.95,38.4,48.55,274.05,65.25,77.4,34.3,20.65,28.7,35.75,147.15,20.55,54.55,47,19.15,13.6,51.45,35.25,38.7,114.45,37.9,154,55.45,22.25,94.4,21.95,124.75,58.45,52.25,29.8,30,54.4,189.9,53.2,57.5,46.9,103.35,46.7,86.95,32.4,91.65,29.45,36.75,73.05,27.65,56.45,26.6,17.9,94.25,51.5,27.95,49.05,25.25,49.25,46.95,43.8,19.4,64.2,84.3,47.3,100,20.4,69.2,79.2,42.2,99.15,62.9,63.2,28.45,97.5,37.4,20.6,37.45,251.35,57.25,57.1,44.45,283.4,69.4,38.1,112.55,107.4,35.3,57.4,53.75,32.85,33.3,58.1,173.85,32.75,43.4,75.15,79.15,37.05,51.15,71.35,24.85,17.25,43,103.7,237.25,33.95,148.7,41.85,43.65,37.25,40.35,25.15,53.15,208.05,55.5,47.3,64.35,48.65,84.8,37.85,27.05,33.85,23.2,36.9,73.35,33.15,32.8,41.5,32.1,34.6,76.15,124.5,98.75,55.8,138.45,117.95,70.65,82.85,66.65,89.85,94,97.45,16.85,22.3,77,37.5,37,143.4,37.15,98.9,52.85,29.3,35.6,83.75,99.7,38.85,52.4,34.55,62.25,27.8,176.45,118.7,18.75,19.8,68.45,258.5,89.65,118.9,100,68.7,24.35,41.25,74,26.4,55.15,59.3,101,81.8,37,16,77.6,31.7,43.15,51.25,30.05,92.05,34.25,29.7,38.9,116,56.55,36.6,139.7,53.55,36.95,70.8,76.25,56.7,201.7,33.85,69.6,86.6,71.5,87,27.35,60.35,25.6,55.45,92.65,24.25,58.8,143.75,52.8,88.75,26.55,32.6,97.15,93.6,270.25,33.8,22.35,93.25,34.85,79.25,143.05,43.15,81.1,62.2,58.15,137.9,53.75,30,50.75,28.35,43.95,39.45,185.45,186.1,24.6,55.95,72.85,88.65,49.15,136.55,38.05,111.95,54.35,39.85,104.9,24.75,63.5,25.75,41.75,30.6,20.5,92.05,32.7,85.3,30.05,52.5,66.4,38.8,25.7,49.85,21.95,20.8,45.8,107.6,20.75,97.05,38.7,99,55,69.5,86.8,35.15,44.35,53.7,75.55,32.9,76.25,43.45,54.15,37.2,66.6,42.35,53.55,27.9,25.75,80.85,48.4,28.25,37.75,31.6,43.6,53.1,50.05,112.65,64.25,149.4,66.8,32.5,295.95,36.6,122.55,44.6,16.35,119.9,76,21.5,45.45,319.95,73.4,24.95,42.7,39.55,51.6,41.95,35.55,20.65,21.9,65.45,153.9,32.7,78.75,41.6,64.45,81.05,62.05,23.85,152.45,37.25,30.25,83.95,22.3,216.1,61.15,71.4,42.3,40.25,54.5,72.4,49.65,59.4,41.05,161.8,44.75,63.7,62.4,80.5,57,33,30.75,141.7,52.35,28.6,19.4,42.7,17.35,54.3,43.3,26.45,29.55,47.8,106.65,132.65,33.45,56.85,43.2,45.45,58.15,104.55,37.65,140.55,109.3,39.05,51.6,26.1,39.45,95.45,22.45,20.15,51.2,16.05,24.9,25.15,29.55,79.25,151.5,31.45,61.45,25.2,67.1,58.85,43,39.35,32.6,63.7,242.6,47.8,48.3,58.45,28.5,20.95,19.15,28.6,27.45,79.15,25.35,70.15,106.5,193.9,31.75,38.5,46.35,59.45,128.15,52,30.15,88.05,50.7,28.8,70.75,20.45,52.35,24.9,42.3,32.5,123.65,20.45,70.9,46,30.2,37.4,80.05,96,76.9,32.9,25.75,34.65,78.5,27.85,39.25,66.95,84.65,54.75,19.25,28.65,32.55,42.35,90.25,36.15,27.4,29.2,71.65,19.55,43.55,37.65,59.65,90.6,90.8,62.7,27.1,24.25,62.3,41.35,33.1,92.8,18.8,23.9,24.65,94.35,22.35,48.85,32.55,50.2,66.4,19.6,80.2,47.3,111.4,46.6,91.8,82.95,34.3,47.35,73.7,28.6,35.8,217.85,53.35,43.8,70.2,111.95,39.45,124.95,43.45,34.75,156,32.1,20.15,18.05,40.2,66.65,47.1,22.45,102.6,36,62.35,61.8,30.95,90.7,36.4,43.4,43.85,29.35,107.75,125.8,90.55,18.95,53.05,32.8,57.55,42.2,27.6,33.6,63,274.25,101.55,128.05,97.1,83.35,90.6,44.5,33.3,50.1,63.65,42.25,32.25,51.65,61.1,33.25,45.55,53.45,75.15,18.7,21.2,71.8,37,23.3,20.8,35.65,36.45,114.4,44.55,34.65,103.5,67.7,41.75,56.75,39.15,82.25,97.3,61.25,130.65,59.1,36.2,118.65,40.3,64.95,26.7,27.55,162.05,27.15,15,37.8,25.2,66.05,78.15,68.85,51.45,14.85,32.65,115.05,166.1,32.6,19.75,81.2,37.85,65.1,45,96.9,64.1,119.15,40.65,38.45,19.35,30.1,25.95,30.2,62.35,50.55,51.75,38.95,77.8,101.05,26.55,32.15,29.2,72.3,171.55,56.65,141.9,95.4,43.6,43.9,22.55,39.8,40.55,88,37.5,83.75,33.7,50.5,56.15,68.35,32.35,275.45,23.15,170.05,113.2,28.65,51.7,61.05,31.4,30.3,47.45,206.2,35.7,49.5,91.15,20.7,81.2,39.95,166,17.6,118.1,84.3,49.75,69,103.85,51.05,35.25,160.15,66.85,37.1,56.2,20.25,51.9,114.15,35,166.9,38.8,119.1,88.15,80.95,40.5,33.45,75.35,36.2,49.05,223.1,78.05,54.6,28,18.6,93.9,103.8,55.3,38.5,31.2,57.1,34.5,72.45,19.55,71.3,21.9,19.5,48,66,46.45,35.85,75.15,82.9,60.6,222.9,30.55,71.75,114.1,138.05,64.65,296.9,99.35,159.75,48.3,47.8,62.15,58.3,102.05,56.65,42.7,62.6,236.15,108.4,34.15,177.65,13.75,27.4,70.1,21.65,35.25,55.9,56.85,57.2,123.05,41.2,113.1,39.35,32.85,32.6,63.45,114.4,31.6,41.6,41.5,30.95,27.4,55.85,35.05,130.8,104.9,88.2,55.6,17.9,194.55,44.05,79.95,21.4,128.85,41.75,49.15,54.2,86.1,73,72.9,57.15,55.6,36.35,66.45,35.8,51.7,18.45,49.9,40.55,108.4,135.65,259.65,71.85,121.2,66.55,84.55,24.7,36.1,34.35,43.15,224.65,45.5,119.2,48.2,29.6,65.2,57,45.7,74.85,211.25,24.75,98.4,71.4,60.7,84.6,59.15,47,96.2,84.85,90.6,57.9,147.75,232.4,34.25,53.2,58.65,44.6,94,42.15,72.75,54.2,13.35,59.1,68.45,77.15,155.4,22.3,78.1,51.35,178,21.05,80.45,38.05,103.55,74.25,28.25,45.15,110.3,64.5,124,53.35,37.85,129.5,34.35,35.5,31.95,59.5,25.6,46.95,27.6,35.4,182.15,89.4,65.65,66.75,29.15,48.5,41.95,36.5,30.4,43.65,55.4,74.05,173.9,22.8,48.9,41.75,156.6,57.85,36.55,47.05,71.8}
            realMul = curmuls[math.random(#curmuls)]
        end
        if imageType == 3 then
            local curmuls = {39.25,192.85,31.5,43.5,27.1,35.8,13.45,137.9,48.35,42.1,62.45,36.25,40.8,122,66.7,106.2,56.2,34.95,44.25,26.65,138.85,45.55,43.45,29.1,54.5,60.55,74.6,43.15,91,33.7,67.85,63.8,73.05,31.2,64.85,53.1,44.95,115.4,45.7,107.25,31,51.45,81.1,130.15,125.3,89.9,144.25,62.15,90.65,59.6,41.55,64.55,25.1,44.8,18.05,59.6,48.3,28.1,30.1,31.9,41.45,21.65,102,44.75,129.45,45.2,85.9,212.55,29.7,41.45,55.05,105.45,21.35,46.05,52.75,55.95,36.25,175.65,101.15,37.65,48,77.55,96.35,68.55,54.15,82.9,22,96.95,151.45,74.5,225.9,68.9,45.1,37.5,37.85,61.45,58.8,78.45,56.25,104,79.3,111.4,53.45,60.65,53.2,43,20.1,95.6,64.6,59.8,217.2,100.6,85.3,90.15,24.65,104.3,93.65,40.25,28,195.2,32.7,32.8,31.25,93.1,70.55,58.35,35.55,92.9,47.05,54.2,59.05,84.1,60.75,68.35,17.75,88.65,19.55,270.05,28.75,57.35,22.45,65.9,94.45,74.1,73.05,77.7,67.9,51.5,70.4,40.95,172.15,24.35,27,26.25,46.9,103.6,32.85,35.15,78.35,61.85,78.1,120.9,69.65,127.8,16.7,61.2,27.5,121.05,25.3,37.4,44.95,78.1,43.1,49.85,46.1,116.2,58.65,30.05,39.95,44.4,56.65,26.65,40.5,59.8,49.9,36.6,43,36.6,234.5,50.7,32.7,44.2,88.75,24,44.3,62.15,50.3,71.6,22.15,98.9,23.45,28.7,118.35,51.5,18.35,56.3,319.9,32.95,26.2,27.5,103.4,67.2,22.9,49.05,301.3,131.15,84.05,38.6,40.35,47.9,50.75,64.75,51.8,38.25,82.2,72.35,91.2,65.4,73.9,38.2,156.2,37.8,54.55,131.55,121.2,134.6,72.5,51.05,63.8,33.7,47.5,40.15,50.1,70.95,91.95,35.4,48.8,94.35,62.55,24.8,72.35,75.8,31.9,34.9,62.65,33.95,75.95,55.75,40.5,32.2,196.7,37.9,157.05,33.9,96.55,42.9,53.35,119.4,116.8,126.35,38.7,28.75,19.55,60.2,32.65,55.95,21.1,44.35,48,42.6,32.65,21.8,82.55,20.55,54.55,56.85,24.4,101.85,30.4,66.6,31,74.9,25.3,264.2,23.2,61.8,51.5,47.05,72.15,63.15,41.8,163.95,156.5,29,49.9,33.65,62.65,45.5,24.9,81.6,31.5,148.7,43.8,29.35,20.2,88.95,74,108.55,104.4,96.05,25.25,167,39.8,53.35,40.65,67.1,39.4,24.35,73.7,175.65,144.1,48.1,47.55,77.35,46.55,49.6,40,41.35,35.25,47.1,29.05,36.55,56.2,117.3,70.35,47.75,58.3,74.25,85.95,48.05,16.95,29,77.05,53.95,21.7,48.25,90.9,46.5,42.5,45,98.55,32.95,28.8,40,76.9,55.8,55.15,62.05,46.35,166.5,155.25,96.2,71.5,12.2,84,53.8,57.4,46,115.25,289.95,43.65,114.95,55.4,116.25,59.3,40.15,43.3,52.15,129.25,33.6,76.95,45,92.95,55.8,31.4,41,39.35,89.3,54.95,71.45,85.95,65.65,47,59.85,44.8,13.05,58.35,254.3,44.55,67.95,43.15,69.55,39,33.45,39.75,29.8,25.35,39.85,306.3,28.5,20.2,44.65,64.45,43.2,77.8,42.65,41.3,79.7,44.2,18,26.45,49.9,50.1,30.6,60,77.5,55.4,43.7,185.3,44.75,140.5,48.65,118.25,32.25,49.4,40.65,68.15,109.35,44.4,58.9,32.2,47.8,33.45,38.2,51.85,96.6,64.05,56.75,35.45,232.1,47.3,41.55,45.3,51.55,18.05,46.85,40.15,18.25,27.8,50.8,56.5,63.2,20.55,41.9,19.9,46,58.95,53.4,15.95,122.1,52.2,29.8,51.25,33.45,37.7,24.85,21.2,174.35,95.65,31.15,230.85,17,30,91.55,45.15,81.05,33,28.5,64.6,87.4,38.15,31.1,73.25,90,65,113.4,49.4,47.35,38.95,33.2,72.3,53.8,37.55,221.55,142,37.75,60,161.05,95.6,126.5,56.7,31.7,37.35,52.6,41.65,115.05,110,63.6,31.1,59.2,19.3,29.7,51.1,81.4,269.55,158.7,17.55,50.4,31.05,219.9,27.2,36,39.5,56.4,37.95,28.95,37.7,30.55,15.05,51.8,142,84.3,73.1,314.2,25.25,28.55,55.25,33.15,60.65,167.75,59.9,48.25,51.25,39.85,47.55,58.7,39.6,56.5,27,40.25,39.85,74.1,26.6,43.35,41.9,41.8,42.95,33.05,33.45,74.4,45.6,109.9,39.95,49,53.2,42,18.3,40.35,76.5,74.75,43.6,33.25,22.2,49.85,33.9,30.1,78.05,56.3,166.45,145.9,88.55,124.15,27.75,83.15,50.8,70.2,29.8,66.25,26.9,46.85,27.9,33.4,109.8,66.1,29.2,62.45,30,46.8,54.2,51.75,73.5,52.95,66.2,219.7,32.35,153,56.8,23.55,30.1,136.25,76.6,31.05,78.1,23.45,54.7,50.95,40.8,96.45,101.45,33.3,35.2,64.35,35.5,65.95,24.65,48.35,30.5,56.6,170.45,30.8,38,74.5,46.25,102.05,31.4,31.55,31.8,39.6,45.45,29.45,40.15,44.35,39.4,104,51.6,81.25,117.15,54.55,32.7,68.6,26.75,36,40.2,89.6,140.85,147.6,24.45,319.8,26.35,25.15,66.05,44.95,29.5,90.25,25.8,29.95,28.2,42.7,51.5,148.4,23.4,39.15,80.1,25.05,42.55,50.3,108.9,31.8,50.3,91.7,35.8,89.1,40.35,51.25,72.35,52.65,54.6,76.95,133.9,70.5,269.6,57.3,50.2,23.75,138.25,41.2,100.3,90.95,74.1,36.5,71.3,95.15,37.55,53.35,53.8,124.45,58.3,27.6,77.75,60.95,24.8,105.7,43.6,21.1,17.2,42.65,33.15,96.85,28.15,119.8,20.5,37.2,30.1,61.15,22.05,91.35,33.5,25.05,48.2,47.9,54.75,30.2,78,141.6,30.9,24.2,36.55,46.65,42.85,22.1,49.2,59.8,36.15,29.25,168.15,107.35,60.35,47.2,48.8,35.6,160.3,108.65,25.55,22.35,50.35,26.65,59.95,84.2,24.25,24.45,149.4,27.4,94.2,63.25,57.9,50.95,40.45,88.05,35.9,30.75,52.7,26.1,35.6,67.05,85.75,40.25,95.1,45.9,26.65,22.35,36.85,77.95,23.4,41.4,48.35,34.15,71.1,79.85,69.8,69.85,50.35,132.25,40.6,65.8,40.45,64.65,20.75,66.65,49.75,36.45,59.15,93.2,51.3,47.95,67.5,21.75,46.65,73.45,35.95,54.9,44.3,42.55,117.35,84.05,40.9,70.45,109.65,113.95,85.15,28.1,27.15,29.15,70.7,73.5,32.2,18.4,27.35,64.7,25.35,217.95,71.35,26.6,34.15,50.7,80.65,33.75,13.8,83.25,72.3,45.75,62.65,71.3,67.9,115.55,31.9,23.35,17.85,22.35,209.55,49.9,29.65,113.75,179.6,49.7,25.2,47.3,35.7,87,157.25,76.9,94.1,122.4,81.25,22.4,88.15,33.55,32.35,36.45,36.95,95.1,62.45,90.95,29.9,153.5,99.3,72.45,36.8,29.5,38.5,33.35,67.95,68.95,38.35,25.35,30.55,123.9,42.25,22.15,25.75,52.5,137,65.25,47.8,31.75,26.15,21.8,54.5,26.8,64.1,38.6,30.5,19.3,61.75,43.1,38.1,46.5,110,22.1,27.2,56.95,21.7,102.25,36.25,46.45,36.3,27.65,52.4,92.5,182.3,28.3,56.85,42.55,70.55,176.95,247.25,50.15,81.05,85.75,59.9,40.2,49.65,35.2,52.15,72.3,207.6,62.9,15.7,54.35,85.75,79.25,90.6,39.45,56.3,56.35,54.15,13.9,271.3,53.35,119,265.65,51.25,92.45,32.1,39,131.25,59.95,41.15,102.95,13.75,111.25,159.05,22.7,43.4,63.05,52.35,42.35,33.85,42.95,95.65,50.9,44,47.6,80.7,272.3,38.75,108.4,15.4,38.7,13.6,67.05}
            realMul = curmuls[math.random(#curmuls)]
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