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
        
        ---------�ڲ�����----------------------------------------------
        make_new_task = NULL_FUNC, --����������
        update_task_progress = NULL_FUNC, --�����������
        give_task_prize = NULL_FUNC, --����
        is_finish_task = NULL_FUNC,--�Ƿ��������

        ---------�ͻ��˷���----------------------------------------------
        net_send_newer_task_info = NULL_FUNC, --������������
        net_send_task_progress = NULL_FUNC, --���������������
        net_send_task_finished = NULL_FUNC, --���������������
        net_send_task_cfg      = NULL_FUNC, --��������������

        ---------ϵͳ�¼�----------------------------------------------
        on_after_user_login = NULL_FUNC,            --��¼�¼�
        on_user_exit = NULL_FUNC,                   --�û��˳�
        on_game_over = NULL_FUNC,                   --�û����һ����Ϸ
        on_user_upgrade_level = NULL_FUNC,           --�û�����
        on_user_add_friend = NULL_FUNC,                   --�û����˺���
        on_user_sit_down = NULL_FUNC,				--�û�����

        ---------�ͻ�������----------------------------------------------
        on_recv_open_wnd = NULL_FUNC,                   --������������񴰿�
        on_recv_award    = NULL_FUNC,                   --�����콱

        STATIC_TASK_COUNT = 5,      --������������
        STATIC_PAIXIN_POKELIST = 2, --�������Ƶ��б�����
        user_list = {},
        task_list = {       --�����б�
            [1] = {
                total = 1,      --����Ҫ���ܽ���
                count = 1,
                [1]={
                prize_type = 1,     --����
                prize_count = 200, --����
                },
            },
            [2] = {
                total = 1,      --����Ҫ���ܽ���
                count = 1,
                [1] = {
                prize_type = 1,     --����
                prize_count = 300, --����
                },
            },
            [3] = {
                total = 1,      --����Ҫ���ܽ���
                count = 1,
                [1]={
                prize_type = 1,     --����
                prize_count = 500, --����
                },
            },
            [4] = {
                total = 1,      --����Ҫ���ܽ���
                count = 1,
                [1] = {
                prize_type = 1,     --����
                prize_count = 1000, --����
                },
            },
            [5] = {
                total = 1,      --����Ҫ���ܽ���
                count = 3,
                [1] = {
                prize_type = 3,     --����ѫ��
                prize_count = 1, --����
                },
                [2] = {
                prize_type = 2,  --ÿ�����񽱾�2��
                prize_count = 2, --����
                },
                [3] = {
                prize_type = 4,  --��ͨ���˼�԰
                prize_count = 1,
                },
            },
            [6] = {--�ճ�����ͼ����ʾ
                total = 1,
                count = 0,
            },
        },

        task_gift_list = {
            [1] = {
                name = _U("����"),
            },
            [2] = {
                name = _U("ÿ������ȯ%d��"),
            },
            [3] = {
                name = _U("$%d����ѫ��һö"),
            },
            [4] = {
                name = _U("��ͨ���˼�԰"),
            },
        },
    }
end
---------------------------------- �߼� --------------------------------------
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
    --�Ƿ��������
    local task_info = tasklib.user_list[user_info.userId];
    if(task_info.task_list[task_id] ~= nil and task_info.task_list[task_id] == 0) then
        if(task_info.task_id == tasklib.STATIC_TASK_COUNT 
           and task_info.task_list[task_info.task_id] ~= nil 
           and task_info.task_list[task_info.task_id] == 0) then
            --���һ�������콱��
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

            --�ĸ�������ȡ���˺����һ������δ��ʼ�ż����������
            local over_task_id = tasklib.STATIC_TASK_COUNT;
            if(get_prize_count == tasklib.STATIC_TASK_COUNT - 1 and task_info.task_list[over_task_id] == nil) then
                --�������,�����콱״̬
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
        --�������Ѿ������,�ȴ��콱�˰�
        return;
    end

    local last_task_id = task_id -1;
    local make_new = 0; 
    task_info.progress = task_info.progress + 1
    if(finish_count == task_info.progress and task_info.task_list[task_id] == nil) then
        --�Ѿ����������,�����콱��
        task_info.task_list[task_id] = 0;

        --������һ������
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
        --��������������,����û����ھ��Ѿ�����������ֱ���������
        tasklib.update_task_progress(user_info, task_info.task_id);
    else
        --֪ͨ�û�����
        tasklib.net_send_task_progress(user_info);
    
        --֪ͨ�û�ˢ�½���
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

--��ʼ����������
tasklib.init_task = function(user_info, callback)
    task_db_lib.init_quest_info(user_info.userId, 1, 0, {}, callback);
end

--����������
--�������û�ID������ID
tasklib.make_new_task = function(user_info, task_id)
    local user_id = user_info.userId
    local task_info = tasklib.user_list[user_id];

    if task_info == nil then
        return
    end

    task_info.task_id = task_id; --����ID
    task_info.progress = 0;    --��ɵ�����

    dblib.cache_set("user_quest_info", {task_id=task_id, progress=tasklib.user_list[user_id].progress, sys_time=timelib.lua_to_db_time(os.time()), task_list=table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);

    --tasklib.show_add_friend_tips(user_info, task_info);
end

tasklib.show_add_friend_tips = function(user_info, task_info)
    if(user_info == nil or task_info == nil) then
        return;
    end
    if(task_info.task_id == 2 and user_info.desk ~= nil and user_info.site ~= nil) then --�Ӻ�������
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
        --ÿ�����񽱾�
        tex_dailytask_lib.add_lottery_count(user_info, prize_count);
    elseif(prize_type == 3) then
        --�������
        gift_addgiftitem(user_info, 5035, 1000, "", true);
		dispatchMeetEvent(user_info);
    elseif(prize_type == 4)then
        --֪ͨ������ʾ��ͨ��԰��ʾ
        dhomelib.update_user_home_info(user_info.userId);
        dhomelib.update_user_home_status(user_info);
        --֪ͨ�����ʾ
        user_info.home_status = 1;
        tasklib.net_send_show_open_home(user_info);
    end

    --[[
    if prize_type == 1 then --���ֶ�
        usermgr.addbean(user_info.userId, prize_count, g_TransType.XINSHOU, groupinfo.groupid, 0)
    elseif prize_type == 2 then --���
        usermgr.addgold(user_info.userId, prize_count, 0, tSqlTemplete.goldType.XIN_SHOU,-1)
    elseif prize_type == 3 then --С����
        bag.add_item(user_info, {item_id = 4, item_num = prize_count}, nil, bag.log_type.XINSHOU);	
    elseif prize_type == 4 then --����������
        bag.add_item(user_info, {item_id = 1, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    elseif prize_type == 5 then --���㿨
        bag.add_item(user_info, {item_id = 3, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    elseif prize_type == 6 then --����������
        bag.add_item(user_info, {item_id = 2, item_num = prize_count}, nil, bag.log_type.XINSHOU);
    end
    --]]

end

tasklib.net_send_task_finished = function(user_info)
    if tasklib.user_list[user_info.userId] == nil then return end

    local task_info = tasklib.user_list[user_info.userId];

    local task_id = task_info.task_id;

    if(task_id ~= tasklib.STATIC_TASK_COUNT) then
        TraceError('��û����������userid'..user_info.userId);
        return;
    end

    for i = 1, tasklib.task_list[task_id].count do
        tasklib.give_task_prize(user_info,tasklib.task_list[task_id][i].prize_type,tasklib.task_list[task_id][i].prize_count);
    end

    task_info.task_id = task_info.task_id + 1;
    task_info.progress = 0;
    dblib.cache_set("user_quest_info", {task_id = task_info.task_id, progress = task_info.progress, sys_time=timelib.lua_to_db_time(os.time()), task_list = table.tostring(task_info.task_list)}, "user_id", user_info.userId, nil, user_info.userId);

    --����
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

--show_type,0:��ʾ����壬1:�����µ�����, 2��������������
tasklib.net_send_newer_task_info = function(user_info,show_type)
    if tasklib.user_list[user_info.userId] == nil then return end

    local task_info = tasklib.user_list[user_info.userId];

    netlib.send(function(buf)
        buf:writeString("NTKTASKFN")
        buf:writeInt(task_info.task_id or 0)
        buf:writeInt(task_info.progress)    --�����
        buf:writeInt(tasklib.task_list[task_info.task_id].total)   --�����������
        buf:writeByte(show_type or 0);
        local count = 0;
        for k, v in pairs(task_info.task_list) do
            count = count + 1;
        end
        buf:writeInt(count);
        for k, v in pairs(task_info.task_list) do
            buf:writeInt(k);--����id
            buf:writeByte(v);--�Ƿ�����ȡ
        end
    end, user_info.ip, user_info.port)
end

--���ʺŵ�¼
tasklib.on_after_sub_user_login = function(e)
    local user_info = e.data.userinfo;
    if(duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 1) then
       local parent_id = duokai_lib.get_parent_id(user_info.userId);
       if(tasklib.user_list[parent_id] ~= nil) then
           tasklib.user_list[user_info.userId] = tasklib.user_list[parent_id];
       end
   end
end


--�û���¼�������Ѿ�ͬ���ɹ�����¼�
tasklib.on_after_user_login = function(user_info)
    if(user_info == nil) then
        return;
    end
    local load_task_callback = function()
        --��ȡ���ݿ�Ľ���
        local call_back = function(dt)
            local task_info = dt ~= nil and #dt > 0 and dt[1] or nil;
            --�������ֵĿ�ͨ��԰
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
    
            
            --�Ƿ��Ѿ������������
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
        --��������֣����ȳ�ʼ�����ݿ�
        tasklib.init_task(user_info, load_task_callback);
    else
        --ֱ�Ӷ�ȡ���ݿ�
        load_task_callback();
    end
end

--�û������¼�
tasklib.on_user_exit = function(e)
    --����ڴ�����
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
       --�Լ�վ����
       task_info.show_tips_id = nil;
       tasklib.net_send_show_add_friend_tips(from_user_info, 0);
   elseif(from_user_info.userId ~= to_user_info.userId and to_user_info.site == nil 
       and task_info.task_id == 2 
       and task_info.show_tips_id ~= nil
       and task_info.show_tips_id == to_user_info.userId) then
       --����վ����
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
                 --��ʾ�Ӻ�����ʾ
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

--�û��˳�
eventmgr:addEventListener("on_user_exit", tasklib.on_user_exit);
--��Ϸ����
eventmgr:addEventListener("game_event", tasklib.on_game_over);
--���ĳ��Ϊ����
eventmgr:addEventListener("want_add_friend", tasklib.on_user_add_friend);
--����
eventmgr:addEventListener("site_event", tasklib.on_user_sit_down);
--�û�����ʱ
eventmgr:addEventListener("user_level_event", tasklib.on_user_upgrade_level);
--����ʱ
eventmgr:addEventListener("meet_event",  tasklib.on_meet_event);
--���ش���
eventmgr:addEventListener("back_to_hall",  tasklib.on_back_to_hall);
eventmgr:addEventListener("on_sub_user_back_to_hall",  tasklib.on_back_to_hall);
--�뿪��Ϸ
eventmgr:addEventListener("do_kick_user_event",  tasklib.on_kick_user);
--���ʺŵ�¼
eventmgr:addEventListener("h2_on_sub_user_login", tasklib.on_after_sub_user_login);





--�����б�
cmdHandler = 
{
	------------------------- ����Э�� ----------------------------
    ["NTKOPEN"] = tasklib.on_recv_open_wnd,    --��������������
    ["NTKAWARD"] = tasklib.on_recv_award,      --�����콱
    ["NTKODT"]    = tasklib.on_recv_open_daily_task, --������½���
    ["NTKTASKFRTIPS"] = tasklib.on_recv_show_friend_tips,--������ʾ�Ӻ�����ʾ
    --["NTKSTART"] = tasklib.on_recv_start,         --��������
}

--���ز���Ļص�
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
