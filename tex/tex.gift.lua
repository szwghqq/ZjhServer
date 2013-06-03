--加载配置表格
config_for_yunying = config_for_yunying or {}
--结束预加载

--玩家在面板状态下买东西，特殊处理
function on_panel_buy(userinfo, sitedata)
    sitedata.panellefttime = hall.desk.get_site_timeout(userinfo.desk, userinfo.site)
    if sitedata.panellefttime <= 0 then 
        sitedata.panellefttime = 1 
    end
    hall.desk.set_site_state(userinfo.desk, userinfo.site, SITE_STATE.WAIT)
    process_site(userinfo.desk, userinfo.site)--重新计算面板
    --经过计算发现竟然不是面板状态了，那就出名人名言吧
    if hall.desk.get_site_state(userinfo.desk, userinfo.site) == SITE_STATE.WAIT then
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
    sitedata.panellefttime = 0
end

--获取玩家身上的石头数量
function get_texstone_by_userinfo(userinfo)
    local str = "";
    if not userinfo then
        TraceError("get_texstone_by_userinfo,收到userinfo为空!!!");
        return str;
    end

    local giftinfo = userinfo.gameInfo.giftinfo;
    if not giftinfo then
        TraceError("get_texstone_by_userinfo,收到giftinfo为空!!!");
        return str;
    end

    local tstones = {};
    for i=1, #giftinfo do
        local item = giftinfo[i];
        if(item ~= nil)then
            --宝石ID是5001 - 6000
            if(item.id > 5000 and item.id <= 6000)then
                if(not tstones[item.id])then
                    tstones[item.id] = 0;
                end
                tstones[item.id] = tstones[item.id] + 1;
            end
        end
    end

    --石头数量列表
    local stonelist = {};
    for k,v in pairs(tstones) do
        table.insert(stonelist, format("%s:%s", tostring(k), tostring(v)));
    end

    --排序
    table.sort(stonelist, 
           function(a,b)
               local id_1 = tonumber(string.sub(a,1,4)) or 0;
               local id_2 = tonumber(string.sub(b,1,4)) or 0;
               return id_1 < id_2;
           end);
    str = "|" .. table.concat(stonelist, "|");
    return str;
end

--记录礼品买卖日志
function record_gift_transaction(userid, viplevel, beforgold, transtype, giftid, counts, amount, touserid, beforestone, afterstone)
    --TraceError(format("beforstone=%s,\nafterstone=%s", beforestone, afterstone));
    local sqltemple = "INSERT INTO log_texgift_transaction ";
    sqltemple = sqltemple .. "(sys_time, user_id, vip_level, befor_gold, trans_type, gift_id, counts, amount, touser_id, before_stone, after_stone) ";
    sqltemple = sqltemple .. "VALUES(NOW(),%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s');COMMIT;";
    local sql = string.format(sqltemple, userid, viplevel, beforgold, transtype, giftid, counts, amount, touserid, beforestone, afterstone);
    dblib.execute(sql);
end

--判断是否情人节(2011-02-14)
function checker_valentine_Day()
	local starttime = os.time{year = 2011, month = 2, day = 14, hour = 0};
	local endtime = os.time{year = 2011, month = 2, day = 15, hour = 0};
	local sys_time = os.time()
    if(sys_time < starttime or sys_time > endtime) then
        return false
	end
    return true
end

--请求打开商店列表
function onrecvopenshop(buf)
	--TraceError("onrecvopenshop()")
	local userinfo = userlist[getuserid(buf)];
	if not userinfo then return end;

	local giftlist = {};
    for k,v in pairs(tex.cfg.giftlist) do
        if(k == 5006) then --情人节礼物(只在情人节里卖)
            if checker_valentine_Day() then
                table.insert(giftlist, {id = k, price = v});
            end
        else
            table.insert(giftlist, {id = k, price = v});
        end
    end

	net_send_gift_shop(userinfo, giftlist);
end

--请求礼品排行榜
function onrecvgetgiftrank(buf)
	--TraceError("onrecvgetgiftrank()")
	local userinfo = userlist[getuserid(buf)];
	if not userinfo then return end;

	local giftrank = tex.giftrank;
    local sys_time = os.time();
    local playerlist = {};
    --1分钟更新一次排行数据(数量相同的按时间早晚排序)
    if(sys_time - giftrank.lasttime > 30 and giftrank.refreshing == 0)then
        local sql = "SELECT * FROM user_sweetheart_info ORDER BY counts DESC, update_time ASC LIMIT 0, 10; ";
        giftrank.refreshing = 1;
        dblib.execute(sql,
    		function(dt)
                if(dt and #dt > 0) then
                    giftrank.lasttime = os.time();
                    for i=1, #dt do
                        giftrank.playerlist[i] = {};
                        giftrank.playerlist[i]["paiming"] = i;
                        giftrank.playerlist[i]["userid"] = dt[i]["user_id"];
                        giftrank.playerlist[i]["nick"] = dt[i]["nick_name"];
                        giftrank.playerlist[i]["counts"] = dt[i]["counts"];
                    end
                end
                giftrank.refreshing = 0;
                do_add_user_itself(userinfo, giftrank.playerlist);
    		end);
    else
        do_add_user_itself(userinfo, giftrank.playerlist);
    end
end

--在礼品排行榜中加入玩家自己的数据
function do_add_user_itself(userinfo, ranklist)
    if not userinfo or not ranklist then return end;
    local templist = {};
    for i=1, #ranklist do
        templist[i] = ranklist[i];
    end
    --防止过多操作数据库，5秒内重复请求直接发送缓存里的数据
    if(userinfo.rankinfo)then
        local userlasttime = userinfo.rankinfo.lasttime;
        local userranklist = userinfo.rankinfo.ranklist;
        if(userlasttime and userranklist and os.time() - userlasttime < 5) then
            net_send_giftrank(userinfo, userinfo.rankinfo.ranklist);
            return
        end
    end

    local len = #templist;
    local sql = "SELECT * FROM user_sweetheart_info WHERE user_id = %d; ";
    sql = format(sql, userinfo.userId);
    dblib.execute(sql,
    		function(dt)
                templist[len + 1] = {};
                templist[len + 1]["paiming"] = 1000000;
                templist[len + 1]["userid"] = userinfo.userId;
                templist[len + 1]["nick"] = userinfo.nick;
                if(dt and #dt > 0) then
                    templist[len + 1]["counts"] = dt[1]["counts"];
                else
                    templist[len + 1]["counts"] = 0;
                end
                userinfo.rankinfo = {lasttime = os.time(), ranklist = templist};
                net_send_giftrank(userinfo, userinfo.rankinfo.ranklist);
    		end);
end

--发送表情
function onrecvsendemot(buf)
	local emotid = buf:readInt()
	--TraceError("onrecvsendemot() emotid:" .. emotid)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 
	if not userinfo.desk or userinfo.desk <= 0 then return end;
	if not userinfo.site or userinfo.site <= 0 then return end;

    local lastbuyemottime = userinfo.lastbuyemottime or 0
    if(os.clock()*1000 - lastbuyemottime < 500)then
        TraceError("购买表情，点击得太快了")
        return
    end
    userinfo.lastbuyemottime = os.clock()*1000

	local deskinfo = desklist[userinfo.desk]

	local deskdata = deskmgr.getdeskdata(userinfo.desk)
	local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)

	local smallbet = desklist[userinfo.desk].smallbet
	local emotprice = smallbet
	--1=成功扣钱 2=钱不够 0=其他异常
	local retcode = dobuyemot(userinfo, deskdata, sitedata, emotprice)   

	--购买成功
	if retcode == 1 then 
		--广播表情动画
		net_broadcast_emot(userinfo.desk, userinfo.site, emotid)
	else
		net_send_gift_faild(userinfo, retcode)
	end
end

--购买表情,扣消费产生的钱,并刷新到客户端 返回码 1=成功扣钱 2=钱不够 0=其他异常
function dobuyemot(userinfo, deskdata, sitedata, emotprice)
    --TraceError("dobuyemot() emotprice:" .. emotprice)
	local deskinfo = desklist[userinfo.desk]
	local largebet = deskinfo.largebet
	local choushui = get_specal_choushui(deskinfo,userinfo)
	local state = hall.desk.get_site_state(userinfo.desk, userinfo.site)
	local canbuy = 0
	--冻结的筹码
	local freezegold = 0
	if(not userinfo.chouma or userinfo.chouma == 0)then
        	freezegold = sitedata.betgold
	end
	--比赛场还没开始就要保留报名费咯
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
        	local gamestart = tex.getGameStart(userinfo.desk)
        	if not gamestart then
            		freezegold = deskinfo.at_least_gold + deskinfo.specal_choushui
        	end
	end
	local usegold = get_canuse_gold(userinfo)--userinfo.gamescore - freezegold  --扣除已下注的筹码
		
	--桌外不能发表情
	if state == NULL_STATE then TraceError("幽灵来消费了") return canbuy end
	
	--看看扣完还够筹码不
    if state == SITE_STATE.PANEL or state == SITE_STATE.WAIT then
		--游戏开始后买表情，留下大盲注
		if(usegold - emotprice >= largebet) then
			canbuy = 1
		else
			canbuy = 2
		end
	else
		--没开始游戏就送表情，要考虑抽水
		if(usegold - emotprice >= largebet + choushui) then
			canbuy = 1
		else
			canbuy = 2
		end
	end
	
	--不符合购买条件
	if(canbuy ~= 1) then
		return canbuy
	end
	
	--开始扣钱啦，要注意咯
	usermgr.addgold(userinfo.userId, -emotprice, 0, g_GoldType.buyemot, -1, 1)
	--客户端筹码显示,如果用到了带入筹码，就要实时刷新减少的数值
	usegold = usegold - emotprice
	if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament and
       deskinfo.desktype ~= g_DeskType.match) then
		if(userinfo.chouma and usegold < userinfo.chouma) then
			userinfo.chouma = usegold
		end
		if(sitedata.gold and usegold < sitedata.gold) then
			sitedata.gold = usegold
			if(sitedata.gold == 0) then
				TraceError("买表情把钱花没了？？怎么会.....")
				sitedata.isallin = 1 
			end
		end
	end
	net_broadcastdesk_goldchange(userinfo)
	
	--用户面板状态下买东西，刷新显示下注面板
	if state == SITE_STATE.PANEL then
		on_panel_buy(userinfo, sitedata)
	end

	return canbuy
end

function is_no_limit_gift(gift_id) 
    local nolimit_ture = 0;
    for _,v in pairs (config_for_yunying.no_limit_gift) do
        if v == gift_id then
                nolimit_ture = 1;
            break
        end
    end
    return nolimit_ture;
end

function check_buy_gift_gold(user_info) 
    local limitgold = config_for_yunying.buy_gift_limit;
	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	if(sys_today ~= user_info.gift_today) then --日期不符
		user_info.gift_today = sys_today	--更新今天日期
		user_info.buygiftgold = 0	--今天购买额
		user_info.salegiftgold = 0	--今天销售额
		update_giftinfo_db(user_info)
	end
end

--执行赠送礼物
--返回:1=成功 2=钱不够 3=超过今天购买额 0=其他异常
function dosendgift(userinfo, touserinfo, giftid, gift_num)
	if not userinfo or not touserinfo then
		TraceError("谁送给谁啊？")
		return 0
    end

    if(gift_num <= 0) then
        TraceError("赠送的数量为"..gift_num);
        return 0;
    end

	local giftprice = tex.cfg.giftlist[giftid]
	
	if not giftprice then 
		TraceError("咩礼物？giftid:" .. giftid)
		return 0
    end

    giftprice = giftprice * gift_num;

    local limitgold = config_for_yunying.buy_gift_limit;
	--检查是否超过每天购买金额
	check_buy_gift_gold(userinfo);

	if(not userinfo.buygiftgold) then
	    userinfo.buygiftgold = giftprice
	else
		local nolimit_ture = is_no_limit_gift(giftid);
	    if(userinfo.buygiftgold + giftprice >= limitgold) and (nolimit_ture == 0) then
	        --当天购买超过150万了
	        return 3
	    else
	    		if nolimit_ture ==  0 then
	        	userinfo.buygiftgold = userinfo.buygiftgold + giftprice       
	     		end
	    end
	end
	
	--运维需求，交易日志
	local userid = userinfo.userId
	local viplevel = 0
	if(viplib) then
	    viplevel = viplib.get_vip_level(userinfo)
	end
	local beforgold = userinfo.gamescore
	local transtype = 0 --交易类型,购买
	
	local amount = -giftprice --买要扣钱，是负数
	local touserid = touserinfo.userId
	
	local retcode = 0
	
	--游戏中给人送礼
	if(userinfo.desk and userinfo.site and touserinfo.site) then
		local deskdata = deskmgr.getdeskdata(userinfo.desk)
		local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site)
		local tosite = touserinfo.site
	
		local tositedata = deskmgr.getsitedata(userinfo.desk, tosite)
		retcode = dobuygift1(userinfo, deskdata, sitedata, giftid, giftprice, touserinfo, gift_num)
		--购买成功
		if retcode == 1 then
			if giftid < 2000 and userinfo.userId ~= touserinfo.userId then--送饮料
				tositedata.getgifecount = tositedata.getgifecount + 1
				if tositedata.getgifecount >= 3 then
					achievelib.updateuserachieveinfo(touserinfo,1004);--干杯朋友
				end
			end
			
			local nolimit_ture = 0;
			for _,v in pairs (config_for_yunying.cannot_puton_gift) do
				if v == giftid then
					nolimit_ture = 1;
					break
				end
			end
			if nolimit_ture ~= 1 then
				--广播播放送礼物动画
				net_broadcast_give_gift(userinfo.desk, userinfo.site, tosite, giftid, 1, gift_num)
			else
				--是图纸的话，发礼物 7
				net_broadcast_give_gift(userinfo.desk, userinfo.site, tosite, giftid, 2)
			end
		end
	else
		retcode = dobuygift2(userinfo, giftid, giftprice, touserinfo, gift_num)
	end
	--购买成功，增加礼品，记录日志
	if(retcode == 1)then
		if zhongqiu_lib ~= nil then 
            local bTrue = zhongqiu_lib.is_in_zhongqiu_tuzhi(userinfo, touserinfo, giftid, gift_num)
            if bTrue == 1 then return -10 end
		end
		if tex_gamepropslib then
            local bTrue = tex_gamepropslib.is_gameprops(userinfo, touserinfo, giftid, gift_num)
            if (bTrue == 1) or (bTrue == 2) then return -10 end
		end
		local before_stones = get_texstone_by_userinfo(userinfo)
        for i = 1, gift_num do
            gift_addgiftitem(touserinfo, giftid, userinfo.userId, userinfo.nick)
        end
		local after_stones = get_texstone_by_userinfo(userinfo)
	    if (duokai_lib and duokai_lib.is_sub_user(touserid) == 1) then
            touserid = duokai_lib.get_parent_id(touserid)
        end
		record_gift_transaction(userid, viplevel, beforgold, transtype, giftid, gift_num, amount, touserid, before_stones, after_stones)
	end
	return retcode
end

function onrecvpresendgift(buf)
    local user_info = userlist[getuserid(buf)];
    if(not user_info) then return end;
    local gift_id = buf:readInt();
    local gift_price = tex.cfg.giftlist[gift_id];

    if(not gift_price) then
        return;
    end

    local max = 100;
    local result = 1;
    local can_use_gold = get_canuse_gold(user_info);
    local can_buy_num = math.floor(can_use_gold / gift_price);

    --计算今日限制道具
    if(is_no_limit_gift(gift_id) == 0) then
        check_buy_gift_gold(user_info);

        local buy_gift_limit = config_for_yunying.buy_gift_limit;
        if(user_info.buygiftgold == nil) then
            user_info.buygiftgold = 0;
        end
        if(user_info.buygiftgold + gift_price * can_buy_num >= buy_gift_limit) then
            --超过限制了
            can_use_gold = buy_gift_limit - user_info.buygiftgold;
            can_buy_num = math.floor(can_use_gold / gift_price);
            result = 2;
        end
    end

    --超出100个了
    if(gift_getgiftcount(user_info) + can_buy_num > 100 and tex_gamepropslib.get_type_pro_gift(gift_id)==2 )then
        can_buy_num = max - gift_getgiftcount(user_info);
        result = 3;
    end

    if(can_buy_num > max) then
        can_buy_num = max;
    end
    if(can_buy_num > 0) then
        local send_func = function(buf)
            buf:writeString("TXPROPNUM");
            buf:writeInt(can_buy_num);
        end
        netlib.send(send_func, user_info.ip, user_info.port);
    else
        if(result == 2) then
            --该道具超出购买的限制了
			net_send_gift_faild(user_info, 6);
        elseif(result == 3)then
			net_send_gift_faild(user_info, 5);
        else
			net_send_gift_faild(user_info, 2);
        end
    end
end

--收到赠送礼物
function onrecvsendgift(buf)
	--TraceError("onrecvsendgift()")
	local giftid = buf:readInt()
	local len = buf:readInt()
	local tosites = {}
	for i = 1, len do
		tosites[i] = buf:readByte()
    end
    local gift_num = buf:readInt();
    local gift_type = buf:readInt();

    if(gift_num <= 0) then
        return;
    end

    if(giftid == 5006 and not checker_valentine_Day())then
        TraceError("今天不是情人节，商店不卖此礼物 id=5006")
        return
    end
	
	local userinfo = userlist[getuserid(buf)];
	if not userinfo then return end;

    local lastbuygifttime = userinfo.lastbuygifttime or 0
    if(os.clock()*1000 - lastbuygifttime < 800)then
        TraceError("购买礼物，点击得太快了")
        return
    end
    userinfo.lastbuygifttime = os.clock()*1000

	local giftprice = tex.cfg.giftlist[giftid]
	
	if not giftprice then 
		--提示商城物品已经过期
		net_send_gift_faild(userinfo, 99)
		TraceError("咩礼物？giftid:" .. giftid)
		return 
    end

    for i = 1, #tosites do
        local touserinfo = nil
		local tosite = tosites[i]
		if(tosite and tosite ~= 0) then
			if(userinfo.desk and userinfo.site) then
				touserinfo = deskmgr.getsiteuser(userinfo.desk, tosite)
			else
				TraceError("观战的时候给人送礼？？？不支持")
			end
		else
			--送给自己
			touserinfo = userinfo
        end

        if(touserinfo ~= nil and touserinfo.userId ~= userinfo.userId) then
            gift_num = 1;
        end
    end
	
	--记录赠送失败的玩家
	local failedusers = {}
    local retcode = 0
    local flag_full = 0
	for i = 1, #tosites do
		local touserinfo = nil
		local tosite = tosites[i]
		if(tosite and tosite ~= 0) then
			if(userinfo.desk and userinfo.site) then
				touserinfo = deskmgr.getsiteuser(userinfo.desk, tosite)
			else
				TraceError("观战的时候给人送礼？？？不支持")
			end
		else
			--送给自己
			touserinfo = userinfo
        end

		if touserinfo then
			if gift_getgiftcount(touserinfo) + gift_num > 100 and tex_gamepropslib.get_type_pro_gift(giftid)==2 then
				if(userinfo.userId == touserinfo.userId) then  --自己给自己送礼
					net_send_gift_faild(userinfo, 5, giftid, gift_num, gift_type)		--告诉客户端礼物已满
					flag_full = 1
				else
					net_send_gift_faild(touserinfo, 3, giftid, gift_num, gift_type)		--1=成功扣钱 2=钱不够 3=礼物满了 4=礼物满了 0=其他异常				
				end
				table.insert(failedusers, {site = touserinfo.site or 0, retcode = 4})
      else 
				retcode = dosendgift(userinfo, touserinfo, giftid, gift_num)
				if(retcode ~= 1) and (retcode ~= -10) then
					table.insert(failedusers, {site = touserinfo.site or 0, retcode = retcode})
				end
			end
		end
	end
	--只有在游戏中才有批量送礼失败的情况
	if(userinfo.desk and userinfo.site) then
		net_send_gift_faildlist(userinfo, failedusers)
	else
		--1=成功扣钱 2=钱不够 3=今天超限 0=其他异常
		if retcode == -10 then
			net_send_gift_faild(userinfo, 1, giftid, gift_num, gift_type)
		else
			if flag_full == 0 then
				net_send_gift_faild(userinfo, retcode == 3 and 6 or retcode, giftid, gift_num, gift_type)
			end
		end
		
	end
end


--游戏中购买礼物,扣消费产生的钱,并刷新到客户端 返回码 1=成功扣钱 2=钱不够 0=其他异常
function dobuygift1(userinfo, deskdata, sitedata, giftid, giftprice, touserinfo, gift_num)
	--TraceError("dobuygift() giftprice:" .. giftprice)
	local deskinfo = desklist[userinfo.desk]
	local largebet = deskinfo.largebet
	local choushui = get_specal_choushui(deskinfo,userinfo)
	local canbuy = 0
	local state = hall.desk.get_site_state(userinfo.desk, userinfo.site)
	local usegold = get_canuse_gold(userinfo);
	
	--桌外??
	if state == NULL_STATE then TraceError("幽灵来消费了") return canbuy end
	
	--看看扣完还够筹码不
    if state == SITE_STATE.PANEL or state == SITE_STATE.WAIT then
		--游戏开始后购买，留下大盲注
		if(usegold - giftprice >= largebet) then
			canbuy = 1
		else
			canbuy = 2
		end
	else
		--没开始游戏就买礼物，要考虑抽水
		if(usegold - giftprice >= largebet + choushui) then
			canbuy = 1
		else
			canbuy = 2
		end
	end
	
	if(usegold < giftprice) then
		canbuy = 2
	end	
	
	--不符合购买条件
	if(canbuy ~= 1) then
		return canbuy
	end
	
	--开始扣钱啦，要注意咯
	--TraceError(format("玩家[%d]购买礼品花了[%d]筹码",userinfo.userId,giftprice))
    if(giftid == 5006)then --甜蜜之心，单独type
	    usermgr.addgold(userinfo.userId, -giftprice, 0, g_GoldType.buysweetheart, -1, 1, nil, giftid, gift_num, touserinfo.userId)
    else
        usermgr.addgold(userinfo.userId, -giftprice, 0, g_GoldType.buy, -1, 1, nil, giftid, gift_num, touserinfo.userId)
    end
	--客户端筹码显示,如果用到了带入筹码，就要实时刷新减少的数值
	usegold = usegold - giftprice
    if(deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) then
    	if(userinfo.chouma and usegold < userinfo.chouma) then
    		userinfo.chouma = usegold
    	end
    	if(sitedata.gold and usegold < sitedata.gold) then
    		sitedata.gold = usegold
    		if(sitedata.gold == 0) then
    			TraceError("买礼品把钱花没了？？怎么会.....")
    			sitedata.isallin = 1 
    		end
        end
    end
	net_broadcastdesk_goldchange(userinfo)
	
	--用户面板状态下买东西，刷新显示下注面板
	if state == SITE_STATE.PANEL then
		on_panel_buy(userinfo, sitedata)
    end

	return canbuy
end

--大厅或观战时购买礼物,扣消费产生的钱,并刷新到客户端 返回码 1=成功扣钱 2=钱不够 0=其他异常
function dobuygift2(userinfo, giftid, giftprice, touserinfo, gift_num)	
	--看看够筹码不	
    local canbuygold = get_canuse_gold(userinfo);
	if(canbuygold - giftprice < 0) then
		return 2
	end
	
	--开始扣钱啦，要注意咯
	--TraceError(format("玩家[%d]购买礼品花了[%d]筹码",userinfo.userId,giftprice))
    if(giftid == 5006)then --甜蜜之心，单独type
        usermgr.addgold(userinfo.userId, -giftprice, 0, g_GoldType.buysweetheart, -1, 1, nil, giftid, gift_num, touserinfo.userId)
    else
	    usermgr.addgold(userinfo.userId, -giftprice, 0, g_GoldType.buy, -1, 1, nil, giftid, gift_num, touserinfo.userId)
    end

	return 1
end

--请求某人的礼物详情
function onrecvgetgiftinfo(buf)
	local to_user_id = buf:readInt()
    if (duokai_lib and duokai_lib.is_sub_user(to_user_id) == 1) then
        to_user_id = duokai_lib.get_parent_id(to_user_id)
    end
	--TraceError("onrecvgetgiftinfo()" .. to_user_id)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; 
	local touserinfo = usermgr.GetUserById(to_user_id); if not touserinfo then return end; 
	local touserdata = deskmgr.getuserdata(touserinfo)
	net_send_gift_list(userinfo, touserdata.giftinfo, touserinfo)
end


--请求穿某礼物
function onrecvusinggift(buf)
	local gift_index = buf:readInt()
	--TraceError("onrecvusinggift()" .. gift_index)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end;
	local userdata = deskmgr.getuserdata(userinfo)
	
	if gift_usegiftitem(userinfo, gift_index) then
		dispatchMeetEvent(userinfo)
	end
end

--请求扔某礼物
function onrecvdropgift(buf)
	local gift_index = buf:readInt()
	--TraceError("onrecvdropgift()" .. gift_index)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end;
	local userdata = deskmgr.getuserdata(userinfo)

	--如果删除的时身上带的，就要派发见面信息
	if gift_removegiftitem(userinfo, gift_index) > 0 then
		dispatchMeetEvent(userinfo)
	end
end

--请求卖掉某个礼物
--TODO:跨服可能存在一个礼物多次卖出的问题，需要注意
function onrecvsalegift(buf)
	local gift_index = buf:readInt()
	--TraceError("onrecvdropgift()" .. gift_index)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end;
	local userdata = deskmgr.getuserdata(userinfo)
    local giftinfo = userdata.giftinfo
    local giftitem = giftinfo[gift_index]
	if not giftitem then
		TraceError(format("试图卖掉不存在的礼物,userId[%d],gift_index[%d]", userinfo.userId, gift_index))
        net_send_sale_gift(userinfo, -1, 0)
		return
    end

    --判断此礼物是否可以出售
    local giftid = giftitem.id
    if giftitem.cansale ~= 1 then 
		TraceError("这种礼物不能回收,请客户端检查,giftid:" .. giftitem.id)
        net_send_sale_gift(userinfo, 2, 0)
		return 
    end

    --价格
    local giftprice = math.floor(giftitem.salegold * 0.95)--回收价是原价的95%
    if not tex.cfg.giftlist[giftid] or not giftprice or giftprice <=0 then 
		TraceError("卖掉？？？礼物:giftid:" .. giftitem.id)
        net_send_sale_gift(userinfo, 2, 0)
		return 
    end
    --抽税
    local taxgold = tex.cfg.giftlist[giftid] - giftprice

    --检查是否超过每天出售金额
    local limitgold = 1500000
	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	if(sys_today ~= userinfo.gift_today) then --日期不符
		userinfo.gift_today = sys_today	--更新今天日期
		userinfo.buygiftgold = 0	--今天购买额
		userinfo.salegiftgold = 0	--今天销售额
		update_giftinfo_db(userinfo)
	end
    if(not userinfo.salegiftgold) then
        userinfo.salegiftgold = giftprice
    else
        if(userinfo.salegiftgold + giftprice >= limitgold) then
            TraceError(format("玩家[%d]今天出售礼品获得筹码[%d]", userinfo.userId, userinfo.salegiftgold + giftprice))
        end
        userinfo.salegiftgold = userinfo.salegiftgold + giftprice
    end

    if(userinfo.issaleing) then
        TraceError("前一个还没卖掉呢！！！"..debug.traceback())
        net_send_sale_gift(userinfo, 3, 0)
		return 
    end
    --原子操作，不能同时卖几个
    userinfo.issaleing = 1

    --运维需求，交易日志
    local userid = userinfo.userId
    local viplevel = 0
    if(viplib) then
        viplevel = viplib.get_vip_level(userinfo)  --最高vip等级
    end
    local beforgold = userinfo.gamescore  --交易前金额
    local transtype = 1 --交易类型,出售

    local ncount = 1 --个数
    local amount = giftprice  --卖是加钱的，正数
    local touserid = 0  --卖出时没有目标人的ID
    
    --一定要删除礼品成功才能加钱哦 
    local before_stones = get_texstone_by_userinfo(userinfo)
    local after_stones = ""
    local result = 0;
    if gift_removegiftitem(userinfo, gift_index) >= 0 then
        after_stones = get_texstone_by_userinfo(userinfo)
		dispatchMeetEvent(userinfo)
        if(giftid == 5006) then  --甜蜜之心
            usermgr.addgold(userinfo.userId, giftprice, -taxgold, g_GoldType.salesweetheart, g_GoldType.sweethearttax, 1, nil, giftid)
            --usermgr.addgold(userinfo.userId, -taxgold, 0, g_GoldType.sweethearttax, -1, 1)
        else
            
            usermgr.addgold(userinfo.userId, giftprice, -taxgold, g_GoldType.salegift, g_GoldType.salegifttax, 1, nil, giftid)
            --usermgr.addgold(userinfo.userId, -taxgold, 0, g_GoldType.salegifttax, -1, 1)
        end
        record_gift_transaction(userid, viplevel, beforgold, transtype, giftid, ncount, amount, touserid, before_stones, after_stones)
        net_send_sale_gift(userinfo, 1, giftprice)
        result = 1;
    else
        net_send_sale_gift(userinfo, -1, 0)
        result = 0;
    end
    userinfo.issaleing = nil
end

--收到礼物响应
function onrecvgiftresponse(buf)
	local to_user_id, response_id = buf:readInt(), buf:readInt()
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	local touserinfo = usermgr.GetUserById(to_user_id); if not touserinfo then return end; if not touserinfo.desk or touserinfo.desk <= 0 then return end;

	net_broadcast_gift_response(userinfo.desk,userinfo.site,touserinfo.site,response_id)
end

-----------------------------------礼物=====改userinfo及数据库-----------------------------------------
--除下礼物
function gift_remove_using(userinfo)
	local userdata = deskmgr.getuserdata(userinfo)
    if userdata.using_gift_item ~= nil then
		userdata.using_gift_item.isusing = 0
		userdata.using_gift_item = nil
        update_giftinfo_db(userinfo)
	end
end

--给userinfo穿一个礼物
function gift_usegiftitem(userinfo, itemindex)
	local userdata = deskmgr.getuserdata(userinfo)
	local giftinfo = userdata.giftinfo
	if not giftinfo[itemindex] then
		TraceError("试图穿不存在的礼物，客户端发了个怪index")
		return false
	end

	if userdata.using_gift_item and userdata.using_gift_item.index ~= itemindex then
		userdata.using_gift_item.isusing = 0
		userdata.using_gift_item = nil
	end

	userdata.using_gift_item = giftinfo[itemindex]
	userdata.using_gift_item.isusing = 1
	update_giftinfo_db(userinfo)
    eventmgr:dispatchEvent(Event("on_using_gift", {userinfo=userinfo,iteminfo=userdata.using_gift_item}));
	return true
end

--更新拥有甜蜜之心的数量:ntype 1加1个，0减1个
function update_sweetheart_counts(userinfo, ntype)
	--TraceError("update_sweetheart_counts ntype:"..ntype)
	local sql = ""
    if(ntype == 1)then
        sql = "insert ignore into user_sweetheart_info (user_id, nick_name, update_time, counts)";
        sql = sql .." values(%d, '%s', now(), 1) "
        sql = sql .."ON DUPLICATE KEY UPDATE nick_name = '%s', update_time = now(), counts = counts + 1; commit;";
        sql = format(sql, userinfo.userId, userinfo.nick, userinfo.nick);
    else
        sql = "update user_sweetheart_info set nick_name='%s', update_time=now(), counts=counts - 1 where user_id=%d; commit; ";
        sql = format(sql, userinfo.nick, userinfo.userId);
    end
    
	dblib.execute(sql,function(dt)end, userinfo.userId)
end

--获取某个userinfo的礼物总数（todo：缓存下，不用遍历）
function gift_getgiftcount(userinfo)
	local userdata = deskmgr.getuserdata(userinfo)
	local giftinfo = userdata.giftinfo 
	local giftcount = 0
	for k, item in pairs(userdata.giftinfo) do
		giftcount = giftcount + 1
	end
	return giftcount
end

--给userinfo增加一个礼物，并自动穿上
function gift_addgiftitem(userinfo, itemid, fromuserid, fromusernick, is_useing)
	local _tosqlstr = function(s) 
			s = string.gsub(s, "\\", " ") 
			s = string.gsub(s, "\"", " ") 
			s = string.gsub(s, "\'", " ") 
			s = string.gsub(s, "%)", " ") 
			s = string.gsub(s, "%(", " ") 
			s = string.gsub(s, "%%", " ") 
			s = string.gsub(s, "%?", " ") 
			s = string.gsub(s, "%*", " ") 
			s = string.gsub(s, "%[", " ") 
			s = string.gsub(s, "%]", " ") 
			s = string.gsub(s, "%+", " ") 
			s = string.gsub(s, "%^", " ") 
			s = string.gsub(s, "%$", " ") 
			s = string.gsub(s, ";", " ") 
			s = string.gsub(s, ",", " ") 
			s = string.gsub(s, "%-", " ") 
			s = string.gsub(s, "%.", " ") 
			return s 
		end
	fromusernick=_tosqlstr(fromusernick)

	local userdata = deskmgr.getuserdata(userinfo)
	local giftinfo = userdata.giftinfo 
	local maxindex = 0
	for k, item in pairs(userdata.giftinfo) do
		if maxindex < k then maxindex = k end
    end

    if (is_useing == true or is_useing == nil) then
	    is_useing = true
    end
    
    
    --查看是不是再config_for_yunying中配置了不可以佩戴的物品
    for _,v in pairs (config_for_yunying.cannot_puton_gift) do
			if v == itemid then
				is_useing = false
				break
			end
		end
		
    if (is_useing) then
        if userdata.using_gift_item then userdata.using_gift_item.isusing = 0 end
    end
	local giftitem = _S
	{
		id 			= itemid,
		experiod 	= 0,
		isusing		= is_useing == true and 1 or 0,
		fromuserid 	= fromuserid,			
		fromuser	= fromusernick,
        --暂时只有5000-6000的礼品可以出售
        cansale     = (tonumber(itemid) >5000 and tonumber(itemid) < 6000) and 1 or 0,
        --卖出价格
        salegold    = 0,
		index		= maxindex + 1,
	}
	--价格
	local giftprice = gift_get_sale_price(itemid);
	if giftprice and giftprice > 0 then --5006是情人节的，卖得比较便宜
          giftitem.salegold = giftprice;
	end

	userdata.giftinfo[giftitem.index] = giftitem
    if (is_useing) then
	    userdata.using_gift_item = giftitem
        eventmgr:dispatchEvent(Event("on_using_gift", {userinfo=userinfo,iteminfo=userdata.using_gift_item}));
    end
    --更新拥有的甜蜜之心数量
    if(itemid == 5006)then
        update_sweetheart_counts(userinfo, 1)
    end

	update_giftinfo_db(userinfo)
    xpcall(function() parkinglib.on_add_gift_item(userinfo, itemid); end,throw);
	return giftitem
end

function gift_get_sale_price(itemid)
    local giftprice = tex.cfg.giftlist[itemid]
	if giftprice and giftprice > 0 then --5006是情人节的，卖得比较便宜
        if(itemid == 5006)then
		    giftprice = 179999
        else            
            --giftprice = math.floor(giftprice * 0.95)
            giftprice = giftprice
        end
    end
    return giftprice;
end

--给userinfo删除某礼物，酌情自动脱掉 
--返回-1表示没有删除物品，0表示删除成功，1表示删除穿着的物品
function gift_removegiftitem(userinfo, itemindex)
	local userdata = deskmgr.getuserdata(userinfo)
	local giftinfo = userdata.giftinfo
	if not giftinfo[itemindex] then
		TraceError("试图删除不存在的礼物，客户端发了个怪index")
		return -1
    end
	giftinfo[itemindex] = nil

	local ret = 0
	if userdata.using_gift_item and userdata.using_gift_item.index == itemindex then
		userdata.using_gift_item = nil
		ret = 1
    end

	update_giftinfo_db(userinfo)

	return ret
end

--同步内存数据到数据库
function update_giftinfo_db(userinfo)
	local userdata = deskmgr.getuserdata(userinfo)
	--TraceError("userdata.giftinfo"..tostringex(userdata.giftinfo))
	local dbstr = gift_tbl2str(userinfo, userdata.giftinfo)
	dblib.cache_set(gamepkg.table, {icon_info=dbstr}, "userid", userinfo.userId, function() end, userinfo.userId)
end



--礼物字符串转 礼物数据 及 使用中的礼物id
--前面几个:日期|买礼物金额|卖礼物金额|礼物信息|..|..
function gift_str2tbl(userinfo, giftstr)
	local ret = {}
	local dbgiftlist = split(giftstr, "|")
	local using_gift_item = nil
	userinfo.gift_today = ""	--礼物的今天日期
	for k, v in pairs(dbgiftlist) do
		if v ~= "" then
			local list = split(v, ";")
			if(tonumber(list[1]) > 0) then
				local item = _S
				{
					id 			= tonumber(list[1]),			--数字
					experiod 	= tonumber(list[2]),			--0 保留
					isusing		= tonumber(list[3]),			--是否在使用中 1/0
					fromuserid 	= tonumber(list[4]),			
					fromuser	= string.HextoString(list[5]),
					--暂时只有5000-6000的礼品可以出售
					cansale     = (tonumber(list[1]) >5000 and tonumber(list[1]) < 6000) and 1 or 0,
					salegold    = 0,
					index		= #ret + 1,
				}
				if not using_gift_item and item.isusing == 1 then
					using_gift_item = item
				else
					item.isusing = 0				--顺便做异常处理防止同时使用多个礼物
				end
				--价格
				local giftprice = tex.cfg.giftlist[item.id]
				if giftprice and giftprice > 0 then 
                    if(item.id == 5006) then
					    item.salegold = 179999 --5006是情人节的，卖得比较便宜
                    else
                        --item.salegold = math.floor(giftprice * 0.95)
                        item.salegold = giftprice;
                    end
				end
				table.insert(ret, item)
			elseif(tonumber(list[1]) == -1) then  --这个是配置信息,记录当天日期和购买、销售礼品的总金额
				userinfo.gift_today = list[2]	--今天日期
				userinfo.buygiftgold = tonumber(list[3])	--今天购买额
				userinfo.salegiftgold = tonumber(list[4])	--今天销售额
			end
		end
	end
	return ret, using_gift_item
end

--礼物数据转字符串
function gift_tbl2str(userinfo, giftinfo)
	local strarr = {}
	--记录当天购买物品和销售物品的总金额
	table.insert(strarr, format("-1;%s;%d;%d", userinfo.gift_today, userinfo.buygiftgold, userinfo.salegiftgold))
	for _, item in pairs(giftinfo) do
		table.insert(strarr,  
					 item.id .. ";" .. 
					 item.experiod .. ";" .. 
					 item.isusing .. ";" .. 
					 item.fromuserid .. ";" .. 
					 string.toHex(item.fromuser)
		)
	end
	return table.concat(strarr, "|")
end

-----------------------------周末狂欢送vip活动-----------------------------------
function check_user_beta_gife(userinfo)
	if not userinfo then return end

	local starttime = os.time{year = 2010, month = 12, day = 4,hour = 0};
	local endtime = os.time{year = 2010, month = 12, day = 6,hour = 0};
	local sys_time = os.time()
	local bvalid = true
    if(sys_time < starttime or sys_time > endtime) then
        return
	end

	dblib.execute(string.format("call sp_getuser_weekendVIP_info(%d,%d)",userinfo.userId,0),
		function(dt)
			if dt and #dt > 0 then
				userinfo.cangivebetagife = 0
				if dt[1]["result"] == 1 then
					userinfo.cangivebetagife = 1
					netlib.send(
						function(buf)
							buf:writeString("SHOWBETAGIFE")
						end,userinfo.ip,userinfo.port)
				end
			else
				TraceError("获取玩家公测送礼出错")
			end
		end)
end

function on_reve_give_betagife(buf)
	local userinfo = userlist[getuserid(buf)]
	if not userinfo then return end

	local starttime = os.time{year = 2010, month = 12, day = 4,hour = 0};
	local endtime = os.time{year = 2010, month = 12, day = 6,hour = 0};
	local sys_time = os.time()
	local bvalid = true
    if(sys_time < starttime or sys_time > endtime) then
        return
	end

	if not userinfo.cangivebetagife or userinfo.cangivebetagife ~= 1 then
		TraceError("收到非法送礼")
		return
	end

	give_user_bate_gife(userinfo)
end

function give_user_bate_gife(userinfo)
	local gifelist = {} --get_random_gifeid_list() --不送礼物，只送VIP

	if #gifelist >= 0 then
		--打乱
		table.disarrange(gifelist)

		for k,v in pairs(gifelist) do
			gift_addgiftitem(userinfo,v,userinfo.userId,userinfo.nick)
		end

		--送VIP
		local sql = ""
		sql = "insert into user_vip_info values(%d,1,DATE_ADD(now(),INTERVAL %d DAY),0,0)"
		sql = sql.." ON DUPLICATE KEY UPDATE over_time = case when over_time > now() then DATE_ADD(over_time,INTERVAL %d DAY) else DATE_ADD(now(),INTERVAL %d DAY) end,notifyed = 0,first_logined = 0; "
		sql = string.format(sql,userinfo.userId,2,2,2)

		dblib.execute(sql,
			function(dt)
				netlib.send(
					function(buf)
						buf:writeString("REGIFT")
						buf:writeByte(#gifelist)
						for i = 1,#gifelist do
							buf:writeInt(gifelist[i])
						end
					end,userinfo.ip,userinfo.port)
			end,userinfo.userId)

		--写入数据库
		dblib.execute(string.format("call sp_getuser_weekendVIP_info(%d,%d)",userinfo.userId,1))
	else
		TraceError("诡异了,礼物ID没随机出来？")
	end	
end

function get_random_gifeid_list()
	local num = math.random(0,2)--随机一种方式
	local tGifeId = {}

	if num == 0 then
		tGifeId = get_random_giftid(3,1,{4001,4005})
	elseif num == 1 then
		local gifelucky = get_random_giftid(2,1,{4006,4013})
		for i = 1,2 do
			table.insert(tGifeId,gifelucky[i])
		end
		local gifenolucky = get_random_giftid(1,0)
		table.insert(tGifeId,gifenolucky[1])
	else
		local gifeid = math.random(4014,4017)
		table.insert(tGifeId,gifeid)
		local gifenolucky = get_random_giftid(2,0)
		table.insert(tGifeId,gifenolucky[1])
		table.insert(tGifeId,gifenolucky[2])
	end

	return tGifeId
end

--得到随机的非吉祥物礼物ID,num--取几个ID,nType--0非幸运，1幸运
function get_random_giftid(num,nType,limitnum)
	local idlist = {}
	for k,v in pairs(tex.cfg.giftlist) do
		if nType == 1 then
			if k >= limitnum[1] and k <= limitnum[2] then
				table.insert(idlist,k)
			end
		else
			if k < 4001 then
				table.insert(idlist,k)
			end
		end
	end

	local gifeidlist = {}
	for i = 1,num do
		local id = math.random(1,#idlist)
		table.insert(gifeidlist,idlist[id])
		table.remove(idlist,id)
	end

	return gifeidlist
end
-----------------------------周末狂欢送vip活动(结束)-----------------------------------

--见面事件, 通知玩家特殊图标
if tex.on_meet_event then
	eventmgr:removeEventListener("meet_event", tex.on_meet_event);
end
--见面事件
tex.on_meet_event = function(e)
	--  e.data.subject      ： 状态改变的玩家
	--  e.data.observer     :  观察者
	--  将状态改变的玩家信息通知给观察者
    local time1 = os.clock() * 1000
	local userdata = deskmgr.getuserdata(e.data.subject)
	if e.data.subject.site then
		local gift_id = 0
		if userdata.using_gift_item then
            gift_id = userdata.using_gift_item.id
        else
            local using_item = parkinglib.get_using_car_info(e.data.subject);
            if(using_item ~= nil) then
                gift_id = using_item.id;
            end
		end
		net_send_gift_icon(e.data.observer, e.data.subject.site, gift_id or 0)
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 50)  then
        TraceError("德州礼物见面事件,时间超长:"..(time2 - time1))
    end
end
eventmgr:addEventListener("meet_event", tex.on_meet_event);

