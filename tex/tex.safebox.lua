tTexSafeBoxSqlTemplete =
{
    --得到保险箱相关数据
    getsafeboxagoldbout = "call sp_getuser_safebox_info(%d,%d,%d)",

    --得到密码相关
    getsafeboxpwabout = "call sp_getuser_safebox_pwinfo(%d,%s,%s,%d)",

    --把玩家email写入数据库
    updateuseremail = "update users set email = %s where id = %d;commit;",
    --获取用户email
    getuseremail = "select email from users where id = %d;",
    --更新保险箱格子数量
    get_safebox_num = "select box_num from user_safebox_info where user_id = %d",
    --更新保险箱格子数量
    update_safebox_num = "update user_safebox_info set box_num = box_num + %d where user_id = %d and box_num <= 20- %d;",
}
tTexSafeBoxSqlTemplete = newStrongTable(tTexSafeBoxSqlTemplete)

texSafeBoxCfg = _S{
    EXCHANGERADIO = 10000;--兑换比例
    GETMINGOLD = 1,--取出的最小钱数
    STOREMINGOLD = 1,--存入的最小钱数
    BOXNUM = 1,--保险箱格子数
    PERBOXGOLD = 5000,--每个格子最大存入钱数
}

--保险箱接口，以后保险箱所有新加入的代码都写到这个接口
if (safebox_lib == nil) then
    safebox_lib = 
    {
        add_safebox_num = NULL_FUNC,
        MAX_BOX_NUM = 20,   --保险箱最大格子数量
    }
end

--增加一个保险箱格子数
function safebox_lib.add_safebox_num(user_id, box_num)
    if (box_num <= 0) then
        TraceError("错误，保险箱格子为什么要减少")
    end
    local sql = ""
    local user_info = usermgr.GetUserById(user_id)
    if not user_info.safeboxnum then return end
    if (user_info ~= nil) then --保证保险箱格子数不会超过20个
        if (user_info.safeboxnum + box_num > 20) then
            box_num = 20 - user_info.safeboxnum
        end
        user_info.safeboxnum = user_info.safeboxnum + box_num
        sql = string.format(tTexSafeBoxSqlTemplete.update_safebox_num, box_num, user_id, box_num)
        dblib.execute(sql, nil, user_id)
    else
        local sql2 = string.format(tTexSafeBoxSqlTemplete.get_safebox_num, user_id)
        dblib.execute(sql2, function(dt)
            if (dt and #dt > 0) then
                if (dt[1].box_num + box_num > 20) then
                    box_num = 20 - dt[1].box_num
                end
                sql = string.format(tTexSafeBoxSqlTemplete.update_safebox_num, box_num, user_id, box_num)
                dblib.execute(sql, nil, user_id)
            end 
        end)
    end
    
end

--点击请求保险箱信息
function onrecvclicksafebox(buf)    
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    --在桌子里面点不出现,不返回
    if userinfo.desk and userinfo.desk > 0 then
        return
    end

    dblib.execute(string.format(tTexSafeBoxSqlTemplete.getsafeboxagoldbout,userinfo.userId,0,0),
        function(dt)
            if dt and #dt > 0 then
                if dt[1]["result"] == 0 or dt[1]["result"] == 1 then
                    if not userinfo.safeboxnum then
                        userinfo.safeboxnum = dt[1]["box_num"]        --texSafeBoxCfg.BOXNUM
                    end
                end

                if dt[1]["result"] == 0 then--没有添加过保险箱第一次
                    userinfo.safegold = 0--写入内存
                    net_send_user_safebox_case(userinfo,1)
                elseif dt[1]["result"] == 1 then--已经有了保险箱
                    userinfo.safegold = dt[1]["safe_gold"]--写入内存

                    dblib.execute(format(tTexSafeBoxSqlTemplete.getuseremail, userinfo.userId), function(dt1)
                		if not dt1 or #dt1 <= 0 then return end
                		userinfo.email = dt1[1]["email"]

                        if not userinfo.email or userinfo.email == "" then
                            --3 没有设置过邮箱的老用户
                            net_send_user_safebox_case(userinfo,3,dt[1]["safe_gold"])   
                        else
                            --2 正常的老用户
                            net_send_user_safebox_case(userinfo,2,dt[1]["safe_gold"])
                        end
                	end)
                    eventmgr:dispatchEvent(Event("on_get_safebox_info", _S{user_info=userinfo}));
                elseif dt[1]["result"] == -1 then--数据库没有该人的记录
                    net_send_user_safebox_case(userinfo,0)
                end
            else
                TraceError("查询用户保险箱数据出错")
            end
        end)
end
--获取玩家在过去30分钟内总赢得钱数
function gethalfhourwintotal(userinfo)
    local totalwin = 0
    local lists = userinfo.extra_info["F09"] or {}
    local interval = userinfo.extra_info["F09"].interval or 0  --时间间隔
    for _, item in pairs(lists) do
        if(type(item) == "table") then
            if(os.time() - item.gametime < interval) then
                totalwin = totalwin + item.wingold
            end
        end
    end

    return totalwin
end
--请求存取游戏币
function onrecvchangesafeboxgold(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    if not userinfo.safegold then return end
    if not userinfo.safeboxnum then return end

    --在桌子里面点不出现,不返回
    if userinfo.desk and userinfo.desk > 0 then
        return
    end  

    if userinfo.iscuning then--已经在帮其存钱，稍后才能存取
        TraceError(format("保险箱正在存取，请稍候...userid[%d]",userinfo.userId))
        return
    end

    userinfo.iscuning = 1--设置玩家正在存取钱
    
    local nType = buf:readByte()

    if nType ~= 0 and nType ~= 1 then
        TraceError("非法的数字传来" .. nType)
        userinfo.iscuning = nil
        return
    end

    local gold = buf:readInt()--该数字是个比例后的结果
    gold = math.floor(math.abs(gold))

    local pwd = ""
    if nType == 1 then
        pwd = buf:readString()
    end

    if nType == 0 then --存钱
        if userinfo.desk and userinfo.desk > 0 then
            TraceError("玩家想在房间里存钱?想作弊?")
            userinfo.iscuning = nil
            return
        end

        if gold * texSafeBoxCfg.EXCHANGERADIO > userinfo.gamescore then
            TraceError(format("尝试存入比身上钱多的钱,userid[%d]", userinfo.userId))
            userinfo.iscuning = nil
            return
        end
        
        if userinfo.safegold + gold > userinfo.safeboxnum * texSafeBoxCfg.PERBOXGOLD then
            TraceError("已经超过存入上限,别存了。。")
            userinfo.iscuning = nil
            return
        end
        local extra_info = userinfo.extra_info
        local lasttime = extra_info["F09"] and extra_info["F09"].last_time or 0
        local interval = extra_info["F09"].interval or 1800
        local lefttime = lasttime + interval - os.time()
        --除去赢了的筹码，其他的筹码都能够存入
        local cansavegold = userinfo.gamescore - gethalfhourwintotal(userinfo)
        if(lefttime > 0 and cansavegold < gold * 10000 ) then
            net_send_lefttime_cansave(userinfo, lefttime)
            userinfo.iscuning = nil
            return
        end
        docheckandchangegold(userinfo,gold,nType)
    else--取钱
        if gold > userinfo.safegold then
            TraceError(format("尝试取走比自己保险箱多的钱,userid[%d]", userinfo.userId))
            userinfo.iscuning = nil
            return
        end

        dblib.execute(string.format(tTexSafeBoxSqlTemplete.getsafeboxpwabout,userinfo.userId,dblib.tosqlstr(pwd),dblib.tosqlstr(''),2),
            function(dt)
                if #dt > 0 then
                    if dt[1]["success"] == 1 then
                        docheckandchangegold(userinfo,gold,nType)                   
                    else
                        net_send_getgoldpw_case(userinfo)--密码输入错了
                        userinfo.iscuning = nil
                    end
                else
                    TraceError("验证用户密码失败")
                    net_send_getgoldpw_case(userinfo)
                    userinfo.iscuning = nil
                end
           end, userinfo.userId)
    end
end

--判断保险箱密码是否正确
function check_safebox_pwd(user_id,password,call_back)
	if(call_back==nil)then return end;
	local sql=string.format(tTexSafeBoxSqlTemplete.getsafeboxpwabout,user_id,dblib.tosqlstr(password),dblib.tosqlstr(''),2)
    dblib.execute(sql,
        function(dt)
            if dt and #dt > 0 then
                if dt[1]["success"] == 1 then
                    call_back(user_id,1)--告诉回调的方法，密码校验通过了
                else
                	call_back(user_id,-1)--告诉回调的方法，密码错了
                end                                       
            else
            	call_back(user_id,-2)--告诉回调的方法，可能没开通保险箱
            end
       end, user_id)	
end

--检查和更改玩家金币
function docheckandchangegold(userinfo,gold,nType)
    dblib.execute(string.format(tTexSafeBoxSqlTemplete.getsafeboxagoldbout,userinfo.userId,gold,nType + 1),
        function(dt)
            if dt and #dt > 0 then
                if dt[1]["success"] == 1 then
                    --加减钱，放到存储过程中去直接处理
                    if nType == 1 then
                        userinfo.safegold = userinfo.safegold - gold
                        userinfo.gamescore = userinfo.gamescore + gold*texSafeBoxCfg.EXCHANGERADIO
                        --通知自己
        				
                        --usermgr.addgold(userinfo.userId,(gold * texSafeBoxCfg.EXCHANGERADIO), 0, 80, -1, 1)
                    else
                        userinfo.safegold = userinfo.safegold + gold
                        userinfo.gamescore = userinfo.gamescore - gold*texSafeBoxCfg.EXCHANGERADIO
                        --usermgr.addgold(userinfo.userId,-(gold * texSafeBoxCfg.EXCHANGERADIO),0, 80, -1, 1)
                    end
        			net_send_user_new_gold(userinfo, userinfo.gamescore)
                    net_send_user_getsetgold_case(userinfo,1,userinfo.safegold)
                else
                    TraceError("出现存取钱数据异常,尝试取走比自己保险箱多的钱")
                    net_send_user_getsetgold_case(userinfo,0,0)
                end
            else
                TraceError("存取钱出错")
            end
            userinfo.iscuning = nil
            --抓囧人要同步一下数据库，所以要发一个事件
            eventmgr:dispatchEvent(Event("on_safebox_sq", _S{userinfo=userinfo,nType=nType,gold=gold}));
            
        end, userinfo.userId)
end

--请求设置密码相关
function onrecvsafeboxpassword(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    if not userinfo.safeboxnum then return end

    --在桌子里面点不出现,不返回
    if userinfo.desk and userinfo.desk > 0 then
        return
    end

    local nType = buf:readByte();

    if nType ~= 0 and nType ~= 1 and nType ~= 2 then--0第一次设置密码,1修改密码,2.设置邮箱
        TraceError("非法的数字传来" .. nType)
        return
    end

    local oldpassword = buf:readString()
    local newpassword = ""
    local email = ""
    if nType == 1 then--1修改密码,0第一次设置密码,2.设置邮箱
        newpassword = buf:readString()
    elseif nType == 0 or nType == 2 then
        email = buf:readString()
    end

    dblib.execute(string.format(tTexSafeBoxSqlTemplete.getsafeboxpwabout,userinfo.userId,dblib.tosqlstr(oldpassword),dblib.tosqlstr(newpassword),nType),
        function(dt)
            if dt and #dt > 0 then
                local flag = dt[1]["success"]
                if flag then
                    --第一次设置密码时记录设置日志
                    if nType == 0 then
                         --把email写入数据库
                        do_save_user_email(userinfo, email)
                        dblib.execute(string.format("insert into log_user_setpw_info(user_id,user_pw,sys_time) values(%d,%s,now())",userinfo.userId,dblib.tosqlstr(oldpassword)))
                    elseif nType == 1 then
                        dblib.execute(string.format("insert into log_user_setpw_info(user_id,user_pw,sys_time) values(%d,%s,now())",userinfo.userId,dblib.tosqlstr(newpassword)))
                    elseif nType == 2 then
                        flag = 3
                         --把email写入数据库
                        do_save_user_email(userinfo, email)
                    end
                    net_send_setpw_case(userinfo, flag)
                else
                    TraceError("数据库返回值出错") 
                end
            else
                TraceError("密码相关设置失败")
            end
        end)
end

--请求玩家的邮箱地址
function onrecvgetuseremail(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;

    dblib.execute(format(tTexSafeBoxSqlTemplete.getuseremail, userinfo.userId), function(dt1)
        if not dt1 or #dt1 <= 0 then return end

        netlib.send(function(buf1)
            buf1:writeString("TXSBFE")
            buf1:writeString(dt1[1]["email"])--玩家邮箱
        end,userinfo.ip,userinfo.port)

    end)
   
end

--把玩家的email写入数据库
function do_save_user_email(userinfo,email)
    dblib.execute(string.format(tTexSafeBoxSqlTemplete.updateuseremail,dblib.tosqlstr(email),userinfo.userId),function(dt)end,userinfo.userId)
end
