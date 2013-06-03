TraceError("init riddle_forgc....")

if not gcriddlelib then
	gcriddlelib = _S
	{
        checker_datevalid           = NULL_FUNC,			--时间校验
        ontimecheck                 = NULL_FUNC,			--自动计时刷新
        sendToGameServer            = NULL_FUNC,			--发送消息到单个gameserver
        sendToAllGameServer         = NULL_FUNC,			--发送消息到全部gameserver
        OnRecvQueryRiddle           = NULL_FUNC,			--请求获得最新的谜语信息
		OnRecvAnswerRiddle			= NULL_FUNC,			--请求校验谜语的正确答案
        SendRiddleToGameServer      = NULL_FUNC,			--发送一个谜题到gameserver
		riddlelist = {},--谜语列表
        curr_riddle = {},
        --从数据库中读取谜语信息
        timelib.createplan(function()
            dblib.execute("select * from configure_riddles_info order by id asc; ",
                function(dt)
                    if not dt or #dt <= 0 then return end;
                    local riddlelist = gcriddlelib.riddlelist;
                    for i = 1, #dt do
                        local riddle_item = {};
                        riddle_item["id"] = dt[i]["id"];
                        riddle_item["riddles_name"] = dt[i]["riddles_name"];
                        riddle_item["riddles_answer"] = dt[i]["riddles_answer"];
                        riddle_item["is_over"] = dt[i]["is_over"];
                        riddle_item["sys_time"] = dt[i]["sys_time"];
                        riddle_item["user_id"] = dt[i]["user_id"];
                        riddle_item["user_nick"] = dt[i]["user_nick"];
                        if(riddle_item["is_over"] == 0)then
                        	riddle_item["left_time"] = 600;  --TODO：600秒上线
                        else
                        	riddle_item["left_time"] = 0;
                        end
                        table.insert(riddlelist, riddle_item);
                    end
                    table.disarrange(riddlelist);  --打乱灯谜次序
                    for i = 1, #riddlelist do
                        if(riddlelist[i]["is_over"] == 0) then
                            gcriddlelib.curr_riddle = riddlelist[i];
                            break;
                        end
                    end
                end
            )
        end,
    3);
	}
end
--判断时间的合法性
gcriddlelib.checker_datevalid = function()
	local starttime = os.time{year = 2011, month = 2, day = 17,hour = 0};
	local endtime = os.time{year = 2011, month = 2, day = 19,hour = 0};
	local sys_time = os.time()
    if(sys_time < starttime or sys_time > endtime) then
        return false
	end
    return true
end
--定时刷新谜语
gcriddlelib.ontimecheck = function()
    --检查时间合法性
    if not gcriddlelib.checker_datevalid() then
        return
    end
    local riddle_item = gcriddlelib.curr_riddle;
    if not riddle_item or not riddle_item["left_time"] then return end;

    --递减答题时间
    riddle_item["left_time"] = riddle_item["left_time"] - 1;
    if(riddle_item["left_time"] > 0) then return end;

    if(riddle_item["is_over"] == 0) then
        --设置谜语过期
        riddle_item["is_over"] = 1;
        riddle_item["sys_time"] = os.date("%Y-%m-%d %X", os.time());
        --记录数据库
        local sql = "update configure_riddles_info set is_over = %d, sys_time = '%s' where is_over = 0 and id = %d; commit;";
        sql = format(sql, 1, riddle_item["sys_time"], riddle_item["id"]);
        dblib.execute(sql);
        --通知所有的服务器谜语过期了
        for game, list in pairs(gamegroups) do
            for id,server in pairs(list) do
                gcriddlelib.SendRiddleToGameServer(tostring(game), tostring(id), riddle_item);
            end
        end
    end

    --刷新到下一题
    gcriddlelib.curr_riddle = nil;
    local riddlelist = gcriddlelib.riddlelist;
    for i = 1, #riddlelist do
        if(riddlelist[i]["is_over"] == 0) then
            gcriddlelib.curr_riddle = riddlelist[i];
            break;
        end
    end

    --通知所有的服务器谜题刷新了
    if(gcriddlelib.curr_riddle ~= nil)then
        for game, list in pairs(gamegroups) do
            for id,server in pairs(list) do
                gcriddlelib.SendRiddleToGameServer(tostring(game), tostring(id), gcriddlelib.curr_riddle);
            end
        end
    end
end

--发消息给指定的游戏服务器
gcriddlelib.sendToGameServer = function(func_send, szGameName, szGameSvrId)
    cmdHandler["SENDTOGAMESERVER"] = nil;
    cmdHandler["SENDTOGAMESERVER"] = func_send;
    local tGameSvrInfo = GetGameSvrInfoById(szGameName, szGameSvrId);
    if (tGameSvrInfo ~= nil) then
        tools.SendBufToGameSvr("SENDTOGAMESERVER", szGameSvrId, tGameSvrInfo.szSvrIp, tGameSvrInfo.nSvrPort);
    end
end

--发消息给所有游戏服务器
gcriddlelib.sendToAllGameServer = function(func_send)
    for game, list in pairs(gamegroups) do
        for id,server in pairs(list) do
            gcriddlelib.sendToGameServer(func_send, tostring(game), tostring(id));
        end
    end
end

--收到gameserver发过来的验证谜语结果的信息
gcriddlelib.OnRecvAnswerRiddle = function(szGameName, szGameSvrId, buf)
    --TraceError("OnRecvAnswerRiddle")
    --检查时间合法性
    if not gcriddlelib.checker_datevalid() then
        return
    end
	local tGameSvrInfo = GetGameSvrInfoById(szGameName, szGameSvrId);
    if not tGameSvrInfo then return end;
	local nId = buf:readInt();  --题目ID
	local nUserId = buf:readInt();--玩家ID
	local sUserNick = buf:readString();--玩家昵称
	
	--找到对应的谜语
	local riddle_item = nil;
    local riddlelist = gcriddlelib.riddlelist;
	for k,v in pairs(riddlelist) do
		if(v.id == nId) then
			riddle_item = v;
			break;
		end
    end

    --没有找到此谜语
    if(not riddle_item)then return end;

    local retcode = -1;
    if(riddle_item["is_over"] == 0) then
        retcode = 1;
    elseif(riddle_item["is_over"] == 1)then
        retcode = 2;
    elseif(riddle_item["is_over"] == 2)then
        retcode = 3;
    else
        TraceError("诡异的is_over="..tostring(riddle_item["is_over"]));
    end

	--返回结果
    gcriddlelib.sendToGameServer(function(buf)
            buf:writeString("RERIDAS");
            buf:writeInt(nUserId);   --玩家ID
            buf:writeInt(retcode);   --答题是否成功
            buf:writeInt(riddle_item["id"]);   --题目编号
            buf:writeInt(riddle_item["is_over"]);--题目状态
            if(riddle_item["is_over"] == 2)then  --有人先答对了
                buf:writeInt(riddle_item["user_id"]);
                buf:writeString(riddle_item["user_nick"]);
                buf:writeString(riddle_item["sys_time"]);
            end
        end, szGameName, szGameSvrId);

    --检查该谜语是否已过期或被猜出
	if(riddle_item["is_over"] ~= 0)then
        return;
    end

    --第一个给出正确答案的玩家
    riddle_item["is_over"] = 2;
    riddle_item["user_id"] = nUserId;
    riddle_item["user_nick"] = sUserNick;
    riddle_item["sys_time"] = os.date("%Y-%m-%d %X", os.time());
    --记录数据库
    local sql = "update configure_riddles_info set is_over = %d, user_id = %d, user_nick = '%s', sys_time = '%s' where id = %d; commit;";
    sql = format(sql, 2, nUserId, sUserNick, riddle_item["sys_time"], nId);
    dblib.execute(sql);

    --全区广播
    gcriddlelib.sendToAllGameServer(function(buf)
            buf:writeString("BCRIDOV");
            buf:writeInt(riddle_item["id"]);   --题目编号
            buf:writeInt(riddle_item["user_id"]);
            buf:writeString(riddle_item["user_nick"]);
            buf:writeString(riddle_item["sys_time"]);
        end);
end

--收到gameserver查询当前谜题
gcriddlelib.OnRecvQueryRiddle = function(szGameName, szGameSvrId, buf)
    --TraceError("OnRecvQueryRiddle")
    --检查时间合法性
    if not gcriddlelib.checker_datevalid() then
        return
    end
    local tGameSvrInfo = GetGameSvrInfoById(szGameName, szGameSvrId);
    if not tGameSvrInfo then return end;
    if not gcriddlelib.curr_riddle then return end;

    local riddle_item = gcriddlelib.curr_riddle;

	--返回结果
    gcriddlelib.SendRiddleToGameServer(szGameName, szGameSvrId, riddle_item);
end

--发送一个谜题到gameserver
gcriddlelib.SendRiddleToGameServer = function(szGameName, szGameSvrId, riddle_item)
    if (not riddle_item or not riddle_item["id"]) then return end;
    local tGameSvrInfo = GetGameSvrInfoById(szGameName, szGameSvrId);
    if not tGameSvrInfo then return end;

    gcriddlelib.sendToGameServer(function(buf)
            buf:writeString("RERIDDL");
            buf:writeInt(riddle_item["id"]);   --题目编号
            buf:writeInt(riddle_item["left_time"]);   --剩余答题时间
            buf:writeInt(riddle_item["is_over"]);--题目状态
            if(riddle_item["is_over"] == 2)then  --有人先答对了
                buf:writeInt(riddle_item["user_id"]);
                buf:writeString(riddle_item["user_nick"]);
                buf:writeString(riddle_item["sys_time"]);
            end
        end, szGameName, szGameSvrId)
end
--命令列表
cmdHandler = 
{
    ["RQRIDDL"] = gcriddlelib.OnRecvQueryRiddle,--请求正在答题的谜语ID
	["RQRIDAS"] = gcriddlelib.OnRecvAnswerRiddle,--请求验证谜语结果
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
