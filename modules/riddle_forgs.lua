TraceError("init riddle_forgs....")

if not gsriddlelib then
	gsriddlelib = _S
	{
        checker_datevalid           = NULL_FUNC,			--时间校验
        ontimecheck                 = NULL_FUNC,			--自动计时
        sendToGameCenter            = NULL_FUNC,			--发送消息到gamecenter
        OnRecvQueryTimeFromClient   = NULL_FUNC,			--收到客户端查询剩余时间
        OnRecvQueryRiddleFromClient = NULL_FUNC,			--收到客户端查询题目内容
        OnRecvAnswerFromClient	    = NULL_FUNC,			--收到客户端的答题结果
        OnSendAnswerResultToClient  = NULL_FUNC,			--发送答题结果到客户端
        OnRecvRiddleFromGC          = NULL_FUNC,			--收到最新的谜语信息
		OnRecvAnswerRiddleFromGC	= NULL_FUNC,			--收到校验结果
        OnRecvRiddleOverFromGC      = NULL_FUNC,			--收到广播有人答对了
		riddlelist = {},--谜语列表
        curr_riddle = {},
        prize_gold = 5000,  --答对奖励
        --从数据库中读取谜语信息
        timelib.createplan(function()
            dblib.execute("select * from configure_riddles_info order by id asc; ",
                function(dt)
                    if not dt or #dt <= 0 then return end;
                    local riddlelist = gsriddlelib.riddlelist;
                    for i = 1, #dt do
                        local riddle_item = {};
                        riddle_item["id"] = dt[i]["id"];
                        riddle_item["riddles_name"] = dt[i]["riddles_name"];
                        riddle_item["riddles_answer"] = dt[i]["riddles_answer"];
                        riddle_item["is_over"] = dt[i]["is_over"];
                        riddle_item["sys_time"] = dt[i]["sys_time"];
                        riddle_item["user_id"] = dt[i]["user_id"];
                        riddle_item["user_nick"] = dt[i]["user_nick"];
                        riddle_item["left_time"] = 0;
                        table.insert(riddlelist, riddle_item);
                    end
                    --查询目前的谜语信息
                    gsriddlelib.sendToGameCenter(
                        function(buf)
                            buf:writeString("RQRIDDL");
                        end);
                end
            )
        end,
    3);
	}
end
--判断时间的合法性
gsriddlelib.checker_datevalid = function()
	local starttime = os.time{year = 2011, month = 2, day = 17,hour = 0};
	local endtime = os.time{year = 2011, month = 2, day = 19,hour = 0};
	local sys_time = os.time()
    if(sys_time < starttime or sys_time > endtime) then
        return false
	end
    return true
end
--自动递减题目的剩余时间
gsriddlelib.ontimecheck = function()
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local riddle_item = gsriddlelib.curr_riddle;
    if not riddle_item or not riddle_item["left_time"] then return end;

    --减少答题时间
    if(riddle_item["left_time"] >= 1) then
        riddle_item["left_time"] = riddle_item["left_time"] - 1;
    else
        --还有没完成的题目就要重新向gamecenter查询
        local riddlelist = gsriddlelib.riddlelist;
        for i = 1, #riddlelist do
            if(riddlelist[i]["is_over"] == 0) then  
                gsriddlelib.sendToGameCenter(
                    function(buf)
                        buf:writeString("RQRIDDL");
                    end);
                break;
            end
        end
    end
end

--发送消息到gamecenter
gsriddlelib.sendToGameCenter = function(func_send)
    cmdHandler["SENDTOGAMECENTER"] = nil;
    cmdHandler["SENDTOGAMECENTER"] = func_send;
    tools.SendBufToGameCenter(getRoomType(), "SENDTOGAMECENTER");
end

--收到gamecenter返回的当前谜题
gsriddlelib.OnRecvRiddleFromGC = function(buf)
    --TraceError("OnRecvRiddleFromGC")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local riddle_item = {};
    riddle_item["id"] = buf:readInt();
    riddle_item["left_time"] = buf:readInt();
    riddle_item["is_over"] = buf:readInt();
    if(riddle_item["is_over"] == 2)then  --有人先答对了
        riddle_item["user_id"] = buf:readInt();
        riddle_item["user_nick"] = buf:readString();
        riddle_item["sys_time"] = buf:readString();
    end

    gsriddlelib.curr_riddle = nil; --重设当前题目
    local riddlelist = gsriddlelib.riddlelist;
    for i = 1, #riddlelist do
        if(riddlelist[i]["id"] == riddle_item["id"]) then
            riddlelist[i]["left_time"] = riddle_item["left_time"];
            riddlelist[i]["is_over"] = riddle_item["is_over"];
            if(riddle_item["is_over"] == 2)then  --有人先答对了
                riddlelist[i]["user_id"] = riddle_item["user_id"];
                riddlelist[i]["user_nick"] = riddle_item["user_nick"];
                riddlelist[i]["sys_time"] = riddle_item["sys_time"];
            end
            gsriddlelib.curr_riddle = riddlelist[i];
            break;
        end
    end
end

--收到gamecenter发过来的验证结果
gsriddlelib.OnRecvAnswerRiddleFromGC = function(buf)
    --TraceError("OnRecvAnswerRiddleFromGC")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local userid = buf:readInt();
    local retcode = buf:readInt();  --1答题成功，2题目过期，3有人先答了
    local riddle_item = {};
    riddle_item["id"] = buf:readInt();
    riddle_item["is_over"] = buf:readInt();
    if(riddle_item["is_over"] == 2)then  --有人先答对了
        riddle_item["user_id"] = buf:readInt();
        riddle_item["user_nick"] = buf:readString();
        riddle_item["sys_time"] = buf:readString();
    end

    --刷新题目状态
    local riddlelist = gsriddlelib.riddlelist;
    for i = 1, #riddlelist do
        if(riddlelist[i]["id"] == riddle_item["id"]) then
            riddlelist[i]["is_over"] = riddle_item["is_over"];
            if(riddle_item["is_over"] == 2)then  --有人先答对了
                riddlelist[i]["user_id"] = riddle_item["user_id"];
                riddlelist[i]["user_nick"] = riddle_item["user_nick"];
                riddlelist[i]["sys_time"] = riddle_item["sys_time"];
            end
            break;
        end
    end

    local userinfo = usermgr.GetUserById(userid);
    if not userinfo then return end;  --必须在桌子里才可以答题
    --处理答题结果
    if(retcode == 1)then
        local addgold = gsriddlelib.prize_gold or 5000 --奖励1万筹码
        gsriddlelib.OnSendAnswerResultToClient(userinfo, 1, riddle_item, addgold);
        usermgr.addgold(userinfo.userId, addgold, 0, g_GoldType.riddleprize or 1026, -1);
    elseif(retcode == 2)then
        --通知玩家题目过期了
        gsriddlelib.OnSendAnswerResultToClient(userinfo, 2, riddle_item, 0);
    elseif(retcode == 3)then
        --通知玩家这题有人答过了
        gsriddlelib.OnSendAnswerResultToClient(userinfo, 3, riddle_item, 0);
    else
        TraceError("诡异的retcode="..tostring(riddle_item["retcode"]));
    end
end

--收到gamecenter广播有人答对了
gsriddlelib.OnRecvRiddleOverFromGC = function(buf)
    --TraceError("OnRecvRiddleOverFromGC")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local riddle_item = {};
    riddle_item["id"] = buf:readInt();
    riddle_item["user_id"] = buf:readInt();
    riddle_item["user_nick"] = buf:readString();
    riddle_item["sys_time"] = buf:readString();

    --刷新题目状态
    local riddlelist = gsriddlelib.riddlelist;
    for i = 1, #riddlelist do
        if(riddlelist[i]["id"] == riddle_item["id"]) then
            riddlelist[i]["is_over"] = 2;
            riddlelist[i]["user_id"] = riddle_item["user_id"];
            riddlelist[i]["user_nick"] = riddle_item["user_nick"];
            riddlelist[i]["sys_time"] = riddle_item["sys_time"];
            --广播答题结果,恭喜XXX第一个猜中灯谜，获得XX金币奖励。灯谜正确答案为"XX
            --BroadcastMsg(_U("恭喜 ")..riddle_item["user_nick"].._U(" 第一个猜中灯谜，获得 "..gsriddlelib.prize_gold.." 筹码奖励。灯谜正确答案为： ")..riddlelist[i]["riddles_answer"],0);
            BroadcastMsg(_U(tex_lan.get_msg(userinfo, "riddle_forgs_msg_1"))..riddle_item["user_nick"].._U(tex_lan.get_msg(userinfo, "riddle_forgs_msg_2")..gsriddlelib.prize_gold..tex_lan.get_msg(userinfo, "riddle_forgs_msg_3"))..riddlelist[i]["riddles_answer"],0);
            break;
        end
    end
end

--收到玩家查询题目内容
gsriddlelib.OnRecvQueryRiddleFromClient = function(buf)
    --TraceError("OnRecvQueryRiddleFromClient")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;

    local riddle_item = gsriddlelib.curr_riddle;
    if not riddle_item then return end;
    netlib.send(function(buf)
        buf:writeString("RIDINFO");
        buf:writeInt(riddle_item["id"]);
        buf:writeInt(riddle_item["left_time"] + 1);
        buf:writeString(riddle_item["riddles_name"]);
        buf:writeInt(riddle_item["is_over"]);
        if(riddle_item["is_over"] == 2)then  --有人先答对了
            buf:writeInt(riddle_item["user_id"]);
            buf:writeString(riddle_item["user_nick"] or "");
            buf:writeString(riddle_item["sys_time"] or "");
            buf:writeString(riddle_item["riddles_answer"]);
            buf:writeInt(gsriddlelib.prize_gold);
        end
    end,userinfo.ip,userinfo.port);
end

--收到玩家查询剩余时间
gsriddlelib.OnRecvQueryTimeFromClient = function(buf)
    --TraceError("OnRecvQueryTimeFromClient")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;

    local riddle_item = gsriddlelib.curr_riddle;
    if not riddle_item or not riddle_item["id"] then return end;
    netlib.send(function(buf)
        buf:writeString("RIDQETM");
        buf:writeInt(riddle_item["id"]);
        buf:writeInt(riddle_item["left_time"] + 1);
    end,userinfo.ip,userinfo.port);
end

--收到玩家答题
gsriddlelib.OnRecvAnswerFromClient = function(buf)
    --TraceError("OnRecvAnswerFromClient")
    --检查时间合法性
    if not gsriddlelib.checker_datevalid() then
        return
    end
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end; 

    --防止有人乱发数据包
    if(userinfo.lastanswer and os.time() - userinfo.lastanswer < 10)then
        --TraceError(format("玩家[%d]还需%d秒之后方可继续答题!", userinfo.userId, userinfo.lastanswer + 10 - os.time()));
        return;
    else
        userinfo.lastanswer = os.time();
    end

    local user_answer = buf:readString();
    local riddle_item = gsriddlelib.curr_riddle;
    if not riddle_item then return end;
    --TraceError(format("收到玩家[%d]的答案:%s,正确答案:%s", userinfo.userId, user_answer, riddle_item["riddles_answer"]));
    --TraceError(format("答案是否正确:%s", tostring(user_answer == riddle_item["riddles_answer"])));
    if(user_answer == riddle_item["riddles_answer"])then
        if(riddle_item["is_over"] == 0) then
            gsriddlelib.sendToGameCenter(
                        function(buf)
                            buf:writeString("RQRIDAS");
                            buf:writeInt(riddle_item["id"]);
                            buf:writeInt(userinfo.userId);
                            buf:writeString(userinfo.nick);
                        end);
        elseif(riddle_item["is_over"] == 1)then
            gsriddlelib.OnSendAnswerResultToClient(userinfo, 2, riddle_item, 0);
        elseif(riddle_item["is_over"] == 2)then
            gsriddlelib.OnSendAnswerResultToClient(userinfo, 3, riddle_item, 0);
        end
    else
        gsriddlelib.OnSendAnswerResultToClient(userinfo, 4, riddle_item, 0);
    end
end

--发送答题结果到客户端
--retcode:1答题成功，2题目过期了，3有人抢先了，4答错了，5其他错误
gsriddlelib.OnSendAnswerResultToClient = function(userinfo, retcode, riddle_item, addgold)
    if not userinfo then return end;

    local riddles_answer = "";
    if(riddle_item["is_over"] ~= 0) then
        riddles_answer = riddle_item["riddles_answer"];
    end
    netlib.send(function(buf)
        buf:writeString("RIDANSW");
        buf:writeInt(retcode);
        buf:writeInt(addgold);
        buf:writeInt(riddle_item["id"]);
        buf:writeInt(riddle_item["is_over"]);
        buf:writeInt(riddle_item["user_id"] or 0);
        buf:writeString(riddle_item["user_nick"] or "");
        buf:writeString(riddle_item["sys_time"] or "");
        buf:writeString(riddles_answer);
        buf:writeInt(addgold or 0);
    end,userinfo.ip,userinfo.port);
end

--命令列表
cmdHandler = 
{
    --gamecenter
    ["RERIDDL"] = gsriddlelib.OnRecvRiddleFromGC,--收到正在答题的谜语ID
	["RERIDAS"] = gsriddlelib.OnRecvAnswerRiddleFromGC,--收到验证谜语结果
    ["BCRIDOV"] = gsriddlelib.OnRecvRiddleOverFromGC,--收到有人答对题了

    --client
    ["RIDQETM"] = gsriddlelib.OnRecvQueryTimeFromClient, --收到玩家查询剩余时间
    ["RIDINFO"] = gsriddlelib.OnRecvQueryRiddleFromClient, --收到玩家查询题目内容
    ["RIDANSW"] = gsriddlelib.OnRecvAnswerFromClient, --收到玩家答题
    
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
