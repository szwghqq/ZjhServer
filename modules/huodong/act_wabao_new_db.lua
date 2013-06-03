TraceError("init wabaonew_db_lib...")
if not wabaonew_db_lib then
    wabaonew_db_lib = _S
    {
        get_user_wabao_info = NULL_FUNC,
        get_user_wabao_record = NULL_FUNC,
        get_gift_cfg        = NULL_FUNC,
        add_user_shovel_num = NULL_FUNC,
        choujiang           = NULL_FUNC,
        get_wabao_info      = NULL_FUNC,
        set_wabao_password  = NULL_FUNC,
        add_wabao_contact   = NULL_FUNC,
        get_owner_list      = NULL_FUNC,
        delete_wabao_info   = NULL_FUNC,
        add_wabao_record    = NULL_FUNC,
        update_user_wabao_record = NULL_FUNC,
        get_wabao_dajiang_info = NULL_FUNC,
    }   
end

function wabaonew_db_lib.update_wabao_get_dajiang(record_id, user_id, callback)
    local sql = "call sp_huodong_wb_get_gift(%d, %d)";
    sql = string.format(sql, record_id, user_id);
    dblib.execute(sql, function(dt)
        if(dt and #dt > 0) then
            callback(dt[1]);
        else
            callback({result=0});
        end
    end, -1);
end

function wabaonew_db_lib.get_wabao_dajiang_info(map_id, valid_time, callback) 
    local sql = "select * from wabao_dajiang_record_info where map_id = %d and valid_time <= '%s' and is_notify = 0 AND NOW() < DATE_ADD(valid_time, INTERVAL 10 DAY)";
    sql = string.format(sql, map_id, timelib.lua_to_db_time(valid_time));
    --TraceError(sql);
    dblib.execute(sql, function(dt)
        callback(dt);
    end, -1);
end

function wabaonew_db_lib.update_user_wabao_record(id, user_id, is_prize)
    local sql = "update wabao_dajiang_record_info set is_notify = %d where id = %d;commit;";
    sql = string.format(sql, is_prize, id);
    dblib.execute(sql, nil, -1);
end

function wabaonew_db_lib.get_user_wabao_dajiang_record(user_id, valid_time, callback)
    local sql = "select * from wabao_dajiang_record_info where user_id = %d and valid_time <= '%s' and is_notify = 0 AND NOW() < DATE_ADD(valid_time, INTERVAL 10 DAY) limit 1";
    sql = string.format(sql, user_id, timelib.lua_to_db_time(valid_time));
    dblib.execute(sql, function(dt)
        callback(dt);
    end, -1);
end

function wabaonew_db_lib.add_wabao_record(map_id, user_id, nick_name, gift_id, is_prize)
    local sql = "insert into wabao_record_info(map_id, user_id, nick_name, gift_id, sys_time, is_prize) values(%d, %d, %s, %d, NOW(), %d)";
    sql = string.format(sql, map_id, user_id, dblib.tosqlstr(nick_name), gift_id, is_prize);
    --TraceError(sql);
    dblib.execute(sql, nil, -1);
end

function wabaonew_db_lib.delete_wabao_info(map_id, gift_id, cur_user_id, current_time)
    local sql = "delete from wabao_info where map_id = %d and gift_id = %d and cur_user_id = %d and sys_time < '%s';commit;";
    sql = string.format(sql, map_id, gift_id, cur_user_id, timelib.lua_to_db_time(current_time));
    --TraceError(sql);
    dblib.execute(sql, nil, -1);
end

function wabaonew_db_lib.get_owner_list(map_id, callback)
    local sql = "select * from wabao_info where map_id = %d";
    sql = string.format(sql, map_id);
    dblib.execute(sql, function(dt)
        callback(dt);
    end, -1);
end

function wabaonew_db_lib.get_wabao_record(map_id, callback)
    local sql = "SELECT wri.* FROM wabao_record_info wri LEFT JOIN cfg_wabao_gift cwg ON wri.gift_id = cwg.gift_id WHERE wri.map_id = %d GROUP BY wri.id ORDER BY cwg.is_qiang DESC, wri.sys_time DESC  LIMIT 50";
    sql = string.format(sql, map_id);
    dblib.execute(sql, function(dt)
        callback(dt);
    end);
end

function wabaonew_db_lib.add_wabao_contact(user_id, gift_id, realname, yy, address, tel)
    local sql = "insert into wabao_contact_info(user_id, gift_id, realname, yy, address, tel) values(%d, %d, %s, %s, %s, %s)";
    sql = string.format(sql, user_id, gift_id, dblib.tosqlstr(realname), dblib.tosqlstr(yy), dblib.tosqlstr(address), dblib.tosqlstr(tel));
    dblib.execute(sql);
end

--加优惠卷
function wabaonew_db_lib.add_jiangjuan(user_id, jiangjuan_type, add_jiangjuan)
    local jiangjuan_column = "jiangjuan"..jiangjuan_type;
    local sql = "insert into user_wabao_info(user_id, %s) value(%d, %d) on duplicate key update %s = %s + %d;commit;";
    sql = string.format(sql, jiangjuan_column, user_id, add_jiangjuan, jiangjuan_column, jiangjuan_column, add_jiangjuan);
    --TraceError(sql);
    dblib.execute(sql, nil, user_id);
end

function wabaonew_db_lib.add_exchange_record(user_id, jiangjuan_type)
    local sql = "insert into wabao_exchange_record_info(user_id, jiangjuan_type, sys_time) values(%d, %d,NOW());commit;";
    sql = string.format(sql, user_id, jiangjuan_type);
    dblib.execute(sql, nil, user_id);
end

function wabaonew_db_lib.get_exchange_list(user_id, callback) 
    local sql = "select * from wabao_exchange_record_info where user_id=%d order by sys_time desc limit 50";
    sql = string.format(sql, user_id);
    --TraceError(sql);
    dblib.execute(sql, function(dt)
        callback(dt);
    end, user_id);
end

function wabaonew_db_lib.set_wabao_password(valid_time, user_id, nick_name, map_id, gift_id, password, cur_user_id, sys_time, callback)
    local sql = "call sp_huodong_wb_set_password('%s', %d, %d, %d, %d, '%s', %d, '%s')";
    sql = string.format(sql, timelib.lua_to_db_time(valid_time), map_id, gift_id, user_id, password, nick_name, cur_user_id, sys_time);
    dblib.execute(sql, function(dt)
        if(dt and #dt > 0) then
            callback(dt[1]);
        else
            callback({});
        end
    end, -1);
end

function wabaonew_db_lib.get_wabao_info(map_id, gift_id, callback)
    local sql = "select * from wabao_info where map_id = %d and gift_id = %d";
    sql = string.format(sql, map_id, gift_id);
    dblib.execute(sql, function(dt)
        if(dt and #dt > 0) then
            callback(dt[1]);
        else
            --获取系统的密码
            sql = string.format("select sys_pwd from cfg_wabao_gift where map_id = %d and gift_id = %d limit 1", map_id, gift_id);
            dblib.execute(sql, function(dt)
                if(dt and #dt > 0) then
                    callback({map_id=map_id, gift_id=gift_id, cur_user_id=0, cur_nick_name=_U('系统'), last_nick_name=_U('系统'), pwd=dt[1]["sys_pwd"], sys_time=timelib.lua_to_db_time(os.time())});
                end
            end);
        end
    end, -1);
end

function wabaonew_db_lib.choujiang(start_time, end_time, user_id, map_id, gift_list, callback)
    local sql = "call sp_huodong_wb_random_gift('%s','%s',%d, %d";
    sql = string.format(sql, start_time, end_time, user_id, map_id);
    for k, v in pairs(gift_list) do
        sql = sql ..","..v.gift_id..","..v.gift_rate;
    end
    sql = sql .. ")";
    dblib.execute(sql, function(dt)
        if(dt and #dt > 0) then
            callback(dt[1]);
        else
            callback({});
        end
    end, -1);
end

function wabaonew_db_lib.clear_user_shovel_num(user_id)
    local sql = "update user_wabao_info set shovel_num = 0 where user_id = %d;commit;";
    sql = string.format(sql, user_id);
    dblib.execute(sql, nil, user_id);
end

function wabaonew_db_lib.add_user_shovel_num(user_id, shovel_num, after_shovel_num)
    local sql = "update user_wabao_info set shovel_num = shovel_num + %d where user_id = %d;commit;";
    sql = string.format(sql, shovel_num, user_id);
    dblib.execute(sql, nil, user_id);

    local sql = "insert into log_wabao_shovel_info(user_id, shovel_num, after_shovel_num, sys_time) values(%d, %d, %d, NOW());commit;";
    sql = string.format(sql, user_id, shovel_num, after_shovel_num);
    dblib.execute(sql, nil, user_id);
end

function wabaonew_db_lib.get_gift_cfg(callback)
    dblib.execute("select * from cfg_wabao_gift", function(dt)
    	if dt and #dt > 0 then
        callback(dt);
      end
    end);
end

function wabaonew_db_lib.get_user_wabao_info(user_id, callback)

    dblib.execute("insert ignore into user_wabao_info(user_id) values("..user_id..");commit;", nil, user_id);

    local sql = "select * from user_wabao_info where user_id = %d";
    sql = string.format(sql, user_id);
    dblib.execute(sql, function(dt)
        local user_wabao_info = nil; 
        if(dt ~= nil and #dt > 0) then
            user_wabao_info = dt[1];
            if(user_wabao_info.gift_list ~= nil and user_wabao_info.gift_list ~= "") then
                user_wabao_info.gift_list = table.loadstring(user_wabao_info.gift_list);
            else
                user_wabao_info.gift_list = {};
            end
        end
        if(callback ~= nil) then
            callback(user_wabao_info);
        end
    end, user_id); 
end

