TraceError("init quest....")
--[[
questlib.ForceRefreshQuest()
--]]

if not questlib then 
    questlib =
    {
		ToQuestInfoString			= NULL_FUNC,		--序列化任务字符串
		LoadQuestInfo				= NULL_FUNC,		--反序列化任务字符串
    	GetUserQuestList 			= NULL_FUNC,		--得到用户已经接的任务信息
        DoPrizeRequest              = NULL_FUNC,        --收到领取任务奖励
        DoProcessUserEveryDayQuest  = NULL_FUNC,        --收到用户今日任务信息
        RefreshAllUserEDQuest       = NULL_FUNC,        --清空服务器上所有用户每日任务信息
        DoCheckUserQuest            = NULL_FUNC,        --检查用户任务完成度        
        AddEveryQuestList           = NULL_FUNC,        --添加今日日常任务
        GetEveryQuestList           = NULL_FUNC,        --得到今日日常任务列表   
        isToday                     = NULL_FUNC,        --是否为本日任务
        ClearUserEDQuest            = NULL_FUNC,        --清空用户每日任务信息
        AddUserEDQuest              = NULL_FUNC,        --给用户每日任务赋值
        InitUserEveryDayQuest       = NULL_FUNC,        --同步系统中日常任务信息到用户的日常任务列表
        AddAndFinishedProcess       = NULL_FUNC,        --任务条件累加器,完成判断器,累加到用户任务变量里
        GetQuestInfo                = NULL_FUNC,        --得到某任务详细信息
        GetDailyQuestList           = NULL_FUNC,        --获取每日任务
        GetRoomNanDuXiShu           = NULL_FUNC,        --得到房间的难度系数
        initquestfromdb             = NULL_FUNC,        --异步从数据库中读出任务相关信息
        OnTimeCheckQuest            = NULL_FUNC,        --刷新和通知的处理
        do_extra_nanduxishu         = NULL_FUNC,        --难度系数额外加成判定
        
        update_completed_quest      = NULL_FUNC,        --更新任务完成度的副本信息

		on_game_event				= NULL_FUNC,        --当收到来自采集器的数据时

        db_UpdateUserEDQuest        = NULL_FUNC,        --写入用户日常任务到数据库
        db_InitQuestList            = NULL_FUNC,        --初始化任务
        db_RefreshEveryDayQuest     = NULL_FUNC,        --刷新日常任务，并且写到数据库
        db_OnRecvToDayQuestList     = NULL_FUNC,        --收到今日日常任务信息
    
    	net_OnRecvEveryDayQuest		= NULL_FUNC,		--收到请求刷新日常任务
        net_OnRecvEDQuestPrize      = NULL_FUNC,        --收到领取任务奖励
        net_OnRecvQuestPhase        = NULL_FUNC,        --收到请求任务状态  
    
        net_OnSendEveryDayQuestInfo = NULL_FUNC,        --发送日常任务进度信息
        net_OnSendEDQuestPrizeOK    = NULL_FUNC,        --发送领取奖励成功
        net_OnBrocastEDQuestPrizeOK = NULL_FUNC,      --发送领取奖励成功(桌内广播）
        net_OnSendQuestPhase        = NULL_FUNC,        --发送任务类型，是新手任务还是日常任务
    
    
        --房间难度系数配置，已经在数据库的configure_quest_nanduxishu中进行配置，此处会被覆盖
        ROOM_NANDUXISHU = {
            [2]     = 1,        --2倍
            [100]   = 1.5,      --100倍 ...
            [2000]  = 2,
            [10000] = 3,
            [60000] = 4,
        },
    
        --每日日常任务存放表
        EveryDayQuestList = {},
    
    
        --任务类型
        QUEST_TYPE = 
        {
            ["EVERYDAY"] = 1,       --日常任务
            ["XXX"]      = 2,
        },
    
        --初始化任务类型
        questList = {},
    
        --任务完成类型，是累加还是一次完成
        QUEST_CONDITION_TYPE = 
        {
            ["SUM"] = 1,
            ["ONCE"] = 2,
            ["CONTINOUS"] = 3,    --连续的任务
        },
    
        --任务难易度
        DIFFICULTY = 
        {
            ["EASY"] = 1,
            ["NORMAL"] = 2,
            ["HARD"] = 3,
            ["FREEGIVE"] = 0,
            ["RAID"] = 4,   --团队任务
        },

        --每日必须有的日常任务列表
        EVERY_DAY_MUST_SHOW = {},
    
        --每日必须没有有的日常任务列表
        EVERY_DAY_NOT_SHOW = {},
    
        --必须成对出现的任务集合,例如：【倒反】 = 地主，表示倒反出现，地主任务必须出现
        EVERY_DAY_FACE_TO_FACE_CLASS = {},

        --必须不成对出现的
        EVERY_DAY_NOT_IN_TOGETHER = {},

		--任务选择个数配置
		quest_num_cfg = {},

        SQL = {
            --得到日常任务信息
            getEveryDayQuestInfo = "insert IGNORE into quest_daily_info(game_name)VALUES(%s);select quest_Id_list from quest_daily_info where game_name = %s",
            --写入日常任务信息
            updateEveryDayQuestInfo = "update quest_daily_info set quest_id_list = %s where game_name = %s",
            --插入日常任务日志
            insertLogEveryDay = "insert into log_quest_every_day (user_id,game_name,sys_time,xishu,quest_id,prizetype,prizevalue,remark) values(%d, %s, %s, %d, %d, '%s', %d, '%s')",
        }
    }

     --异步从数据库中读出任务相关信息，
    --填充：questlib.EVERY_DAY_MUST_SHOW， 
    --		questlib.EVERY_DAY_NOT_IN_TOGETHER 
    --		questlib.EVERY_DAY_FACE_TO_FACE_CLASS 
    --		questlib.questList
    --完成后： dispatchEvent "questlib_init_complete"
    local initquestfromdb = function()
        timelib.createplan(function()
			--加载难度系数表
			local loadquestnanduxishu = function()
				dblib.execute(string.format("select * from configure_quest_nanduxishu where game_name= %s ",dblib.tosqlstr(gamepkg.name)) , function(dt)
                    questlib.ROOM_NANDUXISHU = {}
                    for k, v in pairs(dt) do
						local peilv = v["peilv"]
						local nanduxishu = tonumber(v["nanduxishu"]) or TraceError("nanduxishu not number in peilv " .. tostring(peilv))
						questlib.ROOM_NANDUXISHU[peilv] = nanduxishu
                    end
                    eventmgr:dispatchEvent(Event("questlib_init_complete", 1))
                    trace(questlib)
                end)
			end

			--加载任务数表
            local totalquestcount = 0
			local loadquestcount = function()
				dblib.execute(string.format("select * from configure_quest_count where game_name= %s ",dblib.tosqlstr(gamepkg.name)) , function(dt)
                    questlib.quest_num_cfg	= {}
                    for k, v in pairs(dt) do
						local type_str = v["prize_calc_type_str"]
						local type_count = v["count"]
                        totalquestcount = totalquestcount + type_count  --任务总数量
						questlib.quest_num_cfg[questlib.DIFFICULTY[type_str]] = type_count
                    end
					loadquestnanduxishu()

                    --设置任务总数量
                    set_room_totalquestcount(totalquestcount)
                end)
            end

            --加载任务依赖表
            local loadquestclass = function()
                dblib.execute(string.format("select * from configure_quest_relation where game_name= %s ",dblib.tosqlstr(gamepkg.name)) , function(dt)
                    questlib.EVERY_DAY_FACE_TO_FACE_CLASS 	= {}
                    questlib.EVERY_DAY_NOT_IN_TOGETHER 		= {}
                    for k, v in pairs(dt) do
                        if v["relation_type"] 		== 1 then --互吸
                            questlib.EVERY_DAY_FACE_TO_FACE_CLASS[v["class1"]] = v["class2"]
                        elseif v["relation_type"] 	== 2 then --互斥
                            questlib.EVERY_DAY_NOT_IN_TOGETHER[v["class1"]] = v["class2"]
                        end
                    end
					loadquestcount()
                end)
            end
    
            --分页加载所有任务列表questList
            local alldatareached = function(dt)
                TraceError("alldatareached")
                local everydaymustshow = {}
                local questlist = {}
                questlist[questlib.QUEST_TYPE.EVERYDAY] = {}		--questlib.QUEST_TYPE.EVERYDAY
                for k, v in pairs(dt) do
                    local data = {}
                    data.difficulty =  v["prize_calc_type"] 		--questlib.DIFFICULTY.*
                    data.prize = {}
                    for i = 1, 3 do
                        local priobj = {}
                        priobj["prizetype"] = string.upper(v["prize_type" .. i])
                        if priobj["prizetype"] and priobj["prizetype"] ~= "" then
                            priobj["prizevalue"] = v["prize_type_arg" .. i]
                            data.prize[i] = priobj
                        end
                    end
                    data.condition = {}
                    data.condition.class = v["class"]				-- string
                    data.condition.type = v["calc_type"]			-- questlib.QUEST_CONDITION_TYPE.*  SUM/ONCE
                    data.condition.count = v["count"]
                    data.condition.condition = {}
                    for i = 1, 5 do
                        local gameref = v["game_ref" .. i]
                        if gameref ~= "" then data.condition.condition[gamepkg.gameref[gameref]] = 1 end
                    end
                    local quest_id = v["quest_id"]
                    ASSERT(not questlist[questlib.QUEST_TYPE.EVERYDAY][quest_id], "任务ID有重复啊")
                    questlist[questlib.QUEST_TYPE.EVERYDAY][quest_id] = data
                    if v["is_must_show"] == 1 then
                        table.insert(everydaymustshow, v["quest_id"])
                    end
                end
                questlib.EVERY_DAY_MUST_SHOW = everydaymustshow
                questlib.questList = questlist
    
                --加载任务依赖表
                loadquestclass()			
            end
    
            --加载任务列表
            local loadquestlist = function()
                local sqlwhere = string.format("from configure_quest where game_name=%s and is_disabled = 0", dblib.tosqlstr(gamepkg.name))
                dblib.execute("select count(id) as count " .. sqlwhere, function(dtc)
                    local sqlstr = "select * " .. sqlwhere
                    local reached = 0
                    local dtall = {}
                    for i = 1, dtc[1]["count"] do
                        dblib.execute(string.format(sqlstr .. " limit 1 offset %d" , i - 1), function(dt)
                            if dt and #dt == 1 then
                                dtall[i] = dt[1]
                            else
                                TraceError("返回不是一条？")
                            end
                            reached = reached + 1
                            if reached == dtc[1]["count"] then
                                alldatareached(dtall)
                            end
                        end)
                        --for i
                    end 
                    --dblib.execute
                end)
            end
    
            loadquestlist()
        end, 2)
    end

    --数据库表配置翻译成功，去刷任务
    eventmgr:addEventListener("questlib_init_complete", 
    	function()
    		questlib.db_InitQuestList()
    	end)
    initquestfromdb()
end
---------------------------------- 事件模块 --------------------------------------

--用户登录的时机
if questlib.onuser_login then
	eventmgr:removeEventListener("h2_on_user_login", questlib.onuser_login);
end
questlib.onuser_login = function(e)
	if(not gamepkg.GetBeginnerGuideRate or gamepkg.GetBeginnerGuideRate(e.data.userinfo) == 0) then
		--TraceError("not beginner")	
		local questdata = e.data.data["quest_info"] or ""
		questlib.DoProcessUserEveryDayQuest(e.data.userinfo, questdata)
	end
end
eventmgr:addEventListener("h2_on_user_login", questlib.onuser_login);

--用户脱离新手任务事件
if questlib.user_finished_guide then
	eventmgr:removeEventListener("game_user_finished_guide", questlib.user_finished_guide);
end
questlib.user_finished_guide = function(e)
    --初始化日常任务
    local edlist = questlib.InitUserEveryDayQuest(e.data.userinfo)
    --给userinfo中的任务赋值
    questlib.AddUserEDQuest(e.data.userinfo, edlist)
    --告诉客户端刷任务
    questlib.net_OnSendQuestPhase(e.data.userinfo, 1)
end
eventmgr:addEventListener("game_user_finished_guide", questlib.user_finished_guide);

--用户任务进度变化了
if questlib.on_game_event then
	eventmgr:removeEventListener("game_event", questlib.on_game_event);
end
questlib.on_game_event = function(e)
	--TraceError("questlib.on_game_event()")
	local datalist = e.data
	for i = 1, #datalist do
		local userid = tonumber(datalist[i].userid)
		local data = datalist[i].data
		local userinfo = usermgr.GetUserById(userid)
        local single_event = datalist[i].single_event

		questlib.DoCheckUserQuest(userinfo, data , single_event)
	end
end
eventmgr:addEventListener("game_event", questlib.on_game_event);

--每分钟一次的时间，用来刷新任务和通知
if questlib.ontimer_minute then
	eventmgr:removeEventListener("timer_minute", questlib.ontimer_minute);
end
questlib.ontimer_minute = function(e)
    questlib.OnTimeCheckQuest(e.data.min)
end
eventmgr:addEventListener("timer_minute", questlib.ontimer_minute);

questlib.ForceRefreshQuest = function()
    TraceError("强制刷新任务")
    questlib.db_RefreshEveryDayQuest()
    timelib.createplan(
        function()
            questlib.db_InitQuestList()
        end
    , 2)
    TraceError("如果不是手动调试，看到此信息请报警！！")
end

------------------------------------------------------------------------------
--定时检查，任务相关内容
questlib.OnTimeCheckQuest = function(flagmin) 
    local tableTime = os.date("*t",os.time())
    local nowHour  = tonumber(tableTime.hour)

    local tips = "日常任务将在%s分钟后重置，请完成任务的玩家及时领取奖励。"
    --执行4点钟定时任务
    if(nowHour == 4 and flagmin == 0) then
        --定时刷新每日任务
        questlib.db_InitQuestList()
    end

    --不广播任务刷新倒计时 lch

    -- [[提醒任务还有1小时刷新]]
    if(nowHour == 3 and flagmin == 0) then
        --BroadcastMsg(_U(format(tips, "60")),0);
    end

    -- [[提醒任务还有30分钟刷新]]
    if(nowHour == 3 and flagmin == 30) then
        --BroadcastMsg(_U(format(tips, "30")),0);
    end

    --[[提醒任务还有10分钟刷新]]
    if(nowHour == 3 and flagmin == 50) then
        --BroadcastMsg(_U(format(tips, "10")),0);

        --3：50 把新的任务先放到数据库
        questlib.db_RefreshEveryDayQuest()
    end

     --[[提醒任务还有5分钟刷新]]
    if(nowHour == 3 and flagmin == 55) then
        --BroadcastMsg(_U(format(tips, "5")), 0);
    end
end
--------------------------------------------------------------------------------------
--------------------------------- 发送net ----------------------------------------

--发送任务类型，是新手任务还是日常任务
questlib.net_OnSendQuestPhase = function(userinfo, quest_phase)
    netlib.send(
		function(buf)
			buf:writeString("REQP")
            buf:writeByte(quest_phase)
		end
	, userinfo.ip, userinfo.port)
end

--发送日常任务进度信息[单人]
questlib.net_OnSendEDQuestPrizeOK = function(touserinfo, userinfo, userQuestInfo, getAllQuestPrize)
    if not touserinfo or not userinfo then return end
	netlib.send(
		function(buf)
			buf:writeString("RETC")
            buf:writeByte(userinfo.site or 0)
            buf:writeInt(userinfo.userId)
            buf:writeByte(#userQuestInfo.prize)
            for i=1, #userQuestInfo.prize do
                buf:writeString(userQuestInfo.prize[i].prizetype) --类型
                buf:writeInt(userQuestInfo.prize[i].prizevalue) --数量
            end
            buf:writeByte(getAllQuestPrize) --是否全部领完
		end
	, touserinfo.ip, touserinfo.port)
end

--发送日常任务进度信息，桌子包括观战人
questlib.net_OnBrocastEDQuestPrizeOK = function(userinfo, userQuestInfo, getAllQuestPrize)
    if not userinfo then return end
    --通知桌内玩家
    local deskno = userinfo.desk
    --没有桌子号，只发给自己
    if(not deskno) then
        questlib.net_OnSendEDQuestPrizeOK(userinfo, userinfo, userQuestInfo, getAllQuestPrize)
        return
    end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                questlib.net_OnSendEDQuestPrizeOK(playingUserinfo, userinfo, userQuestInfo, getAllQuestPrize)
            end
            if(playingUserinfo == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            questlib.net_OnSendEDQuestPrizeOK(watchinginfo, userinfo, userQuestInfo, getAllQuestPrize)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
end

--发送日常任务进度信息
questlib.net_OnSendEveryDayQuestInfo = function(userinfo, questList, questRefreshed)
    --得到任务数量
    local num = 0
    for k, v in pairs(questList) do
        if(k ~= nil and v ~= nil) then
            num = num + 1
        end
    end
	netlib.send(
		function(buf)
			buf:writeString("RERG")
            --发送每个任务详细信息
            buf:writeInt(num)
            for k, v in pairs(questList) do
                buf:writeInt(k)               --id
                buf:writeByte(v.isComplete)   --是否完成
                buf:writeByte(v.isGetPrize)   --是否领奖
                buf:writeByte(v.difficulty)   --难度
                buf:writeString(tostring(v.nanDuXiShu))  --难度系数
                buf:writeInt(v.condition)   --任务进度
                --TraceError(v.prize)
                buf:writeByte(#v.prize)   --该任务奖励种数
                for i=1, #v.prize do
                    buf:writeString(v.prize[i].prizetype) --奖励类型名
                    buf:writeInt(v.prize[i].prizevalue) --该类型的奖励数额
                end
            end
            buf:writeByte(questRefreshed) --任务是否重新刷新了
		end
	, userinfo.ip, userinfo.port)
end

--------------------------------- 客户端协议部分 ---------------------------------
--收到请求刷新日常任务
questlib.net_OnRecvEveryDayQuest = function(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    local questList = questlib.GetUserQuestList(userinfo)

    --异常处理，如果这时还没拿到任务就不处理
    if( questList == nil or
        questList[questlib.QUEST_TYPE.EVERYDAY] == nil) then
        return
    end

    local questList = questList[questlib.QUEST_TYPE.EVERYDAY]
    local questRefreshed = 0  --任务是否重新刷新时机
    questlib.net_OnSendEveryDayQuestInfo(userinfo, questList, questRefreshed)
end

--收到领取任务奖励
questlib.net_OnRecvEDQuestPrize = function(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    local questId = buf:readInt() --想要领取的任务ID

    --检查领取奖励合法性,领奖
    questlib.DoPrizeRequest(userinfo,questId)
end

--检查领取奖励合法性
questlib.DoPrizeRequest = function(userinfo,questId)
     --看是否真的完成了
    local edlist = questlib.GetUserQuestList(userinfo)

    if( edlist == nil or
        edlist[questlib.QUEST_TYPE.EVERYDAY] == nil or
        edlist[questlib.QUEST_TYPE.EVERYDAY][questId] == nil) then

        TraceError("用户没有完成任务却来领取奖励，有作弊可能, 不处理")
        return
    end

    local userQuestInfo = edlist[questlib.QUEST_TYPE.EVERYDAY][questId]
    if(userQuestInfo.isComplete == 0) then
        TraceError("用户没有完成任务却来领取奖励，有作弊可能, 不处理")
        return
    end

    --看是否领取过该奖励了，防止作弊
    if(userQuestInfo.isGetPrize == 1) then
        trace("用户领过奖，有作弊可能, 不处理")
        return
    end

    --执行领奖
    userQuestInfo.isGetPrize = 1 --设置领奖标识
    for i = 1, #userQuestInfo.prize do
        local prizeitem = userQuestInfo.prize[i]
        if(prizeitem.prizetype == "GOLD") then
            usermgr.addgold(userinfo.userId, prizeitem.prizevalue, 0, g_GoldType.quest, -1)
        elseif(prizeitem.prizetype == "PRESTIGE") then
            usermgr.addprestige(userinfo.userId, prizeitem.prizevalue) --更改用户声望
        elseif(prizeitem.prizetype == "EXPERIENCE") then
             --更改用户经验
            usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), prizeitem.prizevalue, g_ExpType.quest, questId)
        else
            TraceError("未知奖励类型，如果发现本提示请检查任务id=["..questId.."]的配置")
        end
    end

    local nGiveGoldType = 6

    --更改数据库用户任务信息
    questlib.db_UpdateUserEDQuest(userinfo,edlist[questlib.QUEST_TYPE.EVERYDAY], 3, questId)

    --更改任务进度信息
    questlib.update_completed_quest(userinfo, edlist[questlib.QUEST_TYPE.EVERYDAY])

    local questList = edlist[questlib.QUEST_TYPE.EVERYDAY]
    local questRefreshed = 0  --任务是否重新刷新时机

    questlib.net_OnSendEveryDayQuestInfo(userinfo, questList, questRefreshed)

    local getAllQuestPrize = 1
    --是否全部任务都领奖了
    for k, v in pairs(edlist[questlib.QUEST_TYPE.EVERYDAY]) do
        if v.isGetPrize == 0 then
            getAllQuestPrize = 0
            break
        end
    end
    xpcall(function()
        local getAllNormlQuest = 1
        for k, v in pairs(edlist[questlib.QUEST_TYPE.EVERYDAY]) do
            if v.isGetPrize == 0 and v.difficulty == questlib.DIFFICULTY["NORMAL"] then
                getAllNormlQuest = 0
                break
            end
        end
    
        if getAllNormlQuest == 1 then
            achievelib.updateuserachieveinfo(userinfo,2009)--中等日常
        end
    
        local getAllHardQuest = 1
        for k, v in pairs(edlist[questlib.QUEST_TYPE.EVERYDAY]) do
            if v.isGetPrize == 0 and v.difficulty == questlib.DIFFICULTY["HARD"] then
                getAllHardQuest = 0
                break
            end
        end
    
        if getAllHardQuest == 1 then
            achievelib.updateuserachieveinfo(userinfo,2018)--粉红日常
        end
    end,throw)
    --得到游戏的新声望
    local new_prestige = usermgr.getprestige(userinfo)

    --广播领奖事件
    questlib.net_OnBrocastEDQuestPrizeOK(userinfo, userQuestInfo, getAllQuestPrize)
    --如果在桌上
    --if(userinfo.site ~= nil and userinfo.site > 0) then
        -------------------------------成就采集-------------------------
        xpcall(function()
             achievelib.updateuserachieveinfo(userinfo,1006)--日常任务

             achievelib.updateuserachieveinfo(userinfo,1011)--日常新手

             achievelib.updateuserachieveinfo(userinfo,1019)--日常熟手

             achievelib.updateuserachieveinfo(userinfo,2025)--日常好手

             achievelib.updateuserachieveinfo(userinfo,3019)--日常高手

             achievelib.updateuserachieveinfo(userinfo,3029)--日常大师
        end,throw)
        ----------------------------------------------------------------
    --end
    
    
end

---------------------------------------------------------------------------
----------------  用户登录后 部分 -----------------------------------------
--从字符串加载table
function questlib.LoadQuestInfo(strData)
	if not strData or strData == "" then return nil end
	if string.sub(strData, 1, 2) == "do" then
		return table.loadstring(strData)
	else
		local retTable = {}
		local data = split(strData, ";")
		for i = 1, #data do
            local lines = split(data[i], "|")
			if (lines and #lines >= 8) then
				local t = {}
				t.condition 	= tonumber(lines[2])
				t.date 			= tonumber(lines[3])
				t.difficulty 	= tonumber(lines[4])
				t.isComplete 	= tonumber(lines[5])
				t.isGetPrize 	= tonumber(lines[6])
				t.nanDuXiShu 	= tonumber(lines[7])
                t.prize = {}
                local prize_count = tonumber(lines[8]) or 0
                local offset = 8
                for j = 1, prize_count do
                    t.prize[j] = {}
                    t.prize[j].prizetype 	= tostring(lines[offset + 1])
                    t.prize[j].prizevalue = tonumber(lines[offset+ 2])
                    offset = offset + 2
                end
				retTable[tonumber(lines[1])] = t
			end
        end
       
		return retTable
	end
end

--任务table转换为字符串
function questlib.ToQuestInfoString(tblData)
	local keys = {}
	local strRet = ""
	for k, v in pairs(tblData) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for i = 1, #keys do
		local strLine = keys[i] .. "|"
		local t = tblData[keys[i]]
		strLine = strLine .. t.condition .. "|"
		strLine = strLine .. t.date .. "|"
		strLine = strLine .. t.difficulty .. "|"
		strLine = strLine .. t.isComplete .. "|"
		strLine = strLine .. t.isGetPrize .. "|"
		strLine = strLine .. t.nanDuXiShu .. "|"
        strLine = strLine .. #t.prize .. "|"
        for j = 1, #t.prize do
    		strLine = strLine .. t.prize[j].prizetype .. "|"
    		strLine = strLine .. t.prize[j].prizevalue
            if j == #t.prize then
                strLine = strLine .. ";"
            else
                strLine = strLine .. "|"
            end
        end
		strRet = strRet .. strLine
    end
	return strRet
end


--收到用户今日任务信息
questlib.DoProcessUserEveryDayQuest = function(userinfo, szRet)
	local edlist = nil
    --数据库中有信息
    if(string.len(szRet) ~= 0) then
		--TraceError(szRet)
        edlist = questlib.LoadQuestInfo(szRet)
		--TraceError(edlist)
        --如果过期了，从内存拿，然后写到数据库
        if(edlist ~= nil) then
            local key, edItem = next(edlist)
            if not edItem then
            	return
            end 
						local eddate = edItem.date
            --用户任务不是今天的，去刷新
            if(questlib.isToday(eddate) == false) then
                edlist = questlib.InitUserEveryDayQuest(userinfo)
            end
        else
            edlist = questlib.InitUserEveryDayQuest(userinfo)
        end
    --数据库没有，生成，然后写到数据库
    else
        edlist = questlib.InitUserEveryDayQuest(userinfo)
    end

    --给userinfo中的任务赋值
    questlib.AddUserEDQuest(userinfo,edlist)
end

--写入用户日常任务到数据库
questlib.db_UpdateUserEDQuest = function(userinfo, list, rate, questId)
    dblib.cache_set(gamepkg.table, {quest_info=questlib.ToQuestInfoString(list)}, "userid", userinfo.userId)
	--包房没有日常任务
	if (isguildroom() == true) then
		return
	end
    if(rate == 1) then      --刷新成新的

    elseif(rate == 2) then  --进度发生改变

    elseif(rate == 3) then  --领取奖励
        --记录领奖日志
        local userQuestInfo = list[questId]

        if(userQuestInfo ~= nil) then
            for i = 1, #userQuestInfo.prize do
                local szSql = format(questlib.SQL.insertLogEveryDay,
                    userinfo.userId,
    				dblib.tosqlstr(gamepkg.name),
                    "'"..os.date("%Y-%m-%d %X", os.time()).."'",
                    userQuestInfo.nanDuXiShu,
                    questId,
                    userQuestInfo.prize[i].prizetype,
                    userQuestInfo.prize[i].prizevalue,
                    "")
    			dblib.execute(szSql)
            end
        end
	end
end

--清空服务器上所有用户每日任务信息
questlib.RefreshAllUserEDQuest = function()
    for k, v in pairs(userlist) do
        local bFlag = questlib.ClearUserEDQuest(v)
        --告诉客户端新的任务信息
        if(bFlag == true) then
            local list = questlib.InitUserEveryDayQuest(v) --刷新用户内存里任务信息
            questlib.AddUserEDQuest(v, list) --添加任务信息到用户

            --清空连赢状态
            if(questlib.GetUserQuestList(v) ~= nil and
               questlib.GetUserQuestList(v)[questlib.QUEST_TYPE.EVERYDAY] ~= nil) then

                local questList = questlib.GetUserQuestList(v)[questlib.QUEST_TYPE.EVERYDAY]
                local questRefreshed = 1  --任务是否重新刷新时机
                if (v.key == k and v.offline == nil) then
                    questlib.net_OnSendEveryDayQuestInfo(v, questList, questRefreshed)
                end
            end
        end
    end
end

-------------------- 服务器初始化任务，刷新任务部分 --------------
--收到今日日常任务信息
questlib.db_OnRecvToDayQuestList = function(dataTable)
    local everyDayList = nil

    --数据库中有今日任务信息
    if(#dataTable ~= 0 and dataTable[1][1] ~= nil and dataTable[1][1] ~= "") then
        everyDayList = table.loadstring(dataTable[1]["quest_Id_list"])

    --数据库没有，生成，然后写到数据库
    else
        --TraceError("数据库没有，生成，然后写到数据库")
        everyDayList = questlib.db_RefreshEveryDayQuest()
    end
    questlib.AddEveryQuestList(everyDayList)

    --清空用户任务信息
    questlib.RefreshAllUserEDQuest()
end

--初始化任务
questlib.db_InitQuestList = function()
    --从数据库拿10个任务
	local szSql = string.format(questlib.SQL.getEveryDayQuestInfo, dblib.tosqlstr(gamepkg.name), dblib.tosqlstr(gamepkg.name))
	dblib.execute(szSql, questlib.db_OnRecvToDayQuestList)
end

--刷新日常任务，并且写到数据库
questlib.db_RefreshEveryDayQuest = function()
    local everyDayList = questlib.GetDailyQuestList()
    local szSql = format(
        questlib.SQL.updateEveryDayQuestInfo,
        dblib.tosqlstr(table.tostring(everyDayList)),
		dblib.tosqlstr(gamepkg.name)
    )
    --把得到的list放到系统变量里
	dblib.execute(szSql)
    return everyDayList
end
--------------------------------------------------------------------

--检查用户任务完成度
questlib.DoCheckUserQuest = function(userinfo, questCondInfo, single_event)
    --筛选出任务完成条件
    --gamepkg.process_condition_to_quest 这个是直接调用各游戏里的
    --TODO:改成采集点方式
    --local questCondInfo = gamepkg.process_condition_to_quest(userRoundInfo)

    --看有什么任务完成了或进度变化了
    local result = questlib.AddAndFinishedProcess(userinfo,questCondInfo,single_event)

    --这里暂时只支持日常任务
    --得到用户已经接的日常任务信息
    local userQuestInfo = questlib.GetUserQuestList(userinfo)
    if(userQuestInfo ~= nil) then
        userQuestInfo = userQuestInfo[questlib.QUEST_TYPE.EVERYDAY]
    end

    if(userQuestInfo == nil) then
        return
    end

    --得到变化的任务，重构用户任务表
    local bNeedUpdate = false

    --循环任务进度发生改变的任务
    for k, v in pairs(result) do
        bNeedUpdate = true

        --任务是否完成
        userQuestInfo[k].isComplete = v.isComplete

        --任务完成时候，统计出难度系数，奖励等
        if(userQuestInfo[k].isComplete == 1) then
            --完成时难度系数
            local questInto = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, k)
            for i =1, #userQuestInfo[k].prize do
                userQuestInfo[k].prize[i].prizevalue = userQuestInfo[k].prize[i].prizevalue * userQuestInfo[k].nanDuXiShu
            end
        end
    end

    for k, v in pairs(userQuestInfo) do
        userQuestInfo[k].date = os.time()
    end

    --需要更新信息
    if(bNeedUpdate) then
        questlib.db_UpdateUserEDQuest(userinfo,userQuestInfo, 2, 0) -- 更新到数据库
        local questRefreshed = 0  --任务是否重新刷新时机
        local questList = userQuestInfo
        questlib.net_OnSendEveryDayQuestInfo(userinfo, questList, questRefreshed)
    end
end

--添加今日日常任务
questlib.AddEveryQuestList = function(questList)
    questlib.EveryDayQuestList = questList
end

--得到今日日常任务列表
questlib.GetEveryQuestList = function()
    return questlib.EveryDayQuestList
end

--是否为本日任务
questlib.isToday = function(sec)
	ASSERT(sec and tonumber(sec), "sec error")
    local tbNow  = os.date("*t",os.time())
    local today = os.time({year = tbNow.year,month = tbNow.month,day = tbNow.day,hour = 4,min = 0,sec = 0})

    local tbSec = os.date("*t",sec)
    if(tbNow.hour < 4) then
        today = os.time({year = tbNow.year,month = tbNow.month,day = tbNow.day - 1,hour = 4,min = 0,sec = 0})
    end

    return sec >= today
end

--清空用户每日任务信息
questlib.ClearUserEDQuest = function(userinfo)
    if(userinfo == nil or userinfo.questinfo == nil) then
       return false
    end
    userinfo.questinfo[questlib.QUEST_TYPE.EVERYDAY] = {}
    return true
end

--给用户每日任务赋值
questlib.AddUserEDQuest = function(userinfo, questList)
    if(userinfo == nil) then
        return
    end
	--包房没有每日任务
	if(isguildroom() == true) then
		return
	end

    if(userinfo.questinfo == nil) then
        userinfo.questinfo = {}
    end

    if(userinfo.questinfo[questlib.QUEST_TYPE.EVERYDAY] == nil) then
        userinfo.questinfo[questlib.QUEST_TYPE.EVERYDAY] = {}
    end
    userinfo.gameInfo.winpoint = nil    --清空连赢状态
    userinfo.questinfo[questlib.QUEST_TYPE.EVERYDAY] = questList

    --通知h2该游戏的完成的任务列表
    questlib.update_completed_quest(userinfo, questList)
end

--更新任务完成度的副本信息
questlib.update_completed_quest = function(userinfo, questlist)
    --通知h2该游戏的完成的任务列表
    local completed_quest = {} --完成的任务列表
    for k, v in pairs(questlist) do
        if(v.isGetPrize == 1) then
            table.insert(completed_quest, k)
        end
    end

    usermgr.update_user_completed_quest(userinfo,completed_quest)
end

--同步系统中日常任务信息到用户的日常任务列表
questlib.InitUserEveryDayQuest = function(userinfo)
    if userinfo == nil then
        TraceError("ERROR:USERINFO为空")
        return nil
    end

    local everyDayQuest = questlib.GetEveryQuestList()

    if(everyDayQuest == nil) then
        return nil
    end

    --遍历今日日常任务，将他们放到userinfo里
    local list = {}
    for k, v in pairs(everyDayQuest) do
        --任务详细信息
        local questInto = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, v)
        if(questInto ~= nil) then
            list[v] = {}
            list[v].condition = 0  --进度
            list[v].nanDuXiShu = 0 --难度系数
            list[v].isComplete = 0 --是否完成
            list[v].date = os.time() --时间
            list[v].isGetPrize = 0 --是否领奖
            list[v].difficulty = questInto.difficulty   --任务难度
            list[v].prize = {}
            for i =1, #questInto.prize do
                list[v].prize[i] = questInto.prize[i]
            end
        end
    end
    return list
end

--任务条件累加器,完成判断器,累加到用户任务变量里
--return: 发生变化的任务列表
questlib.AddAndFinishedProcess = function(userinfo, conditionInfo, single_event)
    --异常处理
    if(conditionInfo == nil or userinfo == nil) then
        --TraceError("ERROR:执行questlib.AddAndFinishedProcess,传入数据包含空数据")
        return
    end

    --得到用户的任务信息
    local userQuestList = questlib.GetUserQuestList(userinfo)
    if(userQuestList == nil) then
        return
    end

    local result = {}

    --房间难度系数
	local roomXiShu = questlib.GetRoomNanDuXiShu()

    --确定难度系数是否受BUFF的加成
    roomXiShu= questlib.do_extra_nanduxishu(userinfo, roomXiShu)

    --循环用户接的每个任务，给他们添加完成度
    --[[
        k: 表示任务类型，例如：everyday
        v: 相对应的任务类型的任务列表。
    ]]
    for k, v in pairs(userQuestList) do
        --循环循环每个类型的每个任务
        --[[
            m: 表示任务Id
            n: 表示用户的任务详情
        ]]
        for m, n in pairs(v) do
            local questInfo = questlib.GetQuestInfo(k, m) --得到任务配置信息

            if(questInfo ~= nil) then
                local questCondInfo = questInfo.condition --任务完成条件信息
                local needCond  = questCondInfo.condition --任务所需条件
                local needCount = questCondInfo.count     --任务所需步骤
                local needType  = questCondInfo.type      --任务所需完成类型               
                    

                --看条件是否都完成了
                local isAllComplate = true
                local finishedStep = 0
                for i, j in pairs(needCond) do
                    if(conditionInfo[i] == nil or conditionInfo[i] == 0) then
                        isAllComplate = false
                    else
                        questInfo.single_event = single_event
                         --这里的条件暂时取最大的，例如：3带1 和 赢，取三带一
                        if(conditionInfo[i] > finishedStep) then
                            finishedStep = conditionInfo[i] --任务进度
                        end
                    end
                end

                --需要一次完成的任务，每次清空
                if(needType == questlib.QUEST_CONDITION_TYPE.ONCE and (n.isComplete == nil or n.isComplete == 0)) then
                     result[m] = {}
                     result[m].isComplete = 0
                     n.condition = 0
                     n.nanDuXiShu = 0
                --需要连续完成的任务，中途没完成就清空
                elseif(needType == questlib.QUEST_CONDITION_TYPE.CONTINOUS and (n.isComplete == nil or n.isComplete == 0)) then
                    --if((not isAllComplate) and (questInfo.single_event and questInfo.single_event == single_event)) then
                    if((not isAllComplate) and (questInfo.single_event == nil or (questInfo.single_event and questInfo.single_event == single_event))) then
                         result[m] = {}
                         result[m].isComplete = 0
                         n.condition = 0
                         n.nanDuXiShu = 0
                    end
                end

                --任务超过，取胜下的step，例如 8 + 3 =10
                if(n.condition + finishedStep > needCount) then
                    finishedStep = needCount - n.condition
                end

                --达到完成条件了，进行累加[任务进度发生变化]
                if(isAllComplate == true) then
                    --看是否可以累加
                    if(needType == questlib.QUEST_CONDITION_TYPE.ONCE) then
                        n.condition = finishedStep
                    else
                        n.condition = n.condition + finishedStep   --累加完成条件
                    end
                    
                    if(n.condition > needCount) then
                        finishedStep = finishedStep - (n.condition - needCount)
                        n.condition = needCount
                    end
                    --难度系数
                    if finishedStep > 0 then
                        if(n.nanDuXiShu == 0) then
                            n.nanDuXiShu = math.round((roomXiShu * finishedStep) /  (finishedStep) * 10) / 10
                        else
                            n.nanDuXiShu = math.round((n.nanDuXiShu * (n.condition - finishedStep) + roomXiShu * finishedStep) /  n.condition * 10) / 10
                        end
                    end

                    --用完成处理器去看这个任务是否完成了，完成就加奖励
                    --条件数达成，任务完成
                    if(n.isComplete == 0) then
                        result[m] = {}
                        --任务完成了
                        if(n.condition >= needCount) then
                            result[m].isComplete = 1
                        else
                            result[m].isComplete = 0
                        end
                    end
                end
            end
        end
    end

    return result
end

--确定难度系数额外加成方式
questlib.do_extra_nanduxishu = function(userinfo, nanduxishu)
    local using_buff = bufflib.get_user_using_buff(userinfo)
    local bfind = false
    for k, v in pairs(using_buff) do
        if(v == bufflib.CLASS_INFO["DOUBLE_PRESTIGE"]) then
            bfind = true
        end
    end
    
    if(bfind) then
        nanduxishu = nanduxishu * 2
    end
    return nanduxishu
end

--得到某任务详细信息
questlib.GetQuestInfo = function(questType,questId)
    if(questlib.questList[questType] == nil) then
        return nil
    end
    return questlib.questList[questType][questId]
end

--得到用户已经接的任务信息
questlib.GetUserQuestList = function(userinfo)
    --为空的异常处理
    if(userinfo == nil or userinfo.questinfo == nil) then
        return nil
    end
    return userinfo.questinfo
end

--按配置得到随机的10个任务
questlib.get_random_quest_list = function()
     --重新创建一张临时questlist，用来刷新任务,这样不用按顺序了
    local questlist_origin = questlib.questList[questlib.QUEST_TYPE.EVERYDAY]
    local questidlist = {}

	for k, v in pairs(questlib.DIFFICULTY) do
		questidlist[v] = {}
	end

	--v表示任务详细信息，k表示任务ID
    for k, v in pairs(questlist_origin) do
        for k1, v1 in pairs(questlib.DIFFICULTY) do
            if(v.difficulty == v1 and v ~= nil) then    
                table.insert(questidlist[v1], k)
            end        
        end
    end

    --按配置个数选择任务
    local tSelectQuest = {}
	local quest_num_cfg = questlib.quest_num_cfg --难易任务，选择个数值

    --k为难度，v为该难度所要产生任务的个数
    for k, v in pairs(quest_num_cfg) do
        local nSelectCount = 0
		if(#questidlist[k] > 0 and v > 0) then
			while(true) do
				local nSelectItem = questidlist[k][math.random(1, #questidlist[k])]
				local bFind = false
				for k, v in pairs(tSelectQuest) do
					if (nSelectItem == v) then
						bFind = true
						break
					end
				end
				if (bFind == false) then
					nSelectCount = nSelectCount + 1
					tSelectQuest[table.getn(tSelectQuest) + 1] = nSelectItem
				end
				if (nSelectCount == v or nSelectCount == #questidlist[k]) then
					break
				end
			end
		end
    end
    return tSelectQuest
end

--获取每日任务
questlib.GetDailyQuestList = function()
   
    --得到初始10个任务
    local tSelectQuest = questlib.get_random_quest_list()
    -----------------------------------------------------------------------
    --临时函数，找一个任务系列是否被用过了
    local findUsedClass = function(classId,usedClass)
        local bFind = false
        for m, n in pairs(usedClass) do
            if(n == classId) then
                bFind = true
                break
            end
        end
        return bFind
	end

    --是否为必须出的任务
    local findIsMust = function(questId)
        for i, j in pairs(questlib.EVERY_DAY_MUST_SHOW) do
            if(j == questId) then
                return true
            end
        end
        return false
    end

    --是否为必须不出的任务
    local findIsMustNot = function(questId)
        for i, j in pairs(questlib.EVERY_DAY_NOT_SHOW) do
            if(j == questId) then
                return true
            end
        end
        return false
    end

    --临时函数，按难度随机替换
    local replaceByDifficulty = function(difficulty,questId)
        for k, v in pairs(tSelectQuest) do
            local questInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, v)
            if(questInfo ~= nil) then
                if(questInfo.difficulty == difficulty) then
                    if(findIsMust(v) == false and findIsMustNot(questId) == false) then
                        trace("按难度随机替换:"..tSelectQuest[k].." 换成:"..questId);
                        tSelectQuest[k] = questId
                        break
                    end
                end
            end
        end
    end

    --看任务是否出现过
    local findIsExists = function(questId)
        for k, v in pairs(tSelectQuest) do
            if(v == questId) then
                return true
            end
        end
        return false
    end
	---------------- 特殊处理，保证每天屏蔽掉任务 -----------
    --保证每天有必须屏蔽的任务
    --[[
        j:任务id
    ]]
    for i, j in pairs(questlib.EVERY_DAY_NOT_SHOW) do
        --得到任务难度
        local needDifficulty = questlib.DIFFICULTY.EASY --默认为简单
        local needQuestInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, j)
        if(needQuestInfo ~= nil) then
            needDifficulty = needQuestInfo.difficulty
        end

        --看选出的日常任务有没有必须要的任务
        local bFind = false
        for k, v in pairs(tSelectQuest) do
            if v == j then
                bFind = true
                break;
            end
        end

        --如果有这样的任务，随便替换一个没出现过的同难度的给他
        if bFind then
            for k, v in pairs(tSelectQuest) do
                if(v == j) then
                    for x, y in pairs(questlib.questList[questlib.QUEST_TYPE.EVERYDAY]) do
                        if y.difficulty  == needDifficulty then
                              if(findIsMustNot(x) == false and findIsExists(x) == false) then
                                --TraceError("保证每天有必须屏蔽的任务,把"..tSelectQuest[k].."替换成"..x);
                                tSelectQuest[k] = x
                                break
                            end
                        end
                    end
                end
            end
        end
    end


    --保证每天的必须任务
    --[[
        j:任务id
    ]]
    for i, j in pairs(questlib.EVERY_DAY_MUST_SHOW) do
        --得到必须任务的任务难度
        local needDifficulty = questlib.DIFFICULTY.EASY --默认为简单
        local needQuestInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, j)
        if(needQuestInfo ~= nil) then
            needDifficulty = needQuestInfo.difficulty
        end

        --看选出的日常任务有没有必须要的任务
        local bFind = false
        for k, v in pairs(tSelectQuest) do
            if v == j then
                bFind = true
            end
        end

        --如果没有10盘这样的任务，随便替换一个同难度的给他
        if bFind == false then
            replaceByDifficulty(needDifficulty, j)
        end
    end

    ---------------- 特殊处理，保证不同难度里的任务类型都不一样 ---------
    --[[
        k: 编号，无意义
        v: 任务ID
    -]]
    local usedClass = {}
    for k, v in pairs(tSelectQuest) do
        local questInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, v)

        --把用到任务类型放到一个临时表
        if(questInfo ~= nil) then
            --循环3个任务难度，从简单到难
            for i = 1, 5 do
                if(questInfo.difficulty == i) then

                    --任务系列是否被用过了
                    local bFind = findUsedClass(questInfo.condition.class,usedClass)

                    --之前的类型没用过，添加到已经类型
                    if(bFind == false) then
                        usedClass[k] = questInfo.condition.class

                    --之前的类型已经用了，替换成没用过的类型
                    else
                        --循环所有任务列表，找一个没用过的类型替换
                        --[[
                            m: 任务id
                            n：任务详情
                        ]]
                        for m, n in pairs(questlib.questList[questlib.QUEST_TYPE.EVERYDAY]) do
                            local questClass = n.condition.class     --任务Class
                            --匹配相同的难度
                            if(n.difficulty == i) then
                                local bFind2 = findUsedClass(questClass,usedClass)
                                --该任务没用过，替换掉之前的
                                if(bFind2 == false) then
                                    if(findIsMust(m) == false and findIsMustNot(m) == false) then
                                        --还要判断是否为必出任务
                                        --TraceError("替换"..tSelectQuest[k].." 成"..m);
                                        tSelectQuest[k] = m
                                        usedClass[k] = questClass
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ---------------- 特殊处理，实现必须成对出现的任务集合----------
    --[[
        k: class1
        v: class2
    -]]
    for k, v  in pairs(questlib.EVERY_DAY_FACE_TO_FACE_CLASS) do
        --如果找到了k,去找v
        --如果找到了v,去找k
        --都找到就不处理
        --[[
            m: 编号，无意义
            n: 任务ID
        -]]
        local bFindK = false
        local bFindV = false
        for m, n in pairs(tSelectQuest) do
            local questInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, n)
            if(questInfo ~= nil) then
                if(k == questInfo.condition.class) then
                    bFindK = true
                end
                if(v == questInfo.condition.class) then
                    bFindV = true
                end
                if(bFindK == true and bFindV == true) then
                    break
                end
            end
        end

        --只找到其中一个，去替换另一个
        if(bFindK and bFindV == false) or (bFindV and bFindK ==false) then
            --循环所有任务列表
            --[[
                i: 任务id
                j：任务详情
            ]]
            for i, j in pairs(questlib.questList[questlib.QUEST_TYPE.EVERYDAY]) do
                local questClass = j.condition.class     --任务Class
                local difficulty = j.difficulty          --任务难度
                --替换V
                if(bFindK) then
                    --现有任务中有V系列
                    if(questClass == v) then
                        replaceByDifficulty(difficulty, i)
                        break
                    end
                --替换K
                elseif(bFindV) then
                    --现有任务中有k系列
                    if(questClass == k) then
                        replaceByDifficulty(difficulty, i)
                        break
                    end
                end
            end
        end
    end

    -----------------------------------------------------------------------
    ---------------- 特殊处理，实现必须不能成对出现的任务集合----------
    --[[
        k: class1
        v: class2
    -]]
    for k, v  in pairs(questlib.EVERY_DAY_NOT_IN_TOGETHER) do
        --如果找到了k,去找v
        --如果找到了v,去找k
        --都找到就不处理
        --[[
            m: 编号，无意义
            n: 任务ID
        -]]
        local bFindK = false
        local bFindV = false
        local idxV = 0
        local diffV = 0
        for m, n in pairs(tSelectQuest) do
            local questInfo = questlib.GetQuestInfo(questlib.QUEST_TYPE.EVERYDAY, n)
            if(questInfo ~= nil) then

                if(bFindK == false) then
                    if(k == questInfo.condition.class) then
                        bFindK = true
                    end
                end

                if(bFindV == false) then
                    if(v == questInfo.condition.class) then
                        idxV = m
                        diffV = questInfo.difficulty
                        bFindV = true
                    end
                end

                if(bFindK == true and bFindV == true) then
                    break
                end
            end
        end

        --同时存在，去替换第二个
        if(bFindK == true and bFindV == true) then
            --循环所有任务列表
            --[[
                i: 任务id
                j：任务详情
            ]]
            for i, j in pairs(questlib.questList[questlib.QUEST_TYPE.EVERYDAY]) do
                local questClass = j.condition.class     --任务Class
                local difficulty = j.difficulty          --任务难度

                --匹配相同的难度
                if(j.difficulty == diffV) then
                    local bFind2 = findUsedClass(questClass,usedClass)
                    --该任务没用过，替换掉之前的
                    if(bFind2 == false and findIsExists(i) == false) then
                        if(findIsMustNot(i) == false) then
                            tSelectQuest[idxV] = i
                            usedClass[idxV] = questClass
                            break
                        end
                    end
                end
            end
        end
    end
	return tSelectQuest
end

--得到房间的难度系数
questlib.GetRoomNanDuXiShu = function()
    local peilv = groupinfo.gamepeilv

    if(questlib.ROOM_NANDUXISHU[peilv] == nil) then
        --TraceError("ERROR：房间难度系数未找到对应赔率配置值，取默认值 1")
        return 1
    end
    return questlib.ROOM_NANDUXISHU[peilv]
end

-------------------------------------------------------------------------------
--收到请求任务状态
questlib.net_OnRecvQuestPhase = function(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]

    --做完新手任务才能做日常
    local quest_phase = 0
    if(not gamepkg.GetBeginnerGuideRate or gamepkg.GetBeginnerGuideRate(userinfo) == 0) then
        quest_phase = 1
    end
    
    --通知是否显示日常任务，如果新手任务未完成就不显示
    questlib.net_OnSendQuestPhase(userinfo, quest_phase)
end


--命令列表
cmdHandler = 
{
	------------------------- 日常任务 ----------------------------
    ["RQRG"] = questlib.net_OnRecvEveryDayQuest,         --收到请求刷新任务 [from client]
    ["RQQP"] = questlib.net_OnRecvQuestPhase,            --收到任务类型请求
    ["RQTC"] = questlib.net_OnRecvEDQuestPrize,          --收到领取奖励请求 [from client]
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
