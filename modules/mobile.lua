TraceError("init mobile_lib...初始化手机模块")

if not mobile_lib then
	mobile_lib = _S
	{
		
	}
end

--修改客户端ip，一起手机是用代理的，所以找不到ip
function mobile_lib.on_change_ip(buf)    
    local user_info = userlist[getuserid(buf)];
    local client_ip = buf:readString();
    if (user_info ~= nil) then
        local ip, from_city = iplib.get_location_by_ip(client_ip)
        user_info.szChannelNickName = string.toHex(from_city) --用户频道号
    end
end
--协议命令
cmd_tex_match_handler = 
{ 
    ["MBCGIP"] = mobile_lib.on_change_ip, --请求修改ip
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end


