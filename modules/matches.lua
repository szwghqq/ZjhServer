
if matcheslib and matcheslib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", matcheslib.on_after_user_login)
end

if matcheslib and matcheslib.on_buy_chouma then
	eventmgr:removeEventListener("on_buy_chouma", matcheslib.on_buy_chouma)
end

if matcheslib and matcheslib.on_timer_second then
	eventmgr:removeEventListener("timer_second", matcheslib.on_timer_second)
end

if matcheslib and matcheslib.on_try_start_game then
    eventmgr:removeEventListener("on_try_start_game", matcheslib.on_try_start_game);
end

if matcheslib and matcheslib.on_server_start then
    eventmgr:removeEventListener("on_server_start", matcheslib.on_server_start);
end

if matcheslib and matcheslib.on_back_to_hall then
    eventmgr:removeEventListener("back_to_hall", matcheslib.on_back_to_hall);
end

if matcheslib and matcheslib.on_user_exit then
	eventmgr:removeEventListener("do_kick_user_event", matcheslib.on_user_exit)
end

if matcheslib and matcheslib.on_send_duokai_sub_desk then
    eventmgr:removeEventListener("on_send_duokai_sub_desk", matcheslib.on_send_duokai_sub_desk);
end

if matcheslib and matcheslib.on_after_fapai then
    eventmgr:removeEventListener("on_after_fapai", matcheslib.on_after_fapai);
end

if(matcheslib and matcheslib.on_sub_user_back_to_hall) then
    eventmgr:removeEventListener("on_sub_user_back_to_hall", matcheslib.on_sub_user_back_to_hall);
end

if(matcheslib and matcheslib.on_user_sitdown) then
    eventmgr:removeEventListener("site_event", matcheslib.on_user_sitdown);
end

if(matcheslib and matcheslib.on_force_game_over) then
    eventmgr:removeEventListener("on_force_game_over", matcheslib.on_force_game_over);
end
--------------------------------------------------------------------------------------
if not matcheslib then
    matcheslib  = _S{
        ---网络接收
        on_recv_match_list = NULL_FUNC, --请求发送比赛列表
        on_recv_join_match = NULL_FUNC, --请求加入比赛
        on_recv_join_match_affirm = NULL_FUNC,  --确认报名
        on_recv_match_give_up = NULL_FUNC,   --收到退赛请求
        on_recv_match_rule = NULL_FUNC,    --收到赛制请求
        on_recv_continue_watch = NULL_FUNC, --收到继续观战
        on_recv_tixing = NULL_FUNC, --收到gs发的服务器消息

        ---网络发送
        net_send_match_list = NULL_FUNC, --发送比赛列表
        net_send_join_match = NULL_FUNC,    --发送请求报名结果
        net_send_join_match_result = NULL_FUNC, --发送报名确认结果
        net_send_user_match_list = NULL_FUNC,   --发送用户已报名列
        net_send_match_give_up = NULL_FUNC, --发送退赛结果
        net_send_match_coming = NULL_FUNC,  --发送通知客户端比赛即将开
        net_send_rule = NULL_FUNC,  --发送比赛规则
        net_send_match_win_list = NULL_FUNC, --发送客户端最近比赛赢家

        --外部接口
        get_match_by_desk_no = NULL_FUNC, --根据获取比赛信息
        get_user_match_desk_no = NULL_FUNC,--获取用户比赛桌子

        --内部接口
        get_blind_info_info = NULL_FUNC, --获取比赛盲注信息
        init_match = NULL_FUNC,     --初始化比赛列表
        update_match_list = NULL_FUNC, --更新比赛列表
        get_all_match_list = NULL_FUNC, --获取当天所有比赛信息
        get_match_info = NULL_FUNC,     --获取比赛信息
        auto_join_desk = NULL_FUNC, --自动加入牌桌
        apply_desks = NULL_FUNC,
        save_user_list_info = NULL_FUNC,    --保存报名信息
        create_manren_match_by_id = NULL_FUNC,      --根据比赛ID创建满人开赛场的分场
        process_give_up   = NULL_FUNC,      --处理放弃比赛
        update_match_bet = NULL_FUNC, --更新比赛盲注
        check_time_match = NULL_FUNC, --检查定点赛
        clear_match = NULL_FUNC,  --清掉一场比赛
        on_match_start  = NULL_FUNC,    --比赛开始
        send_tixing = NULL_FUNC,    --全服发送提醒
        on_match_end = NULL_FUNC,
        let_watching_user_join_desk = NULL_FUNC,
        check_match_desk = NULL_FUNC,
        check_match_room = NULL_FUNC, --检查是否比赛房间
        set_match_user_watch = NULL_FUNC,
        free_desks = NULL_FUNC,
        kou_fei = NULL_FUNC,    --参赛扣费
        tui_fei = NULL_FUNC,    --退赛退费
        check_match = NULL_FUNC,    --检查比赛状态是否可报名
        check_user_condition = NULL_FUNC,   --检查玩家条件是否可以参赛
        check_condition = NULL_FUNC,    --检查参赛条件
        check_join_cost = NULL_FUNC,    --检查报名费是否足够
        check_duokai_condition = NULL_FUNC, --检查多开情况
        join_match = NULL_FUNC,     --报名比赛
        refresh_list = NULL_FUNC,   --刷新列表
        go_back_to_hall = NULL_FUNC, --返回大厅
        notify_watcher_out = NULL_FUNC, --通知观战玩家离开

        --系统事件
        on_after_user_login = NULL_FUNC,
        on_buy_chouma = NULL_FUNC,
        on_send_buy_chouma = NULL_FUNC,
        on_timer_second = NULL_FUNC,
        on_try_start_game = NULL_FUNC,
        on_server_start = NULL_FUNC,
        on_back_to_hall = NULL_FUNC,
        on_user_exit = NULL_FUNC,
        
        --全局变量
        match_list_all = {},    ----存放当天每种类型的比赛
        match_list = {},        --可用比赛列表信息
        match_award_base = {},       --所有奖励信息
        match_award = {},       --所有奖励信息
        match_blind = {},       --盲注信息
        desk_list = {},     --比赛桌子列表信息
        user_list = {},     --用户列表
        watch_list = {},    --比赛观战列表
        match_win_list = {}, --比赛排行榜
        refresh_match_list_time = 0,   --刷新比赛列表时间
        is_notify_refresh_match = 0,   --是否需要通知用户刷新比赛列表
        
        --配置参数
        CONFIG_REFRESH_TIME = 99999,    --下场比赛剩余多久才出现在客户端，单位:秒
        
        CONFIG_WATCHING_COUNT = 50, --比赛桌子观战人数上限

        CONFIG_PRE_JOIN_TIME = 120,--提前120可以进入比赛

        CONDITION = {
            REQUIRE_LEVEL = 1,
            WORLD_POINT = 2,
            DIAMOND = 3,
            CHOUMA = 4,
            VIP = 5,
            SEX = 6,
        },
    }

    timelib.createplan(function()
        matcheslib.init_match();
    end, 2);
end

-----------------------------------------网络接收----------------------------------------------
function matcheslib.on_recv_match_list(buf)
    --测试代码
    --[[
    if(os.time() - matcheslib.refresh_match_list_time < 2) then
        return;
    end
    --]]
    local user_info = userlist[getuserid(buf)];
    if not user_info or (user_info.open_match_tab ~= nil and os.time() - user_info.open_match_tab < 2) then return end;
    user_info.open_match_tab = os.time();

    matcheslib.net_send_match_list(user_info);
    matcheslib.net_send_match_win_list(user_info);
end

function matcheslib.on_recv_join_match(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;

    local id = buf:readString();
    local match_info = matcheslib.get_match_info(id);   --根据报名的ID取得场次信息
    local result = 1;
    local baoming_match_info = nil;

    if(match_info == nil) then
        matcheslib.refresh_list(user_info);
        return;
    end
    
    result = matcheslib.check_match(match_info, result);                        --检查比赛状态
    result = matcheslib.check_user_condition(user_info, match_info, result);    --参赛条件检测
    result, baoming_match_info = matcheslib.check_duokai_condition(user_info, match_info, result);
    
    if (result == 2) then   --免费比赛直接报名了
        matcheslib.join_match(user_info, match_info);
    end

    matcheslib.net_send_join_match_result(user_info, result, match_info);  --报名结果

    if (result ~= 1) then   --出问题或者成功报名免费才刷新
        matcheslib.refresh_list(user_info);     --刷新列表
    end
    
end

function matcheslib.on_recv_join_match_affirm(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;

    local id = buf:readString();
    local match_info = matcheslib.get_match_info(id);
    local user_match_info = matcheslib.user_list[user_info.userId];
    local result = 3;
    local baoming_match_info = nil;
    
    result = matcheslib.check_match(match_info, result);                        --检查比赛状态
    result = matcheslib.check_user_condition(user_info, match_info, result);    --参赛条件检测
    result = matcheslib.check_join_cost(user_info, match_info, result);         --参赛费是否足够
    result, baoming_match_info = matcheslib.check_duokai_condition(user_info, match_info, result);
    
    if (result == 3 or result == 2) then   --条件通过，报名
        matcheslib.join_match(user_info, match_info);
    end

    local baoming_match_name = "";
    if(result == -10 and baoming_match_info ~= nil) then
        baoming_match_name = baoming_match_info.match_name;
    end

    matcheslib.refresh_list(user_info);     --刷新列表
    matcheslib.net_send_join_match_result(user_info, result, match_info, baoming_match_name);   --报名结果
    if(duokai_lib ~= nil and match_info and match_info.match_type == 1) then
        duokai_lib.update_sub_desk_info(user_info);
    end
end

function matcheslib.on_recv_match_give_up(buf)
    --TraceError("on_recv_give_up");
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local match_id = buf:readString();
    matcheslib.process_give_up(user_info, match_id, 1);
end

function matcheslib.on_recv_match_rule(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local match_id = buf:readString();
    matcheslib.net_send_rule(user_info, match_id);
end

function matcheslib.let_all_watching_user_join_desk(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and match_info.watch_list ~= nil) then
        for desk_no, _ in pairs(match_info.watch_list) do
            matcheslib.let_watching_user_join_desk(desk_no, match_id);
        end
    end
end

function matcheslib.on_recv_continue_watch(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local match_id = buf:readString();
    local deskno = user_info.desk;
    if(deskno == nil) then
        return;
    end
    --TraceError("on_recv_continue_watch~"..match_id..' deskno'..user_info.desk..' userId'..user_info.userId);

    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and match_info.status < 4) then
        matcheslib.set_match_user_watch(match_id, deskno, user_info.userId);
        matcheslib.let_watching_user_join_desk(deskno, match_id);
    else
        --比赛已经结束了,返回大厅吧
        matcheslib.go_back_to_hall(user_info);
        --TODO 通知比赛已经结束
    end
end

function matcheslib.on_recv_tixing(buf)
    --TraceError("on_recv_tixing");
    local user_info = usermgr.GetUserById(buf:readInt());
    if (user_info) then
        local match_id = buf:readString();
        local match_name = buf:readString();
        local time = buf:readInt();
        matcheslib.net_send_match_coming(user_info, match_id, match_name, time);
    end
end

-----------------------------------------网络发送----------------------------------------------
function matcheslib.net_send_match_list(user_info)
    if not user_info then return end;
    local length = 0;
    local user_match_info = matcheslib.user_list[user_info.userId];

    if(user_match_info == nil) then
        return;
    end

    local tmp_list = table.clone(matcheslib.match_list);

    --遍历用户的报名信息
    for k, v in pairs(user_match_info.baoming_list) do
        if tmp_list[v.id] ~= nil then                --如果报名信息中的比赛 在 比赛列表中存在
            if (tmp_list[v.id].status == 1) then       --并且比赛为未开始状态
                tmp_list[v.id].status = 2;           --显示给该用户时，变为可退赛状态
            elseif (tmp_list[v.id].status == 4) then     --比赛已经结束了，还没来得急刷新掉，现在把它去掉
                tmp_list[v.id] = nil;
            end
        end
    end

    for _, _ in pairs(tmp_list) do
        length = length + 1;
    end

    netlib.send(function(buf)
        buf:writeString("MATCHTTLIST");
        buf:writeInt(length);
        for k, v in pairs(tmp_list) do
            buf:writeString(v.id);   --比赛场id
            buf:writeString(v.match_name);--比赛名
            buf:writeString(v.match_time);--比赛开始时间
            buf:writeString(v.match_logo);--比赛logo
            buf:writeString(v.join_cost);--参赛费用类型
            buf:writeInt(v.join_cost_num);--参赛费用数量
            buf:writeInt(v.match_count);--参赛人数
            buf:writeInt(v.status);--比赛状态 1 可以报名 2 已经报名 3 进行中
            buf:writeInt(v.match_type);--1为定点赛, 2为满人赛
            buf:writeInt(v.need_user_count);--需要的人
            buf:writeInt(v.match_start_time - os.time());--开赛剩余时间
            buf:writeInt(matcheslib.CONFIG_PRE_JOIN_TIME);
        end
    end, user_info.ip, user_info.port);
end

--报名结果
function matcheslib.net_send_join_match_result(user_info, result, match_info, baoming_match_name)
    if not user_info then return end;

    local condition = match_info.match_condition;
    netlib.send(function(buf)
        buf:writeString("MATCHTTJM");
        buf:writeString(match_info ~= nil and match_info.id or "");
        buf:writeString(match_info ~= nil and match_info.client_id or "");
        buf:writeInt(result);
        buf:writeString(match_info ~= nil and match_info.match_name or "");
        buf:writeString(match_info ~= nil and match_info.join_cost or "");
        buf:writeInt(match_info ~= nil and match_info.join_cost_num or 0);
        buf:writeInt(#condition);
        for k, v in pairs(condition) do     --发送参赛条件
            buf:writeString(v);
        end
        buf:writeInt(match_info.satisfy_conditon);  --是否满足所有条件才可参赛
        buf:writeString(baoming_match_name or "");
    end, user_info.ip, user_info.port);
end

--用户已报名列表和可报名列表
function matcheslib.net_send_user_match_list(user_info)
    if not user_info or not matcheslib.user_list[user_info.userId] then return end;
    --已报名
    local user_match_list = matcheslib.user_list[user_info.userId].baoming_list;
    local length = 0;
    for k, v in pairs(user_match_list) do
        length = length + 1;
    end

    --可报名
    local tmp_match = {};
    local no_length = 0;
    for k, v in pairs(matcheslib.match_list) do
        if (v.baoming_list[user_info.userId] == nil) then
            table.insert(tmp_match,v);
            no_length = no_length + 1;
        end
    end

    netlib.send(function(buf)
        buf:writeString("USERMATCHLIST");
        buf:writeInt(length);
        for k, v in pairs(user_match_list) do
            buf:writeString(length == 0 and "" or v.id);          --比赛id
            buf:writeString(length == 0 and "" or v.match_name);  --比赛名
            buf:writeString(length == 0 and "" or v.match_time);  --比赛开始时间
            buf:writeInt(length == 0 and 0 or v.status);          --报名状态
        end
        buf:writeInt(no_length);
        for k, v in pairs(tmp_match) do
            buf:writeString(no_length == 0 and "" or v.id);          --比赛id
            buf:writeString(no_length == 0 and "" or v.match_name);  --比赛名
            buf:writeString(no_length == 0 and "" or v.match_time);  --比赛开始时间
            buf:writeInt(no_length == 0 and 0 or v.status);          --报名状态
        end
    end, user_info.ip, user_info.port);
end

--退赛结果
function matcheslib.net_send_match_give_up(user_info, match_info, msg_type)
    if not user_info or match_info == nil then return end;
    --TraceError("net_send_give_up");
    netlib.send(function(buf)
        buf:writeString("MATCHTTGIVEUP");
        buf:writeInt(msg_type);
        buf:writeString(match_info.join_cost);
        buf:writeInt(match_info.join_cost_num);
        buf:writeString(match_info.match_name);
        buf:writeString(match_info.match_time);
        buf:writeString(match_info.client_id or "");
    end,user_info.ip, user_info.port);
end

--通知客户端比赛倒计时
function matcheslib.net_send_match_coming(user_info, match_id, match_name, time, msg_type)
    if not user_info then return end;
    --TraceError("send_coming");
    netlib.send(function(buf)
        buf:writeString("MATCHCOMING");
        buf:writeString(match_id);
        buf:writeString(match_name);
        buf:writeInt(time);
        buf:writeInt(msg_type or 0);
    end,user_info.ip, user_info.port);
end

--比赛规则
function matcheslib.net_send_rule(user_info, match_id)
    if not user_info then return end;
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info == nil) then
        matcheslib.refresh_list(user_info);
        return;
    end
    local condition = match_info.match_condition;
    local award = matcheslib.match_award_base[match_info.type_id];
    local award_length = 0;
    for _, _ in pairs(award) do
        award_length = award_length + 1;
    end

    netlib.send(function(buf)
        buf:writeString("MATCHTTRULE");
        buf:writeInt(#condition);
        for k, v in pairs(condition) do     --发送参赛条件
            buf:writeString(v);
        end
        buf:writeInt(match_info.start_score);       --起始筹码
        buf:writeInt(match_info.blind_stakes_time); --盲注跳升时间
        buf:writeInt(match_info.need_user_count);   --最低需求人数
        buf:writeInt(match_info.satisfy_conditon);  --是否满足所有条件才可参赛
        
        buf:writeInt(award_length);     --发送奖励部分
        for k, v in pairs(award) do
            buf:writeString(k);         --名次
            buf:writeInt(v.chouma)      --筹码
            buf:writeInt(v.diamond)     --礼券
            buf:writeString(v.others)   --其他
        end

    end, user_info.ip, user_info.port);
end

--最近赢家
function matcheslib.net_send_match_win_list(user_info)
    if not user_info then return end;
    netlib.send(function(buf)
        local win_list = matcheslib.match_win_list;
        buf:writeString("MATCHWINLIST");
        buf:writeInt(#win_list);
        for k, v in pairs(win_list) do
            buf:writeInt(v.user_id);
            buf:writeString(v.nick);
            buf:writeString(v.face);
            buf:writeString(v.match_name);
            buf:writeString(v.sys_time);
            buf:writeInt(timelib.db_to_lua_time(v.sys_time));
            local prize_name = "";
            for k, v in pairs(v.prize_list) do
                if(prize_name ~= "") then
                    prize_name = prize_name .. "+";
                end
                if(v.prize_type == 10) then--礼券
                    prize_name = prize_name .. v.prize_value .. _U("礼券");
                elseif(v.prize_type == 9027) then --发筹码
                    prize_name = prize_name .. v.prize_value .. _U("筹码");
                end
            end
            buf:writeString(prize_name);
        end
    end, user_info.ip, user_info.port);
end


-----------------------------------------外部接口----------------------------------------------

function matcheslib.get_user_join_match_num(user_info)
    local count = 0;
    if(not user_info) then
        return count;
    end
    local user_match_info = matcheslib.user_list[user_info.userId];
    local baoming_list = user_match_info.baoming_list;
    for match_id, v in pairs(baoming_list) do
        local match_info = matcheslib.get_match_info(match_id);
        if(match_info and match_info.match_type == 1 and match_info.status < 3) then
            count = count + 1;
        end
    end
    return count;
end

function matcheslib.get_user_match_desk_no(user_info, match_id)
    local desk_no = -1;--比赛不存在
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        if(match_info.match_type == 1 and match_info.status >= 3 or match_info.match_type == 2) then
            --比赛的所有桌子
            if(duokai_lib ~= nil) then
                local match_desk_list = match_info.desk_list;
                if(match_desk_list) then
                    for k, v in pairs(match_desk_list) do
                       local sub_user_id = duokai_lib.get_sub_user_by_desk_no(user_info.userId, k); 
                       if(sub_user_id ~= -1) then
                           desk_no = k;
                           break;
                       end
                    end
                end
            else
                desk_no = user_info.desk;
            end
        else
            --比赛未开始
            desk_no = -2;
        end
    end
    return desk_no;
end

function matcheslib.get_match_by_desk_no(desk_no)
    local match_id = matcheslib.desk_list[desk_no];
    if(match_id ~= nil) then
        return matcheslib.get_match_info(match_id);
    end
    return nil;
end


-----------------------------------------内部接口----------------------------------------------

function matcheslib.get_blind_info(match_id, level)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and matcheslib.match_blind[match_info.type_id] ~= nil) then
        return matcheslib.match_blind[match_info.type_id][level];
    end
    return nil;
end

function matcheslib.check_match_room()
    return tonumber(groupinfo.groupid) == 18001 and 1 or 0;
end

function matcheslib.init_match()
    matcheslib.get_all_match_list();
end

--更新比赛列表
function matcheslib.update_match_list()
    --更新下所有比赛列表
    matcheslib.get_all_match_list(function()
        local tableTime = os.date("*t",os.time()); --当前系统日期
        local curr_time = os.time();               --当前系统时间
    
        --遍历所有比赛table
        for k, v in pairs(matcheslib.match_list_all) do
            --v为每种类型比赛的table
            for i=1, #v do
                local id = v[i].id;
                local match_type = v[i].match_type;
                local type_id = v[i].type_id;
                local is_gen = 0;

                if(match_type == 2) then
                    --遍历所有已生成的比赛，查看满人赛是否已经生成
                    for k1, v1 in pairs(matcheslib.match_list) do
                        if(v1.type_id == type_id) then
                            is_gen = 1;
                            break;
                        end
                    end
                end
                --如果比赛列表中没有则加入比赛list
                if matcheslib.match_list[id] == nil and is_gen == 0 then
                    matcheslib.match_list[id] = v[i];
                end
            end
        end
    
        --遍历当前比赛table,将即将开赛的status改为1
        for k, v in pairs(matcheslib.match_list_all) do
            for i=1, #v do
                local id = v[i].id;
                local match = matcheslib.match_list[id];
                local tmp_time = v[i].match_start_time;
                --如果比赛列表中有该场比赛，并且为未开赛，则判断该比赛是否即将开赛，true则将状态置为1,并且break出该层循环
                if (match ~= nil) then
                    if (match.match_type == 2) then
                        tmp_time = v[i].match_end_time;
                    end
                    if (tmp_time  - curr_time >= 0 and 
                        tmp_time  - curr_time <= matcheslib.CONFIG_REFRESH_TIME) then--定时赛,满人赛都提前显示
                        if (match.status == 0) then
                            match.status = 1;
                            matcheslib.is_notify_refresh_match = 1;
                        end
                        break;
                    end
                end
            end
        end
    
        --遍历所有比赛table 删除已完成和未开始的比赛 将满人开赛的已开赛再加入一场
        for k, v in pairs(matcheslib.match_list_all) do
            for i=1, #v do
                local id = v[i].id;
                local match_info = matcheslib.match_list[id];
                if match_info ~= nil then
                    if (match_info.status == 4 or match_info.status == 0)then
                        matcheslib.free_desks(id);
                        matcheslib.match_list[id] = nil;
                        if(match_info.status == 4) then
                            matcheslib.is_notify_refresh_match = 1;
                        end
                    end
                end
            end
        end

        for k, v in pairs(matcheslib.match_list) do 
            if(v.status == 4) then 
                matcheslib.free_desks(k); 
                matcheslib.match_list[k] = nil; 
            end 
        end
    end);
end

function matcheslib.notify_all_refresh_match_list()
    if(matcheslib.is_notify_refresh_match == 1) then
        matcheslib.is_notify_refresh_match = 0;

        for k, v in pairs(userlist) do
            if(v.open_match_tab ~= nil) then
                matcheslib.refresh_list(v);
            end
        end
    end
end

--取得当天比赛列表
function matcheslib.get_all_match_list(callback)

    local tableTime = os.date("*t",os.time());          --当前系统日期
    local currtime = os.date("%y-%m-%d %X",os.time());  --当前系统时间
    matcheslib.match_list_all = {};

    --查询盲注信息
    matches_db.get_match_blind(
        function(dt)
            for k, v in pairs(dt) do
                if matcheslib.match_blind[v.type_id] == nil then
                    matcheslib.match_blind[v.type_id] = {};
                end
                if matcheslib.match_blind[v.type_id][v.lv] == nil then
                    matcheslib.match_blind[v.type_id][v.lv] = {}
                end
                matcheslib.match_blind[v.type_id][v.lv].smallbet = v.small_blind;
                matcheslib.match_blind[v.type_id][v.lv].largebet = v.big_blind;
                matcheslib.match_blind[v.type_id][v.lv].ante = v.ante;
            end
        end);

    --查询奖励信息
    matches_db.get_match_award(
        function(dt)
            for k, v in pairs(dt) do
                local ranks = split(v.rank,"-");
                for i=tonumber(ranks[1]), tonumber(ranks[2]) do
                    if matcheslib.match_award[v.type_id] == nil then
                        matcheslib.match_award[v.type_id] = {};
                    end

                    matcheslib.match_award[v.type_id][i] = {};
                    if(v.chouma > 0) then
                        table.insert(matcheslib.match_award[v.type_id][i], {
                            prize_type = 9027,
                            prize_value = v.chouma,
                        });
                    end

                    if(v.diamond > 0) then
                        table.insert(matcheslib.match_award[v.type_id][i], {
                            prize_type = 10,
                            prize_value = v.diamond,
                        });
                    end
                    
                    if (v.others ~= "") then
                        table.insert(matcheslib.match_award[v.type_id][i], {
                            prize_type = split(v.others,":")[1],
                            prize_value = split(v.others,":")[2],
                        });
                    end
                end
            end

            for k, v in pairs(dt) do
                if (matcheslib.match_award_base[v.type_id] == nil) then
                    matcheslib.match_award_base[v.type_id] = {};
                end
                if (matcheslib.match_award_base[v.type_id][v.rank] == nil) then
                    matcheslib.match_award_base[v.type_id][v.rank] = {};
                end
                matcheslib.match_award_base[v.type_id][v.rank].chouma = v.chouma;
                matcheslib.match_award_base[v.type_id][v.rank].diamond = v.diamond;
                matcheslib.match_award_base[v.type_id][v.rank].others = v.others;
            end

        --查找符合比赛日期的赛事
            matches_db.get_match_list(
                function(dt)
                    --取得当天所有比赛种类数量(dt的每一条记录就是一种比赛)
                    for k, v in pairs(dt) do
                        local tmp_match = {};   --存放每种比赛
            
                        --分割比赛时间，每个分号代表一场比赛
                        local times = split(v.match_time,";");
                        for ks,vs in pairs(times) do
                            local m = {};
                            m.type_id = v.type_id;          --比赛类型id
                            m.id = v.type_id .."_"..os.date("%y-%m-%d",os.time()).."_"..vs;    --比赛id
                            m.client_id = m.id..os.time();		--特别ID 用于防止服务器重启造成客户端记录的ID混乱
                            m.match_name = v.match_name;    --比赛名
                            m.match_time = vs;              --开赛时间
                            m.match_logo = v.match_logo;    --图片
                            m.join_cost = split(v.join_cost,":")[1];  --参赛费用类型
                            m.join_cost_num = #v.join_cost == 0 and 0 or split(v.join_cost,":")[2];    --参赛费用数量
                            m.match_count = 0;  --参赛人数(初始为0)
                            m.status = 0;       --比赛状态(初始为0)
                            m.match_type = v.match_type;    --比赛类型
                            m.need_user_count = v.need_user_count;      --需要的人数
                            m.is_giveback_cost = v.is_giveback_cost;    --人数不足开赛是否退还参赛费
                            m.satisfy_conditon = v.satisfy_conditon;    --是否满足所有条件才可参赛
                            m.blind_stakes_time = v.blind_stakes_time;  --盲注调升时间
                            m.blind_stakes_level = v.blind_stakes_level;    --盲注起始等级
                            local tmp_condition = split(v.match_condition,";");
                            m.match_condition = v.match_condition == "" and {} or tmp_condition;   --参赛条件
 				            m.start_score = v.start_score;      --起始分数
                            m.ante = 0;

                            m.baoming_list = {};            --报名该场比赛的玩家
                            m.tixing_list = {};
                            m.watch_list = {};
                            
                            --添加比赛的os time属性 start_time end_time 定点赛开始和结束时间相同
                            local d1_time;
                            local d2_time;
                            if(m.match_type == 1) then      
                                d1_time = split(m.match_time, ":");
                                d2_time = d1_time;         
                            elseif (m.match_type == 2) then
                                d1_time = split(split(m.match_time, "-")[1],":");
                                d2_time = split(split(m.match_time, "-")[2],":");
                            else
                                TraceError("比赛类型出错:"..m.match_time.."的"..m.match_name
                                           .."出错类型:"..m.match_type);
                            end
                            m.match_start_time = os.time{year = tableTime.year, month = tableTime.month,
                                        day = tableTime.day, hour = d1_time[1], min = d1_time[2]};
                            m.match_end_time = os.time{year = tableTime.year, month = tableTime.month,
                                        day = tableTime.day, hour = d2_time[1], min = d2_time[2]};
                                
                            --比赛奖励
                            if matcheslib.match_award[v.type_id] ~= nil then
                                m.award = matcheslib.match_award[v.type_id];    
                            else
                                m.award = {};
                            end

                            --盲注配置
                            if matcheslib.match_blind[v.type_id] ~= nil then
                                m.blind = matcheslib.match_blind[v.type_id];    
                            else
                                m.blind = {};
                            end

                            table.insert(tmp_match,m);
                        end
                        --将比赛按时间从早到晚进行排序
                        table.sort(tmp_match, function(d1, d2)
                            return  d1.match_start_time < d2.match_start_time;
                        end);
                        --放入所有比赛的table中
                        table.insert(matcheslib.match_list_all,tmp_match);
                    end
          
                    if(callback ~= nil) then
                        callback();
                    end
            end);
        end);
end

--通过比赛ID取比赛信息
function matcheslib.get_match_info(id)
    local match_info = nil;
    for k, v in pairs(matcheslib.match_list) do
        if(v.id == id) then
            match_info = v;
            break;
        end
    end
    return match_info;
end

--[[
@param match_id 比赛id
@param match_user_list 加入牌桌用户
@param desk_list 比赛桌子列表
@param is_limit  是否限制每桌6人
@param callback 坐下之前回调
@param is_goto_game 是否切换到该牌桌
@param need_desk_user_count 加入的桌子至少的人数
]]--
function matcheslib.auto_join_desk(match_id, match_user_list, desk_list, 
                                   is_limit, callback, is_goto_game, 
                                   need_desk_user_count)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info == nil) then
        TraceError('比赛已经结束了，为什么还排队');
        return;
    end
    if(need_desk_user_count == nil) then
        need_desk_user_count = 0;
    end
    --获取用户当前比赛的所有等待比赛参赛者
    if(table.maxn(match_user_list) > 0) then
        --找到需要排队的玩家
        local join_list = {};
        for k, v in pairs(match_user_list) do
            local user_info = usermgr.GetUserById(k);
            if(user_info) then--同一场比赛才让他跳转过来
                if(user_info.desk ~= nil and user_info.desk > 0 and 
                   user_info.site ~= nil and user_info.site > 0) then
                       --判断房间开始了没有
                       if(deskmgr.get_game_state(user_info.desk) == gameflag.notstart) then
                           table.insert(join_list, k);
                       else
                           TraceError("who??"..k);
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

        if(#join_list <= 0) then
            return;
        end

        local table_desk_list = {};
        for k, v in pairs(desk_list) do
            table.insert(table_desk_list, k);
        end
        local join_func = function(is_limit, is_join_one, desk_count, is_least)
            local ret = 0;
            if(#join_list > 0) then
                for k, v in pairs(table_desk_list) do
                    if(#join_list <= 0) then
                        break;
                    end
                    --分桌规则
                    local can_join = 1;
                    local count = 0;
                    local user_id = join_list[1];
                    local players = deskmgr.getplayers(v);
                    local t_user_info = nil;
                    if(players[1] ~= nil) then
                        t_user_info = players[1].userinfo;
                    end
                    count = #players;

                    if(count == 1 and user_id ~= nil 
                       and t_user_info ~= nil and t_user_info.userId == user_id 
                       and desk_count ~= nil and desk_count == 1) then
                        --只有一个人，而且桌子上的人是自己,而且要找一张有一个人的桌子
                        --TraceError("只有一个人，而且桌子上的人是自己,而且要找一张有一个人的桌子");
                        count = 0;
                    end

                    if(is_limit == 1) then
                        --每桌只坐6人
                        if(count >= 6) then
                            can_join = 0;
                        end
                    end

                    if(is_join_one == 1 and desk_count ~= nil 
                       and (is_least == nil and count ~= desk_count or count < desk_count)) then
                        can_join = 0;
                           --TraceError('ok???'..count..' '..desk_count);
                    end

                    if(can_join == 1) then
                        for i=1, room.cfg.DeskSiteCount do
                            if(#join_list <= 0) then
                                break;
                            end
        
                            --TraceError('pre i'..i);
                            -- [[
                            --if (duokai_lib ~= nil and duokai_lib.site_have_user(v, i) == 0) or
                                --(duokai_lib == nil and desklist[v].site[i].user == nil)) then
                            if(desklist[v].site[i].user == nil) then
                                --]]
                                ret = 1;
                                local user_id = join_list[1];
                                local user_info = usermgr.GetUserById(user_id);
                                match_user_list[user_id] = nil; 
                                table.remove(join_list, 1);
                                --TraceError(v..'site no'..i..' user id'..user_id);

                                local has_join = 0;
                                if(user_info and user_info.desk and user_info.desk == v and user_info.site) then
                                    --已经坐下了，不用在坐下了 
                                    has_join = 1;
                                    trystartgame(v);
                                end

                                if(user_info and has_join == 0) then
                                    user_info.open_match_tab = nil;
                                    --坐下
                                    --TraceError('坐下 deskno..'..v..' userid:'..user_info.userId);
                                    if(duokai_lib ~= nil) then--多开逻辑
                                        local join_game = 0;
                                        if(duokai_lib.is_sub_user(user_info.userId) == 1) then
                                            local parent_id = duokai_lib.get_parent_id(user_info.userId);
                                            local parent_user_info = usermgr.GetUserById(parent_id);
                                            parent_user_info.open_match_tab = nil;
                                            if(parent_user_info and parent_user_info.desk == user_info.desk) then
                                                --子帐号和主帐号在一个桌子
                                                --TraceError("组帐号跟子帐号在一个桌子了");
                                                join_game = 1;
                                            end
                                        end
                                        --ResetUser(user_info.key, false);
                                        duokai_lib.join_game(user_info.userId, v, i, 
                                                             is_goto_game == 1 and 1 or join_game, 
                                                             function(sub_user_info)
                                            if(callback ~= nil) then
                                                callback(match_id, sub_user_info);
                                            end
                                        end);
                                    else
                                        if(callback ~= nil) then
                                            callback(match_id, user_info);
                                        end
                                        ResetUser(user_info.key, false);
                                        -- [[
                                        if user_info.desk and user_info.desk ~= v then
                                            DoUserExitWatch(user_info);
                                        end
                                        --]]
                                        if user_info.desk == nil then
                                            DoUserWatch(v, user_info, 1);
                                        end
                                        doSitdown(user_info.key, user_info.ip, user_info.port, v, i, g_sittype.queue);
                                    end
                                end
                                if(is_join_one == 1) then
                                    break;
                                end
                            end
                        end
                    end
                end
            end
            return ret;
        end

        local sort_func = function(sort_type)
            --对桌子进行排序
            table.sort(table_desk_list, function(d1, d2)
                local count1 = 0;
                for _, player in pairs(deskmgr.getplayers(d1)) do
                    local userinfo = player.userinfo;
                    if(userinfo.desk ~= nil and userinfo.site ~= nil) then
                        count1 = count1 + 1;
                    end
                end

                local count2 = 0;
                for _, player in pairs(deskmgr.getplayers(d2)) do
                    local userinfo = player.userinfo;
                    if(userinfo.desk ~= nil and userinfo.site ~= nil) then
                        count2 = count2 + 1;
                    end
                end

                if(sort_type == 0) then
                    return count1 < count2;
                else
                    return count1 > count2;
                end
            end);
        end

        --把玩家分到单独的桌子
        local join_one_and_one = function()
            --把剩余的玩家平均分到其它桌子
            sort_func(0);
            local clone_join_list = table.clone(join_list);
            for k, v in pairs(clone_join_list) do
                if(#join_list == 0) then
                    break;
                end
                local ret = 0;
                for i=4, 6 do--先从有4，5，6个人的桌子加
                    if(#join_list > 0 and i >= need_desk_user_count) then
                        ret = join_func(0, 1, i);
                        if(ret == 1) then
                            break;
                        end
                    else
                        break;
                    end
                end

                if(#join_list == 0) then
                    break;
                end

                --找6个人以上的桌子
                ret = join_func(0, 1, 6, 1);

                for i=6, 9 do--先从至少有3，2，1，0个人的桌子加
                    if(#join_list > 0 and 9 - i >= need_desk_user_count) then
                        ret = join_func(0, 1, 9-i);
                        if(ret == 1) then
                            break;
                        end
                    else
                        break;
                    end
                end
            end
        end

        if(is_limit ~= nil) then--比赛未开始
            join_func(is_limit, 0); --每桌6人
            join_one_and_one();--剩余的分到不同桌子
        else
            if(#join_list <= 3) then
                join_one_and_one();
            else
                --超过4人,把几人优先分配到独立桌子上
                sort_func(0);
                join_func(1, 0) ;  
                join_one_and_one();
            end
        end
    end
end

function matcheslib.apply_desks(match_id, match_count) 
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and match_info.desk_list == nil) then
        local desk_count = math.floor(match_count / 6);
        if(match_count % 6 > desk_count * (9 - 6)) then
            --剩余的玩家不够桌子
            desk_count = desk_count + 1;
        end
        match_info.desk_list = {};

        --根据比赛人数申请桌子
        for deskno,deskdata in pairs(desklist) do

            if(desk_count <= 0) then
                break;
            end
			if (tonumber(deskno) ~= nil and deskdata.desktype == g_DeskType.match) then
				local players = deskmgr.getplayers(deskno);
	            if(#players == 0 and matcheslib.desk_list[deskno] == nil) then
	                desk_count = desk_count - 1;
	                --找到空桌子
	                match_info.desk_list[deskno] = 1;
	                matcheslib.desk_list[deskno] = match_id;
	            end
			end
        end

        if(desk_count > 0) then
            TraceError("比赛申请不到空桌子"..match_id);
        end
    end
end

--保存玩家报名信息
function matcheslib.save_user_list_info(user_id, list_info)
    matches_db.save_match_join_info(user_id, list_info);
end

--根据满人开赛的比赛ID创建一场新的满人开赛
function matcheslib.create_manren_match_by_id(id)
    local current_time = os.time();
    if matcheslib.match_list[id] ~= nil and matcheslib.match_list[id].match_type == 2 and 
       current_time < matcheslib.match_list[id].match_end_time then
        local new_id;               --新场次的id
        local num = split(id,"_");  --判断该场 是否创建了分场
        if #num == 3 then           --还未创建分场
            new_id = id.."_1";
        else                        --已创建过分场的，把分场号+1
            num[4] = tonumber(num[4]) + 1;
            new_id = num[1].."_"..num[2].."_"..num[3].."_"..num[4];
        end
        matcheslib.match_list[new_id] = table.clone(matcheslib.match_list[id])
        matcheslib.match_list[new_id].id = new_id;
        matcheslib.match_list[new_id].client_id = new_id..os.time();
        matcheslib.match_list[new_id].match_count = 0;  --重置参赛人数
        matcheslib.match_list[new_id].status = 1;       --重置比赛状态
        matcheslib.match_list[new_id].smallbet = nil;  --重置比赛状态
        matcheslib.match_list[new_id].largebet = nil;
        matcheslib.match_list[new_id].joinning = nil;
        matcheslib.match_list[new_id].desk_list = nil;
        matcheslib.match_list[new_id].refresh_bet_time = nil;
        matcheslib.match_list[new_id].bet_level = 1;
        matcheslib.match_list[new_id].ante = nil;
        matcheslib.match_list[new_id].baoming_list = {};
        matcheslib.match_list[new_id].watch_list = {};
        matcheslib.is_notify_refresh_match = 1;
    end
end

function matcheslib.get_match_count(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    local count = 0;
    for k, v in pairs(match_info.baoming_list) do
        count = count + 1;
    end
    return count;
end

function matcheslib.clear_user_match_info(user_id, match_id, no_refresh_count)
    local match_info = matcheslib.get_match_info(match_id);
    if (match_info ~= nil and match_info.baoming_list[user_id] ~= nil) then
        match_info.baoming_list[user_id] = nil;
        match_info.tixing_list[user_id] = nil;
        if(match_info.wait_list ~= nil) then
            match_info.wait_list[user_id] = nil;
        end
        matcheslib.remove_wait_list(match_id, user_id);
        if(match_info.status < 3) then
            if(no_refresh_count == nil) then
                match_info.match_count = matcheslib.get_match_count(match_id);
            end
        else
            --已经开始比赛了,清除正在等待排队的玩家
           matcheslib.remove_wait_list(match_id, user_id); 
        end
    end
end

--处理退赛事件
function matcheslib.process_give_up(user_info, match_id, msg_type)
    local user_match_info = matcheslib.user_list[user_info.userId];
    local baoming_list = user_match_info.baoming_list;
    local match_info = matcheslib.get_match_info(match_id);
    matcheslib.clear_user_match_info(user_info.userId, match_id);

    if(baoming_list ~= nil and baoming_list[match_id] ~= nil) then
        --退报名费
        --TraceError("退报名费dkdkfjflf");
        matcheslib.tui_fei(user_info, baoming_list[match_id]);
        --如果match_info为空，则是以前的比赛不用处理
        if (match_info == nil) then
            match_info = table.clone(baoming_list[match_id]);
        end
        baoming_list[match_id] = nil;        --清空玩家该场的报名信息
        matcheslib.save_user_list_info(user_info.userId, baoming_list); --保存
        matcheslib.net_send_match_give_up(user_info, match_info, msg_type); --发送退赛结果
    end

    
    if(duokai_lib ~= nil) then
        local sub_user_id = -1;
        if(match_info ~= nil and match_info.desk_list ~= nil) then
            for deskno, v in pairs(match_info.desk_list) do
                sub_user_id = duokai_lib.get_sub_user_by_desk_no(user_info.userId, deskno);
                if(sub_user_id > 0) then
                    break;
                end
            end
        end
        if(sub_user_id > 0) then
            matches_taotai_lib.process_give_up(sub_user_id);
            matcheslib.go_back_to_hall(usermgr.GetUserById(sub_user_id));
            matcheslib.refresh_list(user_info);
            duokai_lib.update_sub_desk_info(user_info);
        end
    else
        matches_taotai_lib.process_give_up(user_info.userId);
        if(matcheslib.check_match_desk(user_info.desk) == 1 and 
           matcheslib.desk_list[user_info.desk] ~= nil and 
           matcheslib.desk_list[user_info.desk] == match_id) then
            --正在参加这场比赛的玩家才退回大厅
            matcheslib.go_back_to_hall(user_info);
        end
        matcheslib.refresh_list(user_info);
    end
end

function matcheslib.update_match_bet()
    for k, v in pairs(matcheslib.match_list) do
        if(v.status == 3) then
            --比赛开始后，盲注开始跳升
            if(v.refresh_bet_time == nil) then
                v.refresh_bet_time = os.time();
                v.bet_level = v.blind_stakes_level;
            end

            if(os.time() - v.refresh_bet_time > v.blind_stakes_time * 60) then
                v.refresh_bet_time = os.time();
                if(v.blind ~= nil) then
                    if(v.blind[v.bet_level] ~= nil and 
                       v.blind[v.bet_level].smallbet ~= nil and 
                       v.blind[v.bet_level].largebet ~= nil and
                       v.blind[v.bet_level].ante ~= nil) then
                        v.smallbet = v.blind[v.bet_level].smallbet;
                        v.largebet = v.blind[v.bet_level].largebet;
                        v.ante = v.blind[v.bet_level].ante;
                    end
                    v.bet_level = v.bet_level + 1;
                end
            end
        end
    end
end

function matcheslib.check_time_match()
    local curr_time = os.time();
    --客户端倒计时提醒  全服方式
    --[[    
    for match_id, match_info in pairs(matcheslib.match_list) do
        if(match_info.match_type == 1 and match_info.status < 3) then --定点开赛且没有开始
            for user_id, _ in pairs(match_info.baoming_list) do      
                local time = match_info.match_start_time - curr_time; --距离比赛开始时间
                if (time >=5 and time <= 120) then
                    if (match_info.tixing_list[user_id] ~= 2) then
                        matcheslib.send_tixing(user_id, match_info, time);
                        match_info.tixing_list[user_id] = 2;
                    end
                elseif (time>=120 and time <= 300) then
                    if (match_info.tixing_list[user_id] ~= 1) then
                        matcheslib.send_tixing(user_id, match_info, time);
                        match_info.tixing_list[user_id] = 1;
                    end
                end
            end
        end
    end
    --]]

    --客户端倒计时提醒 单服方式
    -- [[
    for match_id, match_info in pairs(matcheslib.match_list) do
        if(match_info.match_type == 1 and match_info.status < 3) then       --定点开赛且没有开始
            for user_id, _ in pairs(match_info.baoming_list) do      
                local user_info = usermgr.GetUserById(user_id);
                --在桌子上才广播
                local msg_type = 1;

                if(user_info and user_info.desk and matcheslib.desk_list[user_info.desk] == match_id) then
                    msg_type = 2;
                end

                if (user_info) then
                    local time = match_info.match_start_time - curr_time;   --距离比赛开始时间
                    if (time >5 and time <= 30) then
                        if(msg_type == 1 and match_info.tixing_list[user_id] == 3) then
                            msg_type = 0;
                        end
                        if (match_info.tixing_list[user_id] ~= 4) then
                            matcheslib.net_send_match_coming(user_info, match_info.id, match_info.match_name, time, msg_type);
                            match_info.tixing_list[user_id] = 4;
                        end
                    elseif (time>30 and time <= 60) then
                        if(msg_type == 1 and match_info.tixing_list[user_id] == 2) then
                            msg_type = 0;
                        end
                        if (match_info.tixing_list[user_id] ~= 3) then
                            matcheslib.net_send_match_coming(user_info, match_info.id, match_info.match_name, time, msg_type);
                            match_info.tixing_list[user_id] = 3;
                        end
                    elseif(time>60 and time <= 120) then
                        if (match_info.tixing_list[user_id] ~= 2) then
                            matcheslib.net_send_match_coming(user_info, match_info.id, match_info.match_name, time, msg_type);
                            match_info.tixing_list[user_id] = 2;
                        end
                    elseif (time>120 and time <= 300) then
                        if (match_info.tixing_list[user_id] ~= 1) then
                            matcheslib.net_send_match_coming(user_info, match_info.id, match_info.match_name, time);
                            match_info.tixing_list[user_id] = 1;
                        end
                    end
                end
            end
        end
    end
    --]]
    
    for match_id, v in pairs(matcheslib.match_list) do
        if(v.match_type == 2 and os.time() > v.match_end_time and v.status < 3) then
            --比赛已经结束
            for userid, _ in pairs(v.baoming_list) do
                local user_info = usermgr.GetUserById(userid);
                if(user_info ~= nil) then
                    matcheslib.process_give_up(user_info, match_id, 2); --退赛
                end
                if(duokai_lib ~= nil) then
                    duokai_lib.update_sub_desk_info(user_info);--自动清空多开
                end
            end
            v.status = 4;
        end
        if(v.match_type == 1 and v.status < 3 and v.match_start_time <= os.time()) then --定点赛且没有开始

            --检查已报名的玩家是否都在线，不在线的踢出报名
            local count = 0;
            for user_id, _ in pairs(v.baoming_list) do
                local user_info = usermgr.GetUserById(user_id);
                if (user_info == nil or 
                    (duokai_lib == nil and matcheslib.check_match_desk(user_info.desk, match_id) == 0)) then  
                    --开赛时已报名玩家不在线 则该玩家自动退赛,或者报名的玩家没有来参加
                    if(user_info) then
                        matcheslib.process_give_up(user_info, match_id, 3);
                    else
                        matcheslib.clear_user_match_info(user_id, match_id);
                    end
                else
                    count = count + 1;
                end
            end
            
            --如果最终报名的在线人数不够，比赛取消，通知玩家退赛
            if (count < v.need_user_count) then
                v.status = 4;   --标记比赛已经结束
                for userid, _ in pairs(v.baoming_list) do
                    local user_info = usermgr.GetUserById(userid);
                    if(user_info ~= nil) then
                        matcheslib.process_give_up(user_info, match_id, 2); --退赛
                    end
                    if(duokai_lib ~= nil) then
                        duokai_lib.update_sub_desk_info(user_info);--自动清空多开
                    end
                end
            else
                --比赛开始 
                --TODO在牌桌上的玩家需要多开
                --不在牌桌上的玩家直接拉入游戏
                v.status = 3;
                v.match_count = matcheslib.get_match_count(match_id);
                if(duokai_lib ~= nil) then
                    --多开直接拉人
                    for user_id,_  in pairs(v.baoming_list) do 
                        local user_info = usermgr.GetUserById(user_id);
                        if(user_info ~= nil) then
                            matcheslib.apply_desks(match_id, v.match_count);
                            local match_user_list = {
                                [user_info.userId] = 1;
                            };
                            matcheslib.auto_join_desk(match_id, match_user_list, v.desk_list, 1, matcheslib.on_after_join_desk, user_info.desk == nil and 1 or 0);
                            duokai_lib.update_sub_desk_info(user_info);
                        end
                    end
                else
                    matcheslib.try_start_match(match_id);
                end
            end
        end
    end
end

function matcheslib.on_after_join_desk(match_id, user_info)
    if(user_info ~= nil) then
        --初始比赛帐号
        local e = {data = {userinfo = user_info}};
        matcheslib.on_after_user_login(e);
        matches_taotai_lib.on_after_user_login(e);


        local user_id = user_info.userId;
        --让子账号比赛
        matches_taotai_lib.on_user_queue(match_id, user_id);
        local user_match_info = matches_taotai_lib.get_user_match_info(user_id);
        user_match_info.notify_continue = 0;
        matches_taotai_lib.remove_wait_list(user_id);
        matches_taotai_lib.set_match_user_play(user_id);
    end
end

function matcheslib.clear_match(match_id)
    matcheslib.match_list[match_id] = nil;
end

--比赛开始
function matcheslib.on_match_start(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    --更改比赛状态
    match_info.status = 3;
    match_info.tixing_list = {};
    --创建分场
    matcheslib.create_manren_match_by_id(match_id);
    --清除该场的玩家报名信息
    for userid, _ in pairs(match_info.baoming_list) do
        local user_match_info = matcheslib.user_list[userid];
        local baoming_list = user_match_info.baoming_list;
        baoming_list[match_id] = nil;       --如果考虑断线重连就不能清
        --保存玩家报名信息
        matcheslib.save_user_list_info(userid, baoming_list);
    end
    --TODO 还有什么要做的
end

function matcheslib.send_tixing(userId, match_info, time)
    local send_func = function(buf)
        buf:writeString("MATCHTTTIXING");
        buf:writeInt(userId);
        buf:writeString(match_info.id);
        buf:writeString(match_info.match_name);
        buf:writeInt(time);
    end
    send_buf_to_all_game_svr(send_func);
end

function matcheslib.on_match_end(match_id, rank_info)
    --TraceError('on_match_end'..match_id);
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        timelib.createplan(function()
            match_info.status = 4;
            matcheslib.notify_watcher_out(match_id, 1);
        end, 10);
        --通知所有观战者离开房间
        matcheslib.notify_watcher_out(match_id);

        if(rank_info ~= nil) then
            matches_db.save_match_win_info(match_id, match_info.match_name, 
                                           rank_info.userId, rank_info.jifen, match_info.award[1]);
    
            table.insert(matcheslib.match_win_list, 1, {
                user_id = rank_info.userId,
                nick = rank_info.nick, 
                match_id = match_id,
                match_name = match_info.match_name,
                jifen = rank_info.jifen,
                face = rank_info.imgUrl,
                sys_time = timelib.lua_to_db_time(os.time()),
                prize_list = match_info.award[1],
            });
        else
            TraceError("为什么比赛结束了没有排名信息"..tostringex(match_info));
        end

        if(#matcheslib.match_win_list > 5) then
            table.remove(matcheslib.match_win_list, #matcheslib.match_win_list);
        end

        --TODO在比赛页面的玩家才需要发送赢家列表, 切换到比赛页面需要发送一次赢家列表
        for k, v in pairs(userlist) do
            if(v.open_match_tab ~= nil) then
                matcheslib.net_send_match_win_list(v);
            end
        end
        
    end
end
--通知某桌观战玩家离开
matcheslib.notify_watcher_out = function(match_id, is_back_to_hall)
    local match_info = matcheslib.get_match_info(match_id);
    local desk_list = match_info.desk_list;
    for deskno, _ in pairs(desk_list) do
        local desk_watch_list = desklist[deskno].watchingList;
        local watcher_info = nil;
        for k, v in pairs(desk_watch_list) do
			watcher_info = usermgr.GetUserById(v.userId);
            if(watcher_info ~= nil) then
                if(is_back_to_hall ~= nil) then
                    matcheslib.go_back_to_hall(watcher_info);
                    matcheslib.refresh_list(watcher_info);     
                else
                    matcheslib.clear_user_match_info(v.userId, match_id, 1);
                    netlib.send(function(buf)
                        buf:writeString("MATCHOVER");
                        buf:writeString(match_id);
                    end, watcher_info.ip, watcher_info.port);
                end
            end
            --[[
			watcher_match_info = matcheslib.user_list[v.userId];
			--如果观战玩家还在该桌观战
			if watcher_info ~= nil and watcher_info.desk == deskno then
				--清空该观战玩家该场比赛报名信息
				if watcher_match_info ~= nil and watcher_match_info.baoming_list[match_id] ~= nil then
					watcher_match_info.baoming_list[match_id] = nil;
				end
				--退出大厅
	        	matcheslib.go_back_to_hall(watcher_info);
	        	--刷新列表
				matcheslib.refresh_list(watcher_info);     
			end
            --]]
		end
    end
    --[[
	local desk_watch_list = desklist[deskno].watchingList;
	local watcher_info = nil;
	local watcher_match_info = nil;
	--10秒后退出观战
	timelib.createplan(function()
		for k, v in pairs(desk_watch_list) do
			watcher_info = usermgr.GetUserById(v.userId);
			watcher_match_info = matcheslib.user_list[v.userId];
			--如果观战玩家还在该桌观战
			if watcher_info ~= nil and watcher_info.desk == deskno then
				--清空该观战玩家该场比赛报名信息
				if watcher_match_info ~= nil and watcher_match_info.baoming_list[match_id] ~= nil then
					watcher_match_info.baoming_list[match_id] = nil;
				end
				--退出大厅
	        	matcheslib.go_back_to_hall(watcher_info);
	        	--刷新列表
				matcheslib.refresh_list(watcher_info);     
			end
		end
	end,10);
    --]]
end

matcheslib.go_back_to_hall = function(user_info)
    if(user_info == nil) then return end
    pre_process_back_to_hall(user_info);
end

function matcheslib.let_watching_user_join_desk(cur_desk, match_id)
    --把当前桌子的观战人，移到第一名的那桌看
    local match_list = matches_taotai_lib.get_match_list(match_id);
    local rankinfo = match_list.rank_list[1];
    local match_info = matcheslib.get_match_info(match_id);
    if(rankinfo == nil or match_info == nil or match_info.status > 3) then
        --TraceError("比赛已经结束了 TODO 通知用户比赛结束了");
        matcheslib.notify_watcher_out(match_id, true);
        return;
    end
    local top_user_id = rankinfo.userId;
    --TraceError('top_user_id'..top_user_id);
    local topuserinfo = usermgr.GetUserById(top_user_id);
    local match_info = matcheslib.get_match_info(match_id);

    local count = 0;
    local players = deskmgr.getplayers(cur_desk);
    local count = #players;

    if(count <= 3 and topuserinfo ~= nil and topuserinfo.desk ~= nil and topuserinfo.desk ~= cur_desk) then
        if(match_info.watch_list ~= nil and match_info.watch_list[cur_desk] ~= nil) then
            for k, v in pairs(match_info.watch_list[cur_desk]) do
                local user_info = usermgr.GetUserById(k);
                local watching_count = 0;
                if(user_info ~= nil and user_info.desk == cur_desk and watching_count <= matcheslib.CONFIG_WATCHING_COUNT) then
                    matcheslib.set_match_user_watch(match_id, topuserinfo.desk, user_info.userId);
                    if(duokai_lib ~= nil) then
                        local join_game = 0;
                        if(duokai_lib.is_sub_user(user_info.userId) == 1) then
                            local parent_id = duokai_lib.get_parent_id(user_info.userId);
                            local parent_user_info = usermgr.GetUserById(parent_id);
                            if(parent_user_info and parent_user_info.desk == user_info.desk) then
                                --子帐号和主帐号在一个桌子
                                --TraceError("组帐号跟子帐号在一个桌子了");
                                join_game = 1;
                            end
                        end
                        duokai_lib.join_game(user_info.userId, topuserinfo.desk, 0, join_game);
                    else
                        matcheslib.go_back_to_hall(user_info);
                        DoUserWatch(topuserinfo.desk, user_info, 1);
                    end
                else
                    matcheslib.set_match_user_watch(match_id, 0, k);	
                    if user_info ~= nil and user_info.desk ~= nil and watching_count > matcheslib.CONFIG_WATCHING_COUNT then
                    	--通知客户端返回大厅
                        
                        matcheslib.clear_user_match_info(user_info.userId, match_id);
                    	matcheslib.go_back_to_hall(user_info);
                    end
                end
            end
        end
    end
end

function matcheslib.check_match_desk(deskno, match_id)
    if(deskno ~= nil) then
        local deskinfo = desklist[deskno];
        if(match_id == nil) then
            return deskinfo.desktype and deskinfo.desktype == g_DeskType.match and 1 or 0;
        else
            return deskinfo.desktype and deskinfo.desktype == g_DeskType.match and 
            matcheslib.desk_list[deskno] ~= nil and
            matcheslib.desk_list[deskno] == match_id and 1 or 0;
        end
    else
        return 0;
    end
end

function matcheslib.set_match_user_watch(match_id, deskno, user_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        if(match_info.watch_list == nil) then
            match_info.watch_list = {};
        end

        if(match_info.watch_list[deskno] == nil) then
            match_info.watch_list[deskno] = {};
        end

        if(matcheslib.watch_list[user_id] ~= nil) then
            local last_deskno = matcheslib.watch_list[user_id];
            if(match_info.watch_list[last_deskno] ~= nil and match_info.watch_list[last_deskno][user_id] ~= nil) then
                match_info.watch_list[last_deskno][user_id] = nil;
            end
        end

        match_info.watch_list[deskno][user_id] = 1;
        matcheslib.watch_list[user_id] = deskno;
    end
end

function matcheslib.free_desks(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info.desk_list ~= nil) then
        for k, v in pairs(match_info.desk_list) do
            match_info.desk_list[k] = nil;
            matcheslib.desk_list[k] = nil;
        end
    end
end

--参赛扣费
function matcheslib.kou_fei(user_info, match_info)
    local cost = tonumber(match_info.join_cost_num);    --费用
    local cost_type = match_info.join_cost;             --费用类型

    if (cost_type == "cm") then --参赛费为筹码
        usermgr.addgold(user_info.userId, -cost, 0, new_gold_type.TEX_MATCH_JOIN_COST, -1);
    end
    --TODO 扣除其他道具
end

--退赛退费
function matcheslib.tui_fei(user_info, match_info)
    local cost = tonumber(match_info.join_cost_num);    --费用
    local cost_type = match_info.join_cost;             --费用类型

    if (cost_type == "cm" and cost > 0) then --参赛费为筹码
        usermgr.addgold(user_info.userId, cost, 0, new_gold_type.TEX_MATCH_EXIT_COST, -1);
    end
    --TODO 退还其他道具
end

--检测比赛状态是否可报名
function matcheslib.check_match(match_info, result)
    local tableTime = os.date("*t",os.time()); --当前系统日期
    local curr_time = os.time();               --当前系统时间 
    
    if (match_info == nil or match_info.status == 4) then   --比赛已经结束
        result = -1;
    elseif (match_info.status == 3) then                    --比赛已经开始了
        result = -2;
    elseif(match_info.match_type == 2 and 
           match_info.match_count >= match_info.need_user_count) then
        result = -11;
    elseif (match_info.match_type == 2 and curr_time < match_info.match_start_time) then      --满人开赛未到时间
        result = -3;
    elseif (match_info.join_cost == "" or tonumber(match_info.join_cost_num) == 0) then   --免费比赛
        result = 2;
    end
    return result;
end

--检查玩家条件是否可以报名比赛
function matcheslib.check_user_condition(user_info, match_info, result)
    --TODO要判断是满足所有条件 还是满足一条就可以
    local condition = match_info.match_condition;   --参赛条件
    for k, v in pairs(condition) do
        local condition_key = tonumber(split(v,":")[1]);    --条件名
        local condition_value = split(v,":")[2];            --条件值

        if (condition_key == 1) then                  --玩家等级要求
            if  (matcheslib.check_condition(condition_value, user_info.gameInfo.level) == 1) then
                result = -7;
            end
        elseif (condition_key == 2) then              --TODO世界排名点数要求
           
        elseif (condition_key == 3) then              --TODO玩家现有奖券要求

        elseif (condition_key == 4) then              --TODO玩家现有筹码要求
            if  (matcheslib.check_condition(condition_value, user_info.gamescore) == 1) then
                result = -7;
            end
        elseif (condition_key == 5) then                    --是否VIP
            if (split(condition_value,"-")[1] ~= 0) then    --限制只许VIP进入
                if (user_info.vip_info == nil) then --非vip
                    result = -7;
                elseif (matcheslib.check_condition(condition_value, user_info.vip_info[1].vip_level) == 1) then
                    result = -7;
                end 
            else                                            --限制VIP玩家不许进入
                if (user_info.vip_info ~= nil) then
                    result = -7;
                end
            end
        elseif (condition_key == 6) then                      --性别
            if  user_info.sex ~= condition_value then
                result = -7;
            end
        end
    end
    return result;
end

function matcheslib.check_condition(condition_value, check_value)
    local min = tonumber(split(condition_value,"-")[1]);
    local max = tonumber(split(condition_value,"-")[2]);
    if check_value < min or check_value > max then
        return 1;
    end
    return 0;
end

--检查参赛费
function matcheslib.check_join_cost(user_info, match_info, result)
    if match_info.join_cost == "cm" then                         --筹码
        local can_use_gold = get_canuse_gold(user_info);
        if can_use_gold < tonumber(match_info.join_cost_num) then
            result = -4;
        end
    --TODO 其他道具条件检测
    --elseif()
    --result = -5;
    end
    return result;
end

function matcheslib.on_match_taotai(match_id, user_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        if(duokai_lib ~= nil) then
            local parent_id = duokai_lib.get_parent_id(user_id);
            match_info.baoming_list[parent_id] = nil;
            local user_match_info = matcheslib.user_list[parent_id];
            if(user_match_info ~= nil) then
                user_match_info.baoming_list[match_id] = nil;
            end
        else
            matcheslib.clear_user_match_info(user_id, match_id);
            local user_match_info = matcheslib.user_list[user_id];
            if(user_match_info ~= nil) then
                user_match_info.baoming_list[match_id] = nil;
            end
        end
    end
end

--检查多开情况
matcheslib.check_duokai_condition = function(user_info, match_info, result)
	--是否是比赛场
	local user_match_info = matcheslib.user_list[user_info.userId];
    local baoming_match_info = nil;
	if user_match_info == nil or match_info == nil then
		return result;
    end

    --遍历所有比赛,开赛后检查
    -- [[
    for k, v in pairs(matcheslib.match_list) do
        baoming_match_info = matcheslib.get_match_info(k);
        if(v.status < 4) then--比赛未结束才判断
            if(v.match_type == 2 and match_info.match_type == 2) then--只可以报一场满人赛
                if(v.baoming_list[user_info.userId] ~= nil) then--比赛中也不可以报
    				result = -8;
                    break;
                end
            elseif(v.match_type == 1 and match_info.match_time == v.match_time) then--同一时间只可以报一场
                if(v.baoming_list[user_info.userId] ~= nil) then--比赛中也不可以报
                    result = -9;
                    break;
                end
            end
        end
    end
    --]]
    --[[
    --如果正在比赛也不能加入比赛
    for k, v in pairs(matcheslib.match_list) do
        if(v.status < 4) then--比赛未结束才判断
            if(v.match_type == 2) then
                if(v.baoming_list[user_info.userId] ~= nil) then
                    baoming_match_info = matcheslib.get_match_info(k);
    				result = -10;
                    break;
                end
            elseif(v.match_type == 1) then
                if(v.baoming_list[user_info.userId] ~= nil) then
                    baoming_match_info = matcheslib.get_match_info(k);
                    result = -10;
                    break;
                end
            end
        end
    end
    --]]

    --比赛已经开始检查
    if(result ~= -10) then
    	for match_id, v in pairs(user_match_info.baoming_list) do
            baoming_match_info = matcheslib.get_match_info(match_id);
            if(baoming_match_info ~= nil and baoming_match_info.status < 4) then--查看比赛有没有存在或者结束没有
                --result = -10;
                --break;
        		--满人赛只能报一场
                -- [[
        		if match_info.match_type == 2 then
        		 	if v.match_type == match_info.match_type then
        				result = -8;
        				break;
        			end
        		--定点赛同一时刻只能报一场
        		elseif match_info.match_time == v.match_time then
        			result = -9;
        			break;
                end
                --]]
            end
        end
    end
	return result, baoming_match_info;
end

--报名比赛
function matcheslib.join_match(user_info, match_info)
    local user_match_info = matcheslib.user_list[user_info.userId];
    if (user_match_info ~= nil and user_match_info.baoming_list[match_info.id] == nil) then
        user_match_info.baoming_list[match_info.id] = {
            id = match_info.id;                     --比赛ID
            type_id = match_info.type_id;           --比赛类型
            match_name = match_info.match_name;     --比赛名
            match_time = match_info.match_time;     --开赛时间
            join_cost = match_info.join_cost;       --参赛费类型
            join_cost_num = match_info.join_cost_num;  --参赛费数量
            status = 2;                             --报名的比赛状态  2为已报名
            match_type = match_info.match_type;     --比赛类型
        };
        match_info.tixing_list[user_info.userId] = 0;           --添加玩家的比赛提醒
        if(match_info.match_type == 2) then --检查报名的玩家在不在线
            for k, v in pairs(match_info.baoming_list) do
                local userinfo = usermgr.GetUserById(k);
                if(userinfo == nil or matcheslib.check_match_desk(userinfo.desk) == 0) then
                    matcheslib.clear_user_match_info(k, match_info.id, 1);
                end
            end
        end

        match_info.baoming_list[user_info.userId] = 1;          --添加报名信息
        match_info.match_count = matcheslib.get_match_count(match_info.id);   --更新该场比赛的参赛人数
    
        matcheslib.save_user_list_info(user_info.userId, user_match_info.baoming_list); --将报名信息写入数据库
        matcheslib.kou_fei(user_info, match_info);              --扣费
    else
        TraceError("已经报过该场比赛...");
        return;
    end
    --如果是满人赛，直接加入牌桌
    if(match_info.match_type == 2) then
        --TraceError('auto join match match_type'..match_info.match_type);
        --让玩家加入比赛
        --local result = matches_taotai_lib.on_user_queue(match_info.id, user_info.userId);
        matcheslib.apply_desks(match_info.id, match_info.need_user_count);
        local match_user_list = {
            [user_info.userId] = 1;
        };
        --从大厅直接进入为主账号 需要切换到当前牌桌
        matcheslib.auto_join_desk(match_info.id, match_user_list, match_info.desk_list, 1, matcheslib.on_after_join_desk, (user_info.desk == nil and 1 or 0));
    end
end

function matcheslib.refresh_list(user_info)
    if(duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 1) then
        return;
    end
    matcheslib.net_send_match_list(user_info);      --比赛列表
    matcheslib.net_send_user_match_list(user_info); --已报名列表
    if(duokai_lib ~= nil) then
        duokai_lib.net_send_match_list(user_info);
    end
end

-----------------------------------------系统事件----------------------------------------------
--用户登录事件
function matcheslib.on_after_user_login(e)
    local user_info = e.data.userinfo;

    if(matcheslib.user_list[user_info.userId] ~= nil) then
        return;
    end

    local user_match_info = {};
    matcheslib.user_list[user_info.userId] = user_match_info;
    user_match_info.baoming_list = {};

    --取用户报名信息
    matches_db.get_match_join_info_by_userid(user_info.userId, function(dt)
        if (#dt ~= 0) then
            user_match_info.baoming_list = table.loadstring(dt[1].join_info);
            --未参赛上线后退赛
                for k, v in pairs(user_match_info.baoming_list) do
                    local match_info = matcheslib.get_match_info(v.id);
                    if (match_info == nil or match_info.status > 2 or match_info.baoming_list[user_info.userId] == nil) then --比赛已经结束或已经开赛
                         matcheslib.process_give_up(user_info, v.id, 3);
                    end
                end
        end
        --发送已报名列表到客户端
        matcheslib.net_send_user_match_list(user_info);
    end);

end

function matcheslib.update_user_chouma(user_info)
    if(matcheslib.check_match_desk(user_info.desk) == 1) then
        local user_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
        if(user_match_info.match_id ~= nil) then
            local match_info = matcheslib.get_match_info(user_match_info.match_id);
            if(match_info ~= nil and match_info.largebet == nil) then
                matcheslib.update_desk_blind(user_info.desk);
            end
            local result = matches_taotai_lib.check_user_taotai(user_info.userId);
            if(result == 0) then
                user_info.chouma = user_match_info.jifen;
            end
        else
            TraceError("没有参加比赛，为什么会买筹码");
        end
        return 1;
    end
    return 0;
end

function matcheslib.on_buy_chouma(e)
    local userinfo = e.data.userinfo;
    if(matcheslib.update_user_chouma(userinfo) == 1) then
         e.data.handle = 1;
    end
end

function matcheslib.on_send_buy_chouma(e)
    if(matcheslib.check_match_desk(e.data.userinfo.desk) == 1) then
        e.data.handle = 1;

        local user_info = e.data.userinfo;
        matches_taotai_lib.check_user_taotai(user_info.userId);
    end
end

function matcheslib.on_timer_second(e)
    if(matcheslib.check_match_room() == 1) then
        if os.time() - matcheslib.refresh_match_list_time > 5 then
            matcheslib.update_match_list();
            matcheslib.refresh_match_list_time = os.time();
        end
        matcheslib.update_match_bet();
        matcheslib.check_time_match();
        matcheslib.check_die_match();
        matcheslib.notify_all_refresh_match_list();
    end
end

function matcheslib.check_die_match()
    for match_id, v in pairs(matcheslib.match_list) do
        if(v.check_die_time == nil) then
            v.check_die_time = os.time();
        end
        if(v.status == 3 and (v.check_die_time ~= nil and os.time() - v.check_die_time > 60)) then --1分钟检查一次
            v.check_die_time = os.time();
            --比赛进行中
            for deskno, _ in pairs(v.desk_list) do
                --桌子中少于4个人的
                if(deskmgr.get_game_state(deskno) == gameflag.notstart) then
                    local players = deskmgr.getplayers(deskno);
                    if(#players > 0 and #players <= 4) then
                        trystartgame(deskno);
                    end
                end
            end
            matches_taotai_lib.check_match_end(match_id);
        end

        if(v.status == 3) then
            local list = matches_taotai_lib.get_match_list(match_id);
            local is_join = 0;
            if(list.match_list ~= nil) then
                for k1, v1 in pairs(list.match_list) do
                    local user_info = usermgr.GetUserById(k1);
                    if(user_info ~= nil and (user_info.desk == nil or user_info.site == nil) and 
                       v.wait_list ~= nil and v.wait_list[user_info.userId] == nil) then
                        v.wait_list[user_info.userId] = 1;
                        is_join = 1;
                    end
                end

                if(is_join == 1) then
                    matcheslib.auto_join_desk(match_id, v.wait_list, 
                                                      v.desk_list, nil, 
                                                      nil, nil, 0);
                end
            end
        end
    end
end

--判断是否满人赛
function matcheslib.is_manren_match(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and match_info.match_type == 2) then
        return 1;
    end
    return 0;
end

--判断是否定时赛
function matcheslib.is_dingshi_match(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil and match_info.match_type == 1) then
        return 1;
    end
    return 0;
end

--获取比赛至少开赛人数
function matcheslib.get_need_user_count(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        return match_info.need_user_count;
    end
    return -1;
end

--获取报名人数
function matcheslib.get_baoming_count(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        return match_info.match_count;
    end
    return -1;
end

function matcheslib.update_desk_blind(deskno)
    local match_id = matcheslib.desk_list[deskno]
    if(match_id ~= nil) then
        local match_info = matcheslib.get_match_info(match_id);
        if(match_info ~= nil) then
            local deskinfo = desklist[deskno];
            if(match_info.smallbet == nil) then
                local blind_info = matcheslib.get_blind_info(match_id, match_info.blind_stakes_level); 
                if(blind_info == nil) then
                    TraceError("出错了，没有大小盲");
                    blind_info = {smallbet = 25, largebet = 50, ante = 200};
                end
                match_info.smallbet = blind_info.smallbet;
                match_info.largebet = blind_info.largebet;
                match_info.ante = blind_info.ante;
            end
            deskinfo.smallbet = match_info.smallbet;
            deskinfo.largebet = match_info.largebet;
        end
    end
end

function matcheslib.try_start_match(match_id)
    local match_info = matcheslib.get_match_info(match_id);
    local status = 0;
    local match_user_list = {};
    if(match_info ~= nil) then
        match_user_list, status = matches_taotai_lib.try_start_match(match_id);
        if(status == 1) then
            matcheslib.on_match_start(match_id);
            for deskno, _ in pairs(match_info.desk_list) do
                --TraceError("比赛开始。。。。"..deskno);
                trystartgame(deskno);
            end
        end
    end
    return match_user_list, status;
end

function matcheslib.let_wait_user_join_desk(match_id)
    timelib.createplan(function()
        local match_info = matcheslib.get_match_info(match_id);
        if(match_info ~= nil) then
            match_info.joinning = 1;
            --TraceError('等待的用户'..tostringex(match_info.wait_list));
            --多开坐下开始游戏的必然是子账号
            local wait_count = 0;
            for k, v in pairs(match_info.wait_list) do
                --校验用户是否在比赛
                local user_taotai_match_info = matches_taotai_lib.get_user_match_info(k);
                if user_taotai_match_info.match_id == nil or user_taotai_match_info.match_id ~= match_id then
                    match_info.wait_list[k] = nil;
                else
                    wait_count = wait_count + 1;
                end
            end
            xpcall(function()
                matcheslib.auto_join_desk(match_info.id, match_info.wait_list, match_info.desk_list);
            end, throw);
            match_info.joinning = nil;
            matcheslib.let_all_watching_user_join_desk(match_id);
        end
    end, 2);
end

function matcheslib.on_try_start_game(e)
    --TraceError("try_start_game")
    if(matcheslib.check_match_desk(e.data.deskno) == 1) then
        local deskno = e.data.deskno;
        --TraceError("on_try_start_game deskno"..deskno);
        local match_id = matcheslib.desk_list[deskno]
        if(match_id ~= nil) then
            local match_info = matcheslib.get_match_info(match_id);
            --触发淘汰赛开始
            local match_user_list, status = matcheslib.try_start_match(match_id);

            --TraceError("matches_taotai_lib status"..status);
            if(status == 1) then
                --TraceError("比赛可以开始了,让所有桌子开始游戏吧");
                e.data.handle = 1;
            elseif(table.maxn(match_user_list) <= 0 and status ~= 2) then
                --TraceError("游戏还不可以开始");
                matcheslib.update_desk_blind(deskno);
                e.data.handle = 1;
            else
                if(match_info.joinning == nil) then
                    local count = 0;
                    local wait_list = {};
                    local other_list = table.clone(match_user_list);
                    for _, player in pairs(deskmgr.getplayers(deskno)) do
                        local userinfo = player.userinfo;
                        local is_taotai = matches_taotai_lib.check_user_taotai(userinfo.userId);
                        other_list[userinfo.userId] = nil;
                        if(userinfo.desk ~= nil and userinfo.site ~= nil) then
                           if(is_taotai == 0) then
                               count = count + 1;
                               wait_list[userinfo.userId] = 1;
                               matcheslib.update_user_chouma(userinfo);
                           else
                               --让玩家站起吧
                               doStandUpAndWatch(userinfo, 1);
                           end
                        end
                    end
                    local match_count = matches_taotai_lib.get_match_user_count(match_id, 'match');
                    local is_start = 0;

                    if(match_count <= 1) then
                        return;
                    end

                    if(count > 3 or (match_count <= 3 and count == match_count)) then
                        --判断这3个玩家是否在同一桌上,如果不在那么就需要排队分桌
                        is_start = 1;
                    end
                    --如果这座人数少于三人了，则重新排队
                    if(is_start == 1) then
                        --TraceError('开始比赛deskno'..deskno..' wait_list'..tostringex(wait_list));
                        --如果不用分桌，那么就改变盲注 
                        if(match_count > count and match_count <= 9) then
                            --TraceError("剩余不够9个人了,为什么其它人还在其它桌子呢"..tostringex(other_list));
                            for k, v in pairs(other_list) do
                                match_info.wait_list[k] = 1;
                            end
                            matcheslib.let_wait_user_join_desk(match_id);
                        end
                        matcheslib.update_desk_blind(deskno);
                        matches_taotai_lib.g_on_game_start(deskno);
                    else
                        --进行分桌处理
                        --TraceError("开始分桌了 桌子号"..deskno.."桌子人数"..count.." 比赛人数"..match_count);
                        e.data.handle = 1;
                        if(match_info.wait_list == nil) then
                            match_info.wait_list = {};
                        end

                        for k, v in pairs(wait_list) do
                            matches_taotai_lib.notify_continue_play(k);
                            match_info.wait_list[k] = v;
                        end

                        for k, v in pairs(match_info.wait_list) do--先让所有人站起，不然会出现卡死的情况
                            local user_info = usermgr.GetUserById(k);
                            if(user_info ~= nil) then
                                doUserStandup(user_info.key, false);
                            end
                        end
                        matcheslib.let_wait_user_join_desk(match_id);
                    end
                end
            end
        end
    end
end

function matcheslib.on_force_game_over(e)
    local desk_no = e.data.desk_no;
    if(matcheslib.check_match_desk(desk_no) == 1) then
        trystartgame(desk_no);
    end
end

function matcheslib.on_user_sitdown(e)
    local userinfo = e.data.userinfo;
    userinfo.open_match_tab = nil;
    --如果是比赛桌那么需要看看积分够不够
    if(matcheslib.check_match_desk(userinfo.desk) == 1) then
        if(matches_taotai_lib.check_user_taotai(userinfo.userId) ~= 0) then
            --让用户站起吧
            doStandUpAndWatch(userinfo, 1);
        end
    end
end

--收到发牌后，下底注
function matcheslib.on_after_fapai(e)
    local deskno = e.data.deskno;
    local match_id = matcheslib.desk_list[deskno];
    if(match_id ~= nil) then
        local match_info = matcheslib.get_match_info(match_id);
        if(match_info.status == 3) then
            if(match_info.ante ~= nil and match_info.ante > 0) then
                process_dizhu(deskno, match_info.ante); 
            end
        end
    end
end

function matcheslib.on_server_start(e)
    --获取排行榜
    matches_db.get_match_win_info(function(dt)
        if(dt and #dt > 0) then
            for k, v in pairs(dt) do
                if(v.prize_list and v.prize_list ~= "") then
                    v.prize_list = table.loadstring(v.prize_list);
                else
                    v.prize_lsit = {};
                end
            end
            matcheslib.match_win_list = dt;
        end
    end);
end

function matcheslib.on_sub_user_back_to_hall(e)
    local user_info = e.data.user_info;
    if not user_info then return end;
    
    --子帐号退出了，需要清空主帐号报名
    local user_taotai_match_info = matches_taotai_lib.get_user_match_info(user_info.userId); 
    local match_id = user_taotai_match_info.match_id;
    if(match_id ~= nil) then
        local parent_id = duokai_lib.get_parent_id(user_info.userId);
        local match_info = matcheslib.get_match_info(match_id);

        if(parent_id > 0) then
            if(match_info ~= nil) then
                match_info.baoming_list[parent_id] = nil;
                matcheslib.remove_wait_list(match_id, user_info.userId);
            end
            local user_match_info = matcheslib.user_list[parent_id];    
            user_match_info.baoming_list[match_id] = nil;
            user_info = usermgr.GetUserById(parent_id);
            matcheslib.refresh_list(user_info);
        end
    end
end

function matcheslib.get_match_status(match_id)
    local status = 0;
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        status = match_info.status;
    end
    return status;
end

--获取比赛开始时间
function matcheslib.get_match_start_time(match_id)
    local match_start_time = 0;
    local match_info = matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        match_start_time = match_info.match_start_time;
    end
    return match_start_time;
end

function matcheslib.on_back_to_hall(e)
    local user_info = e.data.user_info;
    if not user_info then return end;

    --matcheslib.refresh_list(user_info);     --刷新列表
end

function matcheslib.on_send_duokai_sub_desk(e)
    local user_info = e.data.user_info;
    local extra_list = e.data.extra_list;

    local user_match_info = matcheslib.user_list[user_info.userId];

    if(user_match_info ~= nil) then
        for match_id, v in pairs(user_match_info.baoming_list) do
            local match_info =  matcheslib.get_match_info(match_id);
            if (match_info.match_type == 1 and match_info.status < 3 and match_info.baoming_list[user_info.userId] ~= nil) then
                --定时赛，且未开始
                local left_time = match_info.match_start_time - os.time();
                if(left_time > 0) then
                    table.insert(extra_list, {
                        desk_no = match_id, 
                        desk_name = match_info.match_name, 
                        desk_type = g_DeskType.match, 
                        left_time = left_time,
                        match_count = 0,
                        match_start_count = 0,
                        match_id = match_id});
                end
            end
        end
    end
end

function matcheslib.remove_wait_list(match_id, user_id)
    local match_info =  matcheslib.get_match_info(match_id);
    if(match_info ~= nil) then
        if(match_info.wait_list ~= nil) then
            if(duokai_lib ~= nil and duokai_lib.is_sub_user(user_id) == 0) then
                for k, v in pairs(match_info.wait_list) do
                    local parent_id = duokai_lib.get_parent_id(k);
                    if(user_id == parent_id) then
                        match_info.wait_list[k] = nil;
                        break;
                    end
                end
            else
                match_info.wait_list[user_id] = nil;
            end
        end
    end
end

function matcheslib.on_user_exit(e)
    local user_info = e.data.userinfo;
    if not user_info then return end;

    local user_match_info = matcheslib.user_list[user_info.userId];
    --用户退出客户端时如果报名了满人开赛，需要将参赛人数减1
        if (user_match_info ~= nil) then
            for match_id, v in pairs(user_match_info.baoming_list) do
                local match_info =  matcheslib.get_match_info(match_id);
                if (match_info and match_info.match_type == 2 and match_info.baoming_list[user_info.userId] ~= nil) then
                    --TraceError("用户"..user_info.userId.."退出了客户端,自动退出满人开赛");
                    matcheslib.clear_user_match_info(user_info.userId, match_id);
                end
            end
        end
    matcheslib.user_list[user_info.userId] = nil;
end

function matcheslib.on_recv_pre_join_match(buf)
    local user_info = userlist[getuserid(buf)];
    if(not user_info) then return end;
    local match_id = buf:readString();
    local result = 1;
    local user_match_info = matcheslib.user_list[user_info.userId];
    local match_info = matcheslib.get_match_info(match_id);
    local current_time = os.time();
    if (match_info ~= nil and user_match_info.baoming_list[match_id] ~= nil and
       match_info.match_type == 1) then
        result = matcheslib.check_match(match_info, result);

        if(result == 1 or result == 2) then
            if(current_time <  match_info.match_start_time - matcheslib.CONFIG_PRE_JOIN_TIME or 
               current_time > match_info.match_start_time) then
                result = -3;
            end
            if(result ~= -3) then
                --如果正在比赛那么就需要放弃
                local user_taotai_match_info = matches_taotai_lib.get_user_match_info(user_info.userId);
                if(user_taotai_match_info.match_id ~= nil) then
                    matcheslib.process_give_up(user_info, user_taotai_match_info.match_id, 1);
                end
                matcheslib.go_back_to_hall(user_info);
                matcheslib.apply_desks(match_info.id, matcheslib.get_match_count(match_id));
                local match_user_list = {
                    [user_info.userId] = 1;
                };
                --从大厅直接进入为主账号 需要切换到当前牌桌
                matcheslib.auto_join_desk(match_info.id, match_user_list, match_info.desk_list, 1, 
                                          matcheslib.on_after_join_desk, (user_info.desk == nil and 1 or 0));
            end
        end

        if(result ~= 1 and result ~= 2) then
            matcheslib.net_send_join_match_result(user_info, result, match_info);  --报名结果
            matcheslib.refresh_list(user_info);
        end
    else
        matcheslib.refresh_list(user_info);
    end
end

--命令列表
cmdHandler =
{
    ["MATCHTTPREJ"] = matcheslib.on_recv_pre_join_match,
    ["MATCHTTLIST"] = matcheslib.on_recv_match_list,
    ["MATCHTTJM"]   = matcheslib.on_recv_join_match,
    ["MATCHTTAFFIRM"] = matcheslib.on_recv_join_match_affirm,
    ["MATCHJXGZ"]   = matcheslib.on_recv_continue_watch,
    ["MATCHTTGIVEUP"] = matcheslib.on_recv_match_give_up,
    ["MATCHTTRULE"] = matcheslib.on_recv_match_rule,

    --服务器通讯协议
    ["MATCHTTTIXING"] = matcheslib.on_recv_tixing,
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end


eventmgr:addEventListener("h2_on_user_login", matcheslib.on_after_user_login)
eventmgr:addEventListener("on_buy_chouma", matcheslib.on_buy_chouma)
eventmgr:addEventListener("on_send_buy_chouma", matcheslib.on_send_buy_chouma);
eventmgr:addEventListener("timer_second", matcheslib.on_timer_second);
eventmgr:addEventListener("on_try_start_game", matcheslib.on_try_start_game);
eventmgr:addEventListener("on_server_start", matcheslib.on_server_start);
eventmgr:addEventListener("back_to_hall", matcheslib.on_back_to_hall);
eventmgr:addEventListener("do_kick_user_event", matcheslib.on_user_exit);
eventmgr:addEventListener("on_send_duokai_sub_desk", matcheslib.on_send_duokai_sub_desk);
eventmgr:addEventListener("on_after_fapai", matcheslib.on_after_fapai);
eventmgr:addEventListener("on_sub_user_back_to_hall", matcheslib.on_sub_user_back_to_hall);
eventmgr:addEventListener("site_event", matcheslib.on_user_sitdown);
eventmgr:addEventListener("on_force_game_over", matcheslib.on_force_game_over);

