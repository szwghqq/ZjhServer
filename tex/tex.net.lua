---------------------------------网络接口-------------------------------------------------------------
--广播结算亮牌 
function net_broadcastdesk_jiesuan(desk, sitewininfo, sitelist, deskpools, iscomplete)
	trace("net_broadcastdesk_jiesuan()")
	local sendFun = function(userinfo)
		local userbetgold = 0
		local userwingold = 0
		local userpoke5 = {}
		if(userinfo.site ~= nil) then
			local sitedata = deskmgr.getsitedata(desk, userinfo.site)
			if(sitedata ~= nil) then
				if(sitedata.betgold ~= nil) then userbetgold = sitedata.betgold end
				if(sitedata.pokes5 ~= nil) then userpoke5 = sitedata.pokes5 end
			end
			local winsitedata = sitewininfo[userinfo.site]
			if(winsitedata ~= nil and winsitedata.wingold ~= nil) then
				userwingold = winsitedata.wingold
			end
		end
		netlib.send(
			function(buf)
				buf:writeString("TXNTGO")
				local count = 0
				for k, v in pairs(sitewininfo) do
					count = count + 1
                end
                buf:writeByte(iscomplete and 1 or 0)
				buf:writeInt(count);
				for siteno, wininfo in pairs(sitewininfo) do
					buf:writeByte(siteno)				--座位号
					buf:writeInt(wininfo.wingold)		--赢了多少钱
					buf:writeString(wininfo.weight)		--牌有多大，是个数字。第一位代表牌型。1-9，但不含皇家同花顺。
					buf:writeInt(#wininfo.poollist)		--获取到的彩池信息
					for i = 1, #wininfo.poollist do
						buf:writeByte(wininfo.poollist[i].poolindex)		--1=主池 2=彩池1 3=彩池2 ...
						buf:writeInt(wininfo.poollist[i].poolgold)		--明细
					end
				end
				buf:writeInt(userbetgold)							--具体玩家的已下注
				buf:writeInt(userwingold)	--具体玩家分到的钱
				buf:writeInt(#userpoke5)			--自己的最佳组合牌，应为5张
				for i = 1, #userpoke5 do		
					buf:writeByte(userpoke5[i])	
                end

                --附加协议
    			buf:writeByte(#sitelist)  --在玩而且没放弃的人
    			for i = 1, #sitelist do
    				local sitedata = deskmgr.getsitedata(desk, sitelist[i])
                    buf:writeByte(sitelist[i])	
    				buf:writeByte(#sitedata.pokes)	
    				for j = 1, #sitedata.pokes do  --底牌
    					buf:writeByte(sitedata.pokes[j])
    				end
    				buf:writeString(sitedata.pokeweight)
    				buf:writeByte(#sitedata.pokes5)	
    				for j = 1, #sitedata.pokes5 do --最佳牌型
    					buf:writeByte(sitedata.pokes5[j])	
    				end
    			end
    			
    			--彩池信息
    			buf:writeByte(#deskpools)
    			for i = 1, #deskpools do --每个彩池
    				buf:writeInt(deskpools[i].chouma)  --彩池金额
                    buf:writeByte(#deskpools[i].winlist)
    				for j =1, #deskpools[i].winlist do	--分钱人数
    					buf:writeByte(deskpools[i].winlist[j].siteno)
    					buf:writeInt(deskpools[i].winlist[j].winchouma)
    				end
                end
			end
		, userinfo.ip, userinfo.port);
	end

	--广播桌面
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(desk,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(desk,i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                sendFun(playingUserinfo)
            end
            if(playingUserinfo == nil) then
                TraceError("用户结算桌子上有个用户的userlist信息为空")
                hall.desk.clear_users(deskno,i)
            end
        end
	end
	local deskinfo = desklist[desk] or {}
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            sendFun(watchinginfo) 
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
    --广播桌面(结束)
end

--广播某人投降
function net_broadcastdesk_giveup(desk, siteno)
	trace("net_broadcastdesk_giveup()")
    local user_info = deskmgr.getsiteuser(desk, siteno);
	netlib.broadcastdeskex(
		function(buf)
			buf:writeString("TXNTTX")
			buf:writeByte(siteno);	--座位号
            buf:writeString(user_info ~= nil and user_info.nick or "");
		end
	, desk, borcastTarget.all);
end

--显示面板
function net_showpanel(userinfo, rule)
	--TraceError("net_showpanel(" .. userinfo.site .. ")")
	--TraceError(rule)
	netlib.send(
		function(buf)
			buf:writeString("TXNTPN")
			buf:writeByte(rule.gen)
			buf:writeByte(rule.jia)
			buf:writeByte(rule.allin)
			buf:writeByte(rule.fangqi)
			buf:writeByte(rule.buxiazhu)
			buf:writeByte(rule.xiazhu)
			buf:writeInt(rule.min)
			buf:writeInt(rule.max)
			buf:writeInt(rule.gengold)
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--显示自动面板
function net_show_autopanel(userinfo, rule)
	--TraceError("net_show_autopanel(" .. userinfo.site .. ")")
	--TraceError(rule)
	netlib.send(
		function(buf)
			buf:writeString("TXNTAP")
			buf:writeByte(rule.guo)
			buf:writeByte(rule.guoqi)
			buf:writeByte(rule.genrenhe)
			buf:writeByte(rule.gen)
			buf:writeInt(rule.gengold)
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--广播某让某座位改钱
function net_broadcastdesk_goldchange(userinfo)
    --TraceError(format("广播某让某座位改钱"))
    if not userinfo then return end
    local deskno = userinfo.desk
    local siteno = userinfo.site
    if not deskno or not siteno then return end
    local usergold = userinfo.chouma
    if usergold == 0 then
        local sitedata = deskmgr.getsitedata(deskno, siteno)
        usergold = sitedata.gold
    end
    --TraceError(format("广播某让某座位改钱,site%d,gold:%d", siteno, usergold))
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("TXNTGC")
			buf:writeByte(siteno);	--座位号
			buf:writeInt(usergold);	--新钱数
		end
	, deskno, borcastTarget.all);
end

--给一个人发送桌子信息
function OnSendDeskInfo(userinfo, deskno)
	if not deskno or not desklist[deskno] then return end
	local deskinfo = desklist[deskno]
	local showsitbutton = 1  --是否显示坐下按钮
    if tex.getGameStart(deskno) == true then
        if (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then showsitbutton = 0 end
    end
    if (deskinfo.playercount >= deskinfo.max_playercount) then showsitbutton = 0 end
    if userinfo.site ~= nil then showsitbutton = 0 end
    --TraceError("是否显示["..userinfo.userId.."]坐下按钮:"..showsitbutton)
    local to_desk_type = deskinfo.desktype
     local to_noble_gold = 0
    if to_desk_type == g_DeskType.nobleroom and viproom_lib then
		if viproom_lib.get_room_spec_type(deskno) == 1 then 
			to_desk_type = g_DeskType.VIP
		end
		to_noble_gold = viproom_lib.get_to_noble_gold(deskinfo.smallbet)
		room_level = viproom_lib.get_room_spec_level(deskno)
    end
	netlib.send(
		function(buf)
            buf:writeString("TXNINF")
            buf:writeInt(deskno)
            --名称
            buf:writeString(deskinfo.name)
            --桌子类型:1普通,2比赛桌,3VIP 10贵族场
            buf:writeByte(to_desk_type)
            --是否快速桌
            buf:writeByte(deskinfo.fast)
            --桌面筹码数
            buf:writeInt(deskinfo.betgold)
            --桌子的玩家筹码
            buf:writeInt(deskinfo.usergold)
            --解锁等级
            buf:writeInt(deskinfo.needlevel)
            --小盲
            buf:writeInt(deskinfo.smallbet)
            --大盲
            buf:writeInt(deskinfo.largebet)
            --金钱下限
            buf:writeInt(deskinfo.at_least_gold)
            --金钱上限
            buf:writeInt(deskinfo.at_most_gold)
            --抽水
            buf:writeInt(deskinfo.specal_choushui)
            --最少开局人数
            buf:writeByte(deskinfo.min_playercount)
            --最大开局人数
            buf:writeByte(deskinfo.max_playercount)
            --当前在玩人数
            buf:writeByte(deskinfo.playercount)
            --是否显示坐下按钮
            buf:writeByte(showsitbutton)
            --桌子的频道ID
            buf:writeInt(deskinfo.channel_id or -1)
            --贵族房需要的底注：
            buf:writeInt(to_noble_gold)
            --贵族房的等级
            buf:writeInt(room_level or 0)
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--给玩家发送今天明细
function net_send_todaydetail(userinfo, dt)
    if not userinfo then return end;
    --通知客户端发送完毕
    local NoticeEnd = function(userinfo)
        netlib.send(
            function(buf)
                buf:writeString("TXNTDTEND");
            end,userinfo.ip,userinfo.port);
    end
    --没有记录
    if not dt or #dt <= 0 then
        netlib.send(
            function(buf)
                buf:writeString("TXNTDT");
                buf:writeInt(0);
            end,userinfo.ip,userinfo.port);
        NoticeEnd(userinfo);
        return;
    end
    --如果记录过多，需要分包发送
    local packlimit = 20;  --每个包20条记录
    local packlist = {};
    for i=1, #dt do
        local packindex = math.floor(i/packlimit) + 1;
        if not packlist[packindex] then packlist[packindex] = {} end;
        table.insert(packlist[packindex], dt[i]);
    end
    --TraceError(packlist)
    for i = 1, #packlist do
        local sendlist = packlist[i];
        netlib.send(
            function(buf)
                buf:writeString("TXNTDT");
                buf:writeInt(#sendlist);
                for i = 1, #sendlist do
                    buf:writeString(sendlist[i]["sys_time"]);
                    buf:writeInt(sendlist[i]["smallbet"]);
                    buf:writeInt(sendlist[i]["largebet"]);
                    buf:writeInt(sendlist[i]["betgold"]);
                    buf:writeInt(sendlist[i]["wingold"]);
                    buf:writeInt(sendlist[i]["betflag"]);
                    buf:writeString(sendlist[i]["pokeweight"]);
                    buf:writeString(sendlist[i]["pokes5"]);
                end;
            end,userinfo.ip,userinfo.port);
    end;
    NoticeEnd(userinfo);
end
--给玩家发送单条的明细
function net_send_detailrecord(userinfo, record)
    if not userinfo or not record then return end;
    netlib.send(
        function(buf)
            buf:writeString("TXNTSGDT");
            buf:writeString(record["sys_time"]);
            buf:writeInt(record["smallbet"]);
            buf:writeInt(record["largebet"]);
            buf:writeInt(record["betgold"]);
            buf:writeInt(record["wingold"]);
            buf:writeInt(record["betflag"]);
            buf:writeString(record["pokeweight"]);
            buf:writeString(record["pokes5"]);
        end,userinfo.ip,userinfo.port);
end
--桌内广播桌子信息
function net_broadcast_deskinfo(deskno)
    if not deskno or not desklist[deskno] then return end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendDeskInfo(playingUserinfo, deskno)
            end
            if(playingUserinfo == nil) then
                TraceError("异常信息,广播桌子信息时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendDeskInfo(watchinginfo, deskno)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
end

--发送得奖或被淘汰的信息
function net_send_prizeorlost(userinfo, mingci, givegold, addexp)
    --TraceError(format("发送得奖或被淘汰的信息:mingci[%d], givegold[%d], addexp[%d]", mingci, givegold, addexp))
    if not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("TXNTPZ")
            buf:writeInt(userinfo.userId)
            buf:writeByte(userinfo.site or 0)
            buf:writeByte(mingci)
            buf:writeInt(givegold)
            buf:writeInt(addexp)
        end
    , userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--发送天天经验红利
function net_send_daygiveexp(userinfo, addexp)
    if not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("TXNTXP")
            buf:writeInt(userinfo.userId);
            buf:writeByte(userinfo.site or 0);	--对应座位号
            buf:writeInt(usermgr.getlevel(userinfo));	--等级
            buf:writeInt(addexp)  
        end
    , userinfo.ip, userinfo.port);
end

--发送学习教程领奖成功
function net_send_study_prize(userinfo, addgold)
    if not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("STOV")
            buf:writeInt(userinfo.userId);
            buf:writeInt(addgold)  
        end
    , userinfo.ip, userinfo.port);
end

--弹出桌子左下角窗口信息
function net_sendsystemmsg(userinfo, msgtype, msg)
	--TraceError("net_sendsystemmsg()"..msgtype)
    --TraceError("net_sendsystemmsg()"..msg)
    if not msgtype or not msg then return end
	netlib.send(
		function(buf)
			buf:writeString("TXNTMG")
			buf:writeInt(tonumber(msgtype))
            buf:writeInt(userinfo.userId)
			buf:writeString(_U(msg))
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--弹出投注窗口 ,defaultgold是默认购买数
function net_sendbuychouma(userinfo, deskno, timeout)
    local eventdata = {handle=0, userinfo=userinfo};
    eventmgr:dispatchEvent(Event("on_send_buy_chouma", eventdata));

    if(eventdata.handle == 1) then
        return;
    end

    --TraceError("net_sendbuychouma()")
    if not userinfo or not deskno then return end
    local siteno = userinfo.site or 1		--让dobuychouma坐在原来的位置上或自动去挑座位
    local gold = 0
    local deskinfo = desklist[deskno]
    local retarr = tex.getdeskdefaultchouma(userinfo, deskno, timeout)
    local defaultchouma = retarr.defaultchouma 
    if not defaultchouma then return end
    local halfhour = retarr.halfhour or 0
    local mingold = retarr.mingold or deskinfo.at_least_gold
    local maxgold = retarr.maxgold or deskinfo.at_most_gold
    local usergold = get_canuse_gold(userinfo, 1);
    local is_auto_buy_chouma=false
    if(maxgold > usergold) then
        maxgold = usergold
    end

    --防止30分钟内玩家赢了很多钱，站起再坐下后出现买入数大于房间允许的最大数的问题
   --[[ TraceError(retarr.mingold..":::"..deskinfo.at_least_gold..":::"..retarr.maxgold..":::"..deskinfo.at_most_gold)
    if(mingold>deskinfo.at_least_gold)then
        halfhour=0
        mingold=deskinfo.at_least_gold
        retarr.mingold=mingold
    end

    if(maxgold>deskinfo.at_most_gold)then
        halfhour=0
        maxgold=deskinfo.at_most_gold
        retarr.maxgold=maxgold
    end
    --]]
    if(userinfo.gameinfo==nil)then 
        userinfo.gameinfo={}
        userinfo.gameinfo.is_auto_buy=0
        userinfo.gameinfo.is_auto_addmoney=0
    end
    --得到玩家桌子上的钱
    if(buy_chouma_limit(userinfo)==1)then
            if(userinfo.gameinfo.is_auto_buy==1 and userinfo.gameinfo.is_auto_addmoney==0)then --自动重买规则
                gold = userinfo.gameinfo.auto_buy_gold or retarr.defaultchouma --自动买入上次买的钱或买默认筹码
                if(usergold>=gold)then  --用户的钱至少要够买默认筹码
                    dobuychouma(userinfo, deskno, siteno, gold)
                    is_auto_buy_chouma=true
                end
            elseif(userinfo.gameinfo.is_auto_buy==1 and userinfo.gameinfo.is_auto_addmoney==1 )then --同时选了自动买入和自动顶注，另外，单选自动顶注规则是在游戏结算时另外去处理的。
                if(usergold>=deskinfo.at_most_gold)then
                    gold = deskinfo.at_most_gold
                else
                    gold = usergold
                end
                dobuychouma(userinfo, deskno, siteno, gold)
                is_auto_buy_chouma=true
            end
            if(is_auto_buy_chouma==false)then --弹买的窗口
                	netlib.send(
            		function(buf)
            			buf:writeString("TXNTBC")
                        buf:writeInt(deskno)
            			buf:writeInt(mingold)
            			buf:writeInt(maxgold)
            			buf:writeInt(usergold)
                        buf:writeInt(defaultchouma)
                        buf:writeInt(timeout or 0)  --是否提示超时
                        buf:writeByte(0)  --是否提醒半小时前来过
            		end
            	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
            end
    end 
 
end

--广播某个用户不下注
function net_broadcastdesk_buxiazhu(desk, siteno)
	trace("net_broadcastdesk_buxiazhu()")
    local user_info = deskmgr.getsiteuser(desk, siteno);
	netlib.broadcastdeskex(
		function(buf)
			buf:writeString("TXNTBX")
			buf:writeByte(siteno);	--操作人
            buf:writeString(user_info ~= nil and user_info.nick or "");
		end
	, desk, borcastTarget.all);
end

--给一个人发送桌子彩池信息
function OnSendDeskPoolsInfo(userinfo, pools)
	if not userinfo then return end
	if not pools or #pools <= 0 then return end
	netlib.send(
		function(buf)
			buf:writeString("TXNTDM")
			buf:writeInt(#pools)
			for i = 1, #pools do
				buf:writeInt(pools[i])
			end
		end
	, userinfo.ip, userinfo.port)
end

--桌内广播桌子彩池信息
function net_broadcast_deskpoolsinfo(deskno, pools)
    if not deskno or not desklist[deskno] then return end
    if not pools or #pools <= 0 then return end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendDeskPoolsInfo(playingUserinfo, pools)
            end
            if(playingUserinfo == nil) then
                TraceError("异常信息,广播桌子信息时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendDeskPoolsInfo(watchinginfo, pools)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
end

--广播某个用户下注
function net_broadcastdesk_xiazhu(deskno, siteno, ntype)
	trace("net_broadcastdesk_xiazhu()")
    if not deskno or not siteno then return end

    local deskdata = deskmgr.getdeskdata(deskno)
    local sitedata = deskmgr.getsitedata(deskno, siteno)

	local userinfo = deskmgr.getsiteuser(deskno, siteno)
    local usersex = 0
    local user_nick = "";
    if(userinfo ~= nil) then 
        usersex = userinfo.sex
        user_nick = userinfo.nick;
    end --站起了

    local betgold = sitedata.betgold
    local currbet = sitedata.betgold - sitedata.roundbet
	netlib.broadcastdeskex(
		function(buf)
			buf:writeString("TXNTXZ")
			buf:writeByte(siteno);		--扔钱座位
			buf:writeInt(betgold);		--总的下注
            buf:writeInt(currbet);	    --本轮下注
			buf:writeByte(usersex); 	--性别
			buf:writeByte(ntype); 		--下注类型  下注 2=加注 3=底注 4=梭哈 5=跟注 6=重登录
            buf:writeString(user_nick);
		end
	, deskno, borcastTarget.all);
end

--获取庄、大小盲信息
function get_relogin_sitelist(deskno)
	local deskdata = deskmgr.getdeskdata(deskno)
	local siteinfolist = {}
	for k, v in pairs(deskdata.playinglist) do
		local siteinfo = {}
		local sitedata = deskmgr.getsitedata(deskno, v)
		siteinfo.siteno = v
		siteinfo.betgold = sitedata.betgold  --总下注筹码
		siteinfo.islose = sitedata.islose
		siteinfo.isallin = sitedata.isallin
        siteinfo.currbet = sitedata.betgold - sitedata.roundbet  --本轮下注筹码
		siteinfolist[k] = siteinfo
	end
	return siteinfolist
end

--给某个用户恢复桌面
function net_send_resoredesk(userinfo)
	--TraceError("net_send_resoredesk()" .. tostringex(userinfo.userId))
    if not userinfo or not userinfo.desk then return end

    local deskno = userinfo.desk
    local siteno = userinfo.site or 0
	local deskdata = deskmgr.getdeskdata(deskno)
    local sitedata = {}
    if(siteno > 0) then
        sitedata = deskmgr.getsitedata(deskno, siteno)
    end
	local siteinfolist = get_relogin_sitelist(deskno)
    local zhuangsite = deskdata.zhuangsite
	local deskpokes = deskdata.deskpokes
	local gold = sitedata.gold or 0
	local betgold = sitedata.betgold or 0
	local sitepokes = sitedata.pokes or {}
	local mybean = userinfo.gamescore

	netlib.send(
		function(buf)
			buf:writeString("TXNTRD")
            buf:writeByte(zhuangsite)
			buf:writeInt(#deskpokes)
			for i = 1, #deskpokes do
				buf:writeByte(deskpokes[i])
			end
			buf:writeInt(#sitepokes)
			for i = 1, #sitepokes do
				buf:writeByte(sitepokes[i])
			end
			buf:writeInt(gold)
			buf:writeInt(betgold)
			buf:writeInt(mybean)

			buf:writeInt(#siteinfolist)
			for i = 1, #siteinfolist do
				buf:writeByte(siteinfolist[i].siteno)
				buf:writeInt(siteinfolist[i].betgold)
				buf:writeByte(siteinfolist[i].islose)
				buf:writeByte(siteinfolist[i].isallin)
                buf:writeInt(siteinfolist[i].currbet)
			end

		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly);
end

--告诉用户德州豆
function net_sendmybean(userinfo, gold)
	netlib.send(
		function(buf)
			buf:writeString("TXREMYB");
			buf:writeInt(gold);	--局已下
		end
	, userinfo.ip, userinfo.port, borcastTarget.all)
end
--TODO:显示离线玩家功能
function get_user_extra_data(userid)
    local userinfo = usermgr.GetUserById(userid)
    if(userinfo ~= nil) then
        local retdata = {}
        retdata.userid     = userinfo.userId              --用户ID
        retdata.nick       = userinfo.nick                --昵称
        retdata.sex        = userinfo.sex                 --性别
        retdata.from       = userinfo.szChannelNickName   --来自
        retdata.gold       = userinfo.gamescore           --金币
        retdata.exp        = usermgr.getexp(userinfo)
        retdata.face       = userinfo.imgUrl
        retdata.extra_info = userinfo.extra_info
        return retdata
    else
       --从数据库读取
        return get_user_extradata_from_db(userid)
    end
end

--返回玩家的extrainfo和achieveinfo
function net_send_user_extrainfo_achieveinfo(userinfo, request_userinfo)
    if not userinfo or not request_userinfo then return end
    local userid     = request_userinfo.userId              --用户ID
    local nick       = request_userinfo.nick                --昵称
    local sex        = request_userinfo.sex                 --性别
    local from       = request_userinfo.szChannelNickName   --来自
    local gold       = request_userinfo.gamescore           --金币
    local exp        = usermgr.getexp(request_userinfo)
    local face       = request_userinfo.imgUrl
    local charmlevel = request_userinfo.charmlevel or 0  --农场魅力等级
    local charmvalue = request_userinfo.charmvalue or 0  --农场魅力值
    local charmgold = request_userinfo.charmgold or 0    --魅力值额外增加的筹码
    local channel_id = request_userinfo.short_channel_id or -1 --默认显示频道短号

    --判断日期(不是今日就得重置)
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    if(sys_today ~= userinfo.dbtoday) then --日期不符
		--重置并同步
		userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
		userinfo.gameInfo.todayexp = 0
		dblib.cache_set(gamepkg.table, {todayexp = 0}, "userid", userinfo.userId)

		userinfo.extra_info["F07"] = 0
        save_extrainfo_to_db(request_userinfo)
    end

    local extra_info = request_userinfo.extra_info
    local reg_date = string.sub(extra_info["F00"],1,10)
    local max_win = extra_info["F01"]
    local pokes5 = {}
    --哈希排不了序，只能这样
    for k,v in pairs(extra_info["F02"].pokes5) do
        pokes5[k] = v
    end
    local pokeweight = extra_info["F02"].pokeweight
    local sortbypokenum = function(poke1, poke2)
        local pokenum1 = tex.pokenum[poke1] or 0
        local pokenum2 = tex.pokenum[poke2] or 0
        return pokenum1 < pokenum2
    end
    table.sort(pokes5, sortbypokenum)
    local play_count = extra_info["F03"]
    local win_count = extra_info["F04"]
    local max_gold = extra_info["F05"]
    local friend_count = extra_info["F06"]
    local today_winlost = extra_info["F07"]
    local deskmatchwin = extra_info["F08"]

    --------------------拿到完成成就的信息-----
    local completetable = achievelib.getcompleteachieve(request_userinfo)
    -------------------------------------------

    -------------------拿到VIP信息-------------
    --local isvip = viplib.get_user_vip_info(request_userinfo) and 1 or 0
    local vip_level = viplib.get_vip_level(request_userinfo)
    --TraceError("大面板个人信息vip等级:"..vip_level)
    -------------------------------------------

    --每日达人完成的次数
    local success
    local tex_daren_count=0
    if(tex_dailytask_lib)then
         success, tex_daren_count = xpcall(function() return tex_dailytask_lib.get_tex_daren_count(request_userinfo) end, throw)
    end
    
    local kick_card_count = 0
    local speaker_count = 0
    if(request_userinfo.propslist ~= nil) then 
        kick_card_count = request_userinfo.propslist[tex_gamepropslib.PROPS_ID.KICK_CARD_ID] or 0
        speaker_count = request_userinfo.propslist[tex_gamepropslib.PROPS_ID.SPEAKER_ID] or 0
    end

	netlib.send(
		function(buf)
    	    buf:writeString("RQPEXT");
    	    --基本信息
    	    buf:writeInt(userid)    --用户ID
    	    buf:writeString(nick)   --昵称
    	    buf:writeByte(sex)      --性别
    	    
			if(request_userinfo.mobile_mode~=nil and request_userinfo.mobile_mode==2)then 
				buf:writeString(string.HextoString(from).._U("（手机客户端）")) 
			else 
				buf:writeString(string.HextoString(from)) --来自 
			end
    	    buf:writeInt(gold)      --金币
            buf:writeInt(exp)       --经验 
    	    buf:writeString(face)   --头像
    
    	    buf:writeString(reg_date)
    	    buf:writeInt(max_win)
    	    --最好牌型
            buf:writeString(pokeweight)
    	    buf:writeByte(#pokes5)
            for i = 1, #pokes5 do
    	        buf:writeByte(pokes5[i])
    	    end
    	    buf:writeInt(play_count)
    	    buf:writeInt(win_count)
    	    buf:writeInt(max_gold)
    	    buf:writeInt(friend_count)
    	    buf:writeInt(today_winlost)
            buf:writeInt(deskmatchwin)
            buf:writeString(os.time())--系统当前时间
            buf:writeInt(#completetable)--成就ID集合
            for i = 1,#completetable do
                buf:writeInt(tonumber(completetable[i]["id"]))
                buf:writeString(completetable[i]["time"])
            end
            buf:writeByte(vip_level)--VIP等级
            buf:writeInt(charmlevel)
            buf:writeInt(charmvalue)
            buf:writeInt(charmgold)
            buf:writeInt(channel_id)
            buf:writeInt(tex_daren_count or 0)--增加参数：每日任务完成次数，int
            buf:writeInt(request_userinfo.home_status or 0) --家园的开通情况
            buf:writeInt(kick_card_count)--踢人卡张数
            buf:writeInt(request_userinfo.safeboxnum or 0)--保险箱格数
            buf:writeInt(speaker_count)--小喇叭数量
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--返回玩家的extrainfo
function net_send_user_extrainfo(userinfo, request_userinfo)
    if not userinfo or not request_userinfo then return end

    local userid     = request_userinfo.userId              --用户ID
    local nick       = request_userinfo.nick                --昵称
    local sex        = request_userinfo.sex                 --性别
    local from       = request_userinfo.szChannelNickName   --来自
    local gold       = request_userinfo.gamescore           --金币
    local exp        = usermgr.getexp(request_userinfo)
    local face       = request_userinfo.imgUrl 
    local charmlevel = request_userinfo.charmlevel or 0  --农场魅力等级
    local charmvalue = request_userinfo.charmvalue or 0  --农场魅力值
    local charmgold  = request_userinfo.charmgold or 0    --魅力值额外增加的筹码
    local channel_id = request_userinfo.short_channel_id or -1; --默认显示频道短号

    --判断日期(不是今日就得重置)
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    if(sys_today ~= userinfo.dbtoday) then --日期不符
		--重置并同步
		userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
		userinfo.gameInfo.todayexp = 0
		dblib.cache_set(gamepkg.table, {todayexp = 0}, "userid", userinfo.userId)

		userinfo.extra_info["F07"] = 0
        save_extrainfo_to_db(request_userinfo)
    end

    local extra_info = request_userinfo.extra_info
    if not extra_info then return end
    local reg_date = string.sub(extra_info["F00"],1,10)
    local max_win = extra_info["F01"]
    local pokes5 = {}
    --哈希排不了序，只能这样
    for k,v in pairs(extra_info["F02"].pokes5) do
        pokes5[k] = v
    end
    local pokeweight = extra_info["F02"].pokeweight
    local sortbypokenum = function(poke1, poke2)
        local pokenum1 = tex.pokenum[poke1] or 0
        local pokenum2 = tex.pokenum[poke2] or 0
        return pokenum1 < pokenum2
    end
    table.sort(pokes5, sortbypokenum)
    local play_count = extra_info["F03"]
    local win_count = extra_info["F04"]
    local max_gold = extra_info["F05"]
    local friend_count = extra_info["F06"]
    local today_winlost = extra_info["F07"]
    local deskmatchwin = extra_info["F08"]
    
    -------------------拿到VIP信息-------------
    --local isvip = viplib.get_user_vip_info(request_userinfo) and 1 or 0
    local vip_level = viplib.get_vip_level(request_userinfo)
    -------------------------------------------
    local tex_daren_count = 0
    if(request_userinfo.wdg_huodong ~= nil) then
        tex_daren_count = request_userinfo.wdg_huodong.daren_count or 0
    end

    local kick_card_count = 0
    local speaker_count = 0
    if(request_userinfo.propslist ~= nil) then 
        kick_card_count = request_userinfo.propslist[tex_gamepropslib.PROPS_ID.KICK_CARD_ID] or 0
        speaker_count = request_userinfo.propslist[tex_gamepropslib.PROPS_ID.SPEAKER_ID] or 0
    end

    
	netlib.send(
		function(buf)
    	    buf:writeString("RQMIXT");
    	    --基本信息
    	    buf:writeInt(userid)    --用户ID
    	    buf:writeString(nick)   --昵称
    	    buf:writeByte(sex)      --性别
    	    if(request_userinfo.mobile_mode~=nil and request_userinfo.mobile_mode==2)then

    	    	buf:writeString(string.HextoString(from).._U("（手机客户端）"))
    	    else
    	    	buf:writeString(string.HextoString(from))   --来自
    	    end
    	    buf:writeInt(gold)      --金币
            buf:writeInt(exp)       --经验 
    	    buf:writeString(face)   --头像
    
    	    buf:writeString(reg_date)
    	    buf:writeInt(max_win)
    	    --最好牌型
            buf:writeString(pokeweight)
    	    buf:writeByte(#pokes5)
            for i = 1, #pokes5 do
    	        buf:writeByte(pokes5[i])
    	    end
    	    buf:writeInt(play_count)
    	    buf:writeInt(win_count)
    	    buf:writeInt(max_gold)
    	    buf:writeInt(friend_count)
    	    buf:writeInt(today_winlost)
            buf:writeInt(deskmatchwin)
            buf:writeByte(vip_level)--是否是VIP标志
            buf:writeInt(charmlevel)
            buf:writeInt(charmvalue)
            buf:writeInt(charmgold)
            buf:writeInt(channel_id)
            buf:writeInt(tex_daren_count)--每日任务完成次数
            buf:writeInt(kick_card_count)--踢人卡张数
            buf:writeInt(request_userinfo.safeboxnum or 0)--保险箱格数
            buf:writeInt(request_userinfo.home_status or 0)--家园开通与否的状态
            buf:writeInt(speaker_count)--小喇叭数量
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--广播某个玩家的魅力更新
function net_broadcastdesk_charmchange(userinfo)
    if not userinfo then return end
    local site = userinfo.site or 0
    local charmlevel = userinfo.charmlevel or 0
    local charmvalue = userinfo.charmvalue or 0
    local charmgold = userinfo.charmgold or 0
    local sendFun = function(buf)
        buf:writeString("CHARMINFO")
        buf:writeInt(userinfo.userId)
        buf:writeByte(site)
        buf:writeInt(charmlevel)
        buf:writeInt(charmvalue)
        buf:writeInt(charmgold)
    end
    --广播给整个桌子
    if(userinfo.desk and userinfo.site)then
        netlib.broadcastdesk(sendFun, userinfo.desk, borcastTarget.all)
    end
end

--通知某个玩家的我魅力更新
function net_send_charmchange(myuserinfo, touserinfo)
    if not myuserinfo or not touserinfo then return end
    local site = myuserinfo.site or 0
    local charmlevel = myuserinfo.charmlevel or 0
    local charmvalue = myuserinfo.charmvalue or 0
    local charmgold = myuserinfo.charmgold or 0
    netlib.send(function(buf)
                    buf:writeString("CHARMINFO")
                    buf:writeInt(myuserinfo.userId)
                    buf:writeByte(site)
                    buf:writeInt(charmlevel)
                    buf:writeInt(charmvalue)
                    buf:writeInt(charmgold)
                end, touserinfo.ip, touserinfo.port)
end


--广播某玩家点了开始
function net_broadcastdesk_ready(desk, sitenowhostart)
	trace("net_broadcastdesk_ready()")
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("TXREST")
			buf:writeByte(sitenowhostart);
		end
	, desk, borcastTarget.all);
end

--广播游戏开始
function net_broadcastdesk_gamestart(desk)
	trace("net_broadcastdesk_gamestart()")
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("TXNTGT")
		end
	, desk, borcastTarget.all);
end

--广播桌面牌
function net_broadcast_deskpokes(deskno)
	--TraceError("net_broadcast_deskpokes()")
	local deskdata = deskmgr.getdeskdata(deskno)
	local deskpokes = deskdata.deskpokes
	netlib.broadcastdeskex(
		function(buf)
			buf:writeString("TXNTDP")
			buf:writeInt(#deskpokes)
			for i = 1, #deskpokes do
				buf:writeByte(deskpokes[i])
			end
		end
	, deskno, borcastTarget.all);
end

--踢走用户
function net_send_BBS_URL(userinfo, bbs_auth)
	netlib.send(
		function(buf)
			buf:writeString("TXNBBS");
            buf:writeString(bbs_auth);
		end
	, userinfo.ip, userinfo.port)
end

--踢走用户
function net_kickuser(userinfo)    
	netlib.send(
		function(buf)
			buf:writeString("REKU");
		end
	, userinfo.ip, userinfo.port)
    eventmgr:dispatchEvent(Event("on_user_kicked", {user_info = userinfo}));
end

--广播所有人状态
function net_broadcastdesk_playerinfo(desk)
	trace("net_broadcastdesk_playerinfo()")
	netlib.broadcastdesk(
		function(buf)
			local len = 0;
			local data = {};
			for _, player in pairs(deskmgr.getplayers(desk)) do
				local state = hall.desk.get_site_state(desk, player.siteno)
				local statecode = 0
				if state == SITE_STATE.NOTREADY then statecode = 2 end
				if state == SITE_STATE.READYWAIT then statecode = 1 end
				if state == SITE_STATE.LEAVE then statecode = 4 end
                if state == SITE_STATE.PANEL then statecode = 5 end
                if state == SITE_STATE.BUYCHOUMA then statecode = 6 end
               
				local timeout, delay = hall.desk.get_site_timeout(desk, player.siteno)

                --delay在买表情后重新计算面板的情况下不准，需要重新读取满格时间，而不能靠计划本身API获取满格时间
                local delay = SITE_STATE.PANEL[3]
                local deskinfo = desklist[desk]
		        if deskinfo.fast == 1 then delay = tex.cfg.fastdelay end

                 --减2秒是考虑到网络延时导致客户端计时未结束就被强制处理了
                --timeout = timeout - 2
				if timeout < 0 then
                    timeout = 0
                    delay = 0
                end
				table.insert(data, {site = player.siteno, state = statecode, time = timeout, delay = delay});
				len = len + 1
				--trace("siteno,statecode,timeout=".. player.siteno .. "," .. statecode .. "," .. timeout)
			end
			buf:writeString("TXNTZT")
			buf:writeInt(len)
			for i = 1, #data do
				buf:writeByte(data[i].site);		--座位号
				buf:writeByte(data[i].state)		--状态号
				buf:writeByte(data[i].time)		--超时时间
                buf:writeByte(data[i].delay)	--超时时间
			end
		end
	, desk, borcastTarget.all);
end

--播放发牌动画
function net_send_fapai(userinfo, sitelist, siteno, pokes)
	netlib.send(
		function(buf)
			buf:writeString("TXREFP")
            buf:writeByte(siteno)
            buf:writeInt(#sitelist)
			for i = 1, #sitelist do
				buf:writeByte(sitelist[i])
			end
			buf:writeInt(#pokes)
			local prevpokeid = -1
			for i = 1, #pokes do
				buf:writeByte(pokes[i])
				if(prevpokeid == pokes[i] or pokes[i]<=0 or pokes[i] > 52) then
					TraceError(format("桌子号:%d，发牌异常", userinfo.desk or 0))
					TraceError(desklist[userinfo.desk])
				end
				prevpokeid = pokes[i]
			end
		end
	, userinfo.ip, userinfo.port)
end

--播放发牌动画(给观战用户)
function net_send_fapai_forwatching(deskno, sitelist)
    local pokes = {55, 55}
    local desk_info = desklist[deskno]
    for k, v in pairs(desk_info.watchingList) do
        local send = 1;
        if(duokai_lib) then
            local sub_user_id = duokai_lib.get_cur_sub_user_id(v.userId);
            if(sub_user_id > 0) then
                local sub_user_info = usermgr.GetUserById(sub_user_id)
                if(sub_user_info.desk and sub_user_info.site and sub_user_info.desk == deskno) then
                    send = 0;
                end
            end
        end
        if (duokai_lib == nil or  --没有多开模块
            (duokai_lib and duokai_lib.is_sub_user(v.userId) == 0) and send == 1) then  --不是子账号
            netlib.send(function(buf)
                buf:writeString("TXREFP")
                buf:writeByte(-1)
                buf:writeInt(#sitelist)
                for i = 1, #sitelist do
                    buf:writeByte(sitelist[i])
                end
                buf:writeInt(#pokes)
                for i = 1, #pokes do
                    buf:writeByte(pokes[i])
                end
            end, v.ip, v.port)
       end
    end
end

--逐步提醒玩家当前最大牌型
function net_send_bestpokes(userinfo, weight, pokes)
    if not userinfo then return end
	netlib.send(
		function(buf)
			buf:writeString("TXREBP")
			buf:writeString(weight)		--牌有多大，是个数字。第一位代表牌型。1-9，但不含皇家同花顺。
			buf:writeInt(#pokes)
			for i = 1, #pokes do
				buf:writeByte(pokes[i])
			end
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end
-----------------------------------------------礼物相关------------------------------
--显示商店的的礼物列表
function net_send_gift_shop(userinfo, giftlist)
    if not userinfo or type(giftlist) ~= "table" then return end
	netlib.send(
		function(buf)
			buf:writeString("TXGFSP")
			buf:writeInt(#giftlist)
			for _, gift_item in pairs(giftlist) do
				buf:writeInt(gift_item.id or 0)				--商品ID，购买时按照ID购买
				buf:writeInt(gift_item.price or 0)			--商品价格
			end
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end


--显示某玩家的礼物标识
function net_send_gift_icon(userinfo, site, giftid)
    if(not userinfo.desk) then return end
    local deskinfo = desklist[userinfo.desk]

    netlib.send(
		function(buf)
			buf:writeString("TXSPBZ")
			buf:writeByte(site)
			buf:writeInt(giftid or 0)
		end
	, userinfo.ip, userinfo.port)
end

--播放送礼物动画
function net_broadcast_give_gift(deskno, fromsite, tositeno, giftid, typenumber, props_number)
    local deskinfo = desklist[deskno]
    local from_user_id = 0;
    local to_user_id = 0;
    local from_user_nick = "";
    local to_user_nick = "";
    if deskinfo.site[fromsite].user ~= nil then
        local from_user_info = userlist[deskinfo.site[fromsite].user];
        from_user_id = from_user_info ~= nil and from_user_info.userId or 0;
        from_user_nick = from_user_info ~= nil and from_user_info.nick or "";
    end

    if deskinfo.site[tositeno].user ~= nil then
        local to_user_info = userlist[deskinfo.site[tositeno].user];
        to_user_id = to_user_info ~= nil and to_user_info.userId or 0;
        to_user_nick = to_user_info ~= nil and to_user_info.nick or 0;
    end

    if not typenumber then
    	typenumber = 0
    end
    if not props_number then
    	props_number = 1
    end

	netlib.broadcastdeskex(
		function(buf)
			buf:writeString("TXZSLW")
			buf:writeByte(fromsite);	--from座位号
			buf:writeByte(tositeno);	--to座位号
			buf:writeInt(giftid);	    --新钱数
            buf:writeByte(typenumber);           --类型：0,其它礼物；9，表示要播放的动画是道具
			buf:writeInt(props_number);
            buf:writeInt(from_user_id or 0);
            buf:writeInt(to_user_id or 0);
            buf:writeString(from_user_nick or "");
            buf:writeString(to_user_nick or "");
		end
	, deskno, borcastTarget.all);
end

--播放发表情动画
function net_broadcast_emot(deskno, fromsite, emotid)
    local deskinfo = desklist[deskno]

	netlib.broadcastdesk(
		function(buf)
			buf:writeString("TXPLEM")
			buf:writeByte(fromsite);	--from座位号
			buf:writeInt(emotid);		--表情ID
		end
	, deskno, borcastTarget.all);
end

--购买礼物失败
function net_send_gift_faild(userinfo, retcode, gift_id, gift_num, gift_type)
    local deskinfo = desklist[userinfo.desk]

	netlib.send(
		function(buf)
			buf:writeString("TXBGFD")
			buf:writeByte(retcode)	--1=成功扣钱 2=钱不够 0=其他异常 3=对方礼物满了
            buf:writeInt(gift_id or 0);
            buf:writeInt(gift_num or 0);
            buf:writeInt(gift_type or 0);
		end
	, userinfo.ip, userinfo.port, borcastTarget.playingOnly)
end

--批量赠送礼物失败(部分失败)
function net_send_gift_faildlist(userinfo, failedlist)
    if(not userinfo or not failedlist) then
        return
    end
	netlib.send(
		function(buf)
			buf:writeString("TXBGFF")
            buf:writeInt(#failedlist)
            for i = 1, #failedlist do
                buf:writeByte(failedlist[i].site)	
                buf:writeInt(failedlist[i].retcode) --1=成功扣钱 2=钱不够 3=今天超过限额了 4=礼物满了 0=其他异常
            end
		end
	, userinfo.ip, userinfo.port)
end

--出售礼品结果
--recode:1成功，其他失败
function net_send_sale_gift(userinfo, retcode, addgold)
	netlib.send(
		function(buf)
			buf:writeString("TXGFSL")
			buf:writeInt(retcode)
			buf:writeInt(addgold)
		end
	, userinfo.ip, userinfo.port);
end

--显示某玩家的礼物列表
function net_send_gift_list(userinfo, giftinfo, touserinfo)
    local deskinfo = desklist[userinfo.desk]
    --过滤车
    local newgiftinfo = {};
    local totalcount = 0;
    for index, gift_item in pairs(giftinfo) do
        totalcount = totalcount + 1;
        if(parkinglib.is_parking_item(gift_item.id) == 0) then
            newgiftinfo[index] = gift_item;
        end
    end
    giftinfo = newgiftinfo;
	netlib.send(
		function(buf)
			buf:writeString("TXGLST")
			local len = 0
			for index, gift_item in pairs(giftinfo) do
				len = len + 1
            end
            buf:writeInt(totalcount);
			buf:writeInt(len)
			for index, gift_item in pairs(giftinfo) do
				buf:writeInt(gift_item.index)				--索引，不一定连续，操作列表时依赖这个东东
				buf:writeInt(gift_item.id)					--礼物编号  决定了显示啥图片
				buf:writeByte(gift_item.isusing)			--是否正在使用 1=是，0=不是
                buf:writeByte(gift_item.cansale)			--是否可以出售 1=是，0=不是
                buf:writeInt(gift_item.salegold)			--回收价格
        if (not gift_item.fromuserid) or (touserinfo.userId == gift_item.fromuserid) then
        	buf:writeString("")	
        else
					buf:writeString(gift_item.fromuser)			--赠送人的名字
				end
			end
		end
	, userinfo.ip, userinfo.port)
end
--发送礼品排行榜数据到客户端
function net_send_giftrank(userinfo, ranklist)
    if not userinfo or not ranklist then return end
	netlib.send(
		function(buf)
			buf:writeString("TXGFPH")
			buf:writeInt(#ranklist)
			for i=1, #ranklist do
				buf:writeInt(ranklist[i].userid)			--玩家ID
                buf:writeString(ranklist[i].nick)			--玩家昵称
				buf:writeInt(ranklist[i].counts)			--拥有甜蜜之心个数
                buf:writeInt(ranklist[i].paiming)			--排名
			end
		end
	, userinfo.ip, userinfo.port)
end

function net_broadcast_gift_response(deskno, fromsite, tositeno, response_id)
    if not fromsite or not tositeno then return end
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("TXGFRP")
			buf:writeInt(fromsite);	--from座位号
			buf:writeInt(tositeno);	--to座位号
			buf:writeInt(response_id);	--新钱数
		end
	, deskno, borcastTarget.all);
end
-------------------

--广播桌面游戏信息
function net_broadcast_chat_message(deskno, msg)
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("REDC")
			buf:writeByte(8)      					--game chat
			buf:writeString(msg)     				--text
			buf:writeInt(0)         				--user id
			buf:writeString("") 					--user name
		end
	, deskno, borcastTarget.all);
end 

-------------------------------------------------保险箱模块相关-----------------------------------
--返回给客户端点击保险箱后的结果
function net_send_user_safebox_case(userinfo,nType,safegold)
	netlib.send(
		function(buf)
			buf:writeString("TXSBIF")
			buf:writeByte(nType)--0表示不是VIP,1表示第一次开通,2已开通查看
            if nType > 0 then
                buf:writeByte(userinfo.safeboxnum or 0)--该玩家可以拥有的箱子数
            end
			if safegold then
				buf:writeInt(safegold) --保险箱中的钱
			end
		end,userinfo.ip,userinfo.port)
end

function net_send_user_getsetgold_case(userinfo,result,nowgold)
	netlib.send(
		function(buf)
			buf:writeString("TXSBSG")
			buf:writeByte(result)--0表示不成功,1成功完成设置
			buf:writeInt(nowgold)--玩家当前的保险箱中的钱
		end,userinfo.ip,userinfo.port)
end

--通知客户端还有多少秒才可以将钱存入保险箱
function net_send_lefttime_cansave(userinfo, lefttime)
	netlib.send(
		function(buf)
			buf:writeString("TXSBSE")
			buf:writeInt(math.floor(lefttime))
		end,userinfo.ip,userinfo.port)
end

--设置密码后的结果返回
function net_send_setpw_case(userinfo,result)
	netlib.send(
		function(buf)
			buf:writeString("TXSBPW")
			buf:writeByte(result)--0表示不成功,1成功完成设置
		end,userinfo.ip,userinfo.port)
end

--取钱时密码输入结果返回
function net_send_getgoldpw_case(userinfo)
    netlib.send(
		function(buf)
			buf:writeString("TXSBGP")
		end,userinfo.ip,userinfo.port)
end
---------------------------------------------德州新手教程相关---------------------------------
--通知客户端显示欢迎界面
function net_send_welcome_tex(userinfo)
    netlib.send(
        function(buf)
            buf:writeString("TXWELCM")
    end, userinfo.ip, userinfo.port)
end
----------------------------------------------------------------------------------------------


