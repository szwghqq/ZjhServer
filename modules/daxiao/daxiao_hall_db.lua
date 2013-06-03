if not daxiao_hall_db_lib then
    daxiao_hall_db_lib = _S
    {    	   
    }
end

--获取用户信息
function daxiao_hall_db_lib.get_user_info(user_id, call_back)
    local sql = "select nick, gold from users where id = %d"
    sql = string.format(sql, user_id)
    dblib.execute(sql, function(dt)
        call_back(dt)
    end)
end
