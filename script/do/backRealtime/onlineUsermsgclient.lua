--玩家信息操作,收到大厅消息请求
Lby.CmdPunishUserToGameCmd_S=function(cmd, lobbytask)
    local uid = cmd.data.uid
    local punishvalue = cmd.data.punishvalue
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    if laccount~=nil then
        local userinfo = unilight.getdata('userinfo',uid)
        userinfo.point.controlvalue = punishvalue
        userinfo.point.autocontroltype = 2
        unilight.update('userinfo',uid,userinfo)
    end
end