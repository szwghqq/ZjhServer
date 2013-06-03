TraceError("加载 dhomelib 插件....")

if not dhomelib then
	dhomelib = _S
	{
        update_share_info           = NULL_FUNC,    --更新分享信息
        net_send_share_info         = NULL_FUNC,    --发送分享事件
        on_recv_check_have_right    = NULL_FUNC,    --检查是否有资格开通家园
        notify_add_friend = NULL_FUNC, --添加好友通知
        update_user_home_status = NULL_FUNC, --更新家园标识
        get_user_home_status = NULL_FUNC, --获取家园标识
        update_user_home_info = NULL_FUNC, --设置家园头像
        deal_game_home_message=NULL_FUNC, --同步消息
        first_sync_friends=NULL_FUNC,  --第一次开通家园要同步好
        
        ----------------德州分享统计活动-----------
        onRecvActiveStat = NULL_FUNC,	--请求活动进行状态
		onRecvActiveCount= NULL_FUNC,	--查询被崇拜/鄙视的次数
		onRecvEvaluate= NULL_FUNC,	--崇拜或鄙视某人
 		on_after_user_login= NULL_FUNC,	--初始化玩家分享信息 
		net_send_friend_share_info= NULL_FUNC,--通知客户端，弹出好友动态分享框
        sendActiveCount=NULL_FUNC,		--通知客户端，新的被赞和鄙视次数
        isVaildTime=NULL_FUNC,		--是否是有效时间内的
        
        statime = "2011-12-16 00:00:00",  --活动开始时间
        endtime = "2011-12-19 00:00:00",  --活动结束时间
        
	}
end

--更新分享信息
dhomelib.update_share_info = function(userinfo, share_id, data)
    if not userinfo then return end;
    --TraceError("达到分享到家园条件share_id：".. share_id)
    dhomelib.net_send_share_info(userinfo, share_id, data)
    
    --通知客户端，弹出好友动态分享框
    if(share_id==4001)then
       	dhomelib.net_send_friend_share_info(userinfo, share_id, data)
    end
end

--发送到客户端，分享ID
dhomelib.net_send_share_info = function(userinfo, share_id, data)
    local smallbet = 0
    local largebet = 0
    local winchouma = 0
    local paixing = -1
    if(data ~= nil) then
        smallbet = data.smallbet and data.smallbet or 0
        largebet = data.largebet and data.largebet or 0
        winchouma = data.winchouma and data.winchouma or 0
        paixing = data.paixing and data.paixing or -1
    end
    if paixing ~= 0 then
    
	    netlib.send(
	        function(buf)
	            buf:writeString("TXSHAREDH")
	            buf:writeInt(share_id)  --分享ID
	            buf:writeInt(smallbet)
	            buf:writeInt(largebet)
	            buf:writeInt(winchouma)
	            buf:writeInt(paixing)
	        end,userinfo.ip,userinfo.port)
	 end
end

--检查是否有资格开通家园
dhomelib.on_recv_check_have_right = function(buf)
    local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    
    local vip_level = 0
    if viplib then
        vip_level = viplib.get_vip_level(userinfo)
    end

    local tex_daren_count = 0
    if(userinfo.wdg_huodong ~= nil) then
        tex_daren_count = userinfo.wdg_huodong.daren_count or 0
    end

    local result = 0
    if(usermgr.getlevel(userinfo) >= 60 or vip_level >= 5 or tex_daren_count > 0) then
        result = 1
    end

    netlib.send(
        function(buf)
            buf:writeString("TXCHRIGHT")
            buf:writeByte(result)  --结果：0，表示资格不够；1，表示有资格
           
        end,userinfo.ip,userinfo.port)
end

function dhomelib.notify_add_friend(user_id_1, user_id_2)

    usermgr.get_passport_by_user_id(user_id_1, function(passport1)
        if (passport1 == nil) then return end
        usermgr.get_passport_by_user_id(user_id_2, function(passport2)
            if (passport2 == nil) then return end
            local user_info_1 = usermgr.GetUserById(user_id_1)
            local user_info_2 = usermgr.GetUserById(user_id_2)
            if(user_info_1==nil or user_info_2==nil)then
            	return
            end
            local sql = "insert into game_home_message(sys_time, msg_type, arg1, arg2, arg3, arg4)values(now(), 3, '%s', '%s', '%s', '%s')"
            sql = string.format(sql,  passport1, passport2,user_info_1.nick, user_info_2.nick)
            --dblib.execute(sql, function()end, user_id_1, common_db_info.home)            
        end)
    end)
end

function dhomelib.update_user_home_status(user_info)

	if(user_id==nil)then return end
	local sql="update user_homezone_info set home_status=1 where user_id=%d"
	sql=string.format(sql,user_info.userId)
	dblib.execute(sql, nil, user_info.userId)
	user_info.home_status=1;
end

function dhomelib.get_user_home_status(user_info)

	if(user_info==nil)then return end
	local sql="select home_status,home_face from user_homezone_info where user_id=%d"
	sql=string.format(sql,user_info.userId)
	 dblib.execute(sql,function(dt)
	  if(dt and #dt > 0) then
	  	--0代表未开通
	  	user_info.home_face = dt[1].home_face or "";
	  	user_info.home_status = dt[1].home_status or 0;
		--如果玩家没更新过头像，那么就可以认为没开通家园
	  	if user_info.home_face == nil or user_info.home_face == "" then
	  		user_info.home_status = 0
	  	end
      end

      if(user_info.home_status == nil) then
        user_info.home_status = 0;
      end

      if(user_info.home_face == "") then
          user_info.home_face = "";
      end

      
    end)		
end

--第一次开通家园时要做一下同步
function dhomelib.first_sync_friends(user_id)
	--TraceError("first sync friends")
	local sql="select friends from user_friends where user_id=%d"
	
	sql=string.format(sql,user_id)
	--TraceError("sql="..sql)
	dblib.execute(sql,function(dt)
		if(dt and #dt > 0) then
			local t_friend = split(dt[1].friends, "|")
            
			for k,v in pairs(t_friend) do
			
			    if(tonumber(v) ~= nil)then
			   		--TraceError("t_friend="..tonumber(v))
			        dhomelib.notify_add_friend(user_id, tonumber(v))			        
			    end
			end
		end
	end)
end


--同步达人家园的消息
function dhomelib.update_user_home_info(user_id,face)
	if(face==nil) then face="" end;
	if(user_id==nil)then
		TraceError("user_id error")
		return
	end
	local sql="insert into user_homezone_info (user_id,home_face,home_status) value(%d,'%s',1) ON DUPLICATE KEY UPDATE home_face='%s'"
	sql=string.format(sql,user_id,face,face);
	dblib.execute(sql, nil, user_id);
end

--同步达人家园的消息
function dhomelib.deal_game_home_message()
	--TraceError("deal_game_home_message")
    --如果还在处理上一轮，就返回
    if(room.process_game_home_msg_ok == 0) then
        return
    end
    
    local del_msg_by_id=function(id)
    	local sql="INSERT INTO log_game_home_message(msg_id,sys_time,msg_type,arg1,arg2,arg3,arg4,del_time) SELECT id AS msg_id,sys_time,msg_type,arg1,arg2,arg3,arg4,NOW() as del_time FROM game_home_message WHERE id=%d;"
    	sql=sql.."delete from game_home_message where id=%d;commit;";
    	sql=string.format(sql,id,id)
    	dblib.execute(sql)
	end
	
    room.process_game_home_msg_ok = 0
    local process_msg_fun = function(dt)

        if(not dt or #dt <= 0) then 
    		room.process_game_home_msg_ok = 1
    		return 
        end
  
        for i = 1, #dt do

            if (dt[i]["msg_type"] == 1) then  --修改头像
            	 if (dt[i]["arg1"] == nil or dt[i]["arg1"] == "") then
                    TraceError("协12passport为空")
                end
		
                usermgr.get_user_id_by_passport(dt[i]["arg1"], function(user_id)
                    if (user_id == nil) then return end
		
                    dblib.cache_set("users",  {face = dt[i]["arg2"]}, "id", user_id)
		   
                    dhomelib.update_user_home_info(user_id,dt[i]["arg2"])   
		
                end)			
    		elseif (dt[i]["msg_type"] == 2) then --修改昵称
    		
		if (dt[i]["arg1"] == nil or dt[i]["arg1"] == "") then
                    TraceError("协议2passport为空")
                end
    			usermgr.get_user_id_by_passport(dt[i]["arg1"], function(user_id)
                    if (user_id == nil) then return end
                
    				dblib.cache_set("users",  {nick_name = string.trans_str(dt[i]["arg2"])}, "id", user_id)  
			
    				--第一次开通家园要同步好友
					dhomelib.first_sync_friends(user_id)              
    			end)
				
    		elseif (dt[i]["msg_type"] == 3) then --加好友
    			local add_gamefriend_sql="update user_friends set friends = concat(friends,%s) where user_id = %d;commit;"
    			usermgr.get_user_id_by_passport(dt[i]["arg1"], function(user_id_1)
    				if (user_id_1 == nil) then return end					
    				usermgr.get_user_id_by_passport(dt[i]["arg2"], function(user_id_2)
    					if (user_id_2 == nil) then return end
    						local usergamestr = tostring(user_id_1) .. "|"
    						local add_friend_sql=string.format(add_gamefriend_sql,dblib.tosqlstr(usergamestr),user_id_2)
    						dblib.execute(add_friend_sql)
    						usergamestr = tostring(user_id_2) .. "|"
    						add_friend_sql=string.format(add_gamefriend_sql,dblib.tosqlstr(usergamestr),user_id_1)
							dblib.execute(add_friend_sql)
    				end)
    			end)
    		elseif (dt[i]["msg_type"] == 4) then --删除好友
    			usermgr.get_user_id_by_passport(dt[i]["arg1"], function(user_id_1)
    				if (user_id_1 == nil) then return end					
    				usermgr.get_user_id_by_passport(dt[i]["arg2"], function(user_id_2)
    					if (user_id_2 == nil) then return end
    					local sql = "UPDATE user_friends SET friends = REPLACE(friends , '%s', '') WHERE user_id= %d;commit"
                        local sql_temp = string.format(sql, user_id_1.."|", user_id_2)
    					dblib.execute(sql_temp)
    					sql_temp = string.format(sql, user_id_2.."|", user_id_1)
    					dblib.execute(sql_temp)					
    				end)
    			end)
    			
    		elseif (dt[i]["msg_type"] == 5) then --开通的话显示V字
    			usermgr.get_user_id_by_passport(dt[i]["arg1"], function(user_id) 
					dhomelib.update_user_home_info(user_id) 
				end)
            end
            --默认每个消息都是执行成功的
            --删除这条消息，如果对数据要求高的话，就要在每个消息执行sql时，#dt>0才删除消息。
            del_msg_by_id(dt[i].id) 
        end
        room.process_game_home_msg_ok = 1
    end
    dblib.execute("select * from game_home_message order by id asc limit 0,100", process_msg_fun)
end




----------------德州分享统计活动-----------

--是否在有效时间内
function dhomelib.isVaildTime()	
    local sys_time = os.time();
    local statime = timelib.db_to_lua_time(dhomelib.statime);
	local endtime = timelib.db_to_lua_time(dhomelib.endtime);
    if(sys_time >= statime and sys_time <= endtime) then
    	return 0
    else
    	return 1
	end
end

--请求活动进行状态
function dhomelib.onRecvActiveStat(buf)
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    
  
    --判断活动有效性
	if(dhomelib.isVaildTime()==0) then
         netlib.send(function(buf)
            buf:writeString("FRACTIVED")
            buf:writeByte(1)		--正常活动日期
        end,userinfo.ip,userinfo.port)
    else
    	netlib.send(function(buf)
            buf:writeString("FRACTIVED")
            buf:writeByte(0)		--无效日期
        end,userinfo.ip,userinfo.port)
	end

end 

--查询被崇拜/鄙视的次数
function dhomelib.sendActiveCount(userinfo)
	
    if not userinfo then return end;
    
    netlib.send(function(buf)
            buf:writeString("FRACTIVECOUNT")
            buf:writeInt(userinfo.praise_count or 0)		--崇拜的次数
			buf:writeInt(userinfo.curse_count or 0)		--被鄙视的次数
        end,userinfo.ip,userinfo.port)
end


--查询被崇拜/鄙视的次数
function dhomelib.onRecvActiveCount(buf)
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    dhomelib.sendActiveCount(userinfo)
  
end

--崇拜或鄙视某人
function dhomelib.onRecvEvaluate(buf)
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
   
    local nUserID = buf:readInt()	--被崇拜或鄙视的玩家ID
    local nEvaluate = buf:readInt()	--赞类型：1，崇拜；2，鄙视
	local sql=""
	
	--给投票的玩家加100块,最多只能投票11次
	local praise_other_count=userinfo.praise_other_count or 0;
	local curse_other_count=userinfo.curse_other_count or 0;
	
	if(userinfo.praise_other_count==nil)then userinfo.praise_other_count=0 end;
	if(userinfo.curse_other_count==nil)then userinfo.curse_other_count=0 end;
	
	
	--保存崇拜或鄙视别人的信息			
	if(curse_other_count+praise_other_count<11)then
		if(nEvaluate==1)then
			userinfo.praise_other_count=userinfo.praise_other_count+1
			sql="insert into user_dhomeshare_info(user_id, share_status, share_count) values(%d,%d,1) ON DUPLICATE KEY UPDATE share_count=share_count+1;" 
			sql=string.format(sql,userinfo.userId,3) 
		elseif(nEvaluate==2)then
			userinfo.curse_other_count=userinfo.curse_other_count+1
			sql="insert into user_dhomeshare_info(user_id, share_status, share_count) values(%d,%d,1) ON DUPLICATE KEY UPDATE share_count=share_count+1;" 
			sql=string.format(sql,userinfo.userId,4) 
		end
    	usermgr.addgold(userinfo.userId, 100, 0, g_GoldType.dhome_share_gold, -1, 1);
    	--写崇拜或鄙视别人的记录
    	dblib.execute(sql)
    end
    
    --写被崇拜的记录
    local org_userinfo=usermgr.GetUserById(nUserID)
    if (org_userinfo.praise_count==nil) then org_userinfo.praise_count=0 end
    if (org_userinfo.curse_count==nil) then org_userinfo.curse_count=0 end
    if(nEvaluate==1)then
    	org_userinfo.praise_count=org_userinfo.praise_count+1
    elseif(nEvaluate==2)then
    	org_userinfo.curse_count=org_userinfo.curse_count+1
    end
    --被赞和鄙视的次数变化了，所以要发消息给客户端
    dhomelib.sendActiveCount(org_userinfo)
    
    --保存到数据库
    sql="insert into user_dhomeshare_info(user_id, share_status, share_count) values(%d,%d,1) ON DUPLICATE KEY UPDATE share_count=share_count+1;" 
	sql=string.format(sql,nUserID,nEvaluate)
	dblib.execute(sql)
 
end

--通知客户端，弹出好友动态分享框
dhomelib.net_send_friend_share_info = function(userinfo, share_id, data)
    local smallbet = 0
    local largebet = 0
    local winchouma = 0
    
    --不是有效时间的话，有直接不分享
    if(dhomelib.isVaildTime()~=0) then
    	return
    end
    
    --如果不是家园用户就直接退出
    if(userinfo==nil or userinfo.home_status==nil or userinfo.home_status~=1)then
    	return    	
    end

    
    if(data ~= nil) then
        smallbet = data.smallbet and data.smallbet or 0
        largebet = data.largebet and data.largebet or 0
        winchouma = data.winchouma and data.winchouma or 0
        paixing = data.paixing and data.paixing or -1
    end

    --判断是否在线
   	local function is_online(user_id)
        if (usermgr.GetUserById(user_id) == nil) then
            return 0
        else
            return 1
        end
   	end
	   	
	--给在线好友分享消息
	for k, v in pairs(userinfo.friends) do
	   local info = userinfo.friends[tonumber(k)].userinfo
	   if(info~=nil and is_online(info.userid)==1)then
	   		local friend_userinfo=usermgr.GetUserById(info.userid)
	  		 if(friend_userinfo~=nil)then
	  		 
	  		 		--如果总次数超过11次的好友，不需要让他赞或鄙视了
	  		 		if(friend_userinfo.praise_other_count==nil)then friend_userinfo.praise_other_count=0 end;
					if(friend_userinfo.curse_other_count==nil)then friend_userinfo.curse_other_count=0 end;
					
					
					--保存崇拜或鄙视别人的信息			
					if(friend_userinfo.curse_other_count+friend_userinfo.praise_other_count<11)then
					    netlib.send(
					        function(buf)
					            buf:writeString("FRPOPACTIVE")
					            buf:writeInt(userinfo.userId)  --分享ID
					            buf:writeString(userinfo.nick or "")
					            buf:writeString(userinfo.face or "")
					            buf:writeInt(share_id)
					            buf:writeInt(smallbet)
					            buf:writeInt(largebet)
					            buf:writeInt(winchouma)
					            buf:writeInt(paixing)
					        end,friend_userinfo.ip,friend_userinfo.port)
				    end    
		        end
		end
	end

end

--初始化玩家分享信息 
dhomelib.on_after_user_login = function(userinfo)

	local sql="select share_status,share_count from user_dhomeshare_info where user_id=%d group by  share_status" 
	sql=string.format(sql,userinfo.userId)--类型：1，崇拜；
	dblib.execute(sql,function(dt)
		if dt==nil or #dt==0 then return end
		for i=1,#dt do
			if(dt[i].share_status==1)then --被崇拜
				userinfo.praise_count = dt[i].share_count or 0;
			elseif(dt[i].share_status==2)then --被鄙视
				userinfo.curse_count = dt[i].share_count or 0;
			elseif(dt[i].share_status==3)then --崇拜别人
				userinfo.praise_other_count = dt[i].share_count or 0;
			elseif(dt[i].share_status==4)then --鄙视别人
				userinfo.curse_other_count = dt[i].share_count or 0;
			end			
		end
	end)
	
end

--命令列表
cmd_userdiy_handler = 
{
   ["TXCHRIGHT"] = dhomelib.on_recv_check_have_right, --收到检查是否有资格开通家园
   
   ----------------德州分享统计活动-----------
   ["FRACTIVED"] = dhomelib.onRecvActiveStat, --请求活动进行状态
   ["FRACTIVECOUNT"] = dhomelib.onRecvActiveCount, --查询被崇拜/鄙视的次数
   ["FRACTIVEWHO"] = dhomelib.onRecvEvaluate, --崇拜或鄙视某人
}

--加载插件的回调
for k, v in pairs(cmd_userdiy_handler) do 
	cmdHandler_addons[k] = v
end



