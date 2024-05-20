-- 兑换提现模块
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}

-- 获取是否绑定CPF
WithdrawCash.GetCpfInfo = function(uid)
    local res
    local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name,uid)
    -- 判断是否需要初始化
    if table.empty(withdrawCashInfo) then
        withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    end
    if withdrawCashInfo.cpf == nil then
        res = {errno = ErrorDefine.SUCCESS, cpfFlag = false}
    else
        res = {errno = ErrorDefine.SUCCESS, cpfFlag = true}
    end
    return res
end

-- 绑定CPF信息
WithdrawCash.BindingCpf = function(uid, cpf, name, flag, chavePix, email, telephone)
    local res
    if name == nil or name == "" then
        res = {errno = ErrorDefine.WITHDRAWCASH_NAMEFORMAT_ERROR}
        return res
    end
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- 判断入参是否合法
    if string.len(cpf) ~= 11 then
        res = {errno = ErrorDefine.WITHDRAWCASH_CPFFORMAT_ERROR}
        return res
    elseif withdrawCashInfo.cpf == nil then
        
        local filter = unilight.eq('cpf',cpf)
        -- -- cpf不唯一
        -- if not table.empty(unilight.chainResponseSequence(unilight.startChain().Table(WithdrawCash.DB_Name).Filter(filter))) then
        --     res = {errno = ErrorDefine.WITHDRAWCASH_REGISTERED_ERROR}
        --     return res
        -- end
        -- 一个CPF只能绑定两次
        if table.len(unilight.chainResponseSequence(unilight.startChain().Table(WithdrawCash.DB_Name).Filter(filter))) >= WithdrawCash.Table_Other[1].MaxCpfNum then
            res = {errno = ErrorDefine.WITHDRAWCASH_REGISTERED_ERROR}
            return res
        end
    end

    if flag == 1 then
        if string.len(chavePix) ~= 11 then
            res = {errno = ErrorDefine.WITHDRAWCASH_PHONEFORMAT_ERROR}
            return res
        end
        -- local filter = unilight.eq('chavePix',chavePix)
        -- if not table.empty(unilight.chainResponseSequence(unilight.startChain().Table(WithdrawCash.DB_Name).Filter(filter))) then
        --     res = {errno = ErrorDefine.WITHDRAWCASH_REGISTERED_ERROR}
        --     return res
        -- end
    end
    if flag == 2 then
        -- if not isRightEmail(chavePix) then
        --     res = {errno = ErrorDefine.WITHDRAWCASH_EMAILFORMAT_ERROR}
        --     return res
        -- end
        -- local filter = unilight.eq('chavePix',chavePix)
        -- if not table.empty(unilight.chainResponseSequence(unilight.startChain().Table(WithdrawCash.DB_Name).Filter(filter))) then
        --     res = {errno = ErrorDefine.WITHDRAWCASH_REGISTERED_ERROR}
        --     return res
        -- end
    end

    -- local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name, uid)
    -- -- 判断是否需要初始化
    -- if table.empty(withdrawCashInfo) then
    --     withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    --     unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    -- end

    -- 判断数据库中是否绑定
    -- if withdrawCashInfo.cpf ~= nil then
    --     res = {errno = ErrorDefine.WITHDRAWCASH_REPEATCPF_ERROR}
    --     return res
    -- end
    withdrawCashInfo.telephone = telephone
    withdrawCashInfo.email = email
    withdrawCashInfo.cpf = cpf
    withdrawCashInfo.name = name
    withdrawCashInfo.flag = flag
    -- 绑定玩家CPF信息
    local userinfo = unilight.getdata('userinfo',uid)
    userinfo.base.cpf = cpf
    unilight.savedata('userinfo',userinfo)
    if flag == 1 or flag == 2 then
        withdrawCashInfo.chavePix = chavePix
    else
        withdrawCashInfo.chavePix = cpf
    end
    -- 保存数据库相关信息
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    res = {errno = ErrorDefine.SUCCESS}
    return res
end

function isRightEmail(str)
    if string.len(str or "") < 6 then return false end
    local b,e = string.find(str or "", '@')
    local bstr = ""
    local estr = ""
    if b then
        bstr = string.sub(str, 1, b-1)
        estr = string.sub(str, e+1, -1)
    else
        return false
    end

    -- check the string before '@'
    local p1,p2 = string.find(bstr, "[%w-_]+")
    if (p1 ~= 1) or (p2 ~= string.len(bstr)) then return false end

    -- check the string after '@'
    if string.find(estr, "^[%.]+") then return false end
    if string.find(estr, "%.[%.]+") then return false end
    if string.find(estr, "@") then return false end
    if string.find(estr, "[%.]+$") then return false end
    
    local _,count = string.gsub(estr, "%.", "")
    if (count < 1 ) or (count > 3) then
        return false
    end
    return true
end
--------------------------------------------------------    外部调用    --------------------------------------------------------

-- 修改玩家CPF信息  固定返回CPF信息
function ChangeWithdrawcashCpfInfo(uid, name, cpf, chavePix)
    if uid == nil then
        local res = {
            name = "",
            cpf = "",
            chavePix = "",
        }
        return res
    end
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name, uid)
    -- -- -- 判断是否需要初始化
    -- -- if table.empty(withdrawCashInfo) then
    -- --     withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- --     unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    -- -- end
    if name ~= nil and name ~= "" then
        withdrawCashInfo.name = name
    end
    if cpf ~= nil and cpf ~= "" then
        if withdrawCashInfo.cpf == withdrawCashInfo.chavePix and withdrawCashInfo.chavePix ~= nil then
            withdrawCashInfo.cpf = cpf
            withdrawCashInfo.chavePix = cpf
        else
            withdrawCashInfo.cpf = cpf
        end
        local userinfo = unilight.getdata('userinfo',uid)
        userinfo.base.cpf = cpf
        unilight.savedata('userinfo',userinfo)
    end
    if chavePix ~= nil and chavePix ~= "" then
        withdrawCashInfo.chavePix = chavePix
    end
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    local res = {
        name = withdrawCashInfo.name or "",
        cpf = withdrawCashInfo.cpf or "",
        chavePix = withdrawCashInfo.chavePix or "",
        telephone = withdrawCashInfo.telephone or "",               -- 满足后台增加额外返回信息
        email = withdrawCashInfo.email or "",                       -- 满足后台增加额外返回信息
        statement = withdrawCashInfo.statement or "",               -- 满足后台增加额外返回信息
    }
    return res
end