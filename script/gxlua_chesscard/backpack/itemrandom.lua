--随机道具
module("ItemRandomMgr", package.seeall)

tableItemRandomConfig = import "table/table_item_random_config"
tableItemGroupConfig  = import "table/table_item_random_group"

randPackageConfigs = {}
bInit = false

--加载数据礼包数据
function Reload()
    randPackageConfigs = {}
    for _,v in pairs(tableItemRandomConfig) do
        if randPackageConfigs[v.randID] == nil then
            randPackageConfigs[v.randID] = {}
        end
        table.insert(randPackageConfigs[v.randID],v)
    end
end

--获得随机id,的礼包
function GetRandomItemByRandId(uid, randomId, sourceType, summary)
    if not bInit then
        bInit = true
        Reload()
    end

    local probability = {}
	local allResult = {}
    local randomConfig = randPackageConfigs[randomId]
    if randomConfig == nil then
        unilight.error("GetRandomItemByRandId 找不到礼包ID:"..randomId)
        return 1
    end
	for k, v in pairs(randomConfig) do
        table.insert(probability, v.weight)
        table.insert(allResult, v.item)
	end

	local randomGoods = math.random(probability, allResult)
    local googId = randomGoods[1]
    local goodNum = randomGoods[2]
    BackpackMgr.GetRewardGood(uid, googId, goodNum, sourceType, summary)
    return 0, googId, goodNum

end

--随机礼包组
function GetRandomGroupByRandId(uid, randomId, sourceType, summary)
    local groupConfig = tableItemGroupConfig[randomId]
    if groupConfig == nil then
        unilight.error("GetRandomGroupByRandId 找不到礼包组ID:"..randomId)
        return
    end
    local goodList = {}  --返回已获得的道具列表
    for _, v in pairs(groupConfig.randGroup) do
        if random.selectByTenTh(v.weight) then
            local ret, googId, goodsNbr = GetRandomItemByRandId(uid, v.randId, sourceType, summary)
            if ret == 0 then
                table.insert(goodList,{googId=googId, goodsNbr=goodsNbr})
            end
        end
    end
    return goodList --{{goodId=1001, goodNum=2},{goodId=1002, goodNum=1}}
end
