TraceError("init wabaonew_lib...初始化新挖宝活动")
if wabaonew_lib and wabaonew_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", wabaonew_lib.on_after_user_login);
end

if wabaonew_lib and wabaonew_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", wabaonew_lib.on_user_exit);
end

if wabaonew_lib and wabaonew_lib.on_server_start then
	eventmgr:removeEventListener("on_server_start", wabaonew_lib.on_server_start);
end
if wabaonew_lib and wabaonew_lib.on_timer_second then
	eventmgr:removeEventListener("timer_second", wabaonew_lib.on_timer_second);
end

if not wabaonew_lib then
	wabaonew_lib = _S
	{
------------------系统事件--------------------------
		on_after_user_login = NULL_FUNC,            --用户登陆后初始化数据
        on_user_exit        = NULL_FUNC,            --用户离开服务器
        on_server_start     = NULL_FUNC,            --服务器启动
        on_timer_second     = NULL_FUNC,            --
------------------发送客户端--------------------------
        net_send_activity_stat   = NULL_FUNC,         --发送活动状态
        net_send_user_wabao_info = NULL_FUNC,       --发送用户挖宝信息
        net_send_owner_wabao_info = NULL_FUNC,      --发送宝物所有者信息
        net_send_wabao_cfg       = NULL_FUNC,
        net_send_buy_result      = NULL_FUNC,       --发送购买铲子结果
        net_send_refresh_shovel  = NULL_FUNC,       --发送铲子数量
        net_send_choujiang_result = NULL_FUNC,      --发送抽奖结果
        net_send_guess_password_result    = NULL_FUNC,--猜密码
        net_send_set_password_result      = NULL_FUNC,--设置密码
        net_send_activity_over   = NULL_FUNC,        --发送活动结束提示
        net_send_get_gift_result        = NULL_FUNC,
        net_send_show_password_panel = NULL_FUNC,    --显示密码提示框
        net_send_exchange_list       = NULL_FUNC,    --发送兑换日志
        net_send_exchange_result     = NULL_FUNC,    --发送兑换结果
        net_send_wabao_result        = NULL_FUNC,    --发送挖宝信息
        net_send_show_contact_panel  = NULL_FUNC,    --让用户填写联系信息
        net_send_show_get_gift_panel = NULL_FUNC,    --显示获取奖品
        net_send_back_shovel_gold    = NULL_FUNC,    --发送返回铲子金币
        net_send_show_add_jiangjuan  = NULL_FUNC,    --发送增加奖卷
------------------客户端请求---------------------
		on_recv_buy_shovel = NULL_FUNC, 			--请求购买 
		on_recv_open_wnd = NULL_FUNC,		    --请求打开活动面板 
		on_recv_activity_stat = NULL_FUNC,		--请求活动时间状态 
		on_recv_wabao = NULL_FUNC,				--收到挖宝
        on_recv_choujiang = NULL_FUNC,          --收到抽奖
        on_recv_guess_password = NULL_FUNC,     --猜中密码了
        on_recv_set_password   = NULL_FUNC,     --设置密码了
        on_recv_get_gift       = NULL_FUNC,     --请求获取奖品
        on_recv_contact        = NULL_FUNC,     --请求联系人
        on_recv_exchange       = NULL_FUNC,     --请求兑换
        on_recv_gs_refresh_owner_list = NULL_FUNC, --刷新拥有者列表
        on_recv_gs_notify_get_gift    = NULL_FUNC, --收到玩家领奖通知
-------------------私有函数-----------------------------
        check_action           = NULL_FUNC,         --活动检查
		check_datetime = NULL_FUNC,	                --检查有效时间，限时问题
        check_game     = NULL_FUNC,                 --检查有效游戏
        get_user_wabao_status = NULL_FUNC,          --获取用户挖宝状态
        init_wabao_gift_info = NULL_FUNC,           --获取挖宝信息
        get_random_gift = NULL_FUNC,                --随机获取礼包
        add_gold        = NULL_FUNC,                --加钱
        send_owner_list = NULL_FUNC,                --发送拥有者列表
        process_user_prize = NULL_FUNC,             --给用户发奖
        process_msg_queue  = NULL_FUNC,             --
-------------------私有成员变量-----------------------------
        user_list = {},                             --用户列表
        owner_list = {},
        refresh_gift_time = 0,
        refresh_map_time = 0,
        refresh_client = 0,
        cfg_fajiang_servers = {
            ['tex'] = 18001, 
            ['cow'] = 61001,
        },
        cfg_games = {
            ['tex']  = 'tex',
            ['cow']  = 'qp',
            ['ddz']  = 'qp',
            ['mj']   = 'qp',
            ['soha'] = 'qp',
            ['zysz'] = 'qp',
        },
        cfg_names = {
            jiangjuan = "优惠券",
            chengzhang = "贵宾卡",
            bean = "达人币",
        },
        cfg_jiangjuans = {
            [1] = {
                need_bean = 150,
                need_jiangjuan = 1,
                chengzhang = 20,
                vip_item = 2011,
                jiangjuan_name = "5元",
            }, 
            [2] = {
                need_bean = 430,
                need_jiangjuan = 1,
                chengzhang = 50,
                vip_item = 2012,
                jiangjuan_name = "7元",
            }, 
            [3] = {
                need_bean = 410,
                need_jiangjuan = 1,
                chengzhang = 50,
                vip_item = 2012,
                jiangjuan_name = "9元",
            }, 
            [4] = {
                need_bean = 800,
                need_jiangjuan = 1,
                chengzhang = 100,
                vip_item = 2013,
                jiangjuan_name = "20元",
            }, 
        },
        cfg_gift_list = {
        },
        cfg_maps  = {
              ['qp']  = {
                [1] = {
                    ["need_shovel_num"] = 1,
                    ["shovel_prices"] = {
                        [1]  = 10000,
                        [5]  = 50000,
                        [10] = 100000,
                    },
                    ["password_range"] = {0, 19},
                    ["tips"] = "活动每天最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "翡翠地图",
                    ["refresh_day"] = 1,
                },
                [2] = {
                    ["need_shovel_num"] = 10,
                    ["shovel_prices"] = {
                        [10]  = 100000,
                        [50]  = 500000,
                        [100] = 1000000,
                    },
                    ["password_range"] = {0, 29},
                    ["tips"] = "活动每3天最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "珍珠地图",
                    ["refresh_day"] = 3,
                },
                [3] = {
                    ["need_shovel_num"] = 50,
                    ["shovel_prices"] = {
                        [50] =  500000,
                        [200] = 2000000,
                        [500] = 5000000,
                    },
                    ["password_range"] = {0, 39},
                    ["tips"] = "截止%s月%s日%s：%s最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "钻石地图",
                    ["refresh_day"] = 7,
                },
            },

            ['tex']  = {
                [1] = {
                    ["need_shovel_num"] = 1,
                    ["shovel_prices"] = {
                        [1]  = 10000,
                        [5]  = 50000,
                        [10] = 100000,
                    },
                    ["password_range"] = {0, 19},
                    ["tips"] = "活动每天最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "翡翠地图",
                    ["refresh_day"] = 1,
                },
                [2] = {
                    ["need_shovel_num"] = 5,
                    ["shovel_prices"] = {
                        [5]  = 50000,
                        [20] = 200000,
                        [50] = 500000,
                    },
                    ["password_range"] = {0, 29},
                    ["tips"] = "活动每3天最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "珍珠地图",
                    ["refresh_day"] = 3,
                },
                [3] = {
                    ["need_shovel_num"] = 10,
                    ["shovel_prices"] = {
                        [10] = 100000,
                        [50] = 500000,
                        [100]= 1000000,
                    },
                    ["password_range"] = {0, 39},
                    ["tips"] = "截止%s月%s日%s：%s最后抢到宝物的玩家将获得宝物",
                    ["over_tips"] = "本地图的宝物已被全部挖光",
                    ["name"] = "钻石地图",
                    ["refresh_day"] = 7,
                },
            },
        },

-------------------常量--------------------------------------
        STATIC_GAME_QP = 'qp',
        STATIC_GAME_TEX = 'tex',
		STATIC_START_TIME = "2012-07-16 09:00:00",  --活动开始时间
    	STATIC_END_TIME = "2012-07-23 00:00:00",    --活动结束时间
        STATIC_KEEP_TIME = "2012-07-23 12:00:00",   --活动图标保留时间
        STATIC_FAJIANG_TIME = "2012-07-33 12:00:00",--最迟发奖奖时间
        STATIC_REFRESH_GIFT_HOUR = 0,
        STATIC_ACTIVED = 1,                         --活动激活状态
        STATIC_KEEP    = 5,                         --活动结束，但是保留图标
        STATIC_OVER    = 0,                         --活动结束了 
        STATIC_FAJIANG = 2,                         --活动发奖
        STATIC_WABAOING = 1,                        --用户挖宝
        STATIC_WABAOED  = 2,                        --已挖宝，等待抽奖
        STATIC_WABAOED_GUESS_PASSWORD = 3,          --已挖宝，已抽奖，正在猜密码
        STATIC_WABAOED_SET_PASSWORD = 4,            --已挖宝，已抽奖，猜了密码，设置密码
        STATIC_SEND_OWNER_NUM = 2,                  --显示多个宝物拥有者
        STATIC_WABAO_GIFT_NUM = 8,                  --默认8个奖品去抽奖
        STATIC_GUESS_TIMEOUT = 20,                  --猜密码超时时间
        STATIC_JIANGJUAN_RATE = 30,                 --抽中奖卷的概率
	}

end
---------------------私有函数------------------------------------------------------

function wabaonew_lib.check_has_dajiang(map_id)
    local result = 0;
    for k, v in pairs(wabaonew_lib.cfg_gift_list[map_id]) do
        if(v.is_qiang == 1) then
            result = 1;
            break;
        end
    end
    return result;
end

function wabaonew_lib.check_map_over(map_id, current_time)
    local result = 0;
    local gift_cfg = nil;
    for k, v in pairs(wabaonew_lib.cfg_gift_list[map_id]) do
        if(v.is_qiang == 1) then
            gift_cfg = v;
            break;
        end
    end
    if(gift_cfg ~= nil) then
        local valid_time = wabaonew_lib.get_vaild_time(wabaonew_lib.STATIC_START_TIME, gift_cfg.dajiang_time, wabaonew_lib.STATIC_END_TIME, current_time);
        if(valid_time > timelib.db_to_lua_time(wabaonew_lib.STATIC_END_TIME)) then
            result = 1
        end
    end
    return result;
end

function wabaonew_lib.reset_user_wabao_info(user_wabao_info) 
    if(user_wabao_info ~= nil) then
        user_wabao_info.status = wabaonew_lib.STATIC_WABAOING;
        user_wabao_info.gift_id = 0;
        user_wabao_info.map_id = 0;
        user_wabao_info.gift_list = {};
        user_wabao_info.gift_info = nil;
        user_wabao_info.guess_start_time = 0;
    end
end

function wabaonew_lib.process_msg_queue(userinfo)
    timelib.createplan(function()
        local check_time, is_fajiang = wabaonew_lib.check_datetime();
        --判断用户是否可以领奖，只判断一次
        wabaonew_db_lib.get_user_wabao_dajiang_record(userinfo.userId, os.time(), function(dt)
            --TraceError('get_user_wabao_dajiang_record');
            if(dt ~= nil) then
                for k, v in pairs(dt) do
                    wabaonew_db_lib.update_user_wabao_record(v.id, userinfo.userId, 1);
                    --弹出提示框
                    local gift_cfg = wabaonew_lib.cfg_gift_list[v.map_id][v.gift_id];  
                    wabaonew_lib.net_send_show_get_gift_panel(userinfo, v.gift_id, v.id, gift_cfg.is_shiwu);
                    break;
                end
            end

            --如果活动结束了，就给用户返回钱
            if((dt == nil or #dt == 0) and (check_time == wabaonew_lib.STATIC_KEEP or (check_time == wabaonew_lib.STATIC_OVER and is_fajiang == 1))) then
                --TraceError('退铲子');
                local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
                if(user_wabao_info ~= nil and user_wabao_info.shovel_num > 0) then
                    local shovel_prices = wabaonew_lib.cfg_maps[1]["shovel_prices"][1] * user_wabao_info.shovel_num;
                    if(shovel_prices > 0) then
                        --返还给用户金币
                        wabaonew_db_lib.clear_user_shovel_num(userinfo.userId);
                        user_wabao_info.shovel_num = 0;
                        wabaonew_lib.add_gold(userinfo, shovel_prices, new_gold_type.WABAONEW_BACK_GOLD);
                        --通知客户端
                        wabaonew_lib.net_send_back_shovel_gold(userinfo, shovel_prices);
                    end
                end
            end
        end);
    end,2);
end

function wabaonew_lib.send_chat(msg)
    if(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_QP) then
        chat_lib.send_chat(chat_lib.chat_type.sys_micro_speaker, -1, msg, 0, "", 0);
    else
        tex_speakerlib.send_sys_msg(msg);
    end
end

function wabaonew_lib.get_vaild_time(start_time,  dajiang_time, end_time, now_time)
    dajiang_time = dajiang_time * 24 * 3600;
    end_time = timelib.db_to_lua_time(end_time);
	local db_date = function(db_time)
		local time = {}
		for i in string.gmatch(db_time, "%d+") do
			table.insert(time, i)
		end
		local lua_time = os.time{year = time[1], month = time[2], day = time[3], hour = 0, min = 0, sec = 0}
		return lua_time
	end
	local start_time_zhen = db_date(start_time)
	local vaild_time = math.ceil((now_time - start_time_zhen) /dajiang_time) * dajiang_time + start_time_zhen

    --[[
	if (vaild_time >  end_time) then
		vaild_time = end_time
	end
    --]]
	return vaild_time
end

function wabaonew_lib.refresh_wabao_info_to_all_ser(map_id)
        wabaonew_db_lib.get_owner_list(map_id, function(dt)
           if(dt == nil) then
               dt = {};
           end
           wabaonew_lib.send_all_server(function(buf)
                buf:writeString("GS_WBRFOWNER");
                buf:writeInt(map_id);
                buf:writeInt(#dt);
                for _, wabao_info in pairs(dt) do
                    buf:writeInt(wabao_info.id);
                    buf:writeInt(wabao_info.gift_id);
                    buf:writeInt(wabao_info.cur_user_id);
                    buf:writeString(wabao_info.cur_nick_name);
                    buf:writeString(wabao_info.last_nick_name);
                    buf:writeString(wabao_info.sys_time);
                end
           end);
       end);
end

function wabaonew_lib.process_user_prize(userinfo, map_id, gift_id) 
    local gift_cfg = wabaonew_lib.cfg_gift_list[map_id][gift_id];
    if(gift_cfg ~= nil) then
        if(gift_cfg.gift_type == 1) then
            --金币
            wabaonew_lib.add_gold(userinfo, gift_cfg.gift_value, new_gold_type.WABAONEW_GIFT);
        elseif(gift_cfg.gift_type == 2) then
            --达人币
            usermgr.addcash(userinfo.userId, gift_cfg.gift_value, new_gold_type.WABAONEW, "", 1);      
        elseif(gift_cfg.gift_type == 10) then
            --德州筹码
            usermgr.addgold(userinfo.userId, gift_cfg.gift_value, 0, new_gold_type.WABAONEW, -1);
        elseif(gift_cfg.gift_type == 11) then
            --vip
            if(gift_id == 11) then
                --铜卡
                viplib.add_user_vip(userinfo, 1, gift_cfg.gift_value);
            elseif(gift_id == 12) then
                --金卡
                viplib.add_user_vip(userinfo, 3, gift_cfg.gift_value);
            end
        elseif(gift_cfg.gift_type == 12) then
            --小喇叭
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, gift_cfg.gift_value, userinfo);
        elseif(gift_cfg.gift_type == 13) then
            --车
            car_match_db_lib.add_car(userinfo.userId, gift_cfg.gift_value, 0);
        elseif(gift_cfg.gift_type == 14) then
            --t人卡
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, gift_cfg.gift_value, userinfo);
        end
    end
end

function wabaonew_lib.send_wabao_record(userinfo, map_id)
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    if(user_wabao_info ~= nil and user_wabao_info.cur_map_id == map_id) then
        wabaonew_db_lib.get_wabao_record(map_id, function(dt)
            if(dt == nil or #dt == 0) then
                dt = {};
            end
            wabaonew_lib.net_send_wabao_record(userinfo, dt);
        end);
    end
end

function wabaonew_lib.send_owner_list(userinfo, map_id)
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    if(user_wabao_info ~= nil and user_wabao_info.cur_map_id ~= nil and user_wabao_info.cur_map_id == map_id) then
        if(wabaonew_lib.owner_list[map_id] ~= nil) then
            wabaonew_lib.net_send_owner_wabao_info(userinfo, wabaonew_lib.owner_list[map_id]);
        else
            wabaonew_db_lib.get_owner_list(map_id, function(dt)
                if(dt == nil or #dt == 0) then
                    dt = {};
                end
                wabaonew_lib.owner_list[map_id] = dt;
                wabaonew_lib.net_send_owner_wabao_info(userinfo, dt);
            end);
        end
    end
end

function wabaonew_lib.add_gold(userinfo, gold, add_type)
	if(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_TEX)then
		 usermgr.addgold(userinfo.userId, gold, 0, add_type, -1);
    elseif(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_QP)then
		usermgr.addgold(userinfo.userId, gold, 0, add_type, -1);
	end
end

function wabaonew_lib.check_action(userinfo)
    --游戏类型验证
    local check_result = wabaonew_lib.check_game();
    if(check_result == 0) then
        return 0;
    end

	--检查活动时间
	check_result = wabaonew_lib.check_datetime();	
	if(check_result ~= wabaonew_lib.STATIC_ACTIVED)then
        wabaonew_lib.net_send_activity_over(userinfo);
		return 0;
    end
    return 1;
end

function wabaonew_lib.get_random_gift(gift_list)
    local gift_id = 0;
    local gift_index = 0;
    if(#gift_list > 0) then
        math.randomseed(os.time() * 100000);
        local random = math.random(1, 100);
        local pre_rate = math.ceil(100/#gift_list);
        for k, v in pairs(gift_list) do
            if(random <= (k * pre_rate)) then
                gift_id = v;
                gift_index = k;
                break;
            end
        end
    end
    return gift_id, gift_index;
end

function wabaonew_lib.init_wabao_gift_info() 
    if(wabaonew_lib.check_game() == 1) then
        wabaonew_db_lib.get_gift_cfg(function(gift_list)
            for k, v in pairs(gift_list) do
                if(wabaonew_lib.cfg_gift_list[v.map_id] == nil) then
                    wabaonew_lib.cfg_gift_list[v.map_id] = {};
                end
                local gift_cfg = wabaonew_lib.cfg_gift_list[v.map_id];
                gift_cfg[v.gift_id] = v;
            end
            wabaonew_lib.gen_gift_random_pwd();
        end);
    end

    wabaonew_lib.cfg_maps = wabaonew_lib.cfg_maps[wabaonew_lib.cfg_games[gamepkg.name]];
end

function wabaonew_lib.check_game() 
    if(wabaonew_lib.cfg_games[gamepkg.name] ~= nil) then
		return 1;
    end
    return 0;
end

--检查有效时间，限时问题
function wabaonew_lib.check_datetime()
	local sys_time = os.time();
	local statime = timelib.db_to_lua_time(wabaonew_lib.STATIC_START_TIME);
	local endtime = timelib.db_to_lua_time(wabaonew_lib.STATIC_END_TIME);
	local keeptime = timelib.db_to_lua_time(wabaonew_lib.STATIC_KEEP_TIME);
    local fajiang_time = timelib.db_to_lua_time(wabaonew_lib.STATIC_FAJIANG_TIME); 
    local is_fajiang = 0;
    if(os.time() < fajiang_time) then
        is_fajiang = 1;
    end
	if(sys_time > statime and sys_time <= endtime) then
	    return wabaonew_lib.STATIC_ACTIVED, is_fajiang;
	end
	
	if(sys_time > endtime and sys_time <= keeptime) then
		return wabaonew_lib.STATIC_KEEP, is_fajiang;
	end
	
	return wabaonew_lib.STATIC_OVER, is_fajiang;
end

-------------------------------发送客户端--------------------------------------------

function wabaonew_lib.net_send_show_add_jiangjuan(userinfo, jiangjuan_type, jiangjuan_num)
    netlib.send(function(buf)
        buf:writeString("WBGETJUAN");
        buf:writeInt(jiangjuan_type);
        buf:writeInt(jiangjuan_num);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_back_shovel_gold(userinfo, gold)
    netlib.send(function(buf)
        buf:writeString("WBGBCZ");
        buf:writeInt(gold);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_wabao_record(userinfo, list)
    netlib.send(function(buf)
        buf:writeString("WBHISTORY");
        buf:writeInt(#list);
        for k, v in pairs(list) do
            buf:writeInt(v.user_id);
            buf:writeString(v.nick_name);
            buf:writeInt(v.gift_id);
            buf:writeInt(#list - k + 1);
        end
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_show_contact_panel(userinfo, gift_id, show_type)
    --TraceError('net_send_show_contact_panel');
    netlib.send(function(buf)
        buf:writeString("WBSHIWU");
        buf:writeInt(gift_id);
        buf:writeInt(show_type or 0);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_wabao_result(userinfo, result)
    netlib.send(function(buf)
        buf:writeString("WBWABAO");
        buf:writeInt(result);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_exchange_result(userinfo, result, jiangjuan_type, bean)
    netlib.send(function(buf)
        buf:writeString("WBCHANGE");
        buf:writeInt(result);
        buf:writeInt(jiangjuan_type or 0);
        buf:writeInt(bean or 0);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_exchange_list(userinfo, list)
    netlib.send(function(buf)
        buf:writeString("WBYHHIS");
        buf:writeInt(#list);
        for k, v in pairs(list) do
            buf:writeInt(v.jiangjuan_type);
            buf:writeInt(v.id);
        end
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_show_password_panel(userinfo, status, user_wabao_info)
    --TraceError("net_send_show_password_panel"..status);
    local owner_nick = _U("系统");
    if(status == wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD and wabaonew_lib.owner_list[user_wabao_info.map_id] ~= nil) then
        for k, v in pairs(wabaonew_lib.owner_list[user_wabao_info.map_id]) do
            if(v.gift_id == user_wabao_info.gift_id) then
                owner_nick = v.cur_nick_name;
                break;
            end
        end
    end
    --TraceError("owner_nick"..owner_nick);
    netlib.send(function(buf)
        buf:writeString("WBMIMA");
        buf:writeInt(status);
        buf:writeInt(wabaonew_lib.cfg_maps[user_wabao_info.map_id]["password_range"][1]);
        buf:writeInt(wabaonew_lib.cfg_maps[user_wabao_info.map_id]["password_range"][2]);
        local timeout = user_wabao_info.guess_start_time + wabaonew_lib.STATIC_GUESS_TIMEOUT - os.time();
        if(status == wabaonew_lib.STATIC_WABAOED_SET_PASSWORD) then
            timeout = 0; 
        end
        buf:writeInt(timeout > 0 and timeout or 0);
        buf:writeInt(user_wabao_info.gift_id);
        buf:writeString(owner_nick or "");
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_get_gift_result(userinfo, result)
    netlib.send(function(buf)
        buf:writeString("WBGETPZ");
        buf:writeInt(result);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_activity_over(userinfo)
    netlib.send(function(buf)
        buf:writeString("WBHDOVER");
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_guess_password_result(userinfo, result)
    netlib.send(function(buf)
        buf:writeString("WBJIEMM");
        buf:writeInt(result);
    end, userinfo.ip, userinfo.port)
end

function wabaonew_lib.net_send_set_password_result(userinfo, result, gift_id, gift_owner)
    --TraceError('net_send_set_password_result '..result);
    netlib.send(function(buf)
        buf:writeString("WBSHEMM");
        buf:writeInt(result);
        buf:writeInt(gift_id or 0);
        buf:writeString(gift_owner or "");
    end, userinfo.ip, userinfo.port)
end

function wabaonew_lib.net_send_choujiang_result(userinfo, result, gift_id)
    --TraceError('choujiang result'..result.." gift_id"..(gift_id or 0));
    if(result == 1 and gift_id == nil) then
        TraceError("抽奖有bug吧，结果为1，但是礼品id为nil");
    end
    netlib.send(function(buf)
        buf:writeString("WBZNPN");
        buf:writeInt(result);
        buf:writeInt(gift_id or 0);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_show_get_gift_panel(userinfo, gift_id, record_id, is_shiwu)
    netlib.send(function(buf)
        buf:writeString("WBGVGF");
        buf:writeInt(gift_id);
        buf:writeInt(record_id);
        buf:writeInt(is_shiwu or 0);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_refresh_shovel(userinfo, user_wabao_info)
    netlib.send(function(buf)
        buf:writeString("WBRFCHANZI");
        buf:writeInt(user_wabao_info.shovel_num);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_owner_wabao_info(userinfo, owner_list) 
    netlib.send(function(buf)
        buf:writeString("WBBWOWNER");
        buf:writeInt(#owner_list);
        local count = 0;
        for k, v in pairs(owner_list) do
            if(count >= wabaonew_lib.STATIC_SEND_OWNER_NUM) then
                break;
            end
            count = count + 1;
            buf:writeInt(v.gift_id);
            buf:writeString(v.last_nick_name == v.cur_nick_name and _U("") or v.last_nick_name);
            buf:writeString(v.cur_nick_name);
            buf:writeInt(v.id);
        end
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_wabao_cfg(userinfo) 
    netlib.send(function(buf)
        buf:writeString("WBCFG");
        buf:writeInt(3);
        for map_id, cfg in pairs(wabaonew_lib.cfg_maps) do
            buf:writeInt(map_id);--地图id
            buf:writeInt(3);
            for shovel_num, shovel_price in pairs(cfg.shovel_prices) do
                buf:writeInt(shovel_num);
                buf:writeInt(shovel_price);
            end
        end
        buf:writeInt(4);
        for jiangjuan_type, cfg in pairs(wabaonew_lib.cfg_jiangjuans) do
            buf:writeInt(jiangjuan_type);
            buf:writeString(_U(cfg.jiangjuan_name..wabaonew_lib.cfg_names["jiangjuan"]));
            buf:writeString(cfg.need_bean.._U(wabaonew_lib.cfg_names["bean"]));
            buf:writeString(cfg.chengzhang.._U(wabaonew_lib.cfg_names["chengzhang"]));
        end
        local gift_list = {};
        local count = 0;
        for map_id, list in pairs(wabaonew_lib.cfg_gift_list) do
            for gift_id, gift_info in pairs(list) do
                if(gift_list[gift_id] == nil) then
                    count = count + 1;
                end
                gift_list[gift_id] = gift_info;
            end
        end

        buf:writeInt(count);
        for k, gift_info in pairs(gift_list) do
            buf:writeInt(gift_info.gift_id);
            buf:writeString(gift_info.gift_name);
        end
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_activity_stat(userinfo, stat) 
    netlib.send(function(buf)
        buf:writeString("WBACTIVED");
        buf:writeByte(stat);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_user_jiangjuan_info(userinfo, user_wabao_info) 
    --TraceError(user_wabao_info);
    netlib.send(function(buf)
        buf:writeString("WBYHJUAN");
        buf:writeInt(4);
        buf:writeInt(user_wabao_info.jiangjuan1);
        buf:writeInt(user_wabao_info.jiangjuan2);
        buf:writeInt(user_wabao_info.jiangjuan3);
        buf:writeInt(user_wabao_info.jiangjuan4);
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info, show_type) 
    local map_cfg = wabaonew_lib.cfg_maps[map_id];
    if(map_cfg ~= nil) then
        netlib.send(function(buf)
            buf:writeString("WBOPPN");
            buf:writeInt(show_type or 0);
            buf:writeInt(map_id);
            if(wabaonew_lib.check_has_dajiang(map_id) == 1) then
                if(wabaonew_lib.check_map_over(map_id, os.time() + 1) == 0) then
                    local time_table = os.date("*t", timelib.db_to_lua_time(wabaonew_lib.STATIC_END_TIME));
                    local tips = _U(map_cfg.tips);
                    local hour  = time_table.hour;
                    local min = time_table.min;
                    if(hour == 0) then
                        hour = "00";
                    end
                    if(min == 0) then
                        min = "00";
                    end
                    tips = string.format(tips, time_table.month, time_table.day, hour, min);
                    buf:writeString(tips);
                else
                    buf:writeString(_U(map_cfg.over_tips));
                end
            else
                buf:writeString("");
            end
            buf:writeInt(user_wabao_info.shovel_num);
            buf:writeInt(map_cfg.need_shovel_num);
            buf:writeInt(user_wabao_info.status);
            if(user_wabao_info ~= wabaonew_lib.STATIC_WABAOING) then--已挖宝
                buf:writeInt(user_wabao_info.gift_id);
                buf:writeInt(#user_wabao_info.gift_list);
                for k, v in pairs(user_wabao_info.gift_list) do
                    buf:writeInt(v);
                end
            end
        end, userinfo.ip, userinfo.port);
    end
end
-------------------------------系统事件--------------------------------------------

function wabaonew_lib.on_user_exit(e)
    local user_id = e.data.user_id;
    if(wabaonew_lib.user_list[user_id] ~= nil) then
        wabaonew_lib.user_list[user_id] = nil;
    end
end

function wabaonew_lib.on_timer_second(e)

   if(#wabaonew_lib.cfg_gift_list <= 0) then
       return;
   end

   local check_result = wabaonew_lib.check_datetime();
   local refresh_owner = 1;
   if(check_result == wabaonew_lib.STATIC_ACTIVED and wabaonew_lib.refresh_client == 0) then
       wabaonew_lib.refresh_client = 1;
       refresh_owner = 0;
       for k, v in pairs(wabaonew_lib.user_list) do
           local userinfo = usermgr.GetUserById(k);
           if(userinfo ~= nil) then
               wabaonew_lib.net_send_activity_stat(userinfo, wabaonew_lib.STATIC_ACTIVED);
               wabaonew_lib.net_send_wabao_cfg(userinfo);
           end
       end
   end

   local current_time = os.time();
   local time_table = os.date("*t",current_time);
   local is_refresh_map = 0;
   local is_prize = 0;
   if(time_table.hour == wabaonew_lib.STATIC_REFRESH_GIFT_HOUR 
      and current_time < timelib.db_to_lua_time(wabaonew_lib.STATIC_KEEP_TIME))then
        if(current_time - wabaonew_lib.refresh_map_time > 24 * 3600) then
            is_refresh_map = 1;
        end
        if(current_time - wabaonew_lib.refresh_gift_time > 24 * 3600) then
            is_prize = 1;
        end
   end
   if(wabaonew_lib.cfg_games[gamepkg.name] ~= nil and is_refresh_map == 1) then
        wabaonew_lib.refresh_map_time = current_time;
        local map_status = {};
        for k, v in pairs(wabaonew_lib.cfg_maps) do
            map_status[k] = wabaonew_lib.check_map_over(k, current_time + 1);
        end
        --TraceError(map_status);
        for k, v in pairs(wabaonew_lib.user_list) do
           local userinfo = usermgr.GetUserById(k);
           if(userinfo ~= nil) then
               local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
               if(user_wabao_info ~= nil and user_wabao_info.cur_map_id ~= nil 
                  and map_status[user_wabao_info.cur_map_id] == 1) then
                      --TraceError('send user_wabao_info');
                      wabaonew_lib.net_send_user_wabao_info(userinfo, user_wabao_info.cur_map_id, user_wabao_info);
               end
           end
       end
   end

   if(wabaonew_lib.cfg_fajiang_servers[gamepkg.name] ~= nil and 
      tonumber(groupinfo.groupid) == wabaonew_lib.cfg_fajiang_servers[gamepkg.name]) then
       if(is_prize == 1) then
           local notify_list = {};      
           wabaonew_lib.gen_gift_random_pwd();
           wabaonew_lib.refresh_gift_time = current_time;
           --系统生成随随机密码
           wabaonew_lib.gen_gift_random_pwd();
           for k, v in pairs(wabaonew_lib.cfg_maps) do
               wabaonew_db_lib.get_wabao_dajiang_info(k, current_time, function(all_wabao_info)
                   for i, wabao_info in pairs(all_wabao_info) do
                       --已过去的时间
                           --开始发奖了,和刷新奖品
                           --先删除数据库里面的数据
                           wabaonew_db_lib.delete_wabao_info(wabao_info.map_id, wabao_info.gift_id, wabao_info.user_id, current_time);
                           --进行记录
                           wabaonew_db_lib.add_wabao_record(wabao_info.map_id, wabao_info.user_id, wabao_info.nick_name, wabao_info.gift_id, 0);
                           --全服广播
                           local gift_cfg = wabaonew_lib.cfg_gift_list[wabao_info.map_id][wabao_info.gift_id];
                           wabaonew_lib.send_chat(_U("恭喜玩家")..wabao_info.nick_name.._U("获得宝物")..gift_cfg.gift_name);
                           --如果玩家在线则通知玩家领奖
                           local touserinfo = usermgr.GetUserById(wabao_info.user_id);
                           if(notify_list[wabao_info.user_id] == nil) then
        			           notify_list[wabao_info.user_id] = 1;
            				   if(touserinfo ~= nil) then
            					   wabaonew_lib.net_send_show_get_gift_panel(touserinfo, wabao_info.gift_id, wabao_info.id, gift_cfg.is_shiwu);
            					   wabaonew_db_lib.update_user_wabao_record(wabao_info.id, touserinfo.userId, 1);
            				   else
                				   wabaonew_lib.send_all_server(function(buf)
                					    buf:writeString("GS_WBNTPRIZE");
                					    buf:writeInt(wabao_info.user_id);
                					    buf:writeInt(wabao_info.gift_id);
                					    buf:writeInt(wabao_info.id);
                					    buf:writeInt(gift_cfg.is_shiwu);
                				   end);
                               end 
                           end 
                   end
                   if(refresh_owner == 1) then
                       wabaonew_lib.refresh_wabao_info_to_all_ser(k); 
                   end
               end)
           end
       end
   end
end

function wabaonew_lib.on_server_start(e)
    wabaonew_lib.init_wabao_gift_info();
    local check_result = wabaonew_lib.check_datetime();
    if(check_result == wabaonew_lib.STATIC_ACTIVED) then
        wabaonew_lib.refresh_client = 1;
    end
end

function wabaonew_lib.send_all_server(callback)
    local send_all_srv = nil;
    if(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_QP) then
        send_all_srv = netlib.send_buf_to_all_game_svr;
    else
        send_all_srv = send_buf_to_all_game_svr;
    end

    if(send_all_srv ~= nil) then
        for k,v in pairs(wabaonew_lib.cfg_games)do
            send_all_srv(callback, k)
        end
    end
end

function wabaonew_lib.gen_gift_random_pwd()
    if(wabaonew_lib.cfg_fajiang_servers[gamepkg.name] ~= nil) then
        local map_count = 0;
        for map_id, gifts in pairs(wabaonew_lib.cfg_gift_list) do
            local map_cfg = wabaonew_lib.cfg_maps[map_id];
            for gift_id, gift_cfg in pairs(gifts) do
                if(gift_cfg.is_qiang == 1) then
                    math.randomseed(os.time() + math.random(0, 10000));
                    gift_cfg.sys_pwd = math.random(map_cfg.password_range[1], map_cfg.password_range[2]);
                    dblib.execute(string.format("update cfg_wabao_gift set sys_pwd = %d where map_id = %d and gift_id = %d;commit;", gift_cfg.sys_pwd, map_id, gift_id));
                    --table.insert(list, {map_id=map_id, gift_id=gift_id, sys_pwd=gift_cfg.sys_pwd});
                end
            end
        end
    end
end

--用户登陆后初始化数据
function wabaonew_lib.on_after_user_login(e)
	--游戏类型验证
    local check_result = wabaonew_lib.check_game();
    if(check_result == 0) then
        return;
    end

	--检查活动时间
	local check_time, is_fajiang = wabaonew_lib.check_datetime();
	if(check_time == wabaonew_lib.STATIC_OVER and is_fajiang == 0) then 
		return
	end 

    --初始化用户数据
	local userinfo = e.data.userinfo
	if(userinfo ~= nil)then 
    	wabaonew_db_lib.get_user_wabao_info(userinfo.userId, function(user_wabao_info)
            userinfo = usermgr.GetUserById(userinfo.userId);
            if(userinfo ~= nil) then
                wabaonew_lib.user_list[userinfo.userId] = user_wabao_info;
            end
        end);
    end
end

function wabaonew_lib.on_recv_wabao(buf)
    --TraceError("on_recv_wabao");
	local userinfo = userlist[getuserid(buf)];	
   	if not userinfo then return end; 

    if(wabaonew_lib.check_action(userinfo) == 0) then
        return;
    end

    local map_id = buf:readInt();
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];

    if(user_wabao_info.status == wabaonew_lib.STATIC_WABAOED) then
        --已经挖宝了，等抽奖吧
        --TraceError("已经挖宝了，等抽奖吧");
        return;
    end

    local map_cfg = wabaonew_lib.cfg_maps[map_id];
    local gift_cfg = wabaonew_lib.cfg_gift_list[map_id];
    if(user_wabao_info ~= nil and gift_cfg ~= nil and map_cfg ~= nil) then
        --用户铲子够不够
        --TraceError(map_cfg.need_shovel_num);
        --TraceError(user_wabao_info.shovel_num);
        if(user_wabao_info.shovel_num >= map_cfg.need_shovel_num) then
            --随机生成礼品
            --50%概率生成大奖
            math.randomseed(os.time());
            local random = math.random(1, 100);
            local gift_list = {};
            local gift_index_list = {};
            --TraceError("大奖概率"..random);
            if(random <= 50 and wabaonew_lib.check_map_over(map_id, os.time()) == 0) then
                --生成大奖
                local baowu_list = {};
                for gift_id, v in pairs(gift_cfg) do
                    if(v.is_qiang == 1) then
                        table.insert(baowu_list, gift_id);
                    end
                end
                local gift_id = wabaonew_lib.get_random_gift(baowu_list);
                if(gift_id > 0) then
                    --TraceError("大奖id"..gift_id);
                    table.insert(gift_list, gift_id);
                    gift_index_list[gift_id] = 1;
                end
            end

            --必须有一个道具数量没有限制的道具
            for gift_id, v in pairs(gift_cfg) do
                if(v.gift_num == -1 and v.is_qiang == 0) then
                    table.insert(gift_list, gift_id);
                    gift_index_list[gift_id] = 1;
                    break;
                end
            end

            local t_gift_list = {};
            local total_count = 0;
            for gift_id, v in pairs(gift_cfg) do
                total_count = total_count + 1;
                if(v.is_qiang == 0 and gift_index_list[gift_id] == nil) then
                    table.insert(t_gift_list, gift_id);
                end
            end

            if(total_count <= wabaonew_lib.STATIC_WABAO_GIFT_NUM) then
                t_gift_list = {};
                gift_list = {};
                for gift_id, v in pairs(gift_cfg) do
                    table.insert(t_gift_list, gift_id);
                end
            end

            --随机生成其它礼包
            for i=#gift_list + 1, wabaonew_lib.STATIC_WABAO_GIFT_NUM do
                local gift_id, gift_index = wabaonew_lib.get_random_gift(t_gift_list)
                table.insert(gift_list, gift_id);
                table.remove(t_gift_list, gift_index);
            end

            if(#gift_list ~= wabaonew_lib.STATIC_WABAO_GIFT_NUM) then
                TraceError('出bug了,随机抽出来的奖品数量不对的啊user_id'..userinfo.userId.." "..tostringex(gift_list));
            else
                --扣除铲子数量
                user_wabao_info.shovel_num = user_wabao_info.shovel_num -map_cfg.need_shovel_num;
                wabaonew_db_lib.add_user_shovel_num(userinfo.userId, -map_cfg.need_shovel_num, user_wabao_info.shovel_num);
                user_wabao_info.gift_list = gift_list;
                --TraceError(gift_list);
                user_wabao_info.map_id = map_id;
                user_wabao_info.status = wabaonew_lib.STATIC_WABAOED;
                user_wabao_info.gift_id = 0;
                user_wabao_info.guess_start_time = 0;
                user_wabao_info.wabao_time = os.time();
                wabaonew_lib.net_send_wabao_result(userinfo,  1);
                wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info);

                if(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_QP) then
                   local jiangjuan_list = {}; 
                   for k, v in pairs(wabaonew_lib.cfg_jiangjuans) do
                       table.insert(jiangjuan_list, k);
                   end
                   local jiangjuan_type = wabaonew_lib.get_random_gift(jiangjuan_list);
                   local random = math.random(0, 100);
                   if(random <= wabaonew_lib.STATIC_JIANGJUAN_RATE) then
                       local jiangjuan_key = 'jiangjuan'..jiangjuan_type; 
                       user_wabao_info[jiangjuan_key] = user_wabao_info[jiangjuan_key] + 1;
                       wabaonew_db_lib.add_jiangjuan(userinfo.userId, jiangjuan_type, 1);
                       wabaonew_lib.net_send_show_add_jiangjuan(userinfo, jiangjuan_type, 1);
                   end
                end
            end
        else
            wabaonew_lib.net_send_wabao_result(userinfo, -1);
        end
    end
end

-----------------客户端请求---------------------
function wabaonew_lib.on_recv_gs_notify_get_gift(buf)
    local user_id = buf:readInt();
    local gift_id = buf:readInt();
    local record_id = buf:readInt();
    local is_shiwu = buf:readInt();
    local touserinfo = usermgr.GetUserById(user_id);
    if(touserinfo) then
        wabaonew_db_lib.update_user_wabao_record(record_id, touserinfo.userId, 1);
        wabaonew_lib.net_send_show_get_gift_panel(touserinfo, gift_id, record_id, is_shiwu);
    end
end

function wabaonew_lib.on_recv_gs_refresh_owner_list(buf)
    --刷新拥有者列表 
    local map_id = buf:readInt();
    --TraceError('on_recv_gs_refresh_owner_list'..map_id);
    local len = buf:readInt();
    local list = {};
    for i = 1, len do
        local wabao_info = {};
        wabao_info.map_id = map_id;
        wabao_info.id = buf:readInt();
        wabao_info.gift_id = buf:readInt();
        wabao_info.cur_user_id = buf:readInt();
        wabao_info.cur_nick_name = buf:readString();
        wabao_info.last_nick_name = buf:readString();
        wabao_info.sys_time = buf:readString();
        table.insert(list, wabao_info);
    end

    wabaonew_lib.owner_list[map_id] = list;
    for k, v in pairs(wabaonew_lib.user_list) do
        local userinfo = usermgr.GetUserById(k);
        if(userinfo) then
            wabaonew_lib.send_owner_list(userinfo, map_id);    
        end
    end
end


--兑换奖品
function wabaonew_lib.on_recv_exchange(buf)
    --TraceError('on_recv_exchange');
    local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end

    if(wabaonew_lib.check_action(userinfo) == 0 or wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_TEX) then
        return;
    end

    local jiangjuan_type = buf:readInt();
    --TraceError("jiangjuan_type"..jiangjuan_type);
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local jiangjuan_key = "jiangjuan"..jiangjuan_type;
    local need_bean = wabaonew_lib.cfg_jiangjuans[jiangjuan_type].need_bean;
    local need_jiangjuan = wabaonew_lib.cfg_jiangjuans[jiangjuan_type].need_jiangjuan; 
    local chengzhang = wabaonew_lib.cfg_jiangjuans[jiangjuan_type].chengzhang;
    local vip_item = wabaonew_lib.cfg_jiangjuans[jiangjuan_type].vip_item;

	if user_wabao_info == nil or user_wabao_info["jiangjuan"..jiangjuan_type] == nil or user_wabao_info[jiangjuan_key] < need_jiangjuan then 
        wabaonew_lib.net_send_exchange_result(userinfo, -1, jiangjuan_type);
		return 
	end
	
	if userinfo.wealth.dzcash == nil or userinfo.wealth.dzcash < need_bean then 
        wabaonew_lib.net_send_exchange_result(userinfo, -2, jiangjuan_type, userinfo.wealth.dzcash);
		return 
    end

    --先扣卷和达人币
	usermgr.addcash(userinfo.userId, -need_bean, g_TransType.Buy, "", 1);      
	wabaonew_db_lib.add_jiangjuan(userinfo.userId, jiangjuan_type, -need_jiangjuan);
    user_wabao_info[jiangjuan_key] = user_wabao_info[jiangjuan_key] - need_jiangjuan;
    wabaonew_db_lib.add_exchange_record(userinfo.userId, jiangjuan_type);

    --加成长点
    local iteminfo = itemlib.items[vip_item];
    itemlib.do_give_gifts(userinfo, iteminfo);  
    itemlib.use_item(userinfo, vip_item);

    --[[
	if(new_viplib_db)then
    	xpcall(function() new_viplib_db.add_chengzhang_db(userinfo.userId, chengzhang) end,throw)
    end
    --]]

    wabaonew_lib.net_send_exchange_result(userinfo, 1, jiangjuan_type);
    if(jiangjuan_type == 4) then
        wabaonew_lib.send_chat(_U("玩家")..userinfo.nick.._U("兑换了"..wabaonew_lib.cfg_jiangjuans[jiangjuan_type].jiangjuan_name.."优惠券"));
    end
    wabaonew_lib.net_send_user_jiangjuan_info(userinfo, user_wabao_info);
    local add_list = {};
    table.insert(add_list, {
        jiangjuan_type = jiangjuan_type,
        id=os.time(),
    });
    wabaonew_lib.net_send_exchange_list(userinfo, add_list);
end

function wabaonew_lib.on_recv_contact(buf)
    --TraceError('on_recv_contact');
	local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end
	    
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local action = buf:readInt();
	local realname = buf:readString();
	local tel = buf:readString();
	local yy = buf:readInt();
	local address = buf:readString();
    if action == 1 then
        local gift_id = user_wabao_info.t_gift_id or user_wabao_info.gift_id;
        if(gift_id ~= nil and gift_id > 0) then
            wabaonew_db_lib.add_wabao_contact(userinfo.userId, gift_id, realname, yy, address, tel);
            user_wabao_info.t_gift_id = nil;
        end
    end

    wabaonew_lib.process_msg_queue(userinfo);
end

function wabaonew_lib.on_recv_get_gift(buf)
    --TraceError('on_recv_get_gift');
    local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end

    if(wabaonew_lib.check_game() == 0) then
        return;
    end

    local check_time, is_fajiang = wabaonew_lib.check_datetime();
	if(check_time == wabaonew_lib.STATIC_OVER and is_fajiang == 0) then 
		return
    end

    local action = buf:readInt();
    local gift_id = buf:readInt();
    local record_id = buf:readInt();
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local map_id = user_wabao_info.map_id;

    if(record_id == 0 and (user_wabao_info == nil or user_wabao_info.gift_id <= 0)) then
        wabaonew_lib.net_send_get_gift_result(userinfo, 0);
        return;
    end

    if(record_id == 0) then
        gift_id = user_wabao_info.gift_id;
    end
    local gift_cfg = {};
    if(wabaonew_lib.cfg_gift_list[map_id] ~= nil) then 
        gift_cfg = wabaonew_lib.cfg_gift_list[map_id][gift_id];
    end
--TraceError('record_id'..record_id);
    if(record_id == 0) then
        if(action == 0) then
            --TraceError('sb取消领奖');
            wabaonew_lib.reset_user_wabao_info(user_wabao_info);
            wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info);
        else
            if(gift_cfg and gift_cfg.is_qiang == 0) then
                wabaonew_lib.reset_user_wabao_info(user_wabao_info);
                wabaonew_lib.process_user_prize(userinfo, map_id, gift_id);
                wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info);

                if(gift_cfg.gift_type ~= 1 and gift_cfg.gift_type ~= 10) then
                    wabaonew_db_lib.add_wabao_record(map_id, userinfo.userId, userinfo.nick, gift_id, 1);
                    local add_list = {};
                    table.insert(add_list, {
                       user_id = userinfo.userId,
                       nick_name = userinfo.nick,
                       gift_id=gift_id,
                       id=os.time(),
                    }); 
                    wabaonew_lib.net_send_wabao_record(userinfo, add_list);
                end
            end
        end
    else
        --领取宝物
        wabaonew_db_lib.update_wabao_get_dajiang(record_id, userinfo.userId, function(data)
            if(data.result == 1) then
                map_id = data.map_id;
                gift_id = data.gift_id;
                user_wabao_info.t_gift_id = gift_id;
                gift_cfg = wabaonew_lib.cfg_gift_list[map_id][gift_id];
                if(gift_cfg.is_shiwu == 0) then
                    wabaonew_lib.process_user_prize(userinfo, map_id, gift_id);
                    wabaonew_lib.process_msg_queue(userinfo);
                else
                    wabaonew_lib.net_send_show_contact_panel(userinfo, gift_id, 1);
                end
            end
        end);
    end
end

function wabaonew_lib.on_recv_guess_password(buf)
    --TraceError('on_recv_guess_password');
    local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end
 
    if(wabaonew_lib.check_action(userinfo) == 0) then
        wabaonew_lib.net_send_guess_password_result(userinfo, 0);
        return;
    end

    local password = buf:readInt();
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local gift_id = user_wabao_info.gift_id;
    local map_id = user_wabao_info.map_id;
    local gift_cfg = wabaonew_lib.cfg_gift_list[map_id][gift_id];

    if(password == -1) then
        wabaonew_lib.reset_user_wabao_info(user_wabao_info);
        return;
    end

    --只有大奖才可以猜密码
    if(user_wabao_info == nil or gift_cfg == nil or gift_cfg.is_qiang == 0 or user_wabao_info.status ~= wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD or (user_wabao_info.doing ~= nil and user_wabao_info.doing == wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD)) then
        wabaonew_lib.net_send_guess_password_result(userinfo, 0);
        return;
    end

    if(user_wabao_info.guess_start_time + wabaonew_lib.STATIC_GUESS_TIMEOUT < os.time()) then
        --过期了
        wabaonew_lib.net_send_guess_password_result(userinfo, -1);
        return;
    end

    user_wabao_info.doing = wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD;

    wabaonew_db_lib.get_wabao_info(map_id, gift_id, function(gift_info)
        user_wabao_info.doing = nil;
        --密码为空的情况认为第一次猜的,获取系统密码
        if(gift_info.pwd ~= nil) then
            --TraceError("猜密码"..tostringex(gift_info));
            if(gift_info.pwd == password) then
                --猜对了
                user_wabao_info.status = wabaonew_lib.STATIC_WABAOED_SET_PASSWORD;
                if(gift_info.cur_user_id > 0) then 
                    user_wabao_info.gift_info = gift_info;
                end
                wabaonew_lib.net_send_show_password_panel(userinfo, wabaonew_lib.STATIC_WABAOED_SET_PASSWORD, user_wabao_info);
                wabaonew_lib.send_chat(_U("恭喜玩家")..userinfo.nick.._U("猜对了玩家")..gift_info.cur_nick_name.._U("的宝物密码,将夺走对方的宝物"));
            else
                if(password - gift_info.pwd > 5) then
                    wabaonew_lib.net_send_guess_password_result(userinfo, -1);
                elseif(password - gift_info.pwd <= 5 and password - gift_info.pwd >= -5) then
                    wabaonew_lib.net_send_guess_password_result(userinfo, -2);
                else
                    wabaonew_lib.net_send_guess_password_result(userinfo, -3);
                end
                
                wabaonew_lib.reset_user_wabao_info(user_wabao_info);
            end
        end
    end);
end

function wabaonew_lib.on_recv_set_password(buf)
    local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end

    if(wabaonew_lib.check_action(userinfo) == 0) then
        return;
    end

    local password = buf:readInt(); 
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local gift_id = user_wabao_info.gift_id;
    local map_id = user_wabao_info.map_id;
    local gift_info = user_wabao_info.gift_info;
    local gift_cfg = wabaonew_lib.cfg_gift_list[map_id][gift_id];

    if(password == -1) then
        wabaonew_lib.reset_user_wabao_info(user_wabao_info);
        return;
    end

    --只有大奖才可以猜密码
    if(user_wabao_info == nil or gift_cfg == nil or gift_cfg.is_qiang == 0 or user_wabao_info.status ~= wabaonew_lib.STATIC_WABAOED_SET_PASSWORD) then
        wabaonew_lib.net_send_set_password_result(userinfo, 0);
        return;
    end

    --查看宝物时间是否过期了
    local valid_time = wabaonew_lib.get_vaild_time(wabaonew_lib.STATIC_START_TIME, gift_cfg.dajiang_time, wabaonew_lib.STATIC_END_TIME, user_wabao_info.wabao_time);
    --TraceError('过期时间'..timelib.lua_to_db_time(valid_time));
    if(os.time() > valid_time) then
        --过期了
        wabaonew_lib.net_send_set_password_result(userinfo, -2);
        return;
    end

    local cur_user_id = gift_info ~= nil and gift_info.cur_user_id or userinfo.userId;
    local sys_time = gift_info ~= nil and gift_info.sys_time or timelib.lua_to_db_time(os.time());
    valid_time = wabaonew_lib.get_vaild_time(wabaonew_lib.STATIC_START_TIME, gift_cfg.dajiang_time, wabaonew_lib.STATIC_END_TIME, os.time());

    wabaonew_db_lib.set_wabao_password(valid_time, userinfo.userId, userinfo.nick, map_id, gift_id, password, cur_user_id, sys_time, function(data)
        if(data.result ~= nil) then
            if(data.result == 1) then
                --成功了
                wabaonew_lib.net_send_set_password_result(userinfo, 1);
                wabaonew_lib.send_chat(_U("玩家")..userinfo.nick.._U("为宝物")..gift_cfg.gift_name.._U("成功设置了密码,夺走了对方的宝物"));
                --刷新其它服务器的玩家拥有列表
                wabaonew_lib.refresh_wabao_info_to_all_ser(map_id);
            else
                --有人已经设置密码了
                wabaonew_lib.net_send_set_password_result(userinfo, -1, gift_id, data.cur_nick_name);
            end
        else
            --数据库没有响应
            wabaonew_lib.net_send_set_password_result(userinfo, 0);
        end
    end);
    wabaonew_lib.reset_user_wabao_info(user_wabao_info);
    wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info);
end

--请求活动时间状态
function wabaonew_lib.on_recv_activity_stat(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if(userinfo == nil)then return end

	--游戏类型验证
    if(wabaonew_lib.check_game() == 0) then
        return;
    end

	--检查时间有效性
	local check_time, is_fajiang = wabaonew_lib.check_datetime();
	if(check_time == wabaonew_lib.STATIC_OVER and is_fajiang == 0) then 
		return
	end 
	 
 	--通知客户端
    if(check_time == wabaonew_lib.STATIC_OVER and is_fajiang == 1) then
        wabaonew_lib.net_send_activity_stat(userinfo, wabaonew_lib.STATIC_FAJIANG);
    else
        wabaonew_lib.net_send_activity_stat(userinfo, wabaonew_lib.STATIC_ACTIVED);
    end
    wabaonew_lib.net_send_wabao_cfg(userinfo);
    wabaonew_lib.process_msg_queue(userinfo);
end


--请求打开活动面板
function wabaonew_lib.on_recv_open_wnd(buf)

	--游戏类型验证
    if(wabaonew_lib.check_game() == 0) then
        return;
    end
    
	local userinfo = userlist[getuserid(buf)];	
   	if not userinfo then return end;

   	--检查时间有效性
	local check_time = wabaonew_lib.check_datetime()
    if(check_time == wabaonew_lib.STATIC_OVER) then
        return;
    end

    local map_id = buf:readInt();
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    --TraceError(user_wabao_info.map_id);
    if(user_wabao_info ~= nil and (map_id == 0 or user_wabao_info.map_id == 0 or map_id == user_wabao_info.map_id)) then
        if(map_id == 0) then
            map_id = user_wabao_info.map_id > 0 and user_wabao_info.map_id or 1;
        end

        user_wabao_info.cur_map_id = map_id;
        wabaonew_lib.net_send_user_wabao_info(userinfo, map_id, user_wabao_info, 1);
        wabaonew_lib.send_owner_list(userinfo, map_id);
        wabaonew_lib.send_wabao_record(userinfo, map_id);

        if(user_wabao_info.status == wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD) then
            if(user_wabao_info.guess_start_time == nil or user_wabao_info.guess_start_time == 0) then
                user_wabao_info.guess_start_time = os.time();
            end
            wabaonew_lib.net_send_show_password_panel(userinfo, wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD, user_wabao_info);
        elseif user_wabao_info.status == wabaonew_lib.STATIC_WABAOED_SET_PASSWORD then
            wabaonew_lib.net_send_show_password_panel(userinfo, wabaonew_lib.STATIC_WABAOED_SET_PASSWORD, user_wabao_info);
        end
        --wabaonew_lib.net_send_user_jiangjuan_info(userinfo, user_wabao_info);
    else
        netlib.send(function(buf)
            buf:writeString("WBNOTAB");
        end, userinfo.ip, userinfo.port);
        --TraceError('not open wnd');
    end
end

--收到抽奖了
function wabaonew_lib.on_recv_choujiang(buf)
    --TraceError('on_recv_choujiang');
    local userinfo = userlist[getuserid(buf)];	
   	if not userinfo then return end;

    if(wabaonew_lib.check_action(userinfo) == 0) then
        return;
    end

    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    local map_id = buf:readInt();
    local result = 0;
    local gift_cfg = wabaonew_lib.cfg_gift_list[map_id];

    if(user_wabao_info.map_id ~= map_id or gift_cfg == nil) then
        --在哪个地图挖宝?
        result = -2; 
        wabaonew_lib.net_send_choujiang_result(userinfo, result);
        return;
    end

    if(#user_wabao_info.gift_list <= 0 or #user_wabao_info.gift_list ~= wabaonew_lib.STATIC_WABAO_GIFT_NUM) then
        --还没有挖宝吧
        result = -3;
        wabaonew_lib.net_send_choujiang_result(userinfo, result);
        return;
    end

    if(user_wabao_info.gift_id > 0) then
        --已经抽奖了，未领取
        result = 1;
        wabaonew_lib.net_send_choujiang_result(userinfo, result, user_wabao_info.gift_id);
        return;
    end

    if(user_wabao_info.doing ~= nil and user_wabao_info.doing == wabaonew_lib.STATIC_WABAOED) then
        return;
    end

    --生成礼包概率
    local has_baowu_list = {};
    if(wabaonew_lib.owner_list[map_id] ~= nil and #wabaonew_lib.owner_list[map_id] > 0) then
        for k, v in pairs(wabaonew_lib.owner_list[map_id]) do
            if(v.cur_user_id == userinfo.userId) then
                --已经拥有大奖了
                has_baowu_list[v.gift_id] = 1; 
            end
        end
    end

    local gift_list = {};
    local total_rate = 0;
    for k, v in pairs(user_wabao_info.gift_list) do
        local cfg = gift_cfg[v];
        if(has_baowu_list[v] == nil and (cfg.is_qiang == 0 or wabaonew_lib.check_map_over(map_id, os.time() + 1) == 0)) then
            total_rate = total_rate + cfg.gift_rate;
        end
    end
    
    --TraceError('has_baowu_list'..tostringex(has_baowu_list));

    local pre_rate = 0;
    for k, v in pairs(user_wabao_info.gift_list) do 
        local cfg = gift_cfg[v];
        local gift_rate = math.ceil(cfg.gift_rate/total_rate * 10000) +  pre_rate;
        if(has_baowu_list[v] ~= nil or (cfg.is_qiang == 1 and wabaonew_lib.check_map_over(map_id, os.time() + 1) == 1)) then
            gift_rate = 0;
        else
            pre_rate = gift_rate;
        end
        table.insert(gift_list, {gift_id=v, gift_rate=gift_rate});
    end

    user_wabao_info.doing = wabaonew_lib.STATIC_WABAOED;

    wabaonew_db_lib.choujiang(wabaonew_lib.STATIC_START_TIME, wabaonew_lib.STATIC_END_TIME, userinfo.userId, map_id, gift_list, function(dt)

        --TraceError("choujiang gift"..tostringex(dt));
        user_wabao_info.doing = nil;
        --test 实物大奖
        if(dt.gift_id ~= nil and dt.gift_id > 0) then
            user_wabao_info.gift_id = dt.gift_id;

            local gift_cfg = wabaonew_lib.cfg_gift_list[map_id][dt.gift_id];
            if(gift_cfg.is_qiang == 1) then
                --显示密码框
                wabaonew_lib.net_send_choujiang_result(userinfo, 2, dt.gift_id);
                user_wabao_info.status = wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD;

                timelib.createplan(function()
                    if(user_wabao_info.guess_start_time == nil or user_wabao_info.guess_start_time == 0) then
                        user_wabao_info.guess_start_time = os.time();
                    end

                    --通知打开猜密码的对话框
                    wabaonew_lib.net_send_show_password_panel(userinfo, wabaonew_lib.STATIC_WABAOED_GUESS_PASSWORD, user_wabao_info);
                end, 4)
            else
                wabaonew_lib.net_send_choujiang_result(userinfo, 1, dt.gift_id);
                timelib.createplan(function()
                    if(gift_cfg.gift_type ~= 1 and gift_cfg.gift_type ~= 10) then 
                        wabaonew_lib.send_chat(_U("恭喜玩家")..userinfo.nick.._U("在"..wabaonew_lib.cfg_maps[map_id].name.."挖到奖品")..gift_cfg.gift_name);
                    end
                end, 4)
            end
        else
            wabaonew_lib.net_send_choujiang_result(userinfo, 0, 0);
        end
        --wabaonew_lib.net_send_show_contact_panel(userinfo, dt.gift_id);
    end); 
end

--请求购买
function wabaonew_lib.on_recv_buy_shovel(buf) 
    --TraceError('on_recv_buy_shovel');
	local userinfo = userlist[getuserid(buf)];	
   	if not userinfo then return end;

    if(wabaonew_lib.check_action(userinfo) == 0) then
        return;
    end
   
   	--收到购买id
    local map_id = buf:readInt();
    local shovel_num = buf:readInt();
    --TraceError('map_id'..map_id.." shovel_num"..shovel_num);
 	local result = 0
    local gold = get_canuse_gold(userinfo)--获得用户筹码
    local map_cfg = wabaonew_lib.cfg_maps[map_id];
    local shovel_price = map_cfg["shovel_prices"][shovel_num];
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    if(map_cfg == nil or shovel_price == nil or shovel_price <= 0 or user_wabao_info == nil) then
        result = -4;
		wabaonew_lib.net_send_buy_result(userinfo, result)
        return;
    end

 	--德州
 	if(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_TEX)then
        local retcode = 0;
        if(userinfo.desk and userinfo.site) then
            local deskdata = deskmgr.getdeskdata(userinfo.desk);
            local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site);
            retcode = dobuygift1(userinfo, deskdata, sitedata, 0, shovel_price);
            --购买成功
        else
            retcode = dobuygift2(userinfo, 0, shovel_price);
        end
	 	--判断是否有钱
        if(retcode == 1) then
            result = 1;
            user_wabao_info.shovel_num = user_wabao_info.shovel_num + shovel_num;
            wabaonew_db_lib.add_user_shovel_num(userinfo.userId, shovel_num, user_wabao_info.shovel_num);
            wabaonew_lib.net_send_refresh_shovel(userinfo, user_wabao_info);
        elseif(retcode == 2) then
            result = -1;
        end
        wabaonew_lib.net_send_buy_result(userinfo, result);
    elseif(wabaonew_lib.cfg_games[gamepkg.name] == wabaonew_lib.STATIC_GAME_QP)then
        --TraceError('step 2');
        if(userinfo.site == nil) then
            if(gold >= shovel_price) then
                --TraceError("success");
                result = 1
                --给用户加铲子
                usermgr.addgold(userinfo.userId, -shovel_price, 0, new_gold_type.WABAONEW_BUY_SHOVEL, -1);
                user_wabao_info.shovel_num = user_wabao_info.shovel_num + shovel_num;
                wabaonew_db_lib.add_user_shovel_num(userinfo.userId, shovel_num, user_wabao_info.shovel_num);
                wabaonew_lib.net_send_refresh_shovel(userinfo, user_wabao_info);
            else
                result = -1;
            end
        else
            result = -3;
        end
        wabaonew_lib.net_send_buy_result(userinfo, result);
    end
end
 
--发送购买结果
function wabaonew_lib.net_send_buy_result(userinfo, result)
	netlib.send(function(buf)
            buf:writeString("WBCHANZI");
            buf:writeInt(result);		---1，购买失败，金币不足；1，购买成功；-2，购买失败，活动已过期；-3，购买失败，其它原因；
    end, userinfo.ip, userinfo.port);
end

function wabaonew_lib.on_recv_youhui_panel(buf)
    local userinfo = userlist[getuserid(buf)]; 
    local user_wabao_info = wabaonew_lib.user_list[userinfo.userId];
    wabaonew_lib.net_send_user_jiangjuan_info(userinfo, user_wabao_info);


    wabaonew_db_lib.get_exchange_list(userinfo.userId, function(dt)
        wabaonew_lib.net_send_exchange_list(userinfo, dt);
    end);
end
--协议命令
cmd_tex_match_handler = 
{ 
    ["WBACTIVED"] = wabaonew_lib.on_recv_activity_stat,  --请求活动时间状态
    ["WBOPPN"] = wabaonew_lib.on_recv_open_wnd,          --请求打开活动面板 
    ["WBZNPN"] = wabaonew_lib.on_recv_choujiang,         --请求抽奖
    ["WBJIEMM"] = wabaonew_lib.on_recv_guess_password,      --猜密码
    ["WBSHEMM"] = wabaonew_lib.on_recv_set_password,        --设置密码
    ["WBWABAO"] = wabaonew_lib.on_recv_wabao,            --请求挖宝
    ["WBCHANZI"] = wabaonew_lib.on_recv_buy_shovel,      --请求购买铲子
    ["WBGETPZ"]  = wabaonew_lib.on_recv_get_gift,         --请求获取奖品
    ["WBDJSW"]   = wabaonew_lib.on_recv_contact,          --填写联系人
    ["WBCHANGE"] = wabaonew_lib.on_recv_exchange,          --兑换优惠券
    ["WBYOUHUI"] = wabaonew_lib.on_recv_youhui_panel, --打开优惠面板

    ["GS_WBRFOWNER"] = wabaonew_lib.on_recv_gs_refresh_owner_list, --收到刷新用户者列表
    ["GS_WBNTPRIZE"] = wabaonew_lib.on_recv_gs_notify_get_gift,    --通知玩家获取礼物
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", wabaonew_lib.on_after_user_login); 
eventmgr:addEventListener("on_server_start", wabaonew_lib.on_server_start);
eventmgr:addEventListener("timer_second", wabaonew_lib.on_timer_second);
eventmgr:addEventListener("on_user_exit", wabaonew_lib.on_user_exit);
