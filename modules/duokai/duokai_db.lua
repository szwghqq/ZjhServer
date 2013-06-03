if not duokai_db_lib then
	duokai_db_lib = 
	{		
        start_sub_user_id = 100000000,
        sub_user_ip = "0.0.0.0",
        start_sub_user_port = 0,
	}
end

--获取当前用户的子用户
function duokai_db_lib.get_sub_user_list(user_id, call_back)
    local sql = "select * from user_duokai_info where user_id = %d"
    sql = string.format(sql, user_id)
    dblib.execute(sql, function(dt) 
        call_back(dt)
    end)
end

--创建一个子账号
function duokai_db_lib.create_sub_user(user_id, user_count, call_back)
    --TraceError("duokai_db_lib.create_sub_user")
    duokai_db_lib.start_sub_user_id = duokai_db_lib.start_sub_user_id + 1
    duokai_db_lib.start_sub_user_port = duokai_db_lib.start_sub_user_port + 1

    local sub_user_key = duokai_db_lib.sub_user_ip..":"..duokai_db_lib.start_sub_user_port

    call_back(duokai_db_lib.start_sub_user_id, tostring(duokai_db_lib.start_sub_user_id),
              sub_user_key, duokai_db_lib.sub_user_ip, duokai_db_lib.start_sub_user_port)

    --[[local sql = "call sp_duokai_add_sub_user(%d, %d)"
    sql = string.format(sql, user_id, user_count)
    dblib.execute(sql, function(dt) 
        call_back(dt)
    end)--]]
end

function duokai_db_lib.log_want_duokai_info(user_id, level, gold, yes_or_no)
    local sql = "insert into log_want_duokai_info(user_id, level, gold, yes_or_no, sys_time) values(%d, %d, %d, %d, NOW())";
    sql = string.format(sql, user_id, level, gold, yes_or_no)
    dblib.execute(sql);
end
