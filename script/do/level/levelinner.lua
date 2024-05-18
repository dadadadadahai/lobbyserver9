module("levelmgr", package.seeall)
--等级对外调用模块
--增加小游戏付费次数
function LevelShopCallBack(uid,shopId)
    if shopId==700 then
        local levelinfo = GetLevelInfo(uid)
        levelinfo.ispaynum = levelinfo.ispaynum+1
        unilight.update('userLevel',levelinfo._id,levelinfo)
    end
end