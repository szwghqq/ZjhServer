TraceError("init car_match_sj_db_lib...")

if not car_match_sj_db_lib then
    car_match_sj_db_lib = _S
    {
        --方法  		
    }
end

--获取车队信息
function car_match_sj_db_lib.get_team_car_info(user_id, call_back)
    local sql = "select * from user_car_team_info where user_id = %d"
    sql = string.format(sql, user_id)
    dblib.execute(sql, function(dt)
        call_back(dt)
    end, user_id)
end

--增减汽油
function car_match_sj_db_lib.add_gas(user_id, add_num, reason)
    local sql = "insert into user_car_team_info(user_id, team_exp, gas_num, flag1_num,flag2_num,flag3_num,flag4_num,flag5_num)value(%d,0,%d,0,0,0,0,0)on duplicate key update gas_num = gas_num + %d;commit;"
    sql = string.format(sql, user_id, add_num, add_num)
    dblib.execute(sql, nil, user_id)
    sql = "insert into log_car_gas_info(user_id, add_num, reason, sys_time)values(%d,%d,%d,now())"
    sql = string.format(sql, user_id, add_num, reason)
    dblib.execute(sql)
end

--更新汽油值恢复时间
function car_match_sj_db_lib.update_gas_time(user_id, gas_time)
    local sql = "update user_car_team_info set gas_time = '%s' where user_id = %d";
    sql = string.format(sql, gas_time, user_id)
    dblib.execute(sql, nil, user_id)
end

--增减车标
function car_match_sj_db_lib.add_car_flag(user_id, flag_lv, add_num, reason)
    local sql = "insert into user_car_team_info(user_id, team_exp, gas_num, flag1_num,flag2_num,flag3_num,flag4_num,flag5_num)value(%d,0,0,%s)on duplicate key update "
    local flag_info = ""
    if (flag_lv == 1) then
        flag_info = add_num..",0,0,0,0"
        sql = sql.." flag1_num=flag1_num+%d"
    elseif (flag_lv == 2) then
        flag_info = "0,"..add_num..",0,0,0"
        sql = sql.." flag2_num=flag2_num+%d"
    elseif (flag_lv == 3) then
        flag_info = "0,0,"..add_num..",0,0"
        sql = sql.." flag3_num=flag3_num+%d"
    elseif (flag_lv == 4) then
        flag_info = "0,0,0,"..add_num..",0"
        sql = sql.." flag4_num=flag4_num+%d"
    elseif (flag_lv == 5) then
        flag_info = "0,0,0,0,"..add_num
        sql = sql.." flag5_num=flag5_num+%d"
    else
        TraceError("增加车标异常数据 "..flag_lv)
        return
    end
    sql = sql..";commit;"
    sql = string.format(sql, user_id, flag_info, add_num)
    dblib.execute(sql, nil, user_id)
    sql = "insert into log_car_flag_info(user_id, flag_lv, add_num, reason, sys_time)values(%d,%d,%d,%d,now())"
    sql = string.format(sql, user_id, flag_lv, add_num, reason)
    dblib.execute(sql)
end

--更新车队经验 add_num:变动值  curr_num:当前等级值
function car_match_sj_db_lib.update_team_exp(user_id, add_num, curr_num, new_lv, reason)
    local sql = "insert into user_car_team_info(user_id, team_lv, team_exp, gas_num, flag1_num,flag2_num,flag3_num,flag4_num,flag5_num)value(%d,%d,%d,0,0,0,0,0,0)on duplicate key update team_exp = %d, team_lv = %d;commit;"
    sql = string.format(sql, user_id, new_lv, curr_num, curr_num, new_lv)
    dblib.execute(sql, nil, user_id)
    sql = "insert into log_car_team_exp_info(user_id, add_num, reason, sys_time)values(%d,%d,%d,now())"
    sql = string.format(sql, user_id, add_num, reason)
    dblib.execute(sql)
end

--备份报名表
function car_match_sj_db_lib.backup_baoming_table()
	if(gamepkg.name == "tex" and car_match_lib.CFG_GAME_ROOM ~= tonumber(groupinfo.groupid))then
		return
	end
	local sql="INSERT IGNORE INTO car_back_baoming_info (area_id,car_id,user_id,baoming_num,match_type,match_id,already_return) SELECT area_id,car_id,user_id,baoming_num,match_type,match_id,0 AS already_return FROM car_baoming_info where user_id > 0 and match_type = 3;"
	dblib.execute(sql, function(dt)
        car_match_sj_db_lib.clear_baoming()
    end)
end

function car_match_sj_db_lib.clear_baoming()
	local sql="update car_baoming_info set user_id = 0 where match_type = 3;"
	dblib.execute(sql)
end

--玩家离线时保存奖励信息
function car_match_sj_db_lib.update_offline_reward(buf_tab)
    local sql = "insert into car_offline_reward (user_id,mingci,add_exp,add_gold,add_gas,flag"..buf_tab.flag_lv.."_num) value(%s,%d,%d,%d,%d,%d)";
	sql = string.format(sql, buf_tab.user_id, buf_tab.mingci, buf_tab.add_exp, buf_tab.add_gold, buf_tab.add_gas, buf_tab.flag_num)
	dblib.execute(sql)
end

function car_match_sj_db_lib.init_user_info(user_id)
    --初始化基础信息
	 if car_match_sj_lib.user_list == nil then car_match_sj_lib.user_list = {} end
	 if car_match_sj_lib.user_list[user_id] == nil then car_match_sj_lib.user_list[user_id] = {} end
	 car_match_sj_lib.user_list[user_id].user_id = user_id
	 
	 local user_info = usermgr.GetUserById(user_id)
     if (user_info ~= nil) then
        car_match_sj_lib.user_list[user_id].nick_name = user_info.nick
        car_match_sj_lib.user_list[user_id].img_url = user_info.imgUrl
        car_match_sj_lib.user_list[user_id].team_lv = 0
        car_match_sj_lib.user_list[user_id].team_exp = 0
        car_match_sj_lib.user_list[user_id].gas_num = 0
        car_match_sj_lib.user_list[user_id].gas_time = 0
        car_match_sj_lib.user_list[user_id].flag1_num = 0
        car_match_sj_lib.user_list[user_id].flag2_num = 0
        car_match_sj_lib.user_list[user_id].flag3_num = 0
        car_match_sj_lib.user_list[user_id].flag4_num = 0
        car_match_sj_lib.user_list[user_id].flag5_num = 0
        car_match_sj_db_lib.get_team_car_info(user_id, function(dt)
            if (dt and #dt > 0) then
                car_match_sj_lib.user_list[user_id].nick_name = user_info.nick
                car_match_sj_lib.user_list[user_id].img_url = user_info.imgUrl
                car_match_sj_lib.user_list[user_id].team_lv = dt[1].team_lv or 0
                car_match_sj_lib.user_list[user_id].team_exp = dt[1].team_exp or 0
                car_match_sj_lib.user_list[user_id].gas_num = dt[1].gas_num or 0
                car_match_sj_lib.user_list[user_id].gas_time = tonumber(dt[1].gas_time) or 0
                car_match_sj_lib.user_list[user_id].flag1_num = dt[1].flag1_num or 0
                car_match_sj_lib.user_list[user_id].flag2_num = dt[1].flag2_num or 0
                car_match_sj_lib.user_list[user_id].flag3_num = dt[1].flag3_num or 0
                car_match_sj_lib.user_list[user_id].flag4_num = dt[1].flag4_num or 0
                car_match_sj_lib.user_list[user_id].flag5_num = dt[1].flag5_num or 0
            end
        end)
     end
end

--登陆后初始化比赛信息
function car_match_sj_db_lib.on_after_user_login(user_info)
    if user_info == nil then return end
    local user_id = user_info.userId
    --如果有match_id不是现在的，就退报名费
    car_match_sj_db_lib.baoming_tuifei(user_info)
    --检查是否有离线奖励提示
    car_match_sj_db_lib.check_offline_reward(user_info)
end

--检查是否需要退参赛费
function car_match_sj_db_lib.baoming_tuifei(user_info)
    local return_gold = 0
    local sql = "select match_id,area_id,match_type from car_back_baoming_info where user_id=%d and match_type = 3 and already_return = 0"
    sql = string.format(sql, user_info.userId)
    dblib.execute(sql,function(dt)
        if dt and #dt>0 then
            for i=1, #dt do
                local match_type = dt[i].match_type
                if dt[i].match_id ~= car_match_sj_lib.match_list[dt[i].match_type].match_id then
                    return_gold = return_gold + car_match_sj_lib.CFG_BAOMING_GOLD[match_type]
                    sql = "delete from car_back_baoming_info where user_id=%d and match_id=%d and match_type = 3"
                    sql = string.format(sql, user_info.userId, dt[i].match_id)
                    dblib.execute(sql, function(dt) end, user_id)
                end
            end
        end
        if return_gold>0 then
            usermgr.addgold(user_info.userId, return_gold, 0, new_gold_type.CAR_MATCH, -1);
            car_match_db_lib.send_return_gold(user_info, return_gold)
        end
    end,user_id)
end

--是否需要提示已经发送奖励(参赛时玩家离线)
function car_match_sj_db_lib.check_offline_reward(user_info)
    --获取车队信息
    local sql = "select * from car_offline_reward where user_id = %d"
    sql = string.format(sql, user_info.userId)
    dblib.execute(sql, function(dt)
        if dt and #dt>0 then
            local add_gold = dt[1].add_gold
            local add_exp = dt[1].add_exp
            local add_gas = dt[1].add_gas
            local mingci = dt[1].mingci
            local flag1 = dt[1].flag1_num
            local flag2 = dt[1].flag2_num
            local flag3 = dt[1].flag3_num
            local flag4 = dt[1].flag4_num
            local flag5 = dt[1].flag5_num
            local result_msg = "恭喜您获得了升级赛第"..mingci.."名,奖励"
            if (add_gold > 0) then
                result_msg = result_msg.."筹码:"..add_gold.."、"
            end
            if (add_exp > 0) then
                result_msg = result_msg.."车队经验:"..add_exp.."、"
            end
            if (add_gas > 0) then
                result_msg = result_msg.."汽油值:"..add_gas.."、"
            end
            if (flag1 > 0) then
                result_msg = result_msg.."普通车标:"..flag1.."个."
            elseif (flag2 > 0) then
                result_msg = result_msg.."优良车标:"..flag2.."个."
            elseif (flag3 > 0) then
                result_msg = result_msg.."珍贵车标:"..flag3.."个."
            elseif (flag4 > 0) then
                result_msg = result_msg.."稀世车标:"..flag4.."个."
            elseif (flag5 > 0) then
                result_msg = result_msg.."传奇车标:"..flag5.."个."
            end
            car_match_sj_db_lib.send_offline_reward(user_info, result_msg)
            sql = "delete from car_offline_reward where user_id=%d"
            sql = string.format(sql, user_info.userId)
            dblib.execute(sql)
        end
    end, user_id)
end

--保存比赛记录
function car_match_sj_db_lib.log_sj_match(match_info)
    local sql = "insert into log_car_sj_match (area1,area2,area3,area4,area5,area6,area7,area8,sys_time) values("
    for i=1, 8 do
        local user_id = match_info.match_car_list[i].match_user_id
        user_id = user_id < 0 and 0 or user_id
        sql = sql..user_id..","
    end
    sql = sql.."now())"
    dblib.execute(sql)
end

--通知玩家发送离线奖励了了
function car_match_sj_db_lib.send_offline_reward(user_info, msg)
 	netlib.send(function(buf)
    	buf:writeString("SJCAROFFLINE");
    	buf:writeString(_U(msg))
    end,user_info.ip,user_info.port);
end

--通过user_id取汽车信息
function car_match_sj_db_lib.init_car_list(user_id)
	 if car_match_sj_lib.user_list == nil then car_match_sj_lib.user_list = {} end
	 if car_match_sj_lib.user_list[user_id] == nil then car_match_sj_lib.user_list[user_id] = {} end
	 --初始化用户基本信息
     car_match_sj_db_lib.init_user_info(user_id)
	 --一辆车都没有的吊丝
     car_match_sj_lib.user_list[user_id].car_list = {}
end

--初始化重启前的match_id到内存里
function car_match_sj_db_lib.init_restart_match_id()
	local sql = "SELECT param_str_value FROM cfg_param_info WHERE param_key = 'CAR_BET3' and room_id=%d order by param_key"
	sql = string.format(sql,groupinfo.groupid);
	dblib.execute(sql,
    function(dt)
    	if dt and #dt > 0 then    		
    		car_match_sj_lib.restart_match_id[3] = dt[1]["param_str_value"]
    	else
    		car_match_sj_lib.restart_match_id[3] = "-1"
		end
	end)
end

--更新报名信息
function car_match_sj_db_lib.update_car_baoming(area_id, car_id, user_id, baoming_num, match_type, match_id)
	local sql = "insert into car_baoming_info(area_id, car_id, user_id, baoming_num, match_type, match_id) value(%d,%d,%d,%d,%d,%d) on duplicate key update car_id=%d,user_id=%d,baoming_num=%d,match_id=%d"
	sql = string.format(sql,area_id, car_id, user_id, baoming_num, match_type, match_id, car_id, user_id, baoming_num, match_id)
	dblib.execute(sql,function(dt) end,user_id)
end

--加到冠军列表
function car_match_sj_db_lib.add_king_list(match_type, king_info)
	local nick_name = string.trans_str(king_info.nick_name)
	local sql = "insert into car_king_list(match_type, user_id,nick_name,car_id,car_type,area_id,sys_time) value(%d,%d,'%s',%d,%d,%d,now())"
	sql = string.format(sql, match_type, king_info.user_id, nick_name, king_info.car_id, king_info.car_type, king_info.area_id)			
	dblib.execute(sql,function(dt) end,user_id)
end

--初始化king_list
function car_match_sj_db_lib.init_today_king_list()
	if car_match_sj_lib.today_king_list[3] == nil then car_match_sj_lib.today_king_list[3] = {} end
   	local sql = "SELECT * FROM car_king_list WHERE match_type = 3 ORDER BY id DESC limit "..car_match_lib.CFG_TODAY_KING_LEN
	dblib.execute(sql,function(dt)
		if dt and #dt>0 then
			for k,v in pairs(dt)do
				local buf_tab = {
                    ["id"] = v.id,
					["user_id"] = v.user_id,
					["nick_name"] = v.nick_name,
					["car_id"] = v.car_id,
					["car_type"] = v.car_type,
					["area_id"] = v.area_id,
				}
				table.insert(car_match_sj_lib.today_king_list[v.match_type], buf_tab)
            end
            table.sort(car_match_sj_lib.today_king_list[3], function(a, b) 
                    return a.id < b.id
            end)
			--删除7天前的数据防止数据太大
			sql = "DELETE FROM car_king_list WHERE match_type = 3 and sys_time< DATE(DATE_SUB(NOW(),INTERVAL 7 DAY));"
			dblib.execute(sql)
		end
	end)
end

------------------------------------------------网络协议--------------------------------------------
cmdHandler =
{
 
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
    cmdHandler_addons[k] = v
end

--eventmgr:addEventListener("timer_second", car_match_lib.timer);
--eventmgr:addEventListener("on_server_start", car_match_lib.restart_server);
--eventmgr:addEventListener("gm_cmd", car_match_lib.gm_cmd)

