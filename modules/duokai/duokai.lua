TraceError("init duokai_lib...初始化多开模块")
dofile("games/modules/duokai/lua_buf.lua")
dofile("games/modules/duokai/duokai_db.lua")
if duokai_lib and duokai_lib.on_after_user_login then
    eventmgr:removeEventListener("h2_on_user_login", duokai_lib.on_after_user_login);
end

if duokai_lib and duokai_lib.on_user_exit then
    eventmgr:removeEventListener("on_user_exit", duokai_lib.on_user_exit);
end

if duokai_lib and duokai_lib.on_timer_second then
    eventmgr:removeEventListener("timer_second", duokai_lib.on_timer_second)
end

if duokai_lib and duokai_lib.on_user_kicked then
    eventmgr:removeEventListener("on_user_kicked", duokai_lib.on_user_kicked)
end

if duokai_lib and duokai_lib.on_user_standup then
    eventmgr:removeEventListener("on_user_standup", duokai_lib.on_user_standup)
end

if duokai_lib and duokai_lib.on_user_exit_watch then
    eventmgr:removeEventListener("on_user_exit_watch", duokai_lib.on_user_exit_watch)
end

if duokai_lib and duokai_lib.on_show_panel then
    eventmgr:removeEventListener("on_show_panel", duokai_lib.on_show_panel)
end

if duokai_lib and duokai_lib.on_game_event then
    eventmgr:removeEventListener("game_event", duokai_lib.on_game_event)
end

if not duokai_lib then
	duokai_lib = _S
	{
        USER_NUM_LIMIT = 2,  --子账号数量限制
		user_list = {},
        sub_user_list = {},
        temp_add_desk = {},     --临时占住的桌子信息，用于登陆时检测桌子是否已经被占用了
        back_hall_buf_list = {}, --返回大厅会清空的缓存列表
        game_over_buf_list = {}, --每一局结束后会清空的缓存列表
	}
end

------------------------------------------------------------------
--[[
    框架相关处理，如果需要改动请咨询李军 
--]]
duokai_lib.need_change_send_cmd =  --子账号发出，需要发送给主账号的协议 
{
    TXNTPN = 1,  --显示面板
    TXNTAP = 1,  --显示自动面板
    TEXXST = 1,  --新手场限制协议
    REMG = 1,  --客户端显示信息
    RESD = 1,  --坐下协议    
    TXREFP = 1,  --发牌协议

    RQPEXT = 1,     --请求某个人的extra_info和achieve_info
    RQMIXT = 1,		--请求某个人的extra_info      
    REOT = 1,		--是否允许退出游戏
    TXNTBC = 1,      --想买筹码
    TXNINF = 1,		--想知道桌子參數
    TXNTRD = 1,		--恢复桌面的协议
    TXNTZT = 1,		--恢复所有人状态
    TXNTDM = 1,		--彩池信息    
    TXBTZL = 1,     --通知被踢的人自己被踢走
    TXNTPZ = 1,     --发送得奖或被淘汰的信息
    TXNTXP = 1,     --发送天天经验红利
    STOV = 1,       --发送学习教程领奖成功
    TXNTMG = 1,     --弹出桌子左下角窗口信息
    TXREDJNUM = 1,  --通知客户端，更新道具数量TIPS
    --TXZSLW = 1,     --赠送道具
    TXSPBZ = 1,


    --比赛模块
    MATCHTTCO = 1,
    MATCHTTTT = 1,
    MATCHTTRLIST = 1,
    MATCHTTRS = 1,
    MATCHTTMYINFO = 1,
    MATCHTTMD = 1,
    MATCHTTGP = 1,
    MATCHTTCJF = 1,
    MATCHTTLIST = 1,
    DKDESKSS = 1,

    --好友模块
    FDSENDSHOWADD = 1,

    --踢人卡
    TXFQTR = 1,
    TXTRID = 1,
    TXTPJG = 1,
    TXKVIP = 1,
    TXVPCS = 1,
    TXKICK = 1,
    TXBTZL = 1,
    TXBFKS = 1,

    --送礼物
    TXBGFD = 1,
    TXBGFF = 1,

    --vip房
    VIPROOMMSG = 1,

    --今日明细
    TXNTSGDT = 1,

    --vip
    VIPINF = 1,

    --新手任务
    NTKTASKPG = 1,
    NTKTASKFN = 1,
    NTKTASKFRTIPS = 1,

    --礼券购买
    SHOPBUY = 1,
    SHOPLS = 1,
    TXGFSL = 1,

    --活动
    GBHDPS = 1,
}

duokai_lib.need_notify_cmd =  --子账号发出，需要通知主账号有操作的协议
{
    TXNTPN = 1,  --显示面板
}

duokai_lib.need_change_recv_cmd =  --主账号收到的，需要发送给子账号
{
    RQSU = 1,       --请求站起来
    REWT = 1,       --请求观战
    TXNINF = 1,		--想知道桌子參數
    TXNTBC = 1,      --想买筹码
    TXRQBC = 1,		--点兑换筹码
    TXRQST = 1,		--用户请求开始
    TXRQFQ = 1,		--点放弃
    TXRQXZ = 1,		--点下注
    TXRQGZ = 1,		--点跟注
    TXRQBX = 1,		--点不下注（过牌）
    TXRQAI = 1,		--点全下
    RQPEXT = 1,     --请求某个人的extra_info和achieve_info
    RQMIXT = 1,		--请求某个人的extra_info
    TXNBBS = 1,		--请求论坛验证串
    TXNTDT = 1,		--请求今日明细
    TXAUSI = 1,     --收到买筹码，自动坐下 
    TXTOUDJ = 1,    --收到赠送道具
    TXGIFT = 1,     --收到送礼物
    TXTOUDJ = 1,    --发送道具
    TXEMOT  = 1,    --发送表情

    --好友
    FDRQTJHY = 1,   --请求显示加好友按钮
    FDRQWTAD = 1,   --请求加好友
    FDRQZJHY = 1,   --确认加好友

    --踢人卡
    TXFQTR = 1,     --请求踢人
    TXTRID = 1,     --想踢谁
    TXTPXX = 1,     --投票结果
    TXKVIP = 1,     --查询vip次数
    TXCLICKCANCEL = 1,--取消踢人
    TXBFKS = 1,

    --礼券兑换
    TXGFDP = 1,
    TXGFUS = 1,
    TXGFSL = 1,
    SHOPBUY = 1,    --买东西

    --比赛
    MATCHJXGZ = 1,
}

--返回大厅或者连线时候会清空的缓存列表
duokai_lib.need_cache_notify_cmd = {
    MATCHTTGP = 1,
    MATCHTTTT = 1,
    FDSENDCANADD = 1,
    TXZSLW = 1,
}

--每一局结束会清空的缓存列表
duokai_lib.need_cache_game_notify_cmd = {
    NTKTASKFRTIPS = 1,
    TXTRID = 1,
    TXNTXZ = 1,
    TXNTTX = 1,
    TXNTBX = 1,
    TXNTDP = 1,
    TXNTGO = 1,
}

--如果发送给的子帐号不是当前帐号，那么协议改为xxx_EX缓存起来，切换帐号时发给主帐号
duokai_lib.need_cache_game_ex_notify_cmd = {
    TXNTXZ = 1,
    TXNTTX = 1,
    TXNTBX = 1,
    TXNTDP = 1,
    TXNTGO = 1,
}

--是发送给子账号的协议,并且主账号正在以当前子账号身份打牌
function duokai_lib.need_process_send_msg(ip, port)
    local sub_user_key = format("%s:%s", ip, port)
    if (userlist[sub_user_key] == nil) then
        return 0
    end
    local sub_user_id = userlist[sub_user_key].userId
    if (duokai_lib.sub_user_list[sub_user_id] ~= nil) then 
        return 1
    else
        return 0
    end
end

--发送主账号的操作通知
function duokai_lib.send_notify_msg(user_info, sub_user_info, cmd)
    if (sub_user_info == nil or sub_user_info.desk == nil) then
        return
    end
    netlib.send(function(buf) 
        buf:writeString("DKNTMSG")
        buf:writeString(cmd)
        buf:writeString(sub_user_info.desk.."")
    end, user_info.ip, user_info.port)
end

--是否需要处理此协议
function duokai_lib.pre_process_send_msg(lua_buf)
    local cmd = lua_buf:get_top_item()
    ip = lua_buf:ip()
    port = lua_buf:port()

    local process_buf = function()
        --获取主账号        
        local sub_user_key = format("%s:%s", lua_buf:ip(), lua_buf:port())
        if (userlist[sub_user_key] == nil) then
            return 1, ip, port
        end
        local sub_user_id = userlist[sub_user_key].userId
        local user_id = duokai_lib.sub_user_list[sub_user_id].parent_id
        --检查主账号现在是否在看当前子账号
        local user_info = usermgr.GetUserById(user_id)
        if (user_info == nil) then
            return 0, ip, port
        end
        if (duokai_lib.user_list[user_id] ~= nil and 
            duokai_lib.user_list[user_id].cur_user_id == sub_user_id) then           
            return 1, user_info.ip, user_info.port
        else
            --需要通知主账号子账号有操作了
            if (duokai_lib.need_notify_cmd[cmd] == 1) then
                duokai_lib.send_notify_msg(user_info, usermgr.GetUserById(sub_user_id), cmd)
            end
            return 0, ip, port, sub_user_id
        end
    end
    --换成buf，用于切换账号后恢复数据通知
    local cache_buf = function(cmd, sub_user_id)
        if(duokai_lib.need_cache_notify_cmd[cmd] ~= nil) then
            if(duokai_lib.back_hall_buf_list[sub_user_id] == nil) then
                duokai_lib.back_hall_buf_list[sub_user_id] = {};
            end
            table.insert(duokai_lib.back_hall_buf_list[sub_user_id], lua_buf);
        elseif (duokai_lib.need_cache_game_notify_cmd[cmd] ~= nil) then
            if(duokai_lib.game_over_buf_list[sub_user_id] == nil) then
                duokai_lib.game_over_buf_list[sub_user_id] = {};
            end
            table.insert(duokai_lib.game_over_buf_list[sub_user_id], lua_buf);
        end
    end

    if (duokai_lib.need_change_send_cmd[cmd] ~= nil) then
        local ret, ip, port, sub_user_id = process_buf();
        if(sub_user_id ~= nil and ret == 0) then
            cache_buf(cmd, sub_user_id);
        end
        return ret, ip, port
    else
        if(duokai_lib.need_cache_notify_cmd[cmd] ~= nil or
           duokai_lib.need_cache_game_notify_cmd[cmd] ~= nil) then
            local ret, ip, port, sub_user_id = process_buf();
            if(sub_user_id ~= nil) then
                cache_buf(cmd, sub_user_id);
            end
        end
        return 0, ip, port
    end
end

function duokai_lib.send_cache_buf(user_info)
    if(duokai_lib.user_list[user_info.userId] ~= nil) then
        local cur_user_id = duokai_lib.user_list[user_info.userId].cur_user_id;
        
        if(duokai_lib.back_hall_buf_list[cur_user_id] ~= nil) then 
            for k, v in pairs(duokai_lib.back_hall_buf_list[cur_user_id]) do
                local func_internal = function(buf)
                   local cmd = v:get_top_item();
                   if(duokai_lib.need_cache_game_ex_notify_cmd[cmd] == 1) then
                       v.content[1].arg = cmd.."_EX";
                   end
                   v:copy_buf(buf)
                end
                netlib.send(func_internal, user_info.ip, user_info.port);
            end
            duokai_lib.back_hall_buf_list[cur_user_id] = nil;
        end
        if(duokai_lib.game_over_buf_list[cur_user_id] ~= nil) then 
            for k, v in pairs(duokai_lib.game_over_buf_list[cur_user_id]) do
                local func_internal = function(buf)
                   local cmd = v:get_top_item();
                   if(duokai_lib.need_cache_game_ex_notify_cmd[cmd] == 1) then
                       v.content[1].arg = cmd.."_EX";
                   end
                   v:copy_buf(buf)
                end
                netlib.send(func_internal, user_info.ip, user_info.port);
            end
            duokai_lib.game_over_buf_list[cur_user_id] = nil;
        end
    end
end

--是否需要处理此协议
function duokai_lib.pre_process_recv_msg(cmd, buf)
    local user_key = format("%s:%s", buf:ip(), buf:port())
    if (userlist[user_key] == nil) then
        return
    end
    --如果是主账号发出来的，并且需要发送给子账号，就发送给当前正在观战的子账号
    local user_id = userlist[user_key].userId
    if (duokai_lib.user_list[user_id] == nil or
        duokai_lib.need_change_recv_cmd[cmd] ~= 1) then
        return
    end
    local sub_user_id = duokai_lib.user_list[user_id].cur_user_id
    local sub_user_info = usermgr.GetUserById(sub_user_id)
    if (sub_user_info ~= nil) then        
        buf:setIp(sub_user_info.ip)
        buf:setPort(sub_user_info.port)
    end
end
------------------------------------------------------------------
-----------------------数据操作-------------------------------------------
--把主账号的数据，克隆到子账号
function duokai_lib.clone_user_info_to_sub(sub_user_id, parent_id)
    local user_info = usermgr.GetUserById(parent_id)
    local sub_user_info = usermgr.GetUserById(sub_user_id)
    --关键数据不能复制，否则无法区分两个账号了
    for k, v in pairs(user_info) do
        if (k ~= "key" and k ~= "userId" and k ~= "userName" and k ~= "prekey" and 
            k ~= "isrobot" and k ~= "realrobot" and k ~= "nRegSiteNo" and k ~= "session" and 
            k ~= "passport" and k ~= "ip" and k ~= "port" and k ~= "desk" and k ~= "site" and
            k ~= "lastRecvBufTime" and k ~= "networkDelayTime" and k ~= "SendNetworkDelayFlag" and
            k ~= "sockeClosed") then
            sub_user_info[k] = v
        end
    end
end

--初始化子账号
function duokai_lib.init_sub_user(user_id, user_name, user_key, user_ip, user_port, parent_id)
    --克隆一个子账号出来
    local user_info = usermgr.GetUserById(parent_id)
    if (user_info == nil) then
        return -1
    end
    --TraceError("wwww")
    local sub_user_info = table.cloneex(user_info)
    sub_user_info.key = user_key
    sub_user_info.userId = user_id
    sub_user_info.userName = user_name
    sub_user_info.prekey = nil
    sub_user_info.isrobot = false
    sub_user_info.realrobot = false
    sub_user_info.nRegSiteNo = -100
    sub_user_info.session = ""
    sub_user_info.passport = ""
    sub_user_info.ip = user_ip
    sub_user_info.port = user_port
    sub_user_info.is_sub_user = 1
    userlist[user_key] = sub_user_info
    userlistIndexId[user_id] = sub_user_info
    
    if (duokai_lib.sub_user_list[user_id] == nil) then
        duokai_lib.sub_user_list[user_id] = {
            user_name = user_name,     --子账号的username
            sit_down_after_login = 0,   --用户登录后是否需要坐下，
            parent_id = parent_id,   --子账号的父id
            want_play_desk = -1,     --希望子账号进入的桌子
            want_play_site = -1,    --希望子账号进入的位置
            is_goto_game = 0,       --子账号登录成功后，主账号是否跟随子账号游戏
            start_login_time = 0,   --开始登陆时间
            login = 1,  
            call_back_login,   --登陆成功的回调
            }        
    end    
    duokai_lib.user_list[parent_id].sub_user_list[user_id] = {sys_time = os.time()}
    eventmgr:dispatchEvent(Event("h2_on_sub_user_login", {user_info = sub_user_info, userinfo = sub_user_info}));
    return 1
end

function duokai_lib.get_user_desk(user_id)
    local user_info = usermgr.GetUserById(user_id)
    if (user_info ~= nil) then
        return user_info.desk or -1
    end
    return -1
end

--获取玩某一桌游戏的子账号
function duokai_lib.get_sub_user_by_desk_no(user_id, desk_no)
    for k, v in pairs(duokai_lib.user_list[user_id].sub_user_list) do
        if (duokai_lib.get_user_desk(k) == desk_no) then
            return k
        end
    end
    return -1
end

function duokai_lib.get_all_sub_user(parent_id)
    if(duokai_lib.user_list[parent_id] ~= nil) then
        return duokai_lib.user_list[parent_id].sub_user_list;
    end
    return nil;
end

--获取父账号
function duokai_lib.get_parent_id(user_id)
    if (duokai_lib.sub_user_list[user_id] ~= nil) then
        return duokai_lib.sub_user_list[user_id].parent_id
    else
        return 0
    end
end

function duokai_lib.get_cur_sub_user_id(user_id)
    if(duokai_lib.user_list[user_id] ~= nil) then
        return duokai_lib.user_list[user_id].cur_user_id;
    end
    return 0;
end

--是否是子账号
function duokai_lib.is_sub_user(user_id)
    if (duokai_lib.sub_user_list[user_id] ~= nil) then
        return 1
    else
        return 0
    end
end

--是否是父账号
function duokai_lib.is_parent_user(user_id)
    if (duokai_lib.user_list[user_id] ~= nil) then
        return 1
    else
        return 0
    end
end

--获取一个未用的子账号, -1表示子账号
function duokai_lib.get_one_sub_user_list(user_id, call_back)    
    local user_count = duokai_lib.get_sub_play_num(user_id);
    --TraceError('get_one_sub_user_list'..user_count)
    --检测子账号是否超过上限
    if (user_count >= duokai_lib.USER_NUM_LIMIT) then
        call_back(-1, 0, 0)
        return
    end
    local user_count = 0
    for k, v in pairs(duokai_lib.user_list[user_id].sub_user_list) do
        if (duokai_lib.get_user_desk(k) == -1) then
            call_back(1, k, duokai_lib.sub_user_list[k].user_name)
            return
        else
            user_count = user_count + 1
        end
    end

    if (user_count >= duokai_lib.USER_NUM_LIMIT) then
        call_back(-1, 0, 0)
        return
    end
    duokai_db_lib.create_sub_user(user_id, os.time(), function(sub_user_id, sub_user_name, sub_user_key, 
                                                                sub_user_ip, sub_user_port)
        --加入内存列表中
        local ret = duokai_lib.init_sub_user(sub_user_id, sub_user_name, sub_user_key, 
                                 sub_user_ip, sub_user_port, user_id)

        if(user_count > 0) then
            duokai_db_lib.log_want_duokai_info(user_id, 0, 0, 1);
        end

        if (ret > 0) then
            call_back(1, sub_user_id, sub_user_name)
        else
            call_back(-2, 0, 0)
        end
    end)
end

----------------------------------------------------------------
--事件相关操作
function duokai_lib.on_timer_second(e)
    --定时发送协议，防止账号被登出
    local cur_time = os.time()
    if (e.data.time % 10 == 0) then
        for k,  v in pairs(duokai_lib.sub_user_list) do
            if (v.login == 1) then
                local sub_user_info = usermgr.GetUserById(k)
                if (sub_user_info ~= nil) then
                    usermgr.ResetNetworkDelay(sub_user_info.key)
                end
            end
            duokai_lib.reset_user_site(v)
        end
    end
end

--用户登陆
function duokai_lib.on_after_user_login(e)
    local user_info = e.data.userinfo
    local user_id = user_info.userId
    local cur_time = os.time()
    --[[if (duokai_lib.sub_user_list[user_id] ~= nil) then --子账号登录了
        duokai_lib.sub_user_list[user_id].login = 1
        local parent_id = duokai_lib.sub_user_list[user_id].parent_id
        --duokai_lib.clone_user_info_to_sub(user_id, parent_id)
        if (duokai_lib.sub_user_list[user_id].is_goto_game == 1) then
            duokai_lib.user_list[parent_id].cur_user_id = user_id
            --让父账号离开观战列表          
            DoUserExitWatch(parent_user_info)
        end
        if (duokai_lib.sub_user_list[user_id].call_back_login ~= nil) then
            duokai_lib.sub_user_list[user_id].call_back_login(user_info)
            duokai_lib.sub_user_list[user_id].call_back_login = nil
        end
        --清空临时占用的位置信息

        local desk_no = duokai_lib.sub_user_list[user_id].want_play_desk
        local site_no = duokai_lib.sub_user_list[user_id].want_play_site
        if (desk_no ~= nil and site_no ~= nil and site_no > 0) then            
            duokai_lib.temp_remove_user_site(desk_no, site_no)
        end
        --让父账号和子账号移动观战
        duokai_lib.process_enter_desk(user_info, usermgr.GetUserById(parent_id), desk_no, site_no, 
                                      duokai_lib.sub_user_list[user_id].is_goto_game)           
    else--]]
    if (user_info.ip ~= "-100") then--父账号登陆了, -100表示机器人账号
        duokai_lib.user_list[user_id] = {cur_user_id = -1, sub_user_list = {}}
        --获取子账号
        --[[duokai_db_lib.get_sub_user_list(user_id, function(dt)
            if (dt and #dt > 0) then
                local sub_user_list = split(dt[1].sub_user_list, "|")            
                for i = 1, #sub_user_list do                    
                    if (sub_user_list[i] ~= "") then
                        local sub_item_info = split(sub_user_list[i], ",")
                        duokai_lib.init_sub_user(tonumber(sub_item_info[1]), sub_item_info[2], user_id)
                    end
                end

                --duokai_lib.user_list[user_id].sub_user_list[user_id] = {sys_time = cur_time}  --把自己加入子账号中
            end
        end)--]]
    end
    
end

--用户退出
function duokai_lib.on_user_exit(e)
    local user_id = e.data.user_id
    if (duokai_lib.user_list[user_id] ~= nil) then
        --让所有的子账号全部掉线
        for k, v in pairs (duokai_lib.user_list[user_id].sub_user_list) do
            local user_info = usermgr.GetUserById(k)
            if (user_info ~= nil) then
                eventmgr:dispatchEvent(Event("before_kick_sub_user", {userinfo = user_info, user_info = user_info}));
                local buf = lua_buf:new()
                buf:set_ip(user_info.ip)
                buf:set_port(user_info.port)
                onclientoffline(buf)
            end
            local sub_user = duokai_lib.sub_user_list[k]
            duokai_lib.reset_user_site(sub_user)
            duokai_lib.sub_user_list[k] = nil
            if (userlistIndexId[k] ~= nil) then
                local user_key = userlistIndexId[k].key
                userlist[user_key] = nil
                userlistIndexId[k] = nil
            end
            duokai_lib.back_hall_buf_list[k] = nil;
            duokai_lib.game_over_buf_list[k] = nil;
            --todo需要处理用户临时短线的情况
        end
        duokai_lib.user_list[user_id] = nil
    end
end

--强制让子账号占用的位置退出来
function duokai_lib.reset_user_site(sub_user_info)
    local cur_time = os.time()
    local desk_no = sub_user_info.want_play_desk
    local site_no = sub_user_info.want_play_site
    if (sub_user_info.login == 0 and sub_user_info.start_login_time ~= 0 and 
        cur_time - sub_user_info.start_login_time > 5 and
        desk_no ~= nil and desk_no > 0 and 
        site_no ~= nil and site_no > 0) then
        duokai_lib.temp_remove_user_site(desk_no, site_no)
    end
end

--检测此位置是否已经有人了
function duokai_lib.site_have_user(desk_no, site_no)
    if (duokai_lib.temp_add_desk[desk_no..":"..site_no] ~= nil) then
        return 1
    end
    if (desklist[desk_no].site[site_no].user ~= nil) then
        return 1
    end
     return 0
end

--用户子账号退出的情况，归还位置
function duokai_lib.temp_remove_user_site(desk_no, site_no)
    if (duokai_lib.temp_add_desk[desk_no..":"..site_no] ~= nil) then
        duokai_lib.temp_add_desk[desk_no..":"..site_no] = nil        
        local find = 0
        --释放内存
        for k, v in pairs(duokai_lib.temp_add_desk) do
            find = 1
            break
        end
        if (find == 0) then
            duokai_lib.temp_add_desk = {}
        end
    end
end

--临时占住一个位置，用户子账号登陆的情况
function duokai_lib.temp_add_user_site(desk_no, site_no)
    if (duokai_lib.temp_add_desk[desk_no] == nil) then
        duokai_lib.temp_add_desk[desk_no] = {}
    end
    duokai_lib.temp_add_desk[desk_no..":"..site_no] = 1
end

--用户被踢走
function duokai_lib.on_user_kicked(e)
    --通知用户退出一桌了   
end

--让用户退出游戏
function duokai_lib.let_user_exit(user_info)
    --从客户端gobacktohall抄过来的
    --[[local new_buf = lua_buf:new()
    new_buf:set_ip(user_info.ip)
    new_buf:set_port(user_info.port)
    new_buf:writeInt(0);
    new_buf:writeInt(0);
    new_buf:writeByte(0);
    new_buf:writeByte(0);
    new_buf:writeByte(0);
    onrecvbuychouma(new_buf)--]]

    local new_buf2 = lua_buf:new()
    new_buf2:set_ip(user_info.ip)
    new_buf2:set_port(user_info.port)
    onrecvstandup(new_buf2)

    local new_buf3 = lua_buf:new()
    new_buf3:set_ip(user_info.ip)
    new_buf3:set_port(user_info.port)
    OnRecvExitWatch(new_buf3)
end

--用户请求回到大厅
function duokai_lib.on_back_to_hall(user_info)    
    local parent_desk_no = user_info.desk;
    --检测是否有其他子账号正在打牌，如果在打牌，就切换过去
    local sub_user_exit_func = function(org_sub_user_info)
        --通知客户端有一桌已经退出了
        duokai_lib.back_hall_buf_list[org_sub_user_info.userId] = nil;
        duokai_lib.game_over_buf_list[org_sub_user_info.userId] = nil;
        duokai_lib.let_user_exit(org_sub_user_info)
        duokai_lib.update_sub_desk_info(user_info)
        eventmgr:dispatchEvent(Event("on_sub_user_back_to_hall", {user_info = org_sub_user_info, userinfo = org_sub_user_info}));
    end
    --如果是子账号退出
    if (duokai_lib.is_sub_user(user_info.userId) == 1) then
        local parent_id = duokai_lib.sub_user_list[user_info.userId].parent_id
        local org_sub_user_info = user_info;
        local org_sub_desk_no = user_info.desk;
        user_info = usermgr.GetUserById(parent_id)
        parent_desk_no = user_info.desk
        sub_user_exit_func(org_sub_user_info)

        if(org_sub_desk_no ~= nil and org_sub_desk_no ~= parent_desk_no) then
            --TraceError("主帐号在观战其它子帐号观战");
            return 0;
        end
    end
    if (user_info ~= nil and parent_desk_no ~= nil) then        
        for k, v in pairs(duokai_lib.user_list[user_info.userId].sub_user_list) do
            --还有子账号在观战其他桌子
            local sub_play_desk = duokai_lib.get_user_desk(k)
            if (sub_play_desk ~= -1 and sub_play_desk ~= parent_desk_no) then
                local org_sub_user_id = duokai_lib.user_list[user_info.userId].cur_user_id
                --TraceError("还有子账号在观战其他桌子, 父账号以前观战的桌子  "..parent_desk_no)
                duokai_lib.join_game(user_info.userId, sub_play_desk, 0, 1)
                --TraceError("父账号现在观战的桌子  "..user_info.desk.."   "..k)
                --还有可以观战的用户，先让当前用户退到大厅，直接站起，退出观战
                local org_sub_user_info = usermgr.GetUserById(org_sub_user_id)
                if (org_sub_user_info ~= nil) then
                    --TraceError("让上一个用户退出观战离开游戏  "..org_sub_user_info.userId)
                     --让子账号gobacktohall
                    sub_user_exit_func(org_sub_user_info)
                end
                return 0
            end
        end
    end
    --没有一桌在玩了，直接退出来吧
    if (user_info ~= nil and duokai_lib.user_list[user_info.userId] ~= nil) then
        --TraceError("没有一桌在玩了，直接退出来吧")
        local sub_user_id = -1
        if (duokai_lib.user_list[user_info.userId] == nil) then
            TraceError("异常情况，子账号数据为空")
        else
            sub_user_id = duokai_lib.user_list[user_info.userId].cur_user_id
        end        
        local org_sub_user_info = usermgr.GetUserById(sub_user_id)
        --让父账号退出观战
        DoUserExitWatch(user_info)
        --让子账号gobacktohall
        if (org_sub_user_info ~= nil) then
            sub_user_exit_func(org_sub_user_info)
        end
        duokai_lib.user_list[user_info.userId].cur_user_id = -1
    end    
    return 1
end


--用户打牌显示面板
function duokai_lib.on_show_panel(e)
    local deskno = e.data.deskno;
    local cur_site = e.data.siteno;

    --计算每一人，还有多少人轮到自己
    local players = deskmgr.getplayingplayers(deskno)
	local deskdata = deskmgr.getdeskdata(deskno)
    local count = 0;
    local status = {};
    local last_num = 0;
    for i = cur_site, room.cfg.DeskSiteCount + cur_site - 1 do
        local siteno = i;
        local timeout = -1;
        local ntype = 0;
        if(i > room.cfg.DeskSiteCount) then
            siteno = i % room.cfg.DeskSiteCount;
        end
        local sitedata = deskmgr.getsitedata(deskno, siteno); 
        if sitedata.isinround == 1 and sitedata.islose == 0 then--and sitedata.isallin == 0 and (sitedata.isbet == 0 or sitedata.betgold < deskdata.maxbetgold) then
            if(siteno ~= cur_site) then
                --还有多少个玩家轮到自己
                status[siteno] = last_num + 1;
                last_num = status[siteno];
                ntype = 1;
            else
                ntype = 2;
                timeout = hall.desk.get_site_timeout(deskno, siteno);
            end
        end

        local userkey = desklist[deskno].site[siteno].user;
        if(userkey ~= nil) then
            local user_info = userlist[userkey];
            if(user_info ~= nil) then
                if(duokai_lib.is_sub_user(user_info.userId) == 1) then
                    user_info = usermgr.GetUserById(duokai_lib.get_parent_id(user_info.userId));
                end

                --[[
                if(user_info ~= nil) then
                    netlib.send(function(buf)
                        buf:writeString("DKDESKSS");
                        buf:writeString(tostring(deskno));
                        buf:writeByte(ntype);--0 没有状态 1 未轮到自己 2 轮到自己
                        buf:writeInt(status[siteno] or -1);--还有几位轮到自己
                        buf:writeInt(timeout);--轮到自己，还有多少时间超过
                    end, user_info.ip, user_info.port);
                end
                --]]
                duokai_lib.net_send_desk_status(user_info, deskno, ntype, status[siteno], timeout);
            end
        end
    end
end

--用户退出观战
function duokai_lib.on_user_exit_watch(e)
    local user_info = e.data.user_info
    --如果是父账号退出观战，就不管了，因为肯定处理了子账号的退出
    if (duokai_lib.sub_user_list[user_info.userId] == nil) then
        return
    end
    --让父账号也退出观战吧
    if (duokai_lib.sub_user_list[user_info.userId] ~= nil) then
        local parent_id = duokai_lib.sub_user_list[user_info.userId].parent_id
        DoUserExitWatch(usermgr.GetUserById(parent_id))
    end
end

--用户站起来
function duokai_lib.on_user_standup(e)
    --[[local user_info = e.data.user_info
    if (duokai_lib.sub_user_list[user_info.userId] ~= nil) then
        duokai_lib.sub_user_list[user_info.userId].play_desk = -1
    end--]]
    local user_info = e.data.user_info;
    duokai_lib.net_send_desk_status(user_info, user_info.desk);
    --TraceError('on_user_stanup'..user_info.userId);
    duokai_lib.game_over_buf_list[user_info.userId] = nil;
end
----------------------------------------------------------------

function duokai_lib.update_sub_desk_info(user_info)    
    local desk_num = 0    
    local cur_desk_no = "";
    for k, v in pairs(duokai_lib.user_list[user_info.userId].sub_user_list) do
        local desk_no = duokai_lib.get_user_desk(k)
        if (desk_no ~= -1) then
            desk_num = desk_num + 1

            if(duokai_lib.user_list[user_info.userId].cur_user_id == k) then
                cur_desk_no = desk_no;
            end
        end
    end

    local extra_list = {};
    eventmgr:dispatchEvent(Event('on_send_duokai_sub_desk', {user_info = user_info ,extra_list = extra_list}));

    if(#extra_list > 0) then
        desk_num = desk_num + #extra_list;
    end
    netlib.send(function(buf)
        buf:writeString("DKMYDLIST")
        buf:writeInt(desk_num)
        for k, v in pairs(duokai_lib.user_list[user_info.userId].sub_user_list) do
            local desk_no = duokai_lib.get_user_desk(k)
            if (desk_no ~= -1) then            
                local desk_info = desklist[desk_no]
                local desk_name = desk_info.name;
                local match_count = 0;
                local match_start_count = 0;
                local left_time = 0;
                local match_id = "";

                --TODO 把这份代码合并到on_send_duokai_sub_desk里面,但是要注意sub_user_list里面已经含有这些比赛
                if(matcheslib ~= nil) then
                    local match_info = matcheslib.get_match_by_desk_no(desk_no);
                    if(match_info ~= nil and desk_info.desktype == g_DeskType.match) then
                        match_id = match_info.id;
                        desk_name = match_info.match_name;
                        if(match_info.match_type == 2) then
                            match_count = match_info.match_count;
                            match_start_count = match_info.need_user_count;
                            left_time = -1;
                        else
                            left_time = match_info.match_start_time - os.time();
                        end
                    end
                end


                buf:writeString(desk_no.."")  --传入字符串是因为比赛的唯一标示是字符串，为了做统一
                buf:writeString(desk_name or "")
                buf:writeByte(desk_info.desktype)  --desktype
                buf:writeInt(left_time)  --sec
                buf:writeInt(match_count)  --match_count
                buf:writeInt(match_start_count)  --match_start_count
                buf:writeString(match_id);
            end
        end

        for k, v in pairs(extra_list) do
            buf:writeString(v.desk_no);
            buf:writeString(v.desk_name);
            buf:writeByte(v.desk_type);
            buf:writeInt(v.left_time);
            buf:writeInt(v.match_count);
            buf:writeInt(v.match_start_count);
            buf:writeString(v.match_id);
        end
        buf:writeString(cur_desk_no or "");
    end, user_info.ip, user_info.port)
end

--拷贝至用户观战协议  参考DoUserWatch
function duokai_lib.process_enter_desk(sub_user_info, user_info, desk_no, site_no, is_goto_game)
    if (sub_user_info == nil or user_info == nil) then
        TraceError("非法用户信息，无法开子账号打牌")
        return
    end
    local desk_info = desklist[desk_no]
    if(desk_info == nil) then return end
    if (is_goto_game == 1) then
        --告诉客户端需要更换子账号了
        netlib.send(function(buf) 
            buf:writeString("DKCGSBU")
            buf:writeInt(sub_user_info.userId)
        end, user_info.ip, user_info.port)
    
        addToWatchList(desk_no, user_info)    
    end
    --如果子账号处于打牌状态，则先坐下，然后恢复桌面
    if (sub_user_info.desk ~= nil and sub_user_info.site ~= nil) then
        --TraceError("恢复桌面")
        if (sub_user_info.desk ~= desk_no) then
            TraceError("严重错误，子账号和需要观战的账号desk不一致")            
        end
        --走坐下流程
        doSitdown(sub_user_info.key, sub_user_info.ip, sub_user_info.port, desk_no, sub_user_info.site, g_sittype.relogin)        
        --恢复牌信息
        gamepkg.AfterUserWatch(desk_no, sub_user_info)
        net_broadcastdesk_goldchange(sub_user_info)
        --恢复面板
        restore_panel(sub_user_info, desk_no, sub_user_info.site)
        duokai_lib.update_sub_desk_info(user_info)        
        return
    end
     --如果子账号已经处于观战状态,就不设置观战状态了
    if (desk_info.watchingList[sub_user_info.userId] == nil) then
        if (user_info.desk == nil) then
            TraceError("出现不合理的情况2，子账号在观战，主账号去子账号的房间")            
        end
        --TraceError("走让子账号观战的流程")
        --这里比较挫，在第一个的时候，主账号需奥处理rewt消息，只要进入游戏以后就不用处理了
        --rewt发给客户端，是为了让主账号客户端能打开桌面，然后坐下
        if (is_goto_game == 1) then
            duokai_lib.need_change_send_cmd["REWT"] = 1
        end
        --子账号走观战流程，完成后，派发桌子信息到主账号客户端，主账号客户端就可以切换到新的桌子了
        DoUserWatch(desk_no, sub_user_info)
        --如果需要坐下来，就让子账号坐下来打牌
        if (site_no > 0) then
            doSitdown(sub_user_info.key, sub_user_info.ip, sub_user_info.port, desk_no, site_no, g_sittype.queue)
        end
        duokai_lib.need_change_send_cmd["REWT"] = nil
    else
        --理论上不会出现这种情况，子账号在观战，主账号要求去这个房间，
        if (user_info.desk == nil) then
            TraceError("出现不合理的情况2，子账号在观战，主账号去子账号的房间")
            return
        end
        DoUserWatch(desk_no, sub_user_info)
    end    
    --[[if (viproom_lib) then
    	local succcess, ret = xpcall( function() 
                                        return viproom_lib.on_before_user_enter_desk(user_info, desk_no) 
                                    end, throw)
    	if (ret == 0) then
    	    return
    	end
    end--]]
    --广播桌面有人进来观战了
    --[[for i = 1, room.cfg.DeskSiteCount do
        local temp_user_key = hall.desk.get_user(desk_no, i)
        if(temp_user_key) then
            local play_user_info = userlist[hall.desk.get_user(desk_no, i) or ""]
            if (play_user_info and play_user_info.offline ~= offlinetype.tempoffline) then
                OnSendUserSitdown(user_info, play_user_info, 1, g_sittype.normal)  --在玩的玩家
                --游戏信息
                OnSendUserGameInfo(user_info, play_user_info, 0)
            end
            if(play_user_info == nil) then
                TraceError("用户观战时桌子上有个用户的userlist信息为空")
                hall.desk.clear_users(desk_no,i)
            end
        end
    end
    for k, watchinginfo in pairs(desk_info.watchingList) do
    	if(userlist[k] == nil) then
    	    deskinfo.watchingList[k] = nil
    	end
    end
    --派发见面事件,用户发送礼物等信息
    dispatchMeetEvent(user_info)
    if (gamepkg ~= nil and gamepkg.AfterUserWatch ~= nil) then
    	gamepkg.AfterUserWatch(desk_no, user_info)
    end    
    if(tex_userdiylib)then
    	tex_userdiylib.on_recv_update_userlist(user_info)
    end--]]
    --更新桌子列表
    duokai_lib.update_sub_desk_info(user_info)    
end

--[[
    加入一桌游戏
    user_id  主账号id,如果传入子账号id，则子账号走加入一桌流程
    desk_no  需要加入的桌子
    site_no  需要加入的位置，如果只是去观战，则传入0
    is_goto_game  开完子账号后，主账号是否也跟着过去， 1过去，0不过去
    call_back_login 子账号登陆成功的回调函数，发送在子账号登陆成功，主账号退出观战后，子账号进入位置前
--]]
function duokai_lib.join_game(user_id, desk_no, site_no, is_goto_game, call_back_login)
    desk_no = tonumber(desk_no)
    site_no = tonumber(site_no)
    if (user_id == nil or desk_no == nil or desk_no > #desklist or 
        site_no == nil or site_no > 9) then
        TraceError("duokai_lib.join_game参数错误")
        return
    end
    --如果不是主账号发起的观战请求,让子账号发起观战就ok了
    if (duokai_lib.user_list[user_id] == nil and duokai_lib.sub_user_list[user_id] ~= nil) then
        local sub_user_info = usermgr.GetUserById(user_id)
        if (sub_user_info == nil) then
            TraceError("子账号为啥为空啊")
            return
        end
        --
        if (sub_user_info.desk == desk_no and sub_user_info.site == site_no) then
            TraceError("join_game 切换到原来的桌子，为啥要这样调用，不用做任何处理了")
            return
        end
        local parent_id = duokai_lib.get_parent_id(user_id)
        local user_info = usermgr.GetUserById(parent_id);
        --如果主账号正在观战此子账号，此时子账号需要切换，那就让主账号一起跟着切换
        if (duokai_lib.user_list[parent_id].cur_user_id == user_id) then
            is_goto_game = 1
        end

        --让子用户先退出游戏
        duokai_lib.let_user_exit(sub_user_info)
        duokai_lib.sub_user_list[user_id].want_play_desk = desk_no
        duokai_lib.sub_user_list[user_id].want_play_site = site_no
        if (is_goto_game == 1) then
            DoUserExitWatch(user_info)
            duokai_lib.user_list[parent_id].cur_user_id = user_id
            netlib.send(function(buf) 
                buf:writeString("DKCGDSK")
            end, user_info.ip, user_info.port)
        end        
        duokai_lib.process_enter_desk(sub_user_info, user_info, 
                                      desk_no, site_no, is_goto_game)
        duokai_lib.send_cache_buf(user_info);
        return        
    elseif(is_goto_game == 1) then
        --如果用户以前在观战另外一桌，则先退出，然后再观战别的桌子        
        local org_sub_user_id = duokai_lib.user_list[user_id].cur_user_id
        if (org_sub_user_id ~= -1) then       
            local org_play_desk = duokai_lib.get_user_desk(org_sub_user_id)
            if (org_play_desk == desk_no) then
                TraceError("已经在观战此桌了，不用做任何处理了")
                return
            elseif (org_play_desk ~= -1) then
                --让父账号离开观战状态
                DoUserExitWatch(usermgr.GetUserById(user_id))
                local org_sub_user_info = usermgr.GetUserById(org_sub_user_id)
                --如果子账号只是在观战，则退出观战
                if (org_sub_user_info ~= nil and org_sub_user_info.desk ~= nil and org_sub_user_info.site == nil) then
                    DoUserExitWatch(org_sub_user_info)
                end
            end
        end
    end
    --获取子账号后，开始登陆
    local after_get_sub_user_func = function(sub_user_id, sub_user_name)
        --通知客户端清空界面，用于显示子用户的界面
        local user_info = usermgr.GetUserById(user_id)    
        if (is_goto_game == 1) then
            netlib.send(function(buf) 
                buf:writeString("DKCGDSK")
            end, user_info.ip, user_info.port)
        end
        if (duokai_lib.sub_user_list[sub_user_id].login == 1) then --此子账号已经登陆了
            --设置当前正在观战的游戏信息
            --让父账号离开观战列表
            duokai_lib.sub_user_list[sub_user_id].want_play_desk = desk_no
            duokai_lib.sub_user_list[sub_user_id].want_play_site = site_no
            if (is_goto_game == 1) then
                duokai_lib.user_list[user_id].cur_user_id = sub_user_id
                --TraceError("让父账号离开观战列表  "..desk_no)
                DoUserExitWatch(user_info)
            end
            local sub_user_info = usermgr.GetUserById(sub_user_id)
            if (call_back_login ~= nil) then
                call_back_login(sub_user_info)
            end
            duokai_lib.process_enter_desk(usermgr.GetUserById(sub_user_id), usermgr.GetUserById(user_id), 
                                          desk_no, site_no, is_goto_game)

            duokai_lib.send_cache_buf(user_info);
        else --用户还没有登陆过，走重登陆流程
            duokai_lib.sub_user_list[sub_user_id].want_play_desk = desk_no
            duokai_lib.sub_user_list[sub_user_id].want_play_site = site_no
            duokai_lib.sub_user_list[sub_user_id].start_login_time = os.time()            
            if (site_no > 0) then
                --临时占住一个位置，不让其他人坐下来
                duokai_lib.temp_add_user_site(desk_no, site_no)
            end
            duokai_lib.sub_user_list[sub_user_id].is_goto_game = is_goto_game
            duokai_lib.sub_user_list[sub_user_id].call_back_login = call_back_login            
            duokai_lib.sub_user_list[sub_user_id].login = 0
            --duokai_lib.sub_user_login(user_id, sub_user_id, sub_user_name);
            --[[
            netlib.send_to_gc(gamepkg.name, function(buf)
                buf:writeString("DKADDUSER")
                buf:writeInt(user_id)
                buf:writeInt(sub_user_id)
                buf:writeString(sub_user_name)  --新建账号的时候，user_name要写成user_id_dzduokai,例如103_dzduokai
                buf:writeInt(tonumber(groupinfo.groupid))
            end)
            --]]
        end
    end
    --检测需要观战的桌子是否已经有子用户在打牌了， 如果有，则直接使用此子用户
    local sub_user_id = duokai_lib.get_sub_user_by_desk_no(user_id, desk_no)
    if (sub_user_id == -1) then
        duokai_lib.get_one_sub_user_list(user_id, function(ret, new_sub_user_id, new_sub_user_name)
            if (ret == -1) then
                local user_info = usermgr.GetUserById(user_id);
                if(user_info ~= nil) then
                    netlib.send(function(buf)
                        buf:writeString("DKLIMIT");
                        buf:writeInt(duokai_lib.USER_NUM_LIMIT);
                    end, user_info.ip, user_info.port);
                end
                TraceError("账号数量达到上限")
                return
            elseif (ret == -2) then
                TraceError("账号创建失败")
                return
            end
            after_get_sub_user_func(new_sub_user_id, new_sub_user_name)
        end)
    else
        local sub_user_info = usermgr.GetUserById(sub_user_id)
        if (sub_user_info == nil) then
            TraceError("子账号信息为空，子账号保持同步有bug")
            return
        end
        after_get_sub_user_func(sub_user_id, sub_user_name)
    end    
end
--[[
function duokai_lib.sub_user_login(parent_user_id, sub_user_id, sub_user_name)
        local user_info = usermgr.GetUserById(sub_user_id);
        if user_info ~= nil then
            TraceError('子帐号已经登录parent='..parent_user_id..',sub='..sub_user_id);
            return;
        end
        local buf = lua_buf:new()
        local ip = buf:ip();
        local port = buf:port();
        local key = getuserid2(ip, port);
        userlist[key] = {}
        userlist[key].userId = tonumber(sub_user_id) --用户的数据库ID
        userlist[key].userName = sub_user_name --用户名
        userlist[key].key  = key
        userlist[key].ip   = ip
        userlist[key].port = port
        userlist[key].lastRecvBufTime = os.time() --上一次收到消息的时间
        userlist[key].networkDelayTime = os.time() --网络延迟时间
        userlist[key].SendNetworkDelayFlag = 0 --是否发送了网络延迟包，如果是正常收到数据包，需要把他设置成0
        userlist[key].isrobot = false --默认为非机器人
        userlist[key].realrobot = false --用于记录真正是否机器人,主要增加了room.cfg.ignorerobot, 为了实现方便,将这里增加一个真正的机器标识
        userlist[key].nRegSiteNo = 0;
        userlist[key].sockeClosed = false  --socket是否被关闭了
        userlist[key].visible_page = 0      --该用户进入房间之后观看牌桌的页号，初始化为0，表示还没有请求过有效页
        userlist[key].desk_in_page = 0      --该用户能够查看的页面牌桌数量
        userlistIndexId[userlist[key].userId] = userlist[key]

        user_info = usermgr.GetUserById(sub_user_id);
        eventmgr:dispatchEvent(Event("h2_on_sub_user_login", {user_info = user_info, userinfo = user_info}));
end
--]]

--用户退出一桌
function duokai_lib.exit_game(user_id, desk_no)
    --退出当前账号
    local sub_user_id = duokai_lib.get_sub_user_by_desk_no(user_id, desk_no)
    local sub_user_info = usermgr.GetUserById(sub_user_id);
    if(sub_user_info) then
        --TraceError('sub_user_info'..sub_user_info.userId);
        pre_process_back_to_hall(sub_user_info);
    end
end

function duokai_lib.on_recv_sub_user_login_gc(buf)
    --TraceError("duokai_lib.on_recv_sub_user_login_gc")
    local user_id = buf:readInt()
    local user_game_key = buf:readString()
    --登录gs
    local buf = lua_buf:new()
    buf:writeInt(user_id)
    buf:writeString(user_game_key)
    buf:writeByte(0)
    buf:writeString("0")
    onrecvlogin(buf)    
end

--请求多开一桌
function duokai_lib.on_recv_join_game(buf)
    local user_info = userlist[getuserid(buf)]	
   	if not user_info then return end;
    local desk_no = buf:readString()  
    local match_id = desk_no;
    if(matcheslib ~= nil) then
        local match_desk_no = matcheslib.get_user_match_desk_no(user_info, match_id);
        if(match_desk_no > 0) then
            desk_no = match_desk_no;
        elseif(match_desk_no == -2) then
            return;
        elseif(match_desk_no == -1 and tonumber(desk_no) == nil) then
            return;
        end
    end
    DoRecvRqWatch(user_info, tonumber(desk_no), 0);
    --duokai_lib.join_game(user_info.userId, tonumber(desk_no), 0, 1)
end

function duokai_lib.get_sub_play_num(user_id)
    --多开限制
    local join_match_num = 0;
    if(matcheslib ~= nil) then
        local user_info = usermgr.GetUserById(user_id);
        join_match_num = matcheslib.get_user_join_match_num(user_info);
    end
    local num = 0;
    for k, v in pairs(duokai_lib.user_list[user_id].sub_user_list) do
        if (duokai_lib.get_user_desk(k) > 0) then
            num = num + 1;
        end
    end
    num = num + join_match_num;
    return num;
end

--请求退出一桌
function duokai_lib.on_recv_sub_desk(buf)
    local user_info = userlist[getuserid(buf)]
	if not user_info then return end
    local desk_no = buf:readString()
    duokai_lib.exit_game(user_info.userId, tonumber(desk_no));    
end

--收到我的桌子列表
function duokai_lib.on_recv_my_desk_list(buf)
    local user_info = userlist[getuserid(buf)]	
	if not user_info then return end    
    duokai_lib.update_sub_desk_info(user_info)
end

--收到普通桌的桌子列表
function duokai_lib.on_recv_common_desk_list(buf)
    local user_info = userlist[getuserid(buf)]	
	if not user_info then return end
    user_info.open_duokai_match_tab = nil;
    local my_desk_no = user_info.desk
    --发送桌子列表开始
    netlib.send(function(buf)
        buf:writeString("DKCOMMONLSTS")
    end, user_info.ip, user_info.port)
    for i = 1, 5 do
        isfast = 0
        if (i == 5) then
            isfast = 1
        end
        DoQuestDeskList(user_info, 1, i, 1, 0, isfast, -1, function(send_list)
            local desk_start = 1
            local desk_end = #send_list
            netlib.send(function(out_buf)
                out_buf:writeString("DKCOMMONLST")
                out_buf:writeInt(desk_end - desk_start + 1)
                for idesk = desk_start, desk_end do
                    local desk_no = send_list[idesk]
                    local desk_info = desklist[desk_no]                 
                    if (desk_no == my_desk_no) then
                        out_buf:writeString("-1")
                    else
                        out_buf:writeString(desk_no)
                    end
                    --名称 --todo需要处理vip房间名字的问题
                    out_buf:writeString(desk_info.name)
                    --桌子类型:1普通,2比赛桌
                    out_buf:writeByte(1)
                    --小盲
                    out_buf:writeInt(desk_info.smallbet)
                    --大盲
                    out_buf:writeInt(desk_info.largebet)
                    --金钱下限
                    out_buf:writeInt(desk_info.at_least_gold)
                    --金钱上限
                    out_buf:writeInt(desk_info.at_most_gold)
                    --抽水
                    --out_buf:writeInt(deskinfo.specal_choushui)
                    --最少开局人数
                    out_buf:writeByte(desk_info.min_playercount)
                    --最大开局人数
                    out_buf:writeByte(desk_info.max_playercount)
                    --当前在玩人数
                    out_buf:writeByte(hall.desk.get_user_count(desk_no))
                    local watch_count = 0
                    for k,v in pairs(desk_info.watchingList) do
                        watch_count = watch_count + 1
                    end
                    --观战人数
                    out_buf:writeInt(watch_count)
                    --是不是VIP房
                    --out_buf:writeByte(is_vip or 0)
                    end
                end
            , user_info.ip, user_info.port)
        end)
    end
    --发送桌子列表结束
    netlib.send(function(buf)
        buf:writeString("DKCOMMONLSTE")
    end, user_info.ip, user_info.port)
end

duokai_lib.on_recv_match_desk_list = function(buf)
	local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    user_info.open_duokai_match_tab = 1;
    duokai_lib.net_send_match_list(user_info);
end

duokai_lib.net_send_match_list = function(user_info)
	if not user_info or not matcheslib or user_info.open_duokai_match_tab == nil then return end;
    local length = 0;
    local user_match_info = matcheslib.user_list[user_info.userId];
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
    for _, v in pairs(tmp_list) do
    	if v.status == 1 then
        	length = length + 1;
        end
    end
    netlib.send(function(buf)
        buf:writeString("DKMATCHLST");
        buf:writeInt(length);
        for k, v in pairs(tmp_list) do
        	if v.status == 1 then
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
            end
        end
    end, user_info.ip, user_info.port);
end

function duokai_lib.net_send_desk_status(user_info, deskno, ntype, left_num, timeout)
    if(user_info ~= nil) then
        netlib.send(function(buf)
            buf:writeString("DKDESKSS");
            buf:writeString(tostring(deskno));
            buf:writeByte(ntype or 0);--0 没有状态 1 未轮到自己 2 轮到自己
            buf:writeInt(left_num or -1);--还有几位轮到自己
            buf:writeInt(timeout or -1);--轮到自己，还有多少时间超过
        end, user_info.ip, user_info.port);
    end
end

function duokai_lib.on_game_event(e)
    --TraceError('on_game_event');
    for k, v in pairs(e.data) do
        local user_info = usermgr.GetUserById(v.userid);
        if(user_info ~= nil) then
            local desk_no = user_info.desk;
            local players = deskmgr.getplayers(desk_no);
            --找到该桌子所有观战
            for k1, v1 in pairs(players) do
                duokai_lib.net_send_desk_status(v1.userinfo);
            end
            timelib.createplan(function()
                for k1, v1 in pairs(players) do
                    duokai_lib.game_over_buf_list[v1.userinfo.userId] = nil;
                end
            end, 2);
            break;
        end
    end
end

function duokai_lib.on_recv_want_duokai(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    if(user_info.log_want_duokai ~= nil) then
        return;
    end
    local yes_or_no = buf:readByte();
    if(yes_or_no ~= 1) then
        yes_or_no = 0;
    end
    user_info.log_want_duokai = 1;
    duokai_db_lib.log_want_duokai_info(user_info.userId, usermgr.getlevel(user_info), user_info.gamescore, yes_or_no)
end
--协议命令
cmd_tex_match_handler = 
{ 
    ["DKJGAME"] = duokai_lib.on_recv_join_game, --请求增开一桌
    ["DKSUBDESK"] = duokai_lib.on_recv_sub_desk, --请求退出一桌
    ["DKLGGC"] = duokai_lib.on_recv_sub_user_login_gc, --收到子账号登录了gc
    ["DKMYDLIST"] = duokai_lib.on_recv_my_desk_list, --收到获取多开的桌子列表
    ["DKCOMMONLST"] = duokai_lib.on_recv_common_desk_list, --收到获取多开的桌子列表
    ["DKMATCHLST"] = duokai_lib.on_recv_match_desk_list, --收到获取多开的桌子列表
    ["DKWANTDK"] = duokai_lib.on_recv_want_duokai, --收到是否想多开
    
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", duokai_lib.on_timer_second)
eventmgr:addEventListener("h2_on_user_login", duokai_lib.on_after_user_login) 
eventmgr:addEventListener("on_user_exit", duokai_lib.on_user_exit)
eventmgr:addEventListener("on_user_kicked", duokai_lib.on_user_kicked)
eventmgr:addEventListener("on_user_standup", duokai_lib.on_user_standup)
eventmgr:addEventListener("on_user_exit_watch", duokai_lib.on_user_exit_watch)
eventmgr:addEventListener("on_show_panel", duokai_lib.on_show_panel)
eventmgr:addEventListener("game_event", duokai_lib.on_game_event)

