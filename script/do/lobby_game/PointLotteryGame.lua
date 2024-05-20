module('Pointlottery', package.seeall) -- 积分抽奖
-- 表名
TABLE_NAME = "pointlottery"
TABLE_PRIZELOG_NAME = "pointlotteryprizelog"
TABLE_LOG_NAME = "pointlotterybetlog"
TABLE_VIPPL_NAME = "vippointlottery"
-- 生成区

--local curdata = { time =1,totalbet=1000,minbet = 500,curbet= 0 ,prizename = "金币",prizeid = 1,prizenum =2,prizeplayer=2,isfinish=0 }
--data = {
--	  _id  -- 编号自动生成
--	  time -- 开奖时间
	--totalbet --总投注数量
	--minbet -- 最低投注数量 
	--curbet   --已经投注数量
	--prizename --奖品名字
	--prizeid  -- 奖品ID
	--prizenum --奖品总数量
	--prizeplayer -- 中将人数量
    --isfinish  --是否已经结算过 0代表没有
--}


function PLTick() --一分钟执行一次
	local time = os.time()
	--print("PLTick"..time)
	local all =  Getplinfo()
	for _, pt in pairs(all) do
		if  pt.isfinish ==0   then
			if pt.time <= time then
				OpenPrize(pt)
			end 
		end
	end
end 
function GetPointLottery(pid)
	local filter = unilight.eq('_id',pid)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
	local res = nil 
	for _, value in pairs(all) do
		res = value
	end
	return res 
end

function Getplinfo()
	local begintime  = chessutil.getTimestampForLastNDaysMidnight(3)
	print("Getplinfo begintime",begintime)
	local filter = unilight.ge('time',begintime)
	local all =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_NAME).Filter(filter))
	return all 
end 
function Getplinfo_Cmd_C()
	local all = Getplinfo()
	local res = {}
	for _, value in pairs(all) do
		local data = value
		local log = getuserPrizeInfo(value._id)
		table.insert(res,{data = data ,log=log})
	end
	return res 
end

--投注
function addbet(uid,pid)
	local pl = GetPointLottery(pid)
	if not pl then 
		print("no pl ",pid)
		return 1
	end 

	if pt.curbet >= pt.totalbet then
		print("nopt",pid)
		return 2
	end
	 -- 执行扣费
	local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB,100,
	"积分抽奖ID"..pid)
	if ok == false then
       return  ErrorDefine.CHIPS_NOT_ENOUGH
    end
	print("addbet")
	local where = { _id=pid}
	local data = {curbet = pl.curbet + 100}
    unilight.startChain().Table("pointlottery").Update(where,{['$set']= data})
	saveUserBetInfo(uid,pid)
	return 0 
end
--开奖
--投注
function OpenPrize(pt)
	if pt.curbet < pt.minbet then
		ReturnPoints(pt)
		return 
	end 
	local plvipInfos = getplvipInfo(pt._id) -- VIP设置中奖人
	local MapplvipInfo = { }
	if  not table.empty(plvipInfos) then
		for _, user in ipairs(plvipInfos) do
			local uid = user.uid
			MapplvipInfo[uid] = 1
		end
	end
	local participants = {} -- 参与者列表
	local userBetInfos = getuserBetInfo(pt._id)
	local curuserbet = {}
    for _, user in ipairs(userBetInfos) do
		local uid = user.uid
		if  table.empty(MapplvipInfo) then 
			table.insert(participants,uid)
			curuserbet[uid] = (curuserbet[uid] or 0 ) + 100
		else
			if  MapplvipInfo[uid] then
				table.insert(participants,uid)
				curuserbet[uid] = (curuserbet[uid] or 0 ) + 100
			end 
		end
    end
    
    -- 随机选择中奖者
    local winners = {}
    for i = 1, pt.prizeplayer do
        local index = math.random(1, #participants)
        table.insert(winners, participants[index])
        table.remove(participants, index)
    end
    
    -- 平分奖金
    local total_bonus = pt.prizenum
    local per_winner_bonus = total_bonus / pt.prizeplayer
    
    -- 显示中奖结果
    for _, winner in ipairs(winners) do
		saveUserPrizeInfo({plid = pt._id,uid = winner,prize = per_winner_bonus,bet = curuserbet[winner]})
		local remainder, ok = chessuserinfodb.WChipsChange(winner, Const.PACK_OP_TYPE.ADD, per_winner_bonus,
		"积分抽奖奖励ID"..pt._id)
        print(winner .. " 中奖，获得奖金：" .. per_winner_bonus )
    end
end

function ReturnPoints(pt)
	dump(pt,"ReturnPoints",10)
	local participants = {} -- 参与者列表
	local userBetInfos = getuserBetInfo(pt._id)
	local curuserbet = {}
    for _, user in ipairs(userBetInfos) do
		local uid = user.uid
		table.insert(participants,uid)
		curuserbet[uid] = (curuserbet[uid] or 0 ) + 100
    end
     -- 执行扣费
	 for uid, value in pairs(curuserbet) do
		local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.ADD, value,
		"积分抽奖返还ID"..pt._id)
		if ok == false then
			unilight.error("ReturnPoints ",uid,value)
		end
	 end
	 pt.isfinish = 1
	 local where = { _id=pt._id}
	 local data = {isfinish = 1}
	 unilight.startChain().Table("pointlottery").Update(where,{['$set']= data})
end 



function saveUserPrizeInfo(data)
	unilight.savedata(TABLE_PRIZELOG_NAME, data)
end

function getuserPrizeInfo(id)
	local filter = unilight.eq('plid',id)
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_PRIZELOG_NAME).Filter(filter))
	return res 
end


function saveUserBetInfo(uid,plid)
	local data = {uid = uid ,plid = plid,}
	unilight.savedata(TABLE_LOG_NAME, data)
end

function getuserBetInfo(plid)
	local filter = unilight.eq('plid',plid)
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_LOG_NAME).Filter(filter))
	return res 
end


function getplvipInfo(plid)
	local filter = unilight.eq('plid',plid)
	local res =  unilight.chainResponseSequence(unilight.startChain().Table(TABLE_VIPPL_NAME).Filter(filter))
	return res
end


