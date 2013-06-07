dofile("common/common.lua")

--处理所有从队列->逻辑处理， 以及 逻辑处理->队列 间的程序

--zysz.pokechar 应该在 preinit 中

zysz.name = "zysz"
zysz.table = "user_zysz_info"
gamepkg = zysz

trace("执行随机种子")
math.randomseed(os.time())

gamecfg = {
    maxbeishu = 19,    -- 加注最大倍数
    dizhuxishu = 0.01, -- 最小携带的1%
    myselfbili = 0.5,  -- 个人下注封顶比例
    addzhutype = {1,2,3}, --玩家加注类型
    jiangchichoushui = 0.2,--彩池奖金抽水
}
deskmgr = {
    --获取玩家数据
    getuserdata = function(userinfo)
	    return userinfo.gameInfo
    end,
    --获取座位userinfo
    getsiteuser = function(deskno, siteno)
	    return userlist[hall.desk.get_user(deskno,siteno) or ""]
    end,

	--获取座位数据
	getsitedata = function(deskno, siteno)
		return desklist[deskno].site[siteno]
	end,

    get_game_state = function(adeskno)
        if adeskno <= 0 then
                return gameflag.notstart
        end
        return desklist[adeskno].gamestate
    end,

    set_game_state = function(adeskno, gamestate)
		if adeskno <= 0 then
			return
		end
        desklist[adeskno].gamestate = gamestate
    end,

    --获取在玩座位号列表, 返回value为{siteno, userinfo}的table, 顺序按座位号, [*包括*]放弃的用户
	getplayers = function(deskno)
		local ret = {}
		for i = 1, room.cfg.DeskSiteCount do
			local userinfo = userlist[hall.desk.get_user(deskno, i)]
			if userinfo then
				table.insert(ret, newStrongTable({ siteno=i, userinfo=userinfo }))
			end
		end
		return ret
	end,

	--获取在玩座位号列表, 返回value为{siteno, userinfo}的table, 顺序按座位号, [*不包括*]放弃的用户
	getplayingplayers = function(deskno)
		local ret = {}
		local players = deskmgr.getplayers(deskno)
		for i = 1, #players do
			if deskmgr.getsitedata(deskno, players[i].siteno).islose == 0 then
				table.insert(ret, players[i])
			end
		end
		return ret
	end,

    --获取下一个在玩的座位号(都不在玩则返回空), 不包括放弃的用户
	getnextsite = function(deskno, siteno)
		local currsite = siteno
		local userinfo
		repeat
			if currsite == 1 then 
				currsite = room.cfg.DeskSiteCount 
			else
				currsite = currsite - 1
			end
			if currsite == siteno then
				return nil
			end
			userinfo = userlist[hall.desk.get_user(deskno, currsite)]
		until userinfo and deskmgr.getsitedata(deskno, currsite).islose == 0 and
            hall.desk.get_site_state(deskno, currsite) ~= SITE_STATE.WATCH

		return currsite
	end,
}

zysz.TransSiteStateValue = function(state)
    local state_value
    if state == NULL_STATE then
		state_value = SITE_UI_VALUE.NULL
    elseif state == SITE_STATE.NOTREADY then
		state_value = SITE_UI_VALUE.NOTREADY
    elseif state == SITE_STATE.READYWAIT or state == SITE_STATE.WATCH then
		state_value = SITE_UI_VALUE.READY
    elseif state == SITE_STATE.KANPAI or state == SITE_STATE.PANEL then
		state_value = SITE_UI_VALUE.PLAYING
    else
		state_value = SITE_UI_VALUE.NULL
    end

    return state_value
end

tZyszSqlTemplete =
{
    --更新结算信息
    updateJiesuan = "call sp_zysz_jiesuan(%s)",
    --插入结算日志
    insertLogRound = "call sp_zysz_insert_log_round(%s)",
    --修改用户金币
    updateUserGold = "call sp_update_user_gold(%s)",
    --得到彩池信息
    getZyszCaichiInfo = "select sumgold,last_win_user,last_win_time,last_win_gold from zysz_caichi_info where room_id = %d",
    --插入彩池信息
    insertZyszCaichiInfo = "insert into zysz_caichi_info (room_id,sumgold,last_win_user,last_win_time,last_win_gold) values (%d, 0, '', %d, 0)",
    --更新彩池获奖信息[更新获奖人]
    updateCaichiInfo = "update zysz_caichi_info set sumgold = %d,last_win_user = %s, last_win_time = %d, last_win_gold = %d where room_id = %d",
    --更新彩池获奖信息[不更新获奖人]
    updateCaichiInfo_goldonly = "update zysz_caichi_info set sumgold = %d where room_id = %d",
    --更新彩池金币数
    updateCaichiGold = "update zysz_caichi_info set sumgold = %d where room_id = %d",
}

---------------------------------------------------------------------------
--未准备-超时
function ss_notready_timeout(userinfo)
    hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
	--踢人
	doUserStandup(userinfo.key, false)
	net_Send_KickUser(userinfo)
end

--未准备-离线
function ss_notready_offline(userinfo)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
end

--准备后开始前-离线
function ss_readywait_offline(userinfo)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
end

--发牌离线
function ss_fapai_offline(userinfo)
	desklist[userinfo.desk].site[userinfo.site].isfapaiover = 1
	do_fapai_over_check(userinfo.desk)
	do_user_state_change(userinfo,1)
end

--发牌超时
function ss_fapai_timeout(userinfo)
	desklist[userinfo.desk].site[userinfo.site].isfapaiover = 1
	do_fapai_over_check(userinfo.desk)
	do_user_state_change(userinfo,0)
end

--面板状态离线
function ss_panel_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--面板状态超时
function ss_panel_timeout(userinfo)
	do_user_state_change(userinfo,0)
end

--看牌状态离线
function ss_kanpai_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--看牌状态超时
function ss_kanpai_timeout(userinfo)
	do_user_state_change(userinfo,0)
end

--等待状态离线
function ss_wait_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--观战离线状态
function ss_watch_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--当用户超时或离线时处理函数
function do_user_state_change(userinfo,isleave)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
    doUserGiveUp(userinfo)
	if isleave == 1 then
		if (userinfo.desk ~= nil) then
			doUserStandup(userinfo.key, false)
			doDelUser(userinfo.key)
		end
	end
end

--座位状态改变
function ss_onstatechange(deskno, siteno, oldstate, newstate)
    trace("ss_statechanged()")
	local userinfo = deskmgr.getsiteuser(deskno, siteno)
	if userinfo ~= nil then
		if userinfo.desk and newstate ~= SITE_STATE.NOTREADY then
			net_broadcastdesk_playerinfo(userinfo.desk)
		end
	end
end

--强制结束游戏
function forceGameOver(deskno)
	deskmgr.set_game_state(deskno, gameflag.notstart)  --直接转为未开始状态
	for i = 1, room.cfg.DeskSiteCount do
		hall.desk.set_site_state(deskno, i, NULL_STATE)
        local userinfo = deskmgr.getsiteuser(deskno,i)
		if userinfo then
			net_Send_KickUser(userinfo)
		end
    end

	initGameData(deskno);
	
	OnGameOver(deskno,true)
end

--设置下一步的动作人和相关动作
function setNextAction(deskno)
    local nextpeople = desklist[deskno].nextpeople        

    --能否看牌（看是否已经看过牌）
    if desklist[deskno].site[nextpeople].islook ==  0 then
        desklist[deskno].site[nextpeople].action_look = 1
    else
        desklist[deskno].site[nextpeople].action_look = 0
    end
    
    --能否开牌
    --剩下两个人的时候才能开牌并且不是第一轮                                              
    if desklist[deskno].peopleplaygame <= 2 and desklist[deskno].site[nextpeople].betmoney ~= desklist[deskno].dizhu 
        and desklist[deskno].isfengding == 0 then
        desklist[deskno].site[nextpeople].action_vs = 1
    else
        desklist[deskno].site[nextpeople].action_vs = 0
    end
    
    --当前桌上已经加了多少注
    local curjiazhunum = math.floor(desklist[deskno].curdeskzhu / desklist[deskno].dizhu)
    --能否加注
    if curjiazhunum < gamecfg.maxbeishu and desklist[deskno].isfengding == 0 then
        local leftzhu = gamecfg.maxbeishu - curjiazhunum
        desklist[deskno].site[nextpeople].action_add =  leftzhu >= 3 and 3 or leftzhu
    else
        desklist[deskno].site[nextpeople].action_add = 0
    end
    
    --能否跟注
    if desklist[deskno].isfengding == 0 then--封顶没有开启
        desklist[deskno].site[nextpeople].action_follow = 1--随便跟
        desklist[deskno].site[nextpeople].followgold = setbetmoney(deskno,nextpeople,desklist[deskno].curdeskzhu)
    else--封顶开启
        if nextpeople ~= desklist[deskno].kaifengsiteno then
            desklist[deskno].site[nextpeople].action_follow = 1
            desklist[deskno].site[nextpeople].followgold = setbetmoney(deskno,nextpeople,desklist[deskno].curdeskzhu)
        else
            desklist[deskno].site[nextpeople].action_follow = 0
            desklist[deskno].site[nextpeople].followgold = 0
        end
    end

    --放弃
    desklist[deskno].site[nextpeople].action_giveup = 1
    
	--设置成为面板状态
	hall.desk.set_site_state(deskno,nextpeople,SITE_STATE.PANEL)
    --发送面板信息
    net_send_show_action_list(deskmgr.getsiteuser(deskno,nextpeople))
end

----------------------------------------------------------------------
--处理输入队列，将队列中内容提取出来进行协议分析及处理
function gameonrecv(cmd, recvbuf)
	--cmd = netbuf.readString(inbuf)
	trace("game onrecv "..cmd)
	gamedispatch(cmd, recvbuf)
end

--将命令相关内容，打包加入到输出队列
function gameonsend(sCommand, sendbuf)
	trace("game onsend ".. sCommand)
	gamedispatch(sCommand, sendbuf)
end

g_errmsgprefix = ""
function throw(msg)
    TraceError('--------------------------')
    TraceError("#### call command faild ".. g_errmsgprefix.." with err: "..msg) --error(msg)
    local serr = debugpkg.traceback()
    TraceError(serr)
    TraceError('--------------------------')
end

function gamedispatch(sCommand, buf)
	local f = cmdGameHandler[sCommand]
	if f ~= nil then        
        local ret, errmsg = xpcall(function() return f(buf) end, throw)
		if (ret) then
			trace("**"..sCommand.. " call command ok ")
		else
			trace("** call 游戏 command faild ".. sCommand)
		end
	else
		trace("** not found 游戏 command ->".. sCommand)
	end
end
--------------------------------------------------------------------------------
--一局结束，重新开始一局
function restartthegame(deskno)
    --计算彩池的金额
    calCaichiMoney(deskno)

    deskmgr.set_game_state(deskno, gameflag.notstart)  --直接转为未开始状态

    initGameData(deskno)

    OnGameOver(deskno,true)
end

function sortpokerlist(pokes)
	table.sort(pokes, function (a,b)
	    return (zysz.pokenum[a] < zysz.pokenum[b])
	end)

	return pokes	
end

--继续游戏
function continuegame(deskno,doType)--doType--1为下注触发自动开牌，2为放弃触发自动开牌
	if desklist[deskno].peopleplaygame <= 1 then
        if desklist[deskno].winner == 0 then
            desklist[deskno].winner = deskmgr.getnextsite(deskno,desklist[deskno].nextpeople)
		end

		desklist[deskno].winpeoplenum = 1 --1个人赢了
		--结算金额，保存到数据库
		calMoney(deskno,desklist[deskno].winner,1)
		restartthegame(deskno)
		--春节活动盘数统计
		--if springboxlib then
		--	xpcall(function() springboxlib.count_huodong_panshu() end,throw)
		--end
    else--检查是否要自动开牌--下个人轮到开封的人了
        --找到下个人
        desklist[deskno].nextpeople = deskmgr.getnextsite(deskno,desklist[deskno].nextpeople)   
        
        --封顶开关开启
        if doType and desklist[deskno].isfengding == 1 then
            if setbetmoney(deskno,desklist[deskno].nextpeople,0) == 0 or desklist[deskno].nextpeople == desklist[deskno].kaifengsiteno then
                doAutoKaiPai(deskno,doType)
				--if springboxlib then
				--	xpcall(function() springboxlib.count_huodong_panshu() end,throw)
				--end
                return
            end
        end

        --设置下个的动作
        setNextAction(deskno)
	end
end

--自动开牌
function doAutoKaiPai(deskno,doType)
	local deskdata = desklist[deskno]

    --先找豹子
	local hasbaozi = false
    --设置自动比牌标识
    for _,player in pairs(deskmgr.getplayingplayers(deskno)) do
        desklist[deskno].site[player.siteno].isautokaipai = 1
        if desklist[deskno].site[player.siteno].paixing == 5 then
			hasbaozi = true			
		end
    end

	--设置特殊牌型等级
	for _,player in pairs(deskmgr.getplayingplayers(deskno)) do
		if desklist[deskno].site[player.siteno].paixing == 6 then--存在偷鸡
			if hasbaozi == false then--没有豹子
				desklist[deskno].site[player.siteno].paixing = 0--设置成散牌
			end
		end		 
	end

    --找出输赢家
	local winsitelist = {}
	local lostsitelist = {}
	for _,player in pairs(deskmgr.getplayingplayers(deskno)) do	
        if (hall.desk.get_site_state(deskno, player.siteno) ~= SITE_STATE.WATCH) then
    		if #winsitelist == 0 then
    			table.insert(winsitelist,player.siteno)
    		else
    			local result = validPoker(deskno,winsitelist[1],player.siteno)
    			if result == 1 then
    				table.insert(lostsitelist,player.siteno)
    			elseif result == 2 then
    				for k,v in pairs(winsitelist) do
    					table.insert(lostsitelist,v)
    				end
    				winsitelist = {}
    				table.insert(winsitelist,player.siteno)
    			else
    				table.insert(winsitelist,player.siteno)
    			end
            end
        end
    end

    --记录采集任务信息
    if #lostsitelist > 0 then
        local loseminsite = lostsitelist[1]
        for k,v in pairs(lostsitelist) do
            if desklist[deskno].site[loseminsite].paixing > desklist[deskno].site[v].paixing then
                loseminsite = v
            end
        end
        
        record_paixin_msg(deskno, winsitelist[1], loseminsite)
		clone_winlist_data(deskno,winsitelist)--拷贝
    end

	local winnum = #winsitelist
	if winnum == 0 then
		TraceError("没有人最大????BUG了 " .. deskno)
		forceGameOver(deskno)
		return
    end

    --通知自动比牌游戏结束了
	net_broadcast_game_over(deskno,doType,winsitelist,lostsitelist)

	--输的人先扣钱
	for k,v in pairs(lostsitelist) do
		--投降者状态改为出局
		desklist[deskno].site[v].islose = 1
		--用户金币修改写入数据库
		writelosergoldtodb(deskno,v)
	end

	--记录系统自动开牌时有多少人输了
	deskdata.lostpeoplenum = #lostsitelist
	
	if winnum > 0 then
		deskdata.winpeoplenum = winnum 

		for k,v in pairs(winsitelist) do
			calMoney(deskno,v,winnum)
		end		
	end

	restartthegame(deskno)
end

--复制玩家信息
function clone_winlist_data(deskno,sitelist)
	local clonesite = sitelist[1]
	local clonesitedata = desklist[deskno].site[clonesite]
	for k,v in pairs(sitelist) do
		if v ~= clonesite then
			local sitedata = desklist[deskno].site[v]
			sitedata.spike = clonesitedata.spike
			sitedata.xiansheng = clonesitedata.xiansheng
			sitedata.win_jinhua = clonesitedata.win_jinhua
		end
	end
end

--收到玩家放弃
function onZYSZRecvLose(buf)
    local curUser = getuserid(buf)
    --安全验证
    local userinfo = userlist[curUser];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site	
	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
	    return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end

	--自己的面板上不能放弃,也发来???
	if desklist[deskno].site[siteno].action_giveup == 0 then
		return
	end

	hall.desk.set_site_state(deskno,siteno, SITE_STATE.WAIT)    

    doUserGiveUp(userinfo)
end

--执行玩家放弃操作
function doUserGiveUp(userinfo)
    local deskno,siteno = userinfo.desk,userinfo.site
	--已经放弃过了还放弃??
	if desklist[deskno].site[siteno].islose == 1 then
		return
	end

     --记录放弃人数+1
    desklist[deskno].giveup_people_num = desklist[deskno].giveup_people_num + 1
    --游戏人数减一
    desklist[deskno].peopleplaygame = desklist[deskno].peopleplaygame - 1

    --投降者状态改为出局
    desklist[deskno].site[siteno].islose = 1--放弃了

    --用户金币修改写入数据库
    writelosergoldtodb(deskno,siteno)
	
	if desklist[deskno].peopleplaygame <= 1 then
		desklist[deskno].isgiveupover = 1
		desklist[deskno].winner = deskmgr.getnextsite(deskno,siteno)
	end

    --广播放弃
    net_broadcastdesk_user_lose(deskno,siteno)

    --点击放弃按钮的继续找下一位。如是强退，则绕过不做这个
    if desklist[deskno].nextpeople == siteno or desklist[deskno].isgiveupover == 1 then
        continuegame(deskno,2)
    end
end

--收到玩家开牌
function onZYSZRecvKaiPai(buf)
	local curUser = getuserid(buf)
	--安全验证
	local userinfo = userlist[curUser];
	if not userinfo then return end

	local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return
	end

	if (siteno ~= desklist[deskno].nextpeople) then
		return
	end
	
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end

	--自己的面板上不能开牌,也发来???
	if desklist[deskno].site[siteno].action_vs == 0 then
		return
	end

    if desklist[deskno].firstkaipai == 0 then
        desklist[deskno].firstkaipai = siteno--记录第一个开牌的座位号
    else
        TraceError("开了两次牌???")
        return
    end
	
    local othersiteno = deskmgr.getnextsite(deskno,siteno)--剩下另外一个人的座位号

    if othersiteno == siteno then
        TraceError("出现异常，开牌时没有找到另一家")
        return
    end

	hall.desk.set_site_state(deskno,siteno,SITE_STATE.WAIT)

    --开牌人应该下注2倍底注
	local money =  desklist[deskno].curdeskzhu * 2

    money = setbetmoney(deskno,siteno,money)

    desklist[deskno].site[siteno].betmoney = desklist[deskno].site[siteno].betmoney + money

    if desklist[deskno].site[siteno].islook == 1 then
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + (money * 0.5)
    else
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + money
    end

    --台面总金额
    desklist[deskno].betmoney =  desklist[deskno].betmoney + money
    --显示的下注金额
    desklist[deskno].site[siteno].curbet = money
    
    local losesite = 0
	local result = validPoker(deskno,siteno,othersiteno)
    if result == 1 then--开牌的人大
        losesite = othersiteno
        desklist[deskno].winner = siteno
        record_paixin_msg(deskno, siteno, othersiteno)
    else
        losesite = siteno
        desklist[deskno].winner = othersiteno
        record_paixin_msg(deskno, othersiteno, siteno)
		if desklist[deskno].site[siteno].paixing == desklist[deskno].site[othersiteno].paixing then
			desklist[deskno].site[othersiteno].isnarrow = 1--记录被人比牌自己相同牌型下获胜
		end
    end

    desklist[deskno].site[losesite].islose = 1

    --游戏人数减一
    desklist[deskno].peopleplaygame = desklist[deskno].peopleplaygame - 1

	--广播开牌信息
	net_broadcast_userkaipai_info(deskno,siteno,losesite)

    --用户金币修改写入数据库
    writelosergoldtodb(deskno,losesite)

    --看牌了继续找下一位
    continuegame(deskno)
end

--收到玩家看牌
function onZYSZRecvKanpai(buf)
	trace(string.format("用户(%s)请求看牌", buf:ip()..":"..buf:port()))
	local curUser = getuserid(buf) --string.format("%s:%s", buf:ip(), buf:port())

	--安全验证
	local userinfo = userlist[curUser];
    local deskno,siteno = userinfo.desk,userinfo.site

	if deskno == nil or siteno == nil then
		return
	end

	if(siteno ~= desklist[deskno].nextpeople) then
		return
	end
    
    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL then
        return
	end

	--自己的面板上不能看牌,也发来???
	if desklist[deskno].site[siteno].action_look == 0 then
		return
	end		 

	--已经看过牌了，直接return
	if desklist[deskno].site[siteno].islook == 1 then
		return
    end

    --先设置成等待
    hall.desk.set_site_state(deskno,siteno, SITE_STATE.WAIT)--座位设置为等待状态
    --座位设置为看牌状态
    desklist[deskno].site[siteno].islook = 1

	--看牌后不能投注彩池了
    if desklist[deskno].site[siteno].iscaichi == 0 then
	    desklist[deskno].site[siteno].iscaichi = 2
    end

    hall.desk.set_site_state(deskno,siteno, SITE_STATE.KANPAI)--座位为看牌状态

    net_send_kanpai(deskno,siteno)--广播看牌状态
end

--将输家的钱写入数据库并记录日志
function writelosergoldtodb(deskno,siteno)
	local tempscore = - desklist[deskno].site[siteno].betmoney

	local userid = hall.desk.get_user(deskno, siteno)
	local userinfo = userlist[userid]

	------统计所有用户10分钟内金币总和--------------
	local all_info = {
		gold = tempscore,
		userid = userinfo.userId,
	}
	eventmgr:dispatchEvent(Event("golderror_checkpoint", all_info))
	------------------------------------------------

    --结算减钱
	usermgr.addgold(userinfo.userId, tempscore, 0, tSqlTemplete.goldType.ZYSZ_JIESUAN, -1,1)

	local sbgold = userinfo.safebox.safegold ~= nil and userinfo.safebox.safegold or 0

    --记录日志
	if(desklist[deskno].logsql == "") then
		desklist[deskno].logsql = userinfo.userId.. ",".. tempscore .. "," ..
			"0," .. userinfo.nSid..","..userinfo.gamescore..","..sbgold
	else
		desklist[deskno].logsql = desklist[deskno].logsql .. "," ..userinfo.userId.. ",".. tempscore .. "," ..
			"0," .. userinfo.nSid..","..userinfo.gamescore..","..sbgold
	end

	desklist[deskno].logpeople = desklist[deskno].logpeople + 1;

    --输家任务相关
    local gameeventdata = {}
    xpcall(function()
        local refdata = {
            userid 	= userinfo.userId,
            iswin 	= 0,
            single_event = 0,
            wingold = tempscore,
            data	=
            {
                [zysz.gameref.REF_GOLD]	= tempscore,
                [zysz.gameref.REF_EXP]  	= 0,
                [zysz.gameref.REF_WIN]  	= 0,
                [zysz.gameref.REF_BIGWIN] = 0,				
            }
        }
        update_game_ref_data(userinfo.desk,userinfo.site, refdata)
        table.insert(gameeventdata, refdata)
    end, throw)
    --派发参考数据
    eventmgr:dispatchEvent(Event("game_event", gameeventdata));

	--算积分
	local integraldata = {
		is_win = 0,                                 --放弃肯定没获胜
		extra_integral = 0,			                --额外加成
		player_count = 1,                           --如果放弃,输的人数肯定是1
		userid = userinfo.userId,                   --用户id
	}

	--发送积分更新消息,更新积分数据
	eventmgr:dispatchEvent(Event("integral_change_event", integraldata));
end

--同步gamecenter用户金币
function SendGoldToGameCenter(userinfo)
    --同步用户金币
    local szSendBuf = userinfo.userId..","..userinfo.gamescore --发送给gc服务中心消息
    tools.SendBufToUserSvr(gamepkg.name, "STGB", "", "", szSendBuf) --发送数据到服务端，通知他更新有人送钱了
end

--强化game_ref_data
function update_game_ref_data(deskno, siteno, refdata)
    local userinfo = userlist[hall.desk.get_user(deskno, siteno)]
    local sitedata = desklist[deskno].site[siteno]
    local refgold = refdata.data[zysz.gameref.REF_GOLD]  --输赢金币

    local userhandpokes = sitedata.handpokes
    local siteChar = sitedata.handchar
    local sitepaixing = sitedata.paixing

    local userdata = deskmgr.getuserdata(userinfo)
	--[[
        单牌：0
        对子：1
        顺子：2
        金花: 3
        顺金：4
        豹子：5
		偷鸡: 6
    -]]
    --REF_BAOZI 豹子
    if sitepaixing == 5 then
        refdata.data[zysz.gameref.REF_BAOZI] = 1
    --REF_SHUNJIN 顺金
    elseif sitepaixing == 4 then 
        refdata.data[zysz.gameref.REF_SHUNJIN] = 1
    --REF_JINHUA 金花
    elseif sitepaixing == 3 then
        refdata.data[zysz.gameref.REF_JINHUA] = 1    
    --REF_DUIZI 对子
    elseif sitepaixing == 1 then
        refdata.data[zysz.gameref.REF_DUIZI] = 1    
    --REF_DANPAI 单牌
    elseif sitepaixing == 0 then
        refdata.data[zysz.gameref.REF_DANPAI] = 1   
		if refgold < 0 and validTouji(siteChar) then
			refdata.data[zysz.gameref.REF_235LOST] = 1
		end			 
    --REF_235 不同花色235
    elseif sitepaixing == 6 then
        refdata.data[zysz.gameref.REF_235] = 1
	end

	--是否是金花以上牌型
	if sitepaixing > 3 then
		refdata.data[zysz.gameref.REF_BIGPAIXING] = 1
	end

    --REF_MENKAI 闷开
    if sitedata.islook == 0 then
        refdata.data[zysz.gameref.REF_MENKAI] = 1
    --REF_KANPAI 看牌
    else
        refdata.data[zysz.gameref.REF_KANPAI] = 1
    end

    if sitedata.isautokaipai == 1 then
        refdata.data[zysz.gameref.REF_AUTOBIPAI] = 1
    end

	--REF_FIRSTKILL第一个开牌
	if desklist[deskno].firstkaipai == siteno then
		refdata.data[zysz.gameref.REF_FIRSTKILL] = 1
	end
	
	--REF_NOADD玩家有没有加过注
	if sitedata.isadd == 0 then
		refdata.data[zysz.gameref.REF_NOADD] = 1
    end

    --REF_WIN假如是放弃结束游戏的，就不算胜利
    if desklist[deskno].isgiveupover == 1 then
        refdata.data[zysz.gameref.REF_WIN] = 0
    end

    --REF_PLAY 玩一盘
    refdata.data[zysz.gameref.REF_PLAY] = 1

    --REF_WINPOINT 连胜点的处理
    if refgold > 0 and desklist[deskno].isgiveupover == 0 then
        if userdata.zysz_winpoint == nil then
            userdata.zysz_winpoint = 0
        end
        userdata.zysz_winpoint = userdata.zysz_winpoint + 1
    else
        userdata.zysz_winpoint = nil
	end

    refdata.data[zysz.gameref.REF_WINPOINT] = userdata.zysz_winpoint

    if(desklist[deskno].isgiveupover == 0) then
        --REF_WINGOLD1W 一盘赢1W金币以上
        if(refgold >= 10000) then
            refdata.data[zysz.gameref.REF_WINGOLD1W] = 1
            --REF_WINGOLD10W 一盘赢10W金币以上
            if(refgold >= 100000) then
                refdata.data[zysz.gameref.REF_WINGOLD10W] = 1
            end
        end
    end

    --REF_GIVEUP3  --桌内其他3人放弃
    if(desklist[deskno].giveup_people_num >= 3) then
        refdata.data[zysz.gameref.REF_GIVEUP3] = 1 
    end

    --REF_SPIKE      --秒杀，跨牌型赢
    if(sitedata.spike == 1) then
        refdata.data[zysz.gameref.REF_SPIKE] = 1 
    end

    --REF_XIANSHENG  --险胜
    if(sitedata.xiansheng == 1) then
        refdata.data[zysz.gameref.REF_XIANSHENG] = 1     
    end

    --REF_WINJINHUA  --赢了别人的金花
    if(sitedata.win_jinhua == 1) then
        refdata.data[zysz.gameref.REF_WINJINHUA] = 1
	end

	--REF_NARROW --被别人开牌而且是相同牌型
	if sitedata.isnarrow == 1 then
		refdata.data[zysz.gameref.REF_NARROW] = 1
	end

	--REF_TRIPLEKILL--系统自动开牌有三个人输
	if desklist[deskno].lostpeoplenum >= 3 then
		refdata.data[zysz.gameref.REF_TRIPLEKILL] = 1
	end

	--REF_KAIPAIWINPOINT--主动开牌累计赢
	if(refdata.data[zysz.gameref.REF_FIRSTKILL] and refdata.data[zysz.gameref.REF_FIRSTKILL] == 1 and refgold > 0) then
        --赢一次+1点
        if(userdata.zysz_kaipai_winpoint == nil) then
            userdata.zysz_kaipai_winpoint = 0
		end

        userdata.zysz_kaipai_winpoint = userdata.zysz_kaipai_winpoint + 1
    else
        userdata.zysz_kaipai_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_KAIPAIWINPOINT] = userdata.zysz_kaipai_winpoint 

    --REF_JINHUAWINPOINT     --金花以上牌型累计赢
    if(refgold > 0 and desklist[deskno].isgiveupover == 0 and ((refdata.data[zysz.gameref.REF_JINHUA] and refdata.data[zysz.gameref.REF_JINHUA] == 1) or
           (refdata.data[zysz.gameref.REF_SHUNJIN] and refdata.data[zysz.gameref.REF_SHUNJIN] == 1) or
           (refdata.data[zysz.gameref.REF_BAOZI] and refdata.data[zysz.gameref.REF_BAOZI] == 1))) then
        --赢一次+1点
        if(userdata.zysz_jinhua_winpoint == nil) then
            userdata.zysz_jinhua_winpoint = 0
        end
        userdata.zysz_jinhua_winpoint = userdata.zysz_jinhua_winpoint + 1   
    else
        userdata.zysz_jinhua_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_JINHUAWINPOINT] = userdata.zysz_jinhua_winpoint

    --REF_DANPAIWINPOINT    --单牌累计赢  
    if(refgold > 0 and desklist[deskno].isgiveupover == 0 and refdata.data[zysz.gameref.REF_DANPAI] and refdata.data[zysz.gameref.REF_DANPAI] == 1) then
        --赢一次+1点
        if(userdata.zysz_danpai_winpoint == nil) then
            userdata.zysz_danpai_winpoint = 0
		end

        userdata.zysz_danpai_winpoint = userdata.zysz_danpai_winpoint + 1
    else
        userdata.zysz_danpai_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_DANPAIWINPOINT] = userdata.zysz_danpai_winpoint 
end

--收到玩家跟注信息
function OnZYSZRecvGenZhu(buf)
	local curUser = getuserid(buf)
	--安全验证
	local userinfo = userlist[curUser];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
		return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end
	
	--自己的面板上不能跟在,也发来???
	if desklist[deskno].site[siteno].action_follow == 0 then
		return
	end

	--执行跟，加注等操作
    doxiazhuabout(userinfo,1)
end

--收到玩家下注
function OnZYSZRecvJiaZhu(buf)
	local curUser = getuserid(buf)
	--安全验证
	local userinfo = userlist[curUser];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site

	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
		return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
    end

	--自己的面板上不能加注,也发来???
	if desklist[deskno].site[siteno].action_add == 0 then
		return
	end

	--加注类型
    local addzhutype = buf:readByte()

    local findtype = 0
    for k,v in pairs(gamecfg.addzhutype) do
        if tonumber(v) == addzhutype then
            findtype = 1
            break
        end
    end

    if findtype == 0 then
        TraceError("发来的类型不合法 " .. addzhutype)
        addzhutype = gamecfg.addzhutype[1]--默认下最小注
    end

    desklist[deskno].curdeskzhu = desklist[deskno].curdeskzhu + desklist[deskno].dizhu * addzhutype
	
	--记录玩家加注了
	desklist[deskno].site[siteno].isadd = 1

    --执行跟，加注等操作
    doxiazhuabout(userinfo,2)
end

function doxiazhuabout(userinfo,xztype)
    local deskno,siteno = userinfo.desk,userinfo.site
    local money = desklist[deskno].curdeskzhu

    --设置下注拆分实际金额并检查下注额是否正确
	money = setbetmoney(deskno,siteno,money)

    --修改闷牌情况下的下注
    if desklist[deskno].site[siteno].islook == 1 then
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + math.floor((money * 0.5) + 0.5)
    else
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + money
    end

	--TraceError("收到"..deskno.." 桌"..siteno.." 座".." 加注 "..money)
    --设置为等待状态
	hall.desk.set_site_state(deskno, siteno, SITE_STATE.WAIT)

    desklist[deskno].site[siteno].betmoney = desklist[deskno].site[siteno].betmoney + money
    --台面总金额
    desklist[deskno].betmoney = desklist[deskno].betmoney + money
    --显示的下注金额
    desklist[deskno].site[siteno].curbet = money

    if desklist[deskno].isfengding == 0 and desklist[deskno].site[siteno].betpercent >= desklist[deskno].fengdingmoney then--超过封顶后触发
        desklist[deskno].isfengding = 1
        desklist[deskno].kaifengsiteno = siteno
    end

    --广播玩家下注
    net_broadcastdesk_user_xiazhu(userinfo,xztype)

    --下注了继续找下一位
    continuegame(deskno,1)
end

--记录牌型相关采集.
function record_paixin_msg(deskno, winsite, losesite)
    local paixin_level_winsite = desklist[deskno].site[winsite].paixing
    local paixin_level_losesite = desklist[deskno].site[losesite].paixing
    --[[
        单牌：0
        对子：1
        顺子：2
        金花: 3
        顺金：4
        豹子：5
		偷鸡: 6
    -]]   

	--输家是偷鸡则算散牌
	if paixin_level_losesite == 6 then
		desklist[deskno].site[losesite].paixing = 0--更改玩家的牌型
		paixin_level_losesite = 0
	end

    local windesksitedata = desklist[deskno].site[winsite]

    --是否为秒杀
    if(paixin_level_winsite - paixin_level_losesite >= 2) then
        windesksitedata.spike = 1   
    else
        windesksitedata.spike = 0 
    end

    --是否杀了金花的牌
    if(paixin_level_losesite == 3) then
        windesksitedata.win_jinhua = 1   
    else
        windesksitedata.win_jinhua = 0  
    end

    --是否为险胜,牌型数字相差不到3
    windesksitedata.xiansheng = 0
    local winpokes = desklist[deskno].site[winsite].handpokes
    local losepokes = desklist[deskno].site[losesite].handpokes

    if(paixin_level_winsite == paixin_level_losesite) then
        if((tonumber(zysz.pokenum[winpokes[2]]) - tonumber(zysz.pokenum[losepokes[2]])) <= 3) then
            windesksitedata.xiansheng = 1
        end
    end
end

--收到用户强退
function OnZYSZRecvForceOutGame(buf)
    local curUser = getuserid(buf)
    --安全验证
    local userinfo = userlist[curUser];
    if not userinfo then return end
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
        hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
        doUserGiveUp(userinfo)
    end
	net_Send_KickUser(userinfo)
end

--收到点击彩池
function onZYSZRecvClickCaiChi(buf)
	local userId = getuserid(buf) --string.format("%s:%s", buf:ip(), buf:port())
	local userinfo = userlist[userId];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	if isguildroom() then return end
	
	local sitedata = desklist[deskno].site[siteno]
    --已经点过投币 或 已经看牌 都不能再投币
    if sitedata.iscaichi >= 1 then
        return
	end

	if sitedata.islose == 1 or desklist[deskno].firstkaipai ~= 0 then
        return
    end
	
	if deskmgr.get_game_state(deskno) ~= gameflag.start then
		return
	end

	local userdata = deskmgr.getuserdata(userinfo)

	sitedata.iscaichi = 1  --投注彩池

	--彩池下注金额为底注
	local caichiAdd = desklist[deskno].addCaichiMoney
	
	--增加彩池总金额
	zysz.caichi.sumgold = zysz.caichi.sumgold + caichiAdd;

    --从玩家身上扣除投注
	usermgr.addgold(userinfo.userId,-caichiAdd,0,tSqlTemplete.goldType.ZYSZ_TOUZHU,-1)
	
	--更新数据库总金币数
	local szsql = format(tZyszSqlTemplete.updateCaichiGold,zysz.caichi.sumgold,groupinfo.groupid) 	
	dblib.execute(szsql)


	--发送当前彩池总金额
	--broadcast_lib.borcast_room_event_by_filter("ZYSZSNCC")
    netlib.send(net_broadcast_caichi_sumgold, userinfo.ip, userinfo.port)
    --发送给当前桌子
    netlib.send(function(buf)
		buf:writeString("ZYSZCC")
    	buf:writeByte(siteno)	--点了彩池投币人的座位号
    	buf:writeInt(caichiAdd)	--投注了多少钱 
    end,userinfo.ip,userinfo.port)

    
end

--收到玩家请求点击开始
function onZYSZRecvGameStart(buf)
	local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	--判断合法性
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.NOTREADY then return end
    --判断是否为观战用户
    if (watch_lib.is_watch_user(userinfo) == 1) then
        --修改桌子中的座位开始等待状态
        hall.desk.set_site_state(deskno, siteno, SITE_STATE.WATCH)        
    else
        --修改桌子中的座位开始等待状态
    	hall.desk.set_site_state(deskno,siteno,SITE_STATE.READYWAIT)    
    	--广播用户已经准备好开始游戏的消息
        net_broadcast_game_start(deskno,siteno)    
    	--尝试开始游戏
    	playgame(deskno)
    end
end

function playgame(deskno)
    if deskmgr.get_game_state(deskno) == gameflag.notstart then  --未开始状态
		local readysite = 0			--点开始的人数
		local notreadysite = 0		--没点开始的人数
		for i = 1, room.cfg.DeskSiteCount do
			local state = hall.desk.get_site_state(deskno, i)
			if state == SITE_STATE.READYWAIT then
				readysite = readysite + 1
			elseif state == SITE_STATE.NOTREADY then
				notreadysite = notreadysite + 1
			end
		end

    	if notreadysite == 0 and readysite >= 2 then

			desklist[deskno].peopleplaygame = readysite

            --记录每局开始时候的人数
            desklist[deskno].gamestart_playercount = desklist[deskno].peopleplaygame

            --这局开始，设置当局开始时间
    	    desklist[deskno].starttime = os.date("%Y-%m-%d %X", os.time())

            --游戏开始标志
		    deskmgr.set_game_state(deskno, gameflag.start)

	        --计算玩家的最小下注
            get_minbet_from_playlist(deskno)

            --开局抽水
            desklist[deskno].choushui = math.abs(math.floor(desklist[deskno].dizhu * groupinfo.specal_choushui * 0.1 + 0.5))

            for _, player in pairs(deskmgr.getplayers(deskno)) do
                --扣抽水钱
                usermgr.addgold(player.userinfo.userId,-desklist[deskno].choushui,-desklist[deskno].choushui,tSqlTemplete.goldType.ZYSZ_CHOUSHUI,tSqlTemplete.goldType.ZYSZ_CHOUSHUI)
                --该座位本局可用最大金额
                desklist[deskno].site[player.userinfo.site].maxbetmoney = player.userinfo.gamescore
            end

            desklist[deskno].mingamescore = desklist[deskno].mingamescore - desklist[deskno].choushui--记录最小携带

            desklist[deskno].fengdingmoney = zysz_get_dizhu_bygold(1+desklist[deskno].mingamescore * gamecfg.myselfbili, 2)--记录封顶值

            --设置扎金花投注
            desklist[deskno].addCaichiMoney = desklist[deskno].dizhu
            if desklist[deskno].addCaichiMoney > 10000 then
                desklist[deskno].addCaichiMoney = 10000
            end

            --开始发牌
    	    fapaiAll(deskno)
    	    
    	    if desklist[deskno].game == nil then desklist[deskno].game = {} end
    		desklist[deskno].game.startTime = os.date("%Y-%m-%d %X", os.time())
    	end
    end
end

--得到底注
function get_minbet_from_playlist(deskno)
	--找出本桌的最小携带
	local mingold = 0
	local num = 0

	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local usergold = player.userinfo.gamescore
		if num == 0 then
			mingold = usergold
			num = 1
		end

		if usergold < mingold then
			mingold = usergold
		end
	end
    
	desklist[deskno].mingamescore = mingold--记录最小携带

    desklist[deskno].dizhu = math.abs(math.floor(zysz_get_dizhu_bygold(mingold,1) * gamecfg.dizhuxishu))--赋值底注

    desklist[deskno].curdeskzhu = desklist[deskno].dizhu
end

function zysz_get_dizhu_bygold(mingold,num)
	local mingoldstr = tostring(math.abs(math.floor(mingold)))
	local betgoldstr = ""

	if string.len(mingoldstr) < 3 then
		TraceError("非法的钱传来!!!" .. mingoldstr)
		return 0
	elseif string.len(mingoldstr) <= 4 then
		betgoldstr = string.sub(mingoldstr,1,num)
	else
		betgoldstr = string.sub(mingoldstr,1,2)
	end

	local leavelen = string.len(mingoldstr) - string.len(betgoldstr)

	for i = 1,leavelen do
		betgoldstr = betgoldstr .. "0"
	end
	
	return tonumber(betgoldstr)
end

--随机设置某台赢家的座位号，即第一个发牌的座位号
--返回座位号
function randomZhuangJia(deskno)
	local randomSite = math.random(1, room.cfg.DeskSiteCount)	--随机位置

	local breakSite = randomSite 
	local userinfo =  deskmgr.getsiteuser(deskno,randomSite)
	for i = 1,room.cfg.DeskSiteCount do
		if userinfo ~= nil then
			break
		end

		randomSite = deskmgr.getnextsite(deskno,randomSite)

		if breakSite == randomSite then
			TraceError("[deadloop]找不到可玩状态的玩家座位BUG了!")
			break
        end

        userinfo = deskmgr.getsiteuser(deskno,randomSite)
	end

	return randomSite
end

--全部发牌
function fapaiAll(deskno)
    if desklist[deskno].zhuangjia == 0 then--没有庄家随机一个
	    desklist[deskno].zhuangjia = randomZhuangJia(deskno)
	else--有庄家的话找下个当庄
		desklist[deskno].zhuangjia = deskmgr.getnextsite(deskno,desklist[deskno].zhuangjia)
	end

	desklist[deskno].nextpeople = desklist[deskno].zhuangjia

    --产生牌
    makePaiList(deskno)
    
    --[[ 
    local test = 0 ]]--

    for _,player in pairs(deskmgr.getplayers(deskno)) do
		local siteno = player.siteno
    	if hall.desk.get_site_state(deskno,siteno) == SITE_STATE.READYWAIT then
            local sitedata = desklist[deskno].site[siteno]
            for j = 1,zysz.cfg.handpokenum do
                table.insert(sitedata.handpokes,fapai(deskno))
            end

            --[[ 
            --测试相同牌型的代码
            if test == 0 then
                sitedata.handpokes =  {10,23,36} --对子  {1,13,11}    --顺金
            elseif test == 1 then
                sitedata.handpokes = {2,3,1}    --235   --{1,15,29}  --顺子
            elseif test == 2 then
                sitedata.handpokes = {2,4,6}    --金花
            elseif test == 3 then
                sitedata.handpokes = {2,3,19}   --{7,8,9}    --顺金
            elseif test == 4 then
                sitedata.handpokes = {10,23,36} --豹子
            elseif test == 5 then
                sitedata.handpokes = {27,38,39} --红桃AKQ
            end
            test = test + 1
            ]]--

            sitedata.handpokes = sortpokerlist(sitedata.handpokes)
            --得到手牌char
            sitedata.handchar = zysz.pokechar[sitedata.handpokes[1]]..zysz.pokechar[sitedata.handpokes[2]]..zysz.pokechar[sitedata.handpokes[3]] 
			--得到牌型
			sitedata.paixing = get_site_poke_level(deskno,siteno)
    	    --底注
    	    desklist[deskno].site[siteno].betmoney = desklist[deskno].dizhu

            desklist[deskno].site[siteno].betpercent = desklist[deskno].dizhu

    	    --台面金额增加
    	    desklist[deskno].betmoney = desklist[deskno].betmoney + desklist[deskno].site[siteno].betmoney
        else
            TraceError("开始的时候有人不是READWAIT，诡异了")
		end

		hall.desk.set_site_state(deskno,siteno,SITE_STATE.FAPAI)
    end

    net_send_fapai(deskno)--广播发牌状态
end

--收到发牌结束
function onZYSZRecvFapaiOver(buf)
	local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	--判断合法性
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.FAPAI then return end

	if desklist[deskno].site[siteno].isfapaiover == 1 then return end

	--设置成已经结束发牌
	desklist[deskno].site[siteno].isfapaiover = 1

	--设置成等待
	hall.desk.set_site_state(deskno,siteno,SITE_STATE.WAIT)

	do_fapai_over_check(deskno)
end

--执行发牌结束检查并进行下步操作
function do_fapai_over_check(deskno)
	local countover = 0
	for i = 1,room.cfg.DeskSiteCount do
		if desklist[deskno].site[i].isfapaiover == 1 then
			countover = countover + 1
		end
	end

	--收到所有人返回了(发牌结束，继续找下一位)
	if countover >= desklist[deskno].peopleplaygame then
		continuegame(deskno)
	end
end

--得到彩池信息
function OnRecvCaiChiInfo(tRet)
    if (#tRet == 0) then
        --没有彩池信息，插入到数据库
        TraceError("没有彩池信息，插入新的到数据库")
        local szsql = format(tZyszSqlTemplete.insertZyszCaichiInfo,groupinfo.groupid, os.time())
		dblib.execute(szsql)
        return
    end

    zysz.caichi.sumgold = tonumber(tRet[1]["sumgold"] or 0)           
    zysz.caichi.lastwinuser = tRet[1]["last_win_user"] or ""              
    zysz.caichi.lastwintime = tonumber(tRet[1]["last_win_time"] or 0) 
    zysz.caichi.lastwinmoney = tonumber(tRet[1]["last_win_gold"] or 0) 
    TraceError("成功得到zysz彩池信息")
end

function getCaichiInfo()
    local szsql = format(tZyszSqlTemplete.getZyszCaichiInfo,groupinfo.groupid)
	dblib.execute(szsql, OnRecvCaiChiInfo)
end
---------------------------------------------
zysz.ontimecheck = function()
    if (room.time % 5 == 0) then
        collectgarbage("collect")
    end
    if timelib.time % 5 == 0 then
        if (zysz.cfg.last_broadcast_user_id == nil) then
                zysz.cfg.last_broadcast_user_id = 0
        end
        zysz.cfg.last_broadcast_user_id = (zysz.cfg.last_broadcast_user_id + 1) % 100
        --发送当前彩池总金额
        if (zysz.caichi.sumgold ~= zysz.caichi.orgsumgold) then            
            broadcast_lib.borcast_room_event_by_filter("ZYSZSNCC", broad_caici_filter)
            zysz.caichi.orgsumgold = zysz.caichi.sumgold
        end
    end
	if timelib.time % 10 == 0 then
        
		for deskno = 1, room.cfg.deskcount do
			if desklist[deskno] and desklist[deskno].state_list ~= nil and
				#desklist[deskno].state_list ~= 0 and zysz.getGameStart(deskno) == true then
				--异常处理开始
				local all_wait = true
				local wait_count = 0
				local null_count = 0
				for i = 1, room.cfg.DeskSiteCount do					
					if hall.desk.get_site_state(deskno, i) ~= SITE_STATE.WAIT and
						hall.desk.get_site_state(deskno, i) ~= SITE_STATE.READYWAIT and 
						hall.desk.get_site_state(deskno, i) ~= NULL_STATE then
						all_wait = false
						break
					end	
				end
				if all_wait == true then --所有人都是稳定状态
					TraceError("第" .. tostring(deskno) .. "桌卡死了")					
					TraceError(desklist[deskno].state_list)
					desklist[deskno].state_list = {}
					forceGameOver(deskno)
				end
				--异常处理结束
			end
		end
	end
end

--设置下注拆分金额
function setbetmoney(deskno,siteno,money)
    local betmoney = 0
    if desklist[deskno].site[siteno].islook == 1 then  --如果看过牌，桌面目前注乘以2
		betmoney = desklist[deskno].curdeskzhu * 2
    end

    if betmoney == 0 then
        betmoney = money
    end

    local mycurbetmoney = desklist[deskno].site[siteno].betmoney
    local mycurbetpercent = desklist[deskno].site[siteno].betpercent
    local fengdingmoney = desklist[deskno].fengdingmoney

    if desklist[deskno].isfengding == 0 then
        --检查跟注时有没有超过最小携带玩家身上的钱
        if betmoney >= desklist[deskno].mingamescore - mycurbetmoney then
            TraceError("异常了超过了最小钱的人")
    	    betmoney = desklist[deskno].mingamescore - mycurbetmoney
        elseif betmoney >= fengdingmoney - mycurbetpercent then--超过封顶后触发
            betmoney = fengdingmoney - mycurbetpercent
            if desklist[deskno].site[siteno].islook == 1 then--自己看牌了
                betmoney = betmoney * 2
            end
        end
    else--有人开启了封顶，补平封顶
        betmoney = fengdingmoney - mycurbetpercent--自己闷牌

        if desklist[deskno].site[siteno].islook == 1 then--自己看牌了
            betmoney = betmoney * 2
        end
    end

	return betmoney
end

function calCaichiMoney(deskno)
    local userpokes = {}
    local siteChar = ""
    local awardMoney = 0;	--获得的彩池奖金
    local awardBeishu = 0;  --获得彩池的倍数
    local updategoldTamplate = "%d,%d,%d"
    local szSql = ""

    for i = 1, room.cfg.DeskSiteCount do 		
        local sitedata = desklist[deskno].site[i]
        if sitedata.iscaichi == 1 and sitedata.islose ~= 1 then	--如果投了彩池 并且 这个人是赢家
            local userinfo = userlist[hall.desk.get_user(deskno, i)]
            --如果离开以后中彩池，不再发奖
            if(userinfo ~= nil) then
                awardMoney = 0;
                userpokes = sitedata.handpokes
                siteChar = sitedata.handchar
            
                local needborcast = false
                --是否红桃AKQ
                if validRedAKQ(userpokes,siteChar) then
                    awardMoney = zysz.caichi.sumgold;	--获得全部彩池
                    needborcast = true
                    awardBeishu = 100
                      
                --是否豹子牌型
                elseif validBaozi(siteChar) then
                    awardMoney = desklist[deskno].addCaichiMoney * 40;	--40倍回报
                    needborcast = true
                    awardBeishu = 40
                
                --是否为顺金（同花顺）
                elseif validColor(userpokes) and validShunzi(siteChar) then 
                    awardMoney = desklist[deskno].addCaichiMoney * 30;	--30倍回报
                    needborcast = true
                    awardBeishu = 30
                
                --是否为金花（同花）
                elseif validColor(userpokes) then
                    awardMoney = desklist[deskno].addCaichiMoney * 5;	--5倍回报
                    awardBeishu = 5
                
                --是否为顺子
                elseif validShunzi(siteChar) then 
                    awardMoney = desklist[deskno].addCaichiMoney * 4;	--4倍回报
                    awardBeishu = 4
                
                --是否为JJ以上的对
                elseif validJJDuizi(siteChar) then
                    awardMoney = desklist[deskno].addCaichiMoney;		--1倍回报
                    awardBeishu = 1
				end

                --中了彩池
                if(awardMoney > 0) then
                    --如果超过余额，直接将彩池中金额全部设为奖金
                    if(awardMoney > zysz.caichi.sumgold) then
                        awardMoney = zysz.caichi.sumgold;
                    end
            
                    --记录玩家赢了彩池多少金币和多少倍
                    sitedata.wincaichi_gold = awardMoney
                    sitedata.wincaichi_beishu = awardBeishu
    
                    zysz.caichi.sumgold = zysz.caichi.sumgold - awardMoney;

                    --奖金抽水
                    local jiangchichoushui = awardBeishu > 5 and math.floor(awardMoney * gamecfg.jiangchichoushui) or 0

                    --中了彩池给玩家加钱
                    usermgr.addgold(userinfo.userId,(awardMoney - jiangchichoushui),-jiangchichoushui,tSqlTemplete.goldType.ZYSZ_CAICHI,tSqlTemplete.goldType.ZYSZ_CAICHI_CHOUSHUI,1)
    
                    --需要广播才去广播,在数据库更新获奖人            
                    if(needborcast) then
                        --更新数据库彩池信息
                        szSql = format(tZyszSqlTemplete.updateCaichiInfo,zysz.caichi.sumgold,dblib.tosqlstr(userinfo.nick),os.time(),awardMoney,groupinfo.groupid) 
                        dblib.execute(szSql)
                        zysz.caichi.lastwinuser = userinfo.nick;
                        zysz.caichi.lastwinmoney = awardMoney - jiangchichoushui;
                        zysz.caichi.lastwintime = os.time()
						zysz.caichi.isshowhuojiang = 1
                    else
                        --不需要广播的不广播，不更新数据库的获奖人
                        --更新数据库彩池信息
                        szSql =  format(tZyszSqlTemplete.updateCaichiInfo_goldonly,zysz.caichi.sumgold,groupinfo.groupid) 
                        dblib.execute(szSql)
						zysz.caichi.isshowhuojiang = 0
                    end
                    
                    zysz.caichi.userid = userinfo.userId
                    --告诉所有人 有人彩池中奖了,1倍数以上的
                    if (awardBeishu > 5) then
                        broadcast_lib.borcast_room_event_by_filter("ZYSZCCOK", broad_prize_filter)
                    elseif (needborcast) then
                        netlib.send(net_send_telluser_getprize, userinfo.ip, userinfo.port)
                    end                    
                end

                --彩池任务相关
                local gameeventdata = {}
                xpcall(function()
                    local refdata = {
                        userid 	= userinfo.userId,
                        single_event = 1,
                        data	= {}
                    }

                    if(sitedata.wincaichi_beishu > 0) then
                        --REF_SMALLCAICHI 拿到5倍及以下彩池奖励
                        if(sitedata.wincaichi_beishu <= 5) then
                            refdata.data[zysz.gameref.REF_SMALLCAICHI] = 1
                        --REF_BIGCAICHI 拿到5倍以上彩池奖励
                        else
                            refdata.data[zysz.gameref.REF_BIGCAICHI] = 1
                        end
                
                        --REF_WINCAICHI100   一盘赢100+彩池金币
                        if(sitedata.wincaichi_gold >= 100) then
                            refdata.data[zysz.gameref.REF_WINCAICHI100] = 1
                            --REF_WINCAICHI1000   一盘赢1000+彩池金币
                            if(sitedata.wincaichi_gold >= 1000) then
                                refdata.data[zysz.gameref.REF_WINCAICHI1000] = 1
                            end
                        end         
                    end

                    table.insert(gameeventdata, refdata)
                end, throw)
                --派发参考数据
                eventmgr:dispatchEvent(Event("game_event", gameeventdata));

            end
        end
    end
end

--winsite赢的人座位号,winnum有几个人赢了
function calMoney(deskno,winsite,winnum)
    trace("进入结算")
    local tempscore = 0

    local logDesk = desklist[deskno];
    local logUsersInfo = groupinfo.groupid..","..desklist[deskno].gamepeilv..",\""..logDesk.starttime.."\",\""
			 ..os.date("%Y-%m-%d %X", os.time()).."\""
	
    --结算的时候只写入赢家的金币数据，输家的在比牌结束和投降后已经写过数据库了
    --获取赢家用户
    local userid = hall.desk.get_user(deskno, winsite);
    local userinfo = userlist[userid]

    tempscore = math.floor(desklist[deskno].betmoney / winnum) - desklist[deskno].site[winsite].betmoney

	------统计所有用户10分钟内金币总和----------
	local all_info = {
		gold = tempscore,
		userid = userinfo.userId,
	}
	eventmgr:dispatchEvent(Event("golderror_checkpoint", all_info))
    ------------------------------------------------

    local userdata = deskmgr.getuserdata(userinfo)

    --结算加钱
	usermgr.addgold(userinfo.userId, tempscore, 0, tSqlTemplete.goldType.ZYSZ_JIESUAN, -1,1)

    --填充日志记录sql，如果不够6人，填充0.
    local sbgold = userinfo.safebox.safegold ~= nil and userinfo.safebox.safegold or 0

    desklist[deskno].logpeople = desklist[deskno].logpeople + 1

	desklist[deskno].winpeoplenum = desklist[deskno].winpeoplenum - 1--赢的人结算了一次

    desklist[deskno].logsql = desklist[deskno].logsql.. "," ..userinfo.userId.. ",".. tempscore .. ",0," 
                                .. userinfo.nSid..","..userinfo.gamescore..","..sbgold

	if desklist[deskno].winpeoplenum <= 0 then
		local countSql = room.cfg.DeskSiteCount - desklist[deskno].logpeople   
		 
		for i = 1,countSql do
			desklist[deskno].logsql = desklist[deskno].logsql.. ",0,0,0,0,0,0"
		end

		logUsersInfo = logUsersInfo..","..desklist[deskno].logsql
		  
		dblib.execute(format(tZyszSqlTemplete.insertLogRound, logUsersInfo))
	end

    --赢家任务相关
    local gameeventdata = {}
    xpcall(function()
        local refdata = {
            userid 	= userinfo.userId,
            iswin = 1,
            single_event = 0,
            wingold = tempscore,
            data =
            {
                [zysz.gameref.REF_GOLD]	= tempscore,
                [zysz.gameref.REF_EXP]  	= 0,
                [zysz.gameref.REF_WIN]  	= 1,
                [zysz.gameref.REF_BIGWIN] = 0,				
            }
        }

        update_game_ref_data(userinfo.desk,userinfo.site, refdata)
        table.insert(gameeventdata, refdata)
    end, throw)
    --派发参考数据
    eventmgr:dispatchEvent(Event("game_event", gameeventdata));

    if desklist[userinfo.desk].gamestart_playercount < 1 then
	    desklist[userinfo.desk].gamestart_playercount = 1
    end

    --算积分[赢的人]
    local integraldata = {
        is_win = 1,          --是否获胜
        extra_integral = 0,	 --额外加成
        player_count = desklist[userinfo.desk].gamestart_playercount - winnum,  --每盘游戏开始时候的人数 - 赢的人数
        userid = userinfo.userId,                   --用户id
    }

    --发送积分更新消息,更新积分数据
    eventmgr:dispatchEvent(Event("integral_change_event", integraldata));

    --zysz转盘活动
    if (zhuanpan_zyszlib) then
        xpcall(function() zhuanpan_zyszlib.on_game_over(userinfo, desklist[deskno].site[winsite].islook, desklist[deskno].site[winsite].paixing, deskno) end, throw)
    end
end

--得到牌型等级
    --[[
        单牌：0
        对子：1
        顺子：2
        金花: 3
        顺金：4
        豹子：5
		偷鸡: 6
    -]]       
function get_site_poke_level(deskno,siteno)
    local userpokes = desklist[deskno].site[siteno].handpokes 
    local siteChar = desklist[deskno].site[siteno].handchar   
    local paixin_level = 0
    --是否豹子牌型
    if validBaozi(siteChar) then
        paixin_level = 5

    --是否为顺金（同花顺）
    elseif validColor(userpokes) and validShunzi(siteChar) then 
       paixin_level = 4

    --是否为金花（同花）
    elseif validColor(userpokes) then
        paixin_level = 3

    --是否为顺子
    elseif validShunzi(siteChar) then 
        paixin_level = 2

    --是否为对子
    elseif validDuizi(siteChar) then
        paixin_level = 1
	else
		if validTouji(siteChar) then--偷鸡牌型
			paixin_level = 6
		end
    end

    return paixin_level
end


--比较某张台上两个座位的牌的大小
--return : 0：一样大；1:site1大； 2:site2大
function validPoker(deskno,site1,site2)
	local result = 0

	--排序后给出
	local site1pokes = desklist[deskno].site[site1].handpokes
	local site2pokes = desklist[deskno].site[site2].handpokes
	
	
	local site1Char = desklist[deskno].site[site1].handchar
	local site2Char = desklist[deskno].site[site2].handchar
	
	local site1Paixing = desklist[deskno].site[site1].paixing
	local site2Paixing = desklist[deskno].site[site2].paixing
	--[[
        单牌：0
        对子：1
        顺子：2
        金花: 3
        顺金：4
        豹子：5
		偷鸡: 6
    -]] 
	--豹子牌型的比较
	if site1Paixing == 5 then
        if site2Paixing == 5 then --site2是豹子
            --比豹子的大小
            if zysz.pokebaozi[site1Char] > zysz.pokebaozi[site2Char] then
                result = 1
            else
                result = 2
            end
        else --site2不是豹子。
            --是否偷鸡牌？
            if site2Paixing == 6 then
                result = 2
            else
                result  = 1
            end
        end
	else --site1不是豹子
		if site2Paixing == 5 then --site2是豹子
			--site1是否偷鸡牌？
			if site1Paixing == 6 then
				result = 1
			else
				result  = 2
			end
		else  --两个都不是豹子
		    --同花顺牌型的比较
			if site1Paixing == 4 then --site1同花顺
                if site2Paixing == 4 then	--site2是同花顺
                    --比较大小
                    if zysz.pokeshunzi[site1Char] > zysz.pokeshunzi[site2Char] then
                       result = 1
                    else
                        if zysz.pokeshunzi[site1Char] < zysz.pokeshunzi[site2Char] then
                            result = 2
                        else --大小相等
                            result = 0
                        end
                    end
                else--site2不是同花顺
                    result = 1
                end
			else--site1不是同花顺
				if site2Paixing == 4 then--site2是同花顺
					result = 2
				else--都不是同花顺
				    --同花牌型的比较
					if site1Paixing == 3 then --site1同花
						if site2Paixing == 3 then	--site2是同花
							--比较单张大小
							result = validDanZhang(site1pokes,site2pokes)
						else--site2不是同花 
							result = 1 
						end
					else--site1不是同花 
						if site2Paixing == 3 then--site2是同花
							result = 2
						else--都不是同花
						    --顺子牌型的比较
							if site1Paixing == 2 then --site1顺子
								if site2Paixing == 2 then	--site2是顺子
									--比较大小
									if zysz.pokeshunzi[site1Char] > zysz.pokeshunzi[site2Char] then
					   					result = 1
									else
										if zysz.pokeshunzi[site1Char] < zysz.pokeshunzi[site2Char] then
											result = 2
										else--一样大
											result = 0
										end
									end
								else--site2不是顺子 
									 result = 1 
								end
							else--site1不是顺子
								if site2Paixing == 2 then	--site2是顺子
							 		result = 2
							 	else--都不是顺子
								    --对子牌型的比较 
									if site1Paixing == 1 then --site1对子
										if site2Paixing == 1 then	--site2是对子
											--比较大小
											if zysz.pokeduizi[site1Char] > zysz.pokeduizi[site2Char]  then
					   							result = 1
											else
												if zysz.pokeduizi[site1Char] < zysz.pokeduizi[site2Char]  then
													result = 2
												else--一样大
													result = 0
												end
											end
										else--site2不是对子 
									 		result = 1 
										end
									else--site1不是对子
										if site2Paixing == 1 then	--site2是对子
							 				result = 2
							 			else--都不是对子
							 			    --单张牌型的比较 --比较单张大小
                                            result = validDanZhang(site1pokes,site2pokes)
							 			end 
								 	end 
								end				 
							end
						end
					end
				end
			end
		end
    end

	return result
end

--单张牌型比较大小（不比花色）
--传入参数：num1_3表示最大的单张
--return 1:num1系列 大；2：num2系列大 。0：一样大
function validDanZhang(site1pokes,site2pokes)
	local compareValue3 = 0
	local compareValue2 = 0
	local compareValue1 = 0
   	compareValue3 = validTwoPoker(site1pokes[3],site2pokes[3])
	if compareValue3 == 1 then
		 return 1
	elseif compareValue3 == 2 then
		return 2
	end

	compareValue2 = validTwoPoker(site1pokes[2],site2pokes[2])
	if compareValue2 == 1 then
		 return 1
	elseif compareValue2 == 2 then
		return 2
	end

	compareValue1 = validTwoPoker(site1pokes[1],site2pokes[1])
	if compareValue1 == 1 then
		 return 1
	elseif compareValue1 == 2 then
		return 2
	end

	return 0
end 


--单牌比较大小（不比花色）
--return 1:num1 大；2：num2大 。0：一样大
function validTwoPoker(num1,num2)
	local result = 0
   	if zysz.pokenum[num1] >  zysz.pokenum[num2] then
   	   result = 1
   	else
   		if zysz.pokenum[num1] <  zysz.pokenum[num2] then
   			result = 2
		else 
			result = 0
   		end
    end

   	return result
end 

--判断是否同花
--传入：三张牌的数字表示
--返回：true/false
function validColor(pokes)
	if zysz.pokecolor[pokes[1]] == zysz.pokecolor[pokes[2]] and  zysz.pokecolor[pokes[2]] == zysz.pokecolor[pokes[3]] then
		return true
	else
		return false
	end
end

--判断是否红桃AKQ
--传入：三张牌的字符表示，如"222"
--返回：true/false
function validRedAKQ(pokes,pokerChar)
	local result = false;
	--先判断是否同花顺牌型
	if validColor(pokes) and validShunzi(pokerChar) then --同花顺
		--是否红桃
		if zysz.pokecolor[pokes[1]] == 3 then
		--是否AKQ
			if zysz.pokeshunzi[pokerChar] == 12 then
				result = true;
			end
		end
	end
	return result;
end

--判断是否豹子
--传入：三张牌的字符表示，如"222"
--返回：true/false
function validBaozi(pokerChar)
	if zysz.pokebaozi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

function validJJDuizi(pokerChar)
	local result = false;
	--是否对子
	if validDuizi(pokerChar) then 
		--是否J以上的对
		if zysz.pokeduizi[pokerChar] > 108  then
			result = true;
		end
	end
	return result;
end

--判断是否顺子
--传入：三张牌的字符表示，如"234"
--返回：true/false
function validShunzi(pokerChar)
	if zysz.pokeshunzi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--判断是否对子
--传入：三张牌的字符表示，如"234"
--返回：true/false
function validDuizi(pokerChar)
	if zysz.pokeduizi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--判断是否偷鸡牌型
--传入：三张牌的字符表示，如"234"
--返回：true/false
--注：还要自己加上花色判断
function validTouji(pokerChar)
	if zysz.poketouji[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--52张牌发完重新生成
function resetpoke(deskno)
	for i = 1,room.cfg.pokerCount do
		desklist[deskno].number_count[i] = 1
	end
end

--根据桌子在玩的人数产生随机对应的牌列表
function makePaiList(deskno)
	local paiCount = desklist[deskno].peopleplaygame * 3	--总牌数
	desklist[deskno].paiList = {}
	for i= 1,paiCount do
		desklist[deskno].paiList[i] = {}
		desklist[deskno].paiList[i].id = makePai(deskno)
		desklist[deskno].paiList[i].isOut = false
	end
end

--返回一张牌
function fapai(deskno)
	local number = 0
	local orderId = 0
	local paiCount = desklist[deskno].peopleplaygame * 3	--总牌数
	
	orderId = math.random(1,paiCount)
	number = desklist[deskno].paiList[orderId].id;

	if desklist[deskno].paiList[orderId].isOut then
	   number = fapai(deskno)
	else
	   desklist[deskno].paiList[orderId].isOut = true;
	end

	return number
end

--产生一张牌
function makePai(deskno)
   local number = 0
   number = math.random(1,room.cfg.pokerCount)

   if desklist[deskno].number_count[number] > 0 then
	   desklist[deskno].number_count[number] = desklist[deskno].number_count[number] - 1
   else
		number = makePai(deskno)
   end

   return number
end
-----------------------------发送协议相关函数-----------------------------------------
--发送T人命令
function net_Send_KickUser(userinfo)
    netlib.send(function(buf)
	    buf:writeString("ZYSZREKU")
	end,userinfo.ip, userinfo.port)
end


function broad_prize_filter(user_info)
    if (user_info ~= nil and user_info.desk) then
        return 1        
    else
        return 0
    end
end

function broad_caici_filter(user_info)
    if (user_info ~= nil and user_info.desk) then
        if ((user_info.userId % 100) == zysz.cfg.last_broadcast_user_id) then
            return 1
        else
            return 0
        end
    else
        return 0
    end
end

--发送彩池信息
--isBorcastAll,0表示广播给自己，1广播给所有人
function net_send_caichi_message(isBorcastAll,userinfo)
	if isBorcastAll == 1 then
		broadcast_lib.borcast_room_event_by_filter("ZYSZCTIF", broad_caici_filter)
	elseif isBorcastAll == 0 then
		if userinfo then
			netlib.send(function(buf)
				net_broadcast_caichi_info(buf)
			end,userinfo.ip,userinfo.port)
		end
	end
end

--发送彩池总金额信息
function net_broadcast_caichi_info(buf)
	buf:writeString("ZYSZCTIF")
	buf:writeInt(zysz.caichi.sumgold)
end

--发送玩家点击彩池后通知所有人当前的彩池总金额
function net_broadcast_caichi_sumgold(buf)
	buf:writeString("ZYSZSNCC")
	buf:writeInt(zysz.caichi.sumgold)    --彩池总金额
end

--告诉彩池中奖的，自己中彩池了
function net_send_telluser_getprize(buf)
    local tbtime = os.date("*t",zysz.caichi.lastwintime)
	local lasttime = tbtime.month .."-"..tbtime.day.." "..tbtime.hour..":"..tbtime.min

    buf:writeString("ZYSZCCOK")--写消息头
    buf:writeInt(zysz.caichi.userid) --谁中了
    buf:writeByte(zysz.caichi.isshowhuojiang)
    buf:writeString(zysz.caichi.lastwinuser)
    buf:writeString(lasttime)
    buf:writeInt(zysz.caichi.lastwinmoney)
end

--通知客户端某人点开始了
function net_broadcast_game_start(deskno,startsite)
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZNTST")
    	buf:writeByte(startsite)
    end,deskno, netlib.borcast_target.all)
end

--广播自动开牌游戏结算
function net_broadcast_game_over(deskno,doType,winlist,lostlist)
	local fengold = math.floor(desklist[deskno].betmoney / #winlist)--赢的人分钱
	broadcast_lib.borcast_desk_event(function(buf)
		buf:writeString("ZYSZNTGO")
        	buf:writeByte(doType) 	--1为下注触发，2为放弃触发
		buf:writeInt(desklist[deskno].betmoney) --写入桌面总金额
		buf:writeByte(#winlist) 	--多少人赢了
		for k,v in pairs(winlist) do
			local sitedata = desklist[deskno].site[v]
			buf:writeByte(v) --座位号		
			buf:writeInt(fengold)--玩家得到多少钱
			buf:writeInt(fengold - sitedata.betmoney) --玩家真实赢了多少
			buf:writeByte(#sitedata.handpokes)
			for i = 1,#sitedata.handpokes do
				buf:writeByte(sitedata.handpokes[i])--手牌ID
			end
			buf:writeByte(sitedata.paixing) --手牌牌型
		end
		buf:writeByte(#lostlist) 	--多少人输了
		for k,v in pairs(lostlist) do
			local sitedata = desklist[deskno].site[v]
			buf:writeByte(v) --座位号		
			buf:writeInt(-sitedata.betmoney)--输了多少
			buf:writeByte(#sitedata.handpokes)
			for i = 1,#sitedata.handpokes do
				buf:writeByte(sitedata.handpokes[i])--手牌ID
			end
			buf:writeByte(sitedata.paixing) --手牌牌型
		end
	end,deskno, netlib.borcast_target.all)
end

--广播玩家放弃
function net_broadcastdesk_user_lose(deskno,giveupsiteno)
	local deskdata = desklist[deskno]
	local winsitedata = deskdata.site[desklist[deskno].winner]
    broadcast_lib.borcast_desk_event(function(buf)
	    buf:writeString("ZYSZSRFQ")
	    buf:writeByte(giveupsiteno)   --放弃的座位号.
		buf:writeInt(-deskdata.site[giveupsiteno].betmoney)--输了多少
		buf:writeByte(desklist[deskno].isgiveupover)    --玩家放弃时是否导致结束
		if desklist[deskno].isgiveupover == 1 then
			buf:writeByte(deskdata.winner) --结束时赢的玩家座位号
			buf:writeInt(deskdata.betmoney) --赢了多少钱
			buf:writeInt(deskdata.betmoney - winsitedata.betmoney) --真正赢了多少
            buf:writeByte(#winsitedata.handpokes)
			for i = 1,#winsitedata.handpokes do
				buf:writeByte(winsitedata.handpokes[i])--手牌ID
			end
			buf:writeByte(winsitedata.paixing) --手牌牌型
		end
    end,deskno, netlib.borcast_target.all)
end

--广播玩家下注信息
function net_broadcastdesk_user_xiazhu(userinfo,xztype)
    local deskno,siteno = userinfo.desk,userinfo.site
    local sitedata = desklist[deskno].site[siteno]
    local deskdata = desklist[deskno]
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZSRXZ")
    	buf:writeByte(siteno)       --下注的座位号
    	buf:writeInt(sitedata.betmoney) --该座号总下注的金额
    	buf:writeInt(sitedata.curbet)   --本次下了多少
    	buf:writeInt(deskdata.betmoney)	   --台面总金额 
    	buf:writeByte(xztype)	   --当前下注类型,1跟注，2加注
		--buf:writeByte(deskdata.isfengding) --是否开启了封顶
    end,deskno, netlib.borcast_target.all)
end

--发送给玩家面板信息
function net_send_show_action_list(userinfo)
    local deskno,siteno = userinfo.desk,userinfo.site
	local sitedata = deskmgr.getsitedata(deskno,siteno)
    netlib.send(function(buf)
		buf:writeString("ZYSZPAIF")
    	buf:writeByte(siteno)	--下一个动作的人
    	buf:writeByte(sitedata.action_look or 0)		--看牌 
    	buf:writeByte(sitedata.action_vs or 0)		--开牌
    	buf:writeByte(sitedata.action_add or 0)		--加注
    	buf:writeByte(sitedata.action_follow or 0)		--跟注
        buf:writeInt(sitedata.followgold or 0)       --跟注多少
    	buf:writeByte(sitedata.action_giveup or 0)		--放弃
    end,userinfo.ip,userinfo.port)
end

--广播发牌信息
function net_send_fapai(deskno)
	local players = {}
	local zhuangsite = desklist[deskno].zhuangjia
	table.insert(players, 1, zhuangsite)		--设置发牌顺序
	local nextsite = zhuangsite
	for i = 1,room.cfg.DeskSiteCount do
		nextsite = deskmgr.getnextsite(deskno,nextsite) 
		if nextsite == zhuangsite then
			break
		end
		table.insert(players,1,nextsite)
	end
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZNTFP")
    	buf:writeByte(zhuangsite)--庄的座位号
    	buf:writeInt(desklist[deskno].dizhu)     --底注
        buf:writeInt(desklist[deskno].choushui)  --抽水
    	buf:writeInt(desklist[deskno].betmoney)  --台面总金额
        buf:writeInt(desklist[deskno].addCaichiMoney)
		buf:writeByte(#players)--多少个人在桌面上
		for i = 1,#players do
			buf:writeByte(players[i])--座位号
		end
    end,deskno, netlib.borcast_target.all)
end

--广播玩家看牌信息
function net_send_kanpai(deskno,kanpaisite)
    --玩家手牌
	for _,player in pairs(deskmgr.getplayers(deskno)) do
		local userinfo = deskmgr.getsiteuser(deskno,player.siteno)
		local userpokes = {}
		if player.siteno == kanpaisite then
			userpokes = desklist[deskno].site[kanpaisite].handpokes
		end

		netlib.send(function(buf)
			buf:writeString("ZYSZNTKP")
			buf:writeByte(kanpaisite)  			--看牌的座位号
			buf:writeByte(#userpokes)           --手牌数
			if #userpokes > 0 then
				for i = 1,#userpokes do
					buf:writeByte(userpokes[i])	    --手牌id
				end
				buf:writeByte(desklist[deskno].site[kanpaisite].paixing)--玩家牌型
			end
		end,userinfo.ip,userinfo.port)
	end
end

--广播玩家手动开牌信息
function net_broadcast_userkaipai_info(deskno,kaipaisiteno,losesite)
	local winnersite = desklist[deskno].winner
	local winpokes = desklist[deskno].site[winnersite].handpokes
	local losepokes = desklist[deskno].site[losesite].handpokes
	local wingold = desklist[deskno].betmoney - desklist[deskno].site[winnersite].betmoney
	local lostgold = - desklist[deskno].site[losesite].betmoney

	broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZSRKP")
        buf:writeByte(kaipaisiteno)--开牌人座位号
		buf:writeInt(desklist[deskno].betmoney)--桌子上总金额
        buf:writeInt(desklist[deskno].site[kaipaisiteno].betmoney)--开牌人总下注
        buf:writeInt(desklist[deskno].site[kaipaisiteno].curbet)--开牌人本次下注多少
        buf:writeByte(winnersite)--赢的座位号
		buf:writeInt(wingold)--赢了多少
    	buf:writeByte(#winpokes)
        for i = 1,#winpokes do
    	    buf:writeByte(winpokes[i])	--手牌ID
		end
		buf:writeByte(desklist[deskno].site[winnersite].paixing)--赢家牌型
        buf:writeByte(losesite)--输的座位号
		buf:writeInt(lostgold)--输了多少
        buf:writeByte(#losepokes)
        for i = 1,#losepokes do
    	    buf:writeByte(losepokes[i])	--手牌ID
		end
		buf:writeByte(desklist[deskno].site[losesite].paixing)--输家牌型
    end,deskno, netlib.borcast_target.all)
end

--广播所有人状态
function net_broadcastdesk_playerinfo(desk)
	broadcast_lib.borcast_desk_event(
		function(buf, user)
			local len = 0;
			local data = {};
			for _, player in pairs(deskmgr.getplayers(desk)) do
				local state = hall.desk.get_site_state(desk, player.siteno)
				local statecode = 0
				if state == SITE_STATE.NOTREADY or state == SITE_STATE.WATCH then statecode = 2 end
				if state == SITE_STATE.READYWAIT then statecode = 1 end
				if state == SITE_STATE.FAPAI then statecode = 3 end
				local timeout = hall.desk.get_site_timeout(desk, player.siteno)
				if timeout < 0 then timeout = 0 end
				table.insert(data, {site = player.siteno, state = statecode, time = timeout});
				len = len + 1
			end
			buf:writeString("ZYSZNTZT")
			buf:writeInt(len)
			for i = 1, #data do
				buf:writeByte(data[i].site);		--座位号
				buf:writeByte(data[i].state)		--状态号
				buf:writeByte(data[i].time)		    --超时时间
			end
		end
	,desk, netlib.borcast_target.all)
end

-----------------------------游戏接口实现函数-----------------------------------------
--收到大厅某用户临时离线的消息，通常是用户进程被意外中止，或者是一段时间没有响应
zysz.OnTempOffline = function(userinfo)
end

zysz.onentergameroom = function(userid, roomtype, gamescore)
	return true
end

zysz.OnBeforeUserReLogin = function(userinfo)
    hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
    doUserGiveUp(userinfo)
    if (userinfo.desk ~= nil) then
        doUserStandup(userinfo.key, false)
    end
    return 0
end

zysz.getGameStart = function(deskno,siteno)
	local gamestate = deskmgr.get_game_state(deskno)
	local bGameAlreadyStart  = true	
	
	if gamestate == gameflag.notstart then
		bGameAlreadyStart = false
    end

    if(siteno and siteno > 0) then
        local sitedata = deskmgr.getsitedata(deskno,siteno)
        local bSitelreadyStart = sitedata.islose == 0

        bGameAlreadyStart = bGameAlreadyStart and  bSitelreadyStart
    end

	return bGameAlreadyStart
end

zysz.AfterUserSitDown = function(userid, desk, site, bRelogin)  --用户坐下后
    trace("有人坐下！！！！".."desk="..desk.."site="..site)
    local userinfo = userlist[hall.desk.get_user(desk, site)]
    if(bRelogin == 0) then	--不是断线的情况        
        hall.desk.set_site_state(desk, site, SITE_STATE.NOTREADY)        
    end
    --发送彩池信息
	zysz.caichi.isshowhuojiang = 0
	net_send_caichi_message(0,userinfo)
end

--用户坐下的消息包发送之后
zysz.AfterUserSitDownMessage = function(userid, desk, site, bRelogin)  --用户坐下后
    local user_info = usermgr.GetUserById(userid)    
    if (watch_lib.is_watch_user(user_info) == 1) then        
        hall.desk.set_site_state(desk, site, SITE_STATE.WATCH)
        zysz.netSendGZFP(user_info);
    end
end
--智勇三张给观战的人发其他人的牌
zysz.netSendGZFP = function(user_info)
	local desk_info = desklist[user_info.desk]
	local desk_sites = desk_info.site --座位列表
	netlib.send(function(buf)
        buf:writeString("GZFP");
        buf:writeByte(#desk_sites);
        for i=1,#desk_sites do
        	local site_id = -1;
        	if desk_sites[i].user ~= nil and userlist[desk_sites[i].user] ~= nil then --该座位有人
        		if watch_lib.is_watch_user(userlist[desk_sites[i].user]) ~= 1 then --并且该座位上的人不在观战列表
        			site_id = i;
        		end
        	end
        	buf:writeByte(site_id);
        end
    end, user_info.ip, user_info.port)
end

zysz.OnUserStandup = function(userid, desk, site)
	trace(string.format("用户(%s)通知已经离开", desk..":"..site))

	--此处与AfterUserStandup中的作用相同，理论上应该不需要两个地方都调用，但是这里不调用会有状态不更新的BUG
	hall.desk.set_site_state(desk, site, NULL_STATE)
end

zysz.AfterOnUserStandup = function(userid, desk, site)
	--清理用户状态
	hall.desk.set_site_state(desk, site, NULL_STATE)

	--尝试开始发牌
	playgame(desk)
end

zysz.AfterUserWatch = function(user_info)
    --恢复桌面
    if (watch_lib.is_watch_user(user_info) == 1) then        
        zysz.netSendGZFP(user_info);
    end
end

zysz.CanEnterGameGroup = function(szPlayingGroupName, nPlayingGroupId, nScore)
    --判断是否有游戏进行中
    if nPlayingGroupId ~= 0 then
		if tonumber(groupinfo.groupid) == nPlayingGroupId then
			return 1, ""
		else
			return -102, "您在 "..szPlayingGroupName.." 的游戏还在进行中,无法进入该房间。"
		end
    else
		trace("当前没有正在进行游戏的id")
    end
end

--判断用户是否可以排队
zysz.CanUserQueue = function(userKey, deskno)
    return 1, 0
end

--判断用户在游戏中能不能买得起某种价格的物品
zysz.CanAfford = function(userinfo, paygold, pay_limit)
	local gold = userinfo.gamescore 
	if userinfo.desk then gold = gold - (pay_limit or groupinfo.pay_limit) end
	return gold - paygold >= 0,paygold - gold
end

zysz.init_desk_info = function()
end

zysz.init_site_info = function()
end

zysz.init_desk_data = function(deskno)
    local i = deskno
    desklist[i].gamestate = gameflag.notstart
    desklist[i].peoplejiesuan = 0	-- 这一桌上已经结算的人数
    desklist[i].peopleplaygame = 0	-- 这一桌上在玩游戏的人数
    desklist[i].nextpeople = 0  --下一个动作的人
    desklist[i].winner = 0      --赢家座位号(0为有多个赢家)
	desklist[i].zhuangjia = 0   --庄家座位号

    desklist[i].logsql = ""   	--该桌的相关日志信息记录sql
    desklist[i].logpeople = 0	--该桌的记录日志的人数，为了避免和游戏逻辑冲突，单独记了一个数据
    desklist[i].starttime = ""	--该桌游戏开始的时间
    desklist[i].giveup_people_num = 0    --是否放弃了
	desklist[i].firstkaipai = 0 --是否开牌了,0未开牌，其他为开牌座位号
    desklist[i].isgiveupover = 0    --这桌游戏以有人放弃结束 
	
    desklist[i].number_count = {} 
    for j = 1, room.cfg.pokerCount do
        desklist[i].number_count[j] = 1	--每张牌的数量 
    end

    desklist[i].betmoney = 0		--台面总金额
    desklist[i].gamestart_playercount = 0  --游戏开始的时候有几个人
    desklist[i].game = {}

    for j = 1, room.cfg.DeskSiteCount do
        desklist[i].site[j].handpokes = {}      --玩家的手牌
        desklist[i].site[j].handchar = ""       --玩家的手牌字符串	
		desklist[i].site[j].paixing = -1        --玩家的手牌牌型	
        desklist[i].site[j].betmoney = 0	    --实际下注金额
        desklist[i].site[j].betpercent = 0      --闷牌下的下注金额
        desklist[i].site[j].maxbetmoney = 0	    --个人的每局可用总金额（因为个人金币不同而不同）
        desklist[i].site[j].islook = 0          --是否看过牌,0未看牌,1看牌
        desklist[i].site[j].iscaichi = 0        --是否投注彩池,0未投注，1投注了,2不能投币
        desklist[i].site[j].islose = 0          --是否放弃了,0为放弃,1放弃了
        desklist[i].site[j].action_look = 0	    --看牌
        desklist[i].site[j].action_vs = 0	    --开牌
        desklist[i].site[j].action_add = 0	    --加注
        desklist[i].site[j].action_follow = 0   --跟注
        desklist[i].site[j].followgold = 0
        desklist[i].site[j].action_giveup = 0   --放弃
        desklist[i].site[j].wincaichi_beishu = 0  --赢彩池倍数
        desklist[i].site[j].wincaichi_gold = 0  --赢彩池奖金
        desklist[i].site[j].win_jinhua = 0      --赢了别人的金花
        desklist[i].site[j].spike = 0           --秒杀
        desklist[i].site[j].xiansheng = 0       --险胜
        desklist[i].site[j].curbet = 0          --玩家每次下注的金额
		desklist[i].site[j].isfapaiover = 0     --发牌是否结束,0未结束,1已经结束
		desklist[i].site[j].isadd = 0           --玩家是否加过注
		desklist[i].site[j].isnarrow = 0	    --是否为相同牌型险胜
        desklist[i].site[j].isautokaipai = 0    --是否自动比牌
    end

    desklist[i].addCaichiMoney = 0 --彩池加注额
    desklist[i].mingamescore = 0  --携带最小钱的钱数
    desklist[i].dizhu = 0         --该局游戏的底注
    desklist[i].curdeskzhu = 0    --该局游戏的当前桌上注
    desklist[i].choushui = 0      --该局游戏抽水
    desklist[i].isfengding = 0    --该局游戏封顶是否开启，0未开启，1开启
    desklist[i].kaifengsiteno = 0 --该局游戏开启封顶的座位号
    desklist[i].fengdingmoney = 0 --该局游戏开启封顶时，封顶座位号下的注
	desklist[i].winpeoplenum = 0	--本局有多少人赢了
	desklist[i].lostpeoplenum = 0  --本局系统开牌多少人输了
end

zysz.init_desk_all = function()
    for i = 1, room.cfg.deskcount do
        zysz.init_desk_data(i)
    end
end

--初始化游戏参数（每局游戏结束的时候调用）
function initGameData(deskno)
    desklist[deskno].logsql = ""
    desklist[deskno].logpeople = 0
    desklist[deskno].firstkaipai = 0 --是否开牌了,0未开牌，其他为开牌座位号
    desklist[deskno].giveup_people_num = 0 --放弃的人数
    desklist[deskno].gamestart_playercount = 0 --每盘开始的人数
    desklist[deskno].betmoney = 0 --台面总金额
    
    desklist[deskno].addCaichiMoney = 0 --彩池加注额
    desklist[deskno].mingamescore = 0  --携带最小钱的钱数
    desklist[deskno].dizhu = 0         --该局游戏的底注
    desklist[deskno].curdeskzhu = 0    --该局游戏的当前桌上注
    desklist[deskno].choushui = 0      --该局游戏抽水
    desklist[deskno].isfengding = 0    --该局游戏封顶是否开启，0未开启，1开启
    desklist[deskno].kaifengsiteno = 0 --该局游戏开启封顶的座位号
    desklist[deskno].fengdingmoney = 0 --该局游戏开启封顶时，封顶座位号下的注

    desklist[deskno].peopleplaygame = 0	-- 这一桌上在玩游戏的人数
    desklist[deskno].nextpeople = 0     --下一个动作的人
	desklist[deskno].winpeoplenum = 0	--本局有多少人赢了
	desklist[deskno].lostpeoplenum = 0  --本局系统开牌多少人输了
	desklist[deskno].winner = 0			--赢家座位号(0为有多个赢家)
    desklist[deskno].isgiveupover = 0        --这桌游戏以有人放弃结束

    for i = 1, room.cfg.DeskSiteCount do 		
        desklist[deskno].site[i].handpokes = {}   --玩家的手牌
        desklist[deskno].site[i].handchar = ""    --玩家的手牌字符串
		desklist[deskno].site[i].paixing = -1	  --玩家的手牌牌型
        desklist[deskno].site[i].islook = 0  	  --是否看过牌,0未看牌,1看牌
        desklist[deskno].site[i].iscaichi = 0     --是否投注彩池,0未投注，1投注了,2不能投注了
        desklist[deskno].site[i].islose = 0       --是否放弃了,0为放弃,1放弃了
        desklist[deskno].site[i].betmoney = 0	  --下注金额
        desklist[deskno].site[i].betpercent = 0   --闷牌下的下注金额
		desklist[deskno].site[i].action_look = 0	--看牌
        desklist[deskno].site[i].action_vs = 0	--开牌
        desklist[deskno].site[i].action_add = 0	--加注
        desklist[deskno].site[i].action_follow = 0  --跟注
        desklist[deskno].site[i].followgold = 0
        desklist[deskno].site[i].action_giveup = 0  --放弃
		desklist[deskno].site[i].maxbetmoney = 0  --个人的每局可用总金额（因为个人金币不同而不同）
        desklist[deskno].site[i].wincaichi_beishu = 0  --赢彩池倍数
        desklist[deskno].site[i].wincaichi_gold = 0    --赢彩池奖金
        desklist[deskno].site[i].win_jinhua = 0  --赢了别人的金花
        desklist[deskno].site[i].spike = 0       --秒杀
        desklist[deskno].site[i].xiansheng = 0   --险胜
		desklist[deskno].site[i].curbet = 0      --玩家每次下注的金额
		desklist[deskno].site[i].isfapaiover = 0 --发牌是否结束,0未结束,1已经结束
		desklist[deskno].site[i].isadd = 0       --玩家是否加过注
		desklist[deskno].site[i].isnarrow = 0	 --是否为相同牌型险胜
        desklist[deskno].site[i].isautokaipai = 0 --是否自动比牌
	end

	--在桌子上的人状态都改为未准备
	for _,player in pairs(deskmgr.getplayers(deskno)) do
		if hall.desk.get_site_state(deskno,player.siteno) ~= SITE_STATE.NOTREADY then
			--用户状态改为坐下
			hall.desk.set_site_state(deskno,player.siteno,SITE_STATE.NOTREADY)
		end
	end

    --重新洗牌
    resetpoke(deskno)

end

zysz.on_start_server = function()
    zysz.init_desk_all();
    TraceError("服务器启动从数据库获得彩池信息")
    getCaichiInfo();
end

--座位状态机
zysz.init_state = function()
    hall.desk.register_site_states(newStrongTable(
	{
		NOTREADY 	= {ss_notready_offline,	 ss_notready_timeout, 20},
		READYWAIT 	= {ss_readywait_offline, NULL_FUNC,           0},
		FAPAI       = {ss_fapai_offline,     ss_fapai_timeout,    10},
        PANEL       = {ss_panel_offline,	 ss_panel_timeout,    13},
        KANPAI      = {ss_kanpai_offline,	 ss_kanpai_timeout,   10},
		WAIT 		= {ss_wait_offline, 	 NULL_FUNC,			  0},
        WATCH 		= {ss_watch_offline, 	 NULL_FUNC,			  0},
	}))
    hall.desk.register_site_state_change(ss_onstatechange)
end

------------------------------收发协议相关函数--------------------------------------------
zysz.init_map = function()
    cmdGameHandler = {
	    ["ZYSZST"] = onZYSZRecvGameStart,		--用户请求开始
		["ZYSZFO"] = onZYSZRecvFapaiOver,		--收到发牌结束
	    ["ZYSZCC"] = onZYSZRecvClickCaiChi,		--用户点击彩池
	    ["ZYSZFQ"] = onZYSZRecvLose,			    --用户放弃
	    ["ZYSZBP"] = onZYSZRecvKaiPai,		 	--用户开牌(比牌)
	    ["ZYSZKP"] = onZYSZRecvKanpai,			--用户看牌
	    ["ZYSZGZ"] = OnZYSZRecvGenZhu,			--用户跟注
        ["ZYSZJZ"] = OnZYSZRecvJiaZhu,			--用户加注
        ["ZYSZOG"] = OnZYSZRecvForceOutGame,    --用户强制退出游戏
        
		--为了用原来的代码执行信息
		["ZYSZSNCC"] = net_broadcast_caichi_sumgold, --发送玩家加注后彩池信息
		["ZYSZCTIF"] = net_broadcast_caichi_info,--发送彩池详细信息
        ["ZYSZCCOK"] = net_send_telluser_getprize,--告诉所有人 有人彩池中奖了
	}
end

zysz.init_state();
zysz.init_map();

