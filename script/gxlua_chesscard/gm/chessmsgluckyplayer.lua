-- 幸运玩家相关gm请求

-- 请求幸运玩家满足要求的个数
GmSvr.PmdRequestLuckyUserPmd_C = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("请求幸运玩家生成 有误")
        local res = {
            data = {
                retcode = 1,
                retdesc = "操作失败 发送信息为空",
            }
        }
		return res
	end
    local res = {
        data = {
            retcode = 0,
            retdesc = "生成成功",
        }
    }
    if cmd.data.optype == 0 then
        local starttime = ""
        local endtime = ""
        if cmd.data.storedata[1].starttime ~= nil and cmd.data.storedata[1].starttime ~= "" then
            starttime = chessutil.TimeByDateGet(cmd.data.storedata[1].starttime)
        end
        if cmd.data.storedata[1].endtime ~= nil and cmd.data.storedata[1].starttime ~= "" then
            endtime = chessutil.TimeByDateGet(cmd.data.storedata[1].endtime)
        end
        -- 请求满足条件人数
        res.data.usercount = LuckyPlayer.GetPlayerCount(starttime,endtime,cmd.data.storedata[1].lowcharge,cmd.data.storedata[1].topcharge,cmd.data.storedata[1].lowchildnum,cmd.data.storedata[1].topchildnum,cmd.data.storedata[1].lowactchildnum,cmd.data.storedata[1].topactchildnum)
        -- res.data.usercount = 10
        res.data.maxpage = 1
    elseif cmd.data.optype == 1 then
        -- 请求发放奖励
        if not LuckyPlayer.GetInviteRouletteInfo(cmd.data.storedata[1].lowgold,cmd.data.storedata[1].topgold,cmd.data.storedata[1].batch,cmd.data.storedata[1].codetype,cmd.data.storedata[1].usernum) then
            local res = {
                data = {
                    retcode = 1,
                    retdesc = "发送失败 需要先查询玩家",
                }
            }
            return res
        else
            local res = {
                data = {
                    retcode = 0,
                    retdesc = "生成成功",
                }
            }
            return res
        end
        
    elseif cmd.data.optype == 2 or cmd.data.optype == 3 then
        local starttime
        local endtime
        if cmd.data.begintime ~= nil and cmd.data.begintime ~= '' then
            starttime = chessutil.TimeByDateGet(cmd.data.begintime)
        end
        if cmd.data.endtime ~= nil and cmd.data.endtime ~= '' then
            endtime = chessutil.TimeByDateGet(cmd.data.endtime)
        end
        
        local filter = unilight.neq('_id',"")
        if cmd.data.batch ~= nil and cmd.data.batch ~= '' then
            filter = unilight.a(filter,unilight.eq("batch", cmd.data.batch))
        end
        if cmd.data.charid ~= nil and cmd.data.charid > 0 then
            filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
        end
        if starttime ~= nil and starttime ~= '' and endtime ~= nil and endtime ~= '' then
            filter = unilight.a(filter,unilight.a(unilight.ge("date", starttime),unilight.le("date", endtime)))
        end
        local order = unilight.desc("date")
        if cmd.data.optype == 2 then
            -- 查询记录
            local datainfos = unilight.chainResponseSequence(unilight.startChain().Table(LuckyPlayer.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
            local infoNum = unilight.startChain().Table(LuckyPlayer.DB_Log_Name).Filter(filter).Count()
            local maxpage = math.ceil(infoNum/cmd.data.perpage)
            local res = {
                data = {
                    maxpage = maxpage,
                    perpage = cmd.data.perpage,
                    curpage = cmd.data.curpage,
                    data = {},
                }
            }
            for _, codeinfo in ipairs(datainfos) do
                table.insert(res.data.data,{
                    charid          = codeinfo.uid,
                    batch   	    = codeinfo.batch,
                    date   	        = chessutil.FormatDateGet(codeinfo.date),
                    phone 		    = codeinfo.phone,
                    allcharge 	    = codeinfo.allcharge,
                    gold 		    = codeinfo.gold,
                })
            end
            return res
        elseif cmd.data.optype == 3 then
            -- 下载
            local datainfos = unilight.chainResponseSequence(unilight.startChain().Table(LuckyPlayer.DB_Log_Name).Filter(filter).OrderBy(order))
            local res = {
                data = {
                    perpage = cmd.data.perpage,
                    curpage = cmd.data.curpage,
                    data = {},
                }
            }
            for _, codeinfo in ipairs(datainfos) do
                table.insert(res.data.data,{
                    charid          = codeinfo.uid,
                    batch   	    = codeinfo.batch,
                    date   	        = chessutil.FormatDateGet(codeinfo.date),
                    phone 		    = codeinfo.phone,
                    allcharge 	    = codeinfo.allcharge,
                    gold 		    = codeinfo.gold,
                })
            end
            return res
        end
    end
	return res
end