TraceError("init treasure_box...")
if zadanlib and zadanlib.ongameover then 
	eventmgr:removeEventListener("on_game_over_event", zadanlib.ongameover);
end

if zadanlib and zadanlib.restart_server then
	eventmgr:removeEventListener("on_server_start", zadanlib.restart_server);
end

if zadanlib and zadanlib.timer then
	eventmgr:removeEventListener("timer_second", zadanlib.timer);
end

if zadanlib and zadanlib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", zadanlib.on_user_exit);
end
if not zadanlib then
    zadanlib = _S
    {
    	--以下是方法
        gettable = NULL_FUNC,--处理数据中字段转换为数组
        checker_time_valid = NULL_FUNC,--检查是否符合验证
        On_Recv_Check_HuoDong = NULL_FUNC,--检查活动是否符进行中
        On_Recv_Get_PlayNumAndBox = NULL_FUNC,--收到请求盘数和箱子信息
        On_Recv_Open_Box = NULL_FUNC,--收到点击打开箱子
        On_Recv_Get_Prize = NULL_FUNC,--收到打开箱子点击领奖
        do_give_user_gift = NULL_FUNC,--给玩家发奖
        ongameover = NULL_FUNC,--每盘游戏结束累计盘数
        net_send_open_box = NULL_FUNC, --通知打开箱子得到什么奖品
        net_send_gift_info = NULL_FUNC, --通知客户端领到什么奖品了
        net_send_playnum_and_boxs = NULL_FUNC,--发送盘数和可以开启的箱子ID
        count_pan = NULL_FUNC, --统计盘数
        is_valid_site = NULL_FUNC, --判断是不是合适的站点
        add_zw = NULL_FUNC, --加助威值
        init_zw_info = NULL_FUNC, --初始化助威信息
        timer = NULL_FUNC, --定时器
        send_zw_list = NULL_FUNC, --发助威列表给所有人
        send_user_zw_info = NULL_FUNC, --发助威列表给某个人
        update_zw_list = NULL_FUNC, --更新各服务器上的排行
        restart_server = NULL_FUNC, --服务器重启时把之前的助威排行读进来
        zw_fajiang = NULL_FUNC, --助威发奖
        init_zw_pm_from_db = NULL_FUNC, --初始化助威排名
        on_user_exit = NULL_FUNC, --玩家离开了
        
        --以下是变量及配置信息
        box1_num=20,    --银宝箱盘数
        box2_num=40,    --金宝箱盘数
        CFG_PLAY_COUNT = 5, --要几个人一起玩的算成绩
        
        valid_site_no = -1, --在360上搞活动，如果等于-1就是全开  360是104
        
        smallbet = 100,  --小盲注限制
        start_time = "2012-07-28 09:00:00",
        end_time = "2012-08-12 23:59:59",
        CFG_FAJIANG_TIME = "2012-08-12 23:59:59",
        CFG_ZW_REWARD = { --助威值配置
        	[1] = 1,
        	[2] = 2,
        	[3] = 5,
        	[4] = 4,
        	[5] = 3,
        	[6] = 6,
        	[7] = 7,
        	[8] = 9,
        	[9] = 10,
        	[10] = 8,
        	
        },
        CFG_GAME_ROOM = 18001,
        user_list = {},
        king_zw_list = {},--助威排行榜上榜的人
        CFG_ZW_LEN = 10, --助威排行榜的长度
        notify_zw_info = 0, --刷新助威信息
        CFG_JP_DESC = { --奖品描述
        	[1] = "玛莎拉蒂",
        	[2] = "奥迪A8L",
        	[3] = "甲壳虫",
        	[4] = "丰田雅力士",
        	[5] = "丰田雅力士",
        	[6] = "海马爱尚",
        	[7] = "海马爱尚",
        	[8] = "海马爱尚",
        	[9] = "海马爱尚",
        	[10] = "海马爱尚",
        },
        CFG_JP = { --奖品
        	[1] = 5021,
        	[2] = 5011,
        	[3] = 5012,
        	[4] = 5030,
        	[5] = 5030,
        	[6] = 5031,
        	[7] = 5031,
        	[8] = 5031,
        	[9] = 5031,
        	[10] = 5031,
        },
    }    
 end
 
 --在哪个站点搞活动
 zadanlib.is_valid_site = function(user_info)
 	if(zadanlib.valid_site_no~=-1 and user_info.nRegSiteNo~=zadanlib.valid_site_no)then
 		return false
 	end
 	return true
 end
 
--判断游戏的时间合法性
zadanlib.checker_time_valid = function()
	
    local isvalide = true
    if gamepkg.name ~= "tex" then
        isvalide = false
    end
	local starttime = timelib.db_to_lua_time(zadanlib.start_time);
	local endtime = timelib.db_to_lua_time(zadanlib.end_time);
	local sys_time = os.time()
    if(sys_time < starttime or sys_time > endtime) then
        isvalide = false
	end
    return isvalide
end

--字符串转换成table
zadanlib.gettable = function(szboxinfo)
    local newtable = split(szboxinfo, "|");
    local retable ={};
    for _,box in pairs(newtable) do
        if box ~= "" then
            local arr = split(box, ":");
            if(#arr == 4) then
                retable[tonumber(arr[1])] = 
                {
                    neednum = tonumber(arr[2]),
                    opened = tonumber(arr[3]), 
                    prizeid = tonumber(arr[4]),
                };
	        else
	            TraceError("什么箱子呀这是?"..box);
	        end
        end
    end

    return retable;
end

--收到查询活动是否进行中,0没有进行,1进行中
zadanlib.On_Recv_Check_HuoDong = function(buf)
    --TraceError("On_Recv_Check_HuoDong");
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local user_id = userinfo.userId

    local retcode = 0;
    if zadanlib.checker_time_valid() and zadanlib.is_valid_site(userinfo) then
        retcode = 1;
    end
    
    zadanlib.init_zw_info(user_id)
    netlib.send(function(buf)
            buf:writeString("TBHDOK");
            buf:writeInt(retcode);
        end,userinfo.ip,userinfo.port);
end

--收到请求盘数和箱子数
zadanlib.On_Recv_Get_PlayNumAndBox = function(buf)
    --TraceError("On_Recv_Get_PlayNumAndBox");
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    
    --if not zadanlib.checker_time_valid() then
    --    return;
    --end
    
    if not zadanlib.is_valid_site(userinfo) then
        return;
    end
    
    if(not userinfo.desk) then return end;
    --500倍场以上
    --if(desklist[userinfo.desk].smallbet < zadanlib.smallbet) then return end;
    --非VIP只能开银宝箱
    local szbox_info = "1:"..zadanlib.box1_num..":0:0|2:"..zadanlib.box2_num..":0:0";
    --if(not viplib.check_user_vip(userinfo))then
   --     szbox_info = "1:"..zadanlib.box1_num..":0:0|2:"..zadanlib.box2_num..":0:0";
   -- else
    --    szbox_info = "1:"..zadanlib.box1_num..":0:0|2:"..zadanlib.box2_num..":0:0";
    --end
   
    local sqltemplet = "insert ignore into user_treasurebox_info (user_id, game_name, login_time, box_info) ";
    sqltemplet = sqltemplet.."values(%d, '%s', now(), '"..szbox_info.."');commit; ";
    sqltemplet = sqltemplet.."select * from user_treasurebox_info where user_id = %d and game_name = '%s'; ";
    
    local userid = userinfo.userId;
    local gamename = gamepkg.name;

    local strsql = string.format(sqltemplet, userid, gamename, userid, gamename);
    dblib.execute(strsql,
    function(dt)
        if dt and #dt > 0 then
            local gamedata = deskmgr.getuserdata(userinfo);
            --写入内存数据
            gamedata.playgameinfo = {}
            local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["login_time"]));  --数据库的今天
            if (db_date ~= sys_today) then
                gamedata.playgameinfo.boxs = {};
                gamedata.playgameinfo.boxs[1] = {neednum = zadanlib.box1_num, opened = 0, prizeid = 0};
                gamedata.playgameinfo.boxs[2] = {neednum = zadanlib.box2_num, opened = 0, prizeid = 0};
                gamedata.playgameinfo.play_num = 0;
                gamedata.playgameinfo.login_time = os.time();
                gamedata.playgameinfo.need_show = 1;
                --if(not viplib.check_user_vip(userinfo))then
                --gamedata.playgameinfo.boxs[2].opened = 1;
                --end
                local sqltemplet = "update user_treasurebox_info ";
                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1 ";
                sqltemplet = sqltemplet.."where user_id = %d and game_name = '%s'; commit;";
                
                dblib.execute(string.format(sqltemplet, userid, gamename))
            else
                gamedata.playgameinfo.boxs = zadanlib.gettable(dt[1]["box_info"]);
                gamedata.playgameinfo.play_num = dt[1]["play_num"];
                gamedata.playgameinfo.login_time = timelib.db_to_lua_time(dt[1]["login_time"]);
                gamedata.playgameinfo.need_show = dt[1]["need_show"];
            end
            local playnum = gamedata.playgameinfo.play_num;
            local boxs = gamedata.playgameinfo.boxs;
            local need_show = gamedata.playgameinfo.need_show;
            zadanlib.net_send_playnum_and_boxs(userinfo, playnum, boxs, need_show);
        else
            TraceError(" 查询数据库时出错:" .. strsql);
        end
    end)
    zadanlib.send_user_zw_info(userinfo)
end

--游戏结束采集盘数
zadanlib.count_pan = function(userinfo)
    if not userinfo or not userinfo.desk then return end;
    local gamedata = deskmgr.getuserdata(userinfo);
    if not gamedata.playgameinfo then return end;
    if not zadanlib.checker_time_valid() then
        return;
    end
    local play_num = gamedata.playgameinfo.play_num;
    --金宝箱必须是vip才增加
    --if (play_num >= 30 and viplib.check_user_vip(userinfo) ~= true) then return end

    --小盲大于等于500并且在玩够5个人就可以累计宝箱盘数
	--TODO:上线改成9个人
    local deskinfo = desklist[userinfo.desk]
    local play_count = deskinfo.playercount
	--if(play_count < 5 or deskinfo.smallbet < zadanlib.smallbet) then
	if(play_count < zadanlib.CFG_PLAY_COUNT) then
		return
    end
    --判断是否所有箱子条件都达到了
    local boxs = gamedata.playgameinfo.boxs;
    local limitNum = 0;
    for k,v in pairs(boxs) do
        if(limitNum < v.neednum) then
            limitNum = v.neednum;
        end
    end
    if play_num >= limitNum then
        return;
    end

    --修改内存数据
    play_num = play_num + 1;
    gamedata.playgameinfo.play_num = play_num;
    gamedata.playgameinfo.is_show = 1; --宝箱未开完，显示成未开状态
    local need_show = gamedata.playgameinfo.is_show;

   --记录到数据库
   local sqltemplet = "update user_treasurebox_info set play_num = %d, need_show = %d where user_id = %d and game_name = '%s'; commit;";
   dblib.execute(string.format(sqltemplet, play_num, need_show, userinfo.userId, gamepkg.name));

   --通知客户端
   zadanlib.net_send_playnum_and_boxs(userinfo, play_num, boxs, need_show);
end

zadanlib.ongameover = function(e)
	local userinfo = e.data.user_info
	zadanlib.count_pan(userinfo) 
end

--发送盘数和箱子ID
zadanlib.net_send_playnum_and_boxs = function(userinfo, playnum, boxs, need_show)
    local boxlist = {};
    for k,v in pairs(boxs) do
        local item = {id = k, neednum = v.neednum, opened = v.opened, prizeid = v.prizeid};
        table.insert(boxlist, item);
    end
    netlib.send(function(buf)
            buf:writeString("TBHDPN");
            buf:writeByte(need_show);
            buf:writeInt(playnum);            
            buf:writeByte(#boxlist);
            for i=1,#boxlist do
                buf:writeByte(boxlist[i].id);  
                buf:writeInt(boxlist[i].neednum);
                buf:writeByte(boxlist[i].opened);
                buf:writeByte(boxlist[i].prizeid);
            end
        end,userinfo.ip,userinfo.port)
end

--收到玩家打开箱子
zadanlib.On_Recv_Open_Box = function(buf)
   local userinfo = userlist[getuserid(buf)];
   if not userinfo then return end;
   --合法性检查
   if not zadanlib.checker_time_valid() then
       return;
   end

   if(not userinfo.desk) then return end;
    --100/200倍场以上
    --小盲大于等于100并且在玩够9个人就可以累计宝箱盘数
	--TODO:上线改成9个人
    local deskinfo = desklist[userinfo.desk]
	--if(deskinfo.smallbet < zadanlib.smallbet) then
	--	return
    --end

   local gamedata = deskmgr.getuserdata(userinfo);
   if not gamedata.playgameinfo then return end;
   
   local boxid = buf:readByte();
    --非VIP只能开银宝箱
    --if(boxid > 1 and not viplib.check_user_vip(userinfo))then
    --    return;
   -- end
   if boxid ~= 1 and boxid ~= 2 then
       TraceError("收到错误的箱子id,不处理")
       return
   end
   local play_num = gamedata.playgameinfo.play_num;
   local need_show = gamedata.playgameinfo.need_show;
   local boxs = gamedata.playgameinfo.boxs;
   if(boxs[boxid] == nil) then
     TraceError("请求的箱子["..boxid.."]不属于此玩家["..userinfo.userId.."]");
     return;
   end
   if(gamedata.playgameinfo.play_num < boxs[boxid].neednum) then
     TraceError("请求的箱子["..boxid.."]需要游戏["..boxs[boxid].neednum.."]盘之后才可以开启");
     return;
   end
   if(boxs[boxid].opened ~= 0) then
     TraceError("请求的箱子["..boxid.."]已经开过");
     return;
   end
   local prizeid = boxs[boxid].prizeid
   if(prizeid <= 0) then
        --随机生成奖品ID
        local sql = format("call sp_get_random_zadan_gift(%d, '%s', %d)", userinfo.userId, "tex", boxid)
        dblib.execute(sql, function(dt)
            if(dt and #dt > 0)then
                --TraceError(dt)
                --TraceError(sql)
                prizeid = dt[1]["gift_id"]
                local prizename = dt[1]["gift_des"] or ""
                if(prizeid <= 0) then
                    TraceError(format("生成奖品失败!prizeid=%d", prizeid));
                    return;
                 end       
                local boxname = "";
                if(boxid == 1) then
                    --boxname = "初级彩蛋";
                    boxname = tex_lan.get_msg(userinfo, "za_dan_type_primary");
                elseif(boxid == 2) then
                    --boxname = "高级彩蛋";
                    boxname = tex_lan.get_msg(userinfo, "za_dan_type_advance");
                end

                
                --得到vip的才广播
                --if(prizeid == 4 or prizeid == 8 or prizeid==9) then                
                --    BroadcastMsg(_U(tex_lan.get_msg(userinfo, "za_dan_msg_1"))..userinfo.nick.._U(tex_lan.get_msg(userinfo, "za_dan_msg_2")..boxname..tex_lan.get_msg(userinfo, "za_dan_msg_3"))..prizename.._U(tex_lan.get_msg(userinfo, "za_dan_msg_4")),0);
                --end
                 
                 --设置箱子奖品
                 boxs[boxid].prizeid = prizeid;
            
                 
                 local box_info = "";
                 need_show = 2;
                 for k,v in pairs(boxs) do
                     box_info = box_info ..format("%d:%d:%d:%d|", tostring(k), tostring(v.neednum), tostring(v.opened), tostring(v.prizeid));
                     if v.opened == 0 then
                         need_show = 1;
                     end
                 end
                 --非VIP只能开银宝箱
                 --if(boxs[boxid].opened == 1 and not viplib.check_user_vip(userinfo))then
                 --    need_show = 2;
                 --end
                 gamedata.playgameinfo.need_show = need_show;
                 --记录到数据库
                 local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d where user_id = %d and game_name = '%s'; commit;";
                 dblib.execute(string.format(sqltemplet, box_info, need_show, userinfo.userId, gamepkg.name));
                 --写入日志
                 sqltemplet = "insert into log_treasurebox_prize(user_id, game_name, sys_time, box_id, prize_id) "
                 sqltemplet = sqltemplet.."values(%d,'%s',now(),%d,%d);commit; "
                 --dblib.execute(string.format(sqltemplet, userinfo.userId, gamepkg.name, boxid, prizeid));
                 --通知玩家得到什么奖品
                zadanlib.net_send_open_box(userinfo, boxid, prizeid, zadanlib.CFG_ZW_REWARD[prizeid]);
                zadanlib.net_send_playnum_and_boxs(userinfo, play_num, boxs, need_show);
            else
                TraceError(format("随机奖品失败，sql=%s",sql))
            end
         end)
    else   
        --通知玩家得到什么奖品
        zadanlib.net_send_open_box(userinfo, boxid, prizeid, zadanlib.CFG_ZW_REWARD[prizeid]);
        zadanlib.net_send_playnum_and_boxs(userinfo, play_num, boxs, need_show);
    end;
end

--收到玩家领奖啦
zadanlib.On_Recv_Get_Prize = function(buf)
   --TraceError("On_Recv_Get_Prize")
   local userinfo = userlist[getuserid(buf)];
   if not userinfo then return end;
   --合法性检查
   if not zadanlib.checker_time_valid() then
       return;
   end

   if(not userinfo.desk) then return end;
   --100/200倍场以上
  -- if(desklist[userinfo.desk].smallbet < zadanlib.smallbet) then return end;

   local gamedata = deskmgr.getuserdata(userinfo);
   if not gamedata.playgameinfo then return end;
   
   local boxid = buf:readByte();

   if boxid ~= 1 and boxid ~= 2 then
       TraceError("收到错误的箱子id,不处理");
       return;
   end
   
   --通知玩家得到什么奖品
   zadanlib.do_give_user_gift(userinfo, boxid);
   --刷新盘数和箱子状态
   local play_num = gamedata.playgameinfo.play_num;
   local need_show = gamedata.playgameinfo.need_show;
   local boxs = gamedata.playgameinfo.boxs;
   zadanlib.net_send_playnum_and_boxs(userinfo, play_num, boxs, need_show);
end

--给玩家发奖(到这里就可以认为是合法领奖了)
zadanlib.do_give_user_gift = function(userinfo, boxid)
    if not zadanlib.checker_time_valid() then
        return;
    end
    
    if not userinfo then return end;
    local gamedata = deskmgr.getuserdata(userinfo);
    if not gamedata.playgameinfo then return end;
    
    local play_num = gamedata.playgameinfo.play_num;
    local boxs = gamedata.playgameinfo.boxs;
    
    if(boxs[boxid] == nil) then
        TraceError("请求的箱子["..boxid.."]不属于此玩家["..userinfo.userId.."]");
        return;
    end
    if(gamedata.playgameinfo.play_num < boxs[boxid].neednum) then
        TraceError("请求的箱子["..boxid.."]需要游戏["..boxs[boxid].neednum.."]盘之后才可以开启");
        return;
    end
    
    if(boxs[boxid].opened ~= 0) then
        --TraceError("请求的箱子["..boxid.."]已经开过");
        return;
    end
    
    if(boxs[boxid].prizeid <= 0) then
        TraceError("领奖了，箱子的奖品还没生成？？？");
        return;
    end
    local prizeid = boxs[boxid].prizeid;
    
    --设置箱子开过
    boxs[boxid].opened = 1;
    
    local need_show = 2;
    local box_info = "";
    for k,v in pairs(boxs) do
        box_info = box_info ..format("%d:%d:%d:%d|", tostring(k), tostring(v.neednum), tostring(v.opened), tostring(v.prizeid));
        --if v.opened == 0 and viplib.check_user_vip(userinfo) then
        if v.opened == 0 then
            need_show = 1;
        end
    end
    
    gamedata.playgameinfo.need_show = need_show;
    --记录到数据库
    local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d where user_id = %d and game_name = '%s'; commit;";
    dblib.execute(string.format(sqltemplet, box_info, need_show, userinfo.userId, gamepkg.name));
    local sql = ""
    --派发奖品啦
    if(prizeid == 1) then  --100筹码
      	usermgr.addgold(userinfo.userId, 100, 0, g_GoldType.baoxiang, -1);
    elseif(prizeid == 2) then  --300筹码
      	usermgr.addgold(userinfo.userId, 300, 0, g_GoldType.baoxiang, -1);
    elseif(prizeid == 3) then  --3000筹码
      	usermgr.addgold(userinfo.userId, 3000, 0, g_GoldType.baoxiang, -1);
    elseif(prizeid == 4) then  --铜卡会员卡3天
    	viplib.add_user_vip(userinfo,1,3)
    elseif(prizeid == 5) then  --经验药水20点
    	usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), 20, g_ExpType.jhm_huodong, groupinfo.groupid);
    elseif(prizeid == 6) then  --500筹码
      usermgr.addgold(userinfo.userId, 500, 0, g_GoldType.baoxiang, -1);
    elseif(prizeid == 7) then  --10000筹码
      usermgr.addgold(userinfo.userId, 10000, 0, g_GoldType.baoxiang, -1);
    elseif(prizeid == 8) then  --铜卡会员卡10天
    	viplib.add_user_vip(userinfo,1,10)
    elseif(prizeid == 9) then	-- 银卡会员卡5天
    	viplib.add_user_vip(userinfo,2,5)	  	
	elseif(prizeid == 10) then	--送小喇叭
		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, userinfo);
    else
      TraceError("未知的prizeid["..prizeid.."]!!!");
      return;
    end
    
    if prizeid >= 1 and prizeid <= 10 then
    	zadanlib.add_zw(userinfo, zadanlib.CFG_ZW_REWARD[prizeid])
    end
    --通知玩家领到什么奖品
    zadanlib.net_send_gift_info(userinfo, boxid, prizeid, zadanlib.CFG_ZW_REWARD[prizeid]);
end

--通知玩家得到什么奖品
--//1:100筹码,2:300筹码,3:500筹码,4:3000筹码,5:1W筹码,6:铜卡VIP,7:金卡VIP,8:小喇叭X1,9:小喇叭X3，10:踢人卡X2
zadanlib.net_send_open_box = function(userinfo, boxid, prizeid, zw_count)
    netlib.send(function(buf)
            buf:writeString("TBHDOB");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
            buf:writeInt(zw_count);
        end,userinfo.ip,userinfo.port);
end

--通知玩家领到什么奖品
--//1:100筹码,2:300筹码,3:500筹码,4:3000筹码,5:1W筹码,6:铜卡VIP,7:金卡VIP,8:小喇叭X1,9:小喇叭X3，10:踢人卡X2
zadanlib.net_send_gift_info = function(userinfo, boxid, prizeid, zw_count)
    netlib.send(function(buf)
            buf:writeString("TBHDGP");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
            buf:writeInt(zw_count);
        end,userinfo.ip,userinfo.port);
end

--给某个玩家加助威值
function zadanlib.add_zw(user_info, zw_count)
    local send_to_gs = function(buf)
		buf:writeString("TBHDGS")
        buf:writeInt(user_id)
        buf:writeString(nick_name)
      	buf:writeInt(zw_count)
    end
    
    --时间到了就不要再加助威了
	if os.time() > timelib.db_to_lua_time(zadanlib.end_time) then return end
	local user_id = user_info.userId
	local nick_name = string.trans_str(user_info.nick)
	zadanlib.user_list[user_id].zw_count = zadanlib.user_list[user_id].zw_count + zw_count
	local sql = "insert into user_olympic_info(user_id, zw_count, nick_name, sys_time) value (%d, %d, '%s', now()) on duplicate key update zw_count = zw_count + %d, nick_name = '%s', sys_time=now();"
	sql = string.format(sql, user_id, zw_count, nick_name, zw_count, nick_name)
	dblib.execute(sql, function(dt) end, user_id)
	
	--更新各服务器上的排行
	--zadanlib.update_zw_list(user_id, nick_name, zadanlib.user_list[user_id].zw_count)
	--local min_zw = 0
	--if #zadanlib.king_zw_list > 0 then
	--	min_zw = zadanlib.king_zw_list[#zadanlib.king_zw_list].zw_count --最后一名的助威值
	--end
	zadanlib.update_zw_list(user_id, nick_name, zadanlib.user_list[user_id].zw_count)
end

--更新排行
function zadanlib.update_zw_list(user_id, nick_name, zw_count)

	--生成助威列表的前15名
	local min_zw = 0
	if #zadanlib.king_zw_list > 0 then
		min_zw = zadanlib.king_zw_list[#zadanlib.king_zw_list].zw_count --最后一名的助威值
	end
	
	if zw_count > min_zw or  #zadanlib.king_zw_list < zadanlib.CFG_ZW_LEN then
		local buf_tab = {
			["user_id"] = user_id,
			["nick_name"] = nick_name,
			["zw_count"] = zw_count,
		}
		local is_finder = 0
		for k,v in pairs (zadanlib.king_zw_list) do 
			if v.user_id == user_id then
				is_finder = 1
				v.nick_name = nick_name
				v.zw_count = zw_count
				break
			end
		end
		if is_finder == 0 then
			table.insert(zadanlib.king_zw_list, buf_tab)
		end
		table.sort(zadanlib.king_zw_list,
			function(a, b)
				     return a.zw_count > b.zw_count		                   
			end)

		 
		if #zadanlib.king_zw_list > zadanlib.CFG_ZW_LEN then
			table.remove(zadanlib.king_zw_list, #zadanlib.king_zw_list)
		end 
		zadanlib.notify_zw_info = 1
	end
end

--初始化玩家的助威信息
function zadanlib.init_zw_info(user_id, call_back)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	if zadanlib.user_list[user_id] == nil then zadanlib.user_list[user_id] = {} end
	local sql = "select zw_count, already_notify from user_olympic_info where user_id = %d"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt)
	
		zadanlib.user_list[user_id].user_id = user_id
		if dt and #dt > 0 then
			zadanlib.user_list[user_id].zw_count = dt[1].zw_count
			zadanlib.user_list[user_id].already_notify = dt[1].already_notify
		else
			zadanlib.user_list[user_id].zw_count = 0 
			zadanlib.user_list[user_id].already_notify = 0
		end
		
		if os.time() > timelib.db_to_lua_time(zadanlib.end_time) then
			local mc = -1
			for i=1, #zadanlib.king_zw_list do
				if zadanlib.king_zw_list[i].user_id == user_id then
					mc = i
					break
				end
			end 
			if mc > 0 and zadanlib.user_list[user_id].already_notify ==0 then
				zadanlib.send_reward_msg(user_id, mc)
			end
		end
		if call_back~= nil then
			call_back(user_info, zadanlib.user_list[user_id].zw_count)
		end
	end, user_id)
end

function zadanlib.timer(e)
	local now_time = timelib.lua_to_db_time(e.data.time)
	
	if now_time == zadanlib.CFG_FAJIANG_TIME then
		--从数据库里重新生成一下排名，防止极小几率时多个玩家的助威值相同，这时要看入库时间来决定谁上榜
		if zadanlib.CFG_GAME_ROOM == tonumber(groupinfo.groupid) then
			zadanlib.init_zw_pm_from_db(1)

		end
	end
	
	--发助威列表
	if zadanlib.notify_zw_info == 1 then
		zadanlib.notify_zw_info = 0
		zadanlib.send_zw_list()
	end
end

----发助威列表给所有人
function zadanlib.send_zw_list()
	for k, v in pairs (zadanlib.user_list) do
		local user_info = usermgr.GetUserById(v.user_id)
		if user_info ~= nil then
			zadanlib.send_user_zw_info(user_info)		
		end
	end
end

--"TBHDZW" 给某个玩家发助威排行
--int my_zw 
--int len
--for 
--String 昵称
--int 助威值
--end
function zadanlib.send_user_zw_info(user_info)
	local send_result = function(user_info, my_zw_count)
		netlib.send(function(buf)
		    buf:writeString("TBHDZW")
		    buf:writeInt(my_zw_count or 0)
		    buf:writeInt(zadanlib.CFG_ZW_LEN)
		    		
		    for i = 1, zadanlib.CFG_ZW_LEN do
		    	local nick_name = "--"
		    	local zw_count = 0
		    	if zadanlib.king_zw_list[i] ~= nil then
		    		nick_name = zadanlib.king_zw_list[i].nick_name
		    		zw_count = zadanlib.king_zw_list[i].zw_count
		    	end
		    	
		    	buf:writeString(nick_name)
		    	buf:writeInt(zw_count)	
				buf:writeString(_U(zadanlib.CFG_JP_DESC[i]))	
		    end
    	end,user_info.ip,user_info.port)   
	end
	
	local user_id = user_info.userId
	local zw_count = 0
	if zadanlib.user_list[user_id] == nil or zadanlib.user_list[user_id].zw_count == nil then
		zadanlib.init_zw_info(user_id, send_result)
	else
		zw_count = zadanlib.user_list[user_id].zw_count
		send_result(user_info, zw_count)
	end
	
end

--重启服务了
function zadanlib.restart_server()
	zadanlib.init_zw_pm_from_db(0)
end

function zadanlib.init_zw_pm_from_db(need_fajiang)
	zadanlib.king_zw_list = {}
	local sql = "select user_id,zw_count,nick_name from user_olympic_info order by zw_count desc,sys_time limit %d"
	sql = string.format(sql, zadanlib.CFG_ZW_LEN)
	dblib.execute(sql,function(dt)
		if dt and #dt > 0 then
			for i = 1, #dt do
				local buf_tab = {
					["user_id"] = dt[i].user_id,
					["nick_name"] = dt[i].nick_name,
					["zw_count"] = dt[i].zw_count,
				}
				table.insert(zadanlib.king_zw_list, buf_tab)
			end
			if need_fajiang == 1 then
				zadanlib.zw_fajiang()
				zadanlib.send_zw_list()
			end
		end
	end)
end

--
--TBHDJP
--byte 名次
--string 奖品
function zadanlib.send_reward_msg(user_id, mc)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	
	netlib.send(function(buf)
        buf:writeString("TBHDJP");
        buf:writeByte(mc);
        buf:writeString(_U(zadanlib.CFG_JP_DESC[mc]));
	end, user_info.ip, user_info.port)
	
	local sql = "update user_olympic_info set already_notify = 1 where user_id = %d"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt) end, user_id)
end

--发奖
function zadanlib.zw_fajiang()
	
	local sql = "select user_id,zw_count,nick_name from user_olympic_info order by zw_count desc,sys_time limit %d"
	sql = string.format(sql, zadanlib.CFG_ZW_LEN)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			for i = 1, #dt do
				car_match_db_lib.add_car(dt[i].user_id, zadanlib.CFG_JP[i], 0)
				zadanlib.send_reward_msg(dt[i].user_id, i)
			end
		end
	end)	
end

--玩家离开了
function zadanlib.on_user_exit(e)
	local user_id = e.data.user_id
	if zadanlib.user_list[user_id] ~= nil then
		zadanlib.user_list[user_id] = nil
	end
end


--命令列表
cmdHandler = 
{
    ["TBHDOK"] = zadanlib.On_Recv_Check_HuoDong, --查询活动是否进行中
    ["TBHDPN"] = zadanlib.On_Recv_Get_PlayNumAndBox, -- 收到登陆成功
    ["TBHDOB"] = zadanlib.On_Recv_Open_Box, -- 收到打开箱子，随机奖品
    ["TBHDGP"] = zadanlib.On_Recv_Get_Prize, -- 收到领取奖励

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", zadanlib.timer); 
eventmgr:addEventListener("on_game_over_event", zadanlib.ongameover); 
eventmgr:addEventListener("on_server_start", zadanlib.restart_server); 
eventmgr:addEventListener("on_user_exit", zadanlib.on_user_exit); 