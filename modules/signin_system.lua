------------------------------------事件移除----------------------------------------
if signinlib and signinlib.on_after_user_login then
	eventmgr:removeEventListener("user_login_already_get_sign_db", signinlib.on_after_user_login)
end

if signinlib and signinlib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", signinlib.on_user_exit)
end

if signinlib and signinlib.on_timer_second then
    eventmgr:removeEventListener("timer_minute", signinlib.on_timer_minute)
end


--------------------------------------------------------------------------------------

--新的比赛场
if not signinlib then
signinlib = 
{
    l_check_today_is_signed = NULL_FUNC,        --得到今天是否已签到
    l_get_last_month_day = NULL_FUNC,           --得到这个月的最后一天
    l_check_time_is_this_month = NULL_FUNC,           --得到通过数据库时间求的月份
    l_get_user_is_full_duty = NULL_FUNC,           --得到用户是否全勤
    l_set_user_sign_info = NULL_FUNC,           --设置用户签到信息

    set_OP_SIGNIN_TASK_LIST = NULL_FUNC,            --修改签到奖励配置
    
    on_after_user_login = NULL_FUNC,            --登录事件
    on_user_exit = NULL_FUNC,            --用户退出
    on_timer_minute = NULL_FUNC,            --倒计时
    is_new_sign_day = NULL_FUN,             --2者是不是超过1天了
    on_recv_do_sign_in = NULL_FUNC,             --请求签到
    on_recv_sign_task_list = NULL_FUNC,          --请求打开签到面板

    net_send_do_sign_in = NULL_FUNC,      --发送签到结果
    net_send_sign_in_info = NULL_FUNC,    --发送签到信息
    send_OP_SIGNIN_TASK_LIST = NULL_FUNC, --发送奖励配置

    reloadUserDataFromDB = NULL_FUNC, --发送奖励配置
	get_date_from_time = NULL_FUNC,   --得到当天的日期
	
    --todo:cjz签到系统赛币改变的类型列表
    STATIC_ADD_GOLD_TYPE_SIGNIN_TASK_JIANGJUAN = 8,
    STATIC_ADD_GOLD_TYPE_SIGNIN_TASK_MATCH_GOLD = 9,

    MIN_MATCH_LAST_DAY = 28,
    SIGNIN_TASK_LIST_LEN = 0,

    user_list   = {},       --用户相关属性。
    


--------------------运营可调参数初始化------------------------------------------------------------------------ 
    OP_SIGNIN_TASK_LIST = {
        [1] = { }, [2] = { }, [3] = { }, [4] = { }, [5] = { }, [6] = { },[7]={},
    },
    
    item_config ={
    	[4] = "小喇叭",
    	[10] = "VIP3 金卡体验卡3天",
    	[11] = "T人卡",
    	[21] = "初级车位",
    	[22] = "中级车位",
    	[23] = "高级车位",
    	[5012] = "甲壳虫",
    	[5013] = "奥拓",

    	
    }
    
    
}
end

------------------------------------方法----------------------------------------
--稳这个月
signinlib.l_check_time_is_this_month = function(db_time)
    local ret = 0
    local lua_time = os.time()
    if db_time ~= nil and db_time ~= "" then
        lua_time = timelib.db_to_lua_time(db_time)
    end

    local month = tonumber(os.date("%m",os.time()))
    local year = tonumber(os.date("%Y",os.time()))
    if lua_time >= os.time({year=year, month=month, day=1, hour=0, minute=0, second=0}) then
        ret = 1
    end
    return ret
end

signinlib.l_check_today_is_signed = function(user_info)
	
	if signinlib.user_list[user_info.userId].last_sign_reward_time==nil or signinlib.user_list[user_info.userId].last_sign_reward_time=="" then return 0 end
    local last_sign_reward_time=timelib.db_to_lua_time(signinlib.user_list[user_info.userId].last_sign_reward_time) or 0
    local table_time1 = os.date("*t",last_sign_reward_time);
	local year1  = table_time1.year;
	local month1 = table_time1.month;
	local day1 = table_time1.day;
	local time1 = year1.."-"..month1.."-"..day1
	
	local table_time2 = os.date("*t",os.time());
	local year2  = tonumber(table_time2.year);
	local month2 = tonumber(table_time2.month);
	local day2 = tonumber(table_time2.day);
	local time2 = year2.."-"..month2.."-"..day2
	
	if time1==time2 then
		return 1
	else
    	return 0
    end
end

signinlib.l_get_last_month_day = function()
    local ret = 0
    local month = tonumber(os.date("%m",os.time()))
    local year = tonumber(os.date("%Y",os.time()))
    if month >= 12 then
        year = year + 1
        month = 0
    end
    month = month + 1
    ret = tonumber(os.date("%d", os.time({year = year, month = month, day = 1}) - 3600 * 24))
    return ret
end

signinlib.l_get_user_is_full_duty = function(user_id)
    local ret = 0
    local last_month_day = signinlib.l_get_last_month_day()
    if signinlib.user_list[user_id] ~= nil and signinlib.user_list[user_id].last_sign_day == last_month_day and signinlib.user_list[user_id].signin_count == last_month_day then
        ret = 1
    end
    return ret
end

signinlib.l_set_user_sign_info = function(user_id, last_sign_day, signin_count, last_sign_reward_time, isThisMonth, today)

    if signin_count == nil then signin_count = 0 end

    --定时器判断一下，如果签到超过7天，或者等于7天但不是今天签的，就清一下数据
    if signin_count > 7 or (signin_count == 7 and signinlib.user_list[user_id].last_sign_day~=today) then
        signinlib.user_list[user_id] = {};
        signinlib.user_list[user_id].signin_count = 0
        signinlib.user_list[user_id].last_sign_day = 0
        signinlib.user_list[user_id].is_full_duty = 0
        signinlib.user_list[user_id].last_sign_reward_time = ""
        --TraceError("置空签到信息userid:"..user_id)
        user_sign_db.clear_sign_info(user_id)
    end
end


signinlib.set_OP_SIGNIN_TASK_LIST = function(day, jiangjuan, match_gold, item_1, item_2, item_3)
    if jiangjuan ~= nil then
        signinlib.OP_SIGNIN_TASK_LIST[day].jiangjuan = jiangjuan
    end

    if match_gold ~= nil then
        signinlib.OP_SIGNIN_TASK_LIST[day].match_gold = match_gold
    end

    if item_1 ~= nil then
        signinlib.OP_SIGNIN_TASK_LIST[day].item_1 = item_1
    end

    if item_2 ~= nil then
        signinlib.OP_SIGNIN_TASK_LIST[day].item_2 = item_2
    end

    if item_3 ~= nil then
        signinlib.OP_SIGNIN_TASK_LIST[day].item_3 = item_3
    end

end

signinlib.get_date_from_time=function(db_time)
	if db_time==nil or db_time=="" then return "" end
	return string.sub(db_time,1,10)
end

--从数据库刷新用户信息
--参数2：用户当前连续签到天数。
--读取本月用户完成任务列表
signinlib.reloadUserDataFromDB = function(user_info,signin_info,last_sign_reward_time,sys_time)
    --只响应大厅的消息
    if (gamepkg.name ~= "tex" and gamepkg.name ~= "commonsvr")  then
       return;
    end

    --TraceError("signinlib.l_check_time_is_this_month(sys_time):"..signinlib.l_check_time_is_this_month(sys_time))
    signinlib.user_list[user_info.userId] = {};
    
        --最近签到日期
        local last_sign_day = tonumber(signin_info[1]) or 0
        signinlib.user_list[user_info.userId].last_sign_day = last_sign_day
        --连续签到数
        local signin_count = 0
        
        if(last_sign_reward_time==nil or last_sign_reward_time=="")then
            signin_count = 0
        elseif user_sign_db.is_next_day(timelib.db_to_lua_time(last_sign_reward_time),os.time())==1 then
            signin_count = #signin_info or 0
        end
        
        local today=timelib.lua_to_db_time(os.time())
        if signin_count > 7 or (signin_count == 7 and signinlib.get_date_from_time(last_sign_reward_time)~=signinlib.get_date_from_time(today)) then
	        signinlib.user_list[user_info.userId].signin_count = 0
	        signinlib.user_list[user_info.userId].last_sign_day = 0
	        signinlib.user_list[user_info.userId].is_full_duty = 0
	        signinlib.user_list[user_info.userId].last_sign_reward_time = ""
	        --TraceError("置空签到信息userid:"..user_info.userId)
	        user_sign_db.clear_sign_info(user_info.userId)
        
        else
	        signinlib.user_list[user_info.userId].signin_count = signin_count
	        --检查是否已经全勤
	        local is_full_duty = 0
	        if signin_count == 7 then
	        	is_full_duty = 1
	        end
	        signinlib.user_list[user_info.userId].is_full_duty = is_full_duty
	        --最近的获奖时间
	        signinlib.user_list[user_info.userId].last_sign_reward_time = last_sign_reward_time or ""
        end

end

signinlib.removeUserMatchDataFromMem = function(user_id)
    --清空用户数据
    signinlib.user_list[user_id] = nil;
end


------------------------------------服务器内部事件响应----------------------------------------
signinlib.on_after_user_login = function(e)
    --只响应新欢乐斗地主比赛场的消息
    -- [[
    if (gamepkg.name ~= "tex" and gamepkg.name ~= "commonsvr") then
        return;
    end

    local user_info;
    if e == nil then return end 
    if e.data ~= nil then
        user_info = e.data.userinfo
    else
        return;
    end
    
    --发送签到信息
    signinlib.net_send_sign_in_info(user_info)
end

signinlib.on_user_exit = function(e)
    --只响应新欢乐斗地主比赛场的消息
    if (gamepkg.name ~= "tex" and gamepkg.name ~= "commonsvr") then
        return;
    end

    --TraceError("clear");
    --清除内存数据
    signinlib.removeUserMatchDataFromMem(e.data.user_id);
end

signinlib.on_timer_minute = function(e)
    local tableTime = os.date("*t",os.time())
    local nowHour  = tonumber(tableTime.hour)
    if(nowHour == 0 and  e.data.min == 0) then
        --定时所有人的签到信息
        local today = tonumber(os.date("%d",os.time()))
        local this_month = tonumber(os.date("%m",os.time()))
        local isThisMonth = signinlib.l_check_time_is_this_month()

        for k,v in pairs(signinlib.user_list) do
            local user_info = usermgr.GetUserById(k)
            if user_info ~= nil and v ~= nil then
                signinlib.l_set_user_sign_info(k, v.last_sign_day, v.signin_count, v.last_sign_reward_time, isThisMonth, today)
                signinlib.net_send_sign_in_info(user_info, this_month, today)
            end
        end
    end
end

------------------------------------请求处理----------------------------------------
--取2个时间的0点0分0秒，如果2者的差值超过1天就返回1，否则返回0
signinlib.is_new_sign_day = function(time1,time2)
    if time1==nil or time2==nil or time1=="" or time2=="" then return 1 end
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
		return 1 
	end
	if timelib.db_to_lua_time(time2)-timelib.db_to_lua_time(time1) > 60*60*24 then
		return 1
	end
	return 0
end
--请求签到
signinlib.on_recv_do_sign_in = function(buf)
    local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	if  signinlib.user_list==nil then return end
	if  signinlib.user_list[user_info.userId]==nil then return end
	
    local sign_status = 0
     local last_reward_day = 0
    if signinlib.user_list[user_info.userId].last_sign_reward_time ~= nil and signinlib.user_list[user_info.userId].last_sign_reward_time ~= "" then
        last_reward_day = timelib.db_to_lua_time(signinlib.user_list[user_info.userId].last_sign_reward_time)
    end
    
    --如果这个窗口一直开着，并过了一天，就认为是新的一次签到，从0开始
    if signinlib.is_new_sign_day(last_reward_day,os.time()) == 1 then
    	signinlib.user_list[user_info.userId].signin_count = 0        
        signinlib.user_list[user_info.userId].is_full_duty = 0        
    end
    
    --begin--------------------------
    --验证是否要处理此消息
    --注意1：全部写在这里，不要新封装函数
    --注意2：signinlib.user_list[user_info.userId].last_daily_reward_time记录了最后一次的领奖时间，使用前记得判断是否为空
	
    --调用加钱接口加钱，l_add_user_match_gold_db，类型参数使用signinlib.STATIC_ADD_GOLD_TYPE_DAILY_REWARD,类型数据用送的钱。注意响应返回值。

    if signinlib.l_check_today_is_signed(user_info) ~= 1 then --今天未签到
        local today = tonumber(os.date("%d",os.time()))
        
        
        sign_status = 1--签到
		signinlib.user_list[user_info.userId].signin_count = signinlib.user_list[user_info.userId].signin_count + 1
        signinlib.user_list[user_info.userId].last_sign_day = today
        signinlib.user_list[user_info.userId].is_full_duty = signinlib.l_get_user_is_full_duty(user_info.userId)
        
        local signin_count = signinlib.user_list[user_info.userId].signin_count
        if signinlib.user_list[user_info.userId].is_full_duty == 1 then
            signin_count = 7
        end
        
        if signinlib.OP_SIGNIN_TASK_LIST[signin_count] ~= nil then
        
        local table_time = os.date("*t",os.time());
	    local now_year  = table_time.year;
	    local now_month = table_time.month;
	    local now_day = table_time.day;
	    local now_date_time = timelib.db_to_lua_time(now_year.."-"..now_month.."-"..now_day.." 00:00:00")
	


            
            if last_reward_day >= now_date_time then --今天已领取过奖励了！
                sign_status = -2
            else
                --记录已签到
        		user_sign_db.record_sign_info(user_info.userId)
                local signin_task_info = signinlib.OP_SIGNIN_TASK_LIST[signin_count]
                local item_count = 1
                sign_status = 2--签到并有奖励
                --领奖
                if signinlib ~= nil then
                    --发奖券
                    if signin_task_info.jiangjuan > 0 then
                   		usermgr.addgold(user_info.userId, signin_task_info.jiangjuan, 0, new_gold_type.SIGNIN, -1);
                    end
    
                end
    
                --加item奖励....
                --if bag ~= nil then
                    local item_Id = 0
                    if signin_task_info.item_1 > 0 then
                        item_Id = signin_task_info.item_1
                        item_count = signin_task_info.item_count_1
                        for i=1,item_count do
	                        if(item_Id==4)then
	                        	--小喇叭
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info);
	                        elseif(item_Id==10)then
	                        	--VIP3 金卡体验卡
	                        	add_user_vip(user_info, 3, 3);
	                         elseif(item_Id==11)then
	                        	--T人卡
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
	                        elseif(item_Id==21)then
	                        	--初级车位
	                        	parkinglib.add_parking(user_info, 1, 1);
	                        	parkinglib.on_add_gift_item(user_info, item_Id)	                        	
	                        elseif(item_Id==22)then
	                        	--中级车位
	                        	parkinglib.add_parking(user_info, 2, 1)
	                        	parkinglib.on_add_gift_item(user_info, item_Id)
						    else
						    	car_match_db_lib.add_car(user_info.userId, item_Id, 0)
	                        	--gift_addgiftitem(user_info,item_Id,user_info.userId,user_info.nick, false)
	                    	end
                    	end
                    end
                    
                    if signin_task_info.item_2 > 0 then
                        item_Id = signin_task_info.item_2
                        item_count = signin_task_info.item_count_2
                         for i=1,item_count do
	                        if(item_Id==4)then
	                        	--小喇叭
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info);
	                        elseif(item_Id==10)then
	                        	--VIP3 金卡体验卡
	                        	add_user_vip(user_info, 3, 3);
	                         elseif(item_Id==11)then
	                        	--T人卡
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
	                        elseif(item_Id==21)then
	                        	--初级车位
	                        	parking_db_lib.add_user_parking_db(user_info.userId, 1, 1)
	                        	parkinglib.on_add_gift_item(user_info, item_Id)	                        	
	                        elseif(item_Id==22)then
	                        	--中级车位
	                        	parking_db_lib.add_user_parking_db(user_info.userId, 2, 1)
	                        	parkinglib.on_add_gift_item(user_info, item_Id)
						    else
						    	car_match_db_lib.add_car(user_info.userId, item_Id, 0)
	                        	--gift_addgiftitem(user_info,item_Id,user_info.userId,user_info.nick, false)
	                    	end
                    	end
                    end
        
                    if signin_task_info.item_3 > 0 then
                        item_Id = signin_task_info.item_3
                        item_count = signin_task_info.item_count_3
                        for i=1,item_count do
	                        if(item_Id==4)then
	                        	--小喇叭
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info);
	                        elseif(item_Id==10)then
	                        	--VIP3 金卡体验卡
	                        	add_user_vip(user_info, 3, 3);
	                         elseif(item_Id==11)then
	                        	--T人卡
	                        	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
	                        elseif(item_Id==21)then
	                        	--初级车位
	                        	parking_db_lib.add_user_parking_db(user_info.userId, 1, 1)
	                        	parkinglib.on_add_gift_item(user_info, item_Id)	                        	
	                        elseif(item_Id==22)then
	                        	--中级车位
	                        	parking_db_lib.add_user_parking_db(user_info.userId, 2, 1)
	                        	parkinglib.on_add_gift_item(user_info, item_Id)
						    else
						    	car_match_db_lib.add_car(user_info.userId, item_Id, 0)
	                        	--gift_addgiftitem(user_info,item_Id,user_info.userId,user_info.nick, false)
	                    	end
                    	end
                    end
                --end
                
                --每日任务和VIP等领钱
                --signinlib.give_daily_gold(user_info)
                
                --内存中记录发奖时间
                signinlib.user_list[user_info.userId].last_sign_reward_time = timelib.lua_to_db_time(os.time());
                user_sign_db.log_user_sign_reward(user_info.userId, signin_count)
            end
        end
    else
		sign_status = -1 --今天已签到过
	end

   
    
    --通知客户端结果，已经写好接口，请查找自己用
	signinlib.net_send_do_sign_in(user_info,sign_status)
    --end---------------------------------
end

--请求打开签到面板
signinlib.on_recv_sign_task_list = function(buf)
    local user_info = userlist[getuserid(buf)]
    if user_info == nil then return end
     
    signinlib.send_OP_SIGNIN_TASK_LIST(user_info)
end

------------------------------------发送到客户端的协议函数----------------------------------------
signinlib.net_send_do_sign_in = function(user_info,sign_status)
    if signinlib.user_list[user_info.userId] == nil then
        return
    end

    if sign_status > 0 then
        signinlib.net_send_sign_in_info(user_info)
    end

    netlib.send(function(buf_out)
        buf_out:writeString("SIGNIN")
        buf_out:writeByte(sign_status or 0)--成功与否
    end, user_info.ip, user_info.port)
end

signinlib.net_send_sign_in_info = function(user_info, this_month, this_day)
    if signinlib.user_list[user_info.userId] == nil then
        return
    end

    if this_month == nil then
        this_month = tonumber(os.date("%m",os.time()))
    end

    if this_day == nil then
        this_day = tonumber(os.date("%d",os.time()))
    end
    
    local is_signed = signinlib.l_check_today_is_signed(user_info)
    local is_full_duty = 0
    if signinlib.user_list[user_info.userId].signin_count>=7 then
    	is_full_duty =1
    end

    netlib.send(function(buf_out)
        buf_out:writeString("SIGNINFO")
        buf_out:writeInt(this_month or 0)--今月
        buf_out:writeInt(this_day or 0)--今日
        buf_out:writeByte(is_signed or 0)--是否已签到
        buf_out:writeInt(signinlib.user_list[user_info.userId].signin_count or 0)--连续签到天数
        buf_out:writeInt(is_full_duty)--是否全勤
    end, user_info.ip, user_info.port)
end

signinlib.send_OP_SIGNIN_TASK_LIST = function(user_info)
    if signinlib.SIGNIN_TASK_LIST_LEN == 0 then
        local len = 0
        for k,v in pairs(signinlib.OP_SIGNIN_TASK_LIST) do
            len = len + 1
        end
        signinlib.SIGNIN_TASK_LIST_LEN = len
    end

    netlib.send(function(buf_out)
        buf_out:writeString("SIGNTASK")
        buf_out:writeInt(signinlib.SIGNIN_TASK_LIST_LEN)
        for k,v in pairs(signinlib.OP_SIGNIN_TASK_LIST) do 
            local key = k
            local item_name=""
            local item_name2=""
            local item_name3=""
            if key >= 7 then
                key = 7
            end
            buf_out:writeInt(key)
            --todo:改奖品
            buf_out:writeInt(v.jiangjuan)--奖励的奖卷
            --buf_out:writeInt(v.match_gold)--奖励的赛币
            buf_out:writeInt(v.item_1)--奖励的物品1            
            if (v.item_1~=0) then item_name=_U(signinlib.item_config[v.item_1]) or "" end
            buf_out:writeString(item_name)--奖励的物品1            
            buf_out:writeInt(v.item_count_1)--奖励的物品1数量
            buf_out:writeInt(v.item_2)--奖励的物品2
      		if (v.item_2~=0) then item_name2=_U(signinlib.item_config[v.item_2]) or "" end
            buf_out:writeString(item_name2)--奖励的物品2  
            buf_out:writeInt(v.item_count_2)--奖励的物品1数量            
            buf_out:writeInt(v.item_3)--奖励的物品3
            if (v.item_3~=0) then item_name3=_U(signinlib.item_config[v.item_3]) or "" end
            buf_out:writeString(item_name3)--奖励的物品3  
            buf_out:writeInt(v.item_count_3)--奖励的物品1数量
        end
    end, user_info.ip, user_info.port)
end

------------------------------------事件添加----------------------------------------
--重载时登录检测监听
eventmgr:addEventListener("user_login_already_get_sign_db", signinlib.on_after_user_login)

--用户退出
eventmgr:addEventListener("on_user_exit", signinlib.on_user_exit);

--倒计时
eventmgr:addEventListener("timer_minute", signinlib.on_timer_minute);


------------------------------------请求响应----------------------------------------
--命令列表
cmdHandler = 
{
    --请求签到
    ["SIGNTASK"] = signinlib.on_recv_sign_task_list, --请求奖励配置
    ["SIGNIN"] = signinlib.on_recv_do_sign_in, --请求签到
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

