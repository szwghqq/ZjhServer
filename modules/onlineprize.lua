TraceError("init onlineprize....")

if not onlineprizelib then
	onlineprizelib = _S
	{
        CheckeDateValid            = NULL_FUNC,			--时间校验
        InitUserGameTimeInfo       = NULL_FUNC,			--初始化挂机者信息
        onGameOver                 = NULL_FUNC,			--累加玩家游戏时间
        OnRecvCheckDateValid       = NULL_FUNC,			--收到客户端查询活动是否在进行中 
        OnRecvQueryGameTimeInfo    = NULL_FUNC,	        --收到客户端查询游戏时间
        OnRecvQueryPrize           = NULL_FUNC,			--收到客户端请求领奖
        OnSendGameTimeInfo         = NULL_FUNC,			--发送游戏时间信息到客户端
        OnSendGivePrize            = NULL_FUNC,			--发送领奖结果到客户端
        get_prizerate              = NULL_FUNC,         --获取每分钟奖励多少筹码数额
        clear_lastdate             = NULL_FUNC,         --清空昨天数据
        get_addgold_by_time        = NULL_FUNC,         --根据玩牌时间，获取要赠送的筹码数额
        get_is_step                = NULL_FUNC,         --是否是阶段挂机累计

        HIGH_LEVEL                 = -100,              --赠送筹码最高阶段时的标志

        --每分钟的奖励，参考get_prizerate
        --[[
        prizerate = 28,   --大于0时，表示挂机活动每分钟按照这个固定的数额赠送筹码
        ary_time      = {},    --时间间隔（单位：分钟）
        ary_prizerate = {},    --对应时间间隔送的筹码数额
        ]]--

        prizerate = -1,     --小于等于0时，表示挂机活动按阶段赠送筹码
        ary_time      = {0,  60, 120, 180, 360},    --时间间隔（单位：分钟）
        ary_prizerate = {10, 20, 30,  50,  100},    --对应时间间隔送的筹码数额
        statime = "2012-05-31 00:00:00",  --活动开始时间
        endtime = "2099-02-28 00:00:00",  --活动结束时间
        exttime = "2099-02-29 00:00:00",  --只能领奖时间
	}
end
--判断时间的合法性,0不合法，1只能领奖，2能领奖和累积时间
onlineprizelib.CheckeDateValid = function()
	local statime = timelib.db_to_lua_time(onlineprizelib.statime);
	local endtime = timelib.db_to_lua_time(onlineprizelib.endtime);
	local exttime = timelib.db_to_lua_time(onlineprizelib.exttime);
	local sys_time = os.time();
	--可以领奖和增加游戏时间
	if(sys_time >= statime and sys_time <= endtime) then
        return 2;
	end
	--只能领奖
	if(sys_time > endtime and sys_time <= exttime) then
        return 1;
	end
	--活动时间过去了
	return 0;
end

--是否是阶段挂机累计：0，不是；1，是
onlineprizelib.get_is_step = function()
    if (onlineprizelib.prizerate > 0) then
        return 0
    end
    return 1
end

--获取每分钟奖励多少筹码数额，返回：
--[[
    1) 当前奖励的筹码数额
    2) 下一阶段奖励的筹码数额
    3) 到达一下还需要的时间（分钟）
--]]
onlineprizelib.get_prizerate = function(total_time)
    --固定数额赠送筹码
    if (onlineprizelib.get_is_step() == 0) then
        return onlineprizelib.prizerate, onlineprizelib.HIGH_LEVEL, 0
    end
    
    
    local ary_time = onlineprizelib.ary_time
    local ary_prizerate = onlineprizelib.ary_prizerate

    local prizerate = ary_prizerate[1]              --分每钟送的筹码数量
    local next_prizerate = ary_prizerate[2]         --下一级分每钟送的筹码数量
    local need_time = ary_time[2] + 1               --达到下一个阶段所需要的时间
    
    for k, v in pairs(ary_time) do
        if (total_time > v) then
            prizerate = ary_prizerate[k]
            --如果k+1超出了范围，表示达到赠送筹码的最高阶段
            next_prizerate = ary_prizerate[k+1] or onlineprizelib.HIGH_LEVEL 
            --达到下一个阶段所需要的时间
            if (k == #ary_time) then
    		    need_time = 0   --已经达到最高阶段了
    	    else
    		    need_time = ary_time[k+1] - total_time + 1
    	    end
        end
    end
   
    --TraceError("prizerate:"..prizerate.."  next_prizerate:"..next_prizerate.."  need_time:"..need_time)
    return prizerate, next_prizerate, need_time
end

--根据玩牌时间（单位：分钟），获取要赠送的筹码数额
onlineprizelib.get_addgold_by_time = function(new_time)
    --TraceError("get_addgold_by_time -> new_time:"..new_time)
    if(onlineprizelib.get_is_step() == 0) then return 0 end

    local ary_time = onlineprizelib.ary_time
    local ary_prizerate = onlineprizelib.ary_prizerate
    

    --拿到时间段的下标
	local index = 1
    for k, v in pairs(ary_time) do
		if(new_time > v) then
			index = k			
		end
	end	

	local addchouma = 0
    --根据时间下标累计每个时间段所赠送的筹码数额
	for i = 1, index do
		if(i-1 > 0) then
			addchouma = addchouma + (ary_time[i] - ary_time[i-1]) * ary_prizerate[i-1]
		end
    end
    --加上剩余的时间段所赠送的筹码数额
	addchouma = addchouma + (new_time - ary_time[index]) * ary_prizerate[index]

	return addchouma
end

--清空昨天数据，result = 0，没清空；1，清空；2，异常
onlineprizelib.clear_lastdate = function(userinfo)
    local result = 0

    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    local today_add = split(userinfo.gametimeinfo["today_add"],"|");
    local dbtoday = tostring(today_add[1]) or "";
    local todayAdd = tonumber(today_add[2]) or 0;
    --TraceError("dbtoday:"..dbtoday.." sys_today:"..sys_today)
    if(dbtoday ~= sys_today)then
        dbtoday = sys_today
        todayAdd = 0
        userinfo.gametimeinfo["today_add"] = format("%s|%d", dbtoday, todayAdd); 
        dblib.cache_set("user_gametime_info", {today_add=userinfo.gametimeinfo["today_add"]}, "user_id", userinfo.userId);

        result = 1
    end

    --异常检查，一天不能超过60 * 60 * 24秒
    local dayMax = 86400; --60 * 60 * 24 = 86400
    if(todayAdd >= dayMax)then
        TraceError(format("领奖出意外啦..todayAdd=[%d],dayMax=[%d]", todayAdd, dayMax));
        result = 2
    end

    return result
end

--初始化玩家挂机信息
onlineprizelib.InitUserGameTimeInfo = function(userinfo, onResult)
    --TraceError("onlineprizelib.InitGameTimeInfo")
    --初始化个人挂机信息
    if onlineprizelib.CheckeDateValid() <= 0 then
        return;
    end

    if not userinfo then return end;
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    local sqltemplet = "insert ignore into user_gametime_info (`user_id`, `today_add`) values(%d, '%s'); commit; ";
    local sql = format(sqltemplet, userinfo.userId, sys_today.."|".."0");
    dblib.execute(sql,
        function(dt1)
            dblib.cache_get("user_gametime_info", "*", "user_id", userinfo.userId,
                function(dt)
                    if not dt or #dt <= 0 then return end;
                    userinfo.gametimeinfo = {};
                    userinfo.gametimeinfo["total_time"] = dt[1]["total_time"];
                    userinfo.gametimeinfo["total_gold"] = dt[1]["total_gold"];
                    userinfo.gametimeinfo["new_time"] = dt[1]["new_time"];
                    userinfo.gametimeinfo["today_add"] = dt[1]["today_add"];
                    userinfo.gametimeinfo["last_time"] = dt[1]["last_time"] or "NULL";
                    userinfo.gametimeinfo["last_give"] = dt[1]["last_give"];
                    userinfo.gametimeinfo["already_gold"] = dt[1]["already_gold"] or 0;
                    --检查，是否清空数据
                    onlineprizelib.clear_lastdate(userinfo)

                    if(onResult ~= nil) then
                        xpcall(function() onResult() end,throw)
                    end
                end
            );
        end
    );
end

--增加玩家的游戏时间
onlineprizelib.onGameOver = function(in_userinfo, in_addtime)
    --TraceError("onlineprizelib.onGameOver")
     
    --检查时间合法性
    if onlineprizelib.CheckeDateValid() ~= 2 then
        return;
    end
	
	  
    local userinfo = in_userinfo;
    local addtime = tonumber(in_addtime) or 0;
    
    if not userinfo then return end;
    
    local gametimeinfo = userinfo.gametimeinfo;
    
    if not gametimeinfo then return end;
    
    --比赛场不加挂机时间
    local deskinfo=desklist[in_userinfo.desk]
    if(deskinfo~=nil and (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament)) then
    	--TraceError("比赛场不加挂机时间");
    	return;
	end
    
    if addtime <= 0 then
    	TraceError(format("开什么玩笑?addtime=[%d]", addtime));
    	return;
    end

    --检查，是否清空数据
    local result = onlineprizelib.clear_lastdate(userinfo)
    if (result == 2) then return end    --异常情况
    
    --检查爵位信息
	  if wing_lib and wing_lib.check_online_prize(userinfo) == 0 then
	     return 
	  end
	  
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    local today_add = split(userinfo.gametimeinfo["today_add"],"|");
    local dbtoday = tostring(today_add[1]) or "";
    local todayAdd = tonumber(today_add[2]) or 0;
    local last_gold = onlineprizelib.get_addgold_by_time(math.floor(todayAdd/60));

    todayAdd = todayAdd + addtime;
    gametimeinfo["today_add"] = format("%s|%d", dbtoday, todayAdd); 
    gametimeinfo["total_time"] = gametimeinfo["total_time"] + addtime;
    gametimeinfo["new_time"] = gametimeinfo["new_time"] + addtime;
    
    if (onlineprizelib.get_is_step() == 0) then
        --如果是领取固定筹码，则按照new_time计算玩家获得的筹码数额
        local new_time_minute = math.floor(gametimeinfo["new_time"] / 60);
        if new_time_minute <= 0 then
        	--TraceError(format("没有游戏时间啊？,new_time_minute=[%d]", new_time_minute));
        	return;
        end
        gametimeinfo["total_gold"] = new_time_minute * onlineprizelib.prizerate
    else
        --这一局所得的筹码
        local now_getgold = onlineprizelib.get_addgold_by_time(math.floor(todayAdd/60)) - last_gold;
        --累计总的筹码
        gametimeinfo["total_gold"] = gametimeinfo["total_gold"] + now_getgold;
    end

    
    dblib.cache_set("user_gametime_info", {total_gold=gametimeinfo["total_gold"]}, "user_id", userinfo.userId);
    dblib.cache_set("user_gametime_info", {today_add=gametimeinfo["today_add"]}, "user_id", userinfo.userId);
    dblib.cache_set("user_gametime_info", {total_time=gametimeinfo["total_time"]}, "user_id", userinfo.userId);
    dblib.cache_set("user_gametime_info", {new_time=gametimeinfo["new_time"]}, "user_id", userinfo.userId);
end

--收到客户端查询活动是否在进行中
onlineprizelib.OnRecvCheckDateValid = function(buf)
    --TraceError("onlineprizelib.OnRecvCheckDateValid")
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local dateflag = onlineprizelib.CheckeDateValid();

    if(userinfo.channel_id ~= nil and userinfo.channel_id > 0) then
        dateflag = 0;
    end

    netlib.send(function(buf)
        buf:writeString("ONPDATE");
        buf:writeInt(dateflag);--日期状态，0无效日期，1只能领奖啦，2正常活动日期
    end,userinfo.ip,userinfo.port);

    --初始化个人挂机信息,只活动期间执行
    if dateflag > 0 then
        onlineprizelib.InitUserGameTimeInfo(userinfo, nil);
    end
end

--收到玩家查询自己游戏时间
onlineprizelib.OnRecvQueryGameTimeInfo = function(buf)
    --TraceError("onlineprizelib.OnRecvQueryGameTimeInfo")

    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;

    --检查时间合法性
    local msgtype = userinfo.desk and 1 or 0; --1表示是游戏里处理的协议,0是大厅
    if onlineprizelib.CheckeDateValid() <= 0 then
        --local msg = format("对不起，活动还没开始或者已经结束!");
        local msg = tex_lan.get_msg(userinfo, "onlineprize_msg_1");
        OnSendServerMessage(userinfo, msgtype, _U(msg));
        return;
    end

    if(not userinfo.gametimeinfo)then
        local onInitOk = function()
            onlineprizelib.OnSendGameTimeInfo(userinfo);
        end
	    onlineprizelib.InitUserGameTimeInfo(userinfo, onInitOk);
    else
        onlineprizelib.clear_lastdate(userinfo)
	  	onlineprizelib.OnSendGameTimeInfo(userinfo);
    end
end

--发送游戏时间信息到客户端
onlineprizelib.OnSendGameTimeInfo = function(userinfo)
    if not userinfo then return end;

    local gametimeinfo = userinfo.gametimeinfo;
    if not gametimeinfo then return end;
    
    local dateflag = onlineprizelib.CheckeDateValid();
    local addgold = gametimeinfo["total_gold"] - gametimeinfo["already_gold"]
    local new_time = gametimeinfo["new_time"] or 0;
    if addgold < 0 then
    	TraceError(format("发送游戏时间信息到客户端。new_time=[%d], addgold=[%d]", gametimeinfo["new_time"], addgold));
    	addgold = 0;
    end

    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    local today_add = split(userinfo.gametimeinfo["today_add"],"|");
    local todayAdd = tonumber(today_add[2]) or 0;
    local curr_prizerate, next_prizerate, need_time = onlineprizelib.get_prizerate(math.floor(todayAdd/60))

    local already_getgold_time = gametimeinfo["total_time"] - gametimeinfo["new_time"] 
    
    local n_type = 1
    if wing_lib then
      n_type = wing_lib.get_online_info(userinfo)
    end
    netlib.send(function(buf)
        buf:writeString("ONPTMIF");
        buf:writeInt(already_getgold_time > 0 and already_getgold_time or 0);
        buf:writeInt(gametimeinfo["already_gold"] or 0);
        buf:writeInt(new_time);
        buf:writeInt(addgold);
        buf:writeString(gametimeinfo["last_time"] or "NULL");
        buf:writeInt(gametimeinfo["last_give"]);
        buf:writeInt(curr_prizerate or 0);
        buf:writeInt(next_prizerate or 0);
        buf:writeInt(need_time or 0);
        buf:writeInt(dateflag);--日期状态，0无效日期，1只能领奖啦，2正常活动日期
        buf:writeByte(n_type);--1没满，0满，-1是爵位等级不够
    end,userinfo.ip,userinfo.port);
end

--收到玩家请求领奖
onlineprizelib.OnRecvQueryPrize = function(buf)
    --TraceError("onlineprizelib.OnRecvQueryPrize")
    local datefalg = onlineprizelib.CheckeDateValid();
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local msgtype = userinfo.desk and 1 or 0; --1表示是游戏里处理的协议,0是大厅

    --检查时间合法性
    if datefalg <= 0 then
        --local msg = format("领取失败，活动还没开始或者已经结束!");
        local msg = tex_lan.get_msg(userinfo, "onlineprize_msg_2");
        OnSendServerMessage(userinfo, msgtype, _U(msg));
        return;
    end
    
    local gametimeinfo = userinfo.gametimeinfo;    
    if not gametimeinfo then return end;

    local curtime = os.clock() * 1000;
    if(gametimeinfo.lastqueryprize and curtime - gametimeinfo.lastqueryprize < 1000) then
        --TraceError(format("点得太快啦..:%d ms", curtime - gametimeinfo.lastquery));
        return;
    end

    gametimeinfo.lastqueryprize = curtime;
    
    local new_time_minute = math.floor(gametimeinfo["new_time"] / 60);
    if new_time_minute <= 0 then
    	--TraceError(format("没有游戏时间领毛啊,new_time_minute=[%d]", new_time_minute));
        --local msg = format("领取失败，您的游戏时间不足!ret=-1");
        local msg = tex_lan.get_msg(userinfo, "onlineprize_msg_3");
        OnSendServerMessage(userinfo, msgtype, _U(msg));
    	return;
    end

    --检查，是否清空数据
    local result = onlineprizelib.clear_lastdate(userinfo)
    --异常情况
    if (result == 2) then 
        --local msg = format("领取失败，您的游戏时间不足!ret=-2");
        local msg = tex_lan.get_msg(userinfo, "onlineprize_msg_4");
        OnSendServerMessage(userinfo, msgtype, _U(msg));
        return 
    end
    
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    local today_add = split(userinfo.gametimeinfo["today_add"],"|");
    local todayAdd = tonumber(today_add[2]) or 0;
    local curr_prizerate, next_prizerate, need_time = onlineprizelib.get_prizerate(math.floor(todayAdd/60))

    --local addgold = curr_prizerate * new_time_minute;
    local addgold = gametimeinfo["total_gold"] - gametimeinfo["already_gold"]
    --TraceError("addgold:"..addgold.."  already_gold:"..gametimeinfo["already_gold"])
    if addgold <= 0 then
        TraceError(format("不可能的，一定有问题。addgold=[%d]", addgold));
        --local msg = format("领取失败，您的游戏时间不足!ret=-3");
        local msg = tex_lan.get_msg(userinfo, "onlineprize_msg_5");
        OnSendServerMessage(userinfo, msgtype, _U(msg));
        return;
    end
    
    --gametimeinfo["total_gold"] = gametimeinfo["total_gold"] + addgold;
    --dblib.cache_set("user_gametime_info", {total_gold=gametimeinfo["total_gold"]}, "user_id", userinfo.userId);
    gametimeinfo["already_gold"] = gametimeinfo["total_gold"];  --更新 已经领的筹码
    dblib.cache_set("user_gametime_info", {already_gold=gametimeinfo["already_gold"]}, "user_id", userinfo.userId);
    gametimeinfo["new_time"] = gametimeinfo["new_time"] - new_time_minute * 60;
    dblib.cache_set("user_gametime_info", {new_time=gametimeinfo["new_time"]}, "user_id", userinfo.userId);
    --记录领奖日志
    local logsql = "insert ignore into log_gametime_pay (`user_id`,`sys_time`,`user_level`,`befor_gold`,`game_time`,`give_gold`) values(%d, now(), %d, %d, %d, %d); commit;";
    logsql = format(logsql, userinfo.userId, usermgr.getlevel(userinfo), userinfo.gamescore, new_time_minute * 60, addgold);
    dblib.execute(logsql);
    --加筹码
    usermgr.addgold(userinfo.userId, addgold, 0, g_GoldType.onlineprize or 1027, -1);
    --发送领奖结果
    onlineprizelib.OnSendGivePrize(userinfo, new_time_minute * 60, addgold);
    
    --刷新客户端的游戏时间显示
    onlineprizelib.OnSendGameTimeInfo(userinfo);
end

--发送领奖结果到客户端
onlineprizelib.OnSendGivePrize = function(userinfo, newtime, addgold)
    if not userinfo then return end;
    if not newtime then return end;
    if not addgold then return end;

    local dateflag = onlineprizelib.CheckeDateValid(); 
    netlib.send(function(buf)
        buf:writeString("ONPGTPR");
        buf:writeInt(newtime);  --本次使用的时间
        buf:writeInt(addgold);	--获得筹码数
        buf:writeInt(dateflag);--日期状态，0无效日期，1只能领奖啦，2正常活动日期
    end,userinfo.ip,userinfo.port);
end

--命令列表
cmdHandler = 
{
    ["ONPDATE"] = onlineprizelib.OnRecvCheckDateValid, --收到客户端查询活动是否在进行中
    ["ONPTMIF"] = onlineprizelib.OnRecvQueryGameTimeInfo, --收到客户端查询游戏时间
    ["ONPGTPR"] = onlineprizelib.OnRecvQueryPrize, --收到客户端请求领奖
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
