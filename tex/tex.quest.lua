
TraceError("init riddle_forgs....")
if not tex_dailytask_lib then
	tex_dailytask_lib = _S
	{
        checker_datevalid = NULL_FUNC,		--时间校验        
        on_game_over = NULL_FUNC,			--游戏结束牌型判断
        on_quan_change = NULL_FUNC,			--奖券变化通知
        onRecvDakaiZhuanpan = NULL_FUNC,	--收到打开转盘
        onRecvKaishiChoujiang = NULL_FUNC,	--开始抽奖
        get_vaild_paixin = NULL_FUNC,	--开始抽奖
        on_after_user_login = NULL_FUNC,	--登录后消息
        get_lottery_count = NULL_FUNC,	--获取奖券数量
        get_pai_xin = NULL_FUNC,	--获取牌型数量
        add_lottery_count = NULL_FUNC,	--减少奖券数量
        notify_lottery_change = NULL_FUNC,	--通知奖券数量变化
        do_notify_lottery_change=NULL_FUNC,--通知奖券数量变化
        find_friend_play=NULL_FUNC, --加过好友，并玩过多少局
        is_qianshan=NULL_FUNC, --比赛前三名
        get_tex_daren_count=NULL_FUNC, --成为德州每日达人几次
        get_daren_list=NULL_FUNC, --本月奖券达人排行 
        get_this_month_paiming=NULL_FUNC,  --本月奖券达人排名
        get_month_reward_count=NULL_FUNC, --本月获得奖券数
        all_task_down=NULL_FUNC, --所有任务都已完成
        set_mingci=NULL_FUNC,--设置当天比赛名次（只看是不是进入过前三名）
        get_mingci=NULL_FUNC,--得到当天比赛名次（只看是不是进入过前三名）
        give_kick_card=NULL_FUNC, --加踢人卡
        add_yesterday_questgold=NULL_FUNC,--给昨天的完成任务的人加钱
        get_already_used_today=NULL_FUNC, --今天用掉的奖卷数
        flash_paihang=NULL_FUNC,--刷新排行榜
        ontimer_flash_paihang=NULL_FUNC,--定时刷新排行榜
        OnTimeCheckQuest=NULL_FUNC,--定时刷新排行榜
        set_addfriend_status=NULL_FUNC,--最新一次加好友的时间
        update_user_playcount=NULL_FUNC,--更新玩家今天玩了多少盘
        get_last_monthday=NULL_FUNC,--得到现在距离月底有多少天
        init_memory_data=NULL_FUNC,  --初始化这个玩家的五道杠数据到内存中
        is_finish_all_pai_xin=NULL_FUNC, --是否打出所有牌型
        get_vaildroom_paixin=NULL_FUNC,--看不是满足房间的要求
        update_pai_xin=NULL_FUNC,--每日任务
        init=NULL_FUNC,--初始化
        fajiang_month=NULL_FUNC, --每月发奖
        is_init = false,
        common_gold=0,	--普通情况下要花1万块来抽奖
        daren_gold=0,	--有奖卷时只要花1千块来抽奖
	}
end

wdg_today_paihang={} --今天的最新排行100名
wdg_yestoday_paihang={} --昨天的排行100名
last_flash_paihang_day="" --最后一次刷新排行的时间
--定时刷新排行榜


--判断时间的合法性，现在不是活动了，改成每日任务了，所以不用判断时间了。
tex_dailytask_lib.checker_datevalid = function()
	--local starttime = os.time{year = 2011, month = 5, day = 19,hour = 10};
	--local endtime = os.time{year = 2011, month = 5, day = 26,hour = 0};
	--local sys_time = os.time()
    --if(sys_time < starttime or sys_time > endtime) then
    --    return false
	--end
    return true
end

function tex_dailytask_lib.h2_after_user_login(e)
    local user_info = e.data.userinfo
    tex_dailytask_lib.on_after_user_login(user_info, viplib.get_vip_level(user_info))
end

--用户登录后事件
tex_dailytask_lib.on_after_user_login = function(userinfo, viplevel, call_back)

    if (userinfo.wdg_huodong == nil) then
        userinfo.wdg_huodong = {}
        userinfo.wdg_huodong.lottery_count = 0
        userinfo.wdg_huodong.pai_xin = 0
		userinfo.wdg_huodong.pan_shu = 0
        userinfo.wdg_huodong.today_used_count=0 --今天用了多少奖卷
        userinfo.wdg_huodong.lottery_all_count=0 --所有的奖卷
        userinfo.wdg_huodong.this_month_paiming=0  --本月排名
        userinfo.wdg_huodong.daren_count=0  --成为达人的次数
        userinfo.wdg_huodong.last_login = os.time()
    end
    --初化化用得到的五道杠数据
    tex_dailytask_lib.init_memory_data(userinfo)
    
    local sql = "call sp_huodong_wdg_init_user_lottery_info(%d, %d)"    
    sql = string.format(sql, userinfo.userId, viplevel)
   
    dblib.execute(sql, 
         function(dt)
            if (dt and #dt > 0) then
                if (userinfo.wdg_huodong == nil) then
                    userinfo.wdg_huodong = {}
                end
                userinfo.wdg_huodong.lottery_count = dt[1]["lottery_count"]
                userinfo.wdg_huodong.pai_xin = dt[1]["pai_xin"]
                userinfo.wdg_huodong.today_used_count = dt[1]["today_used_count"]
                userinfo.wdg_huodong.lottery_all_count = dt[1]["lottery_all_count"]
                userinfo.wdg_huodong.daren_count = dt[1]["daren_count"]
                userinfo.wdg_huodong.pan_shu = dt[1]["pan_shu"]
                userinfo.wdg_huodong.yesterday_pai_xin = dt[1]["yesterday_pai_xin"]
                userinfo.wdg_huodong.add_friend_time = timelib.db_to_lua_time(dt[1]["add_friend_time"])

                if(viplib.get_vip_level(userinfo)>0)then
                    tex_dailytask_lib.update_pai_xin(userinfo,512)
                end
                --tex_dailytask_lib.do_notify_lottery_change(userinfo)
                --tex_dailytask_lib.fuck_clear_error(userinfo)
            end
            if (call_back ~= nil) then
                call_back()
            end
         end)
end

--如果清数据出错，就把玩家的奖卷数变成最多的那种可能
-- [[
tex_dailytask_lib.fuck_clear_error = function(userinfo)
	local table_time = os.date("*t", os.time())
	local now_day = table_time.day
	local most_lottery = now_day * 11 --到这天为止最多可以有的奖卷
	if userinfo.wdg_huodong.lottery_all_count > most_lottery then
		userinfo.wdg_huodong.lottery_all_count = most_lottery
		local sql = "update user_huodong_wdg_info set lottery_all_count = %d where user_id = %d"
		sql = string.format(sql, most_lottery, userinfo.userId)
		dblib.execute(sql, function(dt) end, userinfo.userId)
	end
end
--]]
--获取奖券数量
tex_dailytask_lib.get_lottery_count = function(userinfo)
    if (userinfo.wdg_huodong ~= nil and userinfo.wdg_huodong.lottery_count ~= nil) then
        return userinfo.wdg_huodong.lottery_count
    else
        --TraceError("没有获取奖券")
        return 0
    end
end

--获取牌型
tex_dailytask_lib.get_pai_xin = function(userinfo)
    if (userinfo.wdg_huodong ~= nil and userinfo.wdg_huodong.pai_xin ~= nil) then
        return userinfo.wdg_huodong.pai_xin
    else
        --TraceError("没有牌型")
        return 0
    end
end

--修改奖券数量,1表示成功，0表示失败
tex_dailytask_lib.add_lottery_count = function(userinfo, count)
 
    --TraceError(debug.traceback())
    if (userinfo.wdg_huodong.lottery_count + count >= 0) then
        userinfo.wdg_huodong.lottery_count = userinfo.wdg_huodong.lottery_count + count
    else
        --TraceError("奖券数量要变成负数了，怎么减少啊？")
        return 0
    end
    local sql = "update user_huodong_wdg_info set lottery_all_count = lottery_all_count + %d, lottery_count = lottery_count + %d,today_used_count=today_used_count + abs(%d) where user_id = %d and lottery_count >= 0;insert log_wdg_lottery(user_id, reason, sys_time, count) values(%d, %d, now(), %d);commit;"
    sql = string.format(sql, count < 0 and 0 or 1, count, count < 0 and 1 or 0, userinfo.userId, userinfo.userId, (count > 0 and 2 or 3), count);
 
    dblib.execute(sql, function() end, userinfo.userId)
   -- if (userinfo.wdg_huodong.lottery_count == 0) then
    --    tex_dailytask_lib.do_notify_lottery_change(userinfo)
  --  end
    --用了一张，本月数量不变，今日使用加1，增加一张，本月数量加1，今日使用不变
    userinfo.wdg_huodong.today_used_count=userinfo.wdg_huodong.today_used_count+ (count < 0 and 1 or 0)
    userinfo.wdg_huodong.lottery_all_count=userinfo.wdg_huodong.lottery_all_count+(count < 0 and 0 or 1)
    return 1
end

function tex_dailytask_lib.pay_gold(user_info, gold)
    local retcode = 0;
    if(user_info.desk and user_info.site) then
        local deskdata = deskmgr.getdeskdata(user_info.desk);
        local sitedata = deskmgr.getsitedata(user_info.desk, user_info.site);
        retcode = dobuygift1(user_info, deskdata, sitedata, 0, gold);
        --购买成功
    else
        retcode = dobuygift2(user_info, 0, gold)
    end
    return retcode;
end

function tex_dailytask_lib.onRecvKaishiChoujiang(buf)
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    local advUser = {}    
	local spend_gold = tex_dailytask_lib.daren_gold; --花费的钱

	local userdata = deskmgr.getuserdata(userinfo)
 
	local giftinfo = userdata.giftinfo 
	local giftcount = 0
	for k, item in pairs(giftinfo) do
		giftcount = giftcount + 1
	end

    if giftcount >= 100 then
        netlib.send(
    		function(buf)
    			buf:writeString("TXSTIPS")
    			buf:writeByte(1)	--结果，byte (1, 提示背包已满；2，获奖者在次月首次登录会弹出恭喜对话框)
                buf:writeByte(0)    --名次为0，不作更新（为了与月度大奖兼容作出的处理）
    		end, userinfo.ip, userinfo.port)
        return
    end

    local ret = tex_dailytask_lib.add_lottery_count(userinfo, -1)
    
    --奖券不够,就要花1万块，不然就只要1千块
    if(ret==0) then 
    	spend_gold = tex_dailytask_lib.common_gold
    else
    	spend_gold = tex_dailytask_lib.daren_gold
    end

    --身上连1千块都没有
    local result = 1
    --如果配置成不用钱抽奖，那么奖卷不够就不能抽奖了。
	if spend_gold ~= 0 then
    	result = tex_dailytask_lib.pay_gold(userinfo, spend_gold);
    elseif ret == 0 then
    	result = 0
    end
    if (result ~= 1) then
        if(ret == 0) then
            --TraceError("奖券不够了，无法抽奖")
            local alreaddy_used_today = tex_dailytask_lib.get_already_used_today(userinfo)
            netlib.send(
                function(buf)
                    buf:writeString("TXKSCJ")
                    buf:writeInt(0)  
                    buf:writeInt(-3)  --通知客户端奖券不够
                    buf:writeInt(alreaddy_used_today or 0)--用了几张奖卷
                end,userinfo.ip,userinfo.port)
        else
            --奖卷够了，但是钱不够
            tex_dailytask_lib.add_lottery_count(userinfo, 1);
        	netlib.send(
                    function(buf)
                        buf:writeString("TXSTIPS")
                        buf:writeByte(3)  
                        buf:writeInt(0) 
                    end,userinfo.ip,userinfo.port)
            end
        return  
    end

    local isAdvUser = 0
    if (advUser[userinfo.userId] ~= nil) then
        isAdvUser = 1
    end
    local sql = "call sp_huodong_wdg_get_random_gift(%d, %d)"
    sql = string.format(sql, userinfo.userId, isAdvUser)
   
    dblib.execute(sql, 
         function(dt)
             if (dt and #dt > 0) then
                local jiangpin = dt[1]["gift_id"]
                local desc = ""

                 
    --奖品id对应表
    --1：德州扑克大师套装
    --5005：黑宝石
    --3：小经验药水
    --4：大经验药水
    --5;  筹码
    --6; 踢人卡
    --5007：五道杠
    --5008：三道杠
    --5009：二道杠
    --5010：一道杠

    -----------------------------------------
	--TraceError("dddddddddddddddddd:"..jiangpin)
    if jiangpin == 1 then
        --desc = "德州扑克大师套装一套"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_1");
    elseif jiangpin == 5005 then
        --desc = "黑宝石一枚"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_5005");
    elseif jiangpin == 5007 then
        --desc = "霸气五道杠"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_5007");
    elseif jiangpin == 5008 then
        --desc = "霸气三道杠"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_5008");
    elseif jiangpin == 5009 then
        --desc = "霸气二道杠"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_5009");
    elseif jiangpin == 5010 then
        --desc = "霸气一道杠"
        desc = tex_lan.get_msg(userinfo, "quest_desc_jiangpin_5010");
    end

                --获得非药水奖品后全局广播
                 if jiangpin == 1 or jiangpin > 5000 then
                    --local msg = "恭喜玩家"..userinfo.nick.."在霸气转盘中抽中限量"..desc
		            --local msg = _U("恭喜玩家").._U(userinfo.nick).._U("在霸气转盘中抽中限量").._U(desc)
		            local msg = _U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin")).._U(userinfo.nick).._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_2")).._U(desc)
                    --msg = _U(msg)
                    
                    
                 end
                   --筹码1288改成送天津大发面的
                  --if jiangpin == 5043 then
                  --	car_match_db_lib.add_car(userinfo.userId, 5043, 0);
                    --usermgr.addgold(userinfo.userId, 1288, 0, g_GoldType.quest_wdg_jiangping, -1, 1);
                  --end
				
                --踢人卡
                  if jiangpin == 6 then
                      if(tex_gamepropslib)then
                          tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, userinfo)
                      end
                  end
              
               --小喇叭
                if jiangpin == 4 then
                      if(tex_gamepropslib)then
                      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, userinfo)
                      end
                  end
                  
                --药水奖品
                if jiangpin == 3  then
                    local exp = 10
              	    usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), exp, g_ExpType.wdg_huodong, groupinfo.groupid)
                end

                --加入背包
                if jiangpin ~= 3 and jiangpin~=4 and jiangpin~=5 and jiangpin~=6  then
                    gift_addgiftitem(userinfo,jiangpin,userinfo.userId,userinfo.nick, false)                        
                end

                --抽中贵重礼物发全服广播
                if(jiangpin==5011)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值88W的礼物:奥迪A8"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5011")),0)
                end

                if(jiangpin==5012)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值28W的礼物:甲壳虫"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5012")),0)
                end

                if(jiangpin==5013)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值8888的礼物:奥拓"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5013")),0)
                end
                
                if(jiangpin==5020)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值28W的礼物:LV包"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5020")),0)
                end
                
                if(jiangpin==5021)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值138W的礼物:玛莎"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5021")),0)
                end
                
                if(jiangpin==5001)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值10000的礼物:蓝宝石"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5001")),0)
                end
                
                if(jiangpin==5022)then
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("抽中了价值20000的礼物:QQ车"),0)
                    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_jiangpin_5022")),0)
                end
                


				--扣玩家抽奖的钱
				--usermgr.addgold(userinfo.userId, -spend_gold, 0, g_GoldType.quest_wdg_choujiang, -1, 1);
				
                --通知获奖结果
                --TraceError("通知抽奖结果，id="..jiangpin)
                local already_used_today=tex_dailytask_lib.get_already_used_today(userinfo)
            	netlib.send(
                function(buf)
                    buf:writeString("TXKSCJ")
                    buf:writeInt(userinfo.wdg_huodong.lottery_count)  
                    buf:writeInt(jiangpin)  --奖卷编号
                    buf:writeInt(already_used_today or 0)--用了几张奖卷
                end,userinfo.ip,userinfo.port)
             end
         end)
	
	

    --以下为纯测试代码
    --[[
    local userid = userinfo.userId
    local desc = ""
    local exp = 0
    local giftid = 0
    if userid == 201 then
        jiangpin = 1
        desc = "德州扑克大师套装一套"
    elseif userid == 202 then
        jiangpin = 2
        desc = "黑宝石一枚"
        giftid = 5005
    elseif userid == 203 then
        jiangpin = 3
        exp = 50
    elseif userid == 204 then
        jiangpin = 4
        exp = 100
    elseif userid == 205 then
        jiangpin = 5
        desc = "霸气五道杠"
        giftid = 5007
    elseif userid == 206 then
        jiangpin = 6
        desc = "霸气四道杠"
    elseif userid == 207 then
        jiangpin = 7
        desc = "霸气三道杠"
        giftid = 5008
    elseif userid == 208 then
        jiangpin = 8
        desc = "霸气二道杠"
        giftid = 5009
    elseif userid == 209 then
        jiangpin = 9
        desc = "霸气一道杠"
        giftid = 5010
    end
--]]
end

--每个月给上个月完成任务的玩家发奖
function tex_dailytask_lib.fajiang_month(userinfo)
    --如果背包满了，就不发奖，等他先清背包
    local userdata = deskmgr.getuserdata(userinfo)
    local giftinfo = userdata.giftinfo 
    local giftcount = 0
	for k, item in pairs(giftinfo) do
		giftcount = giftcount + 1
	end

    if giftcount >= 100 then
       netlib.send(
    		function(buf)
    			buf:writeString("TXSTIPS")
    			buf:writeByte(1)	--结果，byte (1, 提示背包已满；2，获奖者在次月首次登录会弹出恭喜对话框)
                buf:writeByte(0)    --名次为0，不作更新
    		end, userinfo.ip, userinfo.port)
        return
    end
    
    --得到玩家的名次，要没领过奖的
    local sql="select mc from pm_month where  left(sys_time,7)=left(DATE_SUB(NOW(), INTERVAL 1 MONTH),7) and ifnull(award_flag,0)=0 and user_id=%d;update pm_month set award_flag=1,award_time=now() where left(sys_time,7)=left(DATE_SUB(NOW(), INTERVAL 1 MONTH),7) and user_id=%d and ifnull(award_flag,0)=0;commit;"
    dblib.execute(string.format(sql,userinfo.userId,userinfo.userId),
    		function(dt)
                if(dt and #dt > 0) then
                    local mc=tonumber(dt[1].mc)

                    --5017奔驰S600,5018雪铁龙C2,5019夏利,5012甲壳虫
                    if(mc==1)then
                        gift_addgiftitem(userinfo,5017,userinfo.userId,userinfo.nick, false) 
                        
                    elseif(mc==2)then
                        gift_addgiftitem(userinfo,5012,userinfo.userId,userinfo.nick, false) 
                        
                    elseif(mc==3)then
                        gift_addgiftitem(userinfo,5018,userinfo.userId,userinfo.nick, false)
                    elseif(mc>=4 and mc<=10)then
                        gift_addgiftitem(userinfo,5019,userinfo.userId,userinfo.nick, false)
                        
                    end

                    netlib.send(
                    		function(buf)
                    			buf:writeString("TXSTIPS")
                    			buf:writeByte(2)	--结果，byte (1, 提示背包已满；2，获奖者在次月首次登录会弹出恭喜对话框)
                                buf:writeByte(mc)    --名次为0，不作更新
                    		end, userinfo.ip, userinfo.port)
                    --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("获得了月度达人大奖第"..tostring(mc).."名"),0)
                end
    		end);
end

function tex_dailytask_lib.onRecvDakaiZhuanpan(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end;
    tex_dailytask_lib.check_fresh_info(userinfo, function()
        local lottery_count = tex_dailytask_lib.get_lottery_count(userinfo)
        local pai_xin = tex_dailytask_lib.get_pai_xin(userinfo)
       
    
    
        -- 本月获得奖券数
        local month_reward_count=tex_dailytask_lib.get_month_reward_count(userinfo)
        
        -- 本月奖券达人排名
        local prev_month_paiming=tex_dailytask_lib.get_this_month_paiming(userinfo)
    
        --成为德州每日达人几次
        local tex_daren_count=tex_dailytask_lib.get_tex_daren_count(userinfo)
    
        --6). 本月奖券达人排行 
    		--	i. 昵称，string
    		--	ii. 奖券数，int
    		--	iii. 奖品，string
    		--	iv. 升降，int
        local tex_daren_list=tex_dailytask_lib.get_daren_list(userinfo)
    
        local daren_list_len=0
        if(tex_daren_list==nil)then
            daren_list_len=0
        elseif(#tex_daren_list>10)then
            daren_list_len=10
        else
            daren_list_len=#tex_daren_list
        end
    
        local already_used_today=tex_dailytask_lib.get_already_used_today(userinfo)
        local how_many_days=tex_dailytask_lib.get_last_monthday()--还差几天到月底
    
        netlib.send(
                function(buf)
                    buf:writeString("TXDKZP")
                    buf:writeInt(lottery_count)  --奖卷数
                    buf:writeInt(pai_xin) --任务完成度
                    buf:writeInt(already_used_today)--今天用了几张奖卷
                    buf:writeInt(how_many_days or 0)--还差几天到月底
                    buf:writeInt(month_reward_count)--本月获得奖券数
                    buf:writeInt(prev_month_paiming)--上月奖券达人排名
                    buf:writeInt(tex_daren_count)--成为德州每日达人几次
                    buf:writeByte(daren_list_len)
                    for i=1,daren_list_len do
                        if(tex_daren_list[i]~=nil)then
                            local v=tex_daren_list[i]
                            buf:writeString(v.nick_name or "")
                            buf:writeInt(v.reward_count or 0)
                            buf:writeInt(v.up_or_down or 4)
                        else
                            buf:writeString("")
                            buf:writeInt(0)
                            buf:writeInt(4)
                        end
                    end
                end,userinfo.ip,userinfo.port)
    
         --发月度大奖
        tex_dailytask_lib.fajiang_month(userinfo)
    end)
end

--:通知客户端奖券变化通知
function tex_dailytask_lib.notify_lottery_change(buf)
  
    local userinfo = userlist[getuserid(buf)]; 
    tex_dailytask_lib.do_notify_lottery_change(userinfo)

end

--:通知客户端奖券变化通知
function tex_dailytask_lib.do_notify_lottery_change(userinfo)
  
	if not userinfo then return end;
    if not userinfo.wdg_huodong then return end;

    --通知客户端奖卷数量变化
    netlib.send(
            function(buf)
                buf:writeString("TXJJBH")
                buf:writeInt(userinfo.wdg_huodong.lottery_count or 0)  --奖卷数量
            end,userinfo.ip,userinfo.port)
end


--判断牌型 返回1，合法牌型，非法牌型-1
--10(皇家同花顺)，9(同花顺)，8(四条)，7(葫芦)，6(同花)，5(顺子)，4(三条)，3(两对)，2(一对)，1(高牌)
--邀请好友玩10局（改成：本日有邀请过好友，并玩过10局游戏）：128
--比赛前三名：256
--VIP登陆：512
--一对：1024
--因为需求变更，不仅仅传递牌型了，还要传一些额外的信息，但为了与原来的程序兼容，所以方法名称不改
function tex_dailytask_lib.get_vaild_paixin(pai_xin)
    if (pai_xin == 10 or pai_xin == 9) then
        pai_xin = 64
    elseif (pai_xin == 8) then
        pai_xin = 32
    elseif (pai_xin == 7) then
        pai_xin = 16
    elseif (pai_xin == 6) then
        pai_xin = 8
    elseif (pai_xin == 5) then
        pai_xin = 4
    elseif (pai_xin == 4) then
        pai_xin = 2
    elseif (pai_xin == 3) then
        pai_xin = 1
    elseif(pai_xin==2)then
        pai_xin = 1024
    elseif(pai_xin==512)then
        pai_xin=512
    elseif(pai_xin==256)then
        pai_xin=256
    elseif(pai_xin==128)then
        pai_xin=128
    else
        pai_xin = 0
    end
    return pai_xin
end

--看看是不是满足相关赔率房间的
function tex_dailytask_lib.get_vaildroom_paixin(pai_xin,smallbet)
    --一对要在专家场，小于1000，就不在专家场
    if(pai_xin==1024 and smallbet<1000)then 
        pai_xin=0
    end

    --2对要在专家场,小于1000，就不在专家场
    if(pai_xin==1 and smallbet<1000)then 
        pai_xin=0
    end


    --3张获胜要在专家场,小于1000，就不在专家场
    if(pai_xin==2 and smallbet<1000)then 
        pai_xin=0
    end

    --顺子获胜要在专家场、职业场
    if(pai_xin==4 and smallbet<100)then 
        pai_xin=0
    end

    --同花获胜要在专家场、职业场
    if(pai_xin==8 and smallbet<100)then 
        pai_xin=0
    end

    --葫芦获胜要在专家场、职业场
    if(pai_xin==16 and smallbet<100)then 
        pai_xin=0
    end

    --同花顺获胜要在专家场、职业场
    if(pai_xin==64 and smallbet<100)then 
        pai_xin=0
    end

     --四条获胜要在专家场、职业场
    if(pai_xin==32 and smallbet<100)then 
        pai_xin=0
    end

    return pai_xin
end

--是否打出所有paixin,1打出来了，0没打出
function tex_dailytask_lib.is_finish_all_pai_xin(pai_xin)
    --所有牌型列出来，不直接算出加后的结果值，以防止以后万一要删除一种牌型时做修改
    if(pai_xin==(1+2+4+8+16+32+64+128+256+512+1024))then
        return 1
    end
    return 0
end

--id = bit：or(oldid，newid )
--判断牌型
tex_dailytask_lib.on_game_over = function(userinfo, pai_xin, deskno,gold)    
    if(tasklib.is_finish_task(userinfo) == 0) then
        return;
    end

    local deskinfo = desklist[deskno];

    if(deskinfo.desktype == g_DeskType.match) then
        return;
    end

    --更新今天玩牌的次数，之后在发奖时要用（玩10盘并加过好友的判断时用得上）
    tex_dailytask_lib.update_user_playcount(userinfo,1)

    --邀请好友玩10局（改成：本日有邀请过好友，并玩过10局游戏）：128
    if(tex_dailytask_lib.find_friend_play(userinfo,10)==1)then
        tex_dailytask_lib.update_pai_xin(userinfo,128)
    end

    --比赛前三名：256，改成放在设置时直接更新牌型
    --if(tex_dailytask_lib.is_qianshan(userinfo)==1)then
    --    tex_dailytask_lib.update_pai_xin(userinfo,256)
    --end

    --必须赢钱的人才算完成任务
    if(gold>0)then
        tex_dailytask_lib.update_pai_xin(userinfo,pai_xin)
    end
end

function tex_dailytask_lib.check_fresh_info(userinfo, call_back)
    --如果是第二天了，就刷新排行榜吧
    if (userinfo.wdg_huodong.last_login == nil) then
        userinfo.wdg_huodong.last_login = os.time()
    end
    local cur_time = os.date("*t",os.time())
    local cur_day  = tonumber(cur_time.day)
    local org_time = os.date("*t", userinfo.wdg_huodong.last_login)
    local org_day = tonumber(org_time.day)
    if (cur_day ~= org_day) then
        userinfo.wdg_huodong.last_login = os.time()
        tex_dailytask_lib.on_after_user_login(userinfo, viplib.get_vip_level(userinfo), call_back)
    else
        call_back()
    end
end

function tex_dailytask_lib.update_pai_xin(userinfo, pai_xin)
    local smallbet =0
    if(userinfo.desk~=nil)then
    	local deskinfo = desklist[userinfo.desk]
    	smallbet = deskinfo.smallbet
    end
    pai_xin=tex_dailytask_lib.get_vaild_paixin(pai_xin)
    pai_xin=tex_dailytask_lib.get_vaildroom_paixin(pai_xin,smallbet)

    tex_dailytask_lib.check_fresh_info(userinfo, function()
        if (pai_xin > 0) then
            --已经打出过此种牌型了，不用给奖券
            if (bit_mgr:_and(userinfo.wdg_huodong.pai_xin, pai_xin) == 0) then
                userinfo.wdg_huodong.pai_xin = bit_mgr:_or(userinfo.wdg_huodong.pai_xin, pai_xin)
                local sql = "update user_huodong_wdg_info set pai_xin = %d,sys_time=now() where user_id = %d;insert into log_user_task_info(user_id,getlottery_reason,sys_time) value(%d,%d,now()) ;commit;"
                sql = string.format(sql, userinfo.wdg_huodong.pai_xin, userinfo.userId,userinfo.userId,pai_xin)
               
                dblib.execute(sql, function()end, userinfo.userId);
                tex_dailytask_lib.add_lottery_count(userinfo, 1)
                tex_dailytask_lib.do_notify_lottery_change(userinfo)
                --完成了一种任务时，要看看是不是要触发所有任务完成的情况
                tex_dailytask_lib.all_task_down(userinfo)
                eventmgr:dispatchEvent(Event("update_quest_event", {userinfo = userinfo}))
            end
        end
    end)
end
--服务端，玩家完成全部任务
function tex_dailytask_lib.all_task_down(userinfo)
    --local how_many_task=11 --有多少种每日任务，现在是11种，记得变量方便以后改
    --local all_task_countnum --如果所有任务完成，应该总和是多少
    --local alltask_num = userinfo.wdg_huodong.pai_xin
    
    --得到所有任务完成时任务总和数
    --for i=1,how_many_task do all_task_countnum =all_task_countnum+ 2^i end
    
    if(tex_dailytask_lib.is_finish_all_pai_xin(userinfo.wdg_huodong.pai_xin) == 1)then --所有的任务都完成了
        
        --给玩家加88888的奖历
        usermgr.addgold(userinfo.userId, 88888, 0, g_GoldType.quest_wdg_alltastkdown, -1, 1);
        netlib.send(
                function(buf)
                    buf:writeString("TXWCAL")                    
                end,userinfo.ip,userinfo.port)
        
        --发全服广播
        --BroadcastMsg(_U("恭喜玩家")..userinfo.nick.._U("完成了每日任务，获得88888奖励。"),0)
        BroadcastMsg(_U(tex_lan.get_msg(userinfo, "quest_msg_task"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "quest_msg_task_1")),0)
        
        --更新一下数据库，达人数+1
        local sql="update user_huodong_wdg_info set daren_count=daren_count+1 where user_id=%d"
        sql=string.format(sql,userinfo.userId)
      
        dblib.execute(sql,function() end, userinfo.userId) 
        
        --更新内存中的数量
        userinfo.wdg_huodong.daren_count=userinfo.wdg_huodong.daren_count+1
        
        --把达人标志加入背包
        gift_addgiftitem(userinfo,9008,userinfo.userId,userinfo.nick, false)
    end
    
end


-- 本月获得奖券数
function tex_dailytask_lib.get_month_reward_count(userinfo)
	if(userinfo.wdg_huodong==nil)then
		userinfo.wdg_huodong={}
		userinfo.wdg_huodong.lottery_all_count=0
	end
    local lottery_all_count=userinfo.wdg_huodong.lottery_all_count or 0
    return lottery_all_count
end

-- 本月奖券达人排名
function tex_dailytask_lib.get_this_month_paiming(userinfo)
	local mingci = -1
	if(userinfo.wdg_huodong==nil or userinfo.wdg_huodong.this_month_paiming==nil)then
		mingci=-1
	else
		 mingci = userinfo.wdg_huodong.this_month_paiming
	end
    return mingci
end

--成为德州每日达人几次
function tex_dailytask_lib.get_tex_daren_count(userinfo)
    return userinfo.wdg_huodong.daren_count or 0;
end

--
function tex_dailytask_lib.flash_paihang()
    --今天没刷新过的话，就刷新，不然就不刷新
    local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
    if(last_flash_paihang_day == nil or last_flash_paihang_day==sys_today)then
        return -1
    end

    --刷新
    wdg_today_paihang={}

    local sql="select nick_name,lottery_count as reward_count,mc,mcsj from pm_today"
   
     dblib.execute(sql,function(dt)
	     	if dt and #dt>0 then
		        for i=1,#dt do               
		            	 local bufftable ={
		                    nick_name = dt[i].nick_name, 
		                    reward_count = tonumber(dt[i].reward_count),
		                    mingci=tonumber(dt[i].mc),
		                    up_or_down = tonumber(dt[i].mcsj), 
		                }
		                
		            table.insert(wdg_today_paihang, bufftable)
		        end
		    end
        end)
    last_flash_paihang_day=sys_today
    return 1 --刷新成功
end

tex_dailytask_lib.ontimer_flash_paihang = function(e)
   
    tex_dailytask_lib.OnTimeCheckQuest(e.data.min)
end

--定时检查，任务相关内容
tex_dailytask_lib.OnTimeCheckQuest = function(min) 

    local tableTime = os.date("*t",os.time())
    local nowHour  = tonumber(tableTime.hour)
   --[[
    --执行0点钟定时任务，12点之后还在线的玩家，就刷新他们的排行。
    if(nowHour == 0 and (min == 0 or min==1)) then
        --12点让用户刷新一下信息
        for k, v in pairs(userlist) do
            --local userinfo=userlist
            tex_dailytask_lib.on_after_user_login(v,viplib.get_vip_level(v))
        end

    end
    --]]
    --每天3点之前，每个小时的前10分钟都会进行刷新，防止没刷新到，因为这个刷新只会执行一次，所以不用担心会有性能问题。
    if(nowHour < 3 and (min >= 0 and min<=5)) then
       --定时刷新每日任务排行
        tex_dailytask_lib.flash_paihang()
    end
end
--本月奖券达人排行 
function tex_dailytask_lib.get_daren_list(userinfo)
    --6). 本月奖券达人排行 
	--	i. 昵称，string  nick_name
	--	ii. 奖券数，int  reward_count
	--	iv. 升降，int  up_or_down
    --如果排行是空的，就刷新一下，防止中途有重启
    if(wdg_today_paihang==nil or #wdg_today_paihang==0)then
        tex_dailytask_lib.flash_paihang()
    end
    
    return wdg_today_paihang
end


--玩过playGameCount局的判断，如果加过好友，并玩过10局就返回1，否则返回0
function tex_dailytask_lib.find_friend_play(userinfo,pan_shu)
    --如果今天没加过好友，直接返回
    local add_friend_time=userinfo.wdg_huodong.add_friend_time
    if(add_friend_time==nil or os.date("%Y-%m-%d", add_friend_time) ~= os.date("%Y-%m-%d", os.time()))then
      return 0  
    end

    --超过playGameCount,10盘了
    if(userinfo.wdg_huodong.pan_shu>=pan_shu)then
      return 1
    end
    --今天没玩够10盘
    return  0
end

--得到比赛名次
function tex_dailytask_lib.get_mingci(user_info)
    return user_info.quest_mingci or 9999999
end

--设置比赛名次
function tex_dailytask_lib.set_mingci(user_info,mingci)
    user_info.quest_mingci=mingci
    if(mingci==1)then
        tex_dailytask_lib.update_pai_xin(user_info,256)
    end
end

--是不是前三名----->调整为第一名才算完成
function tex_dailytask_lib.is_qianshan(user_info)
    local deskinfo = desklist[user_info.desk]
    if(deskinfo==nil or (deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament))then
        return 0
    end
    if(tex_dailytask_lib.get_mingci(user_info)==1)then
        return 1
    end
    return 0
end

--设置最新的一次成功加过好友的时间
function tex_dailytask_lib.set_addfriend_status(userinfo)
    userinfo.wdg_huodong.add_friend_time = os.time()
    local sql = "update user_huodong_wdg_info set add_friend_time = '%s' where user_id=%d"
    sql = string.format(sql, timelib.lua_to_db_time(userinfo.wdg_huodong.add_friend_time), userinfo.userId)
  
    dblib.execute(sql)
end

--更新玩家今天玩了多少盘
function tex_dailytask_lib.update_user_playcount(userinfo,playGameCount)
    if(userinfo.wdg_huodong==nil or userinfo.wdg_huodong.pan_shu==nil)then
	userinfo.wdg_huodong={}
	userinfo.wdg_huodong.pan_shu=0
    end
    userinfo.wdg_huodong.pan_shu = userinfo.wdg_huodong.pan_shu + 1
    local sql = "update user_huodong_wdg_info set pan_shu = pan_shu + 1 where user_id=%d"
    sql = string.format(sql, userinfo.userId)
   
    dblib.execute(sql)
end

--给昨天的完成任务的人加钱
--i=1两对，i=2三条，i=3顺子，i=4同花，i=5葫芦，i=6四条，i=7同花顺或皇家同花顺,i=8邀请好友玩10局，i=9比赛前三名,i=10VIP登陆,i=11一对
function tex_dailytask_lib.add_yesterday_questgold(userinfo)
    --得到昨天完成任务的牌型
    if userinfo==nil then return 0 end;
    if userinfo.wdg_huodong==nil then return 0 end;
    if userinfo.wdg_huodong.yesterday_pai_xin==nil then
    	userinfo.wdg_huodong.yesterday_pai_xin=0
    end
    local yesterday_pai_xin = userinfo.wdg_huodong.yesterday_pai_xin;
    local add_gold=0
    local how_many_task=11  --总共有多少种任务
    if(yesterday_pai_xin==0)then
    	return 0;
    end
    for i=1,how_many_task do 
        if (bit_mgr:_and(yesterday_pai_xin, 2^(i-1) ) >0) then
            if(i==8)then
                add_gold = add_gold + 188
            elseif(i==9)then
                    add_gold = add_gold + 288
            elseif(i==1 or i==2 or i==3 or i== 4 or i==5 or i==11)then
                add_gold = add_gold + 388
            elseif(i==6)then
                add_gold = add_gold + 1888
            elseif(i==7)then
                add_gold = add_gold + 8888
            end
        end
    end

    userinfo.wdg_huodong.yesterday_pai_xin = 0

    local sql = "update user_huodong_wdg_info set yesterday_pai_xin = 0 where user_id = %d;commit;"
    sql = string.format(sql, userinfo.userId)
  
    dblib.execute(sql)
    usermgr.addgold(userinfo.userId, add_gold, 0, g_GoldType.quest_wdg_nextdaylogin, -1, 1);
    
    return add_gold;
end

--是否在某天0点之前
get_before_specday = function(time)
    local tableTime = os.date("*t",time)
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    if time < endtime then
        return true, endtime
    else
        return false, endtime
    end
end

--还差几天到月底
function tex_dailytask_lib.get_last_monthday()
    local sys_day = tonumber(os.date("%d", os.time()))
    local sys_year = os.date("%Y", os.time()) --年
    local sys_month = tonumber(os.date("%m", os.time()))+1 --月
    local next_month_day=sys_year.."-"..sys_month.."-1 00:00:00"
  
    local is_before,newday=get_before_specday(timelib.db_to_lua_time(next_month_day))
    local new_day=tonumber(os.date("%d", newday))
    --修改bug #206，即30号要显示还有1天领奖，而不是还有0天
    return math.floor((newday-os.time()-1)/86400)+1
end


--查一下今天用了几张奖卷
function tex_dailytask_lib.get_already_used_today(userinfo)
    local today_used_count=userinfo.wdg_huodong.today_used_count or 0
    return today_used_count--先默认为用了0张
end


--初始化这个玩家的数据到内存中
function tex_dailytask_lib.init_memory_data(userinfo)
    if (userinfo.wdg_huodong == nil) then
        userinfo.wdg_huodong = {}
    end

    --local sql="call sp_month_paiming(%d)"
    local sql="select mc from pm_today where user_id=%d"
 
    dblib.execute(string.format(sql,userinfo.userId),function(dt)
            if (dt and #dt > 0) then
                userinfo.wdg_huodong.this_month_paiming = dt[1]["mc"]
            end
         end)
end

--对外接口，返回完成了几个任务
function tex_dailytask_lib.get_task_info(user_info)
	if (not user_info) or (not user_info.wdg_huodong.pai_xin) then
			TraceError("错误信息")
		return 
	end
	local id = {1,2,4,8,16,32,64,128,256,512,1024}
	local finish_num = 0
	local pai_xin = user_info.wdg_huodong.pai_xin
	for i,v in pairs(id) do
		if (bit_mgr:_and(pai_xin, v) ~= 0) then
			finish_num = finish_num + 1
		end
	end
	return finish_num
end

--命令列表
cmdHandler = 
{
	
	["TXDKZP"] = tex_dailytask_lib.onRecvDakaiZhuanpan, --收到打开转盘
	["TXKSCJ"] = tex_dailytask_lib.onRecvKaishiChoujiang, --收到开始抽奖
    ["TXJJBH"] = tex_dailytask_lib.notify_lottery_change, --游戏结束时发一次请求，客户端也会发请求


	
    --gamecenter
    --[[["RERIDDL"] = gsriddlelib.OnRecvRiddleFromGC,--收到正在答题的谜语ID
	["RERIDAS"] = gsriddlelib.OnRecvAnswerRiddleFromGC,--收到验证谜语结果
    ["BCRIDOV"] = gsriddlelib.OnRecvRiddleOverFromGC,--收到有人答对题了

    --client
    ["RIDQETM"] = gsriddlelib.OnRecvQueryTimeFromClient, --收到玩家查询剩余时间
    ["RIDINFO"] = gsriddlelib.OnRecvQueryRiddleFromClient, --收到玩家查询题目内容
    ["RIDANSW"] = gsriddlelib.OnRecvAnswerFromClient, --收到玩家答题
    --]]
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

tex_dailytask_lib.init = function ()
    if (tex_dailytask_lib.is_init == true)  then
        return
    end
    tex_dailytask_lib.is_init = true
    eventmgr:removeEventListener("timer_minute", tex_dailytask_lib.ontimer_flash_paihang);
    eventmgr:addEventListener("timer_minute", tex_dailytask_lib.ontimer_flash_paihang);
    eventmgr:removeEventListener("h2_on_user_login", tex_dailytask_lib.h2_after_user_login);
    eventmgr:addEventListener("h2_on_user_login", tex_dailytask_lib.h2_after_user_login);
end

tex_dailytask_lib.init()

TraceError("初始化活动插件")





