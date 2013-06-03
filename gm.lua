if not gm_lib then
    gm_lib =
    {
        
        check_gm_cmd = NULL_FUNC, --是否是gm指令
        send_gm_ret = NULL_FUNC, --发送gm执行结果到客户端
        gm_type = 
        {
            user = 0,   --一般用户
            admin = 1,  --管理员
            kefu = 2,   --客服                        
            
        },
        gm_cmd = 
        {
            micro_speak = 2,  --小喇叭
            add_dx_user = 2,  --增加三分钟账号的gm指令
            change_car_rank = 1,  --修改车的排行
        },
        account_info =   --gm账号信息
        {
            {user_id = 106, pwd="123", open = 0, gm_type = 2},
            {user_id = 1073, pwd="1q3e2w", open = 0, gm_type = 1},
            {user_id = 26852373, pwd="dozen!*%", open = 0, gm_type = 2},
            
        },
        login_failed_rate = 100,
    }
end

--获取用户账号类型
gm_lib.get_user_info = function(user_id)
    local gm_info = {user_id = user_id, pwd="dozengame2012", open = 0, gm_type = 0}
    for k, v in pairs(gm_lib.account_info) do
        if (v.user_id == user_id) then
            gm_info = v
            break;
        end
    end
    return gm_info
end
--[[
    返回gm指令结果
    user_id : gm账号id
    msg : gm执行结果
--]]
gm_lib.send_gm_ret = function(user_id, msg)
    local user_info = usermgr.GetUserById(user_id)
    if (user_info == nil) then
        return 1
    end
    SendChatToUser(4, user_info, _U(msg), user_id, user_info.nick)
end

--gm指令
gm_lib.check_gm_cmd = function(user_id, msg)
    local gm_user_info = gm_lib.get_user_info(user_id)
    if (gm_user_info.gm_type <= gm_lib.gm_type.user) then        
        return 0
    end
    local pre, cmd, args = string.match(msg, "(.*):(.*)%((.*)%)")
    if (pre == "gm") then --gm指令
        if (cmd == "open" and args == gm_user_info.pwd) then
            gm_user_info.open = 1              
            gm_lib.send_gm_ret(user_id, "gm open");
            return 1
        elseif (cmd == "close") then
            gm_lib.send_gm_ret(user_id, "gm close");
            gm_user_info.open = 0
            return 1
        end
        if (gm_user_info.open == 0) then
            gm_lib.send_gm_ret(user_id, "warning! not open");
            return
        end
        if (gm_lib.gm_cmd[cmd] ~= gm_user_info.gm_type) then --检查gm指令是否是可以使用制定的gm账号类型
            gm_lib.send_gm_ret(user_id, "warning! error cmd");
            return
        end
        --记录gm指令日志
        local sql = "insert into log_gm_record(user_id, cmd, args, sys_time) values(%d,'%s','%s',now())"
        sql = string.format(sql, user_id, cmd, args)
        dblib.execute(sql)
        --派发gm指令
        gm_lib.send_gm_ret(user_id, "gm start "..cmd.."(".. args..")");
        eventmgr:dispatchEvent(Event("gm_cmd", {user_id = user_id, gm_type = gm_user_info.gm_type, cmd = cmd, args = split(args, ",")}))
        gm_lib.send_gm_ret(user_id, "gm end "..cmd.."(".. args..")");
        return 1
    end
    return 0
end
