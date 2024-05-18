module('Timer', package.seeall) 

function Init() 
	unilight.addtimer("Timer.OnTimer1SecTick", 1)
	-- unilight.addtimer("annagent.BroadCastGameOnline", 60)
end
-- 一秒定时器，来定时做一些消息推送
function OnTimer1SecTick()
	
end