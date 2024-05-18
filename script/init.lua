json = require 'cjson'
subGameId=0
allMs = {} --所有配表资源模块,方便热更新
SuserId = SuserId or { uid = 0 }
--初始时间放在这一下
iStandTime = os.time({ year = 2017, month = 1, day = 2, hour = 0, minute = 0, second = 0, isdst = false })
require "script/gxlua/reload"
require "script/gxlua/unilight"
require "script/gxlua/class"
require "script/do/constant/constant"
require "script/do/constant/gameevent"
require "script/gxlua/extend"
--加载全局控制表
Table_ctr_whole = import 'table/table_ctr_whole'
Table_ctr_player = import 'table/table_ctr_player'
if Do == nil then Do = {} end
--debug状态下的服务器加载
local function debugInit()

	-- for _, file in pairs(unilight.tablefiles()) do
	-- 	-- unilight.debug("正在加载脚本:"..file)
	-- 	dofile(file)
	-- end
	--为了不折分游戏逻辑，使用同一套代码，在这加载区分下
	local zoneKey = go.config().GetConfigStr("zone_key")
	local gameId = tonumber(string.split(zoneKey, ":")[1])
	if Const.GAME_PATH[gameId] ~= nil then
		for _, pathName in ipairs(Const.GAME_PATH[gameId]) do
			local customFiles = unilight.customfiles(pathName)
			for _, file in pairs(customFiles) do
				-- unilight.debug("加载自定义脚本:" .. file)
				dofile(file)
			end
		end
	end
	for _, file in pairs(unilight.scriptfiles()) do
		-- unilight.debug("正在加载脚本:"..file)
		dofile(file)
	end
end
local function releaseInit()
	
	for _, file in pairs(unilight.scriptfiles()) do
		-- unilight.debug("正在加载脚本:"..file)
		dofile(file)
	end
	local zoneKey = go.config().GetConfigStr("zone_key")
	local gameId = tonumber(string.split(zoneKey, ":")[1])
	local zoneId = tonumber(string.split(zoneKey, ":")[2])
	subGameId = tonumber(string.sub(string.split(zoneKey, ":")[2],1,3))
	--1001 大厅 1002 游戏
	-- for _, file in pairs(unilight.tablefiles()) do
	-- 	dofile(file)
	-- end
	if gameId==1001 or gameId==1000 then
		if Const.GAME_PATH[gameId] ~= nil then
			for _, pathName in ipairs(Const.GAME_PATH[gameId]) do
				local customFiles = unilight.customfiles(pathName)
				for _, file in pairs(customFiles) do
					dofile(file)
				end
			end
		end
	else
		local slots = 'game_slots'
		local customFiles = unilight.customfiles(slots)
		for _, file in pairs(customFiles) do
			local splits = string.split(file,'/')
			if #splits>=3 then
				local middle = splits[2]
				if string.find(middle,subGameId)~=nil and string.find(middle,subGameId)>-1 then
					dofile(file)
				end
			end
		end
		dofile(slots..'/gameinit.lua')
	end
end




local function init()
	math.randomseed(os.time())
	math.random()
	if unilight.getdebuglevel() > 0 then
		--debug模式下
		debugInit()
	else
		--正式模式下
		releaseInit()
	end
	InitTimer()
	unilight.debug("初始化lua脚本成功")
	-- 覆盖 unilight.lua 中的默认实现
	unilight.response = function(w, req)
		if w == nil then
			return w
		end
		req.st = os.msectime() / 1000
		-- local s = json.encode(encode_repair(req))
		local s = json.encode(req)
		-- local enstr = go.ImagePools.GzipDataBase64(s)
		w.SendString(s)
		-- print('CaleOnlineInfo',enstr)
		if Const.IGNORE_MSG[req["do"]] == nil then
			-- unilight.debug("[send] " .. s)
		end
	end
end
init()