module('sweetBonanza', package.seeall)
Table = 'game160sweetBonanza'
LineNum = 1
GameId = 160


J = 100
S = 70


function calcSMul(sNum)
    if sNum==4 then
        return 6
    elseif sNum==5 then
        return 10
    elseif sNum==6 then
        return 200
    end
    return 0
end
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
            gameType = 0,
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0,
            free={},            --免费模式
            isInHight=false ,        --是否处于高下注模式 0:不是 1:是
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo, datainfos
end
--购买高中奖率
function BuyHighBet(highLevel,datainfo,datainfos)
    datainfo.isInHight = highLevel
    unilight.update(Table, datainfos._id, datainfos)
    return {
        errno = 0,
        isInHight=highLevel,
    }
end

