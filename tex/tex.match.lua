
--初始化比赛信息
TraceError("初始化德州比赛信息")

if tex_match and tex_match.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", tex_match.on_after_user_login);
end

if tex_match and tex_match.ontimecheck then
	eventmgr:removeEventListener("timer_minute", tex_match.ontimecheck);
end

tex_match = _S
{
	init = NULL_FUNC,    --初始化   
	add_queue=NULL_FUNC,
	get_base_score=NULL_FUNC,
	get_out_score=NULL_FUNC,
	get_match_id_by_desk_no=NULL_FUNC,
	get_pre_match_win_lost_info=NULL_FUNC,
	is_all_game_over=NULL_FUNC,
	get_match_user_num=NULL_FUNC,
	get_score_rank=NULL_FUNC,
    process_pre_match_over=NULL_FUNC,
	is_final_match_round_over=NULL_FUNC,
	get_final_match_round_rank=NULL_FUNC,
	process_final_match_round_over=NULL_FUNC,
	on_game_over=NULL_FUNC,
	on_user_game_over=NULL_FUNC,
	join_match=NULL_FUNC,
	exit_match=NULL_FUNC,
	start_match=NULL_FUNC,
	on_recv_jbs_info=NULL_FUNC,
	on_recv_jbs_baomin=NULL_FUNC,
	on_recv_jbs_cancel=NULL_FUNC,
	update_invite_ph_list=NULL_FUNC,
	on_recv_invite_ph_list=NULL_FUNC,
	on_recv_invite_dj=NULL_FUNC,
	can_join_invite_match=NULL_FUNC,
	can_sit_invite_desk=NULL_FUNC,
	on_recv_refresh_timeinfo=NULL_FUNC,
	on_after_user_login=NULL_FUNC,
	init_invite_ph=NULL_FUNC,
	init_invate_match=NULL_FUNC,
	get_invate_match_id=NULL_FUNC,
	get_invate_match_count=NULL_FUNC,
	on_recv_already_know_reward=NULL_FUNC,
	invite_match_fajiang=NULL_FUNC,
	ontimecheck=NULL_FUNC,
	invite_update_user_play_count=NULL_FUNC,
	
	on_recv_activity_stat = NULL_FUNC,	--请求活动时间状态
	on_recv_sign = NULL_FUNC,		--请求报名比赛
	sign_succes = NULL_FUNC,	--报名成功
	
	update_invite_db = NULL_FUNC,	--更新比赛信息	
	update_play_count = NULL_FUNC, 	--更新玩的盘数
	consider_screen = NULL_FUNC,	--计算第几场
	inster_invite_db = NULL_FUNC,	--报名写数据库
	
	on_recv_buy_ticket = NULL_FUNC,		--请求购买比赛券
	
	send_buy_ticket_result = NULL_FUNC,	--发送购买比赛券结果
	
	statime = "2012-01-17 20:00:00",  --活动开始时间
    endtime = "2012-02-7 23:00:00",  --活动结束时间
    
    rank_endtime = "2012-02-09 00:00:00",	--排行榜结束时间
 --   exttime = "2011-11-14 00:00:00",  --只能领奖时间
    room_smallbet1=-50,
    room_smallbet2=500,
    room_smallbet3=20000,
    refresh_invate_time=-1,  --上一次刷新排行榜的时间
	last_msg_time=-1, --上一次发消息的时间
    invite_ph_list_zj={}, --专家场排名
    invite_ph_list_zy={}, --职业场排名
    invite_ph_list_yy={}, --业余场排名
 
}

if (tex_match == nil) then
    tex_match = 
    {
        group_list = {},  --报名组
        --[[
            [match_id] =
            {
                user_list = 
                {   
                    user_id=
                    {
                        score = 0, --分数                        
                        join_time = os.time(),
                        round_num = 0,  --打了几轮
                    }
                }
                stage = 0 -- 比赛阶段 1表示初赛，2表示决赛
                start_time = xx
            }         
        --]]
        index_match_id = 1;
        -----------------------决赛配置-----------------------------------
        round_num = 3,      --一轮打几副牌
        ------------------------------------------------------------------
        -----------------------初赛配置-----------------------------------
        init_score = 10,       --初始分数
        min_score = 10,        --初赛被淘汰的分数
        max_score = 10,        --初赛晋级的分数
        start_game_user = 3,   --初赛开始人数
        pass_user_num = 1,     --晋级人数
        ------------------------------------------------------------------
        is_match_group = 0,    --是否是比赛场房间
        
    }
end


--擂台赛 begin

function tex_match.init()
if true then return end
end

--增加一个用户到排队队列中进行排队
function tex_match.add_queue(user_id)
if true then return end
end

--得到某一场比赛的游戏基数分
function tex_match.get_base_score(match_id)
    local match_group_item = tex_match.group_list[match_id]
    if (match_group_item == nil) then
        TraceError("为何没有此比赛信息")
        return 0
    end
    --60s增加20%
    local time_min = math.floor((os.time() - match_group_item.start_time) / 60)
    if (time_min == 0) then
        return tex_match.init_score
    else
        return math.floor(tex_match.init_score * math.pow(1.2, time_min))
    end
end

--获取淘汰分
function tex_match.get_out_score(match_id)
    return tex_match.get_base_score(match_id) * 2
end

--根据桌号获得当前比赛桌的id
function tex_match.get_match_id_by_desk_no(desk_no)   
    local user_key = hall.desk.get_user(desk_no, 1) --得到用户的信息表。
     if (user_key == nil) then
        return -1
    end
    local user_game_data = deskmgr.getuserdata(userlist[user_key])
    if (user_game_data == nil) then
        return -1
    end
    return user_game_data.tex_match_id or -1
end

--获取初赛晋级,淘汰和比赛中的用户数量
function tex_match.get_pre_match_win_lost_info(math_id)
    local match_group_item = tex_match.group_list[math_id]
    if (match_group_item == nil) then
        return -1, -1, -1
    end
    local win_num = 0
    local lose_num = 0
    local match_num = 0
    for k, v in pairs(match_group_item.user_list) do
        if (v.score >= tex_match.max_score) then
            win_num = win_num + 1
        elseif (v.score < tex_match.min_score) then
            lose_num = lose_num + 1
        else
            match_num = match_num + 1
        end
    end
    return win_num, lose_num, match_num
end

--检测是否所有用户都结算完成，处于等待状态
function tex_match.is_all_game_over(match_id) 
    --检测是否所有桌子都结算完成了
    local is_all_game_over = 1
    local user_info = nil
    for k, v in pairs(tex_match.group_list[math_id].user_list) do
        user_info = usermgr.GetUserById(k) 
        if (user_info ~= nil and user_info.desk_no ~= nil and 
            user_info.site_no and gamepkg.getGameStart(user_info.desk, user_info.site) == 1) then
            is_all_game_over = 0
            break
        end
    end
    return is_all_game_over
end

--获取比赛人数
function tex_match.get_match_user_num(match_id)
    local match_group_item = tex_match.group_list[match_id];
    local user_num
    for k, v in pairs(match_group_item.user_list) do
        user_num = user_num + 1
    end
    return user_num
end

--获取分数排行
function tex_match.get_score_rank(match_id)
    local match_group_item = tex_match.group_list[match_id];
    local match_user_list = {}
    for k, v in pairs(match_group_item.user_list) do
        table.insert(match_user_list, k)
    end
    --按照分数排名，分数相同的按照比赛时间排名
    table.sort(match_user_list, 
               function(a, b) 
                    if (match_group_item.user_list[a].score == match_group_item.user_list[b].score) then
                        return match_group_item.user_list[a].join_time > match_group_item.user_list[b].join_time
                    else
                        return match_group_item.user_list[a].score > match_group_item.user_list[b].score 
                    end
               end)
    return match_user_list
end

--初赛结束处理
function tex_match.process_pre_match_over(match_id)
    --确定名次
    local match_group_item = tex_match.group_list[math_id]
    local match_user_rank = tex_match.get_score_rank(match_id)
    -- todo match_user_list 前n个人颁奖,提示晋级，出局，领奖
    --删除淘汰的人，其他人进入决赛
    for i = tex_match.pass_user_num + 1, #match_user_rank do
        tex_match.exit_match(match_user_rank[i])
    end    
end

--决赛一轮是否结束
function tex_match.is_final_match_round_over(desk_no, match_id)    
    local user_info = hall.desk.get_user(desk_no, 1) --得到用户的信息表。
    if (user_info == nil) then
        return -1
    end    
    if (tex_match.group_list[match_id].user_list[user_info.userId].round_num == tex_match.round_num) then
        return 1
    else
        return 0
    end    
end

--获取决赛中一轮名次
function tex_match.get_final_match_round_rank(desk_no, match_id)
    local user_info = nil
    local match_user_id_list = {}
    for i = 1, room.cfg.DeskSiteCount do
        user_info = hall.desk.get_user(desk_no, i)
        table.insert(match_user_id_list, user_info.userId)
    end
    table.sort(match_user_id_list, 
                function(a, b)
                    return tex_match.group_list[match_id].user_list[a].score > tex_match.group_list[match_id].user_list[b].score
                end)
    return match_user_id_list
end

--处理决赛一轮比赛完成后的晋级情况
function tex_match.process_final_match_round_over(match_id)    
    --淘汰出局玩家
    local match_user_rank = tex_match.get_score_rank()
    local user_num = #match_user_rank
    --淘汰一半的玩家
    local match_group_item = tex_match.group_list[match_id]
    local pass_user_list = match_group_item.pass_user_list
    table.sort()
    --选出第二名第三名的玩家中排名靠前的玩家
    local left_user_num = user_num / 2 - pass_user_list
    local is_find = 0
    for i = 1,  #match_user_rank do
        is_find = 0
        for j = 1,  #pass_user_list do
            if (pass_user_list[j] == match_user_rank[i]) then
                is_find = 1
                break
            end
        end
        if (is_find == 0) then
            left_user_num = left_user_num - 1
            table.insert(pass_user_list, match_user_rank[i])
            if (left_user_num == 0) then
                --一半人员的晋级名单已经确定
                break
             end
        end
    end
    --删除没有晋级的玩家
    for i = 1,  #match_user_rank do
        is_find = 0
        for j = 1,  #pass_user_list do
            if (match_user_rank[j] == pass_user_list[i]) then
                is_find = 1
                break
            end    
        end
        if (is_find == 0) then
            tex_match.exit_match(match_user_rank[i])            
        end
    end    
end

--一桌游戏结束
function tex_match.on_game_over(desk_no)    
    local match_id = tex_match.get_match_id_by_desk_no(desk_no)
    if (match_id == -1) then
        return
    end
    local match_group_item = tex_match.group_list[match_id]
    if (match_group_item.stage == 1) then  --第一轮结束
        local win_num, lose_num, match_num = tex_match.get_pre_match_win_lost_info(match_id)
        --出局人数已满
        if (win_num + match_num >= tex_match.pass_user_num) then--如果比赛人数大于其他人数，初赛结束
            if (match_group_item.pre_match_over == 0) then
                TraceError("播报: 出局人数已满，本局结束后将等待其它桌比赛结果确定晋级名单")
            end
            match_group_item.pre_match_over = 1            
            --处理预赛完成
            if (tex_match.is_all_game_over() == 1) then
                tex_match.process_pre_match_over(match_id)
                --到达下一个阶段比赛
                match_group_item.stage = 2
            end 
        end
        if (match_group_item.pre_match_over == 0) then
           --todo 安排座位
            TraceError("安排座位")
            tex_match.start_match(match_id)
        end
    else
        --检测一轮是否已经完成
        if (tex_match.is_final_match_round_over(desk_no, match_id) == 1) then
            --确定本轮名次
            local round_user_rank = tex_match.get_final_match_round_rank(desk_no, match_id)
            if (tex_match.is_all_game_over(match_id) == 0) then                
                TraceError("一轮已经结束，等待其他人比赛完成,通知第一二三名信息")
            else
                --最后一轮了
                if (tex_match.get_match_user_num() == room.cfg.DeskSiteCount) then 
                    TraceError("最后一轮发奖")
                    --所有人退出本场比赛
                    for k, v in pairs(match_group_item.user_list) do
                        tex_match.exit_match(k)
                    end
                    --一场游戏结束，用户重新报名
                    return
                else
                    --第一名晋级
                    table.insert(tex_match.group_list[match_id].pass_user_list, round_user_rank[1])
                    --处理一轮晋级的情况
                    TraceError("一轮已经结束,通知第一二三名信息,已经淘汰获奖信息")
                    tex_match.process_final_match_round_over()                    
                end
            end
            --todo 安排座位
            tex_match.start_match(match_id)
        end
        
    end
    
    --决赛阶段
    --检测3副牌是否打完，打完后确定晋级和淘汰名单
    --晋级玩家直接开赛
    --淘汰和第二名玩家等待
    --所有人打完一轮，确定晋级名单，发奖
end

--一桌游戏结束
--返回值，是否晋级，是否淘汰
function tex_match.on_user_game_over(user_info, gold, beishu)
    --记录用户参加的那场比赛
    	--发送有人出局了
	local send_out_result=function(user_info)
		 netlib.send(function(buf)	    
		    	 buf:writeString("TXBISAIOUT")
		    	 buf:writeByte(user_info.site)
		    	 buf:writeInt(user_info.userId)	
		    	 buf:writeString(user_info.face)
		    	 buf:writeString(user_info.nick)		    	 
			  end, user_info.ip, user_info.port)
	end
    local user_game_data = deskmgr.getuserdata(user_info)
    if (user_game_data.tex_match_id == nil) then
        TraceError("比赛场为何没有比赛id")
        return -1
    end
    local match_group_item = tex_match.group_list[user_game_data.tex_match_id]
    if (match_group_item.user_list[user_info.userId] == nil) then
        TraceError("用户为何没有在比赛信息中")
        return -1
    end
    local match_user_info = match_group_item.user_list[user_info.userId]
    --检测是否是预赛
    if (match_group_item.stage == 1) then        
        --beishu=公共倍数*房间倍数*加倍倍数
        match_user_info.score = match_user_info.score - beishu / groupinfo.gamepeilv * tex_match.get_base_score(user_game_data.tex_match_id)
        --检测是否被淘汰了
        if (match_user_info.score < tex_match.min_score) then
            TraceError("玩家已经被淘汰")
            send_out_result(user_info);
        --检测是否晋级
        elseif (match_user_info.score >= tex_match.max_score) then
            --检测自己是不是最后一个初赛结束的人            
            TraceError("恭喜玩家已经晋级")
        end
    else
        match_user_info.round_num = match_user_info.round_num + 1        
    end
    return 1
    
    --
        --如果结束，重新安排桌子（初赛喝决赛不同处理）
    --检测当前初赛是否结束
        --开始决赛
    --检测决赛是否结束
        
end

--参加比赛
function tex_match.join_match(user_id)

	--发送报名结果
	local send_join_result=function(user_info,match_id,baoming_result,already_baoming)
		 netlib.send(function(buf)	    
		    	 buf:writeString("TXJBSJOIN")
		    	 buf:writeByte(baoming_result)
		    	 buf:writeInt(match_id)	
		    	 buf:writeInt(already_baoming)	
			  end, user_info.ip, user_info.port)
	end
	
	--更新报名结果（发给所有这轮参赛的人）
	local send_update_join_result=function(user_info,match_id,already_baoming)
		local match_user_list = tex_match.group_list[match_id].user_list
	 	for k, v in pairs(match_user_list) do
        	netlib.send(function(buf)	    
		    	 buf:writeString("TXJBSSETNUM")
		    	 buf:writeInt(match_id)	
		    	 buf:writeInt(already_baoming)	
			  end, v.ip, v.port)
        end
		 
	end

    local user_info = usermgr.GetUserById(user_id)
    local group_list = tex_match.group_list
    if (group_list[tex_match.index_match_id] == nil) then
        group_list[tex_match.index_match_id] = 
        {
            stage = 1,
            start_time = 0,
            user_list = {},  
            pass_user_list = {}, --晋级用户列表，用于决赛阶段          
            join_num = 0,       --参加游戏的人数
            pre_match_over = 0, --初赛中出局人数是否已满
        }
    end
    local group_info = group_list[tex_match.index_match_id]
    local match_user_list = group_list[tex_match.index_match_id].user_list
    if (match_user_list[user_info.userId] ~= nil) then
        TraceError("已经报过名了")
        send_join_result(user_info,tex_match.index_match_id,0,group_info.join_num);
        return
    else
        match_user_list[user_info.userId]=
        {
            score = tex_match.init_score,
            rank = -1,
            round_num = 0,  --打了几轮
            join_time = os.time(),
        }
        group_info.join_num = group_info.join_num + 1
        --记录用户参加的那场比赛
        local user_game_data = deskmgr.getuserdata(user_info)
        user_game_data.tex_match_id = tex_match.index_match_id
        
        --通知客户端报名成功
        send_join_result(user_info,tex_match.index_match_id,1,group_info.join_num);
        send_update_join_result(user_info,tex_match.index_match_id,group_info.join_num);
        --检测比赛人数是否达到条件，如果达到则开赛，同时初始化下一场比赛
        if (group_info.join_num == tex_match.start_game_user) then
            tex_match.start_match(tex_match.index_match_id)  --开始一场比赛
            tex_match.index_match_id = tex_match.index_match_id + 1
            --如果举办过1k场比赛，则比赛id重新来一次，是否可能同时举办1k场比赛
            if (tex_match.index_match_id > 10000) then 
                tex_match.index_match_id = 1
            end
        end
    end
end

--退出比赛
function tex_match.exit_match(user_id)
    
    --发送取消报名结果
	local send_exit_result=function(user_info,match_id,baoming_result,already_baoming)
		 netlib.send(function(buf)	    
		    	 buf:writeString("TXJBSCANCEL")
		    	 buf:writeByte(baoming_result)
		    	 buf:writeInt(match_id)	
		    	 buf:writeInt(already_baoming)	
			  end, user_info.ip, user_info.port)
	end
	
    local user_info = usermgr.GetUserById(user_id)
    if (user_info == nil) then
    	send_exit_result(user_info,tex_match.index_match_id,0,group_info.join_num);
        TraceError("退出比赛时有用户信息为空")
        return 
    end

	
    local user_game_data = deskmgr.getuserdata(user_info)
    if (user_game_data == nil) then
    	send_exit_result(user_info,tex_match.index_match_id,0,group_info.join_num);
        TraceError("用户没有比赛id")
        return 
    end
    local match_group_item = tex_match.group_list[user_game_data.tex_match_id]
    local match_user_list = match_group_item.user_list
    if (match_user_list[user_id] ~= nil) then
        match_user_list[user_id] = nil
        if (match_group_item.start_time == 0) then
            match_group_item.join_num = match_group_item.join_num - 1
            send_exit_result(user_info,tex_match.index_match_id,1,group_info.join_num);
        end
        --所有人退出了比赛，重新开始一场比赛
        local has_user = 0
        for k1, v1 in pairs(match_user_list) do
            has_user = 1
            break
        end
        if (has_user == 0) then
            tex_match.group_list[user_game_data.tex_match_id] = nil
        end
    end
         
    local user_game_data = deskmgr.getuserdata(user_info)
    if (user_game_data ~= nil) then 
        user_game_data.tex_match_id = nil
    end
end

--开始一场游戏，开始分用户到不同的桌子
function tex_match.start_match(match_id)
	local send_start_match=function(user_info,match_id,baoming_result,already_baoming)
		 netlib.send(function(buf)	    
		    	 buf:writeString("TXJBSBEGIN")
		    	 buf:writeByte(baoming_result)
		    	 buf:writeInt(match_id)	
		    	 buf:writeInt(already_baoming)	
			  end, user_info.ip, user_info.port)
	end
	
    --设置比赛开始时间
    if (tex_match.group_list[match_id].start_time == 0) then
        tex_match.group_list[match_id].start_time = os.time()
    end
    local match_user_list = tex_match.group_list[match_id].user_list
    local start_desk_no = math.floor(match_id * (tex_match.start_game_user / 3)) + 1
    local end_desk_no = math.floor((match_id + 1) * (tex_match.start_game_user / 3)) + 1
    local site_no = 1    
    local user_info = nil
    for k, v in pairs(match_user_list) do
        --当前用户已经在座位上了，但是游戏没有开始，则让用户站起来，然后坐到一个合适的位置上
        user_info = usermgr.GetUserById(k)
        if (user_info.desk ~=nil or user_info.site ~= nil and 
            gamepkg.getGameStart(user_info.desk, user_info.site) == false) then
            --TraceError("standup:"..user_info.userId.." "..start_desk_no.." "..site_no)
            doUserStandup(user_info.key, true)
        end
    end
    
    local find_site = 0
    for k, v in pairs(match_user_list) do
        find_site = 0
        user_info = usermgr.GetUserById(k)
        if (user_info.desk == nil or user_info.site == nil) then
            for i = start_desk_no, end_desk_no do
                for j = 1, room.cfg.DeskSiteCount do
                    local site_user_info = deskmgr.getsiteuser(i, j)
                    if (site_user_info == nil) then
                        --TraceError("sitdown:"..user_info.userId.." "..i.." "..j)
                        doSitdown(user_info.key, user_info.ip, user_info.port, i, j)
                        find_site = 1
                        break
                    end
                end
                if (find_site == 1) then
                    break
                else
                    start_desk_no = start_desk_no + 1
                end
            end
        end
    end
end


function tex_match.on_recv_jbs_info(buf)
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
end

function tex_match.on_recv_jbs_baomin(buf)
	local user_info = userlist[getuserid(buf)];
	if(user_info == nil)then return end
	--比赛报名
	tex_match.join_match(user_info.userId)
	
	 
end

function tex_match.on_recv_jbs_cancel(buf)
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	tex_match.exit_match(user_info.userId)
end

--擂台赛 end

-----------------我是华丽的分隔线--------------------------------------------
--手机活动,邀请赛 begin

function check_datetime()
	local statime = timelib.db_to_lua_time(tex_match.statime);
	local endtime = timelib.db_to_lua_time(tex_match.endtime);
--	local exttime = timelib.db_to_lua_time(tex_match.exttime);
	local sys_time = os.time();
	--可以领奖和增加游戏时间
	if(sys_time >= statime and sys_time <= endtime) then
		    local tdate = os.date("*t", sys_time);		    
	        if (tdate.hour >= 20 and tdate.hour < 23)  then
	            return 2;
	        end	        
	end	
	--只能领奖
	if(sys_time > statime and sys_time <= endtime) then
        return 1;
	end
	
	
	--活动时间过去了
	return 0;
end

--判断是不是有效的比赛
function tex_match.can_join_invite_match(user_info,deskinfo,match_num)
	--TraceError("--判断是不是有效的比赛, userId:"..user_info.userId.." match_num:"..match_num)
	--判断时间的合法性,0不合法，1只能填领奖信息，2能填领奖信息和比赛
	if(deskinfo~=nil and deskinfo.smallbet~=tex_match.room_smallbet1 and deskinfo.smallbet~=tex_match.room_smallbet2 and deskinfo.smallbet~=tex_match.room_smallbet3)then
		--TraceError("--判断是不是有效的比赛->>>deskinfo,room_smallbet1,room_smallbet2")
		return false
	end
	
	--1.时间判断（比赛还没开始，请在11月4-6日每晚20：:00准时参加。！）
	if(check_datetime()~=2)then
	    --msg = "对不起，本活动有时间限制，请阅读活动说明！";
    	--OnSendServerMessage(userinfo, 1 , _U(msg));
    	--TraceError("--判断是不是有效的比赛->>>>check_datetime")
		return false
	end

	--2.VIP判断（VIP3级）
	--3.人数判断(4人以上才算成绩），因为人数不足也应该可以游戏，所以这里不做判断了
    --[[
    local msg = "";
    local viplevel = 0
	if(viplib) then
	    viplevel = viplib.get_vip_level(user_info)
	end
    if(viplevel<3)then
    	--msg = "抱歉，进入房间需要至少金卡VIP身份，请充值获取金卡VIP身份!";
    	--OnSendServerMessage(userinfo, 1 , _U(msg));
    	return false
    end
    --]]
    
    --判断3人以上才算有效比赛，记录局数
    if(match_num<4)then
   		--TraceError("--判断不是有效的比赛-->>>match_num")
    	return false
    end
    
    return true
end


--生成比赛的信息(每次，每个玩家发生有效比赛时调用）
function tex_match.update_invite_ph_list(user_info,match_gold)
	--TraceError("--生成比赛的信息(每次，每个玩家发生有效比赛时调用）")
	if (user_info==nil) then return end
	
	if(user_info.sign_ruslt == "0")then return end

	local deskno=user_info.desk
	local deskinfo=desklist[deskno]
	local match_num = tex_match.get_invate_match_count(deskno)
	local match_type=1
	
	--TraceError("生成比赛的信息,match_num:"..match_num)
	if(tex_match.can_join_invite_match(user_info,deskinfo,match_num))then
	
		if(deskinfo.smallbet==tex_match.room_smallbet1)then
			match_type=1;
		elseif(deskinfo.smallbet==tex_match.room_smallbet2)then
			match_type=2;
			
			--判断用户在职业场还是专家场打牌
			if(user_info.sign_ruslt == "2")then
				----TraceError("match_type=2,useid:%d, sign:%s"..user_info.userId..user_info.sign_ruslt)
				return
			end
			
		elseif(deskinfo.smallbet==tex_match.room_smallbet3)then
			match_type=3;
			
			--判断用户在职业场还是专家场打牌
			if(user_info.sign_ruslt == "1")then
				--TraceError("match_type=3,useid:%d,sign:%s"..user_info.userId..user_info.sign_ruslt)
				return
			end
			
		end
		--TraceError("match_type "..match_type.."deskinfo.smallbet "..deskinfo.smallbet)
		tex_match.update_invite_db(user_info,match_gold,match_type, 0)
	end	
end

--更新比赛信息 
function tex_match.update_invite_db(user_info,match_gold,match_type, sign)
	--TraceError("更新比赛信息  sign->"..sign)
	if(sign == 0)then
		local sql="insert into t_invite_pm(user_id,nick_name,win_gold,play_count,match_type,sys_time) value(%d,'%s',%d,1,%d,now()) on duplicate key update win_gold=win_gold+%d,play_count=play_count+1,sys_time=now();commit;";
		sql=string.format(sql,user_info.userId,user_info.nick,match_gold,match_type,match_gold);
		dblib.execute(sql)
		tex_match.update_play_count(user_info,match_type)
	else
		local sql="insert into t_invite_pm(user_id,nick_name,win_gold,match_type,sys_time,sign) value(%d,'%s',%d,%d,now(),%d) ON DUPLICATE KEY UPDATE sys_time=NOW()";
		sql=string.format(sql,user_info.userId,user_info.nick,match_gold,match_type,sign);
		dblib.execute(sql)
		tex_match.update_play_count(user_info,match_type)
	end
end	


	--更新玩的盘数
tex_match.update_play_count=function(user_info,match_type)
 
	--TraceError("更新玩的盘数 userID->"..user_info.userId.."match_type->"..match_type)
 
	if(match_type==1)then
	
		if(user_info.yy_play_count==nil)then
			user_info.yy_play_count=1
			return
		end
		
		user_info.yy_play_count=user_info.yy_play_count+1 or 1
		
	elseif(match_type==2)then
	
		if(user_info.zy_play_count==nil)then
			user_info.zy_play_count=1
			--TraceError("更新玩的盘数 user_info.zy_play_count->"..user_info.zy_play_count)
			return
		end
		
		user_info.zy_play_count=user_info.zy_play_count+1 or 1
		--TraceError("更新玩的盘数 user_info.zy_play_count->"..user_info.zy_play_count)
		
	elseif(match_type==3)then
		if(user_info.zj_play_count==nil)then
			user_info.zj_play_count=1
			--TraceError("更新玩的盘数 user_info.zj_play_count->"..user_info.zj_play_count)
			return
		end
		user_info.zj_play_count=user_info.zj_play_count+1 or 1
		--TraceError("更新玩的盘数 user_info.zj_play_count->"..user_info.zj_play_count)
	end
end


function tex_match.can_sit_invite_desk(user_info,desk_info)
	----TraceError("--看房间是不是我们要求的房间")
	if (user_info==nil) then return false end
	if (desk_info==nil) then return false end
	----TraceError("can_sit_invite_desk 01")
	--看房间是不是我们要求的房间
	if(desk_info~=nil and desk_info.smallbet==tex_match.room_smallbet and desk_info.at_least_gold==tex_match.room_at_least_gold)then
		local msg = "";
	    local viplevel = 0
		if(viplib) then
		    viplevel = viplib.get_vip_level(user_info)
		end
	    if(viplevel<3)then
	    	--msg = "抱歉，参加邀请赛需要至少金卡VIP身份，请充值获取金卡VIP身份!";
	    	msg = tex_lan.get_msg(userinfo, "match_msg");
	    	OnSendServerMessage(user_info, 1 , _U(msg));
	    	return false
	    end
	end
	return true

end


tex_match.ontimecheck = function(e)
  	--10分钟要刷一次
  	----TraceError("tex_match.ontimecheck");
  	local userinfo = e.data.userinfo
  	if(userinfo==nil)then
  		--TraceError("tex_match.ontimecheck userinfo is nil")
  	end
  	
  	if(check_datetime() == 0)then	--判断活动时间过期
  		return
  	end
  	
	if(tex_match.refresh_invate_time==-1 or os.time()>tex_match.refresh_invate_time+60*10)then
		----TraceError("tex_match.ontimecheck");
    	tex_match.refresh_invate_time=os.time();
    	tex_match.init_invite_ph();
    end
    
    --20:00,20:20,20:40,21:00,21:20,21:40,22:00 共发全服7次广播
    
    local tableTime = os.date("*t",os.time());
    local nowYear = tonumber(tableTime.year);
    local nowMonth = tonumber(tableTime.month);
    local nowDay = tonumber(tableTime.day);
    
    local nowHour  = tonumber(tableTime.hour);
    local nowMin   = tonumber(tableTime.min);
    local nowSec      = tonumber(tableTime.sec);
    
    local tmp_time="'"..nowYear.."-"..nowMonth.."-"..nowDay.." "..nowHour..":"..nowMin..":00"
    if ((nowHour==20 and nowMin==0)
    	or (nowHour==20 and nowMin==20)
    	or (nowHour==20 and nowMin==40)
    	or (nowHour==21 and nowMin==0)
    	or (nowHour==21 and nowMin==20)
    	or (nowHour==21 and nowMin==40)
    	or (nowHour==22 and nowMin==0)) 	then
		
		-- --TraceError(tmp_time)
		-- --TraceError(tex_match.last_msg_time)
   	-- --TraceError(timelib.db_to_lua_time(tmp_time))
   
		if(tex_match.last_msg_time<timelib.db_to_lua_time(tmp_time))then
		----TraceError("2012公会方舟大赛火热开启")
		   	--BroadcastMsg(_U("2012公会方舟大赛火热开启，赶快加入，赢取每日最高1800W奖励，勇夺最终方舟大奖！"),0)
	    	local msg=""
	    	msg=tex_lan.get_msg(userinfo, "match_msg_noti");
	   -- --TraceError(msg)
	    	BroadcastMsg(_U(msg),0)
	    	tex_match.last_msg_time=os.time();
		end
	end
    
end

--初始化排行榜
function tex_match.init_invite_ph()
	--TraceError("-->>>>初始化排行榜")
	tex_match.invite_ph_list_zj={}; --专家场排名
	tex_match.invite_ph_list_yy={};	--业余场排名
	tex_match.invite_ph_list_zy={};	--职业场排名
	
	--初始化排行
	local init_match_ph=function(ph_list,match_type)
		local sql="select user_id,nick_name,win_gold,match_king_count,play_count,sign from t_invite_pm where match_type=%d and play_count>=1 order by win_gold desc"
		sql=string.format(sql,match_type)
		----TraceError(sql)
		dblib.execute(sql,function(dt)	
				if(dt~=nil and  #dt>0)then
					for i=1,#dt do
						local bufftable ={
						  	    mingci = i, 
			                    user_id = dt[i].user_id,
			                    nick_name=dt[i].nick_name,
			                    win_gold=dt[i].win_gold,
			                    match_king_count=dt[i].match_king_count,
			                    play_count=dt[i].play_count,
			                    sign = dt[i].sign,
		                }
		                
						table.insert(ph_list,bufftable)
					end
				end
	    end)
    end
    --初始化业余场排行
    init_match_ph(tex_match.invite_ph_list_yy,1)
    --初始化职业场排行
    init_match_ph(tex_match.invite_ph_list_zy,2)
    --初始化专家场排行
    init_match_ph(tex_match.invite_ph_list_zj,3)
	
end

--请求邀请赛的排行榜
function tex_match.on_recv_invite_ph_list(buf)
	--TraceError("--请求邀请赛的排行榜")
	local user_info = userlist[getuserid(buf)]; 
	local mc = -1; --用于记下自己的名次
	local win_gold = 0; --用于记下自己的成绩
	local match_king_count = 0; --用于记下自己的王者次数
	local play_count = 0; --用于记下自己的玩的次数
	
	local invite_paimin_list={};
	local send_len=5;--默认发5条信息
	if(user_info == nil)then return end
	
	--查询自己的名次，如果没有名次就返回-1
	--返回名次，成绩，成为王者的次数，玩的次数
	local my_mc=-1;
	local my_win_gold=0;
	local my_king_count=0;
	local my_play_count=0;
	
	local get_my_pm = function(ph_list,user_info)
		local mc=-1
		if (ph_list==nil) then return -1,0,0,0 end
		
		for i=1,#ph_list do
			if(ph_list[i].user_id==user_info.userId)then
				return i,ph_list[i].win_gold,ph_list[i].match_king_count,ph_list[i].play_count
			end
		end

		return -1,0,0,0;--没有找到对应玩家的记录，认为他没有成绩
	end
	
	--得到自己玩了多少盘
	local get_my_real_play_count=function(user_info,match_type)
	
		if(match_type==3)then
			return user_info.zj_play_count or 0
		end
		
		if(match_type==2)then
			return user_info.zy_play_count or 0
		end

		if(match_type==1)then
			return user_info.yy_play_count or 0						
		end	
	end
	
	--1，业余场；2，职业场；3，专家场
	local query_match_type = buf:readByte(); 
	local my_real_play_count=get_my_real_play_count(user_info,query_match_type) or 0
	
	if(query_match_type==1)then
		invite_paimin_list=tex_match.invite_ph_list_yy
	elseif(	query_match_type==2) then
		invite_paimin_list=tex_match.invite_ph_list_zy
	elseif(	query_match_type==3) then
		invite_paimin_list=tex_match.invite_ph_list_zj
	end
	
	----TraceError("query_match_type="..query_match_type)
	
	--TraceError(invite_paimin_list)
	--判断报名    0：未报名    1：职业场      2：专家场       3：职业场和专家场
	local baoming_sign = user_info.sign_ruslt	--发送客户端，只有0，未报名；1，已报名
	--TraceError("query_match_type:"..query_match_type)
	if(query_match_type==2)then
		--TraceError("111111111->>>"..baoming_sign)
		if(baoming_sign=="0")then
		--	TraceError("22222222222")
			baoming_sign = "0"
		elseif(baoming_sign=="1")then
			--TraceError("3333333333")
			baoming_sign = "1"
		elseif(baoming_sign=="2")then
			--TraceError("4444444444")
			baoming_sign = "0"
		elseif(baoming_sign=="3")then
			--TraceError("5555555")
			baoming_sign = "1"
		end
	
	elseif(	query_match_type==3) then
		--TraceError("6666666:"..baoming_sign)
		
		if(baoming_sign == "0")then
			--TraceError("777777777")
			baoming_sign = "0"
		elseif(baoming_sign == "1")then
			--TraceError("88888888888")
			baoming_sign = "0"
		elseif(baoming_sign == "2")then
			--TraceError("99999999999")
			baoming_sign = "1"
		elseif(baoming_sign == "3")then
			--TraceError("++++++++++")
			baoming_sign = "1"
		end
		
	end
	
	--这里my_play_count不能使用，需要用其他机制去处理
	my_mc,my_win_gold,my_king_count,my_play_count=get_my_pm(invite_paimin_list,user_info)

    	netlib.send(function(buf)
	    	buf:writeString("INVITEPHLIST")
			--TraceError("my_win_gold:"..my_win_gold)
			if(baoming_sign=="1")then
	    		buf:writeByte(1)	--是否已报名：0，未报名；1，已报名
	    	else
	    		buf:writeByte(0)	--是否已报名：0，未报名；1，已报名

	    	end
	    	
		    --是否显示领奖按钮
		    buf:writeByte(0) --目前没有领奖功能，先拿掉这块的代码了。以后有再加上
		    buf:writeInt(my_win_gold or 0)
		    buf:writeInt(my_mc or 0)
		    buf:writeInt(my_king_count or 0)

		    buf:writeInt(60-my_real_play_count)--离60局还差多少局
		    buf:writeString(tostring(my_real_play_count))--还要想想怎么优化，玩的局数 e.g. 10|20|32
			if send_len>#invite_paimin_list then send_len=#invite_paimin_list end --最多发5条信息
			--TraceError("send_len:"..send_len)
			
			 buf:writeInt(send_len)
				--再发其他人的
		        for i=1,send_len do
			        buf:writeInt(invite_paimin_list[i].mingci)	--名次
			        buf:writeInt(invite_paimin_list[i].user_id) --玩家ID
			        buf:writeString(invite_paimin_list[i].nick_name) --昵称
			        buf:writeInt(invite_paimin_list[i].win_gold) --玩家成绩
			        
		
		        end
	        end,user_info.ip,user_info.port)   
end

--填写邀请赛的领奖结果，新版本中不再使用了，先保留，防止以后还要发实物奖
function tex_match.on_recv_invite_dj(buf)
	--TraceError("--填写邀请赛的领奖结果，新版本中不再使用了，先保留，防止以后还要发实物奖")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local real_name=buf:readString();
	local tel=buf:readString();
	local yy_num=buf:readInt();
	local address=buf:readString();
	local sql="update t_invite_pm set real_name='%s',tel='%s',yy_num=%d,address='%s' where user_id=%d;commit;"
	sql=string.format(sql,real_name,tel,yy_num,address,user_info.userId)
	
	dblib.execute(sql)
	netlib.send(function(buf)
		    buf:writeString("INVITEDJ")
		    buf:writeByte(1)		    
	        end,user_info.ip,user_info.port)   
end

--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的
function tex_match.init_invate_match(deskno)
	--TraceError("--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的")
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	if(deskinfo.smallbet~=tex_match.room_smallbet1 and deskinfo.smallbet~=tex_match.room_smallbet2 and deskinfo.smallbet~=tex_match.room_smallbet3)then
		return -1
	end
	local playinglist=deskmgr.getplayers(deskno)
	
	deskinfo.invate_match_id = deskno..os.time();
	deskinfo.invate_match_count=#playinglist;
	
	local flag=0;--0无效，1有效
	local match_time_status=check_datetime();
	if(match_time_status ==2)then
	--TraceError("--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的")
		if(deskinfo.invate_match_count~=nil and deskinfo.invate_match_count>3)then
			flag=1;
		end
		for _, player in pairs(playinglist) do
		local user_info = player.userinfo
			if(#playinglist>1)then
			
				--告诉客户端这次成绩是有效还是无效的
				netlib.send(function(buf)
				    buf:writeString("INVITEREC")
				    buf:writeByte(flag)		    
			        end,user_info.ip,user_info.port)   
			end
		end
	end
	
	return deskinfo.invate_match_id;
end

--得到邀请赛的ID
function tex_match.get_invate_match_id(deskno)
	--TraceError("--得到邀请赛的ID")
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	return deskinfo.invate_match_id or -1;
end

--得到邀请赛的玩家人数，拿到人数后会将人数清0，因为邀请赛只有结算时才可能用一次本方法
function tex_match.get_invate_match_count(deskno)
	--TraceError("--得到邀请赛的玩家人数，拿到人数后会将人数清0，因为邀请赛只有结算时才可能用一次本方法  deskno:"..deskno)
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	--TraceError("--111111111111111111 invate_match_count:"..deskinfo.invate_match_count)
	return deskinfo.invate_match_count or 0;
end

--离比赛开局和结束还差多少秒
function tex_match.on_recv_refresh_timeinfo(buf)
	--TraceError("--离比赛开局和结束还差多少秒")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local match_time_status=check_datetime();--有效是1 无效是0
	--有效：距离结束时间1，距离开场时间0
	--无效：距离结束时间0，距离开场时间1
	local flag1=0;
	local flag2=0;
	if(match_time_status == 0 or match_time_status == 1)then
		flag1=0
		flag2=1
	else
		flag1=1
		flag2=0
	end
	netlib.send(function(buf)
	    buf:writeString("INVITEBTN")
	    buf:writeInt(flag1)  --距离比赛结束时间		
	    buf:writeInt(flag2)  --距离比赛开场时间
	    buf:writeInt(-1)  --现在玩了多少盘		    
	end,user_info.ip,user_info.port)   
end

--客户端通知已经点过领奖按钮了(本方法暂时不使用，防止逻辑出现混乱）
function tex_match.on_recv_already_know_reward(buf)
	--TraceError("--客户端通知已经点过领奖按钮了")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local match_type=buf:readByte()
	local sql="update t_invite_pm set get_reward_time=now() where user_id=%d and match_type=%d;commit;"
	sql=string.format(sql,user_info.userId,match_type);
	dblib.execute(sql)
end

--用户登录后事件
tex_match.on_after_user_login = function(e)
	--TraceError("--用户登录后事件")
	local userinfo = e.data.userinfo
	if(userinfo == nil)then 
		--TraceError("比赛  。。用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	--看是不是要给他发奖，是的话就发消息
	local match_time_status=check_datetime();--有效是1 无效是0
	--如果现在不是比赛时间，就发奖（发奖模块也会清空没得奖的人的比赛成绩）
	--TraceError("--用户登录后事件match_time_status->"..match_time_status)

	if(match_time_status==1)then
		tex_match.invite_match_fajiang(userinfo)
	end
	
	tex_match.invite_update_user_play_count(userinfo)
	
end


function tex_match.invite_update_user_play_count(user_info)

		if(user_info.sign_ruslt == nil)then
			user_info.sign_ruslt = "0"
		end
		
		local sql="SELECT play_count,match_type FROM t_invite_pm where user_id=%d order by match_type"
		sql=string.format(sql,user_info.userId)
		dblib.execute(sql,function(dt)
			if(dt~=nil and #dt>0)then			
				for i=1,#dt do
 
					if(dt[i].match_type==1)then
						user_info.yy_play_count=dt[i].play_count or 0
	
					elseif(dt[i].match_type==2)then
						user_info.zy_play_count=dt[i].play_count or 0
			
					elseif(dt[i].match_type==3)then
						user_info.zj_play_count=dt[i].play_count or 0
	
					end
				
				end
			end
		end)
		
		--TraceError("user_info.userId->"..user_info.userId)
		--sql="SELECT SUM(sign) AS sign FROM t_invite_pm where user_id=%d AND DATE(baoming_time) = DATE(NOW()) and hour(baoming_time)<23 "
		--sql="SELECT SUM(sign) AS sign FROM t_invite_pm WHERE user_id=%d AND !(DATE(baoming_time) != DATE(NOW()) OR  ((HOUR(NOW())<23 AND baoming_time='1900-01-01 00:00:00') OR ( HOUR(NOW())>=23 AND HOUR(baoming_time)<23)));"
		--复杂的SQL,（1、判断当天内报名情况，2、判断当天23：00到明天23：00报名情况，3、判断31日至1日情况，4、判断无报名情况）
		sql ="SELECT SUM(sign) AS sign FROM t_invite_pm WHERE user_id=%d AND (!(DATE(baoming_time) != DATE(NOW()) OR  ((HOUR(NOW())<23 AND baoming_time='1900-01-01 00:00:00') OR ( HOUR(NOW())>=23 AND HOUR(baoming_time)<23))) OR (DATE(baoming_time)=DATE_SUB(DATE(NOW()), INTERVAL 1 DAY) AND HOUR(baoming_time)>=23))"
		
		sql=string.format(sql,user_info.userId)
		--TraceError("sql="..sql)
		dblib.execute(sql,function(dt)
			if(dt~=nil and #dt>0)then	
				
				--local temp1 = 0
				--temp1 = dt[1].sign or 0
				--TraceError("temp1->"..temp1)
						
				--user_info.sign_ruslt = temp1
				user_info.sign_ruslt = dt[1].sign or "0"  --取出值，0：未报名 1：职业场  2：专家场  3：职业场和专家场
				
				--TraceError("user_info.sign_ruslt->"..user_info.sign_ruslt)
				
				if(user_info.sign_ruslt == "" )then
					user_info.sign_ruslt = "0"
				end
			end
		end)
end

--计算第几场
function tex_match.consider_screen()
	local screen = 0

	local statime_1 = timelib.db_to_lua_time("2012-01-17 00:00:00")  --活动时间
    local statime_2 = timelib.db_to_lua_time("2012-01-18 00:00:00")  --活动时间
    local statime_3 = timelib.db_to_lua_time("2012-01-19 00:00:00")  --活动时间
    local statime_4 = timelib.db_to_lua_time("2012-01-20 00:00:00")  --活动时间
    local statime_5 = timelib.db_to_lua_time("2012-01-21 00:00:00")  --活动时间
    
    local statime_6 = timelib.db_to_lua_time("2012-01-22 00:00:00")  --活动时间
    local statime_7 = timelib.db_to_lua_time("2012-01-23 00:00:00")  --活动时间
    local statime_8 = timelib.db_to_lua_time("2012-01-24 00:00:00")  --活动时间
    local statime_9 = timelib.db_to_lua_time("2012-01-25 00:00:00")  --活动时间
    local statime_10 = timelib.db_to_lua_time("2012-01-26 00:00:00")  --活动时间
    
    local statime_11 = timelib.db_to_lua_time("2012-01-27 00:00:00")  --活动时间
    local statime_12 = timelib.db_to_lua_time("2012-01-28 00:00:00")  --活动时间
    local statime_13 = timelib.db_to_lua_time("2012-01-29 00:00:00")  --活动时间
    local statime_14 = timelib.db_to_lua_time("2012-01-30 00:00:00")  --活动时间
    local statime_15 = timelib.db_to_lua_time("2012-01-31 00:00:00")  --活动时间
    
    local statime_16 = timelib.db_to_lua_time("2012-02-01 00:00:00")  --活动时间
    local statime_17 = timelib.db_to_lua_time("2012-02-02 00:00:00")  --活动时间
    local statime_18 = timelib.db_to_lua_time("2012-02-03 00:00:00")  --活动时间
    local statime_19 = timelib.db_to_lua_time("2012-02-04 00:00:00")  --活动时间
    local statime_20 = timelib.db_to_lua_time("2012-02-05 00:00:00")  --活动时间
    
    local statime_21 = timelib.db_to_lua_time("2012-02-06 00:00:00")  --活动时间
    local statime_22 = timelib.db_to_lua_time("2012-02-07 00:00:00")  --活动时间
    
  
	local sys_time = os.time()
    if(sys_time > statime_1 and sys_time < statime_2) then
        screen = 1
    elseif(sys_time > statime_2 and sys_time < statime_3) then
    	screen = 2
    elseif(sys_time > statime_3 and sys_time < statime_4) then
    	screen = 3
    elseif(sys_time > statime_4 and sys_time < statime_5) then
    	screen = 4
    elseif(sys_time > statime_5 and sys_time < statime_6) then
    	screen = 5
    	
   elseif(sys_time > statime_6 and sys_time < statime_7) then
    	screen = 6
    elseif(sys_time > statime_7 and sys_time < statime_8) then
    	screen = 7
    elseif(sys_time > statime_8 and sys_time < statime_9) then
    	screen = 8
    elseif(sys_time > statime_9 and sys_time < statime_10) then
    	screen = 9
    	
    elseif(sys_time > statime_10 and sys_time < statime_11) then
    	screen = 10
    elseif(sys_time > statime_11 and sys_time < statime_12) then
    	screen = 11
    elseif(sys_time > statime_12 and sys_time < statime_13) then
    	screen = 12
    elseif(sys_time > statime_13 and sys_time < statime_14) then
    	screen = 13
    	
    elseif(sys_time > statime_14 and sys_time < statime_15) then
    	screen = 14
    elseif(sys_time > statime_15 and sys_time < statime_16) then
    	screen = 15
    elseif(sys_time > statime_16 and sys_time < statime_17) then
    	screen = 16
    elseif(sys_time > statime_17 and sys_time < statime_18) then
    	screen = 17
    elseif(sys_time > statime_18 and sys_time < statime_19) then
    	screen = 18
    elseif(sys_time > statime_19 and sys_time < statime_20) then
    	screen = 19
    elseif(sys_time > statime_20 and sys_time < statime_21) then
    	screen = 20
    elseif(sys_time > statime_21 and sys_time < statime_22) then
    	screen = 21
    elseif(sys_time > statime_22) then
    	screen = 22
	end
	
	return screen;
end

--给玩家发奖
--产生结果后，再打一盘就发奖，或重登陆时才发奖
function tex_match.invite_match_fajiang(userinfo)
	--TraceError("--给玩家发奖")
	local _tosqlstr = function(s) 
		s = string.gsub(s, "\\", " ") 
		s = string.gsub(s, "\"", " ") 
		s = string.gsub(s, "\'", " ") 
		s = string.gsub(s, "%)", " ") 
		s = string.gsub(s, "%(", " ") 
		s = string.gsub(s, "%%", " ") 
		s = string.gsub(s, "%?", " ") 
		s = string.gsub(s, "%*", " ") 
		s = string.gsub(s, "%[", " ") 
		s = string.gsub(s, "%]", " ") 
		s = string.gsub(s, "%+", " ") 
		s = string.gsub(s, "%^", " ") 
		s = string.gsub(s, "%$", " ") 
		s = string.gsub(s, ";", " ") 
		s = string.gsub(s, ",", " ") 
		s = string.gsub(s, "%-", " ") 
		s = string.gsub(s, "%.", " ") 
		return s 
	end
	
	local mc=-1;
	
	local screen_n = tex_match.consider_screen()
	
	local send_result=function(userinfo,mc,match_type)
		--TraceError("mc:"..mc.."  userid"..userinfo.userId.."  match_type"..match_type)
		netlib.send(function(buf)
		    buf:writeString("INVITEGIF")
		    buf:writeInt(mc)  --名次	
		    buf:writeByte(match_type)
		    buf:writeInt(screen_n)  --第几场	    
		end,userinfo.ip,userinfo.port)  
	end
	
	--具体发奖
	local jutifajiang = function(i,userinfo,reward)
		--给发奖
		usermgr.addgold(userinfo.userId, reward, 0, g_GoldType.invite_match_gold, -1, 1);
					  				
		local user_nick = userinfo.nick
		user_nick=_tosqlstr(user_nick).."   "
							
		--发全服广播
		local msg=""
		if(match_type==1)then
			--msg=string.format(msg,"业余","1W");
			msg=tex_lan.get_msg(userinfo, "match_msg_awards_1")..user_nick..tex_lan.get_msg(userinfo, "match_msg_awards_type_1");
			reward = reward/10000
			msg = string.format(msg,i,reward);
 	
		elseif(match_type==2)then
			--msg=string.format(msg,"职业","8W");
			msg=tex_lan.get_msg(userinfo, "match_msg_awards_1")..user_nick..tex_lan.get_msg(userinfo, "match_msg_awards_type_2");
			reward = reward/10000
			msg = string.format(msg,i,reward);
			
		elseif(match_type==3)then
			--msg=string.format(msg,"专家","188W");
			msg=tex_lan.get_msg(userinfo, "match_msg_awards_1")..user_nick..tex_lan.get_msg(userinfo, "match_msg_awards_type_3");
			reward = reward/10000
			msg = string.format(msg,i,reward);
			
		end
		
		BroadcastMsg(_U(msg),0)
	
	end
	
	--发奖
	local fajiang=function(userinfo,match_type,reward1,reward2,reward3,reward4,reward5)
		--get_reward_time每天用计划任务变成'2000-10-10'，
		local sql="select user_id,get_reward_time from t_invite_pm where match_type=%d and play_count>=1  order by win_gold desc limit 5";
		sql=string.format(sql,match_type)
		--荣誉道具，现在不发了，暂时屏蔽掉
		--local xz=0;
		--if(match_type==1)then
		--	xz=9009;
		--elseif(match_type==2)then
		--	xz=9010;
		--elseif(match_type==3)then
		--	xz=9011;
		--end

		dblib.execute(sql,function(dt)	
				if(dt~=nil and  #dt>0)then
					--local fajiang_flag=0;
					local len=5
					if(#dt<5)then
						len=#dt
					end
					
					for i=1,len do
						local get_reward_time=0;
						if(dt[i].get_reward_time~=nil)then
							get_reward_time=timelib.db_to_lua_time(dt[i].get_reward_time) or 0
						end
					  	if(dt[i].user_id==userinfo.userId and get_reward_time<timelib.db_to_lua_time('2010-11-11'))then
	     			  			if(i==1)then
					  				jutifajiang(i,userinfo,reward1)
					  			elseif(i==2)then
					  				jutifajiang(i,userinfo,reward2)
					  				--usermgr.addgold(userinfo.userId, reward2, 0, g_GoldType.invite_match_gold, -1, 1);
					  			elseif(i==3)then
					  				jutifajiang(i,userinfo,reward3)
					  				--usermgr.addgold(userinfo.userId, reward3, 0, g_GoldType.invite_match_gold, -1, 1);
					  			elseif(i==4)then
					  				jutifajiang(i,userinfo,reward4)
					  				--usermgr.addgold(userinfo.userId, reward4, 0, g_GoldType.invite_match_gold, -1, 1);
					  			elseif(i==5)then
					  				jutifajiang(i,userinfo,reward5)
					  				--usermgr.addgold(userinfo.userId, reward5, 0, g_GoldType.invite_match_gold, -1, 1);
					  			end
					  			--fajiang_flag=1;
					      		send_result(userinfo,i,match_type)
					    end
					end
					
					--更新领奖信息,如果是有名次的，就更新他的领奖时间，如果是没名次的，就直接清0
					sql="update t_invite_pm set get_reward_time=now() where user_id=%d and match_type=%d;commit;";
					sql=string.format(sql,userinfo.userId,match_type)
					dblib.execute(sql)
				end
		end)  
	end
 
	--发业余场的奖 
	--fajiang(userinfo,1,10000,2000,1000,500,500);
	
	--发职业场的奖
	--fajiang(userinfo,2,80000,20000,10000,2000,2000);
	fajiang(userinfo,2,200000,100000,50000,10000,10000);
	
	--发专家场的奖
	--fajiang(userinfo,3,1880000,100000,50000,20000,20000);
	fajiang(userinfo,3,1000000,200000,100000,50000,50000);
	
end

--请求活动时间状态
function tex_match.on_recv_activity_stat(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	--0，活动无效，不显示相关UI；2，活动有效，比赛阶段
	local check_stat = check_datetime()
	
	
	local endtime = timelib.db_to_lua_time(tex_match.endtime);
	local ranktime =  timelib.db_to_lua_time(tex_match.rank_endtime);
	local sys_time = os.time();
	if(sys_time > endtime) then
		check_stat = 5 --整个活动结束后，排行榜图标保留1天后消失。
	end
	
	if(sys_time > ranktime) then
		check_stat = 0 --整个活动结束
	end
	--TraceError("--请求活动时间状态-->>"..check_stat)
	
	netlib.send(function(buf)
		    buf:writeString("INVITEPHDATE")
		    buf:writeByte(check_stat)		    
	        end,user_info.ip,user_info.port)   
end

--请求报名比赛
function tex_match.on_recv_sign(buf)
	--TraceError("--请求报名比赛")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	--报名哪一个场： 2，职业场；3，专家场	
	local sign = buf:readByte()
	
	--1，报名成功；2，报名失败，不够资格证；3，活动过期；4，其它异常情况
	local sign_ruslt = 0
	
	--查询资格证数量
	local shiptickets_count = user_info.propslist[7]
    
	if(sign == 2)then	--2，职业场
		if(check_datetime() == 0)then	--判断活动有效性
			sign_ruslt = 3
			--TraceError("--职业场 报名错误    3")
		elseif(shiptickets_count < 2)then	--判断报名资格
			sign_ruslt = 2
	 		--TraceError("-- 职业场 报名错误   2")
		
		else--报名成功，需扣除资格证数量
			sign_ruslt = 1
			tex_match.sign_succes(user_info, 2, sign)
		end
		
	elseif(sign == 3)then	--3，专家场
		if(check_datetime() == 0)then	--判断活动有效性
			sign_ruslt = 3
			--TraceError("--专家场 报名错误    3")
		elseif(shiptickets_count < 5)then	--判断报名资格
			sign_ruslt = 2
			--TraceError("--专家场 报名错误    2")
		
		else--报名成功，需扣除资格证数量
			sign_ruslt = 1
			tex_match.sign_succes(user_info, 5, sign)
		end
		
	else
		--TraceError("报名错误,传入sign->"..sign)
		return;
	end
		 
	netlib.send(function(buf)
		    buf:writeString("INVITESIGNUP")
		    buf:writeByte(sign_ruslt)		    
	        end,user_info.ip,user_info.port) 
end

--报名成功
function  tex_match.sign_succes(user_info, k_count, match_type)
	--TraceError("报名成功->>match_type:"..match_type.."k_count:"..k_count)
	--user_info.sign_ruslt记录    0：未报名        1：职业场        2：专家场          3：职业场和专家场
	
	local xie_sign = 0
	if(match_type == 2)then
		if(user_info.sign_ruslt == "0")then
			user_info.sign_ruslt = "1"
			xie_sign = 1
		elseif(user_info.sign_ruslt == "2")then
			user_info.sign_ruslt = "3"
 			xie_sign = 1
		end
	elseif(match_type == 3)then
		--TraceError("报名成功user_info.sign_ruslt->>"..user_info.sign_ruslt)
		if(user_info.sign_ruslt == "0")then
			user_info.sign_ruslt = "2"
			xie_sign = 2
		elseif(user_info.sign_ruslt == "1")then
			user_info.sign_ruslt = "3"
 			xie_sign = 2
		end
	end
	user_info.propslist[7] = user_info.propslist[7] - k_count
	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, -k_count, user_info)
	--TraceError("--报名成功，需扣除资格证数量"..k_count)
	
	--报名写数据库
	tex_match.inster_invite_db(user_info,0,match_type,xie_sign)
	
	--写日志	
	local sql = "INSERT INTO log_invite_baoming_info (userid,card_count,card_type,sys_time)	VALUES (%d,%d,%d,now());"
	sql=string.format(sql,user_info.userId,k_count,match_type);
	dblib.execute(sql)
end

--报名写数据库
function tex_match.inster_invite_db(user_info,match_gold,match_type, xie_sign)
	--TraceError("报名写数据库,sign->"..xie_sign)

		local sql="insert into t_invite_pm(user_id,nick_name,win_gold,match_type,baoming_time,sign) value(%d,'%s',%d,%d,now(),%d) ON DUPLICATE KEY UPDATE baoming_time=NOW()";
		sql=string.format(sql,user_info.userId,user_info.nick,match_gold,match_type,xie_sign);
		dblib.execute(sql)
		 

end	

--请求购买比赛券
function tex_match.on_recv_buy_ticket(buf)
	--TraceError("--请求购买比赛券")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	local gold = get_canuse_gold(user_info)		--获得用户筹码
	local ruslt = 0
	if(check_datetime() == 0)then	--判断活动有效性
		ruslt = 2
		--TraceError("--请求购买比赛券错误  活动已过期")
		
	elseif(gold < 20000)then	--判断筹码小于2万筹码
		ruslt = 0
	 	--TraceError("-- 请求购买比赛券错误  筹码小于2万筹码")
		
	else--报名成功，需扣除资格证数量
		--TraceError("发送购买比赛券结果,成功")
		ruslt = 1
 		--减2万筹码
	    usermgr.addgold(user_info.userId, -20000, 0, g_GoldType.baoxiang, -1);
	    
	    --加春节大赛参赛券 
  		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, 1, user_info)
  	
	end
 
 	--发送购买比赛券结果
	tex_match.send_buy_ticket_result(user_info, ruslt)
end
 
--发送购买比赛券结果
function tex_match.send_buy_ticket_result(user_info, ruslt)
	--TraceError("发送购买比赛券结果,userId:"..user_info.userId.." ruslt->"..ruslt)
	netlib.send(function(buf)
		    buf:writeString("INVITEBUYTK")
		    buf:writeByte(ruslt)		    
	        end,user_info.ip,user_info.port) 
end

--手机活动,邀请赛 end

--协议命令
cmd_tex_match_handler = 
{
	--擂台赛相关协议
	["TXJBSINFO"] = tex_match.on_recv_jbs_info,  --请求德州锦标赛信息
    ["TXJBSJOIN"] = tex_match.on_recv_jbs_baomin,  --请求报名
    ["TXJBSCANCEL"] = tex_match.on_recv_jbs_cancel,  --取消报名
    
    --邀请赛相关协议
    ["INVITEPHLIST"] = tex_match.on_recv_invite_ph_list,  --请求邀请赛的排行榜
    ["INVITEDJ"] = tex_match.on_recv_invite_dj,  --填写邀请赛的领奖结果
    ["INVITEBTN"] = tex_match.on_recv_refresh_timeinfo, --请求刷新图标按钮信息
    ["INVITEGIF"] = tex_match.on_recv_already_know_reward, --客户端通知已经点过领奖按钮了
    
    ["INVITEPHDATE"] = tex_match.on_recv_activity_stat, --请求活动时间状态
    ["INVITESIGNUP"] = tex_match.on_recv_sign, --请求报名比赛
    ["INVITEBUYTK"] = tex_match.on_recv_buy_ticket, --请求购买比赛券
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", tex_match.on_after_user_login);
eventmgr:addEventListener("timer_minute", tex_match.ontimecheck);