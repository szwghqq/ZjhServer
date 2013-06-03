--处理所有从队列->逻辑处理， 以及 逻辑处理->队列 间的程序
--trace = netbuf.trace
trace("svrgamesohainit.lua loaded!!!")
dofile("games/tex/logic/rule.lua")
dofile("games/tex/tex.gift.lua")
dofile("games/tex/tex.safebox.lua")
dofile("games/tex/tex.achievement.lua")
dofile("games/tex/tex.suanpaiqi.lua")
dofile("games/tex/tex.gameprops.lua")
dofile("games/tex/tex.speaker.lua")
dofile("games/tex/tex.userdiy.lua")
dofile("games/tex/tex.ipprotect.lua")
dofile("games/tex/tex.channelyw.lua")
dofile("games/tex/tex.dhome.lua")
--dofile("games/modules/duokai/duokai.lua")  --注意多开模块一定要在所有模块的最后的加载
--dofile("games/modules/duokai/duokai_data_merge.lua")
--dofile("games/tex/tex.match.lua")
--math.randomseed(os.clock())
--math.randomseed(math.random(1, 65536)+os.clock())

--tex.pokechar 应该在 preinit 中

tex.name = "tex"
tex.table = "user_tex_info"
gamepkg = tex

tTexSqlTemplete =
{
    --插入结算日志
    insertLogRound = "call sp_tex_insert_log_round(%s)",
}
tTexSqlTemplete = newStrongTable(tTexSqlTemplete)

-----------------------------------
--未准备-超时
function ss_notready_timeout(userinfo)
	local deskno, siteno = userinfo.desk, userinfo.site
	if(not deskno or not siteno) then return end
	local deskinfo = desklist[deskno]
	hall.desk.set_site_state(deskno, siteno, SITE_STATE.READYWAIT)
	
	if deskmgr.get_game_state(deskno) == gameflag.notstart then
		trystartgame(deskno) 
	end
end

--未准备-离线
function ss_notready_offline(userinfo)
	local deskno, siteno = userinfo.desk, userinfo.site
	local deskinfo = desklist[deskno]
	if(deskinfo.desktype == g_DeskType.tournament or 
       deskinfo.desktype == g_DeskType.channel_tournament or 
       deskinfo.desktype == g_DeskType.match)then
		hall.desk.set_site_state(deskno, siteno, SITE_STATE.LEAVE)
		if deskmgr.get_game_state(deskno) == gameflag.notstart then
			trystartgame(deskno) 
		end
	else
		hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
	end
end

--准备后开始前-离线
function ss_readywait_offline(userinfo)
	local deskno, siteno = userinfo.desk, userinfo.site
	local deskinfo = desklist[deskno]
	if(deskinfo.desktype == g_DeskType.tournament or 
       deskinfo.desktype == g_DeskType.channel_tournament or 
       deskinfo.desktype == g_DeskType.match)then
		hall.desk.set_site_state(deskno, siteno, SITE_STATE.LEAVE)
		if deskmgr.get_game_state(deskno) == gameflag.notstart then
			trystartgame(deskno) 
		end
	else
		hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
	end
end

--面板-离线
function ss_panel_offline(userinfo)
	local deskno = userinfo.desk
	local siteno = userinfo.site
	if(not deskno or not siteno) then return end
	local deskinfo = desklist[deskno]

    if(deskinfo.desktype == g_DeskType.tournament or 
       deskinfo.desktype == g_DeskType.channel_tournament or
       deskinfo.desktype == g_DeskType.match)then
        --自动放弃
    	letusergiveup(userinfo)
        hall.desk.set_site_state(deskno, siteno, SITE_STATE.LEAVE)
   --[[
    elseif(deskinfo.desktype == g_DeskType.match) then
        auto_chu_pai(userinfo);
    --]]
    else
        hall.desk.set_site_state(deskno, siteno, NULL_STATE)
    end
end

--面板-超时
function ss_panel_timeout(userinfo)
	local deskno = userinfo.desk
	local siteno = userinfo.site
	if(not deskno or not siteno) then return end
	local deskinfo = desklist[deskno]
	
	--自动放弃
	letusergiveup(userinfo)
	local deskinfo =  desklist[deskno]
	--非竞技场，放弃之后自动站起
	if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match) then
		--站起并加入观战
		doStandUpAndWatch(userinfo)
		net_sendbuychouma(userinfo, deskno);
	end
end

--等待-离线
function ss_wait_offline(userinfo)
	local deskno = userinfo.desk
	local siteno = userinfo.site
	local deskinfo = desklist[deskno]
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament)then
		hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.LEAVE)
	else
		hall.desk.set_site_state(deskno, siteno, NULL_STATE)
	end
end

--离线超时
function ss_leave_timeout(userinfo)
	local deskno = userinfo.desk
	local siteno = userinfo.site
	local deskinfo = desklist[deskno]
	--只有比赛场才需要这样踢走玩家，其他情况下玩家会在离线的瞬间被踢走
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament)then
		hall.desk.set_site_state(deskno, siteno, NULL_STATE)
		tex.forceGameOverUser(userinfo)

		DoKickUserOnNotGame(userinfo.key, false)
	end
end

--得到抽水
function get_specal_choushui(deskinfo,userinfo)
	local choushui = deskinfo.specal_choushui;
	local vip_level = 0
    if viplib then
        vip_level = viplib.get_vip_level(userinfo)
    end
	
	if(deskinfo.smallbet==1000)then
		if(vip_level<2)then
			choushui=500
		end
	elseif(deskinfo.smallbet==2000)then
		if(vip_level<2)then
			choushui=900
		end
	elseif(deskinfo.smallbet==5000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=3500
		elseif(vip_level<=1)then
			choushui=4000
		end
	elseif(deskinfo.smallbet==10000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=6500
		elseif(vip_level<=1)then
			choushui=7000
		end	
	elseif(deskinfo.smallbet==20000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=8500
		elseif(vip_level<=1)then
			choushui=9000
		end
	elseif(deskinfo.smallbet==25000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=11000
		elseif(vip_level<=1)then
			choushui=12000
		end		
	elseif(deskinfo.smallbet==40000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=17000
		elseif(vip_level<=1)then
			choushui=18000
		end	
	elseif(deskinfo.smallbet==50000)then
		if(vip_level>=2 and vip_level<=3)then
			choushui=26000
		elseif(vip_level<=1)then
			choushui=27000
		end										
	end
	return choushui
	
end

--买筹码-离线
function ss_buychouma_offline(userinfo)
	local deskno, siteno = userinfo.desk, userinfo.site
	if not deskno or not siteno then return end
	local deskinfo = desklist[deskno]
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament or deskinfo.desktype == g_DeskType.match)then
		return
	else
		hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
		doStandUpAndWatch(userinfo)
		DoKickUserOnNotGame(userinfo.key, false)
	end
end

--买筹码-超时
function ss_buychouma_timeout(userinfo)
	local deskno, siteno = userinfo.desk, userinfo.site
	if not deskno or not siteno then return end
	local deskinfo = desklist[deskno]
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament or deskinfo.desktype == g_DeskType.match)then
		return
	else
		hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
		doStandUpAndWatch(userinfo)
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

function doStandUpAndWatch(userinfo,retcode)
	if not userinfo or not userinfo.desk or not userinfo.site then return end
	local deskno = userinfo.desk
	local siteno = userinfo.site


	--踢人(使其站起)
	hall.desk.set_site_state(deskno, siteno, NULL_STATE)
	--TraceError("doStandUpAndWatch:::::ret:"..retcode);
	doUserStandup(userinfo.key, false,retcode)
	--变为观战
	DoUserWatch(deskno, userinfo,retcode)
end
---------------------------

-- 实现状态翻译接口
tex.TransSiteStateValue = function(state)
	local state_value
	if state == NULL_STATE then
		state_value = SITE_UI_VALUE.NULL
	elseif state == SITE_STATE.NOTREADY then
		state_value = SITE_UI_VALUE.NOTREADY
	elseif state == SITE_STATE.READYWAIT then
		state_value = SITE_UI_VALUE.READY
	elseif (state == SITE_STATE.PANEL) or
			(state == SITE_STATE.WAIT) or
			(state == SITE_STATE.LEAVE) then
		state_value = SITE_UI_VALUE.PLAYING
	else
		state_value = SITE_UI_VALUE.NULL
	end

	return state_value
end

--用户坐下
tex.AfterUserSitDown = function(userid, desk, site, sit_type)  --用户坐下后
	trace("有人坐下！！！！`````" .. "desk=" .. desk .. "site=" .. site)
	local userinfo = deskmgr.getsiteuser(desk, site) 
	if not userinfo then return end
	local deskinfo = desklist[desk]

	if deskinfo.playercount == 1 then
		deskmgr.initdeskdata(desk)
	end
	if (sit_type == g_sittype.relogin) then
		deskinfo.gamedata.rounddata.sitecount[site] = 0  --设置此座位的人玩过的盘数为0
	end
	if (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and 
		userinfo.gamescore < deskinfo.at_least_gold + deskinfo.specal_choushui then
		--站起并观战
		doStandUpAndWatch(userinfo)
	end

	if (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		--比赛场的都是虚拟筹码
		deskinfo.betgold = 0
	end

	--普通坐下或排队，不考虑断线重连
	if(sit_type == g_sittype.normal or sit_type == g_sittype.queue) then
		if hall.desk.get_site_state(desk, site) ~= NULL_STATE then
			TraceError("刚坐下状态必须为NULL_STATE")
		end

		--排队进来的自动买筹码
		if(sit_type == g_sittype.queue) then
			local retarr = tex.getdeskdefaultchouma(userinfo, desk)
			local defaultchouma = retarr.defaultchouma or 0
			dobuychouma(userinfo, desk, site, defaultchouma)
		end

		--坐下时，如果筹码不够，则需要发送购买筹码提示
		local user_chouma = userinfo.chouma or 0
		local at_least_gold = deskinfo.at_least_gold
		local at_most_gold = deskinfo.at_most_gold
		if (deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) and user_chouma < deskinfo.at_least_gold then
			net_sendbuychouma(userinfo, desk);
		end

		--------------成就系统采集-----------------
		if userinfo.friends then
			if userinfo.extra_info["F06"] >= 20 then
				achievelib.updateuserachieveinfo(userinfo,1001);--哥俩好
			end
			if userinfo.extra_info["F06"] >= 50 then
				achievelib.updateuserachieveinfo(userinfo,2005);--人气上升
			end
			if userinfo.extra_info["F06"] >= 100 then
				achievelib.updateuserachieveinfo(userinfo,3004);--桃李满天下
			end
		end

		achievelib.updateuserachieveinfo(userinfo,1005);--欢迎光临

		if userinfo.chouma >= 1000000 then
			achievelib.updateuserachieveinfo(userinfo,3008)--百万富豪
		end
		-------------------------------------------

		--做个判断，如果坐下时游戏已经开，就设置为等待
		local gamestate = deskmgr.get_game_state(desk)
		if gamestate == gameflag.notstart then
			hall.desk.set_site_state(desk, site, SITE_STATE.READYWAIT)
        else
            if(hall.desk.get_site_state(desk, site) ~= SITE_STATE.NOTREADY)then
			    hall.desk.set_site_state(desk, site, SITE_STATE.NOTREADY)
            end
		end
	end
end

--用户坐下的消息包发送之后
tex.AfterUserSitDownMessage = function(userid, desk, site, bRelogin)  --用户坐下后
	--TraceError("AfterUserSitDownMessage "..bRelogin)
	if(not desk or not site) then return end
	net_broadcast_deskinfo(desk)
	local userinfo = deskmgr.getsiteuser(desk, site) 
	if not userinfo then return end
	local gamestate = deskmgr.get_game_state(desk)
	net_broadcastdesk_goldchange(userinfo)
	net_broadcastdesk_playerinfo(desk)

	if gamestate == gameflag.notstart then
		letusergamestart(userinfo)
	end

	--每天第一次坐下送经验咯
	if(userinfo.gameInfo.todayexp and userinfo.gameInfo.todayexp == 0) then
		local level = usermgr.getlevel(userinfo)
		if(level >= 3 and level < room.cfg.MaxLevel) then
			--TraceError("每天第一次坐下送经验咯")
			local addexp = level * 2
			--贈送的經驗為 lv * 2 后四捨五入
			addexp = math.floor(addexp / 10 + 0.5) * 10	
			usermgr.addexp(userinfo.userId, level, addexp, g_ExpType.firstsit, groupinfo.groupid)
			net_send_daygiveexp(userinfo, addexp)
			local sendmsg = format("恭喜获得每天经验红利[%d]，该功能仅3等级以上玩家享有!", addexp)
			--net_sendsystemmsg(userinfo, tex.msgtype.firstsit, sendmsg)
			--TraceError(sendmsg)
		end
	end
	if (tex_buf_lib) then
		xpcall( function() tex_buf_lib.on_after_user_sitdown(userinfo, desk, site) end, throw)
	end
end

--是否游戏进行中
tex.CanEnterGameGroup = function(szPlayingGroupName, nPlayingGroupId, nScore)
    --判断是否有游戏进行中
    if nPlayingGroupId ~= nil and nPlayingGroupId ~= 0 then
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
tex.CanUserQueue = function(userKey, deskno)
	return 1, 0
end

--判断用户在游戏中能不能买得起某种价格的物品
tex.CanAfford = function(userinfo, paygold, pay_limit)
	local gold = get_canuse_gold(userinfo)--userinfo.gamescore
	local deskno = userinfo.desk
	local siteno = userinfo.site

	if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then
        --[[
		if deskno and siteno then 
			local min = pay_limit or groupinfo.pay_limit 
			local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
			if userinfo.chouma and userinfo.chouma > 0 then
				min = userinfo.chouma
			else
				if sitedata then
					min = sitedata.gold + sitedata.betgold
				end
			end
			gold = gold - min
		end
        --]]
	else
		--竞技场必须判断游戏是否开始，没开始而又坐下了就要保留报名费
		local gamestart = tex.getGameStart(deskno)
		local deskinfo = desklist[deskno]
		if deskno and siteno and not gamestart then
			gold = gold - deskinfo.at_least_gold - deskinfo.specal_choushui
		end
	end

	return gold - paygold >= 0
end

tex.getGameStart = function(deskno,siteno)
	local isStart  = false
	local deskinfo = desklist[deskno]
	if not deskinfo then return false end
    if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
        --竞技场只有比赛结束之后才算没有开始
        local deskdata = deskmgr.getdeskdata(deskno)
        isStart = deskdata.rounddata.roundcount > 0
    else
    	local gamestate = deskmgr.get_game_state(deskno)
    	if gamestate ~= gameflag.notstart then
    		isStart = true
    		if(siteno and siteno > 0) then
    			local sitedata = deskmgr.getsitedata(deskno, siteno)
    			if(sitedata.isinround ~= 1 or sitedata.islose == 1) then
    				isStart = false
    			end
    		end
        end
    end
	
	return isStart
end

tex.forceGameOverUser = function(userinfo)
	if not userinfo then return end
	douserforceout(userinfo)
end

tex.OnUserStandup = function(userid, desk, site)
	local userinfo = usermgr.GetUserById(userid)
	local sitedata = deskmgr.getsitedata(desk, site)
	local deskinfo = desklist[desk]
	deskinfo.gamedata.rounddata.sitecount[site] = 0  --设置此座位的人玩过的盘数为0
    sitedata.gold = 0
	--有可能这时候玩家已经离线
    if(not userinfo) then
        return
    end


    --记录本桌最后的筹码，购买时使用此默认值
	tex.setdeskdefaultchouma(userinfo, desk)
    --筹码重置为0
	userinfo.chouma = 0
	--如果没开始游戏
	if tex.getGameStart(desk, site) then
		if userinfo and sitedata.isinround == 1 and sitedata.islose == 0 then
			--------------------连胜取消-----------------------------------
			xpcall(function()
				----------------------------铜成就-----------------------------
				achievelib.updateuserachieveinfo(userinfo,1016,1);--两连胜
	
				---------------------------银成就-------------------------------
				achievelib.updateuserachieveinfo(userinfo,2011,1);--三连胜
	
				achievelib.updateuserachieveinfo(userinfo,2022,1);--5连胜
	
				---------------------------金成就-------------------------------
				achievelib.updateuserachieveinfo(userinfo,3016,1);--10连胜
	
				achievelib.updateuserachieveinfo(userinfo,3026,1);--15连胜
				
				----------------------------好友连续取消------------------
				achievelib.updateuserachieveinfo(userinfo,2015,1);--知己

				achievelib.updateuserachieveinfo(userinfo,3009,1);--死党
			end,throw)
			-----------------------------------------------------
			if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match then
				letusergiveup(userinfo)
			end
		end
	end
end

--用户站起
tex.AfterOnUserStandup = function(userid, desk, site)
    
	local userinfo = usermgr.GetUserById(userid)
	if not userinfo then return end
	local deskinfo = desklist[desk]
	if not deskinfo then return end

	if deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament then
		--比赛场的都是虚拟筹码
		deskinfo.betgold = 0
	end
    if(userinfo.gameinfo==nil)then
        userinfo.gameinfo={}
    end
    userinfo.gameinfo.is_auto_buy=0
    userinfo.gameinfo.is_auto_addmoney=0

	--清理用户状态
	hall.desk.set_site_state(desk, site, NULL_STATE)

	--如果没开始游戏
	if deskmgr.get_game_state(desk) == gameflag.notstart then
		if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then
			if deskmgr.get_game_state(desk) ~= gameflag.notstart then 
				trystartgame(desk)
			end
		end
	end
	if (tex_buf_lib) then
		xpcall(function() tex_buf_lib.on_after_user_standup(userinfo, desk, site) end, throw)
    end

    --玩家在站起时，要把算牌器开关置为关闭状态防止误扣算牌器费用
    if(userinfo.gameInfo.suan)then
        userinfo.gameInfo.suan.suan_switch=0
        userinfo.gameInfo.suan.is_use_suan=0
    end
	net_broadcast_deskinfo(desk)
end

--收到大厅某用户临时离线的消息，通常是用户进程被意外中止，或者是一段时间没有响应
tex.OnTempOffline = function(userinfo)
	--TraceError("OnTempOffline!")
	auto_chu_pai(userinfo);
end

function auto_chu_pai(userinfo)
    local deskno = userinfo.desk
	local siteno = userinfo.site
	if not deskno or not siteno then return end

    --如果轮到自己，则自动看牌或弃牌
    local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
	if deskmgr.get_game_state(userinfo.desk) ~= gameflag.notstart then
        local result = do_bu_xia_zhu(userinfo);
		if result == nil or result == 0 and userinfo and sitedata.isinround == 1 and sitedata.islose == 0 then
			letusergiveup(userinfo)
		end
	end
end

tex.AfterUserLogin = function(userinfo)
    --TraceError("AfterUserLogin!")	
end

--玩家刚进入观战时的呈现 userinfo：观战人 		desk：被观战桌子
tex.AfterUserWatch = function(deskno, userinfo)
	if not deskno or not userinfo then return end
	--TraceError(format("玩家[%d]进入桌子[%d]观战，",userinfo.userId, deskno))
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		net_broadcastdesk_goldchange(player.userinfo)
	end
	local deskdata = deskmgr.getdeskdata(deskno)
	local deskpokes = deskdata.deskpokes
	local gold = 0
	local betgold = 0
	local sitepokes = {}
	local mybean = userinfo.gamescore
	OnSendDeskInfo(userinfo, deskno)    
	net_send_resoredesk(userinfo)    
	net_broadcastdesk_playerinfo(deskno)
	--刷新彩池信息
	OnSendDeskPoolsInfo(userinfo, deskdata.pools)
    --[[
    --发送正在结算的消息，用于结算时有用户进入桌子出现正在结算的提示
    local jiesuanwait = deskdata.jiesuanwait
    if (jiesuanwait ~= nil and jiesuanwait.startplan ~= nil) then
        --TraceError("jiesuanwait.startplan.getdelaytime:"..jiesuanwait.startplan.getlefttime())
        netlib.send(
                function(buf)
                    buf:writeString("TXJSWAIT")
                    buf:writeInt(jiesuanwait.startplan.getlefttime() or -1)
                end,userinfo.ip,userinfo.port)
    end
    --]]
end

--判断桌子是否可以观战
tex.CanWatch = function(userinfo, deskno)
	if not userinfo then return fasle end
	local deskinfo = desklist[deskno]
	if not deskinfo then return false end

	local bvalid = true
	--TODO:加入自定义的条件
    return bvalid
end

--最小破产送钱金币
tex.GetMinGold = function()
	return groupinfo.min_gold
	--return 200
end

--破产送钱金币数
tex.GetAddGold = function()
	return groupinfo.add_gold
	--return 200
end

--取消排队时
tex.OnCancelQueue = function(userinfo)
	userinfo.chouma = 0
end

--取消排队时
tex.OnSitDownFailed = function(userinfo)
	userinfo.chouma = 0
end
------------------网络收包--------------------------------------------------------------
--收到游戏开始
function onrecvgamestart(buf)
	--TraceError("onrecvgamestart()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; 
	if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;
	local deskno = userinfo.desk
	local siteno = userinfo.site

    --判断合法性
	if hall.desk.get_site_state(userinfo.desk, userinfo.site) ~= SITE_STATE.NOTREADY then return end;
	local deskinfo = desklist[userinfo.desk]
    if(deskinfo.desktype ~= g_DeskType.match) then
    	if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) then
    		if not userinfo.chouma or userinfo.chouma < deskinfo.largebet + deskinfo.specal_choushui + 1 then
    			--如果出现不够筹码的玩家，就让其弹出购买窗
    			net_sendbuychouma(userinfo, deskno)
    			return
    		end
    	else
    		if not userinfo.chouma or userinfo.chouma < deskinfo.largebet then
    			--站起并加入观战
    			doStandUpAndWatch(userinfo)
    			return
    		end
        end
    end

	letusergamestart(userinfo)
end

--让用户开始
function letusergamestart(userinfo)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.READYWAIT)	

	--广播给其他玩家说此人点开始了
	net_broadcastdesk_ready(userinfo.desk, userinfo.site); 

	--广播桌面状态
	net_broadcastdesk_playerinfo(userinfo.desk);

	--尝试开始游戏
	trystartgame(userinfo.desk)
end

--收到请求个人extrainfo和achieveinfo
function onrecvgetextrainfo_achieveinfo(buf)
	--TraceError("onrecvgetextrainfo_achieveinfo()")
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 
	local userid = buf:readInt()
    if (duokai_lib and duokai_lib.is_sub_user(userid) == 1) then
        userid = duokai_lib.get_parent_id(userid)
    end    
	local request_userinfo = usermgr.GetUserById(userid);
    if(not request_userinfo) then
		--通知客户次玩家不在线
		local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
		local msg = format("个人信息获取失败，此玩家目前不在线!")
		OnSendServerMessage(userinfo, msgtype, _U(msg))
		return
	end
	net_send_user_extrainfo_achieveinfo(userinfo, request_userinfo)
end

--收到请求个人extrainfo
function onrecvgetextrainfo(buf)
	--TraceError("onrecvgetextrainfo()")
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 
	local userid = buf:readInt()
    if (duokai_lib and duokai_lib.is_sub_user(userid) == 1) then
        userid = duokai_lib.get_parent_id(userid)
    end    
	local request_userinfo = usermgr.GetUserById(userid)
	if(not request_userinfo) then
		--通知客户此玩家不在线
		local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
		local msg = format("个人信息获取失败，此玩家目前不在线!")
		OnSendServerMessage(userinfo, msgtype, _U(msg))
		return 
	end
	net_send_user_extrainfo(userinfo, request_userinfo)
end


--收到请求论坛验证串
function onrecvgetbbsurl(buf)
	--TraceError("onrecvgetbbsurl()")
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 
	local sys_time = os.time()
	local password = "11"
	local bbs_auth = "username="..userinfo["userName"]
	bbs_auth = bbs_auth .. '&password='..password
	bbs_auth = bbs_auth .. '&site_no='..userinfo["nRegSiteNo"]
	bbs_auth = bbs_auth .. '&time='..sys_time
	bbs_auth = bbs_auth .. '&key='..string.md5(userinfo["nRegSiteNo"]..userinfo["userName"]..password..sys_time..'97CfiDV3-92F2-ZKDd-FE8X-58X4ZAA3389')
	net_send_BBS_URL(userinfo, bbs_auth)
end

--收到请求今日明细
function onrecvtodaydetail(buf)
	--TraceError("onrecvtodaydetail()");
	do return end; --客户端自己保存，服务器不处理
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 

	local sqltmplet = "select * from user_tex_todaydetail where userid=%d and Date(sys_time)=Date(now()) order by sys_time desc;";
	local sql = format(sqltmplet, userinfo.userId);
	dblib.execute(sql,
		function(dt)
			net_send_todaydetail(userinfo, dt);
		end);
end

--让玩家强退出游戏
function douserforceout(userinfo)
	if (userinfo == nil) then
		return
	end

	local deskno = userinfo.desk
	local siteno = userinfo.site
	--pre_process_back_to_hall(userinfo);
	-- [[
	if (deskno == nil) then
        return
    end


    if (siteno == nil) then
	    DoUserExitWatch(userinfo) 
        net_kickuser(userinfo)
		return
    end
	local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
	if deskmgr.get_game_state(userinfo.desk) ~= gameflag.notstart then
		if userinfo and sitedata.isinround == 1 and sitedata.islose == 0 then
			letusergiveup(userinfo)
		end
	end

    
    --站起并踢走
	hall.desk.set_site_state(deskno, siteno, NULL_STATE)
	doUserStandup(userinfo.key, false)
	DoUserExitWatch(userinfo) 
	net_kickuser(userinfo)
	--]]

	local deskinfo = desklist[deskno]
	local deskdata = deskmgr.getdeskdata(deskno)
	--如果是比赛场，要判断剩下的人是否分出名次
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		--只剩下一个玩家，自然是第一名
        if(deskinfo.playercount == 1 and deskdata.rounddata.roundcount > 0) then
			--游戏结束
			deskmgr.set_game_state(deskno, gameflag.notstart)
			for _, player in pairs(deskmgr.getplayers(deskno)) do
				if player.userinfo then
					set_lost_or_prize(deskno, {player.siteno})
					break
				end
			end
        end
    end
end

--点放弃
function onrecvgiveup(buf)
	--TraceError("onrecvgiveup()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end;
	if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;

	--如果没开始游戏
	local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
	if deskmgr.get_game_state(userinfo.desk) ~= gameflag.notstart then
		if userinfo and sitedata.isinround == 1 and sitedata.islose == 0 then
			letusergiveup(userinfo)
		end
	end
end

--让用户放弃
function letusergiveup(userinfo)
	--TraceError(format("site:%d, ID[%d]开始放弃", userinfo.site, userinfo.userId))
	if(not userinfo.desk or not userinfo.site) then
		--TraceError(format("都没有坐下怎么放弃？deskno[%s],siteno[%s]",tostring(userinfo.desk), tostring(userinfo.site)))
		return
	end

	if deskmgr.get_game_state(userinfo.desk) == gameflag.notstart then
		--TraceError("游戏还没开始怎么能放弃??"..debug.traceback())
	end

    local oldstate = hall.desk.get_site_state(userinfo.desk, userinfo.site)
	if oldstate ~= SITE_STATE.LEAVE then
		hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)
	end

	local deskdata = deskmgr.getdeskdata(userinfo.desk)
	local deskinfo = desklist[userinfo.desk]
    local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
	if(sitedata.islose == 1) then return end
	--用户放弃
	sitedata.islose = 1

	--插入结算的数据
	local userid = userinfo.userId
	local betgold = -sitedata.betgold
	local nSid = userinfo.nSid
	local curgold = userinfo.gamescore
	local level = usermgr.getlevel(userinfo)
	local joinfee = deskinfo.at_least_gold
	local choushui = get_specal_choushui(deskinfo,userinfo)
	local safegold = userinfo.safegold or 0
    local channel_id = userinfo.channel_id or -1;
	
    if(deskinfo.desktype ~= g_DeskType.match) then
        if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) then
            --+钱 
            usermgr.addgold(userinfo.userId, -sitedata.betgold, 0, g_GoldType.normalwinlost, -1, 1)
    		record_today_detail(userinfo, -sitedata.betgold)
    		--两个人玩，抽水加倍
    		if(deskinfo.playercount <= 2) then
    			choushui = choushui * 2
    		end
        else
            userinfo.tour_point = userinfo.tour_point - sitedata.betgold
    		--比赛场只在比赛开始的第一局收取报名费和抽水
            if(deskdata.rounddata.roundcount > 1) then
    			joinfee = 0
    			choushui = 0
    		end
        end
    end


	local user_level = usermgr.getlevel(userinfo)
    local addexp = 0
	if user_level < 2 then
        addexp = 1
		usermgr.addexp(userinfo.userId, user_level, 1, g_ExpType.lost, groupinfo.groupid);
	end
	if (duokai_lib and duokai_lib.is_sub_user(userid) == 1) then
		sitedata.logsql = format("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d", 
							 duokai_lib.get_parent_id(userid), betgold, addexp, nSid, curgold, level, joinfee, choushui, safegold, channel_id);--增加频道id
	else
		sitedata.logsql = format("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d", 
							 userid, betgold, addexp, nSid, curgold, level, joinfee, choushui, safegold, channel_id);--增加频道id
	end
	
	--通知大厅金币刷新
	--net_send_user_new_gold(userinfo, userinfo.gamescore)
    -----------------------------------------------
	--更新下次买注金额 todo cw 放弃的人不够钱需要买筹码
    --TODO:这里是否多扣了，下注时本身已经扣过钱
	userinfo.chouma = sitedata.gold -- - sitedata.betgold
	
	--通知客户端
	net_broadcastdesk_giveup(userinfo.desk, userinfo.site)

	--看还剩下多少人在继续
	local aliveplayers = 0
	for siteno, sitedata in pairs(deskmgr.getallsitedata(userinfo.desk)) do
		if sitedata.isinround == 1 and sitedata.islose == 0 then
			aliveplayers = aliveplayers + 1
		end
	end

	--下一个人出面板
	local nextsite = deskmgr.getnextsite(userinfo.desk, userinfo.site)
	if not nextsite then return end
	local deskno = userinfo.desk
	local siteno = nextsite

	if userinfo.site == deskdata.leadersite then
		deskdata.leadersite = siteno		--领牌人放弃，换下个人吧
	end
	--TraceError(format("site:%d, ID[%d]放弃后，还有[%d]个人在玩", userinfo.site, userinfo.userId, aliveplayers))
	
	--只剩下一个人将直接导致结算
	if aliveplayers == 1 then
		jiesuan(deskno, false)    
		return
	end

	--如果不是面板状态下放弃就不必自动下一个人
	--TraceError(format("oldstate = [%s]", tostring(oldstate)))
	if oldstate ~= SITE_STATE.PANEL and oldstate ~= SITE_STATE.LEAVE then return end;

	process_site(deskno, siteno)
end

function process_dizhu(deskno, gold)
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local user_info = player.userinfo;
		if(user_info and user_info.desk and user_info.site) then
			add_bet_gold(user_info, gold, 7);
		end
	end
end

function add_bet_gold(user_info, gold, ntype)
    local deskinfo = desklist[user_info.desk];
	local deskdata, sitedata = deskmgr.getdeskdata(user_info.desk), deskmgr.getsitedata(user_info.desk, user_info.site)
    --TraceError(user_info.userId..'sitedata.betgold'..sitedata.betgold.." gold"..gold);
    sitedata.betgold = sitedata.betgold + gold
    deskinfo.betgold = deskinfo.betgold + gold
    deskdata.totalbetgold = deskdata.totalbetgold + gold
    deskdata.roundaddgold = gold - sitedata.panelrule.gengold			--下次加注的最小值
    if(deskdata.maxbetgold < sitedata.betgold) then
        deskdata.maxbetgold = sitedata.betgold
    end

    net_broadcastdesk_xiazhu(user_info.desk, user_info.site, ntype)
    net_sendmybean(user_info, user_info.gamescore);			--自己的德州豆
    --TraceError(sitedata.betgold);

    useraddviewgold(user_info, -gold, true);
end

--点下注/加注
function onrecvxiazhu(buf)
	local gold, ntype = buf:readInt(), buf:readByte()
	trace("onrecvxiazhu()")	
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;
	local deskdata, sitedata = deskmgr.getdeskdata(userinfo.desk), deskmgr.getsitedata(userinfo.desk, userinfo.site)
	--判断合法性	
	if hall.desk.get_site_state(userinfo.desk, userinfo.site) ~= SITE_STATE.PANEL then return end;
	if sitedata.panelrule.jia + sitedata.panelrule.xiazhu ~= 1 then return end

	local oldgold = gold
	gold = gold - (sitedata.betgold - sitedata.roundbet)		--gold到此转换为实际要出的钱数

	--最多只能下成跟桌面第二大的人一样
	if gold > sitedata.panelrule.max then
		--TraceError("超过下注范围>")
		gold = sitedata.panelrule.max
	end
	if gold < sitedata.panelrule.min then
		--TraceError("超过下注范围<")
		gold = sitedata.panelrule.min
    end

    local deskinfo = desklist[userinfo.desk]
    --限注处理开始
    if(deskinfo.limit ~= nil and deskinfo.limit == 1) then
        local smallbet, largebet = getLimitXiazhu(deskinfo, deskdata, sitedata);
        gold = smallbet; 
    end
    --限注处理结束

	if (ntype ~= 1 and ntype ~= 2) then return end

	--可能钱拿去购买表情了
	ASSERT(gold > 0 or (gold == 0 and sitedata.gold == 0) ,"下注为"..gold.." and sitedata.gold ="..sitedata.gold.."????")

	--TraceError(userinfo.nick .. " 实际加注：" .. gold .. " 要加到：" .. (gold + sitedata.betgold - sitedata.roundbet))
	--开始下注/加注
	sitedata.betgold = sitedata.betgold + gold
	deskinfo.betgold = deskinfo.betgold + gold
	deskdata.totalbetgold = deskdata.totalbetgold + gold
	deskdata.roundaddgold = gold - sitedata.panelrule.gengold			--下次加注的最小值
	sitedata.isbet = 1
	deskdata.maxbetgold = sitedata.betgold
    deskdata.rounddata.xiazhucount = deskdata.rounddata.xiazhucount + 1;--下注次数统计

	--加到低等於全下
	if gold == sitedata.panelrule.max then
		sitedata.isallin = 1
		ntype = 4
	end

    local can_use_gold = get_canuse_gold(userinfo, 1);
	if(sitedata.betgold > can_use_gold and deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match) then
		TraceError(format("异常情况，下注数大于身上的筹码...oldgold[%d], sitedata.betgold[%d], userinfo.gamescore[%d]", oldgold, sitedata.betgold, can_use_gold))
		sitedata.betgold = can_use_gold
	end

	--通知客户端
	net_broadcastdesk_xiazhu(userinfo.desk, userinfo.site, ntype)
	net_sendmybean(userinfo, userinfo.gamescore);			--自己的德州豆
	useraddviewgold(userinfo, -gold, true)

	hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)

	--下一个人出面板
	local next_site = deskmgr.getnextsite(userinfo.desk, userinfo.site)
	if(next_site ~= nil) then
		process_site(userinfo.desk, deskmgr.getnextsite(userinfo.desk, userinfo.site))
	else
		jiesuan(userinfo.desk, false)
	end
end

--点跟注
function onrecvgenzhu(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; 
	if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;
	local deskdata, sitedata = deskmgr.getdeskdata(userinfo.desk), deskmgr.getsitedata(userinfo.desk, userinfo.site)
	--判断合法性
	if hall.desk.get_site_state(userinfo.desk, userinfo.site) ~= SITE_STATE.PANEL then return end;
	if sitedata.panelrule.gen ~= 1 then return end	
	local notifytype = 5
	--开始跟注（全下）
	local gold = deskdata.maxbetgold  - sitedata.betgold		--需要跟的钱
	ASSERT(gold > 0)
	if gold >= sitedata.gold then	--没那么多钱跟，那就全下吧
		gold = sitedata.gold
		sitedata.isallin = 1
		deskdata.maxbetgold = math.max(sitedata.betgold + gold, deskdata.maxbetgold)
		notifytype = 4
	end
	sitedata.betgold = sitedata.betgold + gold
	local deskinfo = desklist[userinfo.desk]
	deskinfo.betgold = deskinfo.betgold + gold
	deskdata.totalbetgold = deskdata.totalbetgold + gold
	sitedata.isbet = 1
    local can_use_gold = get_canuse_gold(userinfo, 1);

	if(sitedata.betgold > can_use_gold and deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match) then
		TraceError(format("异常情况，跟注数大于身上的筹码...gold[%d], sitedata.betgold[%d], userinfo.gamescore[%d]", gold, sitedata.betgold, can_use_gold))
		sitedata.betgold = can_use_gold
	end
	
	--通知客户端
	net_broadcastdesk_xiazhu(userinfo.desk, userinfo.site, notifytype)
	net_sendmybean(userinfo, userinfo.gamescore);			--自己的德州豆
	useraddviewgold(userinfo, -gold, true)

	hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)

	--下一个人出面板
	local next_site = deskmgr.getnextsite(userinfo.desk, userinfo.site)
	if(next_site ~= nil) then
		process_site(userinfo.desk, deskmgr.getnextsite(userinfo.desk, userinfo.site))
	else
		jiesuan(userinfo.desk, false)
	end
end

function do_bu_xia_zhu(userinfo)
    if not userinfo then return 0 end; 
	if not userinfo.desk or userinfo.desk <= 0 then return 0 end;
	if not userinfo.site or userinfo.site <= 0 then return 0 end;

	local deskdata, sitedata = deskmgr.getdeskdata(userinfo.desk), deskmgr.getsitedata(userinfo.desk, userinfo.site)
	--判断合法性
	if hall.desk.get_site_state(userinfo.desk, userinfo.site) ~= SITE_STATE.PANEL then return 0 end;
	if sitedata.panelrule.buxiazhu ~= 1 then return 0 end
	
	--通知客户端
	net_broadcastdesk_buxiazhu(userinfo.desk, userinfo.site)

	hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)

	sitedata.isbet = 1	--本轮已经选过不加了
	--下一个人出面板
	local next_site = deskmgr.getnextsite(userinfo.desk, userinfo.site)
	if(next_site ~= nil) then
		process_site(userinfo.desk, deskmgr.getnextsite(userinfo.desk, userinfo.site))
	else
		jiesuan(userinfo.desk, false)
    end
    return 1;
end

--点不下注
function onrecvbuxiazhu(buf)
	trace("onrecvbuxiazhu()")
	local userinfo = userlist[getuserid(buf)]; 
	do_bu_xia_zhu(userinfo);
end

--点全下
function onrecvallin(buf)
	trace("onrecvallin()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; 
	if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;
	local deskdata, sitedata = deskmgr.getdeskdata(userinfo.desk), deskmgr.getsitedata(userinfo.desk, userinfo.site)
	--判断合法性
	if hall.desk.get_site_state(userinfo.desk, userinfo.site) ~= SITE_STATE.PANEL then return end;
	if sitedata.panelrule.allin ~= 1 then return end

	--开始全下
	local gold = sitedata.gold
	sitedata.betgold = sitedata.betgold + gold
	local deskinfo = desklist[userinfo.desk]
	deskinfo.betgold = deskinfo.betgold + gold
	deskdata.totalbetgold = deskdata.totalbetgold + gold;
	sitedata.isbet = 1
	sitedata.isallin = 1

	deskdata.maxbetgold = math.max(sitedata.betgold, deskdata.maxbetgold)
    local can_use_gold = get_canuse_gold(userinfo, 1);
	if(sitedata.betgold > can_use_gold and deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match) then
		TraceError(format("异常情况，全下数大于身上的筹码...gold[%d], sitedata.betgold[%d], userinfo.gamescore[%d]", gold, sitedata.betgold, can_use_gold))
		sitedata.betgold = can_use_gold
	end
	--通知客户端
	net_broadcastdesk_xiazhu(userinfo.desk, userinfo.site, 4)
	net_sendmybean(userinfo, userinfo.gamescore);
	useraddviewgold(userinfo, -gold, true)

	hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)

	--下一个人出面板
	local next_site = deskmgr.getnextsite(userinfo.desk, userinfo.site)
	if(next_site ~= nil) then
		process_site(userinfo.desk, deskmgr.getnextsite(userinfo.desk, userinfo.site))
	else
		jiesuan(userinfo.desk, false)
	end
end

--客户端查询圣诞树信息
--[[
function on_recve_quest_farmtree(buf)
	--TraceError("on_recve_quest_farmtree()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end

	local sql = format("call yysns_farm.sp_get_textree_info('%s', %d)", userinfo["userName"], userinfo["nRegSiteNo"])
	dblib.dofarmsql(sql,
		function(dt)
			if dt and #dt > 0 then
				--TraceError(dt)
				netlib.send(
					function(buf)
						buf:writeString("TXMTREE")
						buf:writeString(dt[1]["sys_time"])
						buf:writeInt(dt[1]["farm_level"])
						buf:writeInt(dt[1]["charm_level"])
						buf:writeInt(dt[1]["charm_value"])
						buf:writeString(dt[1]["start_time"])
						buf:writeInt(dt[1]["online_time"])
						buf:writeString(dt[1]["total_grow_point"])
						buf:writeInt(dt[1]["tree_level"])
						buf:writeInt(dt[1]["fruits_1"])
						buf:writeInt(dt[1]["fruits_2"])
						buf:writeInt(dt[1]["fruits_3"])
						buf:writeInt(dt[1]["fruits_4"])
						buf:writeInt(dt[1]["fruits_5"])
						buf:writeInt(dt[1]["fruits_6"])
						buf:writeInt(dt[1]["fruits_7"])
						buf:writeInt(dt[1]["fruits_8"])
						buf:writeInt(dt[1]["fruits_9"])
						buf:writeInt(dt[1]["fruits_10"])
						buf:writeInt(dt[1]["fruits_11"])
					end,userinfo.ip,userinfo.port)
                    userinfo.charmlevel = tonumber(dt[1]["charm_level"])
                    userinfo.charmvalue = tonumber(dt[1]["charm_value"])
                    --每天领奖额外加成
                    userinfo.charmgold = tonumber(dt[1]["give_gold"])

                    --广播给整个桌子
                    net_broadcastdesk_charmchange(userinfo)
                
				--有农场树玩家的标志
				if(not userinfo.farmtree) then
                    --上次增加在线时间(防止重登录多加时间)
                    userinfo.lastaddtime = os.time()
				    userinfo.farmtree = 1
				end
			end
		end)
end

--客户端查询多久增加一次在线时长
function on_recve_query_delaytime(buf)
	--TraceError("on_recve_query_delaytime()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end
    if not userinfo.farmtree then return end --农场玩家才发此消息

    local delaytime = tex.farm_delaytime or 300
    netlib.send(
            function(buf)
                buf:writeString("TXMTIME")
                buf:writeInt(delaytime)
            end,userinfo.ip,userinfo.port)
end

--客户端请求增加一次在线时长
function on_recve_add_onlinetime(buf)
	--TraceError("on_recve_add_onlinetime()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end

    if not userinfo.farmtree then return end --农场玩家才发此消息

    local delaytime = tex.farm_delaytime or 300

    if(userinfo.lastaddtime and os.time() - userinfo.lastaddtime < delaytime)then
        return
    end

    --记录本次增加的时间
    userinfo.lastaddtime = os.time()

    --发消息给农场服务器让其增加在线时长
    send_online_message_tofarm(userinfo, delaytime) 
end
--]]
--客户端查询是否要显示新手教程
function on_recve_quest_welcome(buf)
	--TraceError("on_recve_quest_welcome()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end

	if userinfo.gotwelcome and userinfo.gotwelcome > 0 then return end

	--可以显示新手教程提示
	net_send_welcome_tex(userinfo)
end

--客户端请求不要再要显示新手教程
function on_recve_notshow_welcome(buf)
	--TraceError("on_recve_notshow_welcome()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end

	local userid = userinfo.userId
	if(userinfo.gotwelcome == 0) then
		--记录到内存
        save_new_user_process(userinfo, 1)
	end
end

--客户端通知已经看完一遍教程
function on_recve_study_over(buf)
	--TraceError("on_recve_study_over()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end

	local userid = userinfo.userId
    local welcome = userinfo.gotwelcome
	if(userinfo.gotwelcome == 0) then
		welcome = 2
	elseif(userinfo.gotwelcome == 1) then
		welcome = 3
	else
		--TraceError(format("玩家%d领取教程奖励时，gotwelcome=%s",userinfo.userId, tostring(userinfo.gotwelcome)))
		return
	end

	local givegold = 800
	usermgr.addgold(userinfo.userId, givegold, 0, g_GoldType.studyprize, -1)
	net_send_study_prize(userinfo, givegold)

	--记录到数据库
    save_new_user_process(userinfo, welcome)	
end

--給玩家桌内的玩家广播桌子信息
function onrecnquestdeskinfo(buf)
	--TraceError("onrecnquestdeskinfo()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end
	local deskno = buf:readInt()
	local deskinfo = desklist[deskno]
	if not deskinfo then return end
	OnSendDeskInfo(userinfo, deskno)
end

--給玩家弹出购买筹码对话框
function onrecvquestbuychouma(buf)	
	--TraceError("給玩家弹出购买筹码对话框 ..onrecvquestbuychouma()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; 
	if not userinfo.desk or userinfo.desk <= 0 then return end;
    local desk = userinfo.desk
    local deskinfo = desklist[desk]
    if(deskinfo==nil) then return end
    --只有坐下时才有这个限制，所以从buy_chouma_limit中拿出来了
	local freshman_limit = 3000;
	if((deskinfo.desktype == g_DeskType.normal or deskinfo.desktype==g_DeskType.channel or deskinfo.desktype==g_DeskType.channel_world) and deskinfo.smallbet == 1 and userinfo.gamescore > freshman_limit) then
        --新手场限制
		local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
            netlib.send(function(buf) 
                buf:writeString("TEXXST")
                end, userinfo.ip, userinfo.port, borcastTarget.playingOnly);
		return -2
	end
    --通过了买筹码的限制
    net_sendbuychouma(userinfo, desk);
end

--判断是否符合买筹码的限制
function buy_chouma_limit(userinfo)
	local desk = userinfo.desk

	local deskinfo = desklist[desk]

    if(deskinfo == nil) then
        return;
    end

	--等级不够，可能是通过好友功能走后门进来的，不允许他玩
	if(usermgr.getlevel(userinfo) < deskinfo.needlevel) then
		--TraceError(format("玩家等级[%d]，桌子需要等级[%d]", usermgr.getlevel(userinfo), deskinfo.needlevel))
		local sendmsg = ""
		sendmsg = format("该桌需要等级%d以上才可以游戏，你等级不够喔!", deskinfo.needlevel)
		net_sendsystemmsg(userinfo, tex.msgtype.systips, sendmsg)
		return -1
    end

	--竞技场开始后不允许弹出购买筹码
	if deskinfo.playercount < deskinfo.max_playercount+1 then
		if (deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) or not tex.getGameStart(desk) then
			return 1
		else
			net_sendsystemmsg(userinfo, tex.msgtype.systips, "对不起，比赛场不能中途加入游戏!")
            return -3
		end
    else
		net_sendsystemmsg(userinfo, tex.msgtype.systips, "该桌人数已满，请稍作等待，或找一个人少的桌子!")
        return -4
	end
end

--点击兑换筹码
function onrecvbuychouma(buf)
	--TraceError("onrecvbuychouma()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;

	--判断合法性
	local gold = buf:readInt()
	local deskno = buf:readInt()
	local siteno = buf:readByte()		--如果还没坐下，此座位应优先考虑
    if(userinfo.gameinfo==nil)then
        userinfo.gameinfo={}
    end
    userinfo.gameinfo.is_auto_addmoney=  buf:readByte() or 0 --是否自动顶注（0，1）
    userinfo.gameinfo.is_auto_buy= buf:readByte() or 0   --是否自动买入（0，1）
    userinfo.gameinfo.auto_buy_gold=gold    --客户端传过来要买的筹码，自动重买时要用
	dobuychouma(userinfo, deskno, siteno, gold)
end

--点击兑换筹码
function dobuychouma(in_userinfo, in_deskno, in_siteno, in_buygold)
	local userinfo = in_userinfo
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;

    local eventdata = {userinfo = in_userinfo, buygold = 0, handle = 0};
    eventmgr:dispatchEvent(Event('on_buy_chouma', eventdata));

	if(eventdata.handle == 1) then
		return;
	end

    if(eventdata.buygold > 0) then
        in_buygold = eventdata.buygold;
    end

	--判断合法性
	local gold = in_buygold or 0
	local deskno = userinfo.desk or in_deskno
	local siteno = userinfo.site or in_siteno
	local deskinfo = desklist[deskno]
	--TraceError(format("桌子号[%d]，座位号[%d], gold[%d]",deskno, siteno, gold))

    --比赛场一旦开始就不允许中途坐下
    if (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and tex.getGameStart(deskno) then
        return
    end
	
	--无效的座位号
	if(not userinfo.site and (siteno <= 0 or siteno > room.cfg.DeskSiteCount)) then siteno = 1 end
	
	if gold == 0 then					--如果传0表示取消兑换筹码
		--TraceError("取消兑换筹码")
		userinfo.chouma = 0
		return
	end	
    local can_use_gold = get_canuse_gold(userinfo, 1);
    if(deskinfo.desktype ~= g_DeskType.match) then
    	if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then 
    		if gold < deskinfo.at_least_gold then
    			gold = deskinfo.at_least_gold
    		end
    		if gold > deskinfo.at_most_gold then
    			--gold = deskinfo.at_most_gold
            end
    		if can_use_gold < gold then
    			gold = can_use_gold			
    			if(userinfo.site ~= nil and gold < deskinfo.at_least_gold) then
    				if(userinfo.site ~= nil) then 
    					--站起并加入观战
    					doStandUpAndWatch(userinfo)
    				end
    				--OnSendServerMessage(userinfo, 1, _U("对不起，您的筹码不够支付本桌的最低带入筹码标准!"))
    				return
    			end
    		end
    		--实现兑换筹码
    		userinfo.chouma = gold
    	else
            if(can_use_gold < deskinfo.at_least_gold + deskinfo.specal_choushui) then
                if(userinfo.site ~= nil) then 
                    hall.desk.set_site_state(deskno, siteno, NULL_STATE)
                    doUserStandup(userinfo.key, false) 
                    DoUserExitWatch(userinfo)
                    net_kickuser(userinfo)
                end
                OnSendServerMessage(userinfo, 1, _U("对不起，您的筹码不够支付本比赛桌的报名和服务费用!"))
                return
            else
                userinfo.chouma = 1000
            end
        end
    else
        userinfo.chouma = gold
    end
	--看是否要坐下(座位号为空说明需要坐下)
	if(not userinfo.site) then
		--坐下前先检查是否有人在座位上(有就随机在该桌子上找一个)
		local siteuserinfo = userlist[hall.desk.get_user(deskno, siteno) or ""]
		if siteuserinfo ~= nil then
            if(siteuserinfo.userId == userinfo.userId)then
                TraceError("怎么搞的?有人分身了!!!"..debug.traceback())
                userinfo.chouma = 0
        		return 
            else
    			local newsiteno = hall.desk.get_empty_site(deskno)
    			--没有空座位，就强坐原来那个座位，使其提示“该座位上有人”
    			if newsiteno > 0 then siteno = newsiteno end
            end
		end
		--竞技场开始后不允许坐下
		if deskinfo.playercount < deskinfo.max_playercount then
            local FunDoSitdown = function()
                doSitdown(userinfo.key, userinfo.ip, userinfo.port, deskno, siteno, g_sittype.normal)
            end
            getprocesstime(FunDoSitdown, "buychoumadoSitdown", 500)
		end
	end
	--没有座位号说明坐下失败了
	if(not userinfo.site) then
		--TraceError(userinfo.site)
		userinfo.chouma = 0
		
		if(viproom_lib.get_room_spec_type(deskno) == 0)then
			OnSendServerMessage(userinfo, 1, _U("暂时没有空位啦，请稍等一下!"))
		end
		return 
    end

    --记录带入到这个赔率房间的筹码
    local smallbet = deskinfo.smallbet
    local extra_info = userinfo.extra_info
    local defaulttb = {gametime = 0, bringgold = gold, bringout = 0, wingold = 0}
    if(extra_info["F09"][smallbet] == nil or type(extra_info["F09"][smallbet]) ~= "table")then 
        extra_info["F09"][smallbet] = defaulttb
    else
        local gametime = extra_info["F09"][smallbet]["gametime"] or 0
        local interval = extra_info["F09"].interval or 1800
        local wingold = extra_info["F09"][smallbet]["wingold"] or 0
        --超过半小时或没赢钱就不限制了
        if(os.time() - gametime > interval or wingold <= 0) then
            extra_info["F09"][smallbet] = defaulttb
        elseif(gold >= wingold)then
            extra_info["F09"][smallbet]["bringgold"] = gold - wingold
            extra_info["F09"][smallbet]["bringout"] = 0
        else
            --TraceError(format("异常:玩家带入筹码[%d],小于之前赢的筹码[%d]，怎么做到的?", gold, wingold))
            extra_info["F09"][smallbet] = defaulttb
        end
    end
    userinfo.extra_info = extra_info
    local FunSaveExtraInfo = function()
        save_extrainfo_to_db(userinfo)
    end
    getprocesstime(FunSaveExtraInfo, "buychoumasave_extrainfo_to_db", 500)

	if(hall.desk.get_site_state(deskno, userinfo.site) == SITE_STATE.BUYCHOUMA) then
		net_broadcastdesk_goldchange(userinfo)
		hall.desk.set_site_state(deskno, userinfo.site, SITE_STATE.READYWAIT)
		net_broadcastdesk_playerinfo(deskno)
		if deskmgr.get_game_state(deskno) == gameflag.notstart then
            local FunTryStartGame = function()
                trystartgame(deskno)
            end
            getprocesstime(FunTryStartGame, "buychoumatrystartgame", 500)
		end
	end
	
	--设置能用来买东西的钱
	--userinfo.canbuygold = can_use_gold -userinfo.chouma
end

--尝试开始游戏
function trystartgame(deskno, onplan)
	--TraceError("trystartgame()")
	
	
	if deskmgr.get_game_state(deskno) ~= gameflag.notstart then return end
	local deskdata = deskmgr.getdeskdata(deskno)

	local jiesuanwait = deskdata.jiesuanwait
	if not onplan and (os.time() - jiesuanwait.jiesuantime < jiesuanwait.needwait) then
		--TraceError("jiesuanwait.startplan 阻止游戏开始, curr = "..os.time() - jiesuanwait.jiesuantime)
		--TraceError(jiesuanwait)
		jiesuanwait.someonestart = 1
		return
	end

	local deskinfo = desklist[deskno]
	local readysite = 0			--准备好的人数	

    deskdata.playinglist = {}
	deskdata.deskpokes = {}

	local sitelist = {}

	--开始游戏时，要生成邀请赛的比赛ID，并记录下这次比赛的人数
	--因为消耗不大，所以每局比赛都生成ID，并记录人数，万一其他地方需要的话，可以调用。
	--[[if(tex_match)then
		xpcall(function() tex_match.init_invate_match(deskno) end, throw)
	end
	--]]
	eventmgr:dispatchEvent(Event("game_begin_event",	_S{deskno = deskno}))

	--如果准备了的人没买筹码，让其弹出购买筹码状态变为未准备，其他人尝试开始游戏
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local userinfo = player.userinfo
		local state = hall.desk.get_site_state(deskno, player.siteno)
		local user_chouma = userinfo.chouma or 0
        local can_use_gold = get_canuse_gold(userinfo, 1);

		--比赛场
		if deskinfo.desktype == g_DeskType.match then
            if(state ~= SITE_STATE.READYWAIT and state ~= SITE_STATE.LEAVE) then
                hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.READYWAIT)
            end
		elseif deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament then
			if(user_chouma < deskinfo.largebet) then  --没筹码啦，淘汰或发奖
				--记录淘汰的座位号
				table.insert(sitelist, player.siteno)
			else
				--继续比赛
				if(state ~= SITE_STATE.READYWAIT and state ~= SITE_STATE.LEAVE) then
					hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.READYWAIT)
				end
			end
		--普通场
		else
			local needgold = deskinfo.largebet + deskinfo.specal_choushui + 1
			if (user_chouma < needgold) then
				if can_use_gold >= deskinfo.at_least_gold then
					if(state ~= SITE_STATE.NOTREADY and state ~= SITE_STATE.BUYCHOUMA) then
						hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.BUYCHOUMA)
                        tex.setdeskdefaultchouma(userinfo, deskno)
						net_sendbuychouma(userinfo, deskno, 30);
					end
				else
					--站起并加入观战
					doStandUpAndWatch(userinfo)
					trystartgame(deskno)
					return
				end
			else
				hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.READYWAIT)
			end
		end
	end

	if ((deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and #sitelist > 0) then
		set_lost_or_prize(deskno, sitelist)
	end
	
    --记录最后一个被搜索到的玩家座位，以备剩下最后一人时发奖
    local siteno = 0
	for i = 1, room.cfg.DeskSiteCount do
		local state = hall.desk.get_site_state(deskno, i)
		if state == SITE_STATE.READYWAIT or 
			((deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and state == SITE_STATE.LEAVE) then
			readysite = readysite + 1
            siteno = i
		end
	end
	--竞技场发奖或淘汰一个人
	if((deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and 
	   siteno > 0 and 
	   deskdata.rounddata.roundcount > 0 and 
	   deskinfo.playercount == 1) then
		set_lost_or_prize(deskno, {siteno})
		return
	end

	local eventdata = {handle=0, deskno=deskno};
	eventmgr:dispatchEvent(Event("on_try_start_game", eventdata));

	if(eventdata.handle == 1) then
		return;
	end

	--TraceError("readysite = "..readysite)
	if readysite >= 2 then
        --竞技场第一轮必须在满人状态开局
    	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament)then
    		if(deskdata.rounddata.roundcount == 0 and readysite ~= deskinfo.max_playercount) then
    			return
    		end
		end

		--TraceError("游戏开始啦~~")
		local old_zhuangsite = deskdata.zhuangsite or 0
		if(old_zhuangsite <= 0) then old_zhuangsite = 1 end

		--初始化桌子数据
		deskinfo.betgold = 0
		local rounddata = table.clone(deskdata.rounddata)
		deskmgr.initdeskdata(deskno)
		deskdata = deskmgr.getdeskdata(deskno)		
		if(rounddata.roundcount > 0) then
			deskdata.rounddata = rounddata
		end

		--初始化座位数据
		for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
			deskmgr.initsitedata(deskno, siteno)
		end

		for _, player in pairs(deskmgr.getplayers(deskno)) do
			local site_state = hall.desk.get_site_state(deskno, player.siteno)
			--准备好的玩家可以开始，剩下的继续购买筹码好了
			if site_state == SITE_STATE.READYWAIT then
				hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.WAIT)
				local userinfo = player.userinfo
				local sitedata = deskmgr.getsitedata(deskno, player.siteno)
				sitedata.isinround = 1
				sitedata.roundplayer = userinfo
				sitedata.gold = userinfo.chouma
				userinfo.chouma = 0
			elseif (deskinfo.desktype == g_DeskType.tournament or 
                    deskinfo.desktype == g_DeskType.channel_tournament or
                    deskinfo.desktype == g_DeskType.match) and site_state == SITE_STATE.LEAVE then
				local userinfo = player.userinfo
				local sitedata = deskmgr.getsitedata(deskno, player.siteno)
				sitedata.isinround = 1
				sitedata.roundplayer = userinfo
				sitedata.gold = userinfo.chouma
				userinfo.chouma = 0
			end
		end

        --寻找下一个庄家的位置
        local startsite = old_zhuangsite
        if(not startsite or startsite <= 0 or startsite > room.cfg.DeskSiteCount) then
            startsite = 1
        end
        while true do
            local newzhuangsite = deskmgr.getnextsite(deskno, startsite)
            if newzhuangsite and newzhuangsite > 0 then
                deskdata.zhuangsite = newzhuangsite
                break
            end
            startsite = startsite + 1
            if startsite > room.cfg.DeskSiteCount then startsite = 1 end
            if(startsite == old_zhuangsite) then
                TraceError("异常情况:游戏开始，怎么没有人做庄了？")
                return
            end
        end

		deskdata.gamestart_playercount = readysite  --记录每局开始时候的人数,
		
		--游戏开始标志
		deskmgr.set_game_state(deskno, gameflag.start)

		--初始化牌盒
		do
			deskdata.pokebox = {}
			for i = 1, #tex.pokenum do
				table.insert(deskdata.pokebox, i)
			end
			table.disarrange(deskdata.pokebox)
			table.disarrange(deskdata.pokebox)--产品认为牌的顺序不够乱，所以再打乱一次
		end

		--局数加1
		deskdata.rounddata.roundcount = deskdata.rounddata.roundcount + 1
        deskdata.rounddata.xiazhucount = 0;

		--广播桌子状态改变
		net_broadcast_deskinfo(deskno)
		
		--广播游戏开始
		net_broadcastdesk_gamestart(deskno);		

		--发牌
		fapai(deskno)
	end
end

--从牌盒摸一张牌
function getpokefrombox(deskno)
	trace("getpokefrombox("..deskno..")")
	local deskdata = deskmgr.getdeskdata(deskno)
	if #deskdata.pokebox == 0 then
		TraceError("牌盒里的牌摸完了,不怎么合理")
		return 
	end
	local ret = deskdata.pokebox[1]
	table.remove(deskdata.pokebox, 1)
	return ret
end


--发牌, 自动根据当前轮数决定发什么
function fapai(deskno)
	trace("fapai("..deskno..")")
	local deskdata = deskmgr.getdeskdata(deskno)
	local deskinfo = desklist[deskno]

    --给每个人发2张牌
    local sitelist = {}
    for _, player in pairs(deskmgr.getplayingplayers(deskno)) do
        local sitedata = deskmgr.getsitedata(deskno, player.siteno)
        if deskdata.zhuangsite == 0 then deskdata.zhuangsite = player.siteno end		--随便选一个当庄
        table.insert(sitelist, player.siteno)
        for i = 1, 2 do
            local pokeid = getpokefrombox(deskno)
            table.insert(sitedata.pokes, pokeid)
		end
		
		--扣抽水
		local choushui = get_specal_choushui(deskinfo,player.userinfo)
        if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match then
			--两个人玩，抽水加倍
			if(deskinfo.playercount <= 2) then
				choushui = choushui * 2
			end
            usermgr.addgold(player.userinfo.userId, -choushui, -choushui, g_GoldType.normalchoushui, g_GoldType.normalchoushui, 1)
            net_sendmybean(player.userinfo, player.userinfo.gamescore)
    		sitedata.gold = sitedata.gold - choushui
    		net_broadcastdesk_goldchange(player.userinfo)
        --竞技场只在第一局抽水
        elseif (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and deskdata.rounddata.roundcount == 1 then
			--------------------成就---------------------
			xpcall(function()
					achievelib.updateuserachieveinfo(player.userinfo,1007) --参加单桌赛
				end,throw)
			--------------------------------------------
            if(deskinfo.at_least_gold ~= deskinfo.at_most_gold) then
                TraceError("竞技场桌子配置应该是允许带入最低筹码和最高筹码一样......")
            end
            local joinfee = deskinfo.at_least_gold
            --扣抽水
            usermgr.addgold(player.userinfo.userId, -choushui, 0, g_GoldType.deskmatchchoushui, -1, 1)
            --扣报名费
            usermgr.addgold(player.userinfo.userId, -joinfee, 0, g_GoldType.deskmatchjoin, -1, 1)
            net_sendmybean(player.userinfo, player.userinfo.gamescore)
        end
	end

	--给sitelist排序,按照庄，小盲，大盲这样的顺序来搞
	local tmpsitelist = {}
	for k, v in pairs(sitelist) do if v >= deskdata.zhuangsite then table.insert(tmpsitelist, v) end end
	for k, v in pairs(sitelist) do if v < deskdata.zhuangsite then table.insert(tmpsitelist, v) end end
	sitelist = tmpsitelist
	deskdata.playinglist = sitelist

	--设置大小盲位置
	deskdata.smallbetsite = deskmgr.getnextsite(deskno, deskdata.zhuangsite)
	deskdata.lagrebetsite = deskmgr.getnextsite(deskno, deskdata.smallbetsite)

	
	--自动下大小盲(底注)
	local siteno = deskmgr.getnextsite(deskno, deskdata.zhuangsite)
	
	--特殊处理两个人的情况：庄为小盲，闲为大盲
	if(deskinfo.playercount == 2) then
		siteno = deskdata.zhuangsite
		deskdata.smallbetsite = deskdata.zhuangsite --小盲
		deskdata.lagrebetsite = deskmgr.getnextsite(deskno, deskdata.smallbetsite) --大盲
	end

	local index = 1
	local startsite = siteno
	local tmp_num = 1 --防止死循环，理论上最多9次，如果跑了20次还没出来肯定挂了
	while true and tmp_num < 20 do
		-----------------------------------------
		tmp_num = tmp_num + 1
		local sitedata = deskmgr.getsitedata(deskno, siteno)
		local userinfo = deskmgr.getsiteuser(deskno, siteno)
		local setbet = false

		if siteno == deskdata.smallbetsite then
			sitedata.betgold = deskinfo.smallbet
			setbet = true
		elseif siteno == deskdata.lagrebetsite then
			sitedata.betgold = deskinfo.largebet
			setbet = true
		end
		
		--[[if deskdata.rounddata.sitecount[siteno] == 0 and deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then 
			sitedata.betgold = deskinfo.largebet
			setbet = true
		else
			if index == 1 then
				sitedata.betgold = deskinfo.smallbet
				setbet = true
			elseif index == 2 then
				sitedata.betgold = deskinfo.largebet
				setbet = true
			end
		end
		--]]
		if(setbet) then
			deskdata.maxbetgold = sitedata.betgold
			deskinfo.betgold = deskinfo.betgold + sitedata.betgold
			deskdata.totalbetgold = deskdata.totalbetgold + sitedata.betgold
		end
		
		--通知客户端
		if userinfo then
			net_broadcastdesk_xiazhu(deskno, siteno, 3)
			net_sendmybean(userinfo, userinfo.gamescore);			--自己的德州豆
			useraddviewgold(userinfo, -sitedata.betgold, true)
			deskdata.rounddata.sitecount[siteno] = deskdata.rounddata.sitecount[siteno] + 1
		end
		-----------------------------------------
		index = index + 1
		siteno = deskmgr.getnextsite(deskno, siteno)
		if siteno == startsite then break end
	end
	
	--告诉客户端播放发牌动画，以及2张牌内容
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local sitedata = deskmgr.getsitedata(deskno, player.siteno)
		net_send_fapai(player.userinfo, sitelist, player.siteno, sitedata.pokes)
	end
	--给观战的人播放发牌
	net_send_fapai_forwatching(deskno, sitelist)

    eventmgr:dispatchEvent(Event("on_after_fapai", {deskno=deskno}));

	fadeskpai(deskno)
end

--结算不管是否round是否为0都计算彩池
function getcurrdeskpools(deskno, isjiesuan)
	--计算当前彩池情况
	local deskdata = deskmgr.getdeskdata(deskno)
	local roundsitedatalist = {}
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		if sitedata.isinround == 1 then
			table.insert(roundsitedatalist, 
				{
					siteno		= siteno, 
					betgold		= sitedata.betgold, 
					isgiveup	= sitedata.islose, 
					isallin 	= sitedata.isallin,
				})
			if deskdata.round <= 0 then
				sitedata.roundbet = 0
			else
				sitedata.roundbet = sitedata.betgold
			end
		end
	end
	if isjiesuan or deskdata.round > 0 then
		local deskpools = getroundpool(roundsitedatalist)
		if isjiesuan and deskdata.round ==0 then  --结算时只有大小盲就必须加起来并成一个主池
			deskdata.pools = {}
			deskdata.pools[1] = 0
			for k, v in pairs(deskpools) do
				deskdata.pools[1] = deskdata.pools[1] + v
			end
		else
			deskdata.pools = deskpools
		end
	end

	return deskdata.pools
end
--广播玩家手牌的最佳组合
function notify_player_beatpoke(deskno)
    local deskdata = deskmgr.getdeskdata(deskno)
    for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		if sitedata.isinround == 1 then
			local newtable = table.mergearray(deskdata.deskpokes, sitedata.pokes)
			local userinfo = deskmgr.getsiteuser(deskno, siteno)
			local pokeweight, bestpokes = gettypeex(newtable)
			local pokestr = ""
			for k,v in pairs(bestpokes) do
				pokestr = pokestr .. tex.pokechar[v]
			end
			if userinfo ~= nil then
				--TraceError(format("玩家[%d]，pokeweight:%s, pokestr:%s", userinfo.userId, pokeweight, pokestr))
				net_send_bestpokes(userinfo, pokeweight, bestpokes)
			end
		end
	end
end

function fadeskpai(deskno)
	local deskdata = deskmgr.getdeskdata(deskno)
	local deskinfo = desklist[deskno]

	--每次发完牌以后，在玩的人应该都设置为未下注
	for _, player in pairs(deskmgr.getplayingplayers(deskno)) do
		local sitedata = deskmgr.getsitedata(deskno, player.siteno)
		sitedata.isbet = 0
		eventmgr:dispatchEvent(Event("ongame_having_sitegold", {user_info = player.userinfo, deskno = deskno, round=deskdata.round}));
	end
   
	--当前轮至少加注 默认为大盲注
	deskdata.roundaddgold = desklist[deskno].largebet

    if deskdata.round == 0 then
		deskdata.leadersite = deskmgr.getnextsite(deskno, deskdata.lagrebetsite)  --下注人
		
	elseif deskdata.round == 1 then
		local newleader = deskmgr.getnextsite(deskno, deskdata.lagrebetsite)
		if newleader then			--有可能第一轮就有人放弃了
			deskdata.leadersite = newleader
		end
		--发3张牌
		for i = 1, 3 do
			local pokeid = getpokefrombox(deskno)
            table.insert(deskdata.deskpokes, pokeid)
		end
	elseif deskdata.round == 2 or deskdata.round == 3 then
		local pokeid = getpokefrombox(deskno)
        table.insert(deskdata.deskpokes, pokeid)
	else
		jiesuan(deskno, true)
		return
	end

	if(deskdata.round > 0) then
		net_broadcast_deskpokes(deskno)
	end

	--下一个
	process_site(deskno, deskdata.leadersite)

	--计算当前彩池
	local currdeskpools = getcurrdeskpools(deskno, false)
	net_broadcast_deskpoolsinfo(deskno, currdeskpools)

	--广播玩家手牌的最佳组合
    	notify_player_beatpoke(deskno)
end


--处理某个玩家 startsite 不传
function process_site(deskno, siteno, startsite)
	--TraceError("process_site(" .. deskno .. ", " .. siteno .. ")")
	
	local deskdata = deskmgr.getdeskdata(deskno)
	local userinfo = deskmgr.getsiteuser(deskno, siteno)
	local sitedata = deskmgr.getsitedata(deskno, siteno)

	if not startsite then startsite = siteno end
	local nextsite = deskmgr.getnextsite(deskno, siteno)

	--如果就剩自己了，或下一个转回来了,就发牌吧
	if (not nextsite) or startsite == nextsite then
		deskdata.round = deskdata.round + 1
        deskdata.rounddata.xiazhucount = 0;
		fadeskpai(deskno)
		return
	end

	--如果别人都全下了，自己也是平的，也再发牌
	--（此代码为补丁式代码，合理的写法是让getnextsite就过滤掉allin了的，但是现在不敢改，还得测）
	local isnototherallin = 0
	for _, player in pairs(deskmgr.getplayingplayers(deskno)) do
		local userinfo = player.userinfo
		local sitedata = deskmgr.getsitedata(deskno, player.siteno)
		if sitedata.isinround == 1 then
			if sitedata.isallin ~= 1 and player.siteno ~= siteno then
				isnototherallin = 1
				break
			end
		end
	end
	--TraceError("isnototherallin=" .. isnototherallin)
	if sitedata.betgold == deskdata.maxbetgold and isnototherallin == 0 then
		deskdata.round = deskdata.round + 1
        deskdata.rounddata.xiazhucount = 0;
		fadeskpai(deskno)
		return
	end

	--全下过，必不出面板； 没全下过，则不平或没下过的情况需要出面板
	if sitedata.isallin == 0 and (sitedata.isbet == 0 or sitedata.betgold < deskdata.maxbetgold) then
		--如果此人离线则自动放弃
		if userinfo and hall.desk.get_site_state(deskno, siteno) == SITE_STATE.LEAVE then
			letusergiveup(userinfo)
			return
		end
		show_panel(deskno, siteno, isnototherallin)		--显示操作面板
		show_auto_panel(deskno, siteno)		--显示自动面板
	else
		--处理下个人
		return process_site(deskno, nextsite, startsite)
	end
end

--显示自动面板
function show_auto_panel(deskno, siteno)
	--TraceError("show_auto_panel(" .. deskno .. ", " .. siteno .. ")")
	local deskdata = deskmgr.getdeskdata(deskno)
	local sitedata = deskmgr.getsitedata(deskno, siteno)
	local rule = sitedata.panelrule
	local panelsite = siteno

	local autocount = 0
	for i = 1, 9 do
		panelsite = deskmgr.getnextsite(deskno, panelsite)
		if panelsite and panelsite ~= siteno then
			local panelsitedata = deskmgr.getsitedata(deskno, panelsite)
			local paneluserinfo = deskmgr.getsiteuser(deskno, panelsite)
			if paneluserinfo then
				if autocount < 9 and 
                   panelsitedata.isallin == 0 and 
                   (panelsitedata.isbet == 0 or panelsitedata.betgold < deskdata.maxbetgold) then
					local autodata = _S
					{
						guo 		= 0, 
						guoqi 		= 1,
						genrenhe 	= 1, 
						gen 		= 0, 
						gengold 	= 0,
					}
					if deskdata.maxbetgold > panelsitedata.betgold then
						if panelsitedata.gold + panelsitedata.betgold <= deskdata.maxbetgold then	--钱不够，过和跟是灰的
							autodata.guo		= 0
							autodata.gen		= 0
							autodata.gengold	= 0
						else																		--只有过是灰的
							autodata.guo		= 0
							autodata.gengold 	= deskdata.maxbetgold - panelsitedata.betgold
							autodata.gen		= 1
						end
					else
						autodata.guo 			= 1													--可以过，但人家没加注的话，跟是灰的
						autodata.gengold 		= 0
						autodata.gen			= 0
					end
					net_show_autopanel(paneluserinfo, autodata)
					autocount = autocount + 1
				else
					if paneluserinfo then
						local autodata = _S
						{
							guo 		= 0, 
							guoqi 		= 0,
							genrenhe 	= 0, 
							gen 		= 0, 
							gengold 	= 0,
						}
						net_show_autopanel(paneluserinfo, autodata)
					end
				end
			end
		else
			break
		end
	end

	--给放弃的人出名人名言
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		local userinfo = deskmgr.getsiteuser(deskno, siteno)
		if userinfo and sitedata.isinround and sitedata.islose == 1 then
			local autodata = _S
			{
				guo 		= 0, 
				guoqi 		= 0,
				genrenhe 	= 0, 
				gen 		= 0, 
				gengold 	= 0,
			}
			net_show_autopanel(userinfo, autodata)
		end
	end
end

--恢复面板
function restore_panel(user_info, desk_no, site_no)
	local site_data = deskmgr.getsitedata(desk_no, site_no)
	local desk_data = deskmgr.getdeskdata(desk_no)
	local desk_info = desklist[desk_no]
	if (hall.desk.get_site_state(desk_no, site_no) == SITE_STATE.PANEL) then
		local rule = site_data.panelrule
		rule = table.clone(rule)
		process_panel_limit(rule, site_data, desk_info, desk_data)
		net_showpanel(user_info, rule);
	end
end

--设置面板限制
function process_panel_limit(rule, site_data, desk_info, desk_data)
	--rule.gengold = rule.gengold + (sitedata.betgold - sitedata.roundbet)
	rule.max = rule.max + (site_data.betgold - site_data.roundbet)
	rule.min = rule.min + (site_data.betgold - site_data.roundbet)

	if(desk_info.limit ~= nil and desk_info.limit == 1) then
		--限制下注开始
		local smallbet, largebet = getLimitXiazhu(desk_info, desk_data, site_data);
		--前两轮
		rule.min = smallbet + (site_data.betgold >= desk_data.maxbetgold and 0 or (site_data.betgold - site_data.roundbet));
		rule.max = rule.min; 
		rule.allin = 0;	
		if(desk_data.rounddata.xiazhucount >= 3) then
			--已经加注过三次了
			if(rule.jia == 1) then--身上还有钱，可以加注，但是限加注了
				rule.jia = 0;
				rule.gengold = desk_data.maxbetgold - site_data.betgold;
				rule.gen = 1;
				rule.allin = 0;
			end
		end
	end
end

--显示面板
function show_panel(deskno, siteno, isnototherallin)
	--TraceError("show_panel(" .. deskno .. ", " .. siteno .. ")")
	local deskdata = deskmgr.getdeskdata(deskno)
	local deskinfo = desklist[deskno]
	local userinfo = deskmgr.getsiteuser(deskno, siteno)
	local sitedata = deskmgr.getsitedata(deskno, siteno)

	if not userinfo then return end

	--查询除自己外其他人的最高跟平后的剩余筹码
	local allowMaxGold = 0
	for k, v in pairs(deskmgr.getallsitedata(deskno)) do
		if k ~= siteno and v.isinround == 1 and v.islose == 0 then
			local gold = v.gold + v.betgold - deskdata.maxbetgold --这个人跟平后的剩余筹码
			if(allowMaxGold < gold) then
				allowMaxGold = gold
			end
		end
	end

	local rule = sitedata.panelrule
	if deskdata.maxbetgold > sitedata.betgold then
		if sitedata.gold + sitedata.betgold <= deskdata.maxbetgold then
			--【全下/放弃】
			rule.gengold 	= sitedata.gold
			rule.gen		= 1
			rule.buxiazhu	= 0
			rule.xiazhu		= 0
			rule.jia 		= 0
			rule.allin		= 0		--全下
			rule.fangqi		= 1		--放弃
			rule.max		= sitedata.gold
			rule.min 		= sitedata.gold
		else
			--【跟，加，放弃】
			rule.gengold 	= deskdata.maxbetgold - sitedata.betgold	--跟多少钱
			rule.gen		= 1		--跟
			rule.buxiazhu	= 0
			rule.xiazhu		= 0
			rule.jia 		= 1		--加
			rule.allin		= 1 
			rule.fangqi		= 1		--放弃
			rule.max		= math.min(rule.gengold + allowMaxGold, sitedata.gold)		--最多加多少钱
			rule.min 		= rule.gengold + deskdata.roundaddgold		--最少加多少钱
			if rule.min >= rule.max then
				--rule.jia 		= 0		--加
				--rule.allin		= 0		--allin
				rule.min = rule.max
			end
			if isnototherallin == 0 then  --其他人全下,就不用再加了
				rule.jia = 0
			end
		end
	else
		--【过牌/下注/放弃】
		rule.gengold 	= 0
		rule.gen		= 0
		rule.buxiazhu	= 1		--过牌
		rule.xiazhu		= 0		--下注
		rule.jia 		= 1
		rule.allin		= 1 
		rule.fangqi		= 1		--放弃
		rule.max		= math.min(allowMaxGold, sitedata.gold)
		rule.min 		= deskdata.roundaddgold
		if rule.min >= rule.max then
			--rule.xiazhu 	= 0		--加
			--rule.jia		= 1		--allin
			rule.min = rule.max
		end
	end
	--TraceError("rule source:" .. tostringex(rule))
	rule = table.clone(rule)
	process_panel_limit(rule, sitedata, deskinfo, deskdata)	
	if sitedata.panellefttime > 0 then			
		--这里表示礼物、表情功能导致了状态重新计算，时间要重设回发表情前的剩余时间
		hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.PANEL, sitedata.panellefttime)
	elseif(deskinfo.fast == 1) then 
		hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.PANEL, tex.cfg.fastdelay)
	else
		hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.PANEL)
	end

	net_showpanel(userinfo, rule);

    eventmgr:dispatchEvent(Event("on_show_panel", {deskno = deskno, siteno = siteno}));
end

function getLimitXiazhu(deskinfo, deskdata, sitedata) 
    local smallbet = 0;
    local largebet = 0;

    if(deskdata.round < 2) then
        smallbet = deskdata.maxbetgold - sitedata.betgold + deskinfo.smallbet;
    elseif(deskdata.round >= 2) then
        smallbet = deskdata.maxbetgold - sitedata.betgold + deskinfo.largebet;
    end
    largebet = smallbet; 
    return smallbet, largebet;
end

--通过金币加成和桌子大小盲计算经验值,
function getAddexp(deskno, addgold)
	if not deskno then return end
	local deskinfo = desklist[deskno]

	local addexp = 0
	local addtype = -1
	if deskinfo.desktype == g_DeskType.normal or deskinfo.desktype == g_DeskType.channel or deskinfo.desktype == g_DeskType.channel_world then
		if addgold and addgold > 0 then
			--TraceError("赢了")
			addtype = g_ExpType.win
			if addgold < 1000 then
				addexp = 4
			elseif addgold < 5000 then
				addexp = 8
			elseif addgold < 10000 then  --1w
				addexp = 12
			elseif addgold < 50000 then  --5w
				addexp = 16
			elseif addgold < 100000 then  --10w
				addexp = 20
			elseif addgold < 500000 then --50w
				addexp = 24
			elseif addgold < 1000000 then --100w
				addexp = 28
			elseif addgold < 5000000 then --500w
				addexp = 32
			elseif addgold < 10000000 then --1000w
				addexp = 36
			elseif addgold < 50000000 then --50000w
				addexp = 40
			elseif addgold < 100000000 then --10000w
				addexp = 44
			else --10000w+
				addexp = 48
			end
		else
			--TraceError("输了")
			addtype = g_ExpType.lost
			local largebet = deskinfo.largebet
			if largebet < 10 then
				addexp = 1
			elseif largebet < 20 then
				addexp = 2
			elseif addgold < 100 then
				addexp = 3
			elseif largebet < 500 then
				addexp = 4
			elseif largebet < 5000 then
				addexp = 5
			elseif largebet < 50000 then
				addexp = 6
			elseif largebet < 200000 then
				addexp = 7
			elseif largebet < 1000000 then
				addexp = 8
			elseif largebet < 2000000 then
				addexp = 9
			else 
				addexp = 10
			end
		end

		if deskinfo.desktype == g_DeskType.VIP then
			addexp = addexp * 2
		end
	elseif deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament then
		local joinfee = deskinfo.at_least_gold
		if addgold and addgold > 0 then
			--TraceError("赢了")
			addtype = g_ExpType.deskmatchwin
			if joinfee < 500 then
				addexp = 3
			elseif joinfee < 5000 then
				addexp = 6
			elseif joinfee < 50000 then 
				addexp = 9
			elseif joinfee < 250000 then 
				addexp = 12
			elseif joinfee < 500000 then  
				addexp = 15
			elseif joinfee >= 500000 then 
				addexp = 18
			end
		else
			--TraceError("输了")
			addtype = g_ExpType.deskmatchlost
			if joinfee < 500 then
				addexp = 1
			elseif joinfee < 5000 then
				addexp = 2
			elseif joinfee < 50000 then 
				addexp = 3
			elseif joinfee < 250000 then 
				addexp = 4
			elseif joinfee < 500000 then  
				addexp = 5
			elseif joinfee >= 500000 then 
				addexp = 6
			end
		end
	end
	return addtype, addexp
end

function setextrainfo(userinfo, deskno, sitedata, addgold)
	--强化之后的玩家信息
	--F00:加入遊戲時間,F01:最大贏取遊戲幣,F02:最佳手牌,F03:玩過局數,F04:贏過局數,
	--F05:最高擁有遊戲幣,F06:好友數量,F07:今日輸贏,获得经验,F08:赢过的单桌比赛次数
    --F09:在各种赔率房间的输赢记录
	local extra_info = userinfo.extra_info
    local deskinfo = desklist[deskno]
	--总局数
	extra_info["F03"] = extra_info["F03"] + 1

	--判断日期(不是今日就得重置)
	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	if(sys_today ~= userinfo.dbtoday) then --日期不符
		--重置并同步
		userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
		userinfo.gameInfo.todayexp = 0
		dblib.cache_set(gamepkg.table, {todayexp = 0}, "userid", userinfo.userId)

		userinfo.extra_info["F07"] = addgold
	else
		extra_info["F07"] = extra_info["F07"] + addgold
	end

	--最大赢取
	if(addgold > extra_info["F01"]) then extra_info["F01"] = addgold end

	--赢过局数
	if(addgold > 0) then extra_info["F04"] = extra_info["F04"] + 1 end

	--最高拥有过游戏币
	if(userinfo.gamescore > extra_info["F05"]) then extra_info["F05"] = userinfo.gamescore end

	--最佳手牌
	if(sitedata.pokeweight > extra_info["F02"].pokeweight) then
		extra_info["F02"].pokeweight = sitedata.pokeweight
		extra_info["F02"].pokes5 = sitedata.pokes5
    end

    --更新在这个赔率房间的最后一盘游戏时间
    local smallbet = deskinfo.smallbet
    if(addgold > 0 and type(extra_info["F09"][smallbet]) == "table") then
        local currtime = os.time()

        extra_info["F09"]["last_time"] = currtime
        extra_info["F09"][smallbet]["gametime"] = currtime
    end
 
	userinfo.extra_info = extra_info
	save_extrainfo_to_db(userinfo)
end
--判断是该发奖还是淘汰
--领奖规则，如果同时被淘汰，则都为淘汰时的最后一名
--如：3个淘汰两个，则两人都为第三名
function set_lost_or_prize(deskno, sitelist)
	if not deskno then return end
	if not sitelist or #sitelist <= 0 then return end

	local deskinfo = desklist[deskno]
	if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then 
		TraceError("不是比赛场发什么奖？？")
		return 
	end
	local deskdata = deskmgr.getdeskdata(deskno)
	local rounddata = deskdata.rounddata

	local mingci = deskinfo.playercount
	--彩池的总数
	local bonus = deskinfo.at_least_gold * deskinfo.max_playercount

	for i = 1, #sitelist do
		local addgold = 0
		local addexp = 0
		local userinfo = deskmgr.getsiteuser(deskno, sitelist[i])
		if userinfo ~= nil then
			userinfo.chouma = 0
			userinfo.tour_point = 0
            if (tex_dailytask_lib) then
			    xpcall(function()tex_dailytask_lib.set_mingci(userinfo,mingci) end,throw)
            end

			if (mingci > 3) then
				--TraceError(format("很遗憾，您已经在本轮比赛中淘汰出局，您获得名次是:第%d名", mingci))
			elseif(mingci == 3) then
				addgold = math.floor(bonus * 0.2)
				addexp = 5
				--TraceError(format("恭喜，您在本轮比赛中发挥出色，获得第%d名。获得彩池奖金%d金币，经验%d", mingci, addgold, addexp))
			elseif(mingci == 2) then
				addgold = math.floor(bonus * 0.3)
				addexp = 10
				--TraceError(format("恭喜，您在本轮比赛中发挥出色，获得第%d名。获得彩池奖金%d金币，经验%d", mingci, addgold, addexp))
			elseif(mingci == 1) then
				addgold = math.floor(bonus * 0.5)
				addexp = 15
				--TraceError(format("恭喜，您在本轮比赛中发挥出色，获得第%d名。获得彩池奖金%d金币，经验%d", mingci, addgold, addexp))
				--------------------成就---------------------
				xpcall(function()
						achievelib.updateuserachieveinfo(userinfo,2017) --淘汰赛熟手
					end,throw)
				--------------------------------------------
			end
			if(addgold > 0) then
				usermgr.addgold(userinfo.userId, addgold, 0, g_GoldType.deskmatchprize, -1, 1)
			end
			if(addexp > 0) then
				usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), addexp, g_ExpType.deskmatchprize, groupinfo.groupid)
			end
			net_send_prizeorlost(userinfo, mingci, addgold, addexp)
			if addgold > 0 then
				local extra_info = userinfo.extra_info
				extra_info["F08"] = extra_info["F08"] + 1
				userinfo.extra_info = extra_info
				save_extrainfo_to_db(userinfo)
			end

			doStandUpAndWatch(userinfo)
		end
	end

	if deskinfo.playercount <= 0 then
		--得出第一名之后要设置游戏结束
		rounddata.roundcount = 0
		deskinfo.betgold = 0
		deskinfo.usergold = 0
		if deskmgr.get_game_state(deskno) ~= gameflag.notstart then
			deskmgr.set_game_state(deskno, gameflag.notstart)
		end
	end
end

--获取桌面彩池的输赢明细
--这是一个还原的过程，因此每个彩池总金额正确性依赖之前的计算结果
function getdeskpools(sitewininfo)
	local deskpools = {}
	for siteno, wininfo in pairs(sitewininfo) do
		for i = 1, #wininfo.poollist do
			local poolindex = wininfo.poollist[i].poolindex		--彩池ID
			local winchouma = wininfo.poollist[i].poolgold		--此人在本池赢得筹码数
			if(deskpools[poolindex] == nil) then
				deskpools[poolindex] = {chouma = 0,winlist = {}}
			end
			table.insert(deskpools[poolindex].winlist, {siteno = siteno, winchouma = winchouma})
			deskpools[poolindex].chouma = deskpools[poolindex].chouma + winchouma  --还原彩池总筹码
		end
	end
	return deskpools
end

--给农场发送在线时长消息
function send_online_message_tofarm(userinfo, addtime)
    --合法性检查
    --TraceError("给农场发送在线时长消息")
    if gamepkg.name ~= 'tex' or not userinfo then return end
    if not userinfo.farmtree then return end
    
    if addtime == nil or addtime <= 0 then return end
    local tmpstr = "call yysns_farm.sp_insert_tex_message('%s', %d, %d, '%s', '%s')"
    local sql = format(tmpstr, userinfo["userName"], userinfo["nRegSiteNo"], g_FarmType.online, tostring(addtime), '')
    xpcall(function() 
        dblib.dofarmsql(sql, function(dt) trace("给农场发送SQL后，返回信息") end) 
        end,throw)
end

--给农场发德州盘局消息，增加果实成长点
--PaiXing 1:高牌,2:一对,3:两对,4:三条,5:顺子,6:同花,7:葫芦,8:四条,9:同花顺,10:皇家同花顺
function send_fruits_message_tofarm(userinfo, paixing)
    --TraceError("给农场发送增加果实成长点消息")
    if not userinfo then return end
	if not userinfo.desk or not userinfo.site then return end
	local smallbet = desklist[userinfo.desk].smallbet

    if not userinfo.farmtree then return end --农场玩家才发此消息
    if paixing == nil or paixing < 0 or paixing > 10 then return end
    local tmpstr = "call yysns_farm.sp_insert_tex_message('%s', %d, %d, '%s', '%s')"
	local roundstr = format("|%s|%s",tostring(paixing), tostring(smallbet))  --农场1.5倍成长点
	--local roundstr = format("%s",tostring(paixing))
    local sql = format(tmpstr, userinfo["userName"], userinfo["nRegSiteNo"], g_FarmType.fruits, roundstr, '')
	xpcall(function()
			dblib.dofarmsql(sql, function(dt) trace("给农场发送SQL后，返回信息") end)
		end,throw)
end

--记录今日输赢明细
function record_today_detail(userinfo, wingold)
	if not userinfo.desk or not userinfo.site then return end
	local deskno = userinfo.desk
	local siteno = userinfo.site

	local deskinfo = desklist[deskno]
	local sitedata = deskmgr.getsitedata(deskno, siteno)

	local userid = userinfo.userId
	local smallbet = deskinfo.smallbet
	local largebet = deskinfo.largebet
	local betgold = sitedata.betgold
	local betfalg = 0
	if(sitedata.isallin == 1) then betfalg = 1 end
	if(sitedata.islose == 1) then betfalg = -1 end
	local pokeweight = sitedata.pokeweight
	local strpokes5 = ""
	for k,v in pairs(sitedata.pokes5) do
		strpokes5 = strpokes5 .."|".. v 
	end
	local sys_time = os.date("%Y-%m-%d %X", os.time())	--时间
	local sqltmplet = "call sp_add_tex_todaydetail(%d,'%s',%d,%d,%d,%d,%d,'%s','%s','%s');"
	local sql = format(sqltmplet, userid, sys_time, smallbet, largebet, betgold, wingold, betfalg, tostring(pokeweight), strpokes5, '')
	--TraceError(sql)
	--dblib.execute(sql) --不要记录数据库，会卡死
	--同步客户端
	local record = {}
	record["sys_time"] = sys_time
	record["smallbet"] = smallbet
	record["largebet"] = largebet
	record["betgold"] = betgold
	record["wingold"] = wingold
	record["betflag"] = betfalg
	record["pokeweight"] = tostring(pokeweight)
	record["pokes5"] = strpokes5
    if(betgold > 0)then
	    net_send_detailrecord(userinfo, record)
    end

	--记录连胜数,连胜数大于3并且开始输了，或者连胜数大于10
	local winningstreak = userinfo.winningstreak or {count = 0, begintime = os.date("%Y-%m-%d %X", os.time())}
	if wingold > 0 then
		winningstreak.count = winningstreak.count + 1
	else
    	if (wingold < 0 and winningstreak.count >= 3) then
    		sqltmplet = "insert into log_winning_streak (`user_id`,`win_count`,`bigin_time`,`end_time`,`remark`) values(%d, %d, '%s', '%s','');commit;" 
    		sql = format(sqltmplet, userid, winningstreak.count, winningstreak.begintime, sys_time)
    		dblib.execute(sql)
    		winningstreak = {count = 0, begintime = sys_time} --重置计数器
        end
    end
	userinfo.winningstreak = winningstreak
end

--结算
function jiesuan(deskno, complete)
	--TraceError("jiesuan() 开始结算啦~,complete = "..tostring(complete))
	local deskdata = deskmgr.getdeskdata(deskno);
	local deskinfo = desklist[deskno]

	--计算当前彩池情况
	local currdeskpools = getcurrdeskpools(deskno, true)
	net_broadcast_deskpoolsinfo(deskno, currdeskpools)

	--广播玩家手牌的最佳组合
	notify_player_beatpoke(deskno)

	--计算每个玩家的最佳牌型
	local iscomplete = complete or false
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		if sitedata.isinround == 1 and iscomplete then
			sitedata.pokeweight, sitedata.pokes5 = gettypeex(table.mergearray(deskdata.deskpokes, sitedata.pokes))
		else
			sitedata.pokeweight, sitedata.pokes5 = 0, {}
		end
	end

	--检测刷钱处理
	local needTrace = false  --打印桌子信息
	for _, player in pairs(deskmgr.getplayingplayers(deskno)) do
		local sitedata = deskmgr.getsitedata(deskno, player.siteno)
        local can_use_gold = get_canuse_gold(player.userinfo, 1);
		if (deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and deskinfo.desktype ~= g_DeskType.match) and sitedata.betgold > can_use_gold then
			TraceError("第["..deskno.."]桌可能有人刷钱 betgold=" .. sitedata.betgold .. "，gamescore=" .. can_use_gold)
			sitedata.betgold = can_use_gold  --强制变回实际筹码数
			--暂时不强制清空桌子了
			--forceGameOver(player.userinfo)
			--return
			needTrace = true
		end
	end
	if needTrace then TraceError(tostringex(desklist[deskno])) end
	
	--获取结算数据
	local roundsitedatalist = {}
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		if sitedata.isinround == 1 then
			local jiesuandata = {}
			jiesuandata["siteno"] = siteno
			jiesuandata["betgold"] = sitedata.betgold
			jiesuandata["isgiveup"] = sitedata.islose
			jiesuandata["weight"] = sitedata.pokeweight
			table.insert(roundsitedatalist, jiesuandata)
		end
	end

	local pools, sitewininfo = getjiesuandata(roundsitedatalist)
	
	--结算数据中补充牌型数据
	for k_site, v in pairs(sitewininfo) do
		local sitedata = deskmgr.getsitedata(deskno, k_site)
		v.pokes5 = sitedata.pokes5
		v.pokes = sitedata.pokes
		v.weight = sitedata.pokeweight
	end

	--玩家列表
	local sitelist = {}
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		if sitedata.isinround == 1 and sitedata.islose == 0 then
			table.insert(sitelist, siteno)
		end
	end

	--桌面彩池
	local deskpools = getdeskpools(sitewininfo)

	--异常处理，防止有人在结算中途加入游戏
	local jiesuanwait = deskdata.jiesuanwait --{jiesuantime = 0, needwait = 0, someonestart = 0, startplan = nil}
	jiesuanwait.jiesuantime = os.time()
	if complete then
		jiesuanwait.needwait = #deskpools * 5 + 7  --推测平分每个彩池需要5秒钟，基础时间7秒
	else
		jiesuanwait.needwait = 8  --弃牌导致的结算
	end
	--TraceError("jiesuanwait.needwait，推测平分彩池的时间:"..jiesuanwait.needwait)
	jiesuanwait.someonestart = 0
	if(jiesuanwait.startplan ~= nil) then
		jiesuanwait.startplan.cancel()
		jiesuanwait.startplan = nil
	end
	jiesuanwait.startplan = timelib.createplan(
        function()
	        --开始游戏
			--TraceError("jiesuanwait.startplan 游戏开始~~")
			trystartgame(deskno, true)
			jiesuanwait.startplan = nil
        end
    , jiesuanwait.needwait)

	--广播结算协议
	net_broadcastdesk_jiesuan(deskno, sitewininfo, sitelist, deskpools, iscomplete)

	local sitewininfoex = table.clone(sitewininfo)    
    local userinfo=nil
    local playinglist = deskmgr.getdeskdata(deskno).playinglist;
	--加减钱(考虑所有参与了的用户，包括坐下的和已经走了的，不包括同一个座位上走了又新来的)
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
        if sitedata.isinround == 1 then		
            userinfo = sitedata.roundplayer
			local addgold = -sitedata.betgold
			local wingold = 0
			if sitewininfo[siteno] then
				wingold = sitewininfo[siteno].wingold
			end
			addgold = addgold + wingold

            --所有牌局的赢钱的总额
            if addgold > 0 then
                xpcall(function() dblib.execute(string.format(tSqlTemplete.update_gold_system, addgold, 2, 3, 90)) end,throw);
            end

			--记录extra_info
			setextrainfo(userinfo, deskno, sitedata, addgold)

			--春节、端午活动
			if(newyear_lib) then
				xpcall(function() newyear_lib.ongameover(userinfo,addgold,#playinglist) end, throw)
			end
			

			--挂机活动,增加游戏时间
			if(onlineprizelib) then
				local starttime = timelib.db_to_lua_time(deskdata.starttime) or os.time()
				local addtime = os.time() - starttime
				if(addtime > 0) then
				    xpcall(function() onlineprizelib.onGameOver(userinfo, addtime) end, throw)
				end
			end 
			
			-----------------------------------附加的插件------------------------------------

			--计算经验
			local nType, addexp = getAddexp(deskno, addgold)
			--同一个座位的玩家，站起又坐下不能获得经验(chouma > 0说明曾站起来)
			if(deskmgr.getsiteuser(deskno, siteno) == userinfo and userinfo.chouma == 0) then
				usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), addexp, nType, groupinfo.groupid)
			end

			--附加结算信息
			sitewininfoex[siteno] = sitewininfoex[siteno] or _S{win_real_gold = 0, wingold = 0}
			sitewininfoex[siteno].win_real_gold = addgold

			if sitedata.islose == 0 then   --没放弃的人才改钱和经验
                if(deskinfo.desktype ~= g_DeskType.match) then
                    if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) then
        				--+钱 
        				usermgr.addgold(userinfo.userId, addgold, 0, g_GoldType.normalwinlost, -1, 1)
    					record_today_detail(userinfo, addgold)
                    else
                        userinfo.tour_point = userinfo.tour_point + addgold
                    end
                end
	
				local userid = userinfo.userId
				local betgold = -sitedata.betgold
				local nSid = userinfo.nSid
				local curgold = userinfo.gamescore
				local level = usermgr.getlevel(userinfo)
				local joinfee = deskinfo.at_least_gold
				local choushui = get_specal_choushui(deskinfo,userinfo)
                local safegold = userinfo.safegold or 0
                local channel_id = userinfo.channel_id or -1;
                if(deskinfo.desktype ~= g_DeskType.match) then
    				if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) then
    					--两个人玩，抽水加倍
    					if(deskinfo.playercount <= 2) then
    						choushui = choushui * 2
    					end
    					betgold = betgold - choushui
    				else
    					userinfo.tour_point = userinfo.tour_point - sitedata.betgold
    					--比赛场只在比赛开始的第一局收取报名费和抽水
    					if(deskdata.rounddata.roundcount > 1) then
    						joinfee = 0
    						choushui = 0
    					end
                    end
                end
                if (duokai_lib and duokai_lib.is_sub_user(userid) == 1) then
                    sitedata.logsql = format("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d ", 
    										 duokai_lib.get_parent_id(userid), addgold, addexp, 
                                             nSid, curgold, level, joinfee, choushui, safegold, channel_id);--增加频道id
                else
    				sitedata.logsql = format("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d ", 
    										 userid, addgold, addexp, nSid, curgold, level, 
                                             joinfee, choushui, safegold, channel_id);--增加频道id
                end
			end
			
			--不另行通知客户端了，用上面的广播结算协议，慢慢给客户端刷出结果
			if deskmgr.getsiteuser(deskno, siteno) == userinfo and userinfo.chouma == 0 then  --用户还坐在本桌的话
				--赢家修改下次的买注额
				userinfo.chouma = sitedata.gold + wingold
				net_broadcastdesk_goldchange(userinfo)

				if userinfo.chouma >= 1000000 then
					achievelib.updateuserachieveinfo(userinfo,3008)--百万富豪
				end
            end
            --算牌器接口
            if (tex_suanpaiqilib) then
                xpcall(function() tex_suanpaiqilib.on_user_game_over(userinfo) end, throw)
            end

            --观战的人，如果超过10分钟还不坐下，就踢出到大厅
            xpcall(function() kick_timeout_user_from_watchlist(deskinfo) end, throw)   
            --新手首次玩，要客户端发相应的提示
            xpcall(function() new_user_process(userinfo,addgold) end, throw)

            --如果设定了自动顶注，就要在这边自动买筹码到最大携带
            --赋初值，防止出错
            if(userinfo.gameinfo==nil)then
                userinfo.gameinfo={}
                userinfo.gameinfo.is_auto_addmoney=0
                userinfo.gameinfo.is_auto_buy=0
            end

            --如果赢了钱，就买入赢的钱+最大携带，否则买最大携带
            local auto_buy_gold=deskinfo.at_most_gold
            if(userinfo.gameinfo.is_auto_addmoney==1)then
                if(userinfo.chouma>=deskinfo.largebet and userinfo.chouma<=deskinfo.at_most_gold)then
                    local can_use_gold = get_canuse_gold(userinfo, 1);
                    if(can_use_gold>=deskinfo.at_most_gold)then
                        dobuychouma(userinfo, deskno, siteno, deskinfo.at_most_gold)
                    else
                        dobuychouma(userinfo, deskno, siteno, can_use_gold)
                    end
                end
            end

        end
        
	end

	--结算后桌面筹码变0
	deskinfo.betgold = 0

	--todo cw 记日志
	do
		local sql = format("%d, %d, %d, '%s', '%s', ",
						   deskno, desklist[deskno].smallbet, desklist[deskno].desktype, deskdata.starttime, os.date("%Y-%m-%d %X", os.time()))
		for i = 1, 9 do
			local userinfo = deskmgr.getsiteuser(deskno, i)
			local sitedata = deskmgr.getsitedata(deskno, i)
			if sitedata.isinround == 1 then
				sql = sql .. sitedata.logsql .. ","
			else
				sql = sql .. "0,0,0,0,0,0,0,0,0,0,";--增加频道id
			end
			sitedata.isinround = 0
		end
		sql = string.sub(sql, 1, string.len(sql) - 1)
		sql = string.format(tTexSqlTemplete.insertLogRound, sql);
		dblib.execute(sql);
	end

	if deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament then
		--任务
		xpcall(function() dispatch_quest_data_jiesuan(deskno, sitewininfoex)  end,throw)
    end

    if(channellib) then
        xpcall(function() channellib.on_game_over(deskno, sitewininfoex) end, throw);
    end

	--游戏结束
	deskmgr.set_game_state(deskno, gameflag.notstart)

    --游戏开始时清空这局的踢人状态
    if (tex_buf_lib) then
        xpcall(function() tex_buf_lib.set_aleady_kick(deskno,0) end,throw)
    end

	--初始化座位数据
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		deskmgr.initsitedata(deskno, siteno)
	end
	deskdata.playinglist = {}
	deskdata.deskpokes = {}
	deskdata.pools = {}

	--初始化座位数据
	for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
		deskmgr.initsitedata(deskno, siteno)
	end
	deskdata.playinglist = {}
	deskdata.deskpokes = {}
	deskdata.pools = {}
	--重置座位状态
	local sitelist = {}	
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local site_state = hall.desk.get_site_state(deskno, player.siteno)
		local playerinfo = player.userinfo
        local sitedata = deskmgr.getsitedata(deskno, player.siteno)
		local needgold = deskinfo.largebet + deskinfo.specal_choushui + 1

		if ((deskinfo.desktype ~= g_DeskType.match and deskinfo.desktype ~= g_DeskType.tournament and 
             deskinfo.desktype ~= g_DeskType.channel_tournament) and playerinfo.chouma < needgold) then
            local can_use_gold = get_canuse_gold(playerinfo, 1);
			if can_use_gold >= deskinfo.at_least_gold then
				if(site_state ~= SITE_STATE.NOTREADY and site_state ~= SITE_STATE.BUYCHOUMA) then
					hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.BUYCHOUMA, jiesuanwait.needwait + 30)
                end
                tex.setdeskdefaultchouma(playerinfo, deskno)
				net_sendbuychouma(playerinfo, deskno, jiesuanwait.needwait + 30);
			else
				--站起并加入观战
				doStandUpAndWatch(playerinfo,0);
				net_sendbuychouma(playerinfo, deskno);
				--DoUserExitWatch(playerinfo)
				--net_kickuser(playerinfo)
				OnSendUserAutoJoinError(playerinfo, 0, deskinfo.at_least_gold)  --借用一下大厅的发送坐下失败协议
			end
		end
		if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
			--提示玩家被淘汰了
			if playerinfo.chouma < deskinfo.largebet then
                --TraceError(format("site[%d] 的筹码[%d]不足大盲[%d]了,淘汰!", player.siteno, playerinfo.chouma, deskinfo.largebet))
				table.insert(sitelist, player.siteno)
			end
		end

		--重新再取状态
		site_state = hall.desk.get_site_state(deskno, player.siteno)
		if(site_state ~= NULL_STATE and 
		   site_state ~= SITE_STATE.NOTREADY and 
		   site_state ~= SITE_STATE.READYWAIT and
		   site_state ~= SITE_STATE.BUYCHOUMA and
		   site_state ~= SITE_STATE.LEAVE) then
			hall.desk.set_site_state(deskno, player.siteno, SITE_STATE.NOTREADY)
		end
	end

	if((deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and #sitelist > 0) then
		--发送被淘汰信息
		set_lost_or_prize(deskno, sitelist)
	end
    if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		--只剩下一个玩家，自然是第一名
        if(deskinfo.playercount == 1 and deskdata.rounddata.roundcount > 0) then
            local thefirst = 0
            for k_site, v in pairs(sitewininfo) do
                if(v.wingold > 0) then
                    thefirst = k_site
                    break
                end
			end
			--发送被得奖信息
            set_lost_or_prize(deskno, {thefirst})
        end
	end

	OnGameOver(deskno, false, false)
	--广播桌子状态改变
	net_broadcast_deskinfo(deskno)
    --TraceError("jiesuan() 完成结算咯~")
	if (tex_buf_lib) then
		xpcall( function() tex_buf_lib.on_after_gameover(deskno) end, throw)
    end
end

function save_new_user_process(userinfo, process)
    userinfo.gotwelcome = process
    --记录到数据库
    dblib.cache_set(gamepkg.table, {integral = userinfo.gotwelcome}, "userid", userinfo.userId)
end

function new_user_process(userinfo,wingold)
    --1.判断是不是新手
    --2.判断是不是今天玩的第一盘

    if(userinfo==nil)then return end
    if(userinfo.gotwelcome==4)then return end
    --todo新手判断
    --userinfo.reg
    local wingold_tips=0
    if(wingold>0)then wingold_tips=1 end
    --新手给他加200，发个消息给客户端
    --usermgr.addgold(userinfo.userId, 200, 0, g_GoldType.new_user_gold, -1, 1);
    --设定这个人不再是新手了
    save_new_user_process(userinfo, 4)

    --[[
    netlib.send(
            function(buf)
                buf:writeString("GREENGOLD")
                buf:writeByte(wingold_tips)
            end,userinfo.ip,userinfo.port)
    --]]
end

--派发任务数据
function dispatch_quest_data_jiesuan(deskno, sitewininfoex)
    --初始化结算参考数据.
    local gameeventdata = {}
    
    local deskdata = deskmgr.getdeskdata(deskno)
    --记录赢家参考数据
    for siteno, wininfo in pairs(sitewininfoex) do
        local sitedata = deskmgr.getsitedata(deskno, siteno)
        local userinfo = deskmgr.getsiteuser(deskno, siteno)
        local paixing = getpokepaixin(sitedata.pokeweight)
        if userinfo then 	
            --战胜了多少人
            local wincount = 0
            if wininfo.wingold > 0 then
                for k, v in pairs(sitewininfoex) do
                    local sub_sitedata = deskmgr.getsitedata(deskno, k)
                    if v.wingold == 0 or sub_sitedata.pokeweight < sitedata.pokeweight then wincount = wincount + 1 end
                end
            end
    
            --多人比牌
            local mul_count = 0
            local myfrienfsnum = 0--这局我的好友数量
            for k, v in pairs(sitewininfoex) do
                local sub_sitedata = deskmgr.getsitedata(deskno, k)
                if sub_sitedata.islose == 0 then mul_count = mul_count + 1 end
    
                local siteuserinfo = deskmgr.getsiteuser(deskno,k)
                if siteuserinfo and userinfo.friends and userinfo.friends[tonumber(siteuserinfo.userId)] then
                    myfrienfsnum = myfrienfsnum + 1
                end
            end
    
            --------------------------好友成就---------------------------
            if myfrienfsnum >= 1 then
                achievelib.updateuserachieveinfo(userinfo,1017);--一起游戏
    
                achievelib.updateuserachieveinfo(userinfo,2015,0);--知己
                
                achievelib.updateuserachieveinfo(userinfo,3009,0);--死党
    
                if myfrienfsnum >= 4 then
                    achievelib.updateuserachieveinfo(userinfo,2016);--同学会
    
                    achievelib.updateuserachieveinfo(userinfo,2023);--一聚再聚
    
                    achievelib.updateuserachieveinfo(userinfo,3010);--百看不厌
                end
            else
                achievelib.updateuserachieveinfo(userinfo,2015,1);--知己
    
                achievelib.updateuserachieveinfo(userinfo,3009,1);--死党
            end
            -------------------------------------------------------------
    
            --黑桃A
            local has_heitaoA = 0
            for k, v in pairs(sitedata.pokes) do
                if v == 40 then has_heitaoA = 1 end
            end
    
            --TraceError("wininfo:" .. tostringex(wininfo))
            local iswin = 0
            if wininfo.win_real_gold > 0 then
            	iswin = 1
            end
            table.insert(gameeventdata, 
            {
                userid 	= userinfo.userId, 
                iswin 	= iswin,
                wingold = wininfo.win_real_gold,
                smallbet = desklist[deskno].smallbet,
                deskno = deskno,
                data	=
                {
                    [tex.gameref.REF_GOLD]				= wininfo.win_real_gold,
                    [tex.gameref.REF_EXP]				= wininfo.win_real_gold,
                    [tex.gameref.REF_PLAY]				= 1,
                    [tex.gameref.REF_WIN]  				= wininfo.wingold > 0 and 1 or 0,
                    [tex.gameref.REF_ALLIN]  			= sitedata.isallin,
                    [tex.gameref.REF_ZHUANG]  			= deskdata.zhuangsite == siteno and 1 or 0,
    
                    [tex.gameref.REF_DUIZI]  			= paixing == 2 and 1 or 0,
                    [tex.gameref.REF_HULU]  			= paixing == 7 and 1 or 0,
                    [tex.gameref.REF_TONGHUA]  			= paixing == 6 and 1 or 0,
                    [tex.gameref.REF_SHUNZI]  			= paixing == 5 and 1 or 0,
                    [tex.gameref.REF_SANTIAO]  			= paixing == 4 and 1 or 0,
                    [tex.gameref.REF_LIANGDUI]  		= paixing == 3 and 1 or 0,
                    [tex.gameref.REF_DANZHANG]  		= paixing == 1 and 1 or 0,
                    [tex.gameref.REF_HJTONGHUASHUN]  	= paixing == 10 and 1 or 0,
                    [tex.gameref.REF_TONGHUASHUN]  		= paixing == 9 and 1 or 0,
                    [tex.gameref.REF_BOMB]  			= paixing == 8 and 1 or 0,
    
                    [tex.gameref.REF_SANTIAO_FAIED]  	= wininfo.wingold == 0 and paixing >=4  and 1 or 0,
                    [tex.gameref.REF_SHUNZI_FAIED]  	= wininfo.wingold == 0 and paixing >=5  and 1 or 0,
                    
                    [tex.gameref.REF_WIN_COUNT]  		= wincount,
                    [tex.gameref.REF_HEITAOA]  			= has_heitaoA,
                    [tex.gameref.REF_GOLD2000]  		= wininfo.win_real_gold >= 2000 and 1 or 0,
                }
            })
            
            ------------------------派发成就参考数据---------------------
            if wininfo.wingold > 0 then
                ------------------------铜成就----------------------------------------
                achievelib.updateuserachieveinfo(userinfo,1002);--通通有奖
    
                achievelib.updateuserachieveinfo(userinfo,1016,0);--两连胜
    
                if wininfo.win_real_gold >= desklist[deskno].largebet * 100 then
                    achievelib.updateuserachieveinfo(userinfo,1003);--扑克好手
                end
    
                if wininfo.win_real_gold >= 5000 then
                    achievelib.updateuserachieveinfo(userinfo,1010);--赢五千
                end
    
                if wininfo.win_real_gold >= 20000 then
                    achievelib.updateuserachieveinfo(userinfo,1015);--赢两万
                end
                
                if getpokechar(sitedata.pokes) == "AK" then
                    achievelib.updateuserachieveinfo(userinfo,1009);--老滑头
                elseif getpokechar(sitedata.pokes) == "AJ" then
                    achievelib.updateuserachieveinfo(userinfo,1013);--黑杰克
                elseif getpokechar(sitedata.pokes) == "QX" then
                    achievelib.updateuserachieveinfo(userinfo,1014);--卡哇伊
                elseif getpokechar(sitedata.pokes) == "88" then
                    achievelib.updateuserachieveinfo(userinfo,1018);--一路发
                end
    
                if sitedata.isallin == 1 then
                    achievelib.updateuserachieveinfo(userinfo,1012);--全下全赢
                end
                
                ---------------------------银成就-------------------------------
                if wininfo.win_real_gold >= desklist[deskno].largebet * 100 then
                    achievelib.updateuserachieveinfo(userinfo,2008);--扑克高手
                end
    
                if paixing == 4 then
                    achievelib.updateuserachieveinfo(userinfo,2001);--三条
                elseif paixing == 5 then
                    achievelib.updateuserachieveinfo(userinfo,2002);--顺子
    
                    achievelib.updateuserachieveinfo(userinfo,2024);--我爱顺子
                elseif paixing == 6 then
                    achievelib.updateuserachieveinfo(userinfo,2007);--同花
                elseif paixing == 7 then
                    achievelib.updateuserachieveinfo(userinfo,2006);--葫芦
                end
    
                if getpokechar(sitedata.pokes) == "J5" then
                    achievelib.updateuserachieveinfo(userinfo,2004);--杰克五人组
                elseif getpokechar(sitedata.pokes) == "JJ" then
                    achievelib.updateuserachieveinfo(userinfo,2013);--一对鱼钩
                elseif getpokechar(sitedata.pokes) == "AA" then
                    achievelib.updateuserachieveinfo(userinfo,2014);--一飞冲天
                elseif getpokechar(sitedata.pokes) == "KK" then
                    achievelib.updateuserachieveinfo(userinfo,2019);--牛仔上阵
                elseif getpokechar(sitedata.pokes) == "K9" then
                    achievelib.updateuserachieveinfo(userinfo,2021);--老狗出马
                end
    
                achievelib.updateuserachieveinfo(userinfo,2011,0);--三连胜
    
                achievelib.updateuserachieveinfo(userinfo,2022,0);--5连胜
            
                if wininfo.win_real_gold >= 50000 then
                    achievelib.updateuserachieveinfo(userinfo,2012);--赢五万
                end
    
                if wininfo.win_real_gold >= 250000 then
                    achievelib.updateuserachieveinfo(userinfo,2020);--赢25万
                end
                --------------------------金成就-----------------------------
                if wininfo.win_real_gold >= desklist[deskno].largebet * 100 then
                    achievelib.updateuserachieveinfo(userinfo,3018);--出手必赢
    
                    achievelib.updateuserachieveinfo(userinfo,3027);--赢家就是你
                end
    
                if paixing == 10 then
                    achievelib.updateuserachieveinfo(userinfo,3005);--皇家同花顺
                elseif paixing == 9 then
                    achievelib.updateuserachieveinfo(userinfo,3003);--同花顺
                elseif paixing == 8 then
                    achievelib.updateuserachieveinfo(userinfo,3001);--四条
                elseif paixing == 7 then
                    achievelib.updateuserachieveinfo(userinfo,3015);--我爱葫芦
                    achievelib.updateuserachieveinfo(userinfo,3023);--葫芦走天下
                    achievelib.updateuserachieveinfo(userinfo,3025);--葫芦定江山
                elseif paixing == 6 then
                    achievelib.updateuserachieveinfo(userinfo,3014);--我爱同花
                    achievelib.updateuserachieveinfo(userinfo,3021);--同花走天下
                    achievelib.updateuserachieveinfo(userinfo,3022);--同花定江山
                elseif paixing == 5 then
                    achievelib.updateuserachieveinfo(userinfo,3013);--顺子走天下
                    achievelib.updateuserachieveinfo(userinfo,3020);--顺子定江山
                elseif paixing == 4 then
                    achievelib.updateuserachieveinfo(userinfo,3011);--我爱三条
                    achievelib.updateuserachieveinfo(userinfo,3012);--三条走天下
                    achievelib.updateuserachieveinfo(userinfo,3024);--三条定江山
                end
    
                if getpokechar(sitedata.pokes) == "72" then 
                    achievelib.updateuserachieveinfo(userinfo,3002);--大逆转
                elseif getpokechar(sitedata.pokes) == "X2" then 
                    achievelib.updateuserachieveinfo(userinfo,3007);--冠军黑马
                end
    
                achievelib.updateuserachieveinfo(userinfo,3016,0);--10连胜
    
                achievelib.updateuserachieveinfo(userinfo,3026,0);--15连胜
    
                if wininfo.win_real_gold >= 500000 then
                    achievelib.updateuserachieveinfo(userinfo,3017);--赢50万
                end
    
                if wininfo.win_real_gold >= 1000000 then
                    achievelib.updateuserachieveinfo(userinfo,3028);--赢100万
				end

				---------------------------分享游戏事件------------------
				if(dhomelib) then
					local share_data = {};
					share_data.smallbet = desklist[deskno].smallbet 
					share_data.largebet = desklist[deskno].largebet 
					share_data.winchouma = wininfo.win_real_gold 
					share_data.paixing = paixing
					--大赢分享


					if wininfo.win_real_gold >= desklist[deskno].largebet * 200 and paixing>0 then

						xpcall(function() dhomelib.update_share_info(userinfo, 4001, share_data) end, throw)
					end
				end
            else
                ----------------------------铜成就-----------------------------
                achievelib.updateuserachieveinfo(userinfo,1016,1);--两连胜
    
                if paixing >= 5 and sitedata.islose == 0 then
                    achievelib.updateuserachieveinfo(userinfo,2003);--爆冷门
                end
    
                ---------------------------银成就-------------------------------
                achievelib.updateuserachieveinfo(userinfo,2011,1);--三连胜
    
                achievelib.updateuserachieveinfo(userinfo,2022,1);--5连胜
    
                ---------------------------金成就-------------------------------
                achievelib.updateuserachieveinfo(userinfo,3016,1);--10连胜
    
                achievelib.updateuserachieveinfo(userinfo,3026,1);--15连胜
            end
            if (tex_dailytask_lib) then
                xpcall(function() tex_dailytask_lib.on_game_over(userinfo, paixing,deskno,wininfo.wingold) end, throw)
            end
            -------------------------------------------------------------			
        end
    end
    --gameeventdata 代码有bug，用户数据上一局和本局数用户窜了，具体原因待查
    local gameeventdata_ex = {}
    --增加中途退出的用户放入game_event中
    for siteno, sitedata in pairs(deskmgr.getallsitedata(deskno)) do
        local split_info = split(sitedata.logsql, ",")
        local split_user_id = tonumber(split_info[1])
        local split_add_gold = tonumber(split_info[2])
        local split_iswin = 0
        if (split_add_gold > 0) then
            split_iswin = 1
        end
        if (split_add_gold ~= 0) then
            table.insert(gameeventdata_ex, 
            {
                userid 	= split_user_id, 
                iswin 	= split_iswin,
                wingold = split_add_gold,
                smallbet = desklist[deskno].smallbet,
                deskno = deskno,
            })
        end
    end
    eventmgr:dispatchEvent(Event("game_event_ex", gameeventdata_ex));
	--派发参考数据
	eventmgr:dispatchEvent(Event("game_event", gameeventdata));
end

function getpokechar(pokelist)
	local pokestr = ""
	table.sort(pokelist,function(a,b) return tex.pokenum[a] > tex.pokenum[b] end)

	for k,v in pairs(pokelist) do
		pokestr = pokestr .. tex.pokechar[v]
	end

	return pokestr
end
--获取牌型:10(皇家同花顺)，9(同花顺)，8(四条)，7(葫芦)，6(同花)，5(顺子)，4(三条)，3(两对)，2(一对)，1(高牌)
function getpokepaixin(pokeweight)
	if tonumber(pokeweight) == 90001576012 then
		return 10
	else
		return math.floor(pokeweight / (10 ^ 10))
	end
end

--改客户端显示的金币
function useraddviewgold(userinfo, gold, notifyclient)
	local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
	sitedata.gold = sitedata.gold + gold
	ASSERT(sitedata.gold >= 0)
	--通知客户端的桌内用户
	if notifyclient and userinfo.desk then
		--net_broadcastdesk_goldchange(userinfo.desk, userinfo.site, sitedata.gold)
		net_broadcastdesk_goldchange(userinfo)
	end
end

------------------------------------------------------------------------------------------------------------------------------------
dofile("games/tex/tex.net.lua")
------------------------------------------------------------------------------------------------------------------------------------


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

-------------------------------------------------------------------------------------------------------

tex.ontimecheck = function()
	if timelib.time % 10 ~= 0 then return end
	for deskno = 1, #desklist do
		local deskinfo = desklist[deskno]
		local deslaytime = 180
        --处理竞技场大小盲比赛开始后每3分钟翻倍一次
        if(deskinfo and (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament)) then
            local deskdata = deskmgr.getdeskdata(deskno);
            if deskdata.rounddata.roundcount > 0 then
                deskdata.rounddata.timecheck = deskdata.rounddata.timecheck + 10
                if(deskdata.rounddata.timecheck >= deslaytime) then
                    deskdata.rounddata.timecheck = 0
                    --TODO:翻倍需要通知客户端吗?
                    deskinfo.smallbet = deskinfo.smallbet * 2
                    deskinfo.largebet = deskinfo.largebet * 2
					net_broadcast_deskinfo(deskno)
					local sendmsg = ""
					sendmsg = format("比赛过去%d分钟，自动调整小大盲为%d/%d，游戏开局使用新数值", math.floor(deslaytime / 60), deskinfo.smallbet, deskinfo.largebet)
                end
			else
                deskdata.rounddata.timecheck = 0
                deskinfo.smallbet = deskinfo.staticsmallbet
                deskinfo.largebet = deskinfo.staticlargebet
            end
		end
		if(deskinfo and deskinfo.playercount <= 0) then
			local deskdata = deskmgr.getdeskdata(deskno)
			deskdata.rounddata.roundcount = 0
			deskinfo.betgold = 0
			deskinfo.usergold = 0
		end
		--tex.getGameStart(deskno) == true
		if(deskinfo and deskinfo.state_list ~= nil and #deskinfo.state_list ~= 0 and 
		   deskmgr.get_game_state(deskno) ~= gameflag.notstart) then
			   --异常处理开始
			   local all_wait = true
			   local userinfo = nil
			   for i = 1, room.cfg.DeskSiteCount do	
 					if  userlist[hall.desk.get_user(deskno, i)] ~= nil then
						userinfo = userlist[hall.desk.get_user(deskno, i)]
					end
					if  hall.desk.get_site_state(deskno, i) ~= SITE_STATE.WAIT and
						hall.desk.get_site_state(deskno, i) ~= SITE_STATE.READYWAIT and
						hall.desk.get_site_state(deskno, i) ~= SITE_STATE.LEAVE and 
						hall.desk.get_site_state(deskno, i) ~= NULL_STATE then
						all_wait = false
						break
					end	
				end
				if all_wait == true then --所有人都是稳定状态
					TraceError("第" .. tostring(deskno) .. "桌卡死了")					
					TraceError(deskinfo.state_list)
					deskinfo.state_list = {}
					forceGameOver(userinfo)
				end
		end
	end
end

--强制结束牌局,用于四个人都托管之类的
function forceGameOver(userinfo)
    if not userinfo then return end
    TraceError("强制结束牌局,用于四个人都托管之类的")
	local deskno = userinfo.desk
	local deskinfo = desklist[deskno]

	local deskdata = deskmgr.getdeskdata(deskno)
	deskdata.pools = {}
	--竞技场必须在roundcount=0的情况下才能结束
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		deskinfo.betgold = 0
		deskinfo.usergold = 0
		deskdata.rounddata.roundcount = 0
	end
	--都是自动出牌,结束牌局吧
	for i = 1, room.cfg.DeskSiteCount do
		local user = userlist[hall.desk.get_user(userinfo.desk or 0, i) or ""]
		if user then 
			letusergiveup(user)
			doUserStandup(user.key, true)
			DoUserExitWatch(user)
			net_kickuser(user)
		end
    end
    tex.OnAbortGame(userinfo.key)
    eventmgr:dispatchEvent(Event("on_force_game_over", {desk_no = deskno}));
end

--设置玩家在某桌子的默认购买筹码数
tex.setdeskdefaultchouma = function(userinfo, deskno)
	local groupsdata = userinfo.groupsdata or {}
	if not groupsdata[groupinfo.groupid] then 
		groupsdata[groupinfo.groupid] ={} 
	end

	local deskchouma = groupsdata[groupinfo.groupid][deskno] or {}
    local deskinfo = desklist[deskno]
    local userchouma = userinfo.chouma or 0
    userinfo.chouma = 0
	--赋值
	deskchouma.chouma = userchouma
	deskchouma.savetime = os.time()
	groupsdata[groupinfo.groupid][deskno] = deskchouma
	userinfo.groupsdata = groupsdata

    --更新在这个赔率房间的输赢记录
    local extra_info = userinfo.extra_info
    local currtime = deskchouma.savetime
    local smallbet = deskinfo.smallbet

    if(extra_info["F09"][smallbet] == nil or type(extra_info["F09"][smallbet]) ~= "table")then 
        extra_info["F09"][smallbet] = {gametime = 0, bringgold = 0, bringout = 0, wingold = 0}
    else
        --记住玩家站起时赢的钱
        local bringgold = extra_info["F09"][smallbet]["bringgold"] or 0
        local wingold = userchouma - bringgold
        --TraceError(format("bringgold[%d], userchouma[%d], wingold[%d]",bringgold, userchouma, wingold))
        if(wingold < 0)then wingold = 0 end
        extra_info["F09"][smallbet]["wingold"] = wingold
        extra_info["F09"][smallbet]["bringout"] = userchouma
    end
    userinfo.extra_info = extra_info
	save_extrainfo_to_db(userinfo)
end

--获取玩家在某桌子的默认购买筹码数
tex.getdeskdefaultchouma = function(userinfo, deskno, timeout)
	local deskinfo = desklist[deskno]
	if not deskinfo then return {} end

	local extra_info = userinfo.extra_info
	local smallbet = deskinfo.smallbet
	local mingold = deskinfo.at_least_gold
	local maxgold = deskinfo.at_most_gold
	local usergold = get_canuse_gold(userinfo, 1)
	local retarr = {}
	retarr.defaultchouma = -1
	retarr.halfhour = 0  --半小时前来过本桌

	local groupsdata = userinfo.groupsdata or {}
	if not groupsdata[groupinfo.groupid] then 
		groupsdata[groupinfo.groupid] ={} 
	end

	local deskchouma = groupsdata[groupinfo.groupid][deskno] or {}

	--优先使用之前在这桌子的数值
--[[
    if(deskchouma.savetime and os.time() - deskchouma.savetime < 1800) then
		--TIMEOUT是在游戏中输光了还没站起来的情况
		if(not timeout or timeout == 0) then
			retarr.halfhour = 1
			retarr.defaultchouma = deskchouma.chouma or maxgold
		end
	end
]]--

	--再判断是否在这种赔率的桌子上赢过钱
    --[[
	if(type(extra_info["F09"][smallbet]) == "table")then
		local gametime = extra_info["F09"][smallbet]["gametime"] or 0
		local interval = extra_info["F09"].interval or 1800
		local wingold = extra_info["F09"][smallbet]["wingold"] or 0
        local bringout = extra_info["F09"][smallbet]["bringout"] or 0
		--限制条件:赢过钱，时间不超过半小时，身上还有足够的钱进入(买宝石存钱的暂时不管他)
		if(wingold > 0 and os.time() - gametime < interval and usergold >= mingold) then
		    retarr.halfhour = 2
            retarr.defaultchouma = bringout
		    mingold = mingold + wingold
            if(retarr.defaultchouma > mingold) then mingold = retarr.defaultchouma end
            if(mingold > usergold) then mingold = usergold end
		    if(mingold > maxgold) then maxgold = mingold end
        end
        --TraceError(format("ID:%d, wingold:%d, mingold:%d, maxgold:%d, deskchouma:%d", userinfo.userId, wingold, mingold, maxgold, deskchouma.chouma or 0))
	end
    ]]--
	--默认规则
	if(retarr.defaultchouma < mingold or retarr.defaultchouma > maxgold) then
		--1.若玩家身上的筹码超过该该牌桌最大限制的两倍，则默认为最大显示
		if usergold >= maxgold * 2 then
			retarr.defaultchouma = maxgold
		--2.若玩家身上的筹码大于最小限制的两倍且小于最大限制的两倍，则默认显示身上的筹码/2
		elseif usergold > mingold * 2 and usergold < maxgold * 2 then
			retarr.defaultchouma = math.floor(usergold / 2)
		--3.若玩家身上的筹码大于最小显示且小于最小限制的两倍，则默认显示最小带入筹码数
		else
			retarr.defaultchouma = mingold
		end
	end

	--合法性检查
	if(retarr.defaultchouma < mingold) then
		retarr.defaultchouma = mingold
	end
	if(retarr.defaultchouma > maxgold) then
		retarr.defaultchouma = maxgold
	end
	if(retarr.defaultchouma > usergold) then retarr.defaultchouma = usergold end
    
	if(retarr.defaultchouma < 0) then retarr.defaultchouma = 0 end
    retarr.maxgold = maxgold
    retarr.mingold = mingold

	return retarr
end

--所有人都掉线，直接结束牌局
tex.OnAbortGame = function(userKey)
    local userinfo = userlist[userKey]
    local deskno = userinfo.desk
	if (deskno == nil) then
		TraceError("游戏强制结束，为啥桌子为空呢"..debug.traceback())
		return
	end
    deskmgr.set_game_state(deskno, gameflag.notstart)  --直接转为未开始状态
	
    --初始化桌子和座位的数据
    deskmgr.initdeskdata(deskno)
    hall.desk.set_site_state(deskno, NULL_STATE)
    for j = 1, room.cfg.DeskSiteCount do
        deskmgr.initsitedata(deskno, j)
	end

	for i = 1, room.cfg.DeskSiteCount do
		local userKey = hall.desk.get_user(deskno, i)
		local siteUserInfo = userlist[userKey]
        if (siteUserInfo ~= nil) then
			doUserStandup(userKey, false)
			DoKickUserOnNotGame(siteUserInfo.key, false)
		end
	end

	--广播桌子状态改变
	net_broadcast_deskinfo(deskno)
    --OnGameOver(deskno, false) 
end

tex.OnUserReLogin = function(userinfo)
    TraceError('OnUserReLogin');
    --取消自动托管出牌状态
    userinfo.gamerobot = false

    --发送桌状态给客户端，通知重新登录的客户端当前的桌面信息
    tex.arg.reloginuserinfo = userinfo

    --设置用户状态为ready状态
    hall.desk.set_site_start(userinfo.desk, userinfo.site, startflag.ready)

    --同步用户状态
    --usermgr.setUserState(userinfo,deskmgr.get_game_state(userinfo.desk),true)

    --发送其他人的剩余牌
    --net_send_pokes_and_playerinfo(userinfo)
    net_send_resoredesk(userinfo);

    --通知其他客户端有用户已经成功地再次登录，需要点亮头像
    --broadcast_lib.borcast_desk_event_ex_old('NTGR', userinfo.desk)
end

--得到用户游戏信息
tex.OnBeforeUserLogin = function(userinfo, data, alldata)
    local userdata = deskmgr.getuserdata(userinfo)

	local giftstr = data["icon_info"] or ""	--礼物图标

	userdata.giftinfo, userdata.using_gift_item = gift_str2tbl(userinfo, giftstr)		--using_gift_item为nil表示未装备礼物    
    eventmgr:dispatchEvent(Event("already_init_gift", {user_id=userinfo.userId}));

	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	if(userinfo.gift_today ~= sys_today) then --日期不符
		userinfo.gift_today = sys_today	--更新今天日期
		userinfo.buygiftgold = 0	--今天购买额
		userinfo.salegiftgold = 0	--今天销售额
        update_giftinfo_db(userinfo)
	end
	userinfo.winningstreak = {count = 0, begintime = os.date("%Y-%m-%d %X", os.time())} --连胜记录

	userinfo.upgradetime = data["upgradetime"] or os.time()

	--强化之后的玩家信息
	--F00:加入遊戲時間,F01:最大贏取遊戲幣,F02:最佳手牌,F03:玩過局數,F04:贏過局數,
	--F05:最高擁有遊戲幣,F06:好友數量,F07:今日輸贏,获得经验,F08:赢过的单桌比赛次数
    --F09:在各种赔率房间的输赢记录
	local extra_info = nil
	local sz_extra_info = data["extra_info"]
	--memchched给加上双引号了,必须去掉不然无法还原
	if(string.sub(data["extra_info"], 1, 1) == "\"") then
		sz_extra_info = string.sub(data["extra_info"], 2, string.len(data["extra_info"]) - 1)
	end
	--替换掉\
	sz_extra_info = string.gsub (sz_extra_info, "\\", "")
	extra_info = table.loadstring(sz_extra_info) or {}

	--加入遊戲時間(理论上这个值不会变的)
	extra_info["F00"] = data["reg_time"]
	--最大贏取遊戲幣
	if(extra_info["F01"] == nil) then extra_info["F01"] = 0 end
	--最佳手牌
	if(extra_info["F02"] == nil) then
		extra_info["F02"] = {pokeweight = 0, pokes5 = {}}
	end
	--玩過局數
	if(extra_info["F03"] == nil) then extra_info["F03"] = 0 end
	--贏過局數
	if(extra_info["F04"] == nil) then extra_info["F04"] = 0 end
	--最高擁有遊戲幣
	if(extra_info["F05"] == nil) then extra_info["F05"] = 0 end
	--好友數量
	if(extra_info["F06"] == nil) then extra_info["F06"] = 0 end
	--今日輸贏
	if(extra_info["F07"] == nil) then extra_info["F07"] = 0 end
	--赢过单桌比赛次数
	if(extra_info["F08"] == nil) then extra_info["F08"] = 0 end
    --在各种赔率房间的输赢记录
	if(extra_info["F09"] == nil) then extra_info["F09"] = {last_time = 0, interval = 1800} end

	userinfo.extra_info = extra_info

	local dbtoday = data["today"] 	--数据库的今天日期
	userinfo.dbtoday = dbtoday
	local todayexp = data["todayexp"] or 0	--今天获得经验
	userinfo.gameInfo.todayexp = todayexp

	--判断日期(不是今日就得重置)
	if(sys_today ~= dbtoday) then --日期不符
        userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
        userinfo.gameInfo.todayexp = 0
		dblib.cache_set(gamepkg.table, {todayexp = 0}, "userid", userinfo.userId)

		userinfo.extra_info["F07"] = 0
		save_extrainfo_to_db(userinfo)
    end

    
    --如果还在游戏中并且不是比赛场，就先强制退出游戏
    if(userinfo.desk and userinfo.site)then
        local deskinfo = desklist[userinfo.desk]
        --[[
        if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament)then
            douserforceout(userinfo)
            --改为不是重登录
            userinfo.nRet = 1
        end
        --]]
    end    
end

--桌面管理器
deskmgr = 
{
	--得到游戏状态
	get_game_state = function(deskno)
		ASSERT(deskno)
		--trace("getgamestate(" .. deskno .. ")")
		local deskdata = deskmgr.getdeskdata(deskno);
		if not deskdata then
			return gameflag.notstart
		end
		return deskdata.state;
	end,
	
	--设置游戏状态
	set_game_state = function(deskno, gamestate)
		ASSERT(deskno)
		ASSERT(gamestate)
		local deskdata = deskmgr.getdeskdata(deskno);
		deskdata.state = gamestate;
	end,
	--获取桌子数据
	getdeskdata = function(deskno)
		return desklist[deskno].gamedata
	end,

	--获取座位数据
	getsitedata = function(deskno, siteno)
		if desklist[deskno] and desklist[deskno].site[siteno] then
			return desklist[deskno].site[siteno].gamedata
		else
			TraceError(format("无效座位号deskno[%d], siteno[%d]", deskno, siteno))
			return {}
		end
	end,
	--获取玩家数据
	getuserdata = function(userinfo)
		return userinfo.gameInfo
	end,
	--获取座位userinfo
	getsiteuser = function(deskno, siteno)
		return userlist[hall.desk.get_user(deskno, siteno) or ""]
	end,

	--初始化桌子数据
	initdeskdata = function(deskno)
		trace("initdeskdata()")
		--这个和牌局没有关系没有关系,踢人卡相关需要
		local org_kickinfo = desklist[deskno].gamedata.kickinfo
		local org_kickedlist = desklist[deskno].gamedata.kickedlist
		desklist[deskno].gamedata = tex.init_desk_info()
		if (org_kickinfo ~= nil) then
			desklist[deskno].gamedata.kickinfo = org_kickinfo	
		end
		if (org_kickedlist ~= nil) then
			desklist[deskno].gamedata.kickedlist = org_kickedlist	
		end
		for i = 1, room.cfg.DeskSiteCount do
			desklist[deskno].gamedata.rounddata.sitecount[i] = 0
		end
	end,

	--初始化座位数据
	initsitedata = function(deskno, siteno)
		desklist[deskno].site[siteno].gamedata = tex.init_site_info()
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

	--获取所有的座位信息，包括空座位
	getallsitedata = function(deskno)
		local ret = {}
		for i = 1, room.cfg.DeskSiteCount do
			local siteinfo = deskmgr.getsitedata(deskno, i)
			if siteinfo then
				ret[i] = siteinfo
			end
		end
		return ret
	end,

	--获取在玩座位号列表, 返回value为{siteno, userinfo}的table, 顺序按座位号, [*不包括*]放弃的用户
	getplayingplayers = function(deskno)
		local ret = {}
		local players = deskmgr.getplayers(deskno)
		for i = 1, #players do
			local sitedata = deskmgr.getsitedata(deskno, players[i].siteno)
			if(sitedata.isinround == 1 and sitedata.islose == 0) then
				table.insert(ret, players[i])
			end
		end
		return ret
	end,

	--获取前一个有用户的座位号(都不在玩则返回空), 不包括放弃的用户
	getprevsite = function(deskno, siteno)
		ASSERT(siteno and siteno > 0 and siteno <= room.cfg.DeskSiteCount, "getnextsite获取siteno非法"..tostring(siteno))
		local currsite = siteno
		local userinfo, sitedata
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
			sitedata = deskmgr.getsitedata(deskno, currsite) or {}
		until userinfo and sitedata.islose == 0 and sitedata.isinround == 1
		return currsite
	end,

	--获取下一个在玩的座位号(都不在玩则返回空), 不包括放弃的用户
	getnextsite = function(deskno, siteno)
		ASSERT(siteno and siteno > 0 and siteno <= room.cfg.DeskSiteCount, "getnextsite获取siteno非法"..tostring(siteno))
		local currsite = siteno
		local userinfo, sitedata
		repeat
			if currsite == room.cfg.DeskSiteCount then 
				currsite = 1
			else
				currsite = currsite + 1
			end
			if currsite == siteno then
				return nil
			end
			userinfo = userlist[hall.desk.get_user(deskno, currsite)]
			sitedata = deskmgr.getsitedata(deskno, currsite) or {}
		until userinfo and sitedata.islose == 0 and sitedata.isinround == 1
		return currsite
	end,
}

deskmgr = _S(deskmgr)
--[[function on_meet_event_charm(e)
    --TraceError("魅力农夫的见面事件处理")
    local time1 = os.clock() * 1000
    local touserinfo = e.data.observer
    if(not touserinfo) then return end
    local meet_userinfo = e.data.subject
    --暂时只支持在座位上见面
    if(not meet_userinfo.site)then return end

    net_send_charmchange(meet_userinfo, touserinfo)
    local time2 = os.clock() * 1000
    if (time2 - time1 > 50)  then
        TraceError("魅力农夫见面事件,时间超长:"..(time2 - time1))
    end
end
--]]
tex.on_start_server = function()    
    --------------------魅力农夫的见面事件处理----------------------------
   -- eventmgr:removeEventListener("meet_event", on_meet_event_charm);
    --eventmgr:addEventListener("meet_event", on_meet_event_charm);
    --------------------魅力农夫的见面事件处理----------------------------	
end

-----------------------------------------------------------------------------------------------------------
---------------------------发送数据函数结束-----------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--座位状态机  https://docs.google.com/Doc?id=dd4q9wgh_16dgzx9hvc
tex.init_state = function()
	hall.desk.register_site_states(newStrongTable(
	{
		NOTREADY 	= {ss_notready_offline,		ss_notready_timeout,	60},
		READYWAIT 	= {ss_readywait_offline,	NULL_FUNC, 				0},
		PANEL 		= {ss_panel_offline, 		ss_panel_timeout, 		21},
		WAIT 		= {ss_wait_offline, 		NULL_FUNC,				0},
		BUYCHOUMA 	= {ss_buychouma_offline, 	ss_buychouma_timeout,	30},
		LEAVE		= {NULL_FUNC, 				ss_leave_timeout,		180},
	}))
	hall.desk.register_site_state_change(ss_onstatechange)
end

--[[
	to wangyu
	踢人卡实现代码
	获取桌子上的用户信息方法如下
						deskmgr.getplayers(deskno)
	返回内容结构如下	{{ siteno=i, userinfo=userinfo },{ siteno=i, userinfo=userinfo }...}	

--]]

--收到买筹码，自动坐下
function onrecvautosite(buf)
    local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;

    --判断合法性
    local gold = buf:readInt()
    local deskno = userinfo.desk
    local siteno = 1		--让dobuychouma自动去挑座位
    local deskinfo = desklist[deskno]

    --只有坐下时才有这个限制，所以从buy_chouma_limit中拿出来了
	local freshman_limit = 3000;
    if(userinfo.gameinfo==nil)then
        userinfo.gameinfo={}
        userinfo.gameinfo.is_auto_buy=0
        userinfo.gameinfo.is_auto_addmoney=0
    end
    --因为在玩游戏时，如果有自动重买或自动顶注，就不需要做新手限制，防止玩游戏时弹出
    if(userinfo.gameinfo.is_auto_buy==0 and userinfo.gameinfo.is_auto_addmoney==0)then
    	if((deskinfo.desktype == g_DeskType.normal or deskinfo.desktype==g_DeskType.channel or deskinfo.desktype==g_DeskType.channel_world) and deskinfo.smallbet == 1 and userinfo.gamescore > freshman_limit) then
            --新手场限制
    		local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
                netlib.send(function(buf) 
                    buf:writeString("TEXXST")
                    end, userinfo.ip, userinfo.port, borcastTarget.playingOnly);
    		return -2
        end
     end
    --通过了买筹码的限制
    if(buy_chouma_limit(userinfo)==1)then
        dobuychouma(userinfo, deskno, siteno, gold)
    end
end


--收到手机端用来判断网络连接状态（网速）
function onrecv_check_net(buf)
    local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
    --判断合法性
    local str_time = buf:readString()
    netlib.send(function(buf) 
                    buf:writeString("CHECK_NET")
                    buf:writeString(str_time)
                    end, userinfo.ip, userinfo.port);
end


--收到手机端刷新屏幕时恢复
function onrecv_mobile_refresh(buf)
	if true then return end; --这个协议不用了，万一收到的话，不作处理
    local userinfo = userlist[getuserid(buf)]; 
    local user_states=0
	

    if not userinfo then  
   		user_states=1   --重新登陆
    end; 

    if not userinfo.desk or userinfo.desk <= 0 then 
    	user_states=2   --在大厅，并在线
    end;

    if(user_states==0)then --玩家在玩或在观战

        hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)
		local deskdata, sitedata = deskmgr.getdeskdata(userinfo.desk), deskmgr.getsitedata(userinfo.desk, userinfo.site)
		
		local deskpokes = deskdata.deskpokes
		local gold = sitedata.gold
		local betgold = sitedata.betgold
		local sitepokes = sitedata.pokes
		local mybean = userinfo.gamescore
		OnSendDeskInfo(userinfo, userinfo.desk)
		net_send_resoredesk(userinfo)
		--net_broadcastdesk_playerinfo(userinfo.desk)
		--刷新彩池信息
		OnSendDeskPoolsInfo(userinfo, deskdata.pools)
	    	
    	return
    end        

    --判断合法性
    local str_time = buf:readString()
 	netlib.send(function(buf) 
            buf:writeString("MO_REFRESH")
            buf:writeByte(user_states or 0) 
            end, userinfo.ip, userinfo.port);
end

--更新玩家的GPS信息，并且告诉这个玩家其他玩家的GPS信息
function onrecv_user_gpsinfo(buf)
    local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    
    --更新或新建用户gps信息
   	local function update_user_gps_info(userinfo)
   		local sql="insert into user_gps_info (user_id,latitude,longitude,last_login_time) value (%d,'%s','%s',now()) ON DUPLICATE KEY UPDATE latitude='%s',longitude='%s',last_login_time=now();";
   		sql=string.format(sql,userinfo.userId,userinfo.xpos,userinfo.ypos,userinfo.xpos,userinfo.ypos);
   		--TraceError("sql="..sql)
   		dblib.execute(sql);
   	end
   	
   	--判断是否在线
   	local function is_online(user_id)
        if (usermgr.GetUserById(user_id) == nil) then
            return 0
        else
            return 1
        end
   	end
   	
   	--发送所有GPS用户信息
   	local function send_user_gps_info(userinfo)
 
   		local sql="select user_id,latitude,longitude,face,nick_name,gold,sex,user_gps_info.last_login_time AS last_login_time from user_gps_info LEFT JOIN users ON user_gps_info.user_id=users.id";
   		dblib.execute(sql,
	        function(dt)
	            if dt and #dt > 0 then
	                netlib.send(function(buf) 
					buf:writeString("GPSPOSI")
					buf:writeInt(#dt)
					local len=100
					if (#dt<len) then len=#dt end
                    for i = 1,len do					   
		   			    	buf:writeInt(dt[i].user_id)	
							buf:writeString(dt[i].latitude)	
			            	buf:writeString(dt[i].longitude)
						    buf:writeString(dt[i].face)
						    buf:writeString(dt[i].nick_name)							
						    buf:writeInt(dt[i].gold)
						    buf:writeInt(is_online(dt[i].user_id))
						    buf:writeInt(dt[i].sex)						    
						    buf:writeString(dt[i].last_login_time)						  
				    end
					
				 end, userinfo.ip, userinfo.port);
	            end
	       end)	
   	end
   	
   	local x_pos = buf:readString();
   	local y_pos = buf:readString();
   	local stat = buf:readByte();
   	
   	userinfo.xpos=x_pos;
   	userinfo.ypos=y_pos;
   	--更新用户GPS信息
   	update_user_gps_info(userinfo);
   	--向这个用户发送其他人的GPS信息
   	if(stat==1)then
   		send_user_gps_info(userinfo)
   	end
   	
end

--得到玩家当前可用筹码
--[[
@param is_include_self_chouma 0:不包含自己筹码可用的金币
                            1:包含自己筹码可用的金币
--]]
function get_canuse_gold(user_info, is_include_self_chouma)
	if not user_info then return 0 end
	--得到玩家桌子上的钱

    local usergold = 0; 
	--多开
	if(duokai_lib ~= nil)then
		local parent_id = user_info.userId; 
		if(duokai_lib.is_sub_user(user_info.userId) == 1) then
			parent_id = duokai_lib.get_parent_id(user_info.userId);
		end

		local all_sub_user_arr = duokai_lib.get_all_sub_user(parent_id);
		if(all_sub_user_arr ~= nil) then
			for user_id, v in pairs(all_sub_user_arr) do
                if(is_include_self_chouma == nil or is_include_self_chouma == 0 or (is_include_self_chouma == 1 and user_id ~= user_info.userId)) then
    				local sub_user_info = usermgr.GetUserById(user_id);
    				if(sub_user_info ~= nil and sub_user_info.desk and sub_user_info.site) then
                        local deskinfo = desklist[sub_user_info.desk];
                        if(deskinfo.desktype ~= g_DeskType.match) then
        					local sitedata = deskmgr.getsitedata(sub_user_info.desk, sub_user_info.site);
        					if(sitedata.gold + sitedata.betgold > 0) then
        						usergold = usergold + sitedata.gold + sitedata.betgold;
        					elseif(sub_user_info.chouma ~= nil)then
        						usergold = usergold + sub_user_info.chouma;
                            end
                        end
                    end
                end
			end
		end

		if(usergold > user_info.gamescore) then
			usergold = user_info.gamescore;
		end

		if(usergold > 0) then
			return user_info.gamescore - usergold;
		else
			return user_info.gamescore
		end
	else
		if user_info.site~=nil and (is_include_self_chouma == nil or is_include_self_chouma == 0) then 	
            local deskinfo = desklist[user_info.desk];
            if(deskinfo.desktype ~= g_DeskType.match) then
    			local sitedata = deskmgr.getsitedata(user_info.desk, user_info.site)
    			usergold = sitedata.gold + sitedata.betgold
    			if usergold == 0 and user_info.chouma then
    				return user_info.gamescore - user_info.chouma
    			else
    				return user_info.gamescore - usergold
                end
            else
                return user_info.gamescore
            end
		else
			return user_info.gamescore
		end
	end
end


tex.init_map = function()
	cmdGameHandler = {
		["TXNINF"] = onrecnquestdeskinfo,		--想知道桌子參數
		["TXNTBC"] = onrecvquestbuychouma,      --想买筹码
		["TXRQBC"] = onrecvbuychouma,			--点兑换筹码
		["TXRQST"] = onrecvgamestart,			--用户请求开始
		["TXRQFQ"] = onrecvgiveup,				--点放弃
		["TXRQXZ"] = onrecvxiazhu,				--点下注
		["TXRQGZ"] = onrecvgenzhu,				--点跟注
		["TXRQBX"] = onrecvbuxiazhu,			--点不下注（过牌）
		["TXRQAI"] = onrecvallin,				--点全下
		["RQPEXT"] = onrecvgetextrainfo_achieveinfo, --请求某个人的extra_info和achieve_info
		["RQMIXT"] = onrecvgetextrainfo,		--请求某个人的extra_info
		["TXNBBS"] = onrecvgetbbsurl,		--请求论坛验证串
		["TXNTDT"] = onrecvtodaydetail,		--请求今日明细
        ["TXAUSI"] = onrecvautosite,      --收到买筹码，自动坐下


		----------表情礼品模块----------
		["TXGFSP"] = onrecvopenshop,			--请求商品列表
		["TXEMOT"] = onrecvsendemot,			--点发表情
        ["TXPROPNUM"] = onrecvpresendgift,      --送礼物预处理
		["TXGIFT"] = onrecvsendgift,			--点送礼物
		["TXGFLT"] = onrecvgetgiftinfo,			--请求某人的礼物详情
		["TXGFUS"] = onrecvusinggift,			--请求穿某礼物
		["TXGFDP"] = onrecvdropgift,			--请求扔某礼物
		["TXGFSL"] = onrecvsalegift,			--请求卖掉某礼物
		["TXGFRS"] = onrecvgiftresponse,		--请求发送礼物回应
		["TXGFPH"] = onrecvgetgiftrank,			--请求礼品排行榜


		----------保险箱模块----------
		["TXSBIF"] = onrecvclicksafebox,		--点击请求保险箱信息
		["TXSBSG"] = onrecvchangesafeboxgold,	--请求存取游戏币
		["TXSBPW"] = onrecvsafeboxpassword,		--请求密码相关
        ["TXSBFE"] = onrecvgetuseremail,        --请求得到玩家的email

		-----------成就模块-----------
		["TXAMWC"] = achievelib.onrecvgetcompleteachieve,--得到完成了的成就ID
		["TXAMZJ"] = achievelib.onrecvgetlastcompleteachieve,--得到最近完成的成就ID
		["TXAMFJ"] = achievelib.onrecvgetprize,--动画播放完成后发奖

		---------活动请求送礼--------------
		["RQGIFT"] = on_reve_give_betagife,--活动请求送礼

		---------请求欢迎和教程--------------
		["TXWELCM"] = on_recve_quest_welcome,--请求显示欢迎界面
		["TXNOSHOW"] = on_recve_notshow_welcome,--请求以后不要显示欢迎界面
		["STOV"] = on_recve_study_over,--学习了一遍教程，看看是否要奖励800筹码

		---------手机相关--------------
		["CHECK_NET"] = onrecv_check_net,--手机查询网络连接问题
		["MO_REFRESH"] = onrecv_mobile_refresh,--手机查询网络连接问题
		["GPSPOSI"] = onrecv_user_gpsinfo,		--手机用户初始化gps信息
		
		---------请求农场圣诞树信息--------------
        --[[
        ["TXMTREE"] = on_recve_quest_farmtree,
        ["TXMTIME"] = on_recve_query_delaytime,  --请求查询多久加一次在线时长
        ["TXADDTM"] = on_recve_add_onlinetime, --增加在线时间
        --]]
		--[[
			to wangyu
			踢人卡协议放在这里
				
		--]]
	}
    --加载插件的回调
	for k, v in pairs(cmdHandler_addons) do
		ASSERT(not cmdHandler[k])
		cmdHandler[k] = v
	end
end
tex.init_state();

tex.init_map();




