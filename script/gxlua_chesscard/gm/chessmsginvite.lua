GmSvr.PmdStRequestPromotionPmd_CS =function(cmd, laccount)
    local filter = unilight.gt('_id',0)
    if cmd.data.charid ~= nil and cmd.data.charid > 0 then
        filter = unilight.a(filter,unilight.eq("_id", cmd.data.charid))
    end
    local order = unilight.desc("_id")
    local infoNum = unilight.startChain().Table('extension_relation').Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            newuser = 0,
            activeuser = 0,
            tolchildren = 0,
            tolinvite = 0,
            data = {},
        }
    }
    -- 查找下级
    local exinfos = unilight.chainResponseSequence(unilight.startChain().Table('extension_relation').Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    for _, exinfo in ipairs(exinfos) do
        -- 只查找一级下线
        local filter = unilight.a(unilight.eq("uid",exinfo._id),unilight.eq("lev", 1))
        local tolchildren = unilight.startChain().Table('rebateItem').Filter(filter).Count()
        table.insert(res.data.data,{
            charid                  = exinfo._id,                                                                                           -- 用户id
            tolchildren             = tolchildren,                                                                                          -- 下级数量
            tolinvite               = exinfo.totalFreeValidChips + exinfo.totalRebateChip + exinfo.totalValidChips + exinfo.tolBetFall,     -- 邀请总收益
            tolinviteordinary       = exinfo.totalFreeValidChips + exinfo.totalRebateChip + exinfo.totalValidChips,                         -- 普通邀请收益
            tolinviteteam           = exinfo.tolBetFall,                                                                                    -- 团队邀请收益
        })
        res.data.tolchildren = res.data.tolchildren + tolchildren
        res.data.tolinvite = res.data.tolinvite + exinfo.totalFreeValidChips + exinfo.totalRebateChip + exinfo.totalValidChips + exinfo.tolBetFall
    end
    return res
end