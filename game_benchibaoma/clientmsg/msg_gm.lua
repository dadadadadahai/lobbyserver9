Net.CmdLotteryControlRequestGmCmd_C = function(cmd, laccount)
    local res = {}
    res["do"] = "Cmd.LotteryControlRequestGmCmd_S"
    res["data"] = {}
    local uid = laccount.Id
    local gmLevel = laccount.GetGmlevel() 
    if gmLevel < 1 then
        unilight.error("不是GM的玩家发了gm命令，无视")
    end
    if cmd.data == nil or cmd.data.control == nil or cmd.data.roomId == nil then
	    res.data.resultCode= 1 
	    res.data.desc = "参数缺少" 
    end
    local control = cmd.data.control
    local roomId = cmd.data.roomId
    unilight.info("debug 收到gm控制开将命令管理员：" .. uid .. table.tostring(cmd.data))
	local ret, desc = RoomMgr.GmControl(roomId, control)
	res.data.resultCode= ret 
	res.data.retdesc = desc
    return res
end
