TraceError("加载频道排行相关插件....")

if not tex_channelyw_lib then
	tex_channelyw_lib = _S
	{
        query_channelyw_info = NULL_FUNC,
    
	}
end
    
    
channel_yw_paimin_yestoday={}
channel_yw_paimin_lastweek={}
channel_yw_paimin_total={}
last_refresh_channel_day=""

--查询频道排行信息
function tex_channelyw_lib.query_channelyw_info(buf)
	local user_info = userlist[getuserid(buf)]; 
	--user_info.channel_id=444
    if(user_info == nil)then return end
    local query_time = buf:readByte()
	local query_type = buf:readByte()
	
		local send_result=function(channel_yw_paimin)
			if(query_type==0)then
				table.sort(channel_yw_paimin,
					function(a,b)
						if(tonumber(a.win_count)==tonumber( b.win_count))then
						     return tonumber(a.channel_id)>tonumber( b.channel_id)
						else
						     return tonumber(a.win_count)>tonumber( b.win_count)
						end
					end)
	    	elseif(query_type==1)then
	    		table.sort(channel_yw_paimin,
					function(a,b)
						if(tonumber(a.win_gold)==tonumber( b.win_gold))then
						     return tonumber(a.channel_id)>tonumber( b.channel_id)
						else
						     return tonumber(a.win_gold)>tonumber( b.win_gold)
						end
					end)
	    		
	    	elseif(query_type==2)then
	    		table.sort(channel_yw_paimin,
					function(a,b)
						if(tonumber(a.play_count)==tonumber( b.play_count))then
						     return tonumber(a.channel_id)>tonumber( b.channel_id)
						else
						     return tonumber(a.play_count)>tonumber( b.play_count)
						end
					end)
	    		
	    	end

	    	local tmpIndex=-1;
	    	for i=1,#channel_yw_paimin do
	    		--记下名次	    	
	    		channel_yw_paimin[i].mingci=i
	    		if(user_info.channel_id==tonumber(channel_yw_paimin[i].channel_id))then
					tmpIndex=i;
	    		end
	    	end
	    	--防止异步代码，第一个进入的人tmpIndex走到这里还是-1。
	    	--[[
	    		if(tmpIndex==-1)then
	    		netlib.send(function(buf)
	    
		    	 buf:writeString("CHANNELYW")
		    	 buf:writeByte(query_time)
		    	 buf:writeByte(query_type)
		    	buf:writeInt(0)
	    	    end, user_info.ip, user_info.port)
	    		return 
	    	end
	 	    --]]
	    	 netlib.send(function(buf)
	    
		    	 buf:writeString("CHANNELYW")
		    	 buf:writeByte(query_time)
		    	 buf:writeByte(query_type)
		    	 if(tmpIndex==-1)then
			     	buf:writeInt(0)
			     else
			     
					     
				    	 buf:writeInt((#channel_yw_paimin<100 and #channel_yw_paimin or 100)+1)
				  		--先发自己的频道	
				  			 buf:writeInt(channel_yw_paimin[tmpIndex].mingci or -1)
					       	 buf:writeString(user_info.channel_id or "")
					       	 buf:writeString(tostring(user_info.short_channel_id or -1))
					       	 local query_value=channel_yw_paimin[tmpIndex].win_count
							 if(query_type==1)then
							   	query_value=channel_yw_paimin[tmpIndex].win_gold
							 elseif (query_type==2) then
							 	query_value=channel_yw_paimin[tmpIndex].play_count
							 end			       	 
					       	 buf:writeString(query_value or 0)
					       	 
					     --再发排行里的频道
					     local tem_list_len=#channel_yw_paimin<100 and #channel_yw_paimin or 100
						 for i=1, tem_list_len do
					      	 buf:writeInt(channel_yw_paimin[i].mingci)
					       	 buf:writeString(channel_yw_paimin[i].channel_id)
					       	 buf:writeString(channel_yw_paimin[i].channel_name)
					       	 local query_value=channel_yw_paimin[i].win_count
							 if(query_type==1)then
							   	query_value=channel_yw_paimin[i].win_gold
							 elseif (query_type==2) then
							 	query_value=channel_yw_paimin[i].play_count
							 end
					       	 
					       	 buf:writeString(query_value)
			             end
			         end
			  end, user_info.ip, user_info.port)
    	end
	
		local refresh_paimin=function(query_time)

	    local sql="SELECT sys_time,channel_id,channel_name,sum(win_count) as win_count,sum(win_gold) as win_gold,sum(play_count) as play_count,sum(rich_count) as rich_count FROM channel_yw_paimin";
		    local query_name="win_count";
		    if(query_type==1)then
		    	query_name="win_gold";
		    elseif (query_type==2) then
		   		query_name="play_count";
		    end
		    
		    local query_where="";
		    
		    if(query_time==0)then
		    	query_where=" where date(sys_time)=date(now()) "
		    elseif(query_time==1)then
		   	    --因为sys_time是记录昨天的数据，所以上周数据要取上周二到这周一的数据代表上周一到周日
		    	query_where=" where sys_time>=DATE(DATE_ADD(NOW(), INTERVAL - ( 4 + DAYOFWEEK(NOW())) DAY)) and sys_time<DATE(DATE_ADD(NOW(), INTERVAL - (-3+ DAYOFWEEK(NOW())) DAY))"
		    end
		    
		    sql=sql..query_where.." group by channel_id order by "..query_name.." desc "
			dblib.execute(sql,function(dt)
				if(dt and #dt>0)then
				    	 for i=1,#dt do
							  	local bufftable ={
							  	    channel_id = tostring(dt[i].channel_id), 
				                    channel_name = dt[i].channel_name,
				                    win_count=dt[i].win_count,
				                    win_gold=dt[i].win_gold,
				                    play_count=dt[i].play_count,
				                    sys_time=dt[i].sys_time,
				                }
				             if(query_time==0)then			                    
				             	table.insert(channel_yw_paimin_yestoday, bufftable)
				             elseif(query_time==1)then
				            	 table.insert(channel_yw_paimin_lastweek, bufftable)
				             else
				             	table.insert(channel_yw_paimin_total, bufftable)
				             end
				         end
				   if(query_time==0)then
				    	send_result(channel_yw_paimin_yestoday);
				   elseif(query_time==1)then
				    	send_result(channel_yw_paimin_lastweek);
				   else
				    	send_result(channel_yw_paimin_total);
				   end
		   	end
			end)
		
  	end
	
	
	--因为是异步的，所以第一个访问的人可能看不到频道排行，考虑到性能的问题，暂时不改进。
	
  	  
    	
    	
    	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	    if(channel_yw_paimin_yestoday==nil or last_refresh_channel_day == nil or last_refresh_channel_day~=sys_today)then
	        refresh_paimin(0);
	        refresh_paimin(1);
	        refresh_paimin(2);
	        last_refresh_channel_day=sys_today;
	    end
    	--切换上周，昨天和总的
       if(query_time==0)then
	    	send_result(channel_yw_paimin_yestoday);
	   elseif(query_time==1)then
	    	send_result(channel_yw_paimin_lastweek);
	   else
	    	send_result(channel_yw_paimin_total);
	   end
    
end

--命令列表
cmd_tex_channelyw_lib_handler = 
{
	["CHANNELYW"] = tex_channelyw_lib.query_channelyw_info, --查询频道排行信息
}

--加载插件的回调
for k, v in pairs(cmd_tex_channelyw_lib_handler) do 
	cmdHandler_addons[k] = v
end



