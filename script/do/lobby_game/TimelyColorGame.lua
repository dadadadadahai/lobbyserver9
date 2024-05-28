
module('timelycolor', package.seeall) 
-- 数字球抽奖
local tableMailConfig = import "table/table_mail_config"

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
TABLE_CONTROL_NAME = "smallgamecontrol"
GameID = 777
local constindex = 1
local function get_last_tenmin()
	return math.floor(os.time()/600)*600   
end
local function get_next_tenmin()
	return  get_last_tenmin() +600
end
local NEXTOPENTIME =  get_next_tenmin() 
function Tick() --一分钟执行一次
	if  os.time() <  NEXTOPENTIME  then
		return
	end
	local endtime = NEXTOPENTIME
	local begintime = NEXTOPENTIME - 600
	print("timelycolorTick"..NEXTOPENTIME)
	OpenPrize(begintime,endtime)
	NEXTOPENTIME = NEXTOPENTIME +600
end 


function GettTelvePrize(i)
	local prizes = {t={},f={}}
	local r = constindex+i%64+1
	print(constindex,i,r)
	local curnumber = CONSTTIMELYCOLOR[r]
	table.insert(prizes.t,curnumber)
	table.insert(prizes.f,curnumber%2) --0是双--1是单
	return prizes
end 
function getOneOpenPrizes(allbets,i)
	local prizes = GettTelvePrize(i)
	local TprizesMP = table.map(prizes.t,function (v,k)
		return v,true
	end)
	local FprizesMP = table.map(prizes.f,function (v,k)
		return v,true
	end)

	local totablbonus = 0
	local totablbetmoney = 0
	for key, value in pairs(allbets) do
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

		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney

	end
	return prizes ,totablbonus,totablbetmoney
end
function GetTongshaPro()
	local filter =  unilight.eq('game',GameID)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_CONTROL_NAME).Filter(filter))
	dump(all,"all",10)
	if table.empty(all) then
		return 100
	else 
		for _, value in pairs(all) do
			return value.tongsha
		end
	end 
end 

function OpenPrizes(allbets)
	local prizes, totablbonus,totablbetmoney
	local curprizes = {}
	constindex = math.random(64)
	local tongshapro = math.random(10000) < GetTongshaPro()
	for i = 1, 64, 1 do
		 prizes, totablbonus,totablbetmoney= getOneOpenPrizes(allbets,i)
		 if not table.empty(allbets)  then 
			if not tongshapro then 
				if totablbetmoney >=totablbonus and totablbonus >0  then
					return prizes
				end
			else
				if totablbetmoney >=totablbonus and totablbonus == 0  then
					return prizes
				end
			end 
		else
			return prizes
		end 
		 table.insert(curprizes,{prizes=prizes,tt = totablbetmoney -totablbonus })
	end
	local key = table.max(curprizes,function (v)
		return v.tt
	end)
	return curprizes[key].prizes
end

function OpenPrize(btime,etime)
	local allbets =  getUserBetInfo(btime,etime)
	local prizes = OpenPrizes(allbets)
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
		local winprizes = {t={},f={}}
		for _, v in pairs(value.tw) do
			if TprizesMP[v] then
				winnums = winnums +1
				per_winner_bonus = gold *15
				table.insert(winprizes.t,v)
			end 
		end
		for _, v in pairs(value.fv) do
			if FprizesMP[v] then
				per_winner_bonus = per_winner_bonus +  gold*1.9
				table.insert(winprizes.f,v)
			end 
		end
		saveUserPrizeInfo({time = etime,uid = uid,win = per_winner_bonus,bet = betmoney,bets = {t=value.tw,f=value.fv},winprizes = winprizes})
		--local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, per_winner_bonus,
		--"时时彩中奖")
		print(uid .. "时时彩 中奖，获得奖金：" .. per_winner_bonus )
		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney
			-- 增加后台历史记录
			gameDetaillog.SaveDetailGameLog(
				uid,
				etime,
				GameID,
				1,
				betmoney,
				0,
				per_winner_bonus,
				0,
				{type='normal'},
				{}
			)
		if per_winner_bonus > 0 then 
			prinzeusernums = prinzeusernums + 1
			    --发送邮件
			local mailInfo = {}
	
			local mailConfig = tableMailConfig[49]
			mailInfo.charid = uid
			mailInfo.subject = mailConfig.subject
			mailInfo.content = string.format(mailConfig.content,per_winner_bonus/100) 
			mailInfo.type = 0 --0是个人邮件
			mailInfo.attachment = {}
			mailInfo.extData = {configId=mailConfig.ID}
			table.insert(mailInfo.attachment,{itemId=Const.GOODS_ID.GOLD, itemNum=per_winner_bonus})
			ChessGmMailMgr.AddGlobalMail(mailInfo)
		end 
	end
	saveGamePrizeInfo({time = etime,totablbonus = totablbonus,totablbetmoney = totablbetmoney,usernums = usernums,prinzeusernums = prinzeusernums,prizes= prizes})
	
end

local betconfig = {1,5,10,20,100}
local basescore = 200
--投注
function addbet(uid,data)
	if not data or not data.betIndex or not data.prizes then
		return  ErrorDefine.ERROR_PARAM,"参数错误"
	end
	if data.betIndex <1 or data.betIndex >5  then
		return  ErrorDefine.ERROR_PARAM,"下注错误"
	end
	local gold = betconfig[data.betIndex] *basescore 
	local t = data.prizes.t
	local f = data.prizes.f
	if not t or table.empty(t)  or table.nums(t) > 1 then
		return  ErrorDefine.ERROR_PARAM,"没有下注"
	end
	if not table.empty(f) and  table.nums(f) ~= 1  then
		return  ErrorDefine.ERROR_PARAM,"下注越界"
	end


	if table.Or(t,function (v,k)
		return v>64 or v <1
	end)  or  table.Or(f or {},function (v,k)
		return v>1 or v <0
	end)  then
		return  ErrorDefine.ERROR_PARAM,"下注越界"
	end
	if not table.empty(getUserBetInfoOne(NEXTOPENTIME-600,uid))  then 
		return  ErrorDefine.ERROR_PARAM,"已经下注"
	end 
	local tgroup = table.group(t,function (v,_)
		return v
	end)
	
	if table.Or(tgroup,function (v,k)
		return table.nums(v) > 1
	end)   then
		return  ErrorDefine.ERROR_PARAM,"不能一个元素下多次"
	end
	 local betnums = table.nums(t)+table.nums(f)
	local betmoney = gold * betnums 
	 -- 执行扣费
	local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,betmoney,
	"时时彩")
	if ok == false then
       return  ErrorDefine.CHIPS_NOT_ENOUGH,"没有钱"
    end
	print("addbet")
	saveUserBetInfo({time = os.time(),uid =uid,gold = gold,betnums =betnums,tw=t,fv = f  })
	return 0 ,"ok"
end

function saveUserPrizeInfo(data)
	unilight.savedata(TABLE_PRIZELOG_NAME, data)
end
function getUserPrizeInfo(time,uid)
	local filter =unilight.a(unilight.eq('time',time),unilight.eq('uid',uid))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_PRIZELOG_NAME).Filter(filter))
	return all 
end


function saveGamePrizeInfo(data)
	dump(data,"timelycolorsaveGamePrizeInfo",10)
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
	print("timelycolor Getbetinfo begintime",btime)
	print("timelycolor Getbetinfo etime",etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return all
end

function getUserBetInfoOne(btime,uid)
	local etime = btime+600
	print("twelvegame Getbetinfo begintime",btime)
	print("twelvegame Getbetinfo etime",etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime),unilight.eq('uid',uid))
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return all
end


function getVipInfo(btime,etime)
	local filter =  unilight.a(unilight.ge('time',btime),unilight.lt('time',etime))
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_VIPPL_NAME).Filter(filter))
	return res
end



function Get_info_Cmd_C(uid)
	local all = getGamePrizeInfo()
	local res = {game={},nextopentime = NEXTOPENTIME - os.time(),basescore = basescore,betconfig=betconfig,isbet= not table.empty(getUserBetInfoOne(NEXTOPENTIME-600,uid)) }
	for _, value in pairs(all) do
		local data = value
		local log = getUserPrizeInfo(value.time,uid)
		table.insert(res.game,{data = data,log = log })
	end
	return res 
end
