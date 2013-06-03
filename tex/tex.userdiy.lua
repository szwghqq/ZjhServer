TraceError("加载 游戏设置 插件....")

if not tex_userdiylib then
	tex_userdiylib = _S
	{
        on_after_user_login         = NULL_FUNC,
        on_recv_userdiy_person_info = NULL_FUNC, --收到“个人设置”相关信息
        on_recv_userdiy_pokeui_info = NULL_FUNC, --收到“牌样设置”相关信息
		on_recv_send_userlist = NULL_FUNC,
		on_recv_update_userlist = NULL_FUNC,
		
        SQL = _S
        {
            update_users = "update users set nick_name='%s', sex=%d where id=%d; ",
            --change_type: 1，表示更新个人设置；2，表示更新牌样设置
            insert_log_user_diy_info = "insert log_user_diy_info(user_id, sys_time, change_type) values(%d, now(), %d);",
        }
	}
end

--收到“个人设置”相关信息
function tex_userdiylib.on_recv_userdiy_person_info(buf)

    -- 0,表示设置失败；-1,表示昵称重复；-2,敏感词汇；1,表示设置成功
    local send_userdiy_person = function(result, user_info)
        TraceError("游戏个人设置结果->"..result)
        netlib.send(
            function(buf)
                buf:writeString("TXPERSZ")
                buf:writeByte(result)
            end,user_info.ip,user_info.port)
    end

    local user_info = userlist[getuserid(buf)]; 
    if not user_info then return end;

    local nick = buf:readString();              --得到玩家昵称
    local sex = buf:readByte();                 --得到玩家性别
    local privileged_type = buf:readByte();     --得到特权设置类型
    local chat_type = buf:readByte();           --得到聊天设置类

    --TraceError("--> nick:"..nick.." sex:"..sex.." privileged_type:"..privileged_type.." chat_type:"..chat_type)
    if(texfilter) then
	    if(texfilter.is_exist_pingbici(nick))then
	    	--"包含敏感词汇，请重新输入"
            send_userdiy_person(-2, user_info)
            return;
        end
    end
    nick = string.trans_str(nick)
    --查看是否有重复昵称

      --TraceError("--> 如果没有重复昵称，正常写入数据")
      	local face = ''
      	local sql_1 = ""
      	if user_info.sex ~= sex then
      		if(sex ~= 0) then
      			face = 'face/1.jpg'
      		else
      			face = 'face/1001.jpg'
      		end
      		sql_1 = "update users set nick_name='%s', sex=%d ,face='"..face.."' where id=%d; "
      	else
      		sql_1 = tex_userdiylib.SQL.update_users
      	end
      	
      	
        sql_1 = sql_1.."INSERT INTO cfg_user_diy_info(user_id, privileged_type, chat_type) values(%d, %d, %d)"..
                    "ON DUPLICATE KEY UPDATE user_id=%d, privileged_type=%d, chat_type=%d;"..
                    tex_userdiylib.SQL.insert_log_user_diy_info..
                    "commit;";
      
  		if(string.len(nick)>=60)then
  			send_userdiy_person(0, user_info);
  			return;
  		end
        sql_1 = string.format(sql_1, nick, sex, user_info.userId,
                             user_info.userId, privileged_type, chat_type, 
                             user_info.userId, privileged_type, chat_type, 
                             user_info.userId, 1);

        dblib.execute(sql_1, 
                    function(dt)       
                        if (dt and #dt >= 0) then
                        	user_info.sex = sex
                        	user_info.nick = nick
                        	if face ~= '' then
                        		user_info.imgUrl = face
                        	end
                            send_userdiy_person(1, user_info)
                        end    
                    end)

end


function tex_userdiylib.on_after_user_login(user_info)
    --TODO
    TraceError("user_info id:"..user_info.userId)
end

--收到“牌样设置”相关信息
function tex_userdiylib.on_recv_userdiy_pokeui_info(buf)
    --TODO
    TraceError("--> on_recv_userdiy_pokeui_info()")
end


function tex_userdiylib.on_recv_send_userlist(buf)
	local user_info = userlist[getuserid(buf)]; 
    if not user_info then return end;
    tex_userdiylib.on_recv_update_userlist(user_info) 
end

function tex_userdiylib.on_recv_update_userlist(userinfo,n_deskno)
	
 	local deskno=0
 	if(n_deskno~=nil) then
 		deskno=n_deskno
 	else
 		deskno=userinfo.desk
 	end 	
 	
 	ASSERT(deskno and deskno > 0, "deskno 非法deskno:" .. tostring(deskno))
    local deskinfo = desklist[deskno]
    ASSERT(deskinfo, "deskno 非法或desklist破坏了 deskno:" .. tostring(deskno))
    
    local desk_user_list={};
    
    
    if(duokai_lib == nil) then
        for i = 1, room.cfg.DeskSiteCount do
                local userinfo = userlist[deskinfo.site[i].user]
                if (userinfo and userinfo.offline ~= offlinetype.tempoffline) then
                    table.insert(desk_user_list,userinfo)
                end
        end
    end
    
    for k, userinfo in pairs(deskinfo.watchingList) do
            if (userinfo and userinfo.offline ~= offlinetype.tempoffline and (duokai_lib == nil or duokai_lib.is_sub_user(userinfo.userId) == 0)) then
                table.insert(desk_user_list,userinfo)
            end
    end
    
    
    	
        netlib.broadcastdesk(
            function(buf)
                buf:writeString("TXUSERLIST")
                buf:writeInt(#desk_user_list)
                for k, desk_userinfo in pairs(desk_user_list) do
	                buf:writeInt(desk_userinfo.userId);		
	                buf:writeString(desk_userinfo.nick);
	                local vip_level = 0
				    if viplib then
				    	vip_level = viplib.get_vip_level(desk_userinfo)
				    end
	                buf:writeInt(vip_level);
                end
            end
        , deskno, borcastTarget.all);
end



--命令列表
cmd_userdiy_handler = 
{
	["TXPERSZ"] = tex_userdiylib.on_recv_userdiy_person_info, --收到“个人设置”相关信息
    ["TXPAYSZ"] = tex_userdiylib.on_recv_userdiy_pokeui_info, --收到“牌样设置”相关信息
    ["TXUSERLIST"] = tex_userdiylib.on_recv_send_userlist, --发送牌桌用户列表（包括 在玩的 和 旁观的）
  
}

--加载插件的回调
for k, v in pairs(cmd_userdiy_handler) do 
	cmdHandler_addons[k] = v
end



