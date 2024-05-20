TASK_ID_LOGIN = 8 

ENUM_SET_TYPE = {
	MUSIC = 1,
	SOUND = 2, 
	RANK  = 3, 
}
--用户发消息请求登陆
Net.CmdUserInfoSynRequestLbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserLoginReturnLbyCmd_S"
	local uid = laccount.Id
	local platInfo = {}
	--点控恢复删除
	ChessGmUserInfoMgr.CheckUserPunish(uid, Const.BAN_TYPE.CONTROL)
	-- 损失返利计算
	LossRebate.isRefresh(uid)
	local userInfo = chessuserinfodb.RUserLoginGet(uid, cmd.data)
    unilight.info("玩家登陆:"..uid..", chips="..userInfo.property.chips)
	local userBaseInfo = chessuserinfodb.RUserBaseInfoGet(userInfo)	
	res["data"] = {
		errno = 0,
		desc = "ok",
		userInfo = userBaseInfo,
	}
    local curDayNo = chessutil.GetMorningDayNo()
    if userInfo.status.lastLoginDayNo ~= curDayNo  then
        --跨天清除玩家赢取的钱
        userInfo.property.slotsWins = 0
        --更新登陆天数
        userInfo.status.lastLoginDayNo = curDayNo
    end	
	-- 检测是否显示首充礼包	(系统开始后 未充值过 或 充值达额且未领取奖励 的玩家 显示)
	if userInfo.recharge.first == nil or (userInfo.recharge.first >= 1000 and userInfo.recharge.isGot == false) then
		res["data"].isShow = true
	else
		res["data"].isShow = false
	end
	-- apk首次登陆奖励
    res["data"].userInfo.apkFirstReward = -1
    --活动开启编号
    res["data"].activityId = ActivityMgr.GetOpenActivityNumber()

	-- 更新登陆时间
	userInfo.status.lastlogintime = userInfo.status.logintime
	userInfo.status.logintime = chessutil.FormatDateGet()
    userInfo.status.logintimestamp = os.time()
    userInfo.status.lastLoginIp = laccount.GetLoginIpstr()
    userInfo.status.lastLoginImei = laccount.JsMessage.GetImei()
	-- 更新玩家渠道	1 安卓网页 2 苹果网页 3 安卓客户端 4 苹果客户端 5 windows
	if cmd.data.loginPlatId ~= nil then
		-- 只更新安卓和苹果客户端的数据
		if cmd.data.loginPlatId ~= nil and userInfo.status.loginPlatId < cmd.data.loginPlatId and (cmd.data.loginPlatId == 3 or cmd.data.loginPlatId == 4) then
			userInfo.status.loginPlatId = cmd.data.loginPlatId
		end
		local againFlag = false
		if table.empty(userInfo.status.loginPlatIds) == false then
			for _, loginPlatId in ipairs(userInfo.status.loginPlatIds) do
				-- 下标增加
				if loginPlatId == cmd.data.loginPlatId then
					againFlag = true
					break
				end
			end
		end
		-- 判断玩家是否登陆过APK
		if table.empty(userInfo.status.loginPlatIds) or (not againFlag) then
			-- 插入前判断是否是首次进入APK  首次进入需要下发奖励
			if #userInfo.status.loginPlatIds <= 2 then
				local firstApkFlag = true
				-- 如果现在平台不是安卓APK也不能发送
				if cmd.data.loginPlatId < 3 then
					firstApkFlag = false
				end
				if cmd.data.loginPlatId == 5 then
					firstApkFlag = false
				end
				if userInfo.status.loginPlatReward ~= 0 then
					firstApkFlag = false
				end
				-- -- 遍历查找玩家是否登陆过安卓APK
				-- for _, loginPlatId in ipairs(userInfo.status.loginPlatIds) do
				-- 	if loginPlatId >= 3 then
				-- 		firstApkFlag = false
				-- 		break
				-- 	end
				-- end
				-- 首次登陆下发奖励
				if firstApkFlag == true then
					--赠送金币
					local addScore = (import "table/table_parameter_parameter")[37].Parameter
					local mailInfo = {}
					local tableMailConfig = import "table/table_mail_config"
					local mailConfig = tableMailConfig[41]
					userInfo.status.loginPlatReward = 1
					if userInfo.status.experienceStatus == 1 then
						addScore = (import "table/table_parameter_parameter")[33].Parameter
						mailConfig = tableMailConfig[40]
						WithdrawCash.AddBet(uid, addScore * 3)
						userInfo.status.loginPlatReward = 2
					end
					mailInfo.charid = uid
					mailInfo.subject = mailConfig.subject
					mailInfo.content = string.format(mailConfig.content,addScore / 100,chessutil.FormatDateGet(nil,"%d/%m/%Y %H:%M:%S"))
					mailInfo.configId = 30
					mailInfo.type = 0
					-- mailInfo.attachment={{itemId=3, itemNum=addScore}}
					mailInfo.extData={configId=mailConfig.ID,isPresentChips = 1}
					ChessGmMailMgr.AddGlobalMail(mailInfo)
					BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, addScore, Const.GOODS_SOURCE_TYPE.BINDAPK)
					res["data"].userInfo.apkFirstReward = addScore
				end
			end
			-- 登陆过则需要插入
			table.insert(userInfo.status.loginPlatIds,cmd.data.loginPlatId)
		end
	end

    --上线统计下下级人数
    userInfo.status.childNum = chessuserinfodb.GetBelowNum(uid)

	chessuserinfodb.WUserInfoUpdate(uid, userInfo)
	
    UserInfo.UserLogin(uid)
    if unilight.getgameid() == Const.GAME_TYPE.LOBBY then
        UserInfo.UserLoginLobby(uid)
        --检测拉回
        local gameInfo = userInfo.gameInfo
        unilight.info(string.format("玩家:%d, 登陆大厅时,上次房间连接信息:gameId=%d,zoneId=%d",uid, gameInfo.gameId, gameInfo.zoneId  ))
        if gameInfo.gameId ~= 0 and gameInfo.gameId ~= Const.GAME_TYPE.LOBBY and gameInfo.gameId ~= Const.GAME_TYPE.SLOTS then
            local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(gameInfo.gameId, gameInfo.zoneId)
            if zoneInfo ~= nil then
                res["data"].roomInfo = {
                    lobbyId = gameInfo.subGameId * 10000 + gameInfo.subGameType, --    //大厅id
                    gameId  = gameInfo.gameId, --    //要连接的游戏id
                    zoneId  = gameInfo.zoneId, --    //要连接的大区id
                    globalRoomId = 0, -- //全局房间id
                    roomId  = 0, --    //房间id
                }
            end
        end
    end
	return res
end


-- 银行与携带互转协议
Net.CmdUserBankChipsTransferRequestLbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserBankChipsTransferReturnLbyCmd_S"
	if cmd.data == nil or cmd.data.exchangeType == nil or cmd.data.exchangeChips == nil or type(cmd.data.exchangeChips) ~= "number" then
		res["data"] = {
			resultCode = 1,
			desc = "参数有误"
		}
		return res
	end
	local uid = laccount.Id
	local chips = cmd.data.exchangeChips
	local exchangeType = cmd.data.exchangeType
	local bOk, remainder, bank = chessuserinfodb.WBankchipsExChange(uid, chips, exchangeType)
	if bOk == false then
		res["data"] = {
			resultCode = 2,
			desc = "筹码不足"
		}
		return res
	end

	res["data"] = {
		resultCode = 0,
		remainder = remainder,
		bankChips = bank,
	}
	return res
end


-- 主动请求各个游戏人数
Net.CmdGameOnlineNumLbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GameOnlineNumLbyCmd_S"

	-- 如果数据为空 则提前先跑一遍 获取数据
	if annagent.GameOnline == nil then
		annagent.BroadCastGameOnline()
	end

	res["data"] = annagent.GameOnline
	return res
end


-- 大厅选场协议
Net.CmdCheckEnterGameLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.CheckEnterGameLobbyCmd_S"
	if cmd.data == nil or cmd.data.gameId == nil or cmd.data.subGameId == nil or cmd.data.roomType == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不足"
		}
		return res
	end
	local uid = laccount.Id

	local ret, desc = EnterGameMgr.CheckEnterGame(uid, cmd.data.gameId, cmd.data.subGameId, cmd.data.roomType)
	res["data"] = {
		resultCode = ret,
		desc = desc,
	}
	return res
end


-- 大厅设置协议
Net.CmdGameSetLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GameSetLobbyCmd_S"
	if cmd.data == nil or cmd.data.key == nil or cmd.data.value == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不足"
		}
		return res
	end
	local uid = laccount.Id
	

	local userSetInfo = unilight.getdata("userset", uid)     --数据库获取内容
	if userSetInfo == nil then
		userSetInfo = {
			_id = uid,
			set = {}
		}
	end
	userSetInfo.set[cmd.data.key] = cmd.data.value

	res["data"] = {
		resultCode = 0,
		desc = "设置成功",
	}
	unilight.savedata("userset", userSetInfo)
	return res
end

-- 获取大厅 当前设置
Net.CmdGetGameSetLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetGameSetLobbyCmd_S"
	if cmd.data == nil or cmd.data.key == nil then
			res["data"] = {
				resultCode = 1,
				desc = "参数不足"
			}
			return res
		end
	local uid = laccount.Id

	local userSetInfo = unilight.getdata("userset", uid)     --数据库获取内容
	if userSetInfo == nil then
		res["data"] = {
			resultCode = 2,
			desc = "用户未设置过数据"
		}
		return res
	end

	res["data"] = {
		resultCode = 0,
		desc  = "获取设置成功",
		key = cmd.data.key,
		value  = userSetInfo.set[cmd.data.key]
	}
	return res
end


-- 获取10条公聊记录
Net.CmdGetCommonChatRecordLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetCommonChatRecordLobbyCmd_S"

	local record = chesscommonchat.GetCommonChatRecord()

	res["data"] = {
		resultCode 	= 0,
		desc  		= "获取公聊记录成功",
		chatRecords = record,
	}
	return res
end

-- 获取15条公告记录
Net.CmdGetCommonHonorRecordLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetCommonHonorRecordLobbyCmd_S"

	local record = chesscommonchat.GetCommonHonorRecord()

	res["data"] = {
		resultCode 	 = 0,
		desc  		 = "获取公告记录成功",
		honorRecords = record,
	}
	return res
end


-- 充值成功请求验证
Net.CmdRechargeQueryCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.RechargeQueryCmd_S"
	if cmd.data == nil or cmd.data.gameorder == nil or cmd.data.originalmoney == nil or cmd.data.ordermoney == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不足"
		}
		return res
	end
	local uid = laccount.Id
	cmd.data.token = cmd.data.token or ""
	cmd.data.extdata = cmd.data.extdata or ""
	local ret = laccount.RechargeQueryRequestIOS(cmd.data.gameorder, cmd.data.originalmoney, cmd.data.ordermoney, cmd.data.token, cmd.data.extdata)
	if ret == true then
		res["data"] = {
			resultCode = 0,
			desc = "向sdk发送充值查询成功",
		}
	else
		res["data"] = {
			resultCode = 2,
			desc = "向sdk发送充值查询失败",
		}
	end
	return res	
end


-- 进入首充礼包界面
Net.CmdIntoFirstRechargeCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.IntoFirstRechargeCmd_S"
	local uid = laccount.Id
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- 充值过 且 （首充低于1000 或 已经领过奖励） 则 不再显示首充礼包
	if userInfo.recharge.first ~= nil and (userInfo.recharge.first < 1000 or userInfo.recharge.isGot == true) then
	res["data"] = {
		resultCode 	= 1,
		desc  		= "当前首充礼包不显示 进入失败",
	}		
	end

	local canReceive = false
	if userInfo.recharge.first ~= nil and  userInfo.recharge.first >= 1000 and userInfo.recharge.isGot == false then
		canReceive = true
	end

	res["data"] = {
		resultCode 	= 0,
		desc  		= "进入首充礼包界面成功",
		canReceive  = canReceive,
	}
	return res
end


-- 领取首充礼包奖励
Net.CmdGetFirstRechargeCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetFirstRechargeCmd_S"

	local uid = laccount.Id
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- 满足条件 则可领取
	if userInfo.recharge.first ~= nil and  userInfo.recharge.first >= 1000 and userInfo.recharge.isGot == false then
		-- 获取物品(首充礼包 物品id 9)
		BackpackMgr.GetRewardGood(uid, 9, 1, Const.GOODS_SOURCE_TYPE.FSTRECHARGE)

		-- 状态存档(userInfo重新获取 因为在获取东西的时候 可能会修改到筹码相关内容)
		userInfo = chessuserinfodb.RUserInfoGet(uid)
		userInfo.recharge.isGot = true
		unilight.savedata("userinfo", userInfo)

		res["data"] = {
			resultCode 	= 1,
			desc  		= "首充礼包领取成功",
			firstReword = TableGoodsConfig[9].giftGoods,
			remainder   = userInfo.property.chips,
		}	
	else
		res["data"] = {
			resultCode 	= 1,
			desc  		= "不符合条件 礼包领取失败",
		}	
	end
	return res
end


-- 进入免费金币界面
Net.CmdIntoFreeGoldLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.IntoFreeGoldLobbyCmd_S"
	local uid = laccount.Id

	local _, _, surplus, all = BankRuptcyMgr.GetSubsidyBankruptcyTimes(uid)

	local _, _, turnTableInfo = TurnTableMgr.GetTurnTableInfo(uid)

	res["data"] = {
		resultCode = 0,
		desc = "获取免费金币相关信息成功",
		surplus = surplus,
		all = all,
		turnTimes = turnTableInfo.times,
	}
	return res
end

--请求buff列表
Net.CmdGetBuffListLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.BuffListLobbyCmd_S"
	local uid = laccount.Id

	local buffList = BuffMgr.GetBuffList(uid)
	res["data"] = {
		errno = 0,
		desc = "",
		buffInfo = buffList,
	}
	return res
end

--查找玩家
Net.CmdFindPlayerLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.FindPlayerLobbyCmd_S"
    if cmd.data == nil or cmd.data.uidList == nil or type(cmd.data.uidList) ~= "table" then
        res["data"] = {
            errno = 1,
            desc = "参数错误",
        }
        return res
    end

    local userBaseInfoList = {}

    local orList = {}

    for k, tarUid in pairs(cmd.data.uidList) do
        table.insert(orList, unilight.eq("uid", tarUid))
    end

    local filter =  unilight.o(unpack(orList))
    local chain = unilight.startChain().Table("userinfo").Filter(filter)
    local userList = unilight.chainResponseSequence(chain)

    for k, userInfo in pairs(userList) do
        local userBaseInfo = chessuserinfodb.RUserBaseInfoGet(userInfo)	
        local isOnline = 0
        if go.roomusermgr.GetRoomUserById(userInfo.uid) ~= nil then
            isOnline = 1
        end
        local userInfo = {
            uid         = userBaseInfo.uid,
            headUrl     = userBaseInfo.headUrl,
            nickName    = userBaseInfo.nickName,
            gender      = userBaseInfo.gender,
            vipLevel    = userBaseInfo.vipLevel,
            level       = userBaseInfo.level,
            -- headFrame   = userBaseInfo.headFrame,
            lastOfflineTime = userBaseInfo.logoutTime,
            isOnline    = isOnline,
        }
        table.insert(userBaseInfoList, userInfo)
    end

    if table.len(userBaseInfoList) == 0 then
        res["data"] = {
            errno = 2,
            desc = "未查找到相关信息",
            userInfo = userBaseInfoList
        }
    end

    res["data"] = {
        errno = 0,
        desc = "查找成功",
        userInfo = userBaseInfoList
    }
    return res
end

--请求离线奖励列表
Net.CmdReqGetOfflineRewardListLobbyCmd_CS = function(cmd, laccount)
    UserInfo.CmdGetOfflineRewardList(laccount.Id, cmd.data.sourceType)
end


--领取离线奖励
Net.CmdReqGetOfflineRewardLobbyCmd_CS = function(cmd, laccount)
    local uid = laccount.Id
    local sourceType = cmd.data.sourceType
	cmd.data.errno = 0
	cmd.data.desc = ""
    cmd.data.errno, cmd.data.rewardList = UserInfo.GetOfflineReward(uid, sourceType)
	return cmd
end

--查询服务器时间
Net.CmdReqServerTimestampLobbyCmd_C = function(cmd, laccount)
    local uid = laccount.Id
	local res = {}
	res["do"] = "Cmd.ReqServerTimestampLobbyCmd_S"
    res["data"] = {
        timestamp = os.msectime()  / 1000
    }
	return res
end

--查询玩家分享上传标志
Net.CmdReqUserUploadInfoLobbyCmd_C = function(cmd, laccount)
    local uid = laccount.Id
	-- local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local info = unilight.getdata("user_image_upload", uid)
	local res = {}
	local uploadFlag = 0
	if info~=nil and info.uploadFlag~=nil then
		uploadFlag = info.uploadFlag
	end
	res["do"] = "Cmd.ReqUserUploadInfoLobbyCmd_S"
    res["data"] = {
        uploadFlag   = uploadFlag,         --上传标志(1已上传，0未上传)
    }
	return res
end
--查询玩家是否已经添加到桌面
Net.CmdReqUserAddDeskorInfoLobbyCmd_C = function (cmd,laccount)
	local uid = laccount.Id
	local info = unilight.getdata("user_image_addDesktop", uid)
	local res = {}
	local appUpLoadFlag = 0
	if info~=nil and info.uploadFlag~=nil then
		appUpLoadFlag = info.uploadFlag
	end
	res["do"] = "Cmd.ReqUserAddDeskorInfoLobbyCmd_S"
    res["data"] = {
        uploadFlag   = appUpLoadFlag,         --上传标志(1已上传，0未上传)
    }
	return res
end

-- 
Net.CmdRequestPointLotteryInfo_C = function(cmd, laccount)
	print("CmdRequestPointLotteryInfo_C")
	local uid = laccount.Id
		-- 往上提 不需要读两次mongo
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local property = userInfo.property
	--dump(property,"CmdRequestPointLotteryInfo_C",10)
	local data = Pointlottery.Getplinfo_Cmd_C()
	local res  = {}
	res["do"] = "Cmd.ReturnPointLotteryInfo_S"
	res["data"] = {
		errno = 0,
		desc = "ok",
		data = data,
	}
	dump(res,"CmdRequestPointLotteryInfo_Cres",10)
	return res 
end 

-- 
Net.CmdRequestPointLotteryBet_C = function(cmd, laccount)
	dump(cmd,"CmdRequestPointLotteryBet_C",10)
	local uid = laccount.Id
	local plid =  cmd.data and  cmd.data.id or 0 

	local resultCode = 0 
	local res = {}
	res["do"] = "Cmd.ReturnPointLotteryBet_S"
	res["data"] = {
		errno = 0,
		desc = "ok",
		
	}

	resultCode = Pointlottery.addbet(uid,plid)
	res["data"].errno = resultCode
	dump(res,"CmdRequestPointLotteryBet_C",10)
	return res

end 