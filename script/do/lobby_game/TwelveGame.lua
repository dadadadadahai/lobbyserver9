module('twelvegame', package.seeall) -- 十二生肖
-- 十二生肖
local tableMailConfig = import "table/table_mail_config"
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
GameID = 888
TABLE_CONTROL_NAME = "smallgamecontrol"
local data = import "script/do/lobby_game/TwelveGameConf"

local constindex = 1
local function get_last_tenmin()
	return math.floor(os.time()/600)*600
end
local function get_next_tenmin()
	return get_last_tenmin() +600
end
local NEXTOPENTIME = get_next_tenmin()
function Tick() --一分钟执行一次
	if  os.time() <  NEXTOPENTIME  then
		return
	end
	local endtime = NEXTOPENTIME
	local begintime = NEXTOPENTIME - 600
	print("twelvegameTick"..NEXTOPENTIME)
	OpenPrize(begintime,endtime)
	NEXTOPENTIME = NEXTOPENTIME +600
end 


function GettTelvePrize(i)
	-- local prizes = {t={},f={}}
	-- local curtw = table.clone(CONSTTWELVE)
	-- if table.empty(mustprize) then
	-- 	for i = 1, 3, 1 do
	-- 		table.insert(prizes.t,table.remove(curtw,math.random(#curtw)))
	-- 	end
	-- 	table.insert(prizes.f,CONSTFIVE[math.random(#CONSTFIVE)])
	-- else
	-- end 
	local r = (constindex+i)%1100+1
	print(constindex,i,r)
	return data[r]
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
		local per_winner_bonus = 0
		for _, v in pairs(value.tw) do
			if TprizesMP[v] then
				winnums = winnums +1
			end 
		end
		if winnums == 3 then 
			per_winner_bonus =   15 *  3 * gold 
		elseif winnums == 2 then 
			per_winner_bonus =   2.5 *  3 * gold 
		elseif winnums == 1 then 	
			per_winner_bonus =   0.75 *  3 * gold 
		end 
	
		if not  table.empty(value.fv) then 
			if winnums <1 then 
				for _, v in pairs(value.fv) do
					if FprizesMP[v] then
						winnums = winnums +1
					end 
				end
			else 
				local iswinf = false 
				for _, v in pairs(value.fv) do
					if FprizesMP[v] then
						iswinf = true
						winnums = winnums +1
						per_winner_bonus = per_winner_bonus * 3
					end
				end
				if not iswinf then
					per_winner_bonus = 0
				end
			end
		end
		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney
	end
	return prizes ,totablbonus,totablbetmoney
end 
--game tongsha 
function GetTongshaPro()
	local filter =  unilight.eq('game',GameID)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_CONTROL_NAME).Filter(filter))
	dump(all)
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
	constindex = math.random(1100)
	local tongshapro = math.random(10000) < GetTongshaPro()
	for i = 1, 1100, 1 do
		prizes, totablbonus,totablbetmoney= getOneOpenPrizes(allbets,i)
		if not table.empty(allbets) then
			if not tongshapro then
				if totablbetmoney >=totablbonus and totablbonus > 0  then
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
	print(os.time())
	local prizes = OpenPrizes(allbets)
	print(os.time())
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
		local per_winner_bonus = 0
		local winprizes = {t={},f={}}
		for _, v in pairs(value.tw) do
			if TprizesMP[v] then
				winnums = winnums +1
				table.insert(winprizes.t,v)
			end 
		end

		if winnums == 3 then 
			per_winner_bonus =   15 *  3 * gold
		elseif winnums == 2 then 
			per_winner_bonus =   2.5 *  3 * gold
		elseif winnums == 1 then 	
			per_winner_bonus =   0.75 *  3 * gold
		end
	
		if not  table.empty(value.fv) then 
			if winnums <1 then 
				for _, v in pairs(value.fv) do
					if FprizesMP[v] then
						winnums = winnums +1
						table.insert(winprizes.f,v)
					end 
				end
			else 
				local iswinf = false 
				for _, v in pairs(value.fv) do
					if FprizesMP[v] then
						iswinf = true
						winnums = winnums +1
						per_winner_bonus = per_winner_bonus * 3
						table.insert(winprizes.f,v)
					end 
				end
				if not iswinf then
					per_winner_bonus = 0 
				end 
			end 
		end 
		saveUserPrizeInfo({time = etime,uid = uid,win = per_winner_bonus,bet = betmoney,bets = {t=value.tw,f=value.fv},winprizes = winprizes})
		--local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, per_winner_bonus,
		--"十二生肖中奖")
		print(uid .. "十二生肖中奖 中奖，获得奖金：" .. per_winner_bonus )
		totablbonus  = 	totablbonus  + per_winner_bonus
		totablbetmoney  = 	totablbetmoney  + betmoney
		--统计流水
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
--投注 ERROR_PARAM
function addbet(uid,data)
	if not data or not data.betIndex or not data.prizes then
		return  ErrorDefine.ERROR_PARAM,"参数错误"
	end
	if data.betIndex <1 or data.betIndex >5  then
		return  ErrorDefine.ERROR_PARAM,"下注错误"
	end

	 local gold = betconfig[data.betIndex] *basescore 
	 local t = data.prizes.t --{30}
	 local f = data.prizes.f -- {0}
	if not t or table.empty(t) or table.nums(t) ~= 3  then
		return  ErrorDefine.ERROR_PARAM,"没有下注"
	end
	if not table.empty(f) and  table.nums(f) ~= 1  then
		return  ErrorDefine.ERROR_PARAM,"下注越界"
	end

	if table.Or(t,function (v,k)
		return v>12 or v <1
	end)  or  table.Or(f,function (v,k)
		return v>5 or v <1
	end)  then
		return  ErrorDefine.ERROR_PARAM,"下注越界"
	end
	if not table.empty(getUserBetInfoOne(NEXTOPENTIME-600,uid)) then 
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
	"十二生肖")
	if ok == false then
       return  ErrorDefine.CHIPS_NOT_ENOUGH,"没有钱"
    end
	print("addbet")
	saveUserBetInfo({time = os.time(),uid =uid,gold = gold,betnums =betnums,tw=t,fv = f})
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
	dump(data,"twelvegamesaveGamePrizeInfo",10)
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
	local res = {game={},nextopentime = NEXTOPENTIME - os.time(),basescore = basescore,betconfig=betconfig,isbet= not table.empty(getUserBetInfoOne(NEXTOPENTIME-600,uid))}
	for _, value in pairs(all) do
		local data = value
		local log = getUserPrizeInfo(value.time,uid)
		table.insert(res.game,{data = data,log = log })
	end
	return res 
end