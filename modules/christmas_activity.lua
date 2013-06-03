TraceError("init christmas_activity...")
if not christmasLib then
    christmasLib = _S
    {
    	-------------圣诞-元旦活动-------
    
        gettable = NULL_FUNC,--处理数据中字段转换为数组
        checker_time_valid = NULL_FUNC,--检查是否符合验证
        onRecvChristmasActivityStat = NULL_FUNC,--检查活动是否符进行中
        onRecvGetPlayNumAndBox_ChristmasActivity = NULL_FUNC,--收到请求盘数和箱子信息
        onRecvOpenBox_ChristmasActivity = NULL_FUNC,--收到点击打开箱子
        onRecvGetPrize_ChristmasActivity = NULL_FUNC,--收到打开箱子点击领奖
        doGiveUserGift_ChristmasActivity = NULL_FUNC,--给玩家发奖
        ongameover_ChristmasActivity = NULL_FUNC,--每盘游戏结束累计盘数
        netSendOpenBox_ChristmasActivity = NULL_FUNC, --通知打开箱子得到什么奖品
        netSendGiftInfo_ChristmasActivity = NULL_FUNC, --通知客户端领到什么奖品了
        netSendPlaynumAndBoxs_ChristmasActivity = NULL_FUNC,--发送盘数和可以开启的箱子ID
        on_after_user_login=NULL_FUNC,--登陆后做的事
        
        box1_num=20,    --银宝箱盘数
        box2_num=40,    --金宝箱盘数
         
  		statime_christmas = "2011-12-23 00:00:00",  --活动开始时间
        endtime_christmas = "2011-12-27 00:00:00",  --活动结束时间
    }    
 end


--登陆后做的事
christmasLib.on_after_user_login = function(userinfo)
	--TraceError("christmasLib.on_after_user_login")
  --  if(tex_gamepropslib ~= nil) then
   --     tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.ShipTickets_ID, userinfo, function(ship_ticket_count) end)
   -- end

	local sql = "insert ignore into user_treasurebox_info (user_id, game_name, login_time, box_info) ";
    sql = sql.."values(%d, '%s', '%s', '1:20:0:0|2:40:0:0');commit; "; --"1:30:0:0|2:60:0:0"是用来初始化的变量
    
    sql = string.format(sql, userinfo.userId, "tex", timelib.lua_to_db_time(os.time()));
	dblib.execute(sql)
	
	local sql_1 = "select login_time,lj_num from user_treasurebox_info where user_id = %d and game_name = '%s'; "
	sql_1 = string.format(sql_1, userinfo.userId, "tex");
	
	dblib.execute(sql_1,
    function(dt)
    	if dt and #dt > 0 then

    		local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["login_time"]));  --数据库的今天
            
            if (db_date ~= sys_today) then
            	userinfo.christmasActivity_openNm = 0;

            else
            	userinfo.christmasActivity_openNm = dt[1]["lj_num"];
            
            end
  
    	else
    		userinfo.christmasActivity_openNm = 0;
    	end
    
    end)
end


--字符串转换成table
christmasLib.gettable = function(szboxinfo)
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
	        end
        end
    end

    return retable;
end

--是否在有效时间内
function christmasLib.checker_time_valid()	
   local isvalide = true
    if gamepkg.name ~= "tex" then
        isvalide = false
    end
	local starttime = timelib.db_to_lua_time(christmasLib.statime_christmas);
	local endtime = timelib.db_to_lua_time(christmasLib.endtime_christmas);
	local sys_time = os.time()
    if(sys_time < starttime or sys_time > endtime) then
        isvalide = false
	end
    return isvalide
end

--圣诞状态
function christmasLib.onRecvChristmasActivityStat(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end;

	--判断活动有效性
	local retcode = 0;	--无效日期
    if christmasLib.checker_time_valid() then
        retcode = 1;	--正常活动日期
    end
    netlib.send(function(buf)
            buf:writeString("TBHDOK");
            buf:writeInt(retcode);
        end,userinfo.ip,userinfo.port);	
	end

--游戏结束采集盘数
christmasLib.ongameover_ChristmasActivity = function(userinfo,addgold)
   if not userinfo or not userinfo.desk then return end;

    local gamedata = deskmgr.getuserdata(userinfo);
    if not gamedata.playgameinfo then return end;

    if not christmasLib.checker_time_valid() then
        return;
    end
    
 --   TraceError(" 游戏结束采集盘数")
    
   if(userinfo.christmasActivity_openNm >= 1 and not viplib.check_user_vip(userinfo))then	-- 非VIP可开宝箱1次循环共2个箱子

		return;    
   elseif(userinfo.christmasActivity_openNm >=2  and viplib.get_vip_level(userinfo) < 4)then  --VIP可开2次循环共4个箱子

       return;
   elseif(userinfo.christmasActivity_openNm >=3  and viplib.get_vip_level(userinfo) >= 4)then  --VIP4.5可开3次循环共6个箱子

       return;
   end
 
   if(addgold > 0)then
        netlib.broadcastdesk(
        function(buf)
            buf:writeString("TBHDPLMOV")
            buf:writeInt(userinfo.site); 
        end
    , userinfo.desk, borcastTarget.all);
   end
   
    local play_num = gamedata.playgameinfo.play_num;
    
     --修改内存数据
    play_num = play_num + 1;
    gamedata.playgameinfo.play_num = play_num;
    gamedata.playgameinfo.is_show = 1; --宝箱未开完，显示成未开状态
    local need_show = gamedata.playgameinfo.is_show;
 
    --判断是否所有箱子条件都达到了
    local boxs = gamedata.playgameinfo.boxs;
    local limitNum = 0;
    for k,v in pairs(boxs) do
        if(limitNum < v.neednum) then
            limitNum = v.neednum;
        end
    end
    
    
    
    --判断play_num > 40
   	if play_num > 40 then
   	
   		if(not viplib.check_user_vip(userinfo))then
   			return;
   		end
   		
   		--如果所以箱子未开启，不进入
    	if(boxs[1].opened == 1 and boxs[2].opened == 1)then
   		
	        play_num = 0;
	        need_show=1;
	        gamedata.playgameinfo.play_num = play_num;
	        
	        local szbox_info = ""
	        
	      
	        --VIP再开一轮
	        if(viplib.get_vip_level(userinfo) < 4 and userinfo.christmasActivity_openNm <= 2)then  --VIP可开2次循环共4个箱子
				
				szbox_info = "1:"..christmasLib.box1_num..":0:0|2:"..christmasLib.box2_num..":0:0";
	        	 
	        	local lj_num =  userinfo.christmasActivity_openNm;
	        	
		        	local sqltemplet = "update user_treasurebox_info ";
		                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1, lj_num = "..lj_num;
		                sqltemplet = sqltemplet.." where user_id = %d and game_name = '%s'; commit;";
		                
		                dblib.execute(string.format(sqltemplet, userinfo.userId, gamepkg.name))
		       	
	
	    	elseif(viplib.get_vip_level(userinfo) >= 4 and userinfo.christmasActivity_openNm <= 3)then  --VIP4、5可开3次循环共6个箱子
		
		  		szbox_info = "1:"..christmasLib.box1_num..":0:0|2:"..christmasLib.box2_num..":0:0";
		    		
		    		local lj_num =  userinfo.christmasActivity_openNm;
		    		
		    		local sqltemplet = "update user_treasurebox_info ";
		                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1, lj_num = "..lj_num;
		                sqltemplet = sqltemplet.." where user_id = %d and game_name = '%s'; commit;";
		                
		                dblib.execute(string.format(sqltemplet, userinfo.userId, gamepkg.name))
		                
		    else
		    	return; 
  
	        end
        
        else
	       	return;
          		
    	end
    	
    else

	   --记录到数据库

	   local sqltemplet = "update user_treasurebox_info set play_num = %d, need_show = %d, lj_num =%d  where user_id = %d and game_name = '%s'; commit;";
	   local sql=string.format(sqltemplet, play_num, need_show,userinfo.christmasActivity_openNm or 0 , userinfo.userId, gamepkg.name);
	   --TraceError(sql)
	   dblib.execute(sql);

	end
	
	
   --通知客户端
   christmasLib.netSendPlaynumAndBoxs_ChristmasActivity(userinfo, play_num, boxs, need_show);
   
end

--发送盘数和箱子ID
christmasLib.netSendPlaynumAndBoxs_ChristmasActivity = function(userinfo, playnum, boxs, need_show)
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
christmasLib.onRecvOpenBox_ChristmasActivity = function(buf)
   local userinfo = userlist[getuserid(buf)];
   if not userinfo then return end;
 
 	--TraceError("收到玩家打开箱子")
 	
   --判断活动有效性
	if not christmasLib.checker_time_valid() then
       return;--无效日期
   end
 
   local gamedata = deskmgr.getuserdata(userinfo);
   if not gamedata.playgameinfo then return end;
   
   local boxid = buf:readByte();
   
   if(userinfo.christmasActivity_openNm >= 1 and not viplib.check_user_vip(userinfo))then	-- 非VIP可开宝箱1次循环共2个箱子

		return;    
   elseif(userinfo.christmasActivity_openNm >=2  and viplib.get_vip_level(userinfo) < 4)then  --VIP可开2次循环共4个箱子

       return;
   elseif(userinfo.christmasActivity_openNm >=3  and viplib.get_vip_level(userinfo) >= 4)then  --VIP4.5可开3次循环共6个箱子

       return;
   end
   
   --1.银宝箱  2.金宝箱
   if boxid ~= 1 and boxid ~= 2 then
     --  TraceError("收到错误的箱子id,不处理")
       return
   end
   local play_num = gamedata.playgameinfo.play_num;
   local need_show = gamedata.playgameinfo.need_show;
   local boxs = gamedata.playgameinfo.boxs;
   if(boxs[boxid] == nil) then
   --  TraceError("请求的箱子["..boxid.."]不属于此玩家["..userinfo.userId.."]");
     return;
   end
   if(gamedata.playgameinfo.play_num < boxs[boxid].neednum) then
  --   TraceError("请求的箱子["..boxid.."]需要游戏["..boxs[boxid].neednum.."]盘之后才可以开启");
     return;
   end
   if(boxs[boxid].opened ~= 0) then
  --   TraceError("请求的箱子["..boxid.."]已经开过");
     return;
   end
   local prizeid = boxs[boxid].prizeid
   if(prizeid <= 0) then
        --随机生成奖品ID
        local sql = format("call sp_get_random_spring_gift(%d, '%s', %d)", userinfo.userId, "tex", boxid)
 
        dblib.execute(sql, function(dt)
            if(dt and #dt > 0)then
                prizeid = dt[1]["gift_id"]
                local prizename = dt[1]["gift_des"] or ""
                if(prizeid <= 0) then
                    return;
                 end       
                local boxname = "";
                if(boxid == 1) then
                    --boxname = "银宝箱";
                    boxname = tex_lan.get_msg(userinfo, "treasure_box_type_silver");
                elseif(boxid == 2) then
                    --boxname = "金宝箱";
                    boxname = tex_lan.get_msg(userinfo, "treasure_box_type_gold");
                end
                 
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
   
              	--记录打开一轮
              	if(boxs[1].opened == 1 and boxs[2].opened == 1)then
              		need_show = 2;--记录打开一轮
              	end
              	
                 gamedata.playgameinfo.need_show = need_show;
                 --记录到数据库
                 local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d,lj_num =%d where user_id = %d and game_name = '%s'; commit;";
                 dblib.execute(string.format(sqltemplet, box_info, need_show,userinfo.christmasActivity_openNm, userinfo.userId, gamepkg.name));
                 --写入日志
                 sqltemplet = "insert into log_treasurebox_prize(user_id, game_name, sys_time, box_id, prize_id) "
                 sqltemplet = sqltemplet.."values(%d,'%s',now(),%d,%d);commit; "
                 --通知玩家得到什么奖品
                christmasLib.netSendOpenBox_ChristmasActivity(userinfo, boxid, prizeid);
                christmasLib.netSendPlaynumAndBoxs_ChristmasActivity(userinfo, play_num, boxs, need_show);
            else
          --      TraceError(format("随机奖品失败，sql=%s",sql))
            end
         end)
    else   
        --通知玩家得到什么奖品
        christmasLib.netSendOpenBox_ChristmasActivity(userinfo, boxid, prizeid);
        christmasLib.netSendPlaynumAndBoxs_ChristmasActivity(userinfo, play_num, boxs, need_show);
    end;
end
 
--收到玩家领奖啦
christmasLib.onRecvGetPrize_ChristmasActivity = function(buf)
--   TraceError("收到玩家领奖 _ChristmasActivity")
   local userinfo = userlist[getuserid(buf)];
   if not userinfo then return end;
   --合法性检查
   if not christmasLib.checker_time_valid() then
       return;
   end


	if(not viplib.check_user_vip(userinfo) and userinfo.christmasActivity_openNm >= 1)then

		return; --非VIP用户一轮返回
	elseif(viplib.get_vip_level(userinfo) < 4 and userinfo.christmasActivity_openNm >= 2 )then

		return;	--VIP1-3用户两轮返回
		
	elseif(viplib.get_vip_level(userinfo) >= 4 and userinfo.christmasActivity_openNm >= 3 )then

		return;	--VIP4，5用户三轮返回
	end
 
   local boxid = buf:readByte();
  
   if boxid ~= 1 and boxid ~= 2 then
   --    TraceError("收到错误的箱子id,不处理");
       return;
   end
   
   --通知玩家得到什么奖品
   christmasLib.doGiveUserGift_ChristmasActivity(userinfo, boxid);
  
end

--给玩家发奖(到这里就可以认为是合法领奖了)
christmasLib.doGiveUserGift_ChristmasActivity = function(userinfo, boxid)
--	TraceError("给玩家发奖 _ChristmasActivity")
    if not christmasLib.checker_time_valid() then
        return;
    end
    
  --  TraceError("给玩家发奖 _ChristmasActivity1111111111111")
    if not userinfo then return end;
    local gamedata = deskmgr.getuserdata(userinfo);
    if not gamedata.playgameinfo then return end;
    
    local play_num = gamedata.playgameinfo.play_num;
    local boxs = gamedata.playgameinfo.boxs;
    
    if(boxs[boxid] == nil) then
   --     TraceError("请求的箱子["..boxid.."]不属于此玩家["..userinfo.userId.."]");
        return;
    end
    if(gamedata.playgameinfo.play_num < boxs[boxid].neednum) then
   --     TraceError("请求的箱子["..boxid.."]需要游戏["..boxs[boxid].neednum.."]盘之后才可以开启");
        return;
    end
 --   TraceError("给玩家发奖 _ChristmasActivity22222222222222")
    if(boxs[boxid].opened ~= 0) then
 --       TraceError("请求的箱子["..boxid.."]已经开过");
        return;
    end
  --  TraceError("给玩家发奖 _ChristmasActivity3333333333")
    if(boxs[boxid].prizeid <= 0) then
   --     TraceError("领奖了，箱子的奖品还没生成？？？");
        return;
    end
    local prizeid = boxs[boxid].prizeid;
    
    --设置箱子开过
    boxs[boxid].opened = 1;
    
    local need_show = 2;
    local box_info = "";
    for k,v in pairs(boxs) do
        box_info = box_info ..format("%d:%d:%d:%d|", tostring(k), tostring(v.neednum), tostring(v.opened), tostring(v.prizeid));
        if v.opened == 0 then
            need_show = 1;
        end
    end
    
     --1:这是第一轮开启完毕；2：这是第二轮开启完毕;3:其它情况
	if(boxs[1].opened == 1 and boxs[2].opened == 1)then

		if(userinfo.christmasActivity_openNm==nil)then 
			userinfo.christmasActivity_openNm=1 
		else
			userinfo.christmasActivity_openNm = userinfo.christmasActivity_openNm + 1;		
		end
		
		local vip_lev = viplib.get_vip_level(userinfo);
		if(not viplib.check_user_vip(userinfo)  )then	-- 非VIP可开宝箱1次循环共2个箱子
        	need_show = 2;
        	--记录到数据库
	    	local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d,lj_num =%d where user_id = %d and game_name = '%s'; commit;";
	    	dblib.execute(string.format(sqltemplet, box_info, need_show,userinfo.christmasActivity_openNm, userinfo.userId, gamepkg.name));
	    	
	    elseif(viplib.get_vip_level(userinfo) < 4 and userinfo.christmasActivity_openNm <= 1 )then  --VIP可开2次循环共4个箱子
		
	        need_show = 1;
	        play_num = 0
	        gamedata.playgameinfo.play_num = play_num;
	        local lj_num = userinfo.christmasActivity_openNm
	        
	        local szbox_info = ""
 	  			szbox_info = "1:"..christmasLib.box1_num..":0:0|2:"..christmasLib.box2_num..":0:0";
	        	 
		        	local sqltemplet = "update user_treasurebox_info ";
	--	        	TraceError("before:"..sqltemplet)
		                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1, lj_num = "..lj_num;
	--	            TraceError("after1:"..sqltemplet)
		                sqltemplet = sqltemplet.." where user_id = %d and game_name = '%s'; commit;";
	--	            TraceError("after2:"..sqltemplet)
		                dblib.execute(string.format(sqltemplet, userinfo.userId, gamepkg.name))
			 --查询  
			local strsql = "select * from user_treasurebox_info where user_id = %d and game_name = '%s'; ";
		    dblib.execute(strsql,
		    function(dt)
		        if dt and #dt > 0 then

		                gamedata.playgameinfo.boxs = christmasLib.gettable(dt[1]["box_info"]);
		                gamedata.playgameinfo.play_num = dt[1]["play_num"];
		                gamedata.playgameinfo.login_time = timelib.db_to_lua_time(dt[1]["login_time"]);
		                gamedata.playgameinfo.need_show = dt[1]["need_show"];
		         end
		         
		            boxs = gamedata.playgameinfo.boxs;
		     end)
 
	    elseif(viplib.get_vip_level(userinfo) >= 4 and userinfo.christmasActivity_openNm <= 2)then  --VIP4、5可开3次循环共6个箱子
	    	need_show = 1;
	    	play_num = 0
	        gamedata.playgameinfo.play_num = play_num;
	        
	        local lj_num = userinfo.christmasActivity_openNm
	        
	             local szbox_info = ""
 	  			szbox_info = "1:"..christmasLib.box1_num..":0:0|2:"..christmasLib.box2_num..":0:0";
	        	 
		        	local sqltemplet = "update user_treasurebox_info ";
		                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1, lj_num = "..lj_num;
		                sqltemplet = sqltemplet.." where user_id = %d and game_name = '%s'; commit;";
		                
		                dblib.execute(string.format(sqltemplet, userinfo.userId, gamepkg.name))
		         --查询       
		         local strsql = "select * from user_treasurebox_info where user_id = %d and game_name = '%s'; ";
			    dblib.execute(strsql,
			    function(dt)
			        if dt and #dt > 0 then
	
			                gamedata.playgameinfo.boxs = christmasLib.gettable(dt[1]["box_info"]);
			                gamedata.playgameinfo.play_num = dt[1]["play_num"];
			                gamedata.playgameinfo.login_time = timelib.db_to_lua_time(dt[1]["login_time"]);
			                gamedata.playgameinfo.need_show = dt[1]["need_show"];
			         end
			         
			            boxs = gamedata.playgameinfo.boxs;
			     end)
		 else
		 	need_show = 2;
		 	--记录到数据库
	    	local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d, lj_num =%d where user_id = %d and game_name = '%s'; commit;";
	    	dblib.execute(string.format(sqltemplet, box_info, need_show,userinfo.christmasActivity_openNm, userinfo.userId, gamepkg.name));
		            
	    end

	else
	
		--记录到数据库
   
	    local sqltemplet = "update user_treasurebox_info set box_info = '%s', need_show = %d, lj_num =%d where user_id = %d and game_name = '%s'; commit;";
	    	dblib.execute(string.format(sqltemplet, box_info, need_show,userinfo.christmasActivity_openNm, userinfo.userId, gamepkg.name));
	    
	end
    
    gamedata.playgameinfo.need_show = need_show;
 
	    
    --派发奖品啦
    if(boxid == 1)then		--银宝箱
	    --派发奖品啦
	    if(prizeid == 1) then  --200筹码
	    	--加200筹码
	      	usermgr.addgold(userinfo.userId, 200, 0, g_GoldType.baoxiang, -1);
	 
	    elseif(prizeid == 2) then  --1K筹码
	      	--加200筹码
	      	usermgr.addgold(userinfo.userId, 1000, 0, g_GoldType.baoxiang, -1);
	      	
	    elseif(prizeid == 3) then  --小喇叭
	      	--小喇叭怎么加
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, userinfo)
	    elseif(prizeid == 4) then  --5W筹码
			--加5W筹码
			usermgr.addgold(userinfo.userId, 50000, 0, g_GoldType.baoxiang, -1);
			
	    elseif(prizeid == 5) then  --方舟资格证书
	      	--加方舟资格证书
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.ShipTickets_ID, 1, userinfo)
	    elseif(prizeid == 6) then  --圣诞火鸡礼物
	    	--加圣诞火鸡礼物
	      	gift_addgiftitem(userinfo,9012,userinfo.userId,userinfo.nick, false)
	    else
	  --    TraceError("未知宝箱!!!!!!");
	      return;
	    end
	elseif(boxid == 2)then	--金宝箱
		if(prizeid == 1) then  --1K筹码
	    	--加1K筹码
	      	usermgr.addgold(userinfo.userId, 1000, 0, g_GoldType.baoxiang, -1);
	 
	    elseif(prizeid == 2) then  --1W筹码
	      	--加1W筹码
	      	usermgr.addgold(userinfo.userId, 10000, 0, g_GoldType.baoxiang, -1);
	      	
	    elseif(prizeid == 3) then  --T人卡
	      	--T人卡怎么加
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, userinfo)
	    elseif(prizeid == 4) then  --50W筹码
			--加50W筹码
			usermgr.addgold(userinfo.userId, 500000, 0, g_GoldType.baoxiang, -1);
			
	    elseif(prizeid == 5) then  --方舟资格证书
	      	--加方舟资格证书
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.ShipTickets_ID, 1, userinfo)
	    elseif(prizeid == 6) then  --圣诞树礼物
	    	--加圣诞树礼物
			gift_addgiftitem(userinfo,9013,userinfo.userId,userinfo.nick, false)
		else	--错误
	--		TraceError("未知宝箱!!!");
		    return;
		end

	end
    
    --通知玩家领到什么奖品
 --	TraceError("通知玩家领到什么奖品,userinfo"..userinfo.userId.."boxid"..boxid.."prizeid"..prizeid..""); 
    christmasLib.netSendGiftInfo_ChristmasActivity(userinfo, boxid, prizeid);
    christmasLib.netSendPlaynumAndBoxs_ChristmasActivity(userinfo, play_num, boxs, need_show);
end

--通知玩家得到什么奖品
christmasLib.netSendOpenBox_ChristmasActivity = function(userinfo, boxid, prizeid)
--	TraceError("通知玩家得到什么奖品_ChristmasActivity")
    netlib.send(function(buf)
            buf:writeString("TBHDOB");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
        end,userinfo.ip,userinfo.port);
end

--通知玩家领到什么奖品
christmasLib.netSendGiftInfo_ChristmasActivity = function(userinfo, boxid, prizeid)
--	TraceError("通知玩家领到什么什么什么奖品 _ChristmasActivity")
    netlib.send(function(buf)
            buf:writeString("TBHDGP");
            buf:writeInt(boxid);
            buf:writeInt(prizeid);
            buf:writeByte(userinfo.christmasActivity_openNm or 0);-- : 1:这是第一轮开启完毕；2：这是第二轮开启完毕;3:其它情况
        end,userinfo.ip,userinfo.port);
end

--收到请求盘数和箱子数
christmasLib.onRecvGetPlayNumAndBox_ChristmasActivity = function(buf)
   -- TraceError("收到请求盘数和箱子数 ChristmasActivity");
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    
    if not christmasLib.checker_time_valid() then
        return;
    end
    
    if(not viplib.check_user_vip(userinfo) and userinfo.christmasActivity_openNm >= 1)then
		
		return; --非VIP用户一轮返回
	elseif(viplib.get_vip_level(userinfo) < 4 and userinfo.christmasActivity_openNm >= 2 )then

		return;	--VIP1-3用户两轮返回
		
	elseif(viplib.get_vip_level(userinfo) >= 4 and userinfo.christmasActivity_openNm >= 3 )then

		return;	--VIP4，5用户三轮返回
	end
     
    local szbox_info = ""
  
    szbox_info = "1:"..christmasLib.box1_num..":0:0|2:"..christmasLib.box2_num..":0:0";
 
    sqltemplet = "select login_time,box_info,play_num,need_show,lj_num from user_treasurebox_info where user_id = %d and game_name = '%s'; ";
    
    local userid = userinfo.userId;
    local gamename = gamepkg.name;

    local strsql = string.format(sqltemplet, userid, gamename);
    dblib.execute(strsql,
    function(dt)
        if dt and #dt > 0 then
        --TraceError("收到请求盘数和箱子数 ChristmasActivity1111111111111111");
            local gamedata = deskmgr.getuserdata(userinfo);
            local lj_num = 0
            --写入内存数据
            gamedata.playgameinfo = {}
            local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["login_time"]));  --数据库的今天
            if (db_date ~= sys_today) then
            --TraceError("收到请求盘数和箱子数 ChristmasActivity22222222222222");
                gamedata.playgameinfo.boxs = {};
                gamedata.playgameinfo.boxs[1] = {neednum = christmasLib.box1_num, opened = 0, prizeid = 0};
                gamedata.playgameinfo.boxs[2] = {neednum = christmasLib.box2_num, opened = 0, prizeid = 0};
                gamedata.playgameinfo.play_num = 0;
                gamedata.playgameinfo.login_time = os.time();
                gamedata.playgameinfo.need_show = 1;

                local sqltemplet = "update user_treasurebox_info ";
                sqltemplet = sqltemplet.."set login_time = now(), box_info = '"..szbox_info.."', play_num = 0, need_show = 1, lj_num = "..lj_num;
                sqltemplet = sqltemplet.." where user_id = %d and game_name = '%s'; commit;";
                
                dblib.execute(string.format(sqltemplet, userid, gamename))
            else
                gamedata.playgameinfo.boxs = christmasLib.gettable(dt[1]["box_info"]);
                gamedata.playgameinfo.play_num = dt[1]["play_num"];
                gamedata.playgameinfo.login_time = timelib.db_to_lua_time(dt[1]["login_time"]);
                gamedata.playgameinfo.need_show = dt[1]["need_show"];
                userinfo.christmasActivity_openNm=dt[1]["lj_num"];
            end
            local playnum = gamedata.playgameinfo.play_num;
            local boxs = gamedata.playgameinfo.boxs;
            local need_show = gamedata.playgameinfo.need_show;
            christmasLib.netSendPlaynumAndBoxs_ChristmasActivity(userinfo, playnum, boxs, need_show);
        else
  --          TraceError(" 查询数据库时出错:" .. strsql);
        end
    end)
end


--命令列表
cmdHandler = 
{
    ["TBHDOK"] = christmasLib.onRecvChristmasActivityStat, --查询活动是否进行中
    ["TBHDPN"] = christmasLib.onRecvGetPlayNumAndBox_ChristmasActivity, -- 收到登陆成功
    ["TBHDOB"] = christmasLib.onRecvOpenBox_ChristmasActivity, -- 收到打开箱子，随机奖品
    ["TBHDGP"] = christmasLib.onRecvGetPrize_ChristmasActivity, -- 收到领取奖励
 
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

