TraceError("init super_cow_lib...")

if not chat_tools_lib then
    chat_tools_lib = _S
    {    	   
		on_recv_chat=NULL_FUNC, --客户端发聊天消息
		send_chat_msg=NULL_FUNC,  --服务端发聊天消息
    }    
end


chat_tools_lib.on_recv_chat=function(buf)
	local user_info = userlist[getuserid(buf)];	
	if(user_info==nil)then return end;
	local huodong_type=buf:readByte();
	local chat_msg=buf:readString();
	local from_user_id=buf:readInt();
	local chat_type=1; --小游戏里聊天用1做类型
	local chat_user_list={}
	if(huodong_type==1)then
		chat_user_list=super_cow_lib.user_list
	end
	
	chat_msg = string.gsub(chat_msg, "\r", "")
    chat_msg = string.gsub(chat_msg, "\n", "")
    if(texfilter)then
		chat_msg = texfilter.change_string_by_pingbikey(chat_msg);
		for k,v in pairs(chat_user_list)do
			local user_info=usermgr.GetUserById(v.user_id)
			chat_tools_lib.send_chat_msg(user_info,chat_msg,huodong_type,chat_type,from_user_id)	
		end
	end
end

--发聊天消息 
--huodong_type 小游戏标识：1，疯狂斗牛；
--chat_type 内容类型：1，当前游戏；2，所有游戏；3，当前游戏系统消息；4，所有游戏系统消息；
--如当前小游戏里的聊天内容用1，有玩家退出发3等
chat_tools_lib.send_chat_msg=function(user_info,chat_msg,huodong_type,chat_type,from_user_id)
	if (user_info==nil) then return end
	local from_user_info=usermgr.GetUserById(from_user_id)
	if(from_user_info==nil) then return end
	netlib.send(function(buf)
            buf:writeString("TJDCHAT");
            buf:writeByte(huodong_type);
            buf:writeByte(chat_type);
            buf:writeString(chat_msg);
            buf:writeInt(from_user_info.userId);
            buf:writeString(from_user_info.imgUrl or "");
            buf:writeString(from_user_info.nick or "");
            
        end,user_info.ip,user_info.port);	

end

--协议命令
cmd_chattools_handler = 
{
        ["TJDCHAT"] = chat_tools_lib.on_recv_chat, --客户端，请求插件是否有效
}

--加载插件的回调
for k, v in pairs(cmd_chattools_handler) do 
	cmdHandler_addons[k] = v
end
