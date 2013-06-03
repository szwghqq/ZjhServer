dofile("games/tex/lanpack/language_package_cn.lua")
dofile("games/tex/lanpack/language_package_big5.lua")

--lan="lan_cn"
--userinfo.lan="lan_big5"
if not tex_lan then
	tex_lan = _S
	{
		on_recv_set_lan = NULL_FUNC, --预留，如果玩家要保存自己的语言，就要实现这个功能。
        on_after_user_login = NULL_FUNC,		--玩家登陆后会调用的方法
        set_msg = NULL_FUNC,
        get_msg = NULL_FUNC,			--得到对应的文字

	}
end
--lan="lan_cn"
local msg=""

--设置对应的文字，预留，暂时无用。
function tex_lan.on_after_user_login(userinfo)
	if (userinfo==nil) then return  end
	if(userinfo.nRegSiteNo>=200 and userinfo.nRegSiteNo<300)then
		
		userinfo.lan="lan_big5"
	else
		--userinfo.lan="lan_big5"
		userinfo.lan="lan_cn"
	end
end

function tex_lan.set_msg(tmpStr)
    msg=tmpStr
end

--得到对应的文字
function tex_lan.get_msg(userinfo,msg_key)
	local lan="lan_cn";
	if(userinfo~=nil and userinfo.lan~=nil and userinfo.lan=="lan_big5")then
		lan="lan_big5";
	end
	
	local aa = "tex_lan.set_msg("..lan.."."..msg_key..")"
	--TraceError(aa)	
	local f=loadstring(aa);
	f()
	return msg
end

--预留，如果玩家要保存自己的语言，就要实现这个功能。
function tex_lan.on_recv_set_lan(userinfo)
	return
end

--命令列表
cmd_texlan_handler = 
{
   ["SETLAN"] = tex_lan.on_recv_set_lan, --客户端告诉服务器这次用什么语言
}

--加载插件的回调
for k, v in pairs(cmd_texlan_handler) do 
	cmdHandler_addons[k] = v
end