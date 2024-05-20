module('twelvegame', package.seeall) -- 十二生肖
-- 十二生肖

-- 十二生肖每10分钟开奖，玩家可以从12个生肖中选择1-3个投注，同时可以选择附加或者不附加五行，但不能单独购买五行，五行为金木水火土，单图标投注金额2，每买一个生肖和五行都收取固定等价费用。可选择倍投5、10、20、100倍
-- 每一期开奖为3个随机不同生肖+1个本期五行，匹配任意生肖+符号的玩家获奖，押注和中奖赔付比例如下：
-- 1个生肖：购买价格2，赔付2倍
-- 1个生肖+五行：购买价格4，赔付4倍
-- 2个生肖：购买价格4，赔付4倍
-- 2个生肖+五行：购买价格6，赔付8倍
-- 3个生肖：购买价格6，赔付8倍
-- 3个生肖+五行：购买价格8，赔付15倍


-- 开奖随机选择赔付图形，计算当期购买总额>总赔付直接开奖，当期购买总额<总赔付再随机一次图形，随机10次后仍无法赔付时开空奖或选择10次中最低赔付。

-- 客户端呈现最近20次开奖记录，开奖记录包含开奖图形，玩家购买图形和中奖金额

-- 中奖金额通过邮件发放到玩家
-- 表名
CONSTTWELVE = {1,2,3,4,5,6,7,8,9,10,11,12}
CONSTFIVE = {1,2,3,4,5}
TABLE_NAME = "twelvegame"
TABLE_PRIZELOG_NAME = "twelveprizelog"
TABLE_LOG_NAME = "twelvebetlog"
TABLE_VIPPL_NAME = "viptwelve"
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
	print("twelvegameTick"..endtime)
	OpenPrize(begintime,endtime)
				

end 


function GettTelvePrize(mustprize)
	local prizes = {t={},f={}}
	local curtw = table.clone(CONSTTWELVE)
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
		for _, v in pairs(value.tw) do
			if TprizesMP[v] then
				winnums = winnums +1
			end 
		end
		for _, v in pairs(value.fv) do
			if FprizesMP[v] then
				winnums = winnums +1
			end 
		end
		local per_winner_bonus= winnums * gold
	
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
	print("twelvegame Getbetinfo begintime",btime)
	print("twelvegame Getbetinfo etime",etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return all
end


function getplvipInfo(btime,etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_VIPPL_NAME).Filter(filter))
	return res
end


