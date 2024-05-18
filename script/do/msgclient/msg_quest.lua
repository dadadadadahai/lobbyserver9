--探索
    --玩家游戏数据
    DB_USER_QUEST_DATA ="userQuestInfo"
--101 探索 请求新人数据
Net.CmdGetQuesetInfoCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
    local questInfo = {}
    local us ={}
    questInfo,us = questMgr.GetQuestInfo(uid)

    res["do"] = "Cmd.GetQuesetInfoCmd_S"
    local data = {
        --子游戏列表
        games = {},
        --子游戏任务列表
        tasks = {},
        --探索结束时间
        lastTime =0,
        --探索子游戏未完成数量
        finishNum =0,
        --探索期数
        round =0;
        --探索章数(每一期有四章)
        chapters=0;
        --章节难度
        phase = 0;
        --探索类型 0新手 1 老手
        type = 0;
        --探索开始时间
        starTime =0,
        --探索大奖 0未领取 1已领取
        bigReward={},
        --排行榜金币奖励数量
        superGold =0,
        --上一期数
        oldRound = 0,
        --购买buff数据
        useGem = {},
        --章节奖励列表
        reward ={},
        --
        isGeAward =0
    }
    data.games = questInfo.gameInfo
    data.tasks = questInfo.taskInfo
    data.lastTime = questInfo.lastTime
    data.finishNum = questInfo.finishNum
    data.bigReward = questInfo.bigReward
    data.round = questInfo.confRound
    data.chapters = questInfo.curChapters
    data.phase = questInfo.phase
    data.type = questInfo.type
    data.starTime = questInfo.starTime
    data.superGold = questInfo.superGoldz
    data.oldRound = questInfo.oldRound
    data.useGem = us
    if questInfo.type==1 then
        data.reward = questMgr.loadQuestReward(questInfo.phase,questInfo.curChapters,uid)
        data.chapReward = questMgr.GetPhaseReward(uid,questInfo.curChapters)
        data.rankAward  = questMgr.GetRank(uid)
    end
    data.isGeAward = questInfo.isGeAward
    res["data"]=data
	return res
end


--102 进行子游戏任务
Net.CmdplayQuestGameCmd_C = function (cmd,laccount)
    local res ={}
    local uid = laccount.Id

    local pos = cmd.data.pos
    local questInfo = {}
    local awardList=0
    questInfo,awardList = questMgr.playerQuestGame(uid,pos)

    res["do"] = "Cmd.resetQuesetInfoCmd_S"

    local data = {
        --子游戏列表
        games = {},
        --子游戏任务列表
        tasks = {},
        --探索结束时间
        lastTime =0,
        --探索子游戏未完成数量
        finishNum =0,
        --探索大奖 0未领取 1已领取
        bigReward={},
        --探索期数
        round =0;
        --探索章数(每一期有四章)
        chapters=0;
        --章节难度
        phase = 0;
        --探索类型 0新手 1 老手
        type = 0;
        --探索开始时间
        starTime =0,
        --排行榜金币奖励数量
        superGold =0,
        --上一期数
        oldRound = 0,
        --章节奖励列表
        reward ={},
        --
        isGeAward =0,
        awardList={},
    }
    data.games = questInfo.gameInfo
    data.tasks = questInfo.taskInfo
    data.lastTime = questInfo.lastTime
    data.finishNum = questInfo.finishNum
    data.bigReward = questInfo.bigReward
    data.round = questInfo.confRound
    data.chapters = questInfo.curChapters
    data.phase = questInfo.phase
    data.type = questInfo.type
    data.starTime = questInfo.starTime
    data.superGold = questInfo.superGold
    data.oldRound = questInfo.oldRound
    if questInfo.type==1 then
        data.reward = questMgr.loadQuestReward(questInfo.phase,questInfo.curChapters,uid)
        data.chapReward = questMgr.GetPhaseReward(uid,questInfo.curChapters)
        data.rankAward  = questMgr.GetRank(uid)
    end
    data.isGeAward = questInfo.isGeAward
    data.awardList = awardList
    res["data"]=data
	return res
end

-- --103领取奖励 并解锁下一关（与长期探索共用接口）
Net.CmdGetRewardNewCmd_C = function (cmd,laccount)

    local res ={}
    local uid = laccount.Id
    local pos = cmd.data.pos
    local userInfo = unilight.getdata(DB_USER_QUEST_DATA,uid)
    local questInfo = {}
    local rewardList ={}
    questInfo,rewardList= questMgr.getRewardAndNext(uid,pos,userInfo)

    print("rewardList  ... .",rewardList)
    res["do"] = "Cmd.resetQuesetInfoCmd_S"

        local data = {
            --子游戏列表
            games = {},
            --子游戏任务列表
            tasks = {},
            --探索结束时间
            lastTime =0,
            --探索子游戏未完成数量
            finishNum =0,
            --探索大奖 0未领取 1已领取
            bigReward={},
            --探索期数
            round =0;
            --探索章数(每一期有四章)
            chapters=0;
            --章节难度
            phase = 0;
            --探索类型 0新手 1 老手
            type = 0;
            --探索开始时间
            starTime =0,
            --排行榜金币奖励数量
            superGold =0,
            --上一期数
            oldRound = 0,
            --章节奖励列表
            reward ={},
            isGeAward=0,
            rewardList={}
        }
        data.games = questInfo.gameInfo
        data.tasks = questInfo.taskInfo
        data.lastTime = questInfo.lastTime
        data.finishNum = questInfo.finishNum
        data.bigReward = questInfo.bigReward
        data.round = questInfo.confRound
        data.chapters = questInfo.curChapters
        data.phase = questInfo.phase
        data.type = questInfo.type
        data.starTime = questInfo.starTime
        data.superGold = questInfo.superGold
        data.oldRound = questInfo.oldRound
        if questInfo.type==1 then
            data.reward = questMgr.loadQuestReward(questInfo.phase,questInfo.curChapters,uid)
            data.chapReward = questMgr.GetPhaseReward(uid,questInfo.curChapters)
            data.rankAward  = questMgr.GetRank(uid)
        end
        data.isGeAward = questInfo.isGeAward
        data.rewardList =rewardList
        res["data"]=data
        return res

end

--103领取通关大奖
Net.CmdGetRewardAndOpenNextCmd_C = function (cmd,laccount)
    local res ={}
    local uid = laccount.Id
    local questInfo = {}
    questInfo = questMgr.getBigReward(uid)

    res["do"] = "Cmd.openBigReward_S"
        
    local data ={
            --探索大奖 0未领取 1已领取
            bigReward={},
            --打开宝箱 后的物品 
            openBox={},   
            --期数
            round=0,
            --章节数
            chapters=0,
            --关卡难度
            phase=0,
            oldRound=0
    }

        data.bigReward = questInfo.bigReward
        data.openBox = questInfo.openBox
        data.round = questInfo.confRound
        data.chapters = questInfo.curChapters
        data.phase = questInfo.phase
        data.oldRound = questInfo.oldRound
        res["data"]=data
        return res


        -- local data = {
        --     --子游戏列表
        --     games = {},
        --     --子游戏任务列表
        --     tasks = {},
        --     --探索结束时间
        --     lastTime =0,
        --     --探索子游戏未完成数量
        --     finishNum =0,
        --     --探索大奖 0未领取 1已领取
        --     bigReward={},
        --     --探索期数
        --     round =0;
        --     --探索章数(每一期有四章)
        --     chapters=0;
        --     --章节难度
        --     phase = 0;
        --     --探索类型 0新手 1 老手
        --     type = 0;
        --     --探索开始时间
        --     starTime =0,
        --     --打开宝箱 后的物品 
        --     openBox={},           
        -- }
        -- data.games = questInfo.gameInfo
        -- data.tasks = questInfo.taskInfo
        -- data.lastTime = questInfo.lastTime
        -- data.finishNum = questInfo.finishNum
        -- data.bigReward = questInfo.bigReward
        -- data.round = questInfo.confRound
        -- data.chapters = questInfo.chapters
        -- data.phase = questInfo.phase
        -- data.type = questInfo.type
        -- data.starTime = questInfo.starTime
        -- data.openBox = questInfo.openBox
        -- res["data"]=data
        -- return res
end

--104 通过难度初始化玩家数据
Net.CmdUserChaptersGamesCmd_C = function (cmd,laccount)
    local res ={}
    local uid = laccount.Id
    local phase = cmd.data.phase
    local questInfo = questMgr.UserChaptersGames(uid,phase)
    res["do"] = "Cmd.resetQuesetInfoCmd_S"

        local data = {
            --子游戏列表
            games = {},
            --子游戏任务列表
            tasks = {},
            --探索结束时间
            lastTime =0,
            --探索子游戏未完成数量
            finishNum =0,
            --探索大奖 0未领取 1已领取
            bigReward={},
            --探索期数
            round =0;
            --探索章数(每一期有四章)
            chapters=0;
            --章节难度
            phase = 0;
            --探索类型 0新手 1 老手
            type = 0;
            --探索开始时间
            starTime =0,
            --排行榜金币奖励数量
            superGold =0,
            --上一期数
            oldRound=0,
            --章节奖励列表
            reward ={},
            isGeAward=0
        }
        data.games = questInfo.gameInfo
        data.tasks = questInfo.taskInfo
        data.lastTime = questInfo.lastTime
        data.finishNum = questInfo.finishNum
        data.bigReward = questInfo.bigReward
        data.round = questInfo.confRound
        data.chapters = questInfo.curChapters
        data.phase = questInfo.phase
        data.type = questInfo.type
        data.starTime = questInfo.starTime
        data.superGold = questInfo.superGold
        data.oldRound = questInfo.oldRound
        if questInfo.type==1 then
            data.reward = questMgr.loadQuestReward(questInfo.phase,questInfo.curChapters,uid)
            data.chapReward = questMgr.GetPhaseReward(uid,questInfo.curChapters)
            data.rankAward  = questMgr.GetRank(uid)
        end
        data.isGeAward = questInfo.isGeAward
        res["data"]=data
        return res
    
end

--105
Net.CmdPlayQuestDialCmd_C = function (cmd,laccount)
    local res ={}
    local uid = laccount.Id
    local item,po = questMgr.playDialGames(uid)

    res["do"] = "Cmd.PlayQuestDialCmd_S"
    local data ={
            items = item,
            pos = po

        }

    res["data"]=data
    return res
end

--购买BUFF
Net.CmdQuestBuyBuffCmd_C= function (cmd,laccount)

    local res ={}
    local uid = laccount.Id
    local info = questMgr.questBuyBuff(uid)

    res["do"] = "Cmd.QuestBuyBuffCmd_S"
    res["data"]=info

    return res
end

