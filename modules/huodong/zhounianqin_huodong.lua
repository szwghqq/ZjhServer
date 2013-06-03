TraceError("init zhounian_huodong_lib...")
if zhounian_huodong_lib and zhounian_huodong_lib.timer then
	eventmgr:removeEventListener("timer_second", zhounian_huodong_lib.timer);
end
if zhounian_huodong_lib and zhounian_huodong_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", zhounian_huodong_lib.on_after_user_login);
end 

if zhounian_huodong_lib and zhounian_huodong_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", zhounian_huodong_lib.restart_server);
end

if zhounian_huodong_lib and zhounian_huodong_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", zhounian_huodong_lib.on_user_exit);
end

if not zhounian_huodong_lib then
    zhounian_huodong_lib = _S
    {
		--方法
  		query_huodong_status = NULL_FUNC,
  		open_paiming = NULL_FUNC,
  		send_chenhao = NULL_FUNC,
  		timer = NULL_FUNC,
  		on_after_user_login = NULL_FUNC,
  		get_remain_time = NULL_FUNC,
  		restart_server = NULL_FUNC, 
  		send_reward = NULL_FUNC,
  		send_sys_msg = NULL_FUNC, 
  		send_huodong_status = NULL_FUNC, 
        on_user_exit = NULL_FUNC,
  		
  		--参数
  		user_list = {},
		need_refresh = 1,
		paiming_list = {},
		chenghao_list = {},
		CFG_PAIMING_LEN = 10,
		start_time = "2012-08-29 10:00:00",
		end_time = "2012-09-04 10:00:00",
		rank_time = "2012-09-05 10:00:00",
		CFG_CHENGHAO_TIME = 30, --30天过期
		CFG_ROOM_ID = "18001",
		CFG_CHENGHAO_NAME = {
			[1] = "THE RICHEST MAN",
			[2] = "I'M BUFFETT",
			[3] = "FABULOUSLY RICH",
		},
		CFG_REWARD_CAR = {
			[1] = 5039,
			[2] = 5040,
			[3] = 5041,
			
		}
    }    
end


function zhounian_huodong_lib.send_huodong_status(user_info, ret_status)
	netlib.send(function(buf)
		buf:writeString("CZHDSTAT")
		buf:writeInt(ret_status)
	end, user_info.ip, user_info.port)
end
function zhounian_huodong_lib.query_huodong_status(buf)
	if groupinfo.groupid ~= zhounian_huodong_lib.CFG_ROOM_ID then return end
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	

	local sys_time = os.time();
	
	--活动时间
	local start_time = timelib.db_to_lua_time(zhounian_huodong_lib.start_time);
	
	local rank_time = timelib.db_to_lua_time(zhounian_huodong_lib.rank_time);
	if(sys_time < start_time or sys_time > rank_time) then
	    zhounian_huodong_lib.send_huodong_status(user_info, 0)
	    return
	end
	
	zhounian_huodong_lib.send_huodong_status(user_info, 1)

end
function zhounian_huodong_lib.get_remain_time()
	local current_time = os.time()
	local end_time = timelib.db_to_lua_time(zhounian_huodong_lib.end_time)
	local remain_time = end_time - current_time
	return remain_time
	
end
function zhounian_huodong_lib.open_paiming(buf)
	if groupinfo.groupid ~= zhounian_huodong_lib.CFG_ROOM_ID then return end
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local open_type = buf:readByte()
	
	local send_paiming = function(paiming_list)
		netlib.send(function(buf)
			buf:writeString("CZHDOPEN")
			buf:writeInt(zhounian_huodong_lib.get_remain_time())
			buf:writeInt(#paiming_list)
			for i = 1, #paiming_list do
				buf:writeInt(paiming_list[i].user_id)
				buf:writeString(paiming_list[i].nick_name)
				buf:writeString(paiming_list[i].img_url)
				local disp_rmb = paiming_list[i].rmb
				if i > 3 then disp_rmb = 0 end
				buf:writeInt(disp_rmb)
				buf:writeString(paiming_list[i].sys_time)
			end
			buf:writeString(timelib.lua_to_db_time(os.time()))
		end, user_info.ip, user_info.port)
	end
	
	--如果是点了刷新，就要等数据返回后再发
	--if open_type == 1 then
	--	zhounian_huodong_db_lib.get_paiming(send_paiming)
	--else
	--	zhounian_huodong_lib.need_refresh = 1
	--	send_paiming(zhounian_huodong_lib.paiming_list)
	--end
	send_paiming(zhounian_huodong_lib.paiming_list)
end

function zhounian_huodong_lib.send_chenhao(send_user_info)
		if send_user_info ~= nil and #zhounian_huodong_lib.chenghao_list > 0 then
			netlib.send(function(buf)
				buf:writeString("CZHDCH")
				buf:writeInt(#zhounian_huodong_lib.chenghao_list)
				for i = 1, #zhounian_huodong_lib.chenghao_list do
					if os.time() > timelib.db_to_lua_time(zhounian_huodong_lib.chenghao_list[i].over_time) then
						buf:writeInt(-1)
						buf:writeInt(-1)
						buf:writeString(zhounian_huodong_lib.chenghao_list[i].over_time)
					else
						buf:writeInt(zhounian_huodong_lib.chenghao_list[i].user_id)
						buf:writeInt(zhounian_huodong_lib.chenghao_list[i].chenghao_id)
						buf:writeString(zhounian_huodong_lib.chenghao_list[i].over_time)
					end
				end
			end, send_user_info.ip, send_user_info.port)
		end

end

function zhounian_huodong_lib.timer(e)
	if groupinfo.groupid ~= zhounian_huodong_lib.CFG_ROOM_ID then return end
	local current_time = e.data.time
	local table_time = os.date("*t", current_time);
	local now_hour = table_time.hour
	local now_min = table_time.min
	local now_sec = table_time.sec
	local db_time = timelib.lua_to_db_time(current_time)
	if db_time == zhounian_huodong_lib.start_time then
		for k, v in pairs(zhounian_huodong_lib.user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info ~=nil then
				zhounian_huodong_lib.send_huodong_status(user_info, 1)
			end
		end
	end
	
	if current_time < timelib.db_to_lua_time(zhounian_huodong_lib.rank_time) and now_hour == 0 and now_min == 0 and now_sec == 1 then
		zhounian_huodong_db_lib.get_paiming()
	end
	
	if current_time > timelib.db_to_lua_time(zhounian_huodong_lib.end_time) and 
			current_time < timelib.db_to_lua_time(zhounian_huodong_lib.rank_time) and 
			now_hour == 10 and now_min == 0 and now_sec == 1 then
		zhounian_huodong_db_lib.get_paiming()
	end 
	
	if current_time > timelib.db_to_lua_time(zhounian_huodong_lib.end_time) and 
			current_time < timelib.db_to_lua_time(zhounian_huodong_lib.rank_time) and 
			now_hour == 10 and now_min == 0 and now_sec == 10 then
		--目前只有3个称号
		local len = 3
		if #zhounian_huodong_lib.paiming_list < 3 then
			len = #zhounian_huodong_lib.paiming_list
		end
		for i=1, len do
			local buf_tab = {}
			local user_id = zhounian_huodong_lib.paiming_list[i].user_id
			local chenghao_id = i --目前把名次等同于称号ID。需要的话以后再改
			if zhounian_huodong_lib.user_list[user_id] ~= nil then
				zhounian_huodong_lib.user_list[user_id].chenghao_id = chenghao_id
			end
			zhounian_huodong_db_lib.insert_chenghao(user_id, i, zhounian_huodong_lib.CFG_CHENGHAO_TIME)
			if i == 1 then
				car_match_db_lib.add_car(user_id,zhounian_huodong_lib.CFG_REWARD_CAR[i], 0, 0)
				local msg = _U("恭喜")..zhounian_huodong_lib.paiming_list[i].nick_name.._U("获得本次周年充值活动第")..i.._U("名，获得").._U(car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]).._U("一辆")
            	zhounian_huodong_lib.send_sys_msg(msg)
            	buf_tab.mc = i
            	buf_tab.car_name = car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]
            	buf_tab.chenghao_name = zhounian_huodong_lib.CFG_CHENGHAO_NAME[i]
			elseif i == 2 then
				car_match_db_lib.add_car(user_id,zhounian_huodong_lib.CFG_REWARD_CAR[i], 0, 0)
				local msg = _U("恭喜")..zhounian_huodong_lib.paiming_list[i].nick_name.._U("获得本次周年充值活动第")..i.._U("名，获得").._U(car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]).._U("一辆")
            	zhounian_huodong_lib.send_sys_msg(msg)
            	buf_tab.mc = i
            	buf_tab.car_name = car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]
            	buf_tab.chenghao_name = zhounian_huodong_lib.CFG_CHENGHAO_NAME[i]
			elseif i == 3 then
				car_match_db_lib.add_car(user_id,zhounian_huodong_lib.CFG_REWARD_CAR[i], 0, 0)
				local msg = _U("恭喜")..zhounian_huodong_lib.paiming_list[i].nick_name.._U("获得本次周年充值活动第")..i.._U("名，获得").._U(car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]).._U("一辆")
            	zhounian_huodong_lib.send_sys_msg(msg)
            	buf_tab.mc = i
            	buf_tab.car_name = car_match_lib.CFG_CAR_INFO[zhounian_huodong_lib.CFG_REWARD_CAR[i]]["name"]
            	buf_tab.chenghao_name = zhounian_huodong_lib.CFG_CHENGHAO_NAME[i]
			end
			local user_info = usermgr.GetUserById(user_id)
			if user_info ~= nil then
				timelib.createplan(
					function()
						zhounian_huodong_lib.chenghao_list[i].already_notify = 1
						zhounian_huodong_lib.send_chenhao(user_info)
						zhounian_huodong_lib.send_reward(user_info, buf_tab)
						zhounian_huodong_db_lib.update_chenghao_notify(user_id, chenghao_id)
					end, 20)				
			end			
		end
		
		--15秒后到数据库去刷新称号，防止数据库还没操作完
		timelib.createplan(
			function()
				zhounian_huodong_db_lib.gen_chenghao()
			end, 15)
	end
	
	--过了时间，让活动自动下线
	if current_time > timelib.db_to_lua_time(zhounian_huodong_lib.rank_time)  and now_hour == 10 and now_min == 0 and now_sec == 1 then
		for k, v in pairs(zhounian_huodong_lib.user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info ~= nil then
				netlib.send(function(buf)
					buf:writeString("CZHDSTAT")
					buf:writeInt(0)
				end, user_info.ip, user_info.port)
			end
		end
	end
end

function zhounian_huodong_lib.send_sys_msg(msg)
	for k, v in pairs(zhounian_huodong_lib.user_list) do
		local user_info = usermgr.GetUserById(v.user_id)
		if user_info ~= nil then
			netlib.send(function(buf)
		        buf:writeString("REDC");
		        buf:writeByte(4)      --desk chat
		        buf:writeString(msg or "")     --text
		        buf:writeInt(0)         --user id
		        buf:writeString("") --user name
		        buf:writeByte(0)
		    end,user_info.ip,user_info.port);
	    end
    end
end

function zhounian_huodong_lib.on_user_exit(e)
    local user_id = e.data.user_id;
    if(user_id ~= nil) then
        zhounian_huodong_lib.user_list[user_id] = nil;
    end
end

function zhounian_huodong_lib.on_after_user_login(e)

	if groupinfo.groupid ~= zhounian_huodong_lib.CFG_ROOM_ID then return end
	local user_info = e.data.userinfo
	if user_info == nil then return end
	local user_id = user_info.userId
	if zhounian_huodong_lib.user_list[user_id] == nil then 
		zhounian_huodong_lib.user_list[user_id] = {} 
		zhounian_huodong_lib.user_list[user_id].user_id = user_id
	end

	if os.time() > timelib.db_to_lua_time(zhounian_huodong_lib.end_time) then

		zhounian_huodong_lib.send_chenhao(user_info)
		for k, v in pairs(zhounian_huodong_lib.chenghao_list) do
			
			if v.user_id == user_id and v.already_notify == 0 then
				v.already_notify = 1
				local buf_tab = {}
				buf_tab.mc = v.mc
				local car_id = zhounian_huodong_lib.CFG_REWARD_CAR[v.mc]
            	buf_tab.car_name = car_match_lib.CFG_CAR_INFO[car_id]["name"]
            	buf_tab.chenghao_name = zhounian_huodong_lib.CFG_CHENGHAO_NAME[v.mc]
				zhounian_huodong_lib.send_reward(user_info, buf_tab)
				zhounian_huodong_db_lib.update_chenghao_notify(user_id, v.chenghao_id)
			end
		end
	end
end

function zhounian_huodong_lib.restart_server()
	if groupinfo.groupid ~= zhounian_huodong_lib.CFG_ROOM_ID then return end
	zhounian_huodong_db_lib.gen_chenghao()
    zhounian_huodong_db_lib.get_paiming()
end

function zhounian_huodong_lib.send_reward(user_info, buf_tab)
	if user_info == nil then return end
	if buf_tab == nil or buf_tab == {} then return end
	netlib.send(function(buf)
		buf:writeString("CZHDFJ")
		buf:writeInt(buf_tab.mc)
		buf:writeString(_U(buf_tab.car_name))
		buf:writeString(_U(buf_tab.chenghao_name))		
	end, user_info.ip, user_info.port)
end

--命令列表
cmdHandler = 
{
	["CZHDSTAT"] = zhounian_huodong_lib.query_huodong_status,
	["CZHDOPEN"] = zhounian_huodong_lib.open_paiming,
	

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", zhounian_huodong_lib.timer);
eventmgr:addEventListener("h2_on_user_login", zhounian_huodong_lib.on_after_user_login);
eventmgr:addEventListener("on_server_start", zhounian_huodong_lib.restart_server);
eventmgr:addEventListener("on_user_exit", zhounian_huodong_lib.on_user_exit);
