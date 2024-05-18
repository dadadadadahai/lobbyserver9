module('backPackMgr', package.seeall)  

CONST_TASK_WIN20_ID = 1

function CmdBackPackWin20InfoGetByUid(uid)
	local backPack = CmdBackPackListGetByUid(uid)
	return backPack.task[CONST_TASK_WIN20_ID]
end

function CmdBackPackWinNbrSetByUid(uid, winNbr)

end
