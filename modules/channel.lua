TraceError("初始化频道::::::::::::::::")

if not channellib then
    channellib = _S
    {
        net_recv_get_rank_list = NULL_FUNC,
        net_recv_get_channel_user_list = NULL_FUNC,
        net_recv_get_channel_id = NULL_FUNC,
        net_recv_get_channel_user_pm = NULL_FUNC,
        net_send = NULL_FUNC,
        ontimecheck = NULL_FUNC,
        on_game_over = NULL_FUNC,
        update_win_lost_gold = NULL_FUNC,
        on_game_get_gold = NULL_FUNC,
        update_user_shortid = NULL_FUNC,
        SQL = _S
        {
            get_day_rank_list = "select a.gold, a.channel_id from channel_paimin_day a LIMIT 50;",     
            get_total_rank_list = "select a.gold, a.channel_id from channel_paimin_total a LIMIT 50;",
            refresh_rank_list = "call sp_gen_pdpm(%d);";
            update_win_lost_gold = "call sp_update_pdpm_win_lost_gold(%d, %d);",
            update_last_gold_time = "update dw_user_info set last_get_gold_time = NOW() where userid = %d;commit;",
            get_last_gold_time = "select last_get_gold_time from dw_user_info where userid = %d;",
            init_channel_roleinfo = "select * from configure_channel_roleinfo",
            refresh_channel_user_pm = "call sp_gen_channel_user_pm();",
            get_channel_user_pm = "select cup.*, u.face, u.nick_name, u.sex from channel_user_paimin cup left join users u on u.id = cup.user_id where channel_id = %d order by sys_time LIMIT 50;",
            get_user_vip_info = "SELECT user_id, vip_level FROM user_vip_info WHERE over_time > NOW() AND user_id IN",
        },
        cmd = _S
        {
            net_recv_get_rank_list = "CHANNELGRL", 
            net_recv_get_channel_user_list = "CHANNELGCL",
            net_recv_get_channel_id = "CHANNELGCI",
            net_recv_get_channel_user_pm = "CHANNELUPM",
        },
        channel_role_cfg = {},
        dayranklist = {},
        userranklist = {},
        totalranklist = {},
        refresh_day_time = 0,
        refresh_total_time = 0,
        refresh_channel_user_pm = 0,
        pagesize = 30,
        refresh_interval = 60,
        refresh_interval_time = 0,
        timelib.createplan(function()
            dblib.execute(channellib.SQL.init_channel_roleinfo, function(dt)
                if(dt and #dt > 0) then
                    for k, v in pairs(dt) do
                        channellib.channel_role_cfg[v["role_id"]] = v;
                    end
                end
            end);
        end,2);
    }
end

channellib.ontimecheck = function()
    if(tonumber(groupinfo.groupid) ~= 18002) then
        return;
    end
    local tableTime = os.date("*t",os.time());
    local nowHour  = tonumber(tableTime.hour);
    local nowMin   = tonumber(tableTime.min);
    local nowSec      = tonumber(tableTime.sec);

    if(nowHour == 5 and channellib.refresh_channel_user_pm == 1) then
        --清空缓存
         channellib.userranklist = {};
    end

    if(nowHour == 4 and channellib.refresh_channel_user_pm == 0) then
        channellib.refresh_channel_user_pm = 1;
        dblib.execute(channellib.SQL.refresh_channel_user_pm);
    elseif(nowHour ~= 4 and channellib.refresh_channel_user_pm == 1) then
        channellib.refresh_channel_user_pm = 0;
    end
end

channellib.on_game_get_gold = function(userinfo) 
    if(userinfo and userinfo.channel_role and userinfo.channel_role > 0) then
        local role_cfg = channellib.channel_role_cfg[userinfo.channel_role];
        if(role_cfg and role_cfg["every_day_gold"] > 0) then
            if(userinfo.channel_get_gold_time == nil) then
                userinfo.channel_get_gold_time = os.time();
                dblib.execute(string.format(channellib.SQL.get_last_gold_time, userinfo.userId), function(dt)
                    if(dt and #dt > 0) then
                        userinfo.channel_get_gold_time = timelib.db_to_lua_time(dt[1]["last_get_gold_time"]);
                        local isbefore, endtime = timelib.is_before_today(userinfo.channel_get_gold_time);
                        if(isbefore == true) then
                            userinfo.channel_get_gold_time = os.time();
                            --送钱
                            usermgr.addgold(userinfo.userId, role_cfg["every_day_gold"], 0, g_GoldType.channel_day_gold, -1)
                            --更新数据库
                            dblib.execute(string.format(channellib.SQL.update_last_gold_time, userinfo.userId));
                            --通知用户
                            netlib.send(function(buf)
                                buf:writeString("CHANNELGGOLD");
                                buf:writeInt(userinfo.channel_role);
                                buf:writeInt(role_cfg["every_day_gold"]);
                            end, userinfo.ip, userinfo.port);
                        end
                    end
                end);
            else
               local isbefore, endtime = timelib.is_before_today(userinfo.channel_get_gold_time);  
                if(isbefore == true) then
                    userinfo.channel_get_gold_time = os.time();
                    --送钱
                    usermgr.addgold(userinfo.userId, role_cfg["every_day_gold"], 0, g_GoldType.channel_day_gold, -1)
                    --更新数据库
                    dblib.execute(string.format(channellib.SQL.update_last_gold_time, userinfo.userId));

                    --通知用户
                    netlib.send(function(buf)
                        buf:writeString("CHANNELGGOLD");
                        buf:writeInt(userinfo.channel_role);
                        buf:writeInt(role_cfg["every_day_gold"]);
                    end,userinfo.ip,userinfo.port)
                end
            end
        end
    end
end;

channellib.on_game_over = function(deskno, sitewininfo)
    local channelwininfo = {};
    for siteno, wininfo in pairs(sitewininfo) do
        local userinfo = deskmgr.getsiteuser(deskno, siteno);
        if(userinfo and userinfo.channel_id and userinfo.channel_id > 0) then
            if(channelwininfo[userinfo.channel_id] == nil) then
                channelwininfo[userinfo.channel_id] = 0;
            end

            channelwininfo[userinfo.channel_id] = channelwininfo[userinfo.channel_id] + wininfo.win_real_gold;
            channellib.on_game_get_gold(userinfo);
        end
    end
    for channel_id, win_lost_gold in pairs(channelwininfo) do
        if(win_lost_gold ~= 0) then
            channellib.update_win_lost_gold(channel_id, win_lost_gold); 
        end
    end
end

channellib.update_win_lost_gold = function(channel_id, gold)
    dblib.execute(string.format(channellib.SQL.update_win_lost_gold, channel_id, gold));
end

channellib.net_recv_get_rank_list = function(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local ntype = buf:readInt();
    local list = {};
    local sendFunc = function(buf)
        buf:writeString(channellib.cmd.net_recv_get_rank_list);
        buf:writeInt(ntype);
        buf:writeInt(#list);
        for k, v in pairs(list) do
            buf:writeInt(v.channel_id);
            buf:writeString(tostring(v.gold));
        end
    end
    
    local refresh_time = 0;
    local cache_ranklist;
    if(ntype == 0) then
        cache_ranklist = channellib.dayranklist;
        refresh_time = channellib.refresh_day_time;
    else
        cache_ranklist = channellib.totalranklist;
        refresh_time = channellib.refresh_total_time;
    end

    --读内存 
    if(refresh_time == 0 and refresh_time + channellib.refresh_interval < os.time()) then
        --刷新
        local sql;
        if(ntype == 0) then
            sql = channellib.SQL.get_day_rank_list;
            channellib.refresh_day_time = os.time();
        else
            sql = channellib.SQL.get_total_rank_list;
            channellib.refresh_total_time = os.time();
        end
        dblib.execute(sql, function(dt)
            if(dt and #dt > 0) then
               cache_ranklist = dt;

                if(ntype == 0) then
                    channellib.dayranklist = cache_ranklist;
                else
                    channellib.totalranklist = cache_ranklist;
                end
            end
            list =  cache_ranklist;
            channellib.net_send(sendFunc, userinfo);
        end);
    else
        --读内存
        list = cache_ranklist;
        channellib.net_send(sendFunc, userinfo);
    end
end

channellib.net_recv_get_channel_user_list = function(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local page = buf:readInt();
    local list = {};
    local totalpage = 1;
    local sendFunc = function(outBuf)
        outBuf:writeString(channellib.cmd.net_recv_get_channel_user_list);
        outBuf:writeInt(totalpage);
        for k, v in pairs(list) do
           local ntype = 0
            local deskinfo = {}
            if v.desk and v.desk > 0 then
                ntype = 1
                table.insert(deskinfo,desklist[v.desk].smallbet)
                table.insert(deskinfo,desklist[v.desk].largebet)
                table.insert(deskinfo,desklist[v.desk].channel_id or -1)
                table.insert(deskinfo,v.desk)
                table.insert(deskinfo,desklist[v.desk].desktype)
            end
            local vip_level = 0
            if viplib and viplib.get_vip_level(v) then
               vip_level = viplib.get_vip_level(v)
           end
            outBuf:writeInt(v.userId)
            outBuf:writeString(v.nick or "")
            outBuf:writeString(v.imgUrl or "")
            outBuf:writeByte(vip_level or 0)--是否为VIP
            outBuf:writeByte(ntype)--0大厅,1在牌桌
            outBuf:writeInt(v.channel_id or -1);
            outBuf:writeInt(v.channel_role or 0);
            outBuf:writeInt(v.sex);
            outBuf:writeInt(v.home_status or 0);--是否开通达人家园
            
            outBuf:writeByte(#deskinfo)
            for k,v in pairs(deskinfo) do
               outBuf:writeInt(v)
            end 
        end
        outBuf:writeInt(0);
    end

    local channel_id = userinfo.channel_id;
    if not channel_id then
        return;
    end

    if(channellist[channel_id]) then
        totalpage = math.ceil(channellist[channel_id].count/channellib.pagesize);
        if(page > totalpage) then
            page = totalpage;
        end
        local page_start = (page - 1) * channellib.pagesize;
        local page_end   =  page_start + channellib.pagesize;
        local i = 0;
        for k, v in pairs(channellist[channel_id].userlist) do
            if(i >= page_end) then
                break;
            end
    
            if(page_start <= i) then
                local userinfo = usermgr.GetUserById(k);
                if(userinfo) then
                    table.insert(list, userinfo);
                else
                    --清空用户
                    channellist[channel_id].count = channellist[channel_id].count - 1;
                    channellist[channel_id].userlist[k] = nil;
                    if(channellist[channel_id].count < 0) then
                        channellist[channel_id].count = 0;
                    end
                    totalpage = math.ceil(channellist[channel_id].count/channellib.pagesize);
                    i = i - 1;
                end
            end
            i = i + 1; 
        end
    end
    channellib.net_send(sendFunc, userinfo); 
end

channellib.net_send = function(sendFunc, userinfo)
    netlib.send(sendFunc, userinfo.ip, userinfo.port);
end

channellib.net_recv_get_channel_id = function(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local channel_id = -1;
    local sendFunc = function(buf)
        buf:writeString(channellib.cmd.net_recv_get_channel_id);
        buf:writeInt(userinfo.short_channel_id or -1);
    end
    channellib.net_send(sendFunc, userinfo);
end

channellib.net_recv_get_channel_user_pm = function(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo or not userinfo.channel_id or userinfo.channel_id < 1 then return end;

    local sendFunc = function(buf)
        buf:writeString(channellib.cmd.net_recv_get_channel_user_pm);
        buf:writeInt(#channellib.userranklist[userinfo.channel_id]);
        for k, v in pairs(channellib.userranklist[userinfo.channel_id]) do
            buf:writeInt(v.user_id);
            buf:writeInt(v.gold);
            buf:writeInt(v.channel_role);
            buf:writeInt(v.sex);
            buf:writeString(v.face);
            buf:writeString(v.nick_name);
            buf:writeInt(v.vip_level or 0);
        end
    end

    if(channellib.userranklist[userinfo.channel_id] == nil) then
        dblib.execute(string.format(channellib.SQL.get_channel_user_pm, userinfo.channel_id), function(dt)
            if(dt and #dt > 0) then
                channellib.userranklist[userinfo.channel_id] = dt;
                --获取vip信息
                local sqlplus = "";
                for k, v in pairs(dt) do
                    if(sqlplus ~= "") then
                        sqlplus = sqlplus .. ",";
                    end
                    sqlplus = sqlplus .. v.user_id;
                end

                if(sqlplus ~= "") then
                    sqlplus = channellib.SQL.get_user_vip_info.."("..sqlplus..");";
                    dblib.execute(sqlplus, function(dt)
                        if(dt and #dt > 0) then
                            local vipinfo = {};
                            for k, v in pairs(dt) do
                                vipinfo[v.user_id] = v.vip_level;
                            end

                            for k, v in pairs(channellib.userranklist[userinfo.channel_id]) do
                                if(vipinfo[v.user_id]) then
                                    v.vip_level = vipinfo[v.user_id];
                                end
                            end
                        end
                        netlib.send(sendFunc, userinfo.ip, userinfo.port);
                    end);
                    return
                end
            else
                channellib.userranklist[userinfo.channel_id] = {}; 
            end
            netlib.send(sendFunc, userinfo.ip, userinfo.port);
        end);
    else
        netlib.send(sendFunc, userinfo.ip, userinfo.port);
    end
end


--更新userinfo里的short_channel_id字段
channellib.update_user_shortid = function(user_info)
      if (user_info.channel_id == -1) then
          user_info.short_channel_id = -1
          return
      end
      local sql="select short_num from channel_info where channel_id=%d"
	  sql=string.format(sql,user_info.channel_id)
      dblib.execute(sql,function(dt)
	        if(dt and #dt > 0) then
	  			user_info.short_channel_id=dt[1].short_num   
	  		else
	      		local url = "http://222.186.49.38/check_sid_asid?req_type=asid&req_value=%d"
	     		 url=string.format(url,user_info.channel_id)
	      		 dblib.dourl(url, function(short_num)  
	      		 if(short_num==nil or short_num=="")then return end
	      		 short_num=split(short_num,"<")[1]
	      		 if(short_num==nil or short_num=="" or string.len(short_num)<2)then return end
	      		 
	      		 user_info.short_channel_id=short_num  or -1
	      		 if(user_info.short_channel_id~=-1)then
	      		 	sql="INSERT IGNORE INTO channel_info(channel_id,short_num) VALUE(%d,%d);commit;" 
	      		 	sql=string.format(sql,user_info.channel_id,short_num)
	      		 	dblib.execute(sql)
	      		 end
	      end)
	      end
	    end)   
end

----------------------------------------协议------------------------------------------------
--命令列表
cmdHandler =
{
    [channellib.cmd.net_recv_get_rank_list] = channellib.net_recv_get_rank_list, --获取频道事例排行
    [channellib.cmd.net_recv_get_channel_user_list] = channellib.net_recv_get_channel_user_list,--获取频道在线用户
    [channellib.cmd.net_recv_get_channel_id] = channellib.net_recv_get_channel_id,--获取频道id
    [channellib.cmd.net_recv_get_channel_user_pm] = channellib.net_recv_get_channel_user_pm,
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
	cmdHandler_addons[k] = v
end


