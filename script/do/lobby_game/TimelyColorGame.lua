
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
local function get_last_tenmin()
	local date_tbl = os.date("*t")
	date_tbl.sec = 0
	date_tbl.min =  math.floor(date_tbl.min/10)	*10
	return os.time(date_tbl)
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
		local curnumber = CONSTTIMELYCOLOR[math.random(#CONSTTIMELYCOLOR)]
		table.insert(prizes.t,curnumber)
		table.insert(prizes.f,curnumber%2) --0是双--1是单
	else
	end 
	return prizes
end 
function OpenPrize(btime,etime)
	local allbets =  getUserBetInfo(btime,etime)
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
				per_winner_bonus = gold *15
			end 
		end
		for _, v in pairs(value.fv) do
			if FprizesMP[v] then
				per_winner_bonus = per_winner_bonus +  gold*1.9
			end 
		end

		saveUserPrizeInfo({time = etime,uid = uid,prize = per_winner_bonus,bet = betmoney})
		local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, per_winner_bonus,
		"时时彩中奖")
		print(uid .. "时时彩 中奖，获得奖金：" .. per_winner_bonus )
		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney
		if per_winner_bonus > 0 then 
			prinzeusernums = prinzeusernums + 1
		end 
	end
	saveGamePrizeInfo({time = etime,totablbonus = totablbonus,totablbetmoney = totablbetmoney,usernums = usernums,prinzeusernums = prinzeusernums,prizes= prizes})
	
end

local betconfig = {1,5,10,20,100}
local basescore = 200
--投注
function addbet(uid,data)
	if not data or not data.betindex or not data.prizes then
		return  ErrorDefine.ERROR_PARAM
	end
	if data.betindex <1 or data.betindex >5  then
		return  ErrorDefine.ERROR_PARAM
	end
	local gold = betconfig[data.betindex] *basescore 
	local t = data.prizes.t
	local f = data.prizes.f
	if not t or table.empty(t) then
		return  ErrorDefine.ERROR_PARAM
	end

	if table.Or(t,function (v,k)
		return v>64 or v <1
	end)  or  table.Or(f,function (v,k)
		return v>1 or v <0
	end)  then
		return  ErrorDefine.ERROR_PARAM
	end
	 local betnums = table.nums(t)+table.nums(f)
	local betmoney = gold * betnums 
	 -- 执行扣费
	local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,betmoney,
	"时时彩")
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
function getUserPrizeInfo(time)
	local filter = unilight.eq('time',time)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_PRIZELOG_NAME).Filter(filter))
	return all 
end


function saveGamePrizeInfo(data)
	unilight.savedata(TABLE_NAME, data)
end

function getGamePrizeInfo()
	local filter =  unilight.gt('_id',0)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter).OrderBy(unilight.desc("time")).Limit(20)) 
	return all 
end



function saveUserBetInfo(data)
	unilight.savedata(TABLE_LOG_NAME, data)
end

function getUserBetInfo(btime,etime)
	etime = etime or (btime+600)
	print("timelycolor Getbetinfo begintime",btime)
	print("timelycolor Getbetinfo etime",etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return all
end


function getVipInfo(btime,etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_VIPPL_NAME).Filter(filter))
	return res
end



function Get_info_Cmd_C()
	local all = getGamePrizeInfo()
	local res = {game={},basescore = basescore,betconfig=betconfig,isbet= not table.empty(getUserBetInfo(get_last_tenmin()))}
	for _, value in pairs(all) do
		local data = value
		local log = getuserPrizeInfo(value.time)
		table.insert(res.game,{data = data,log = log })
	end
	return res 
end
