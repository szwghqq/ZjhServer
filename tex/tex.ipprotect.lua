TraceError("加载 游戏设置 插件....")

if not tex_ip_protect_lib then
	tex_ip_protect_lib = _S
	{
        check_ip_address_protect = NULL_FUNC,
        unlock_user_protect = NULL_FUNC,   
        after_user_login = NULL_FUNC,  
        check_user_email = NULL_FUNC,	--检查用户email   
	}
end

--请求验证“异地上线保护”
function tex_ip_protect_lib.check_ip_address_protect(user_info)

	--向客户端返回结果的内部方法
	local send_check_ip = function(open_box,is_first)
		    netlib.send(function(buf)
		                    buf:writeString("TXCHECKIP")
		                    buf:writeByte(open_box)
		                    buf:writeByte(is_first)
		                end,
	                user_info.ip, user_info.port)    
	end
  	
  	
	--传入玩家ID，本次登陆的IP
	--返回玩家的历次的登陆IP，是否第一次登陆
	local send_user_ip_info = function(user_id,user_ip_address)
		local sql="SELECT safe_pw ,ipaddress,lockflag,last_ip FROM user_safebox_info AS a LEFT JOIN user_ip_protect_info b ON a.user_id=b.user_id WHERE a.user_id=%d;";
   
	    local ipaddress="";
	    local lockflag=0;
	    local safe_pw="";
	    --is_first是否第一次登陆，open_box是不是要弹窗
	    local is_first=1;
	    local open_box=0;--（1弹窗，0不弹窗）
	    sql=string.format(sql,user_id);
	    dblib.execute(sql,function(dt)
	        if(dt and #dt > 0) then
	        	ipaddress = dt[1].ipaddress;
	        	lockflag = dt[1].lockflag;
	        	safe_pw=dt[1].safe_pw;
	        	--如果没开通保险箱密码，直接不用弹窗
				if(safe_pw==nil or safe_pw=="") then
					open_box=0;				
	        	--如果ipaddress为空或nil，那么is_first=1否则为0
	            elseif(ipaddress~=nil and ipaddress~="")then
	            	is_first=0;	
			    	local pos=string.find(ipaddress,user_ip_address) or -1
			    	--返回客户端不用弹窗（1弹窗，0不弹窗）
			    	if(pos==-1)then	
			    		
			    		open_box=1;
			    	else			    		
			    		open_box=0;
			    	end
			    	--1.有没有channel_id，2.last_ip是不是相同
			    	local user_info=usermgr.GetUserById(user_id);
			    	if(user_info~=nil and user_info.channel_id~=nil and user_info.channel_id>0
			    		 and user_info.ip~=dt[1].last_ip)then
			    		open_box=1;
			    	end
			    	
				else
					is_first=1;
					open_box=1;
			    end
				--发送检查结果给客户端		    
	        	send_check_ip(open_box,is_first);
	        	--解锁成功及登陆时不用弹窗口时，即我们认为是合法登陆时，我们要改IP地址
	        	if(open_box==0)then  	
					tex_ip_protect_lib.after_user_login(user_info)
				end
	        end
        end)
		
	end
	
	
	--1.得到玩家的IP地址
	--2.玩家的IP地址是不是那5个常用地址中的
	--3.常用地址，直接返回|不是常用地址，更新IP地址库，锁定用户，通知客户端这个用户被锁了
	
    if(user_info == nil)then return end;
    local user_ip_address=get_two_pairs_ip(user_info.ip);
	local user_id=user_info.userId
   
    --得到玩家历次登陆IP地址，
    send_user_ip_info(user_id,user_ip_address); 
    
end


--更新IP地址到常用IP地址中
update_user_ipaddress = function(user_id,ip_address,user_ip_address,last_ip)
	local sql="";
	--如果是空的，就直接插入这次的IP
	if(ip_address==nil or ip_address=="") then
		sql="insert ignore into user_ip_protect_info(user_id,ipaddress,last_ip,lockflag,sys_time) value(%d,'%s','%s',0,now())";
		sql = string.format(sql,user_id,user_ip_address,last_ip);
		dblib.execute(sql);
	else
		--如果不为空，就在最后面加上这次的IP
		local tmpStr=get_four_rencent_ip(ip_address)..","..user_ip_address;
		sql="update user_ip_protect_info set ipaddress='%s',lockflag=0,last_ip='%s' where user_id=%d";
		sql = string.format(sql,tmpStr,last_ip,user_id);
		dblib.execute(sql);
    end

end
--检查用户email
tex_ip_protect_lib.check_user_email = function(buf)
	local userKey = getuserid(buf)
	local userInfo = userlist[userKey]
	if not userInfo then return end
	--通知客户端
	netlib.send(function(buf)
            buf:writeString("TXRETRIEVE")
            buf:writeString(userInfo.email or "")
        end,
    userInfo.ip, userInfo.port)
end

--返回玩家IP的前二段
get_two_pairs_ip = function(ip_address)
	if(ip_address==nil or ip_address=="") then return "" end;
	local ip_address_list = split(ip_address,".");
	local two_pairs_ip_address = ""; 
	for i=1,2 do
		two_pairs_ip_address = two_pairs_ip_address.."."..ip_address_list[i];
	end
	two_pairs_ip_address=string.sub(two_pairs_ip_address, 2)
	return two_pairs_ip_address;
end

--返回玩家最近用过的4个IP地址段,自动顶掉最左边那个IP
get_four_rencent_ip = function(ip_address)
	if(ip_address==nil or ip_address=="") then return "" end;
	local ip_address_list = split(ip_address,",");
	local four_rencent_ip = ""; 
	local tmplen=#ip_address_list;
	local pos=1;	
	if (tmplen>=5) then 
		tmplen=5
		pos=2; 
	end;
	for i=pos,tmplen do
		four_rencent_ip = four_rencent_ip..","..ip_address_list[i];
	end
	four_rencent_ip=string.sub(four_rencent_ip, 2)
	return four_rencent_ip;
end


function tex_ip_protect_lib.after_user_login(user_info)
	local sql="update user_ip_protect_info set last_ip='%s' where user_id=%d"
	sql=string.format(sql,user_info.ip,user_info.userId)
	dblib.execute(sql);
end

--解锁用户，如果密码是对的就解锁，不对的就解锁失败
function tex_ip_protect_lib.unlock_user_protect(buf)
--向客户端返回结果的内部方法

	local send_unlock_info = function(unlockflag,user_info)
			
		    netlib.send(function(buf)
		                    buf:writeString("TXUNLOCK")
		                    buf:writeByte(unlockflag)
		                end,
	                user_info.ip, user_info.port)    
	end
	
    local user_info = userlist[getuserid(buf)]; 
    if(user_info == nil)then return end;
	    local password = buf:readString(buf)
	    local sql="";
	
	    
	    --给玩家解锁
	    local unlock_user=function(user_id,check_flag)
	    local user_info = usermgr.GetUserById(user_id);
		local user_ip_address=get_two_pairs_ip(user_info.ip);
		   
		--如果保险箱密码是对的，就解锁（将这次的IP写入数据库中）
		local unlockflag=0
	   if(check_flag==1)then
	    	sql="select ipaddress from user_ip_protect_info where user_id=%d";
	    	sql=string.format(sql,user_id);
	    	  dblib.execute(sql,function(dt)
		        if(dt and #dt > 0) then
		        	local ipaddress = dt[1].ipaddress;		        	

			    	unlockflag=1
			    	update_user_ipaddress(user_id,ipaddress,user_ip_address,user_info.ip)		    	
				    --发回给客户端解锁状态，解锁成功
				    send_unlock_info(unlockflag,user_info);
				else
					unlockflag=1
					--发回给客户端解锁状态,解锁成功
					update_user_ipaddress(user_id,"",user_ip_address,user_info.ip)
				    send_unlock_info(unlockflag,user_info);
		        end
	        end)
	    else
	        unlockflag=0
			--发回给客户端解锁状态,解锁不成功
			send_unlock_info(unlockflag,user_info);
	    end
  	end

    --看玩家保险箱密码是不是对的，是对的就解锁
    check_safebox_pwd(user_info.userId,password,unlock_user)
    
end


--命令列表
cmd_ip_protect_handler = 
{
	["TXCHECKIP"] = tex_ip_protect_lib.check_ip_address_protect, --更新IP地址信息
    ["TXUNLOCK"] = tex_ip_protect_lib.unlock_user_protect, --解锁用户
	["TXRETRIEVE"] = tex_ip_protect_lib.check_user_email,	--检查用户邮箱
}

--加载插件的回调
for k, v in pairs(cmd_ip_protect_handler) do 
	cmdHandler_addons[k] = v
end



