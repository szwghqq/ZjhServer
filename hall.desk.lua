--[[
��Ϸ������Ϣ��������

]]
hall.desk = {}

hall.desk.isemptysite = function(deskno, siteno)
	local deskSite = desklist[deskno].site[siteno]
    --�Ŷӻ����
    if (deskSite.user == nil) then
        return true
	else
		return false
    end
end

hall.desk.clear_users = function(nDeskNo, nDeskSite)
    --trace(format("deskno:%d, desksite:%d", nDeskNo, nDeskSite))
    ASSERT(nDeskNo ~= nil and nDeskNo > 0 and nDeskSite ~= nil and nDeskSite > 0)
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    --�Ŷӻ����
    if (deskSite.user == nil) then
        return
    end
    if (userlist[deskSite.user] == nil) then
        ASSERT(false, "�û���ϢΪ�գ�����������Ϣ��Ϊ��")
        return
    end

    ASSERT(userlist[deskSite.user].desk ~= nil and
                userlist[deskSite.user].site ~= nil, "���û��Ѿ���������λ������")
    ASSERT(userlist[deskSite.user].desk == nDeskNo
                and userlist[deskSite.user].site == nDeskSite, "���û���¼��������Ϣ��ʵ�ʵ�������Ϣ��ƥ��")
    ASSERT(desklist[nDeskNo].playercount ~= nil and desklist[nDeskNo].playercount > 0)
    if (desklist[nDeskNo].playercount > 0) then
        desklist[nDeskNo].playercount = desklist[nDeskNo].playercount - 1
		usermgr.leave_playing(userlist[deskSite.user])
        trace("�������û���������1nDeskNo:"..nDeskNo.."playcount:"..desklist[nDeskNo].playercount)
        if (gamepkg ~= nil and gamepkg.OnClearUser ~= nil) then
            gamepkg.OnClearUser(nDeskNo, nDeskSite, desklist[nDeskNo].playercount) --�¼�֪ͨ
        end
    else
        --����ʽ��������������֮���������
        desklist[nDeskNo].betgold = 0
        desklist[nDeskNo].usergold = 0
    end
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
    if desklist[nDeskNo].usergold < 0 then
        desklist[nDeskNo].usergold = 0
    end
    if(desklist[nDeskNo].watchingList[deskSite.user]) then
        TraceError("clear_users,�ӹ�ս�б�ɾ��һ�����")
        desklist[nDeskNo].watchingList[deskSite.user] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end
    --TraceError("deskSite.user  "..deskSite.user)
    userlist[deskSite.user].desk = nil
    userlist[deskSite.user].site = nil
    deskSite.user = nil;
    hall.desk.set_site_start(nDeskNo, nDeskSite, startflag.notready)
end

--ǿ�����һ���û�
hall.desk.force_clear_users = function(nDeskNo, nDeskSite)
    if (nDeskNo == nil or nDeskSite == nil) then
        ASSERT(false, "hall.desk.force_clear_users�û���ϢΪ��")
        return
    end
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    if (desklist[nDeskNo].playercount > 0) then
        desklist[nDeskNo].playercount = desklist[nDeskNo].playercount - 1
        desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
        if (userlist[deskSite.user]~= nil) then
			usermgr.leave_playing(userlist[deskSite.user])
        end
        trace("�������û���������1nDeskNo:"..nDeskNo.."playcount:"..desklist[nDeskNo].playercount)
        if (gamepkg ~= nil and gamepkg.OnClearUser ~= nil) then
            gamepkg.OnClearUser(nDeskNo, nDeskSite, desklist[nDeskNo].playercount) --�¼�֪ͨ
        end
    else
        --����ʽ��������������֮���������
        desklist[nDeskNo].betgold = 0
        desklist[nDeskNo].usergold = 0
    end
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
    if desklist[nDeskNo].usergold < 0 then
        desklist[nDeskNo].usergold = 0
    end
    if(desklist[nDeskNo].watchingList[deskSite.user]) then
        TraceError("clear_users,�ӹ�ս�б�ɾ��һ�����")
        desklist[nDeskNo].watchingList[deskSite.user] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end
    if (userlist[deskSite.user] ~= nil) then
        userlist[deskSite.user].desk = nil
        userlist[deskSite.user].site = nil
    end
    deskSite.user = nil
    hall.desk.set_site_start(nDeskNo, nDeskSite, startflag.notready)
end

hall.desk.user_sitdown = function(userKey, nDeskNo, nDeskSite, nStartState, sit_type)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return
    end
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    ASSERT(deskSite.user == nil, "����λ�Ѿ����û��ˣ�û���Ž�ȥ")
    ASSERT(userlist[userKey].site == nil, "���û��Ѿ���������λ������")

    deskSite.user = userKey;
    desklist[nDeskNo].playercount = desklist[nDeskNo].playercount + 1
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold + userlist[userKey].gamescore or 0

    if(desklist[nDeskNo].watchingList[userKey]) then
        TraceError("user_sitdown,�ӹ�ս�б�ɾ��һ�����")
        desklist[nDeskNo].watchingList[userKey] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end

    userlist[userKey].desk = nDeskNo
    userlist[userKey].site = nDeskSite
    deskSite.startstate = nStartState;
end

hall.desk.get_user_count = function(nDeskno)
    if (desklist[nDeskno].playercount == nil) then
        return 0
    else
        return desklist[nDeskno].playercount
    end
end

hall.desk.get_empty_site = function(deskno)
    for i = 1, room.cfg.DeskSiteCount do
        if (desklist[deskno].site[i].user == nil) then
            return i
        end
    end
    return -1
end

hall.desk.get_user = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return nil
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    return desksite.user
end

hall.desk.is_win_site = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return false
    end
    local bWinner = desklist[nDeskNo].site[nDeskSite].IsWinner
    if (bWinner == nil)  then--������
        trace("����û�����ݣ�Ӧ�������")
        return false
    end
    return bWinner
end

hall.desk.set_win_site = function(nDeskNo, nDeskSite, bWinner)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return
    end
    desklist[nDeskNo].site[nDeskSite].IsWinner = bWinner
end

hall.desk.set_user = function(nDeskNo, nDeskSite, userkey)
    if nDeskNo == nil or nDeskSite == nil or nDeskNo <= 0 or nDeskSite <= 0 then
        return nil
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    desksite.user = userkey
    return desksite.user
end

hall.desk.set_site_start = function(nDeskNo, nDeskSite, nStartFlag)
    if nDeskNo == nil or nDeskSite == nil or nDeskNo <= 0 or nDeskSite <= 0 then
        trace('invalid deskno or desksite')
        return
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    desksite.startstate = nStartFlag
end

hall.desk.get_site_start = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return startflag.notready
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    return desksite.startstate
end

--ע��״̬�б���λ
hall.desk.register_site_states = function(states)
	if SITE_STATE == nil then
		SITE_STATE = states
		for k,v in pairs(SITE_STATE) do
			setmetatable(v, {__tostring = function() return "[SITE_STATE." .. k .. "]" end})
		end
	else
		TraceError("�ظ���ʼ��״̬�����ԣ�")
	end
end

--ע��״̬�ı亯��
hall.desk.register_site_state_change = function(callback)
    ASSERT(callback and type(callback) == "function")
    desklist.onstatechange = callback
end

--�������״̬
hall.desk.clear_state_list = function(deskno)
    desklist[deskno].state_list = {}
end

--��¼����״̬
hall.desk.set_state_list = function(deskno, siteno, state)
    if (desklist[deskno].state_list == nil) then
        desklist[deskno].state_list = {}
    end
    local siteinfo = desklist[deskno].site[siteno]
    local str = " timelib.time "..timelib.time.." room.cfg.time "..room.time.."site:" .. siteno .. " " .. tostring(siteinfo.state) .. "->" .. tostring(state)
    table.insert(desklist[deskno].state_list, str)
end

--������λ״̬ (deskno, siteno, state) �����������Ļ�������������������״̬, timeout�ɲ���
hall.desk.set_site_state = function(deskno, siteno, state, timeout)
    local set_site_state = function(deskno, siteno, state)
        local stateinfo = state
        local siteinfo = desklist[deskno].site[siteno]
        ASSERT(siteinfo, "siteno=" .. tostring(siteno))
        --����ϸ�״̬ʱ��timeoutfunc
        if siteinfo.state ~= state then
            if siteinfo.plan and siteinfo.plan.cancel then
                siteinfo.plan.cancel()
                siteinfo.plan = {}
            end
        else
            if (state ~= NULL_STATE and stateinfo[3] ~= 0) then
                TraceError("���ȵ�״̬��ִ������"..tostring(state).."  "..debug.traceback())
            end
            return
        end
        xpcall(function() hall.desk.set_state_list(deskno, siteno, state) end, throw)

		--TraceError("    site:" .. siteno .. " " .. tostring(siteinfo.state) .. "->" .. tostring(state))
        local oldstate = siteinfo.state
        siteinfo.state = state
        local timeoutfunc = stateinfo[2]
        local delay = timeout or stateinfo[3] or 0
        local userinfo = userlist[hall.desk.get_user(deskno, siteno) or ""]
        if timeoutfunc and userinfo then
            if delay > 0 then
                siteinfo.plan = timelib.createplan(function() timeoutfunc(userinfo) end, delay)
            end
		end
        if oldstate ~= state and desklist.onstatechange then
            xpcall(function() desklist.onstatechange(deskno, siteno, oldstate, state) end, throw)
        end
    end

    ASSERT(deskno and deskno > 0 and deskno <= #desklist, "deskno=" .. tostring(deskno))
    if type(siteno) == "table" then
        for i = 1, room.cfg.DeskSiteCount do
            set_site_state(deskno, i, siteno)
        end
    else
        ASSERT(state, "���״̬�Ļ���NULL_STATE,��Ҫ��nil")
        ASSERT(siteno and siteno > 0 and siteno <= room.cfg.DeskSiteCount)
        set_site_state(deskno, siteno, state)
    end
end

--��ȡ��λ״̬
hall.desk.get_site_state = function(deskno, siteno)
    ASSERT(deskno and siteno and deskno > 0 and deskno <= #desklist and siteno > 0, "������λ��������")
    local siteinfo = desklist[deskno].site[siteno]
    ASSERT(siteinfo)
    return siteinfo.state or NULL_STATE
end

--��ȡ��λ���볬ʱ��ʱ��(-1��ʾ������ʱ)
hall.desk.get_site_timeout = function(deskno, siteno)
    ASSERT(deskno and siteno and deskno > 0 and deskno <= #desklist and siteno > 0, "������λ��������")
    local siteinfo = desklist[deskno].site[siteno]
    ASSERT(siteinfo)
    if siteinfo.plan and siteinfo.plan.getlefttime then
        return siteinfo.plan.getlefttime(), siteinfo.plan.getdelaytime()
    else
        return -1
    end
end

--�����������Ѿ���ʼ�˼���
hall.desk.inc_round_num = function(nDeskNo)
    if nDeskNo <= 0 then
        return
    end
    desklist[nDeskNo].js = (desklist[nDeskNo].js or 0) + 1
end

hall.desk.get_round_num = function(nDeskNo)
    if nDeskNo <= 0 then
        return -1
    end
    if (desklist[nDeskNo].js == nil) then
        desklist[nDeskNo].js = 0
    end
    return desklist[nDeskNo].js
end

hall.desk.get_site_data = function(deskno, siteno)
	return desklist[deskno].site[siteno].gamedata
end

hall.desk.get_desk_data = function(deskno)
	return desklist[deskno].gamedata
end

--������Ƽ�һ�����Ӻ���λ
--�Ƽ�������
--��ұ���������
--������������ӽ���������
--Ȼ���ٿ����ӣ����������Ӳ�����
hall.desk.give_user_deskno = function(userinfo)
    if not userinfo then return end
    --��ѡ���Ӻ�,���գ���1����2����3...���ɸ�ѡһ��
    local tmpdesklist = {}
    local tmp_null_desk_list = {} --�շ���
    local nulldesks = {}  --��֤ÿ�����ʵĿշ���ֻ��һ��(���Ч��)
    local find_desk_no = -1
    local channel_id=userinfo.channel_id
    
    --���ǲ��Ǳ��ߵ��û�
    local is_kickeduser=function(kick_deskinfo,userinfo)
    	--�����Ƿ�����Ҫ���ߵ���
	    for i, player in pairs(kick_deskinfo.gamedata.kickedlist) do
	        if(player.userinfo.userId==userinfo.userId)then
	        	return 1
	        end
	    end
	    return 0
    end

    for i = 1, #desklist do
        --ֻ���Զ�������ͨ��Ϸ��,���ˣ�����û��
        local playercount = desklist[i].playercount
        local maxplayercount = desklist[i].max_playercount
        local smallbet = desklist[i].smallbet
        local nullkey = format("%d_%d", smallbet, maxplayercount) --ÿ�����ʣ��������޵Ŀ����Ӽ�һ������


        --��������Ƶ����������Ƶ������
        if((groupinfo.groupid == "18002" and desklist[i].desktype==g_DeskType.channel and desklist[i].channel_id==channel_id) or
           (desklist[i].desktype == g_DeskType.normal)) then  --���˲���û��������
            if(playercount > 0 and playercount < maxplayercount)then
            	--�����˲���û���������ӣ��������ڱ����б��У�������
            	if(desklist[i].gamedata.kickedlist~=nil)then
            		if(is_kickeduser(desklist[i],userinfo)~=1)then
            			table.insert(tmpdesklist, {deskno = i, deskinfo = desklist[i]})
            		end            	
            	else            	
               		table.insert(tmpdesklist, {deskno = i, deskinfo = desklist[i]})
                end
            elseif(playercount == 0 and nulldesks[nullkey] == nil)then  --û�˵�����ֻҪһ��
                nulldesks[nullkey] = 1
                table.insert(tmp_null_desk_list, {deskno = i, deskinfo = desklist[i]})
            end
        end
        
    end

    --�ѿշ�����ں���
    for i=1,#tmp_null_desk_list do
        table.insert(tmpdesklist,tmp_null_desk_list[i])
    end

    --����Ƿ������´�����
    local isCanSitdown = function(userinfo, deskinfo)

        local needlevel = deskinfo["deskinfo"].needlevel
        local needgold = deskinfo["deskinfo"].at_least_gold
        local smallbet=deskinfo["deskinfo"].smallbet
        local deskno=deskinfo.deskno or "-1"
	
	if(userinfo==nil or userinfo.gamescore == nil or userinfo.bankruptcy_give_count==nil)then
	    return false
	end

        if(usermgr.getlevel(userinfo) < needlevel) then
            return false
        end

        if(userinfo.gamescore < needgold and userinfo.bankruptcy_give_count>3) then
            return false
        end

        --���ֳ����ƣ��������1500���������ֳ�
        if(smallbet == 1 and userinfo.gamescore > room.cfg.freshman_limit) then
            return false
        end
        --�����û����ϵ�Ǯ���䷿��
        --2000001���ϣ����䵽10K/20K�����Ϸ��䡣������ø��ˣ�ֱ�ӾͿ����ŵ�
        --800001-200W�����䵽5K/10K�ķ���
        if(userinfo.gamescore >= 800001 and userinfo.gamescore<=2000000 and smallbet>=10000) then
            return false
        end
        --400001-80W�����䵽2K/4K�ķ��䣬smallbet>=5000������Ϊ�������Զ����ķ���
        if(userinfo.gamescore >= 400001 and userinfo.gamescore<=800000 and smallbet>=5000) then
            return false
        end

        --200001-40W�����䵽1K/2K�ķ���
        if(userinfo.gamescore >= 200001 and userinfo.gamescore<=400000 and smallbet>=2000) then
            return false
        end

        --80001-20W �����䵽500/1K�ķ���
        if(userinfo.gamescore >= 80001 and userinfo.gamescore<=200000 and smallbet>=1000) then
            return false
        end

         --40001-80000�����䵽200/400����
        if(userinfo.gamescore >= 40001 and userinfo.gamescore<=80000 and smallbet>=500) then
            return false
        end
    

         --20001-40000�����䵽100/200����
        if(userinfo.gamescore >= 20001 and userinfo.gamescore<=40000 and smallbet>=200) then
            return false
        end

        --10001-20000�����䵽50/100����
        if(userinfo.gamescore >= 10001 and userinfo.gamescore<=20000 and smallbet>=100) then
            return false
        end

        --4001-10000�����䵽25/50����
        if(userinfo.gamescore >= 4001 and userinfo.gamescore<=10000 and smallbet>=50) then
            return false
        end

        --1500-4000�����䵽10/20����
        if(userinfo.gamescore >= 1501 and userinfo.gamescore<=4000 and smallbet>=25) then
            return false
        end

        --200-1500����Ӧ�ȼ�����3�����������֣����䵽�ܽ�����������ҵ�ೡ
        if(userinfo.gamescore >=200  and userinfo.gamescore<=room.cfg.freshman_limit and smallbet>=10) then
            return false
        end

        --0-200�����䵽���ֳ�
        if(userinfo.gamescore >=0  and userinfo.gamescore<=200 and smallbet>=2) then
            return false
        end

        return true
    end

    local hasSameIP = function(userinfo, players)
        for i = 1, #players do
            local ip = players[i].userinfo.ip;
            if(userinfo.ip == ip) then
                return true
            end
        end
        return false
    end

    --��������ѡ�����ӹ���
    local success, templist = xpcall (function() 
        return hall.desk.xinshou_desklist_handle(userinfo, tmpdesklist) end, throw)

    if (success == true and templist ~= nil) then
        tmpdesklist = templist
        -- else
        --��������˳���ٱ���
        --table.disarrange(tmpdesklist)
    end

    --���������ʺ����������ӣ�ע�⣺�ȼ�����3���ҳ�������1500������ȥ���ַ�
    for i = 1, #tmpdesklist do
        local deskinfo = tmpdesklist[i]
        local deskno = tmpdesklist[i].deskno
        
        local players = deskmgr.getplayers(deskno)
            --�ж��ܷ�����
            local allow_sit = false
            if(room.cfg.allow_samedesk == 1) then
                allow_sit = true
            else
                allow_sit = (hasSameIP(userinfo, players) == false)
            end

            if(isCanSitdown(userinfo, deskinfo) == true and allow_sit) then
                find_desk_no = deskno 
		break
	    end

    end
	return find_desk_no
end

--��������ѡ�����ӹ���
--[[
    �ȼ�����3���ҳ�������1500�����ȷ��䵽���ֳ�
--]]
hall.desk.xinshou_desklist_handle = function(userinfo, desklist)
    local temp_desklist = {}
    local xinshou_desklist = {}  --���ֳ�����
    local other_desklist = {}    --�������ֳ����������
    if(usermgr.getlevel(userinfo) < 3 and userinfo.gamescore <= room.cfg.freshman_limit) then
        --TraceError("�ȼ�����3���ҳ�������1500")
        for i = 1, #desklist do
            --���ֳ�����û���������������ֳ�
            if(desklist[i].deskinfo.smallbet == 1 and   --���ֳ�
               desklist[i].deskinfo.playercount ~= desklist[i].deskinfo.max_playercount) then --��û����Ա�ķ���
                table.insert(xinshou_desklist, desklist[i])   --���ֳ�
            elseif (desklist[i].deskinfo.at_least_gold <= userinfo.gamescore and --����Ǯ������СЯ���ķ��� 
                    desklist[i].playercount ~= desklist[i].max_playercount) then --��û�����ķ���
                table.insert(other_desklist, desklist[i])     --������ͨ��
            end
        end
        --��������˳��
        --table.disarrange(xinshou_desklist)
        --table.disarrange(other_desklist)

        for j = 1, #xinshou_desklist do
            table.insert(temp_desklist, xinshou_desklist[j])
        end
        for k = 1, #other_desklist do
            table.insert(temp_desklist, other_desklist[k])
        end
    else
        return nil
    end

    return temp_desklist
end

hall.desk.init_desk_info = function(index, deskcfg)
	local deskinfo = {}
	
	--�Ŷ����
	deskinfo.playercount = 0 --�����Ѿ����µ��������
    deskinfo.watchercount = 0 --��ս���������
	deskinfo.gamepeilv = groupinfo and groupinfo.gamepeilv or 0

    deskinfo.name = ""
    deskinfo.description = ""
    deskinfo.needlevel = 0
    deskinfo.fast = 0
    deskinfo.desktype = 1  --��������(1��ͨ��2������3VIPר��)
    deskinfo.smallbet = groupinfo and groupinfo.gamepeilv or 0
    deskinfo.largebet = deskinfo.smallbet * 2
    deskinfo.at_most_gold = 200000000
    deskinfo.specal_choushui = 0
    deskinfo.min_playercount = 2
    deskinfo.max_playercount = room.cfg.DeskSiteCount
    deskinfo.desk_settings = ""
    deskinfo.at_least_gold = deskinfo.largebet + deskinfo.specal_choushui

	deskinfo.site = {}
	for j = 1, room.cfg.DeskSiteCount do
	    deskinfo.site[j] = {}
	    deskinfo.site[j].gamedata = gamepkg.init_site_info()
	    deskinfo.site[j].state = NULL_STATE
	    deskinfo.site[j].pokes = {}
	    deskinfo.site[j].response = false  --�û���������δʹ��
    end

    --��ս����б� lch
    deskinfo.watchingList = {}

    --�����ݿ��������Ӳ��� lch
    if(deskcfg ~= nil) then
        deskinfo.desk_settings = deskcfg["desk_settings"] or ""
        --���ӵĸ�������(ע��˴�������ֶ�����ͻ�ˣ���ᱻ����)
        local desksetting = split(deskinfo.desk_settings, "|")
        for i = 1, #desksetting do
            local item = split(desksetting[i], ":")
            if(#item == 2) then
                deskinfo[item[1]] = tonumber(item[2]) or item[2]
            end
        end
	    deskinfo.db_desk_id = deskcfg["id"] or -1 
        deskinfo.name = deskcfg["name"] or ""
        deskinfo.description = deskcfg["description"] or ""
        deskinfo.desktype = deskcfg["desktype"] or 1
        deskinfo.needlevel = deskcfg["needlevel"] or 0
        deskinfo.smallbet = deskcfg["smallbet"] or 1
        deskinfo.largebet = deskcfg["largebet"] or 2
        deskinfo.at_most_gold = deskcfg["at_most_gold"] or 2100000000
        deskinfo.specal_choushui = deskcfg["specal_choushui"] or 0
        deskinfo.min_playercount = deskcfg["min_playercount"] or room.cfg.DeskSiteCount
        deskinfo.max_playercount = deskcfg["max_playercount"] or room.cfg.DeskSiteCount
        deskinfo.at_least_gold = deskcfg["at_least_gold"] or (deskinfo.largebet + deskinfo.specal_choushui)
        deskinfo.channel_id = deskcfg["channel_id"] or -1

        if((deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) and deskinfo.at_least_gold < (deskinfo.largebet + deskinfo.specal_choushui)) then
            TraceError(deskinfo)
            TraceError(format("����[%d]��������, ��С���[%d]����С�ڴ�ä�ӳ�ˮ���ܶ�", index, deskinfo.at_least_gold))
            deskinfo.at_least_gold = (deskinfo.largebet + deskinfo.specal_choushui)
        end
        
		TraceError("fffffffffffffffffffffffffffffffffffffsssssssssssssssssssssssssssssssss")
        eventmgr:dispatchEvent(Event("on_desk_init", null));
       
    end

    --����һ����̬��Сäʵ�ֶ�̬��Сä����
    deskinfo.staticsmallbet = deskinfo.smallbet
    deskinfo.staticlargebet = deskinfo.largebet
    deskinfo.betgold = 0
    deskinfo.usergold = 0

	deskinfo.gamedata = gamepkg.init_desk_info()
	deskqueue[index] = index            --ʣ���λ������˳��
	return deskinfo
end

hall.desk.init_all = function()
    --��ע���������ڲ��Һ��ʵķ��䣬��Ҫ����޸�������򣬷��������λ���ܻ�������
    --desktype!=3����ȥ��VIP��
    --�������Ƶ�������ͳ�ʼ������
    if(groupinfo.groupid ~= "18002")then
	    local szsql = "select * from configure_deskinfo where room_id = %d and desktype!=3  ORDER BY smallbet desc,id asc"
	    local ongetdeskcfg = function(dt)
	        if(dt and #dt > 0) then
	            for i = 1, #dt do
	        		desklist[i] = hall.desk.init_desk_info(i, dt[i])
	        	end
	        else
	            for i = 1, room.cfg.deskcount do
	        		desklist[i] = hall.desk.init_desk_info(i, nil)
	        	end
	        end
	    end
	    dblib.execute(format(szsql, groupinfo.groupid), ongetdeskcfg);
    end
end

--TraceError("����hall.desk.lua���!");


--[[��Ϸ������ʾ������Ϣ������]]
if not hall.displaycfg then
    TraceError("��ʼ��hall.displaycfg!");
    hall.displaycfg = {cfgdata = {},}
end
--��ȡĳ��������ʾ����
hall.displaycfg.getdisplaycfg = function(desktype, tabindex)
    if hall.displaycfg.cfgdata[desktype] == nil then
        hall.displaycfg.cfgdata[desktype] = {}
    end
	return hall.displaycfg.cfgdata[desktype][tabindex] or {}
end

hall.displaycfg.init = function()
    local szsql = "select * from configure_displaydesk order by desktype asc, tabindex asc, isfast asc, peilv1 asc "
    local displaycfg = function(dt)
        if(dt and #dt > 0) then
            for i = 1, #dt do
        		local desktype = dt[i]["desktype"]
                local tabindex = dt[i]["tabindex"]
                local isfast = dt[i]["isfast"]
                local peilv1 = dt[i]["peilv1"]
                local peilv2 = dt[i]["peilv2"]  --��ʱ����
                local displaycount = dt[i]["displaycount"]
                if hall.displaycfg.cfgdata[desktype] == nil then
                    hall.displaycfg.cfgdata[desktype] = {}
                end
                if hall.displaycfg.cfgdata[desktype][tabindex] == nil then
                    hall.displaycfg.cfgdata[desktype][tabindex] = {}
                end
                if hall.displaycfg.cfgdata[desktype][tabindex][isfast] == nil then
                    hall.displaycfg.cfgdata[desktype][tabindex][isfast] = {}
                end
                hall.displaycfg.cfgdata[desktype][tabindex][isfast][peilv1] = displaycount
        	end
        else
            TraceError("�����ݿ��ȡ��ʾ�����б�����ʧ��")
        end
        --TraceError(hall.displaycfg.cfgdata)
    end
    dblib.execute(szsql, displaycfg);
end

--�ı����ӵ�״��
function hall.desk.add_channel_desk(userinfo)
    --todo:����Ƶ������֮�󣬰����д�ɴӳ�����ȡ
    local channel_id=userinfo.channel_id--��д��һ��Ƶ�����������userinfo.channel_id

    --�����õĴ��룬���ߺ�Ҫ�õ�
    if(userinfo.userId<=105) then 
        channel_id=888
        userinfo.channel_id=888
    end

    if(userinfo.userId>105 and userinfo.userId<200) then 
        channel_id=7612793
        userinfo.channel_id=7612793
    end

    --1.�������û���channel_idΪ�գ��Ͳ���ʲô����
    if(channel_id==nil)then
        return
    end

    --2.�������û���channel_id���Ϳ�һ�¶�Ӧ��channel_id�������ǲ��Ǵ��ڣ���������ڣ��ʹ���33��Ƶ�����ӣ�����Ͳ���ʲô����
    if(hall.desk.is_exist_channel_desk(channel_id)~=1)then--���������Ƶ�����ӣ��ʹ���33��
        create_channel_desklist(channel_id)
    end
end

--����ָ��channel_id��Ƶ����
function create_channel_desklist(channel_id)
	
    if(channel_desklist==nil or #channel_desklist==0)then
          --ȡ��Ƶ����������channel_desklist��
        local szsql = "select * from configure_deskinfo where desktype=4  ORDER BY smallbet desc,id asc"
        local ongetdeskcfg = function(dt)
            if(dt and #dt > 0) then
                channel_desklist = table.clone(dt)
                for i = 1, #dt do
               		local need_show = 1
		        	--761279328205������ӣ�ֻ��333Ƶ����Ƶ�����ǣ�7612793���ܿ����Ŷ�
		        	if dt[i].id == 28205 and channel_id ~= 7612793 then
		        		need_show = 0
		        	end
			        if need_show == 1 then
	                    dt[i].id=channel_id..dt[i].id   --�趨����ΪƵ��������
	                    dt[i].channel_id=channel_id
	                    table.insert(desklist,hall.desk.init_desk_info(i, dt[i]))
                    end
            	end
            end
        end
        dblib.execute(szsql, ongetdeskcfg);
    else
        --�ҵ�һ�ѿ����ӣ����ڴ���Ƶ������
        local desk_pos = 0
        for i=1,#desklist do
            if (desklist[i].channel_id == -2) then
                desk_pos = i
                break
            end
        end
        if (desk_pos == 0) then
            desk_pos = #desklist + 1
        end

        local tmp_channel_desklist = table.clone(channel_desklist)
        for i=1, #tmp_channel_desklist do
        	local need_show = 1
        	--761279328205������ӣ�ֻ��333Ƶ����Ƶ�����ǣ�7612793���ܿ����Ŷ�
        	if tmp_channel_desklist[i].id == 28205 and channel_id ~= 7612793 then
        		need_show = 0
        	end
        	
	        if need_show == 1 then
	            tmp_channel_desklist[i].id = channel_id..tmp_channel_desklist[i].id   --�趨����ΪƵ��������
	            tmp_channel_desklist[i].channel_id = channel_id                
	            desklist[desk_pos] = hall.desk.init_desk_info(i, tmp_channel_desklist[i])
	            desk_pos = desk_pos + 1
            end
        end
    end
    
end

--ɾ�����õ�����
function hall.desk.remove_channel_desk(channel_id)
    --�û����ӱ����������ģ���Ϊ�ܶ�ط�����#desklist������ֻ�ܰ�����Ƶ�����ó�-2
    for i = #desklist, 1, -1 do
        if(channel_id~=nil and desklist[i].channel_id==channel_id and channel_id~=-1)then
            desklist[i].channel_id = -2
        end
    end    
    for i = #desklist, 1, -1 do
        if(desklist[i].channel_id ~= -2)then
            break
        end
        table.remove(desklist,i)
    end
end

--�ж��ǲ������Ƶ��û������,��������˾ͷ���1������ͷ���0
function hall.desk.is_not_exist_channel(user_id,channel_id)
   for k,v in pairs(userlist) do
        if (v.channel_id==channel_id and v.userId~=user_id) then
             return 1
        end
    end
    return 0
end


--���ǲ����Ѿ��ж�ӦƵ����������
function hall.desk.is_exist_channel_desk(channel_id)
    for i = 1, #desklist do
        if(desklist[i].channel_id==channel_id)then
            return 1
        end
    end
    return 0
end
--TraceError("��ʼ��hall.displaycfg.lua���!");


