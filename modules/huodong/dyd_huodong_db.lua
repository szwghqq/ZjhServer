TraceError("init dyd db...")

if not dyd_db_lib then
    dyd_db_lib = _S
    {
    	--以下是方法
    	init_user = NULL_FUNC,
 		save_user_info = NULL_FUNC,
        --以下是变量及配置信息
 
    }    
end

function dyd_db_lib.save_user_info(user_id) 
	if dyd_lib.user_list[user_id] == nil or dyd_lib.user_list[user_id].play_count == nil then return end
	
	local sql = "update user_dyd_info set play_count1 = %d, play_count2 = %d, play_count3 = %d,sys_time = now() where user_id = %d"
	sql = string.format(sql, dyd_lib.user_list[user_id].play_count[1], dyd_lib.user_list[user_id].play_count[2], dyd_lib.user_list[user_id].play_count[3], user_id)
	dblib.execute(sql, function(dt) end, user_id) 
end

function dyd_db_lib.add_user_flag(user_id, flag_count) 
	local sql = "update user_dyd_info set userflag_count=userflag_count+%d, sys_time = now() where user_id = %d"
	sql = string.format(sql, flag_count, user_id)
	dblib.execute(sql, function(dt) end, user_id) 
	sql = "insert into log_give_flag(user_id, add_flag, sys_time) value(%d,%d,now())"
	sql = string.format(sql, user_id, flag_count)
	dblib.execute(sql, function(dt) end, user_id) 
	
end

function dyd_db_lib.init_user(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	dyd_lib.user_list[user_id] = {}
	dyd_lib.user_list[user_id].user_id = user_id
	dyd_lib.user_list[user_id].play_count = {}	
	local sql = "select play_count1, play_count2, play_count3,userflag_count,already_userflag_count,notify_num from user_dyd_info where user_id = %d"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			dyd_lib.user_list[user_id].play_count[1] = dt[1].play_count1
			dyd_lib.user_list[user_id].play_count[2] = dt[1].play_count2
			dyd_lib.user_list[user_id].play_count[3] = dt[1].play_count3
			dyd_lib.user_list[user_id].userflag_count = dt[1].userflag_count
			dyd_lib.user_list[user_id].already_userflag_count = dt[1].already_userflag_count
			dyd_lib.user_list[user_id].notify_num = dt[1].notify_num
			if tonumber(dt[1].notify_num) > 0 then
				dyd_lib.send_reward_msg(user_id, dt[1].notify_num)
			end
			
		else
			dyd_lib.user_list[user_id].play_count[1] = 0
			dyd_lib.user_list[user_id].play_count[2] = 0
			dyd_lib.user_list[user_id].play_count[3] = 0
			dyd_lib.user_list[user_id].userflag_count = 0
			dyd_lib.user_list[user_id].already_userflag_count = 0
			dyd_lib.user_list[user_id].notify_num = 0
			sql = "insert into user_dyd_info(play_count1, play_count2, play_count3,userflag_count,already_userflag_count,notify_num, user_id, sys_time) value(0,0,0,0,0,0,%d,now()); "
			sql = string.format(sql, user_id)
			dblib.execute(sql)
		end
		
		dyd_lib.send_panshu(user_info)
		dyd_lib.send_user_flag(user_info)
	end, user_id)	
end

function dyd_db_lib.init_server_flag()
	local sql = "select param_value, param_str_value from cfg_param_info where param_key = 'DYD_HUODONG'"
	dblib.execute(sql, function(dt)
		if dt and #dt>0 then
			dyd_lib.flag_count = dt[1].param_value
			dyd_lib.fajiang_flag = dt[1].param_str_value
		else
			dyd_lib.flag_count = 0
			dyd_lib.fajiang_flag = "0"
		end
	end)
end

function dyd_db_lib.save_already_flag(flag_count)
	local sql = "insert into cfg_param_info(param_key, param_value, param_str_value, room_id) value('DYD_HUODONG', %d, '0', '-1') on duplicate key update param_value = %d"
	sql = string.format(sql, flag_count, flag_count)
	dblib.execute(sql)
end
function dyd_db_lib.update_fajiang_flag()
	local sql = "update cfg_param_info set  param_str_value = '1' where param_key = 'DYD_HUODONG'"
	sql = string.format(sql)
	dblib.execute(sql)
end

function dyd_db_lib.clear_userflag(user_id)
	local sql = "update user_dyd_info set already_userflag_count=already_userflag_count + userflag_count,userflag_count = 0 where user_id = %d"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt) end, user_id)
end

function dyd_db_lib.update_fajiang_notify(user_id, notify_num)
	local sql = "update user_dyd_info set notify_num = %d where user_id = %d"
	sql = string.format(sql, notify_num, user_id)
	dblib.execute(sql, function(dt) end, user_id)
end

function dyd_db_lib.init_server_pm()
	local sql = "select a.user_id as user_id,a.already_userflag_count as already_userflag_count,b.nick_name as nick_name from user_dyd_info a left join users b on a.user_id=b.id where a.already_userflag_count >0 order by a.already_userflag_count desc limit %d"
	sql = string.format(sql, dyd_lib.CQ_PM_LEN)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			for i = 1, #dt do 
				local buf_tab = {
					["user_id"] = dt[i].user_id,
					["nick_name"] = dt[i].nick_name,
					["cq_count"] = dt[i].already_userflag_count,
				}
				table.insert(dyd_lib.cq_pm_list, buf_tab)
			end
		end
	end)

end

--命令列表
cmdHandler = 
{
   

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
