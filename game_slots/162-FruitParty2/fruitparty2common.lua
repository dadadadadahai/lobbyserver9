module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

J = 100
S = 70
-- fruitparty2
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
            isInHight=false  ,        --是否处于高下注模式 0:不是 1:是
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
--购买免费



function calcSMul(sNum)
    if sNum==3 then
        return 6
    elseif sNum==4 then
        return 10
    elseif sNum==5 then
        return 20
	elseif sNum==6 then
		return 40
	elseif sNum==7 then
		return 200
    end
    return 0
end

function CalcFreeNum(sNum)
    if sNum==3 then
        return 10
    elseif sNum==4 then
        return 12
    elseif sNum==5 then
        return 15
	elseif sNum==6 then
		return 20
	elseif sNum==7 then
		return 25
    end
    return 0
end
