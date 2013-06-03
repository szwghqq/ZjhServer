TraceError("init vip....")

if not viplib then
	viplib = _S
	{
		load_user_vip_info_from_db 				= NULL_FUNC,			--从数据库中读取vip信息
		get_user_vip_info						= NULL_FUNC,			--获取玩家vip信息
		set_user_vip_info						= NULL_FUNC,			--设置玩家vip信息
		check_user_vip							= NULL_FUNC,			--获取玩家是不是vip
		get_vip_level                           = NULL_FUNC,			--获取玩家的最高VIP等级
		check_user_vip_case						= NULL_FUNC,			--检查玩家VIP状态以及写入内存
		on_reve_load_user_vip_info_from_db		= NULL_FUNC,			--请求获得最新的VIP信息

		give_user_vip						    = NULL_FUNC,			--外部接口，给予玩家VIP资格

		on_meet_event							= NULL_FUNC,			--见面事件

		net_send_my_vip_info					= NULL_FUNC,			--发送自己的vip信息
		net_send_vip_info						= NULL_FUNC,			--发送,说某个座位的VIP状态
		net_send_vip_case						= NULL_FUNC,			--通知客户端会员充值是否成功或是否过期
		add_user_vip						= NULL_FUNC,			--送VIP
		--不同VIP身份每天领奖的加成:铜牌888，银牌1888，金牌3888,钻石5888,白金8888,钛金
		add_day_gold ={888,1888,3888,5888,8888, 88888},
	}
end

function viplib.add_user_vip(userinfo,vip_level,vip_days)
		--送VIP
		local sql = "";
		sql = "insert into user_vip_info values(%d,%d,DATE_ADD(now(),INTERVAL %d DAY),0,0)";
		sql = sql.." ON DUPLICATE KEY UPDATE over_time = case when over_time > now() then DATE_ADD(over_time,INTERVAL %d DAY) else DATE_ADD(now(),INTERVAL %d DAY) end,notifyed = 0,first_logined = 0; ";
		sql = string.format(sql,userinfo.userId,vip_level,vip_days,vip_days,vip_days);
		dblib.execute(sql);
end

--从数据库中读取vip信息
viplib.load_user_vip_info_from_db = function(user_id, call_back)
	--TraceError("viplib.load_user_vip_info_from_db()")
	local userinfo = usermgr.GetUserById(user_id)
    if not userinfo then  return end
	dblib.execute(string.format("select * from user_vip_info where user_id = %d;", user_id),
		function(dt)
			if dt and #dt > 0 then
				viplib.check_user_vip_case(userinfo,dt)
				--得到踢人卡次数
                if (tex_buf_lib) then
                    xpcall(function() tex_buf_lib.load_kick_card_from_db(userinfo) end, throw)
                end
				--刷新数据事件
                eventmgr:dispatchEvent(Event("on_after_refresh_info", userinfo));

            end
            --通知大厅是否显示每日登陆送钱
	        xpcall(
	            function()
	                give_daygold_check(userinfo)
	            end,throw)
          
            --vip登陆送奖券
            if (tex_dailytask_lib) then
                xpcall(function() tex_dailytask_lib.on_after_user_login(userinfo, viplib.get_vip_level(userinfo)) end, throw)

            end
            if (call_back ~= nil) then
                call_back()
            end            
		end, user_id)
end

viplib.on_reve_load_user_vip_info_from_db = function(buf)
    --TraceError("刷洗vip info")
	local userinfo = userlist[getuserid(buf)]
	if not userinfo then  return end
	viplib.load_user_vip_info_from_db(userinfo.userId)
end

--检查玩家VIP状态以及写入内存
viplib.check_user_vip_case = function(userinfo,dt)
	if not userinfo or not dt or #dt <=0 then return end
	local user_id = userinfo.userId		
	local vip_info = {}
	for i = 1, #dt do
		local sql = ""
        local over_time = timelib.db_to_lua_time(dt[i].over_time) or 0
		local is_over = over_time < os.time() and 1 or 0
		if is_over == 1 or dt[i].vip_level <= 0 then	--过期
			if dt[i].notifyed == 0 then
				sql = "update user_vip_info set notifyed = 1 where user_id = %d and vip_level = %d;commit;"
				viplib.net_send_vip_case(userinfo,dt[i],0)--过期了首次登陆
			end
		else
			if dt[i].first_logined == 0 then
				sql = "update user_vip_info set first_logined = 1 where user_id = %d and vip_level = %d;commit;"
				dt[i].first_logined = 1
				viplib.net_send_vip_case(userinfo,dt[i],1)--刚充值了首次登陆
			end
			table.insert(vip_info, dt[i])
		end
		if(sql ~= "") then
			dblib.execute(format(sql, user_id, dt[i].vip_level))
		end
	end
	
	if(#vip_info > 0)then
		viplib.set_user_vip_info(userinfo, vip_info)
		viplib.net_send_my_vip_info(userinfo, vip_info)
	else
		viplib.set_user_vip_info(userinfo, nil)
	end
end

--看玩家是否是vip
viplib.check_user_vip = function(userinfo)
	local vip_info = viplib.get_user_vip_info(userinfo)
	if not vip_info then return false end

	local is_VIP = false
	for k,v in pairs(vip_info) do
		if(timelib.db_to_lua_time(v.over_time) > os.time() and v.vip_level > 0) then
			is_VIP = true
			break
		end
	end
	return is_VIP
end

--获取最高VIP等级
viplib.get_vip_level = function(userinfo)
    local max_level = 0
	local vip_info = viplib.get_user_vip_info(userinfo)
	if not vip_info then return max_level end
    --获取最高的等级
	for k,v in pairs(vip_info) do
		if(timelib.db_to_lua_time(v.over_time) > os.time()) then
			if(max_level < v.vip_level) then
                max_level = v.vip_level
            end
		end
	end
	return max_level
end

--获取玩家vip信息
viplib.get_user_vip_info = function(userinfo)
	return userinfo.vip_info
end

--设置玩家vip信息
viplib.set_user_vip_info = function(userinfo, vip_info)
	userinfo.vip_info = vip_info
end

--给玩家一个VIP资格和附送筹码
--ntype:给予的VIP类型，1铜牌，2银牌，3金牌
viplib.give_user_vip = function(userinfo, ntype)
    if(not userinfo) then return end
    if(ntype < 1 or ntype > 6) then return end --现在有VIP6了，这里加VIP6的人没改到。
    --送VIP
    local sql = ""
    sql = "insert into user_vip_info(user_id, vip_level, over_time, notifyed, first_logined) values(%d,%d,DATE_ADD(now(),INTERVAL %d DAY),0,0)";
    sql = sql.." ON DUPLICATE KEY UPDATE over_time = case when over_time > now() then DATE_ADD(over_time,INTERVAL %d DAY) else DATE_ADD(now(),INTERVAL %d DAY) end,notifyed = 0,first_logined = 0;commit; ";
    sql = string.format(sql,userinfo.userId, ntype, 30, 30, 30);
    dblib.execute(sql, function(dt) viplib.load_user_vip_info_from_db(userinfo.userId) end);
end
----------------------------------------事件处理-----------------------------------

if viplib.on_meet_event and viplib.on_meet_event ~= NULL_FUNC then
	eventmgr:removeEventListener("meet_event", viplib.on_meet_event);
end

--见面事件
viplib.on_meet_event = function(e)
    local time1 = os.clock() * 1000
	local userinfo = e.data.subject
	local vip_info = viplib.get_user_vip_info(userinfo)
	if vip_info then
		viplib.net_send_vip_info(e.data.observer, userinfo.userId, userinfo.site,  vip_info, e.data.relogin)	
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 50)  then
        TraceError("VIP见面事件,时间超长:"..(time2 - time1))
    end
end

eventmgr:addEventListener("meet_event", viplib.on_meet_event);

----------------------------------------网络------------------------------------

--发送自己的vip信息
viplib.net_send_my_vip_info = function(userinfo, vip_info)
	netlib.send(
		function(buf)
			buf:writeString("VIPMYI")
			buf:writeInt(#vip_info)
			for i=1,#vip_info do
				buf:writeInt(vip_info[i].vip_level)
				buf:writeString(vip_info[i].over_time)
			end
		end
	, userinfo.ip, userinfo.port)
end

--发送,说某个座位的VIP状态
viplib.net_send_vip_info = function(userinfo, userid, site, vip_info, relogin)
	netlib.send(
		function(buf)
			buf:writeString("VIPINF")
			buf:writeInt(userid)
			buf:writeByte(site or 0)
			buf:writeInt(#vip_info)
			for i=1,#vip_info do
				buf:writeInt(vip_info[i].vip_level)
				buf:writeString(vip_info[i].over_time)
			end
            buf:writeByte(relogin)
		end
	, userinfo.ip, userinfo.port)
end

--通知客户端会员充值是否成功或是否过期
viplib.net_send_vip_case = function(userinfo,vip_item,nType)
	if not userinfo or not vip_item then return end
	netlib.send(
		function(buf)
			buf:writeString("VIPOVR")
			buf:writeByte(nType)
			buf:writeByte(vip_item["vip_level"])
			if nType == 1 then
				buf:writeString(vip_item["over_time"])
			end
		end
	, userinfo.ip, userinfo.port)
end

--命令列表
cmdHandler = 
{
	["RQVIPIF"] = viplib.on_reve_load_user_vip_info_from_db,--请求获得最新的VIP信息
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
