TraceError("init newer quest....")


if tasklib and tasklib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", tasklib.on_user_exit)
end

if tasklib and tasklib.on_game_over then
	eventmgr:removeEventListener("game_event", tasklib.on_game_over)
end

if tasklib and tasklib.on_user_add_friend then
	eventmgr:removeEventListener("want_add_friend", tasklib.on_user_add_friend)
end

if tasklib and tasklib.on_user_upgrade_level then
    eventmgr:removeEventListener("user_level_event", tasklib.on_user_upgrade_level)
end

if tasklib and tasklib.on_meet_event then
    eventmgr:removeEventListener("meet_event",  tasklib.on_meet_event);
end

if tasklib and tasklib.on_back_to_hall then
    eventmgr:removeEventListener("back_to_hall",  tasklib.on_back_to_hall);
end

if tasklib and tasklib.on_back_to_hall then
    eventmgr:removeEventListener("on_sub_user_back_to_hall",  tasklib.on_back_to_hall);
end

if tasklib and tasklib.on_kick_user then
    eventmgr:removeEventListener("do_kick_user_event",  tasklib.on_kick_user);
end

if tasklib and tasklib.on_user_sit_down then
    eventmgr:removeEventListener("site_event",  tasklib.on_user_sit_down);
end

if tasklib and tasklib.on_after_sub_user_login then
    eventmgr:removeEventListener("h2_on_sub_user_login",  tasklib.on_after_sub_user_login);
end

if not tasklib then 
    tasklib = _S
    {
        
        ---------内部函数----------------------------------------------
        make_new_task = NULL_FUNC, --产生新任务
        update_task_progress = NULL_FUNC, --更新任务进度
        give_task_prize = NULL_FUNC, --发奖
        is_finish_task = NULL_FUNC,--是否完成任务

        ---------客户端发送----------------------------------------------
        net_send_newer_task_info = NULL_FUNC, --发送新手任务
        net_send_task_progress = NULL_FUNC, --发送新手任务进度
        net_send_task_finished = NULL_FUNC, --发送新手任务完成
        net_send_task_cfg      = NULL_FUNC, --发送任务奖励配置

        ---------系统事件----------------------------------------------
        on_after_user_login = NULL_FUNC,            --登录事件
        on_user_exit = NULL_FUNC,                   --用户退出
        on_game_over = NULL_FUNC,                   --用户完成一盘游戏
        on_user_upgrade_level = NULL_FUNC,           --用户升级
        on_user_add_friend = NULL_FUNC,                   --用户加了好友
        on_user_sit_down = NULL_FUNC,				--用户坐下

        ---------客户端请求----------------------------------------------
        on_recv_open_wnd = NULL_FUNC,                   --请求打开新手任务窗口
        on_recv_award    = NULL_FUNC,                   --请求领奖

        STATIC_TASK_COUNT = 5,      --新手任务总数
        STATIC_PAIXIN_POKELIST = 2, --牌型中牌的列表数量
        user_list = {},
        task_list = {       --任务列表
            [1] = {
                total = 1,      --所需要的总进度
                count = 1,
                [1]={
                prize_type = 1,     --筹码
                prize_count = 200, --数量
                },
            },
            [2] = {
                total = 1,      --所需要的总进度
                count = 1,
                [1] = {
                prize_type = 1,     --筹码
                prize_count = 300, --数量
                },
            },
            [3] = {
                total = 1,      --所需要的总进度
                count = 1,
                [1]={
                prize_type = 1,     --筹码
                prize_count = 500, --数量
                },
            },
            [4] = {
                total = 1,      --所需要的总进度
                count = 1,
                [1] = {
                prize_type = 1,     --筹码
                prize_count = 1000, --数量
                },
            },
            [5] = {
                total = 1,      --所需要的总进度
                count = 3,
                [1] = {
                prize_type = 3,     --新手勋章
                prize_count = 1, --数量
                },
                [2] = {
                prize_type = 2,  --每日任务奖卷2张
                prize_count = 2, --数量
                },
                [3] = {
                prize_type = 4,  --开通达人家园
                prize_count = 1,
                },
            },
            [6] = {--日常任务图标提示
                total = 1,
                count = 0,
            },
        },

        task_gift_list = {
            [1] = {
                name = _U("筹码"),
            },
            [2] = {
                name = _U("每日任务奖券%d张"),
            },
            [3] = {
                name = _U("$%d新手勋章一枚"),
            },
            [4] = {
                name = _U("开通达人家园"),
            },
        },
    }
end
---------------------------------- 逻辑 --------------------------------------
tasklib.is_new_user = function(user_info)
    local level = usermgr.getlevel(user_info);
    if(level < 2) then
        return 1;
    end
    return 0;
end

tasklib.is_finish_task = function(user_info, task_info)

    if(task_info == nil) then
        task_info = tasklib.user_list[user_info.userId];
    end

    local is_finish = 0;
    if task_info == nil or task_info.task_id > tasklib.STATIC_TASK_COUNT or task_info.task_list[tasklib.STATIC_TASK_COUNT] == 1 then
        is_finish = 1;
    end
    return is_finish;
end


tasklib.on_recv_open_daily_task = function(buf)
    local user_info = userlist[getuserid(buf)]
    local task_info = tasklib.user_list[user_info.userId];
    if user_info == nil or task_info == nil then return end
    if(task_info.task_id == 6) then
        tasklib.update_task_progress(user_info, task_info.task_id);
    end
end

tasklib.do_give_prize = function(user_info, task_id)
    if(user_info == nil) then
        return;
    end
    --是否完成任务
    local task_info = tasklib.user_list[user_info.userId];
    if(task_info.task_list[task_id] ~= nil and task_info.task_list[task_id] == 0) then
        if(task_info.task_id == tasklib.STATIC_TASK_COUNT 
           and task_info.task_list[task_info.task_id] ~= nil 
           and task_info.task_list[task_info.task_id] == 0) then
            --最后一个任务领奖了
            task_info.task_list[task_id] = 1;
            tasklib.net_send_task_finished(user_info);
        else
            task_info.task_list[task_id] = 1;
            if task_id > 0 and task_id <= tasklib.STATIC_TASK_COUNT then
                for i = 1, tasklib.task_list[task_id].count do
                    tasklib.give_task_prize(user_info,tasklib.task_list[task_id][i].prize_type,tasklib.task_list[task_id][i].prize_count);
                end
            end

            local get_prize_count = 0;
            for k, v in pairs(task_info.task_list) do
                if(v == 1) then
                    get_prize_count = get_prize_count + 1;
                end
            end

            --四个任务都领取完了和最后一个任务还未开始才激活最后任务
            local over_task_id = tasklib.STATIC_TASK_COUNT;
            if(get_prize_count == tasklib.STATIC_TASK_COUNT - 1 and task_info.task_list[over_task_id] == nil) then
                --任务完成,进入领奖状态
                tasklib.update_task_progress(user_info, over_task_id);
            else
                dblib.cache_set("user_quest_info", {task_list=table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);

                tasklib.net_send_newer_task_info(user_info, 2);
            end
        end
    end
end

tasklib.on_recv_award = function(buf)
    local user_info = userlist[getuserid(buf)]
    if user_info == nil then return end
    local task_id = buf:readInt();
    if(task_id == tasklib.STATIC_TASK_COUNT) then
        for i = 1, task_id - 1 do
            tasklib.do_give_prize(user_info, i);
        end
        timelib.createplan(function()
            tasklib.do_give_prize(user_info, task_id);
        end, 2);
    else
        tasklib.do_give_prize(user_info, task_id);
    end
end

tasklib.on_recv_open_wnd = function(buf)
    local user_info = userlist[getuserid(buf)]
    if user_info == nil or tasklib.user_list[user_info.userId] == nil then return end

    tasklib.net_send_newer_task_info(user_info);
end

tasklib.update_task_progress = function(user_info,task_id)
    local task_info = tasklib.user_list[user_info.userId];
    if task_info == nil or task_info.task_id ~= task_id then
        return
    end
    local finish_count = tasklib.task_list[task_info.task_id].total;

    if(task_info.progress >= finish_count) then
        --该任务已经完成了,等待领奖了吧
        return;
    end

    local last_task_id = task_id -1;
    local make_new = 0; 
    task_info.progress = task_info.progress + 1
    if(finish_count == task_info.progress and task_info.task_list[task_id] == nil) then
        --已经完成任务了,进行领奖吧
        task_info.task_list[task_id] = 0;

        --进行下一个任务
        if(task_id + 1 <= tasklib.STATIC_TASK_COUNT) then
            make_new = 1;
            tasklib.make_new_task(user_info, task_id + 1);
        end
    end
    
    if(make_new == 0) then
        dblib.cache_set("user_quest_info", {task_id = task_id, progress = task_info.progress, sys_time=timelib.lua_to_db_time(os.time()), task_list=table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);
    end


    local level = usermgr.getlevel(user_info);
    if(task_info.task_id == 4 and level >= 2) then
        --生到两级的任务,如果用户现在就已经两级以上则直接完成任务
        tasklib.update_task_progress(user_info, task_info.task_id);
    else
        --通知用户进度
        tasklib.net_send_task_progress(user_info);
    
        --通知用户刷新界面
        tasklib.net_send_newer_task_info(user_info, make_new == 1 and 1 or 2);
    end
end


tasklib.on_user_upgrade_level = function(e)
    local user_info = e.data.userinfo;
    local from_level = e.data.from_level;
    local to_level = e.data.to_level;
    if(user_info ~= nil) then
        if(from_level <= 1 and to_level > 1 or to_level >= 2) then
            tasklib.update_task_progress(user_info, 4);
        end
    end
end

tasklib.on_user_add_friend = function(e)
    local user_info;
    if e == nil then return end   
    if e.data ~= nil then
        user_info = e.data.from_user_info
    else
        return;
    end

    tasklib.net_send_show_add_friend_tips(e.data.from_user_info, 0);
    tasklib.net_send_show_add_friend_tips(e.data.to_user_info, 0);
    tasklib.update_task_progress(user_info, 2);
end



tasklib.on_game_over = function(e)
    for k, v in pairs(e.data) do
        if v.iswin == 1 then
            local user_info = usermgr.GetUserById(v.userid);
            local task_info = tasklib.user_list[v.userid];
            local deskinfo = desklist[user_info.desk];
            if(deskinfo.desktype == g_DeskType.match) then
                return;
            end
            if(task_info ~= nil and v.wingold > 0) then
                tasklib.update_task_progress(user_info,3);
            end
        end
    end
end

--初始化新手任务
tasklib.init_task = function(user_info, callback)
    task_db_lib.init_quest_info(user_info.userId, 1, 0, {}, callback);
end

--产生新任务
--参数：用户ID，任务ID
tasklib.make_new_task = function(user_info, task_id)
    local user_id = user_info.userId
    local task_info = tasklib.user_list[user_id];

    if task_info == nil then
        return
    end

    task_info.task_id = task_id; --任务ID
    task_info.progress = 0;    --完成的盘数

    dblib.cache_set("user_quest_info", {task_id=task_id, progress=tasklib.user_list[user_id].progress, sys_time=timelib.lua_to_db_time(os.time()), task_list=table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);

    --tasklib.show_add_friend_tips(user_info, task_info);
end

tasklib.show_add_friend_tips = function(user_info, task_info)
    if(user_info == nil or task_info == nil) then
        return;
    end
    if(task_info.task_id == 2 and user_info.desk ~= nil and user_info.site ~= nil) then --加好友任务
		local players = deskmgr.getplayers(user_info.desk);
        for k, v in pairs(players) do
            if(v.userinfo.userId ~= user_info.userId and user_info.friends[v.userinfo.userId] == nil and task_info.show_tips_id == nil) then
                local refuse = 0;
                if v.userinfo.refuselist ~= nil then
                    for k,v in pairs(v.userinfo.refuselist) do
                        if tonumber(v) == user_info.userId then
                            refuse = 1
                            break
                        end
                    end
                end
                if(refuse == 0) then
                    task_info.show_tips_id = v.userinfo.userId;
                    tasklib.net_send_show_add_friend_tips(user_info, 1, v.userinfo);
                    break;
                end
            end
        end
    end
end


tasklib.give_task_prize = function(user_info,prize_type,prize_count)
    if prize_count <= 0 then return end

    if(prize_type == 1) then
        usermgr.addgold(user_info.userId, prize_count, 0, new_gold_type.TASK_PRIZE, -1);
    elseif(prize_type == 2)then
        --每日任务奖卷
        tex_dailytask_lib.add_lottery_count(user_info, prize_count);
    elseif(prize_type == 3) then
        --新手礼包
        gift_addgiftitem(user_info, 5035, 1000, "", true);
		dispatchMeetEvent(user_info);
    elseif(prize_type == 4)then
        --通知大厅显示开通家园提示
        dhomelib.update_user_home_info(user_info.userId);
        dhomelib.update_user_home_status(user_info);
        --通知玩家提示
        user_info.home_status = 1;
        tasklib.net_send_show_open_home(user_info);
    end

    --[[
    if prize_type == 1 then --欢乐豆
        usermgr.addbean(user_info.userId, prize_count, g_TransType.XINSHOU, groupinfo.groupid, 0)
    elseif prize_type == 2 then --金币
        usermgr.addgold(user_info.userId, prize_count, 0, tSqlTemplete.goldType.XIN_SHOU,-1)
    elseif prize_type == 3 then --小喇叭
        bag.add_item(user_info, {item_id = 4, item_num = prize_count}, nil, bag.log_type.XINSHOU);	
    elseif prize_type == 4 then --荣誉翻倍卡
        bag.add_item(user_info, {item_id = 1, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    elseif prize_type == 5 then --清零卡
        bag.add_item(user_info, {item_id = 3, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    elseif prize_type == 6 then --声望翻倍卡
        bag.add_item(user_info, {item_id = 2, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    end
    --]]

end

tasklib.net_send_task_finished = function(user_info)
    if tasklib.user_list[user_info.userId] == nil then return end

    local task_info = tasklib.user_list[user_info.userId];

    local task_id = task_info.task_id;

    if(task_id ~= tasklib.STATIC_TASK_COUNT) then
        TraceError('还没有完成任务吧userid'..user_info.userId);
        return;
    end

    for i = 1, tasklib.task_list[task_id].count do
        tasklib.give_task_prize(user_info,tasklib.task_list[task_id][i].prize_type,tasklib.task_list[task_id][i].prize_count);
    end

    task_info.task_id = task_info.task_id + 1;
    task_info.progress = 0;
    dblib.cache_set("user_quest_info", {task_id = task_info.task_id, progress = task_info.progress, sys_time=timelib.lua_to_db_time(os.time()), task_list = table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);

    --发奖
    netlib.send(function(buf)
        buf:writeString("NTKTASKOVER")
        buf:writeInt(task_info.task_id - 1);
    end, user_info.ip, user_info.port)

    
end

tasklib.net_send_show_open_home = function(user_info)
    netlib.send(function(buf)
        buf:writeString("NTKTASKHOME");
        buf:writeInt(user_info.home_status);
    end, user_info.ip, user_info.port);
end

tasklib.net_send_task_progress = function(user_info)
    if tasklib.user_list[user_info.userId] == nil then return end

    local task_info = tasklib.user_list[user_info.userId];

    netlib.send(function(buf)
        buf:writeString("NTKTASKPG")
        buf:writeInt(task_info.progress)
    end, user_info.ip, user_info.port)
end

tasklib.net_send_task_cfg = function(user_info)
    netlib.send(function(buf)
        buf:writeString("NTKTASKCFG");
        buf:writeInt(5);
        for k, v in pairs(tasklib.task_list) do
            buf:writeInt(k);
            buf:writeInt(v.count);
            for i = 1, v.count do
                local prize_type = v[i].prize_type;
                local prize_count = v[i].prize_count;
                buf:writeInt(prize_type);
                buf:writeInt(prize_count);
                local name = tasklib.task_gift_list[prize_type].name;
                if(prize_type == 1) then
                    name = prize_count .. name; 
                elseif(prize_type == 2) then
                    name = string.format(name, prize_count);
                elseif(prize_type == 3) then
                    name = "what name";
                end
                buf:writeString(name);
            end
        end
    end, user_info.ip, user_info.port);
end

--show_type,0:表示打开面板，1:产生新的任务, 2：更新任务数据
tasklib.net_send_newer_task_info = function(user_info,show_type)
    if tasklib.user_list[user_info.userId] == nil then return end

    local task_info = tasklib.user_list[user_info.userId];

    netlib.send(function(buf)
        buf:writeString("NTKTASKFN")
        buf:writeInt(task_info.task_id or 0)
        buf:writeInt(task_info.progress)    --完成数
        buf:writeInt(tasklib.task_list[task_info.task_id].total)   --完成所需总数
        buf:writeByte(show_type or 0);
        local count = 0;
        for k, v in pairs(task_info.task_list) do
            count = count + 1;
        end
        buf:writeInt(count);
        for k, v in pairs(task_info.task_list) do
            buf:writeInt(k);--任务id
            buf:writeByte(v);--是否有领取
        end
    end, user_info.ip, user_info.port)
end

--子帐号登录
tasklib.on_after_sub_user_login = function(e)
    local user_info = e.data.userinfo;
    if(duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 1) then
       local parent_id = duokai_lib.get_parent_id(user_info.userId);
       if(tasklib.user_list[parent_id] ~= nil) then
           tasklib.user_list[user_info.userId] = tasklib.user_list[parent_id];
       end
   end
end


--用户登录后数据已经同步成功后的事件
tasklib.on_after_user_login = function(user_info)
    if(user_info == nil) then
        return;
    end
    local load_task_callback = function()
        --读取数据库的进度
        local call_back = function(dt)
            local task_info = dt ~= nil and #dt > 0 and dt[1] or nil;
            --不是新手的开通家园
            if(user_info.home_status == 0 and tasklib.is_new_user(user_info) == 0 and tasklib.is_finish_task(user_info, task_info) == 1) then
              dhomelib.update_user_home_info(user_info.userId);
              dhomelib.update_user_home_status(user_info);
              user_info.home_status = 1;
              tasklib.net_send_show_open_home(user_info);
            end

            if(task_info == nil) then
                do return end;
            end

            if(task_info.task_list ~= nil and task_info.task_list ~= "") then
                task_info.task_list = table.loadstring(task_info.task_list);
            else
                task_info.task_list = {};
            end
    
            
            --是否已经完成新手任务
            if(tasklib.is_finish_task(user_info, task_info) == 1 
               and task_info.task_id >= 6 
               and task_info.progress == 1) then
                return;
            end

            tasklib.user_list[user_info.userId] = task_info; 
            tasklib.net_send_task_cfg(user_info);
            tasklib.net_send_newer_task_info(user_info, 2);
        end
        dblib.cache_exec("getquestinfo", {user_info.userId}, call_back);
    end
    if(tasklib.is_new_user(user_info) == 1) then
        --如果是新手，则先初始化数据库
        tasklib.init_task(user_info, load_task_callback);
    else
        --直接读取数据库
        load_task_callback();
    end
end

--用户断线事件
tasklib.on_user_exit = function(e)
    --清除内存数据
    tasklib.user_list[e.data.user_id] = nil;
end

tasklib.on_meet_event = function(e)
    local from_user_info = e.data.observer;
    local to_user_info = e.data.subject;
    local task_info = tasklib.user_list[from_user_info.userId];
    if(task_info == nil) then
        return;
    end

    local to_parent_id = to_user_info.userId;
    if(duokai_lib and duokai_lib.is_sub_user(to_parent_id) == 1)then
        to_parent_id = duokai_lib.get_parent_id(to_user_info.userId);
    end

   if(from_user_info.userId == to_user_info.userId and from_user_info.site == nil
       and task_info.task_id == 2 and task_info.show_tips_id ~= nil) then
       --自己站起了
       task_info.show_tips_id = nil;
       tasklib.net_send_show_add_friend_tips(from_user_info, 0);
   elseif(from_user_info.userId ~= to_user_info.userId and to_user_info.site == nil 
       and task_info.task_id == 2 
       and task_info.show_tips_id ~= nil
       and task_info.show_tips_id == to_user_info.userId) then
       --别人站起了
       task_info.show_tips_id = nil;
       tasklib.net_send_show_add_friend_tips(from_user_info, 0);
    elseif(task_info ~= nil and task_info.task_id == 2 
       and from_user_info.userId ~= to_user_info.userId
       and from_user_info.site ~= nil
       and to_user_info.site ~= nil
       and task_info.show_tips_id == nil
       and from_user_info.friends ~= nil and from_user_info.friends[to_parent_id] == nil) then
            local refuse = 0;
            if to_user_info.refuselist ~= nil then
                for k,v in pairs(to_user_info.refuselist) do
                    if tonumber(v) == from_user_info.userId then
                        refuse = 1
                        break
                    end
                end
            end
            if(refuse == 0) then
                 --显示加好友提示
                 task_info.show_tips_id = to_user_info.userId;
                 tasklib.net_send_show_add_friend_tips(from_user_info, 1, to_user_info);
            end
    end
end

tasklib.net_send_show_add_friend_tips = function(user_info, is_show, to_user_info)
    if(user_info.desk) then
        local deskinfo = desklist[user_info.desk];
        if(deskinfo.desktype == g_DeskType.match) then
            return;
        end
    end
    netlib.send(function(buf)
        buf:writeString("NTKTASKFRTIPS");
        buf:writeByte(is_show);
        buf:writeInt(to_user_info and to_user_info.site or 0);
        buf:writeInt(to_user_info and to_user_info.userId or 0);
    end, user_info.ip, user_info.port);
end

tasklib.on_back_to_hall = function(e)
    local user_info = e.data.userinfo;
    local deskno = user_info.desk;
    local siteno = user_info.site;
    if(deskno ~= nil and deskno > 0) then
        for i = 1, room.cfg.DeskSiteCount do
			local userinfo = userlist[hall.desk.get_user(deskno, i)];
			if userinfo then
                local task_info = tasklib.user_list[userinfo.userId];
                if(task_info ~= nil and task_info.show_tips_id == user_info.userId) then
                    task_info.show_tips_id = nil;
                    tasklib.net_send_show_add_friend_tips(userinfo, 0);
                end
			end
		end
    end
end


tasklib.on_recv_show_friend_tips = function(buf)
    local user_info = userlist[getuserid(buf)];
    if(user_info == nil) then return end;
    local task_info = tasklib.user_list[user_info.userId];
    tasklib.show_add_friend_tips(user_info, task_info);
end


tasklib.on_kick_user = function(e) 
    local user_info = e.data.userinfo;
    if(user_info ~= nil) then
        tasklib.on_back_to_hall(e);
    end
end

tasklib.on_user_sit_down = function(e)
	local user_id = e.data.user_id;
	local task_info = tasklib.user_list[user_id];
    local user_info = usermgr.GetUserById(user_id);
    if  task_info ~= nil and user_info then
        local deskinfo = desklist[user_info.desk];
        if(task_info.task_id == 1 and deskinfo.desktype ~= g_DeskType.match) then
            tasklib.update_task_progress(user_info, task_info.task_id);
        end
    end
end

--用户退出
eventmgr:addEventListener("on_user_exit", tasklib.on_user_exit);
--游戏结束
eventmgr:addEventListener("game_event", tasklib.on_game_over);
--想加某人为好友
eventmgr:addEventListener("want_add_friend", tasklib.on_user_add_friend);
--坐下
eventmgr:addEventListener("site_event", tasklib.on_user_sit_down);
--用户升级时
eventmgr:addEventListener("user_level_event", tasklib.on_user_upgrade_level);
--坐下时
eventmgr:addEventListener("meet_event",  tasklib.on_meet_event);
--返回大厅
eventmgr:addEventListener("back_to_hall",  tasklib.on_back_to_hall);
eventmgr:addEventListener("on_sub_user_back_to_hall",  tasklib.on_back_to_hall);
--离开游戏
eventmgr:addEventListener("do_kick_user_event",  tasklib.on_kick_user);
--子帐号登录
eventmgr:addEventListener("h2_on_sub_user_login", tasklib.on_after_sub_user_login);





--命令列表
cmdHandler = 
{
	------------------------- 任务协议 ----------------------------
    ["NTKOPEN"] = tasklib.on_recv_open_wnd,    --请求打开新手任务框
    ["NTKAWARD"] = tasklib.on_recv_award,      --请求领奖
    ["NTKODT"]    = tasklib.on_recv_open_daily_task, --请求更新进度
    ["NTKTASKFRTIPS"] = tasklib.on_recv_show_friend_tips,--请求显示加好友提示
    --["NTKSTART"] = tasklib.on_recv_start,         --接受任务
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
