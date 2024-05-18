-- 接收gm 命令相关相关

-- 执行脚本
GmSvr.PmdRequestExecScriptGmPmd_S = function(cmd, laccount)
    local scriptStr = cmd.data.script
    loadstring("return "..scriptStr)()
	local res = cmd
	res["do"] = "ReturnExecScriptGmPmd_C" 
    res.data.script = nil
    return res

end

