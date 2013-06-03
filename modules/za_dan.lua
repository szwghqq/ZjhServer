TraceError("init treasure_box...")
if zadanlib and zadanlib.ongameover then 
	eventmgr:removeEventListener("game_event", zadanlib.ongameover);
end
 
if not zadanlib then
    zadanlib = _S
    {
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
        
        box1_num=20,    --银宝箱盘数
        box2_num=40,    --金宝箱盘数
        
        valid_site_no = -1, --在360上搞活动，如果等于-1就是全开  360是104
        
        smallbet = 100,  --小盲注限制
        start_time = "2012-04-19 00:00:00",
        end_time = "2019-05-21 00:00:00",
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

    local retcode = 0;
    if zadanlib.checker_time_valid() and zadanlib.is_valid_site(userinfo) then
        retcode = 1;
    end
  
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
    
    if not zadanlib.checker_time_valid() then
        return;
    end
    
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
	if(play_count < 5) then
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
	local userinfo = e.data.userinfo
 	for k,v in pairs(e.data)do
 		local userinfo=usermgr.GetUserById(v.userid)
 		zadanlib.count_pan(userinfo) 
 	end
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
                zadanlib.net_send_open_box(userinfo, boxid, prizeid);
                zadanlib.net_send_playnum_and_boxs(userinfo, play_num, boxs, need_show);
            else
                TraceError(format("随机奖品失败，sql=%s",sql))
            end
         end)
    else   
        --通知玩家得到什么奖品
        zadanlib.net_send_open_box(userinfo, boxid, prizeid);
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
    
    --通知玩家领到什么奖品
    zadanlib.net_send_gift_info(userinfo, boxid, prizeid);
end

--通知玩家得到什么奖品
--//1:100筹码,2:300筹码,3:500筹码,4:3000筹码,5:1W筹码,6:铜卡VIP,7:金卡VIP,8:小喇叭X1,9:小喇叭X3，10:踢人卡X2
zadanlib.net_send_open_box = function(userinfo, boxid, prizeid)
    netlib.send(function(buf)
            buf:writeString("TBHDOB");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
        end,userinfo.ip,userinfo.port);
end
--通知玩家领到什么奖品
--//1:100筹码,2:300筹码,3:500筹码,4:3000筹码,5:1W筹码,6:铜卡VIP,7:金卡VIP,8:小喇叭X1,9:小喇叭X3，10:踢人卡X2
zadanlib.net_send_gift_info = function(userinfo, boxid, prizeid)
    netlib.send(function(buf)
            buf:writeString("TBHDGP");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
        end,userinfo.ip,userinfo.port);
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

eventmgr:addEventListener("game_event", zadanlib.ongameover); 