TraceError("初始化三分钟加强版...")

daxiao_lib

--协议命令
cmd_daxiao_handler = 
{
	["DVDDATE"] = daxiao_lib.on_recv_check_time, --请求活动时间状态
    ["DVDEXCG"] = daxiao_lib.on_recv_buy_yinpiao, --接收购买银票
    ["DVDBET"] = daxiao_lib.on_recv_xiazhu, --接收下注
    ["DVDOPEN"] = daxiao_lib.on_recv_open_game, --请求服务端，请求打开面板信息
    ["DVDTIME"] = daxiao_lib.on_recv_query_time, --请求服务端，剩余开奖时间
    ["DVDGMNUM"] = daxiao_lib.on_recv_gm_num, --请求服务端，剩余开奖时间
}

--加载插件的回调
for k, v in pairs(cmd_daxiao_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", daxiao_lib.on_after_user_login);
eventmgr:addEventListener("timer_second", daxiao_lib.timer);
eventmgr:addEventListener("on_server_start", daxiao_lib.restart_server);
eventmgr:addEventListener("gm_cmd", daxiao_lib.gm_cmd)
 