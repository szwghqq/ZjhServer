TraceError("init user_sign_db...")

if user_sign_db and user_sign_db.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", user_sign_db.on_after_user_login);
end

if not user_sign_db then
    user_sign_db = _S
    {    	   
    	on_after_user_login = NULL_FUNC, --玩家登陆时初始化签到信息
 		record_sign_info = NULL_FUNC,    --记录签到信息
 		get_sign_info = NULL_FUNC,       --得到签到信息
 		log_user_sign_reward = NULL_FUNC, --记录领奖日志
 		get_current_day = NULL_FUNC,     --得到对应时间的day值
        clear_sign_info = NULL_FUNC,
        is_next_day = NULL_FUNC,
    }    
end

--玩家登陆时初始化签到信息
function user_sign_db.on_after_user_login(e)
	local user_info = e.data.userinfo
	if(user_info == nil)then 
		TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
    
	if(signinlib)then
		user_sign_db.get_sign_info(user_info,signinlib.reloadUserDataFromDB)
	end
end

--记录签到信息
function user_sign_db.record_sign_info(user_id)
	
	local today = user_sign_db.get_current_day(os.time())
	local lingjiang_time = 0
	local sign_info = ""
	local sql = "select sign_info,lingjiang_time from t_sign_list_tex where user_id=%d limit 1"
	sql = string.format(sql,user_id)

	dblib.execute(sql,function(dt)
		if(dt and #dt>0)then
			lingjiang_time = timelib.db_to_lua_time(dt[1].lingjiang_time)
			sign_info = dt[1].sign_info or ""
		end
		if user_sign_db.is_next_day(lingjiang_time,os.time())==0 or sign_info=="" then
			sql="insert into t_sign_list_tex(user_id,sign_info,lingjiang_time,sys_time) value(%d,'%s',now(),now()) on duplicate key update sign_info='%s',lingjiang_time=now(),sys_time=now();" 
		else
			sql="insert into t_sign_list_tex(user_id,sign_info,lingjiang_time,sys_time) value(%d,'%s',now(),now()) on duplicate key update sign_info=CONCAT(sign_info,',%s'),lingjiang_time=now(),sys_time=now();"
	    end
		sql=string.format(sql,user_id,today,today)
		dblib.execute(sql,function(dt) end,user_id)
	end,user_id)
    sql = "insert into log_user_sign_info(user_id,sys_time) value(%d,now());"
    sql = string.format(sql, user_id)
    dblib.execute(sql, function(dt) end, user_id)
end

function user_sign_db.clear_sign_info(user_id)
    local sql = string.format("UPDATE t_sign_list_tex SET sign_info='',sys_time=now() WHERE user_id = %d", user_id);
    dblib.execute(sql, function(dt)end, user_id);
end

--0超过1天了，1还在1天内
function user_sign_db.is_next_day(time1,time2)
    if time1==nil or time2==nil or time1=="" or time2=="" then return 0 end
	local table_time1 = os.date("*t",time1);
	local year1  = table_time1.year;
	local month1 = table_time1.month;
	local day1 = table_time1.day;
	local time1 = year1.."-"..month1.."-"..day1.." 00:00:00"
	
	local table_time2 = os.date("*t",time2);
	local year2  = tonumber(table_time2.year);
	local month2 = tonumber(table_time2.month);
	local day2 = tonumber(table_time2.day);
	local time2 = year2.."-"..month2.."-"..day2.." 00:00:00"
	
	--容错处理，如果时间拿到空的，会得到1970年
	if tonumber(year1)<2012 or tonumber(year2)<2012 then 
		return 0 
	end
	if timelib.db_to_lua_time(time2)-timelib.db_to_lua_time(time1) > 60*60*24 then
		return 0
	end
	return 1
	
end

--得到签到信息
function user_sign_db.get_sign_info(user_info,call_back)
    local user_id = user_info.userId
	--得到连继签到的数据
	local get_last_sign_info = function(tmp_str,lingjiang_time)
		--如果最后一次签到的日期与今天差的天数超过了一天就返回空字符串
		if user_sign_db.is_next_day(timelib.db_to_lua_time(lingjiang_time),os.time())==0 then
			tmp_str = ""
		end
		return tmp_str
	end
	
	if(call_back==nil)then return end
	
    local sign_info_list = {}
	local sign_info=""
	local lingjiang_time=""
    local sys_time=""
    local sql="select sign_info,lingjiang_time,sys_time from t_sign_list_tex where user_id=%d"
    sql=string.format(sql,user_id)

    dblib.execute(sql,function(dt) 
    	if(dt and #dt>0)then
    		sign_info=dt[1].sign_info
    		lingjiang_time=dt[1].lingjiang_time
    		sign_info=get_last_sign_info(sign_info,lingjiang_time)
    		
    		sign_info_list=split(sign_info,",")
            sys_time=dt[1].sys_time
        end
        
        call_back(user_info,sign_info_list,lingjiang_time,sys_time)
        eventmgr:dispatchEvent(Event("user_login_already_get_sign_db", _S{userinfo = user_info}))
    end,user_id)
end

----记录领奖时间并记录日志
function user_sign_db.log_user_sign_reward(user_id,lingjiang_type)
	local sql="update t_sign_list_tex set lingjiang_time=now() where user_id=%d;insert into log_user_sign_reward_qp(user_id,lingjiang_type,sys_time) value(%d,%d,now());"
	sql=string.format(sql,user_id,user_id,lingjiang_type)
	dblib.execute(sql,function(dt) end,user_id)
end


--得到指定时间的天是对应哪天
function user_sign_db.get_current_day(lua_time)
	return os.date("%d", lua_time)
end

--协议命令
cmd_user_sign_db_handler = 
{

}

--加载插件的回调
for k, v in pairs(cmd_user_sign_db_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", user_sign_db.on_after_user_login);
