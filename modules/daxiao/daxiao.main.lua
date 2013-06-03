trace("daxiao_hall.main.lua loaded!!!")
dofile("games/modules/daxiao/daxiao.lua") --心跳十分钟功能
if (daxiao_hall and daxiao_hall.on_socket_close) then
    eventmgr:removeEventListener("on_socket_close", daxiao_hall.on_socket_close);
end

if (daxiao_hall and daxiao_hall.timer) then
    eventmgr:removeEventListener("timer_second", daxiao_hall.timer);
end


daxiao_hall.name = "daxiao"
daxiao_hall.table = ""
gamepkg = daxiao_hall

----------------------------机制代码--------------------------------------
function daxiao_hall.TransSiteStateValue(state)
	return SITE_UI_VALUE.NULL
end
function daxiao_hall.OnAbortGame(userKey)
    return
end
function daxiao_hall.CanWatch(deskno)
    return false
end
function daxiao_hall.AfterUserWatch(target_userinfo, userinfo)
	return
end
function daxiao_hall.AfterUserSitDown(userid, desk, site, bRelogin)
	return
end
function daxiao_hall.AfterUserSitDownMessage(userid, desk, site, bRelogin)
    return
end
function daxiao_hall.CanEnterGameGroup(szPlayingGroupName, nPlayingGroupId, nScore)
    return
end
function daxiao_hall.CanUserQueue(userKey)
    return 1, 0
end
function daxiao_hall.CanAfford(userinfo, paygold, pay_limit)
	return true
end
function daxiao_hall.getGameStart(deskno)
	return false
end
function daxiao_hall.AfterOnUserStandup(userid, desk, site)
	return
end
function daxiao_hall.OnUserReLogin(userinfo)
	return
end
function daxiao_hall.init_desk_info()
	return {};
end
function daxiao_hall.init_site_info()
	return {};
end
function daxiao_hall.on_start_server()	
end
function daxiao_hall.ontimecheck()	
end
function daxiao_hall.get_user_key(buf)
    return format("%s:%s", buf:ip(), buf:port())
end

----------------------------机制代码结束-------------------------------------
-----------------------------------网络收包------------------------------------
--处理输入队列
function gameonrecv(cmd, recvbuf)
	--TraceError("gameonrecv()cmd="..cmd)
    local ip,port = recvbuf:ip(), recvbuf:port()
    gamedispatch(cmd, recvbuf)
end

--将命令相关内容，打包加入到输出队列
function gameonsend(sCommand, sendbuf)
    --TraceError("game onsend ".. sCommand)
    gamedispatch(sCommand, sendbuf)
end

function gamedispatch(sCommand, buf)
	local f = cmdGameHandler[sCommand]
	if f ~= nil then        
        local ret, errmsg = xpcall(function() return f(buf) end, throw)
		if (ret) then
			trace("**"..sCommand.. " call command ok ")
		else
			trace("** call 游戏 command faild ".. sCommand)
		end
	else
		trace("** not found 游戏 command ->".. sCommand)
	end
end
----------------------------------------------------------------
--增加用户
function daxiao_hall.add_user(user_key, user_id, nick, vip_level, ip, port)
    if (daxiao_hall.user_list[user_key] ~= nil and
        daxiao_hall.user_list[user_key].init == 0) then
        return
    end
    local user_info = daxiao_hall.user_id_list[user_id]
    --如果上一个用户还在，就删除这个用户
    if (user_info ~= nil) then
        daxiao_hall.del_user(user_info.key)
    else
        user_info = {}
    end
    user_info.vip_level = vip_level
    user_info.nick = nick
    user_info.last_recv_time = os.time()
    user_info.user_id = user_id
    user_info.userId = user_id  --为了兼容以前的代码
    user_info.key = user_key
    user_info.ip = ip
    user_info.port = port
    user_info.init = 1
    daxiao_hall.user_list[user_key] = user_info
    daxiao_hall.user_id_list[user_id] = user_info
end
--减少用户
function daxiao_hall.del_user(user_key)    
    if (daxiao_hall.user_list[user_key] ~= nil) then
        if (daxiao_hall.user_list[user_key].init == 0) then
            daxiao_hall.user_list[user_key].init = -1
        else
            local user_id = daxiao_hall.user_list[user_key].user_id
            daxiao_hall.user_list[user_key] = nil
            daxiao_hall.user_id_list[user_id] = nil
        end
    end
end
function daxiao_hall.get_user_info(user_id)
    return daxiao_hall.user_id_list[user_id]
end
--通过key获取用户
function daxiao_hall.get_user_info_by_key(user_key)
    return daxiao_hall.user_list[user_key]
end
--收到客户端关闭socket
function daxiao_hall.on_socket_close(e)
    local user_key = e.data.user_key
    daxiao_hall.del_user(user_key)
end
--检测用户是否无效了
function daxiao_hall.timer(e)
   for k, v in pairs(daxiao_hall.user_list) do
        if (os.time() - v.last_recv_time > 25 and v.init ~= -1) then
            daxiao_hall.del_user(v.key)
            tools.CloseConn(v.ip, v.port)
        end
   end
end
--接收定时器
function daxiao_hall.on_echo(buf)
    local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf))
    if (user_info ~= nil) then
        user_info.last_recv_time = os.time()
    end
end
--进入游戏
function daxiao_hall.on_recv_open_game(buf)
    local user_key = buf:readString()
    local user_id = buf:readInt()
    local user_nick = buf:readString()
    local vip_level = buf:readInt()
    if (daxiao_adapt_lib.is_valid_key(user_key, user_id) == 0) then
        return
    end
    daxiao_hall.add_user(daxiao_hall.get_user_key(buf), user_id, user_nick, vip_level, buf:ip(), buf:port())
    local user_info = daxiao_hall.get_user_info(user_id)    
    if user_info.init_daxiao_flag == nil then
        daxiao_lib.on_after_user_login(user_info, daxiao_lib.do_open_game)
        daxiao_lib.refresh_buy_yinpiao(user_info)
    else
        daxiao_lib.do_open_game(user_info)		
    end

end

daxiao_hall.init_map = function()
    cmdGameHandler = 
    {
       ["DVECHO"] = daxiao_hall.on_echo, --请求服务端，请求打开面板信息
       ["DVDOPEN"] = daxiao_hall.on_recv_open_game, --请求服务端，请求打开面板信息
       ["DVDCLOSE"] = daxiao_hall.on_recv_close_game, --请求服务端，请求关闭面板信息
	}
end

daxiao_hall.init_map();
eventmgr:addEventListener("timer_second", daxiao_hall.timer);
eventmgr:addEventListener("on_socket_close", daxiao_hall.on_socket_close);
