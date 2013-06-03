------------------------------------事件移除----------------------------------------
if matches_taotai_lib and matches_taotai_lib.on_game_over then
	eventmgr:removeEventListener("game_event", matches_taotai_lib.on_game_over)
end
if matches_taotai_lib and matches_taotai_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", matches_taotai_lib.on_after_user_login)
end
if matches_taotai_lib and matches_taotai_lib.on_timer_second then
	eventmgr:removeEventListener("timer_second", matches_taotai_lib.on_timer_second)
end

if matches_taotai_lib and matches_taotai_lib.on_user_exit then
	eventmgr:removeEventListener("do_kick_user_event", matches_taotai_lib.on_user_exit)
end

if matches_taotai_lib and matches_taotai_lib.on_user_exit then
	eventmgr:removeEventListener("before_kick_sub_user", matches_taotai_lib.on_user_exit)
end

if matches_taotai_lib and matches_taotai_lib.on_server_start then
	eventmgr:removeEventListener("on_server_start", matches_taotai_lib.on_server_start)
end

if matches_taotai_lib and matches_taotai_lib.on_watch_event then
    eventmgr:removeEventListener("on_watch_event", matches_taotai_lib.on_watch_event);
end

if matches_taotai_lib and matches_taotai_lib.on_back_to_hall then
    eventmgr:removeEventListener("back_to_hall", matches_taotai_lib.on_back_to_hall);
end

if matches_taotai_lib and matches_taotai_lib.on_user_exit then
    eventmgr:removeEventListener("on_sub_user_back_to_hall", matches_taotai_lib.on_user_exit);
end

if matches_taotai_lib and matches_taotai_lib.on_parent_user_add_watch then
    eventmgr:removeEventListener("on_parent_user_add_watch", matches_taotai_lib.on_parent_user_add_watch);
end
--[[
if matches_taotai_lib and matches_taotai_lib.on_user_queue then
    eventmgr:removeEventListener("on_user_queue", matches_taotai_lib.on_user_queue)
end
--]]


--------------------------------------------------------------------------------------

--新的比赛场
if not matches_taotai_lib then
matches_taotai_lib = 
{
-----------------------------公开接口------------------------
    get_user_match_info = NULL_FUNC,--获取用户比赛信息 
    get_match_list = NULL_FUNC,--获取比赛用户列表
    get_match_user_count = NULL_FUNC,--获取当前比赛的人数
    get_current_match_id = NULL_FUNC,--获取当前正在报名的比赛id
    process_give_up      = NULL_FUNC,--中途放弃比赛

-------------------------------网络发送-------------------------------
    net_send_match_all_rank_list = NULL_FUNC,--发送排名列表
    net_send_match_rank_list = NULL_FUNC,--发送排名列表
    net_send_match_change_taotai_jifen = NULL_FUNC,--发送淘汰分改边了
    net_send_match_result = NULL_FUNC,--发送给玩家每一盘的结果
    net_send_match_all_begin = NULL_FUNC,--发送给所有玩家自动排队，提示进入下一轮比赛
    net_send_match_prize = NULL_FUNC,--发送比赛奖励
    net_send_match_user_info = NULL_FUNC,--发送个人信息
    net_send_match_msg = NULL_FUNC,--发送播报
    net_send_match_user_taotai = NULL_FUNC,--用户被淘汰


--------------------------------网络收发----------------------------------------

    on_recv_match_info = NULL_FUNC,--收到获取比赛信息
    on_recv_match_join = NULL_FUNC,--收到自动排队请求
    on_recv_match_baoming_check = NULL_FUNC,--收到报名检测
    on_recv_commonsvr_match_config = NULL_FUNC,--收到gs发过来的比赛配置
    on_recv_commonsvr_match_online = NULL_FUNC,--收到gs发过来的比赛在线情况

-----------------------------内部接口--------------------------------
    set_match_user_wait = NULL_FUNC,--设置用户等待
    set_match_user_taotai = NULL_FUNC,--设置用户被淘汰
    init_match_config = NULL_FUNC,--初始化比赛配置
    count_still_playing_desks = NULL_FUNC,--计算还有多少张台没有打完
    end_first_match = NULL_FUNC,--结束初赛
    end_second_match = NULL_FUNC,--结束决赛
    process_taotai = NULL_FUNC, --处理淘汰函数
    send_desk_match_chat = NULL_FUNC,--发送聊天比赛信息
    process_rank_list = NULL_FUNC,--对玩家进行排名
    give_user_prize = NULL_FUNC, --给玩家发奖
    check_match_room = NULL_FUNC,--检查是否比赛房间
    update_match_to_commonsrv = NULL_FUNC,--更新比赛信息到公共服务器
   
---------系统事件----------------------------------------------
    on_after_user_login = NULL_FUNC,            --登录事件
    on_game_over = NULL_FUNC,                   --结算事件
    on_timer_second = NULL_FUNC,                --倒计时处理
    on_user_exit = NULL_FUNC,                   --用户退出
    on_server_start = NULL_FUNC,                --游戏启动    
    on_parent_user_add_watch = NULL_FUNC,       --多开切换
-----------------------------------系统调用接口----------------------------  
    g_on_game_start = NULL_FUNC,                 --游戏开始
    g_can_enter_game  = NULL_FUNC,               --是否可以进入游戏
    g_check_match_room = NULL_FUNC,
    try_start_match = NULL_FUNC,            --获取比赛用户的列表
------------------------发送到客户端的协议函数----------------------------------------
    --用户比赛信息
    user_list = {
    },

    --全局变量
    match_list = {
    },

    --用户断线后比赛结果
    user_offline_list = {
        
    },

    commonsrv_match_list = {
    },

    refresh_rank_list = {
    },

    --可配置参数,具体请看config_for_yunyin.lua
    OP_BAOMING_SAIBI = {},
    OP_MATCH_PRIZE = {},
    OP_CHANGE_MATCH_BASE_RATE_TIME = {},
    OP_FIRST_MATCH_BASE_JIFEN = {},
    OP_FIRST_MATCH_BASE_RATE = {},
    OP_FIRST_MATCH_END_COUNT = {},
    OP_FIRST_MATCH_END_JIFEN_RATE = {},
    OP_FIRST_MATCH_END_MATCH_COUNT = {},
    OP_FIRST_MATCH_INC_RATE = {},
    OP_MATCH_START_COUNT={},
    OP_MATCH_TAOTAI_RATE={},
    OP_SECOND_MATCH_END_JIFEN_RATE = {},
    OP_SECOND_MATCH_END_MATCH_COUNT={},
    OP_SECOND_MATCH_BASE_RATE = {},
    OP_MATCH_NAMES = {},
    OP_JINJI_TIMEOUT = {},
    OP_WIN_ADD_MATCH_EXP = {},
    init_config = function()
        local peilv_arr = {1000};
        for k, v in pairs(peilv_arr) do
            if(matches_taotai_lib.OP_MATCH_PRIZE[v] == nil) then
                matches_taotai_lib.OP_SECOND_MATCH_END_MATCH_COUNT[v] = {};
                matches_taotai_lib.OP_MATCH_NAMES[v] = {};
                matches_taotai_lib.OP_MATCH_PRIZE[v] = {};
    
                for i=1, 30 do 
                    --初始化30名的奖品结构
                    matches_taotai_lib.OP_MATCH_PRIZE[v][i] = {};
                end
            end
        end
    end,

    --内部调用变量
    CONFIG_BAOMING_SAIBI = 0,
    CONFIG_CHANGE_MATCH_BASE_RATE_TIME = 999999999,
    CONFIG_FIRST_MATCH_BASE_JIFEN = 5000,
    CONFIG_FIRST_MATCH_BASE_RATE = 0,
    CONFIG_FIRST_MATCH_END_COUNT = 1,
    CONFIG_FIRST_MATCH_END_JIFEN_RATE = 1,
    CONFIG_FIRST_MATCH_END_MATCH_COUNT = 1,
    CONFIG_FIRST_MATCH_INC_RATE = 0,
    CONFIG_MATCH_START_COUNT=48,
    CONFIG_MATCH_TAOTAI_RATE=0,
    CONFIG_SECOND_MATCH_END_JIFEN_RATE = 1,
    CONFIG_SECOND_MATCH_END_MATCH_COUNT={},
    CONFIG_MATCH_NAMES={},
    CONFIG_SECOND_MATCH_BASE_RATE = 0,
    CONFIG_MATCH_PRIZE={},
    CONFIG_JINJI_TIMEOUT = 5,
    CONFIG_WIN_ADD_MATCH_EXP = 1,
}
end

------------------------------------公开函数--------------------------------

matches_taotai_lib.log_user_match_record = function(user_id, result)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    if(user_match_info.match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
        local rank = 0;
        for k, v in pairs(list.rank_list) do
            if(v.userId == user_id) then
                rank = k;
                break;
            end
        end
        local sql = "insert into log_taotai_match(user_id, match_id, match_result, match_status, panshu, rank, sys_time, group_id, jifen) values(%d, %s, %d, %d, %d, %d, NOW(), %d, %d);commit;";
        if(duokai_lib and duokai_lib.is_sub_user(user_id) == 1) then
            user_id = duokai_lib.get_parent_id(user_id);
        end
        sql = string.format(sql, user_id, dblib.tosqlstr(user_match_info.match_id), result or 0, list.match_info.status, user_match_info.panshu, rank, tonumber(groupinfo.groupid), user_match_info.jifen);
        dblib.execute(sql);
    end
end

matches_taotai_lib.get_current_match_id = function()
    return table.maxn(matches_taotai_lib.match_list); 
end

--[[
@desc 获取用户比赛信息
@param user_id 用户id 
--]]
matches_taotai_lib.get_user_match_info = function(user_id) 
    local user_match_info = {
        match_id=nil,--比赛id
        jifen=0,--积分
        begin_time=0,--比赛报名或者排队时间
        user_id=user_id,--用户id
        panshu=0,--用户盘数
        first_jifen = 0,--预赛积分
        --nRegSiteNo = 0,--用户regsite
        notify_continue = 0,--通知用户是否继续玩
    };
    if(matches_taotai_lib.user_list[user_id] ~= nil) then
        user_match_info = matches_taotai_lib.user_list[user_id];
    else
        matches_taotai_lib.user_list[user_id] = user_match_info;
    end
    return user_match_info;
end

matches_taotai_lib.remove_wait_list = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    if(user_match_info.match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
        if(list.wait_list[user_id] ~= nil) then
            list.wait_list[user_id] = nil;
        end
    end
end

--[[
@desc 获取比赛列表
@param match_id 比赛组id
--]]
matches_taotai_lib.get_match_list = function(match_id) 
    local match_list = {
        match_list = {},--比赛中的用户
        taotai_list = {},--已经淘汰的用户
        taotai_desk_list = {},--桌子上淘汰的用户
        wait_list = {},--等待中的用户
        rank_list = {},--比赛排名列表
        play_list = {},--正在打牌的用户
        match_info = {
            status = 0,--比赛状态,0未开始,1:初赛,2:决赛, 3:决赛第2轮 4:决赛第3轮 5:决赛第4轮
            base_rate = matches_taotai_lib.CONFIG_FIRST_MATCH_BASE_RATE,--游戏基数
            taotai_jifen = matches_taotai_lib.CONFIG_FIRST_MATCH_BASE_RATE * matches_taotai_lib.CONFIG_MATCH_TAOTAI_RATE,--比赛淘汰积分
            begin_time = 0,--比赛开始时间
            panshu= 0,--每一轮盘数统计
            change_base_rate_time=0,--预赛基础数改变时间
            finish_taotai_time=0,--通知完成淘汰时间
            end_time = 0,--这一轮结束时间,
            unfinished_desk = {},--没有结算的桌子
            match_count = 0,--比赛人数
            notify_wait_next = 0,
        },
    };

    if(matches_taotai_lib.match_list[match_id] ~= nil) then
        match_list = matches_taotai_lib.match_list[match_id];
    else
        matches_taotai_lib.match_list[match_id] = match_list;
    end

    return match_list;
end

-----------------------------------网络收发--------------------------------------------------------

matches_taotai_lib.on_recv_match_baoming_check = function(buf) 
     --TraceError('on_recv_match_baoming_check');
    local user_info = userlist[getuserid(buf)];
    if(not user_info) then return end;
    local groupid = buf:readInt();
    local code = 1;
    local sendFunc = function(buf)
        buf:writeString('MATCHTTBMC');
        buf:writeInt(code);
    end
    if matcheslib.user_list[user_info.userId] ~= nil and matches_taotai_lib.commonsrv_match_list[groupid] ~= nil and matcheslib.user_list[user_info.userId].match_gold  < matches_taotai_lib.commonsrv_match_list[groupid].baoming_saibi then
        code = 0;
    end
    netlib.send(sendFunc, user_info.ip, user_info.port);
end

matches_taotai_lib.process_give_up = function(user_id)
    local user_info = usermgr.GetUserById(user_id);
    if(user_info ~= nil) then
        user_info.last_open_match_rank_time = nil;
    end
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    if(user_match_info.match_id ~= nil) then
        local match_id = user_match_info.match_id;
        local list = matches_taotai_lib.get_match_list(match_id);
        if(list.match_info.status == 0 and list.match_list[user_id] ~= nil) then
            --比赛未开始,可以退赛
            
            matches_taotai_lib.log_user_match_record(user_id, -3);
            user_match_info.match_id = nil;
            list.match_list[user_id] = nil;
            list.wait_list[user_id] = nil;
            --matcheslib.l_add_user_match_gold_db(user_info,matches_taotai_lib.CONFIG_BAOMING_SAIBI,matcheslib.STATIC_ADD_GOLD_TYPE_TAOTAI_GIVEUP,0);
            --matches_db.record_back_match_gold(user_id, matches_taotai_lib.CONFIG_BAOMING_SAIBI);
            
            matches_taotai_lib.process_rank_list(match_id);
            --matches_taotai_lib.update_match_to_commonsrv(user_match_info, match_id);
	        user_match_info.match_id = nil;
            matches_taotai_lib.net_send_match_all_rank_list(match_id);
        elseif(list.match_info.status > 0) then
            matches_taotai_lib.set_match_user_taotai(match_id, user_id);
            matches_taotai_lib.check_match_end(match_id);
            matches_taotai_lib.net_send_match_all_rank_list(match_id);
        end
    end
end

matches_taotai_lib.on_recv_match_info = function(buf) 
    --TraceError('on_recv_match_info');
    local user_info = userlist[getuserid(buf)];
    if(not user_info) then return end;
    local groupid  = buf:readInt();
    local match_info = matches_taotai_lib.commonsrv_match_list[groupid];

    netlib.send(function(buf)
        buf:writeString("MATCHTTINFO");
        buf:writeInt(groupid);
        buf:writeString(_U(match_info.groupname));
        buf:writeInt(match_info.match_start_count);
        buf:writeInt(match_info.start_time);
        buf:writeInt(match_info.end_time);
        buf:writeInt(match_info.baoming_count or 0);
        buf:writeInt(match_info.total_user_count or 0);
        buf:writeInt(1);
        buf:writeString(_U(match_info.baoming_saibi..'赛币'));
        buf:writeInt(#match_info.prize_list);
        for k, v in pairs(match_info.prize_list) do
            buf:writeInt(k);
            buf:writeInt(v[1].prize_value);
        end
    end, user_info.ip, user_info.port);
end

--[[
matches_taotai_lib.auto_join_desk = function(match_user_list)
    --获取用户当前比赛的所有等待比赛参赛者
    if(table.maxn(match_user_list) > 0) then
        --找到需要排队的玩家
        local join_list = {};
        for k, v in pairs(match_user_list) do
            local user_info = usermgr.GetUserById(k);
            if(user_info) then
                if(user_info.desk ~= nil and user_info.desk > 0 and 
                   user_info.site ~= nil and user_info.site > 0) then
                       --判断房间开始了没有
                       local state = hall.desk.get_site_state(user_info.desk, user_info.site);
                       if(state ~= SITE_STATE.PLAYING) then
                           table.insert(join_list, k);
                       else
                           TraceError("who??"..k.." "..tostringex(match_user_list));
                       end
                else
                    table.insert(join_list, k);
                end
            else
                --用户离线了
                match_user_list[k] = nil; 
                matches_taotai_lib.remove_wait_list(k);
            end
        end

        if(#join_list > 2) then
            for k, v in pairs(desklist) do
                if(#join_list < 3) then
                    break;
                end
                local nstart = false; 
                local execok, ret = xpcall(function() return gamepkg.getGameStart(k); 
                                    end, throw);
				if execok then
					nstart = ret
                end

                if(nstart == false) then
                    --检查三个都为空桌子的坐下去
                    local can_join = 1;
                    for i=1, room.cfg.DeskSiteCount do
                        if (desklist[k].site[i].user ~= nil) then
                            can_join = 0; 
                        end
                    end
                    --安排三个人坐进去
                    if(can_join == 1) then
                        --TraceError('找到桌子了'..k);
                        for i=1, room.cfg.DeskSiteCount do
                            local user_id = join_list[1];
                            local user_info = usermgr.GetUserById(user_id);
                            local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
                            user_match_info.notify_continue = 0;
                            match_user_list[user_id] = nil; 
                            matches_taotai_lib.remove_wait_list(user_id);
                            matches_taotai_lib.set_match_user_play(user_id);
                            table.remove(join_list, 1);
                            if(user_info) then
                                --坐下
                                --TraceError('坐下'..user_info.userId);
                                ResetUser(user_info.key, true);
                                doSitdown(user_info.key, user_info.ip, user_info.port, k, i);
                            end
                        end
                    end
                end
            end
        end
    end
end
--]]

matches_taotai_lib.is_taotai = function(match_id, user_id)
    local match_list = matches_taotai_lib.get_match_list(match_id);
    local ret = 0;
    if(match_list.taotai_list[user_id] ~= nil) then
        ret = 1;
    end
    return ret;
end

matches_taotai_lib.on_recv_match_join = function(buf)
    local user_info = userlist[getuserid(buf)];
    if(not user_info) then return end;
    --TraceError('on_recv_match_join'..user_info.userId);
    local action = buf:readInt();
    if(action == 1) then
        --TraceError("没有叫地主");
    end

    --自动报名 
    matches_taotai_lib.on_user_queue(user_info.userId);
    
    --自动加入牌桌
    local match_user_list = matches_taotai_lib.try_start_match(user_info.userId, action);
    --TraceError(match_user_list);
    --[[
    if(match_user_list[user_info.userId] ~= nil) then
        matches_taotai_lib.auto_join_desk(match_user_list);
    end
    --]]
end

matches_taotai_lib.on_recv_commonsvr_match_online = function(buf)
    if(gamepkg.name ~= "commonsvr" and groupinfo.match_type ~= 2) then
        return;
    end
    local groupid = buf:readInt();
    local total_user_count = buf:readInt();
    local baoming_count = buf:readInt();
    if(matches_taotai_lib.commonsrv_match_list[groupid] == nil) then
        return;
    end
    matches_taotai_lib.commonsrv_match_list[groupid].total_user_count = total_user_count;
    matches_taotai_lib.commonsrv_match_list[groupid].baoming_count = baoming_count;
end

matches_taotai_lib.on_recv_commonsvr_match_config = function(buf)
    if(gamepkg.name ~= "commonsvr" and groupinfo.match_type ~= 2) then
        return;
    end
    --TraceError("收到gs发来的比赛配置");
    local groupid = buf:readInt();
    local groupname = buf:readString();
    local match_start_count = buf:readInt();
    local baoming_saibi = buf:readInt();
    local start_time = buf:readInt(); 
    local end_time = buf:readInt();
    local len = buf:readInt();
    local prize_list = {};
    local rank = 0;
    local prize_value = 0;
    local prize_type = 0;
    local prize_name = 0;
    for i=1, len do
        rank  = buf:readInt();
        local len2 = buf:readInt();
        prize_list[rank] = {};
        for i=1, len2 do
            prize_value = buf:readInt();
            prize_type = buf:readInt();
            prize_name = buf:readString();
            table.insert(prize_list[rank],{
                prize_value=prize_value,
                prize_type=prize_type,
                prize_name=prize_name});
        end
    end

    matches_taotai_lib.commonsrv_match_list[groupid] = {
        groupname=groupname,
        match_start_count=match_start_count,
        baoming_saibi=baoming_saibi,
        start_time=start_time,
        end_time=end_time,
        prize_list=prize_list,
    };
end

-----------------------------------网络发送--------------------------------------------------

matches_taotai_lib.net_send_match_condition = function(user_info)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
    if(user_match_info.match_id ~= nil) then
        local match_info = matcheslib.get_match_info(user_match_info.match_id);
        if(match_info ~= nil) then
            --TraceError('net_send_match_condition');
            netlib.send(function(buf)
                buf:writeString("MATCHTTCO");
                buf:writeString(user_match_info.match_id);
                buf:writeString(match_info.match_name or "");
            end, user_info.ip, user_info.port);
        end
    end
end

matches_taotai_lib.net_send_match_user_taotai = function(user_info, rank, is_over, match_count, match_name)
    if(rank <= 2) then
        is_over = 1;
    end
    --进行排名
    if(user_info) then
        netlib.send(function(buf)
            buf:writeString("MATCHTTTT");
            buf:writeInt(rank);
            buf:writeByte(is_over or 0);
            buf:writeInt(match_count or 0);
            buf:writeString(match_name or "");
        end, user_info.ip, user_info.port);
    end
end

--[[
@desc 发送播报
@param user_id 用户id
@param msg_type 播报类型 1:出局人数已满，本剧结束后将等待其它桌。。。
]]--
matches_taotai_lib.net_send_match_msg = function(user_id, msg_type)
    local user_info = usermgr.GetUserById(user_id);
    if(user_info) then
        netlib.send(function(buf)
            buf:writeString("MATCHTTBB");
            buf:writeInt(msg_type);
        end, user_info.ip, user_info.port);
    end
end

matches_taotai_lib.net_send_back_match_gold = function(user_info, back_match_gold)
    netlib.send(function(buf)
        buf:writeString("MATCHTTBMG");
        buf:writeInt(back_match_gold);
    end, user_info.ip, user_info.port)
end


matches_taotai_lib.net_send_match_user_info = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local user_info = usermgr.GetUserById(user_id);
    if(user_match_info.match_id ~= nil and user_info) then
        netlib.send(function(buf)
            buf:writeString("MATCHTTMYINFO");
            buf:writeInt(user_match_info.jifen);
            buf:writeInt(user_match_info.panshu);
            buf:writeInt(user_match_info.first_jifen);
        end, user_info.ip, user_info.port);
    end
end

matches_taotai_lib.net_send_match_prize = function(user_info, rank, prize_list, begin_time, is_over, match_count, match_name)
    if(user_info) then
        netlib.send(function(buf)
            buf:writeString("MATCHTTGP");
            buf:writeInt(rank);
            buf:writeInt(#prize_list);
            for k, v in pairs(prize_list) do
                buf:writeInt(v.prize_type);
                buf:writeInt(v.prize_value);
            end
            buf:writeInt(begin_time);
            buf:writeByte(is_over or 0);
            buf:writeInt(match_count or 0);
            buf:writeString(match_name or "");
        end, user_info.ip, user_info.port);
    end
end

--[[
@desc 发送让所有用户进入下一轮比赛
@param match_id 比赛id
]]--
matches_taotai_lib.net_send_match_all_begin = function(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    for k, v in pairs(list.match_list) do
       matches_taotai_lib.net_send_match_result(k, (list.match_info.status == 1 and 3 or 4), matches_taotai_lib.CONFIG_JINJI_TIMEOUT);
    end
end

--[[
@desc 发送每一盘比赛的结果
@user_info 用户信息
@result 结果, 1:让玩家等待比赛结果 2：让玩家自动排队 3:让玩家自动排队并且提示用户晋级了,比赛马上开始
]]--
matches_taotai_lib.net_send_match_result = function(user_id, result, timeout, unfinished_count, show_timeout)
    local user_info = usermgr.GetUserById(user_id);
    if(user_info) then 
        --倒计时开赛
        local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
        if(user_match_info.match_id == nil) then
            return;
        end
        local match_info = matcheslib.get_match_info(user_match_info.match_id);
        --[[
        if(result > 1) then
            --TraceError('result'..result);
            local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
            local match_status = list.match_info.status;
            local match_id = user_match_info.match_id;
            if(timeout ~= nil and timeout > 0) then
                timelib.createplan(function()
                    --让玩家自动加入牌桌
                    local new_user_match_info = matches_taotai_lib.get_user_match_info(user_id);
                    if(list.match_info.status == match_status 
                       and new_user_match_info.match_id == match_id
                       and list.taotai_list[user_id] == nil) then
                        matches_taotai_lib.set_match_user_wait(user_id);
                        matches_taotai_lib.process_wait_list(match_id);
                        matches_taotai_lib.log_user_match_record(user_id, result);


                        local match_count = matches_taotai_lib.get_match_user_count(match_id, "match");
                        local play_count = matches_taotai_lib.get_match_user_count(match_id, "play");
                        local left_count = match_count - play_count;
                        if(left_count < 3 and left_count > 0 
                           and list.match_info.notify_wait_next == 0 
                           and list.match_info.status > 1) then
                            --找到人数不够凑成一桌的用户
                            list.match_info.notify_wait_next = 1;
                            for k, v in pairs(list.match_list) do
                                if(list.play_list[k] == nil) then
                                    --不够人数了
                                    timelib.createplan(function()
                                        list.match_info.notify_wait_next = 0;
                                        local user_info = usermgr.GetUserById(k);
                                        if(user_info ~= nil) then
                                            new_user_match_info = matches_taotai_lib.get_user_match_info(user_id);
                                            if(list.match_info.status == match_status 
                                               and new_user_match_info.match_id == match_id
                                               and list.taotai_list[user_id] == nil) then
                                                local unfinished_count = matches_taotai_lib.count_still_playing_desks(match_id, 0, {}, os.time());
                                                netlib.send(function(buf)
                                                    buf:writeString("MATCHTTRS");
                                                    buf:writeInt(list.match_info.status == 1 and 5 or 6);
                                                    buf:writeInt(-1);
                                                    buf:writeInt(unfinished_count or 0);
                                                    buf:writeInt(0);
                                                end, user_info.ip, user_info.port);
                                           end
                                        end
                                    end, 2);
                                end
                            end
                        end
                    end
                end, timeout+5);--有三秒时间为结束框时间
            else
                --让玩家自动加入牌桌
                matches_taotai_lib.set_match_user_wait(user_id);
                matches_taotai_lib.process_wait_list(user_match_info.match_id);
                matches_taotai_lib.log_user_match_record(user_id, result);
            end
        else
            matches_taotai_lib.log_user_match_record(user_id, result);
        end
        --]]
        matches_taotai_lib.log_user_match_record(user_id, result);

        netlib.send(function(buf)
            buf:writeString("MATCHTTRS");
            buf:writeInt(result);
            buf:writeInt(timeout or -1);
            buf:writeInt(unfinished_count or 0);
            buf:writeInt(show_timeout or 1);
            buf:writeInt(match_info.smallbet or 0);
            buf:writeInt(match_info.largebet or 0);
        end, user_info.ip, user_info.port);
    end
end

matches_taotai_lib.net_send_match_change_taotai_jifen = function(match_id, match_count)
    local list = matches_taotai_lib.get_match_list(match_id);
    for k, v in pairs(list.match_list) do
        local user_info = usermgr.GetUserById(k);
        matches_taotai_lib.net_send_match_taotai_jifen(user_info, match_id, match_count);
    end
end

matches_taotai_lib.net_send_match_taotai_jifen = function(user_info, match_id, match_count)
    local list = matches_taotai_lib.get_match_list(match_id);
    local match_start_time = matcheslib.get_match_start_time(match_id);
    if(user_info ~= nil) then
        netlib.send(function(buf)
            buf:writeString("MATCHTTCJF");
            buf:writeInt(list.match_info.taotai_jifen);
            buf:writeInt(list.match_info.base_rate);
            buf:writeInt(list.match_info.status);
            local status = list.match_info.status > 1 and 2 or 1;
            buf:writeString(":");
            buf:writeInt(list.match_info.status > 0 and (os.time() - list.match_info.begin_time) or 0);
            buf:writeInt(match_count or -1);
            buf:writeInt(list.match_info.status <= 0 and (match_start_time - os.time()) or 0);
        end, user_info.ip, user_info.port);
    end
end

function matches_taotai_lib.net_send_match_all_rank_info(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    local rank_list, left_num = matches_taotai_lib.get_match_rank_list(match_id);
    for k, v in pairs(rank_list) do
        local user_info = usermgr.GetUserById(v.userId);
        if(user_info ~= nil) then
            local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
            if((user_match_info.match_id == match_id or user_match_info.match_id == nil) and user_match_info.is_taotai == nil) then
                if(user_info.desk and matcheslib.desk_list[user_info.desk] ~= nil and 
                   matcheslib.desk_list[user_info.desk] == match_id) then
                    if(v.rank == nil) then
                        v.rank = k;
                    end
                    matches_taotai_lib.net_send_match_rank_info(user_info, v, left_num, #rank_list);
                end
            end
        end
    end
end

function matches_taotai_lib.net_send_match_rank_info(user_info, rank_info, left_num, total_num)
    netlib.send(function(buf)
        buf:writeString("MATCHTTRANK");
        buf:writeInt(rank_info.rank);
        buf:writeInt(rank_info.jifen);
        buf:writeInt(left_num);
        buf:writeInt(total_num);
    end, user_info.ip, user_info.port);
end

function matches_taotai_lib.net_send_match_all_rank_list(match_id)
    matches_taotai_lib.refresh_rank_list[match_id] = 1;
end

matches_taotai_lib.net_send_match_all_rank_list_ex = function(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    local rank_list = matches_taotai_lib.get_match_rank_list(match_id);
    local count = 0;
    for k, v in pairs(list.match_list) do
        local user_info = usermgr.GetUserById(k);
        if(user_info ~= nil and user_info.open_match_rank_panel ~= nil and 
           user_info.open_match_rank_panel == match_id and count < 24) then --只刷新24个客户端
            count = count + 1;
            matches_taotai_lib.net_send_match_rank_list(user_info, rank_list);
        end
    end

    for k, v in pairs(list.taotai_list) do
        local user_info = usermgr.GetUserById(k);
        if(user_info ~= nil and user_info.open_match_rank_panel ~= nil and 
           user_info.open_match_rank_panel == match_id and count < 24) then --只刷新24个客户端
            local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
            if((user_match_info.match_id == match_id or user_match_info.match_id == nil) and user_match_info.is_taotai == nil) then
                if(user_info.desk and matcheslib.desk_list[user_info.desk] ~= nil and 
                   matcheslib.desk_list[user_info.desk] == match_id) then
                    count = count + 1;
                    matches_taotai_lib.net_send_match_rank_list(user_info, rank_list);
                end
            end
        end
    end
end

matches_taotai_lib.net_send_match_rank_list = function(user_info, all_rank_list)
    matches_taotai_lib.split_start(user_info.ip, user_info.port, "MATCHTTRLISTSTART");
    local send_count = 0
    local max_count = 100
	repeat
        send_count = matches_taotai_lib.split_send("MATCHTTRLISTEX", all_rank_list, function(buf_out, v, k)
            --buf_out:writeString(v);
            -- [[
            local user_match_info = matches_taotai_lib.get_user_match_info(v.userId);
            buf_out:writeString(v.nick or "")--昵称
            buf_out:writeInt(v.userId or 0)--用户id
            buf_out:writeString(v.imgUrl or "")--用户头像
            buf_out:writeInt(v.rank == nil and k or v.rank)--排名
            buf_out:writeInt(v.jifen or 0)--用户积分
            buf_out:writeInt(user_match_info.panshu or 0);
            buf_out:writeInt(v.is_taotai or 0);
            --]]
        end)
		max_count = max_count - 1
		if max_count <= 0 then
			break
		end
	until(send_count <= 0)
    matches_taotai_lib.split_end("MATCHTTRLISTEND")
    --[[
    netlib.send(function(buf_out)
        buf_out:writeString("MATCHTTRLIST")
        buf_out:writeInt(#all_rank_list)
        for k,v in pairs(all_rank_list) do
            buf_out:writeString(v.nick or "")--昵称
            local user_match_info = matches_taotai_lib.get_user_match_info(v.userId);
            buf_out:writeInt(v.userId or 0)--用户id
            buf_out:writeString(v.imgUrl or "")--用户头像
            buf_out:writeInt(v.rank == nil and k or v.rank)--排名
            buf_out:writeInt(v.jifen or 0)--用户积分
            buf_out:writeInt(user_match_info.panshu or 0);
            buf_out:writeInt(0);
            buf_out:writeInt(0);
            buf_out:writeInt(v.is_taotai or 0);
        end
        buf_out:writeInt(taotai_line); 
    end, user_info.ip, user_info.port);
    --]]
end

-----------------------------------内部函数---------------------------------------------------------- 

matches_taotai_lib.set_match_user_wait = function(user_id) 
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local match_id = user_match_info.match_id;
    if(match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        if(list.match_list[user_id] ~= nil) then
            list.wait_list[user_id] = 1;
        end
    end
end

--[[
matches_taotai_lib.update_match_to_commonsrv = function(user_match_info, match_id) 
    local list = matches_taotai_lib.get_match_list(match_id);
    if(list.match_info.status == 0) then
        local count = matches_taotai_lib.get_match_user_count(match_id);
        --通知commonsrv改变了报名人数了
        local total_count = usermgr.GetTotalUserCount(user_match_info.nRegSiteNo);
        local send_func = function(buf)
            buf:writeString("MATCHTTOL");
            buf:writeInt(groupinfo.groupid);
            buf:writeInt(total_count);
            buf:writeInt(count);
        end;
        send_buf_to_all_game_svr(send_func, "commonsvr");
        send_buf_to_all_game_svr(send_func, "hldz_taotai");
    end
end
--]]

matches_taotai_lib.check_match_room = function()
    return matcheslib.check_match_room();
end

function matches_taotai_lib.do_give_prize(user_info, prize_list)
    local new_prize_list = {};
    if(user_info) then
        --进行发奖
        for k, v in pairs(prize_list) do
            if(v.prize_type == 10) then--礼券
                tex_gamepropslib.set_props_count_by_id(v.prize_type, v.prize_value, user_info);
            elseif(v.prize_type == 9027) then --发筹码
                usermgr.addgold(user_info.userId, v.prize_value, 0, new_gold_type.TAOTAI_MATCH_PRIZE, -1);
            end
            table.insert(new_prize_list, v);
        end
    end
    return new_prize_list;
end

matches_taotai_lib.give_user_prize = function(user_id, rank, prize_list, match_id)
    local has_prize = 0;
    local new_prize_list = {};
    if(prize_list ~= nil) then
        local user_info = usermgr.GetUserById(user_id);
        local list = matches_taotai_lib.get_match_list(match_id);
        has_prize = 1;
        new_prize_list = matches_taotai_lib.do_give_prize(user_info, prize_list);
        matches_taotai_lib.net_send_match_prize(user_info, rank, new_prize_list, list.match_info.begin_time, (list.match_info.status > 1 and 1 or 0), list.match_info.match_count)
    end
    return has_prize;
end

matches_taotai_lib.process_rank_list = function(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    local rank_list = {};
    for k, v in pairs(list.match_list) do
        local user_match_info = matches_taotai_lib.get_user_match_info(k);
        local user_info = usermgr.GetUserById(k);
        if(user_info ~= nil and user_match_info.match_id == match_id and match_id ~= nil) then
            table.insert(rank_list, {
                jifen=user_match_info.jifen,
                imgUrl=user_info.imgUrl,    
                nick=user_info.nick,
                userId=user_info.userId,
                deskno=user_info.desk,
                begin_time=user_match_info.begin_time,
            });
        end
    end

    table.sort(rank_list, function(d1, d2)
        if(d1.jifen == d2.jifen) then
            return d1.begin_time < d2.begin_time;
        else
            return d1.jifen > d2.jifen;
        end
    end);

    list.rank_list = rank_list;
end

matches_taotai_lib.send_desk_match_chat = function(desk, msg)
    --TraceError('发送桌面比赛信息'..desk);
    room.arg.chatType = 0
    room.arg.currchat = msg
    room.arg.currentuser = ""
    room.arg.userId  = 0
    room.arg.siteno  = 0
    --borcastDeskEventEx("REDC", desk);
end

matches_taotai_lib.send_match_chat = function(match_id, msg)
    local list = matches_taotai_lib.get_match_list(match_id);
    for k, v in pairs(list.match_list) do
        local user_info = usermgr.GetUserById(k);
        if(user_info ~= nil) then
            SendChatToUser(4, user_info, msg);
        end
    end
end

matches_taotai_lib.process_taotai = function(match_id, left_num, status)
    --进行排名
    matches_taotai_lib.process_rank_list(match_id);

    local list = matches_taotai_lib.get_match_list(match_id);
    local rank_list = list.rank_list;

    --local last_taotai_key = 0;
    for k, v in pairs(rank_list) do
        if(k > left_num) then
            --[[
            if(last_taotai_key == 0) then
                last_taotai_key = k;
            end
            --]]
            --进行淘汰
            matches_taotai_lib.set_match_user_taotai(match_id, v.userId, 1, status);
        end
    end

    --[[
    if(last_taotai_key == 0) then
        --剩下的玩家少于需要淘汰的玩家数
        last_taotai_key = #rank_list + 1;
    end

    --当前剩下的玩家
    local match_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
    --如果不够一桌的还是淘汰掉
    local taotai_count = match_count % 3;
    if(taotai_count > 0 and match_count < 3) then
        for k, v in pairs(rank_list) do
            if(k < last_taotai_key and k >= (last_taotai_key - taotai_count)) then
                --进行淘汰
                if(list.match_info.status == 2) then--刚进决赛就结束了
                    --TraceError('taotai ??'..k);
                    matches_taotai_lib.set_match_user_taotai(match_id, v.userId, k, status);
                end
            end
        end
    end
    --]]
end

matches_taotai_lib.end_first_match = function(match_id) 
    matches_taotai_lib.end_second_match(match_id);
    --[[
	--进入下一场比赛
    local list = matches_taotai_lib.get_match_list(match_id);
    --TraceError('end_first_match'..match_id..' status'..list.match_info.status);
    list.match_info.status = 2;
    list.match_info.base_rate = matches_taotai_lib.CONFIG_SECOND_MATCH_BASE_RATE;
    list.match_info.end_time = 0;
    list.match_info.panshu = 0;
    list.wait_list = {};
    list.play_list = {};

    list.match_info.taotai_jifen = list.match_info.base_rate * matches_taotai_lib.CONFIG_MATCH_TAOTAI_RATE; 

    matches_taotai_lib.process_taotai(match_id, matches_taotai_lib.CONFIG_FIRST_MATCH_END_MATCH_COUNT, 1);

    --计算所有人晋级玩家的积分
    for k, v in pairs(list.match_list) do
        local user_match_info = matches_taotai_lib.get_user_match_info(k);
        if(user_match_info.match_id == match_id) then
            user_match_info.first_jifen = user_match_info.jifen;
            user_match_info.jifen = math.floor(math.sqrt(user_match_info.jifen)) * matches_taotai_lib.CONFIG_FIRST_MATCH_END_JIFEN_RATE;
        else
            TraceError("出bug了，用户出现在两长比赛中??user_id"..k);
        end
    end

    local match_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
    list.match_info.match_count = match_count;
    --通知改变比赛信息
    matches_taotai_lib.net_send_match_change_taotai_jifen(match_id, match_count);

    --通知所有用户开始进入决赛了
    matches_taotai_lib.net_send_match_all_begin(match_id);
    --]]
end

matches_taotai_lib.check_user_taotai = function(user_id)
        local user_match_info = matches_taotai_lib.get_user_match_info(user_id);

        if(user_match_info.match_id == nil) then    
            return 3;
        end

        local match_info = matcheslib.get_match_info(user_match_info.match_id);

        if(match_info == nil) then
            TraceError("为什么比赛结束了，还检查用户有没有被淘汰");
            return 2;
        end

        local need_jifen = match_info.ante + match_info.largebet;
        local jifen = user_match_info.jifen - (match_info.ante or 0);

        if(need_jifen > jifen or jifen <= 0) then
            --被淘汰了
            matches_taotai_lib.set_match_user_taotai(user_match_info.match_id, user_id, 1);
            return 1;
        end
        return 0;
end

matches_taotai_lib.end_second_match = function(match_id) 
    local list = matches_taotai_lib.get_match_list(match_id);

    if(list.match_info.status > 5) then
        return;
    end

    --TraceError('end_second_match'..match_id..' status '..list.match_info.status);
    list.match_info.status = 6;--list.match_info.status + 1;
    list.match_info.end_time = 0;
    list.match_info.panshu = 0;
    list.wait_list = {};
    list.play_list = {};

    --进行淘汰
    --matches_taotai_lib.process_taotai(match_id, matches_taotai_lib.CONFIG_SECOND_MATCH_END_MATCH_COUNT[list.match_info.status - 2]);

    matches_taotai_lib.process_taotai(match_id, 1);

    local match_user_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
    if(match_user_count <= 1) then
        --比赛结束了
        --TraceError('比赛结束了');
        matches_taotai_lib.process_rank_list(match_id);
        matches_taotai_lib.net_send_match_all_rank_list(match_id);
        --清空比赛的数据
        local match_info = matcheslib.get_match_info(match_id);
        local rank_info = list.rank_list[1];
        for k, v in pairs(list.match_list) do
            --发给最后一个玩家的，大奖
            local user_match_info = matches_taotai_lib.get_user_match_info(k);
            if(user_match_info.match_id == match_id) then
                --matches_taotai_lib.give_user_prize(k, 1, match_info.award[1], match_id);
                matches_taotai_lib.set_match_user_taotai(match_id, k, 1);
            end
            break;
        end

        --[[
        for k, v in pairs(list.taotai_list) do
            local user_match_info = matches_taotai_lib.get_user_match_info(k);
            if(user_match_info.match_id == match_id) then
                matches_taotai_lib.user_list[k] = nil;
            end
        end
        --]]

        matches_taotai_lib.match_list[match_id] = nil;
        matcheslib.on_match_end(match_id, rank_info);
    else
        --计算所有人的积分
        if(matches_taotai_lib.CONFIG_SECOND_MATCH_END_JIFEN_RATE ~= 1) then
        	for k, v in pairs(list.match_list) do
        	    local user_match_info = matches_taotai_lib.get_user_match_info(k);
        	    if(user_match_info.match_id == match_id) then
                    user_match_info.jifen = user_match_info.jifen * matches_taotai_lib.CONFIG_SECOND_MATCH_END_JIFEN_RATE;
        	    else
                    TraceError("出bug了，用户出现在两长比赛中??user_id"..k);
        	    end
        	end
        end

        local match_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
        list.match_info.match_count = match_count;
        matches_taotai_lib.net_send_match_change_taotai_jifen(match_id, match_count);
        matches_taotai_lib.net_send_match_all_begin(match_id);
    end
end

matches_taotai_lib.count_still_playing_desks = function(match_id, deskno, unfinished_desk, end_time)
    --TraceError("count_still_playing_ cur_deskno"..deskno);
    local list = matches_taotai_lib.get_match_list(match_id);
    for user_id,_ in pairs(list.match_list) do
    	local v = usermgr.GetUserById(user_id);
    	if(v ~= nil) then
    		if v.desk ~= nil then   --是否在桌上
    		    local desk = desklist[v.desk]
    		    if desk.game.startTime ~= nil and desk.game.startTime ~= 0 then --是否有开牌时间
    			 if timelib.db_to_lua_time(desk.game.startTime) < end_time then  --是否在结束之前开的牌
    			     --是否以前有插入过同桌号的数据
    			     local is_same = 0;
                     local remove_key = 0;
    			     for k1,v1 in pairs(unfinished_desk) do
                         if(v1 == deskno) then
                             remove_key = k1;
                         end
        				 if v.desk == v1 then
        				     is_same = 1;
        				     break;
                         end
                     end

                     if(remove_key > 0) then
                         table.remove(unfinished_desk, remove_key);
                     elseif(v.desk ~= deskno) then
        			     if is_same == 0 then
                            table.insert(unfinished_desk,v.desk)
        			     end
                     end
    			 end
    		    end
    		end
    	end
    end
    return #unfinished_desk;
end

matches_taotai_lib.init_match_config = function()
    TraceError('初始化淘汰配置');
    if groupinfo == nil or groupinfo.gamepeilv == nil then
        return
    end
    local m = matches_taotai_lib;
    local peilv = groupinfo.gamepeilv;
    for k, v in pairs(m) do
        local res = string.match(k, "CONFIG_(.*)");
        if(res and m["OP_"..res][peilv] ~= nil) then
            if(res == "MATCH_PRIZE") then
                TraceError('init match prize');
                for k, v in pairs(m["OP_"..res][peilv]) do
                    for k1, v1 in pairs(v) do
                        local t = split(v1, ":");
                        v[k1] = {prize_value=tonumber(t[1]), prize_type=tonumber(t[2]), prize_name=_U(tostring(t[3]))};
                    end
                end
            end
            m[k] = m["OP_"..res][peilv];
        end
    end

    local send_func = function(buf)
        buf:writeString("MATCHTTCFG");
        buf:writeInt(groupinfo.groupid);
        buf:writeString(groupinfo.groupname);
        buf:writeInt(matches_taotai_lib.CONFIG_MATCH_START_COUNT);
        buf:writeInt(matches_taotai_lib.CONFIG_BAOMING_SAIBI);
        buf:writeInt(0);
        buf:writeInt(24);
        local count = 0;
        for k, v in pairs(matches_taotai_lib.CONFIG_MATCH_PRIZE) do
            count = count + 1;
        end
        buf:writeInt(count);
        for k, v in pairs(matches_taotai_lib.CONFIG_MATCH_PRIZE) do
            buf:writeInt(k);
            local count2 = 0;
            for k1, v1 in pairs(v) do
                count2 = count2 + 1;
            end
            buf:writeInt(count2);--长度
            for k1, v1 in pairs(v) do
                buf:writeInt(v1.prize_value);--数值
                buf:writeInt(v1.prize_type);--类型
                buf:writeString(v1.prize_name);--名称
            end
        end
    end
    --发送配置到commonsvr,重载的时候也会发送给commonsrv，所以重载后需要1秒后才发送数据
    --[[
    timelib.createplan(function()
        send_buf_to_all_game_svr(send_func, "commonsvr");
        send_buf_to_all_game_svr(send_func, "hldz_taotai");
    end, 1);
    
    --初始化多一点桌子
    room.cfg.deskcount = 150;
	gamepkg.init_desk_all();
    --]]
end

matches_taotai_lib.remove_match_user_play = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local match_id = user_match_info.match_id;
    if(match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        list.play_list[user_id] = nil;
    end
end

matches_taotai_lib.set_match_user_play = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local match_id = user_match_info.match_id;
    if(match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        if(list.match_list[user_id] ~= nil) then
            list.play_list[user_id] = 1;
        end
    end
end


matches_taotai_lib.set_match_user_taotai = function(match_id, user_id, is_give_prize, status, is_kick) 
    local user_info = usermgr.GetUserById(user_id);
    if(user_info ~= nil) then
        user_info.last_open_match_rank_time = nil;
    end
    local list = matches_taotai_lib.get_match_list(match_id);
    matcheslib.on_match_taotai(match_id, user_id);
    if(list.match_list[user_id] == nil) then
        TraceError("用户不在比赛列表了，还淘汰个什么?"..user_id.." match_id"..match_id);
        return;
    end

    local match_info = matcheslib.get_match_info(match_id);
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local old_rank_info = nil;
    
    for k, v in pairs(list.rank_list) do
        if(v.userId == user_id) then
            old_rank_info = v;
            break;
        end
    end

    matches_taotai_lib.log_user_match_record(user_id, -2);

    local last_rank = #list.rank_list;
    if(is_kick ~= nil and is_kick == true or is_give_prize == nil) then
        user_match_info.last_match_id = user_match_info.match_id;
        user_match_info.match_id = nil;
        user_match_info.jifen = 0;
    end

    --重新排名
    matches_taotai_lib.process_rank_list(match_id);
    
    if(is_kick ~= nil and is_kick == true or is_give_prize == nil) then
        rank = last_rank
    else
        rank = matches_taotai_lib.get_user_rank(user_id); 
    end

    local has_prize = matches_taotai_lib.give_user_prize(user_id, rank, match_info.award[rank], match_id);

    if(has_prize == 0) then
        --没有奖的，提示被淘汰
        matches_taotai_lib.net_send_match_user_taotai(user_info, rank, 
                                                      (list.match_info.status > 1 and 1 or 0), 
                                                      list.match_info.match_count);
    end

    if(list.rank_list[rank] == nil) then
        list.taotai_list[user_id] = old_rank_info;
    else
        list.taotai_list[user_id] = table.clone(list.rank_list[rank]);
    end

    --更新排名
    list.taotai_list[user_id].rank = rank;
    if(is_kick ~= nil and is_kick == true or is_give_prize == nil) then
        --放弃或者断线的，直接最后一名
        list.taotai_list[user_id].rank = last_rank;
    end


    list.play_list[user_id] = nil;
    list.match_list[user_id] = nil;
    list.wait_list[user_id] = nil;
    
    if(status ~= nil) then
        list.taotai_list[user_id].status = status;
    else
        list.taotai_list[user_id].status = list.match_info.status;
    end
    user_match_info.last_match_id = user_match_info.match_id;
    user_match_info.match_id = nil;

    --让用户站起
    local deskno = user_info.desk;
    local site = user_info.site;

    if(deskno ~= nil and site ~= nil and rank > 1) then
        if(list.taotai_desk_list[deskno] == nil) then
            list.taotai_desk_list[deskno] = {};
        end
        list.taotai_desk_list[deskno][site] = list.taotai_list[user_id];
    end

    user_match_info.jifen = 0;
    letusergiveup(user_info)
    doStandUpAndWatch(user_info, 0);
    matches_taotai_lib.broadcast_taotai_list(match_id, deskno);--在桌面显示有用户淘汰了

    --记录内存，下次登录通知比赛结果
    local parent_user_id = user_id;
    if(duokai_lib and duokai_lib.is_sub_user(user_id) == 1) then
        parent_user_id = duokai_lib.get_parent_id(user_id);
    end
    if((is_kick ~= nil and is_kick == true) or (user_info and user_info.offline == offlinetype.tempoffline)) then
        local offline_list = nil;
        if(matches_taotai_lib.user_offline_list[parent_user_id] ~= nil) then
            offline_list = matches_taotai_lib.user_offline_list[parent_user_id];
        else
            offline_list = {};
            matches_taotai_lib.user_offline_list[parent_user_id] = offline_list;
        end
    
        --保存名次，奖励 
        offline_list[match_id] = {rank = rank, is_award = has_prize, prize_list = match_info.award[rank], time = os.time(), begin_time = list.match_info.begin_time, match_name = match_info.match_name, match_count = list.match_info.match_count};
    end

    matches_taotai_lib.check_match_end(match_id);
    matcheslib.refresh_list(user_info);
    eventmgr:dispatchEvent(Event("on_match_user_taotai", {user_id = user_id, rank = list.taotai_list[user_id].rank, match_type = 1, match_count = list.match_info.match_count}));
end

matches_taotai_lib.broadcast_taotai_list = function(match_id, deskno, user_info)
    --广播给所有人知道有人淘汰了
    if(deskno ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        local send_func = nil;
        if(list.taotai_desk_list ~= nil and list.taotai_desk_list[deskno] ~= nil) then
            send_func = function(buf)
                buf:writeString("MATCHTTMD")
                for k, v in pairs(list.taotai_desk_list[deskno]) do
                    if(desklist[deskno].site[k].user == nil) then
                        buf:writeInt(k);--座位
                        buf:writeInt(v.userId);--用户id
                        buf:writeString(v.nick);--用户昵称
                        buf:writeString(v.imgUrl);--用户头像
                        buf:writeInt(v.jifen);--用户积分
                    end
                end
                buf:writeInt(0);
            end
            
        else
            send_func = function(buf)
                buf:writeString("MATCHTTMD")
                buf:writeInt(0);
            end
        end
        if(user_info == nil) then
            netlib.broadcastdesk(send_func, deskno, borcastTarget.all);
        else
            netlib.send(send_func, user_info.ip, user_info.port);
        end
    end
end

matches_taotai_lib.get_user_rank = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local rank = 0;
    if(user_match_info.match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
        --TraceError(list.rank_list);
        for k, v in pairs(list.rank_list) do
            if(v.userId == user_id) then
                rank = k;
                break;
            end
        end
    end
    --TraceError('rank'..rank);
    return rank;
end

matches_taotai_lib.get_match_user_count = function(match_id, list_type)
    if(list_type == nil) then
        list_type = 'all';
    end

    local list = matches_taotai_lib.get_match_list(match_id);
    local count = 0;

    if(list_type == 'wait') then
        for k, v in pairs(list.wait_list) do
            count = count + 1;
        end
        return count;
    end

    if(list_type == "play") then
        for k, v in pairs(list.play_list) do
            count = count + 1;
        end
        return count;
    end

    if(list_type == 'all' or list_type == 'match') then
        for k, v in pairs(list.match_list) do
            count = count + 1;
        end
    end

    if(list_type == 'all' or list_type == 'taotai') then
        for k, v in pairs(list.taotai_list) do 
            count = count + 1;
        end
    end

    return count; 
end

--发送用户赛币信息给桌面用户
matches_taotai_lib.send_jifen_info_desk = function(user_info)
    local desk_no = user_info.desk
    if desk_no ~= nil and desk_no > 0 then
        for i = 1, room.cfg.DeskSiteCount do
            local site_user_info = userlist[desklist[desk_no].site[i].user]
            if (site_user_info) then
                matches_taotai_lib.net_send_jifen_info(site_user_info,user_info);--发送user_info的信息给同桌的玩家
                matches_taotai_lib.net_send_jifen_info(user_info,site_user_info);--发送同桌的玩家的信息给user_info
            end
        end
    end
end

--发送赛币信息
matches_taotai_lib.net_send_jifen_info = function(user_info, from_user_info, site)
    netlib.send(function(buf_out)
        buf_out:writeString("MATCHSAIBIINFO")
        	buf_out:writeInt(from_user_info.userId)   --用户ID
            local user_match_info = matches_taotai_lib.get_user_match_info(from_user_info.userId);
        	buf_out:writeInt(user_match_info.jifen)  --积分
            buf_out:writeInt(site == nil and from_user_info.site or site)  --座位号
    end, user_info.ip, user_info.port)
end


-----------------------------------系统事件响应-----------------------------------------------------------------

function matches_taotai_lib.on_parent_user_add_watch(e) 
    local user_info = e.data.user_info;
    local desk_no = user_info.desk;
    if(matcheslib.check_match_desk(desk_no) == 0) then
        do return end;
    end
    local sub_user_id = duokai_lib.get_sub_user_by_desk_no(user_info.userId, desk_no);
    if(sub_user_id > -1) then
        local sub_user_info = usermgr.GetUserById(sub_user_id);
        if(sub_user_info ~= nil) then
            local user_match_info = matches_taotai_lib.get_user_match_info(sub_user_info.userId);
            if(user_match_info.match_id ~= nil) then
                local match_id = user_match_info.match_id;
                matches_taotai_lib.on_watch_event({
                    data = {
                        userinfo = sub_user_info
                    },
                });
        
        
                matches_taotai_lib.net_send_match_taotai_jifen(sub_user_info, match_id);
                matches_taotai_lib.net_send_match_condition(sub_user_info);
                matches_taotai_lib.net_send_match_user_info(sub_user_id);
                matches_taotai_lib.net_send_match_rank_list(sub_user_info, matches_taotai_lib.get_match_rank_list(match_id));
            end
        end
    end
end

function matches_taotai_lib.get_match_rank_list(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    local rank_list = list.rank_list;
    local taotai_list = list.taotai_list;
    local taotai_line = list.match_info.status < 2 and #rank_list or -1;
    local all_rank_list = table.clone(rank_list); 
    local left_num = #all_rank_list;
    for k, v in pairs(taotai_list) do
        v.is_taotai = 1;
        if(list.match_info.status == 1) then
            table.insert(all_rank_list, v);
        elseif(v.status > 1) then
            table.insert(all_rank_list, v);
        end
    end
    --[[
    local t_list = {};
    local str = "";
    for k, v in pairs(all_rank_list) do
        if(str ~= "") then
            str = str .. "';'";
        end
        local user_match_info = matches_taotai_lib.get_user_match_info(v.userId);
        local rank = v.rank == nil and k or v.rank;
        str = str .. v.userId.."|"..v.jifen.."|"..(v.is_taotai or 0).."|"..rank.."|"..user_match_info.panshu.."|"..v.imgUrl.."|"..v.nick;
        if(k % 50 == 0 or k >= #all_rank_list) then
            table.insert(t_list, str);
            str = "";
        end
    end
    --]]
    return all_rank_list, left_num;
end

--用户比赛信息已经初始化
matches_taotai_lib.on_after_user_login = function(e)
    --TraceError('on_after_user_login');
    if(matches_taotai_lib.check_match_room() == 0) then
        return;
    end
    local user_info = e.data.userinfo;

    if(matches_taotai_lib.user_list[user_info.userId] ~= nil) then
        return;
    end

    --TraceError('on_after_user_login'..user_info.userId);
    --初始化用户比赛信息
    local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
    --TraceError(user_match_info);
    if(user_match_info.match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
        matches_taotai_lib.net_send_match_user_info(user_info.userId);
        matches_taotai_lib.net_send_match_taotai_jifen(user_info, user_match_info.match_id, list.match_info.match_count);
        matches_taotai_lib.net_send_match_condition(user_info);
        matches_taotai_lib.net_send_match_rank_list(user_info, matches_taotai_lib.get_match_rank_list(user_match_info.match_id));

        --重登陆发送积分显示
        --matches_taotai_lib.send_jifen_info_desk(user_info);
    end

    local match_result_list = matches_taotai_lib.user_offline_list[user_info.userId];
    if(match_result_list ~= nil) then
        for k, v in pairs(match_result_list) do
            if(v.is_award == 1) then
                matches_taotai_lib.net_send_match_prize(user_info, v.rank, v.prize_list, v.begin_time, 1, v.match_count, v.match_name);
            else
                matches_taotai_lib.net_send_match_user_taotai(user_info, v.rank, 1, v.match_count, v.match_name);
            end
        end
        matches_taotai_lib.user_offline_list[user_info.userId] = nil;
    end
end

matches_taotai_lib.on_timer_second = function(e)

    if(matches_taotai_lib.check_match_room() == 0) then
        return;
    end

    if(matches_taotai_lib.refresh_rank_list_ex == nil) then
        matches_taotai_lib.refresh_rank_list_ex = {};
    end

    for match_id, v in pairs(matches_taotai_lib.refresh_rank_list) do
        if(v == 1) then
            matches_taotai_lib.refresh_rank_list[match_id] = 0;
            matches_taotai_lib.net_send_match_all_rank_info(match_id);

            if(matches_taotai_lib.refresh_rank_list_ex[match_id] == nil) then
                matches_taotai_lib.refresh_rank_list_ex[match_id] = os.time();
            end
    
            if(os.time() - matches_taotai_lib.refresh_rank_list_ex[match_id] > 1) then
                matches_taotai_lib.refresh_rank_list_ex[match_id] = os.time();
                matches_taotai_lib.net_send_match_all_rank_list_ex(match_id);
            end
        end
    end

    --24小时后清空离线玩家获奖或淘汰通知
    for user_id, v in pairs(matches_taotai_lib.user_offline_list) do
        local count = 0;
        local remove_count = 0;
        for match_id, v1 in pairs(v) do
            count = count + 1;
            if(os.time() - v1.time > 24 * 3600) then
                v[match_id] = nil;
                remove_count = remove_count + 1;
            end
        end

        if(count == remove_count) then
            v[user_id] = nil;
        end
    end

    local current_match_id = matches_taotai_lib.get_current_match_id();
    --遍历所有比赛，更新游戏基数
    for k, v in pairs(matches_taotai_lib.match_list) do
        --定时清空没有结束的比赛
        local clear = 0;
        if(k ~= current_match_id) then
            local match_count = matches_taotai_lib.get_match_user_count(k, 'match');
            if(match_count == 0) then
                --比赛都没有人了
                matches_taotai_lib.match_list[k] = nil;
                clear = 1;
            end
        end
        
        --[[
        if(clear == 0) then
            --比赛状态 
            local status = v.match_info.status;
            if(status == 1) then
                --在预赛的时候，基数和淘汰分会不断增加
                local begin_time = v.match_info.begin_time;
                local change_base_rate_time = v.match_info.change_base_rate_time;
        
                if(change_base_rate_time == 0) then
                    --第一次的改变时间为开始时间
                    change_base_rate_time = begin_time;
                end
        
                if(change_base_rate_time + matches_taotai_lib.CONFIG_CHANGE_MATCH_BASE_RATE_TIME <= os.time()) then
                    --初赛进行处理
                    v.match_info.change_base_rate_time = os.time(); 
                    --更新基础数
                    v.match_info.base_rate = v.match_info.base_rate + matches_taotai_lib.CONFIG_FIRST_MATCH_BASE_RATE * matches_taotai_lib.CONFIG_FIRST_MATCH_INC_RATE
                    --更新淘汰积分
                    v.match_info.taotai_jifen = v.match_info.base_rate * matches_taotai_lib.CONFIG_MATCH_TAOTAI_RATE;
                    --发送给玩家，淘汰分改了
                    matches_taotai_lib.net_send_match_change_taotai_jifen(k, v.match_info.match_count);
                end
            end

            --检测有没有比赛卡死了
            local unfinished_desk = v.match_info.unfinished_desk;
            local die_count = 0;
            for _, desk_no in pairs(unfinished_desk) do
    		    local desk = desklist[desk_no];
    		    if desk.game.startTime ~= nil and desk.game.startTime ~= 0 then --是否有开牌时间
                    local lua_start_time = timelib.db_to_lua_time(desk.game.startTime);
                    if lua_start_time < v.match_info.end_time 
                        and os.time() - lua_start_time > 700 then  --是否在结束之前开的牌
                        --判断有没有超时,10分钟
                        die_count = die_count + 1;
                    end
                end
            end

            if(die_count > 0 and #unfinished_desk == die_count) then
                --超时的和没有完成的桌子数一样，那么就可以结束这场比赛了
                if(v.match_info.status == 1) then
                    matches_taotai_lib.end_first_match(k);
                elseif(v.match_info.status > 1) then
                    matches_taotai_lib.end_second_match(k);
                end
                TraceError("发现有卡死的比赛match_id"..k);
            end
        end
        --]]
    end
end

--[[
@desc 每一盘游戏结束
]]--
matches_taotai_lib.on_game_over = function(e)

    if(matches_taotai_lib.check_match_room() == 0) then
        return;
    end

    local match_id = nil;
    local chat_match_msg = "";
    local deskno = 0;
    for k,v in pairs(e.data) do
        local user_info = usermgr.GetUserById(v.userid or 0);
        if(user_info ~= nil) then
            if(deskno == nil or deskno == 0) then
                deskno = user_info.desk;
            end
            local user_match_info = matches_taotai_lib.get_user_match_info(v.userid);
            if(user_match_info.match_id ~= nil) then

                if(match_id == nil) then
                    match_id = user_match_info.match_id;
                elseif(match_id ~= user_match_info.match_id) then
                    TraceError("排队出bug了，同一桌的人比赛id竟然不一样");
                end

                local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
                local inc_jifen = v.wingold --v.beishu * list.match_info.base_rate * (v.iswin == 1 and 1 or -1);
                user_match_info.panshu = user_match_info.panshu + 1;
                user_match_info.jifen = user_match_info.jifen + inc_jifen;
                matches_taotai_lib.remove_match_user_play(v.userid);
                --记录比赛日志
                matches_taotai_lib.log_user_match_record(v.userid, 10);

                if(v.iswin == 1) then
                    --matcheslib.l_add_user_match_exp(user_info, matches_taotai_lib.CONFIG_WIN_ADD_MATCH_EXP);
                    --matcheslib.send_match_my_info(user_info);
                end

                --判断玩家积分情况
                
                --if(list.match_info.status == 1 and user_match_info.jifen < list.match_info.taotai_jifen) then
                if(list.match_info.status == 1) then
                    --被淘汰了
                    --matches_taotai_lib.set_match_user_taotai(match_id, v.userid);
                    matches_taotai_lib.check_user_taotai(v.userid);
                end
            end
        end
    end

    if(match_id ~= nil) then

        --matches_taotai_lib.send_desk_match_chat(deskno, tools.AnsiToUtf8("本局结束，成绩统计:\n")..chat_match_msg);

        --处理是否进入决赛
        local list = matches_taotai_lib.get_match_list(match_id);
        list.match_info.panshu = list.match_info.panshu + 1;

        local over_callback = nil;
        if(list.match_info.status > 1) then--决赛的第n轮
            over_callback = matches_taotai_lib.end_second_match;
        elseif(list.match_info.status == 1) then
            --正在比赛的玩家人数
    	    local match_user_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
    	    if(match_user_count <= matches_taotai_lib.CONFIG_FIRST_MATCH_END_COUNT) then
    	    --if(match_user_count <= 1) then
                over_callback = matches_taotai_lib.end_first_match;
    	    end
        end
	
    	if(over_callback ~= nil) then
            --判断其它玩家完成比赛没有，完成了就进入下一场比赛
    	    if(list.match_info.end_time == 0)  then
                list.match_info.end_time = os.time();
    	    end
    
    	    --计算还有多少张台没有打完
    	    --local unfinish_desk_count = matches_taotai_lib.count_still_playing_desks(match_id, deskno, list.match_info.unfinished_desk, list.match_info.end_time);
    	    local unfinish_desk_count = 0;
    
            --TraceError('unfinish_desk_count'..unfinish_desk_count);
    	    if(unfinish_desk_count <= 0) then
    		    over_callback(match_id);
                --清空所有玩家盘数
                for k, v in pairs(list.match_list) do
                    local user_match_info = matches_taotai_lib.get_user_match_info(k);
                    user_match_info.panshu = 0;
                    matches_taotai_lib.net_send_match_user_info(k);
                end
    	    else
        		--让用户等待吧
        		for k,v in pairs(e.data) do
        			if list.match_list[v.userid] ~= nil then --结算和没有被淘汰的用户提示
                        local user_match_info = matches_taotai_lib.get_user_match_info(v.userid);
                        user_match_info.notify_continue = 0;
                        --发送等待协议
                        matches_taotai_lib.net_send_match_result(v.userid, 1, nil, unfinish_desk_count);
        			end
                end

                --让其它等待轮换的用户知道比赛已经结束了
                for k, v in pairs(list.match_list) do
                    local user_match_info = matches_taotai_lib.get_user_match_info(k);
                    if(user_match_info.notify_continue == 1) then
                        user_match_info.notify_continue = 0;
                        matches_taotai_lib.net_send_match_result(k, 1, nil, unfinish_desk_count);
                    end
                end

                if(list.match_info.finish_taotai_time == 0) then
                    list.match_info.finish_taotai_time = os.time();
                    --通知还没有打完的玩家
                    for k, v in pairs(list.match_info.unfinished_desk) do
                        --根据桌子号获取用户
                        for i= 1,room.cfg.DeskSiteCount do
                            local siteuserinfo = deskmgr.getsiteuser(v,i); --得到用户的信息表。
                            matches_taotai_lib.net_send_match_msg(siteuserinfo.userId, 1);
                        end
                    end
                end
    	    end
    	else
    	    --通知用户继续轮换打牌,还没有淘汰到指定人数
            --[[
            for k,v in pairs(e.data) do
                --TraceError("通知用户继续轮换打牌"..v.userid);
                matches_taotai_lib.notify_continue_play(v.userid);
            end
            --]]
        end

        --重新计算排名
        matches_taotai_lib.process_rank_list(match_id);

        --发送排名
        matches_taotai_lib.net_send_match_all_rank_list(match_id);

        --刷新个人信息
        for k,v in pairs(e.data) do
            matches_taotai_lib.net_send_match_user_info(v.userid);
        end
    end
end

matches_taotai_lib.notify_continue_play = function(user_id)
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    if(user_match_info.match_id ~= nil) then
        user_match_info.notify_continue = 1;
        matches_taotai_lib.net_send_match_result(user_id, 2, 0, nil, 0);
    end
end

matches_taotai_lib.on_server_start = function(e)
    if(matches_taotai_lib.check_match_room() == 0) then
        return;
    end
    --matches_taotai_lib.init_match_config();
end


------------------------------------公共函数库----------------------------------------

matches_taotai_lib.g_on_game_start = function(deskno)
    --TraceError('on_game_start'..deskno);
    for _, player in pairs(deskmgr.getplayers(deskno)) do
		local user_info = player.userinfo;
        if(user_info) then
            matches_taotai_lib.net_send_match_result(user_info.userId, -1);
        end
    end
end

matches_taotai_lib.g_can_enter_game = function(type, user_info)
    --让所有人不能按以前的排队进到游戏
    local ret = 1;
    return ret;
end

matches_taotai_lib.can_enter_game = function(type, user_info)
    --让所有人不能按以前的排队进到游戏
    local ret = 1;
    if matcheslib.user_list[user_info.userId].match_gold  < matches_taotai_lib.CONFIG_BAOMING_SAIBI then
        ret = 0;
    end
    return ret;
end

matches_taotai_lib.g_check_match_room = function()
    return 1;
end

matches_taotai_lib.process_wait_list = function(match_id)
    --TraceError('process_wait_list');
    --[[
    local list = matches_taotai_lib.get_match_list(match_id);
    for k, v in pairs(list.wait_list) do
        local group = matches_taotai_lib.get_match_group_by_rank(k);
        --TraceError('process_wait_list'..tostringex(group));
        matches_taotai_lib.auto_join_desk(group);
    end
    --]]
end

matches_taotai_lib.get_match_group_by_rank = function(user_id, action)
    local group = {};
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id); 
    local match_id = user_match_info.match_id;
    if(match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        if(list.match_info.end_time == 0 and list.match_info.status > 0) then
            local wait_list = list.wait_list;
            local new_rank_list = {};
    
            for k, v in pairs(list.rank_list) do
                if((list.play_list[v.userId] == nil or (action ~= nil and action == 1)) and list.taotai_list[v.userId] == nil) then
                    table.insert(new_rank_list, v);
                end
            end
    
            --进入决赛了,按照排名去进行比赛
            local user_rank = 0;
            for k, v in pairs(new_rank_list) do
                if(v.userId == user_id) then
                    user_rank = k;
                end
            end
            local mod = user_rank % 3;
            mod = mod == 0 and 3 or mod;
            local begin_index = user_rank - mod + 1;
            local end_index = user_rank + 3 - mod 
            local count = 0;
            for i = begin_index, end_index do
                local item = new_rank_list[i];
                if(item ~= nil and wait_list[item.userId] ~= nil) then
                    group[item.userId] = 1;
                end
            end
        end
    end
    return group;
end


--[[
@desc 系统排队的时候调用获取当前用户所在比赛用户列表
@param user_id 
--]]
matches_taotai_lib.try_start_match = function(match_id)
    local user_list = {};
    local status = 0;
    if(match_id ~= nil) then
        local list = matches_taotai_lib.get_match_list(match_id);
        --判断比赛是否开始
        if(list.match_info.status > 0 and list.match_info.end_time == 0) then
            status = 2;
            user_list = list.match_list;
        else
            --判断人数是否足够了，足够了就开始比赛
            local count = matches_taotai_lib.get_match_user_count(match_id);
            local need_user_count = matcheslib.get_need_user_count(match_id);
            local baoming_count = matcheslib.get_baoming_count(match_id);
            local match_status = matcheslib.get_match_status(match_id);
            if (matcheslib.is_manren_match(match_id) == 1 and need_user_count > 0 and count >= need_user_count) or 
               (matcheslib.is_dingshi_match(match_id) == 1 and baoming_count > 0 and match_status == 3) then 
                --开赛了     
                user_list = list.match_list;       

                if(list.match_info.status == 0) then
                    list.match_info.status = 1;
                    list.match_info.begin_time = os.time();
                    list.match_info.match_count = count;
                    matches_taotai_lib.net_send_match_change_taotai_jifen(match_id, count);
                    status = 1;
                end
            end
        end
    end
    return user_list, status;
end


------------------------------------系统接口----------------------------------------
--[[
@desc 用户排队的时候,进行扣除报名费用
@param e 事件 e.data.user_id
--]]
matches_taotai_lib.on_user_queue = function(match_id, user_id)
    if(matches_taotai_lib.check_match_room() == 0) then
        return 0;
    end
    local user_info = usermgr.GetUserById(user_id);
    if(matches_taotai_lib.user_list[user_id] ~= nil) then
        local user_match_info = matches_taotai_lib.get_user_match_info(user_id); 
        if(user_match_info.match_id ~= nil) then
            local list = matches_taotai_lib.get_match_list(user_match_info.match_id);
            if(list.taotai_list[user_id] == nil) then
                matches_taotai_lib.set_match_user_wait(user_id);
            end
            return -1;
        end

        local count = matches_taotai_lib.get_match_user_count(match_id);
        --[[
        if(count >= matches_taotai_lib.CONFIG_MATCH_START_COUNT) then
            return -2;
        end
        --]]

        --分配比赛组 
        local list = matches_taotai_lib.get_match_list(match_id);
        local match_info = matcheslib.get_match_info(match_id);

        --设置玩家比赛id
        user_match_info.match_id = match_id;
        --user_match_info.nRegSiteNo = user_info.nRegSiteNo;
        --把玩家放到比赛列表里面
        list.match_list[user_id] = 1;
        --初始化用户积分
        user_match_info.jifen =  match_info.start_score;
        user_info.chouma = match_info.start_score;
        user_match_info.first_jifen = 0
        user_match_info.panshu = 0;
        user_match_info.last_match_id = nil;
        user_match_info.is_taotai = nil;
        --比赛报名时间
        user_match_info.begin_time = os.time();

        matches_taotai_lib.set_match_user_wait(user_id);
        matches_taotai_lib.net_send_match_taotai_jifen(user_info, match_id);
        matches_taotai_lib.net_send_match_condition(user_info);
        matches_taotai_lib.net_send_match_user_info(user_id);
        matches_taotai_lib.process_rank_list(match_id);
        matches_taotai_lib.net_send_match_all_rank_list(match_id);
        matches_taotai_lib.log_user_match_record(user_info.userId, -1);
        return 1;
    else
        return 0;
    end
end

matches_taotai_lib.on_watch_event = function(e)
    local user_info = e.data.userinfo;
    if(user_info == nil or matcheslib.check_match_desk(user_info.desk) == 0) then 
        return;
    end
    local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
    local match_id = user_match_info.match_id;
    if(match_id == nil and user_match_info.last_match_id ~= nil) then
        match_id = user_match_info.last_match_id;
    end
    if(match_id ~= nil) then
        --更新比赛信息
        local list = matches_taotai_lib.get_match_list(match_id);
        matches_taotai_lib.broadcast_taotai_list(match_id, user_info.desk, user_info);
        matches_taotai_lib.net_send_match_user_info(user_info.userId);
        matches_taotai_lib.net_send_match_taotai_jifen(user_info, match_id, list.match_count);
        matches_taotai_lib.net_send_match_condition(user_info);
    end
end

--[[
@desc 用户离开服务器了
@param e 事件 e.data.user_id
--]]
matches_taotai_lib.on_user_exit = function(e)
    if(matches_taotai_lib.check_match_room() == 0) then
        return;
    end
    local user_id = e.data.userinfo.userId;
    --用户离开了算是淘汰了
    local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
    local match_id = user_match_info.match_id;
    if(match_id ~= nil) then
        --把用户放到淘汰列表
        local list = matches_taotai_lib.get_match_list(match_id);
        if(list.match_list[user_id] ~= nil 
           and list.match_info.status > 0 
           and list.taotai_list[user_id] == nil) then
                matches_taotai_lib.set_match_user_taotai(match_id, user_id, nil, nil, true);
        else 
            matches_taotai_lib.log_user_match_record(user_id, -9);
        end
        
        list.match_list[user_id] = nil;
        list.wait_list[user_id] = nil;
        user_match_info.match_id = nil;

        --处理因用户离开导致比赛停止处理
        matches_taotai_lib.check_match_end(match_id);
        --matches_taotai_lib.update_match_to_commonsrv(user_match_info, match_id);
    end
    matches_taotai_lib.user_list[user_id] = nil;
end

function matches_taotai_lib.check_match_end(match_id)
    local list = matches_taotai_lib.get_match_list(match_id);
    if(list.match_info.status >= 1 and list.match_info.status < 5) then
        local match_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
        if(match_count > 0 and match_count < 2) then
            --如果比赛人数少于两个人，就直接颁奖了
            matches_taotai_lib.end_first_match(match_id);
        else
            matches_taotai_lib.net_send_match_all_rank_list(match_id);
        end
    else
        matches_taotai_lib.net_send_match_all_rank_list(match_id);
    end
end

function matches_taotai_lib.on_back_to_hall(e)
    local user_info = e.data.userinfo;
    matches_taotai_lib.process_give_up(user_info.userId);
end

-- 分批多次发送数据封装
matches_taotai_lib.split_start = function(ip, port, protocol_start, split_num)
    netlib.ip = ip
    netlib.port = port
    netlib.split_num = split_num or 20
    netlib.cur_pos = 1

    netlib.send(
        function(out_buf)
            out_buf:writeString(protocol_start)
        end
    , netlib.ip, netlib.port)
    --TraceError("分拆发送数据开始："..protocol_start)
end

-- 使用时需要回传一个回调来解释数据
matches_taotai_lib.split_send = function(protocal_send, data, cb_record)
    local count = #data - netlib.cur_pos + 1
    if count > netlib.split_num then
        count = netlib.split_num
    elseif count <= 0 then
        --TraceError("没有可发送的数据，直接返回")
        return 0
    end
    --TraceError("本次发送的数据量:"..tostring(count))
    netlib.send(
        function(out_buf)
            -- 计算当前应当发送多少数据
            -- 发送协议
            out_buf:writeString(protocal_send)
            -- 发送本次记录数
            out_buf:writeInt(count)

            -- 添加每一个记录到buf中，由外部回调解释数据
            local loop_start = netlib.cur_pos
            local loop_end = netlib.cur_pos + count - 1
            for offset = loop_start, loop_end do
                --TraceError("准备发送第"..offset.."条数据")
                xpcall(function() return cb_record(out_buf, data[offset], offset) end, throw)
                netlib.cur_pos = offset + 1
            end
        end
    , netlib.ip, netlib.port)
    --TraceError("分拆发送数据："..tostring(count))
    return count
end

matches_taotai_lib.split_end = function(protocol_end)
    netlib.send(
        function(out_buf)
            out_buf:writeString(protocol_end)
        end
    , netlib.ip, netlib.port)	
    --TraceError("分拆发送数据结束："..protocol_end)
end

function matches_taotai_lib.on_recv_get_all_rank_list(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;

    local is_show = buf:readInt();
    local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
    local match_id = user_match_info.match_id or user_match_info.last_match_id;

    if(is_show == 0) then
        user_info.open_match_rank_panel = nil; 
        return;
    end

    if(user_info.open_match_rank_panel ~= nil or user_info.last_open_match_rank_time ~= nil) then
      --已经打开过或者打开了3秒再打开不刷新
        user_info.open_match_rank_panel = match_id;
        return;
    end

    user_info.open_match_rank_panel = match_id;
    user_info.last_open_match_rank_time = os.time();

    if(match_id ~= nil) then
        matches_taotai_lib.net_send_match_rank_list(user_info, matches_taotai_lib.get_match_rank_list(match_id));
    end
end


------------------------------------事件添加----------------------------------------
--游戏开始事件
eventmgr:addEventListener("on_server_start", matches_taotai_lib.on_server_start);
--监听游戏结束事件
eventmgr:addEventListener("game_event", matches_taotai_lib.on_game_over);
--重载时登录检测监听
eventmgr:addEventListener("h2_on_user_login", matches_taotai_lib.on_after_user_login)
--倒计时
eventmgr:addEventListener("timer_second", matches_taotai_lib.on_timer_second);
--用户退出
eventmgr:addEventListener("do_kick_user_event", matches_taotai_lib.on_user_exit);
--用户观战的时候
eventmgr:addEventListener("on_watch_event", matches_taotai_lib.on_watch_event);
--返回大厅时候
eventmgr:addEventListener("back_to_hall", matches_taotai_lib.on_back_to_hall);
--子帐号返回大厅
eventmgr:addEventListener("on_sub_user_back_to_hall", matches_taotai_lib.on_user_exit);
--切换观战
eventmgr:addEventListener("on_parent_user_add_watch", matches_taotai_lib.on_parent_user_add_watch);

eventmgr:addEventListener("before_kick_sub_user", matches_taotai_lib.on_user_exit);
--用户点击报名
--eventmgr:addEventListener("on_user_queue", matches_taotai_lib.on_user_queue);


------------------------------------请求响应----------------------------------------
--命令列表
cmdHandler = 
{
    --自动排队
    --["MATCHTTJOIN"] = matches_taotai_lib.on_recv_match_join,
    --[[
    ["MATCHTTINFO"] = matches_taotai_lib.on_recv_match_info,
    ["MATCHTTBMC"] = matches_taotai_lib.on_recv_match_baoming_check,

    --收到其它服务器传过来的信息
    ["MATCHTTCFG"] = matches_taotai_lib.on_recv_commonsvr_match_config,
    ["MATCHTTOL"] = matches_taotai_lib.on_recv_commonsvr_match_online,
    --]]
    ["MATCHTTRLISTEX"] = matches_taotai_lib.on_recv_get_all_rank_list,
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

