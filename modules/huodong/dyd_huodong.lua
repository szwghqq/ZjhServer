TraceError("init dyd_lib...")
if dyd_lib and dyd_lib.ongameover then 
	eventmgr:removeEventListener("on_game_over_event", dyd_lib.ongameover);
end

if dyd_lib and dyd_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", dyd_lib.restart_server);
end

if dyd_lib and dyd_lib.timer then
	eventmgr:removeEventListener("timer_second", dyd_lib.timer);
end

if dyd_lib and dyd_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", dyd_lib.on_user_exit);
end

if dyd_lib and dyd_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", dyd_lib.on_after_user_login);
end

if not dyd_lib then
    dyd_lib = _S
    {
    	--以下是方法
  		ongameover = NULL_FUNC,
  		restart_server = NULL_FUNC,
  		timer = NULL_FUNC,
  		on_user_exit = NULL_FUNC,
  		on_after_user_login = NULL_FUNC,
        
        --以下是变量及配置信息
		user_list = {},
		flag_count = 0, --已插旗数量
		notify_flag = 0,
		CFG_ROOM_BET = {
			[1] = 10, 
			[2] = 100, --小于100是业余
			[3] = 1000, --小于1000是职业,大于等于1000是专家
		},
		start_time = "2012-09-15 00:00:01",
		end_time = "2012-09-19 00:00:01",
		rank_time = "2012-09-20 00:00:01",
		CQ_PM_LEN = 10,
		cq_pm_list = {},
		CFG_PANSHU = 20,
		CFG_GIVE_FLAG = {
			[1] = 1, 
			[2] = 3, 
			[3] = 10, 
			
		},
		CFG_REWARD_CAR = {
			[1] = 5038, 
			[2] = 5021, 
			[3] = 5011, 
			[4] = 5011,
			[5] = 5012,
			[6] = 5012,
			[7] = 5012,
			[8] = 5012,
			[9] = 5012,
			[10] = 5012,
		},
		fajiang_flag = "0",
    }
end

dyd_lib.CFG_FLAG_NEED = 4000
dyd_lib.CFG_MAX_FLAG = dyd_lib.CFG_FLAG_NEED * 50
--1 业余 2职业 3专家
function dyd_lib.get_room_type(small_bet)
	if small_bet < dyd_lib.CFG_ROOM_BET[1] then
		return -1
	elseif small_bet < dyd_lib.CFG_ROOM_BET[2] then
		return 1
	elseif small_bet < dyd_lib.CFG_ROOM_BET[3] then
		return 2
	elseif small_bet >= dyd_lib.CFG_ROOM_BET[3] then
		return 3
	end
	return 1
end 

function dyd_lib.on_after_user_login(e)
	local user_info = e.data.userinfo
	if user_info == nil then return end
	local user_id = user_info.userId
	dyd_db_lib.init_user(user_id)
	dyd_lib.send_already_flag(user_info)
end

function dyd_lib.ongameover(e)
	--活动时间判断
	local status = dyd_lib.check_time()
	if status ~= 1 then return end
	if dyd_lib.flag_count > dyd_lib.CFG_MAX_FLAG then return end 
	local user_info = e.data.user_info
	if user_info == nil then return end
	
	local user_id = user_info.userId
	local deskno = user_info.desk
	local deskinfo = desklist[deskno]
	local room_type = dyd_lib.get_room_type(deskinfo.smallbet)
	if room_type > 0 then
		dyd_lib.user_list[user_id].play_count[room_type] = dyd_lib.user_list[user_id].play_count[room_type] + 1
		if dyd_lib.user_list[user_id].play_count[room_type] % dyd_lib.CFG_PANSHU == 0 then
			dyd_lib.give_flag(user_id, room_type)
			dyd_lib.send_get_flag(user_info, dyd_lib.CFG_GIVE_FLAG[room_type])
			dyd_lib.cha_qi(user_info)		
		end
		
		dyd_lib.send_panshu(user_info)
	end
end

function dyd_lib.give_flag(user_id, room_type)
	dyd_lib.user_list[user_id].userflag_count = dyd_lib.user_list[user_id].userflag_count + dyd_lib.CFG_GIVE_FLAG[room_type]
	dyd_db_lib.add_user_flag(user_id, dyd_lib.CFG_GIVE_FLAG[room_type]) 
end

function dyd_lib.on_user_exit(e)
	local user_id = e.data.user_id
	if user_id == nil then return end
	if dyd_lib.user_list[user_id] ~= nil then
		dyd_db_lib.save_user_info(user_id)
		dyd_lib.user_list[user_id] = nil
	end
end

function dyd_lib.restart_server(e)
	dyd_db_lib.init_server_flag()
	dyd_db_lib.init_server_pm()
end

function dyd_lib.timer(e)
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	local current_time = e.data.time
	local table_time = os.date("*t", current_time);
	local now_year = table_time.year
	local now_month = table_time.month
	local now_day = table_time.day	
	local now_hour = table_time.hour
	local now_min = table_time.min
	local now_sec = table_time.sec
	--if now_year == 2012 and now_month == 9 and now_day == 19 and now_hour==0 and now_min == 0 and now_sec == 1 then
	--	dyd_lib.fajiang()
	--end
	
	--改成10秒保存一次数据
	if current_time % 10 == 0 then
		dyd_db_lib.save_already_flag(dyd_lib.flag_count)
	end
	
	if dyd_lib.notify_flag == 1 then
		dyd_lib.notify_flag = 0
		for k, v in pairs(dyd_lib.user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info ~= nil then
				dyd_lib.send_pm(user_info)
				dyd_lib.send_user_flag(user_info)
				dyd_lib.send_already_flag(user_info)
			end
		end
	end
end

function dyd_lib.query_huodong_status(buf)
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	local status = dyd_lib.check_time()
	netlib.send(function(buf)
		buf:writeString("DYDSTATU")
		buf:writeByte(status)
	end, buf:ip(), buf:port()) 	 	 	 	
end

function dyd_lib.check_time()
	local status = 1

	local sys_time = os.time();
	
	--活动时间
	local start_time = timelib.db_to_lua_time(dyd_lib.start_time);
	local rank_time = timelib.db_to_lua_time(dyd_lib.rank_time);
	local end_time = timelib.db_to_lua_time(dyd_lib.end_time);
	if(sys_time < start_time or sys_time > rank_time) then
	    status = 0
	end
	
	if sys_time > end_time and sys_time < rank_time then
		status = 2
	end
	
	return status
end

function dyd_lib.cha_qi(user_info)
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	--local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	local send_result = function(result)
		netlib.send(function(buf)
			buf:writeString("DYDCAQI")
			buf:writeByte(result)
		end, user_info.ip, user_info.port)
	end
	
	if dyd_lib.user_list[user_id].userflag_count < 1 then
		send_result(0)
		return
	end
	
	dyd_lib.flag_count = dyd_lib.flag_count + dyd_lib.user_list[user_id].userflag_count
	if dyd_lib.flag_count >= dyd_lib.CFG_MAX_FLAG and dyd_lib.fajiang_flag == "0" then
		dyd_lib.fajiang_flag = "1"
		dyd_lib.fajiang()
		dyd_db_lib.update_fajiang_flag()
		--全服广播
		BroadcastMsg(_U("维护主权，守卫钓鱼岛活动圆满结束！五星红旗飘扬在钓鱼岛上，感谢所有玩家对此活动的支持与参与！"),0);
	end
	
	dyd_lib.user_list[user_id].already_userflag_count = dyd_lib.user_list[user_id].already_userflag_count + dyd_lib.user_list[user_id].userflag_count  
	dyd_lib.user_list[user_id].userflag_count = 0	
	dyd_db_lib.clear_userflag(user_id)
	
	send_result(1)
	
	--看看有没有资格上榜
	
	local len = #dyd_lib.cq_pm_list
	local buf_tab = {
		["user_id"] = user_id,
		["nick_name"] = user_info.nick or "",
		["cq_count"] = dyd_lib.user_list[user_id].already_userflag_count,
	}
	local isfinder = 0
	for k, v in pairs(dyd_lib.cq_pm_list) do
		if v.user_id == user_id then
			v.cq_count = buf_tab.cq_count
			isfinder = 1
			break
		
		end
	end
	
	if isfinder == 0 then
		if  len < dyd_lib.CQ_PM_LEN then
			table.insert(dyd_lib.cq_pm_list, buf_tab)
		elseif dyd_lib.user_list[user_id].already_userflag_count > dyd_lib.cq_pm_list[len].cq_count then
			dyd_lib.cq_pm_list[len] = buf_tab
		end
	end

	if len > 1 then
		table.sort(dyd_lib.cq_pm_list, 
		      function(a, b)
			     return a.cq_count > b.cq_count		                   
		end)
	end
	
	dyd_lib.notify_flag = 1
end

function dyd_lib.open_pl(buf)
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	dyd_lib.send_pm(user_info)

end

function dyd_lib.send_pm(user_info)
	local len = #dyd_lib.cq_pm_list
	if len > dyd_lib.CQ_PM_LEN then len = dyd_lib.CQ_PM_LEN end
	netlib.send(function(buf)
		buf:writeString("DYDOPPL")
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(dyd_lib.cq_pm_list[i].user_id)
			buf:writeString(dyd_lib.cq_pm_list[i].nick_name)
			buf:writeString("") --头像，预留
			buf:writeInt(dyd_lib.cq_pm_list[i].cq_count)
		end
	end, user_info.ip, user_info.port)
end

function dyd_lib.send_panshu(user_info)
	if user_info == nil then return end
	local user_id = user_info.userId
	netlib.send(function(buf)
		buf:writeString("DYDPANSHU")
		buf:writeInt(user_id)
		buf:writeInt(dyd_lib.user_list[user_id].play_count[1])
		buf:writeInt(dyd_lib.user_list[user_id].play_count[2])
		buf:writeInt(dyd_lib.user_list[user_id].play_count[3])
	end, user_info.ip, user_info.port)
end

function dyd_lib.fajiang()
	local len = #dyd_lib.cq_pm_list
	if len > dyd_lib.CQ_PM_LEN then
		len = dyd_lib.CQ_PM_LEN
	end
	for i = 1, len do
		local user_id = dyd_lib.cq_pm_list[i].user_id
		local car_type = dyd_lib.CFG_REWARD_CAR[i]
		car_match_db_lib.add_car(user_id,car_type, 0, 1)
		local user_info = usermgr.GetUserById(user_id)
		if user_info ~= nil then
			dyd_lib.send_reward_msg(user_id, i)
		else
			dyd_db_lib.update_fajiang_notify(user_id, i)
		end
	end
end

function dyd_lib.send_reward_msg(user_id, notify_num)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	local car_type = dyd_lib.CFG_REWARD_CAR[notify_num]
	netlib.send(function(buf)
		buf:writeString("DYDREWARD")
		buf:writeInt(notify_num)
		buf:writeString(_U(car_match_lib.CFG_CAR_INFO[car_type]["name"]))
	end, user_info.ip, user_info.port)
	dyd_db_lib.update_fajiang_notify(user_id, 0)
end

function dyd_lib.send_get_flag(user_info, add_flag)
	if user_info == nil then return end

	netlib.send(function(buf)
		buf:writeString("DYDGET")
		buf:writeInt(add_flag)
	end, user_info.ip, user_info.port)
end

function dyd_lib.send_user_flag(user_info)
	if user_info == nil then return end
	local user_id = user_info.userId
	netlib.send(function(buf)
		buf:writeString("DYDFLAG")
		buf:writeInt(dyd_lib.user_list[user_id].already_userflag_count)
	end, user_info.ip, user_info.port)
end

function dyd_lib.send_already_flag(user_info)
	if user_info == nil then return end
	local user_id = user_info.userId
	netlib.send(function(buf)
		buf:writeString("DYDYCQ")
		buf:writeInt(dyd_lib.flag_count)
		buf:writeInt(dyd_lib.CFG_FLAG_NEED)		
	end, user_info.ip, user_info.port)
end

--命令列表
cmdHandler = 
{
    ["DYDSTATU"] = dyd_lib.query_huodong_status, --查询活动是否进行中
    ["DYDCAQI"] = dyd_lib.cha_qi, -- 插旗
    ["DYDOPPL"] = dyd_lib.open_pl, -- 打开面板

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", dyd_lib.timer); 
eventmgr:addEventListener("on_game_over_event", dyd_lib.ongameover); 
eventmgr:addEventListener("on_server_start", dyd_lib.restart_server); 
eventmgr:addEventListener("on_user_exit", dyd_lib.on_user_exit); 
eventmgr:addEventListener("h2_on_user_login", dyd_lib.on_after_user_login); 
