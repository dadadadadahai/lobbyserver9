module('nchip',package.seeall)
function CmdRecvNchipCmd_C(uid,data)
    local data = unilight.getdata('extension_relation',uid)
    if data==nil or data.todayFlowingChips<=0 then
        return{
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    -- BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, data.todayFlowingChips,
    --     Const.GOODS_SOURCE_TYPE.NCHIP)

    local todayFlowingChips = data.todayFlowingChips
    data.todayFlowingChips = 0
    data.tolRecv = data.tolRecv or 0
    data.tolRecv = data.tolRecv + todayFlowingChips
    unilight.incdate('extension_relation', uid, {tolRecv=todayFlowingChips,todayFlowingChips=-todayFlowingChips,rebatechip=todayFlowingChips})
    local nchipLog = 'nchiplog'
    local res={
        _id = go.newObjectId(),
        uid = uid,
        todayFlowingChips = todayFlowingChips,
        timestamp = os.time(),
    }
    unilight.savedata(nchipLog,res)
    return{
        errno = 0,
        todayFlowingChips = todayFlowingChips,
    }
end
function RecvFreeViteChipsCmd_S(uid,data)
    local data = unilight.getdata('extension_relation',uid)
    if data==nil or  data.freeValidinViteChips<=0 then
        return{
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    local freeValidinViteChips = data.freeValidinViteChips
    unilight.incdate('extension_relation', uid, {freeValidinViteChips=-freeValidinViteChips,totalFreeValidinViteChips=freeValidinViteChips})
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, freeValidinViteChips,Const.GOODS_SOURCE_TYPE.NCHIP)
    local nchipLog = 'nchiplogfreeValidinViteChips'
    local res={
        _id = go.newObjectId(),
        uid = uid,
        freeValidinViteChips = freeValidinViteChips,
        timestamp = os.time(),
    }
    unilight.savedata(nchipLog,res)
    return{
        errno = 0,
        freeValidinViteChips = freeValidinViteChips,
    }
end