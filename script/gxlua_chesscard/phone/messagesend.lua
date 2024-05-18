module('chessmessagesend', package.seeall)
mapNotice = {}

function SendPhoneErrorNotice(phone, s, gamename)
    local key = phone..s
    if mapNotice[key] == nil or os.time()-mapNotice[key].sendtime>24*60*60 then
        uniplatform.requestsenderrornotice(phone, gamename .. s)
        mapNotice[key] = {}
        mapNotice[key].sendtime = os.time()
        unilight.info("发送短信提示" .. phone)
    end
end
