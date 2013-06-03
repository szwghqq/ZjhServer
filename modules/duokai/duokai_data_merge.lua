if(duokai_merge_lib == nil) then
    duokai_merge_lib = {}
end
--[[
    多开的数据合并模块
--]]
function duokai_lib.merge_data(user_info, merge_table, on_change_func)
    if (user_info == nil or merge_table == nil) then
        TraceError(debug.traceback());
        TraceError("参数不对，合并数据的table不对，请检查")
        return
    end
    if (duokai_lib.user_list[user_info.userId] == nil) then
        return
    end
    for k, v in pairs(duokai_lib.user_list[user_info.userId].sub_user_list) do
        local sub_user_info = usermgr.GetUserById(k)
        if (sub_user_info ~= nil) then
            if (on_change_func ~= nil) then
                on_change_func(user_info, sub_user_info)
            else
                sub_user_info[merge_table] = user_info[merge_table]            
            end
        end
    end
end

--vip合并
if (viplib.set_user_vip_info ~= nil) then
    viplib.org_set_user_vip_info = viplib.set_user_vip_info
end
viplib.set_user_vip_info = function(userinfo, vip_info)
    local user_info = nil
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        viplib.org_set_user_vip_info(userinfo, vip_info)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            viplib.org_set_user_vip_info(user_info, vip_info)
        end
    end
    duokai_lib.merge_data(user_info, "vip_info")
end

--成就合并
if (achievelib.updateuserachieveinfo ~= nil) then
    achievelib.org_updateuserachieveinfo = achievelib.updateuserachieveinfo
end
achievelib.updateuserachieveinfo = function(userinfo, id, isreset)

    if(userinfo.desk) then
        local deskinfo = desklist[userinfo.desk];
        if(deskinfo.desktype == g_DeskType.match) then
            return;
        end
    end

    local user_info = nil
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        achievelib.org_updateuserachieveinfo(userinfo, id, isreset)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            achievelib.org_updateuserachieveinfo(user_info, id, isreset)
        end
    end
    if(user_info ~= nil) then
        duokai_lib.merge_data(user_info, "achieveinfo")
    end
end

--经验合并
if (usermgr.addexp ~= nil) then
    usermgr.org_addexp = usermgr.addexp
end
usermgr.addexp = function(userid, level, added_exp, nType, remark)
    local user_info = nil
    if (duokai_lib.sub_user_list[userid] == nil) then
        usermgr.org_addexp(userid, level, added_exp, nType, remark)
        user_info = usermgr.GetUserById(userid)
    else
        local user_id = duokai_lib.sub_user_list[userid].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           usermgr.org_addexp(user_id, level, added_exp, nType, remark)
        end
    end
    if (user_info == nil or duokai_lib.sub_user_list[user_info.userId] == nil) then
        return
    end
    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        sub_user_info.gameInfo.level = parent_user_info.gameInfo.level
        sub_user_info.gameInfo.exp = parent_user_info.gameInfo.exp
    end)
end

--extra信息合并
if (save_extrainfo_to_db ~= nil) then
   duokai_merge_lib.org_save_extrainfo_to_db = save_extrainfo_to_db
end

function save_extrainfo_to_db(userinfo)
    local user_info = nil
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        duokai_merge_lib.org_save_extrainfo_to_db(userinfo)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            user_info.extra_info = userinfo.extra_info
            duokai_merge_lib.org_save_extrainfo_to_db(user_info)
        end
    end
    if(user_info ~= nil) then
        duokai_lib.merge_data(user_info, "extra_info")
    end
end

--筹码合并
if (usermgr.addgold ~= nil) then
    usermgr.org_addgold = usermgr.addgold
end
usermgr.addgold = function(userid, addgold, chou_shui_gold, ntype, 
                        chou_shui_type, borcastDesk, call_back)
    local user_info = nil
    if (duokai_lib.sub_user_list[userid] == nil) then
        usermgr.org_addgold(userid, addgold, chou_shui_gold, ntype, 
                            chou_shui_type, borcastDesk, call_back)
        user_info = usermgr.GetUserById(userid)
    else
        local user_id = duokai_lib.sub_user_list[userid].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           usermgr.org_addgold(user_id, addgold, chou_shui_gold, ntype, 
                            chou_shui_type, borcastDesk, call_back)
        end
    end
    if(user_info ~= nil) then
        duokai_lib.merge_data(user_info, "gamescore")
    end
end

--五道杠加好友时间
if (tex_dailytask_lib.set_addfriend_status ~= nil) then
    tex_dailytask_lib.org_set_addfriend_status = tex_dailytask_lib.set_addfriend_status
end
function tex_dailytask_lib.set_addfriend_status(userinfo)
    local user_info = nil
    if (duokai_lib.sub_user_list[userid] == nil) then
        tex_dailytask_lib.org_set_addfriend_status(userinfo)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userid].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            tex_dailytask_lib.org_set_addfriend_status(user_info)
        end
    end
    duokai_lib.merge_data(user_info, "wdg_huodong")
end

--每日任务
if (tex_dailytask_lib.on_game_over ~= nil) then
    tex_dailytask_lib.org_on_game_over = tex_dailytask_lib.on_game_over
end

function tex_dailytask_lib.on_game_over(userinfo, pai_xin, deskno, gold)
    local user_info = nil
    if (duokai_lib.sub_user_list[userid] == nil) then
        tex_dailytask_lib.org_on_game_over(userinfo, pai_xin, deskno, gold)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userid].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            tex_dailytask_lib.org_on_game_over(user_info, pai_xin, deskno, gold)
        end
    end
end


--新手任务进度合并
if (save_new_user_process ~= nil) then
    org_save_new_user_process = save_new_user_process
end
function save_new_user_process(userinfo, process)
    local user_info = nil
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        org_save_new_user_process(userinfo, process)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           org_save_new_user_process(user_info, process)
        end
    end
    duokai_lib.merge_data(user_info, "gotwelcome")
end

--道具数据合并
if (tex_gamepropslib and tex_gamepropslib.set_props_count_by_id ~= nil) then
    tex_gamepropslib.org_set_props_count_by_id = tex_gamepropslib.set_props_count_by_id
end

function tex_gamepropslib.set_props_count_by_id(props_id, add_count, user_info, complete_callback_func)
    local new_user_info = nil
    if (duokai_lib.sub_user_list[user_info.userId] == nil) then
        tex_gamepropslib.org_set_props_count_by_id (props_id, add_count, user_info, complete_callback_func)
        new_user_info = user_info
    else
        local user_id = duokai_lib.sub_user_list[user_info.userId].parent_id
        new_user_info = usermgr.GetUserById(user_id)
        if (new_user_info ~= nil) then
            tex_gamepropslib.org_set_props_count_by_id (props_id, add_count, new_user_info, complete_callback_func)
        end
    end
    duokai_lib.merge_data(new_user_info, "propslist")
end

--礼物数据合并

if gift_removegiftitem ~= nil then
    org_gift_removegiftitem = gift_removegiftitem
end

function gift_removegiftitem(userinfo, itemindex) 
    local user_info = nil
    local ret = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        ret = org_gift_removegiftitem(userinfo, itemindex)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            ret = org_gift_removegiftitem(user_info, itemindex)
        end
    end
    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        -- [[
        sub_user_info.gameInfo.using_gift_item = parent_user_info.gameInfo.using_gift_item
        sub_user_info.gameInfo.giftinfo = parent_user_info.gameInfo.giftinfo
        sub_user_info.gameInfo.gift_today = parent_user_info.gameInfo.gift_today
        sub_user_info.gameInfo.buygiftgold = parent_user_info.gameInfo.buygiftgold
        sub_user_info.gameInfo.salegiftgold = parent_user_info.gameInfo.salegiftgold
        --]]
    end)
    return ret;
end

if (gift_addgiftitem ~= nil) then
    org_gift_addgiftitem = gift_addgiftitem
end


function gift_addgiftitem(userinfo, itemid, fromuserid, fromusernick, is_useing)
    local user_info = nil
    local ret = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        ret = org_gift_addgiftitem(userinfo, itemid, fromuserid, fromusernick, is_useing)
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            ret = org_gift_addgiftitem(user_info, itemid, fromuserid, fromusernick, is_useing)
        end
    end
    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        sub_user_info.gameInfo.using_gift_item = parent_user_info.gameInfo.using_gift_item
        sub_user_info.gameInfo.giftinfo = parent_user_info.gameInfo.giftinfo
        sub_user_info.gameInfo.gift_today = parent_user_info.gameInfo.gift_today
        sub_user_info.gameInfo.buygiftgold = parent_user_info.gameInfo.buygiftgold
        sub_user_info.gameInfo.salegiftgold = parent_user_info.gameInfo.salegiftgold
    end)

    return ret;
end

--车库合并
if(parkinglib and parkinglib.get_using_car_info ~= nil) then
    parkinglib.org_get_using_car_info = parkinglib.get_using_car_info;
end

function parkinglib.get_using_car_info(userinfo) 
    local user_info = nil
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        return parkinglib.org_get_using_car_info(userinfo)
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
            return parkinglib.org_get_using_car_info(user_info)
        end
    end
    return nil;
end

if(friendlib and friendlib.do_add_userfriend_byid ~= nil) then
    friendlib.org_do_add_userfriend_byid = friendlib.do_add_userfriend_byid;
end

function friendlib.do_add_userfriend_byid(userinfo, addid)
    local user_info = nil
    local parent_addid = nil
    
    if(duokai_lib.sub_user_list[addid] ~= nil) then
        parent_addid = duokai_lib.sub_user_list[addid].parent_id;
    end


    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        friendlib.org_do_add_userfriend_byid(userinfo, parent_addid or addid);
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           friendlib.org_do_add_userfriend_byid(user_info, parent_addid or addid);
           friendlib.net_broadcastdesk_toplay(userinfo, addid)
        end
    end

    --合并数据
    duokai_lib.merge_data(user_info, "friends");
end

--比赛场奖品合并
if(matches_taotai_lib and matches_taotai_lib.do_give_prize ~= nil) then
    matches_taotai_lib.org_do_give_prize = matches_taotai_lib.do_give_prize;

    function matches_taotai_lib.do_give_prize(userinfo, prize_list)
        local user_info = nil
        if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
            return matches_taotai_lib.org_do_give_prize(userinfo, prize_list);
        else
            local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
            user_info = usermgr.GetUserById(user_id)
            if (user_info ~= nil) then
               return matches_taotai_lib.org_do_give_prize(user_info, prize_list);
            end
        end
        return {};
    end
end

--踢人卡
if(tex_buf_lib and tex_buf_lib.add_desk_kick_list ~= nil) then
    tex_buf_lib.org_add_desk_kick_list = tex_buf_lib.add_desk_kick_list;
end

function tex_buf_lib.add_desk_kick_list(deskno, kick_info, kick_user_info)
    local user_info = nil;
    local userinfo = kick_user_info;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        tex_buf_lib.org_add_desk_kick_list(deskno, kick_info, userinfo);
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           tex_buf_lib.org_add_desk_kick_list(deskno, kick_info, user_info);
        end
    end
end

if(tasklib ~= nil and tasklib.update_task_progress) then
    tasklib.org_update_task_progress = tasklib.update_task_progress;
end

function tasklib.update_task_progress(userinfo, task_id)
    local user_info = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        tasklib.org_update_task_progress(userinfo, task_id);
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           tasklib.org_update_task_progress(user_info, task_id);
        end
    end

    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        tasklib.user_list[sub_user_info.userId] = tasklib.user_list[parent_user_info.userId];
    end)
end

if(tasklib ~= nil and tasklib.do_give_prize) then
    tasklib.org_do_give_prize = tasklib.do_give_prize;
end

function tasklib.do_give_prize(userinfo, task_id)
    local user_info = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        tasklib.org_do_give_prize(userinfo, task_id);
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           tasklib.org_do_give_prize(user_info, task_id);
        end
    end
end

if(tex_dailytask_lib ~= nil and tex_dailytask_lib.update_pai_xin) then
    tex_dailytask_lib.org_update_pai_xin = tex_dailytask_lib.update_pai_xin;
end

function tex_dailytask_lib.update_pai_xin(userinfo, pai_xin)
    local user_info = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        tex_dailytask_lib.org_update_pai_xin(userinfo, pai_xin);
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           tex_dailytask_lib.org_update_pai_xin(user_info, pai_xin);
        end
    end
end

if(car_match_db_lib and car_match_db_lib.add_car) then
    car_match_db_lib.org_add_car = car_match_db_lib.add_car;

    function car_match_db_lib.add_car(user_id, car_type, is_using, can_sale)
        if (duokai_lib.sub_user_list[user_id] == nil) then
            car_match_db_lib.org_add_car(user_id, car_type, is_using, can_sale);
        else
            user_id = duokai_lib.sub_user_list[user_id].parent_id
            car_match_db_lib.org_add_car(user_id, car_type, is_using, can_sale);
        end
    end
end

if(shop_lib and shop_lib.add_gold) then
    shop_lib.org_add_gold = shop_lib.add_gold;
    function shop_lib.add_gold(user_id, gold_type, change_gold, change_result, call_back)
        if (duokai_lib.sub_user_list[user_id] == nil) then
            shop_lib.org_add_gold(user_id, gold_type, change_gold, change_result, call_back);
        else
            user_id = duokai_lib.sub_user_list[user_id].parent_id
            shop_lib.org_add_gold(user_id, gold_type, change_gold, change_result, call_back);
        end
    end
end




if(shop_lib and shop_lib.check_can_buy) then
    shop_lib.org_check_can_buy = shop_lib.check_can_buy;
    function shop_lib.check_can_buy(userinfo, gift_type, gift_id, gift_count, to_user_tab)
        local user_info = nil;
        if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
            return shop_lib.org_check_can_buy(userinfo, gift_type, gift_id, gift_count, to_user_tab);
        else
            local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
            user_info = usermgr.GetUserById(user_id)
            if (user_info ~= nil) then
               return shop_lib.org_check_can_buy(user_info, gift_type, gift_id, gift_count, to_user_tab);
            end
        end
        return -1;
    end
end

if(matches_db and matches_db.save_match_win_info) then
    matches_db.org_save_match_win_info = matches_db.save_match_win_info;

    function matches_db.save_match_win_info(match_id, match_name, win_user_id, win_jifen, prize_list) 
        if (duokai_lib.sub_user_list[win_user_id] == nil) then
            matches_db.org_save_match_win_info(match_id, match_name, win_user_id, win_jifen, prize_list);
        else
           win_user_id = duokai_lib.sub_user_list[win_user_id].parent_id
           matches_db.org_save_match_win_info(match_id, match_name, win_user_id, win_jifen, prize_list);
        end
    end
end

if(gift_usegiftitem ~= nil) then
    org_gift_usegiftitem = gift_usegiftitem;
end
function gift_usegiftitem(userinfo, item_index)
    local user_info = nil;
    local ret = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        ret = org_gift_usegiftitem(userinfo, item_index);
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           ret = org_gift_usegiftitem(user_info, item_index);
        end
    end
    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        sub_user_info.gameInfo.using_gift_item = parent_user_info.gameInfo.using_gift_item
    end)
    return ret;
end

if(gift_remove_using ~= nil) then
    org_gift_remove_using = gift_remove_using;
end
function gift_remove_using(userinfo)
    local user_info = nil;
    if (duokai_lib.sub_user_list[userinfo.userId] == nil) then
        org_gift_remove_using(userinfo, item_index);
        user_info = userinfo
    else
        local user_id = duokai_lib.sub_user_list[userinfo.userId].parent_id
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil) then
           org_gift_remove_using(user_info);
        end
    end
    --合并数据
    duokai_lib.merge_data(user_info, "", function(parent_user_info, sub_user_info)
        sub_user_info.gameInfo.using_gift_item = parent_user_info.gameInfo.using_gift_item
    end)
end


if(dispatchMeetEvent ~= nil) then
    org_dispatchMeetEvent = dispatchMeetEvent;
end

function dispatchMeetEvent(user_info)
    if(duokai_lib.is_sub_user(user_info.userId) == 0) then
        local cur_user_id = duokai_lib.get_cur_sub_user_id(user_info.userId);
        local cur_user_info = usermgr.GetUserById(cur_user_id);
        if(cur_user_info ~= nil) then
            org_dispatchMeetEvent(cur_user_info);
        end
    else
        org_dispatchMeetEvent(user_info);
    end
end

