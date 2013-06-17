dofile("games/hall.desk.lua")

--dofile("games/modules/treasure_box.lua")
--dofile("games/modules/quest.lua")
--dofile("games/modules/vip.lua")
--dofile("games/modules/friend.lua")
--dofile("games/modules/riddle_forgs.lua")
--dofile("games/modules/onlineprize.lua")
--dofile("games/modules/za_dan.lua")

--dofile("games/tex/tex.buff.lua")
--dofile("games/tex/huodong.lua")

--dofile("games/tex/tex.quest.lua")
dofile("games/modules/channel.lua");
dofile("common/ipinfo/iplib.lua")
--dofile("games/tex/tex.filter.lua")

dofile("games/tex/tex.language_package.lua")
dofile("games/file_load.lua")
--dofile("games/gm.lua")
-----------------------------------------------------------------------------

format = string.format
fmt = format
OutputLogStr("服务端大厅开始初始化")

--更新数据库
tSqlTemplete =
{
    --更新用户头像
    updateUserFace = "update users set face = '%s' where id = %d",
    --激活用户头像
    active_user_face = "insert ignore into user_extra_face(user_id, normal_face, active_face) values(%d,concat(''),concat('|'));"..
                       "update user_extra_face set active_face = concat(active_face,'%d|') where user_id = %d; commit;",
    --更换上一次的头像
    update_last_face = "update user_extra_face set normal_face = concat(%s) where user_id = %d;",
    --得到默认头像
    get_last_face = "select normal_face from user_extra_face where user_id = %d;",
    --得到extra头像
    get_extra_face = "select active_face from user_extra_face where user_id = %d;",

    getUserGoldFromDb = "select gold from users where id=%d",
    --刷金币
    updateGold = "update users set gold = gold + %d where id = %s",
    GetRegSite = "select site_no from reg_site where site_no != 0 and site_no != 2",
    --[[
        1:2009年送红包活动
        2:好友之间每日免费送钱
        3:每日登录送钱 网页【暂为校内专用】
        4:每日登录送钱 Server【暂为YY专用】
        5:大型比赛发奖
        6:任务奖励
        13,14,15 比赛,
        10诈金花彩池,
        20:更换头像,
        21:道具消耗
        22：挑战场金币赠送
        23: 挑战场完成挑战赠送
        24: 创建工会
        25: 公会转正
        26：公会捐献
        27：公会发工资

        30: 竞技场获奖
        31: 购买竞技场金币
        32: 梭哈活动发奖

        80:存取保险箱中的钱
        81:成就达成送钱
        82:德州扑克每日登陆送钱
        85:保险箱取出类型

        t_economy_info产出消耗类型
        90:每天24小时内所有牌局的赢钱的总额

    ]]
	--updateUserGold = "call sp_update_user_gold(%d, %d, %d)",  --userid, gold, type
    --得到房间信息
	get_roominfo_copy = "select * from ROOMS where id = %d",

    --计算比赛积分信息
    calc_match_integral = "call sp_match_record_integral(%d, %d, '%s')", --(userid，integral，idcfg)
    
    --检查每日登陆送钱是否合法
    check_daygold_cangive = "call sp_check_daygold(%d,%s,%d,%d)",

    --记录经济系统
    update_gold_system = "call sp_update_goldsystem_info(-14, %d,%d,%d,%d)", -- -14为德州的服务器

    --经济系统产出消耗类型
    GOLDSYSCFG = 
    {
        produceType = {0,4,12,50,81,83,1000,1001,1002,1008,1011,1012,1014,1016,1017,1018,1019,1020,1021,1026,1027,999999},
        usedType = {1003,1004 ,1006,1007,1009,1010,1013},
    },

    CONFIG = {
        LIMITNUM = 10,--IP登陆用户个数限制
        MAXGIVE = 888,--每日登陆最大送钱
        MINGIVE = 500, --每日登陆最小送钱
    },
}

g_errmsgprefix = ""

--可序列化的Table
DSerizlizeableTable = class("DSerizlizeableTable")
function DSerizlizeableTable:__init()
    local m = {}
    m.format = {}
    m.strRet = ""

    local setnew
    local processbuf
    local rwvalue

    function DSerizlizeableTable:setformat(format)
        assert(format and type(format) == "table")
        m.format = format
        local meta = getmetatable(self)
        meta.__newindex = setnew
    end

    function setnew(t, key, value)            --覆盖赋值方法，用于检查是否匹配format
        local find = false
        for k, v in pairs(m.format) do
            --print(k,key,v,type(value))
            if k == key then
                assert(v == "string" or v == "int" or v == "short" or v == "byte" or type(v) == "table", "format '" .. k .. "' error")
                if type(v) == "table" and type(value) == "table" then
                    find = true
                    break
                elseif  (v == "int" or v == "short" or v == "byte") and tonumber(value) then
                    value = tonumber(value)
                    find = true
                    break
                elseif v == "string" and tostring(value) then
                    value = tostring(value)
                    find = true
                    break
                end
            end
        end
        assert(find, "'" .. key .. "' is not match to protocol")
        rawset(self, key, value)
    end



    function DSerizlizeableTable:tostring()
    m.strRet = ""
        processbuf(self, m.format)
    return m.strRet
    end

    function processbuf(data, format)
        local ks = {}
        for k, v in pairs(format) do
            ks[#ks + 1] = k
        end
        table.sort(ks)
        for i = 1, #ks do
            --print("format type", type(format[ks[i]]), string.gsub(tostringex(format[ks[i]]), "[\n%s]+", ""))
            if type(format[ks[i]]) == "string" then
                assert(data[ks[i]], "the value is nil in field '" .. ks[i] .. "'")
                rwvalue(ks[i], data, data[ks[i]], format[ks[i]])
            elseif type(format[ks[i]]) == "table" then
                if not data[ks[i]] then data[ks[i]] = {} end
                local len = rwvalue("[len]", data, #(data[ks[i]] or {}), "int")
                if not len then len = #data[ks[i]] end
                for j = 1, len do
                    if not data[ks[i]][j] then data[ks[i]][j] = {} end
                    processbuf(data[ks[i]][j], format[ks[i]])
                end
            else
                error('error format')
            end
        end
    end

    function rwvalue(name, data, value, type)
        m.strRet = m.strRet .. string.gsub(value, "|", " ") .. "|"
    end

end



function throw(msg)
    TraceError('--------------------------')
    TraceError("#### call command faild ".. g_errmsgprefix.." with err: "..msg) --error(msg)
    local serr = debugpkg.traceback()
    TraceError(serr)
    TraceError('--------------------------')
end

--排队时的策略不再区分机器人与自然人
function oncheckrobot(caption, value)
    if value == 1 then
        room.cfg.ignorerobot = 1
    else
        room.cfg.ignorerobot = 0
    end
    if room.cfg.ignorerobot == 1 then
        --将所有的机器人设置为自然人
        for k, v in pairs(userlist) do
            v.isrobot = false
        end
        --让正在排队的机器人加入到输的队列中
        for i = 1, g_QueueRobot.count do
            g_QueueLostPeople:Add(g_QueueRobot:Pop())
        end

    else --将所有的机器人身份设置正确的机器人
        for k, v in pairs(userlist) do
            v.isrobot = v.realrobot
        end
    end
end

-- 不赔钱通用计算
function calc_bupeiqian(deskno, player_count, get_fen, set_fen)
	if (room.cfg.oncheckbupeiqian == 1) then
		local total_lost = 0
		local total_win = 0
		local win_list = {}
		-- 输家最多输光，按照输家的钱作为上限
		for i = 1, player_count do
			local userKey = hall.desk.get_user(deskno, i) --得到对应用户的IP地址和端口
			local sfuserinfo = userlist[userKey] --得到用户的信息表。
			if (sfuserinfo.gamescore + get_fen(i) < 0) then
				set_fen(i, -sfuserinfo.gamescore)
			end
			if get_fen(i) < 0 then
				total_lost = total_lost + get_fen(i)
			elseif get_fen(i) > 0 then
				win_list[i] = get_fen(i)
				total_win = total_win + get_fen(i)
			end
		end
		--
		-- 赢家不管一家还是两家，按比例分钱的，如果输赢总数不同，使用total_lost计算
		if total_win ~= total_lost then
			for key, value in pairs(win_list) do
				set_fen(key, math.floor(-value * total_lost/total_win))
			end
		end
	end
end

--系统不赔钱
function oncheckbupeiqian(caption, value)
    room.cfg.oncheckbupeiqian = value
end

--强制轮换
function oncheckfocerequeue(caption, value)
    room.cfg.checkforcerequeue = value
end

--允许GM控制发牌
function oncheck_control_fapai(caption, value)
    room.cfg.oncheck_control_fapai = value

    if (gamepkg.clear_control ~= nil) then
            gamepkg.clear_control() --事件通知
    end
end

--测试一个函数执行的毫秒数
function getprocesstime(fun, comment, max_times)
	local time1 = os.clock() * 1000
	fun()
	local time2 = os.clock() * 1000
	if (time2 - time1 > max_times) then
		TraceError(format("Fun:%s, takes:%d ms",comment, (time2 - time1)))
	end
end

--设置相同ip的人不能同桌子打牌
function onchecksameip(caption, value)
    room.cfg.checksameip = value
end

--是否有相同ip不能同桌打牌的限制
function ischecksameip()
    return room.cfg.checksameip or 1
end

--是否强制轮换
function ischeckforcerequeue()
    return room.cfg.checkforcerequeue or 1
end

--是否允许GM控制发牌
function is_allow_gm_control_fapai()
    return room.cfg.oncheck_control_fapai or 0
end


--设置是否为包房
function oncheckbaofang(caption, value)
    if value == 1 then
        room.cfg.roomtype = roomtype.baofang
    else
        room.cfg.roomtype = roomtype.normal
    end
end

--function isbaofang()
--    return room.cfg.roomtype == roomtype.baofang
--end

--是否为公会专用房间
function isguildroom()
	return groupinfo.isguildroom == 1
end

-- =1 每局结束后重新排牌友 = 0
function oncheckrequeue(caption, value)
    if value == 1 then
        room.cfg.ongameOverReQueue = 1
    else
        room.cfg.ongameOverReQueue = 0
    end
end

-- =1 允许同桌打牌 = 0
function onchecksamedesk(caption, value)
    if value == 1 then
        room.cfg.allow_samedesk = 1
    else
        room.cfg.allow_samedesk = 0
    end
end

--为0表示不限时出牌
function onchecktimelimit(caption, value)
    if value == 1 then --限时出牌
        room.cfg.istimecheck = true
    else --不限时出牌，仅用于调试
        room.cfg.istimecheck = false
    end
end
--value==1表示关闭输出信息
function onchecklog(caption, value)
    if value == 1 then --限时出牌
        room.cfg.org_outputlog = room.cfg.outputlog
        room.cfg.outputlog = 1
    else --不限时出牌，仅用于调试
        room.cfg.org_outputlog = room.cfg.outputlog
        room.cfg.outputlog = 0
    end
end
--value==1表示只输出错误信息
function oncheckerrorlog(caption, value)
    --trace(caption..'   '..value)
    if value == 1 then --不输出非错误信息
        --log('切换到只输出错误信息模式!')
        trace = nulloutput
    else
        --log('切换到输出所有信息模式!')
        trace = netbuf.trace
    end
end
--value==1表示每桌中必须至少有一个自然人
function oncheckqueue(caption, value)
    room.cfg.DeskMustHavePerson = value
end

function testdate()
    local nowtime = tools.SectionCreator() --实际是取时间
    --trace(nowtime)
    local timevalid = {
    '2008-1', '2008-2', '2008-3', '2008-4', '2008-5', '2008-6', '2008-7', '2008-8', '2008-9', '2008-10', '2008-11', '2008-12',
    '2008-01', '2008-02', '2008-03', '2008-04', '2008-06', '2008-06', '2008-07', '2008-08', '2008-09', '2008-10', '2008-11', '2008-12',
    '08-01', '08-02', '08-03', '08-04', '08-06', '08-06', '2008-07', '2008-08', '2008-09', '2008-10', '2008-11', '2008-12',
    '08-1', '08-2', '08-3', '08-4', '08-5', '08-6', '08-7', '08-8', '08-9', '08-10', '08-11', '08-12',
    }

    local k, v
    local bdateok = false
    for k, v in pairs(timevalid) do
        local len = string.len(v)
        --print("string.sub(nowtime, 1, 1)".. string.sub(nowtime, 1, len)..'  v:'..v)
        if (string.sub(nowtime, 1, len) == v) then
            --trace('valid date')
            bdateok = true
            break
        end
    end
    if (bdateok == false) then
        onsendrqck = function() end
        onsendlogin = onsendrqck
    end
end

--设置该房间总任务数量
function set_room_totalquestcount(count)
    room.cfg.totalquestcount = count
end
------------------------------------------------------------------------
--得到输赢数关联数组
usermgr.get_user_history = function(userinfo)
    return userinfo.gameInfo.history
end

--日期排序用,日期转为整数
cal_day_number = function(strDate)
    if strDate == nil then
        return 0
    end

    local str_year, str_month, str_day
    str_year, str_month, str_day = string.match(strDate,"(%d+)-(%d+)-(%d+)")
    if(str_year == nil or str_month == nil or str_day == nil)then
        return 0
    end

    local date = {year= tonumber(str_year), month= tonumber(str_month), day=tonumber(str_day), hour=0,min=0,sec=0}
    local standard_time = {year=1990, month=1, day=1, hour=0,min=0,sec=0}
    local day = math.floor(os.difftime(os.time(date),os.time(standard_time))/86400);

    --TraceError("cal_day_number():"..day)
    return day
end

--得到输赢数数组
usermgr.get_user_history_array = function(useinfo)
    if(useinfo == nil) then return nil end
 
	 local history = {}
	    local history_data = {}
        history_data.date =  "NULL"
        history_data.win  = 0
        history_data.lose = 0
        table.insert(history,history_data)
    return history
end
------------------------------------------------------------------------
--
function getuserid2(ip, port)
    --todo:需要生成GUID才够安全，这里只是临时解决方案
    return format("%s:%s", ip, port)
end

function getuserid(buf)
    --todo:需要生成GUID才够安全，这里只是临时解决方案
    return format("%s:%s", buf:ip(), buf:port())
end

function silentTrace(msg)
    if (string.sub(msg, 1, 4) == '####') then
        trace(msg)
    end
end

--当玩家 坐下/状态改变/重登陆 的时候派发见面事件  observer = 观察者, subject = 状态改变的玩家
function dispatchMeetEvent(userinfo, bReloginUser)
    if(not bReloginUser) then bReloginUser = 0 end
	local deskno = userinfo.desk
	if not deskno then return end
    local deskinfo = desklist[deskno]
    if not deskinfo then return end
    local time1 = os.clock() * 1000
    local nCount = 0
	for i = 1, room.cfg.DeskSiteCount do
		local user = userlist[desklist[deskno].site[i].user]
        if user then
            nCount = nCount + 1
			eventmgr:dispatchEvent(Event("meet_event", _S{observer = user, subject = userinfo, relogin = bReloginUser}))
			if userinfo ~= user then
				eventmgr:dispatchEvent(Event("meet_event",	_S{observer = userinfo, subject = user, relogin = 0}))
			end
		end
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 300)  then
        TraceError(format("见面事件1,时间超常:nCount=[%d], time=[%d]",nCount ,(time2 - time1)))
    end
    time1 =  os.clock() * 1000
    nCount = 0
    for k,v in pairs(deskinfo.watchingList) do
        nCount = nCount + 1
        local user = userlist[k]
        if(user)then
            eventmgr:dispatchEvent(Event("meet_event", 	_S{observer = user, subject = userinfo, relogin = bReloginUser}))
        else
            TraceError("清除幽灵了....")
            deskinfo.watchingList[k] = nil
        end
    end
    time2 = os.clock() * 1000
    if (time2 - time1 > 300)  then
        TraceError(format("见面事件2,时间超常:nCount=[%d], time=[%d]",nCount ,(time2 - time1)))
    end
end

--广播给一个玩家和观战他的用户,fireevent1
function borcastUserEvent(msg,userkey)
    local user = userlist[userkey]
    local ok
    if (user and user.offline ~= offlinetype.tempoffline) then
        gamepkg.arg.deskno = user.desk
        gamepkg.arg.curdesksite = user.site

        ok = tools.fireEvent(msg, user.ip, user.port)

        local deskinfo = desklist[user.desk]
        for k,v in pairs(deskinfo.watchingList) do
            gamepkg.arg.userinfo = v
            ok = tools.fireEvent(msg, v.ip, v.port)
        end
    end
end

--广播给一个玩家和观战他的用户,fireevent2
function borcastUserEvent2(func,userkey)
    local user = userlist[userkey]
    if (user and user.offline ~= offlinetype.tempoffline) then
        gamepkg.arg.deskno = user.desk
        gamepkg.arg.curdesksite = user.site

        tools.FireEvent2(func, user.ip, user.port)

        local deskinfo = desklist[user.desk]
        for k,v in pairs(deskinfo.watchingList) do
            gamepkg.arg.userinfo = v
            tools.FireEvent2(func, v.ip, v.port)
        end
    end
end

--房间内广播
--function(buf, userinfo)
--    userinfo:用户信息
--    target: borcastTarget.XXX 类型
netlib.broadcastroom = function(callback)
    for k, v in pairs(userlist) do
        if (v.key == k and v.offline == nil) then
            local sendfunc = function(buf)
                callback(buf, v)
            end
            netlib.send(sendfunc, v.ip, v.port)
        else
            if(v ~= nil and v.key ~=nil) then
                trace('发现重新登录的IP，跳过广播的队列:k='..k..'v.key='..v.key..' v.offline='..tostring(v.offline))
            else
                TraceError("广播错误，怎么会发生这种情况")
            end
        end
    end
end
----------------------------------------------------------------------------------------------------
--统计当前在线人数并发送给服务端
function OnStatisticsOnline(buf)
    local szBuf = groupinfo.groupid .. "," .. groupinfo.gamepeilv .. "," .. --参数有房间号,赔率，在线人数，在玩人数，机器人数
	usermgr.GetTotalUserCount() .. "," .. usermgr.GetPlayingUserCount() .. "," .. usermgr.GetRobotUserCount() --初始化传递的参数

    local tUserNumInfo = usermgr.GetUserNumberInfo()
    local nRegSiteCount = 0
    for k, v in pairs(tUserNumInfo) do
        nRegSiteCount = nRegSiteCount + 1
    end
    szBuf = szBuf..","..nRegSiteCount
    for k, v in pairs(tUserNumInfo) do
        if (k ~= 0) then  --不算机器人
            local szTemp = k..","..v.totalCount..","
            szTemp = szTemp..v.playingCount..","
            szTemp = szTemp..v.robotCount
            szBuf = szBuf..","..szTemp
        end
    end
    tools.SendBufToUserSvr(getRoomType(), "NTCU", "", "", szBuf) --发送数据到服务端
--    TraceError("发送了数据给游戏中心：" ..szBuf)
end

--更细游戏服务器里面的在线人数信息。
function OnNotifyOnlineUsers(buf)
    local groupsUsersCount2 = {} --所有服务器的在线人数情况。
    local szInfo = buf:readString() --读取字符串
    szInfo = split(szInfo, ",")
    for i = 1,table.getn(szInfo),5 do
        groupsUsersCount2[szInfo[i]] = {}
        groupsUsersCount2[szInfo[i]].peilv = szInfo[i+ 1]
        groupsUsersCount2[szInfo[i]].users = szInfo[i+ 2]
        groupsUsersCount2[szInfo[i]].playing = szInfo[i+ 3]
        groupsUsersCount2[szInfo[i]].robots = szInfo[i+ 4]
    end
    groupsUsersCount = groupsUsersCount2 --覆盖原来的，让原来的用垃圾回收器自动清除。
end

------------------------------------------------------------------------
--得到客服端的在线人数请求
function OnQuestServerCount(buf)
    local SendFun = function(outBuf)
        outBuf:writeString("REOS")--写消息头
        for k, v in pairs(groupsUsersCount) do
            outBuf:writeString(k)
            outBuf:writeInt(v.users or 1)
        end
        outBuf:writeString("") --以空串结尾
    end
    tools.FireEvent2(SendFun, buf:ip(), buf:port()) --发送在线人数消息
end

-----------------------------------------------------------------------------------------------------
--得到客户端在线人数请求，发送当前在线人数给客户端
function OnRecevOnlineCount(buf)
    local sendFun = function(outBuf) --发送数据填充的闭包
        outBuf:writeString("REOC") --写消息头
        outBuf:writeInt(usermgr.GetTotalUserCount()) --在线人数
        outBuf:writeInt(3000) --最大能承载的人数
        outBuf:writeInt(userOnline.playCount)--当前在玩的人数
    end
    tools.FireEvent2(sendFun, buf:ip(), buf:port())
end

---------------------------------------------------------------------------------------------------
function OnStrongKickUser(buf)
    local userId = tonumber(buf:readString())
    local sendFun = function(outBuf)
            outBuf:writeString("GMSK") -- gm强行踢人
            outBuf:writeInt(1) --表示被GM踢掉。
    end
    if userlistIndexId[userId] then
        --踢出用户，这里不用返回了，因为服务器不需要知道
        tools.FireEvent2(sendFun, userlistIndexId[userId].ip, userlistIndexId[userId].port)
        tools.CloseConn(userlistIndexId[userId].ip, userlistIndexId[userId].port)
    end
end

--系统通知，聊天框
function BroadcastMsg(szMsg, msgType)
    local sendFun = function (outBuf)
        outBuf:writeString("REDC") --写消息头。
        outBuf:writeByte(4)      --desk chat
        outBuf:writeString(szMsg or "")     --text
        outBuf:writeInt(0)         --user id
        outBuf:writeString("") --user name
        outBuf:writeByte(0)
    end
    for k, v in pairs(userlist) do
        if (v.is_sub_user == nil) then
            netlib.send(sendFun, v.ip, v.port)
        end
    end
    
    if tex_speakerlib then
    	tex_speakerlib.record_chat_log(2, 0, szMsg, "系统消息")
    end
end

--系统通知，聊天框(自动全服广播) 
function broadcast_by_msgtype(szmsg_type, msgType) 
	local szMsg= "" 
	local sendFun = function (outBuf) 
		outBuf:writeString("REDC") --写消息头。 
		outBuf:writeByte(4) --desk chat 
		outBuf:writeString(szMsg or "") --text 
		outBuf:writeInt(0) --user id 
		outBuf:writeString("") --user name 
		outBuf:writeByte(0) 
	end 	
	for k, v in pairs(userlist) do 		
		if (v.is_sub_user == nil) then 
			szMsg = _U(tex_lan.get_msg(v,szmsg_type)); 
			netlib.send(sendFun, v.ip, v.port) 
		end 
	end 
	if tex_speakerlib then
		tex_speakerlib.record_chat_log(2, 0, szMsg, "系统消息")
	end
end

------------------------------------------------------------------------
--收到服务端发送过来的广播信息。给客服端发送广播。
function OnBroadcasetToClient(buf)
    local szMsg = buf:readString() --读取要广播的信息
    szMsg = split(szMsg,":FGLUA:") --分隔
    BroadcastMsg(szMsg[1], szMsg[2]) --GM发送的广播信息
end
--记录上次用户什么时间往服务器发了消息的
usermgr.ResetNetworkDelay = function(userKey)
    if (userlist[userKey] ~= nil) then
        userlist[userKey].lastRecvBufTime = os.time()
        userlist[userKey].SendNetworkDelayFlag = 0
        userlist[userKey].networkDelayTime = os.time()
        --如果用户反馈了nttt，则说明用户没有掉线，则直接删除userNeedCheckOnline里面的用户，不用检查了
    end
    userNeedCheckOnline[userKey] = nil
end

--找到没有发送网络数据超过20s的用户
usermgr.CheckNetWorkDelay = function()
    local timeFunc = function(buf)
                        buf:writeString("NTTT")
                    end
    for k, v in pairs(userlist) do
        --只检测非离线用户,如果断线了就不用检测了,5m内没有消息过来
        if (v.is_sub_user == nil and v.sockeClosed == false and math.abs(os.time() - v.lastRecvBufTime) > 300 and v.SendNetworkDelayFlag == 0) then
            userNeedCheckOnline[k] = v
            userNeedCheckOnline[k].networkDelayTime = os.time()
            userNeedCheckOnline[k].SendNetworkDelayFlag = 1
            tools.FireEvent2(timeFunc, v.ip, v.port)
        end
    end
end

--删除延时超时用户
usermgr.DelOffLineUser = function()
    for k, v in pairs(userNeedCheckOnline) do
        --如果用户断线超过2m，并且已经发送了探测网络的包，则踢掉用户
         if (v.is_sub_user == nil and math.abs(os.time() - v.networkDelayTime) > 120 and v.SendNetworkDelayFlag == 1) then
            userNeedCheckOnline[k].SendNetworkDelayFlag = 0
            --userNeedCheckOnline[k] = v
            local szIp = v.ip
            local nPort = v.port
            --掉线后，如果只有机器人，则直接结束牌局,一局打完后就踢掉此用户
            TraceError("倒计时踢用户")
            v.sockeClosed = true
            if (userlist[k] == nil) then
                userNeedCheckOnline[k] = nil
            else
                DoKickUserOnNotGame(k, true)
            end
            local time1 = os.clock() * 1000
            tools.CloseConn(szIp, nPort);
            local time2 = os.clock() * 1000
            if (time2 - time1 > 1000) then
                TraceError("tools.CloseConn执行超过1s时间 "..(time2 - time1))
            end
        end
    end
end

usermgr.IsLogin = function(userinfo)
    if (userinfo == nil) then
        return false
    end
    --nRet = nil说明用户登陆完成,否则登陆不算完成
    return userinfo.nRet == nil
end

--得到某个注册站点用户信息
usermgr.GetUserNumberInfo = function(nRegSiteNo)
    if (nRegSiteNo == nil) then
        return userOnline
    else
        return userOnline[nRegSiteNo]
    end

end

--增加在线总用户数
usermgr.AddTotalUserCount = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.totalCount = tUserNumberInfo.totalCount +  nNum --在线人数统计加1
end

--获取总人数
usermgr.GetTotalUserCount = function(nRegSiteNo)
    if (nRegSiteNo ~= nil) then
        local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
        if (tUserNumberInfo == nil) then
            return 0
        end
        return tUserNumberInfo.totalCount
    else
        local tUserNumberInfo = usermgr.GetUserNumberInfo()
        local nTotalCount = 0
        for k, v in pairs(tUserNumberInfo) do
            nTotalCount = nTotalCount + v.totalCount
        end
        return nTotalCount;
    end
end

--增加在玩总用户数
usermgr.enter_playing = function(user_info)
    -- 通知GameCenter玩家坐下
    notify_gc_user_site_state(user_info.userId, 1)

    usermgr.AddPlayingUserCount(user_info.nRegSiteNo, 1) --在玩人数+1
end

usermgr.leave_playing = function(user_info)
	-- 通知GameCenter玩家站起
	notify_gc_user_site_state(user_info.userId, 0)

    usermgr.AddPlayingUserCount(user_info.nRegSiteNo, -1) --在玩人数-1
end

usermgr.AddPlayingUserCount = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.playingCount = tUserNumberInfo.playingCount +  nNum --在线人数统计加1
end

--获取在玩总用户数
usermgr.GetPlayingUserCount = function(nRegSiteNo)
    if (nRegSiteNo ~= nil) then
        local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
        if (tUserNumberInfo == nil) then
            return 0
        end
        return tUserNumberInfo.playingCount
    else
        local tUserNumberInfo = usermgr.GetUserNumberInfo()
        local nTotalCount = 0
        for k, v in pairs(tUserNumberInfo) do
            nTotalCount = nTotalCount + v.playingCount
        end
        return nTotalCount;
    end
end

--增加机器人数量
usermgr.AddRobotUser = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.robotCount = tUserNumberInfo.robotCount +  nNum --在线人数统计加1
end

--获取机器人总用户数
usermgr.GetRobotUserCount = function(nRegSiteNo)
    if (nRegSiteNo ~= nil) then
        local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
        if (tUserNumberInfo == nil) then
            return 0
        end
        return tUserNumberInfo.robotCount
    else
        local tUserNumberInfo = usermgr.GetUserNumberInfo()
        local nTotalCount = 0
        for k, v in pairs(tUserNumberInfo) do
            nTotalCount = nTotalCount + v.robotCount
        end
        return nTotalCount;
    end
end


function usermgr.get_passport_by_user_id(user_id, callback) 
	local user_info = usermgr.GetUserById(user_id) 
		if (user_info ~= nil and user_info.passport ~= nil) then 
			callback(user_info.passport) 
		end 
		--处理以前的bug，通行证有回车换行的情况 
		local sql = string.format("select passport from dw_user_info where userid = %d", user_id) 
			dblib.execute(sql, function(dt) 
		if (dt and #dt > 0) then 
		local passport = string.match(dt[1]["passport"], "^(.*)\r\n$") 
		if (passport == nil or passport == "") then 
			passport = dt[1]["passport"] 
		end 
		if (user_info ~= nil) then 
			user_info.passport = passport 
		end 
			callback(passport) 
		else 
			callback(nil) 
		end 
	end) 
end

--根据passport获取用户id 
function usermgr.update_user_passport(user_info) 
	if (user_info == nil) then 
		return
	end 
		--处理以前的bug，通行证有回车换行的情况 
		local sql = "select passport from dw_user_info where userid = %d" 
		sql = string.format(sql, user_info.userId) 
		dblib.execute(sql, function(dt) 
			if (dt and #dt > 0) then 
				user_info.passport=dt[1]["passport"]
			else
				user_info.passport=""
			end 
		end) 
end

usermgr.AddUser = function(ip, port, key, szUserId, szUserName, nick, sex, imgUrl,
                 gamescore,city, szChannelNickName, nSid, nRegSiteNo, szUserSession, nChannelRole)
    --加入当前登录的用户到用户列表中
    ASSERT(userlist[key] == nil, "新增用户有问题，以前已经有这个用户，会把其他用户顶掉")
    userlist[key] = {}
    userlist[key].userId = tonumber(szUserId) --用户的数据库ID
    userlist[key].userName = szUserName --用户名
    userlist[key].nick = nick --昵称
    userlist[key].key  = key
    userlist[key].sex  = sex --性别
    userlist[key].imgUrl  = imgUrl --头像索引
    userlist[key].ip   = ip
    userlist[key].port = port
    userlist[key].gamescore = tonumber(gamescore) --游戏金币
    userlist[key].lastRecvBufTime = os.time() --上一次收到消息的时间
    userlist[key].networkDelayTime = os.time() --网络延迟时间
    userlist[key].SendNetworkDelayFlag = 0 --是否发送了网络延迟包，如果是正常收到数据包，需要把他设置成0
    userlist[key].city = city
    userlist[key].prekey = nil --用于保存重新登录前的USERKEY，便于退出时一起删除
    userlist[key].isrobot = false --默认为非机器人
    userlist[key].realrobot = false --用于记录真正是否机器人,主要增加了room.cfg.ignorerobot, 为了实现方便,将这里增加一个真正的机器标识
    if (userlist[key].userId == 21079) then  --特殊要求
        ip = "47.153.191.255"
    end
    if (userlist[key].userId == 16660) then  --特殊要求
        ip = "113.108.228.222"
    end
    local ip, from_city = iplib.get_location_by_ip(ip)
    userlist[key].szChannelNickName = string.toHex(from_city) --用户频道号
    userlist[key].nSid = tonumber(nSid)
    userlist[key].nRegSiteNo = tonumber(nRegSiteNo) --注册的站点
    userlist[key].sockeClosed = false  --socket是否被关闭了
    userlist[key].nRet = -1     --登陆返回值
    userlist[key].gameInfo = {} --游戏相关信息
    userlist[key].session = szUserSession
    userlist[key].visible_page = 0      --该用户进入房间之后观看牌桌的页号，初始化为0，表示还没有请求过有效页
    userlist[key].desk_in_page = 0      --该用户能够查看的页面牌桌数量

    if (tonumber(nSid) ~= 0) then
        userlist[key].channel_id = tonumber(nSid);
    else
        userlist[key].channel_id = -1;
    end
    userlist[key].channel_role = tonumber(nChannelRole);
        --更新家园开通信息等到user_info中，以后有需要的话，家园头像或其他家园信息也可以放这里更新
    
    if(dhomelib)then
    	xpcall(function()dhomelib.get_user_home_status(userlist[key]) end,throw)
	end
	
	--写入passport
	--xpcall(function() usermgr.update_user_passport(userlist[key]) end, throw)
	
	
	--更新短号
	if(channellib)then
		xpcall(function()channellib.update_user_shortid(userlist[key]) end,throw)
	end
    
    if(channellist[tonumber(nSid)] == nil) then
        channellist[tonumber(nSid)] = {count = 0, userlist={}}; 
    end

    channellist[tonumber(nSid)].count = channellist[tonumber(nSid)].count + 1;
    channellist[tonumber(nSid)].userlist[userlist[key].userId] = 1;

    ASSERT(userlistIndexId[userlist[key].userId] == nil, "新增用户有问题，userlistIndexId里面有这个用户")
    userlistIndexId[userlist[key].userId] = userlist[key]
    
    usermgr.AddTotalUserCount(userlist[key].nRegSiteNo, 1)

	 --因为频道默认是-1，而运维系统中所有站点也是用-1表示，所以这里转换一下，用1代表多玩，与-1不冲突
     --[[local online_count_flag=userlist[key].channel_id or -1
     if(online_count_flag==-1)then
      	online_count_flag=1
     end
     usermgr.AddTotalUserCount(online_count_flag, 1)
	 --]]
    --通知gamecenter用户来了
    tools.SendBufToUserSvr(gamepkg.name, "NTUF", "", "1", szUserSession)

    if(gamepkg.name == "tex") then
        usermgr.after_login_get_bankruptcy_info(userlist[key])
    end
    --更新频道房间列表（动态生成）
    if(groupinfo.groupid == "18002")then
    	hall.desk.add_channel_desk(userlist[key])
    end

end

usermgr.DelUser = function(key)
    --排队机相关
    if (key) then
        trace("清除排队中的用户"..key)
        UserQueueMgr.RemoveUser(key)
    end
    if(userlist[key] ~= nil) then
        local channel_id=userlist[key].channel_id;
        --通知客户端大厅，维护玩家在线列表(只有在100张桌以下的房间实行)
        if(#desklist <= 100 and gamepkg.name ~= "tex") then
            notify_sort_list_del(userlist[key])
        end

        --德州追踪连赢的玩家
        if(gamepkg.name == "tex")then
            local winningstreak = userlist[key].winningstreak
            if (winningstreak and winningstreak.count >= 3) then
        		local sqltmplet = "insert into log_winning_streak (`user_id`,`win_count`,`bigin_time`,`end_time`,`remark`) values(%d, %d, '%s', '%s','offline');commit;" 
        		local sql = format(sqltmplet, userlist[key].userId, winningstreak.count, winningstreak.begintime, os.date("%Y-%m-%d %X", os.time()))
        		dblib.execute(sql)
            end
        end

        local channel_id = userlist[key].channel_id;
        if(channel_id and channellist[channel_id] and channellist[channel_id].userlist[userlist[key].userId] ~= nil) then
            channellist[channel_id].userlist[userlist[key].userId] = nil
            channellist[channel_id].count = channellist[channel_id].count - 1;

            if(channellist[channel_id].count < 0) then
                channellist[channel_id].count = 0; 
            end

            if(not next(channellist[channel_id].userlist)) then
                channellist[channel_id] = nil;
            end
        end

        --只检查座位
        ASSERT(userlist[key].site == nil, "删除用户时候位置信息不为空 userid="..tostring(userlist[key].userId))
        usermgr.AddTotalUserCount(userlist[key].nRegSiteNo, -1)
        --因为频道默认是-1，而运维系统中所有站点也是用-1表示，所以这里转换一下，用1代表多玩，与-1不冲突
        --[[
        local online_count_flag=userlist[key].channel_id or -1
        if(online_count_flag==-1)then
        	online_count_flag=1
        end
        usermgr.AddTotalUserCount(online_count_flag, -1)
        --]]
        
        if (userlist[key].realrobot) then --如果是一个机器人
            usermgr.AddRobotUser(userlist[key].nRegSiteNo, -1) --机器人人数统计减1
        end
        ASSERT(userlist[key].userId ~= nil, "删除用户时候userId为空")
        ASSERT(userlistIndexId[userlist[key].userId] ~= nil, "删除用户时候userlistIndexId为空")

        local nUserId = userlist[key].userId
        local szSession = tostring(userlist[key].session)
        userNeedCheckOnline[key] = nil
        userlistIndexId[userlist[key].userId] = nil
        userlist[key] = nil
        tools.SendBufToUserSvr(gamepkg.name, "NTUF", "", "2", szSession) --gs删除用户了，通知gamecenter删除相应的数据

        --如果一个频道里没有人了，就把对应频道房清空
        if(channel_id~=nil and channel_id>0)then
            if(hall.desk.is_not_exist_channel(nUserId,channel_id)==0)then 
                hall.desk.remove_channel_desk(channel_id) 
            end
        end
        eventmgr:dispatchEvent(Event("on_user_exit", {user_id=nUserId}));   
    end
end

--替换key
usermgr.RelpaceUserKey = function(oldUserKey, newUserKey)
    local oldUserInfo = userlist[oldUserKey]
    if (oldUserInfo == nil) then
        TraceError("usermgr.RelpaceUserKey 老用户为空，m没法替换")
        return
    end
    if (oldUserKey == newUserKey) then
        TraceError("重登陆用户，但是ip port和以前的一样,特殊处理")
        userlist[oldUserKey].prekey = oldUserKey
        return
    end
    oldUserInfo.key = newUserKey --替换成新的KEY
    userlist[newUserKey] = oldUserInfo --USERLIST指向原有的的userinfo
    userlist[newUserKey].prekey = oldUserKey
    userlist[oldUserKey] = nil
    if (userNeedCheckOnline[oldUserKey] ~= nil) then
        userNeedCheckOnline[newUserKey] = userNeedCheckOnline[oldUserKey]
        userNeedCheckOnline[oldUserKey] = nil
    end
    --todo如果不是重登陆时候调用，要记得换掉排队队列里面的用户key,因为此函数只在重登陆时候调用，
    --且重登陆用户又踢掉了排队用户，所以不用更换排队队列里面的用户key
    hall.desk.set_user(oldUserInfo.desk, oldUserInfo.site, newUserKey) --替换desklist的userkey
end

usermgr.GetUserById = function (userId)
	if type(userId) ~= "number" then
		TraceError("userid is " .. type(userId))
		TraceError(tostring(debug.traceback()))
	end
    return userlistIndexId[tonumber(userId)]
end

usermgr.ChangeFace = function(key, szImgUrl)
    if (key == nil or userlist[key] == nil or szImgUrl == nil) then
        return false
    end
    userlist[key].imgUrl = szImgUrl
    net_broadcast_face_change(userlist[key])
    return true
end

usermgr.GiveGold = function(fromKey, toKey, nGold)
   if (fromKey == nil or userlist[fromKey] == nil or toKey == nil or userlist[toKey] == nil or nGold == nil) then
        return false
    end
    userlist[fromKey].gamescore = userlist[fromKey].gamescore - nGold
	userlist[toKey].gamescore = userlist[toKey].gamescore + nGold
    return true
end

--给玩家加钱 gold:钱数  ntype:理由
usermgr.addgold = function(userid, addgold, chou_shui_gold, ntype, 
                        chou_shui_type, borcastDesk, call_back, gools_id, gools_num, to_user_id)
	ASSERT(userid and userid > 0)
	--TraceError("usermgr.addgold("..userid..","..gold..","..ntype..")")
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then
		--改钱
		userinfo.gamescore = userinfo.gamescore + addgold
		if userinfo.gamescore < 0 then
            TraceError("为什么要送钱" .. debug.traceback())
			userinfo.gamescore = 0
		end

		--通知GameCenter
		--local szSendBuf = userinfo.userId..","..userinfo.gamescore --发送给gc服务中心消息
		--tools.SendBufToUserSvr(gamepkg.name, "STGB", "", "", szSendBuf) --发送数据到服务端，通知他更新有人送钱了
        --最高拥有过游戏币，如果userinfo.extra_info是空，宁可不更新，也比出错好
    	if(userinfo.extra_info~=nil and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            save_extrainfo_to_db(userinfo)
        end
		--通知自己
        net_send_user_new_gold(userinfo, userinfo.gamescore)
    end
	--写数据库
    dblib.cache_exec("updategold", {userid, addgold, chou_shui_gold, ntype, chou_shui_type}, nil, userid)

    --如果不需要通知客户端桌面
    if(borcastDesk and borcastDesk == 0) then
        return
    end

    --通知桌内玩家
    if userinfo and userinfo.desk then
        netlib.broadcastdesk(
            function(buf)
                buf:writeString("NTGC")
                buf:writeInt(userinfo.site or 0);		--对应座位号
                buf:writeInt(userinfo.gamescore);	--新钱
            end
        , userinfo.desk, borcastTarget.all);
    end
    
    if addgold == 0 then
    	return
    end
    --[[
    local economy_type = search_economy_by_type(ntype)
    if ntype == 80 then
        economy_type = 4 --这个是保险箱的产出消耗类型
        if gold > 0 then
            ntype = 85  --保险箱取出类型85 t_economy_info
        end
    end

    --记录经济系统数据
    xpcall(function() dblib.execute(string.format(tSqlTemplete.update_gold_system,gold,2,economy_type,ntype)) end,throw)
    --]]
    eventmgr:dispatchEvent(Event("on_user_add_gold", {user_id = userid, add_gold = addgold, 
                            chou_shui_gold = chou_shui_gold, add_type = ntype, chou_shui_type = chou_shui_type, 
                            gools_id = gools_id, gools_num = gools_num, to_user_id = to_user_id}));
end

--判断经济类型：0产出1消耗
function search_economy_by_type(ntype)
    for k,v in pairs(tSqlTemplete.GOLDSYSCFG.produceType) do
        if tonumber(ntype) == v then
            return 0
        end
    end

    for k,v in pairs(tSqlTemplete.GOLDSYSCFG.usedType) do
        if tonumber(ntype) == v then
            return 1
        end
    end

    return -1
end

--同步内存数据中的个人信息到数据库
function save_extrainfo_to_db(userinfo)
	local szextra_info = table.tostring(userinfo.extra_info)
	--TraceError("szextra_info:"..szextra_info)
	--local sql = "update user_tex_info set extra_info = %s where userid = %d"
	--dblib.execute(format(sql,szextra_info, userinfo.userId))
	dblib.cache_set(gamepkg.table, {extra_info=szextra_info}, "userid", userinfo.userId)
end

--更改玩家经验(多出来的代码都是为运维加的)
usermgr.addexp = function(userid, level, added_exp, nType, remark)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
    if(not userinfo) then return end

    --等级达到顶级了不增加经验
    if usermgr.getlevel(userinfo) > room.cfg.MaxLevel then
        userinfo.gameInfo.level = room.cfg.MaxLevel
        userinfo.gameInfo.exp = g_ExpLevelMap[room.cfg.MaxLevel]
        --写数据库
        dblib.cache_set(gamepkg.table, {level = room.cfg.MaxLevel}, "userid", userid)
        --等级与经验对应
        dblib.cache_set(gamepkg.table, {experience = g_ExpLevelMap[room.cfg.MaxLevel]}, "userid", userid)
        return
    end

    --判断日期(不是今日就得重置)——每天只能增加2500以内的经验
	local sys_today = os.date("%Y-%m-%d", os.time()) --系统的今天
	if(userinfo.dbtoday and userinfo.dbtoday ~= sys_today) then --日期不符
		--重置并同步
		userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
		userinfo.gameInfo.todayexp = added_exp
		dblib.cache_set(gamepkg.table, {todayexp = added_exp}, "userid", userinfo.userId)
    else
        --记录此人今天已经获得多少经验了
        if(userinfo.gameInfo.todayexp) then
            --每天获得经验不得超过2500点
            if(userinfo.gameInfo.todayexp > 2500) then 
                --TraceError(format("此玩家[%d]今天获得经验[%d]超过2500点了", userinfo.userId, userinfo.gameInfo.todayexp))
                return 
            end 
    		userinfo.gameInfo.todayexp = userinfo.gameInfo.todayexp + added_exp
    		dblib.cache_inc(gamepkg.table, {todayexp = added_exp}, "userid", userinfo.userId)
        end
	end

    --经验值达到上限，不再加了
    if(usermgr.getprestige(userinfo) >= room.cfg.MaxExperience) then
        return
    end

    --改经验
    userinfo.gameInfo.exp = usermgr.getexp(userinfo) + added_exp

    if userinfo.gameInfo.exp > room.cfg.MaxExperience then
        userinfo.gameInfo.exp = room.cfg.MaxExperience
    end
    --更经验副本
    userinfo.gameinfo_copy.e[gamepkg.name] = userinfo.gameInfo.exp

    --通知大厅
    notify_hall_prestige(userinfo)

    --通知桌内所有玩家某玩家的声望和积分,用广播方法
    net_broadcast_game_info(userinfo)

    --告诉自己增加了多少经验
    OnSendUserAddExpMsg(userinfo, userinfo, added_exp)

	--写数据库
    dblib.cache_inc(gamepkg.table, {experience = added_exp}, "userid", userid)

    --记录运维数据...................
    local peilv = "0/0"
    if(userinfo.desk) then
        local deskinfo = desklist[userinfo.desk]
        peilv = format("%d/%d", deskinfo.smallbet, deskinfo.largebet)
    end
    local questid = 0
    if nType == g_ExpType.quest then
        questid = tonumber(remark)
        remark = ""
    end
    local nowtime = os.time()
    local upgrade_time = os.date("%Y-%m-%d %X", nowtime)
    local distance_leveltime = 0
    --记录运维数据...................

    if(usermgr.getlevel(userinfo) > level) then
        --计算升级所需的时间
        distance_leveltime = nowtime - userinfo.upgradetime
        --改等级
		userinfo.gameInfo.level = usermgr.getlevel(userinfo)
        local givegold = get_upgrade_give_gold(level, usermgr.getlevel(userinfo))  --送钱
        
        if usermgr.getlevel(userinfo) == 1 then
            --玩家升到一级就发
            xpcall(
                function()
                    give_daygold_check(userinfo)
                end,throw)
        end

        --记录玩家升级日志
        xpcall(
            function()
                record_user_upgrade_log(userinfo.userId, level, 
                                        usermgr.getlevel(userinfo)- level, 
                                        usermgr.getlevel(userinfo), 
                                        givegold, groupinfo.groupid)
            end,throw)

        if userinfo.gameInfo.level > room.cfg.MaxLevel then
            userinfo.gameInfo.level = room.cfg.MaxLevel
        end

        --记录升级时间
        upgrade_time = os.date("%Y-%m-%d %X", nowtime)
        --记录到数据库，只是便于计算
        userinfo.upgradetime = nowtime
        dblib.cache_set(gamepkg.table, {upgradetime = userinfo.upgradetime}, "userid", userid)

        --写数据库(加1)
        dblib.cache_set(gamepkg.table, {level = usermgr.getlevel(userinfo)}, "userid", userid)

        --加钱
        usermgr.addgold(userinfo.userId, givegold, 0, g_GoldType.upgradegive, -1, 1)
        --播放升级动画
        --TraceError(format("等级从[%d]升到[%d]，共赠送金币[%d]", level, usermgr.getlevel(userinfo), givegold))
        net_broadcast_user_upgrade(userinfo, givegold)

        eventmgr:dispatchEvent(Event("user_level_event", {userinfo=userinfo, from_level=level, to_level=usermgr.getlevel(userinfo)}));
    end

    --记录变动日志
    --local sqlstr = "insert into log_change_experience "
    --sqlstr = sqlstr.."(sys_time, user_id, beforelevel, add_experience, after_experience, afterlevel, type, peilv, questid, upgrade_time, distance_leveltime, remark) "
    --sqlstr = sqlstr.." values(now(), %d, %d, %d, %d, %d, %d, '%s', %d, '%s', %d, '%s'); commit;"
    --sqlstr = format(sqlstr, userid, level, added_exp, usermgr.getexp(userinfo), usermgr.getlevel(userinfo), nType, peilv, questid, upgrade_time, distance_leveltime, remark or "")
    --dblib.execute(sqlstr)
end

--记录玩家升级日志
function record_user_upgrade_log(userid, oldlevel, addlevel, newlevel, givegold, remark)
    local insertstr = "insert into log_change_level (`sys_time`, `user_id`, `oldlevel`, `add_level`, `newlevel`, `givegold`, `remark`) "
    insertstr = insertstr .."values(now(), %d, %d, %d, %d, %d, '%s'); commit;"
    local sql = format(insertstr, userid, oldlevel, addlevel, newlevel, givegold, remark or "")

    dblib.execute(sql)
end

--得到用户经验
usermgr.getexp = function(userinfo)
    if not userinfo.gameInfo.exp then
        userinfo.gameInfo.exp = 0
        return 0
    end
    if userinfo.gameInfo.exp > room.cfg.MaxExperience then
        return room.cfg.MaxExperience
    end
    return userinfo.gameInfo.exp or 0
end
--得到用户等级
usermgr.getlevel = function(userinfo)
    local userExp = usermgr.getexp(userinfo)
    local level = 0
    for i = 1, #g_ExpLevelMap do
        if (userExp < g_ExpLevelMap[i]) then
            level = i - 1
            break
        end
    end
    return level
end
--得到所有游戏的最高等级
usermgr.get_max_game_level = function(userinfo)
    return room.arg.MaxLevel
end
--获取该次升级对应的赠送金额
function get_upgrade_give_gold(beforgrade, aftergrade)
    local givegold = 0
    if beforgrade <= 0 then
    	givegold = -400		--0级只送100
    end
    
    for i = beforgrade + 1, aftergrade do
        if i > 0 and i < 10 then
            givegold = givegold + 500
        elseif i < 20 then
            givegold = givegold + 1000
        elseif i < 30 then
            givegold = givegold + 2000
        elseif i < 40 then
            givegold = givegold + 3000
        elseif i < 50 then
            givegold = givegold + 4000
        elseif i < 60 then
            givegold = givegold + 5000
        elseif i < 70 then
            givegold = givegold + 6000
        elseif i < 80 then
            givegold = givegold + 7000
        elseif i < 90 then
            givegold = givegold + 8000
        elseif i < 100 then
            givegold = givegold + 9000
        end
    end
    return givegold
end
--广播玩家升级消息到客户端
function net_broadcast_user_upgrade(userinfo, givegold)
    if not userinfo then return end
    --通知桌内玩家
    local deskno = userinfo.desk
    --没有桌子号，只发给自己
    if(not deskno) then
        OnSendUserUpgradeInfo(userinfo, userinfo, givegold)
        return
    end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserUpgradeInfo(playingUserinfo, userinfo, givegold)
            end
            if(playingUserinfo == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno]
    if(not deskinfo) then return end
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendUserUpgradeInfo(watchinginfo, userinfo, givegold)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end

    --广播用户buff状态   
    net_broadcast_buff_change(userinfo)
end

--发送增加经验消息给一位玩家
function OnSendUserAddExpMsg(touserinfo, userinfo, addexp)
    if not touserinfo or not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("NTEXP")
            buf:writeInt(userinfo.userId);
            buf:writeByte(userinfo.site or 0);--对应座位号
            buf:writeInt(addexp)  
        end
    , touserinfo.ip, touserinfo.port);
end

--发送玩家升级消息给另一位玩家
function OnSendUserUpgradeInfo(touserinfo, userinfo, givegold)
    if not touserinfo or not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("NTUP")
            buf:writeInt(userinfo.userId);
            buf:writeByte(userinfo.site or 0);	--对应座位号
            buf:writeInt(usermgr.getlevel(userinfo));	--等级
            buf:writeInt(givegold or 0)  
        end
    , touserinfo.ip, touserinfo.port);
end

--更改玩家声望
usermgr.addprestige = function(userid, added_prestige)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then
        --声望值达到上限，不再加了
        if(usermgr.getprestige(userinfo) >= room.cfg.MaxPrestige) then
            return
        end

        --改声望
        userinfo.gameInfo.prestige = usermgr.getprestige(userinfo) + added_prestige

        if userinfo.gameInfo.prestige > room.cfg.MaxPrestige then
            userinfo.gameInfo.prestige = room.cfg.MaxPrestige
        end
        --更新声望副本
        userinfo.gameinfo_copy.p[gamepkg.name] = userinfo.gameInfo.prestige

		--通知大厅
		notify_hall_prestige(userinfo)

        --通知桌内所有玩家某玩家的声望和积分,用广播声望的方法
	    net_broadcast_game_info(userinfo)
	end

	--写数据库
    dblib.cache_inc(gamepkg.table, {prestige = added_prestige}, "userid", userid)
end

--得到用户声望
usermgr.getprestige = function(userinfo)
    if not userinfo.gameInfo.prestige then
		userinfo.gameInfo.prestige = 0
		--TraceError("userinfo.gameInfo.prestige = nil" .. debug.traceback())
        return 0
    end
    if userinfo.gameInfo.prestige > room.cfg.MaxPrestige then
        return room.cfg.MaxPrestige
    end
    return userinfo.gameInfo.prestige or 0
end

--更改玩家积分
usermgr.addintegral = function(userid, added_integral)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then

        --积分值达到上限，不再加了
        if(usermgr.getintegral(userinfo) >= room.cfg.MaxIntegral) then
            return
        end

		--改积分
		userinfo.gameInfo.integral = usermgr.getintegral(userinfo) + added_integral

        if userinfo.gameInfo.integral > room.cfg.MaxIntegral then
            userinfo.gameInfo.integral = room.cfg.MaxIntegral
        end

        --更新积分副本
        userinfo.gameinfo_copy.i[gamepkg.name] = userinfo.gameInfo.integral

		--通知大厅
		notify_hall_prestige(userinfo)

        --通知桌内所有玩家某玩家的声望和积分,用广播声望的方法
	    net_broadcast_game_info(userinfo)
	end

	--写数据库
    dblib.cache_inc(gamepkg.table, {integral = added_integral}, "userid", userid)
end

--得到用户积分
usermgr.getintegral = function(userinfo)
	if not userinfo.gameInfo.integral then
		userinfo.gameInfo.integral = 0
		--TraceError("userinfo.gameInfo.integral = nil" .. debug.traceback())
        return 0
    end
    if userinfo.gameInfo.integral > room.cfg.MaxIntegral then
        return room.cfg.MaxIntegral
    end
    return userinfo.gameInfo.integral or 0
end

--判断玩家是否可以领取破产救济
usermgr.check_user_get_bankruptcy_give = function(userinfo)
    if(not userinfo) then
        return 0
    end
    local givegold = room.cfg.gold_bankrupt_give_value   	   --破产赠送数额
    local give_count = userinfo.bankruptcy_give_count or 0     --破产赠送次数
    local give_time = userinfo.bankruptcy_give_time or 0       --最后赠送时间
    local mingold = room.cfg.gold_bankrupt_give_value          --最低赠送值界限
    local safegold = userinfo.safegold or 0                    --玩家保险箱里的钱

    if userinfo.gamescore >= mingold or safegold > 0 then 
    	return 0
    end
    
    if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
    	return 0
    end

    --今天开始时间
    local tbNow  = os.date("*t",os.time())    
    local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})

    --如果超过最后日期是0或者是昨天的
    if(give_time == 0 or give_time < todaystart) then
        userinfo.bankruptcy_give_count = 0
        return 1
    --如果是今天的
    else
        --超过赠送次数
        if(give_count >= room.cfg.gold_bankrupt_give_times) then
            return 0
        --还可以送
        else
            return 1
        end
    end
end

--用户登陆从DB读入赠送次数信息
usermgr.after_login_get_bankruptcy_info = function(userinfo, refresh, call_back)
    if(not userinfo) then
        return 
    end
    --如果用户的钱大于破产值，则不用查询数据库破产送钱次数了
    if (userinfo.gamescore > room.cfg.gold_bankrupt_give_value) then
        userinfo.bankruptcy_give_count = room.cfg.gold_bankrupt_give_times
        userinfo.bankruptcy_give_time= os.time();
        if (call_back) then
            call_back()
        end
        return
    end
    local userid = userinfo.userId
    dblib.execute(string.format(room.cfg.gold_bankrupt_selectsql, userid, userid),
        function(dt)
            if(dt~=nil and #dt > 0) then
                userinfo.bankruptcy_give_count = dt[1]["give_count"]
                userinfo.bankruptcy_give_time= dt[1]["give_time"]                
            end
            if (call_back) then
                call_back()
            end
        end
    )
end

--提供数值属性的二分查找可插入的位置，按照由大到小的次序
usermgr.locate_byprop = function(user_info, prop_tops, func_getprop)
    local topcount = #prop_tops
    local istart = 1
    local iend = topcount
    
    --异常处理
    if(user_info == nil or func_getprop == nil or func_getprop(user_info) == nil) then
        return -1
    end

    if(topcount < 0) then
        return -2
    end
    -- 空表，直接返回1
    if topcount == 0 or prop_tops[1] == nil then
        return 1
    end

    --要插入的值
    local user_value = func_getprop(user_info)
    local max_value = func_getprop(prop_tops[1])
    local min_value = func_getprop(prop_tops[topcount])

    -- 比最大的大，直接返回1
    if user_value > max_value then
        return 1
    end

    --最小为空，把它顶下去
    if min_value == nil then
        return topcount
    end
    -- 小于或等于最小，直接返回最末位置+1，后来的同名次排后
    if user_value <= min_value then
        return topcount + 1
    end

    local itag = math.floor((istart + iend)/2)
    -- 使用二分法查找定位
    while true do
        --中间值
        local mid_value = func_getprop(prop_tops[itag])
        if(mid_value ~= nil)then
            if mid_value > user_value then
                -- 二分的位置属性大于目标值
                istart = itag
            elseif mid_value < user_value then
                -- 二分的位置属性小于目标值
                iend = itag
            else
                -- 如果名次相同，先来先到的次序处理
                while mid_value ~= nil and mid_value == user_value do
                    itag = itag + 1
                    mid_value = func_getprop(prop_tops[itag])
                end
                break
            end
            if iend - istart < 2 then
                -- 没有相等的情况，表示需要插入到大(istart)和小(iend)之间
                itag = iend
                break
            end
            itag = math.floor((istart + iend)/2)
        else
            --为什么有空属性???
            itag = iend
            break
        end
    end
    return itag
end

-- 删除排序的结果
usermgr.clear_top_data = function()
    local top_value
    for _, top_value in pairs(g_topusers) do
        while(#top_value.data > 0) do
            table.remove(top_value.data)
        end
    end
end

--按照指定的属性设置获取排名前N名的列表
usermgr.sort_top_users = function(count)
    local top_value, user_info
    usermgr.clear_top_data()
    for _, user_info in pairs(userlist) do
        if user_info.realrobot == false or _DEBUG then --不是机器人账号
            for top_key, top_value in pairs(g_topusers) do
                --判断信息是否在范围，是否大于最后一位，如果是，则用二分法找到应该插入的位置
        		local pos_item = usermgr.locate_byprop(user_info, top_value.data, top_value.rule)
                --插入到top的表
        		if (pos_item > 0 and pos_item < count + 1) then	--位置合法
					-- count表示需要排序的排名总数，在排序过程中，不一定与top_value.data的长度相等
        			if(pos_item > #top_value.data) then
        				table.insert(top_value.data, user_info)
        			else
        				table.insert(top_value.data, pos_item, user_info)
        			end

					-- 删除超过排名的数据，从末位删除
                    while(count < #top_value.data) do
                        table.remove(top_value.data)
                    end
				else
					--超出了范围是可能发生的正常情况，表示该User不能上榜
        		end
                --按照从大至小的顺序排序
            end
        end
    end
end

--通知桌内所有玩家某玩家的声望信息()
function net_broadcast_game_info(myuserinfo, bReloginUser)
    if not myuserinfo then return end
    --通知桌内玩家
    if(not bReloginUser) then bReloginUser = 0 end
    local deskno = myuserinfo.desk
    --没有桌子号，只发给自己
    if(not deskno) then
        OnSendUserGameInfo(myuserinfo, myuserinfo, bReloginUser)
        return
    end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserGameInfo(playingUserinfo, myuserinfo, bReloginUser)
            end
            if(playingUserinfo == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendUserGameInfo(watchinginfo, myuserinfo, bReloginUser)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end

    --广播用户buff状态   
    net_broadcast_buff_change(myuserinfo)
end

--发送玩家声望信息给另一位玩家
function OnSendUserGameInfo(touserinfo, userinfo, isrelogin)
    if not touserinfo or not userinfo then return end
    if(not isrelogin) then isrelogin = 0 end
    netlib.send(
        function(buf)
				buf:writeString("NTDU")
				buf:writeInt(userinfo.site or 0);		                --对应座位号
                buf:writeInt(userinfo.userId);
				buf:writeInt(usermgr.getprestige(userinfo));	--新声望
                buf:writeInt(usermgr.getintegral(userinfo));	--新积分
                buf:writeInt(usermgr.getexp(userinfo));	--经验
                buf:writeInt(usermgr.getlevel(userinfo));	--等级
                buf:writeByte(isrelogin)  
        end
    , touserinfo.ip, touserinfo.port);
end

----------------------------------------------

--更新输赢数和日期
--is_win为空时今日输赢数不改变
usermgr.update_win_lose = function(userid, recent_date, wingold)
    ASSERT(userid and userid > 0)
	if true then return end 
    local userinfo = usermgr.GetUserById(userid)
    local user_history = usermgr.get_user_history(userinfo)

    if(userinfo ~=nil and user_history ~=nil)then
        --创建新的日期
        if(user_history[recent_date] == nil)then
            user_history[recent_date] = {}
            user_history[recent_date].win = 0
            user_history[recent_date].lose = 0
        end

        --今日输赢发生改变
        if(wingold ~= nil)then
            if(wingold > 0) then
                user_history[recent_date].win = user_history[recent_date].win + wingold
            else
                user_history[recent_date].lose = user_history[recent_date].lose - wingold
            end
        end

        --获取更新今日输赢后的输赢数组
        local history = usermgr.get_user_history_array(userinfo)

        --数组大小不足时补足,并且检查日期格式
        local HISTORY_MIN = 2  --保证至少有2个数组成员
        local history_count = #history > HISTORY_MIN and #history or HISTORY_MIN
        for i=1,history_count do
            if(history[i]==nil)then
                history[i]={}
                history[i].win = 0
                history[i].lose = 0
                history[i].date = "NULL"
            else
                if(history[i].date == nil) then
                    history[i].date = "NULL"
                else
                    local str_year, str_month, str_day
                    str_year, str_month, str_day = string.match(history[i].date,"(%d+)-(%d+)-(%d+)")
                    if(str_year == nil or str_month == nil or str_day == nil)then
                        history[i].date = "NULL"
                    end
                end
            end
        end

        --写入数据库的变量
        local recent_win, recent_lose, recent_date, last_win, last_lose, last_date

        --写数据库
        recent_win  = history[1].win or 0
        recent_lose  = history[1].lose or 0
        if(history[1].date == nil or history[1].date == "NULL")then
            recent_date = "NULL"
        else
            recent_date = history[1].date
            dblib.cache_set(gamepkg.table, {recent_date = recent_date}, "userid", userid)
        end
        last_win = history[2].win or 0
        last_lose = history[2].lose or 0
        if(history[2].date == nil or history[2].date == "NULL")then
            last_date = "NULL"
        else
            last_date = history[2].date
            dblib.cache_set(gamepkg.table, {last_date = last_date}, "userid", userid)
        end

        dblib.cache_set(gamepkg.table, {recent_win = recent_win,recent_lose = recent_lose,last_win = last_win,last_lose = last_lose}, "userid", userid)
   end
end

----------------------------------------------

--------------------------公会专用房间相关代码---------------------------
--处理输入队列，将队列中内容提取出来进行协议分析及处理
function onrecv(recvbuf)
    --cmd = netbuf.readString(inbuf)
    local recv_start = os.clock()*1000

    room.perf.recv_packcount = room.perf.recv_packcount + 1
    usermgr.ResetNetworkDelay(getuserid(recvbuf))
    local nBufLen = recvbuf:readInt()
    local cmd = recvbuf:readString()
    if (cmd ~= "RETT") then
        trace(string.format("onrecv command %s(in %d bytes).", cmd, nBufLen))
    end
    if (duokai_lib) then
        duokai_lib.pre_process_recv_msg(cmd, recvbuf)
    end
    if not dispatch(cmd, recvbuf) then
        gameonrecv(cmd, recvbuf)
    end

    if (room.perf.cmdlist[cmd] == nil) then
		room.perf.cmdlist[cmd] = {count=0,cost=0,aver=0}
    end

    local recv_end = os.clock()*1000
    local difftime = recv_end - recv_start
    --统计每一种协议的执行效率
    room.perf.cmdlist[cmd].count = room.perf.cmdlist[cmd].count + 1
    room.perf.cmdlist[cmd].cost = room.perf.cmdlist[cmd].cost + difftime
    room.perf.cmdlist[cmd].aver = room.perf.cmdlist[cmd].cost / room.perf.cmdlist[cmd].count

    room.perf.recv_slicelen = room.perf.recv_slicelen + difftime
end

--将命令相关内容，打包加入到输出队列
function onsend(sCommand, sendbuf)
	room.perf.send_packcount = room.perf.send_packcount + 1
	local send_start = os.clock()*1000
    if (sCommand ~= "NTTT") then
        trace("onsend ".. sCommand)
    end
    if not dispatch(sCommand, sendbuf) then
        gameonsend(sCommand, sendbuf)
    end
	local send_end = os.clock()*1000
	room.perf.send_slicelen = room.perf.send_slicelen + send_end - send_start
end


function dispatch(sCommand, buf)
    local fCommand = cmdHandler[sCommand]
    if fCommand ~= nil then
        g_errmsgprefix = sCommand
        xpcall(function() fCommand(buf) end, throw)
    else
        return false
    end
    return true
end

--机制代码:
function OnRecvBufFromGameSvr(buf)
    onrecv(buf)
end

function on_send_gs_buf_to_user_id(buf)
    buf:writeString("GSPP")
    buf:writeInt(room.arg.gspp_to_user_id)
    buf:writeInt(room.arg.gspp_from_user_id)
    buf:writeString(room.arg.gspp_szErrorMsg)
    room.arg.func(buf)
    return true
end

function on_send_gs_buf(buf)
    buf:writeString("GSSG")
    room.arg.func(buf)
    return true
end

--发送一个buf到其他gameserver上
function send_buf_to_gamesvr_by_use_id(from_user_id, to_user_id, func, szErrorMsg)
    room.arg.gspp_from_user_id = from_user_id
    room.arg.gspp_to_user_id = to_user_id
    room.arg.gspp_szErrorMsg = szErrorMsg
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSPP")
end

--发送一个buf到所有的gamesvr上
function send_buf_to_all_game_svr(func)
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSSG")
end

--广播玩家列表，告诉有人进来了
function notify_sort_list_add(user_info)
    netlib.broadcastroom(
        function(buf, user)
            buf:writeString("ULAD")
            --当前用户的数据库ID
			buf:writeInt(user_info.userId)
			--昵称
			buf:writeString(user_info.nick)
			--头像URL
			buf:writeString(user_info.imgUrl)
			--金币数    user_info.gamescore
			buf:writeInt(user_info.gamescore)
			--经验      user_info.gameInfo.exp
			buf:writeInt(user_info.gameInfo.exp)
			--声望      user_info.gameInfo.prestige
			buf:writeInt(user_info.gameInfo.prestige)
			--荣誉      user_info.gameInfo.integral
			buf:writeInt(user_info.gameInfo.integral)
        end
    )
end

--广播玩家列表，告诉有人走了
function notify_sort_list_del(userinfo)
    netlib.broadcastroom(
        function(buf, user)
            buf:writeString("ULDL")
            buf:writeInt(userinfo.userId)
        end
    )
end

function notify_sort_list(user_info, sort_data, sort_type)
    netlib.send(
        function(out_buf)
            out_buf:writeString("RERSL")
			-- 当前请求的排序类型
			out_buf:writeString(sort_type)
			-- 当前请求的玩家排序数量,加入自己的信息，自己放在第一位
			local send_count = 50
			if (send_count > #sort_data) then
				send_count = #sort_data
			end
    		out_buf:writeShort(send_count + 1)
			--当前用户的数据库ID
			out_buf:writeInt(user_info.userId)
			--昵称
			out_buf:writeString(user_info.nick)
			--头像URL
			out_buf:writeString(user_info.imgUrl)
			--金币数    user_info.gamescore
			out_buf:writeInt(user_info.gamescore)
			--经验      user_info.gameInfo.exp
			out_buf:writeInt(user_info.gameInfo.exp)
			--声望      user_info.gameInfo.prestige
			out_buf:writeInt(usermgr.getprestige(user_info))
			--荣誉      user_info.gameInfo.integral
			out_buf:writeInt(usermgr.getintegral(user_info))
    		for iuser = 1, send_count do
                --用户的数据库ID
                out_buf:writeInt(sort_data[iuser].userId and sort_data[iuser].userId or 0)
                --昵称
                out_buf:writeString(sort_data[iuser].nick)
				--头像URL
				out_buf:writeString(sort_data[iuser].imgUrl)
            	--金币数    user_info.gamescore
            	out_buf:writeInt(sort_data[iuser].gamescore and sort_data[iuser].gamescore or 0)
            	--经验      user_info.gameInfo.exp
            	out_buf:writeInt(sort_data[iuser].gameInfo.exp and sort_data[iuser].gameInfo.exp or 0)
            	--声望      user_info.gameInfo.prestige
            	out_buf:writeInt(usermgr.getprestige(sort_data[iuser]) and usermgr.getprestige(sort_data[iuser]) or 0)
            	--荣誉      user_info.gameInfo.integral
            	out_buf:writeInt(usermgr.getintegral(sort_data[iuser]) and usermgr.getintegral(sort_data[iuser]) or 0)
    		end
        end
    , user_info.ip, user_info.port)
end

-- 处理查看页状态
visible_page_list.reg_page_user = function(user_info, visible_page, desk_in_page, visible_desk_list)
	user_info.visible_page = visible_page
	user_info.desk_in_page = desk_in_page
	user_info.visible_desk_list = visible_desk_list
end

visible_page_list.unreg_page_user = function(user_info)
	user_info.visible_page = 0
	user_info.desk_in_page = 0
	user_info.visible_desk_list = {}
end

--------------------------------------------------------------------------------
--发送指定属性排序的结果，需要客户端发送需要的排序类型，参考g_topusers中的key分别对应gold, exp, prestige, integral
function OnRequireRoomSortList(in_buf)
    local sort_type = in_buf:readString()
    local user_key = getuserid(in_buf) --buf:ip()..":"..buf:port()
	local user_info = userlist[user_key]
	if not user_info then return end

    if g_topusers[sort_type] ~= nil then
        notify_sort_list(user_info, g_topusers[sort_type].data, sort_type)
    else
        TraceError("客户端发送非法的排序标记，忽略！")
    end
end

--发送本房间所有玩家列表
function OnRequireRoomUserList(in_buf)
    --TraceError("本房间所有玩家列表")
    local user_key = getuserid(in_buf)
	local user_info = userlist[user_key]
	if not user_info then return end

    local sendlist = {}
    for k, v in pairs(userlist) do
        table.insert(sendlist, v)
    end
    notify_sort_list(user_info, sendlist, "integral")
end

-- 客户端通知玩家离开了牌桌大厅画面（进入牌桌游戏，或者离开大厅, TODO:关闭客户端怎么办?）
function OnClientLeaveRoom(in_buf)
    local user_key = getuserid(in_buf) --buf:ip()..":"..buf:port()
	local user_info = userlist[user_key]
	if user_info ~= nil then
		visible_page_list.unreg_page_user(user_info)
	end
end
--------------------------------------------------------------------------------
--收到玩家请求桌子列表
function OnQuestDeskList(in_buf)
    --TraceError("收到玩家请求桌子列表OnQuestDeskList")
    local userkey = getuserid(in_buf)
    local userinfo = userlist[userkey]
    if not userinfo  then
        TraceError("OnQuestDeskList遇到不合法的用户识别，忽略请求!")
        return 
    end 
    --选哪个大TAB
    local desktype = in_buf:readShort()
    --选哪个小TAB
    local chosetab = in_buf:readShort()
    
    if desktype < 1 then return end
    if chosetab < 1 then return end
    
    --隐藏房间参数
    local hidenull, hidefull, isfast, isstart = in_buf:readByte(), in_buf:readByte(), in_buf:readByte(), in_buf:readInt()
    
    --处理玩家请求桌子列表
    DoQuestDeskList(userinfo, desktype, chosetab, hidenull, hidefull, isfast, isstart)
end

--处理玩家请求桌子列表
function DoQuestDeskList(userinfo, desktype, chosetab, hidenull, hidefull, isfast, isstart, send_func)
    --TraceError("处理玩家请求桌子列表")
    if not userinfo  then
        TraceError("DoQuestDeskList遇到不合法的用户识别，忽略请求!")
        return 
    end

    local get_key = format("%d_%d_%d_%d_%d_%d_%d", userinfo.channel_id, desktype, chosetab, hidenull, hidefull, isfast, isstart)
    local resultarr = displaydesk[get_key] or {}
    --如果请求的是频道的桌子列表，那么要看这个用户是不是对应频道的

    --没过缓存时间
    local sendlist = {}
    local currtime = os.clock() * 1000
    if resultarr.savetime and currtime - resultarr.savetime < 1000 then
        --TraceError(format("缓存的列表没过期，自动发送缓存列表.."))
        sendlist = resultarr.sendlist
    else
        --刷新列表
        sendlist = get_show_desks(desktype, chosetab, hidenull, hidefull, isfast, isstart,userinfo.channel_id)
        --缓存此次筛选的列表
        resultarr.sendlist = sendlist
        resultarr.savetime = os.clock() * 1000
        displaydesk[get_key] = resultarr
        table.sort(sendlist, function(deskno1, deskno2) return deskno1 < deskno2 end)
        
    end	
    response_desk_list(userinfo, sendlist, send_func)
    
    --TraceError(format("desktype[%d], chosetab[%d], hidenull[%d], hidefull[%d], isfast[%d], isstart[%d]",desktype, chosetab, hidenull, hidefull, isfast, isstart));
    --TraceError(format("用时:%d ms", os.clock() * 1000 - currtime))
end

--按条件显示桌子列表
function get_show_desks(desktype, chosetab, hidenull, hidefull, isfast, isstart,channel_id)
    local sendlist = {}
    
    --预筛选函数
    local FunPreSelector = function(deskno)

        local deskinfo = desklist[deskno]
        
        --无效桌子
        if not deskinfo then
            return false
        end
        
        
        --请求的桌子种类:1普通,2比赛,3VIP 10是VIP贵族房
        if deskinfo.desktype ~= desktype and deskinfo.desktype  ~= 10  then
           return false
        end
        


        --如果桌子有频道属性，并且桌子的频道号与玩家的频道号不同，就不显示出来。
        if(desktype==4 and (deskinfo.channel_id==nil or deskinfo.channel_id==-1))then--频道房如果没有频道ID，直接不显示
            return false
        end

        if(deskinfo.channel_id~=nil and deskinfo.channel_id~=-1)then

            if(channel_id~=nil and  deskinfo.channel_id ~= channel_id)then
            
                return false
            end
        end

        --隐藏空房间
        if hidenull == 1 and deskinfo.playercount == 0 then
            return false
        end
        
        --隐藏满人房间
        if hidefull == 1 and (deskinfo.playercount == deskinfo.max_playercount) then
            return false
        end
        
        --隐藏非快速场
        if deskinfo.fast ~= isfast then
            return false
        end
        
        --是否隐藏已开始桌
        if(isstart == 1 and gamepkg.getGameStart(deskno)) then
            return false
        end
        
        return true
    end

    --再次筛选(ntype:1找有人而且不满的，2找满人的，3找空的)
    local FunSelector = function(deskno, isfast, peilv1, ntype)
        local deskinfo = desklist[deskno]
        --无效的桌子
        if deskinfo == nil then
            return false
        end
        --每次筛选时去掉等于10（贵族房）的情况，在最后再单独处理
        if deskinfo.desktype == 10 then
        	return false
        end
        local playercount = deskinfo.playercount
        local max_playercount = deskinfo.max_playercount
        local deskpeilv1 = deskinfo.smallbet
        if(desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
            deskpeilv1 = deskinfo.at_least_gold
        end
        if deskinfo.fast == isfast and deskpeilv1 == peilv1 then
            --有人而且不满
            if ntype == 1 and playercount > 0 and playercount < max_playercount then  
                return true 
            --满人桌子
            elseif ntype == 2 and playercount == max_playercount then  
                return true 
            --没人的桌子
            elseif ntype == 3 and playercount == 0 then
                return true 
            end
        end
        return false
    end

    --预筛选
    local newdesklist = {}
    for i = 1, #desklist do
        if(FunPreSelector(i) == true)then
            table.insert(newdesklist, i)
        end
    end
    --获取显示配置
    local displaycfg = hall.displaycfg.getdisplaycfg(desktype, chosetab)
    
    --整个场，如新手场、高手场
    --要求：优先显示有人而且不满的桌子，然后显示满的桌子，再显示空桌子
    --如果：显示的都满了，就必须显示一个空桌子
    local tmp_display_count=0
    for ifast,fastarr in pairs(displaycfg) do
        --快速或普通
        for peilv1, displaycount in pairs(fastarr) do
    
            local desk_by_peilv1 = {}
            local singlefull = -1  --多找一个满桌子，如果都满了就把这个附上
            local not_full_desk_count=0 --有人且没满
            local full_desk_count=0 --满人
            
            for i = 1, #newdesklist do  
                if FunSelector(newdesklist[i], ifast, peilv1, 1) == true then --先找有人而且没满的桌子
                    not_full_desk_count=not_full_desk_count+1
                    table.insert(desk_by_peilv1, newdesklist[i])
                end
                if FunSelector(newdesklist[i], ifast, peilv1, 2) == true then  --再找满人的桌子
                    full_desk_count=full_desk_count+1
                    table.insert(desk_by_peilv1, newdesklist[i])
                end
            end
            
            --再找空桌子,如果一开始没人，至少显示displaycount个空桌子
            tmp_display_count=not_full_desk_count+full_desk_count+1
            if(tmp_display_count<displaycount) then tmp_display_count=displaycount end

            if #desk_by_peilv1 < tmp_display_count then
                for i = 1, #newdesklist do
                    if FunSelector(newdesklist[i], ifast, peilv1, 3) == true then
                        table.insert(desk_by_peilv1, newdesklist[i])
                        if #desk_by_peilv1 >= tmp_display_count then break end
                    end 
                end
            end
            --选中普通专家房这个tab时，把VIP和贵族房加上
	       if (viproom_lib and desktype == g_DeskType.normal and chosetab == 4) then
	       		for i = 1, #newdesklist do
			     	if viproom_lib.is_spec_room_id(sendlist, newdesklist[i]) == 1 then
			     		 table.insert(desk_by_peilv1, newdesklist[i])
			     	end
		     	end

		    end  
            for i = 1, #desk_by_peilv1 do
                table.insert(sendlist, desk_by_peilv1[i])
            end
            

      end --for peilv1, displaycount
    end --for ifast,fastarr
    return sendlist
end

--发送一批桌子的列表
function onsenddesklist(userinfo, sendlist)
  local desk_start    = 1
  local desk_end      = #sendlist
  local desk_count    = #sendlist

  --判断参数合法性
  if not userinfo then return end

  local idesk = 1
    netlib.send(
      function(out_buf)
        out_buf:writeString("REDS")
        out_buf:writeInt(desk_end - desk_start + 1)
        for idesk = desk_start, desk_end do
          local deskno = sendlist[idesk]
          local deskinfo = desklist[deskno]
          local userarr = {}
          for isite = 1, room.cfg.DeskSiteCount do
            local playerinfo = get_site_user(deskno, isite)
            if playerinfo then 
              table.insert(userarr, playerinfo)
            end
          end
          for _, watcherinfo in pairs(deskinfo.watchingList) do
            if watcherinfo then 
              table.insert(userarr, watcherinfo)
            end
          end

          out_buf:writeInt(deskno)
          --名称
          out_buf:writeString(vip_room_name ~= nil and vip_room_name or deskinfo.name)
          --桌子类型:1普通,2比赛桌,3VIP
          out_buf:writeByte(deskinfo.desktype)
          --是否快速桌
          out_buf:writeByte(deskinfo.fast)
          --桌面筹码数
          out_buf:writeInt(deskinfo.betgold)
          --桌子的玩家筹码
          out_buf:writeInt(deskinfo.usergold)
          --所需等级
          out_buf:writeInt(deskinfo.needlevel)
          --小盲
          out_buf:writeInt(deskinfo.smallbet)
          --大盲
          out_buf:writeInt(deskinfo.largebet)
          --金钱下限
          out_buf:writeInt(deskinfo.at_least_gold)
          --金钱上限
          out_buf:writeInt(deskinfo.at_most_gold)
          --抽水
          out_buf:writeInt(deskinfo.specal_choushui)
          --最少开局人数
          out_buf:writeByte(deskinfo.min_playercount)
          --最大开局人数
          out_buf:writeByte(deskinfo.max_playercount)
          --当前在玩人数
          out_buf:writeByte(hall.desk.get_user_count(deskno))
          local watch_count = 0
          for k,v in pairs(deskinfo.watchingList) do
              watch_count = watch_count + 1
          end
          --观战人数
          out_buf:writeInt(watch_count)
          --是否开始
          out_buf:writeByte(gamepkg.getGameStart(deskno) and 1 or 0)
          
          --是不是VIP房
          out_buf:writeByte(0)
        end
      end
    , userinfo.ip, userinfo.port)
end

--给玩家分批发送桌子列表
function response_desk_list(userinfo, sendlist, send_func)
    --TraceError("response_desk_list")
    if not userinfo then return end;
    --通知客户端开始发送
    local NoticeStart = function(userinfo)
        netlib.send(
            function(buf)
                buf:writeString("REDSS");
            end,userinfo.ip,userinfo.port);
    end
    --通知客户端发送完毕
    local NoticeEnd = function(userinfo)
        netlib.send(
            function(buf)
                buf:writeString("REDSE");
            end,userinfo.ip,userinfo.port);
    end
    --发送开始
    NoticeStart(userinfo);
    
    --没有记录
    if not sendlist or #sendlist <= 0 then
        NoticeEnd(userinfo);
        return;
    end
    
    --如果记录过多，需要分包发送
    local packlimit = 20;  --每个包20条记录
    local packlist = {};
    for i=1, #sendlist do
        local packindex = math.floor(i/packlimit) + 1;
        if not packlist[packindex] then packlist[packindex] = {} end;
        table.insert(packlist[packindex], sendlist[i]);
    end
 
    --TraceError(packlist)
    for i = 1, #packlist do
        if (send_func == nil) then
            onsenddesklist(userinfo, packlist[i]);
        else
            send_func(packlist[i]);
        end
    end;   
    
    NoticeEnd(userinfo);
end
--收到玩家请求某桌子上的玩家列表
function OnRequireDeskUser(in_buf)
	--TraceError("OnRequireDeskUser")
	local userkey = getuserid(in_buf)
	local userinfo = userlist[userkey]
	if not userinfo  then
		TraceError("OnRequireDeskUser遇到不合法的用户识别，忽略请求!")
		return 
    end
	--选哪个deskno
	local deskno = in_buf:readInt()
	if deskno < 1 or deskno > #desklist then return end

    OnSendDeskUser(userinfo, deskno)
end
--给玩家发送桌子上所有玩家(包括观战玩家)信息
function OnSendDeskUser(userinfo, deskno)
    --TraceError("OnSendDeskUser"
	if not userinfo or not deskno or not desklist[deskno] then return end;
	local deskinfo = desklist[deskno];
    local parent_play_arr = {};
    local userarr = {}
    deskinfo.usergold = 0
    for nsite = 1, room.cfg.DeskSiteCount do
        local playerinfo = userlist[hall.desk.get_user(deskno, nsite)]
        if playerinfo then 
            table.insert(userarr, playerinfo)
            deskinfo.usergold = deskinfo.usergold + playerinfo.gamescore

            if(duokai_lib ~= nil) then
                local parent_id = duokai_lib.get_parent_id(playerinfo.userId);
                if(parent_id > 0) then 
                    parent_play_arr[parent_id] = 1;
                end
            end
        else
            desklist[deskno].site[nsite].user = nil
        end
    end
    for k, watcherinfo in pairs(deskinfo.watchingList) do
        if userlist[k] == nil then
            deskinfo.watchingList[k] = nil
        else
            if (duokai_lib == nil or (parent_play_arr[watcherinfo.userId] == nil and duokai_lib.is_sub_user(watcherinfo.userId) == 0)) then
                table.insert(userarr, watcherinfo)                              
            end 
        end
    end 
    
    netlib.send(
        function(out_buf)
            out_buf:writeString("SDDU")
            out_buf:writeInt(deskno)
            --桌面筹码数
            out_buf:writeInt(deskinfo.betgold)
            --桌子的玩家筹码
            out_buf:writeInt(deskinfo.usergold)
            --当前在玩人数
            out_buf:writeByte(hall.desk.get_user_count(deskno))
            local watch_count = 0
            for k,v in pairs(deskinfo.watchingList) do
                if (duokai_lib == nil or (parent_play_arr[v.userId] == nil and duokai_lib.is_sub_user(v.userId) == 0)) then                   
                    watch_count = watch_count + 1
                end
            end            
            --观战人数
            out_buf:writeInt(watch_count)
            out_buf:writeByte(#userarr)
            for i = 1, #userarr do
                local state_value = SITE_UI_VALUE.NULL
                if userarr[i].site then
                    state_value = gamepkg.TransSiteStateValue(deskinfo.site[userarr[i].site].state)
                end
                local vip_level = 0
                if viplib then
                    vip_level = viplib.get_vip_level(userarr[i])
                end
                out_buf:writeByte(state_value)
                --用户的数据库ID
                out_buf:writeInt(userarr[i].userId or 0)
                --昵称
                out_buf:writeString(userarr[i].nick or "")
                --VIP玩家
                out_buf:writeByte(vip_level)
                --头像URL
                out_buf:writeString(userarr[i].imgUrl or "")
                --金币
                out_buf:writeInt(userarr[i].gamescore or 0)
                --频道角色
                out_buf:writeInt(userarr[i].channel_role or 0);
                --性别
                out_buf:writeInt(userarr[i].sex or 0);
                --是否开通了家园
                out_buf:writeInt(userarr[i].home_status or 0);
                
            end
        end
    ,userinfo.ip, userinfo.port)  
end
function onsendrqck(buf)
    buf:writeString("RQCK")
end

function onrecvreck(buf)
    local sessionkey = buf:readString()
    trace(string.format("收到客户端会话密钥:%s, 地址为:%s:%d", sessionkey, buf:ip(), buf:port()))

    --trace(type(userlist))
    --userlist = {}
    local key = getuserid(buf) --buf:ip()..":"..buf:port()
    local userinfo = userlist[key]
    --room.arg.score = userinfo.gamescore
    --同名判断放在登录时进行
    --if (user) then
        --已经有同名用户登录到本房间，不允许再登入
        --todo:需要断开与客户端的连接
        --
    --  trace("todo:同名用户已经登录到房间中，不允许再登录")
    --  return 0
    --else
        --doAddUser(buf:ip(), buf:port(), userid, key, sessionkey, -1, -1, startflag.notready)
        --给当前登录用户发送密钥验证成功，登录房间成功
        --trace("验证密钥成功！ "..buf:ip()..":"..buf:port())
        tools.fireEvent("CKOK", buf:ip(), buf:port())
    --end
end

function onsendckok(buf)
    buf:writeString("CKOK")
    buf:writeString(getuserid(buf)) --string.format("%s:%s", buf:ip(), buf:port()))
    --buf:writeString(room.arg.score)
end
--------------------------------------------------------------------------------
function doDelUser(userKey)
    local userinfo = userlist[userKey]
    if (userinfo) then
        --清除服务端桌子信息
        eventmgr:dispatchEvent(Event("do_kick_user_event", {userinfo=userlist[userKey]}));

        if (userinfo.desk and userinfo.site) then
            hall.desk.clear_users(userinfo.desk, userinfo.site)
        end
        --如果在观战，就只从观战列表清除
        if (userinfo.desk and not userinfo.site) then
            DoUserExitWatch(userinfo)
        end

        --好友离线通知
        --TraceError("通知好友离线change_userstate_tofriend")
        --friendlib.change_userstate_tofriend(userinfo,0)

        if (userinfo.sockeClosed == true) then
            usermgr.DelUser(userKey)
        end
    else
        trace(userKey.."用户从未登录过，取消发送其离线通知")
    end
end

function onnotifyoffline(buf)
    buf:writeString("NTOF")
    buf:writeString(g_currentuser) --唯一用户名
    buf:writeString(g_currentusernick) --眤称
    buf:writeInt(g_olddeskno)
    buf:writeInt(g_oldsiteno)
    buf:writeByte(1) --需要显示在屏幕上
end

function onclientoffline(buf)
    local userkey = getuserid(buf)
    eventmgr:dispatchEvent(Event("on_socket_close",	{user_key=userkey}))
    trace(format("收到离线通知: %s", userkey))
    local userinfo = userlist[userkey]
    if (userinfo == nil) then
        return
    end
    
	--好友离线通知
	--TraceError("通知好友离线onclientoffline")
    --friendlib.change_userstate_tofriend(userinfo,0)
    
    userinfo.sockeClosed = true
    DoKickUserOnNotGame(userkey, true)    
end

function notify_gc_user_site_state(user_id, is_sitdown)
    local szParam = user_id..","..is_sitdown
    tools.SendBufToUserSvr(getRoomType(), "SCUSS", "", "", szParam)
end

--------------------------------------------------------------------------------
function doSitdown(userKey, ip, port, nDeskNo, nSiteNo, sittype)
    --判断参数合法性
    local sit_type = sittype or g_sittype.normal
    local bReloginUser = sit_type == g_sittype.relogin and 1 or 0
    ASSERT(nDeskNo <= #desklist and nSiteNo <= room.cfg.DeskSiteCount)

    local userinfo = userlist[userKey]    
    --检查双重坐下，坐下失败
    if sit_type ~= g_sittype.relogin and userinfo.site then
       TraceError("还在别的桌子游戏..却来坐这个桌子？？？"..debug.traceback());
       return;
    end
    
    --检查双重身份，干掉原来身份
    if userinfo.desk and userinfo.desk ~= nDeskNo then
       TraceError("还在别的桌子观战..却来坐这个桌子？？？"..debug.traceback());
       desklist[userinfo.desk].watchingList[userKey] = nil
    end
        
     if (viproom_lib) then
        local succcess, ret = xpcall( function() return viproom_lib.on_before_user_site(userinfo, nDeskNo) end, throw)
        if (ret == 0) then
            return
        end
    end   

    --超过10分钟不坐下，踢出到大厅


    --从观战列表移除
    local deskinfo = desklist[nDeskNo] or {}
        
    deskinfo.watchingList[userKey] = nil
    
    userinfo.olddesk = userinfo.desk or -1
    userinfo.oldsite = userinfo.site or -1
    
   
    --设置用户坐下的位置
    if bReloginUser == 0 then
        hall.desk.user_sitdown(userKey, nDeskNo, nSiteNo, startflag.notready, sit_type)
    end

    if (gamepkg ~= nil and gamepkg.AfterUserSitDown ~= nil) then
        local doSitdown1 = function()
            gamepkg.AfterUserSitDown(userinfo.userId, userinfo.desk, userinfo.site, sit_type)
        end
        getprocesstime(doSitdown1, "doSitdown1", 500)
    end

    --通知该人的声望信息
    OnSendUserSitdown(userinfo, userinfo, 1, sit_type)  --先告诉自己坐下
    net_broadcast_game_info(userinfo, bReloginUser)

    --通知桌子上所有人本人来啦
    local time1 = os.clock() * 1000
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(nDeskNo,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(nDeskNo,i) or ""]
            if (playingUserinfo and 
                playingUserinfo.offline ~= offlinetype.tempoffline and
                userinfo.userId ~= playingUserinfo.userId) then
                OnSendUserSitdown(playingUserinfo, userinfo, 1, sit_type)  --我坐下你坐下
                OnSendUserSitdown(userinfo, playingUserinfo, 1, g_sittype.normal)  --你坐下我坐下

                --游戏信息
                OnSendUserGameInfo(userinfo, playingUserinfo, 0)
            end
            if(playingUserinfo == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(nDeskNo,i)
            end
        end
    end
    
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if(userlist[k] == nil) then
            deskinfo.watchingList[k] = nil
        else
            if (watchinginfo.offline ~= offlinetype.tempoffline) then
                OnSendUserSitdown(watchinginfo, userinfo, 1, sit_type)  --我坐下你观战
            end
        end
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 500)  then
        TraceError("通知桌子上有人来啦,时间超常:"..(time2 - time1))
    end
    --通知桌子上所有人本人来啦(结束)

	--派发见面事件
    local doSitdown2 = function()
        dispatchMeetEvent(userinfo, bReloginUser)
    end
    getprocesstime(doSitdown2, "doSitdown2", 500)
	

	--发送坐下消息报之后
	if (gamepkg ~= nil and gamepkg.AfterUserSitDownMessage ~= nil) then
        local doSitdown3 = function()
            gamepkg.AfterUserSitDownMessage(userinfo.userId, userinfo.desk, userinfo.site, bReloginUser)
        end
        getprocesstime(doSitdown3, "doSitdown3", 500)
        eventmgr:dispatchEvent(Event("site_event",	_S{userinfo=userinfo,user_id = userinfo.userId, deskno = userinfo.desk, site = userinfo.site}))
        
    end
    usermgr.enter_playing(userinfo)
end

--发送玩家坐下
function OnSendUserSitdown(userinfo, sitdowninfo, retcode, sittype)
    if not userinfo or not sitdowninfo then return end
    if not sitdowninfo.desk or not sitdowninfo.site then return end 
    local bReloginUser = sittype == g_sittype.relogin and 1 or 0
    local nStartFlag = gamepkg.getGameStart(sitdowninfo.desk, sitdowninfo.site) and 1 or 0
    local ship_ticket_count = sitdowninfo.propslist[tex_gamepropslib.PROPS_ID.ShipTickets_ID] or 0
    --冠军次数
    local car_king_count =  -1 
    if car_match_lib then
    	car_king_count = car_match_lib.get_useing_king_count(sitdowninfo.userId)
    end
    netlib.send(
        function(buf, user)
            buf:writeString("RESD")
            buf:writeByte(retcode) --错误代号 0, 已经有人，1 可以坐, 2是站起来
            buf:writeByte(bReloginUser) --1 表示重新登录的用户,不要增加桌面图标, 0表示正常登录用户,可以增加桌面人数
            buf:writeString(sitdowninfo.key) --哪个用户坐下
            buf:writeString(sitdowninfo.nick) --此用户眤称
            buf:writeInt(sitdowninfo.desk)
            buf:writeInt(sitdowninfo.site)
            buf:writeInt(sitdowninfo.olddesk) -- > -1 则为从哪张台站起来
            buf:writeInt(sitdowninfo.oldsite)
            buf:writeInt(sitdowninfo.gamescore) --写入分数
            buf:writeString(sitdowninfo.city) --城市名称
            buf:writeInt(room.cfg.beginTimeOut) --超时时间,这里暂时只写了斗地主时间
            buf:writeString(sitdowninfo.imgUrl)
            buf:writeByte(sitdowninfo.sex)
            buf:writeByte(nStartFlag)  --游戏开始状态
            buf:writeInt(sitdowninfo.userId)
            buf:writeString(string.HextoString(sitdowninfo.szChannelNickName))
            buf:writeInt(usermgr.getexp(sitdowninfo)) --游戏经验
            buf:writeInt(sitdowninfo.nSid) --频道Id
            buf:writeInt(desklist[sitdowninfo.desk].gamepeilv)
            buf:writeInt(sitdowninfo.tour_point or 0) --坐下发送竞技场点数
            buf:writeInt(usermgr.getlevel(sitdowninfo)); --游戏等级
            buf:writeInt(getSiteGold(sitdowninfo));     --手上的筹码数
            buf:writeInt(viplib.get_vip_level(sitdowninfo) or 0);     --用户的VIP等级
            buf:writeInt(sitdowninfo.short_channel_id or -1)
            buf:writeInt(sitdowninfo.home_status or 0)
            buf:writeByte(sitdowninfo.mobile_mode or 0)
            buf:writeInt(ship_ticket_count)
            buf:writeInt(car_king_count)
        end
    , userinfo.ip, userinfo.port);
end

--获得某个座位的筹码数
function getSiteGold(userinfo)
    local usergold = userinfo.chouma;
    if(usergold == 0) then
        local sitedata = deskmgr.getsitedata(userinfo.desk, userinfo.site);
        usergold = sitedata.gold;
    end
    return usergold;
end

function onrequestchangesite(buf)
	local dessiteno = buf:readInt()
	--参数合法检测
	if (dessiteno == nil or dessiteno > room.cfg.DeskSiteCount or dessiteno < 1) then
		return
	end
	--没有此人，或没有坐下，或者位置相同，则不做任何操作
	local userkey = getuserid(buf)
    local userinfo = userlist[userkey]
	if (userinfo == nil or userinfo.desk == nil or userinfo.site == nil or userinfo.site == siteno) then
		return
	end
	local deskno = userlist[userkey].desk
	local siteno = userlist[userkey].site
	--不是公会房，或者游戏开始了，或者需要换的位置有人了，则不做任何操作
	if (gamepkg.getGameStart(deskno, dessiteno) == true or hall.desk.isemptysite(deskno, dessiteno) == false) then
		return
	end
	--用户站起来
	doUserStandup(userkey, false)
	--用户坐下
	doSitdown(userkey, buf:ip(), buf:port(), deskno, dessiteno, g_sittype.normal)
	usermgr.enter_playing(userlist[userkey])
end

--[[
	-1参数不对
	-2房间已经开始游戏，且不允许观战
	-3坐满了不允许观战
	-4观战人数满了
	-5本房间不允许直接坐下
	-6坐在有人的座位上
	-7你已经不属于此公会
	-8坐下的时候发现别人设置了新赔率
	-9非法赔率
--]]
function onrecvrqsitdown(buf)
	local deskno = buf:readInt()
    local siteno = buf:readInt()
	local peilv	 = buf:readInt()

    local userkey = getuserid(buf)
	local userinfo = userlist[userkey]
	local nRet = 0

    local retFun = function(buf)
		buf:writeString("REFS")
		buf:writeInt(nRet)
    end
	local sitdownFailFun = function()
		if gamepkg and gamepkg.OnSitDownFailed then		--坐下失败时
            gamepkg.OnSitDownFailed(userinfo)
        end
	end

    if not userinfo or userinfo.site then
		return
	end

    --本房间不允许直接坐下
    if (groupinfo.can_sit == 0) then
        nRet = -5
        tools.FireEvent2(retFun, buf:ip(), buf:port())
        return
    end

	--检测参数对不对
    if (deskno > #desklist or deskno <= 0) then --桌子id不对
        nRet = -1
        tools.FireEvent2(retFun, buf:ip(), buf:port())
		--sitdownFailFun()
        return
    end

    local canqueue, value = can_user_enter_desk(userkey, deskno)
    if canqueue ~= 1 then
        --发送无法进入房间消息
        OnSendUserAutoJoinError(userinfo, canqueue, value)
        return
    end

    --检测游戏是否开始
    local nstart = false
    if (gamepkg ~= nil and gamepkg.getGameStart ~= nil) then
        nstart = gamepkg.getGameStart(deskno)
    end

    local desktype = desklist[deskno].desktype
    if ((desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and nstart == true) then --房间已经开始了
        nRet = -2
        tools.FireEvent2(retFun, buf:ip(), buf:port())
        trace("房间开始了")
		sitdownFailFun()
        return
	end

	--座位号为0时检测是否有空位置
	if(siteno == 0)then
		siteno = hall.desk.get_empty_site(deskno)
		if(siteno == -1)then --位置坐满了
			nRet = -3
			tools.FireEvent2(retFun, buf:ip(), buf:port())
			sitdownFailFun()
			return
		end
	end

    --已经有人
	if(desklist[deskno].site[siteno].user ~= nil)then
		nRet = -6
		tools.FireEvent2(retFun, buf:ip(), buf:port())
		sitdownFailFun()
		return
	end

    --成功坐下
	nRet = 1
	tools.FireEvent2(retFun, buf:ip(), buf:port())

	doSitdown(userkey, buf:ip(), buf:port(), deskno, siteno, g_sittype.normal)

	UserQueueMgr.RemoveUser(userkey)

	usermgr.enter_playing(userlist[userkey])


end

--------------------------------------------------------------------------------
function onrecvcall(buf)
    g_currcall = buf:readString();
    g_isvalid = 1

    group = groupinfo
    if (group ~= nil and group.allowhallchat == 1) then
        local userid = getuserid(buf)
        local userinfo = userlist[userid]
        g_currentuser = userinfo.nick --getuserid(buf)--string.format("%s:%s", buf:ip(), buf:port())
        g_siteno = userinfo.site

        callallpeople(g_currentuser, g_currcall, g_isvalid, userinfo)
    end
end

--------------------------------------------------------------------------------
function doUserStandup(userkey, bIsLunHuan, retcode)
    local userinfo = userlist[userkey]
    local deskno = userinfo.desk
    local siteno = userinfo.site

    --先发送游戏异常中断消息  --转移到外面执行，因与站起来无直接的关系
    if (deskno == nil) then
        return      --未曾坐下的不需要继续处理，不然会出错
    end
    --人没坐下，不用站起来了，
    if (siteno == nil) then
        return
    end

    --站起前
    if (gamepkg ~= nil and gamepkg.OnUserStandup ~= nil) then
        xpcall(function() gamepkg.OnUserStandup(userinfo.userId, deskno, siteno) end, throw)
    end

    --发送用户站起来的消息,(1允许站起来)
    local rcode = 1;
    if(retcode ~= nil) then rcode = retcode; end
   -- TraceError("doUserStandup站起来:::::::::"..rcode);
    onsendstandup(userinfo, rcode);
     
    if (gamepkg ~= nil and gamepkg.OnPlayGame ~= nil) then
        gamepkg.OnPlayGame(deskno)
    end
    hall.desk.clear_users(deskno, siteno)
    eventmgr:dispatchEvent(Event("on_user_standup", {user_info = userinfo, desk_no = deskno, site_no = siteno}));
    --站起后
    if (gamepkg ~= nil and gamepkg.AfterOnUserStandup ~= nil) then
        xpcall(function() gamepkg.AfterOnUserStandup(userinfo.userId, deskno, siteno) end, throw)
    end
end

--让所有机器人站起来，并放到排队队列里
function DoAllDeskRobotStandup(nDeskNo)
    if (desklist[nDeskNo].playercount > 0) then --如果还有人
        local bHavePeople = false
        local userKey  = nil
        for i = 1, room.cfg.DeskSiteCount do
            userKey = hall.desk.get_user(nDeskNo, i)
            if (userKey ~= nil and userlist[userKey].isrobot == false) then
                bHavePeople = true
                break
            end
        end
        --让当前桌所有的机器人全部站起来去排队, 并把机器人扔到队列里面
        if (bHavePeople == false) then
            trace("重置机器人状态，让他们都去排队")
            for i = 1, room.cfg.DeskSiteCount do
                userKey = hall.desk.get_user(nDeskNo, i)
                if (userKey ~= nil ) then
                    doUserStandup(userKey,false)
                    userinfo = userlist[userKey]
                    if (userinfo ~= nil) then
                        UserQueueMgr.AddUser(userKey, userinfo.ip, userinfo.port, queryReasonFlg.gameOverAndLost)
                    else
                        trace("userInfo为空？")
                    end
                end
            end
        end
    end
end

--当用户在游戏时踢成断线用户，不再游戏时直接从userlist里面清空
function DoKickUserOnNotGame(userkey, resetAllRobot)
    local key = userkey
    local nRet = ResetUser(key, resetAllRobot, true)
    if (nRet == 2) then
        doDelUser(key)
    end
    return nRet
end

--当用户在打牌时踢成离线用户，当用户没在打牌时让他站起来,并且重置排队状态
function ResetUser(userkey, resetAllRobot, is_kill)
    --清除坐下的信息
    local bGameAlreadyStart = false
    local userinfo = userlist[userkey]
    if (userinfo == nil) then
        return
    end
    local userid = userinfo.userId
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
        bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)
    end
    --德州只有比赛场才有离线状态
    if(bGameAlreadyStart and gamepkg.name == "tex") then
        local deskinfo = desklist[userinfo.desk]
        bGameAlreadyStart = false; 
        --[[
        if(deskinfo and deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament)then
            bGameAlreadyStart = false
        end
        --]]
    end
    bGameAlreadyStart = false
    if bGameAlreadyStart then --游戏已经开始，则视为用户断线了
        trace("重置用户状态，游戏已开始")
        doSetTempOfflineState(userinfo)
        return 1
    else  --游戏未开始，则作为用户站起来处理，一般情况是游戏未开始时，用户直接关闭了游戏客户端

        if(is_kill ~= nil and is_kill == true) then
            eventmgr:dispatchEvent(Event("do_kick_user_event", {userinfo=userlist[userkey]}));
        end

        trace("重置用户状态，游戏未开始")
        local nDeskNo = userinfo.desk
        doUserStandup(userkey,false)
        --如果用户站起来，并却游戏未开始，则把用户从排队机的队列中取出来
        UserQueueMgr.RemoveUser(userkey)
        --如果一桌必须要有自然人，并当前桌都是机器人，并且一桌打完时需要重牌机器人，则让机器人站起来，则踢掉当前桌所有机器人到队列中
        if (room.cfg.DeskMustHavePerson == 1 and nDeskNo ~= nil and room.cfg.ongameOverReQueue == 1 and resetAllRobot == true) then
            DoAllDeskRobotStandup(nDeskNo)
        end
        return 2
    end
end

--如果三家都掉线直接结束牌局
function OverGameOnAllOffline(userinfo)
    local nOffLineCount = 0
    for i = 1, room.cfg.DeskSiteCount do
        --ASSERT(userinfo.desk ~= nil, "当前用户没有桌子")
        --ASSERT(desklist[userinfo.desk].site[i].user ~= nil, "当前桌子没有用户")
        --ASSERT(userlist[desklist[userinfo.desk].site[i].user] ~= nil, "当前桌子没有用户")

        if (desklist[userinfo.desk].site[i].user ~= nil and
            userlist[desklist[userinfo.desk].site[i].user] ~= nil and
            userlist[desklist[userinfo.desk].site[i].user].offline) then
            nOffLineCount = nOffLineCount + 1
        end
    end
    trace(userinfo.desk.."桌暂时离线用户"..nOffLineCount)
    if (nOffLineCount == hall.desk.get_user_count(userinfo.desk)) then
        trace("所有人都掉线,直接结束牌局")
        if(gamepkg and gamepkg.OnAbortGame) then
            gamepkg.OnAbortGame(userinfo.key)
            return true
        end
    end
    return false
end
--新协议，玩家请求回到大厅
function onrecvsbacktohall(buf)
    trace(string.format("用户(%s)请求回大厅", getuserid(buf)))
    local user_key = getuserid(buf)
    local user_info = userlist[user_key]
    if (user_info == nil) then
        return
    end
    pre_process_back_to_hall(user_info)
end

--新协议，玩家请求回到大厅,传入user_info的版本
function pre_process_back_to_hall(user_info)
    local ret = 1
    if (duokai_lib) then
        ret = duokai_lib.on_back_to_hall(user_info)        
    end
    if (ret == 1) then
        eventmgr:dispatchEvent(Event("back_to_hall", {userinfo=user_info, user_info=user_info}));
        --这里可能是子账号，但是一定要告诉父账号离开了
        if (duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 1) then
            user_info = usermgr.GetUserById(duokai_lib.get_parent_id(user_info.userId))
        end
        process_back_to_hall(user_info)
    end
end

--玩家请求回到大厅,
--注意内部接口其他模块不能直接调用，需要调用pre_process_back_to_hall，或者直接发协议onrecvsbacktohall
function process_back_to_hall(userinfo)
    local bok = 1
    local bGameAlreadyStart = false
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
    	local n_desk=userinfo.desk
        local bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)
        if bGameAlreadyStart then
            gamepkg.forceGameOverUser(userinfo)
        end
        ResetUser(userinfo.key, true)

		if(tex_userdiylib)then
			tex_userdiylib.on_recv_update_userlist(userinfo,n_desk)
   		end
    elseif(userinfo.desk ~= nil) then
    	
        DoUserExitWatch(userinfo)

    end

    if bGameAlreadyStart then
        gamepkg.forceGameOverUser(userinfo)
        bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)

    end
    netlib.send(
        function(buf)
            buf:writeString("REBH")
            buf:writeShort(1) --是否允许退出,0不允许，1允许
        end
        , userinfo.ip, userinfo.port)
end

--用户请求站起来--不一定要回大厅
function onrecvstandup(buf)
    trace(string.format("用户(%s)请求站起来", getuserid(buf)))
    local userKey = getuserid(buf)
    if (userlist[userKey] == nil) then
        return
    end
    local bGameAlreadyStart = false
    local userinfo = userlist[userKey]
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
        bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)
    end
    if bGameAlreadyStart then
        gamepkg.forceGameOverUser(userinfo)
        bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)
    end
    local bok = 1
    if bGameAlreadyStart == false then 
        ResetUser(userKey, true)
         bok = 1
    else  --游戏已经开始,不允许站起来
         bok = 0
    end
    netlib.send(
        function(buf)
            buf:writeString("REOT")
            buf:writeShort(bok) --是否允许退出
        end
        , userlist[userKey].ip, userlist[userKey].port)
end

--发送玩家站起
function onsendstandup(userinfo, retcode)
    --TraceError("发送玩家站起"..debug.traceback())
    --TraceError(format("桌号[%d]座位号[%d]站起,玩家ID[%d]", userinfo.desk, userinfo.site, userinfo.userId))
	if userinfo==nil then return end;
    if not userinfo.desk or not userinfo.site then return end
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("NTSU")
            buf:writeInt(retcode)        --返回代号 0, 不能站起来，1 可以站起来
            buf:writeString(userinfo.key) --哪个用户站起来
            buf:writeString(userinfo.nick)
            buf:writeInt(userinfo.desk)
            buf:writeInt(userinfo.site)
        end
    , userinfo.desk, borcastTarget.all);
end

--登录相关
function getRoomType()
    if (gamepkg.name == nil) then
        trace("没有初始化gamepkg.name变量，请在Gama脚本中初始化这个变量")
        return "error"
    end
    return gamepkg.name --当前房间为ddz, zjh, xxxx....
end

--限制同一个IP的登陆玩家数量,1可以登陆，-1不允许登陆
function LoginIP_Restrict(userinfo, lgIP)
    local sendFun = function(userinfo, retcode, msg)
        netlib.send(
            function(buf)
                buf:writeString("NTIP")
                buf:writeInt(retcode)
                buf:writeString(msg)
            end
        , userinfo.ip, userinfo.port)
    end

    --公司IP地址:113.106.110.34
    if not LoginIPs or lgIP == "125.88.37.28" or tonumber(userinfo.userId) <= 1000 then sendFun(userinfo, 1, _U("可以登录")) return 1 end --兼容不重启
    local iprarr = LoginIPs[lgIP];
    local allowMax = 10;
    local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天

    if(not iprarr or iprarr["today"] ~= sys_today) then
        iprarr = {};
        iprarr["logincount"] = 0;
        iprarr["today"] = sys_today;
    end
    if(iprarr[userinfo.userId] == 1) then
        sendFun(userinfo, 1, _U("可以登录"));
        return 1
    end
    if(iprarr["logincount"] >= allowMax) then
        --不准登录咯
        --local msg = format("对不起，该IP允许的最大登入账户数超过限制，请明天再试!");
        local msg = tex_lan.get_msg(userinfo, "h2_msg");
        sendFun(userinfo, -1, _U(msg));
        return -1
    else
        --sendFun(userinfo, 1, _U("可以登录"));
        sendFun(userinfo, 1, _U(tex_lan.get_msg(userinfo, "h2_msg_1")));
    end
    iprarr[userinfo.userId] = 1;
    iprarr["logincount"] = iprarr["logincount"] + 1;

    LoginIPs[lgIP] = iprarr;

    return 1
end

--用户从临时断线状态中，再次登录了
function doUserRelogin(oldUserKey, newUserKey, newIp, newPort)
    local oldUserInfo = userlist[oldUserKey]
    if (oldUserInfo == nil) then
        TraceError("doUserRelogin重登陆用户，但是以前的用户信息为空")
        return
    end
    room.arg.oldkey = oldUserInfo.key
    room.arg.oldreloginip = oldUserInfo.ip
    room.arg.oldreloginport = oldUserInfo.port
    room.arg.olddeskno = oldUserInfo.desk
    room.arg.oldsite = oldUserInfo.site

    --换key之前，重置检测用户状态
    usermgr.ResetNetworkDelay(oldUserKey)
    --清除排队队列里面的用户
    UserQueueMgr.RemoveUser(oldUserKey)
    --修改用户列表信息
    usermgr.RelpaceUserKey(oldUserInfo.key, newUserKey)
    oldUserInfo.ip = newIp
    oldUserInfo.port = newPort
    oldUserInfo.relogin = true
    oldUserInfo.sockeClosed = false
    usermgr.ResetReloginState(newUserKey)      --初始化重登录状态
    --如果重登陆ip端口没有重复，且以前的socket没有被关闭过，则关闭以前的socket
    --todo如果出现第一次和第二次的ip prot一样，会造成以前的socket泄露
    if oldUserInfo.sockeClosed == false then
        tools.CloseConn(room.arg.oldreloginip, room.arg.oldreloginport)
    end
    trace(format('重新登录时(newkey=%s)，记录旧KEY(prekey):%s', userlist[newUserKey].key, userlist[newUserKey].prekey))

    room.arg.newkey = newUserKey
    room.arg.newreloginip = oldUserInfo.ip
    room.arg.newreloginport = oldUserInfo.port

    -- 通知GameCenter玩家坐下, 特别修改，没有使用enter_playing
    notify_gc_user_site_state(userlist[newUserKey].userId, 1)
    --通知所有大厅用户，有客户重新登录，要进行IP地址替换工作
    --重新登录的客户端，在大厅初始化后立即启动游戏客户端
    --broadcast_lib.borcast_desk_event_old("NTRL", userlist[newUserKey].desk, netlib.borcast_target.playing)
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("NTRL")
        end
    , userlist[newUserKey].desk, borcastTarget.playingOnly);
    return 101
end


function OnNotifyLogin(buf)
    local clockQueue = {};
	table.insert(clockQueue, os.clock()*1000);

    local nRet = 0
    local szToken = buf:readString()
    local szUserInfo = buf:readString()
    local szUserId = nil     --todo 这里是服务器定义的userid，而下面的userid其实是服务器上的userName，以后要全部改过来才可以
    local szUserName = nil
    local szNick = nil
    local szSex = nil
    local szIconIdx = nil
    local szScore = nil
    local szCity = nil
    local szPlayingRoomId = nil
    local szPlayingRoomName = nil
    local szChannelNickName = ""
    local nSid = 0
    local nChannelRole = 0;
    local last_sid = -1;
    local nRegSiteNo = 0 --注册站点ID
    local msg = "nouse"   --返回的登录信息
    local tableUserInfo = nil
    local szUserSession = nil
    local kickFun = function(outBuf)
        outBuf:writeString("GMSK") -- gm强行踢人
        outBuf:writeInt(1) --表示被GM踢掉。
    end
    
    if (string.len(szUserInfo) == 0 )then  --说明用户没有登录过gamcenter
        nRet = -1
    else
        tableUserInfo = split(szUserInfo, ",")
        szUserId = tableUserInfo[1]
        szUserName = tableUserInfo[2]
        szNick = string.HextoString(tableUserInfo[3])
        szSex = tableUserInfo[4]
        szIconIdx = string.HextoString(tableUserInfo[5])
        szScore = tableUserInfo[6]
        szCity = tableUserInfo[7]
        szChannelNickName = tableUserInfo[8]
        nSid = tableUserInfo[9]
        nRegSiteNo = tableUserInfo[10] --得到注册站点。
        szPlayingRoomId = tableUserInfo[11]
        szPlayingRoomName = tableUserInfo[12]
        szUserSession = tableUserInfo[13]
        szUserSession = szUserSession .. "|" .. os.time() .. math.floor(math.random() * 9999) .. "|" .. groupinfo.groupid
        nChannelRole = tableUserInfo[14] or 0;
        last_sid = tableUserInfo[15] or -1;
        nRet = 1
    end

    table.insert(clockQueue, os.clock()*1000);

    local szIpInfo = split(szToken, ",")
    local szUserKey = getuserid2(szIpInfo[1], szIpInfo[2])
    if (nRet == 1) then  --登录过gamecenter,请参考登陆流程图看下面代码
        --TraceError('ok1')
        local userinfo = usermgr.GetUserById(tonumber(szUserId))
        --[[
        if (userinfo ~= nil and userinfo.desk ~= nil and gamepkg.getGameStart(userinfo.desk) == true) then
            --TraceError('ok2')
            raiseSiteStateEvent(userinfo);
            doUserRelogin(userinfo.key, szUserKey, szIpInfo[1], tonumber(szIpInfo[2]))
            nRet = 2 --重新登陆
        else--]]
        if (userinfo ~= nil) then
            --ASSERT(userinfo.offline == nil, "用户离线，异常情况")
            if(userinfo.offline ~= nil) then
                TraceError(format("玩家[%d]离线状态异常[%s]", userinfo.userId, tostring(userinfo.offline)))
            end
            userinfo.sockeClosed = true  --为了踢此用户信息,需要强制设置socketcolse 为true
            DoKickUserOnNotGame(userinfo.key, false)
            if (not (szIpInfo[1] == userinfo.ip and tonumber(szIpInfo[2]) == userinfo.port)) then                
                tools.CloseConn(userinfo.ip, userinfo.port)
            end
            nRet = 1
        else
             if (userlist[szUserKey] ~= nil) then --其他人登陆但是ip端口和自己重复
                nRet = -103
                TraceError("NTLG其他人登陆但是ip端口和自己重复返回值-103")
             else
                 nRet = 1
             end
        end
    end
    table.insert(clockQueue, os.clock()*1000);

    if (szPlayingRoomName == nil) then
        szPlayingRoomName = "其他区"
    end
    local ret, errmsg, reasonmsg = xpcall(function() return gamepkg.CanEnterGameGroup(szPlayingRoomName,
              tonumber(szPlayingRoomId), tonumber(szScore)) end, throw) --登录帐号是否在打牌
    if(errmsg == -102) then
    	if (tonumber(last_sid) ~= tonumber(nSid)) then --上次和这次不是同一个房间，通知gc修改房间的sid
            local szSendBuf = szUserId..","..last_sid --发送给gc服务中心消息            
            tools.SendBufToUserSvr(gamepkg.name, "NTGSID", "", "", szSendBuf) --发送数据到服务端，通知他更新有人送钱了
        end
        nRet = -102
    end
    table.insert(clockQueue, os.clock()*1000);
    if (tonumber(nRegSiteNo) == 106 and math.random(0, 100) <= gm_lib.login_failed_rate) then
        nRet = -102
    end

    local userinfo = nil
    if nRet == 1 then
        usermgr.AddUser(szIpInfo[1], szIpInfo[2],szUserKey, szUserId, szUserName, szNick,
                        szSex, szIconIdx, szScore, szCity, szChannelNickName, nSid, nRegSiteNo, szUserSession, nChannelRole)

    elseif nRet == 2 then
        userinfo = usermgr.GetUserById(tonumber(szUserId))
        userinfo.szChannelNickName = szChannelNickName --用户频道号
        userinfo.nSid = tonumber(nSid)
    else
        local retFun = function(buf)
            buf:writeString("RELG")
            buf:writeShort(nRet) --注册结果代码，1=成功，0失败
            buf:writeString(tostring(os.time()))
        end
        tools.FireEvent2(retFun, szIpInfo[1], tonumber(szIpInfo[2]))
        return
    end
    table.insert(clockQueue, os.clock()*1000);

    userinfo = usermgr.GetUserById(tonumber(szUserId))

    if(userinfo == nil) then
        return
    end

    userinfo.nRet = nRet
    if(nRet == 1 or nRet == 2) then
        --得到用户游戏详细信息

        --取到正在进行的竞技场ID和默认点数
        local tour_id = 0
        local default_point = 0

        local is_sub_user = 0;
        if (duokai_lib ~= nil and duokai_lib.is_sub_user(userinfo.userId) == 1) then
            is_sub_user = 1;
        end

        if(is_sub_user == 1) then
            local gameeventdata = {userinfo = userinfo, user_info = userinfo, data = {}, alldata = {}}
            eventmgr:dispatchEvent(Event("h2_on_sub_user_login", gameeventdata));
            return;
        end

        dblib.cache_exec("getgameinfo", {gamepkg.table, szUserId, tour_id, default_point, groupinfo.is_tournament}, function(dt)
			local userinfo = usermgr.GetUserById(userinfo.userId)	--数据库查询过程中玩家退出则不处理
			if userinfo then
                --游戏信息副本，用来存所有游戏的声望和任务进度
                dblib.cache_exec("get_game_info_copy", {userinfo.userId}, function(dtgameinfo)
                    --如果查询you结果
                    local userinfo = usermgr.GetUserById(userinfo.userId)	--数据库查询过程中玩家退出则不处理
                    if userinfo == nil then
                        return
                    end
                    if(dtgameinfo~=nil and #dtgameinfo ~= 0 and dtgameinfo[1]["game_info"] ~= nil and dtgameinfo[1]["game_info"] ~= "") then
                        userinfo.gameinfo_copy = table.loadstring(dtgameinfo[1]["game_info"])
                    else
                        userinfo.gameinfo_copy = {e={},p={},i={},q={}}
                    end
                    --成就系统登录读缓存
                    local gameeventdata1 = {userinfo = userinfo, data = dt[1] or {}, alldata = dt}
    				eventmgr:dispatchEvent(Event("h2_on_user_login_forachieve", gameeventdata1));
                    --添加用户公共信息,如声望，等级，经验
                    --add_user_common_info(userinfo, dt[1], dt)

                    --写入游戏信息副本到db
                    update_gameinfo_copy(userinfo)

                    --得到用户的BUFF
                    bufflib.get_user_buff(userinfo.userId)                   
                
                    --更新游戏的个数信息
    				if(gamepkg and gamepkg.OnBeforeUserLogin) then
    					gamepkg.OnBeforeUserLogin(userinfo, dt[1], dt)
                    end
                    

                    local func = function()
        				NotifyGameLoginOk(userinfo)
                        --限制相同IP登录账户数量
                        if(is_sub_user == 0 and LoginIP_Restrict(userinfo, userinfo.ip) < 0) then
                            --usermgr.DelUser(userinfo.key)
                            --tools.CloseConn(userinfo.ip, userinfo.port)
                            return
                        end
                        --通知客户端大厅，维护玩家在线列表(只有在100张桌以下的房间实行)
                        if(#desklist <= 100) then
                            notify_sort_list_add(userinfo)
                        end
                        --用户登录完成后                    
                        if(gamepkg and gamepkg.after_user_login) then
                            gamepkg.after_user_login(userinfo)
                        end
                        local gameeventdata = {userinfo = userinfo, user_info = userinfo, data = dt[1] or {}, alldata = dt}
                        eventmgr:dispatchEvent(Event("h2_on_user_login", gameeventdata));
                    end
                    --刷新vip信息
                    if (viplib ~= nil) then
                        viplib.load_user_vip_info_from_db(userinfo.userId, function() 
                            require_refresh_gold(userinfo.userId, func)
                        end)
                    else
                        require_refresh_gold(userinfo.userId, func)
                    end
                end, userinfo.userId);
			end
		end, userinfo.userId)
    end
    table.insert(clockQueue, os.clock()*1000);

    if (clockQueue[#clockQueue] - clockQueue[1]) > 1000 then
        TraceError(" clock check OnNotifyLogin--->>>>")
        check_perf2(clockQueue);
    end
end

--添加用户公共信息
function add_user_common_info(userinfo, data, alldata)
    --添加竞技场积分
    userinfo.tour_point         = data["point"] or 0
    userinfo.gameInfo.exp 		= data["experience"]
    userinfo.gameInfo.level 	= data["level"]
    userinfo.gameInfo.prestige 	= data["prestige"]
    userinfo.gameInfo.integral  = data["integral"]
    userinfo.gotwelcome = data["integral"]  --是否领取过首次教程奖励(德州没有积分)
    if userinfo.gotwelcome == nil then userinfo.gotwelcome = 3 end  --0没看过，1看过但没领过奖，3看过也领过激昂

    --校验等级和经验的合法性
    if usermgr.getlevel(userinfo) > room.cfg.MaxLevel then
        userinfo.gameInfo.level = room.cfg.MaxLevel
        userinfo.gameInfo.exp = g_ExpLevelMap[room.cfg.MaxLevel]
        --写数据库
        dblib.cache_set(gamepkg.table, {level = room.cfg.MaxLevel}, "userid", userinfo.userId)
        --等级与经验对应
        dblib.cache_inc(gamepkg.table, {experience = g_ExpLevelMap[room.cfg.MaxLevel]}, "userid", userinfo.userId)
    end
    ---最近两个游戏日的输赢数
    local recent_win            = data["recent_win"]
    local recent_lose           = data["recent_lose"]
    local recent_date           = data["recent_date"]
    local last_win              = data["last_win"]
    local last_lose             = data["last_lose"]
    local last_date             = data["last_date"]

    userinfo.gameInfo.history = {}
    local str_year, str_month, str_day
    str_year, str_month, str_day = string.match(last_date,"(%d+)-(%d+)-(%d+)")
    if(str_year and str_month and str_day)then
        userinfo.gameInfo.history[last_date] = {}
        userinfo.gameInfo.history[last_date].win = last_win
        userinfo.gameInfo.history[last_date].lose = last_lose
    end
    str_year, str_month, str_day = string.match(recent_date,"(%d+)-(%d+)-(%d+)")
    if(str_year and str_month and str_day)then
        userinfo.gameInfo.history[recent_date] = {}
        userinfo.gameInfo.history[recent_date].win = recent_win
        userinfo.gameInfo.history[recent_date].lose = recent_lose
    end

    --todo:经验信息还没做刷新，只在登陆时候刷. 积分也如要要分游戏在这里
    --所有游戏副本信息
    --经验信息
    if(userinfo.gameinfo_copy.e == nil) then
        userinfo.gameinfo_copy.e = {}
    end
    userinfo.gameinfo_copy.e[gamepkg.name] = userinfo.gameInfo.exp

    --声望信息
    if(userinfo.gameinfo_copy.p == nil) then
        userinfo.gameinfo_copy.p = {}
    end
    userinfo.gameinfo_copy.p[gamepkg.name] = usermgr.getprestige(userinfo)
    --任务信息
    if(userinfo.gameinfo_copy.q == nil) then
        userinfo.gameinfo_copy.q = {}
        userinfo.gameinfo_copy.q[gamepkg.name] = {}
    end
    --积分信息
    if(userinfo.gameinfo_copy.i == nil) then
        userinfo.gameinfo_copy.i = {}
    end
    userinfo.gameinfo_copy.i[gamepkg.name] = usermgr.getintegral(userinfo)
end

--TODO:这个极限会超过2K，一定要处理
--写入游戏信息副本到数据库
function update_gameinfo_copy(userinfo)
    local sz = table.tostring(userinfo.gameinfo_copy)
    --todo为何是inc类型
    dblib.cache_set("user_game_info_copy", {game_info = sz}, "user_id", userinfo.userId)
end

--usermgr.....
--收到完成的任务列表
usermgr.add_user_completed_quest = function(userinfo, questlist)
    if(userinfo.gameinfo_copy.q == nil) then
        userinfo.gameinfo_copy.q = {}
    end
    if(userinfo.gameinfo_copy.q[gamepkg.name] == nil) then
        userinfo.gameinfo_copy.q[gamepkg.name] = {}
    end

    for k, v in pairs(questlist) do
        table.insert(userinfo.gameinfo_copy.q[gamepkg.name], v)
    end
end

--更新完成的任务列表
usermgr.update_user_completed_quest = function(userinfo, questlist)
    if(userinfo.gameinfo_copy.q == nil) then
        userinfo.gameinfo_copy.q = {}
    end
    userinfo.gameinfo_copy.q[gamepkg.name] = {}

    for k, v in pairs(questlist) do
        table.insert(userinfo.gameinfo_copy.q[gamepkg.name], v)
    end
end


--通知游戏登陆成功
function NotifyGameLoginOk(userinfo)
    --TraceError("NotifyGameLoginOk");
    if(userinfo == nil) then
        return
    end
    --如果用户已经登陆ok，则不用登陆了
    if (usermgr.IsLogin(userinfo) == true) then
        return
    end    
    local nRet = userinfo.nRet
    userinfo.nRet = nil
    
    local retFun = function(buf)
        buf:writeString("RELG")
        buf:writeShort(nRet) --注册结果代码，1=成功，0失败
        buf:writeString(tostring(os.time()))
    end    
    tools.FireEvent2(retFun, userinfo.ip, userinfo.port)

    --告诉客户端角色面板是否能用
    on_recve_show_authorbar(userinfo)

	--登陆时告诉客户端是不是要做异地上线保护的弹窗
	if(tex_ip_protect_lib)then
        --多开的子用户不做ip保护判断
        if (duokai_lib == nil or (duokai_lib ~= nil and duokai_lib.is_sub_user(userinfo.userId) == 0)) then
		    tex_ip_protect_lib.check_ip_address_protect(userinfo)
        end
	end
		    
    --发邀请赛的奖
    --if(tex_match)then
    --	xpcall(function() tex_match.on_after_user_login(userinfo) end, throw)
    --end    
	
	--初始化玩家的简繁体信息
    if(tex_lan)then
    	xpcall(function() tex_lan.on_after_user_login(userinfo) end, throw)
    end   
    
    
    --初始化圣诞活动，活动结束后要拿掉
    --if(christmasLib)then
    --	xpcall(function() christmasLib.on_after_user_login(userinfo) end, throw)
    --end   
   	
   	
   	--初始化玩家分享信息
    if(dhomelib)then
    	xpcall(function() dhomelib.on_after_user_login(userinfo) end, throw)
    end

    if(parkinglib) then
    	xpcall(function() parkinglib.on_after_user_login(userinfo) end, throw)
    end

    if(tasklib)then
    	xpcall(function() tasklib.on_after_user_login(userinfo) end, throw)
    end
	
    if(nRet == 1 or nRet == 2) then
        retFun = function(buf)
            buf:writeString("NTMI")
            buf:writeString(userinfo.key)
            buf:writeByte(userinfo.sex)
            buf:writeString(userinfo.nick)
            buf:writeString(userinfo.imgUrl)
            buf:writeInt(userinfo.gamescore)
            buf:writeString(userinfo.city)
            if (userinfo.nSid == nil) then --频道号
                buf:writeInt(0)
            else
                buf:writeInt(userinfo.nSid)
            end
            buf:writeInt(userinfo.userId)
            buf:writeString(string.md5(userinfo.userId.. "97C47DV3-54F2-35Dd-FE8X-58X4DVA33FB"))
            buf:writeInt(usermgr.getexp(userinfo))
            buf:writeInt(groupinfo.can_sit)
            buf:writeInt(userinfo.tour_point or 0)--竞技场积分
            buf:writeInt(userinfo.gotwelcome or 3)
            buf:writeByte(usermgr.check_user_get_bankruptcy_give(userinfo) or 0)  --是否可以领取破产救济
            buf:writeInt(userinfo.channel_id or -1)
            buf:writeInt(tonumber(userinfo.short_channel_id) or -1)
            buf:writeString(userinfo.home_face or "")
            buf:writeInt(userinfo.home_status or 0)
            buf:writeByte(tasklib.is_new_user(userinfo));
        end
        tools.FireEvent2(retFun, userinfo.ip, userinfo.port)

		--补发groupinfo
		notify_group_info(userinfo)

        --通知大厅声望信息
		notify_hall_prestige(userinfo)

        --通知大厅各游戏信息副本
        net_send_gameinfo_copy(userinfo,userinfo)
        
        --通知大厅是否显示每日登陆送钱
        xpcall(
            function()
                give_daygold_check(userinfo)
            end,throw)
        if (gamepkg ~= nil and gamepkg.AfterUserLogin ~= nil) then
            gamepkg.AfterUserLogin(userinfo) --用户登录后
        end


         if (nRet == 2) then
            local bSendDeskInfo = 1;
            if (gamepkg.OnBeforeUserReLogin) then --询问游戏是否允许玩家是否回到游戏中 1 允许，0 不允许
                bSendDeskInfo = gamepkg.OnBeforeUserReLogin(userinfo);
            end
            if (bSendDeskInfo == 1) then
                DoSendDeskInfo(userinfo) --向客户端发送当前牌的信息
            else
                usermgr.ResetReloginState(userinfo.key);
                doUserStandup(userInfo.key, false);
            end
        end
    end
end

--发送当前牌桌的信息
function DoSendDeskInfo(userInfo)
    --ASSERT(userInfo.desk ~= nil and userInfo.site ~= nil)
	if(userInfo == nil or userInfo.desk == nil or userInfo.site == nil) then
		TraceError("重新登录，自动坐回原来的位置时失败，座位不存在!")
		return
	end
    trace(format('重新登录后，自动坐回原来的位置(ip=%s, port=%d, desk=%d, site=%d',userInfo.ip, userInfo.port, userInfo.desk, userInfo.site))
    room.arg.deskno = userInfo.desk
    room.arg.siteno = userInfo.site
    room.arg.curusernick = userInfo.nick
    doSitdown(userInfo.key, userInfo.ip, userInfo.port, userInfo.desk, userInfo.site, g_sittype.relogin);
    gamepkg.OnUserReLogin(userInfo)
end

--补发groupinfo
function notify_group_info(userinfo)
    netlib.send(
        function(buf)
            buf:writeString("NTGP")
            buf:writeInt(groupinfo.groupid)
			buf:writeInt(groupinfo.isguildroom)
			--公会专用房间的话，传可选赔率表
			local guild_pelv_arr = {}
			for k, v in pairs (groupinfo.guild_peilv_map) do
				table.insert(guild_pelv_arr, k)
			end
			buf:writeInt(#guild_pelv_arr)
			for i = 1, #guild_pelv_arr do
				buf:writeInt(guild_pelv_arr[i])
			end

			buf:writeInt(groupinfo.at_least_gold)
			buf:writeInt(groupinfo.at_most_gold)
            buf:writeInt(groupinfo.pay_limit)
            buf:writeInt(groupinfo.is_nocheat)
        end
    , userinfo.ip, userinfo.port)
end


--通知刷新大厅新声望信息
function notify_hall_prestige(userinfo)
    netlib.send(
        function(buf)
            buf:writeString("REDU")
            buf:writeInt(usermgr.getprestige(userinfo))
            buf:writeInt(usermgr.getintegral(userinfo))
            buf:writeInt(usermgr.getexp(userinfo))
            buf:writeInt(usermgr.getlevel(userinfo))
        end
    , userinfo.ip, userinfo.port)
end

--发送游戏信息副本给客户端
function net_send_gameinfo_copy(userinfo,request_userinfo)
    local gameinfocp = request_userinfo.gameinfo_copy
    local userid     = request_userinfo.userId              --用户ID
    local nick       = request_userinfo.nick                --昵称
    local sex        = request_userinfo.sex                 --性别
    local from       = request_userinfo.szChannelNickName   --来自
    local gold       = request_userinfo.gamescore           --金币
    local face       = request_userinfo.imgUrl              --头像
    local exp        = usermgr.getexp(request_userinfo)--经验

    netlib.send(
        function(buf)
            buf:writeString("REGICP")
            --基本信息
            buf:writeInt(userid)    --用户ID
            buf:writeString(nick)   --昵称
            buf:writeByte(sex)      --性别
            
            if(request_userinfo.mobile_mode~=nil and request_userinfo.mobile_mode==2)then

    	    	--buf:writeString(string.HextoString(from).._U("（手机客户端）"))
    	    	buf:writeString(string.HextoString(from).._U(tex_lan.get_msg(userinfo, "h2_msg_2")))
    	    else
    	    	buf:writeString(string.HextoString(from))   --来自
    	    end
            
            buf:writeInt(gold)      --金币
            buf:writeString(face)      --头像
            buf:writeInt(exp)       --经验


            --所有游戏信息
            local action_game_name = {}
            for k, v in pairs(gameinfocp.p) do
                table.insert(action_game_name,k)
            end

            buf:writeByte(#action_game_name)    --激活游戏个数

            for i = 1, #action_game_name do
                local game_name =   action_game_name[i]
                buf:writeString(game_name)             --游戏名称
                buf:writeInt(gameinfocp.p[game_name] or 0)  --声望值
                buf:writeInt(gameinfocp.i[game_name] or 0)  --积分值

                local finished_count = 0    --完成任务的数量
                if (gameinfocp.q[game_name] ~= nil) then
                    for k1, v1 in pairs(gameinfocp.q[game_name]) do
                        finished_count = finished_count + 1
                    end
                end
                buf:writeInt(finished_count)            --完成数量
                buf:writeInt(room.cfg.totalquestcount)  --总数量
            end

            --todo:暂时从这里跨权限拿金牌数量，以后要改的
            local goldPaiNum = 0
            buf:writeInt(goldPaiNum)            --金牌数量

            --今日输赢数组
            local history = usermgr.get_user_history_array(request_userinfo)
            local history_count = #history
            buf:writeByte(history_count);                       --数组长度
            for i=1,#history do
                buf:writeString(history[i].date);	            --日期
                buf:writeInt(history[i].win);	                --赢的次数
                buf:writeInt(history[i].lose);                  --输的次数
            end
            local server_time = os.date("%Y-%m-%d %H:%M:%S")
            buf:writeString(server_time)                        --服务器时间
        end
    , userinfo.ip, userinfo.port)
end

--收到请求刷新游戏副本信息
function onrecv_gameinfo_copy(buf)
    local userkey = getuserid(buf)
    local userinfo = userlist[userkey]
    local request_userid = buf:readInt()    --要请求的userid
    local request_userinfo = usermgr.GetUserById(request_userid)

	if not request_userinfo then
		--发gc包
		cmdHandler["GCINFO"] = function(buf)
			buf:writeString("GCINFO")
			buf:writeInt(userinfo.userId)				--fromuserid
			buf:writeInt(request_userid)				--touserid
        end
		tools.SendBufToGameCenter(gamepkg.name, "GCINFO")
		return
	end
    net_send_gameinfo_copy(userinfo, request_userinfo)
end

function onrecv_gc_get_info(buf)
	local fromuserid = buf:readInt()
	local touserid = buf:readInt()
	local touserinfo = usermgr.GetUserById(touserid)
	if not touserinfo then return end
	--发gc包
	cmdHandler["_SNDINFO"] = function(buf)
		buf:writeString("SNDINFO")
		buf:writeInt(fromuserid)

        local new_userinfo = {}
        new_userinfo.gameinfo_copy = touserinfo.gameinfo_copy
        new_userinfo.userId = touserinfo.userId              --用户ID
        new_userinfo.nick = touserinfo.nick               --昵称
        new_userinfo.sex = touserinfo.sex                 --性别
        new_userinfo.szChannelNickName = touserinfo.szChannelNickName   --来自
        new_userinfo.gamescore = touserinfo.gamescore           --金币
        new_userinfo.imgUrl = touserinfo.imgUrl              --头像
        new_userinfo.gameInfo = {}
        new_userinfo.gameInfo.exp = usermgr.getexp(touserinfo)
        new_userinfo.gameInfo.history =  touserinfo.gameInfo.history

		buf:writeString(table.tostring(new_userinfo))				--touserinfo
	end
	tools.SendBufToGameCenter(gamepkg.name, "_SNDINFO")
end

function onrecv_gc_reply_info(buf)
	local fromuserid 	= buf:readInt()
	local sztouserinfo 	= buf:readString()
	local userinfo = usermgr.GetUserById(fromuserid)
	if not userinfo then return end
	local touserinfo = table.loadstring(sztouserinfo)
	net_send_gameinfo_copy(userinfo, touserinfo)
end

function onrecvlogin(buf)
	--TraceError("onrecvlogin!!")
    local user_id = buf:readInt()
    local password = buf:readString()
    local reg_site_no = buf:readByte()
    local login_type = buf:readString()
    login_type = tonumber(login_type) or 0;
    local token = buf:ip()..","..buf:port()
    --token = token..","..buf:port()..","..getuserid(buf)
    tools.SendBufToUserSvr(getRoomType(), "RQUI", "NTLG", token,
        user_id .. "," ..
        reg_site_no .. "," ..
        groupinfo.groupid .. "," ..
        password.."," ..login_type
    )
end

--补充手机登陆时要用的一些变量到内存中
function on_mobile_login(buf)
	--TraceError("mobile login")
	local user_info = userlist[getuserid(buf)]; 
    --说明 0:PC, 1:MAC ios/Iphone, 2:Android, 3:Windows Phone 7
    local mobile_mode = buf:readInt()
    --[[说明 MAC ios/Iphone：
							0:Iphone
							1:Ipad
							2:Itouch
							4:MAC

							Android:
							 0:HTC
							 1:三星
	--]]
    local mobile_type = buf:readString()
    local mobile_screen = buf:readString()
    
    --将信息保存在内存中供后继调用
    user_info.mobile_mode=mobile_mode or 0
    user_info.mobile_type=mobile_type or ""
    user_info.mobile_screen=mobile_screen or ""
    
    netlib.send(function(buf) 
                    buf:writeString("MO_PAYOFF")
                    buf:writeByte(0)              
                    end, user_info.ip, user_info.port);
    local sql="insert into log_mobile_user_login(user_id,mobile_mode,mobile_type,mobile_screen,sys_time) value(%d,%d,'%s','%s',now());commit;";
    --TraceError("mobile login sql "..sql)
    sql=string.format(sql,user_info.userId,user_info.mobile_mode,user_info.mobile_type,user_info.mobile_screen);
    dblib.execute(sql);
 end

function doSetTempOfflineState(userinfo)
    if (userinfo.offline == nil) then
        userinfo.offline = offlinetype.tempoffline  --临时离线
        userinfo.offlinetime = os.time()            --记录临时离线的时间
        --如果三家都托管，则直接结束牌局
        local bRet = OverGameOnAllOffline(userinfo)
        if (bRet == false and gamepkg ~= nil and gamepkg.OnTempOffline ~= nil) then
            gamepkg.OnTempOffline(userinfo)
        end
        if bRet == false then
            raiseSiteStateEvent(userinfo)
        end
    end
end


--响应座位状态事件(离线事件)
function raiseSiteStateEvent(userinfo)
    --TraceError("raiseSiteStateEvent")
    if userinfo.site and userinfo.desk then
        local siteinfo = desklist[userinfo.desk].site[userinfo.site]
        if siteinfo and siteinfo.state and siteinfo.state ~= NULL_STATE then
            local stateinfo = siteinfo.state
            if stateinfo and stateinfo[1] then
                --xpcall(function() stateinfo[1](userinfo) end, throw)
                stateinfo[1](userinfo)
            end
        end
    end
end

--广播系统提示
function gm_broadcastmsg(msg,styleId)
   if(msg ~= nil) then
        broadcastmsg(msg,styleId)
   end
end

--按一桌要达到游戏开始条件，需要的人数，从少到多排列
DeskQueueMgr.SortDeskPlayerCount = function(a, b)
    --如果游戏已经开始，则桌子排在队列后面
    local bGameAlreadyStart1, bGameAlreadyStart2= gamepkg.getGameStart(a), gamepkg.getGameStart(b)
    if (bGameAlreadyStart1 == true and bGameAlreadyStart2 == false) then
        return false
    elseif (bGameAlreadyStart2 == true and bGameAlreadyStart1 == false) then
        return true
    elseif (bGameAlreadyStart1 == true and bGameAlreadyStart2 == true) then
        return a < b
    end

    --如果一桌已经满了，则排在最后面
    if (room.cfg.DeskSiteCount <= desklist[a].playercount and room.cfg.DeskSiteCount > desklist[b].playercount ) then
        return false
    elseif (room.cfg.DeskSiteCount <= desklist[b].playercount and room.cfg.DeskSiteCount > desklist[a].playercount) then
        return true
    elseif (room.cfg.DeskSiteCount <= desklist[b].playercount and room.cfg.DeskSiteCount < desklist[a].playercount) then
        return a < b
    end

    --按小盲排队，小盲低的在前面
    local smallbet1 = desklist[a].smallbet or 0
    local smallbet2 = desklist[b].smallbet or 0
    if(smallbet1 ~= smallbet2) then
        return smallbet1 < smallbet2
    end

    --两桌分别需要多少人才可以开始游戏
    local nMiniNeedCount1 = room.cfg.MinDeskSiteCount - desklist[a].playercount
    local nMiniNeedCount2 = room.cfg.MinDeskSiteCount - desklist[b].playercount
    if (nMiniNeedCount1 == nMiniNeedCount2) then --如果两桌人数相同，则真人多的  排在最前面
        return a < b
    elseif (nMiniNeedCount1 <= 0 and nMiniNeedCount2 <= 0) then --如果两桌都可以开始，则人少的，排在前面
        return  desklist[a].playercount > desklist[b].playercount
    elseif (nMiniNeedCount1 <= 0 and nMiniNeedCount2 > 0) then --如果一桌可以开始，另一桌不能开始，可以开始的排在前面
        return  true
    elseif (nMiniNeedCount1 > 0 and nMiniNeedCount2 <= 0) then --如果一桌可以开始，另一桌不能开始，可以开始的排在前面
        return false
    elseif (nMiniNeedCount1 > 0 and nMiniNeedCount2 > 0) then --如果两桌都不能开始, 需要人少的排在前面
        return nMiniNeedCount1 < nMiniNeedCount2
    end
end


function OnRecvNetworkCheck(buf)
    usermgr.ResetNetworkDelay(getuserid(buf))
end

--定时检测断线用户
function doCheckOfflineUser()
    local time1 = os.clock() * 1000

    --删除超时用户
    usermgr.DelOffLineUser()  --注意，不要和下面函数颠倒使用，可能会定时踢掉所有的人
    --看看还有那些用户快超时了，如果快超时则发送nttt

    local time2 = os.clock() * 1000

    usermgr.CheckNetWorkDelay()

    local time3 = os.clock() * 1000
    if (time2 - time1 > 1000) then
        TraceError("usermgr.DelOffLineUser 超过1s时间"..(time2 - time1))
    end
    if (time3 - time2 > 1000) then
        TraceError("usermgr.CheckNetWorkDelay 超过1s时间"..(time3 - time2))
    end
end

--注册gameserver
function OnRegisterGameSvr(buf)
    buf:writeString("GCRG")
end

function InitUserOnline()
	local OnNotifyRegSite = function(dt)
		if (#dt == 0) then
			TraceError("！！！获取注册站点信息出错")
			return
		end
		for k, v in pairs(dt) do
			userOnline[tonumber(v["site_no"])] = { --机器人
							totalCount = 0, --用户的在线人数
							playingCount = 0,--用户的在玩人数
							robotCount = 0, --机器人的个数
							}
		end
		TraceError("获取注册站点信息成功")
	end

	dblib.execute(tSqlTemplete.GetRegSite, OnNotifyRegSite)
end

hall.on_start_server = function()
    disable_global();
	hall.desk.init_all();
    hall.displaycfg.init();
	on_init_room_settings();
	InitUserOnline();
	tools.SendBufToGameCenter(getRoomType(), "GCRG");
	checkGamePkg()	-- 检查游戏实现的接口是否完善
	-- 最后游戏初始化启动自己
	--gamepkg.on_start_server();	
	eventmgr:dispatchEvent(Event("on_server_start", null));
end

function check_perf2(clockQueue)
    local lenCheck = {};
    local prevCheck = nil;
    for i, value in pairs(clockQueue) do
        if prevCheck == nil then
            prevCheck = value;
        else
            table.insert(lenCheck, value - prevCheck);
            prevCheck = value;
        end
    end
    TraceError(tostringex(lenCheck))        
end

function check_perf(clockQueue)
	local timeinterval = os.clock()*1000 - room.perf.time_check_prev

	local lenCheck = {};
	local prevCheck = nil;
	for i, value in pairs(clockQueue) do
		if prevCheck == nil then
			prevCheck = value;
		else
			table.insert(lenCheck, value - prevCheck);
			prevCheck = value;
		end
	end

	if(room.time > 60 and timeinterval > room.perf.check_interval_max) then
		TraceError("\n\t大厅ontimecheck执行时长："..tostring(timeinterval)
		.."毫秒\n\t每个检查段执行时长："..tostringex(lenCheck)
		.."毫秒\n\t发送数据请求："..tostring(room.perf.send_packcount)
		.."个\t执行时长："..tostring(room.perf.send_slicelen)
		.."毫秒\n\t收到数据请求："..tostring(room.perf.recv_packcount)
		.."个\t执行时长："..tostring(room.perf.recv_slicelen)
		.."毫秒")
		TraceError(room.perf.cmdlist)
	end

	room.perf.time_check_prev = os.clock()*1000
	room.perf.recv_packcount = 0
	room.perf.send_packcount = 0
	room.perf.recv_slicelen = 0
	room.perf.send_slicelen = 0
	room.perf.cmdlist = {}
end
function ontimecheck()
	local clockQueue = {};
	table.insert(clockQueue, os.clock()*1000);

	room.time = room.time + 1;
    if (room.time == 1) then
		hall.on_start_server();
    end
    --如果设置和以前不一样，则需要重置是否显示日志状态
    if (room.cfg.org_outputlog ~= room.cfg.outputlog and room.cfg.outputlog ~= nil and room.time > 60) then
		--todo cw
		--[[
        if (room.cfg.outputlog == 1) then
            tools.setcheckLog(0);
        else
            tools.setcheckLog(1);
        end
		--]]
        room.cfg.org_outputlog = room.cfg.outputlog
    end

	table.insert(clockQueue, os.clock()*1000);
    if (room.cfg.istimecheck == true) then
        --每秒检查一次是否要打乱重排
		table.insert(clockQueue, os.clock()*1000);
        if (math.mod(room.time, room.cfg.timerandomwait) == 0) then --每3秒查一次
            doProcessQueue()
        end
    end
    table.insert(clockQueue, os.clock()*1000);
    if (math.mod(room.time, room.cfg.timeOfflineInterval) == 0) then --定时检测掉线用户
        doCheckOfflineUser()
    end
    --trace(format("心跳检查:%d", room.time))
    table.insert(clockQueue, os.clock()*1000);
    gamepkg.ontimecheck(); --如果这句出错，表示在游戏脚本中没有初始化 gamepkg 这个变量
	table.insert(clockQueue, os.clock()*1000);
    ----------------------------------------------------
    --派发时间时间，每分钟一次
    dispatchTimerEvent()
	table.insert(clockQueue, os.clock()*1000);

    --派发牌桌大厅变动数据
	xpcall(function()
		dispatchDeskChangeEvent()
	end, throw)
	table.insert(clockQueue, os.clock()*1000);

	--定时排序牌桌大厅的Top排行
	xpcall(function()
		do_users_prop_sort()
	end, throw)
	table.insert(clockQueue, os.clock()*1000);

    --用于执行plan
	timelib.ontimecheck()
	table.insert(clockQueue, os.clock()*1000);

    --元宵节猜灯谜插件
    --[[
    if(gsriddlelib and gsriddlelib.ontimecheck ~= nil) then
        gsriddlelib.ontimecheck()
        table.insert(clockQueue, os.clock()*1000);
    end
	--]]
	
    if(channellib and channellib.ontimecheck ~= nil) then
        channellib.ontimecheck();
    end
	
	--if(tex_match)then
	--	xpcall(function() tex_match.ontimecheck() end, throw);
	--end
	
    if (room.time % 30 == 0) then
        collectgarbage("collect")  --很费时间，不知为啥
	end
	table.insert(clockQueue, os.clock()*1000);

	check_perf(clockQueue);
end
--精确ontimecheck实现 游戏须实现 gamepkg.ontimecheck_second()接口
if ontimer_second then
	eventmgr:removeEventListener("timer_second", ontimer_second);
end
ontimer_second = function(e)
	if gamepkg.ontimecheck_second then
        gamepkg.ontimecheck_second()
	end
end
eventmgr:addEventListener("timer_second", ontimer_second);
--派发时间时间，每分钟一次
function dispatchTimerEvent()
	--eventmgr:dispatchEvent(Event("timer_second"));
    local tableTime = os.date("*t",os.time())
    local nowMin  = tonumber(tableTime.min)
    if(nowMin ~= room.timeflagMin) then
        local gameeventdata = {min = nowMin}
        eventmgr:dispatchEvent(Event("timer_minute", gameeventdata));
    end
    room.timeflagMin = nowMin
end

--定时排序N名的排行榜
function do_users_prop_sort()
    if(room.time - room.timeLastTime > room.timeSortDelay) then
		usermgr.sort_top_users(room.sortTopMax)
		room.timeLastTime = room.time
    end
end

-- 返回座位状态有变化的牌桌新状态组合，形式如desklist(key:deskno, "start":1 or 0,value:states(key:siteno, value:SITE_UI_VALUE))
function get_changed_desk(user_info)
	local changed_desks = {}
	--TraceError("user:"..user_info.userId.."\r\n visible:"..tostringex(user_info.visible_desk_list));
	for _, idesk in pairs(user_info.visible_desk_list) do
		local has_changed = false
		for isite = 1, room.cfg.DeskSiteCount do
			local state_value = gamepkg.TransSiteStateValue(desklist[idesk].site[isite].state)
			if (state_value ~= desklist[idesk].site[isite].state_value_send) then
				-- 记录当前牌桌有一个座位状态与记录不同
				has_changed = true
			end
		end
		if has_changed then
			-- 只记录状态有变化的牌桌
			changed_desks[idesk] = 1
		end
    end
	return changed_desks
end

--获取座位userinfo
function get_site_user(deskno, siteno)
	return userlist[hall.desk.get_user(deskno, siteno) or ""]
end

function notify_changed_desk(user_info, changed_desk)
	local count_desk = 0
	for k, v in pairs(changed_desk) do
		count_desk = count_desk + 1
	end

	if count_desk == 0 then
		-- 没有可以发送的牌桌数据
		return
	end

    -- TODO:需要增加牌桌的进行状态：已开始，未开始，已开始打牌
    netlib.send(
        function(out_buf)
            out_buf:writeString("SDDSS")
    		out_buf:writeInt(count_desk)  --有变化的桌子计数
			for deskno, desk_data in pairs(changed_desk) do
                local deskinfo = desklist[deskno]
    			out_buf:writeInt(deskno)
                --名称
    			out_buf:writeString(deskinfo.name)
                --桌子类型:1普通，2比赛，3VIP
                out_buf:writeByte(deskinfo.desktype)
                --是否快速桌
                out_buf:writeByte(deskinfo.fast)
                --桌面筹码数
                out_buf:writeInt(deskinfo.betgold)
                --桌子的玩家筹码
                out_buf:writeInt(deskinfo.usergold)
                --解锁等级
    			out_buf:writeInt(deskinfo.needlevel)
                --小盲
    			out_buf:writeInt(deskinfo.smallbet)
                --大盲
    			out_buf:writeInt(deskinfo.largebet)
                --金钱下限
    			out_buf:writeInt(deskinfo.at_least_gold)
                --金钱上限
    			out_buf:writeInt(deskinfo.at_most_gold)
                --抽水
    			out_buf:writeInt(deskinfo.specal_choushui)
                --最少开局人数
    			out_buf:writeByte(deskinfo.min_playercount)
                --最大开局人数
    			out_buf:writeByte(deskinfo.max_playercount)
				--当前在玩人数
    			out_buf:writeByte(hall.desk.get_user_count(deskno))
                local watch_count = 0
                for k,v in pairs(deskinfo.watchingList) do
                    watch_count = watch_count + 1
                end
                --观战人数
    			out_buf:writeInt(watch_count)
				--是否开始
    			out_buf:writeByte(gamepkg.getGameStart(deskno) and 1 or 0)

				--- TODO:Client需要增加数据包的处理
                out_buf:writeByte(room.cfg.DeskSiteCount)
                for isite = 1, room.cfg.DeskSiteCount do
					local state_value = gamepkg.TransSiteStateValue(desklist[deskno].site[isite].state)
					out_buf:writeByte(state_value)
					local user_info = get_site_user(deskno, isite) or {}
                    --用户的数据库ID
                    out_buf:writeInt(user_info.userId or 0)
                    --昵称
                    out_buf:writeString(user_info.nick or "")
                    --头像URL
                    out_buf:writeString(user_info.imgUrl or "")
                    desklist[deskno].site[isite].state_value_send = state_value
                end
    		end
			-- 当前请求的页数
    		out_buf:writeShort(user_info.visible_page)
			-- 一共分多少页
    		out_buf:writeShort((count_desk - count_desk % user_info.desk_in_page) / user_info.desk_in_page + 1)
        end
    , user_info.ip, user_info.port)
end

function dispatchDeskChangeEvent()
	local visible_pages = {}
	local sendlist = {}
	for _, user_info in pairs(userlist) do
		-- 检查用户是否在看此页面
		if (user_info.visible_page ~= 0) then
			if(visible_pages[user_info.visible_page] == nil or isguildroom()) then --公会专用房，每个人的第一页是不同的
				-- 如果该页面第一次被检查，则筛选一次变化的牌桌
				visible_pages[user_info.visible_page] = get_changed_desk(user_info)
			end
			--使用已经筛选过的牌桌变更累计数据
			sendlist[user_info] = visible_pages[user_info.visible_page]
		end
	end
	for user_info, data in pairs(sendlist) do
		notify_changed_desk(user_info, data)
	end
end

DeskQueueMgr.Resort = function()
    table.sort(deskqueue, DeskQueueMgr.SortDeskPlayerCount)
end

--取到需要人数最少就可以开始的桌子，如果取到桌号不是-1，且返回值是1的表示有桌子可以排
DeskQueueMgr.getFirstQueueDeskInfo = function(nIndex)
    ASSERT(type(nIndex) == "number")
    if (deskqueue[nIndex] ~= nil) then
        ASSERT(desklist[(deskqueue[nIndex])] ~= nil, "排队时桌子信息是空"..tostring(nIndex))
        return 1, deskqueue[nIndex], desklist[(deskqueue[nIndex])].playercount
    else
        return 0, -1, -1
    end
end

--todo:让机器人排队时进入队列后面，自然人在最前面
UserQueueMgr.AddUser = function(userKey, ip, port, queryReason)
    --如果已经有桌号了，则不进行排队
    if (userlist[userKey].desk ~= nil) then
        return false
    end
    if (g_UserQueue[userKey]) then
        trace(format("%s已经在排队了", userKey))
        return false
    else
        --trace('suserid:'..suserid)
        g_UserQueue[userKey] = {}
        local userQueueInfo = g_UserQueue[userKey]
        userQueueInfo.key = userKey
        userQueueInfo.ip  = ip
        userQueueInfo.port = port
        userQueueInfo.queueindex = g_queueindex --全局变量，永远递增
        userQueueInfo.isRobot = 0
        local userItem = userlist[userKey]
        if (userItem) then
            if (userItem.isrobot and room.cfg.ignorerobot == 0) then
                userQueueInfo.isRobot = 1
                g_QueueRobot:Add(userKey)
            elseif (queryReason == queryReasonFlg.login) then
                if (g_LastInsertLoginIn1 == 0) then
                    g_QueueLoginPeople1:Add(userKey)
                    g_LastInsertLoginIn1 = 1
                else
                    g_QueueLoginPeople2:Add(userKey)
                    g_LastInsertLoginIn1 = 0
                end
            elseif (queryReason == queryReasonFlg.gameOverAndWin) then
                if (g_LastInsertWinIn1 == 0) then
                    g_QueueWinPeople1:Add(userKey)
                    g_LastInsertWinIn1 = 1
                else
                    g_QueueWinPeople2:Add(userKey)
                    g_LastInsertWinIn1 = 0
                end
            elseif (queryReason == queryReasonFlg.gameOverAndLost) then
                g_QueueLostPeople:Add(userKey)
            elseif (queryReason == queryReasonFlg.inValid) then
                g_QueueInvalid:Add(userKey)
            end
        end
        --放入无效队列的用户不能计算在线人数
        if (queryReason ~= queryReasonFlg.inValid) then
			usermgr.enter_playing(userlist[userKey])
        end
        trace(format("%s加入到排队队列中", userKey))
        --[[for k, v in pairs(userqueue) do
            trace("in queue userinfo.key:"..v.key)
        end--]]
        return true
    end
end

UserQueueMgr.RemoveUser = function(userKey)
    if (g_UserQueue[userKey]) then
        g_UserQueue[userKey] = nil
        local userItem = userlist[userKey]
        if (userItem) then
            if (userItem.isrobot) then
                g_QueueRobot:Remove(userKey)
            else --清除真人队伍
                if  (g_QueueLoginPeople1:Remove(userKey) == nil) then
                    if  (g_QueueLoginPeople2:Remove(userKey) == nil) then
                        if (g_QueueWinPeople1:Remove(userKey) == nil) then
                            if (g_QueueWinPeople2:Remove(userKey) == nil) then
                                if (g_QueueLostPeople:Remove(userKey) == nil) then
                                    if (g_QueueInvalid:Remove(userKey) == nil) then
                                    end
                                end
                            end
                        end
                    end
                end
            end
			usermgr.leave_playing(userItem)
        end
        trace(format("%s从排队队列中清除",userKey))
        return true
    else
        return false
    end
end

--取到队列里面的人数
UserQueueMgr.GetCount = function(IncludeRobot)
    local count = g_QueueLoginPeople1.count + g_QueueLoginPeople2.count + g_QueueWinPeople1.count
                  + g_QueueWinPeople2.count + g_QueueLostPeople.count + g_QueueInvalid.count
    if (IncludeRobot == 1) then
        return count + g_QueueRobot.count
    end
    return count
end

--发送当前排队人数
UserQueueMgr.SendQueueCountToAllQueueUser = function()
    if (UserQueueMgr.GetCount(0) == 0) then
        return
    end
    for k, v in pairs(g_UserQueue) do
        if (v.isRobot == 0) then
            tools.fireEvent("NTQC", v.ip, v.port)
        end
    end
end

UserQueueMgr.PopUser = function(pop_invaild_user)
    --先取排队的用户，再取赢的用户，再取输的用户，再去机器人
    local userKey, userinfo
    if (pop_invaild_user == true and g_QueueInvalid.count > 0) then
        userKey = g_QueueInvalid:Pop()
        trace(format("返回无效队列里面的用户:%s", userKey))
    elseif (g_QueueLoginPeople1.count > 0) then --有自然人1
        userKey = g_QueueLoginPeople1:Pop()
        trace(format("返回排队用户:%s", userKey))
    elseif (g_QueueWinPeople1.count > 0) then --有赢的人1
        userKey = g_QueueWinPeople1:Pop()
        trace('返回赢的一队列中的人:'..userKey)
    elseif (g_QueueLoginPeople2.count > 0) then --有自然人2
        userKey = g_QueueLoginPeople2:Pop()
        trace(format("返回排队用户:%s", userKey))
    elseif (g_QueueWinPeople2.count > 0) then --有赢的人2
        userKey = g_QueueWinPeople2:Pop()
        trace('返回赢的二队列中的人:'..userKey)
    elseif (g_QueueLostPeople.count > 0) then --有输的人
        userKey = g_QueueLostPeople:Pop()
        trace('返回输的队列的人:'..userKey)
    elseif (g_QueueRobot.count > 0) then --有机器人
        userKey = g_QueueRobot:Pop()
        trace('返回机器人队列的人:'..userKey)
    end
    if (userKey ~= nil) then
        local popUser = g_UserQueue[userKey]
        --trace("清除排队队列"..g_UserQueue[userKey].key)
        g_UserQueue[userKey] = nil
        return userKey, popUser
    end
end

function can_user_sitdown(deskno, userinfo)
    local deskinfo = desklist[deskno]
    if not deskinfo then return false end
    if (deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and gamepkg.getGameStart(deskno) then
		return false;
	end
	if (ischecksameip() == 0 and ischeckforcerequeue() == 0) then
		return true
	end
	for i= 1, room.cfg.DeskSiteCount do
		local userKey = hall.desk.get_user(deskno, i)
		if (userKey ~= nil and userlist[userKey] ~= nil and userinfo ~= nil) then
			if (ischecksameip() == 1) then
				if (userlist[userKey].ip == userinfo.ip) then  --相同ip的不能进入
					return false
				end
			end
			if (ischeckforcerequeue() == 1) then
				if (userlist[userinfo.key].last_desk ~= nil and userlist[userKey].last_desk == userlist[userinfo.key].last_desk) then  --相同的座位不允许坐下
					return false
				end
			end
		end
	end
    return true
end

--本函数调用一次，只处理一张桌子
function FillDesk(nDeskNo, nDeskPlayerCount)
    --如果一桌必须要有自然人，并且没有自然人排队，则要检测此桌子是否有自然人,如果没有，则要排下一桌
    if (room.cfg.DeskMustHavePerson == 1 and UserQueueMgr.GetCount(0) == 0) then
        local bHavePeople = false
        local userId = nil
        for i = 1, room.cfg.DeskSiteCount do
            userId = hall.desk.get_user(nDeskNo, i)
            if (userId ~= nil and userlist[userId] == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空3")
                hall.desk.clear_users(nDeskNo, i)
            else
                if (userId ~= nil and userlist[userId].isrobot == false) then
                    bHavePeople = true
                    break
                end
            end
        end
        if (bHavePeople == false) then  --当前桌没有自然人，并且没有自然人排队,直接退出
            --trace(nDeskNo.."号桌没有自然人，并且排队机中没有自然人")
            return false
        end
    end
    local bHavePeopleSitDown = false
    --从用户队列中找一个用户出来
    local bBlankSite = false --是否空座位
    for i = 1, room.cfg.DeskSiteCount do
        if (UserQueueMgr.GetCount(1) < 0) then  --如果队列中没有人了，就退出排队
            break
        end
        if (gamepkg ~= nil and gamepkg.IsBlankSite ~= nil) then
            bBlankSite = gamepkg.IsBlankSite(nDeskNo, i)
        else
            bBlankSite = not hall.desk.get_user(nDeskNo, i)
        end
        --找到一个空位置
        --todo bug
        --如果没有此用户，则清除此用户
        local tempUserKey = hall.desk.get_user(nDeskNo, i)
        if (tempUserKey ~= nil and userlist[tempUserKey] == nil) then
            TraceError("用户坐下时桌子上有个用户的userlist信息为空4")
            hall.desk.clear_users(nDeskNo, i)
        end
        if (bBlankSite == true) then
            local userkey = nil
            local userinfo = nil
            local loop_count = 1
            while(UserQueueMgr.GetCount(1) >= loop_count) do
                local userkey_temp = nil
                local userinfo_temp = nil
                if (loop_count == 1) then
                    userkey_temp, userinfo_temp = UserQueueMgr.PopUser(true)
                else
                    userkey_temp, userinfo_temp = UserQueueMgr.PopUser(false)
                end
                if (userkey_temp == nil) then    --如果已经没有排队用户了，就直接返回
                    break
                end
                --检测用户是否能够坐下
                if(can_user_sitdown(nDeskNo, userinfo_temp) == false) then
                    UserQueueMgr.AddUser(userkey_temp, userinfo_temp.ip, userinfo_temp.port, queryReasonFlg.inValid)
                    trace("相同ip不能同房间打牌")
                else
                    userkey = userkey_temp
                    userinfo = userinfo_temp

                    --成功排队进去，清除增强防作弊标志
                    userinfo.queue_time = 0
                    userinfo.queue_seed = 0

                    break
                end
                loop_count = loop_count + 1
            end
            if (userkey == nil) then --没有找到合适的用户，退出排队
                break
            end
            --填位置
            trace(format("排队机自动分配%s到%d号桌子, %d号位坐下", userkey, nDeskNo, i))
            DoUserWatch(nDeskNo, userlist[userkey])
            doSitdown(userkey, userinfo.ip, userinfo.port, nDeskNo, i, g_sittype.queue)
            bHavePeopleSitDown = true   --说明当前用户排队成功
            if (desklist[nDeskNo].playercount  >= room.cfg.DeskSiteCount) then   --如果一桌人数达到最大，就不排人了
                trace(format("%d号桌满足最小开始条件，可以开始game了", nDeskNo))
                break
            end
        end
    end
    if (bHavePeopleSitDown == true) then
        return true
    end

    trace("一轮下来，没法坐下了，不用再排队了")
    return false
end

--坏桌子的列表
local g_nBadDesk = {};

function processQueue()
    --根据最少空位的桌中的人数判定要循环几次可以填满一桌
    if (UserQueueMgr.GetCount(1) > 0) then
        DeskQueueMgr.Resort()
    end
    local loopcount = 0
    local peopleCount = UserQueueMgr.GetCount(0)
    local nIndex = 1
    while (nIndex < #desklist) do
        if (UserQueueMgr.GetCount(1) <= 0) then
            return
        end
        --第一个有最少空位的桌子中已经坐上的玩家数
        local nRet, nFeatDeskNo, nDeskPlayerCount = DeskQueueMgr.getFirstQueueDeskInfo(nIndex)
        --没有人可以排队了
        if (nRet == 0 or nFeatDeskNo == -1 or nDeskPlayerCount < 0 or nDeskPlayerCount > room.cfg.DeskSiteCount) then
            return
        end
        --当前桌还最少需要多少人才可以开始游戏
        local nMiniNeedCount = 0
        if (room.cfg.MinDeskSiteCount > nDeskPlayerCount) then
            nMiniNeedCount = room.cfg.MinDeskSiteCount - nDeskPlayerCount
        end
        local BlankSiteCount = room.cfg.DeskSiteCount - nDeskPlayerCount
        --当前排队人数够填一桌，且有空位
        if (UserQueueMgr.GetCount(1) >= nMiniNeedCount and BlankSiteCount > 0) then
            trace("开始填桌子，空位子数:"..BlankSiteCount)
            local ret, nRet = xpcall (function() FillDesk(nFeatDeskNo, nDeskPlayerCount) end, throw)
            if (ret == false) then
                g_nBadDesk[nFeatDeskNo] = 0
            elseif (nRet == false) then
                break
            end
            g_nBadDesk[nFeatDeskNo] = 1
        else
            break
        end
        nIndex = nIndex + 1
    end
end

function gm_list_bad_desk()
    TraceError("坏桌子列表:")
    local nDeskCount = 0
    for k ,v in pairs(g_nBadDesk) do
        if (v == 0) then
            nDeskCount = nDeskCount + 1
            TraceError(k)
        end
    end
    TraceError("坏桌子总数:"..nDeskCount)
end

function doProcessQueue()
    local ret, errmsg = xpcall(function() return processQueue() end, throw)
    UserQueueMgr.SendQueueCountToAllQueueUser()
end

function processRequireDeskQueue(suserid, ip, port)
    --先将用户压入到排队队列中
    UserQueueMgr.AddUser(suserid, ip, port, queryReasonFlg.login)
end

usermgr.ResetReloginState = function(key)
    if (userlist[key] ~= nil) then
        userlist[key].offline = nil
        userlist[key].offlinetime = nil
        userlist[key].relogin = nil
    end
end

--收到请求自动加入游戏
function onrecvrAutoJoin(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        TraceError("请求直接加入游戏, userinfo空"..tostring(userKey))
        return
    end
    
    local deskno = buf:readInt()
    local user_desk_type=buf:readInt()
    if(user_desk_type~=nil) then
    	userinfo.user_desk_type=user_desk_type
    end
    local siteno = -1
    local errcode, value = 0, 0
    local msgtype = 0 --0表示是大厅处理的协议
    local msg =""
    local needsitdown = false  --输入房间号默认是观战，只有点击开始才是坐下
    if(userinfo.desk or userinfo.site) then
        --TraceError("怪事，在桌子上也能点击排队？？？")
        return
    end

    if (deskno > #desklist) then
       -- msg = "对不起，您输入的桌子号码超出范围，请重新输入!"
        msg = tex_lan.get_msg(userinfo, "h2_msg_autojoin_1")
        OnSendServerMessage(userinfo, msgtype, _U(msg))
        return
    end


    if(deskno > 0) then
        local deskinfo = desklist[deskno]

        if(deskinfo.playercount >= room.maxWatchUserCount) then
            --msg = format("对不起，您选择的桌子人数已满，请选择其他桌子!")
            msg = tex_lan.get_msg(userinfo, "h2_msg_autojoin_2")
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end

        if(deskinfo.needlevel > usermgr.getlevel(userinfo)) then
            --msg = format("对不起，您选择的桌子需要%d级才可以进入，您等级不够!", deskinfo.needlevel)
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_3"), deskinfo.needlevel)
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end
        --[[
        local needgold  = deskinfo.at_least_gold
        if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then 
            needgold  = needgold + deskinfo.specal_choushui 
        end
        if(needgold > userinfo.gamescore) then --不够金币也可以进入观战
            --msg = format("对不起，您选择的桌子最低带入筹码%d，您身上携带的筹码不够!", needgold)
            --OnSendServerMessage(userinfo, msgtype, _U(msg))
            --return
        end
        --]]

        if(deskinfo.desktype == g_DeskType.match) then
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_5"))
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return;
        end

        if(deskinfo.desktype == g_DeskType.VIP and (not viplib or not viplib.check_user_vip(userinfo))) then
            --msg = format("对不起，您选择的桌子需要VIP权限才能进入!")
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_4"))
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end
        
        if((deskinfo.desktype == g_DeskType.channel and userinfo.channel_id<=0) or 
        	(deskinfo.desktype == g_DeskType.channel and userinfo.channel_id~=deskinfo.channel_id)) then
            --msg = format("对不起，请输入正确的房间ID!")
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_5"))
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end

        --指定桌子号加入
        errcode, value = can_user_enter_desk(userKey, deskno)

    else

        --未指定桌子号，自动加入
        needsitdown = true  --自动坐下
        local finddesk = 0
        local FunQuerryDesk = function()
            finddesk = hall.desk.give_user_deskno(userinfo)
        end

        getprocesstime(FunQuerryDesk, "give_user_deskno", 500)

        if finddesk > 0 then
            deskno = finddesk
            errcode, value = can_user_enter_desk(userKey, deskno)
        end
        
    end
    
    if errcode ~= 1 then
        --发送无法进入房间消息        
        OnSendUserAutoJoinError(userinfo, errcode, value)
        return
    end
            
   --加入桌子之前，看看能不能观战
    errcode = CanUserWatch(userinfo, deskno)
    if errcode < 0 then
        OnSendUserWarchError(userinfo, errcode)
        return
    end
        
    if (tex_buf_lib) then
        local succcess, ret = xpcall( function() return tex_buf_lib.on_before_user_enter_desk(userinfo, deskno) end, throw)
        if (ret == 0) then
            errcode = -8
        end
    end
   
    if (viproom_lib) then
        local succcess, ret = xpcall( function() return viproom_lib.on_before_user_enter_desk(userinfo, deskno) end, throw)
        if (ret == 0) then
            errcode = -11
        elseif (ret == -1) then
        	errcode = -12    
        end
    end   
    --在桌子上找个空座位坐下  
    siteno = hall.desk.get_empty_site(deskno)
    if (siteno > 0) then
        if (duokai_lib) then
            local sit_down_flag = 0
            if (needsitdown == true) then
                sit_down_flag = 1
            end
            duokai_lib.join_game(userlist[userKey].userId, deskno, siteno, 1)
        else
    	    local FunDoWatch = function()
            	DoUserWatch(deskno, userlist[userKey])
            end
            getprocesstime(FunDoWatch, "RQAJDoUserWatch", 500)
            if(needsitdown) then
            local FunDoSitdown = function()
                doSitdown(userKey, userinfo.ip, userinfo.port, deskno, siteno, g_sittype.queue)
            end
            
            getprocesstime(FunDoSitdown, "RQAJdoSitdown", 500)
            end
        end
    	
    else
    	--没有空座位就进入观战
        if (duokai_lib) then
            duokai_lib.join_game(userlist[userKey].userId, deskno, -1, 1)
        else
    	    DoUserWatch(deskno, userlist[userKey])
        end
    end
end

--发送服务器信息:0是大厅消息，1是游戏里消息,客户端直接显示就行了
function OnSendServerMessage(userinfo, ntype, szmsg)
    --TraceError("发送服务器信息:"..ntype)
    if(not userinfo) then return end
    netlib.send(
        function(buf)
            buf:writeString("REMG")
            buf:writeByte(ntype)
            buf:writeString(szmsg)
        end
    , userinfo.ip, userinfo.port, borcastTarget.playingOnly);
end

--通知加入游戏结果
function OnSendUserAutoJoinError(userinfo, errcode, value)
    --TraceError("通知玩家坐下失败")
    if(not userinfo) then return end
    netlib.send(
        function(buf)
            buf:writeString("RQNI")
            buf:writeByte(errcode)
    		buf:writeInt(value)
        end
    , userinfo.ip, userinfo.port, borcastTarget.playingOnly);
end

--收到排队请求
function onrecvrqDeskQueue(buf)
    if (isguildroom()) then --公会专用房间不能排队进入
        return
    end

    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        TraceError("排队时userinfo空"..userKey)
        return
    end

    local CanQueueFlag, value = can_user_enter_desk(userKey, nil)
    --发送无法进入房间消息
    OnSendUserAutoJoinError(userinfo, CanQueueFlag, value)
    if (CanQueueFlag == 1 and userinfo ~= nil) then--用户金币未达到赔率要求
         --用户金币已达到赔率要求
        --用户不是暂时离线用户，用户不是从登陆用户，则排队
        if (userinfo.desk == nil or userinfo.desk < 0 or   --大厅的重登陆用户
            (userinfo.key == userKey and userinfo.offline == nil)) then --桌面的重登陆用户
            --不知道为什么客户端明明在打牌，但是有时候仍然会发送排队信息
            local bGameAlreadyStart = false
            if (userinfo.desk == nil or userinfo.desk < 0) then
                bGameAlreadyStart = false
            else
                local execok, ret = xpcall(function() gamepkg.getGameStart(userinfo.desk, userinfo.site) end, throw)
				if execok then
					bGameAlreadyStart = ret
				end
            end
            --如果当前用户已经在游戏，但是还请求排队。则直接返回了，不再做排队处理
            if (bGameAlreadyStart) then
                TraceError("异常信息，当前用户已经在游戏了，为什么还要排队?")
            else
                processRequireDeskQueue(userKey, buf:ip(), buf:port())
            end
        end
    else
        trace("用户排队信息为空?")
    end
end

--是否符合进入条件 返回 1,0 为正常情况，其余都为异常情况
function can_user_enter_desk(userkey, deskno)
	local userinfo = userlist[userkey]
	local at_least_gold = groupinfo.at_least_gold
	local at_most_gold = groupinfo.at_most_gold
    local at_least_integral = groupinfo.at_least_integral

	return gamepkg.CanUserQueue(userkey, deskno)
end

--判断用户能不能支付得起XX钱
function can_user_afford(userinfo, gold)
	local pay_limit = groupinfo.pay_limit
	if isguildroom() then
		pay_limit = groupinfo.guild_peilv_map[desklist[deskno].gamepeilv]
		if not pay_limit or pay_limit == 0 then TraceError("pay_limit error") end
	end
	return gamepkg.CanAfford(userinfo,gold, pay_limit)
end

function onnotifyDeskQueuePlayer(buf)
    buf:writeString("NTQC")
    --因为机器人排队，且可能因为没有真人不进行游戏，所以如果大于2就只显示2
    local showqueueplayer =  UserQueueMgr.GetCount(1)
    if(showqueueplayer > room.cfg.DeskSiteCount - 1) then
       showqueueplayer = room.cfg.DeskSiteCount - 1
    end
    buf:writeInt(showqueueplayer)

    --buf:writeInt(UserQueueMgr.GetCount(1))
    if (room.arg.addqueueplayernick == nil) then
        buf:writeString("")
    else
        buf:writeString(room.arg.addqueueplayernick)
    end
end

--取消排队
function onRecvCancelQueue(buf)
    local suserid = getuserid(buf)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end;
	if gamepkg and gamepkg.OnCancelQueue then		--取消排队时
        gamepkg.OnCancelQueue(userinfo)
    end
    UserQueueMgr.RemoveUser(suserid)
end

--创建本服务时，传入的大厅及游戏的相关设置参数
function onsetgroupinfo(groupid
                    , groupname                         --组名字
                    , ispublic                          --是否让所有人自动进入此组 =1 表示所有自动进入的组
                    , allowhallchat                     --是否允许在大厅中聊天 1=允许
                    , displayusernameinhall             --是否在大厅中显示游戏者名字
                    , allowclickdesk                    --是否在大厅中直接点击桌子坐下
                    , allowclicksite                    --是否在大厅中直接点击座位坐下
                    , allowgamechat                     --是否允许在游戏中聊天 1=允许
                    , displayusernameingame             --是否在游戏中显示游戏者名字
                    , gamepeilv                             ----赔率
                    , allowMaiMa)                          --是否可以买马
    --记录组信息
    if (groupinfo ~= nil) then
        trace(format("发现修改组信息操作(%s)", groupid))
    end

    groupinfo = {}
    local group = groupinfo
    group.key = groupid
    group.groupid = groupid
    group.groupname = groupname
    group.ispublic = ispublic
    group.allowhallchat = allowhallchat
    group.displayusernameinhall = displayusernameinhall
    group.allowclickdesk = allowclickdesk
    group.allowclicksite = allowclicksite
    group.allowgamechat = allowgamechat
    group.displayusernameingame = displayusernameingame
    group.gamepeilv = gamepeilv
    group.allowMaiMa = allowMaiMa
    --group.port = cfg.nextnewport
    --return 1;
    --todo 这里显示当前服务器启动的房间id，但是现在只能显示一个id
    tools.setcaption("-"..groupname)
end
function OnGameOver(deskno, bQueueDeskUser, bStandupOnNotQueue)
    xpcall(function() hall.desk.clear_state_list(deskno) end, throw)
    local userid, siteUserInfo, i
    local DeskUsers = {}
    for i = 1, room.cfg.DeskSiteCount do
        trace("获取第"..i.."个用户信息")
        local userKey = hall.desk.get_user(deskno, i)
        siteUserInfo = userlist[userKey]
        if (siteUserInfo ~= nil) then
		    siteUserInfo.last_desk = deskno --记录上一次在那里打牌
            trace('游戏结束,检查断线用户:'..siteUserInfo.nick..":"..siteUserInfo.key)

            --托管的回复状态
            if(siteUserInfo.gamerobot == true) then
                siteUserInfo.gamerobot = false
            end

            --如果是离线用户，则让用户站起来
            if (siteUserInfo.offline == offlinetype.tempoffline) then
                --这里不用重置机器人状态，因为整个循环完成后机器人就站起来了.
                trace("有断线用户"..siteUserInfo.key)
                DoKickUserOnNotGame(siteUserInfo.key, false)
			else
				local retcode, value = can_user_enter_desk(siteUserInfo.key, deskno)
				if retcode ~= 1 then	--不够钱,踢出来
					netlib.send(
						function(buf) --发送不够钱踢出房间
							buf:writeString("NTPC")
							buf:writeInt(retcode)
							buf:writeInt(value)
						end
					, siteUserInfo.ip, siteUserInfo.port)
					DoKickUserOnNotGame(siteUserInfo.key, false)
				--房间允许坐下 和 结算不轮换 的情况下都不做轮换操作
				elseif (room.cfg.ongameOverReQueue == 1 and groupinfo.can_sit == 0 and bQueueDeskUser == true) then
					--用户全部排队到队列里面
					trace(format("让%s  %s开始加入排队队列里", userKey, siteUserInfo.nick))

					--这个站起是特殊的，为排队时候站起，不清空观战列表
					doUserStandup(userKey,true)
					--用户此时可能正在登陆游戏但是还没有完成，要登陆完成了才能轮换
					if (usermgr.IsLogin(siteUserInfo) == true) then
						local bWinner = hall.desk.is_win_site(deskno, i)
						if (bWinner == true) then
							UserQueueMgr.AddUser(userKey, siteUserInfo.ip, siteUserInfo.port, queryReasonFlg.gameOverAndWin)
						else
							UserQueueMgr.AddUser(userKey, siteUserInfo.ip, siteUserInfo.port, queryReasonFlg.gameOverAndLost)
						end
					end
				--如果游戏结束不轮换，且坐下方式为站起来再坐下，则先站起来再坐下，否则就没有坐下来消息
				elseif ((bStandupOnNotQueue == nil or bStandupOnNotQueue == true) and
						(room.cfg.ongameOverReQueue == 0 or groupinfo.can_sit == 1)) then
					--在不排队的时候需要先站起来在坐下来
					if (siteUserInfo ~= nil and siteUserInfo.desk ~= nil and siteUserInfo.site ~= nil) then
						local siteno = siteUserInfo.site
						doUserStandup(userKey, true)
						--用户此时可能正在登陆游戏但是还没有完成，要登陆完成了才能轮换
						if (usermgr.IsLogin(siteUserInfo) == true) then
							doSitdown(userKey, siteUserInfo.ip, siteUserInfo.port, deskno, siteno, g_sittype.normal)
							usermgr.enter_playing(siteUserInfo)
						end
				   end
			    end
            end
            --如果用户没有被删除，则设置离线状态为nil
            usermgr.ResetReloginState(userKey)
        end
    end
end

--------------------------------------------------------------------------------
function onrecviamrobot(buf)
    local userkey = getuserid(buf)
    local userinfo = userlist[userkey]

    if userinfo.realrobot ~= true then --如果是第一次发声明，userIfo.realrobot为false才加1
        usermgr.AddRobotUser(userinfo.nRegSiteNo, 1) --机器人人数统计加1
    end
    userinfo.isrobot = true
    userinfo.realrobot = true
    if (userinfo.isrobot == true) then
        trace('user is robot '..userinfo.nick)
    end
    if (room.cfg.ignorerobot == 1) then
        userinfo.isrobot = false --强行设置为自然人,让它们与自然人一起混成排队,方便人少时与机器人打乱打
    end
end
--------------------------------------------------------------------------------
function checkGamePkg()
    if (gamepkg == nil) then
        trace('需要在游戏脚本中定义 gamepkg table')
    end
    local testgamepkg ={
        gamepkg.OnClearUser,
        gamepkg.OnUserSitDown,
        gamepkg.OnAbortGame,
        gamepkg.OnPlayGame,
        gamepkg.getGameStart,
        gamepkg.ontimecheck,
        gamepkg.AfterUserSitDown,
        gamepkg.OnUserStandup,
        gamepkg.IsBlankSite,
        gamepkg.CanEnterGameGroup,
        gamepkg.IsWinner,
        gamepkg.OnBeforeUserLogin,
        gamepkg.AfterUserLogin,
        gamepkg.CanUserQueue,
        gamepkg.GetMinGold,
		gamepkg.TransSiteStateValue,
        gamepkg.after_user_login,
    }
    for k, v in pairs(testgamepkg) do
        if (k == nil) then
            TraceError('游戏脚本定义内容不完整')
            return false
        end
    end
    return true
end

--改变用户头像
function OnChangeFace(buf)
    local szFaceUrl = buf:readString()
    local userKey = getuserid(buf)
    --看看是否换的是vip头像

    local face_id = string.match(szFaceUrl, "^face\/(%d+)\.swf$")
    if (face_id ~= nil) then
		face_id = tonumber(face_id)
        local userinfo = userlist[userKey]
        local vaild_face_begin_id = 500
		local vaild_face_end_id = 1000
        if (userinfo.sex == "0") then
            vaild_face_begin_id = vaild_face_begin_id + 1000
			vaild_face_end_id = vaild_face_end_id + 1000
        end
        if (face_id > vaild_face_begin_id and face_id <= vaild_face_end_id and  --用户请求换vip头像
            viplib and viplib.check_user_vip(userinfo)) then --用户是vip
            local vipinfo = viplib.get_user_vip_info(userinfo)
            local user_vip_level = vipinfo.vip_level
            local find = false
            if (user_vip_level > 1 and facelib.vip_level_face[user_vip_level] ~= nil) then   --用户vip等级>1
                for k, v in pairs(facelib.vip_level_face[user_vip_level]) do
                    if (userinfo.sex == "0") then
                        v = v + 1000
                    end
                    if (v == face_id) then  --找到此头像，说明用户可以换这个头像
                        find = true
                        break
                    end
                end
            end
            if (find == face) then
                TraceError("靠，非vip还想换vip头像,小样")
                return
            end
        end
    end
    if (usermgr.ChangeFace(userKey, szFaceUrl) == false) then
        return
    end
    dblib.cache_set("users", {face=szFaceUrl}, "id", userlist[userKey].userId)
    --在user_extra_face里记录上次的头像，
    --如果FACEID是10001和10002的话就不更换，因为如果是这2个到时间要换回来
    local istemp = false
    for k, v in pairs(facelib.extra_temp_faceid) do
        local s1 = string.find(userlist[userKey].imgUrl, tostring(v))
        if(s1 and s1 > 0) then istemp = true end
    end

    if not istemp then
        local last_use_face = "'"..userlist[userKey].imgUrl.."'"
        local actionSql = string.format(tSqlTemplete.update_last_face, last_use_face,userlist[userKey].userId);
        dblib.execute(actionSql)
    end
    ---------------------------------------------------------

    local szParam = userlist[userKey].userId..","..szFaceUrl
    tools.SendBufToUserSvr(getRoomType(), "NTCF", "", "", szParam)
end

--通知玩家有玩家修改了头像
function OnSendChangeFace(touserinfo, chguserinfo)
    --TraceError("通知玩家头像更改)
    if(not touserinfo or not chguserinfo) then return end
    netlib.send(
        function(buf)
            buf:writeString("RECF")
            buf:writeInt(chguserinfo.userId)
            buf:writeInt(chguserinfo.site or 0)
            buf:writeString(chguserinfo.imgUrl)
        end
    , touserinfo.ip, touserinfo.port);
end

--广播有玩家修改了头像
function net_broadcast_face_change(userinfo)
    if not userinfo then return end
    --通知桌内玩家
    local deskno = userinfo.desk
    --没有桌子号，只发给自己
    if(not deskno) then
        OnSendChangeFace(userinfo, userinfo)
        return
    end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendChangeFace(playingUserinfo, userinfo)
            end
            if(playingUserinfo == nil) then
                TraceError("头像变更时桌子上有个用户的userlist信息为空")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendChangeFace(watchinginfo, userinfo)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
end

facelib = {
    --特殊头像价格
    extra_face_price = {
        [10001] = 50000,
        [10002] = 500000,
        [10003] = 10000000,
    },
    --临时的特殊头像
    extra_temp_faceid = {
        [1] = 10011,    --临时
        --[2] = 10012,  --永久
    },


	--VIP头像，规定500以上为vip头像，500以下为普通头像,男头像500以上，女头像1500以上
	vip_level_face = {
		[1] = {},
		[2] = {501, 502},
		[3] = {501, 502, 503, 504},
	},
}

--是否是扩展头像
facelib.is_extra_face = function(face_id)
     if (face_id == nil) then
        return false
    end
    face_id = tonumber(face_id)
	for k, v in pairs(facelib.extra_temp_faceid) do
		if(v == face_id) then return true end
	end
	return false
end

--是否是vip头像
facelib.is_vip_face = function(face_id)
    if (face_id == nil) then
        return false
    end
    face_id = tonumber(face_id)
    if (face_id > 500 and face_id <= 1000 or
        face_id > 1500 and face_id <= 2000) then
        return true
    end
end

--收到请求显示头像列表
function on_recv_select_head_info(buf)
    local userinfo = userlist[getuserid(buf)]
    local extra_faces = {}  --活动头像
    local vip_faces = {}    --vip头像
	--考虑会员附加头像  //TODO
	local user_vip_level = 0
	if viplib and viplib.check_user_vip(userinfo)  then
		local vipinfo = viplib.get_user_vip_info(userinfo)
		user_vip_level = vipinfo.vip_level
        --大于1级的才有vip头像
        if (facelib.vip_level_face[user_vip_level] ~= nil) then
            for k, v in pairs(facelib.vip_level_face[user_vip_level]) do
                if (userinfo.sex == "0") then
                    v = v + 1000
                end
                table.insert(vip_faces, v)
            end
        end
	end
    local isover = check_halloween_time()

    --如果活动已经结束,得到用户已经买到的extra头像
    --if(isover == 1) then
        dblib.execute(string.format(tSqlTemplete.get_extra_face, userinfo.userId),
            function(dt)
                if(#dt > 0) then

                    local faces = split(dt[1].active_face, "|")
                    for k, v in pairs(faces) do
						if v ~= "" then
							local bfind = false
							for k1, v1 in pairs(facelib.extra_temp_faceid) do
								if(tonumber(v) == tonumber(v1)) then
									bfind = true
									break
								end
							end
							--if(not bfind) and v ~= "" then
							if(facelib.is_extra_face(v) == false) then
							   table.insert(extra_faces, v)
							else
							   if(isover == 0) then
								   table.insert(extra_faces, tonumber(v))
							   end
							end
						end
                    end
                end
                on_send_select_face(userinfo, 1, extra_faces, vip_faces)
            end
        )
       
        

   -- else
        --on_send_select_face(userinfo, isover, extra_faces, vip_faces)
   -- end
end

function on_send_select_face(userinfo, isover, extra_faces, vip_faces)
    --告诉客户端结果
    netlib.send(
        function(buf)
            buf:writeString("RAHD")
            buf:writeInt(isover)
            buf:writeInt(#extra_faces)
            if(#extra_faces > 0) then
                for i = 1,#extra_faces do
                    buf:writeInt(extra_faces[i])
                end
            end
            buf:writeInt(#vip_faces)
            if(#vip_faces > 0) then
                for i = 1,#vip_faces do
                    buf:writeInt(vip_faces[i])
                end
            end               
        end
    , userinfo.ip, userinfo.port)
end

--看2009年万圣节活动是否过期
function check_halloween_time()
    --TODO:日期写死了
    local isover = 0
    local endtime = os.time{year = 2009, month = 12, day = 26,hour = 0};
    if(os.time() > endtime) then
        isover = 1
    end
    return isover
end

--活动过后恢复原来的头像
function restore_temp_face(userinfo)
    local is_special_face = 0
    local is_special_face_over = 0
    local isover = 0
    if (facelib.is_extra_face(string.match(userinfo.imgUrl, "^face\/(%d+)\.swf$")) == true) then  --检测活动是否结束
        is_special_face_over = check_halloween_time()
        is_special_face = 1
    elseif (facelib.is_vip_face(string.match(userinfo.imgUrl, "^face\/(%d+)\.swf$")) == true) then  --检测vip是否结束
        if (viplib ~= nil and viplib.check_user_vip(userinfo) == false) then
            is_special_face_over = 1
        end
        is_special_face = 1
    end
    --如果万圣节结束而且头像是10001或者10002恢复以前的头像
    if(is_special_face_over == 1 and is_special_face == 1) then
        local normal_face = "face/1.jpg"
        if (userinfo.sex == "0") then
            normal_face = "face/1001.jpg"
        end
        if (usermgr.ChangeFace(userinfo.key, normal_face) == false) then
            return
        end
        --local szSql = format(tSqlTemplete.updateUserFace, dt[1].normal_face, userinfo.userId)
        dblib.cache_set("users", {face=normal_face}, "id", userinfo.userId)
        --dblib.execute(szSql)
        local szParam = userinfo.userId..","..normal_face
        tools.SendBufToUserSvr(getRoomType(), "NTCF", "", "", szParam)

        --因为数据库不同步，要单独通知客户端
        netlib.send(
            function(buf)
                buf:writeString("CHFCOK")
                buf:writeString(normal_face)
            end
        , userinfo.ip, userinfo.port)
    end
end

--激活特殊头像
function on_active_extra_face(buf)
    local userinfo = userlist[getuserid(buf)]
	local faceId = buf:readString()
    faceId = tonumber(faceId)
    local sure = buf:readInt()
    --TODO:face价格配置,先写死在代码里
    --string.gmatch("face/1000.swf", "/(%d+)\.swf")()
    --扣用户钱，增加user_extra_face表记录
    if(not userinfo) then return end
    if(not facelib.extra_face_price[faceId]) then return end

    local nsuccess = 0
    local actived = 0

    --看用户是否激活
    local active_str = ""
    dblib.execute(string.format(tSqlTemplete.get_extra_face, userinfo.userId),
        function(dt)
            if(#dt > 0) then
                active_str = dt[1].active_face

                local active_list = split(active_str, "|")
            	for k, v in pairs(active_list) do
                    if v and v ~= "" then
            		    if(tonumber(v) == faceId) then
                            actived = 1
                        end
                    end
                end
            end

             --如果用户已经激活了，就不做数据库操作
            if(actived == 1) then
                nsuccess = 1

            --用户每激活，尝试激活头像，
            else
                --用户不够钱买啊
                if(sure == 1) then
                    if(facelib.extra_face_price[faceId] <=  userinfo.gamescore) then
                        --更改用户金币，注意是负数，扣钱的
                        usermgr.addgold(userinfo.userId, -facelib.extra_face_price[faceId], 0, g_GoldType.buy, -1)

                        local actionSql = string.format(tSqlTemplete.active_user_face, userinfo.userId ,faceId,userinfo.userId);
                        dblib.execute(actionSql)
                        nsuccess = 1
                    end
                else
                    nsuccess = 2
                end
            end

            --告诉客户端结果
            netlib.send(
                function(buf)
                    buf:writeString("RAAF")
                    buf:writeInt(nsuccess)
                    buf:writeInt(faceId)
                    buf:writeInt(facelib.extra_face_price[faceId])
                end
            , userinfo.ip, userinfo.port)
        end
    )
end

--广播送钱消息
function OnNotifyChangeGold(buf)
    buf:writeString("NTUM")
    buf:writeString(room.arg.szFromUserKey)
    buf:writeString(room.arg.szToUserKey)
    buf:writeInt(room.arg.nGold)
end


function require_refresh_user_info(user_id, callback_fun)
	local OnNotifyRefreshGold = function(dt)
		if (user_id == nil or dt==nil or #dt == 0) then
			return
		end
		local user_gold = dt[1]["gold"]
		if (user_gold == nil) then
			return
		end
		local userinfo = usermgr.GetUserById(user_id)
		if (userinfo == nil) then
			return
		end
		userinfo.gamescore = user_gold
        --最高拥有过游戏币
    	if(userinfo.extra_info and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            save_extrainfo_to_db(userinfo)
        end
		--刷新vip信息
        if (viplib ~= nil) then
            viplib.load_user_vip_info_from_db(userinfo.userId)
        end
        net_send_user_new_gold(userinfo, user_gold)
        if (callback_fun ~= nil) then
            callback_fun(userinfo)
        end
	end
    dblib.cache_exec("get_user_gold_from_db", {user_id}, function(dt) OnNotifyRefreshGold(dt, user_id) end)

	--dblib.execute(format(tSqlTemplete.getUserGoldFromDb, userlist[userKey].userId),
	--        function(dt) OnNotifyRefreshGold(dt, userlist[userKey].userId) end)
end

function on_require_refresh_user_info(buf)
    local userKey = getuserid(buf)
    if (userlist[userKey] == nil) then
        return
    end
    local user_id = userlist[userKey].userId

    require_refresh_gold(user_id)
end

function require_refresh_gold(user_id, call_back)

	local OnNotifyRefreshGold = function(dt)
		if (user_id == nil or dt==nil or #dt == 0) then
			return
		end
		local user_gold = dt[1]["gold"]
		if (user_gold == nil) then
			return
		end
		local userinfo = usermgr.GetUserById(user_id)
		if (userinfo == nil) then
			return
		end
		userinfo.gamescore = user_gold
        if (duokai_lib) then
            duokai_lib.merge_data(userinfo, "gamescore")
        end
        --最高拥有过游戏币
    	if(userinfo.extra_info and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            if (duokai_lib) then
                duokai_lib.merge_data(userinfo, "extra_info")
            end
            save_extrainfo_to_db(userinfo)
        end
		local szBuf = tostring(user_id)..","..tostring(user_gold)
		tools.SendBufToUserSvr(getRoomType(), "STGB", "", "", szBuf) --发送数据到服务端
        net_send_user_new_gold(userinfo, user_gold)
        if (call_back ~= nil) then
            call_back(userinfo)
        end            
	end
    dblib.cache_exec("get_user_gold_from_db", {user_id}, function(dt) OnNotifyRefreshGold(dt, user_id) end, user_id)

	--dblib.execute(format(tSqlTemplete.getUserGoldFromDb, userlist[userKey].userId),
	--        function(dt) OnNotifyRefreshGold(dt, userlist[userKey].userId) end)
end

--------------------------------------------------------------------------------
--****************************************************************************
--*                                                                          *
--*                       用户观战部分逻辑,Felon                             *
--*                                                                          *
--****************************************************************************
function OnRequestGetSvrId(buf)
    buf:writeString("RQUS")
    buf:writeInt(room.arg.userId)
    buf:writeInt(room.arg.reqUserId)
end

function OnRecvGetSvrId(buf)
    local nUserId = buf:readInt()
    local nReqUserId = buf:readInt()
    local nGameSvrId = buf:readString()

    local userKey = getuserid(buf)
    local userinfo = userlistIndexId[nReqUserId]
    local ErrorCode = 0

    --如果观战,而且是该人发送的请求
    if(room.arg.ReqGetSvrIdType == "watch" and room.arg.reqUserId == nReqUserId) then
        --用户不在线
        if(nGameSvrId == "-1") then
             ErrorCode = -1
        else
            --需要自动登录发相关信息
            ErrorCode = -2
        end
        OnSendUserWarchError(userinfo, ErrorCode, nUserId, nGameSvrId)
    end
end

--收到请求退出观战
function OnRecvExitWatch(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        return
    end
    if(userinfo.site ~= nil) then
        TraceError("退出观战必须先退出游戏:userid = "..userinfo.userId)
        return
    end

    DoUserExitWatch(userlist[userKey])
end

--判断是否可以观战
--   错误标识
   -- -1   被观战的桌子无效
   -- -2   被观战的桌子不在此服
   -- -3   被观战的桌子不允许观战
   -- -4   观战列表已满
   -- -5   等级不够
   -- -6   不是VIP会员不能进入
   -- -7   身上金币不够
   -- -8   玩家是在被踢列表中的
   -- -9   如果牌桌的频道ID不为空，并且玩家的频道ID与牌桌的频道ID不同
function CanUserWatch(userinfo, deskno, friend)
    if not userinfo then return end
    local bCanWatch = true         --能否观战标识
    local nErrorCode = 1

    local deskinfo = desklist[deskno]

    if(deskinfo == nil) then
        nErrorCode = -1
        return nErrorCode
    end

    --TODO:加入观战限制条件
    --进入牌桌前，看一下是不是在本桌的被踢列表中的
    if (tex_buf_lib) then
        local succcess, ret = xpcall( function() return tex_buf_lib.on_before_user_enter_desk(userinfo, deskno) end, throw)
        if (ret == 0) then
            return -8
        end
    end

    if (viproom_lib) then
        local succcess, ret = xpcall( function() return viproom_lib.on_before_user_enter_desk(userinfo, deskno) end, throw)
        if (ret == 0) then
            return -11
        elseif(ret == -1) then
        	return -12
        end
    end

    --如果牌桌的频道ID不为空，并且玩家的频道ID与牌桌的频道ID不同，就返回-9
    --没有桌子的频道等于0，如果有，就是个错误的桌子
   if(deskinfo.channel_id~=nil and deskinfo.channel_id~=-1 and deskinfo.channel_id~=userinfo.channel_id) then
       return -9
    end


    --进入牌桌的判断
    if bCanWatch then
        --如果是VIP5就直接可以观战 
        if(viplib) then
            if (viplib.get_vip_level(userinfo)>=5) then
                return 1
            end
        end


        if(nErrorCode > 0) then
            if(gamepkg.CanWatch and not gamepkg.CanWatch(userinfo, deskno)) then
                nErrorCode = -3
            end
        end

        --检查观战列表是否已满
        if(nErrorCode > 0) then
            local nCount = 0
            for k,v in pairs(deskinfo.watchingList) do
                nCount = nCount + 1
            end

            if(nCount >= room.maxWatchUserCount and deskinfo.desktype ~= g_DeskType.match) then
               
                nErrorCode = -4
            end
        end
    end

    --等级判断，利用朋友关系进入的不限制等级
    if not friend or friend ~= 1 then
        if(deskinfo.desktype ~= g_DeskType.match and deskinfo.needlevel > usermgr.getlevel(userinfo)) then
            --TraceError(format("不够等级观战, needlevel[%d], userlevel[%d]", deskinfo.needlevel, usermgr.getlevel(userinfo)))
            nErrorCode = -5
        end
    end

    --VIP资格判断
    if deskinfo.desktype == g_DeskType.VIP and not (viplib and viplib.check_user_vip(userinfo)) then
        --TraceError(format("非VIP玩家不可以进VIP俱乐部,userid[%d]", userinfo.userId))
        nErrorCode = -6
    end

    --金币判断
	local needgold = deskinfo.at_least_gold
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		needgold = needgold + deskinfo.specal_choushui
	end
	if(userinfo.gamescore < needgold) then
		--nErrorCode = -7  --改为观战不限制金币
        nErrorCode = 1
    end

    return nErrorCode
end

--收到请求观战
function OnRecvRqWatch(buf)
    local deskno = buf:readInt()    --要观战的桌子
    local userKey = getuserid(buf)
    if (deskno <= 0 or deskno > #desklist) then return end
    local userinfo = userlist[userKey]
    if not userinfo then return end

    DoRecvRqWatch(userinfo, deskno, 0)
end

--处理收到的观战请求
function DoRecvRqWatch(userinfo, deskno, friend)
    if not userinfo then return end
    if (deskno <= 0 or deskno > #desklist) then return end
    local nErrorCode = CanUserWatch(userinfo, deskno, friend)
    if nErrorCode > 0 then
        --开始观战计时
        if (duokai_lib) then
            duokai_lib.join_game(userinfo.userId, deskno, -1, 1)
        else
            DoUserWatch(deskno, userinfo)
        end
    else
       OnSendUserWarchError(userinfo, nErrorCode)
   end
end

--通知玩家观战失败
function OnSendUserWarchError(userinfo, errcode, watchUserId, watchRoomId)
    --TraceError("通知玩家观战失败")
    if(not userinfo) then return end
    netlib.send(
        function(buf, user)
            buf:writeString("RESE")
            buf:writeByte(errcode)
        end
    , userinfo.ip, userinfo.port);
end

--离开观战
function DoUserExitWatch(userinfo)
    if(userinfo == nil) then
        return
    end

    --离开大厅清空拒绝列表
    if userinfo.refuselist then
        userinfo.refuselist = nil
    end


    local deskno = userinfo.desk
    if(deskno == nil) then
        return
    end

    OnBrocastrExitWatch(deskno, userinfo)
    removeFromWatchList(userinfo)
    
    if(tex_userdiylib)then
    	tex_userdiylib.on_recv_update_userlist(userinfo,deskno)
    end
    eventmgr:dispatchEvent(Event("on_user_exit_watch", {user_info=userinfo}));
end

--执行玩家观战
function DoUserWatch(deskno, userinfo,retcode)
    if(deskno == nil) then return end

    local deskinfo = desklist[deskno]
    if(deskinfo == nil) then return end
    
    if (viproom_lib) then
        local succcess, ret = xpcall( function() return viproom_lib.on_before_user_enter_desk(userinfo, deskno) end, throw)
        if (ret == 0) then
            return -11
        elseif(ret == -1) then
        	return -12    
        end
    end
   
    
    if(userinfo.site ~= nil) then
      TraceError("进入观战前必须先站起~~")
      TraceError(format("userid[%d],deskno:%s,siteno:%s", userinfo.userId, tostring(userinfo.desk), tostring(userinfo.site)))
      doUserStandup(userinfo.key, false)
      --未知原因站不起来了
      if(userinfo.site ~= nil)then return end
    end

    --加入观战列表
    addToWatchList(deskno, userinfo);

    --给自己发送观战成功信息
    if(retcode == nil) then retcode = 1 end
    OnSendSelftWatch(userinfo,retcode)

    --广播桌面有人进来观战了
    local time1 = os.clock() * 1000
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno,i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserSitdown(userinfo, playingUserinfo, 1, g_sittype.normal)  --在玩的玩家
                --游戏信息
                OnSendUserGameInfo(userinfo, playingUserinfo, 0)
            end
            if(playingUserinfo == nil) then
                TraceError("用户观战时桌子上有个用户的userlist信息为空")
                hall.desk.clear_users(deskno,i)
            end
        end
    end
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if(userlist[k] == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 500)  then
        TraceError("通知桌子有人来观战,时间超常:"..(time2 - time1))
    end
    
    --进入观战派发见面事件了
    local DoUserWatch1 = function()
        dispatchMeetEvent(userinfo)
    end
    getprocesstime(DoUserWatch1, "DoUserWatch1", 500)

    --从大厅到牌桌
    local DoUserWatch2 = function()
        --TraceError("从大厅到牌桌")
    end
    getprocesstime(DoUserWatch2, "DoUserWatch2", 500)

    --广播桌面有人进来观战了(结束)
    if (gamepkg ~= nil and gamepkg.AfterUserWatch ~= nil) then
        local DoUserWatch3 = function()
            gamepkg.AfterUserWatch(deskno, userinfo)
        end
        getprocesstime(DoUserWatch3, "DoUserWatch3", 500)
    end

    eventmgr:dispatchEvent(Event("on_watch_event", _S{userinfo=userinfo}));
    
    
    if(tex_userdiylib)then
    	tex_userdiylib.on_recv_update_userlist(userinfo)
    end

end

function check_run_settings(caption, onresultname, onresult, value)
    if(value == nil) then value = 0 end
    onresult(caption, value)
    settings.addcheck(caption, onresultname, value)
end

--默认初始化房间设置
function on_init_room_settings()
    dblib.execute(string.format(tSqlTemplete.get_roominfo_copy, groupinfo.groupid),
        function(dbsettings)
            local dtsettings = {}
            local dtgamesettings = {}
            if (#dbsettings == 0 or dbsettings[1]["room_settings"] == nil or dbsettings[1]["room_settings"] == "") then
                TraceError("没有为房间配置数据库表rooms字段room_settings的配置信息，采用默认配置或者请自行手动修改!")
                dtsettings = split('1,1,1,1,0,0,1,1,0', ',')
                dtgamesettings = split('1,1,1', ',')
            else
                local tempsettings = split(dbsettings[1]["room_settings"], ';')
                dtsettings = split(tempsettings[1], ',')
                dtgamesettings = split(tempsettings[2], ',')
            end

            if(#dtsettings == 0) then return end

			groupinfo.can_sit = dbsettings[1]["cansit"] or error()						--是否可以坐下

			--公会专用房间配置
			groupinfo.isguildroom = dbsettings[1]["isguildroom"] or error()				--是否为公会专用房间
			local guild_peilv_info = split(dbsettings[1]["guild_peilv_info"], "|")		--10,100|100,100|1000,100|10000,100|100000,100
																						--100等价于at_least_gold和pay_limit
			groupinfo.guild_peilv_map = {}
			for k, v in pairs(guild_peilv_info) do
				if v ~= "" then
					groupinfo.guild_peilv_map[tonumber(split(v,",")[1])] = tonumber(split(v,",")[2])
				end
			end

			--上下限配置
			groupinfo.at_least_gold =  dbsettings[1]["at_least_gold"] or groupinfo.gamepeilv * 50
			groupinfo.at_most_gold =  dbsettings[1]["at_most_gold"] or groupinfo.gamepeilv * 100
			groupinfo.pay_limit =  dbsettings[1]["pay_limit"] or groupinfo.gamepeilv * 50
			groupinfo.min_gold =  dbsettings[1]["min_gold"] or 150
			groupinfo.add_gold =  dbsettings[1]["add_gold"] or 200
            groupinfo.specal_pochan_give_money = dbsettings[1]["specal_pochan_give_money"] or 0
            groupinfo.specal_choushui = dbsettings[1]["specal_choushui"] or -1
            groupinfo.is_tournament = dbsettings[1]["is_tournament"] or 0
            groupinfo.is_nocheat = dbsettings[1]["is_nocheat"] or 0
            groupinfo.is_highroom = dbsettings[1]["is_highroom"] or 0
            groupinfo.at_least_integral = dbsettings[1]["at_least_integral"] or 0

            ----------------wlmf添加--------------------
            groupinfo.max_lost_gold = dbsettings[1]["max_lost_gold"] or 0
            groupinfo.limit_jia_bei = dbsettings[1]["limit_jia_bei"] or 0
            groupinfo.is_huanle     = dbsettings[1]["is_huanle"] or 0
            --------------------------------------------

			-----------------拖拉机至少打到几-----------
            groupinfo.at_least_zhunum = dbsettings[1]["at_least_zhunum"] or 0
            --------------------------------------------


			for i = 1, #desklist do
				desklist[i].gamepeilv = groupinfo.gamepeilv
			end
			if _DEBUG then
				check_run_settings('1分钟后关闭输出日志', 'onchecklog', onchecklog, 0)
			else
				check_run_settings('1分钟后关闭输出日志', 'onchecklog', onchecklog, 1)
            end

            check_run_settings('只输出错误信息', 'oncheckerrorlog', oncheckerrorlog, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)

            if(#dtsettings == 0) then return end
            check_run_settings('同一台机器允许同桌打牌', 'onchecksamedesk', onchecksamedesk, tonumber(dtsettings[0]))
            table.remove(dtsettings, 1)

            if(#dtsettings == 0) then return end
            check_run_settings('每局结束后重新排牌友', 'oncheckrequeue', oncheckrequeue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)


            if(#dtsettings == 0) then return end
            check_run_settings('每桌至少有一个自然人', 'oncheckqueue', oncheckqueue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)


            if(#dtsettings == 0) then return end
			check_run_settings('限定每手限时出牌(仅限于调试)', 'onchecktimelimit', onchecktimelimit, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('忽略机器人排队规则', 'oncheckrobot', oncheckrobot, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('包房专用房间(已失效)', 'oncheckbaofang', oncheckbaofang, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('限制ip相同的用户同桌打牌', 'onchecksameip', onchecksameip, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
			if(#dtsettings == 0) then return end
			check_run_settings('系统不赔钱(二人斗地主无效)', 'oncheckbupeiqian', oncheckbupeiqian, tonumber(dtsettings[1]))
			table.remove(dtsettings, 1)
			if(#dtsettings == 0) then return end
			check_run_settings('每局结束强制轮换(必须勾上每局结束后重排牌友才生效)', 'oncheckfocerequeue', oncheckfocerequeue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtgamesettings == 0) then return end
            check_run_settings('允许GM控制发牌', 'oncheck_control_fapai', oncheck_control_fapai, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtgamesettings == 0) then return end

        	if (gamepkg.init_room_settings) then
           		gamepkg.init_room_settings(dtgamesettings)
            end
        end)
end

--返回请求观战的结果到客户端(和自己的个人信息)
function OnSendSelftWatch(userinfo,retcode)
    local retarr = tex.getdeskdefaultchouma(userinfo, userinfo.desk)
    local defaultchouma = retarr.defaultchouma 

    --TraceError("返回请求观战的结果到客户端retcode:"..retcode)
    netlib.send(
        function(buf, user)
            buf:writeString("REWT")
            buf:writeShort(userinfo.desk)        --桌号
            buf:writeInt(userinfo.userId)
            buf:writeInt(userinfo.gamescore)     --金币
            buf:writeByte(userinfo.sex)          --性别
            buf:writeString(userinfo.imgUrl)     --头像
            buf:writeInt(userinfo.nSid)          --频道Id
            buf:writeString(_U(string.HextoString(userinfo.szChannelNickName))) --频道名
            buf:writeInt(usermgr.getexp(userinfo))    --经验
            buf:writeInt(userinfo.tour_point)    --竞技点
            buf:writeInt(retcode or 1)           --
            buf:writeInt(defaultchouma or 0)     -- 默认筹码，用来在客户端下面的面板上显示
        end
    , userinfo.ip, userinfo.port)
end

--通知其他人，谁离开观战
function OnBrocastrExitWatch(desk, userinfo)
    --TraceError(format("桌子[%d]上玩家[%d]离开观战", desk, userinfo.userId))
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("NTET")
            buf:writeShort(desk);	-- 桌号
            buf:writeInt(userinfo.userId);	-- userid
        end
    , desk, borcastTarget.all);
end

--添加用户到观战列表
function addToWatchList(deskno, userinfo)
    if(not userinfo) then return end
    if(deskno <= 0 or deskno > #desklist) then
        TraceError("观战失败，非法桌号:"..deskno)
        return
    end
    --[[if(userinfo.site ~=nil) then
        TraceError("警告:玩家已经在别的位置游戏")
        return
    end

    if(userinfo.desk ~=nil) then
        TraceError("警告:玩家已经在别的桌子观战")
        return
    end--]]

    local deskinfo = desklist[deskno]
    if(deskinfo == nil) then
        TraceError("deskinfo怎么会为空？addToWatchList抛异常了")
        return
    end

    --观战的桌子
    userinfo.desk = deskno
    userinfo.site = nil  --强制使其先观战

    --添加到桌子的观战列表
    deskinfo.watchingList[userinfo.key] = userinfo
    deskinfo.watchingList[userinfo.key].begin_watch_time = os.time()
    deskinfo.watchercount = deskinfo.watchercount + 1
    if (duokai_lib and duokai_lib.is_parent_user(userinfo.userId) == 1) then
        --如果是主账号切换房间，则发送主账号加入的事件
        eventmgr:dispatchEvent(Event("on_parent_user_add_watch", {user_info = userinfo}))
    end
end

--超时之后，如果不是3级以上的VIP，如果不在高手场就踢走
function kick_timeout_user_from_watchlist(deskinfo)
    for k, v in pairs(deskinfo.watchingList) do
        --多开用户不受超时影响
        local check = 1
        if (duokai_lib and duokai_lib.is_sub_user(v.userId) == 0) then
            check = 0
        end
        if(v.begin_watch_time ~= nil and os.time()-v.begin_watch_time>=600 and deskinfo.smallbet >= 500 and 
           deskinfo.desktype ~= g_DeskType.match and check == 1)then
           if(viplib) then
                if (viplib.get_vip_level(v)<3) then
                    douserforceout(v)
                    OnSendUserWarchError(v, -10)
                end
            end
        end 
    end
end

--从观战列表删除用户
function removeFromWatchList(userinfo)
    if(userinfo == nil or userinfo.desk == nil) then return end

    local deskinfo = desklist[userinfo.desk]
    if(deskinfo == nil) then
        TraceError("deskinfo怎么会为空？removeFromWatchList抛异常了")
        return
    end

    if(userinfo.site ~= nil) then
        TraceError("坐下状态不允许直接退出观战")
        TraceError(debug.traceback())
        return
    end

    local watchingList = deskinfo.watchingList
    if(watchingList[userinfo.key]~=nil)then
	    watchingList[userinfo.key].begin_watch_time = nil
	    watchingList[userinfo.key] = nil
	    deskinfo.watchercount = deskinfo.watchercount - 1
	end
    userinfo.desk = nil
    userinfo.site = nil
end

--请求加好友
function OnRequestAddFriend(buf)
    local szFromUserKey = getuserid(buf)
    local userinfo = userlist[szFromUserKey]
    if not userinfo then return end
    local nToUserId = buf:readInt()
    local touserinfo = usermgr.GetUserById(nToUserId)
    if not touserinfo then return end
    --check whether two users in same site
    local fromdesk = getUserDesk(userinfo)
    local todesk = getUserDesk(touserinfo)
    if  not fromdesk then return end
    if  not fromdesk == todesk then return end
    --make md5
    local szMd5 = string.md5(tostring(userinfo.userId) .. tostring(touserinfo.userId) .. "HOO^_^")
    --send request to another user
    local sendFun = function(outBuf)
        outBuf:writeString("NTFC")
        outBuf:writeString(szMd5)
        outBuf:writeInt(touserinfo.userId)
        outBuf:writeInt(userinfo.userId)
        outBuf:writeString(userinfo.nick)
    end

    --要播放动画，所以要告诉桌上所有人，FELON
    netlib.broadcastdesk(sendFun, touserinfo.desk, borcastTarget.playingOnly)
end

--同意加好友
function OnAcceptAddFriend(buf)
    local szFromUserKey = getuserid(buf)
    local userinfo = userlist[szFromUserKey]
    if not userinfo then return end
    local szMd5 = buf:readString()
    local nFromUserId = buf:readInt()
    local fromuserinfo = usermgr.GetUserById(nFromUserId)
    if not fromuserinfo then return end

    if userinfo.userId == fromuserinfo.userId then
        TraceError("add friend myself")
        return
    end
    --check md5
    local szMd5Check = string.md5(tostring(fromuserinfo.userId) .. tostring(userinfo.userId) .. "HOO^_^")
    if szMd5 ~= szMd5Check then return end
    --check whether two users in same site
    local fromdesk = getUserDesk(userinfo)
    local todesk = getUserDesk(fromuserinfo)
    if  not fromdesk then return end
    if  not fromdesk == todesk then return end
    --tell gamecenter friend was build between FROM and TO
    local szsendbuff = tostring(fromuserinfo.userId) .. "," .. tostring(userinfo.userId)
    tools.SendBufToUserSvr(getRoomType(), "NT2F", "", "", szsendbuff)

    --通知桌上的所有人，他们两个是好友了
    OnSendAcceptFriendOK(fromdesk, fromuserinfo, userinfo)
end

--通知桌上的所有人，他们两个是好友了
function OnSendAcceptFriendOK(desk, fromuserinfo, touserinfo)
    --TraceError("通知桌上的所有人，他们两个是好友了")
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("FROK")
            buf:writeInt(fromuserinfo.userId)
            buf:writeInt(touserinfo.userId)
        end
    , desk, borcastTarget.all);
end

--获取玩家的座位号, 含观战
function getUserDesk(userinfo)
    if userinfo.desk then return userinfo.desk end
    if userinfo.watchingUser and userinfo.watchingUser.desk then return userinfo.watchingUser.desk end
    return nil
end

--机制代码:转发来自GameCenter的请求
function OnRecvBufFromGameCenterToUser(buf)
    local userid = buf:readInt()
    local userinfo = usermgr.GetUserById(userid)
    if not userinfo then return end
    local sendFun = function(outBuf)
         outBuf:writeBuf(buf, buf:getRemainLen())
    end
    tools.FireEvent2(sendFun, userinfo.ip, userinfo.port)
end

--机制代码:
function SendBufferToGameCenter(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then return end
    room.arg.buf = buf
    room.arg.userid = userinfo.userId
    tools.SendBufToGameCenter(getRoomType(), "SDSBTC")
end

--机制代码:
function OnSendBufferToGameCenter(buf)
    buf:writeString("SDSBTC")
    buf:writeInt(room.arg.userid)
    buf:writeBuf(room.arg.buf, room.arg.buf:getRemainLen())
    return true
end

function on_exe_over(buf)
	TraceError("on_exe_over...")
	for k, v in pairs(userlist) do
		tools.CloseConn(v.ip, v.port)
	end
	TraceError("on_exe_over...OK")
end

--------------------------- 聊天 -------------------------
--发送聊天消息失败
function OnRecvChatError(buf)
    local szSendFunc = buf:readString()
    local nChatType = buf:readByte()
    local nToUserId = buf:readInt()
    local szChatInfo = buf:readString()
    local nFromUserId = buf:readInt()
    local szFromUserNick = buf:readString()
    local tToUserInfo = usermgr.GetUserById(nFromUserId)
    if (tToUserInfo ~=  nil) then
        SendChatToUser(4, tToUserInfo, "1", 0, "")
    end
end

function OnRecvChatFromGameSvr(buf)
    local nChatType = buf:readByte()
    local nToUserId = buf:readInt()
    local szChatInfo = buf:readString()
    local nFromUserId = buf:readInt()
    local szFromUserNick = buf:readString()
    local tToUserInfo = usermgr.GetUserById(nToUserId)
    if (tToUserInfo ~=  nil) then
        SendChatToUser(1, tToUserInfo, szChatInfo, nFromUserId, szFromUserNick)
    end
end

function SendChatToGameSvr(buf)
    buf:writeString("RECT")
    buf:writeByte(room.arg.chatType)                                            --私聊
    buf:writeInt(room.arg.nToUserId)                    --私聊
    buf:writeString(room.arg.currchat)                --text
    buf:writeInt(room.arg.tFromUserInfo.userId)
    buf:writeString(room.arg.tFromUserInfo.nick)
end

--收到桌内聊天请求
function onrecvdeskchat(buf)
    local nType = buf:readByte()
    local msg = buf:readString()
    room.arg.currchat = msg
    local nToUserId = buf:readInt()
    local userKey = getuserid(buf)
    local tFromUserInfo = userlist[userKey]
    room.arg.tFromUserInfo = tFromUserInfo
    room.arg.nToUserId = nToUserId
    local userNick = tFromUserInfo.nick
    room.arg.chatType = nType

    if (nType == 1) then            --私聊
        local tToUserInfo = usermgr.GetUserById(nToUserId)
        if (tToUserInfo ~= nil) then --要发送的用户在本服
            SendChatToUser(1, tToUserInfo, room.arg.currchat, tFromUserInfo.userId, tFromUserInfo.nick)
        else --用户在其他服务器上
            send_buf_to_gamesvr_by_use_id(tFromUserInfo.userId, nToUserId, SendChatToGameSvr,  "ERDC")
        end
    elseif (nType == 2) then        --桌面聊天
        if tFromUserInfo.desk then
            if (gm_lib and gm_lib.check_gm_cmd(tFromUserInfo.userId, msg) == 0) then --不是gm消息，则走正常流程
                room.arg.currentuser = tFromUserInfo.nick
                room.arg.userId  = tFromUserInfo.userId
                room.arg.siteno  = tFromUserInfo.site
                onsenddeskchat(tFromUserInfo.desk, nType, msg, tFromUserInfo)
            end
        end
    elseif nType == 3 then           --观战聊天
        room.arg.currentuser = userNick
        room.arg.userId  = tFromUserInfo.userId
        local borcastUserKey = tFromUserInfo.key
        --如果该用户正在观战
        if(userlist[borcastUserKey].watchingUser ~= nil) then
            borcastUserKey = userlist[borcastUserKey].watchingUser.key
        end
        borcastUserEvent("REDC", borcastUserKey)
	elseif (nType == 6) then            --公会
        local tToUserInfo = usermgr.GetUserById(nToUserId)
		tools.SendBufToUserSvr(getRoomType(), "GDCT", "", "", table.tostring({userid=tFromUserInfo.userId, chatstr=room.arg.currchat}))
    elseif (nType == 7) then        --当前聊天
        for _, userinfo in pairs(userlist) do
			if not userinfo.desk then
				SendChatToUser(7, userinfo, room.arg.currchat, tFromUserInfo.userId, tFromUserInfo.nick)
			end
		end
    else
		TraceError("用户请求聊天类型非法");
    end
end

--发送个人聊天信息
function SendChatToUser(nType, toUserInfo, szMsg, nFromUserId, szFromUserNick)
    netlib.send(
		function(buf)
            buf:writeString("REDC")
            buf:writeByte(nType)                    --chat type
            buf:writeString(szMsg)                 --text
            buf:writeInt(nFromUserId or 0)       --user id
            buf:writeString(szFromUserNick)      --user name
            buf:writeByte(0)   --user site
        end
    , toUserInfo.ip, toUserInfo.port)
    
    szFromUserNick = string.trans_str(szFromUserNick)
    szMsg = string.trans_str(szMsg)
    if tex_speakerlib then
    	tex_speakerlib.record_chat_log(1, nFromUserId, szMsg, szFromUserNick)
    end
end

--广播桌面聊天信息
function onsenddeskchat(desk, ntype, msg, fromuserinfo)
    --TraceError("广播桌面聊天信息")
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("REDC")
            buf:writeByte(ntype)                    --desk chat
            buf:writeString(msg)                    --text
            buf:writeInt(fromuserinfo.userId)       --user id
            buf:writeString(fromuserinfo.nick)      --user name
            buf:writeByte(fromuserinfo.site or 0)   --user site
        end
    , desk, borcastTarget.all);
    
    local nick_name = string.trans_str(fromuserinfo.nick)
    if tex_speakerlib then
    	tex_speakerlib.record_chat_log(1, fromuserinfo.userId, msg, nick_name)
    end
end

function OnEcho(buf)
    local nTime = buf:readInt()
    local retFun = function(buf)
                        buf:writeString("ECHO")
                        buf:writeInt(nTime)
    end
    tools.FireEvent2(retFun, buf:ip(), buf:port())
end

----------------- 破产送钱放到大厅里 -------------------
--德州破产领救济啦
function OnRecvTexBankruptGiveGold (buf)
    local userKey = getuserid(buf) --得到哪个用户传来的key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local process_func = function()
        local givegold = room.cfg.gold_bankrupt_give_value   	  --破产赠送数额
        local give_count = userinfo.bankruptcy_give_count or 0  --破产赠送次数
        local give_time = userinfo.bankruptcy_give_time or 0    --最后赠送时间
        local mingold = room.cfg.gold_bankrupt_give_value  --TODO:上线必须修改为真实数字
    
        if userinfo.gamescore >= mingold  then 
        	return
        end
        
        if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
        	return
        end
    
        --今天开始时间
        local tbNow  = os.date("*t",os.time())
        local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})
    
        --如果超过最后日期是0或者是昨天的
        if(give_time == 0 or give_time < todaystart) then
           userinfo.bankruptcy_give_count = 1
        --如果是今天的
        else
            --超过赠送次数
            if(give_count >= room.cfg.gold_bankrupt_give_times) then
                return
            --还可以送
            else
                userinfo.bankruptcy_give_count = userinfo.bankruptcy_give_count + 1
            end
        end
        
        userinfo.bankruptcy_give_time= os.time()
    
        --更新数据库状态 
        local updatestr = format("give_count = %d, give_time = %d, remark = 'tex' ",userinfo.bankruptcy_give_count, userinfo.bankruptcy_give_time)
        dblib.execute(format(room.cfg.gold_bankrupt_updatesql, updatestr, userinfo.userId))
    
        --破产送钱的处理
        local addGold = givegold
        if(userinfo.gamescore < 0) then
            addGold = -userinfo.gamescore + addGold
        end
    
        --更新用户筹码数
        usermgr.addgold(userinfo.userId, addGold, 0, g_GoldType.bankruptcy, -1, 1)
        
        --通知客户
        local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
        local currtimes = userinfo.bankruptcy_give_count
        local totaltimes = room.cfg.gold_bankrupt_give_times
        --local msg = format("您成功领取了今日破产救济金$%d!每天 %d 次，今天第 %d 次!",givegold, totaltimes, currtimes)
        local msg = format(tex_lan.get_msg(userinfo, "h2_msg_givegold").."%d!"..tex_lan.get_msg(userinfo, "h2_msg_givegold_1").."%d 次，"..tex_lan.get_msg(userinfo, "h2_msg_givegold_2").."%d 次!",givegold, totaltimes, currtimes)
        OnSendServerMessage(userinfo, msgtype, _U(msg))
    end
    usermgr.after_login_get_bankruptcy_info(userinfo, 1, process_func)
end

--德州破产领救济啦
function OnBankruptAutoGiveGold (buf)
    local result=1
    local userKey = getuserid(buf) --得到哪个用户传来的key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local process_func = function()
        local givegold = room.cfg.gold_bankrupt_give_value   	  --破产赠送数额
        local give_count = userinfo.bankruptcy_give_count or 0  --破产赠送次数
        local give_time = userinfo.bankruptcy_give_time or 0    --最后赠送时间
        local mingold = room.cfg.gold_bankrupt_give_value  --TODO:上线必须修改为真实数字
    
        if userinfo.gamescore >= mingold  then 
        	result=-1
        end
        
        if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
        	result=-1
        end
    
        --如果有不能发救济金的情况，就直接告诉客户端
        if(result == -1) then 
            --TraceError("11.22德州破产领救济啦userinfo.bankruptcy_give_count:"..userinfo.bankruptcy_give_count)
            net_send_give_gold(userinfo, result, 0)
            return
        end
    
        --今天开始时间
        local tbNow  = os.date("*t",os.time())
        local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})
    
        --如果超过最后日期是0或者是昨天的
        if(give_time == 0 or give_time < todaystart) then
           userinfo.bankruptcy_give_count = 1
        --如果是今天的
        else
            --超过赠送次数
            if(give_count >= room.cfg.gold_bankrupt_give_times) then
                result=-1
            --还可以送
            else
                userinfo.bankruptcy_give_count = userinfo.bankruptcy_give_count + 1
            end
        end
    
        --如果有不能发救济金的情况，就直接告诉客户端
        if(result==-1)then
            net_send_give_gold(userinfo, result, 0)
            return
        end
        
        userinfo.bankruptcy_give_time= os.time()
    
        --更新数据库状态 
        local updatestr = format("give_count = %d, give_time = %d, remark = 'tex' ",userinfo.bankruptcy_give_count, userinfo.bankruptcy_give_time)
        dblib.execute(format(room.cfg.gold_bankrupt_updatesql, updatestr, userinfo.userId))
    
        --破产送钱的处理
        local addGold = givegold
        if(userinfo.gamescore < 0) then
            addGold = -userinfo.gamescore + addGold
        end
    
        --更新用户筹码数
        usermgr.addgold(userinfo.userId, addGold, 0, g_GoldType.bankruptcy, -1, 1)
        
        --通知客户
        local msgtype = userinfo.desk and 1 or 0 --1表示是游戏里处理的协议,0是大厅
        local currtimes = userinfo.bankruptcy_give_count
        local totaltimes = room.cfg.gold_bankrupt_give_times
        
        --告诉客户端执行结果
        net_send_give_gold(userinfo, result, currtimes)
    end
    usermgr.after_login_get_bankruptcy_info(userinfo, 1, process_func)
end

--救济金发送给客户端结果，第一个参数是是不是成功，第二个参数是救济金领取的次数
function net_send_give_gold(userinfo, result, timers)
    netlib.send(
        function(buf)
            buf:writeString("RQATGIVE")
            buf:writeByte(result)
            buf:writeByte(timers)
        end
    , userinfo.ip, userinfo.port)
end

--破产送钱
function OnRecvGiveGoldByBankrupt(buf)
    local userKey = getuserid(buf) --得到哪个用户传来的key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local minGold = 0
    if gamepkg and gamepkg.name == "tex" then  return end --现在德洲不需要送钱
    if(gamepkg and gamepkg.GetMinGold) then
        minGold = gamepkg.GetMinGold();
    end

    local nAddGold = 150  --金币增加数量
    if gamepkg and gamepkg.GetAddGold then nAddGold = gamepkg.GetAddGold() or 150 end

    --local szSql = format(tSqlTemplete.updateGold, nAddGold, userlist[userKey].userId)
	--dblib.execute(szSql)

	local userid = userlist[userKey].userId
	dblib.cache_get("users", "gold", "id", userlist[userKey].userId, function(dt)
		local userinfo =  usermgr.GetUserById(userid)
		if not userinfo then return end
		if #dt == 0 then return end
		if dt[1]["gold"] > minGold or minGold == 0 then
			userinfo.gamescore = dt[1]["gold"]
			net_send_user_new_gold(userinfo, userinfo.gamescore)
			return
		end

		--如果玩家连续发N次刷钱，数据库操作是异步的，所以钱可能会+N次，从这里进行判断可以防止重复+钱
		if userinfo.gamescore > minGold then
			net_send_user_new_gold(userinfo, userinfo.gamescore)
			return
		end

		nAddGold = nAddGold - dt[1]["gold"]
		dblib.cache_inc("users", {gold = nAddGold}, "id", userlist[userKey].userId)

		userinfo.gamescore = dt[1]["gold"] + nAddGold
		local szSendBuf = userinfo.userId..","..userinfo.gamescore --发送给gc服务中心消息
		tools.SendBufToUserSvr(getRoomType(), "STGB", "", "", szSendBuf) --发送数据到服务端，通知他更新有人送钱了。


		net_send_user_new_gold(userinfo, userinfo.gamescore)
		--todo: 这里的送钱日志没有，需要加上
	end)
end

function net_send_user_new_gold(userinfo, newgold)
	local sendFunc = function(buf)
		buf:writeString("REGB")
		buf:writeInt(tonumber(newgold))
        buf:writeByte(usermgr.check_user_get_bankruptcy_give(userinfo) or 0)  --是否可以领取破产救济
	end
	--TraceError(newgold)
	tools.FireEvent2(sendFunc, userinfo.ip, userinfo.port)
end

function OnRecvUserLeaveGame(buf)
    local szKey = getuserid(buf)
	if (userlist[szKey] == nil) then
		trace("OnRecvUserLeaveGame的时候用户信息不存在(userlist[szKey])!")
        return
    end
    local nUserId = userlist[szKey].userId
    if (nUserId == nil) then
		TraceError("OnRecvUserLeaveGame的时候用户不存在(id)!")
        return
    end
    tools.SendBufToUserSvr(getRoomType(), "NTUL", "", "", tostring(nUserId))
end

function OnRecvUserEnterGame(buf)
    local szKey = getuserid(buf)
    local nUserId = userlist[szKey].userId
    if (nUserId == nil) then
        return
    end
    tools.SendBufToUserSvr(getRoomType(), "NTUE", "", "", tostring(nUserId))
end

----------------------------------------------------------------------------
--用户道具相关的usermgr
--设置用户BUFF
usermgr.setbuff = function(buffinfo,userinfo)
    userinfo.buff = buffinfo
end

--得到用户的Buff
usermgr.getbuff = function(userinfo)
    if(userinfo.buff == nil) then
        userinfo.buff = {}
    end
    return userinfo.buff
end
-------------------------------------------------------------------------
--道具系统数据结构
--[[
    系统items配置表定义
        itemlib.items = {
            [1] = {
                id = id,                 --道具ID
                main_class = main_class, --主分类
                sub_class = sub_class,   --子分类
                price = price,           --价格
                name = name,             --名称
                buffs_id = {}               --增益效果集合,对应bufflib.buffs的ID
            },
            [2] = {

            },
        }
    系统buff配置表定义
        bufflib.buffs = {
            [1] = {
                id =   --ID
                buff_time = 增益持续时间/秒
                class = - 1:荣誉翻倍， 2：声望翻倍， 3：荣誉清0
                cd_class = --  0:无冷却  1：每日0:00点冷却

            }
            [2]...
            .....
        }

    用户的buff定义（userinfo.buff){
        [class] = {    --增益类别,
             start_time  = 使用时间，
             over_time = 过期时间
             cd_class = CD类别， --  0:无冷却  1：每日0:00点冷却
             give_nick = ""
             give_userid
        },
    }
]]
-------------------------------------------------------------------------
---------------------- BUFF模块（商城系统) ------------------------------
if not bufflib then
    bufflib = {
        --相关SQL
        sql = {
            get_user_buff = "insert ignore into user_buff(user_id, buff_info) values(%d,concat('')); commit; "..
                            "select buff_info from user_buff where user_id = %d;",
            update_user_buff = "update user_buff set buff_info = %s where user_id = %d;",
            get_buffs = "select * from configure_buff",
        },
        --BUFF LIST 从数据库中拿到
        buffs = {},

        --效果class
        CLASS_INFO = {
            ["DOUBLE_INTEGRAL"] = 1,    --class = 1 为 双倍积分
            ["DOUBLE_PRESTIGE"] = 2,    --class = 2 为 双倍声望
            ["ZERO_INTEGRAL"] = 3,      --class = 3 为 积分清0
            ["DOUBLE_INTEGRAL2"] = 4,   --class = 4 为 积分双倍，正的 * 2,负的 * 1
        },
        --cd类别
        CD_CLASS = {
            ["EVERYDAY"] = 1,
            ["NOCD"]     = 0,
        },

        --函数列表
        get_user_using_buff = NULL_FUNC, --得到某用户正在使用的buff
        get_user_buff = NULL_FUNC,      --用户登陆从DB读入内存
        update_user_buff = NULL_FUNC,   --修改时写入DB
    }

     --从数据库中读出BUFF相关信息
	timelib.createplan(function()
        dblib.execute(string.format(bufflib.sql.get_buffs),
				function(dt)
					for i = 1, #dt do
						local bufftable = {
                            id = tonumber(dt[i].id),  --ID
                            buff_time = tonumber(dt[i].buff_time), --buff_time: 增益持续时间/秒
                            class = tonumber(dt[i].class), -- 1:荣誉翻倍， 2：声望翻倍， 3：荣誉清0
                            cd_class = tonumber(dt[i].cd_class), --  0:无冷却  1：每日0:00点冷却
                        }
                        table.insert(bufflib.buffs, bufftable)
                    end
				end
			)
        end,
    2)
end

--用户登陆从DB读入内存
bufflib.get_user_buff = function(user_id)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then TraceError("读入BUFF进DB UserInfo为空？") return end

    dblib.execute(string.format(bufflib.sql.get_user_buff, user_id, user_id),
        function(dt)
            if(dt and #dt > 0) then
                usermgr.setbuff(table.loadstring(dt[1].buff_info),userinfo)
            end
        end
    )
end

--得到用户使用中的buff
bufflib.get_user_using_buff = function(userinfo)
    local using_buffs = {}      --正在生效的buffs
    local userbuff = usermgr.getbuff(userinfo)

    for k, v in pairs(userbuff) do
        if(os.time() < v.over_time) then
            table.insert(using_buffs, k)
        end
    end
    return using_buffs
end

--修改BUFF时写入DB
bufflib.update_user_buff = function(user_id)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then TraceError("修改BUFF时写入DB UserInfo为空？") return end

    --写入数据库更新
    dblib.execute(string.format(bufflib.sql.update_user_buff, dblib.tosqlstr(table.tostring(userinfo.buff)), user_id));
end


--新增一个buff到用户
--user_id: 用户ID
--buff_time: 增益持续时间/秒
--class: buff类别
--1:荣誉翻倍， 2：声望翻倍， 3：荣誉清0
--cd_class: 冷却类型
--[[  0:无冷却  1：每日0:00点冷却   ]]
bufflib.add_new_buff_touser = function(user_id, buff_id, myuserinfo)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then return end

    --构造user的BUFFINFO,数据结构遵循上述说明
    local itembuff = bufflib.buffs[buff_id]
    if(not itembuff) then return end

    local buffinfo = {
        start_time = os.time(),
        over_time =  os.time() + itembuff.buff_time,
        cd_class = itembuff.cd_class,
        give_nick = myuserinfo.nick,
        give_userid = myuserinfo.userId,
    }

    --放BUFF到用户里
    usermgr.getbuff(userinfo)[itembuff.class] = buffinfo

    --BUFF结束计划
    if(itembuff.buff_time <= 0) then return end
    local endplan = timelib.createplan(
        function()
            local newuserinfo =  usermgr.GetUserById(user_id)
	        if(newuserinfo) then
            	--发送buff信息
            	net_broadcast_buff_change(newuserinfo)
	        end
        end
    , itembuff.buff_time + 2)
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------
----------------------------- 商城模块 ----------------------------------
if not itemlib then
    itemlib = {
        --相关SQL
        sql = {
            get_items = "select * from configure_items",
            log_buy_item = "insert into log_buy_item (item_id, user_id, to_user_id, sys_time, before_gold, after_gold) values (%d, %d, %d, %s, %d, %d)",
        },

        --物品信息
        items = {},

        --物品用途
        ITEM_USEFOR = {
            ["DOUBLE_INTEGRAL"] = 1,    --item_id = 1 为 双倍积分
            ["DOUBLE_PRESTIGE"] = 2,    --item_id = 2 为 双倍声望
            ["ZERO_INTEGRAL"] = 3,      --item_id = 3 为 积分积分
			["MICRO_LOUDSPEAKER"] = 4,  --item_id = 4 为 小喇叭
            ["DOUBLE_INTEGRAL2"] = 5,  --item_id = 5 为 双倍积分
        },
        --函数列表
        new_items = NULL_FUNC,  --新建item
        buy_item  = NULL_FUNC,  --购买
        send_shop_items = NULL_FUNC, --发送商店物品
        can_buy_item = NULL_FUNC,   --可否买物品
        use_integral_zero = NULL_FUNC, --使用积分清0卡
    }

    --从数据库中读出物品相关信息
	timelib.createplan(function()
        dblib.execute(string.format(itemlib.sql.get_items),
				function(dt)
					for i = 1, #dt do
						itemlib.new_items(
							dt[i].id,
							dt[i].main_class,
							dt[i].sub_class,
							dt[i].price,
							dt[i].name,
							dt[i].buffs_id
						)
                    end
				end
			)
        end,
    2)
end

--新建item
itemlib.new_items = function(id, main_class, sub_class, price, name, buffs_id)
    local item = {
        id = tonumber(id),                 --道具ID
        main_class = tonumber(main_class), --主分类
        sub_class = tonumber(sub_class),   --子分类
        price = tonumber(price),           --价格
        name = name,                       --名称
        buffs_id = split(buffs_id, "|"),    --效果集合
    }

    for i = 1, #item.buffs_id do
        item.buffs_id[i] = tonumber(item.buffs_id[i])
    end
    --插入itemlib.items
    table.insert(itemlib.items, item)
end

--根据玩家属性决定是否能购买
--[[
    -1:正在使用
    -2:没CD
    1：可以购买
]]
itemlib.can_buy_item = function(userinfo, item_id)
    local userbuff = usermgr.getbuff(userinfo)
    local using_buffs = bufflib.get_user_using_buff(userinfo)
    local notcd_buffs = {}      --还未cd的buffs
    local iteminfo = itemlib.items[item_id]

    if(iteminfo == nil) then return 0 end

    --荣誉清0卡，写死了
    if(item_id == itemlib.ITEM_USEFOR["ZERO_INTEGRAL"]) then
        if(usermgr.getintegral(userinfo) >= 0) then
            return -3 --返回-3，无需使用
        end
    end



    --[[
	--喇叭类
	if item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
        --斗地主积分场喇叭类已经没有会员限制。
        if gamepkg.name == "dznew" then
            return 1
        end
		if not (viplib and viplib.check_user_vip(userinfo)) then
            if( gamepkg.name ~= "dznew")
			return -4 --返回-4，非会员不能使用
		end
	end
    ]]

    --得到用户正在使用的buffs和还未cd的buffs
    for k, v in pairs(userbuff) do
        --不在使用中
        if(os.time() >= v.over_time) then
            --如果buff是每日刷新，而且还没到cd时间
            if(v.cd_class == bufflib.CD_CLASS.EVERYDAY) then
                --如果今天0：00以后用过了，就不能再用
                if(get_today_start_ostime() < v.start_time) then
                    table.insert(notcd_buffs, k)
                end
            end
        end
    end
    for k, v in pairs(iteminfo.buffs_id) do
        local item_buff_class = bufflib.buffs[v].class
        --去看每个道具的buff是不是用户正在使用，如果正在使用或未CD，则该道具定义为无法使用状态
        if(item_buff_class and item_buff_class > 0) then
            --该BUFF是不是用户正在使用
            for i, j in pairs(using_buffs) do
                if(j == item_buff_class) then
                    return -1   --返回-1，正在使用
                end
            end
            --该BUFF是否未CD?
            for i, j in pairs(notcd_buffs) do
                if(j == item_buff_class) then
                    return -2   --返回-2，物品还未CD
                end
            end
        end
    end
    return 1
end

--购买事件处理
itemlib.buy_item = function(myuserinfo, touserinfo, item_id, tag)

    --看道具是否存在
    if(itemlib.items[item_id] == nil) then return end

    --看道具是否达到使用条件
    if(itemlib.can_buy_item(touserinfo, item_id) <= 0) then return end

	--如果赠送喇叭  （喇叭是不能赠送的）
	if myuserinfo ~= touserinfo and item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
		return
	end

    local iteminfo = itemlib.items[item_id]
    local nsuccess = 0
    
	local price = iteminfo.price
    --去掉VIP的的优惠
    --[[
    	if viplib and viplib.check_user_vip(myuserinfo) then
    		price = math.floor(price * 0.9)
        end 
    --]]

    --看玩家金币是否足够
	if(price <= myuserinfo.gamescore and can_user_afford(myuserinfo,price)) then
        local before_gold = myuserinfo.gamescore
        --更改用户金币，注意是负数，扣钱的
        usermgr.addgold(myuserinfo.userId, -price, 0, g_GoldType.buy, -1)
        --写入道具购买日志

        local actionSql = string.format(itemlib.sql.log_buy_item,item_id,
                                        myuserinfo.userId,
                                        touserinfo.userId,
                                        dblib.tosqlstr(os.date("%Y-%m-%d %X", os.time())),
                                        before_gold,
                                        myuserinfo.gamescore);
        dblib.execute(actionSql)

        --不是自己使用，记录赠送日志
        --TODO
        --if(myuserinfo.userId ~= touserinfo.userId) then

        --end

		
        --更改用户buff状态
        local userbuff = usermgr.getbuff(touserinfo)
        for k, v in pairs(iteminfo.buffs_id) do
            bufflib.add_new_buff_touser(touserinfo.userId, v, myuserinfo)
        end
        nsuccess = 1
         --写入buff
        bufflib.update_user_buff(touserinfo.userId)
        --发送购买道具结果
        net_send_buy_item(myuserinfo, nsuccess)

        --写死ID=3是荣誉清0卡，立即生效
        if(item_id == itemlib.ITEM_USEFOR["ZERO_INTEGRAL"]) then
            itemlib.use_integral_zero(touserinfo)
        end

        --发送buff信息
        net_broadcast_buff_change(touserinfo)

        --刷新商店状态
        itemlib.send_shop_items(myuserinfo, touserinfo)
    else

        --发送购买道具结果
        net_send_buy_item(myuserinfo, nsuccess)
        --斗地主积分场,不需要更新商店状态
    	if item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
            --斗地主积分场喇叭类已经没有会员限制。
            if gamepkg.name == "dznew" then
                return
            end
    	end
        --刷新商店状态
        itemlib.send_shop_items(myuserinfo, touserinfo)
    end
end

--发送商店商品
itemlib.send_shop_items = function(myuserinfo, touserinfo)
    local userbuff = usermgr.getbuff(touserinfo)
    local send_item_info = {}
	local items =  table.clone(itemlib.items)

	--根据正在生效的buffs 和 还未cd的buffs，改变道具的一些属性，是否可用
	for k, v in pairs(items) do
        v.using = 0
        v.nocd = 0
        v.noneed = 0
		v.novip = 0

        local can_buy_result = itemlib.can_buy_item(touserinfo, v.id)
        if(can_buy_result == -1) then
            v.using = 1
        elseif(can_buy_result == -2) then
            v.nocd = 1
        elseif(can_buy_result == -3) then
            v.noneed = 1
		elseif(can_buy_result == -4) then
			v.novip = 1
        end

		--如果不是赠送喇叭  （喇叭是不能赠送的）
        --过滤掉4号道具，4号道具不能再商店买
		if (not(myuserinfo ~= touserinfo and v.id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"])) and
            (v.id ~= itemlib.ITEM_USEFOR["DOUBLE_INTEGRAL2"]) then
			send_item_info[k] = v
		end
    end
    --通知客户端商店道具信息
    net_send_shop_item_list(myuserinfo,touserinfo, send_item_info)
end

--使用积分清0卡
itemlib.use_integral_zero = function(userinfo)
    --更改玩家积分
    if(usermgr.getintegral(userinfo) < 0) then
        usermgr.addintegral(userinfo.userId, -usermgr.getintegral(userinfo))
        return 1
    end
    return 0
end

------------------------------------------------------------------------------------
----------------------------------- 道具部分协议 -----------------------------------
------------------------------------------------------------------------------------
--得到今天0：00的OSTIME
function get_today_start_ostime()
    local today_table = os.date("*t", os.time())
    return os.time({year = today_table.year, month=today_table.month, day = today_table.day, hour= 0,min=0,sec=0})
end

--收到请求道具列表
function on_recv_shop_item_list(buf)
    local myuserinfo = userlist[getuserid(buf)]
    local to_userid = buf:readInt()
    local touserinfo = usermgr.GetUserById(to_userid)
    if(not touserinfo or not myuserinfo) then return end

    itemlib.send_shop_items(myuserinfo, touserinfo)
end

--收到购买道具
function on_recv_buy_item(buf)
    --TraceError("--收到购买道具")
    local myuserinfo = userlist[getuserid(buf)]
    local request_item_id = buf:readInt()
    local to_userid = buf:readInt()
	local tag = buf:readString()
    local touserinfo = usermgr.GetUserById(to_userid)

    if(not myuserinfo or not touserinfo) then return end
    itemlib.buy_item(myuserinfo, touserinfo, request_item_id, tag)
end


--收到刷新用户buff
function on_recv_user_buff(buf)
    local userinfo = userlist[getuserid(buf)]
    net_broadcast_buff_change(userinfo)
end

--发送购买道具结果
function net_send_buy_item(userinfo, nsuccess)
    netlib.send(
		function(buf)
			buf:writeString("ITEMBUY")
            buf:writeInt(nsuccess)
        end
    , userinfo.ip, userinfo.port)
end

--通知用户buff发生改变
function OnSendUserBuffChange(userinfo, changeuserinfo)
	if not userinfo or not changeuserinfo then return end

    local userbuff = usermgr.getbuff(changeuserinfo)
    netlib.send(
        function(buf)
            buf:writeString("BUFFCHANGE")
            buf:writeInt(changeuserinfo.userId)
            buf:writeInt(changeuserinfo.site and changeuserinfo.site or 0)
            --只发送生效的buff
            local buffnum = 0
            for k, v in pairs(userbuff) do
                if(v.over_time > os.time()) then
                    buffnum = buffnum + 1
                end
            end
            buf:writeInt(buffnum)
            for k, v in pairs(userbuff) do
                if(v.over_time > os.time()) then
                    buf:writeInt(k)     --class
                    buf:writeInt(os.time())
                    buf:writeInt(v.over_time) --过期时间
                    buf:writeInt(v.cd_class)  --冷却类型
                    buf:writeInt(v.give_userid)
                    buf:writeString(v.give_nick)
                end
            end
        end
    , userinfo.ip, userinfo.port)
end

--通知桌内所有玩家某玩家的声望信息()
function net_broadcast_buff_change(userinfo)
    if not userinfo then return end
    --通知桌内玩家
    local deskno = userinfo.desk
    --没有桌子号，只发给自己
    if(not deskno) then
        OnSendUserBuffChange(userinfo, userinfo)
        return
    end

    --通知桌子上所有人
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserBuffChange(playingUserinfo, userinfo)
            end
            if(playingUserinfo == nil) then
                TraceError("用户坐下时桌子上有个用户的userlist信息为空2")
                hall.desk.clear_users(deskno, i)
            end
        end
    end
    
    local deskinfo = desklist[deskno] 
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if (watchinginfo and watchinginfo.offline ~= offlinetype.tempoffline) then
            OnSendUserBuffChange(watchinginfo, userinfo)
        end
        if(watchinginfo == nil) then
            deskinfo.watchingList[k] = nil
        end
    end
end


--发送商店道具列表
function net_send_shop_item_list(userinfo, touserinfo, send_item_info)
	netlib.send(
		function(buf)
			buf:writeString("SPITEMLIST")
            buf:writeInt(touserinfo.userId)
            local itemcount = 0
            for k, v in pairs(send_item_info) do
                itemcount = itemcount + 1
            end
            buf:writeInt(itemcount)         --道具数量
            for i = 1, itemcount do
                buf:writeInt(send_item_info[i].id)             --道具ID
                buf:writeInt(send_item_info[i].main_class)     --主分类
                buf:writeInt(send_item_info[i].sub_class)      --子分类
                buf:writeInt(send_item_info[i].price)          --价格

                local buffcount = 0
                for k, v in pairs(send_item_info[i].buffs_id) do
                    buffcount = buffcount + 1
                end
                buf:writeInt(buffcount)        --产生效果数量

                for j = 1, buffcount do
                    local buffid = send_item_info[i].buffs_id[j]
                    buf:writeInt(buffid)                            --效果ID
                    buf:writeInt(bufflib.buffs[buffid].buff_time)   --效果持续时间
                    buf:writeInt(bufflib.buffs[buffid].class)       --效果类别（1:荣誉翻倍， 2：声望翻倍， 3：荣誉清0)
                    buf:writeInt(bufflib.buffs[buffid].cd_class)    --冷却类型（0：无CD，1：每日0：00 CD)
                end

                buf:writeInt(send_item_info[i].using)  --是否正在使用
                buf:writeInt(send_item_info[i].nocd)   --是否还未CD
                buf:writeInt(send_item_info[i].noneed)   --是否无需使用
				buf:writeInt(send_item_info[i].novip)   --是否非会员导致不能使用
            end
			local user_vip_level = 0
			if viplib and viplib.check_user_vip(userinfo)  then
				local vipinfo = viplib.get_user_vip_info(userinfo)
				user_vip_level = vipinfo.vip_level
			end
			buf:writeInt(user_vip_level)
		end
	, userinfo.ip, userinfo.port)
end
--收到客户端GM控制发牌
function on_recv_gm_control_fapai(buf)
    if is_allow_gm_control_fapai() == 0 then
        TraceError(" 非法控制出牌 ")
        return
    end
    if gamepkg.porcess_gm_control_fapai then
        gamepkg.porcess_gm_control_fapai(buf)
    end
end
function on_send_friends_rank(userinfo, friends_rank)
    --TraceError(friends_rank)
    netlib.send(
        function(buf)
            buf:writeString("FRRANK")
            buf:writeInt(#friends_rank)
            for i = 1, #friends_rank do
                buf:writeInt(friends_rank[i]["id"])
                buf:writeInt(friends_rank[i]["gold"])
                buf:writeInt(friends_rank[i]["integral"])
                buf:writeInt(friends_rank[i]["prestige"])
                buf:writeString(friends_rank[i]["nick_name"])
                buf:writeString(friends_rank[i]["face"])
            end
        end, userinfo.ip, userinfo.port)
end

--收到好友排行请求
function on_recv_friend_rank(buf)
    local userinfo = userlist[getuserid(buf)]

     --得到好友列表
	 --暂时屏蔽SNS好友列表snsfriends
    local get_friend_sql = "select CONCAT(friends) as friends from user_friends where user_id = %d";
    local get_rank_sql = "select b.integral,b.prestige,a.id,a.nick_name,a.sex, a.user_name,concat(face) as face,a.reg_site_no,a.gold from" ..
				" (select experience,prestige,integral,last_win,last_lose, recent_date,last_date,recent_win, recent_lose, userid from ".. gamepkg.table ..
                " where userid in (%s)) b, users a where a.id = b.userid";

    dblib.execute(string.format(get_friend_sql, userinfo.userId), function(dt)
        if(#dt > 0 and dt[1]["friends"]) then
            local friend_list = split(dt[1]["friends"], "|")
            --拼写查询SQL
            local idstr = ""
            for k, v in pairs(friend_list) do
                if(v and v ~= "") then
                    idstr = idstr .. v .. ","
                end
            end
            idstr = idstr .. userinfo.userId

            --取得好友排行
            local friends_rank = {}
            dblib.execute(string.format(get_rank_sql, idstr), function(rankdt)
                for k, v in pairs(rankdt) do
                    local tb = {}
                    tb["face"] = v.face
                    tb["id"] = v.id
                    tb["prestige"] = v.prestige
                    tb["sex"] = v.sex
                    tb["nick_name"] = v.nick_name
                    tb["gold"] = v.gold
                    tb["integral"] = v.integral
                    table.insert(friends_rank, tb)
                end

                on_send_friends_rank(userinfo, friends_rank)
            end)
        end
    end)
end
--计算VIP会员额外加的奖励
function calc_vip_add_gold(userinfo)
    --VIP额外加钱
    local addgold = 0
    if viplib and viplib.check_user_vip(userinfo) then
        local vip_info = viplib.get_user_vip_info(userinfo)
        for _,v in pairs(vip_info) do
            if(timelib.db_to_lua_time(v.over_time) > os.time()) then
                addgold = addgold + (viplib.add_day_gold[v.vip_level] or 0)
            end
        end
    end

    return addgold
end

function on_recv_daygold_give(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then return end
    if usermgr.getlevel(userinfo) < 1 then return end
    
    local result = 0
    local gold = 0
    local vipadd = 0
    local charmadd = 0
    local charmlevel = userinfo.charmlevel or 0
    if userinfo.cangivedaygold and userinfo.cangivedaygold == 1 then
        userinfo.cangivedaygold = nil --清空
        result = 1
        gold = 500 --math.random(tSqlTemplete.CONFIG.MINGIVE,tSqlTemplete.CONFIG.MAXGIVE)  --改为只送500 by lch
        vipadd = calc_vip_add_gold(userinfo)
        charmadd = userinfo.charmgold or 0
        usermgr.addgold(userinfo.userId, gold, 0, g_GoldType.daygive, -1)--送钱啦
        usermgr.addgold(userinfo.userId, vipadd, 0, g_GoldType.vipdaygive, -1)--每天VIP加成送钱
        usermgr.addgold(userinfo.userId, charmadd, 0, g_GoldType.charmdaygive, -1)--每天魅力加成送钱
        --写入数据库
        dblib.execute(string.format(tSqlTemplete.check_daygold_cangive,userinfo.userId,dblib.tosqlstr(userinfo.ip),tSqlTemplete.CONFIG.LIMITNUM,1))
    end
    --给五道杠昨天完成任务的人发钱
    local success, quest_gold, wing_level, wing_gold;
    if (tex_dailytask_lib) then
        success, quest_gold=xpcall(function() return tex_dailytask_lib.add_yesterday_questgold(userinfo) end,throw)
    end

    if(wing_lib) then
        success, wing_level, wing_gold = xpcall(function() return wing_lib.add_wing_level_gold(userinfo.userId) end, throw);
    end

    netlib.send(
        function(buf)
            buf:writeString("REDAYGOLD")
            buf:writeByte(result)
            buf:writeInt(gold)
            buf:writeInt(vipadd)
            buf:writeInt(charmlevel)
            buf:writeInt(charmadd)
            buf:writeInt(quest_gold or 0)
            buf:writeInt(wing_level or 0);
            buf:writeInt(wing_gold or 0);
        end,userinfo.ip,userinfo.port)
end

--检查每日登陆送钱是否合法
function give_daygold_check(userinfo)
    if not userinfo then return end
    if usermgr.getlevel(userinfo) < 1 then 
		netlib.send(
                    function(buf)
                        buf:writeString("SHOWDAYGOLD")
                        buf:writeInt(0)
                        buf:writeInt(0)  --最高VIP等级
                        buf:writeInt(0)  --VIP加成
                    end,userinfo.ip,userinfo.port)
		return
	end
    
    dblib.execute(string.format(tSqlTemplete.check_daygold_cangive,userinfo.userId,dblib.tosqlstr(userinfo.ip),tSqlTemplete.CONFIG.LIMITNUM,0),--10是限制最多用户
        function(dt)
            if dt and #dt > 0 then
                --1显示领奖，-1显示不能领奖    
                userinfo.cangivedaygold = tonumber(dt[1]["result"])
                if not userinfo.cangivedaygold then userinfo.cangivedaygold = 0 end
                --VIP额外加钱
                local VIPadd = calc_vip_add_gold(userinfo)
                local max_VIP_Level = -1
                if viplib and viplib.check_user_vip(userinfo) then
                    local vip_info = viplib.get_user_vip_info(userinfo)
                    for _,v in pairs(vip_info) do
                        if(timelib.db_to_lua_time(v.over_time) > os.time()) then
                            if(max_VIP_Level < v.vip_level) then max_VIP_Level = v.vip_level end
                        end
                    end
                end
                netlib.send(
                    function(buf)
                        buf:writeString("SHOWDAYGOLD")
                        buf:writeInt(userinfo.cangivedaygold)
                        buf:writeInt(max_VIP_Level)  --最高VIP等级
                        buf:writeInt(VIPadd)  --VIP加成
                    end,userinfo.ip,userinfo.port)
            else            	 
                TraceError("检查查询玩家能否送钱数据异常")
            end
        end)
end

--隐藏反馈系统功能
function on_recv_show_freeback(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then return end
    
    local result = 1
    --2011年4月1日前，每晚0：00  -- 次日早上10：00，屏蔽德州里的反馈系统。
    local curtime = os.time();
    local endtime = os.time{year = 2011, month = 4, day = 1,hour = 0};
    local tdate = os.date("*t", curtime);
    if(curtime < endtime) then
        if(tdate.hour >= 0 and tdate.hour < 10)then
            result = 0;
        end
    end

    netlib.send(
        function(buf)
            buf:writeString("SHOWFEEDBK")
            buf:writeByte(result)  --返回是否可以使用反馈系统:0不可以，1可以
        end,userinfo.ip,userinfo.port)
end

--收到查询玩家历史最高充值金额
function on_recve_quest_user_maxpay(buf)
	--TraceError("on_recve_quest_user_maxpay()")
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end;

    local SendFun = function(history_maxpay)
        netlib.send(
            function(buf)
                buf:writeString("REHISMPAY");
                buf:writeInt(history_maxpay);
            end,userinfo.ip,userinfo.port)
    end

    if(userinfo.history_maxpay ~= nil)then
        SendFun(userinfo.history_maxpay);
    else
    	dblib.execute(format("select * from user_max_chongzhi where user_id = %d", userinfo.userId),
    		function(dt)
    			if dt then
                    if(dt[1] ~= nil)then
                        userinfo.history_maxpay = tonumber(dt[1]["max_rmb"]);
                    end
                else
                    TraceError("ERROR:table user_max_chongzhi not exists!");
                end
                if not userinfo.history_maxpay then
                    userinfo.history_maxpay = 0;
                end
                --下发客户端
                SendFun(userinfo.history_maxpay);
    		end)
    end
end

--客户端查询是否显示是否需要显示角色选择面板
--直接返回给客户端
function on_recve_show_authorbar(userinfo)
  --  TraceError("on_recve_show_authorbar:::");
    local usersex=-1;--1=>男，0=>女，异常=>-1
    local showflag=0;--0不显示面板 ，1显示面板
    local nickname="";
  
	if(userinfo ~= nil) then 
        usersex = userinfo.sex;
        if(userinfo.nick~=nil) then
            nickname=userinfo.nick;
        end

    end
 

    if (nickname==nil or nickname == "") then
        showflag=1;
    else
        showflag=0;
    end


    netlib.send(
            function(buf)
                buf:writeString("TEXAUTHORBAR")
                buf:writeByte(showflag)  --是否显示
                buf:writeByte(usersex)
                buf:writeString(_U(nickname))              
            end,userinfo.ip, userinfo.port)
end



--更新用户昵称
function on_recve_update_usernick(buf)
	local _tosqlstr = function(s) 
		s = string.gsub(s, "\\", " ") 
		s = string.gsub(s, "\"", " ") 
		s = string.gsub(s, "\'", " ") 
		s = string.gsub(s, "%)", " ") 
		s = string.gsub(s, "%(", " ") 
		s = string.gsub(s, "%%", " ") 
		s = string.gsub(s, "%?", " ") 
		s = string.gsub(s, "%*", " ") 
		s = string.gsub(s, "%[", " ") 
		s = string.gsub(s, "%]", " ") 
		s = string.gsub(s, "%+", " ") 
		s = string.gsub(s, "%^", " ") 
		s = string.gsub(s, "%$", " ") 
		s = string.gsub(s, ";", " ") 
		s = string.gsub(s, ",", " ") 
		s = string.gsub(s, "%-", " ") 
		s = string.gsub(s, "%.", " ") 
		return s 
	end
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local v_nickname=buf:readString();
    local v_sex=buf:readByte();
    local face = "face/1001.jpg"
    local errMsg = "" 	--更新错误信息
    local isSucc = 0	--是否更新成功：1，成功；0，失败
    if (v_sex == 0) then
        face = "face/1001.jpg"    
    else
        face = "face/1.jpg"
    end
    v_nickname=_tosqlstr(v_nickname);
    
    if(texfilter) then
	    if(texfilter.is_exist_pingbici(v_nickname))then
	    	--errMsg = "包含敏感词汇，请重新输入"
	    	errMsg = tex_lan.get_msg(userinfo, "h2_msg_err_1");
        else
	       userinfo.nick=v_nickname
	       userinfo.sex=v_sex
	       userinfo.imgUrl=face
	       dblib.cache_set("users", {nick_name=v_nickname,sex=v_sex,face=face}, "id", userinfo.userId);
	       isSucc = 1
	       --errMsg = "更新成功，重新登录生效"
	       errMsg = tex_lan.get_msg(userinfo, "h2_msg_err_2");
	    end 
	   
	    netlib.send(
	        function(buf)
	            buf:writeString("TEXUSERNICK")  --写协议头
	            buf:writeByte(isSucc)
	            buf:writeString(_U(errMsg))
                buf:writeString(userinfo.nick or "")
                buf:writeByte(userinfo.sex or 0)
                buf:writeString(userinfo.imgUrl or "")
	        end
    	, userinfo.ip, userinfo.port);
	    
	end
 
end

--更新用户频道信息
function on_recve_update_channel(buf)
   -- TraceError("on_recve_update_channel");
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end;
    local v_channel=buf:readString();
    if (v_channel==nil or v_channel=="" or v_channel == "-1" or v_channel=="yygame") then return end;
    
    local sql = "INSERT IGNORE INTO user_channel_info(user_id,channel_id,sys_time)VALUE(%d,'%s',NOW());COMMIT;";
    sql = string.format(sql,userinfo.userId,v_channel);
    dblib.execute(sql);

end
--收到保存用户授权码
function on_recve_keep_tocken(buf)
	local user_info = userlist[getuserid(buf)];
	local user_tocken = buf:readString();
	if user_info == nil or user_tocken == nil or user_tocken == "" or user_info.init_keep_tocken ~= nil then return end;
	user_info.init_keep_tocken = 1;
	--只要保存第一次登陆的
	local sql = "INSERT IGNORE INTO dw_user_tocken VALUE (%d, %s);COMMIT;";
	sql = string.format(sql, user_info.userId, dblib.tosqlstr(user_tocken));
	dblib.execute(sql);
end

--得到某个全局参数值
function get_param_value(param_key,call_back)
   -- TraceError("get_param_value");
   if(call_back==nil) then return end;
    dblib.cache_get("cfg_param_info","param_value","param_key",param_key,
    			function(dt)
                    if dt and #dt > 0 then
                        call_back(dt[1]["param_value"]);
                    else
                        TraceError("读取数据失败cfg_param_info")
                    end
                end)
end

--游戏结算事件
if (on_game_over_event ~= nil) then
    eventmgr:removeEventListener("game_event", on_game_over_event)
end

on_game_over_event = function(e)
    for k, v in pairs(e.data) do
        local user_info =  usermgr.GetUserById(v.userid);
        if user_info~=nil then
        	eventmgr:dispatchEvent(Event("on_game_over_event", {user_info = user_info, is_win = v.iswin, win_gold = v.wingold}))
        end
    end
end

eventmgr:addEventListener("game_event", on_game_over_event)

--更新某个全局参数值
function set_param_value(param_key,param_value)
   -- TraceError("set_param_value");
    dblib.cache_set("cfg_param_info", {param_value=param_value}, "param_key", param_key);
end



---------------------------------------------------------------------------------
hall.init_map = function()
	--log("开始 大厅 命令初始化，必须全局在重载代码的时候执行")
	cmdHandler = {
	
	["RQCK"] = onsendrqck,              --要求客户端提供会话密钥
	["RECK"] = onrecvreck,              --客户端响应会话密钥
	["CKOK"] = onsendckok,              --告诉客户端密钥验证成功
	["VCOF"] = onclientoffline,         --收到某用户离线消息
	["NTOF"] = onnotifyoffline,         --发送某用户离线通知
    
	["RQSD"] = onrecvrqsitdown,         --客户端请求坐到某座位上
	
    --排队相关
    ["RQAJ"] = onrecvrAutoJoin,       --用户请求自动加入游戏
	["RQDQ"] = onrecvrqDeskQueue,       --收到某用户请求排队
	["NTQC"] = onnotifyDeskQueuePlayer, --广播现在排队中的用户总数
	["RQCQ"] = onRecvCancelQueue,       --收到某用户取消排队
	
	["RQSU"] = onrecvstandup,           --用户请求站起来
    ["RQBH"] = onrecvsbacktohall,       --用户请求回大厅
	
	["RQLG"] = onrecvlogin,           --有人开始登录
	["MOBLOGIN"] = on_mobile_login,    --有人用手机登录
	
	["RETT"] = OnRecvNetworkCheck,    --侦测用户网络状况
	
	["IMBT"] = onrecviamrobot,        --表明机器人身份

	['NTLG'] = OnNotifyLogin,        --玩家登录

    ["RQDS"] = OnQuestDeskList,    --请求桌子列表
    ["SDDU"] = OnRequireDeskUser,    --请求桌子里的玩家列表
	['RQCLR'] = OnClientLeaveRoom,		-- 客户端通知玩家离开牌桌大厅（进入牌桌打牌，或者离开牌桌大厅到房间大厅）
	['RQRSL'] = OnRequireRoomSortList,   --请求当前房间用户排名
	['RQASL'] = OnRequireRoomUserList,   --请求当前房间玩家列表
	
	['RQCF'] = OnChangeFace,        --修改头像
	['RAAF'] = on_active_extra_face, --激活特殊头像
	['RAHD'] = on_recv_select_head_info, --请求显示头像列表信息
	['NTUM'] = OnNotifyChangeGold,        --通知金币发生变化
	["SDOU"] = OnStatisticsOnline, --统计当前在线人数信息
	["RQOC"] = OnRecevOnlineCount, --收到客服端是在线人数查询
	["SDNO"] = OnNotifyOnlineUsers, --更新在线人数信息
	["RQOS"] = OnQuestServerCount, --请求得到服务器的人数

	["GMSK"] = OnStrongKickUser, --通过ID提出用户，GC发过来
	["GMBC"] = OnBroadcasetToClient, --收到游戏中心的发送广播消息
	["RQGB"] = on_require_refresh_user_info, --收到客户端刷新用户信息
	["GCRG"] = OnRegisterGameSvr, -- ??
	["RQUS"] = OnRequestGetSvrId,  --获取用户在那个服务器上
	["REUS"] = OnRecvGetSvrId,  --获取用户在那个服务器上
	
	["REWT"] = OnRecvRqWatch,       --收到请求观战
	["REET"] = OnRecvExitWatch,     --收到请求退出观战
	
	["RQAF"] = OnRequestAddFriend,
	["ACAF"] = OnAcceptAddFriend,
	
	["RQDC"] = onrecvdeskchat,              --聊天请求
	["ERDC"] = OnRecvChatError,             --收到发送聊天信息失败
	["RECT"] = OnRecvChatFromGameSvr,       --收到其他服务器发过来的聊天信息
	["ECHO"] = OnEcho,                      --客户端检测网速
	["RQGG"] = OnRecvGiveGoldByBankrupt,    --破产送钱

    ["RQGIVE"] = OnRecvTexBankruptGiveGold,    --德州破产领取救济
    ["RQUL"] = OnRecvUserLeaveGame,         --用户离开游戏了,这里只有退到选游戏界面才发出
	["RQUE"] = OnRecvUserEnterGame,         --用户进入游戏了，这里只有选游戏才发出
	["RQCS"] = onrequestchangesite,      --请求换桌子

    ["RQATGIVE"] = OnBankruptAutoGiveGold,    --德州破产自动领取救济，手动领救济的接口不变，保持兼容性。
	
	------------------------------------------------------------------
	--跨服架构相关
	["GCGS"] = OnRecvBufFromGameSvr,    --收到其他GameServer通过GameCenter发过来的信息
	["GSPP"] = on_send_gs_buf_to_user_id,    --发送buf到其他服务器，发送条件通过用户id判断
    ["GSSG"] = on_send_gs_buf,    --发送buf到所有服务器
        
	["SBTU"] = OnRecvBufFromGameCenterToUser,    --转发来自GameCenter的请求
	["EXEOVER"] = on_exe_over,					--当GameCenter要关闭的时候
	["SCTC"] = SendBufferToGameCenter,
	["SDSBTC"] = OnSendBufferToGameCenter,
	
	["REGICP"] = onrecv_gameinfo_copy,  --收到得到游戏信息副本请求
	
	["GCGETINFO"] = onrecv_gc_get_info,
	
	["GCREPYINFO"] = onrecv_gc_reply_info,
	
	------------------ 道具商城部分 --------------------
	["SPITEMLIST"] = on_recv_shop_item_list, --收到道具列表
	
	["ITEMBUY"]  = on_recv_buy_item,        --购买道具
	
	["USERBUFF"] = on_recv_user_buff,       --收到刷新用户buff
	
	----------------------------------------------------
	["GMCTFP"]  = on_recv_gm_control_fapai,  --收到gm控制发牌
	--["FRRANK"] = on_recv_friend_rank,       --收到好友排行请求

    ["RQDAYGOLD"] = on_recv_daygold_give, --收到每日登陆送钱

    ["SHOWFEEDBK"] = on_recv_show_freeback, --客户端查询是否显示反馈按钮
    ["REHISMPAY"] = on_recve_quest_user_maxpay, --收到查询历史最高充值金额   
    
    -----------------对接相关-------------------------
    ["TEXAUTHORBAR"] = on_recve_show_authorbar, --客户端查询是否显示是否需要显示角色选择面板
    ["TEXUSERNICK"] = on_recve_update_usernick, --更新用户昵称
    ["TEXUSERCHANNEL"] = on_recve_update_channel, --更新频道
    ["TEXTOCKEN"] = on_recve_keep_tocken,	--收到保存用户授权码（主要用于YY）
	}
	trace("成功完成 服务端大厅 初始化")
end

hall.init_map();

--[[
命令约定
RQ,请求前缀
SD,在接收时需要发送响应，使用SD作为前缀
RE,返回请求查询结果

NT,通知消息,由服务端主动外发,不是客户端主动请求的查询结果
]]
