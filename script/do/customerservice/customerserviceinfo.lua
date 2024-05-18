module('customerservice',package.seeall)
DB_Name = "customerservice"
--客服地址
GmSvr.PmdStCustomerServicePmd_CS = function(cmd, laccount)
    
    -- 如果是查询客服地址
    if cmd.data.optype == 1 then
        -- 地址信息格式化
            -- platid,          //平台id
            -- url             //客服地址
        cmd.data.data = {}
        -- 查询所有数据(数据不多所以直接全查)
        local customerserviceInfos = unilight.getAll(DB_Name)
        for _, customerserviceInfo in ipairs(customerserviceInfos) do
            table.insert(cmd.data.data,{platid = customerserviceInfo.platid,url = customerserviceInfo.url})
        end
    elseif cmd.data.optype == 2 then
        if cmd.data.data[1].platid == nil or cmd.data.data[1].url == nil then
            cmd.data.retcode = 1
            cmd.data.retdesc =  "参数错误"
            return cmd
        end
        -- 修改或添加
        local customerserviceInfo = {_id = cmd.data.data[1].platid,platid = cmd.data.data[1].platid,url = cmd.data.data[1].url}
        unilight.savedata(DB_Name,customerserviceInfo)
    end
    cmd.data.retcode = 0
    cmd.data.retdesc =  "操作成功"
    return cmd
end

