TraceError("init duokai_gc_lib...初始化多开模块")
dofile("games/modules/duokai/lua_buf.lua")
if (duokai_gc_lib and duokai_gc_lib.on_after_user_login) then
    eventmgr:removeEventListener("user2_on_user_login", duokai_gc_lib.on_after_user_login)
end

if (duokai_gc_lib and duokai_gc_lib.on_user_exit) then
    eventmgr:removeEventListener("user2_on_user_exit", duokai_gc_lib.on_user_exit); 
end

if (duokai_gc_lib and duokai_gc_lib.on_timer_second) then
    eventmgr:removeEventListener("timer_second", duokai_gc_lib.on_timer_second)
end

if not duokai_gc_lib then
	duokai_gc_lib = _S
	{
		user_list = {}
	}
end


--------------------------------------------------------
--框架相关处理
function duokai_gc_lib.need_process_msg(ip, port)
    return 0
end

function duokai_gc_lib.pre_process_send_msg(lua_buf)
    return ip, port
end
--------------------------------------------------------

--定时器，发送echo命令
function duokai_gc_lib.on_timer_second(e)
    
end

--用户退出
function duokai_gc_lib.on_user_exit(e)
    local user_id  = e.data.user_id
    duokai_gc_lib.user_list[user_id] = nil;
end

--用户登录
function duokai_gc_lib.on_after_user_login(e)
    local user_info = e.data.user_info
    if (duokai_gc_lib.user_list[user_info.userId] == nil) then
        return
    end
    duokai_gc_lib.user_list[user_info.userId].user_info = user_info
    local gs_id = duokai_gc_lib.user_list[user_info.userId].gs_id
    --通知gs用户登录成功
    netlib.send_to_gs_ex("tex", gs_id, function(buf)
        buf:writeString("DKLGGC")
        buf:writeInt(user_info.userId)
        buf:writeString(user_info.szGameKey)        
    end)
    
end

--初始化子用户
function duokai_gc_lib.init_sub_user(sub_user_id, parent_id, gs_id)
    duokai_gc_lib.user_list[sub_user_id] = {parent_id = parent_id, gs_id = gs_id, user_info = {}}    
end

--收到添加子用户
function duokai_gc_lib.on_recv_add_user(buf)
    local user_id = buf:readInt()
    local sub_user_id = buf:readInt()
    local sub_user_name = buf:readString()
    local gs_id = buf:readInt()
    local sub_user_info = usermgr.GetUserById(sub_user_id)
    if (sub_user_info ~= nil) then --如果子账号已经登陆了，直接返回登陆成功
        --通知gs用户登录成功
        netlib.send_to_gs_ex("tex", gs_id, function(buf)
            buf:writeString("DKLGGC")
            buf:writeInt(sub_user_info.userId)
            buf:writeString(sub_user_info.szGameKey)        
        end)
    else --模拟一个用户登录
        local buf = lua_buf:new()
        TraceError(sub_user_name)
        buf:writeString(sub_user_name)
        buf:writeString("11")
        buf:writeByte(0)
        buf:writeString("0")
        onrecvlogin(buf, sub_user_id)
        duokai_gc_lib.init_sub_user(sub_user_id, user_id, gs_id)
    end
end
--协议命令
cmd_tex_match_handler = 
{ 
    ["DKADDUSER"] = duokai_gc_lib.on_recv_add_user, --请求某一个用户登录
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end
eventmgr:addEventListener("timer_second", duokai_gc_lib.on_timer_second)
eventmgr:addEventListener("user2_on_user_login", duokai_gc_lib.on_after_user_login)
eventmgr:addEventListener("user2_on_user_exit", duokai_gc_lib.on_user_exit)

