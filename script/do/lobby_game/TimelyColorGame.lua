
module('timelycolor', package.seeall) 
-- 数字球抽奖

-- 数字球每10分钟开奖，两种开奖模式，一种买中某个球数字赔付，一种按单双赔付，玩家可以从1-64号球中买任意3个数字，或者单双。
-- 每一期开奖1个数字，匹配数字或单双的玩家中奖，投注1个数字金额2，2个数字金额4，3个数字金额6；购买单、双金额2，可选择倍投5、10、20、100倍，赔付比例如下：

-- 匹配当期中奖数字：赔付15倍

-- 匹配单双：赔付1.9倍

-- 开奖随机选择数字，计算当期购买总额(不包括单双)>总赔付（不包括单双）直接开奖，当期购买总额(不包括单双)<总赔付（不包括单双）

-- 客户端呈现最近20次开奖记录，开奖记录包含开奖数字，玩家购买数字和中奖金额

-- 中奖金额通过邮件发放到玩家
CONSTTIMELYCOLOR = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64}
CONSTFIVE = {1,2}
TABLE_NAME = "timelycolor"
TABLE_PRIZELOG_NAME = "timelycolorprizelog"
TABLE_LOG_NAME = "timelycolorbetlog"
TABLE_VIPPL_NAME = "viptimelycolor"
local function check_is_tenmin()
	local date_tbl = os.date("*t")
	local sec = date_tbl.sec
	local min = date_tbl.min
	return sec == 0 and min /10 == 0 and  min %10 == 0
end
function Tick() --一分钟执行一次
	if not check_is_tenmin then
		return
	end
	local endtime = os.time()
	local begintime = os.time() - 600
	print("timelycolorTick"..endtime)
	OpenPrize(begintime,endtime)
				

end 


function GettTelvePrize(mustprize)
	local prizes = {t={},f={}}
	local curtw = table.clone(CONSTTIMELYCOLOR)
	if table.empty(mustprize) then
		for i = 1, 3, 1 do
			table.insert(prizes.t,table.remove(curtw,math.random(#curtw)))
		end
		table.insert(prizes.f,CONSTFIVE[math.random(#CONSTFIVE)])
	else
	end 
end 
function OpenPrize(btime,etime)
	local allbets =  getuserBetInfo(btime,etime)
	local prizes = GettTelvePrize()
	local TprizesMP = table.map(prizes.t,function (v,k)
		return v,true
	end)
	local FprizesMP = table.map(prizes.f,function (v,k)
		return v,true
	end)

	local totablbonus = 0
	local totablbetmoney = 0
	local usernums = 0 
	local prinzeusernums = 0 
	for key, value in pairs(allbets) do
		usernums = usernums + 1
		local uid = value.uid
		local gold = value.gold
		local winnums = 0
		local betmoney= value.betnums  * gold
		local  per_winner_bonus=  0 
		for _, v in pairs(value.tw) do
			if TprizesMP[v] then
				winnums = winnums +1
			end 
		end
		for _, v in pairs(value.fv) do
			if FprizesMP[v%2+1] then
				per_winner_bonus = per_winner_bonus * gold*1.9
			end 
		end
		 per_winner_bonus= winnums * gold *15
	
		saveUserPrizeInfo({time = etime,uid = uid,prize = per_winner_bonus,bet = betmoney})
		local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, per_winner_bonus,
		"十二生肖中奖")
		print(uid .. "十二生肖中奖 中奖，获得奖金：" .. per_winner_bonus )
		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney
		if per_winner_bonus > 0 then 
			prinzeusernums = prinzeusernums + 1
		end 
		saveGamePrizeInfo({time = etime,totablbonus = totablbonus,totablbetmoney = totablbetmoney,usernums = usernums,prinzeusernums = prinzeusernums,prizes= prizes})
	end
end


--投注
function addbet(uid,data)
	 local gold = data.betindex *100 or 100
	 local t = data.prizes.t
	 local f = data.prizes.f
	 local betnums = table.nums(t)+table.nums(f)
	local betmoney = gold * betnums
	 -- 执行扣费
	local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,betmoney,
	"积分抽奖ID"..pid)
	if ok == false then
       return  ErrorDefine.CHIPS_NOT_ENOUGH
    end
	print("addbet")
	saveUserBetInfo({time = os.time,uid =uid,gold = gold,betnums =betnums,tw=t,fv = f  })
	return 0 
end

function saveUserPrizeInfo(data)
	unilight.savedata(TABLE_PRIZELOG_NAME, data)
end

function saveGamePrizeInfo(data)
	unilight.savedata(TABLE_NAME, data)
end


function saveUserBetInfo(data)
	unilight.savedata(TABLE_LOG_NAME, data)
end

function getuserBetInfo(btime,etime)
	print("timelycolor Getbetinfo begintime",btime)
	print("timelycolor Getbetinfo etime",etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return all
end


function getplvipInfo(btime,etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_VIPPL_NAME).Filter(filter))
	return res
end


