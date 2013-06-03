
--事件卸载，一定要放在tex_speakerlib的前面，否则事件会加载两次
if (tex_speakerlib ~= nil and tex_speakerlib.on_after_refresh_info ~= nil) then
    eventmgr:removeEventListener("on_after_refresh_info", tex_speakerlib.on_after_refresh_info);
end

tex_speakerlib = _S
{
    on_recv_check_speaker_num = NULL_FUNC,--收到查询喇叭剩余次数
    on_recv_speaker_broadcast = NULL_FUNC,--收到需要广播的内容
    on_recv_speaker_from_gc = NULL_FUNC,--收到gc发过来的小喇叭
    on_after_refresh_info = NULL_FUNC,--用户刷新数据事件
    do_refresh_info = NULL_FUNC,--刷新小喇叭
    send_sys_msg = NULL_FUNC, --发系统小喇叭
    record_chat_db = NULL_FUNC, --把chat_list写到数据层
    record_chat_log = NULL_FUNC,
    
    sql = 
    {
        --获取小喇叭数量
        get_speaker_count = "select total_count as speakerNum from user_props_info where props_type=2 and user_id=%d",
        --减少小喇叭数量
        sub_speaker_count = "update user_props_info set total_count=total_count-1, sys_time=now() where props_type=2 and total_count>0 and user_id=%d;commit;",
        --记录小喇叭日志
        log_speaker_count="insert into log_user_speaker_info(user_id,speaker_count,speak_content,sys_time) value (%d,-1,'%s',now());commit;",
    },
    gm_id_arr = {'1097','773547'},
    
    chat_list = {},
    
    
}

--刷新事件
function tex_speakerlib.on_after_refresh_info(event_data)    
    local user_info = event_data.data
     tex_speakerlib.do_refresh_info(user_info)    		
end

--刷新事件
function tex_speakerlib.do_refresh_info(user_info,is_first,buf)    

    local complete_callback_func = function(speaker_count)
        if is_first ~= nil then
            netlib.send(function(buf)
                buf:writeString("SPEAKERNUM")
                buf:writeInt(speaker_count)
            end,user_info.ip, user_info.port)
        end
    end
    if(tex_gamepropslib ~= nil) then
        tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, user_info, complete_callback_func)
    end

end

--响应喇叭剩余次数
function tex_speakerlib.on_recv_check_speaker_num(buf)
    local user_info = userlist[getuserid(buf)]; 
    if(user_info == nil)then return end

    if(tex_gamepropslib ~= nil) then
        tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, user_info, 
              function(speaker_count)
                    netlib.send(function(buf)
                                buf:writeString("SPEAKERNUM")
                                buf:writeInt(speaker_count)
                            end,
                        user_info.ip, user_info.port)    
              end)
    end
end
--是否GM
function isGM(user_id)
	if type(user_id) ~= string then
		user_id = tostring(user_id)
	end
	for k, v in pairs(tex_speakerlib.gm_id_arr) do
		if v == user_id then
			return true
		end
	end
	return false
end

--收到发布广播
function tex_speakerlib.on_recv_speaker_broadcast(buf)
	local msg = buf:readString()--需要gu
    local user_info = userlist[getuserid(buf)]; 
  	if(user_info == nil)then
		return 0
	end
    msg = string.gsub(msg, "\r", "")
    msg = string.gsub(msg, "\n", "")
    if(texfilter and isGM(user_info.userId) ~= true)then
        msg = texfilter.change_string_by_pingbikey(msg);
    end

    local speaker_id = tex_gamepropslib.PROPS_ID.SPEAKER_ID
    --设置小喇叭数量后，回调函数
    local complete_callback_func = function(speaker_count)
        --发广播
        local send_func = function(buf)
            buf:writeString("SPEAKERALL")
            buf:writeInt(user_info.userId)
            buf:writeString(user_info.nick)
            buf:writeString(msg)
        end
        send_buf_to_all_game_svr(send_func)
        --记日志
        msg = string.trans_str(msg)
        local sql = string.format(tex_speakerlib.sql.log_speaker_count, user_info.userId,msg)
        dblib.execute(sql)
        
        tex_speakerlib.record_chat_log(2, user_info.userId, msg, user_info.nick)
    end

    if (tex_gamepropslib == nil or user_info.propslist == nil
            or user_info.propslist[speaker_id] <= 0) then
        return
    end
    --重新设置小喇叭数量，减少一个
    tex_gamepropslib.set_props_count_by_id(speaker_id, -1, user_info, complete_callback_func)
end


--发系统小喇叭
function tex_speakerlib.send_sys_msg(msg)
	local is_me = 0
	msg = "<font color='#33FF00'>".._U("【系统广播】： ")..msg.."</font>"

    local send_fun = function(buf)
        buf:writeString("SPEAKERBC") --写消息头。
        buf:writeByte(is_me)
        buf:writeString((msg) or "")     --广播内容
    end
    for k, v in pairs(userlist) do
        if (v.is_sub_user == nil) then
            netlib.send(send_fun, v.ip, v.port)
        end
    end
end

--收到gc发过来的小喇叭
function tex_speakerlib.on_recv_speaker_from_gc(buf)
    local user_id = buf:readInt(buf)
    local nick_name = buf:readString(buf)
    local msg = buf:readString(buf)
    local content = ""
	local is_me = 0
	if string.len(nick_name) > 18 then
		nick_name = string.sub(nick_name,1,18).."..."
	end
	if isGM(user_id) then --客服广播
		msg = "<font color='#33FF00'>".._U("【系统广播】： ")..msg.."</font>"
		--msg = "<font color='#33FF00'>".._U(tex_lan.get_msg("speaker_msg"))..msg.."</font>"
	else 
		msg = "<font color='#FFFF00'>".._U("【")..nick_name.._U("】 ：")..msg.."</font>"
	end
	
    local send_fun = function(buf)
        buf:writeString("SPEAKERBC") --写消息头。
        buf:writeByte(is_me)
        buf:writeString((msg) or "")     --广播内容
    end
    
    for k, v in pairs(userlist) do
        if v.userId == user_id then --是否是发送人自己
            is_me = 1
        else
            is_me = 0
        end
        netlib.send(send_fun, v.ip, v.port)
    end
end

function tex_speakerlib.record_chat_db()

	local sql = "insert ignore into log_chat_msg(sys_time,room_id,msg_type,user_id,nick_name,msg) values "
	local chat_list_sql = ""
	for k,v in pairs(tex_speakerlib.chat_list) do
		chat_list_sql = chat_list_sql..string.format(" (now(),%d,%d,%d,'%s','%s'),", v.room_id, v.msg_type, v.user_id, v.nick_name, v.msg)
	end
	sql = sql..chat_list_sql
	tex_speakerlib.chat_list = {}
	--去掉最后一个逗号，换成分号
	sql = string.sub(sql, 1, string.len(sql)-1)..";"
	
	dblib.execute(sql)
end


function tex_speakerlib.record_chat_log(msg_type, user_id, msg, nick_name)

	if nick_name == nil then
		local user_info = usermgr.GetUserById(user_id)
		if user_info ~= nil then
			nick_name = user_info.nick
		else
			nick_name = ""
		end	
	end
	
	nick_name = string.trans_str(nick_name)
	msg = string.trans_str(msg)
	local msg_len = string.len(msg)
	if msg_len > 200 then
		msg = string.sub(msg, 1, 200)
	end
	local buf_tab = {
		["room_id"] = groupinfo.groupid,
		["msg_type"] = msg_type,
		["user_id"] = user_id,
		["nick_name"] = nick_name,
		["msg"] = msg,
	}
	table.insert(tex_speakerlib.chat_list, buf_tab)
	if #tex_speakerlib.chat_list >= 20 then
		tex_speakerlib.record_chat_db()
	end
end

--事件监听器，一定放在最后
eventmgr:addEventListener("on_after_refresh_info", tex_speakerlib.on_after_refresh_info);

--协议命令
cmd_tex_speaker_handler = 
{
	["SPEAKERNUM"] = tex_speakerlib.on_recv_check_speaker_num, --收到查询喇叭剩余次数
	["SPEAKERBC"] = tex_speakerlib.on_recv_speaker_broadcast,  --收到喇叭广播
    ["SPEAKERALL"] = tex_speakerlib.on_recv_speaker_from_gc,  --收到全服小喇叭广播
    
}

--加载插件的回调
for k, v in pairs(cmd_tex_speaker_handler) do 
	cmdHandler_addons[k] = v
end