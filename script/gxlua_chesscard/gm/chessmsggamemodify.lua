--处理gm查询slots游戏数据

local table_ctr_whole = import 'table/table_ctr_whole'
local table_game_list = import 'table/table_game_list'

--查询slots游戏参数
--[[
GmSvr.PmdStRequestSlotsGameParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    if cmd.data.optype == 1 then
        local curpage 		= cmd.data.curpage
        local perpage 		= cmd.data.perpage

        if curpage == 0 then
            curpage = 1
        end

        local maxpage = 0

        local poolConfigs = gamecommon.GmGetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.sysrtp = table_ctr_whole[1].wholeXs
        cmd.data.regrtp = table_ctr_whole[2].wholeXs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then
        gamecommon.GmSetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        local poolConfigs = gamecommon.GmGetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.sysrtp = table_ctr_whole[1].wholeXs
        cmd.data.regrtp = table_ctr_whole[2].wholeXs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd

    --设置系统rtp
    elseif cmd.data.optype == 3 then
        unilight.info(string.format("gm设置系统rtp:"..cmd.data.sysrtp))
        table_ctr_whole[1].wholeXs = cmd.data.sysrtp
        table_ctr_whole[2].wholeXs = cmd.data.regrtp
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end
]]

--查询slots游戏参数走redis
GmSvr.PmdStRequestSlotsGameParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    if cmd.data.optype == 1 then
        local curpage 		= cmd.data.curpage
        local perpage 		= cmd.data.perpage

        if curpage == 0 then
            curpage = 1
        end
        local getItemGameInfo=function(item)
            return{
                fakepoolmin=0,
                lowrechargertp=item.lowChargeRtp,
                limitlow=0,
                fakepoolchips=0,
                addrealpoolper=0,
                fakepoolmax=0,
                totalprofit=0,
                bomblooptime=0,
                subgameid=item.subGameId,
                norechargertp=item.noChargeRtp,
                subgametype=item.gameType,
                rebatevalue=item.RTP4,
                standardchips=0,
                realpoolchips=0,
            }
        end
        local poolConfigs = {}
        if cmd.data.subgameid == 0 and cmd.data.subgametype == 0 then
            for _,value in pairs(table_game_list) do
                table.insert(poolConfigs,getItemGameInfo(value))
            end
        elseif cmd.data.subgameid > 0 and cmd.data.subgametype == 0 then
            for _,value in pairs(table_game_list) do
                if value.subGameId==cmd.data.subgameid then
                    table.insert(poolConfigs,getItemGameInfo(value))
                end
            end
        end
        cmd.data.datas = poolConfigs
        cmd.data.sysrtp = table_ctr_whole[1].wholeXs
        cmd.data.regrtp = table_ctr_whole[2].wholeXs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then
        local poolInfo = cmd.data.datas[1]
        --首先修改本地配置
        local key = poolInfo.subgameid*10000+1
        if table_game_list[key]~=nil then
            table_game_list[key].RTP4 = poolInfo.rebatevalue
            table_game_list[key].lowChargeRtp = poolInfo.lowrechargertp
            if unilight.getdebuglevel() > 0 then
                --debug 模式
                --全局推送
                
                RoomInfo.BroadcastToAllZone("Cmd.EditSysSingleRtpCmd_S", {subgameid=poolInfo.subgameid,sysRtp=poolInfo.lowrechargertp, regRtp= poolInfo.rebatevalue})
            else
                --组装zoneId
                local zoneId = poolInfo.subgameid*100+11
                local zone = ZoneInfo.zoneIdInfoMap[zoneId]
                if zone~=nil then
                    zone:SendCmdToMe("Cmd.EditSysSingleRtpCmd_S",{subgameid=poolInfo.subgameid,sysRtp=poolInfo.lowrechargertp, regRtp= poolInfo.rebatevalue})
                end
            end
        end
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"                                          
        -- gamecommon.GmSetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        -- ZoneInfo.BroadcastToZone(poolInfo.subgameid, poolInfo.zoneid, "Cmd.EditSlotsPoolInfoCmd_S", poolInfo)
        -- local poolConfigs = gamecommon.GmGetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        -- cmd.data.datas = poolConfigs
        -- cmd.data.sysrtp = table_ctr_whole[1].wholeXs
        -- cmd.data.regrtp = table_ctr_whole[2].wholeXs
        -- cmd.data.retcode = 0 
        -- cmd.data.retdesc =  "操作成功"



        return cmd

    --设置系统rtp
    elseif cmd.data.optype == 3 then
        -- unilight.info(string.format("gm设置系统rtp:"..cmd.data.sysrtp))
        -- table_ctr_whole[1].wholeXs = cmd.data.sysrtp
        -- table_ctr_whole[2].wholeXs = cmd.data.regrtp

        for _, value in pairs(table_game_list) do
            value.lowChargeRtp = cmd.data.sysrtp
            value.RTP4 = cmd.data.regrtp
        end
        --红包雨 参考
        RoomInfo.BroadcastToAllZone("Cmd.EditSysRtpCmd_S", {sysRtp=cmd.data.sysrtp, regRtp=cmd.data.regrtp})
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end


--查询设置百人场游戏参数
GmSvr.PmdStRequestHundredGameParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    if cmd.data.optype == 1 then
        local curpage 		= cmd.data.curpage
        local perpage 		= cmd.data.perpage

        if curpage == 0 then
            curpage = 1
        end

        local maxpage = 0

        local poolConfigs = gamecommon.GmGetHundredGameConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then
        gamecommon.GmSetHundredGameConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        local poolConfigs = gamecommon.GmGetHundredGameConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end

--查询设置百人场游戏参数
--[[
GmSvr.PmdStRequestSignleGameParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    if cmd.data.optype == 1 then
        local curpage 		= cmd.data.curpage
        local perpage 		= cmd.data.perpage

        if curpage == 0 then
            curpage = 1
        end

        local maxpage = 0

        local poolConfigs = gamecommon.GmGetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then
        gamecommon.GmSetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        local poolConfigs = gamecommon.GmGetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end
]]

--查询设置单机游戏参数
GmSvr.PmdStRequestSignleGameParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    if cmd.data.optype == 1 then
        local curpage 		= cmd.data.curpage
        local perpage 		= cmd.data.perpage

        if curpage == 0 then
            curpage = 1
        end

        local maxpage = 0

        local zonePoolInfos = unilight.redis_gethashmultdata_Str(Const.REDIS_HASH_NAME.SINGLE_POOL_INFO)
        local poolConfigs = {}

        for zoneId, poolInfos in pairs(zonePoolInfos) do
            poolInfos = json2table(poolInfos)
            --查找所有
            if cmd.data.subgameid == 0 and cmd.data.subgametype == 0 then
                for _, poolInfo in pairs(poolInfos) do
                    table.insert(poolConfigs, poolInfo)
                end

            --指定游戏所有场次
            elseif cmd.data.subgameid > 0 and cmd.data.subgametype == 0 then
                for _, poolInfo in pairs(poolInfos) do
                    if poolInfo.subgameid == cmd.data.subgameid then
                        table.insert(poolConfigs, poolInfo)
                    end
                end

            --指定游戏指定场次
            elseif cmd.data.subgameid > 0 and cmd.data.subgametype > 0 then
                for _, poolInfo in pairs(poolInfos) do
                    if poolInfo.subgameid == cmd.data.subgameid and cmd.data.subgametype == poolInfo.subgametype then
                        table.insert(poolConfigs, poolInfo)
                    end
                end
            end

        end
        -- local poolConfigs = gamecommon.GmGetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then

        local poolInfo = cmd.data.datas[1]
        -- gamecommon.GmSetSlotsPoolConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        ZoneInfo.BroadcastToZone(poolInfo.subgameid, poolInfo.subgameid, "Cmd.EditSinglePoolInfoCmd_S", poolInfo)
        -- gamecommon.GmSetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype, cmd.data.datas[1])
        -- local poolConfigs = gamecommon.GmGetSinglePoolConfig(cmd.data.subgameid, cmd.data.subgametype)
        -- cmd.data.datas = poolConfigs
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end




--查询设置转盘参数
GmSvr.PmdStTurntableParamPmd_CS = function(cmd, laccount)
	local res = cmd
    --查询奖池
    local curpage 		= cmd.data.curpage
    local perpage 		= cmd.data.perpage

    if curpage == 0 then
        curpage = 1
    end

    local maxpage = 0
    local datas  = {}
    if cmd.data.optype == 1 then



        -- targetStock     --目标库存
        -- Stock           --实际库存
        -- decPeriod       --衰减周期
        -- decRatio        --衰减比例
        -- type            --衰减方式 1局数 2分钟
        local poolConfigs = Roulette.GetStockInfo()
        table.insert(datas, {
                srcstock       = poolConfigs.Stock, -- //实际库存
                tarstock       = poolConfigs.targetStock, --; //目标库存
                decaytype      = poolConfigs.type, --; //衰减方式
                decaytime      = poolConfigs.decPeriod, --; //衰减时间
                decayratio     = poolConfigs.decRatio, --; //衰减比例
                totaldecaynum  = poolConfigs.decval or 0,  --累计衰减值
            })
        cmd.data.data = datas
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    --设置奖池
    elseif cmd.data.optype == 2 then
        Roulette.SetStockInfo(cmd.data.data[1])
        local poolConfigs = Roulette.GetStockInfo()
        table.insert(datas, {
                srcstock       = poolConfigs.Stock, -- //实际库存
                tarstock       = poolConfigs.targetStock, --; //目标库存
                decaytype      = poolConfigs.type, --; //衰减方式
                decaytime      = poolConfigs.decPeriod, --; //衰减时间
                decayratio     = poolConfigs.decRatio, --; //衰减比例
                totaldecaynum  = poolConfigs.decval or 0,  --累计衰减值
            })
        cmd.data.data = datas
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "操作成功"
        return cmd
    else
        cmd.data.retcode = 0 
        cmd.data.retdesc =  "参数错误"
        return cmd
    end

end
