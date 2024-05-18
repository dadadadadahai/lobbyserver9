module('gameDetaillog',package.seeall)
--更新押注状态
function toBetCoin(userinfo,betchip)
    if userinfo.base.experienceStatus==1 and betchip>0 or true then
        local data={
            uid=userinfo._id,
            betChip=betchip,
            chargeNum=0,
            table='curBetCharge_Record'
        }
        go.logRpc.SaveLogData(json.encode(encode_repair(data)))
    end
end
--更新充值状态
function toChargeOrder(uid,money)
    local data={
        uid=uid,
        betChip=0,
        chargeNum=money,
        table='curBetCharge_Record'
    }
    go.logRpc.SaveLogData(json.encode(encode_repair(data)))
end