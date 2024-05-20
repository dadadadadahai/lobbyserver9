module('backRealtime',package.seeall)
--用户在线位置管理
lobbyOnlineUserManageMap={}


--用户登陆上报,lobby
function userLoginInToLoddy(uid)
   local zoneId,gameId = gamecommon.GetGameZoneId()
   if gameId==1000 then
      --本地管理
      lobbyOnlineUserManageMap[uid] = 1
   else
      --发到大厅处理
      local uInfo = unilight.getdata('userinfo',uid)
      uInfo.point.rtp = 0
      ChessToLobbyMgr.SendCmdToLobby('Cmd.UserLoginInCmd_C',{uid=uid,chip=uInfo.property.chips})
   end
   --设置redis玩家在线信息
   
end
--用户离开上报,lobby
function userLoginOutToLoddy(uid)
   local zoneId,gameId = gamecommon.GetGameZoneId()
   if gameId==1000 then
      --本地管理
      lobbyOnlineUserManageMap[uid] = nil
   else
      ChessToLobbyMgr.SendCmdToLobby('Cmd.UserLoginOutCmd_C',{uid=uid})
   end
end



--定时器上报在线用户情况,只上报需要的数据
--id 金币 流水 剩余打码数 最高允许金币 充值数 总提现数
function gameTimerToLobby()
   local dataToLobby={}
   if mongo_data_cache['userinfo']~=nil then
      for uid,data in pairs(mongo_data_cache['userinfo']) do
         local uValue = data.data
         local withdrawcashUid =  storecatch.Get('withdrawcash',uid)
         local statement,totalWithdrawal=0,0
         if withdrawcashUid~=nil then
            statement = withdrawcashUid.statement
            totalWithdrawal = withdrawcashUid.totalWithdrawal
         end
         local item={
            uid=uid,
            chips = uValue.property.chips,
            totalRechargeChips=uValue.property.totalRechargeChips,
            chargeMax=uValue.point.chargeMax,
            statement = statement,
            totalWithdrawal = totalWithdrawal,
            rtp = uValue.point.rtp or 0,
            --点控类型
            autocontroltype = uValue.point.autocontroltype,
            --点控系数
            controlvalue = uValue.point.controlvalue,
            --注册类型
            regFlag=uValue.base.regFlag,
            --总押注
            slotsBet = uValue.gameData.slotsBet,
            --总返还
            slotsWin = uValue.gameData.slotsWin,
         }
         table.insert(dataToLobby,item)
      end
   end
   if table.empty(dataToLobby)==false then
      ChessToLobbyMgr.SendCmdToLobby('Cmd.GameDataToLobbyCmd_C',{data=dataToLobby})
   end
end