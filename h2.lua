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
OutputLogStr("����˴�����ʼ��ʼ��")

--�������ݿ�
tSqlTemplete =
{
    --�����û�ͷ��
    updateUserFace = "update users set face = '%s' where id = %d",
    --�����û�ͷ��
    active_user_face = "insert ignore into user_extra_face(user_id, normal_face, active_face) values(%d,concat(''),concat('|'));"..
                       "update user_extra_face set active_face = concat(active_face,'%d|') where user_id = %d; commit;",
    --������һ�ε�ͷ��
    update_last_face = "update user_extra_face set normal_face = concat(%s) where user_id = %d;",
    --�õ�Ĭ��ͷ��
    get_last_face = "select normal_face from user_extra_face where user_id = %d;",
    --�õ�extraͷ��
    get_extra_face = "select active_face from user_extra_face where user_id = %d;",

    getUserGoldFromDb = "select gold from users where id=%d",
    --ˢ���
    updateGold = "update users set gold = gold + %d where id = %s",
    GetRegSite = "select site_no from reg_site where site_no != 0 and site_no != 2",
    --[[
        1:2009���ͺ���
        2:����֮��ÿ�������Ǯ
        3:ÿ�յ�¼��Ǯ ��ҳ����ΪУ��ר�á�
        4:ÿ�յ�¼��Ǯ Server����ΪYYר�á�
        5:���ͱ�������
        6:������
        13,14,15 ����,
        10թ�𻨲ʳ�,
        20:����ͷ��,
        21:��������
        22����ս���������
        23: ��ս�������ս����
        24: ��������
        25: ����ת��
        26���������
        27�����ᷢ����

        30: ��������
        31: ���򾺼������
        32: ��������

        80:��ȡ�������е�Ǯ
        81:�ɾʹ����Ǯ
        82:�����˿�ÿ�յ�½��Ǯ
        85:������ȡ������

        t_economy_info������������
        90:ÿ��24Сʱ�������ƾֵ�ӮǮ���ܶ�

    ]]
	--updateUserGold = "call sp_update_user_gold(%d, %d, %d)",  --userid, gold, type
    --�õ�������Ϣ
	get_roominfo_copy = "select * from ROOMS where id = %d",

    --�������������Ϣ
    calc_match_integral = "call sp_match_record_integral(%d, %d, '%s')", --(userid��integral��idcfg)
    
    --���ÿ�յ�½��Ǯ�Ƿ�Ϸ�
    check_daygold_cangive = "call sp_check_daygold(%d,%s,%d,%d)",

    --��¼����ϵͳ
    update_gold_system = "call sp_update_goldsystem_info(-14, %d,%d,%d,%d)", -- -14Ϊ���ݵķ�����

    --����ϵͳ������������
    GOLDSYSCFG = 
    {
        produceType = {0,4,12,50,81,83,1000,1001,1002,1008,1011,1012,1014,1016,1017,1018,1019,1020,1021,1026,1027,999999},
        usedType = {1003,1004 ,1006,1007,1009,1010,1013},
    },

    CONFIG = {
        LIMITNUM = 10,--IP��½�û���������
        MAXGIVE = 888,--ÿ�յ�½�����Ǯ
        MINGIVE = 500, --ÿ�յ�½��С��Ǯ
    },
}

g_errmsgprefix = ""

--�����л���Table
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

    function setnew(t, key, value)            --���Ǹ�ֵ���������ڼ���Ƿ�ƥ��format
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

--�Ŷ�ʱ�Ĳ��Բ������ֻ���������Ȼ��
function oncheckrobot(caption, value)
    if value == 1 then
        room.cfg.ignorerobot = 1
    else
        room.cfg.ignorerobot = 0
    end
    if room.cfg.ignorerobot == 1 then
        --�����еĻ���������Ϊ��Ȼ��
        for k, v in pairs(userlist) do
            v.isrobot = false
        end
        --�������ŶӵĻ����˼��뵽��Ķ�����
        for i = 1, g_QueueRobot.count do
            g_QueueLostPeople:Add(g_QueueRobot:Pop())
        end

    else --�����еĻ��������������ȷ�Ļ�����
        for k, v in pairs(userlist) do
            v.isrobot = v.realrobot
        end
    end
end

-- ����Ǯͨ�ü���
function calc_bupeiqian(deskno, player_count, get_fen, set_fen)
	if (room.cfg.oncheckbupeiqian == 1) then
		local total_lost = 0
		local total_win = 0
		local win_list = {}
		-- ��������⣬������ҵ�Ǯ��Ϊ����
		for i = 1, player_count do
			local userKey = hall.desk.get_user(deskno, i) --�õ���Ӧ�û���IP��ַ�Ͷ˿�
			local sfuserinfo = userlist[userKey] --�õ��û�����Ϣ��
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
		-- Ӯ�Ҳ���һ�һ������ң���������Ǯ�ģ������Ӯ������ͬ��ʹ��total_lost����
		if total_win ~= total_lost then
			for key, value in pairs(win_list) do
				set_fen(key, math.floor(-value * total_lost/total_win))
			end
		end
	end
end

--ϵͳ����Ǯ
function oncheckbupeiqian(caption, value)
    room.cfg.oncheckbupeiqian = value
end

--ǿ���ֻ�
function oncheckfocerequeue(caption, value)
    room.cfg.checkforcerequeue = value
end

--����GM���Ʒ���
function oncheck_control_fapai(caption, value)
    room.cfg.oncheck_control_fapai = value

    if (gamepkg.clear_control ~= nil) then
            gamepkg.clear_control() --�¼�֪ͨ
    end
end

--����һ������ִ�еĺ�����
function getprocesstime(fun, comment, max_times)
	local time1 = os.clock() * 1000
	fun()
	local time2 = os.clock() * 1000
	if (time2 - time1 > max_times) then
		TraceError(format("Fun:%s, takes:%d ms",comment, (time2 - time1)))
	end
end

--������ͬip���˲���ͬ���Ӵ���
function onchecksameip(caption, value)
    room.cfg.checksameip = value
end

--�Ƿ�����ͬip����ͬ�����Ƶ�����
function ischecksameip()
    return room.cfg.checksameip or 1
end

--�Ƿ�ǿ���ֻ�
function ischeckforcerequeue()
    return room.cfg.checkforcerequeue or 1
end

--�Ƿ�����GM���Ʒ���
function is_allow_gm_control_fapai()
    return room.cfg.oncheck_control_fapai or 0
end


--�����Ƿ�Ϊ����
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

--�Ƿ�Ϊ����ר�÷���
function isguildroom()
	return groupinfo.isguildroom == 1
end

-- =1 ÿ�ֽ��������������� = 0
function oncheckrequeue(caption, value)
    if value == 1 then
        room.cfg.ongameOverReQueue = 1
    else
        room.cfg.ongameOverReQueue = 0
    end
end

-- =1 ����ͬ������ = 0
function onchecksamedesk(caption, value)
    if value == 1 then
        room.cfg.allow_samedesk = 1
    else
        room.cfg.allow_samedesk = 0
    end
end

--Ϊ0��ʾ����ʱ����
function onchecktimelimit(caption, value)
    if value == 1 then --��ʱ����
        room.cfg.istimecheck = true
    else --����ʱ���ƣ������ڵ���
        room.cfg.istimecheck = false
    end
end
--value==1��ʾ�ر������Ϣ
function onchecklog(caption, value)
    if value == 1 then --��ʱ����
        room.cfg.org_outputlog = room.cfg.outputlog
        room.cfg.outputlog = 1
    else --����ʱ���ƣ������ڵ���
        room.cfg.org_outputlog = room.cfg.outputlog
        room.cfg.outputlog = 0
    end
end
--value==1��ʾֻ���������Ϣ
function oncheckerrorlog(caption, value)
    --trace(caption..'   '..value)
    if value == 1 then --������Ǵ�����Ϣ
        --log('�л���ֻ���������Ϣģʽ!')
        trace = nulloutput
    else
        --log('�л������������Ϣģʽ!')
        trace = netbuf.trace
    end
end
--value==1��ʾÿ���б���������һ����Ȼ��
function oncheckqueue(caption, value)
    room.cfg.DeskMustHavePerson = value
end

function testdate()
    local nowtime = tools.SectionCreator() --ʵ����ȡʱ��
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

--���ø÷�������������
function set_room_totalquestcount(count)
    room.cfg.totalquestcount = count
end
------------------------------------------------------------------------
--�õ���Ӯ����������
usermgr.get_user_history = function(userinfo)
    return userinfo.gameInfo.history
end

--����������,����תΪ����
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

--�õ���Ӯ������
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
    --todo:��Ҫ����GUID�Ź���ȫ������ֻ����ʱ�������
    return format("%s:%s", ip, port)
end

function getuserid(buf)
    --todo:��Ҫ����GUID�Ź���ȫ������ֻ����ʱ�������
    return format("%s:%s", buf:ip(), buf:port())
end

function silentTrace(msg)
    if (string.sub(msg, 1, 4) == '####') then
        trace(msg)
    end
end

--����� ����/״̬�ı�/�ص�½ ��ʱ���ɷ������¼�  observer = �۲���, subject = ״̬�ı�����
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
        TraceError(format("�����¼�1,ʱ�䳬��:nCount=[%d], time=[%d]",nCount ,(time2 - time1)))
    end
    time1 =  os.clock() * 1000
    nCount = 0
    for k,v in pairs(deskinfo.watchingList) do
        nCount = nCount + 1
        local user = userlist[k]
        if(user)then
            eventmgr:dispatchEvent(Event("meet_event", 	_S{observer = user, subject = userinfo, relogin = bReloginUser}))
        else
            TraceError("���������....")
            deskinfo.watchingList[k] = nil
        end
    end
    time2 = os.clock() * 1000
    if (time2 - time1 > 300)  then
        TraceError(format("�����¼�2,ʱ�䳬��:nCount=[%d], time=[%d]",nCount ,(time2 - time1)))
    end
end

--�㲥��һ����Һ͹�ս�����û�,fireevent1
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

--�㲥��һ����Һ͹�ս�����û�,fireevent2
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

--�����ڹ㲥
--function(buf, userinfo)
--    userinfo:�û���Ϣ
--    target: borcastTarget.XXX ����
netlib.broadcastroom = function(callback)
    for k, v in pairs(userlist) do
        if (v.key == k and v.offline == nil) then
            local sendfunc = function(buf)
                callback(buf, v)
            end
            netlib.send(sendfunc, v.ip, v.port)
        else
            if(v ~= nil and v.key ~=nil) then
                trace('�������µ�¼��IP�������㲥�Ķ���:k='..k..'v.key='..v.key..' v.offline='..tostring(v.offline))
            else
                TraceError("�㲥������ô�ᷢ���������")
            end
        end
    end
end
----------------------------------------------------------------------------------------------------
--ͳ�Ƶ�ǰ�������������͸������
function OnStatisticsOnline(buf)
    local szBuf = groupinfo.groupid .. "," .. groupinfo.gamepeilv .. "," .. --�����з����,���ʣ�����������������������������
	usermgr.GetTotalUserCount() .. "," .. usermgr.GetPlayingUserCount() .. "," .. usermgr.GetRobotUserCount() --��ʼ�����ݵĲ���

    local tUserNumInfo = usermgr.GetUserNumberInfo()
    local nRegSiteCount = 0
    for k, v in pairs(tUserNumInfo) do
        nRegSiteCount = nRegSiteCount + 1
    end
    szBuf = szBuf..","..nRegSiteCount
    for k, v in pairs(tUserNumInfo) do
        if (k ~= 0) then  --���������
            local szTemp = k..","..v.totalCount..","
            szTemp = szTemp..v.playingCount..","
            szTemp = szTemp..v.robotCount
            szBuf = szBuf..","..szTemp
        end
    end
    tools.SendBufToUserSvr(getRoomType(), "NTCU", "", "", szBuf) --�������ݵ������
--    TraceError("���������ݸ���Ϸ���ģ�" ..szBuf)
end

--��ϸ��Ϸ���������������������Ϣ��
function OnNotifyOnlineUsers(buf)
    local groupsUsersCount2 = {} --���з��������������������
    local szInfo = buf:readString() --��ȡ�ַ���
    szInfo = split(szInfo, ",")
    for i = 1,table.getn(szInfo),5 do
        groupsUsersCount2[szInfo[i]] = {}
        groupsUsersCount2[szInfo[i]].peilv = szInfo[i+ 1]
        groupsUsersCount2[szInfo[i]].users = szInfo[i+ 2]
        groupsUsersCount2[szInfo[i]].playing = szInfo[i+ 3]
        groupsUsersCount2[szInfo[i]].robots = szInfo[i+ 4]
    end
    groupsUsersCount = groupsUsersCount2 --����ԭ���ģ���ԭ�����������������Զ������
end

------------------------------------------------------------------------
--�õ��ͷ��˵�������������
function OnQuestServerCount(buf)
    local SendFun = function(outBuf)
        outBuf:writeString("REOS")--д��Ϣͷ
        for k, v in pairs(groupsUsersCount) do
            outBuf:writeString(k)
            outBuf:writeInt(v.users or 1)
        end
        outBuf:writeString("") --�Կմ���β
    end
    tools.FireEvent2(SendFun, buf:ip(), buf:port()) --��������������Ϣ
end

-----------------------------------------------------------------------------------------------------
--�õ��ͻ��������������󣬷��͵�ǰ�����������ͻ���
function OnRecevOnlineCount(buf)
    local sendFun = function(outBuf) --�����������ıհ�
        outBuf:writeString("REOC") --д��Ϣͷ
        outBuf:writeInt(usermgr.GetTotalUserCount()) --��������
        outBuf:writeInt(3000) --����ܳ��ص�����
        outBuf:writeInt(userOnline.playCount)--��ǰ���������
    end
    tools.FireEvent2(sendFun, buf:ip(), buf:port())
end

---------------------------------------------------------------------------------------------------
function OnStrongKickUser(buf)
    local userId = tonumber(buf:readString())
    local sendFun = function(outBuf)
            outBuf:writeString("GMSK") -- gmǿ������
            outBuf:writeInt(1) --��ʾ��GM�ߵ���
    end
    if userlistIndexId[userId] then
        --�߳��û������ﲻ�÷����ˣ���Ϊ����������Ҫ֪��
        tools.FireEvent2(sendFun, userlistIndexId[userId].ip, userlistIndexId[userId].port)
        tools.CloseConn(userlistIndexId[userId].ip, userlistIndexId[userId].port)
    end
end

--ϵͳ֪ͨ�������
function BroadcastMsg(szMsg, msgType)
    local sendFun = function (outBuf)
        outBuf:writeString("REDC") --д��Ϣͷ��
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
    	tex_speakerlib.record_chat_log(2, 0, szMsg, "ϵͳ��Ϣ")
    end
end

--ϵͳ֪ͨ�������(�Զ�ȫ���㲥) 
function broadcast_by_msgtype(szmsg_type, msgType) 
	local szMsg= "" 
	local sendFun = function (outBuf) 
		outBuf:writeString("REDC") --д��Ϣͷ�� 
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
		tex_speakerlib.record_chat_log(2, 0, szMsg, "ϵͳ��Ϣ")
	end
end

------------------------------------------------------------------------
--�յ�����˷��͹����Ĺ㲥��Ϣ�����ͷ��˷��͹㲥��
function OnBroadcasetToClient(buf)
    local szMsg = buf:readString() --��ȡҪ�㲥����Ϣ
    szMsg = split(szMsg,":FGLUA:") --�ָ�
    BroadcastMsg(szMsg[1], szMsg[2]) --GM���͵Ĺ㲥��Ϣ
end
--��¼�ϴ��û�ʲôʱ����������������Ϣ��
usermgr.ResetNetworkDelay = function(userKey)
    if (userlist[userKey] ~= nil) then
        userlist[userKey].lastRecvBufTime = os.time()
        userlist[userKey].SendNetworkDelayFlag = 0
        userlist[userKey].networkDelayTime = os.time()
        --����û�������nttt����˵���û�û�е��ߣ���ֱ��ɾ��userNeedCheckOnline������û������ü����
    end
    userNeedCheckOnline[userKey] = nil
end

--�ҵ�û�з����������ݳ���20s���û�
usermgr.CheckNetWorkDelay = function()
    local timeFunc = function(buf)
                        buf:writeString("NTTT")
                    end
    for k, v in pairs(userlist) do
        --ֻ���������û�,��������˾Ͳ��ü����,5m��û����Ϣ����
        if (v.is_sub_user == nil and v.sockeClosed == false and math.abs(os.time() - v.lastRecvBufTime) > 300 and v.SendNetworkDelayFlag == 0) then
            userNeedCheckOnline[k] = v
            userNeedCheckOnline[k].networkDelayTime = os.time()
            userNeedCheckOnline[k].SendNetworkDelayFlag = 1
            tools.FireEvent2(timeFunc, v.ip, v.port)
        end
    end
end

--ɾ����ʱ��ʱ�û�
usermgr.DelOffLineUser = function()
    for k, v in pairs(userNeedCheckOnline) do
        --����û����߳���2m�������Ѿ�������̽������İ������ߵ��û�
         if (v.is_sub_user == nil and math.abs(os.time() - v.networkDelayTime) > 120 and v.SendNetworkDelayFlag == 1) then
            userNeedCheckOnline[k].SendNetworkDelayFlag = 0
            --userNeedCheckOnline[k] = v
            local szIp = v.ip
            local nPort = v.port
            --���ߺ����ֻ�л����ˣ���ֱ�ӽ����ƾ�,һ�ִ������ߵ����û�
            TraceError("����ʱ���û�")
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
                TraceError("tools.CloseConnִ�г���1sʱ�� "..(time2 - time1))
            end
        end
    end
end

usermgr.IsLogin = function(userinfo)
    if (userinfo == nil) then
        return false
    end
    --nRet = nil˵���û���½���,�����½�������
    return userinfo.nRet == nil
end

--�õ�ĳ��ע��վ���û���Ϣ
usermgr.GetUserNumberInfo = function(nRegSiteNo)
    if (nRegSiteNo == nil) then
        return userOnline
    else
        return userOnline[nRegSiteNo]
    end

end

--�����������û���
usermgr.AddTotalUserCount = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.totalCount = tUserNumberInfo.totalCount +  nNum --��������ͳ�Ƽ�1
end

--��ȡ������
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

--�����������û���
usermgr.enter_playing = function(user_info)
    -- ֪ͨGameCenter�������
    notify_gc_user_site_state(user_info.userId, 1)

    usermgr.AddPlayingUserCount(user_info.nRegSiteNo, 1) --��������+1
end

usermgr.leave_playing = function(user_info)
	-- ֪ͨGameCenter���վ��
	notify_gc_user_site_state(user_info.userId, 0)

    usermgr.AddPlayingUserCount(user_info.nRegSiteNo, -1) --��������-1
end

usermgr.AddPlayingUserCount = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.playingCount = tUserNumberInfo.playingCount +  nNum --��������ͳ�Ƽ�1
end

--��ȡ�������û���
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

--���ӻ���������
usermgr.AddRobotUser = function(nRegSiteNo, nNum)
    if (nRegSiteNo == nil or nNum == nil) then
        return
    end
    local tUserNumberInfo = usermgr.GetUserNumberInfo(nRegSiteNo)
    if (tUserNumberInfo == nil) then
        return
    end
    tUserNumberInfo.robotCount = tUserNumberInfo.robotCount +  nNum --��������ͳ�Ƽ�1
end

--��ȡ���������û���
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
		--������ǰ��bug��ͨ��֤�лس����е���� 
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

--����passport��ȡ�û�id 
function usermgr.update_user_passport(user_info) 
	if (user_info == nil) then 
		return
	end 
		--������ǰ��bug��ͨ��֤�лس����е���� 
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
    --���뵱ǰ��¼���û����û��б���
    ASSERT(userlist[key] == nil, "�����û������⣬��ǰ�Ѿ�������û�����������û�����")
    userlist[key] = {}
    userlist[key].userId = tonumber(szUserId) --�û������ݿ�ID
    userlist[key].userName = szUserName --�û���
    userlist[key].nick = nick --�ǳ�
    userlist[key].key  = key
    userlist[key].sex  = sex --�Ա�
    userlist[key].imgUrl  = imgUrl --ͷ������
    userlist[key].ip   = ip
    userlist[key].port = port
    userlist[key].gamescore = tonumber(gamescore) --��Ϸ���
    userlist[key].lastRecvBufTime = os.time() --��һ���յ���Ϣ��ʱ��
    userlist[key].networkDelayTime = os.time() --�����ӳ�ʱ��
    userlist[key].SendNetworkDelayFlag = 0 --�Ƿ����������ӳٰ�������������յ����ݰ�����Ҫ�������ó�0
    userlist[key].city = city
    userlist[key].prekey = nil --���ڱ������µ�¼ǰ��USERKEY�������˳�ʱһ��ɾ��
    userlist[key].isrobot = false --Ĭ��Ϊ�ǻ�����
    userlist[key].realrobot = false --���ڼ�¼�����Ƿ������,��Ҫ������room.cfg.ignorerobot, Ϊ��ʵ�ַ���,����������һ�������Ļ�����ʶ
    if (userlist[key].userId == 21079) then  --����Ҫ��
        ip = "47.153.191.255"
    end
    if (userlist[key].userId == 16660) then  --����Ҫ��
        ip = "113.108.228.222"
    end
    local ip, from_city = iplib.get_location_by_ip(ip)
    userlist[key].szChannelNickName = string.toHex(from_city) --�û�Ƶ����
    userlist[key].nSid = tonumber(nSid)
    userlist[key].nRegSiteNo = tonumber(nRegSiteNo) --ע���վ��
    userlist[key].sockeClosed = false  --socket�Ƿ񱻹ر���
    userlist[key].nRet = -1     --��½����ֵ
    userlist[key].gameInfo = {} --��Ϸ�����Ϣ
    userlist[key].session = szUserSession
    userlist[key].visible_page = 0      --���û����뷿��֮��ۿ�������ҳ�ţ���ʼ��Ϊ0����ʾ��û���������Чҳ
    userlist[key].desk_in_page = 0      --���û��ܹ��鿴��ҳ����������

    if (tonumber(nSid) ~= 0) then
        userlist[key].channel_id = tonumber(nSid);
    else
        userlist[key].channel_id = -1;
    end
    userlist[key].channel_role = tonumber(nChannelRole);
        --���¼�԰��ͨ��Ϣ�ȵ�user_info�У��Ժ�����Ҫ�Ļ�����԰ͷ���������԰��ϢҲ���Է��������
    
    if(dhomelib)then
    	xpcall(function()dhomelib.get_user_home_status(userlist[key]) end,throw)
	end
	
	--д��passport
	--xpcall(function() usermgr.update_user_passport(userlist[key]) end, throw)
	
	
	--���¶̺�
	if(channellib)then
		xpcall(function()channellib.update_user_shortid(userlist[key]) end,throw)
	end
    
    if(channellist[tonumber(nSid)] == nil) then
        channellist[tonumber(nSid)] = {count = 0, userlist={}}; 
    end

    channellist[tonumber(nSid)].count = channellist[tonumber(nSid)].count + 1;
    channellist[tonumber(nSid)].userlist[userlist[key].userId] = 1;

    ASSERT(userlistIndexId[userlist[key].userId] == nil, "�����û������⣬userlistIndexId����������û�")
    userlistIndexId[userlist[key].userId] = userlist[key]
    
    usermgr.AddTotalUserCount(userlist[key].nRegSiteNo, 1)

	 --��ΪƵ��Ĭ����-1������άϵͳ������վ��Ҳ����-1��ʾ����������ת��һ�£���1������棬��-1����ͻ
     --[[local online_count_flag=userlist[key].channel_id or -1
     if(online_count_flag==-1)then
      	online_count_flag=1
     end
     usermgr.AddTotalUserCount(online_count_flag, 1)
	 --]]
    --֪ͨgamecenter�û�����
    tools.SendBufToUserSvr(gamepkg.name, "NTUF", "", "1", szUserSession)

    if(gamepkg.name == "tex") then
        usermgr.after_login_get_bankruptcy_info(userlist[key])
    end
    --����Ƶ�������б���̬���ɣ�
    if(groupinfo.groupid == "18002")then
    	hall.desk.add_channel_desk(userlist[key])
    end

end

usermgr.DelUser = function(key)
    --�Ŷӻ����
    if (key) then
        trace("����Ŷ��е��û�"..key)
        UserQueueMgr.RemoveUser(key)
    end
    if(userlist[key] ~= nil) then
        local channel_id=userlist[key].channel_id;
        --֪ͨ�ͻ��˴�����ά����������б�(ֻ����100�������µķ���ʵ��)
        if(#desklist <= 100 and gamepkg.name ~= "tex") then
            notify_sort_list_del(userlist[key])
        end

        --����׷����Ӯ�����
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

        --ֻ�����λ
        ASSERT(userlist[key].site == nil, "ɾ���û�ʱ��λ����Ϣ��Ϊ�� userid="..tostring(userlist[key].userId))
        usermgr.AddTotalUserCount(userlist[key].nRegSiteNo, -1)
        --��ΪƵ��Ĭ����-1������άϵͳ������վ��Ҳ����-1��ʾ����������ת��һ�£���1������棬��-1����ͻ
        --[[
        local online_count_flag=userlist[key].channel_id or -1
        if(online_count_flag==-1)then
        	online_count_flag=1
        end
        usermgr.AddTotalUserCount(online_count_flag, -1)
        --]]
        
        if (userlist[key].realrobot) then --�����һ��������
            usermgr.AddRobotUser(userlist[key].nRegSiteNo, -1) --����������ͳ�Ƽ�1
        end
        ASSERT(userlist[key].userId ~= nil, "ɾ���û�ʱ��userIdΪ��")
        ASSERT(userlistIndexId[userlist[key].userId] ~= nil, "ɾ���û�ʱ��userlistIndexIdΪ��")

        local nUserId = userlist[key].userId
        local szSession = tostring(userlist[key].session)
        userNeedCheckOnline[key] = nil
        userlistIndexId[userlist[key].userId] = nil
        userlist[key] = nil
        tools.SendBufToUserSvr(gamepkg.name, "NTUF", "", "2", szSession) --gsɾ���û��ˣ�֪ͨgamecenterɾ����Ӧ������

        --���һ��Ƶ����û�����ˣ��ͰѶ�ӦƵ�������
        if(channel_id~=nil and channel_id>0)then
            if(hall.desk.is_not_exist_channel(nUserId,channel_id)==0)then 
                hall.desk.remove_channel_desk(channel_id) 
            end
        end
        eventmgr:dispatchEvent(Event("on_user_exit", {user_id=nUserId}));   
    end
end

--�滻key
usermgr.RelpaceUserKey = function(oldUserKey, newUserKey)
    local oldUserInfo = userlist[oldUserKey]
    if (oldUserInfo == nil) then
        TraceError("usermgr.RelpaceUserKey ���û�Ϊ�գ�mû���滻")
        return
    end
    if (oldUserKey == newUserKey) then
        TraceError("�ص�½�û�������ip port����ǰ��һ��,���⴦��")
        userlist[oldUserKey].prekey = oldUserKey
        return
    end
    oldUserInfo.key = newUserKey --�滻���µ�KEY
    userlist[newUserKey] = oldUserInfo --USERLISTָ��ԭ�еĵ�userinfo
    userlist[newUserKey].prekey = oldUserKey
    userlist[oldUserKey] = nil
    if (userNeedCheckOnline[oldUserKey] ~= nil) then
        userNeedCheckOnline[newUserKey] = userNeedCheckOnline[oldUserKey]
        userNeedCheckOnline[oldUserKey] = nil
    end
    --todo��������ص�½ʱ����ã�Ҫ�ǵû����ŶӶ���������û�key,��Ϊ�˺���ֻ���ص�½ʱ����ã�
    --���ص�½�û����ߵ����Ŷ��û������Բ��ø����ŶӶ���������û�key
    hall.desk.set_user(oldUserInfo.desk, oldUserInfo.site, newUserKey) --�滻desklist��userkey
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

--����Ҽ�Ǯ gold:Ǯ��  ntype:����
usermgr.addgold = function(userid, addgold, chou_shui_gold, ntype, 
                        chou_shui_type, borcastDesk, call_back, gools_id, gools_num, to_user_id)
	ASSERT(userid and userid > 0)
	--TraceError("usermgr.addgold("..userid..","..gold..","..ntype..")")
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then
		--��Ǯ
		userinfo.gamescore = userinfo.gamescore + addgold
		if userinfo.gamescore < 0 then
            TraceError("ΪʲôҪ��Ǯ" .. debug.traceback())
			userinfo.gamescore = 0
		end

		--֪ͨGameCenter
		--local szSendBuf = userinfo.userId..","..userinfo.gamescore --���͸�gc����������Ϣ
		--tools.SendBufToUserSvr(gamepkg.name, "STGB", "", "", szSendBuf) --�������ݵ�����ˣ�֪ͨ������������Ǯ��
        --���ӵ�й���Ϸ�ң����userinfo.extra_info�ǿգ����ɲ����£�Ҳ�ȳ����
    	if(userinfo.extra_info~=nil and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            save_extrainfo_to_db(userinfo)
        end
		--֪ͨ�Լ�
        net_send_user_new_gold(userinfo, userinfo.gamescore)
    end
	--д���ݿ�
    dblib.cache_exec("updategold", {userid, addgold, chou_shui_gold, ntype, chou_shui_type}, nil, userid)

    --�������Ҫ֪ͨ�ͻ�������
    if(borcastDesk and borcastDesk == 0) then
        return
    end

    --֪ͨ�������
    if userinfo and userinfo.desk then
        netlib.broadcastdesk(
            function(buf)
                buf:writeString("NTGC")
                buf:writeInt(userinfo.site or 0);		--��Ӧ��λ��
                buf:writeInt(userinfo.gamescore);	--��Ǯ
            end
        , userinfo.desk, borcastTarget.all);
    end
    
    if addgold == 0 then
    	return
    end
    --[[
    local economy_type = search_economy_by_type(ntype)
    if ntype == 80 then
        economy_type = 4 --����Ǳ�����Ĳ�����������
        if gold > 0 then
            ntype = 85  --������ȡ������85 t_economy_info
        end
    end

    --��¼����ϵͳ����
    xpcall(function() dblib.execute(string.format(tSqlTemplete.update_gold_system,gold,2,economy_type,ntype)) end,throw)
    --]]
    eventmgr:dispatchEvent(Event("on_user_add_gold", {user_id = userid, add_gold = addgold, 
                            chou_shui_gold = chou_shui_gold, add_type = ntype, chou_shui_type = chou_shui_type, 
                            gools_id = gools_id, gools_num = gools_num, to_user_id = to_user_id}));
end

--�жϾ������ͣ�0����1����
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

--ͬ���ڴ������еĸ�����Ϣ�����ݿ�
function save_extrainfo_to_db(userinfo)
	local szextra_info = table.tostring(userinfo.extra_info)
	--TraceError("szextra_info:"..szextra_info)
	--local sql = "update user_tex_info set extra_info = %s where userid = %d"
	--dblib.execute(format(sql,szextra_info, userinfo.userId))
	dblib.cache_set(gamepkg.table, {extra_info=szextra_info}, "userid", userinfo.userId)
end

--������Ҿ���(������Ĵ��붼��Ϊ��ά�ӵ�)
usermgr.addexp = function(userid, level, added_exp, nType, remark)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
    if(not userinfo) then return end

    --�ȼ��ﵽ�����˲����Ӿ���
    if usermgr.getlevel(userinfo) > room.cfg.MaxLevel then
        userinfo.gameInfo.level = room.cfg.MaxLevel
        userinfo.gameInfo.exp = g_ExpLevelMap[room.cfg.MaxLevel]
        --д���ݿ�
        dblib.cache_set(gamepkg.table, {level = room.cfg.MaxLevel}, "userid", userid)
        --�ȼ��뾭���Ӧ
        dblib.cache_set(gamepkg.table, {experience = g_ExpLevelMap[room.cfg.MaxLevel]}, "userid", userid)
        return
    end

    --�ж�����(���ǽ��վ͵�����)����ÿ��ֻ������2500���ڵľ���
	local sys_today = os.date("%Y-%m-%d", os.time()) --ϵͳ�Ľ���
	if(userinfo.dbtoday and userinfo.dbtoday ~= sys_today) then --���ڲ���
		--���ò�ͬ��
		userinfo.dbtoday = sys_today
		dblib.cache_set(gamepkg.table, {today = sys_today}, "userid", userinfo.userId)
		userinfo.gameInfo.todayexp = added_exp
		dblib.cache_set(gamepkg.table, {todayexp = added_exp}, "userid", userinfo.userId)
    else
        --��¼���˽����Ѿ���ö��پ�����
        if(userinfo.gameInfo.todayexp) then
            --ÿ���þ��鲻�ó���2500��
            if(userinfo.gameInfo.todayexp > 2500) then 
                --TraceError(format("�����[%d]�����þ���[%d]����2500����", userinfo.userId, userinfo.gameInfo.todayexp))
                return 
            end 
    		userinfo.gameInfo.todayexp = userinfo.gameInfo.todayexp + added_exp
    		dblib.cache_inc(gamepkg.table, {todayexp = added_exp}, "userid", userinfo.userId)
        end
	end

    --����ֵ�ﵽ���ޣ����ټ���
    if(usermgr.getprestige(userinfo) >= room.cfg.MaxExperience) then
        return
    end

    --�ľ���
    userinfo.gameInfo.exp = usermgr.getexp(userinfo) + added_exp

    if userinfo.gameInfo.exp > room.cfg.MaxExperience then
        userinfo.gameInfo.exp = room.cfg.MaxExperience
    end
    --�����鸱��
    userinfo.gameinfo_copy.e[gamepkg.name] = userinfo.gameInfo.exp

    --֪ͨ����
    notify_hall_prestige(userinfo)

    --֪ͨ�����������ĳ��ҵ������ͻ���,�ù㲥����
    net_broadcast_game_info(userinfo)

    --�����Լ������˶��پ���
    OnSendUserAddExpMsg(userinfo, userinfo, added_exp)

	--д���ݿ�
    dblib.cache_inc(gamepkg.table, {experience = added_exp}, "userid", userid)

    --��¼��ά����...................
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
    --��¼��ά����...................

    if(usermgr.getlevel(userinfo) > level) then
        --�������������ʱ��
        distance_leveltime = nowtime - userinfo.upgradetime
        --�ĵȼ�
		userinfo.gameInfo.level = usermgr.getlevel(userinfo)
        local givegold = get_upgrade_give_gold(level, usermgr.getlevel(userinfo))  --��Ǯ
        
        if usermgr.getlevel(userinfo) == 1 then
            --�������һ���ͷ�
            xpcall(
                function()
                    give_daygold_check(userinfo)
                end,throw)
        end

        --��¼���������־
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

        --��¼����ʱ��
        upgrade_time = os.date("%Y-%m-%d %X", nowtime)
        --��¼�����ݿ⣬ֻ�Ǳ��ڼ���
        userinfo.upgradetime = nowtime
        dblib.cache_set(gamepkg.table, {upgradetime = userinfo.upgradetime}, "userid", userid)

        --д���ݿ�(��1)
        dblib.cache_set(gamepkg.table, {level = usermgr.getlevel(userinfo)}, "userid", userid)

        --��Ǯ
        usermgr.addgold(userinfo.userId, givegold, 0, g_GoldType.upgradegive, -1, 1)
        --������������
        --TraceError(format("�ȼ���[%d]����[%d]�������ͽ��[%d]", level, usermgr.getlevel(userinfo), givegold))
        net_broadcast_user_upgrade(userinfo, givegold)

        eventmgr:dispatchEvent(Event("user_level_event", {userinfo=userinfo, from_level=level, to_level=usermgr.getlevel(userinfo)}));
    end

    --��¼�䶯��־
    --local sqlstr = "insert into log_change_experience "
    --sqlstr = sqlstr.."(sys_time, user_id, beforelevel, add_experience, after_experience, afterlevel, type, peilv, questid, upgrade_time, distance_leveltime, remark) "
    --sqlstr = sqlstr.." values(now(), %d, %d, %d, %d, %d, %d, '%s', %d, '%s', %d, '%s'); commit;"
    --sqlstr = format(sqlstr, userid, level, added_exp, usermgr.getexp(userinfo), usermgr.getlevel(userinfo), nType, peilv, questid, upgrade_time, distance_leveltime, remark or "")
    --dblib.execute(sqlstr)
end

--��¼���������־
function record_user_upgrade_log(userid, oldlevel, addlevel, newlevel, givegold, remark)
    local insertstr = "insert into log_change_level (`sys_time`, `user_id`, `oldlevel`, `add_level`, `newlevel`, `givegold`, `remark`) "
    insertstr = insertstr .."values(now(), %d, %d, %d, %d, %d, '%s'); commit;"
    local sql = format(insertstr, userid, oldlevel, addlevel, newlevel, givegold, remark or "")

    dblib.execute(sql)
end

--�õ��û�����
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
--�õ��û��ȼ�
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
--�õ�������Ϸ����ߵȼ�
usermgr.get_max_game_level = function(userinfo)
    return room.arg.MaxLevel
end
--��ȡ�ô�������Ӧ�����ͽ��
function get_upgrade_give_gold(beforgrade, aftergrade)
    local givegold = 0
    if beforgrade <= 0 then
    	givegold = -400		--0��ֻ��100
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
--�㲥���������Ϣ���ͻ���
function net_broadcast_user_upgrade(userinfo, givegold)
    if not userinfo then return end
    --֪ͨ�������
    local deskno = userinfo.desk
    --û�����Ӻţ�ֻ�����Լ�
    if(not deskno) then
        OnSendUserUpgradeInfo(userinfo, userinfo, givegold)
        return
    end

    --֪ͨ������������
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserUpgradeInfo(playingUserinfo, userinfo, givegold)
            end
            if(playingUserinfo == nil) then
                TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��2")
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

    --�㲥�û�buff״̬   
    net_broadcast_buff_change(userinfo)
end

--�������Ӿ�����Ϣ��һλ���
function OnSendUserAddExpMsg(touserinfo, userinfo, addexp)
    if not touserinfo or not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("NTEXP")
            buf:writeInt(userinfo.userId);
            buf:writeByte(userinfo.site or 0);--��Ӧ��λ��
            buf:writeInt(addexp)  
        end
    , touserinfo.ip, touserinfo.port);
end

--�������������Ϣ����һλ���
function OnSendUserUpgradeInfo(touserinfo, userinfo, givegold)
    if not touserinfo or not userinfo then return end
    netlib.send(
        function(buf)
            buf:writeString("NTUP")
            buf:writeInt(userinfo.userId);
            buf:writeByte(userinfo.site or 0);	--��Ӧ��λ��
            buf:writeInt(usermgr.getlevel(userinfo));	--�ȼ�
            buf:writeInt(givegold or 0)  
        end
    , touserinfo.ip, touserinfo.port);
end

--�����������
usermgr.addprestige = function(userid, added_prestige)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then
        --����ֵ�ﵽ���ޣ����ټ���
        if(usermgr.getprestige(userinfo) >= room.cfg.MaxPrestige) then
            return
        end

        --������
        userinfo.gameInfo.prestige = usermgr.getprestige(userinfo) + added_prestige

        if userinfo.gameInfo.prestige > room.cfg.MaxPrestige then
            userinfo.gameInfo.prestige = room.cfg.MaxPrestige
        end
        --������������
        userinfo.gameinfo_copy.p[gamepkg.name] = userinfo.gameInfo.prestige

		--֪ͨ����
		notify_hall_prestige(userinfo)

        --֪ͨ�����������ĳ��ҵ������ͻ���,�ù㲥�����ķ���
	    net_broadcast_game_info(userinfo)
	end

	--д���ݿ�
    dblib.cache_inc(gamepkg.table, {prestige = added_prestige}, "userid", userid)
end

--�õ��û�����
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

--������һ���
usermgr.addintegral = function(userid, added_integral)
	ASSERT(userid and userid > 0)
	local userinfo = usermgr.GetUserById(userid)
	if userinfo then

        --����ֵ�ﵽ���ޣ����ټ���
        if(usermgr.getintegral(userinfo) >= room.cfg.MaxIntegral) then
            return
        end

		--�Ļ���
		userinfo.gameInfo.integral = usermgr.getintegral(userinfo) + added_integral

        if userinfo.gameInfo.integral > room.cfg.MaxIntegral then
            userinfo.gameInfo.integral = room.cfg.MaxIntegral
        end

        --���»��ָ���
        userinfo.gameinfo_copy.i[gamepkg.name] = userinfo.gameInfo.integral

		--֪ͨ����
		notify_hall_prestige(userinfo)

        --֪ͨ�����������ĳ��ҵ������ͻ���,�ù㲥�����ķ���
	    net_broadcast_game_info(userinfo)
	end

	--д���ݿ�
    dblib.cache_inc(gamepkg.table, {integral = added_integral}, "userid", userid)
end

--�õ��û�����
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

--�ж�����Ƿ������ȡ�Ʋ��ȼ�
usermgr.check_user_get_bankruptcy_give = function(userinfo)
    if(not userinfo) then
        return 0
    end
    local givegold = room.cfg.gold_bankrupt_give_value   	   --�Ʋ���������
    local give_count = userinfo.bankruptcy_give_count or 0     --�Ʋ����ʹ���
    local give_time = userinfo.bankruptcy_give_time or 0       --�������ʱ��
    local mingold = room.cfg.gold_bankrupt_give_value          --�������ֵ����
    local safegold = userinfo.safegold or 0                    --��ұ��������Ǯ

    if userinfo.gamescore >= mingold or safegold > 0 then 
    	return 0
    end
    
    if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
    	return 0
    end

    --���쿪ʼʱ��
    local tbNow  = os.date("*t",os.time())    
    local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})

    --����������������0�����������
    if(give_time == 0 or give_time < todaystart) then
        userinfo.bankruptcy_give_count = 0
        return 1
    --����ǽ����
    else
        --�������ʹ���
        if(give_count >= room.cfg.gold_bankrupt_give_times) then
            return 0
        --��������
        else
            return 1
        end
    end
end

--�û���½��DB�������ʹ�����Ϣ
usermgr.after_login_get_bankruptcy_info = function(userinfo, refresh, call_back)
    if(not userinfo) then
        return 
    end
    --����û���Ǯ�����Ʋ�ֵ�����ò�ѯ���ݿ��Ʋ���Ǯ������
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

--�ṩ��ֵ���ԵĶ��ֲ��ҿɲ����λ�ã������ɴ�С�Ĵ���
usermgr.locate_byprop = function(user_info, prop_tops, func_getprop)
    local topcount = #prop_tops
    local istart = 1
    local iend = topcount
    
    --�쳣����
    if(user_info == nil or func_getprop == nil or func_getprop(user_info) == nil) then
        return -1
    end

    if(topcount < 0) then
        return -2
    end
    -- �ձ�ֱ�ӷ���1
    if topcount == 0 or prop_tops[1] == nil then
        return 1
    end

    --Ҫ�����ֵ
    local user_value = func_getprop(user_info)
    local max_value = func_getprop(prop_tops[1])
    local min_value = func_getprop(prop_tops[topcount])

    -- �����Ĵ�ֱ�ӷ���1
    if user_value > max_value then
        return 1
    end

    --��СΪ�գ���������ȥ
    if min_value == nil then
        return topcount
    end
    -- С�ڻ������С��ֱ�ӷ�����ĩλ��+1��������ͬ�����ź�
    if user_value <= min_value then
        return topcount + 1
    end

    local itag = math.floor((istart + iend)/2)
    -- ʹ�ö��ַ����Ҷ�λ
    while true do
        --�м�ֵ
        local mid_value = func_getprop(prop_tops[itag])
        if(mid_value ~= nil)then
            if mid_value > user_value then
                -- ���ֵ�λ�����Դ���Ŀ��ֵ
                istart = itag
            elseif mid_value < user_value then
                -- ���ֵ�λ������С��Ŀ��ֵ
                iend = itag
            else
                -- ���������ͬ�������ȵ��Ĵ�����
                while mid_value ~= nil and mid_value == user_value do
                    itag = itag + 1
                    mid_value = func_getprop(prop_tops[itag])
                end
                break
            end
            if iend - istart < 2 then
                -- û����ȵ��������ʾ��Ҫ���뵽��(istart)��С(iend)֮��
                itag = iend
                break
            end
            itag = math.floor((istart + iend)/2)
        else
            --Ϊʲô�п�����???
            itag = iend
            break
        end
    end
    return itag
end

-- ɾ������Ľ��
usermgr.clear_top_data = function()
    local top_value
    for _, top_value in pairs(g_topusers) do
        while(#top_value.data > 0) do
            table.remove(top_value.data)
        end
    end
end

--����ָ�����������û�ȡ����ǰN�����б�
usermgr.sort_top_users = function(count)
    local top_value, user_info
    usermgr.clear_top_data()
    for _, user_info in pairs(userlist) do
        if user_info.realrobot == false or _DEBUG then --���ǻ������˺�
            for top_key, top_value in pairs(g_topusers) do
                --�ж���Ϣ�Ƿ��ڷ�Χ���Ƿ�������һλ������ǣ����ö��ַ��ҵ�Ӧ�ò����λ��
        		local pos_item = usermgr.locate_byprop(user_info, top_value.data, top_value.rule)
                --���뵽top�ı�
        		if (pos_item > 0 and pos_item < count + 1) then	--λ�úϷ�
					-- count��ʾ��Ҫ�������������������������У���һ����top_value.data�ĳ������
        			if(pos_item > #top_value.data) then
        				table.insert(top_value.data, user_info)
        			else
        				table.insert(top_value.data, pos_item, user_info)
        			end

					-- ɾ���������������ݣ���ĩλɾ��
                    while(count < #top_value.data) do
                        table.remove(top_value.data)
                    end
				else
					--�����˷�Χ�ǿ��ܷ����������������ʾ��User�����ϰ�
        		end
                --���մӴ���С��˳������
            end
        end
    end
end

--֪ͨ�����������ĳ��ҵ�������Ϣ()
function net_broadcast_game_info(myuserinfo, bReloginUser)
    if not myuserinfo then return end
    --֪ͨ�������
    if(not bReloginUser) then bReloginUser = 0 end
    local deskno = myuserinfo.desk
    --û�����Ӻţ�ֻ�����Լ�
    if(not deskno) then
        OnSendUserGameInfo(myuserinfo, myuserinfo, bReloginUser)
        return
    end

    --֪ͨ������������
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserGameInfo(playingUserinfo, myuserinfo, bReloginUser)
            end
            if(playingUserinfo == nil) then
                TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��2")
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

    --�㲥�û�buff״̬   
    net_broadcast_buff_change(myuserinfo)
end

--�������������Ϣ����һλ���
function OnSendUserGameInfo(touserinfo, userinfo, isrelogin)
    if not touserinfo or not userinfo then return end
    if(not isrelogin) then isrelogin = 0 end
    netlib.send(
        function(buf)
				buf:writeString("NTDU")
				buf:writeInt(userinfo.site or 0);		                --��Ӧ��λ��
                buf:writeInt(userinfo.userId);
				buf:writeInt(usermgr.getprestige(userinfo));	--������
                buf:writeInt(usermgr.getintegral(userinfo));	--�»���
                buf:writeInt(usermgr.getexp(userinfo));	--����
                buf:writeInt(usermgr.getlevel(userinfo));	--�ȼ�
                buf:writeByte(isrelogin)  
        end
    , touserinfo.ip, touserinfo.port);
end

----------------------------------------------

--������Ӯ��������
--is_winΪ��ʱ������Ӯ�����ı�
usermgr.update_win_lose = function(userid, recent_date, wingold)
    ASSERT(userid and userid > 0)
	if true then return end 
    local userinfo = usermgr.GetUserById(userid)
    local user_history = usermgr.get_user_history(userinfo)

    if(userinfo ~=nil and user_history ~=nil)then
        --�����µ�����
        if(user_history[recent_date] == nil)then
            user_history[recent_date] = {}
            user_history[recent_date].win = 0
            user_history[recent_date].lose = 0
        end

        --������Ӯ�����ı�
        if(wingold ~= nil)then
            if(wingold > 0) then
                user_history[recent_date].win = user_history[recent_date].win + wingold
            else
                user_history[recent_date].lose = user_history[recent_date].lose - wingold
            end
        end

        --��ȡ���½�����Ӯ�����Ӯ����
        local history = usermgr.get_user_history_array(userinfo)

        --�����С����ʱ����,���Ҽ�����ڸ�ʽ
        local HISTORY_MIN = 2  --��֤������2�������Ա
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

        --д�����ݿ�ı���
        local recent_win, recent_lose, recent_date, last_win, last_lose, last_date

        --д���ݿ�
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

--------------------------����ר�÷�����ش���---------------------------
--����������У���������������ȡ��������Э�����������
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
    --ͳ��ÿһ��Э���ִ��Ч��
    room.perf.cmdlist[cmd].count = room.perf.cmdlist[cmd].count + 1
    room.perf.cmdlist[cmd].cost = room.perf.cmdlist[cmd].cost + difftime
    room.perf.cmdlist[cmd].aver = room.perf.cmdlist[cmd].cost / room.perf.cmdlist[cmd].count

    room.perf.recv_slicelen = room.perf.recv_slicelen + difftime
end

--������������ݣ�������뵽�������
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

--���ƴ���:
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

--����һ��buf������gameserver��
function send_buf_to_gamesvr_by_use_id(from_user_id, to_user_id, func, szErrorMsg)
    room.arg.gspp_from_user_id = from_user_id
    room.arg.gspp_to_user_id = to_user_id
    room.arg.gspp_szErrorMsg = szErrorMsg
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSPP")
end

--����һ��buf�����е�gamesvr��
function send_buf_to_all_game_svr(func)
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSSG")
end

--�㲥����б��������˽�����
function notify_sort_list_add(user_info)
    netlib.broadcastroom(
        function(buf, user)
            buf:writeString("ULAD")
            --��ǰ�û������ݿ�ID
			buf:writeInt(user_info.userId)
			--�ǳ�
			buf:writeString(user_info.nick)
			--ͷ��URL
			buf:writeString(user_info.imgUrl)
			--�����    user_info.gamescore
			buf:writeInt(user_info.gamescore)
			--����      user_info.gameInfo.exp
			buf:writeInt(user_info.gameInfo.exp)
			--����      user_info.gameInfo.prestige
			buf:writeInt(user_info.gameInfo.prestige)
			--����      user_info.gameInfo.integral
			buf:writeInt(user_info.gameInfo.integral)
        end
    )
end

--�㲥����б�������������
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
			-- ��ǰ�������������
			out_buf:writeString(sort_type)
			-- ��ǰ����������������,�����Լ�����Ϣ���Լ����ڵ�һλ
			local send_count = 50
			if (send_count > #sort_data) then
				send_count = #sort_data
			end
    		out_buf:writeShort(send_count + 1)
			--��ǰ�û������ݿ�ID
			out_buf:writeInt(user_info.userId)
			--�ǳ�
			out_buf:writeString(user_info.nick)
			--ͷ��URL
			out_buf:writeString(user_info.imgUrl)
			--�����    user_info.gamescore
			out_buf:writeInt(user_info.gamescore)
			--����      user_info.gameInfo.exp
			out_buf:writeInt(user_info.gameInfo.exp)
			--����      user_info.gameInfo.prestige
			out_buf:writeInt(usermgr.getprestige(user_info))
			--����      user_info.gameInfo.integral
			out_buf:writeInt(usermgr.getintegral(user_info))
    		for iuser = 1, send_count do
                --�û������ݿ�ID
                out_buf:writeInt(sort_data[iuser].userId and sort_data[iuser].userId or 0)
                --�ǳ�
                out_buf:writeString(sort_data[iuser].nick)
				--ͷ��URL
				out_buf:writeString(sort_data[iuser].imgUrl)
            	--�����    user_info.gamescore
            	out_buf:writeInt(sort_data[iuser].gamescore and sort_data[iuser].gamescore or 0)
            	--����      user_info.gameInfo.exp
            	out_buf:writeInt(sort_data[iuser].gameInfo.exp and sort_data[iuser].gameInfo.exp or 0)
            	--����      user_info.gameInfo.prestige
            	out_buf:writeInt(usermgr.getprestige(sort_data[iuser]) and usermgr.getprestige(sort_data[iuser]) or 0)
            	--����      user_info.gameInfo.integral
            	out_buf:writeInt(usermgr.getintegral(sort_data[iuser]) and usermgr.getintegral(sort_data[iuser]) or 0)
    		end
        end
    , user_info.ip, user_info.port)
end

-- ����鿴ҳ״̬
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
--����ָ����������Ľ������Ҫ�ͻ��˷�����Ҫ���������ͣ��ο�g_topusers�е�key�ֱ��Ӧgold, exp, prestige, integral
function OnRequireRoomSortList(in_buf)
    local sort_type = in_buf:readString()
    local user_key = getuserid(in_buf) --buf:ip()..":"..buf:port()
	local user_info = userlist[user_key]
	if not user_info then return end

    if g_topusers[sort_type] ~= nil then
        notify_sort_list(user_info, g_topusers[sort_type].data, sort_type)
    else
        TraceError("�ͻ��˷��ͷǷ��������ǣ����ԣ�")
    end
end

--���ͱ�������������б�
function OnRequireRoomUserList(in_buf)
    --TraceError("��������������б�")
    local user_key = getuserid(in_buf)
	local user_info = userlist[user_key]
	if not user_info then return end

    local sendlist = {}
    for k, v in pairs(userlist) do
        table.insert(sendlist, v)
    end
    notify_sort_list(user_info, sendlist, "integral")
end

-- �ͻ���֪ͨ����뿪�������������棨����������Ϸ�������뿪����, TODO:�رտͻ�����ô��?��
function OnClientLeaveRoom(in_buf)
    local user_key = getuserid(in_buf) --buf:ip()..":"..buf:port()
	local user_info = userlist[user_key]
	if user_info ~= nil then
		visible_page_list.unreg_page_user(user_info)
	end
end
--------------------------------------------------------------------------------
--�յ�������������б�
function OnQuestDeskList(in_buf)
    --TraceError("�յ�������������б�OnQuestDeskList")
    local userkey = getuserid(in_buf)
    local userinfo = userlist[userkey]
    if not userinfo  then
        TraceError("OnQuestDeskList�������Ϸ����û�ʶ�𣬺�������!")
        return 
    end 
    --ѡ�ĸ���TAB
    local desktype = in_buf:readShort()
    --ѡ�ĸ�СTAB
    local chosetab = in_buf:readShort()
    
    if desktype < 1 then return end
    if chosetab < 1 then return end
    
    --���ط������
    local hidenull, hidefull, isfast, isstart = in_buf:readByte(), in_buf:readByte(), in_buf:readByte(), in_buf:readInt()
    
    --����������������б�
    DoQuestDeskList(userinfo, desktype, chosetab, hidenull, hidefull, isfast, isstart)
end

--����������������б�
function DoQuestDeskList(userinfo, desktype, chosetab, hidenull, hidefull, isfast, isstart, send_func)
    --TraceError("����������������б�")
    if not userinfo  then
        TraceError("DoQuestDeskList�������Ϸ����û�ʶ�𣬺�������!")
        return 
    end

    local get_key = format("%d_%d_%d_%d_%d_%d_%d", userinfo.channel_id, desktype, chosetab, hidenull, hidefull, isfast, isstart)
    local resultarr = displaydesk[get_key] or {}
    --����������Ƶ���������б���ôҪ������û��ǲ��Ƕ�ӦƵ����

    --û������ʱ��
    local sendlist = {}
    local currtime = os.clock() * 1000
    if resultarr.savetime and currtime - resultarr.savetime < 1000 then
        --TraceError(format("������б�û���ڣ��Զ����ͻ����б�.."))
        sendlist = resultarr.sendlist
    else
        --ˢ���б�
        sendlist = get_show_desks(desktype, chosetab, hidenull, hidefull, isfast, isstart,userinfo.channel_id)
        --����˴�ɸѡ���б�
        resultarr.sendlist = sendlist
        resultarr.savetime = os.clock() * 1000
        displaydesk[get_key] = resultarr
        table.sort(sendlist, function(deskno1, deskno2) return deskno1 < deskno2 end)
        
    end	
    response_desk_list(userinfo, sendlist, send_func)
    
    --TraceError(format("desktype[%d], chosetab[%d], hidenull[%d], hidefull[%d], isfast[%d], isstart[%d]",desktype, chosetab, hidenull, hidefull, isfast, isstart));
    --TraceError(format("��ʱ:%d ms", os.clock() * 1000 - currtime))
end

--��������ʾ�����б�
function get_show_desks(desktype, chosetab, hidenull, hidefull, isfast, isstart,channel_id)
    local sendlist = {}
    
    --Ԥɸѡ����
    local FunPreSelector = function(deskno)

        local deskinfo = desklist[deskno]
        
        --��Ч����
        if not deskinfo then
            return false
        end
        
        
        --�������������:1��ͨ,2����,3VIP 10��VIP���巿
        if deskinfo.desktype ~= desktype and deskinfo.desktype  ~= 10  then
           return false
        end
        


        --���������Ƶ�����ԣ��������ӵ�Ƶ��������ҵ�Ƶ���Ų�ͬ���Ͳ���ʾ������
        if(desktype==4 and (deskinfo.channel_id==nil or deskinfo.channel_id==-1))then--Ƶ�������û��Ƶ��ID��ֱ�Ӳ���ʾ
            return false
        end

        if(deskinfo.channel_id~=nil and deskinfo.channel_id~=-1)then

            if(channel_id~=nil and  deskinfo.channel_id ~= channel_id)then
            
                return false
            end
        end

        --���ؿշ���
        if hidenull == 1 and deskinfo.playercount == 0 then
            return false
        end
        
        --�������˷���
        if hidefull == 1 and (deskinfo.playercount == deskinfo.max_playercount) then
            return false
        end
        
        --���طǿ��ٳ�
        if deskinfo.fast ~= isfast then
            return false
        end
        
        --�Ƿ������ѿ�ʼ��
        if(isstart == 1 and gamepkg.getGameStart(deskno)) then
            return false
        end
        
        return true
    end

    --�ٴ�ɸѡ(ntype:1�����˶��Ҳ����ģ�2�����˵ģ�3�ҿյ�)
    local FunSelector = function(deskno, isfast, peilv1, ntype)
        local deskinfo = desklist[deskno]
        --��Ч������
        if deskinfo == nil then
            return false
        end
        --ÿ��ɸѡʱȥ������10�����巿���������������ٵ�������
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
            --���˶��Ҳ���
            if ntype == 1 and playercount > 0 and playercount < max_playercount then  
                return true 
            --��������
            elseif ntype == 2 and playercount == max_playercount then  
                return true 
            --û�˵�����
            elseif ntype == 3 and playercount == 0 then
                return true 
            end
        end
        return false
    end

    --Ԥɸѡ
    local newdesklist = {}
    for i = 1, #desklist do
        if(FunPreSelector(i) == true)then
            table.insert(newdesklist, i)
        end
    end
    --��ȡ��ʾ����
    local displaycfg = hall.displaycfg.getdisplaycfg(desktype, chosetab)
    
    --�������������ֳ������ֳ�
    --Ҫ��������ʾ���˶��Ҳ��������ӣ�Ȼ����ʾ�������ӣ�����ʾ������
    --�������ʾ�Ķ����ˣ��ͱ�����ʾһ��������
    local tmp_display_count=0
    for ifast,fastarr in pairs(displaycfg) do
        --���ٻ���ͨ
        for peilv1, displaycount in pairs(fastarr) do
    
            local desk_by_peilv1 = {}
            local singlefull = -1  --����һ�������ӣ���������˾Ͱ��������
            local not_full_desk_count=0 --������û��
            local full_desk_count=0 --����
            
            for i = 1, #newdesklist do  
                if FunSelector(newdesklist[i], ifast, peilv1, 1) == true then --�������˶���û��������
                    not_full_desk_count=not_full_desk_count+1
                    table.insert(desk_by_peilv1, newdesklist[i])
                end
                if FunSelector(newdesklist[i], ifast, peilv1, 2) == true then  --�������˵�����
                    full_desk_count=full_desk_count+1
                    table.insert(desk_by_peilv1, newdesklist[i])
                end
            end
            
            --���ҿ�����,���һ��ʼû�ˣ�������ʾdisplaycount��������
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
            --ѡ����ͨר�ҷ����tabʱ����VIP�͹��巿����
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

--����һ�����ӵ��б�
function onsenddesklist(userinfo, sendlist)
  local desk_start    = 1
  local desk_end      = #sendlist
  local desk_count    = #sendlist

  --�жϲ����Ϸ���
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
          --����
          out_buf:writeString(vip_room_name ~= nil and vip_room_name or deskinfo.name)
          --��������:1��ͨ,2������,3VIP
          out_buf:writeByte(deskinfo.desktype)
          --�Ƿ������
          out_buf:writeByte(deskinfo.fast)
          --���������
          out_buf:writeInt(deskinfo.betgold)
          --���ӵ���ҳ���
          out_buf:writeInt(deskinfo.usergold)
          --����ȼ�
          out_buf:writeInt(deskinfo.needlevel)
          --Сä
          out_buf:writeInt(deskinfo.smallbet)
          --��ä
          out_buf:writeInt(deskinfo.largebet)
          --��Ǯ����
          out_buf:writeInt(deskinfo.at_least_gold)
          --��Ǯ����
          out_buf:writeInt(deskinfo.at_most_gold)
          --��ˮ
          out_buf:writeInt(deskinfo.specal_choushui)
          --���ٿ�������
          out_buf:writeByte(deskinfo.min_playercount)
          --��󿪾�����
          out_buf:writeByte(deskinfo.max_playercount)
          --��ǰ��������
          out_buf:writeByte(hall.desk.get_user_count(deskno))
          local watch_count = 0
          for k,v in pairs(deskinfo.watchingList) do
              watch_count = watch_count + 1
          end
          --��ս����
          out_buf:writeInt(watch_count)
          --�Ƿ�ʼ
          out_buf:writeByte(gamepkg.getGameStart(deskno) and 1 or 0)
          
          --�ǲ���VIP��
          out_buf:writeByte(0)
        end
      end
    , userinfo.ip, userinfo.port)
end

--����ҷ������������б�
function response_desk_list(userinfo, sendlist, send_func)
    --TraceError("response_desk_list")
    if not userinfo then return end;
    --֪ͨ�ͻ��˿�ʼ����
    local NoticeStart = function(userinfo)
        netlib.send(
            function(buf)
                buf:writeString("REDSS");
            end,userinfo.ip,userinfo.port);
    end
    --֪ͨ�ͻ��˷������
    local NoticeEnd = function(userinfo)
        netlib.send(
            function(buf)
                buf:writeString("REDSE");
            end,userinfo.ip,userinfo.port);
    end
    --���Ϳ�ʼ
    NoticeStart(userinfo);
    
    --û�м�¼
    if not sendlist or #sendlist <= 0 then
        NoticeEnd(userinfo);
        return;
    end
    
    --�����¼���࣬��Ҫ�ְ�����
    local packlimit = 20;  --ÿ����20����¼
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
--�յ��������ĳ�����ϵ�����б�
function OnRequireDeskUser(in_buf)
	--TraceError("OnRequireDeskUser")
	local userkey = getuserid(in_buf)
	local userinfo = userlist[userkey]
	if not userinfo  then
		TraceError("OnRequireDeskUser�������Ϸ����û�ʶ�𣬺�������!")
		return 
    end
	--ѡ�ĸ�deskno
	local deskno = in_buf:readInt()
	if deskno < 1 or deskno > #desklist then return end

    OnSendDeskUser(userinfo, deskno)
end
--����ҷ����������������(������ս���)��Ϣ
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
            --���������
            out_buf:writeInt(deskinfo.betgold)
            --���ӵ���ҳ���
            out_buf:writeInt(deskinfo.usergold)
            --��ǰ��������
            out_buf:writeByte(hall.desk.get_user_count(deskno))
            local watch_count = 0
            for k,v in pairs(deskinfo.watchingList) do
                if (duokai_lib == nil or (parent_play_arr[v.userId] == nil and duokai_lib.is_sub_user(v.userId) == 0)) then                   
                    watch_count = watch_count + 1
                end
            end            
            --��ս����
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
                --�û������ݿ�ID
                out_buf:writeInt(userarr[i].userId or 0)
                --�ǳ�
                out_buf:writeString(userarr[i].nick or "")
                --VIP���
                out_buf:writeByte(vip_level)
                --ͷ��URL
                out_buf:writeString(userarr[i].imgUrl or "")
                --���
                out_buf:writeInt(userarr[i].gamescore or 0)
                --Ƶ����ɫ
                out_buf:writeInt(userarr[i].channel_role or 0);
                --�Ա�
                out_buf:writeInt(userarr[i].sex or 0);
                --�Ƿ�ͨ�˼�԰
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
    trace(string.format("�յ��ͻ��˻Ự��Կ:%s, ��ַΪ:%s:%d", sessionkey, buf:ip(), buf:port()))

    --trace(type(userlist))
    --userlist = {}
    local key = getuserid(buf) --buf:ip()..":"..buf:port()
    local userinfo = userlist[key]
    --room.arg.score = userinfo.gamescore
    --ͬ���жϷ��ڵ�¼ʱ����
    --if (user) then
        --�Ѿ���ͬ���û���¼�������䣬�������ٵ���
        --todo:��Ҫ�Ͽ���ͻ��˵�����
        --
    --  trace("todo:ͬ���û��Ѿ���¼�������У��������ٵ�¼")
    --  return 0
    --else
        --doAddUser(buf:ip(), buf:port(), userid, key, sessionkey, -1, -1, startflag.notready)
        --����ǰ��¼�û�������Կ��֤�ɹ�����¼����ɹ�
        --trace("��֤��Կ�ɹ��� "..buf:ip()..":"..buf:port())
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
        --��������������Ϣ
        eventmgr:dispatchEvent(Event("do_kick_user_event", {userinfo=userlist[userKey]}));

        if (userinfo.desk and userinfo.site) then
            hall.desk.clear_users(userinfo.desk, userinfo.site)
        end
        --����ڹ�ս����ֻ�ӹ�ս�б����
        if (userinfo.desk and not userinfo.site) then
            DoUserExitWatch(userinfo)
        end

        --��������֪ͨ
        --TraceError("֪ͨ��������change_userstate_tofriend")
        --friendlib.change_userstate_tofriend(userinfo,0)

        if (userinfo.sockeClosed == true) then
            usermgr.DelUser(userKey)
        end
    else
        trace(userKey.."�û���δ��¼����ȡ������������֪ͨ")
    end
end

function onnotifyoffline(buf)
    buf:writeString("NTOF")
    buf:writeString(g_currentuser) --Ψһ�û���
    buf:writeString(g_currentusernick) --�z��
    buf:writeInt(g_olddeskno)
    buf:writeInt(g_oldsiteno)
    buf:writeByte(1) --��Ҫ��ʾ����Ļ��
end

function onclientoffline(buf)
    local userkey = getuserid(buf)
    eventmgr:dispatchEvent(Event("on_socket_close",	{user_key=userkey}))
    trace(format("�յ�����֪ͨ: %s", userkey))
    local userinfo = userlist[userkey]
    if (userinfo == nil) then
        return
    end
    
	--��������֪ͨ
	--TraceError("֪ͨ��������onclientoffline")
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
    --�жϲ����Ϸ���
    local sit_type = sittype or g_sittype.normal
    local bReloginUser = sit_type == g_sittype.relogin and 1 or 0
    ASSERT(nDeskNo <= #desklist and nSiteNo <= room.cfg.DeskSiteCount)

    local userinfo = userlist[userKey]    
    --���˫�����£�����ʧ��
    if sit_type ~= g_sittype.relogin and userinfo.site then
       TraceError("���ڱ��������Ϸ..ȴ����������ӣ�����"..debug.traceback());
       return;
    end
    
    --���˫����ݣ��ɵ�ԭ�����
    if userinfo.desk and userinfo.desk ~= nDeskNo then
       TraceError("���ڱ�����ӹ�ս..ȴ����������ӣ�����"..debug.traceback());
       desklist[userinfo.desk].watchingList[userKey] = nil
    end
        
     if (viproom_lib) then
        local succcess, ret = xpcall( function() return viproom_lib.on_before_user_site(userinfo, nDeskNo) end, throw)
        if (ret == 0) then
            return
        end
    end   

    --����10���Ӳ����£��߳�������


    --�ӹ�ս�б��Ƴ�
    local deskinfo = desklist[nDeskNo] or {}
        
    deskinfo.watchingList[userKey] = nil
    
    userinfo.olddesk = userinfo.desk or -1
    userinfo.oldsite = userinfo.site or -1
    
   
    --�����û����µ�λ��
    if bReloginUser == 0 then
        hall.desk.user_sitdown(userKey, nDeskNo, nSiteNo, startflag.notready, sit_type)
    end

    if (gamepkg ~= nil and gamepkg.AfterUserSitDown ~= nil) then
        local doSitdown1 = function()
            gamepkg.AfterUserSitDown(userinfo.userId, userinfo.desk, userinfo.site, sit_type)
        end
        getprocesstime(doSitdown1, "doSitdown1", 500)
    end

    --֪ͨ���˵�������Ϣ
    OnSendUserSitdown(userinfo, userinfo, 1, sit_type)  --�ȸ����Լ�����
    net_broadcast_game_info(userinfo, bReloginUser)

    --֪ͨ�����������˱�������
    local time1 = os.clock() * 1000
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(nDeskNo,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(nDeskNo,i) or ""]
            if (playingUserinfo and 
                playingUserinfo.offline ~= offlinetype.tempoffline and
                userinfo.userId ~= playingUserinfo.userId) then
                OnSendUserSitdown(playingUserinfo, userinfo, 1, sit_type)  --������������
                OnSendUserSitdown(userinfo, playingUserinfo, 1, g_sittype.normal)  --������������

                --��Ϸ��Ϣ
                OnSendUserGameInfo(userinfo, playingUserinfo, 0)
            end
            if(playingUserinfo == nil) then
                TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��2")
                hall.desk.clear_users(nDeskNo,i)
            end
        end
    end
    
    for k,watchinginfo in pairs(deskinfo.watchingList) do
        if(userlist[k] == nil) then
            deskinfo.watchingList[k] = nil
        else
            if (watchinginfo.offline ~= offlinetype.tempoffline) then
                OnSendUserSitdown(watchinginfo, userinfo, 1, sit_type)  --���������ս
            end
        end
    end
    local time2 = os.clock() * 1000
    if (time2 - time1 > 500)  then
        TraceError("֪ͨ��������������,ʱ�䳬��:"..(time2 - time1))
    end
    --֪ͨ�����������˱�������(����)

	--�ɷ������¼�
    local doSitdown2 = function()
        dispatchMeetEvent(userinfo, bReloginUser)
    end
    getprocesstime(doSitdown2, "doSitdown2", 500)
	

	--����������Ϣ��֮��
	if (gamepkg ~= nil and gamepkg.AfterUserSitDownMessage ~= nil) then
        local doSitdown3 = function()
            gamepkg.AfterUserSitDownMessage(userinfo.userId, userinfo.desk, userinfo.site, bReloginUser)
        end
        getprocesstime(doSitdown3, "doSitdown3", 500)
        eventmgr:dispatchEvent(Event("site_event",	_S{userinfo=userinfo,user_id = userinfo.userId, deskno = userinfo.desk, site = userinfo.site}))
        
    end
    usermgr.enter_playing(userinfo)
end

--�����������
function OnSendUserSitdown(userinfo, sitdowninfo, retcode, sittype)
    if not userinfo or not sitdowninfo then return end
    if not sitdowninfo.desk or not sitdowninfo.site then return end 
    local bReloginUser = sittype == g_sittype.relogin and 1 or 0
    local nStartFlag = gamepkg.getGameStart(sitdowninfo.desk, sitdowninfo.site) and 1 or 0
    local ship_ticket_count = sitdowninfo.propslist[tex_gamepropslib.PROPS_ID.ShipTickets_ID] or 0
    --�ھ�����
    local car_king_count =  -1 
    if car_match_lib then
    	car_king_count = car_match_lib.get_useing_king_count(sitdowninfo.userId)
    end
    netlib.send(
        function(buf, user)
            buf:writeString("RESD")
            buf:writeByte(retcode) --������� 0, �Ѿ����ˣ�1 ������, 2��վ����
            buf:writeByte(bReloginUser) --1 ��ʾ���µ�¼���û�,��Ҫ��������ͼ��, 0��ʾ������¼�û�,����������������
            buf:writeString(sitdowninfo.key) --�ĸ��û�����
            buf:writeString(sitdowninfo.nick) --���û��z��
            buf:writeInt(sitdowninfo.desk)
            buf:writeInt(sitdowninfo.site)
            buf:writeInt(sitdowninfo.olddesk) -- > -1 ��Ϊ������̨վ����
            buf:writeInt(sitdowninfo.oldsite)
            buf:writeInt(sitdowninfo.gamescore) --д�����
            buf:writeString(sitdowninfo.city) --��������
            buf:writeInt(room.cfg.beginTimeOut) --��ʱʱ��,������ʱֻд�˶�����ʱ��
            buf:writeString(sitdowninfo.imgUrl)
            buf:writeByte(sitdowninfo.sex)
            buf:writeByte(nStartFlag)  --��Ϸ��ʼ״̬
            buf:writeInt(sitdowninfo.userId)
            buf:writeString(string.HextoString(sitdowninfo.szChannelNickName))
            buf:writeInt(usermgr.getexp(sitdowninfo)) --��Ϸ����
            buf:writeInt(sitdowninfo.nSid) --Ƶ��Id
            buf:writeInt(desklist[sitdowninfo.desk].gamepeilv)
            buf:writeInt(sitdowninfo.tour_point or 0) --���·��;���������
            buf:writeInt(usermgr.getlevel(sitdowninfo)); --��Ϸ�ȼ�
            buf:writeInt(getSiteGold(sitdowninfo));     --���ϵĳ�����
            buf:writeInt(viplib.get_vip_level(sitdowninfo) or 0);     --�û���VIP�ȼ�
            buf:writeInt(sitdowninfo.short_channel_id or -1)
            buf:writeInt(sitdowninfo.home_status or 0)
            buf:writeByte(sitdowninfo.mobile_mode or 0)
            buf:writeInt(ship_ticket_count)
            buf:writeInt(car_king_count)
        end
    , userinfo.ip, userinfo.port);
end

--���ĳ����λ�ĳ�����
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
	--�����Ϸ����
	if (dessiteno == nil or dessiteno > room.cfg.DeskSiteCount or dessiteno < 1) then
		return
	end
	--û�д��ˣ���û�����£�����λ����ͬ�������κβ���
	local userkey = getuserid(buf)
    local userinfo = userlist[userkey]
	if (userinfo == nil or userinfo.desk == nil or userinfo.site == nil or userinfo.site == siteno) then
		return
	end
	local deskno = userlist[userkey].desk
	local siteno = userlist[userkey].site
	--���ǹ��᷿��������Ϸ��ʼ�ˣ�������Ҫ����λ�������ˣ������κβ���
	if (gamepkg.getGameStart(deskno, dessiteno) == true or hall.desk.isemptysite(deskno, dessiteno) == false) then
		return
	end
	--�û�վ����
	doUserStandup(userkey, false)
	--�û�����
	doSitdown(userkey, buf:ip(), buf:port(), deskno, dessiteno, g_sittype.normal)
	usermgr.enter_playing(userlist[userkey])
end

--[[
	-1��������
	-2�����Ѿ���ʼ��Ϸ���Ҳ������ս
	-3�����˲������ս
	-4��ս��������
	-5�����䲻����ֱ������
	-6�������˵���λ��
	-7���Ѿ������ڴ˹���
	-8���µ�ʱ���ֱ���������������
	-9�Ƿ�����
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
		if gamepkg and gamepkg.OnSitDownFailed then		--����ʧ��ʱ
            gamepkg.OnSitDownFailed(userinfo)
        end
	end

    if not userinfo or userinfo.site then
		return
	end

    --�����䲻����ֱ������
    if (groupinfo.can_sit == 0) then
        nRet = -5
        tools.FireEvent2(retFun, buf:ip(), buf:port())
        return
    end

	--�������Բ���
    if (deskno > #desklist or deskno <= 0) then --����id����
        nRet = -1
        tools.FireEvent2(retFun, buf:ip(), buf:port())
		--sitdownFailFun()
        return
    end

    local canqueue, value = can_user_enter_desk(userkey, deskno)
    if canqueue ~= 1 then
        --�����޷����뷿����Ϣ
        OnSendUserAutoJoinError(userinfo, canqueue, value)
        return
    end

    --�����Ϸ�Ƿ�ʼ
    local nstart = false
    if (gamepkg ~= nil and gamepkg.getGameStart ~= nil) then
        nstart = gamepkg.getGameStart(deskno)
    end

    local desktype = desklist[deskno].desktype
    if ((desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) and nstart == true) then --�����Ѿ���ʼ��
        nRet = -2
        tools.FireEvent2(retFun, buf:ip(), buf:port())
        trace("���俪ʼ��")
		sitdownFailFun()
        return
	end

	--��λ��Ϊ0ʱ����Ƿ��п�λ��
	if(siteno == 0)then
		siteno = hall.desk.get_empty_site(deskno)
		if(siteno == -1)then --λ��������
			nRet = -3
			tools.FireEvent2(retFun, buf:ip(), buf:port())
			sitdownFailFun()
			return
		end
	end

    --�Ѿ�����
	if(desklist[deskno].site[siteno].user ~= nil)then
		nRet = -6
		tools.FireEvent2(retFun, buf:ip(), buf:port())
		sitdownFailFun()
		return
	end

    --�ɹ�����
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

    --�ȷ�����Ϸ�쳣�ж���Ϣ  --ת�Ƶ�����ִ�У�����վ������ֱ�ӵĹ�ϵ
    if (deskno == nil) then
        return      --δ�����µĲ���Ҫ����������Ȼ�����
    end
    --��û���£�����վ�����ˣ�
    if (siteno == nil) then
        return
    end

    --վ��ǰ
    if (gamepkg ~= nil and gamepkg.OnUserStandup ~= nil) then
        xpcall(function() gamepkg.OnUserStandup(userinfo.userId, deskno, siteno) end, throw)
    end

    --�����û�վ��������Ϣ,(1����վ����)
    local rcode = 1;
    if(retcode ~= nil) then rcode = retcode; end
   -- TraceError("doUserStandupվ����:::::::::"..rcode);
    onsendstandup(userinfo, rcode);
     
    if (gamepkg ~= nil and gamepkg.OnPlayGame ~= nil) then
        gamepkg.OnPlayGame(deskno)
    end
    hall.desk.clear_users(deskno, siteno)
    eventmgr:dispatchEvent(Event("on_user_standup", {user_info = userinfo, desk_no = deskno, site_no = siteno}));
    --վ���
    if (gamepkg ~= nil and gamepkg.AfterOnUserStandup ~= nil) then
        xpcall(function() gamepkg.AfterOnUserStandup(userinfo.userId, deskno, siteno) end, throw)
    end
end

--�����л�����վ���������ŵ��ŶӶ�����
function DoAllDeskRobotStandup(nDeskNo)
    if (desklist[nDeskNo].playercount > 0) then --���������
        local bHavePeople = false
        local userKey  = nil
        for i = 1, room.cfg.DeskSiteCount do
            userKey = hall.desk.get_user(nDeskNo, i)
            if (userKey ~= nil and userlist[userKey].isrobot == false) then
                bHavePeople = true
                break
            end
        end
        --�õ�ǰ�����еĻ�����ȫ��վ����ȥ�Ŷ�, ���ѻ������ӵ���������
        if (bHavePeople == false) then
            trace("���û�����״̬�������Ƕ�ȥ�Ŷ�")
            for i = 1, room.cfg.DeskSiteCount do
                userKey = hall.desk.get_user(nDeskNo, i)
                if (userKey ~= nil ) then
                    doUserStandup(userKey,false)
                    userinfo = userlist[userKey]
                    if (userinfo ~= nil) then
                        UserQueueMgr.AddUser(userKey, userinfo.ip, userinfo.port, queryReasonFlg.gameOverAndLost)
                    else
                        trace("userInfoΪ�գ�")
                    end
                end
            end
        end
    end
end

--���û�����Ϸʱ�߳ɶ����û���������Ϸʱֱ�Ӵ�userlist�������
function DoKickUserOnNotGame(userkey, resetAllRobot)
    local key = userkey
    local nRet = ResetUser(key, resetAllRobot, true)
    if (nRet == 2) then
        doDelUser(key)
    end
    return nRet
end

--���û��ڴ���ʱ�߳������û������û�û�ڴ���ʱ����վ����,���������Ŷ�״̬
function ResetUser(userkey, resetAllRobot, is_kill)
    --������µ���Ϣ
    local bGameAlreadyStart = false
    local userinfo = userlist[userkey]
    if (userinfo == nil) then
        return
    end
    local userid = userinfo.userId
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
        bGameAlreadyStart = gamepkg.getGameStart(userinfo.desk, userinfo.site)
    end
    --����ֻ�б�������������״̬
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
    if bGameAlreadyStart then --��Ϸ�Ѿ���ʼ������Ϊ�û�������
        trace("�����û�״̬����Ϸ�ѿ�ʼ")
        doSetTempOfflineState(userinfo)
        return 1
    else  --��Ϸδ��ʼ������Ϊ�û�վ��������һ���������Ϸδ��ʼʱ���û�ֱ�ӹر�����Ϸ�ͻ���

        if(is_kill ~= nil and is_kill == true) then
            eventmgr:dispatchEvent(Event("do_kick_user_event", {userinfo=userlist[userkey]}));
        end

        trace("�����û�״̬����Ϸδ��ʼ")
        local nDeskNo = userinfo.desk
        doUserStandup(userkey,false)
        --����û�վ��������ȴ��Ϸδ��ʼ������û����Ŷӻ��Ķ�����ȡ����
        UserQueueMgr.RemoveUser(userkey)
        --���һ������Ҫ����Ȼ�ˣ�����ǰ�����ǻ����ˣ�����һ������ʱ��Ҫ���ƻ����ˣ����û�����վ���������ߵ���ǰ�����л����˵�������
        if (room.cfg.DeskMustHavePerson == 1 and nDeskNo ~= nil and room.cfg.ongameOverReQueue == 1 and resetAllRobot == true) then
            DoAllDeskRobotStandup(nDeskNo)
        end
        return 2
    end
end

--������Ҷ�����ֱ�ӽ����ƾ�
function OverGameOnAllOffline(userinfo)
    local nOffLineCount = 0
    for i = 1, room.cfg.DeskSiteCount do
        --ASSERT(userinfo.desk ~= nil, "��ǰ�û�û������")
        --ASSERT(desklist[userinfo.desk].site[i].user ~= nil, "��ǰ����û���û�")
        --ASSERT(userlist[desklist[userinfo.desk].site[i].user] ~= nil, "��ǰ����û���û�")

        if (desklist[userinfo.desk].site[i].user ~= nil and
            userlist[desklist[userinfo.desk].site[i].user] ~= nil and
            userlist[desklist[userinfo.desk].site[i].user].offline) then
            nOffLineCount = nOffLineCount + 1
        end
    end
    trace(userinfo.desk.."����ʱ�����û�"..nOffLineCount)
    if (nOffLineCount == hall.desk.get_user_count(userinfo.desk)) then
        trace("�����˶�����,ֱ�ӽ����ƾ�")
        if(gamepkg and gamepkg.OnAbortGame) then
            gamepkg.OnAbortGame(userinfo.key)
            return true
        end
    end
    return false
end
--��Э�飬�������ص�����
function onrecvsbacktohall(buf)
    trace(string.format("�û�(%s)����ش���", getuserid(buf)))
    local user_key = getuserid(buf)
    local user_info = userlist[user_key]
    if (user_info == nil) then
        return
    end
    pre_process_back_to_hall(user_info)
end

--��Э�飬�������ص�����,����user_info�İ汾
function pre_process_back_to_hall(user_info)
    local ret = 1
    if (duokai_lib) then
        ret = duokai_lib.on_back_to_hall(user_info)        
    end
    if (ret == 1) then
        eventmgr:dispatchEvent(Event("back_to_hall", {userinfo=user_info, user_info=user_info}));
        --������������˺ţ�����һ��Ҫ���߸��˺��뿪��
        if (duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 1) then
            user_info = usermgr.GetUserById(duokai_lib.get_parent_id(user_info.userId))
        end
        process_back_to_hall(user_info)
    end
end

--�������ص�����,
--ע���ڲ��ӿ�����ģ�鲻��ֱ�ӵ��ã���Ҫ����pre_process_back_to_hall������ֱ�ӷ�Э��onrecvsbacktohall
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
            buf:writeShort(1) --�Ƿ������˳�,0������1����
        end
        , userinfo.ip, userinfo.port)
end

--�û�����վ����--��һ��Ҫ�ش���
function onrecvstandup(buf)
    trace(string.format("�û�(%s)����վ����", getuserid(buf)))
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
    else  --��Ϸ�Ѿ���ʼ,������վ����
         bok = 0
    end
    netlib.send(
        function(buf)
            buf:writeString("REOT")
            buf:writeShort(bok) --�Ƿ������˳�
        end
        , userlist[userKey].ip, userlist[userKey].port)
end

--�������վ��
function onsendstandup(userinfo, retcode)
    --TraceError("�������վ��"..debug.traceback())
    --TraceError(format("����[%d]��λ��[%d]վ��,���ID[%d]", userinfo.desk, userinfo.site, userinfo.userId))
	if userinfo==nil then return end;
    if not userinfo.desk or not userinfo.site then return end
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("NTSU")
            buf:writeInt(retcode)        --���ش��� 0, ����վ������1 ����վ����
            buf:writeString(userinfo.key) --�ĸ��û�վ����
            buf:writeString(userinfo.nick)
            buf:writeInt(userinfo.desk)
            buf:writeInt(userinfo.site)
        end
    , userinfo.desk, borcastTarget.all);
end

--��¼���
function getRoomType()
    if (gamepkg.name == nil) then
        trace("û�г�ʼ��gamepkg.name����������Gama�ű��г�ʼ���������")
        return "error"
    end
    return gamepkg.name --��ǰ����Ϊddz, zjh, xxxx....
end

--����ͬһ��IP�ĵ�½�������,1���Ե�½��-1�������½
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

    --��˾IP��ַ:113.106.110.34
    if not LoginIPs or lgIP == "125.88.37.28" or tonumber(userinfo.userId) <= 1000 then sendFun(userinfo, 1, _U("���Ե�¼")) return 1 end --���ݲ�����
    local iprarr = LoginIPs[lgIP];
    local allowMax = 10;
    local sys_today = os.date("%Y-%m-%d", os.time()); --ϵͳ�Ľ���

    if(not iprarr or iprarr["today"] ~= sys_today) then
        iprarr = {};
        iprarr["logincount"] = 0;
        iprarr["today"] = sys_today;
    end
    if(iprarr[userinfo.userId] == 1) then
        sendFun(userinfo, 1, _U("���Ե�¼"));
        return 1
    end
    if(iprarr["logincount"] >= allowMax) then
        --��׼��¼��
        --local msg = format("�Բ��𣬸�IP������������˻����������ƣ�����������!");
        local msg = tex_lan.get_msg(userinfo, "h2_msg");
        sendFun(userinfo, -1, _U(msg));
        return -1
    else
        --sendFun(userinfo, 1, _U("���Ե�¼"));
        sendFun(userinfo, 1, _U(tex_lan.get_msg(userinfo, "h2_msg_1")));
    end
    iprarr[userinfo.userId] = 1;
    iprarr["logincount"] = iprarr["logincount"] + 1;

    LoginIPs[lgIP] = iprarr;

    return 1
end

--�û�����ʱ����״̬�У��ٴε�¼��
function doUserRelogin(oldUserKey, newUserKey, newIp, newPort)
    local oldUserInfo = userlist[oldUserKey]
    if (oldUserInfo == nil) then
        TraceError("doUserRelogin�ص�½�û���������ǰ���û���ϢΪ��")
        return
    end
    room.arg.oldkey = oldUserInfo.key
    room.arg.oldreloginip = oldUserInfo.ip
    room.arg.oldreloginport = oldUserInfo.port
    room.arg.olddeskno = oldUserInfo.desk
    room.arg.oldsite = oldUserInfo.site

    --��key֮ǰ�����ü���û�״̬
    usermgr.ResetNetworkDelay(oldUserKey)
    --����ŶӶ���������û�
    UserQueueMgr.RemoveUser(oldUserKey)
    --�޸��û��б���Ϣ
    usermgr.RelpaceUserKey(oldUserInfo.key, newUserKey)
    oldUserInfo.ip = newIp
    oldUserInfo.port = newPort
    oldUserInfo.relogin = true
    oldUserInfo.sockeClosed = false
    usermgr.ResetReloginState(newUserKey)      --��ʼ���ص�¼״̬
    --����ص�½ip�˿�û���ظ�������ǰ��socketû�б��رչ�����ر���ǰ��socket
    --todo������ֵ�һ�κ͵ڶ��ε�ip protһ�����������ǰ��socketй¶
    if oldUserInfo.sockeClosed == false then
        tools.CloseConn(room.arg.oldreloginip, room.arg.oldreloginport)
    end
    trace(format('���µ�¼ʱ(newkey=%s)����¼��KEY(prekey):%s', userlist[newUserKey].key, userlist[newUserKey].prekey))

    room.arg.newkey = newUserKey
    room.arg.newreloginip = oldUserInfo.ip
    room.arg.newreloginport = oldUserInfo.port

    -- ֪ͨGameCenter�������, �ر��޸ģ�û��ʹ��enter_playing
    notify_gc_user_site_state(userlist[newUserKey].userId, 1)
    --֪ͨ���д����û����пͻ����µ�¼��Ҫ����IP��ַ�滻����
    --���µ�¼�Ŀͻ��ˣ��ڴ�����ʼ��������������Ϸ�ͻ���
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
    local szUserId = nil     --todo �����Ƿ����������userid���������userid��ʵ�Ƿ������ϵ�userName���Ժ�Ҫȫ���Ĺ����ſ���
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
    local nRegSiteNo = 0 --ע��վ��ID
    local msg = "nouse"   --���صĵ�¼��Ϣ
    local tableUserInfo = nil
    local szUserSession = nil
    local kickFun = function(outBuf)
        outBuf:writeString("GMSK") -- gmǿ������
        outBuf:writeInt(1) --��ʾ��GM�ߵ���
    end
    
    if (string.len(szUserInfo) == 0 )then  --˵���û�û�е�¼��gamcenter
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
        nRegSiteNo = tableUserInfo[10] --�õ�ע��վ�㡣
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
    if (nRet == 1) then  --��¼��gamecenter,��ο���½����ͼ���������
        --TraceError('ok1')
        local userinfo = usermgr.GetUserById(tonumber(szUserId))
        --[[
        if (userinfo ~= nil and userinfo.desk ~= nil and gamepkg.getGameStart(userinfo.desk) == true) then
            --TraceError('ok2')
            raiseSiteStateEvent(userinfo);
            doUserRelogin(userinfo.key, szUserKey, szIpInfo[1], tonumber(szIpInfo[2]))
            nRet = 2 --���µ�½
        else--]]
        if (userinfo ~= nil) then
            --ASSERT(userinfo.offline == nil, "�û����ߣ��쳣���")
            if(userinfo.offline ~= nil) then
                TraceError(format("���[%d]����״̬�쳣[%s]", userinfo.userId, tostring(userinfo.offline)))
            end
            userinfo.sockeClosed = true  --Ϊ���ߴ��û���Ϣ,��Ҫǿ������socketcolse Ϊtrue
            DoKickUserOnNotGame(userinfo.key, false)
            if (not (szIpInfo[1] == userinfo.ip and tonumber(szIpInfo[2]) == userinfo.port)) then                
                tools.CloseConn(userinfo.ip, userinfo.port)
            end
            nRet = 1
        else
             if (userlist[szUserKey] ~= nil) then --�����˵�½����ip�˿ں��Լ��ظ�
                nRet = -103
                TraceError("NTLG�����˵�½����ip�˿ں��Լ��ظ�����ֵ-103")
             else
                 nRet = 1
             end
        end
    end
    table.insert(clockQueue, os.clock()*1000);

    if (szPlayingRoomName == nil) then
        szPlayingRoomName = "������"
    end
    local ret, errmsg, reasonmsg = xpcall(function() return gamepkg.CanEnterGameGroup(szPlayingRoomName,
              tonumber(szPlayingRoomId), tonumber(szScore)) end, throw) --��¼�ʺ��Ƿ��ڴ���
    if(errmsg == -102) then
    	if (tonumber(last_sid) ~= tonumber(nSid)) then --�ϴκ���β���ͬһ�����䣬֪ͨgc�޸ķ����sid
            local szSendBuf = szUserId..","..last_sid --���͸�gc����������Ϣ            
            tools.SendBufToUserSvr(gamepkg.name, "NTGSID", "", "", szSendBuf) --�������ݵ�����ˣ�֪ͨ������������Ǯ��
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
        userinfo.szChannelNickName = szChannelNickName --�û�Ƶ����
        userinfo.nSid = tonumber(nSid)
    else
        local retFun = function(buf)
            buf:writeString("RELG")
            buf:writeShort(nRet) --ע�������룬1=�ɹ���0ʧ��
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
        --�õ��û���Ϸ��ϸ��Ϣ

        --ȡ�����ڽ��еľ�����ID��Ĭ�ϵ���
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
			local userinfo = usermgr.GetUserById(userinfo.userId)	--���ݿ��ѯ����������˳��򲻴���
			if userinfo then
                --��Ϸ��Ϣ������������������Ϸ���������������
                dblib.cache_exec("get_game_info_copy", {userinfo.userId}, function(dtgameinfo)
                    --�����ѯyou���
                    local userinfo = usermgr.GetUserById(userinfo.userId)	--���ݿ��ѯ����������˳��򲻴���
                    if userinfo == nil then
                        return
                    end
                    if(dtgameinfo~=nil and #dtgameinfo ~= 0 and dtgameinfo[1]["game_info"] ~= nil and dtgameinfo[1]["game_info"] ~= "") then
                        userinfo.gameinfo_copy = table.loadstring(dtgameinfo[1]["game_info"])
                    else
                        userinfo.gameinfo_copy = {e={},p={},i={},q={}}
                    end
                    --�ɾ�ϵͳ��¼������
                    local gameeventdata1 = {userinfo = userinfo, data = dt[1] or {}, alldata = dt}
    				eventmgr:dispatchEvent(Event("h2_on_user_login_forachieve", gameeventdata1));
                    --����û�������Ϣ,���������ȼ�������
                    --add_user_common_info(userinfo, dt[1], dt)

                    --д����Ϸ��Ϣ������db
                    update_gameinfo_copy(userinfo)

                    --�õ��û���BUFF
                    bufflib.get_user_buff(userinfo.userId)                   
                
                    --������Ϸ�ĸ�����Ϣ
    				if(gamepkg and gamepkg.OnBeforeUserLogin) then
    					gamepkg.OnBeforeUserLogin(userinfo, dt[1], dt)
                    end
                    

                    local func = function()
        				NotifyGameLoginOk(userinfo)
                        --������ͬIP��¼�˻�����
                        if(is_sub_user == 0 and LoginIP_Restrict(userinfo, userinfo.ip) < 0) then
                            --usermgr.DelUser(userinfo.key)
                            --tools.CloseConn(userinfo.ip, userinfo.port)
                            return
                        end
                        --֪ͨ�ͻ��˴�����ά����������б�(ֻ����100�������µķ���ʵ��)
                        if(#desklist <= 100) then
                            notify_sort_list_add(userinfo)
                        end
                        --�û���¼��ɺ�                    
                        if(gamepkg and gamepkg.after_user_login) then
                            gamepkg.after_user_login(userinfo)
                        end
                        local gameeventdata = {userinfo = userinfo, user_info = userinfo, data = dt[1] or {}, alldata = dt}
                        eventmgr:dispatchEvent(Event("h2_on_user_login", gameeventdata));
                    end
                    --ˢ��vip��Ϣ
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

--����û�������Ϣ
function add_user_common_info(userinfo, data, alldata)
    --��Ӿ���������
    userinfo.tour_point         = data["point"] or 0
    userinfo.gameInfo.exp 		= data["experience"]
    userinfo.gameInfo.level 	= data["level"]
    userinfo.gameInfo.prestige 	= data["prestige"]
    userinfo.gameInfo.integral  = data["integral"]
    userinfo.gotwelcome = data["integral"]  --�Ƿ���ȡ���״ν̳̽���(����û�л���)
    if userinfo.gotwelcome == nil then userinfo.gotwelcome = 3 end  --0û������1������û�������3����Ҳ�������

    --У��ȼ��;���ĺϷ���
    if usermgr.getlevel(userinfo) > room.cfg.MaxLevel then
        userinfo.gameInfo.level = room.cfg.MaxLevel
        userinfo.gameInfo.exp = g_ExpLevelMap[room.cfg.MaxLevel]
        --д���ݿ�
        dblib.cache_set(gamepkg.table, {level = room.cfg.MaxLevel}, "userid", userinfo.userId)
        --�ȼ��뾭���Ӧ
        dblib.cache_inc(gamepkg.table, {experience = g_ExpLevelMap[room.cfg.MaxLevel]}, "userid", userinfo.userId)
    end
    ---���������Ϸ�յ���Ӯ��
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

    --todo:������Ϣ��û��ˢ�£�ֻ�ڵ�½ʱ��ˢ. ����Ҳ��ҪҪ����Ϸ������
    --������Ϸ������Ϣ
    --������Ϣ
    if(userinfo.gameinfo_copy.e == nil) then
        userinfo.gameinfo_copy.e = {}
    end
    userinfo.gameinfo_copy.e[gamepkg.name] = userinfo.gameInfo.exp

    --������Ϣ
    if(userinfo.gameinfo_copy.p == nil) then
        userinfo.gameinfo_copy.p = {}
    end
    userinfo.gameinfo_copy.p[gamepkg.name] = usermgr.getprestige(userinfo)
    --������Ϣ
    if(userinfo.gameinfo_copy.q == nil) then
        userinfo.gameinfo_copy.q = {}
        userinfo.gameinfo_copy.q[gamepkg.name] = {}
    end
    --������Ϣ
    if(userinfo.gameinfo_copy.i == nil) then
        userinfo.gameinfo_copy.i = {}
    end
    userinfo.gameinfo_copy.i[gamepkg.name] = usermgr.getintegral(userinfo)
end

--TODO:������޻ᳬ��2K��һ��Ҫ����
--д����Ϸ��Ϣ���������ݿ�
function update_gameinfo_copy(userinfo)
    local sz = table.tostring(userinfo.gameinfo_copy)
    --todoΪ����inc����
    dblib.cache_set("user_game_info_copy", {game_info = sz}, "user_id", userinfo.userId)
end

--usermgr.....
--�յ���ɵ������б�
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

--������ɵ������б�
usermgr.update_user_completed_quest = function(userinfo, questlist)
    if(userinfo.gameinfo_copy.q == nil) then
        userinfo.gameinfo_copy.q = {}
    end
    userinfo.gameinfo_copy.q[gamepkg.name] = {}

    for k, v in pairs(questlist) do
        table.insert(userinfo.gameinfo_copy.q[gamepkg.name], v)
    end
end


--֪ͨ��Ϸ��½�ɹ�
function NotifyGameLoginOk(userinfo)
    --TraceError("NotifyGameLoginOk");
    if(userinfo == nil) then
        return
    end
    --����û��Ѿ���½ok�����õ�½��
    if (usermgr.IsLogin(userinfo) == true) then
        return
    end    
    local nRet = userinfo.nRet
    userinfo.nRet = nil
    
    local retFun = function(buf)
        buf:writeString("RELG")
        buf:writeShort(nRet) --ע�������룬1=�ɹ���0ʧ��
        buf:writeString(tostring(os.time()))
    end    
    tools.FireEvent2(retFun, userinfo.ip, userinfo.port)

    --���߿ͻ��˽�ɫ����Ƿ�����
    on_recve_show_authorbar(userinfo)

	--��½ʱ���߿ͻ����ǲ���Ҫ��������߱����ĵ���
	if(tex_ip_protect_lib)then
        --�࿪�����û�����ip�����ж�
        if (duokai_lib == nil or (duokai_lib ~= nil and duokai_lib.is_sub_user(userinfo.userId) == 0)) then
		    tex_ip_protect_lib.check_ip_address_protect(userinfo)
        end
	end
		    
    --���������Ľ�
    --if(tex_match)then
    --	xpcall(function() tex_match.on_after_user_login(userinfo) end, throw)
    --end    
	
	--��ʼ����ҵļ�����Ϣ
    if(tex_lan)then
    	xpcall(function() tex_lan.on_after_user_login(userinfo) end, throw)
    end   
    
    
    --��ʼ��ʥ������������Ҫ�õ�
    --if(christmasLib)then
    --	xpcall(function() christmasLib.on_after_user_login(userinfo) end, throw)
    --end   
   	
   	
   	--��ʼ����ҷ�����Ϣ
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
            if (userinfo.nSid == nil) then --Ƶ����
                buf:writeInt(0)
            else
                buf:writeInt(userinfo.nSid)
            end
            buf:writeInt(userinfo.userId)
            buf:writeString(string.md5(userinfo.userId.. "97C47DV3-54F2-35Dd-FE8X-58X4DVA33FB"))
            buf:writeInt(usermgr.getexp(userinfo))
            buf:writeInt(groupinfo.can_sit)
            buf:writeInt(userinfo.tour_point or 0)--����������
            buf:writeInt(userinfo.gotwelcome or 3)
            buf:writeByte(usermgr.check_user_get_bankruptcy_give(userinfo) or 0)  --�Ƿ������ȡ�Ʋ��ȼ�
            buf:writeInt(userinfo.channel_id or -1)
            buf:writeInt(tonumber(userinfo.short_channel_id) or -1)
            buf:writeString(userinfo.home_face or "")
            buf:writeInt(userinfo.home_status or 0)
            buf:writeByte(tasklib.is_new_user(userinfo));
        end
        tools.FireEvent2(retFun, userinfo.ip, userinfo.port)

		--����groupinfo
		notify_group_info(userinfo)

        --֪ͨ����������Ϣ
		notify_hall_prestige(userinfo)

        --֪ͨ��������Ϸ��Ϣ����
        net_send_gameinfo_copy(userinfo,userinfo)
        
        --֪ͨ�����Ƿ���ʾÿ�յ�½��Ǯ
        xpcall(
            function()
                give_daygold_check(userinfo)
            end,throw)
        if (gamepkg ~= nil and gamepkg.AfterUserLogin ~= nil) then
            gamepkg.AfterUserLogin(userinfo) --�û���¼��
        end


         if (nRet == 2) then
            local bSendDeskInfo = 1;
            if (gamepkg.OnBeforeUserReLogin) then --ѯ����Ϸ�Ƿ���������Ƿ�ص���Ϸ�� 1 ����0 ������
                bSendDeskInfo = gamepkg.OnBeforeUserReLogin(userinfo);
            end
            if (bSendDeskInfo == 1) then
                DoSendDeskInfo(userinfo) --��ͻ��˷��͵�ǰ�Ƶ���Ϣ
            else
                usermgr.ResetReloginState(userinfo.key);
                doUserStandup(userInfo.key, false);
            end
        end
    end
end

--���͵�ǰ��������Ϣ
function DoSendDeskInfo(userInfo)
    --ASSERT(userInfo.desk ~= nil and userInfo.site ~= nil)
	if(userInfo == nil or userInfo.desk == nil or userInfo.site == nil) then
		TraceError("���µ�¼���Զ�����ԭ����λ��ʱʧ�ܣ���λ������!")
		return
	end
    trace(format('���µ�¼���Զ�����ԭ����λ��(ip=%s, port=%d, desk=%d, site=%d',userInfo.ip, userInfo.port, userInfo.desk, userInfo.site))
    room.arg.deskno = userInfo.desk
    room.arg.siteno = userInfo.site
    room.arg.curusernick = userInfo.nick
    doSitdown(userInfo.key, userInfo.ip, userInfo.port, userInfo.desk, userInfo.site, g_sittype.relogin);
    gamepkg.OnUserReLogin(userInfo)
end

--����groupinfo
function notify_group_info(userinfo)
    netlib.send(
        function(buf)
            buf:writeString("NTGP")
            buf:writeInt(groupinfo.groupid)
			buf:writeInt(groupinfo.isguildroom)
			--����ר�÷���Ļ�������ѡ���ʱ�
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


--֪ͨˢ�´�����������Ϣ
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

--������Ϸ��Ϣ�������ͻ���
function net_send_gameinfo_copy(userinfo,request_userinfo)
    local gameinfocp = request_userinfo.gameinfo_copy
    local userid     = request_userinfo.userId              --�û�ID
    local nick       = request_userinfo.nick                --�ǳ�
    local sex        = request_userinfo.sex                 --�Ա�
    local from       = request_userinfo.szChannelNickName   --����
    local gold       = request_userinfo.gamescore           --���
    local face       = request_userinfo.imgUrl              --ͷ��
    local exp        = usermgr.getexp(request_userinfo)--����

    netlib.send(
        function(buf)
            buf:writeString("REGICP")
            --������Ϣ
            buf:writeInt(userid)    --�û�ID
            buf:writeString(nick)   --�ǳ�
            buf:writeByte(sex)      --�Ա�
            
            if(request_userinfo.mobile_mode~=nil and request_userinfo.mobile_mode==2)then

    	    	--buf:writeString(string.HextoString(from).._U("���ֻ��ͻ��ˣ�"))
    	    	buf:writeString(string.HextoString(from).._U(tex_lan.get_msg(userinfo, "h2_msg_2")))
    	    else
    	    	buf:writeString(string.HextoString(from))   --����
    	    end
            
            buf:writeInt(gold)      --���
            buf:writeString(face)      --ͷ��
            buf:writeInt(exp)       --����


            --������Ϸ��Ϣ
            local action_game_name = {}
            for k, v in pairs(gameinfocp.p) do
                table.insert(action_game_name,k)
            end

            buf:writeByte(#action_game_name)    --������Ϸ����

            for i = 1, #action_game_name do
                local game_name =   action_game_name[i]
                buf:writeString(game_name)             --��Ϸ����
                buf:writeInt(gameinfocp.p[game_name] or 0)  --����ֵ
                buf:writeInt(gameinfocp.i[game_name] or 0)  --����ֵ

                local finished_count = 0    --������������
                if (gameinfocp.q[game_name] ~= nil) then
                    for k1, v1 in pairs(gameinfocp.q[game_name]) do
                        finished_count = finished_count + 1
                    end
                end
                buf:writeInt(finished_count)            --�������
                buf:writeInt(room.cfg.totalquestcount)  --������
            end

            --todo:��ʱ�������Ȩ���ý����������Ժ�Ҫ�ĵ�
            local goldPaiNum = 0
            buf:writeInt(goldPaiNum)            --��������

            --������Ӯ����
            local history = usermgr.get_user_history_array(request_userinfo)
            local history_count = #history
            buf:writeByte(history_count);                       --���鳤��
            for i=1,#history do
                buf:writeString(history[i].date);	            --����
                buf:writeInt(history[i].win);	                --Ӯ�Ĵ���
                buf:writeInt(history[i].lose);                  --��Ĵ���
            end
            local server_time = os.date("%Y-%m-%d %H:%M:%S")
            buf:writeString(server_time)                        --������ʱ��
        end
    , userinfo.ip, userinfo.port)
end

--�յ�����ˢ����Ϸ������Ϣ
function onrecv_gameinfo_copy(buf)
    local userkey = getuserid(buf)
    local userinfo = userlist[userkey]
    local request_userid = buf:readInt()    --Ҫ�����userid
    local request_userinfo = usermgr.GetUserById(request_userid)

	if not request_userinfo then
		--��gc��
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
	--��gc��
	cmdHandler["_SNDINFO"] = function(buf)
		buf:writeString("SNDINFO")
		buf:writeInt(fromuserid)

        local new_userinfo = {}
        new_userinfo.gameinfo_copy = touserinfo.gameinfo_copy
        new_userinfo.userId = touserinfo.userId              --�û�ID
        new_userinfo.nick = touserinfo.nick               --�ǳ�
        new_userinfo.sex = touserinfo.sex                 --�Ա�
        new_userinfo.szChannelNickName = touserinfo.szChannelNickName   --����
        new_userinfo.gamescore = touserinfo.gamescore           --���
        new_userinfo.imgUrl = touserinfo.imgUrl              --ͷ��
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

--�����ֻ���½ʱҪ�õ�һЩ�������ڴ���
function on_mobile_login(buf)
	--TraceError("mobile login")
	local user_info = userlist[getuserid(buf)]; 
    --˵�� 0:PC, 1:MAC ios/Iphone, 2:Android, 3:Windows Phone 7
    local mobile_mode = buf:readInt()
    --[[˵�� MAC ios/Iphone��
							0:Iphone
							1:Ipad
							2:Itouch
							4:MAC

							Android:
							 0:HTC
							 1:����
	--]]
    local mobile_type = buf:readString()
    local mobile_screen = buf:readString()
    
    --����Ϣ�������ڴ��й���̵���
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
        userinfo.offline = offlinetype.tempoffline  --��ʱ����
        userinfo.offlinetime = os.time()            --��¼��ʱ���ߵ�ʱ��
        --������Ҷ��йܣ���ֱ�ӽ����ƾ�
        local bRet = OverGameOnAllOffline(userinfo)
        if (bRet == false and gamepkg ~= nil and gamepkg.OnTempOffline ~= nil) then
            gamepkg.OnTempOffline(userinfo)
        end
        if bRet == false then
            raiseSiteStateEvent(userinfo)
        end
    end
end


--��Ӧ��λ״̬�¼�(�����¼�)
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

--�㲥ϵͳ��ʾ
function gm_broadcastmsg(msg,styleId)
   if(msg ~= nil) then
        broadcastmsg(msg,styleId)
   end
end

--��һ��Ҫ�ﵽ��Ϸ��ʼ��������Ҫ�����������ٵ�������
DeskQueueMgr.SortDeskPlayerCount = function(a, b)
    --�����Ϸ�Ѿ���ʼ�����������ڶ��к���
    local bGameAlreadyStart1, bGameAlreadyStart2= gamepkg.getGameStart(a), gamepkg.getGameStart(b)
    if (bGameAlreadyStart1 == true and bGameAlreadyStart2 == false) then
        return false
    elseif (bGameAlreadyStart2 == true and bGameAlreadyStart1 == false) then
        return true
    elseif (bGameAlreadyStart1 == true and bGameAlreadyStart2 == true) then
        return a < b
    end

    --���һ���Ѿ����ˣ������������
    if (room.cfg.DeskSiteCount <= desklist[a].playercount and room.cfg.DeskSiteCount > desklist[b].playercount ) then
        return false
    elseif (room.cfg.DeskSiteCount <= desklist[b].playercount and room.cfg.DeskSiteCount > desklist[a].playercount) then
        return true
    elseif (room.cfg.DeskSiteCount <= desklist[b].playercount and room.cfg.DeskSiteCount < desklist[a].playercount) then
        return a < b
    end

    --��Сä�Ŷӣ�Сä�͵���ǰ��
    local smallbet1 = desklist[a].smallbet or 0
    local smallbet2 = desklist[b].smallbet or 0
    if(smallbet1 ~= smallbet2) then
        return smallbet1 < smallbet2
    end

    --�����ֱ���Ҫ�����˲ſ��Կ�ʼ��Ϸ
    local nMiniNeedCount1 = room.cfg.MinDeskSiteCount - desklist[a].playercount
    local nMiniNeedCount2 = room.cfg.MinDeskSiteCount - desklist[b].playercount
    if (nMiniNeedCount1 == nMiniNeedCount2) then --�������������ͬ�������˶��  ������ǰ��
        return a < b
    elseif (nMiniNeedCount1 <= 0 and nMiniNeedCount2 <= 0) then --������������Կ�ʼ�������ٵģ�����ǰ��
        return  desklist[a].playercount > desklist[b].playercount
    elseif (nMiniNeedCount1 <= 0 and nMiniNeedCount2 > 0) then --���һ�����Կ�ʼ����һ�����ܿ�ʼ�����Կ�ʼ������ǰ��
        return  true
    elseif (nMiniNeedCount1 > 0 and nMiniNeedCount2 <= 0) then --���һ�����Կ�ʼ����һ�����ܿ�ʼ�����Կ�ʼ������ǰ��
        return false
    elseif (nMiniNeedCount1 > 0 and nMiniNeedCount2 > 0) then --������������ܿ�ʼ, ��Ҫ���ٵ�����ǰ��
        return nMiniNeedCount1 < nMiniNeedCount2
    end
end


function OnRecvNetworkCheck(buf)
    usermgr.ResetNetworkDelay(getuserid(buf))
end

--��ʱ�������û�
function doCheckOfflineUser()
    local time1 = os.clock() * 1000

    --ɾ����ʱ�û�
    usermgr.DelOffLineUser()  --ע�⣬��Ҫ�����溯���ߵ�ʹ�ã����ܻᶨʱ�ߵ����е���
    --����������Щ�û��쳬ʱ�ˣ�����쳬ʱ����nttt

    local time2 = os.clock() * 1000

    usermgr.CheckNetWorkDelay()

    local time3 = os.clock() * 1000
    if (time2 - time1 > 1000) then
        TraceError("usermgr.DelOffLineUser ����1sʱ��"..(time2 - time1))
    end
    if (time3 - time2 > 1000) then
        TraceError("usermgr.CheckNetWorkDelay ����1sʱ��"..(time3 - time2))
    end
end

--ע��gameserver
function OnRegisterGameSvr(buf)
    buf:writeString("GCRG")
end

function InitUserOnline()
	local OnNotifyRegSite = function(dt)
		if (#dt == 0) then
			TraceError("��������ȡע��վ����Ϣ����")
			return
		end
		for k, v in pairs(dt) do
			userOnline[tonumber(v["site_no"])] = { --������
							totalCount = 0, --�û�����������
							playingCount = 0,--�û�����������
							robotCount = 0, --�����˵ĸ���
							}
		end
		TraceError("��ȡע��վ����Ϣ�ɹ�")
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
	checkGamePkg()	-- �����Ϸʵ�ֵĽӿ��Ƿ�����
	-- �����Ϸ��ʼ�������Լ�
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
		TraceError("\n\t����ontimecheckִ��ʱ����"..tostring(timeinterval)
		.."����\n\tÿ������ִ��ʱ����"..tostringex(lenCheck)
		.."����\n\t������������"..tostring(room.perf.send_packcount)
		.."��\tִ��ʱ����"..tostring(room.perf.send_slicelen)
		.."����\n\t�յ���������"..tostring(room.perf.recv_packcount)
		.."��\tִ��ʱ����"..tostring(room.perf.recv_slicelen)
		.."����")
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
    --������ú���ǰ��һ��������Ҫ�����Ƿ���ʾ��־״̬
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
        --ÿ����һ���Ƿ�Ҫ��������
		table.insert(clockQueue, os.clock()*1000);
        if (math.mod(room.time, room.cfg.timerandomwait) == 0) then --ÿ3���һ��
            doProcessQueue()
        end
    end
    table.insert(clockQueue, os.clock()*1000);
    if (math.mod(room.time, room.cfg.timeOfflineInterval) == 0) then --��ʱ�������û�
        doCheckOfflineUser()
    end
    --trace(format("�������:%d", room.time))
    table.insert(clockQueue, os.clock()*1000);
    gamepkg.ontimecheck(); --�����������ʾ����Ϸ�ű���û�г�ʼ�� gamepkg �������
	table.insert(clockQueue, os.clock()*1000);
    ----------------------------------------------------
    --�ɷ�ʱ��ʱ�䣬ÿ����һ��
    dispatchTimerEvent()
	table.insert(clockQueue, os.clock()*1000);

    --�ɷ����������䶯����
	xpcall(function()
		dispatchDeskChangeEvent()
	end, throw)
	table.insert(clockQueue, os.clock()*1000);

	--��ʱ��������������Top����
	xpcall(function()
		do_users_prop_sort()
	end, throw)
	table.insert(clockQueue, os.clock()*1000);

    --����ִ��plan
	timelib.ontimecheck()
	table.insert(clockQueue, os.clock()*1000);

    --Ԫ���ڲµ��ղ��
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
        collectgarbage("collect")  --�ܷ�ʱ�䣬��֪Ϊɶ
	end
	table.insert(clockQueue, os.clock()*1000);

	check_perf(clockQueue);
end
--��ȷontimecheckʵ�� ��Ϸ��ʵ�� gamepkg.ontimecheck_second()�ӿ�
if ontimer_second then
	eventmgr:removeEventListener("timer_second", ontimer_second);
end
ontimer_second = function(e)
	if gamepkg.ontimecheck_second then
        gamepkg.ontimecheck_second()
	end
end
eventmgr:addEventListener("timer_second", ontimer_second);
--�ɷ�ʱ��ʱ�䣬ÿ����һ��
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

--��ʱ����N�������а�
function do_users_prop_sort()
    if(room.time - room.timeLastTime > room.timeSortDelay) then
		usermgr.sort_top_users(room.sortTopMax)
		room.timeLastTime = room.time
    end
end

-- ������λ״̬�б仯��������״̬��ϣ���ʽ��desklist(key:deskno, "start":1 or 0,value:states(key:siteno, value:SITE_UI_VALUE))
function get_changed_desk(user_info)
	local changed_desks = {}
	--TraceError("user:"..user_info.userId.."\r\n visible:"..tostringex(user_info.visible_desk_list));
	for _, idesk in pairs(user_info.visible_desk_list) do
		local has_changed = false
		for isite = 1, room.cfg.DeskSiteCount do
			local state_value = gamepkg.TransSiteStateValue(desklist[idesk].site[isite].state)
			if (state_value ~= desklist[idesk].site[isite].state_value_send) then
				-- ��¼��ǰ������һ����λ״̬���¼��ͬ
				has_changed = true
			end
		end
		if has_changed then
			-- ֻ��¼״̬�б仯������
			changed_desks[idesk] = 1
		end
    end
	return changed_desks
end

--��ȡ��λuserinfo
function get_site_user(deskno, siteno)
	return userlist[hall.desk.get_user(deskno, siteno) or ""]
end

function notify_changed_desk(user_info, changed_desk)
	local count_desk = 0
	for k, v in pairs(changed_desk) do
		count_desk = count_desk + 1
	end

	if count_desk == 0 then
		-- û�п��Է��͵���������
		return
	end

    -- TODO:��Ҫ���������Ľ���״̬���ѿ�ʼ��δ��ʼ���ѿ�ʼ����
    netlib.send(
        function(out_buf)
            out_buf:writeString("SDDSS")
    		out_buf:writeInt(count_desk)  --�б仯�����Ӽ���
			for deskno, desk_data in pairs(changed_desk) do
                local deskinfo = desklist[deskno]
    			out_buf:writeInt(deskno)
                --����
    			out_buf:writeString(deskinfo.name)
                --��������:1��ͨ��2������3VIP
                out_buf:writeByte(deskinfo.desktype)
                --�Ƿ������
                out_buf:writeByte(deskinfo.fast)
                --���������
                out_buf:writeInt(deskinfo.betgold)
                --���ӵ���ҳ���
                out_buf:writeInt(deskinfo.usergold)
                --�����ȼ�
    			out_buf:writeInt(deskinfo.needlevel)
                --Сä
    			out_buf:writeInt(deskinfo.smallbet)
                --��ä
    			out_buf:writeInt(deskinfo.largebet)
                --��Ǯ����
    			out_buf:writeInt(deskinfo.at_least_gold)
                --��Ǯ����
    			out_buf:writeInt(deskinfo.at_most_gold)
                --��ˮ
    			out_buf:writeInt(deskinfo.specal_choushui)
                --���ٿ�������
    			out_buf:writeByte(deskinfo.min_playercount)
                --��󿪾�����
    			out_buf:writeByte(deskinfo.max_playercount)
				--��ǰ��������
    			out_buf:writeByte(hall.desk.get_user_count(deskno))
                local watch_count = 0
                for k,v in pairs(deskinfo.watchingList) do
                    watch_count = watch_count + 1
                end
                --��ս����
    			out_buf:writeInt(watch_count)
				--�Ƿ�ʼ
    			out_buf:writeByte(gamepkg.getGameStart(deskno) and 1 or 0)

				--- TODO:Client��Ҫ�������ݰ��Ĵ���
                out_buf:writeByte(room.cfg.DeskSiteCount)
                for isite = 1, room.cfg.DeskSiteCount do
					local state_value = gamepkg.TransSiteStateValue(desklist[deskno].site[isite].state)
					out_buf:writeByte(state_value)
					local user_info = get_site_user(deskno, isite) or {}
                    --�û������ݿ�ID
                    out_buf:writeInt(user_info.userId or 0)
                    --�ǳ�
                    out_buf:writeString(user_info.nick or "")
                    --ͷ��URL
                    out_buf:writeString(user_info.imgUrl or "")
                    desklist[deskno].site[isite].state_value_send = state_value
                end
    		end
			-- ��ǰ�����ҳ��
    		out_buf:writeShort(user_info.visible_page)
			-- һ���ֶ���ҳ
    		out_buf:writeShort((count_desk - count_desk % user_info.desk_in_page) / user_info.desk_in_page + 1)
        end
    , user_info.ip, user_info.port)
end

function dispatchDeskChangeEvent()
	local visible_pages = {}
	local sendlist = {}
	for _, user_info in pairs(userlist) do
		-- ����û��Ƿ��ڿ���ҳ��
		if (user_info.visible_page ~= 0) then
			if(visible_pages[user_info.visible_page] == nil or isguildroom()) then --����ר�÷���ÿ���˵ĵ�һҳ�ǲ�ͬ��
				-- �����ҳ���һ�α���飬��ɸѡһ�α仯������
				visible_pages[user_info.visible_page] = get_changed_desk(user_info)
			end
			--ʹ���Ѿ�ɸѡ������������ۼ�����
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

--ȡ����Ҫ�������پͿ��Կ�ʼ�����ӣ����ȡ�����Ų���-1���ҷ���ֵ��1�ı�ʾ�����ӿ�����
DeskQueueMgr.getFirstQueueDeskInfo = function(nIndex)
    ASSERT(type(nIndex) == "number")
    if (deskqueue[nIndex] ~= nil) then
        ASSERT(desklist[(deskqueue[nIndex])] ~= nil, "�Ŷ�ʱ������Ϣ�ǿ�"..tostring(nIndex))
        return 1, deskqueue[nIndex], desklist[(deskqueue[nIndex])].playercount
    else
        return 0, -1, -1
    end
end

--todo:�û������Ŷ�ʱ������к��棬��Ȼ������ǰ��
UserQueueMgr.AddUser = function(userKey, ip, port, queryReason)
    --����Ѿ��������ˣ��򲻽����Ŷ�
    if (userlist[userKey].desk ~= nil) then
        return false
    end
    if (g_UserQueue[userKey]) then
        trace(format("%s�Ѿ����Ŷ���", userKey))
        return false
    else
        --trace('suserid:'..suserid)
        g_UserQueue[userKey] = {}
        local userQueueInfo = g_UserQueue[userKey]
        userQueueInfo.key = userKey
        userQueueInfo.ip  = ip
        userQueueInfo.port = port
        userQueueInfo.queueindex = g_queueindex --ȫ�ֱ�������Զ����
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
        --������Ч���е��û����ܼ�����������
        if (queryReason ~= queryReasonFlg.inValid) then
			usermgr.enter_playing(userlist[userKey])
        end
        trace(format("%s���뵽�ŶӶ�����", userKey))
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
            else --������˶���
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
        trace(format("%s���ŶӶ��������",userKey))
        return true
    else
        return false
    end
end

--ȡ���������������
UserQueueMgr.GetCount = function(IncludeRobot)
    local count = g_QueueLoginPeople1.count + g_QueueLoginPeople2.count + g_QueueWinPeople1.count
                  + g_QueueWinPeople2.count + g_QueueLostPeople.count + g_QueueInvalid.count
    if (IncludeRobot == 1) then
        return count + g_QueueRobot.count
    end
    return count
end

--���͵�ǰ�Ŷ�����
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
    --��ȡ�Ŷӵ��û�����ȡӮ���û�����ȡ����û�����ȥ������
    local userKey, userinfo
    if (pop_invaild_user == true and g_QueueInvalid.count > 0) then
        userKey = g_QueueInvalid:Pop()
        trace(format("������Ч����������û�:%s", userKey))
    elseif (g_QueueLoginPeople1.count > 0) then --����Ȼ��1
        userKey = g_QueueLoginPeople1:Pop()
        trace(format("�����Ŷ��û�:%s", userKey))
    elseif (g_QueueWinPeople1.count > 0) then --��Ӯ����1
        userKey = g_QueueWinPeople1:Pop()
        trace('����Ӯ��һ�����е���:'..userKey)
    elseif (g_QueueLoginPeople2.count > 0) then --����Ȼ��2
        userKey = g_QueueLoginPeople2:Pop()
        trace(format("�����Ŷ��û�:%s", userKey))
    elseif (g_QueueWinPeople2.count > 0) then --��Ӯ����2
        userKey = g_QueueWinPeople2:Pop()
        trace('����Ӯ�Ķ������е���:'..userKey)
    elseif (g_QueueLostPeople.count > 0) then --�������
        userKey = g_QueueLostPeople:Pop()
        trace('������Ķ��е���:'..userKey)
    elseif (g_QueueRobot.count > 0) then --�л�����
        userKey = g_QueueRobot:Pop()
        trace('���ػ����˶��е���:'..userKey)
    end
    if (userKey ~= nil) then
        local popUser = g_UserQueue[userKey]
        --trace("����ŶӶ���"..g_UserQueue[userKey].key)
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
				if (userlist[userKey].ip == userinfo.ip) then  --��ͬip�Ĳ��ܽ���
					return false
				end
			end
			if (ischeckforcerequeue() == 1) then
				if (userlist[userinfo.key].last_desk ~= nil and userlist[userKey].last_desk == userlist[userinfo.key].last_desk) then  --��ͬ����λ����������
					return false
				end
			end
		end
	end
    return true
end

--����������һ�Σ�ֻ����һ������
function FillDesk(nDeskNo, nDeskPlayerCount)
    --���һ������Ҫ����Ȼ�ˣ�����û����Ȼ���Ŷӣ���Ҫ���������Ƿ�����Ȼ��,���û�У���Ҫ����һ��
    if (room.cfg.DeskMustHavePerson == 1 and UserQueueMgr.GetCount(0) == 0) then
        local bHavePeople = false
        local userId = nil
        for i = 1, room.cfg.DeskSiteCount do
            userId = hall.desk.get_user(nDeskNo, i)
            if (userId ~= nil and userlist[userId] == nil) then
                TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��3")
                hall.desk.clear_users(nDeskNo, i)
            else
                if (userId ~= nil and userlist[userId].isrobot == false) then
                    bHavePeople = true
                    break
                end
            end
        end
        if (bHavePeople == false) then  --��ǰ��û����Ȼ�ˣ�����û����Ȼ���Ŷ�,ֱ���˳�
            --trace(nDeskNo.."����û����Ȼ�ˣ������Ŷӻ���û����Ȼ��")
            return false
        end
    end
    local bHavePeopleSitDown = false
    --���û���������һ���û�����
    local bBlankSite = false --�Ƿ����λ
    for i = 1, room.cfg.DeskSiteCount do
        if (UserQueueMgr.GetCount(1) < 0) then  --���������û�����ˣ����˳��Ŷ�
            break
        end
        if (gamepkg ~= nil and gamepkg.IsBlankSite ~= nil) then
            bBlankSite = gamepkg.IsBlankSite(nDeskNo, i)
        else
            bBlankSite = not hall.desk.get_user(nDeskNo, i)
        end
        --�ҵ�һ����λ��
        --todo bug
        --���û�д��û�����������û�
        local tempUserKey = hall.desk.get_user(nDeskNo, i)
        if (tempUserKey ~= nil and userlist[tempUserKey] == nil) then
            TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��4")
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
                if (userkey_temp == nil) then    --����Ѿ�û���Ŷ��û��ˣ���ֱ�ӷ���
                    break
                end
                --����û��Ƿ��ܹ�����
                if(can_user_sitdown(nDeskNo, userinfo_temp) == false) then
                    UserQueueMgr.AddUser(userkey_temp, userinfo_temp.ip, userinfo_temp.port, queryReasonFlg.inValid)
                    trace("��ͬip����ͬ�������")
                else
                    userkey = userkey_temp
                    userinfo = userinfo_temp

                    --�ɹ��Ŷӽ�ȥ�������ǿ�����ױ�־
                    userinfo.queue_time = 0
                    userinfo.queue_seed = 0

                    break
                end
                loop_count = loop_count + 1
            end
            if (userkey == nil) then --û���ҵ����ʵ��û����˳��Ŷ�
                break
            end
            --��λ��
            trace(format("�Ŷӻ��Զ�����%s��%d������, %d��λ����", userkey, nDeskNo, i))
            DoUserWatch(nDeskNo, userlist[userkey])
            doSitdown(userkey, userinfo.ip, userinfo.port, nDeskNo, i, g_sittype.queue)
            bHavePeopleSitDown = true   --˵����ǰ�û��Ŷӳɹ�
            if (desklist[nDeskNo].playercount  >= room.cfg.DeskSiteCount) then   --���һ�������ﵽ��󣬾Ͳ�������
                trace(format("%d����������С��ʼ���������Կ�ʼgame��", nDeskNo))
                break
            end
        end
    end
    if (bHavePeopleSitDown == true) then
        return true
    end

    trace("һ��������û�������ˣ��������Ŷ���")
    return false
end

--�����ӵ��б�
local g_nBadDesk = {};

function processQueue()
    --�������ٿ�λ�����е������ж�Ҫѭ�����ο�������һ��
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
        --��һ�������ٿ�λ���������Ѿ����ϵ������
        local nRet, nFeatDeskNo, nDeskPlayerCount = DeskQueueMgr.getFirstQueueDeskInfo(nIndex)
        --û���˿����Ŷ���
        if (nRet == 0 or nFeatDeskNo == -1 or nDeskPlayerCount < 0 or nDeskPlayerCount > room.cfg.DeskSiteCount) then
            return
        end
        --��ǰ����������Ҫ�����˲ſ��Կ�ʼ��Ϸ
        local nMiniNeedCount = 0
        if (room.cfg.MinDeskSiteCount > nDeskPlayerCount) then
            nMiniNeedCount = room.cfg.MinDeskSiteCount - nDeskPlayerCount
        end
        local BlankSiteCount = room.cfg.DeskSiteCount - nDeskPlayerCount
        --��ǰ�Ŷ���������һ�������п�λ
        if (UserQueueMgr.GetCount(1) >= nMiniNeedCount and BlankSiteCount > 0) then
            trace("��ʼ�����ӣ���λ����:"..BlankSiteCount)
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
    TraceError("�������б�:")
    local nDeskCount = 0
    for k ,v in pairs(g_nBadDesk) do
        if (v == 0) then
            nDeskCount = nDeskCount + 1
            TraceError(k)
        end
    end
    TraceError("����������:"..nDeskCount)
end

function doProcessQueue()
    local ret, errmsg = xpcall(function() return processQueue() end, throw)
    UserQueueMgr.SendQueueCountToAllQueueUser()
end

function processRequireDeskQueue(suserid, ip, port)
    --�Ƚ��û�ѹ�뵽�ŶӶ�����
    UserQueueMgr.AddUser(suserid, ip, port, queryReasonFlg.login)
end

usermgr.ResetReloginState = function(key)
    if (userlist[key] ~= nil) then
        userlist[key].offline = nil
        userlist[key].offlinetime = nil
        userlist[key].relogin = nil
    end
end

--�յ������Զ�������Ϸ
function onrecvrAutoJoin(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        TraceError("����ֱ�Ӽ�����Ϸ, userinfo��"..tostring(userKey))
        return
    end
    
    local deskno = buf:readInt()
    local user_desk_type=buf:readInt()
    if(user_desk_type~=nil) then
    	userinfo.user_desk_type=user_desk_type
    end
    local siteno = -1
    local errcode, value = 0, 0
    local msgtype = 0 --0��ʾ�Ǵ��������Э��
    local msg =""
    local needsitdown = false  --���뷿���Ĭ���ǹ�ս��ֻ�е����ʼ��������
    if(userinfo.desk or userinfo.site) then
        --TraceError("���£���������Ҳ�ܵ���Ŷӣ�����")
        return
    end

    if (deskno > #desklist) then
       -- msg = "�Բ�������������Ӻ��볬����Χ������������!"
        msg = tex_lan.get_msg(userinfo, "h2_msg_autojoin_1")
        OnSendServerMessage(userinfo, msgtype, _U(msg))
        return
    end


    if(deskno > 0) then
        local deskinfo = desklist[deskno]

        if(deskinfo.playercount >= room.maxWatchUserCount) then
            --msg = format("�Բ�����ѡ�������������������ѡ����������!")
            msg = tex_lan.get_msg(userinfo, "h2_msg_autojoin_2")
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end

        if(deskinfo.needlevel > usermgr.getlevel(userinfo)) then
            --msg = format("�Բ�����ѡ���������Ҫ%d���ſ��Խ��룬���ȼ�����!", deskinfo.needlevel)
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_3"), deskinfo.needlevel)
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end
        --[[
        local needgold  = deskinfo.at_least_gold
        if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then 
            needgold  = needgold + deskinfo.specal_choushui 
        end
        if(needgold > userinfo.gamescore) then --�������Ҳ���Խ����ս
            --msg = format("�Բ�����ѡ���������ʹ������%d��������Я���ĳ��벻��!", needgold)
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
            --msg = format("�Բ�����ѡ���������ҪVIPȨ�޲��ܽ���!")
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_4"))
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end
        
        if((deskinfo.desktype == g_DeskType.channel and userinfo.channel_id<=0) or 
        	(deskinfo.desktype == g_DeskType.channel and userinfo.channel_id~=deskinfo.channel_id)) then
            --msg = format("�Բ�����������ȷ�ķ���ID!")
            msg = format(tex_lan.get_msg(userinfo, "h2_msg_autojoin_5"))
            OnSendServerMessage(userinfo, msgtype, _U(msg))
            return
        end

        --ָ�����Ӻż���
        errcode, value = can_user_enter_desk(userKey, deskno)

    else

        --δָ�����Ӻţ��Զ�����
        needsitdown = true  --�Զ�����
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
        --�����޷����뷿����Ϣ        
        OnSendUserAutoJoinError(userinfo, errcode, value)
        return
    end
            
   --��������֮ǰ�������ܲ��ܹ�ս
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
    --���������Ҹ�����λ����  
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
    	--û�п���λ�ͽ����ս
        if (duokai_lib) then
            duokai_lib.join_game(userlist[userKey].userId, deskno, -1, 1)
        else
    	    DoUserWatch(deskno, userlist[userKey])
        end
    end
end

--���ͷ�������Ϣ:0�Ǵ�����Ϣ��1����Ϸ����Ϣ,�ͻ���ֱ����ʾ������
function OnSendServerMessage(userinfo, ntype, szmsg)
    --TraceError("���ͷ�������Ϣ:"..ntype)
    if(not userinfo) then return end
    netlib.send(
        function(buf)
            buf:writeString("REMG")
            buf:writeByte(ntype)
            buf:writeString(szmsg)
        end
    , userinfo.ip, userinfo.port, borcastTarget.playingOnly);
end

--֪ͨ������Ϸ���
function OnSendUserAutoJoinError(userinfo, errcode, value)
    --TraceError("֪ͨ�������ʧ��")
    if(not userinfo) then return end
    netlib.send(
        function(buf)
            buf:writeString("RQNI")
            buf:writeByte(errcode)
    		buf:writeInt(value)
        end
    , userinfo.ip, userinfo.port, borcastTarget.playingOnly);
end

--�յ��Ŷ�����
function onrecvrqDeskQueue(buf)
    if (isguildroom()) then --����ר�÷��䲻���Ŷӽ���
        return
    end

    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        TraceError("�Ŷ�ʱuserinfo��"..userKey)
        return
    end

    local CanQueueFlag, value = can_user_enter_desk(userKey, nil)
    --�����޷����뷿����Ϣ
    OnSendUserAutoJoinError(userinfo, CanQueueFlag, value)
    if (CanQueueFlag == 1 and userinfo ~= nil) then--�û����δ�ﵽ����Ҫ��
         --�û�����Ѵﵽ����Ҫ��
        --�û�������ʱ�����û����û����Ǵӵ�½�û������Ŷ�
        if (userinfo.desk == nil or userinfo.desk < 0 or   --�������ص�½�û�
            (userinfo.key == userKey and userinfo.offline == nil)) then --������ص�½�û�
            --��֪��Ϊʲô�ͻ��������ڴ��ƣ�������ʱ����Ȼ�ᷢ���Ŷ���Ϣ
            local bGameAlreadyStart = false
            if (userinfo.desk == nil or userinfo.desk < 0) then
                bGameAlreadyStart = false
            else
                local execok, ret = xpcall(function() gamepkg.getGameStart(userinfo.desk, userinfo.site) end, throw)
				if execok then
					bGameAlreadyStart = ret
				end
            end
            --�����ǰ�û��Ѿ�����Ϸ�����ǻ������Ŷӡ���ֱ�ӷ����ˣ��������ŶӴ���
            if (bGameAlreadyStart) then
                TraceError("�쳣��Ϣ����ǰ�û��Ѿ�����Ϸ�ˣ�Ϊʲô��Ҫ�Ŷ�?")
            else
                processRequireDeskQueue(userKey, buf:ip(), buf:port())
            end
        end
    else
        trace("�û��Ŷ���ϢΪ��?")
    end
end

--�Ƿ���Ͻ������� ���� 1,0 Ϊ������������඼Ϊ�쳣���
function can_user_enter_desk(userkey, deskno)
	local userinfo = userlist[userkey]
	local at_least_gold = groupinfo.at_least_gold
	local at_most_gold = groupinfo.at_most_gold
    local at_least_integral = groupinfo.at_least_integral

	return gamepkg.CanUserQueue(userkey, deskno)
end

--�ж��û��ܲ���֧������XXǮ
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
    --��Ϊ�������Ŷӣ��ҿ�����Ϊû�����˲�������Ϸ�������������2��ֻ��ʾ2
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

--ȡ���Ŷ�
function onRecvCancelQueue(buf)
    local suserid = getuserid(buf)
	local userinfo = userlist[getuserid(buf)]; if not userinfo then return end;
	if gamepkg and gamepkg.OnCancelQueue then		--ȡ���Ŷ�ʱ
        gamepkg.OnCancelQueue(userinfo)
    end
    UserQueueMgr.RemoveUser(suserid)
end

--����������ʱ������Ĵ�������Ϸ��������ò���
function onsetgroupinfo(groupid
                    , groupname                         --������
                    , ispublic                          --�Ƿ����������Զ�������� =1 ��ʾ�����Զ��������
                    , allowhallchat                     --�Ƿ������ڴ��������� 1=����
                    , displayusernameinhall             --�Ƿ��ڴ�������ʾ��Ϸ������
                    , allowclickdesk                    --�Ƿ��ڴ�����ֱ�ӵ����������
                    , allowclicksite                    --�Ƿ��ڴ�����ֱ�ӵ����λ����
                    , allowgamechat                     --�Ƿ���������Ϸ������ 1=����
                    , displayusernameingame             --�Ƿ�����Ϸ����ʾ��Ϸ������
                    , gamepeilv                             ----����
                    , allowMaiMa)                          --�Ƿ��������
    --��¼����Ϣ
    if (groupinfo ~= nil) then
        trace(format("�����޸�����Ϣ����(%s)", groupid))
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
    --todo ������ʾ��ǰ�����������ķ���id����������ֻ����ʾһ��id
    tools.setcaption("-"..groupname)
end
function OnGameOver(deskno, bQueueDeskUser, bStandupOnNotQueue)
    xpcall(function() hall.desk.clear_state_list(deskno) end, throw)
    local userid, siteUserInfo, i
    local DeskUsers = {}
    for i = 1, room.cfg.DeskSiteCount do
        trace("��ȡ��"..i.."���û���Ϣ")
        local userKey = hall.desk.get_user(deskno, i)
        siteUserInfo = userlist[userKey]
        if (siteUserInfo ~= nil) then
		    siteUserInfo.last_desk = deskno --��¼��һ�����������
            trace('��Ϸ����,�������û�:'..siteUserInfo.nick..":"..siteUserInfo.key)

            --�йܵĻظ�״̬
            if(siteUserInfo.gamerobot == true) then
                siteUserInfo.gamerobot = false
            end

            --����������û��������û�վ����
            if (siteUserInfo.offline == offlinetype.tempoffline) then
                --���ﲻ�����û�����״̬����Ϊ����ѭ����ɺ�����˾�վ������.
                trace("�ж����û�"..siteUserInfo.key)
                DoKickUserOnNotGame(siteUserInfo.key, false)
			else
				local retcode, value = can_user_enter_desk(siteUserInfo.key, deskno)
				if retcode ~= 1 then	--����Ǯ,�߳���
					netlib.send(
						function(buf) --���Ͳ���Ǯ�߳�����
							buf:writeString("NTPC")
							buf:writeInt(retcode)
							buf:writeInt(value)
						end
					, siteUserInfo.ip, siteUserInfo.port)
					DoKickUserOnNotGame(siteUserInfo.key, false)
				--������������ �� ���㲻�ֻ� ������¶������ֻ�����
				elseif (room.cfg.ongameOverReQueue == 1 and groupinfo.can_sit == 0 and bQueueDeskUser == true) then
					--�û�ȫ���Ŷӵ���������
					trace(format("��%s  %s��ʼ�����ŶӶ�����", userKey, siteUserInfo.nick))

					--���վ��������ģ�Ϊ�Ŷ�ʱ��վ�𣬲���չ�ս�б�
					doUserStandup(userKey,true)
					--�û���ʱ�������ڵ�½��Ϸ���ǻ�û����ɣ�Ҫ��½����˲����ֻ�
					if (usermgr.IsLogin(siteUserInfo) == true) then
						local bWinner = hall.desk.is_win_site(deskno, i)
						if (bWinner == true) then
							UserQueueMgr.AddUser(userKey, siteUserInfo.ip, siteUserInfo.port, queryReasonFlg.gameOverAndWin)
						else
							UserQueueMgr.AddUser(userKey, siteUserInfo.ip, siteUserInfo.port, queryReasonFlg.gameOverAndLost)
						end
					end
				--�����Ϸ�������ֻ��������·�ʽΪվ���������£�����վ���������£������û����������Ϣ
				elseif ((bStandupOnNotQueue == nil or bStandupOnNotQueue == true) and
						(room.cfg.ongameOverReQueue == 0 or groupinfo.can_sit == 1)) then
					--�ڲ��Ŷӵ�ʱ����Ҫ��վ������������
					if (siteUserInfo ~= nil and siteUserInfo.desk ~= nil and siteUserInfo.site ~= nil) then
						local siteno = siteUserInfo.site
						doUserStandup(userKey, true)
						--�û���ʱ�������ڵ�½��Ϸ���ǻ�û����ɣ�Ҫ��½����˲����ֻ�
						if (usermgr.IsLogin(siteUserInfo) == true) then
							doSitdown(userKey, siteUserInfo.ip, siteUserInfo.port, deskno, siteno, g_sittype.normal)
							usermgr.enter_playing(siteUserInfo)
						end
				   end
			    end
            end
            --����û�û�б�ɾ��������������״̬Ϊnil
            usermgr.ResetReloginState(userKey)
        end
    end
end

--------------------------------------------------------------------------------
function onrecviamrobot(buf)
    local userkey = getuserid(buf)
    local userinfo = userlist[userkey]

    if userinfo.realrobot ~= true then --����ǵ�һ�η�������userIfo.realrobotΪfalse�ż�1
        usermgr.AddRobotUser(userinfo.nRegSiteNo, 1) --����������ͳ�Ƽ�1
    end
    userinfo.isrobot = true
    userinfo.realrobot = true
    if (userinfo.isrobot == true) then
        trace('user is robot '..userinfo.nick)
    end
    if (room.cfg.ignorerobot == 1) then
        userinfo.isrobot = false --ǿ������Ϊ��Ȼ��,����������Ȼ��һ�����Ŷ�,��������ʱ������˴��Ҵ�
    end
end
--------------------------------------------------------------------------------
function checkGamePkg()
    if (gamepkg == nil) then
        trace('��Ҫ����Ϸ�ű��ж��� gamepkg table')
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
            TraceError('��Ϸ�ű��������ݲ�����')
            return false
        end
    end
    return true
end

--�ı��û�ͷ��
function OnChangeFace(buf)
    local szFaceUrl = buf:readString()
    local userKey = getuserid(buf)
    --�����Ƿ񻻵���vipͷ��

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
        if (face_id > vaild_face_begin_id and face_id <= vaild_face_end_id and  --�û�����vipͷ��
            viplib and viplib.check_user_vip(userinfo)) then --�û���vip
            local vipinfo = viplib.get_user_vip_info(userinfo)
            local user_vip_level = vipinfo.vip_level
            local find = false
            if (user_vip_level > 1 and facelib.vip_level_face[user_vip_level] ~= nil) then   --�û�vip�ȼ�>1
                for k, v in pairs(facelib.vip_level_face[user_vip_level]) do
                    if (userinfo.sex == "0") then
                        v = v + 1000
                    end
                    if (v == face_id) then  --�ҵ���ͷ��˵���û����Ի����ͷ��
                        find = true
                        break
                    end
                end
            end
            if (find == face) then
                TraceError("������vip���뻻vipͷ��,С��")
                return
            end
        end
    end
    if (usermgr.ChangeFace(userKey, szFaceUrl) == false) then
        return
    end
    dblib.cache_set("users", {face=szFaceUrl}, "id", userlist[userKey].userId)
    --��user_extra_face���¼�ϴε�ͷ��
    --���FACEID��10001��10002�Ļ��Ͳ���������Ϊ�������2����ʱ��Ҫ������
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

--֪ͨ���������޸���ͷ��
function OnSendChangeFace(touserinfo, chguserinfo)
    --TraceError("֪ͨ���ͷ�����)
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

--�㲥������޸���ͷ��
function net_broadcast_face_change(userinfo)
    if not userinfo then return end
    --֪ͨ�������
    local deskno = userinfo.desk
    --û�����Ӻţ�ֻ�����Լ�
    if(not deskno) then
        OnSendChangeFace(userinfo, userinfo)
        return
    end

    --֪ͨ������������
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendChangeFace(playingUserinfo, userinfo)
            end
            if(playingUserinfo == nil) then
                TraceError("ͷ����ʱ�������и��û���userlist��ϢΪ��")
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
    --����ͷ��۸�
    extra_face_price = {
        [10001] = 50000,
        [10002] = 500000,
        [10003] = 10000000,
    },
    --��ʱ������ͷ��
    extra_temp_faceid = {
        [1] = 10011,    --��ʱ
        --[2] = 10012,  --����
    },


	--VIPͷ�񣬹涨500����Ϊvipͷ��500����Ϊ��ͨͷ��,��ͷ��500���ϣ�Ůͷ��1500����
	vip_level_face = {
		[1] = {},
		[2] = {501, 502},
		[3] = {501, 502, 503, 504},
	},
}

--�Ƿ�����չͷ��
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

--�Ƿ���vipͷ��
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

--�յ�������ʾͷ���б�
function on_recv_select_head_info(buf)
    local userinfo = userlist[getuserid(buf)]
    local extra_faces = {}  --�ͷ��
    local vip_faces = {}    --vipͷ��
	--���ǻ�Ա����ͷ��  //TODO
	local user_vip_level = 0
	if viplib and viplib.check_user_vip(userinfo)  then
		local vipinfo = viplib.get_user_vip_info(userinfo)
		user_vip_level = vipinfo.vip_level
        --����1���Ĳ���vipͷ��
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

    --�����Ѿ�����,�õ��û��Ѿ��򵽵�extraͷ��
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
    --���߿ͻ��˽��
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

--��2009����ʥ�ڻ�Ƿ����
function check_halloween_time()
    --TODO:����д����
    local isover = 0
    local endtime = os.time{year = 2009, month = 12, day = 26,hour = 0};
    if(os.time() > endtime) then
        isover = 1
    end
    return isover
end

--�����ָ�ԭ����ͷ��
function restore_temp_face(userinfo)
    local is_special_face = 0
    local is_special_face_over = 0
    local isover = 0
    if (facelib.is_extra_face(string.match(userinfo.imgUrl, "^face\/(%d+)\.swf$")) == true) then  --����Ƿ����
        is_special_face_over = check_halloween_time()
        is_special_face = 1
    elseif (facelib.is_vip_face(string.match(userinfo.imgUrl, "^face\/(%d+)\.swf$")) == true) then  --���vip�Ƿ����
        if (viplib ~= nil and viplib.check_user_vip(userinfo) == false) then
            is_special_face_over = 1
        end
        is_special_face = 1
    end
    --�����ʥ�ڽ�������ͷ����10001����10002�ָ���ǰ��ͷ��
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

        --��Ϊ���ݿⲻͬ����Ҫ����֪ͨ�ͻ���
        netlib.send(
            function(buf)
                buf:writeString("CHFCOK")
                buf:writeString(normal_face)
            end
        , userinfo.ip, userinfo.port)
    end
end

--��������ͷ��
function on_active_extra_face(buf)
    local userinfo = userlist[getuserid(buf)]
	local faceId = buf:readString()
    faceId = tonumber(faceId)
    local sure = buf:readInt()
    --TODO:face�۸�����,��д���ڴ�����
    --string.gmatch("face/1000.swf", "/(%d+)\.swf")()
    --���û�Ǯ������user_extra_face���¼
    if(not userinfo) then return end
    if(not facelib.extra_face_price[faceId]) then return end

    local nsuccess = 0
    local actived = 0

    --���û��Ƿ񼤻�
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

             --����û��Ѿ������ˣ��Ͳ������ݿ����
            if(actived == 1) then
                nsuccess = 1

            --�û�ÿ������Լ���ͷ��
            else
                --�û�����Ǯ��
                if(sure == 1) then
                    if(facelib.extra_face_price[faceId] <=  userinfo.gamescore) then
                        --�����û���ң�ע���Ǹ�������Ǯ��
                        usermgr.addgold(userinfo.userId, -facelib.extra_face_price[faceId], 0, g_GoldType.buy, -1)

                        local actionSql = string.format(tSqlTemplete.active_user_face, userinfo.userId ,faceId,userinfo.userId);
                        dblib.execute(actionSql)
                        nsuccess = 1
                    end
                else
                    nsuccess = 2
                end
            end

            --���߿ͻ��˽��
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

--�㲥��Ǯ��Ϣ
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
        --���ӵ�й���Ϸ��
    	if(userinfo.extra_info and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            save_extrainfo_to_db(userinfo)
        end
		--ˢ��vip��Ϣ
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
        --���ӵ�й���Ϸ��
    	if(userinfo.extra_info and userinfo.gamescore > userinfo.extra_info["F05"]) then 
            userinfo.extra_info["F05"] = userinfo.gamescore
            if (duokai_lib) then
                duokai_lib.merge_data(userinfo, "extra_info")
            end
            save_extrainfo_to_db(userinfo)
        end
		local szBuf = tostring(user_id)..","..tostring(user_gold)
		tools.SendBufToUserSvr(getRoomType(), "STGB", "", "", szBuf) --�������ݵ������
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
--*                       �û���ս�����߼�,Felon                             *
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

    --�����ս,�����Ǹ��˷��͵�����
    if(room.arg.ReqGetSvrIdType == "watch" and room.arg.reqUserId == nReqUserId) then
        --�û�������
        if(nGameSvrId == "-1") then
             ErrorCode = -1
        else
            --��Ҫ�Զ���¼�������Ϣ
            ErrorCode = -2
        end
        OnSendUserWarchError(userinfo, ErrorCode, nUserId, nGameSvrId)
    end
end

--�յ������˳���ս
function OnRecvExitWatch(buf)
    local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
    if (userinfo == nil) then
        return
    end
    if(userinfo.site ~= nil) then
        TraceError("�˳���ս�������˳���Ϸ:userid = "..userinfo.userId)
        return
    end

    DoUserExitWatch(userlist[userKey])
end

--�ж��Ƿ���Թ�ս
--   �����ʶ
   -- -1   ����ս��������Ч
   -- -2   ����ս�����Ӳ��ڴ˷�
   -- -3   ����ս�����Ӳ������ս
   -- -4   ��ս�б�����
   -- -5   �ȼ�����
   -- -6   ����VIP��Ա���ܽ���
   -- -7   ���Ͻ�Ҳ���
   -- -8   ������ڱ����б��е�
   -- -9   ���������Ƶ��ID��Ϊ�գ�������ҵ�Ƶ��ID��������Ƶ��ID��ͬ
function CanUserWatch(userinfo, deskno, friend)
    if not userinfo then return end
    local bCanWatch = true         --�ܷ��ս��ʶ
    local nErrorCode = 1

    local deskinfo = desklist[deskno]

    if(deskinfo == nil) then
        nErrorCode = -1
        return nErrorCode
    end

    --TODO:�����ս��������
    --��������ǰ����һ���ǲ����ڱ����ı����б��е�
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

    --���������Ƶ��ID��Ϊ�գ�������ҵ�Ƶ��ID��������Ƶ��ID��ͬ���ͷ���-9
    --û�����ӵ�Ƶ������0������У����Ǹ����������
   if(deskinfo.channel_id~=nil and deskinfo.channel_id~=-1 and deskinfo.channel_id~=userinfo.channel_id) then
       return -9
    end


    --�����������ж�
    if bCanWatch then
        --�����VIP5��ֱ�ӿ��Թ�ս 
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

        --����ս�б��Ƿ�����
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

    --�ȼ��жϣ��������ѹ�ϵ����Ĳ����Ƶȼ�
    if not friend or friend ~= 1 then
        if(deskinfo.desktype ~= g_DeskType.match and deskinfo.needlevel > usermgr.getlevel(userinfo)) then
            --TraceError(format("�����ȼ���ս, needlevel[%d], userlevel[%d]", deskinfo.needlevel, usermgr.getlevel(userinfo)))
            nErrorCode = -5
        end
    end

    --VIP�ʸ��ж�
    if deskinfo.desktype == g_DeskType.VIP and not (viplib and viplib.check_user_vip(userinfo)) then
        --TraceError(format("��VIP��Ҳ����Խ�VIP���ֲ�,userid[%d]", userinfo.userId))
        nErrorCode = -6
    end

    --����ж�
	local needgold = deskinfo.at_least_gold
	if(deskinfo.desktype == g_DeskType.tournament or deskinfo.desktype == g_DeskType.channel_tournament) then
		needgold = needgold + deskinfo.specal_choushui
	end
	if(userinfo.gamescore < needgold) then
		--nErrorCode = -7  --��Ϊ��ս�����ƽ��
        nErrorCode = 1
    end

    return nErrorCode
end

--�յ������ս
function OnRecvRqWatch(buf)
    local deskno = buf:readInt()    --Ҫ��ս������
    local userKey = getuserid(buf)
    if (deskno <= 0 or deskno > #desklist) then return end
    local userinfo = userlist[userKey]
    if not userinfo then return end

    DoRecvRqWatch(userinfo, deskno, 0)
end

--�����յ��Ĺ�ս����
function DoRecvRqWatch(userinfo, deskno, friend)
    if not userinfo then return end
    if (deskno <= 0 or deskno > #desklist) then return end
    local nErrorCode = CanUserWatch(userinfo, deskno, friend)
    if nErrorCode > 0 then
        --��ʼ��ս��ʱ
        if (duokai_lib) then
            duokai_lib.join_game(userinfo.userId, deskno, -1, 1)
        else
            DoUserWatch(deskno, userinfo)
        end
    else
       OnSendUserWarchError(userinfo, nErrorCode)
   end
end

--֪ͨ��ҹ�սʧ��
function OnSendUserWarchError(userinfo, errcode, watchUserId, watchRoomId)
    --TraceError("֪ͨ��ҹ�սʧ��")
    if(not userinfo) then return end
    netlib.send(
        function(buf, user)
            buf:writeString("RESE")
            buf:writeByte(errcode)
        end
    , userinfo.ip, userinfo.port);
end

--�뿪��ս
function DoUserExitWatch(userinfo)
    if(userinfo == nil) then
        return
    end

    --�뿪������վܾ��б�
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

--ִ����ҹ�ս
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
      TraceError("�����սǰ������վ��~~")
      TraceError(format("userid[%d],deskno:%s,siteno:%s", userinfo.userId, tostring(userinfo.desk), tostring(userinfo.site)))
      doUserStandup(userinfo.key, false)
      --δ֪ԭ��վ��������
      if(userinfo.site ~= nil)then return end
    end

    --�����ս�б�
    addToWatchList(deskno, userinfo);

    --���Լ����͹�ս�ɹ���Ϣ
    if(retcode == nil) then retcode = 1 end
    OnSendSelftWatch(userinfo,retcode)

    --�㲥�������˽�����ս��
    local time1 = os.clock() * 1000
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno,i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserSitdown(userinfo, playingUserinfo, 1, g_sittype.normal)  --��������
                --��Ϸ��Ϣ
                OnSendUserGameInfo(userinfo, playingUserinfo, 0)
            end
            if(playingUserinfo == nil) then
                TraceError("�û���սʱ�������и��û���userlist��ϢΪ��")
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
        TraceError("֪ͨ������������ս,ʱ�䳬��:"..(time2 - time1))
    end
    
    --�����ս�ɷ������¼���
    local DoUserWatch1 = function()
        dispatchMeetEvent(userinfo)
    end
    getprocesstime(DoUserWatch1, "DoUserWatch1", 500)

    --�Ӵ���������
    local DoUserWatch2 = function()
        --TraceError("�Ӵ���������")
    end
    getprocesstime(DoUserWatch2, "DoUserWatch2", 500)

    --�㲥�������˽�����ս��(����)
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

--Ĭ�ϳ�ʼ����������
function on_init_room_settings()
    dblib.execute(string.format(tSqlTemplete.get_roominfo_copy, groupinfo.groupid),
        function(dbsettings)
            local dtsettings = {}
            local dtgamesettings = {}
            if (#dbsettings == 0 or dbsettings[1]["room_settings"] == nil or dbsettings[1]["room_settings"] == "") then
                TraceError("û��Ϊ�����������ݿ��rooms�ֶ�room_settings��������Ϣ������Ĭ�����û����������ֶ��޸�!")
                dtsettings = split('1,1,1,1,0,0,1,1,0', ',')
                dtgamesettings = split('1,1,1', ',')
            else
                local tempsettings = split(dbsettings[1]["room_settings"], ';')
                dtsettings = split(tempsettings[1], ',')
                dtgamesettings = split(tempsettings[2], ',')
            end

            if(#dtsettings == 0) then return end

			groupinfo.can_sit = dbsettings[1]["cansit"] or error()						--�Ƿ��������

			--����ר�÷�������
			groupinfo.isguildroom = dbsettings[1]["isguildroom"] or error()				--�Ƿ�Ϊ����ר�÷���
			local guild_peilv_info = split(dbsettings[1]["guild_peilv_info"], "|")		--10,100|100,100|1000,100|10000,100|100000,100
																						--100�ȼ���at_least_gold��pay_limit
			groupinfo.guild_peilv_map = {}
			for k, v in pairs(guild_peilv_info) do
				if v ~= "" then
					groupinfo.guild_peilv_map[tonumber(split(v,",")[1])] = tonumber(split(v,",")[2])
				end
			end

			--����������
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

            ----------------wlmf���--------------------
            groupinfo.max_lost_gold = dbsettings[1]["max_lost_gold"] or 0
            groupinfo.limit_jia_bei = dbsettings[1]["limit_jia_bei"] or 0
            groupinfo.is_huanle     = dbsettings[1]["is_huanle"] or 0
            --------------------------------------------

			-----------------���������ٴ򵽼�-----------
            groupinfo.at_least_zhunum = dbsettings[1]["at_least_zhunum"] or 0
            --------------------------------------------


			for i = 1, #desklist do
				desklist[i].gamepeilv = groupinfo.gamepeilv
			end
			if _DEBUG then
				check_run_settings('1���Ӻ�ر������־', 'onchecklog', onchecklog, 0)
			else
				check_run_settings('1���Ӻ�ر������־', 'onchecklog', onchecklog, 1)
            end

            check_run_settings('ֻ���������Ϣ', 'oncheckerrorlog', oncheckerrorlog, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)

            if(#dtsettings == 0) then return end
            check_run_settings('ͬһ̨��������ͬ������', 'onchecksamedesk', onchecksamedesk, tonumber(dtsettings[0]))
            table.remove(dtsettings, 1)

            if(#dtsettings == 0) then return end
            check_run_settings('ÿ�ֽ���������������', 'oncheckrequeue', oncheckrequeue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)


            if(#dtsettings == 0) then return end
            check_run_settings('ÿ��������һ����Ȼ��', 'oncheckqueue', oncheckqueue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)


            if(#dtsettings == 0) then return end
			check_run_settings('�޶�ÿ����ʱ����(�����ڵ���)', 'onchecktimelimit', onchecktimelimit, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('���Ի������Ŷӹ���', 'oncheckrobot', oncheckrobot, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('����ר�÷���(��ʧЧ)', 'oncheckbaofang', oncheckbaofang, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtsettings == 0) then return end
			check_run_settings('����ip��ͬ���û�ͬ������', 'onchecksameip', onchecksameip, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
			if(#dtsettings == 0) then return end
			check_run_settings('ϵͳ����Ǯ(���˶�������Ч)', 'oncheckbupeiqian', oncheckbupeiqian, tonumber(dtsettings[1]))
			table.remove(dtsettings, 1)
			if(#dtsettings == 0) then return end
			check_run_settings('ÿ�ֽ���ǿ���ֻ�(���빴��ÿ�ֽ������������Ѳ���Ч)', 'oncheckfocerequeue', oncheckfocerequeue, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtgamesettings == 0) then return end
            check_run_settings('����GM���Ʒ���', 'oncheck_control_fapai', oncheck_control_fapai, tonumber(dtsettings[1]))
            table.remove(dtsettings, 1)
            if(#dtgamesettings == 0) then return end

        	if (gamepkg.init_room_settings) then
           		gamepkg.init_room_settings(dtgamesettings)
            end
        end)
end

--���������ս�Ľ�����ͻ���(���Լ��ĸ�����Ϣ)
function OnSendSelftWatch(userinfo,retcode)
    local retarr = tex.getdeskdefaultchouma(userinfo, userinfo.desk)
    local defaultchouma = retarr.defaultchouma 

    --TraceError("���������ս�Ľ�����ͻ���retcode:"..retcode)
    netlib.send(
        function(buf, user)
            buf:writeString("REWT")
            buf:writeShort(userinfo.desk)        --����
            buf:writeInt(userinfo.userId)
            buf:writeInt(userinfo.gamescore)     --���
            buf:writeByte(userinfo.sex)          --�Ա�
            buf:writeString(userinfo.imgUrl)     --ͷ��
            buf:writeInt(userinfo.nSid)          --Ƶ��Id
            buf:writeString(_U(string.HextoString(userinfo.szChannelNickName))) --Ƶ����
            buf:writeInt(usermgr.getexp(userinfo))    --����
            buf:writeInt(userinfo.tour_point)    --������
            buf:writeInt(retcode or 1)           --
            buf:writeInt(defaultchouma or 0)     -- Ĭ�ϳ��룬�����ڿͻ���������������ʾ
        end
    , userinfo.ip, userinfo.port)
end

--֪ͨ�����ˣ�˭�뿪��ս
function OnBrocastrExitWatch(desk, userinfo)
    --TraceError(format("����[%d]�����[%d]�뿪��ս", desk, userinfo.userId))
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("NTET")
            buf:writeShort(desk);	-- ����
            buf:writeInt(userinfo.userId);	-- userid
        end
    , desk, borcastTarget.all);
end

--����û�����ս�б�
function addToWatchList(deskno, userinfo)
    if(not userinfo) then return end
    if(deskno <= 0 or deskno > #desklist) then
        TraceError("��սʧ�ܣ��Ƿ�����:"..deskno)
        return
    end
    --[[if(userinfo.site ~=nil) then
        TraceError("����:����Ѿ��ڱ��λ����Ϸ")
        return
    end

    if(userinfo.desk ~=nil) then
        TraceError("����:����Ѿ��ڱ�����ӹ�ս")
        return
    end--]]

    local deskinfo = desklist[deskno]
    if(deskinfo == nil) then
        TraceError("deskinfo��ô��Ϊ�գ�addToWatchList���쳣��")
        return
    end

    --��ս������
    userinfo.desk = deskno
    userinfo.site = nil  --ǿ��ʹ���ȹ�ս

    --��ӵ����ӵĹ�ս�б�
    deskinfo.watchingList[userinfo.key] = userinfo
    deskinfo.watchingList[userinfo.key].begin_watch_time = os.time()
    deskinfo.watchercount = deskinfo.watchercount + 1
    if (duokai_lib and duokai_lib.is_parent_user(userinfo.userId) == 1) then
        --��������˺��л����䣬�������˺ż�����¼�
        eventmgr:dispatchEvent(Event("on_parent_user_add_watch", {user_info = userinfo}))
    end
end

--��ʱ֮���������3�����ϵ�VIP��������ڸ��ֳ�������
function kick_timeout_user_from_watchlist(deskinfo)
    for k, v in pairs(deskinfo.watchingList) do
        --�࿪�û����ܳ�ʱӰ��
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

--�ӹ�ս�б�ɾ���û�
function removeFromWatchList(userinfo)
    if(userinfo == nil or userinfo.desk == nil) then return end

    local deskinfo = desklist[userinfo.desk]
    if(deskinfo == nil) then
        TraceError("deskinfo��ô��Ϊ�գ�removeFromWatchList���쳣��")
        return
    end

    if(userinfo.site ~= nil) then
        TraceError("����״̬������ֱ���˳���ս")
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

--����Ӻ���
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

    --Ҫ���Ŷ���������Ҫ�������������ˣ�FELON
    netlib.broadcastdesk(sendFun, touserinfo.desk, borcastTarget.playingOnly)
end

--ͬ��Ӻ���
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

    --֪ͨ���ϵ������ˣ����������Ǻ�����
    OnSendAcceptFriendOK(fromdesk, fromuserinfo, userinfo)
end

--֪ͨ���ϵ������ˣ����������Ǻ�����
function OnSendAcceptFriendOK(desk, fromuserinfo, touserinfo)
    --TraceError("֪ͨ���ϵ������ˣ����������Ǻ�����")
    netlib.broadcastdesk(
        function(buf)
            buf:writeString("FROK")
            buf:writeInt(fromuserinfo.userId)
            buf:writeInt(touserinfo.userId)
        end
    , desk, borcastTarget.all);
end

--��ȡ��ҵ���λ��, ����ս
function getUserDesk(userinfo)
    if userinfo.desk then return userinfo.desk end
    if userinfo.watchingUser and userinfo.watchingUser.desk then return userinfo.watchingUser.desk end
    return nil
end

--���ƴ���:ת������GameCenter������
function OnRecvBufFromGameCenterToUser(buf)
    local userid = buf:readInt()
    local userinfo = usermgr.GetUserById(userid)
    if not userinfo then return end
    local sendFun = function(outBuf)
         outBuf:writeBuf(buf, buf:getRemainLen())
    end
    tools.FireEvent2(sendFun, userinfo.ip, userinfo.port)
end

--���ƴ���:
function SendBufferToGameCenter(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then return end
    room.arg.buf = buf
    room.arg.userid = userinfo.userId
    tools.SendBufToGameCenter(getRoomType(), "SDSBTC")
end

--���ƴ���:
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

--------------------------- ���� -------------------------
--����������Ϣʧ��
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
    buf:writeByte(room.arg.chatType)                                            --˽��
    buf:writeInt(room.arg.nToUserId)                    --˽��
    buf:writeString(room.arg.currchat)                --text
    buf:writeInt(room.arg.tFromUserInfo.userId)
    buf:writeString(room.arg.tFromUserInfo.nick)
end

--�յ�������������
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

    if (nType == 1) then            --˽��
        local tToUserInfo = usermgr.GetUserById(nToUserId)
        if (tToUserInfo ~= nil) then --Ҫ���͵��û��ڱ���
            SendChatToUser(1, tToUserInfo, room.arg.currchat, tFromUserInfo.userId, tFromUserInfo.nick)
        else --�û���������������
            send_buf_to_gamesvr_by_use_id(tFromUserInfo.userId, nToUserId, SendChatToGameSvr,  "ERDC")
        end
    elseif (nType == 2) then        --��������
        if tFromUserInfo.desk then
            if (gm_lib and gm_lib.check_gm_cmd(tFromUserInfo.userId, msg) == 0) then --����gm��Ϣ��������������
                room.arg.currentuser = tFromUserInfo.nick
                room.arg.userId  = tFromUserInfo.userId
                room.arg.siteno  = tFromUserInfo.site
                onsenddeskchat(tFromUserInfo.desk, nType, msg, tFromUserInfo)
            end
        end
    elseif nType == 3 then           --��ս����
        room.arg.currentuser = userNick
        room.arg.userId  = tFromUserInfo.userId
        local borcastUserKey = tFromUserInfo.key
        --������û����ڹ�ս
        if(userlist[borcastUserKey].watchingUser ~= nil) then
            borcastUserKey = userlist[borcastUserKey].watchingUser.key
        end
        borcastUserEvent("REDC", borcastUserKey)
	elseif (nType == 6) then            --����
        local tToUserInfo = usermgr.GetUserById(nToUserId)
		tools.SendBufToUserSvr(getRoomType(), "GDCT", "", "", table.tostring({userid=tFromUserInfo.userId, chatstr=room.arg.currchat}))
    elseif (nType == 7) then        --��ǰ����
        for _, userinfo in pairs(userlist) do
			if not userinfo.desk then
				SendChatToUser(7, userinfo, room.arg.currchat, tFromUserInfo.userId, tFromUserInfo.nick)
			end
		end
    else
		TraceError("�û������������ͷǷ�");
    end
end

--���͸���������Ϣ
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

--�㲥����������Ϣ
function onsenddeskchat(desk, ntype, msg, fromuserinfo)
    --TraceError("�㲥����������Ϣ")
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

----------------- �Ʋ���Ǯ�ŵ������� -------------------
--�����Ʋ���ȼ���
function OnRecvTexBankruptGiveGold (buf)
    local userKey = getuserid(buf) --�õ��ĸ��û�������key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local process_func = function()
        local givegold = room.cfg.gold_bankrupt_give_value   	  --�Ʋ���������
        local give_count = userinfo.bankruptcy_give_count or 0  --�Ʋ����ʹ���
        local give_time = userinfo.bankruptcy_give_time or 0    --�������ʱ��
        local mingold = room.cfg.gold_bankrupt_give_value  --TODO:���߱����޸�Ϊ��ʵ����
    
        if userinfo.gamescore >= mingold  then 
        	return
        end
        
        if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
        	return
        end
    
        --���쿪ʼʱ��
        local tbNow  = os.date("*t",os.time())
        local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})
    
        --����������������0�����������
        if(give_time == 0 or give_time < todaystart) then
           userinfo.bankruptcy_give_count = 1
        --����ǽ����
        else
            --�������ʹ���
            if(give_count >= room.cfg.gold_bankrupt_give_times) then
                return
            --��������
            else
                userinfo.bankruptcy_give_count = userinfo.bankruptcy_give_count + 1
            end
        end
        
        userinfo.bankruptcy_give_time= os.time()
    
        --�������ݿ�״̬ 
        local updatestr = format("give_count = %d, give_time = %d, remark = 'tex' ",userinfo.bankruptcy_give_count, userinfo.bankruptcy_give_time)
        dblib.execute(format(room.cfg.gold_bankrupt_updatesql, updatestr, userinfo.userId))
    
        --�Ʋ���Ǯ�Ĵ���
        local addGold = givegold
        if(userinfo.gamescore < 0) then
            addGold = -userinfo.gamescore + addGold
        end
    
        --�����û�������
        usermgr.addgold(userinfo.userId, addGold, 0, g_GoldType.bankruptcy, -1, 1)
        
        --֪ͨ�ͻ�
        local msgtype = userinfo.desk and 1 or 0 --1��ʾ����Ϸ�ﴦ���Э��,0�Ǵ���
        local currtimes = userinfo.bankruptcy_give_count
        local totaltimes = room.cfg.gold_bankrupt_give_times
        --local msg = format("���ɹ���ȡ�˽����Ʋ��ȼý�$%d!ÿ�� %d �Σ������ %d ��!",givegold, totaltimes, currtimes)
        local msg = format(tex_lan.get_msg(userinfo, "h2_msg_givegold").."%d!"..tex_lan.get_msg(userinfo, "h2_msg_givegold_1").."%d �Σ�"..tex_lan.get_msg(userinfo, "h2_msg_givegold_2").."%d ��!",givegold, totaltimes, currtimes)
        OnSendServerMessage(userinfo, msgtype, _U(msg))
    end
    usermgr.after_login_get_bankruptcy_info(userinfo, 1, process_func)
end

--�����Ʋ���ȼ���
function OnBankruptAutoGiveGold (buf)
    local result=1
    local userKey = getuserid(buf) --�õ��ĸ��û�������key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local process_func = function()
        local givegold = room.cfg.gold_bankrupt_give_value   	  --�Ʋ���������
        local give_count = userinfo.bankruptcy_give_count or 0  --�Ʋ����ʹ���
        local give_time = userinfo.bankruptcy_give_time or 0    --�������ʱ��
        local mingold = room.cfg.gold_bankrupt_give_value  --TODO:���߱����޸�Ϊ��ʵ����
    
        if userinfo.gamescore >= mingold  then 
        	result=-1
        end
        
        if(room.cfg.gold_bankrupt_give_value <= 0 or givegold <= 0) then
        	result=-1
        end
    
        --����в��ܷ��ȼý���������ֱ�Ӹ��߿ͻ���
        if(result == -1) then 
            --TraceError("11.22�����Ʋ���ȼ���userinfo.bankruptcy_give_count:"..userinfo.bankruptcy_give_count)
            net_send_give_gold(userinfo, result, 0)
            return
        end
    
        --���쿪ʼʱ��
        local tbNow  = os.date("*t",os.time())
        local todaystart = os.time({year = tbNow.year, month = tbNow.month, day = tbNow.day, hour = 0, min = 0, sec = 0})
    
        --����������������0�����������
        if(give_time == 0 or give_time < todaystart) then
           userinfo.bankruptcy_give_count = 1
        --����ǽ����
        else
            --�������ʹ���
            if(give_count >= room.cfg.gold_bankrupt_give_times) then
                result=-1
            --��������
            else
                userinfo.bankruptcy_give_count = userinfo.bankruptcy_give_count + 1
            end
        end
    
        --����в��ܷ��ȼý���������ֱ�Ӹ��߿ͻ���
        if(result==-1)then
            net_send_give_gold(userinfo, result, 0)
            return
        end
        
        userinfo.bankruptcy_give_time= os.time()
    
        --�������ݿ�״̬ 
        local updatestr = format("give_count = %d, give_time = %d, remark = 'tex' ",userinfo.bankruptcy_give_count, userinfo.bankruptcy_give_time)
        dblib.execute(format(room.cfg.gold_bankrupt_updatesql, updatestr, userinfo.userId))
    
        --�Ʋ���Ǯ�Ĵ���
        local addGold = givegold
        if(userinfo.gamescore < 0) then
            addGold = -userinfo.gamescore + addGold
        end
    
        --�����û�������
        usermgr.addgold(userinfo.userId, addGold, 0, g_GoldType.bankruptcy, -1, 1)
        
        --֪ͨ�ͻ�
        local msgtype = userinfo.desk and 1 or 0 --1��ʾ����Ϸ�ﴦ���Э��,0�Ǵ���
        local currtimes = userinfo.bankruptcy_give_count
        local totaltimes = room.cfg.gold_bankrupt_give_times
        
        --���߿ͻ���ִ�н��
        net_send_give_gold(userinfo, result, currtimes)
    end
    usermgr.after_login_get_bankruptcy_info(userinfo, 1, process_func)
end

--�ȼý��͸��ͻ��˽������һ���������ǲ��ǳɹ����ڶ��������Ǿȼý���ȡ�Ĵ���
function net_send_give_gold(userinfo, result, timers)
    netlib.send(
        function(buf)
            buf:writeString("RQATGIVE")
            buf:writeByte(result)
            buf:writeByte(timers)
        end
    , userinfo.ip, userinfo.port)
end

--�Ʋ���Ǯ
function OnRecvGiveGoldByBankrupt(buf)
    local userKey = getuserid(buf) --�õ��ĸ��û�������key
    local userinfo = userlist[userKey]
	if not userinfo then return end
    local minGold = 0
    if gamepkg and gamepkg.name == "tex" then  return end --���ڵ��޲���Ҫ��Ǯ
    if(gamepkg and gamepkg.GetMinGold) then
        minGold = gamepkg.GetMinGold();
    end

    local nAddGold = 150  --�����������
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

		--������������N��ˢǮ�����ݿ�������첽�ģ�����Ǯ���ܻ�+N�Σ�����������жϿ��Է�ֹ�ظ�+Ǯ
		if userinfo.gamescore > minGold then
			net_send_user_new_gold(userinfo, userinfo.gamescore)
			return
		end

		nAddGold = nAddGold - dt[1]["gold"]
		dblib.cache_inc("users", {gold = nAddGold}, "id", userlist[userKey].userId)

		userinfo.gamescore = dt[1]["gold"] + nAddGold
		local szSendBuf = userinfo.userId..","..userinfo.gamescore --���͸�gc����������Ϣ
		tools.SendBufToUserSvr(getRoomType(), "STGB", "", "", szSendBuf) --�������ݵ�����ˣ�֪ͨ������������Ǯ�ˡ�


		net_send_user_new_gold(userinfo, userinfo.gamescore)
		--todo: �������Ǯ��־û�У���Ҫ����
	end)
end

function net_send_user_new_gold(userinfo, newgold)
	local sendFunc = function(buf)
		buf:writeString("REGB")
		buf:writeInt(tonumber(newgold))
        buf:writeByte(usermgr.check_user_get_bankruptcy_give(userinfo) or 0)  --�Ƿ������ȡ�Ʋ��ȼ�
	end
	--TraceError(newgold)
	tools.FireEvent2(sendFunc, userinfo.ip, userinfo.port)
end

function OnRecvUserLeaveGame(buf)
    local szKey = getuserid(buf)
	if (userlist[szKey] == nil) then
		trace("OnRecvUserLeaveGame��ʱ���û���Ϣ������(userlist[szKey])!")
        return
    end
    local nUserId = userlist[szKey].userId
    if (nUserId == nil) then
		TraceError("OnRecvUserLeaveGame��ʱ���û�������(id)!")
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
--�û�������ص�usermgr
--�����û�BUFF
usermgr.setbuff = function(buffinfo,userinfo)
    userinfo.buff = buffinfo
end

--�õ��û���Buff
usermgr.getbuff = function(userinfo)
    if(userinfo.buff == nil) then
        userinfo.buff = {}
    end
    return userinfo.buff
end
-------------------------------------------------------------------------
--����ϵͳ���ݽṹ
--[[
    ϵͳitems���ñ���
        itemlib.items = {
            [1] = {
                id = id,                 --����ID
                main_class = main_class, --������
                sub_class = sub_class,   --�ӷ���
                price = price,           --�۸�
                name = name,             --����
                buffs_id = {}               --����Ч������,��Ӧbufflib.buffs��ID
            },
            [2] = {

            },
        }
    ϵͳbuff���ñ���
        bufflib.buffs = {
            [1] = {
                id =   --ID
                buff_time = �������ʱ��/��
                class = - 1:���������� 2������������ 3��������0
                cd_class = --  0:����ȴ  1��ÿ��0:00����ȴ

            }
            [2]...
            .....
        }

    �û���buff���壨userinfo.buff){
        [class] = {    --�������,
             start_time  = ʹ��ʱ�䣬
             over_time = ����ʱ��
             cd_class = CD��� --  0:����ȴ  1��ÿ��0:00����ȴ
             give_nick = ""
             give_userid
        },
    }
]]
-------------------------------------------------------------------------
---------------------- BUFFģ�飨�̳�ϵͳ) ------------------------------
if not bufflib then
    bufflib = {
        --���SQL
        sql = {
            get_user_buff = "insert ignore into user_buff(user_id, buff_info) values(%d,concat('')); commit; "..
                            "select buff_info from user_buff where user_id = %d;",
            update_user_buff = "update user_buff set buff_info = %s where user_id = %d;",
            get_buffs = "select * from configure_buff",
        },
        --BUFF LIST �����ݿ����õ�
        buffs = {},

        --Ч��class
        CLASS_INFO = {
            ["DOUBLE_INTEGRAL"] = 1,    --class = 1 Ϊ ˫������
            ["DOUBLE_PRESTIGE"] = 2,    --class = 2 Ϊ ˫������
            ["ZERO_INTEGRAL"] = 3,      --class = 3 Ϊ ������0
            ["DOUBLE_INTEGRAL2"] = 4,   --class = 4 Ϊ ����˫�������� * 2,���� * 1
        },
        --cd���
        CD_CLASS = {
            ["EVERYDAY"] = 1,
            ["NOCD"]     = 0,
        },

        --�����б�
        get_user_using_buff = NULL_FUNC, --�õ�ĳ�û�����ʹ�õ�buff
        get_user_buff = NULL_FUNC,      --�û���½��DB�����ڴ�
        update_user_buff = NULL_FUNC,   --�޸�ʱд��DB
    }

     --�����ݿ��ж���BUFF�����Ϣ
	timelib.createplan(function()
        dblib.execute(string.format(bufflib.sql.get_buffs),
				function(dt)
					for i = 1, #dt do
						local bufftable = {
                            id = tonumber(dt[i].id),  --ID
                            buff_time = tonumber(dt[i].buff_time), --buff_time: �������ʱ��/��
                            class = tonumber(dt[i].class), -- 1:���������� 2������������ 3��������0
                            cd_class = tonumber(dt[i].cd_class), --  0:����ȴ  1��ÿ��0:00����ȴ
                        }
                        table.insert(bufflib.buffs, bufftable)
                    end
				end
			)
        end,
    2)
end

--�û���½��DB�����ڴ�
bufflib.get_user_buff = function(user_id)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then TraceError("����BUFF��DB UserInfoΪ�գ�") return end

    dblib.execute(string.format(bufflib.sql.get_user_buff, user_id, user_id),
        function(dt)
            if(dt and #dt > 0) then
                usermgr.setbuff(table.loadstring(dt[1].buff_info),userinfo)
            end
        end
    )
end

--�õ��û�ʹ���е�buff
bufflib.get_user_using_buff = function(userinfo)
    local using_buffs = {}      --������Ч��buffs
    local userbuff = usermgr.getbuff(userinfo)

    for k, v in pairs(userbuff) do
        if(os.time() < v.over_time) then
            table.insert(using_buffs, k)
        end
    end
    return using_buffs
end

--�޸�BUFFʱд��DB
bufflib.update_user_buff = function(user_id)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then TraceError("�޸�BUFFʱд��DB UserInfoΪ�գ�") return end

    --д�����ݿ����
    dblib.execute(string.format(bufflib.sql.update_user_buff, dblib.tosqlstr(table.tostring(userinfo.buff)), user_id));
end


--����һ��buff���û�
--user_id: �û�ID
--buff_time: �������ʱ��/��
--class: buff���
--1:���������� 2������������ 3��������0
--cd_class: ��ȴ����
--[[  0:����ȴ  1��ÿ��0:00����ȴ   ]]
bufflib.add_new_buff_touser = function(user_id, buff_id, myuserinfo)
    local userinfo = usermgr.GetUserById(user_id)
    if(not userinfo) then return end

    --����user��BUFFINFO,���ݽṹ��ѭ����˵��
    local itembuff = bufflib.buffs[buff_id]
    if(not itembuff) then return end

    local buffinfo = {
        start_time = os.time(),
        over_time =  os.time() + itembuff.buff_time,
        cd_class = itembuff.cd_class,
        give_nick = myuserinfo.nick,
        give_userid = myuserinfo.userId,
    }

    --��BUFF���û���
    usermgr.getbuff(userinfo)[itembuff.class] = buffinfo

    --BUFF�����ƻ�
    if(itembuff.buff_time <= 0) then return end
    local endplan = timelib.createplan(
        function()
            local newuserinfo =  usermgr.GetUserById(user_id)
	        if(newuserinfo) then
            	--����buff��Ϣ
            	net_broadcast_buff_change(newuserinfo)
	        end
        end
    , itembuff.buff_time + 2)
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------
----------------------------- �̳�ģ�� ----------------------------------
if not itemlib then
    itemlib = {
        --���SQL
        sql = {
            get_items = "select * from configure_items",
            log_buy_item = "insert into log_buy_item (item_id, user_id, to_user_id, sys_time, before_gold, after_gold) values (%d, %d, %d, %s, %d, %d)",
        },

        --��Ʒ��Ϣ
        items = {},

        --��Ʒ��;
        ITEM_USEFOR = {
            ["DOUBLE_INTEGRAL"] = 1,    --item_id = 1 Ϊ ˫������
            ["DOUBLE_PRESTIGE"] = 2,    --item_id = 2 Ϊ ˫������
            ["ZERO_INTEGRAL"] = 3,      --item_id = 3 Ϊ ���ֻ���
			["MICRO_LOUDSPEAKER"] = 4,  --item_id = 4 Ϊ С����
            ["DOUBLE_INTEGRAL2"] = 5,  --item_id = 5 Ϊ ˫������
        },
        --�����б�
        new_items = NULL_FUNC,  --�½�item
        buy_item  = NULL_FUNC,  --����
        send_shop_items = NULL_FUNC, --�����̵���Ʒ
        can_buy_item = NULL_FUNC,   --�ɷ�����Ʒ
        use_integral_zero = NULL_FUNC, --ʹ�û�����0��
    }

    --�����ݿ��ж�����Ʒ�����Ϣ
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

--�½�item
itemlib.new_items = function(id, main_class, sub_class, price, name, buffs_id)
    local item = {
        id = tonumber(id),                 --����ID
        main_class = tonumber(main_class), --������
        sub_class = tonumber(sub_class),   --�ӷ���
        price = tonumber(price),           --�۸�
        name = name,                       --����
        buffs_id = split(buffs_id, "|"),    --Ч������
    }

    for i = 1, #item.buffs_id do
        item.buffs_id[i] = tonumber(item.buffs_id[i])
    end
    --����itemlib.items
    table.insert(itemlib.items, item)
end

--����������Ծ����Ƿ��ܹ���
--[[
    -1:����ʹ��
    -2:ûCD
    1�����Թ���
]]
itemlib.can_buy_item = function(userinfo, item_id)
    local userbuff = usermgr.getbuff(userinfo)
    local using_buffs = bufflib.get_user_using_buff(userinfo)
    local notcd_buffs = {}      --��δcd��buffs
    local iteminfo = itemlib.items[item_id]

    if(iteminfo == nil) then return 0 end

    --������0����д����
    if(item_id == itemlib.ITEM_USEFOR["ZERO_INTEGRAL"]) then
        if(usermgr.getintegral(userinfo) >= 0) then
            return -3 --����-3������ʹ��
        end
    end



    --[[
	--������
	if item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
        --���������ֳ��������Ѿ�û�л�Ա���ơ�
        if gamepkg.name == "dznew" then
            return 1
        end
		if not (viplib and viplib.check_user_vip(userinfo)) then
            if( gamepkg.name ~= "dznew")
			return -4 --����-4���ǻ�Ա����ʹ��
		end
	end
    ]]

    --�õ��û�����ʹ�õ�buffs�ͻ�δcd��buffs
    for k, v in pairs(userbuff) do
        --����ʹ����
        if(os.time() >= v.over_time) then
            --���buff��ÿ��ˢ�£����һ�û��cdʱ��
            if(v.cd_class == bufflib.CD_CLASS.EVERYDAY) then
                --�������0��00�Ժ��ù��ˣ��Ͳ�������
                if(get_today_start_ostime() < v.start_time) then
                    table.insert(notcd_buffs, k)
                end
            end
        end
    end
    for k, v in pairs(iteminfo.buffs_id) do
        local item_buff_class = bufflib.buffs[v].class
        --ȥ��ÿ�����ߵ�buff�ǲ����û�����ʹ�ã��������ʹ�û�δCD����õ��߶���Ϊ�޷�ʹ��״̬
        if(item_buff_class and item_buff_class > 0) then
            --��BUFF�ǲ����û�����ʹ��
            for i, j in pairs(using_buffs) do
                if(j == item_buff_class) then
                    return -1   --����-1������ʹ��
                end
            end
            --��BUFF�Ƿ�δCD?
            for i, j in pairs(notcd_buffs) do
                if(j == item_buff_class) then
                    return -2   --����-2����Ʒ��δCD
                end
            end
        end
    end
    return 1
end

--�����¼�����
itemlib.buy_item = function(myuserinfo, touserinfo, item_id, tag)

    --�������Ƿ����
    if(itemlib.items[item_id] == nil) then return end

    --�������Ƿ�ﵽʹ������
    if(itemlib.can_buy_item(touserinfo, item_id) <= 0) then return end

	--�����������  �������ǲ������͵ģ�
	if myuserinfo ~= touserinfo and item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
		return
	end

    local iteminfo = itemlib.items[item_id]
    local nsuccess = 0
    
	local price = iteminfo.price
    --ȥ��VIP�ĵ��Ż�
    --[[
    	if viplib and viplib.check_user_vip(myuserinfo) then
    		price = math.floor(price * 0.9)
        end 
    --]]

    --����ҽ���Ƿ��㹻
	if(price <= myuserinfo.gamescore and can_user_afford(myuserinfo,price)) then
        local before_gold = myuserinfo.gamescore
        --�����û���ң�ע���Ǹ�������Ǯ��
        usermgr.addgold(myuserinfo.userId, -price, 0, g_GoldType.buy, -1)
        --д����߹�����־

        local actionSql = string.format(itemlib.sql.log_buy_item,item_id,
                                        myuserinfo.userId,
                                        touserinfo.userId,
                                        dblib.tosqlstr(os.date("%Y-%m-%d %X", os.time())),
                                        before_gold,
                                        myuserinfo.gamescore);
        dblib.execute(actionSql)

        --�����Լ�ʹ�ã���¼������־
        --TODO
        --if(myuserinfo.userId ~= touserinfo.userId) then

        --end

		
        --�����û�buff״̬
        local userbuff = usermgr.getbuff(touserinfo)
        for k, v in pairs(iteminfo.buffs_id) do
            bufflib.add_new_buff_touser(touserinfo.userId, v, myuserinfo)
        end
        nsuccess = 1
         --д��buff
        bufflib.update_user_buff(touserinfo.userId)
        --���͹�����߽��
        net_send_buy_item(myuserinfo, nsuccess)

        --д��ID=3��������0����������Ч
        if(item_id == itemlib.ITEM_USEFOR["ZERO_INTEGRAL"]) then
            itemlib.use_integral_zero(touserinfo)
        end

        --����buff��Ϣ
        net_broadcast_buff_change(touserinfo)

        --ˢ���̵�״̬
        itemlib.send_shop_items(myuserinfo, touserinfo)
    else

        --���͹�����߽��
        net_send_buy_item(myuserinfo, nsuccess)
        --���������ֳ�,����Ҫ�����̵�״̬
    	if item_id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"] then
            --���������ֳ��������Ѿ�û�л�Ա���ơ�
            if gamepkg.name == "dznew" then
                return
            end
    	end
        --ˢ���̵�״̬
        itemlib.send_shop_items(myuserinfo, touserinfo)
    end
end

--�����̵���Ʒ
itemlib.send_shop_items = function(myuserinfo, touserinfo)
    local userbuff = usermgr.getbuff(touserinfo)
    local send_item_info = {}
	local items =  table.clone(itemlib.items)

	--����������Ч��buffs �� ��δcd��buffs���ı���ߵ�һЩ���ԣ��Ƿ����
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

		--���������������  �������ǲ������͵ģ�
        --���˵�4�ŵ��ߣ�4�ŵ��߲������̵���
		if (not(myuserinfo ~= touserinfo and v.id == itemlib.ITEM_USEFOR["MICRO_LOUDSPEAKER"])) and
            (v.id ~= itemlib.ITEM_USEFOR["DOUBLE_INTEGRAL2"]) then
			send_item_info[k] = v
		end
    end
    --֪ͨ�ͻ����̵������Ϣ
    net_send_shop_item_list(myuserinfo,touserinfo, send_item_info)
end

--ʹ�û�����0��
itemlib.use_integral_zero = function(userinfo)
    --������һ���
    if(usermgr.getintegral(userinfo) < 0) then
        usermgr.addintegral(userinfo.userId, -usermgr.getintegral(userinfo))
        return 1
    end
    return 0
end

------------------------------------------------------------------------------------
----------------------------------- ���߲���Э�� -----------------------------------
------------------------------------------------------------------------------------
--�õ�����0��00��OSTIME
function get_today_start_ostime()
    local today_table = os.date("*t", os.time())
    return os.time({year = today_table.year, month=today_table.month, day = today_table.day, hour= 0,min=0,sec=0})
end

--�յ���������б�
function on_recv_shop_item_list(buf)
    local myuserinfo = userlist[getuserid(buf)]
    local to_userid = buf:readInt()
    local touserinfo = usermgr.GetUserById(to_userid)
    if(not touserinfo or not myuserinfo) then return end

    itemlib.send_shop_items(myuserinfo, touserinfo)
end

--�յ��������
function on_recv_buy_item(buf)
    --TraceError("--�յ��������")
    local myuserinfo = userlist[getuserid(buf)]
    local request_item_id = buf:readInt()
    local to_userid = buf:readInt()
	local tag = buf:readString()
    local touserinfo = usermgr.GetUserById(to_userid)

    if(not myuserinfo or not touserinfo) then return end
    itemlib.buy_item(myuserinfo, touserinfo, request_item_id, tag)
end


--�յ�ˢ���û�buff
function on_recv_user_buff(buf)
    local userinfo = userlist[getuserid(buf)]
    net_broadcast_buff_change(userinfo)
end

--���͹�����߽��
function net_send_buy_item(userinfo, nsuccess)
    netlib.send(
		function(buf)
			buf:writeString("ITEMBUY")
            buf:writeInt(nsuccess)
        end
    , userinfo.ip, userinfo.port)
end

--֪ͨ�û�buff�����ı�
function OnSendUserBuffChange(userinfo, changeuserinfo)
	if not userinfo or not changeuserinfo then return end

    local userbuff = usermgr.getbuff(changeuserinfo)
    netlib.send(
        function(buf)
            buf:writeString("BUFFCHANGE")
            buf:writeInt(changeuserinfo.userId)
            buf:writeInt(changeuserinfo.site and changeuserinfo.site or 0)
            --ֻ������Ч��buff
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
                    buf:writeInt(v.over_time) --����ʱ��
                    buf:writeInt(v.cd_class)  --��ȴ����
                    buf:writeInt(v.give_userid)
                    buf:writeString(v.give_nick)
                end
            end
        end
    , userinfo.ip, userinfo.port)
end

--֪ͨ�����������ĳ��ҵ�������Ϣ()
function net_broadcast_buff_change(userinfo)
    if not userinfo then return end
    --֪ͨ�������
    local deskno = userinfo.desk
    --û�����Ӻţ�ֻ�����Լ�
    if(not deskno) then
        OnSendUserBuffChange(userinfo, userinfo)
        return
    end

    --֪ͨ������������
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playingUserinfo = userlist[hall.desk.get_user(deskno, i) or ""]
            if (playingUserinfo and playingUserinfo.offline ~= offlinetype.tempoffline) then
                OnSendUserBuffChange(playingUserinfo, userinfo)
            end
            if(playingUserinfo == nil) then
                TraceError("�û�����ʱ�������и��û���userlist��ϢΪ��2")
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


--�����̵�����б�
function net_send_shop_item_list(userinfo, touserinfo, send_item_info)
	netlib.send(
		function(buf)
			buf:writeString("SPITEMLIST")
            buf:writeInt(touserinfo.userId)
            local itemcount = 0
            for k, v in pairs(send_item_info) do
                itemcount = itemcount + 1
            end
            buf:writeInt(itemcount)         --��������
            for i = 1, itemcount do
                buf:writeInt(send_item_info[i].id)             --����ID
                buf:writeInt(send_item_info[i].main_class)     --������
                buf:writeInt(send_item_info[i].sub_class)      --�ӷ���
                buf:writeInt(send_item_info[i].price)          --�۸�

                local buffcount = 0
                for k, v in pairs(send_item_info[i].buffs_id) do
                    buffcount = buffcount + 1
                end
                buf:writeInt(buffcount)        --����Ч������

                for j = 1, buffcount do
                    local buffid = send_item_info[i].buffs_id[j]
                    buf:writeInt(buffid)                            --Ч��ID
                    buf:writeInt(bufflib.buffs[buffid].buff_time)   --Ч������ʱ��
                    buf:writeInt(bufflib.buffs[buffid].class)       --Ч�����1:���������� 2������������ 3��������0)
                    buf:writeInt(bufflib.buffs[buffid].cd_class)    --��ȴ���ͣ�0����CD��1��ÿ��0��00 CD)
                end

                buf:writeInt(send_item_info[i].using)  --�Ƿ�����ʹ��
                buf:writeInt(send_item_info[i].nocd)   --�Ƿ�δCD
                buf:writeInt(send_item_info[i].noneed)   --�Ƿ�����ʹ��
				buf:writeInt(send_item_info[i].novip)   --�Ƿ�ǻ�Ա���²���ʹ��
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
--�յ��ͻ���GM���Ʒ���
function on_recv_gm_control_fapai(buf)
    if is_allow_gm_control_fapai() == 0 then
        TraceError(" �Ƿ����Ƴ��� ")
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

--�յ�������������
function on_recv_friend_rank(buf)
    local userinfo = userlist[getuserid(buf)]

     --�õ������б�
	 --��ʱ����SNS�����б�snsfriends
    local get_friend_sql = "select CONCAT(friends) as friends from user_friends where user_id = %d";
    local get_rank_sql = "select b.integral,b.prestige,a.id,a.nick_name,a.sex, a.user_name,concat(face) as face,a.reg_site_no,a.gold from" ..
				" (select experience,prestige,integral,last_win,last_lose, recent_date,last_date,recent_win, recent_lose, userid from ".. gamepkg.table ..
                " where userid in (%s)) b, users a where a.id = b.userid";

    dblib.execute(string.format(get_friend_sql, userinfo.userId), function(dt)
        if(#dt > 0 and dt[1]["friends"]) then
            local friend_list = split(dt[1]["friends"], "|")
            --ƴд��ѯSQL
            local idstr = ""
            for k, v in pairs(friend_list) do
                if(v and v ~= "") then
                    idstr = idstr .. v .. ","
                end
            end
            idstr = idstr .. userinfo.userId

            --ȡ�ú�������
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
--����VIP��Ա����ӵĽ���
function calc_vip_add_gold(userinfo)
    --VIP�����Ǯ
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
        userinfo.cangivedaygold = nil --���
        result = 1
        gold = 500 --math.random(tSqlTemplete.CONFIG.MINGIVE,tSqlTemplete.CONFIG.MAXGIVE)  --��Ϊֻ��500 by lch
        vipadd = calc_vip_add_gold(userinfo)
        charmadd = userinfo.charmgold or 0
        usermgr.addgold(userinfo.userId, gold, 0, g_GoldType.daygive, -1)--��Ǯ��
        usermgr.addgold(userinfo.userId, vipadd, 0, g_GoldType.vipdaygive, -1)--ÿ��VIP�ӳ���Ǯ
        usermgr.addgold(userinfo.userId, charmadd, 0, g_GoldType.charmdaygive, -1)--ÿ�������ӳ���Ǯ
        --д�����ݿ�
        dblib.execute(string.format(tSqlTemplete.check_daygold_cangive,userinfo.userId,dblib.tosqlstr(userinfo.ip),tSqlTemplete.CONFIG.LIMITNUM,1))
    end
    --��������������������˷�Ǯ
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

--���ÿ�յ�½��Ǯ�Ƿ�Ϸ�
function give_daygold_check(userinfo)
    if not userinfo then return end
    if usermgr.getlevel(userinfo) < 1 then 
		netlib.send(
                    function(buf)
                        buf:writeString("SHOWDAYGOLD")
                        buf:writeInt(0)
                        buf:writeInt(0)  --���VIP�ȼ�
                        buf:writeInt(0)  --VIP�ӳ�
                    end,userinfo.ip,userinfo.port)
		return
	end
    
    dblib.execute(string.format(tSqlTemplete.check_daygold_cangive,userinfo.userId,dblib.tosqlstr(userinfo.ip),tSqlTemplete.CONFIG.LIMITNUM,0),--10����������û�
        function(dt)
            if dt and #dt > 0 then
                --1��ʾ�콱��-1��ʾ�����콱    
                userinfo.cangivedaygold = tonumber(dt[1]["result"])
                if not userinfo.cangivedaygold then userinfo.cangivedaygold = 0 end
                --VIP�����Ǯ
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
                        buf:writeInt(max_VIP_Level)  --���VIP�ȼ�
                        buf:writeInt(VIPadd)  --VIP�ӳ�
                    end,userinfo.ip,userinfo.port)
            else            	 
                TraceError("����ѯ����ܷ���Ǯ�����쳣")
            end
        end)
end

--���ط���ϵͳ����
function on_recv_show_freeback(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then return end
    
    local result = 1
    --2011��4��1��ǰ��ÿ��0��00  -- ��������10��00�����ε�����ķ���ϵͳ��
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
            buf:writeByte(result)  --�����Ƿ����ʹ�÷���ϵͳ:0�����ԣ�1����
        end,userinfo.ip,userinfo.port)
end

--�յ���ѯ�����ʷ��߳�ֵ���
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
                --�·��ͻ���
                SendFun(userinfo.history_maxpay);
    		end)
    end
end

--�ͻ��˲�ѯ�Ƿ���ʾ�Ƿ���Ҫ��ʾ��ɫѡ�����
--ֱ�ӷ��ظ��ͻ���
function on_recve_show_authorbar(userinfo)
  --  TraceError("on_recve_show_authorbar:::");
    local usersex=-1;--1=>�У�0=>Ů���쳣=>-1
    local showflag=0;--0����ʾ��� ��1��ʾ���
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
                buf:writeByte(showflag)  --�Ƿ���ʾ
                buf:writeByte(usersex)
                buf:writeString(_U(nickname))              
            end,userinfo.ip, userinfo.port)
end



--�����û��ǳ�
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
    local errMsg = "" 	--���´�����Ϣ
    local isSucc = 0	--�Ƿ���³ɹ���1���ɹ���0��ʧ��
    if (v_sex == 0) then
        face = "face/1001.jpg"    
    else
        face = "face/1.jpg"
    end
    v_nickname=_tosqlstr(v_nickname);
    
    if(texfilter) then
	    if(texfilter.is_exist_pingbici(v_nickname))then
	    	--errMsg = "�������дʻ㣬����������"
	    	errMsg = tex_lan.get_msg(userinfo, "h2_msg_err_1");
        else
	       userinfo.nick=v_nickname
	       userinfo.sex=v_sex
	       userinfo.imgUrl=face
	       dblib.cache_set("users", {nick_name=v_nickname,sex=v_sex,face=face}, "id", userinfo.userId);
	       isSucc = 1
	       --errMsg = "���³ɹ������µ�¼��Ч"
	       errMsg = tex_lan.get_msg(userinfo, "h2_msg_err_2");
	    end 
	   
	    netlib.send(
	        function(buf)
	            buf:writeString("TEXUSERNICK")  --дЭ��ͷ
	            buf:writeByte(isSucc)
	            buf:writeString(_U(errMsg))
                buf:writeString(userinfo.nick or "")
                buf:writeByte(userinfo.sex or 0)
                buf:writeString(userinfo.imgUrl or "")
	        end
    	, userinfo.ip, userinfo.port);
	    
	end
 
end

--�����û�Ƶ����Ϣ
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
--�յ������û���Ȩ��
function on_recve_keep_tocken(buf)
	local user_info = userlist[getuserid(buf)];
	local user_tocken = buf:readString();
	if user_info == nil or user_tocken == nil or user_tocken == "" or user_info.init_keep_tocken ~= nil then return end;
	user_info.init_keep_tocken = 1;
	--ֻҪ�����һ�ε�½��
	local sql = "INSERT IGNORE INTO dw_user_tocken VALUE (%d, %s);COMMIT;";
	sql = string.format(sql, user_info.userId, dblib.tosqlstr(user_tocken));
	dblib.execute(sql);
end

--�õ�ĳ��ȫ�ֲ���ֵ
function get_param_value(param_key,call_back)
   -- TraceError("get_param_value");
   if(call_back==nil) then return end;
    dblib.cache_get("cfg_param_info","param_value","param_key",param_key,
    			function(dt)
                    if dt and #dt > 0 then
                        call_back(dt[1]["param_value"]);
                    else
                        TraceError("��ȡ����ʧ��cfg_param_info")
                    end
                end)
end

--��Ϸ�����¼�
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

--����ĳ��ȫ�ֲ���ֵ
function set_param_value(param_key,param_value)
   -- TraceError("set_param_value");
    dblib.cache_set("cfg_param_info", {param_value=param_value}, "param_key", param_key);
end



---------------------------------------------------------------------------------
hall.init_map = function()
	--log("��ʼ ���� �����ʼ��������ȫ�������ش����ʱ��ִ��")
	cmdHandler = {
	
	["RQCK"] = onsendrqck,              --Ҫ��ͻ����ṩ�Ự��Կ
	["RECK"] = onrecvreck,              --�ͻ�����Ӧ�Ự��Կ
	["CKOK"] = onsendckok,              --���߿ͻ�����Կ��֤�ɹ�
	["VCOF"] = onclientoffline,         --�յ�ĳ�û�������Ϣ
	["NTOF"] = onnotifyoffline,         --����ĳ�û�����֪ͨ
    
	["RQSD"] = onrecvrqsitdown,         --�ͻ�����������ĳ��λ��
	
    --�Ŷ����
    ["RQAJ"] = onrecvrAutoJoin,       --�û������Զ�������Ϸ
	["RQDQ"] = onrecvrqDeskQueue,       --�յ�ĳ�û������Ŷ�
	["NTQC"] = onnotifyDeskQueuePlayer, --�㲥�����Ŷ��е��û�����
	["RQCQ"] = onRecvCancelQueue,       --�յ�ĳ�û�ȡ���Ŷ�
	
	["RQSU"] = onrecvstandup,           --�û�����վ����
    ["RQBH"] = onrecvsbacktohall,       --�û�����ش���
	
	["RQLG"] = onrecvlogin,           --���˿�ʼ��¼
	["MOBLOGIN"] = on_mobile_login,    --�������ֻ���¼
	
	["RETT"] = OnRecvNetworkCheck,    --����û�����״��
	
	["IMBT"] = onrecviamrobot,        --�������������

	['NTLG'] = OnNotifyLogin,        --��ҵ�¼

    ["RQDS"] = OnQuestDeskList,    --���������б�
    ["SDDU"] = OnRequireDeskUser,    --���������������б�
	['RQCLR'] = OnClientLeaveRoom,		-- �ͻ���֪ͨ����뿪���������������������ƣ������뿪�������������������
	['RQRSL'] = OnRequireRoomSortList,   --����ǰ�����û�����
	['RQASL'] = OnRequireRoomUserList,   --����ǰ��������б�
	
	['RQCF'] = OnChangeFace,        --�޸�ͷ��
	['RAAF'] = on_active_extra_face, --��������ͷ��
	['RAHD'] = on_recv_select_head_info, --������ʾͷ���б���Ϣ
	['NTUM'] = OnNotifyChangeGold,        --֪ͨ��ҷ����仯
	["SDOU"] = OnStatisticsOnline, --ͳ�Ƶ�ǰ����������Ϣ
	["RQOC"] = OnRecevOnlineCount, --�յ��ͷ���������������ѯ
	["SDNO"] = OnNotifyOnlineUsers, --��������������Ϣ
	["RQOS"] = OnQuestServerCount, --����õ�������������

	["GMSK"] = OnStrongKickUser, --ͨ��ID����û���GC������
	["GMBC"] = OnBroadcasetToClient, --�յ���Ϸ���ĵķ��͹㲥��Ϣ
	["RQGB"] = on_require_refresh_user_info, --�յ��ͻ���ˢ���û���Ϣ
	["GCRG"] = OnRegisterGameSvr, -- ??
	["RQUS"] = OnRequestGetSvrId,  --��ȡ�û����Ǹ���������
	["REUS"] = OnRecvGetSvrId,  --��ȡ�û����Ǹ���������
	
	["REWT"] = OnRecvRqWatch,       --�յ������ս
	["REET"] = OnRecvExitWatch,     --�յ������˳���ս
	
	["RQAF"] = OnRequestAddFriend,
	["ACAF"] = OnAcceptAddFriend,
	
	["RQDC"] = onrecvdeskchat,              --��������
	["ERDC"] = OnRecvChatError,             --�յ�����������Ϣʧ��
	["RECT"] = OnRecvChatFromGameSvr,       --�յ�������������������������Ϣ
	["ECHO"] = OnEcho,                      --�ͻ��˼������
	["RQGG"] = OnRecvGiveGoldByBankrupt,    --�Ʋ���Ǯ

    ["RQGIVE"] = OnRecvTexBankruptGiveGold,    --�����Ʋ���ȡ�ȼ�
    ["RQUL"] = OnRecvUserLeaveGame,         --�û��뿪��Ϸ��,����ֻ���˵�ѡ��Ϸ����ŷ���
	["RQUE"] = OnRecvUserEnterGame,         --�û�������Ϸ�ˣ�����ֻ��ѡ��Ϸ�ŷ���
	["RQCS"] = onrequestchangesite,      --��������

    ["RQATGIVE"] = OnBankruptAutoGiveGold,    --�����Ʋ��Զ���ȡ�ȼã��ֶ���ȼõĽӿڲ��䣬���ּ����ԡ�
	
	------------------------------------------------------------------
	--����ܹ����
	["GCGS"] = OnRecvBufFromGameSvr,    --�յ�����GameServerͨ��GameCenter����������Ϣ
	["GSPP"] = on_send_gs_buf_to_user_id,    --����buf����������������������ͨ���û�id�ж�
    ["GSSG"] = on_send_gs_buf,    --����buf�����з�����
        
	["SBTU"] = OnRecvBufFromGameCenterToUser,    --ת������GameCenter������
	["EXEOVER"] = on_exe_over,					--��GameCenterҪ�رյ�ʱ��
	["SCTC"] = SendBufferToGameCenter,
	["SDSBTC"] = OnSendBufferToGameCenter,
	
	["REGICP"] = onrecv_gameinfo_copy,  --�յ��õ���Ϸ��Ϣ��������
	
	["GCGETINFO"] = onrecv_gc_get_info,
	
	["GCREPYINFO"] = onrecv_gc_reply_info,
	
	------------------ �����̳ǲ��� --------------------
	["SPITEMLIST"] = on_recv_shop_item_list, --�յ������б�
	
	["ITEMBUY"]  = on_recv_buy_item,        --�������
	
	["USERBUFF"] = on_recv_user_buff,       --�յ�ˢ���û�buff
	
	----------------------------------------------------
	["GMCTFP"]  = on_recv_gm_control_fapai,  --�յ�gm���Ʒ���
	--["FRRANK"] = on_recv_friend_rank,       --�յ�������������

    ["RQDAYGOLD"] = on_recv_daygold_give, --�յ�ÿ�յ�½��Ǯ

    ["SHOWFEEDBK"] = on_recv_show_freeback, --�ͻ��˲�ѯ�Ƿ���ʾ������ť
    ["REHISMPAY"] = on_recve_quest_user_maxpay, --�յ���ѯ��ʷ��߳�ֵ���   
    
    -----------------�Խ����-------------------------
    ["TEXAUTHORBAR"] = on_recve_show_authorbar, --�ͻ��˲�ѯ�Ƿ���ʾ�Ƿ���Ҫ��ʾ��ɫѡ�����
    ["TEXUSERNICK"] = on_recve_update_usernick, --�����û��ǳ�
    ["TEXUSERCHANNEL"] = on_recve_update_channel, --����Ƶ��
    ["TEXTOCKEN"] = on_recve_keep_tocken,	--�յ������û���Ȩ�루��Ҫ����YY��
	}
	trace("�ɹ���� ����˴��� ��ʼ��")
end

hall.init_map();

--[[
����Լ��
RQ,����ǰ׺
SD,�ڽ���ʱ��Ҫ������Ӧ��ʹ��SD��Ϊǰ׺
RE,���������ѯ���

NT,֪ͨ��Ϣ,�ɷ���������ⷢ,���ǿͻ�����������Ĳ�ѯ���
]]
