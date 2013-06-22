--[[
    ��ս��ط���
    author lj
--]]
if (watch_lib and watch_lib.on_sitdown) then
    eventmgr:removeEventListener("site_event", watch_lib.on_sitdown)
end

if (watch_lib and watch_lib.on_standup) then
    eventmgr:removeEventListener("before_standup_event", watch_lib.on_standup)
end

if (watch_lib and watch_lib.on_game_over) then
    eventmgr:removeEventListener("on_game_over_event",	watch_lib.on_game_over)
end

if not watch_lib then
    watch_lib = 
    {
        can_watch = NULL_FUNC, --�ж��û��Ƿ���Թ�ս
        on_sitdown = NULL_FUNC, --�û������¼�
        on_standup = NULL_FUNC, --�û�վ����
        is_watch_user = NULL_FUNC, --�Ƿ��ǹ�ս�û�
        del_watch_user = NULL_FUNC, --ɾ����ս�û�
        add_watch_user = NULL_FUNC, --���ӹ�ս�û�
        on_game_over = NULL_FUNC, --��Ϸ������ս�û�
        del_watch_desk = NULL_FUNC, --ɾ��һ���Ĺ�ս�û�
        on_recv_request_watch = NULL_FUNC, --�����ս

        on_recv_request_exit_watch = NULL_FUNC, --�����뿪��ս
        do_user_exit_watch = NULL_FUNC, --�뿪��ս
        on_recv_request_auto_join = NULL_FUNC, --�����Զ�������Ϸ,�������¾͹�ս
        do_user_watch = NULL_FUNC, --��ս����
        net_send_self_watch = NULL_FUNC, --�����Լ���ս
        on_recv_request_watch = NULL_FUNC, --�����ս

        watch_game =   --֧�ֹ�ս����Ϸ
        {
            zysz = 1, 
            cow = 1, 
            soha = 1, 
            cow_new = 1
        }  
    }
end

function watch_lib.can_watch(desk_no, is_game_start)
    if(is_game_start == nil) then
        if (gamepkg.getGameStart(desk_no) == false) then  --��Ϸû�п�ʼ���ܹ�ս
            return 0
        end
    end
    if (watch_lib.watch_game[gamepkg.name] ~= nil) then
        if (cow_jifen_lib ~= nil and cow_jifen_lib.can_watch() == 0) then
            return 0
        end
        return 1
    else
        return 0
    end
end

--�Ƿ�վ���ս�û�
function watch_lib.is_standup_watch(user_info)
    if (user_info.desk == nil) then
        return 0
    end
    local desk_info = desklist[user_info.desk]
    if (desk_info.watch_list ~= nil and desk_info.watch_list[user_info.userId] == 2) then
        return 1 
    end
    return 0 
end

function watch_lib.is_watch_user(user_info)
    if (user_info.desk == nil) then
        return 0
    end
    local desk_info = desklist[user_info.desk]
    if (desk_info.watch_list == nil or desk_info.watch_list[user_info.userId] == nil) then
        return 0
    end
    return 1
end

function watch_lib.del_watch_desk(desk_no)
    local desk_info = desklist[desk_no]
    desk_info.watch_list = {}    
end

function watch_lib.get_watch_count(desk_no)
    local desk_info = desklist[desk_no]
    return desk_info.watch_count or 0;
end

--ɾ�����¹�ս�û�
function watch_lib.del_watch_desk_ex(desk_no)
    local desk_info = desklist[desk_no]
    if(desk_info.watch_list ~= nil) then
        for k, v in pairs(desk_info.watch_list) do
            if(v == 1) then
                desk_info.watch_list[k] = nil;
            end
        end
    end
end

--ɾ����ս�û�
function watch_lib.del_watch_user(user_info)
    local desk_info = desklist[user_info.desk]

    if(desk_info == nil) then
        return;
    end

    if (desk_info.watch_list == nil) then
        desk_info.watch_list = {}
    end

    if(desk_info.watch_list[user_info.userId] ~= nil) then
        if(desk_info.watch_list[user_info.userId] == 2) then
            desk_info.watch_count = desk_info.watch_count - 1;
            if(desk_info.watch_count < 0) then
                desk_info.watch_count = 0;
            end
        end
        desk_info.watch_list[user_info.userId] = nil;
    end
end

--ɾ�����º��ս���û�
function watch_lib.del_watch_user_ex(user_info)
    local desk_info = desklist[user_info.desk]
    if (desk_info.watch_list == nil) then
        desk_info.watch_list = {}
    end
    if(desk_info.watch_list[user_info.userId] ~= nil and desk_info.watch_list[user_info.userId] == 1) then
        desk_info.watch_list[user_info.userId] = nil;
    end
end

function watch_lib.add_watch_user(user_info, watch_type)
    if (user_info.desk ~= nil) then
        local desk_info = desklist[user_info.desk]
        if (desk_info.watch_list == nil) then
            desk_info.watch_list = {}
        end
        if(watch_type == nil) then
            watch_type = 1;
        end

        if(watch_type == 2) then
            if(desk_info.watch_count == nil) then
                desk_info.watch_count = 0;
            end
            desk_info.watch_count = desk_info.watch_count + 1;
        end

        desk_info.watch_list[user_info.userId] = watch_type; 
    end
end



function watch_lib.on_standup(e)
    local user_info = e.data["user_info"]
    --���ش�������չ�ս�б�
    watch_lib.del_watch_user_ex(user_info)
end

function watch_lib.on_game_over(e)
    local user_info = e.data["user_info"]
    watch_lib.del_watch_desk_ex(user_info.desk)
end

function watch_lib.on_sitdown(e)
    local user_info = e.data["user_info"]
    if user_info == nil then return end
    local desk_info = desklist[user_info.desk]
    local desk_sites = desk_info.site --��λ�б�
    
    -- [[
    if (watch_lib.can_watch(e.data["deskno"]) == 1 and gamepkg.getGameStart(e.data["deskno"]) == true) then  --�����Ϸ�Ѿ���ʼ�������¾�����Ϊ��ս״̬
        watch_lib.add_watch_user(user_info)
        netlib.send(function(buf)
            buf:writeString("GZZT");
            buf:writeByte(#desk_sites);
            for i=1,#desk_sites do
            	local site_id = -1;
            	if desk_sites[i].user ~= nil and userlist[desk_sites[i].user] ~= nil then --����λ����
            		if desk_info.watch_list == nil or desk_info.watch_list[userlist[desk_sites[i].user].userId] ~= 1 then --���Ҹ���λ�ϵ��˲��ڹ�ս�б�
            			site_id = i;
            		end
            	end
            	buf:writeByte(site_id);
            end
        end, user_info.ip, user_info.port)
    end
    --]]
end

function watch_lib.on_recv_request_watch(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local desk_no = buf:readInt(); 
    if(watch_lib.can_watch(desk_no, 1) == 1) then
        watch_lib.do_user_watch(desk_no, user_info, 1);
    end
end

function watch_lib.net_send_self_watch(user_info, retcode)
    --TraceError("���������ս�Ľ�����ͻ���retcode:"..retcode)
    netlib.send(
        function(buf)
            buf:writeString("REWT")
            buf:writeString(user_info.nick);
            buf:writeShort(user_info.desk)        --����
            buf:writeByte(user_info.site or -1);
            buf:writeInt(user_info.gamescore) --д�����
            buf:writeInt(user_info.wealth.dzcash) --���˱�
            buf:writeInt(user_info.wealth.bean) --���ֶ�
            buf:writeInt(user_info.wealth.homepeas) --��԰��
            buf:writeString(user_info.imgUrl)     --ͷ��
            buf:writeByte(user_info.sex)          --�Ա�
            buf:writeByte(0);                     --��ʼ״̬
            buf:writeInt(user_info.userId)
            buf:writeString(string.HextoString(user_info.szChannelNickName))
            buf:writeInt(usermgr.get_user_exp(user_info))
            buf:writeInt(user_info.nSid or -1);
            buf:writeInt(user_info.tour_point or 0);
            buf:writeByte(retcode or 1)           --
        end
    , user_info.ip, user_info.port)
end

function watch_lib.do_user_watch(deskno, user_info, retcode)
    if(deskno == nil) then return end
    local desk_info = desklist[deskno]
    if(desk_info == nil) then return end

    --ֻ����25�˹�ս(�������Ƶ����)
    if watch_lib.get_watch_count(deskno) + desk_info.playercount >= 25 then
        netlib.send(function(buf)
            buf:writeString("WTFULL");
        end, user_info.ip, user_info.port);
        return;
    end

    if(watch_lib.is_playing(user_info) == 1) then
        TraceError("����ڴ��ƣ�������ս"..user_info.userId);
        return;
    end

    if(user_info.site ~= nil) then
      --TODO �жϸ���λ�ϵ�״̬���Ƿ�ʼ��Ϸ
      doUserStandup(user_info.key, false)
      --δ֪ԭ��վ��������
      if(user_info.site ~= nil)then return end
    end

    --�����ս�б�
    user_info.desk = deskno;
    watch_lib.add_watch_user(user_info, 2);

    --���Լ����͹�ս�ɹ���Ϣ
    if(retcode == nil) then retcode = 1 end
    watch_lib.net_send_self_watch(user_info, retcode)

    --�㲥�������˽�����ս��
    local time1 = os.clock() * 1000
    for i = 1, room.cfg.DeskSiteCount do
        local tempuserkey = hall.desk.get_user(deskno,i);
        if(tempuserkey) then
            local playing_user_info = userlist[hall.desk.get_user(deskno,i) or ""]
            if (playing_user_info and playing_user_info.offline ~= offlinetype.tempoffline) then
                net_send_user_sitdown(user_info, playing_user_info, retcode, 0);
            end
        end
    end

    --����ս�б���û���û�����ߵ�
    for k, _ in pairs(desk_info.watch_list) do
        if(usermgr.GetUserById(k) == nil) then
            desk_info.watch_list[k] = nil;
        end
    end

    local time2 = os.clock() * 1000
    if (time2 - time1 > 500)  then
        TraceError("֪ͨ������������ս,ʱ�䳬��:"..(time2 - time1))
    end
    
    --�����ս�ɷ������¼�
    dispatchMeetEvent(user_info)

    if(gamepkg.AfterUserWatch ~= nil) then
        gamepkg.AfterUserWatch(user_info);
    end

    eventmgr:dispatchEvent(Event("on_watch_event", _S{user_info=user_info}));
end

function watch_lib.is_playing(user_info)
    local ret = 0;
    if(user_info.desk and user_info.site) then
        local site_state = hall.desk.get_site_state(user_info.desk, user_info.site)
        if(site_state ~= SITE_STATE.NOTREADY and site_state ~= SITE_STATE.WATCH) then
            ret = 1;
        end
    end
    return ret;
end

function watch_lib.on_recv_request_auto_join(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local desk_no = buf:readInt();--Ҫ��������Ӻ�
    local ntype = buf:readByte();--��������

    --�ж������ܲ��ܹ�ս
    if(watch_lib.can_watch(desk_no, 1) == 0) then
        return;
    end
    
    --�ж�����Ƿ��ڴ���,�ڴ��ƾͲ���ȥ��ս
    if(watch_lib.is_playing(user_info) == 1) then
        TraceError("����ڴ��ƣ�������ת"..user_info.userId);
        return;
    end

    --���ж���û�п���λ
    local site_no = hall.desk.get_empty_site(desk_no);
    --������Ƿ��㹻
    local retcode, value = can_user_enter_desk(user_info.key, desk_no);

    if(retcode == 98) then
        retcode = 0;
    end

    --����֮ǰ�Ƿ���Ҫ�������
    if(user_info.desk ~= nil and user_info.site ~= nil and user_info.desk == desk_no) then
        TraceError('�Ѿ�������'..user_info.userId);
        return;
    end

    if retcode == 1 and site_no > 0 then
        watch_lib.do_user_exit_watch(user_info);
        doSitdown(user_info.key, user_info.ip, user_info.port, desk_no, site_no);
    else
        --���ǹ�ս�û��ٽ��й�ս
        if(watch_lib.is_watch_user(user_info) == 0) then
            --���������¾͹�ս
            watch_lib.do_user_watch(desk_no, user_info, 1);
        end

        if(retcode == 1 and site_no <= 0) then
            retcode = 80;
        end

        if retcode ~= 1 then
            netlib.send(function(buf)
                buf:writeString("RQNI")
                buf:writeByte(retcode)
                buf:writeInt(value)
            end, user_info.ip, user_info.port);
        end
    end
end

function watch_lib.on_recv_request_exit_watch(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;

    --�����˺����ڹ�ս
    if(user_info.desk and watch_lib.can_watch(user_info.desk, 1) == 1) then
        watch_lib.do_user_exit_watch(user_info);
    end
end

function watch_lib.do_user_exit_watch(user_info)
    if(user_info == nil) then
        return
    end

    --TODO �жϸ���λ�ϵ�״̬���Ƿ�ʼ��Ϸ, zysz����ǿ��
    local deskno = user_info.desk
    if(deskno == nil) then
        return
    end

    if(watch_lib.is_playing(user_info) == 1) then
        TraceError("����ڴ��ƣ������뿪��ս"..user_info.userId);
        return;
    end


    watch_lib.del_watch_user(user_info);
    ResetUser(user_info.key, false);
    user_info.desk = nil;

    netlib.send(function(buf)
        buf:writeString("EXWT");
    end, user_info.ip, user_info.port);
    
    eventmgr:dispatchEvent(Event("on_user_exit_watch", {user_info=user_info}));
end

cmdHandler = 
{
    ["REWTEX"] = watch_lib.on_recv_request_watch,
    ["REAUSD"] = watch_lib.on_recv_request_auto_join,
    ["REET"] = watch_lib.on_recv_request_exit_watch,
}

--���ز���Ļص�
for k, v in pairs(cmdHandler) do 
    cmdHandler_addons[k] = v
end

eventmgr:addEventListener("site_event",	watch_lib.on_sitdown)
eventmgr:addEventListener("before_standup_event", watch_lib.on_standup)
eventmgr:addEventListener("on_game_over_event",	watch_lib.on_game_over)


