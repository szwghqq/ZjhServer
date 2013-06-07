dofile("common/common.lua")

--�������дӶ���->�߼����� �Լ� �߼�����->���� ��ĳ���

--zysz.pokechar Ӧ���� preinit ��

zysz.name = "zysz"
zysz.table = "user_zysz_info"
gamepkg = zysz

trace("ִ���������")
math.randomseed(os.time())

gamecfg = {
    maxbeishu = 19,    -- ��ע�����
    dizhuxishu = 0.01, -- ��СЯ����1%
    myselfbili = 0.5,  -- ������ע�ⶥ����
    addzhutype = {1,2,3}, --��Ҽ�ע����
    jiangchichoushui = 0.2,--�ʳؽ����ˮ
}
deskmgr = {
    --��ȡ�������
    getuserdata = function(userinfo)
	    return userinfo.gameInfo
    end,
    --��ȡ��λuserinfo
    getsiteuser = function(deskno, siteno)
	    return userlist[hall.desk.get_user(deskno,siteno) or ""]
    end,

	--��ȡ��λ����
	getsitedata = function(deskno, siteno)
		return desklist[deskno].site[siteno]
	end,

    get_game_state = function(adeskno)
        if adeskno <= 0 then
                return gameflag.notstart
        end
        return desklist[adeskno].gamestate
    end,

    set_game_state = function(adeskno, gamestate)
		if adeskno <= 0 then
			return
		end
        desklist[adeskno].gamestate = gamestate
    end,

    --��ȡ������λ���б�, ����valueΪ{siteno, userinfo}��table, ˳����λ��, [*����*]�������û�
	getplayers = function(deskno)
		local ret = {}
		for i = 1, room.cfg.DeskSiteCount do
			local userinfo = userlist[hall.desk.get_user(deskno, i)]
			if userinfo then
				table.insert(ret, newStrongTable({ siteno=i, userinfo=userinfo }))
			end
		end
		return ret
	end,

	--��ȡ������λ���б�, ����valueΪ{siteno, userinfo}��table, ˳����λ��, [*������*]�������û�
	getplayingplayers = function(deskno)
		local ret = {}
		local players = deskmgr.getplayers(deskno)
		for i = 1, #players do
			if deskmgr.getsitedata(deskno, players[i].siteno).islose == 0 then
				table.insert(ret, players[i])
			end
		end
		return ret
	end,

    --��ȡ��һ���������λ��(���������򷵻ؿ�), �������������û�
	getnextsite = function(deskno, siteno)
		local currsite = siteno
		local userinfo
		repeat
			if currsite == 1 then 
				currsite = room.cfg.DeskSiteCount 
			else
				currsite = currsite - 1
			end
			if currsite == siteno then
				return nil
			end
			userinfo = userlist[hall.desk.get_user(deskno, currsite)]
		until userinfo and deskmgr.getsitedata(deskno, currsite).islose == 0 and
            hall.desk.get_site_state(deskno, currsite) ~= SITE_STATE.WATCH

		return currsite
	end,
}

zysz.TransSiteStateValue = function(state)
    local state_value
    if state == NULL_STATE then
		state_value = SITE_UI_VALUE.NULL
    elseif state == SITE_STATE.NOTREADY then
		state_value = SITE_UI_VALUE.NOTREADY
    elseif state == SITE_STATE.READYWAIT or state == SITE_STATE.WATCH then
		state_value = SITE_UI_VALUE.READY
    elseif state == SITE_STATE.KANPAI or state == SITE_STATE.PANEL then
		state_value = SITE_UI_VALUE.PLAYING
    else
		state_value = SITE_UI_VALUE.NULL
    end

    return state_value
end

tZyszSqlTemplete =
{
    --���½�����Ϣ
    updateJiesuan = "call sp_zysz_jiesuan(%s)",
    --���������־
    insertLogRound = "call sp_zysz_insert_log_round(%s)",
    --�޸��û����
    updateUserGold = "call sp_update_user_gold(%s)",
    --�õ��ʳ���Ϣ
    getZyszCaichiInfo = "select sumgold,last_win_user,last_win_time,last_win_gold from zysz_caichi_info where room_id = %d",
    --����ʳ���Ϣ
    insertZyszCaichiInfo = "insert into zysz_caichi_info (room_id,sumgold,last_win_user,last_win_time,last_win_gold) values (%d, 0, '', %d, 0)",
    --���²ʳػ���Ϣ[���»���]
    updateCaichiInfo = "update zysz_caichi_info set sumgold = %d,last_win_user = %s, last_win_time = %d, last_win_gold = %d where room_id = %d",
    --���²ʳػ���Ϣ[�����»���]
    updateCaichiInfo_goldonly = "update zysz_caichi_info set sumgold = %d where room_id = %d",
    --���²ʳؽ����
    updateCaichiGold = "update zysz_caichi_info set sumgold = %d where room_id = %d",
}

---------------------------------------------------------------------------
--δ׼��-��ʱ
function ss_notready_timeout(userinfo)
    hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
	--����
	doUserStandup(userinfo.key, false)
	net_Send_KickUser(userinfo)
end

--δ׼��-����
function ss_notready_offline(userinfo)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
end

--׼����ʼǰ-����
function ss_readywait_offline(userinfo)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
end

--��������
function ss_fapai_offline(userinfo)
	desklist[userinfo.desk].site[userinfo.site].isfapaiover = 1
	do_fapai_over_check(userinfo.desk)
	do_user_state_change(userinfo,1)
end

--���Ƴ�ʱ
function ss_fapai_timeout(userinfo)
	desklist[userinfo.desk].site[userinfo.site].isfapaiover = 1
	do_fapai_over_check(userinfo.desk)
	do_user_state_change(userinfo,0)
end

--���״̬����
function ss_panel_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--���״̬��ʱ
function ss_panel_timeout(userinfo)
	do_user_state_change(userinfo,0)
end

--����״̬����
function ss_kanpai_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--����״̬��ʱ
function ss_kanpai_timeout(userinfo)
	do_user_state_change(userinfo,0)
end

--�ȴ�״̬����
function ss_wait_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--��ս����״̬
function ss_watch_offline(userinfo)
	do_user_state_change(userinfo,1)
end

--���û���ʱ������ʱ������
function do_user_state_change(userinfo,isleave)
	hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
    doUserGiveUp(userinfo)
	if isleave == 1 then
		if (userinfo.desk ~= nil) then
			doUserStandup(userinfo.key, false)
			doDelUser(userinfo.key)
		end
	end
end

--��λ״̬�ı�
function ss_onstatechange(deskno, siteno, oldstate, newstate)
    trace("ss_statechanged()")
	local userinfo = deskmgr.getsiteuser(deskno, siteno)
	if userinfo ~= nil then
		if userinfo.desk and newstate ~= SITE_STATE.NOTREADY then
			net_broadcastdesk_playerinfo(userinfo.desk)
		end
	end
end

--ǿ�ƽ�����Ϸ
function forceGameOver(deskno)
	deskmgr.set_game_state(deskno, gameflag.notstart)  --ֱ��תΪδ��ʼ״̬
	for i = 1, room.cfg.DeskSiteCount do
		hall.desk.set_site_state(deskno, i, NULL_STATE)
        local userinfo = deskmgr.getsiteuser(deskno,i)
		if userinfo then
			net_Send_KickUser(userinfo)
		end
    end

	initGameData(deskno);
	
	OnGameOver(deskno,true)
end

--������һ���Ķ����˺���ض���
function setNextAction(deskno)
    local nextpeople = desklist[deskno].nextpeople        

    --�ܷ��ƣ����Ƿ��Ѿ������ƣ�
    if desklist[deskno].site[nextpeople].islook ==  0 then
        desklist[deskno].site[nextpeople].action_look = 1
    else
        desklist[deskno].site[nextpeople].action_look = 0
    end
    
    --�ܷ���
    --ʣ�������˵�ʱ����ܿ��Ʋ��Ҳ��ǵ�һ��                                              
    if desklist[deskno].peopleplaygame <= 2 and desklist[deskno].site[nextpeople].betmoney ~= desklist[deskno].dizhu 
        and desklist[deskno].isfengding == 0 then
        desklist[deskno].site[nextpeople].action_vs = 1
    else
        desklist[deskno].site[nextpeople].action_vs = 0
    end
    
    --��ǰ�����Ѿ����˶���ע
    local curjiazhunum = math.floor(desklist[deskno].curdeskzhu / desklist[deskno].dizhu)
    --�ܷ��ע
    if curjiazhunum < gamecfg.maxbeishu and desklist[deskno].isfengding == 0 then
        local leftzhu = gamecfg.maxbeishu - curjiazhunum
        desklist[deskno].site[nextpeople].action_add =  leftzhu >= 3 and 3 or leftzhu
    else
        desklist[deskno].site[nextpeople].action_add = 0
    end
    
    --�ܷ��ע
    if desklist[deskno].isfengding == 0 then--�ⶥû�п���
        desklist[deskno].site[nextpeople].action_follow = 1--����
        desklist[deskno].site[nextpeople].followgold = setbetmoney(deskno,nextpeople,desklist[deskno].curdeskzhu)
    else--�ⶥ����
        if nextpeople ~= desklist[deskno].kaifengsiteno then
            desklist[deskno].site[nextpeople].action_follow = 1
            desklist[deskno].site[nextpeople].followgold = setbetmoney(deskno,nextpeople,desklist[deskno].curdeskzhu)
        else
            desklist[deskno].site[nextpeople].action_follow = 0
            desklist[deskno].site[nextpeople].followgold = 0
        end
    end

    --����
    desklist[deskno].site[nextpeople].action_giveup = 1
    
	--���ó�Ϊ���״̬
	hall.desk.set_site_state(deskno,nextpeople,SITE_STATE.PANEL)
    --���������Ϣ
    net_send_show_action_list(deskmgr.getsiteuser(deskno,nextpeople))
end

----------------------------------------------------------------------
--����������У���������������ȡ��������Э�����������
function gameonrecv(cmd, recvbuf)
	--cmd = netbuf.readString(inbuf)
	trace("game onrecv "..cmd)
	gamedispatch(cmd, recvbuf)
end

--������������ݣ�������뵽�������
function gameonsend(sCommand, sendbuf)
	trace("game onsend ".. sCommand)
	gamedispatch(sCommand, sendbuf)
end

g_errmsgprefix = ""
function throw(msg)
    TraceError('--------------------------')
    TraceError("#### call command faild ".. g_errmsgprefix.." with err: "..msg) --error(msg)
    local serr = debugpkg.traceback()
    TraceError(serr)
    TraceError('--------------------------')
end

function gamedispatch(sCommand, buf)
	local f = cmdGameHandler[sCommand]
	if f ~= nil then        
        local ret, errmsg = xpcall(function() return f(buf) end, throw)
		if (ret) then
			trace("**"..sCommand.. " call command ok ")
		else
			trace("** call ��Ϸ command faild ".. sCommand)
		end
	else
		trace("** not found ��Ϸ command ->".. sCommand)
	end
end
--------------------------------------------------------------------------------
--һ�ֽ��������¿�ʼһ��
function restartthegame(deskno)
    --����ʳصĽ��
    calCaichiMoney(deskno)

    deskmgr.set_game_state(deskno, gameflag.notstart)  --ֱ��תΪδ��ʼ״̬

    initGameData(deskno)

    OnGameOver(deskno,true)
end

function sortpokerlist(pokes)
	table.sort(pokes, function (a,b)
	    return (zysz.pokenum[a] < zysz.pokenum[b])
	end)

	return pokes	
end

--������Ϸ
function continuegame(deskno,doType)--doType--1Ϊ��ע�����Զ����ƣ�2Ϊ���������Զ�����
	if desklist[deskno].peopleplaygame <= 1 then
        if desklist[deskno].winner == 0 then
            desklist[deskno].winner = deskmgr.getnextsite(deskno,desklist[deskno].nextpeople)
		end

		desklist[deskno].winpeoplenum = 1 --1����Ӯ��
		--��������浽���ݿ�
		calMoney(deskno,desklist[deskno].winner,1)
		restartthegame(deskno)
		--���ڻ����ͳ��
		--if springboxlib then
		--	xpcall(function() springboxlib.count_huodong_panshu() end,throw)
		--end
    else--����Ƿ�Ҫ�Զ�����--�¸����ֵ����������
        --�ҵ��¸���
        desklist[deskno].nextpeople = deskmgr.getnextsite(deskno,desklist[deskno].nextpeople)   
        
        --�ⶥ���ؿ���
        if doType and desklist[deskno].isfengding == 1 then
            if setbetmoney(deskno,desklist[deskno].nextpeople,0) == 0 or desklist[deskno].nextpeople == desklist[deskno].kaifengsiteno then
                doAutoKaiPai(deskno,doType)
				--if springboxlib then
				--	xpcall(function() springboxlib.count_huodong_panshu() end,throw)
				--end
                return
            end
        end

        --�����¸��Ķ���
        setNextAction(deskno)
	end
end

--�Զ�����
function doAutoKaiPai(deskno,doType)
	local deskdata = desklist[deskno]

    --���ұ���
	local hasbaozi = false
    --�����Զ����Ʊ�ʶ
    for _,player in pairs(deskmgr.getplayingplayers(deskno)) do
        desklist[deskno].site[player.siteno].isautokaipai = 1
        if desklist[deskno].site[player.siteno].paixing == 5 then
			hasbaozi = true			
		end
    end

	--�����������͵ȼ�
	for _,player in pairs(deskmgr.getplayingplayers(deskno)) do
		if desklist[deskno].site[player.siteno].paixing == 6 then--����͵��
			if hasbaozi == false then--û�б���
				desklist[deskno].site[player.siteno].paixing = 0--���ó�ɢ��
			end
		end		 
	end

    --�ҳ���Ӯ��
	local winsitelist = {}
	local lostsitelist = {}
	for _,player in pairs(deskmgr.getplayingplayers(deskno)) do	
        if (hall.desk.get_site_state(deskno, player.siteno) ~= SITE_STATE.WATCH) then
    		if #winsitelist == 0 then
    			table.insert(winsitelist,player.siteno)
    		else
    			local result = validPoker(deskno,winsitelist[1],player.siteno)
    			if result == 1 then
    				table.insert(lostsitelist,player.siteno)
    			elseif result == 2 then
    				for k,v in pairs(winsitelist) do
    					table.insert(lostsitelist,v)
    				end
    				winsitelist = {}
    				table.insert(winsitelist,player.siteno)
    			else
    				table.insert(winsitelist,player.siteno)
    			end
            end
        end
    end

    --��¼�ɼ�������Ϣ
    if #lostsitelist > 0 then
        local loseminsite = lostsitelist[1]
        for k,v in pairs(lostsitelist) do
            if desklist[deskno].site[loseminsite].paixing > desklist[deskno].site[v].paixing then
                loseminsite = v
            end
        end
        
        record_paixin_msg(deskno, winsitelist[1], loseminsite)
		clone_winlist_data(deskno,winsitelist)--����
    end

	local winnum = #winsitelist
	if winnum == 0 then
		TraceError("û�������????BUG�� " .. deskno)
		forceGameOver(deskno)
		return
    end

    --֪ͨ�Զ�������Ϸ������
	net_broadcast_game_over(deskno,doType,winsitelist,lostsitelist)

	--������ȿ�Ǯ
	for k,v in pairs(lostsitelist) do
		--Ͷ����״̬��Ϊ����
		desklist[deskno].site[v].islose = 1
		--�û�����޸�д�����ݿ�
		writelosergoldtodb(deskno,v)
	end

	--��¼ϵͳ�Զ�����ʱ�ж���������
	deskdata.lostpeoplenum = #lostsitelist
	
	if winnum > 0 then
		deskdata.winpeoplenum = winnum 

		for k,v in pairs(winsitelist) do
			calMoney(deskno,v,winnum)
		end		
	end

	restartthegame(deskno)
end

--���������Ϣ
function clone_winlist_data(deskno,sitelist)
	local clonesite = sitelist[1]
	local clonesitedata = desklist[deskno].site[clonesite]
	for k,v in pairs(sitelist) do
		if v ~= clonesite then
			local sitedata = desklist[deskno].site[v]
			sitedata.spike = clonesitedata.spike
			sitedata.xiansheng = clonesitedata.xiansheng
			sitedata.win_jinhua = clonesitedata.win_jinhua
		end
	end
end

--�յ���ҷ���
function onZYSZRecvLose(buf)
    local curUser = getuserid(buf)
    --��ȫ��֤
    local userinfo = userlist[curUser];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site	
	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
	    return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end

	--�Լ�������ϲ��ܷ���,Ҳ����???
	if desklist[deskno].site[siteno].action_giveup == 0 then
		return
	end

	hall.desk.set_site_state(deskno,siteno, SITE_STATE.WAIT)    

    doUserGiveUp(userinfo)
end

--ִ����ҷ�������
function doUserGiveUp(userinfo)
    local deskno,siteno = userinfo.desk,userinfo.site
	--�Ѿ��������˻�����??
	if desklist[deskno].site[siteno].islose == 1 then
		return
	end

     --��¼��������+1
    desklist[deskno].giveup_people_num = desklist[deskno].giveup_people_num + 1
    --��Ϸ������һ
    desklist[deskno].peopleplaygame = desklist[deskno].peopleplaygame - 1

    --Ͷ����״̬��Ϊ����
    desklist[deskno].site[siteno].islose = 1--������

    --�û�����޸�д�����ݿ�
    writelosergoldtodb(deskno,siteno)
	
	if desklist[deskno].peopleplaygame <= 1 then
		desklist[deskno].isgiveupover = 1
		desklist[deskno].winner = deskmgr.getnextsite(deskno,siteno)
	end

    --�㲥����
    net_broadcastdesk_user_lose(deskno,siteno)

    --���������ť�ļ�������һλ������ǿ�ˣ����ƹ��������
    if desklist[deskno].nextpeople == siteno or desklist[deskno].isgiveupover == 1 then
        continuegame(deskno,2)
    end
end

--�յ���ҿ���
function onZYSZRecvKaiPai(buf)
	local curUser = getuserid(buf)
	--��ȫ��֤
	local userinfo = userlist[curUser];
	if not userinfo then return end

	local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return
	end

	if (siteno ~= desklist[deskno].nextpeople) then
		return
	end
	
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end

	--�Լ�������ϲ��ܿ���,Ҳ����???
	if desklist[deskno].site[siteno].action_vs == 0 then
		return
	end

    if desklist[deskno].firstkaipai == 0 then
        desklist[deskno].firstkaipai = siteno--��¼��һ�����Ƶ���λ��
    else
        TraceError("����������???")
        return
    end
	
    local othersiteno = deskmgr.getnextsite(deskno,siteno)--ʣ������һ���˵���λ��

    if othersiteno == siteno then
        TraceError("�����쳣������ʱû���ҵ���һ��")
        return
    end

	hall.desk.set_site_state(deskno,siteno,SITE_STATE.WAIT)

    --������Ӧ����ע2����ע
	local money =  desklist[deskno].curdeskzhu * 2

    money = setbetmoney(deskno,siteno,money)

    desklist[deskno].site[siteno].betmoney = desklist[deskno].site[siteno].betmoney + money

    if desklist[deskno].site[siteno].islook == 1 then
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + (money * 0.5)
    else
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + money
    end

    --̨���ܽ��
    desklist[deskno].betmoney =  desklist[deskno].betmoney + money
    --��ʾ����ע���
    desklist[deskno].site[siteno].curbet = money
    
    local losesite = 0
	local result = validPoker(deskno,siteno,othersiteno)
    if result == 1 then--���Ƶ��˴�
        losesite = othersiteno
        desklist[deskno].winner = siteno
        record_paixin_msg(deskno, siteno, othersiteno)
    else
        losesite = siteno
        desklist[deskno].winner = othersiteno
        record_paixin_msg(deskno, othersiteno, siteno)
		if desklist[deskno].site[siteno].paixing == desklist[deskno].site[othersiteno].paixing then
			desklist[deskno].site[othersiteno].isnarrow = 1--��¼���˱����Լ���ͬ�����»�ʤ
		end
    end

    desklist[deskno].site[losesite].islose = 1

    --��Ϸ������һ
    desklist[deskno].peopleplaygame = desklist[deskno].peopleplaygame - 1

	--�㲥������Ϣ
	net_broadcast_userkaipai_info(deskno,siteno,losesite)

    --�û�����޸�д�����ݿ�
    writelosergoldtodb(deskno,losesite)

    --�����˼�������һλ
    continuegame(deskno)
end

--�յ���ҿ���
function onZYSZRecvKanpai(buf)
	trace(string.format("�û�(%s)������", buf:ip()..":"..buf:port()))
	local curUser = getuserid(buf) --string.format("%s:%s", buf:ip(), buf:port())

	--��ȫ��֤
	local userinfo = userlist[curUser];
    local deskno,siteno = userinfo.desk,userinfo.site

	if deskno == nil or siteno == nil then
		return
	end

	if(siteno ~= desklist[deskno].nextpeople) then
		return
	end
    
    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL then
        return
	end

	--�Լ�������ϲ��ܿ���,Ҳ����???
	if desklist[deskno].site[siteno].action_look == 0 then
		return
	end		 

	--�Ѿ��������ˣ�ֱ��return
	if desklist[deskno].site[siteno].islook == 1 then
		return
    end

    --�����óɵȴ�
    hall.desk.set_site_state(deskno,siteno, SITE_STATE.WAIT)--��λ����Ϊ�ȴ�״̬
    --��λ����Ϊ����״̬
    desklist[deskno].site[siteno].islook = 1

	--���ƺ���Ͷע�ʳ���
    if desklist[deskno].site[siteno].iscaichi == 0 then
	    desklist[deskno].site[siteno].iscaichi = 2
    end

    hall.desk.set_site_state(deskno,siteno, SITE_STATE.KANPAI)--��λΪ����״̬

    net_send_kanpai(deskno,siteno)--�㲥����״̬
end

--����ҵ�Ǯд�����ݿⲢ��¼��־
function writelosergoldtodb(deskno,siteno)
	local tempscore = - desklist[deskno].site[siteno].betmoney

	local userid = hall.desk.get_user(deskno, siteno)
	local userinfo = userlist[userid]

	------ͳ�������û�10�����ڽ���ܺ�--------------
	local all_info = {
		gold = tempscore,
		userid = userinfo.userId,
	}
	eventmgr:dispatchEvent(Event("golderror_checkpoint", all_info))
	------------------------------------------------

    --�����Ǯ
	usermgr.addgold(userinfo.userId, tempscore, 0, tSqlTemplete.goldType.ZYSZ_JIESUAN, -1,1)

	local sbgold = userinfo.safebox.safegold ~= nil and userinfo.safebox.safegold or 0

    --��¼��־
	if(desklist[deskno].logsql == "") then
		desklist[deskno].logsql = userinfo.userId.. ",".. tempscore .. "," ..
			"0," .. userinfo.nSid..","..userinfo.gamescore..","..sbgold
	else
		desklist[deskno].logsql = desklist[deskno].logsql .. "," ..userinfo.userId.. ",".. tempscore .. "," ..
			"0," .. userinfo.nSid..","..userinfo.gamescore..","..sbgold
	end

	desklist[deskno].logpeople = desklist[deskno].logpeople + 1;

    --����������
    local gameeventdata = {}
    xpcall(function()
        local refdata = {
            userid 	= userinfo.userId,
            iswin 	= 0,
            single_event = 0,
            wingold = tempscore,
            data	=
            {
                [zysz.gameref.REF_GOLD]	= tempscore,
                [zysz.gameref.REF_EXP]  	= 0,
                [zysz.gameref.REF_WIN]  	= 0,
                [zysz.gameref.REF_BIGWIN] = 0,				
            }
        }
        update_game_ref_data(userinfo.desk,userinfo.site, refdata)
        table.insert(gameeventdata, refdata)
    end, throw)
    --�ɷ��ο�����
    eventmgr:dispatchEvent(Event("game_event", gameeventdata));

	--�����
	local integraldata = {
		is_win = 0,                                 --�����϶�û��ʤ
		extra_integral = 0,			                --����ӳ�
		player_count = 1,                           --�������,��������϶���1
		userid = userinfo.userId,                   --�û�id
	}

	--���ͻ��ָ�����Ϣ,���»�������
	eventmgr:dispatchEvent(Event("integral_change_event", integraldata));
end

--ͬ��gamecenter�û����
function SendGoldToGameCenter(userinfo)
    --ͬ���û����
    local szSendBuf = userinfo.userId..","..userinfo.gamescore --���͸�gc����������Ϣ
    tools.SendBufToUserSvr(gamepkg.name, "STGB", "", "", szSendBuf) --�������ݵ�����ˣ�֪ͨ������������Ǯ��
end

--ǿ��game_ref_data
function update_game_ref_data(deskno, siteno, refdata)
    local userinfo = userlist[hall.desk.get_user(deskno, siteno)]
    local sitedata = desklist[deskno].site[siteno]
    local refgold = refdata.data[zysz.gameref.REF_GOLD]  --��Ӯ���

    local userhandpokes = sitedata.handpokes
    local siteChar = sitedata.handchar
    local sitepaixing = sitedata.paixing

    local userdata = deskmgr.getuserdata(userinfo)
	--[[
        ���ƣ�0
        ���ӣ�1
        ˳�ӣ�2
        ��: 3
        ˳��4
        ���ӣ�5
		͵��: 6
    -]]
    --REF_BAOZI ����
    if sitepaixing == 5 then
        refdata.data[zysz.gameref.REF_BAOZI] = 1
    --REF_SHUNJIN ˳��
    elseif sitepaixing == 4 then 
        refdata.data[zysz.gameref.REF_SHUNJIN] = 1
    --REF_JINHUA ��
    elseif sitepaixing == 3 then
        refdata.data[zysz.gameref.REF_JINHUA] = 1    
    --REF_DUIZI ����
    elseif sitepaixing == 1 then
        refdata.data[zysz.gameref.REF_DUIZI] = 1    
    --REF_DANPAI ����
    elseif sitepaixing == 0 then
        refdata.data[zysz.gameref.REF_DANPAI] = 1   
		if refgold < 0 and validTouji(siteChar) then
			refdata.data[zysz.gameref.REF_235LOST] = 1
		end			 
    --REF_235 ��ͬ��ɫ235
    elseif sitepaixing == 6 then
        refdata.data[zysz.gameref.REF_235] = 1
	end

	--�Ƿ��ǽ���������
	if sitepaixing > 3 then
		refdata.data[zysz.gameref.REF_BIGPAIXING] = 1
	end

    --REF_MENKAI �ƿ�
    if sitedata.islook == 0 then
        refdata.data[zysz.gameref.REF_MENKAI] = 1
    --REF_KANPAI ����
    else
        refdata.data[zysz.gameref.REF_KANPAI] = 1
    end

    if sitedata.isautokaipai == 1 then
        refdata.data[zysz.gameref.REF_AUTOBIPAI] = 1
    end

	--REF_FIRSTKILL��һ������
	if desklist[deskno].firstkaipai == siteno then
		refdata.data[zysz.gameref.REF_FIRSTKILL] = 1
	end
	
	--REF_NOADD�����û�мӹ�ע
	if sitedata.isadd == 0 then
		refdata.data[zysz.gameref.REF_NOADD] = 1
    end

    --REF_WIN�����Ƿ���������Ϸ�ģ��Ͳ���ʤ��
    if desklist[deskno].isgiveupover == 1 then
        refdata.data[zysz.gameref.REF_WIN] = 0
    end

    --REF_PLAY ��һ��
    refdata.data[zysz.gameref.REF_PLAY] = 1

    --REF_WINPOINT ��ʤ��Ĵ���
    if refgold > 0 and desklist[deskno].isgiveupover == 0 then
        if userdata.zysz_winpoint == nil then
            userdata.zysz_winpoint = 0
        end
        userdata.zysz_winpoint = userdata.zysz_winpoint + 1
    else
        userdata.zysz_winpoint = nil
	end

    refdata.data[zysz.gameref.REF_WINPOINT] = userdata.zysz_winpoint

    if(desklist[deskno].isgiveupover == 0) then
        --REF_WINGOLD1W һ��Ӯ1W�������
        if(refgold >= 10000) then
            refdata.data[zysz.gameref.REF_WINGOLD1W] = 1
            --REF_WINGOLD10W һ��Ӯ10W�������
            if(refgold >= 100000) then
                refdata.data[zysz.gameref.REF_WINGOLD10W] = 1
            end
        end
    end

    --REF_GIVEUP3  --��������3�˷���
    if(desklist[deskno].giveup_people_num >= 3) then
        refdata.data[zysz.gameref.REF_GIVEUP3] = 1 
    end

    --REF_SPIKE      --��ɱ��������Ӯ
    if(sitedata.spike == 1) then
        refdata.data[zysz.gameref.REF_SPIKE] = 1 
    end

    --REF_XIANSHENG  --��ʤ
    if(sitedata.xiansheng == 1) then
        refdata.data[zysz.gameref.REF_XIANSHENG] = 1     
    end

    --REF_WINJINHUA  --Ӯ�˱��˵Ľ�
    if(sitedata.win_jinhua == 1) then
        refdata.data[zysz.gameref.REF_WINJINHUA] = 1
	end

	--REF_NARROW --�����˿��ƶ�������ͬ����
	if sitedata.isnarrow == 1 then
		refdata.data[zysz.gameref.REF_NARROW] = 1
	end

	--REF_TRIPLEKILL--ϵͳ�Զ���������������
	if desklist[deskno].lostpeoplenum >= 3 then
		refdata.data[zysz.gameref.REF_TRIPLEKILL] = 1
	end

	--REF_KAIPAIWINPOINT--���������ۼ�Ӯ
	if(refdata.data[zysz.gameref.REF_FIRSTKILL] and refdata.data[zysz.gameref.REF_FIRSTKILL] == 1 and refgold > 0) then
        --Ӯһ��+1��
        if(userdata.zysz_kaipai_winpoint == nil) then
            userdata.zysz_kaipai_winpoint = 0
		end

        userdata.zysz_kaipai_winpoint = userdata.zysz_kaipai_winpoint + 1
    else
        userdata.zysz_kaipai_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_KAIPAIWINPOINT] = userdata.zysz_kaipai_winpoint 

    --REF_JINHUAWINPOINT     --�����������ۼ�Ӯ
    if(refgold > 0 and desklist[deskno].isgiveupover == 0 and ((refdata.data[zysz.gameref.REF_JINHUA] and refdata.data[zysz.gameref.REF_JINHUA] == 1) or
           (refdata.data[zysz.gameref.REF_SHUNJIN] and refdata.data[zysz.gameref.REF_SHUNJIN] == 1) or
           (refdata.data[zysz.gameref.REF_BAOZI] and refdata.data[zysz.gameref.REF_BAOZI] == 1))) then
        --Ӯһ��+1��
        if(userdata.zysz_jinhua_winpoint == nil) then
            userdata.zysz_jinhua_winpoint = 0
        end
        userdata.zysz_jinhua_winpoint = userdata.zysz_jinhua_winpoint + 1   
    else
        userdata.zysz_jinhua_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_JINHUAWINPOINT] = userdata.zysz_jinhua_winpoint

    --REF_DANPAIWINPOINT    --�����ۼ�Ӯ  
    if(refgold > 0 and desklist[deskno].isgiveupover == 0 and refdata.data[zysz.gameref.REF_DANPAI] and refdata.data[zysz.gameref.REF_DANPAI] == 1) then
        --Ӯһ��+1��
        if(userdata.zysz_danpai_winpoint == nil) then
            userdata.zysz_danpai_winpoint = 0
		end

        userdata.zysz_danpai_winpoint = userdata.zysz_danpai_winpoint + 1
    else
        userdata.zysz_danpai_winpoint = 0
	end

    refdata.data[zysz.gameref.REF_DANPAIWINPOINT] = userdata.zysz_danpai_winpoint 
end

--�յ���Ҹ�ע��Ϣ
function OnZYSZRecvGenZhu(buf)
	local curUser = getuserid(buf)
	--��ȫ��֤
	local userinfo = userlist[curUser];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
		return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
	end
	
	--�Լ�������ϲ��ܸ���,Ҳ����???
	if desklist[deskno].site[siteno].action_follow == 0 then
		return
	end

	--ִ�и�����ע�Ȳ���
    doxiazhuabout(userinfo,1)
end

--�յ������ע
function OnZYSZRecvJiaZhu(buf)
	local curUser = getuserid(buf)
	--��ȫ��֤
	local userinfo = userlist[curUser];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site

	if deskno == nil or siteno == nil then
		return
	end

	if siteno ~= desklist[deskno].nextpeople then
		return
    end

    if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.PANEL and hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.KANPAI then
        return
    end

	--�Լ�������ϲ��ܼ�ע,Ҳ����???
	if desklist[deskno].site[siteno].action_add == 0 then
		return
	end

	--��ע����
    local addzhutype = buf:readByte()

    local findtype = 0
    for k,v in pairs(gamecfg.addzhutype) do
        if tonumber(v) == addzhutype then
            findtype = 1
            break
        end
    end

    if findtype == 0 then
        TraceError("���������Ͳ��Ϸ� " .. addzhutype)
        addzhutype = gamecfg.addzhutype[1]--Ĭ������Сע
    end

    desklist[deskno].curdeskzhu = desklist[deskno].curdeskzhu + desklist[deskno].dizhu * addzhutype
	
	--��¼��Ҽ�ע��
	desklist[deskno].site[siteno].isadd = 1

    --ִ�и�����ע�Ȳ���
    doxiazhuabout(userinfo,2)
end

function doxiazhuabout(userinfo,xztype)
    local deskno,siteno = userinfo.desk,userinfo.site
    local money = desklist[deskno].curdeskzhu

    --������ע���ʵ�ʽ������ע���Ƿ���ȷ
	money = setbetmoney(deskno,siteno,money)

    --�޸���������µ���ע
    if desklist[deskno].site[siteno].islook == 1 then
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + math.floor((money * 0.5) + 0.5)
    else
        desklist[deskno].site[siteno].betpercent = desklist[deskno].site[siteno].betpercent + money
    end

	--TraceError("�յ�"..deskno.." ��"..siteno.." ��".." ��ע "..money)
    --����Ϊ�ȴ�״̬
	hall.desk.set_site_state(deskno, siteno, SITE_STATE.WAIT)

    desklist[deskno].site[siteno].betmoney = desklist[deskno].site[siteno].betmoney + money
    --̨���ܽ��
    desklist[deskno].betmoney = desklist[deskno].betmoney + money
    --��ʾ����ע���
    desklist[deskno].site[siteno].curbet = money

    if desklist[deskno].isfengding == 0 and desklist[deskno].site[siteno].betpercent >= desklist[deskno].fengdingmoney then--�����ⶥ�󴥷�
        desklist[deskno].isfengding = 1
        desklist[deskno].kaifengsiteno = siteno
    end

    --�㲥�����ע
    net_broadcastdesk_user_xiazhu(userinfo,xztype)

    --��ע�˼�������һλ
    continuegame(deskno,1)
end

--��¼������زɼ�.
function record_paixin_msg(deskno, winsite, losesite)
    local paixin_level_winsite = desklist[deskno].site[winsite].paixing
    local paixin_level_losesite = desklist[deskno].site[losesite].paixing
    --[[
        ���ƣ�0
        ���ӣ�1
        ˳�ӣ�2
        ��: 3
        ˳��4
        ���ӣ�5
		͵��: 6
    -]]   

	--�����͵������ɢ��
	if paixin_level_losesite == 6 then
		desklist[deskno].site[losesite].paixing = 0--������ҵ�����
		paixin_level_losesite = 0
	end

    local windesksitedata = desklist[deskno].site[winsite]

    --�Ƿ�Ϊ��ɱ
    if(paixin_level_winsite - paixin_level_losesite >= 2) then
        windesksitedata.spike = 1   
    else
        windesksitedata.spike = 0 
    end

    --�Ƿ�ɱ�˽𻨵���
    if(paixin_level_losesite == 3) then
        windesksitedata.win_jinhua = 1   
    else
        windesksitedata.win_jinhua = 0  
    end

    --�Ƿ�Ϊ��ʤ,������������3
    windesksitedata.xiansheng = 0
    local winpokes = desklist[deskno].site[winsite].handpokes
    local losepokes = desklist[deskno].site[losesite].handpokes

    if(paixin_level_winsite == paixin_level_losesite) then
        if((tonumber(zysz.pokenum[winpokes[2]]) - tonumber(zysz.pokenum[losepokes[2]])) <= 3) then
            windesksitedata.xiansheng = 1
        end
    end
end

--�յ��û�ǿ��
function OnZYSZRecvForceOutGame(buf)
    local curUser = getuserid(buf)
    --��ȫ��֤
    local userinfo = userlist[curUser];
    if not userinfo then return end
    if (userinfo.desk ~= nil and userinfo.site ~= nil) then
        hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
        doUserGiveUp(userinfo)
    end
	net_Send_KickUser(userinfo)
end

--�յ�����ʳ�
function onZYSZRecvClickCaiChi(buf)
	local userId = getuserid(buf) --string.format("%s:%s", buf:ip(), buf:port())
	local userinfo = userlist[userId];
    if not userinfo then return end
    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	if isguildroom() then return end
	
	local sitedata = desklist[deskno].site[siteno]
    --�Ѿ����Ͷ�� �� �Ѿ����� ��������Ͷ��
    if sitedata.iscaichi >= 1 then
        return
	end

	if sitedata.islose == 1 or desklist[deskno].firstkaipai ~= 0 then
        return
    end
	
	if deskmgr.get_game_state(deskno) ~= gameflag.start then
		return
	end

	local userdata = deskmgr.getuserdata(userinfo)

	sitedata.iscaichi = 1  --Ͷע�ʳ�

	--�ʳ���ע���Ϊ��ע
	local caichiAdd = desklist[deskno].addCaichiMoney
	
	--���Ӳʳ��ܽ��
	zysz.caichi.sumgold = zysz.caichi.sumgold + caichiAdd;

    --��������Ͽ۳�Ͷע
	usermgr.addgold(userinfo.userId,-caichiAdd,0,tSqlTemplete.goldType.ZYSZ_TOUZHU,-1)
	
	--�������ݿ��ܽ����
	local szsql = format(tZyszSqlTemplete.updateCaichiGold,zysz.caichi.sumgold,groupinfo.groupid) 	
	dblib.execute(szsql)


	--���͵�ǰ�ʳ��ܽ��
	--broadcast_lib.borcast_room_event_by_filter("ZYSZSNCC")
    netlib.send(net_broadcast_caichi_sumgold, userinfo.ip, userinfo.port)
    --���͸���ǰ����
    netlib.send(function(buf)
		buf:writeString("ZYSZCC")
    	buf:writeByte(siteno)	--���˲ʳ�Ͷ���˵���λ��
    	buf:writeInt(caichiAdd)	--Ͷע�˶���Ǯ 
    end,userinfo.ip,userinfo.port)

    
end

--�յ������������ʼ
function onZYSZRecvGameStart(buf)
	local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	--�жϺϷ���
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.NOTREADY then return end
    --�ж��Ƿ�Ϊ��ս�û�
    if (watch_lib.is_watch_user(userinfo) == 1) then
        --�޸������е���λ��ʼ�ȴ�״̬
        hall.desk.set_site_state(deskno, siteno, SITE_STATE.WATCH)        
    else
        --�޸������е���λ��ʼ�ȴ�״̬
    	hall.desk.set_site_state(deskno,siteno,SITE_STATE.READYWAIT)    
    	--�㲥�û��Ѿ�׼���ÿ�ʼ��Ϸ����Ϣ
        net_broadcast_game_start(deskno,siteno)    
    	--���Կ�ʼ��Ϸ
    	playgame(deskno)
    end
end

function playgame(deskno)
    if deskmgr.get_game_state(deskno) == gameflag.notstart then  --δ��ʼ״̬
		local readysite = 0			--�㿪ʼ������
		local notreadysite = 0		--û�㿪ʼ������
		for i = 1, room.cfg.DeskSiteCount do
			local state = hall.desk.get_site_state(deskno, i)
			if state == SITE_STATE.READYWAIT then
				readysite = readysite + 1
			elseif state == SITE_STATE.NOTREADY then
				notreadysite = notreadysite + 1
			end
		end

    	if notreadysite == 0 and readysite >= 2 then

			desklist[deskno].peopleplaygame = readysite

            --��¼ÿ�ֿ�ʼʱ�������
            desklist[deskno].gamestart_playercount = desklist[deskno].peopleplaygame

            --��ֿ�ʼ�����õ��ֿ�ʼʱ��
    	    desklist[deskno].starttime = os.date("%Y-%m-%d %X", os.time())

            --��Ϸ��ʼ��־
		    deskmgr.set_game_state(deskno, gameflag.start)

	        --������ҵ���С��ע
            get_minbet_from_playlist(deskno)

            --���ֳ�ˮ
            desklist[deskno].choushui = math.abs(math.floor(desklist[deskno].dizhu * groupinfo.specal_choushui * 0.1 + 0.5))

            for _, player in pairs(deskmgr.getplayers(deskno)) do
                --�۳�ˮǮ
                usermgr.addgold(player.userinfo.userId,-desklist[deskno].choushui,-desklist[deskno].choushui,tSqlTemplete.goldType.ZYSZ_CHOUSHUI,tSqlTemplete.goldType.ZYSZ_CHOUSHUI)
                --����λ���ֿ��������
                desklist[deskno].site[player.userinfo.site].maxbetmoney = player.userinfo.gamescore
            end

            desklist[deskno].mingamescore = desklist[deskno].mingamescore - desklist[deskno].choushui--��¼��СЯ��

            desklist[deskno].fengdingmoney = zysz_get_dizhu_bygold(1+desklist[deskno].mingamescore * gamecfg.myselfbili, 2)--��¼�ⶥֵ

            --��������Ͷע
            desklist[deskno].addCaichiMoney = desklist[deskno].dizhu
            if desklist[deskno].addCaichiMoney > 10000 then
                desklist[deskno].addCaichiMoney = 10000
            end

            --��ʼ����
    	    fapaiAll(deskno)
    	    
    	    if desklist[deskno].game == nil then desklist[deskno].game = {} end
    		desklist[deskno].game.startTime = os.date("%Y-%m-%d %X", os.time())
    	end
    end
end

--�õ���ע
function get_minbet_from_playlist(deskno)
	--�ҳ���������СЯ��
	local mingold = 0
	local num = 0

	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local usergold = player.userinfo.gamescore
		if num == 0 then
			mingold = usergold
			num = 1
		end

		if usergold < mingold then
			mingold = usergold
		end
	end
    
	desklist[deskno].mingamescore = mingold--��¼��СЯ��

    desklist[deskno].dizhu = math.abs(math.floor(zysz_get_dizhu_bygold(mingold,1) * gamecfg.dizhuxishu))--��ֵ��ע

    desklist[deskno].curdeskzhu = desklist[deskno].dizhu
end

function zysz_get_dizhu_bygold(mingold,num)
	local mingoldstr = tostring(math.abs(math.floor(mingold)))
	local betgoldstr = ""

	if string.len(mingoldstr) < 3 then
		TraceError("�Ƿ���Ǯ����!!!" .. mingoldstr)
		return 0
	elseif string.len(mingoldstr) <= 4 then
		betgoldstr = string.sub(mingoldstr,1,num)
	else
		betgoldstr = string.sub(mingoldstr,1,2)
	end

	local leavelen = string.len(mingoldstr) - string.len(betgoldstr)

	for i = 1,leavelen do
		betgoldstr = betgoldstr .. "0"
	end
	
	return tonumber(betgoldstr)
end

--�������ĳ̨Ӯ�ҵ���λ�ţ�����һ�����Ƶ���λ��
--������λ��
function randomZhuangJia(deskno)
	local randomSite = math.random(1, room.cfg.DeskSiteCount)	--���λ��

	local breakSite = randomSite 
	local userinfo =  deskmgr.getsiteuser(deskno,randomSite)
	for i = 1,room.cfg.DeskSiteCount do
		if userinfo ~= nil then
			break
		end

		randomSite = deskmgr.getnextsite(deskno,randomSite)

		if breakSite == randomSite then
			TraceError("[deadloop]�Ҳ�������״̬�������λBUG��!")
			break
        end

        userinfo = deskmgr.getsiteuser(deskno,randomSite)
	end

	return randomSite
end

--ȫ������
function fapaiAll(deskno)
    if desklist[deskno].zhuangjia == 0 then--û��ׯ�����һ��
	    desklist[deskno].zhuangjia = randomZhuangJia(deskno)
	else--��ׯ�ҵĻ����¸���ׯ
		desklist[deskno].zhuangjia = deskmgr.getnextsite(deskno,desklist[deskno].zhuangjia)
	end

	desklist[deskno].nextpeople = desklist[deskno].zhuangjia

    --������
    makePaiList(deskno)
    
    --[[ 
    local test = 0 ]]--

    for _,player in pairs(deskmgr.getplayers(deskno)) do
		local siteno = player.siteno
    	if hall.desk.get_site_state(deskno,siteno) == SITE_STATE.READYWAIT then
            local sitedata = desklist[deskno].site[siteno]
            for j = 1,zysz.cfg.handpokenum do
                table.insert(sitedata.handpokes,fapai(deskno))
            end

            --[[ 
            --������ͬ���͵Ĵ���
            if test == 0 then
                sitedata.handpokes =  {10,23,36} --����  {1,13,11}    --˳��
            elseif test == 1 then
                sitedata.handpokes = {2,3,1}    --235   --{1,15,29}  --˳��
            elseif test == 2 then
                sitedata.handpokes = {2,4,6}    --��
            elseif test == 3 then
                sitedata.handpokes = {2,3,19}   --{7,8,9}    --˳��
            elseif test == 4 then
                sitedata.handpokes = {10,23,36} --����
            elseif test == 5 then
                sitedata.handpokes = {27,38,39} --����AKQ
            end
            test = test + 1
            ]]--

            sitedata.handpokes = sortpokerlist(sitedata.handpokes)
            --�õ�����char
            sitedata.handchar = zysz.pokechar[sitedata.handpokes[1]]..zysz.pokechar[sitedata.handpokes[2]]..zysz.pokechar[sitedata.handpokes[3]] 
			--�õ�����
			sitedata.paixing = get_site_poke_level(deskno,siteno)
    	    --��ע
    	    desklist[deskno].site[siteno].betmoney = desklist[deskno].dizhu

            desklist[deskno].site[siteno].betpercent = desklist[deskno].dizhu

    	    --̨��������
    	    desklist[deskno].betmoney = desklist[deskno].betmoney + desklist[deskno].site[siteno].betmoney
        else
            TraceError("��ʼ��ʱ�����˲���READWAIT��������")
		end

		hall.desk.set_site_state(deskno,siteno,SITE_STATE.FAPAI)
    end

    net_send_fapai(deskno)--�㲥����״̬
end

--�յ����ƽ���
function onZYSZRecvFapaiOver(buf)
	local userinfo = userlist[getuserid(buf)];
    if not userinfo then return end

    local deskno,siteno = userinfo.desk,userinfo.site
	if deskno == nil or siteno == nil then
		return 
    end

	--�жϺϷ���
	if hall.desk.get_site_state(deskno,siteno) ~= SITE_STATE.FAPAI then return end

	if desklist[deskno].site[siteno].isfapaiover == 1 then return end

	--���ó��Ѿ���������
	desklist[deskno].site[siteno].isfapaiover = 1

	--���óɵȴ�
	hall.desk.set_site_state(deskno,siteno,SITE_STATE.WAIT)

	do_fapai_over_check(deskno)
end

--ִ�з��ƽ�����鲢�����²�����
function do_fapai_over_check(deskno)
	local countover = 0
	for i = 1,room.cfg.DeskSiteCount do
		if desklist[deskno].site[i].isfapaiover == 1 then
			countover = countover + 1
		end
	end

	--�յ������˷�����(���ƽ�������������һλ)
	if countover >= desklist[deskno].peopleplaygame then
		continuegame(deskno)
	end
end

--�õ��ʳ���Ϣ
function OnRecvCaiChiInfo(tRet)
    if (#tRet == 0) then
        --û�вʳ���Ϣ�����뵽���ݿ�
        TraceError("û�вʳ���Ϣ�������µĵ����ݿ�")
        local szsql = format(tZyszSqlTemplete.insertZyszCaichiInfo,groupinfo.groupid, os.time())
		dblib.execute(szsql)
        return
    end

    zysz.caichi.sumgold = tonumber(tRet[1]["sumgold"] or 0)           
    zysz.caichi.lastwinuser = tRet[1]["last_win_user"] or ""              
    zysz.caichi.lastwintime = tonumber(tRet[1]["last_win_time"] or 0) 
    zysz.caichi.lastwinmoney = tonumber(tRet[1]["last_win_gold"] or 0) 
    TraceError("�ɹ��õ�zysz�ʳ���Ϣ")
end

function getCaichiInfo()
    local szsql = format(tZyszSqlTemplete.getZyszCaichiInfo,groupinfo.groupid)
	dblib.execute(szsql, OnRecvCaiChiInfo)
end
---------------------------------------------
zysz.ontimecheck = function()
    if (room.time % 5 == 0) then
        collectgarbage("collect")
    end
    if timelib.time % 5 == 0 then
        if (zysz.cfg.last_broadcast_user_id == nil) then
                zysz.cfg.last_broadcast_user_id = 0
        end
        zysz.cfg.last_broadcast_user_id = (zysz.cfg.last_broadcast_user_id + 1) % 100
        --���͵�ǰ�ʳ��ܽ��
        if (zysz.caichi.sumgold ~= zysz.caichi.orgsumgold) then            
            broadcast_lib.borcast_room_event_by_filter("ZYSZSNCC", broad_caici_filter)
            zysz.caichi.orgsumgold = zysz.caichi.sumgold
        end
    end
	if timelib.time % 10 == 0 then
        
		for deskno = 1, room.cfg.deskcount do
			if desklist[deskno] and desklist[deskno].state_list ~= nil and
				#desklist[deskno].state_list ~= 0 and zysz.getGameStart(deskno) == true then
				--�쳣����ʼ
				local all_wait = true
				local wait_count = 0
				local null_count = 0
				for i = 1, room.cfg.DeskSiteCount do					
					if hall.desk.get_site_state(deskno, i) ~= SITE_STATE.WAIT and
						hall.desk.get_site_state(deskno, i) ~= SITE_STATE.READYWAIT and 
						hall.desk.get_site_state(deskno, i) ~= NULL_STATE then
						all_wait = false
						break
					end	
				end
				if all_wait == true then --�����˶����ȶ�״̬
					TraceError("��" .. tostring(deskno) .. "��������")					
					TraceError(desklist[deskno].state_list)
					desklist[deskno].state_list = {}
					forceGameOver(deskno)
				end
				--�쳣�������
			end
		end
	end
end

--������ע��ֽ��
function setbetmoney(deskno,siteno,money)
    local betmoney = 0
    if desklist[deskno].site[siteno].islook == 1 then  --��������ƣ�����Ŀǰע����2
		betmoney = desklist[deskno].curdeskzhu * 2
    end

    if betmoney == 0 then
        betmoney = money
    end

    local mycurbetmoney = desklist[deskno].site[siteno].betmoney
    local mycurbetpercent = desklist[deskno].site[siteno].betpercent
    local fengdingmoney = desklist[deskno].fengdingmoney

    if desklist[deskno].isfengding == 0 then
        --����עʱ��û�г�����СЯ��������ϵ�Ǯ
        if betmoney >= desklist[deskno].mingamescore - mycurbetmoney then
            TraceError("�쳣�˳�������СǮ����")
    	    betmoney = desklist[deskno].mingamescore - mycurbetmoney
        elseif betmoney >= fengdingmoney - mycurbetpercent then--�����ⶥ�󴥷�
            betmoney = fengdingmoney - mycurbetpercent
            if desklist[deskno].site[siteno].islook == 1 then--�Լ�������
                betmoney = betmoney * 2
            end
        end
    else--���˿����˷ⶥ����ƽ�ⶥ
        betmoney = fengdingmoney - mycurbetpercent--�Լ�����

        if desklist[deskno].site[siteno].islook == 1 then--�Լ�������
            betmoney = betmoney * 2
        end
    end

	return betmoney
end

function calCaichiMoney(deskno)
    local userpokes = {}
    local siteChar = ""
    local awardMoney = 0;	--��õĲʳؽ���
    local awardBeishu = 0;  --��òʳصı���
    local updategoldTamplate = "%d,%d,%d"
    local szSql = ""

    for i = 1, room.cfg.DeskSiteCount do 		
        local sitedata = desklist[deskno].site[i]
        if sitedata.iscaichi == 1 and sitedata.islose ~= 1 then	--���Ͷ�˲ʳ� ���� �������Ӯ��
            local userinfo = userlist[hall.desk.get_user(deskno, i)]
            --����뿪�Ժ��вʳأ����ٷ���
            if(userinfo ~= nil) then
                awardMoney = 0;
                userpokes = sitedata.handpokes
                siteChar = sitedata.handchar
            
                local needborcast = false
                --�Ƿ����AKQ
                if validRedAKQ(userpokes,siteChar) then
                    awardMoney = zysz.caichi.sumgold;	--���ȫ���ʳ�
                    needborcast = true
                    awardBeishu = 100
                      
                --�Ƿ�������
                elseif validBaozi(siteChar) then
                    awardMoney = desklist[deskno].addCaichiMoney * 40;	--40���ر�
                    needborcast = true
                    awardBeishu = 40
                
                --�Ƿ�Ϊ˳��ͬ��˳��
                elseif validColor(userpokes) and validShunzi(siteChar) then 
                    awardMoney = desklist[deskno].addCaichiMoney * 30;	--30���ر�
                    needborcast = true
                    awardBeishu = 30
                
                --�Ƿ�Ϊ�𻨣�ͬ����
                elseif validColor(userpokes) then
                    awardMoney = desklist[deskno].addCaichiMoney * 5;	--5���ر�
                    awardBeishu = 5
                
                --�Ƿ�Ϊ˳��
                elseif validShunzi(siteChar) then 
                    awardMoney = desklist[deskno].addCaichiMoney * 4;	--4���ر�
                    awardBeishu = 4
                
                --�Ƿ�ΪJJ���ϵĶ�
                elseif validJJDuizi(siteChar) then
                    awardMoney = desklist[deskno].addCaichiMoney;		--1���ر�
                    awardBeishu = 1
				end

                --���˲ʳ�
                if(awardMoney > 0) then
                    --���������ֱ�ӽ��ʳ��н��ȫ����Ϊ����
                    if(awardMoney > zysz.caichi.sumgold) then
                        awardMoney = zysz.caichi.sumgold;
                    end
            
                    --��¼���Ӯ�˲ʳض��ٽ�ҺͶ��ٱ�
                    sitedata.wincaichi_gold = awardMoney
                    sitedata.wincaichi_beishu = awardBeishu
    
                    zysz.caichi.sumgold = zysz.caichi.sumgold - awardMoney;

                    --�����ˮ
                    local jiangchichoushui = awardBeishu > 5 and math.floor(awardMoney * gamecfg.jiangchichoushui) or 0

                    --���˲ʳظ���Ҽ�Ǯ
                    usermgr.addgold(userinfo.userId,(awardMoney - jiangchichoushui),-jiangchichoushui,tSqlTemplete.goldType.ZYSZ_CAICHI,tSqlTemplete.goldType.ZYSZ_CAICHI_CHOUSHUI,1)
    
                    --��Ҫ�㲥��ȥ�㲥,�����ݿ���»���            
                    if(needborcast) then
                        --�������ݿ�ʳ���Ϣ
                        szSql = format(tZyszSqlTemplete.updateCaichiInfo,zysz.caichi.sumgold,dblib.tosqlstr(userinfo.nick),os.time(),awardMoney,groupinfo.groupid) 
                        dblib.execute(szSql)
                        zysz.caichi.lastwinuser = userinfo.nick;
                        zysz.caichi.lastwinmoney = awardMoney - jiangchichoushui;
                        zysz.caichi.lastwintime = os.time()
						zysz.caichi.isshowhuojiang = 1
                    else
                        --����Ҫ�㲥�Ĳ��㲥�����������ݿ�Ļ���
                        --�������ݿ�ʳ���Ϣ
                        szSql =  format(tZyszSqlTemplete.updateCaichiInfo_goldonly,zysz.caichi.sumgold,groupinfo.groupid) 
                        dblib.execute(szSql)
						zysz.caichi.isshowhuojiang = 0
                    end
                    
                    zysz.caichi.userid = userinfo.userId
                    --���������� ���˲ʳ��н���,1�������ϵ�
                    if (awardBeishu > 5) then
                        broadcast_lib.borcast_room_event_by_filter("ZYSZCCOK", broad_prize_filter)
                    elseif (needborcast) then
                        netlib.send(net_send_telluser_getprize, userinfo.ip, userinfo.port)
                    end                    
                end

                --�ʳ��������
                local gameeventdata = {}
                xpcall(function()
                    local refdata = {
                        userid 	= userinfo.userId,
                        single_event = 1,
                        data	= {}
                    }

                    if(sitedata.wincaichi_beishu > 0) then
                        --REF_SMALLCAICHI �õ�5�������²ʳؽ���
                        if(sitedata.wincaichi_beishu <= 5) then
                            refdata.data[zysz.gameref.REF_SMALLCAICHI] = 1
                        --REF_BIGCAICHI �õ�5�����ϲʳؽ���
                        else
                            refdata.data[zysz.gameref.REF_BIGCAICHI] = 1
                        end
                
                        --REF_WINCAICHI100   һ��Ӯ100+�ʳؽ��
                        if(sitedata.wincaichi_gold >= 100) then
                            refdata.data[zysz.gameref.REF_WINCAICHI100] = 1
                            --REF_WINCAICHI1000   һ��Ӯ1000+�ʳؽ��
                            if(sitedata.wincaichi_gold >= 1000) then
                                refdata.data[zysz.gameref.REF_WINCAICHI1000] = 1
                            end
                        end         
                    end

                    table.insert(gameeventdata, refdata)
                end, throw)
                --�ɷ��ο�����
                eventmgr:dispatchEvent(Event("game_event", gameeventdata));

            end
        end
    end
end

--winsiteӮ������λ��,winnum�м�����Ӯ��
function calMoney(deskno,winsite,winnum)
    trace("�������")
    local tempscore = 0

    local logDesk = desklist[deskno];
    local logUsersInfo = groupinfo.groupid..","..desklist[deskno].gamepeilv..",\""..logDesk.starttime.."\",\""
			 ..os.date("%Y-%m-%d %X", os.time()).."\""
	
    --�����ʱ��ֻд��Ӯ�ҵĽ�����ݣ���ҵ��ڱ��ƽ�����Ͷ�����Ѿ�д�����ݿ���
    --��ȡӮ���û�
    local userid = hall.desk.get_user(deskno, winsite);
    local userinfo = userlist[userid]

    tempscore = math.floor(desklist[deskno].betmoney / winnum) - desklist[deskno].site[winsite].betmoney

	------ͳ�������û�10�����ڽ���ܺ�----------
	local all_info = {
		gold = tempscore,
		userid = userinfo.userId,
	}
	eventmgr:dispatchEvent(Event("golderror_checkpoint", all_info))
    ------------------------------------------------

    local userdata = deskmgr.getuserdata(userinfo)

    --�����Ǯ
	usermgr.addgold(userinfo.userId, tempscore, 0, tSqlTemplete.goldType.ZYSZ_JIESUAN, -1,1)

    --�����־��¼sql���������6�ˣ����0.
    local sbgold = userinfo.safebox.safegold ~= nil and userinfo.safebox.safegold or 0

    desklist[deskno].logpeople = desklist[deskno].logpeople + 1

	desklist[deskno].winpeoplenum = desklist[deskno].winpeoplenum - 1--Ӯ���˽�����һ��

    desklist[deskno].logsql = desklist[deskno].logsql.. "," ..userinfo.userId.. ",".. tempscore .. ",0," 
                                .. userinfo.nSid..","..userinfo.gamescore..","..sbgold

	if desklist[deskno].winpeoplenum <= 0 then
		local countSql = room.cfg.DeskSiteCount - desklist[deskno].logpeople   
		 
		for i = 1,countSql do
			desklist[deskno].logsql = desklist[deskno].logsql.. ",0,0,0,0,0,0"
		end

		logUsersInfo = logUsersInfo..","..desklist[deskno].logsql
		  
		dblib.execute(format(tZyszSqlTemplete.insertLogRound, logUsersInfo))
	end

    --Ӯ���������
    local gameeventdata = {}
    xpcall(function()
        local refdata = {
            userid 	= userinfo.userId,
            iswin = 1,
            single_event = 0,
            wingold = tempscore,
            data =
            {
                [zysz.gameref.REF_GOLD]	= tempscore,
                [zysz.gameref.REF_EXP]  	= 0,
                [zysz.gameref.REF_WIN]  	= 1,
                [zysz.gameref.REF_BIGWIN] = 0,				
            }
        }

        update_game_ref_data(userinfo.desk,userinfo.site, refdata)
        table.insert(gameeventdata, refdata)
    end, throw)
    --�ɷ��ο�����
    eventmgr:dispatchEvent(Event("game_event", gameeventdata));

    if desklist[userinfo.desk].gamestart_playercount < 1 then
	    desklist[userinfo.desk].gamestart_playercount = 1
    end

    --�����[Ӯ����]
    local integraldata = {
        is_win = 1,          --�Ƿ��ʤ
        extra_integral = 0,	 --����ӳ�
        player_count = desklist[userinfo.desk].gamestart_playercount - winnum,  --ÿ����Ϸ��ʼʱ������� - Ӯ������
        userid = userinfo.userId,                   --�û�id
    }

    --���ͻ��ָ�����Ϣ,���»�������
    eventmgr:dispatchEvent(Event("integral_change_event", integraldata));

    --zyszת�̻
    if (zhuanpan_zyszlib) then
        xpcall(function() zhuanpan_zyszlib.on_game_over(userinfo, desklist[deskno].site[winsite].islook, desklist[deskno].site[winsite].paixing, deskno) end, throw)
    end
end

--�õ����͵ȼ�
    --[[
        ���ƣ�0
        ���ӣ�1
        ˳�ӣ�2
        ��: 3
        ˳��4
        ���ӣ�5
		͵��: 6
    -]]       
function get_site_poke_level(deskno,siteno)
    local userpokes = desklist[deskno].site[siteno].handpokes 
    local siteChar = desklist[deskno].site[siteno].handchar   
    local paixin_level = 0
    --�Ƿ�������
    if validBaozi(siteChar) then
        paixin_level = 5

    --�Ƿ�Ϊ˳��ͬ��˳��
    elseif validColor(userpokes) and validShunzi(siteChar) then 
       paixin_level = 4

    --�Ƿ�Ϊ�𻨣�ͬ����
    elseif validColor(userpokes) then
        paixin_level = 3

    --�Ƿ�Ϊ˳��
    elseif validShunzi(siteChar) then 
        paixin_level = 2

    --�Ƿ�Ϊ����
    elseif validDuizi(siteChar) then
        paixin_level = 1
	else
		if validTouji(siteChar) then--͵������
			paixin_level = 6
		end
    end

    return paixin_level
end


--�Ƚ�ĳ��̨��������λ���ƵĴ�С
--return : 0��һ����1:site1�� 2:site2��
function validPoker(deskno,site1,site2)
	local result = 0

	--��������
	local site1pokes = desklist[deskno].site[site1].handpokes
	local site2pokes = desklist[deskno].site[site2].handpokes
	
	
	local site1Char = desklist[deskno].site[site1].handchar
	local site2Char = desklist[deskno].site[site2].handchar
	
	local site1Paixing = desklist[deskno].site[site1].paixing
	local site2Paixing = desklist[deskno].site[site2].paixing
	--[[
        ���ƣ�0
        ���ӣ�1
        ˳�ӣ�2
        ��: 3
        ˳��4
        ���ӣ�5
		͵��: 6
    -]] 
	--�������͵ıȽ�
	if site1Paixing == 5 then
        if site2Paixing == 5 then --site2�Ǳ���
            --�ȱ��ӵĴ�С
            if zysz.pokebaozi[site1Char] > zysz.pokebaozi[site2Char] then
                result = 1
            else
                result = 2
            end
        else --site2���Ǳ��ӡ�
            --�Ƿ�͵���ƣ�
            if site2Paixing == 6 then
                result = 2
            else
                result  = 1
            end
        end
	else --site1���Ǳ���
		if site2Paixing == 5 then --site2�Ǳ���
			--site1�Ƿ�͵���ƣ�
			if site1Paixing == 6 then
				result = 1
			else
				result  = 2
			end
		else  --���������Ǳ���
		    --ͬ��˳���͵ıȽ�
			if site1Paixing == 4 then --site1ͬ��˳
                if site2Paixing == 4 then	--site2��ͬ��˳
                    --�Ƚϴ�С
                    if zysz.pokeshunzi[site1Char] > zysz.pokeshunzi[site2Char] then
                       result = 1
                    else
                        if zysz.pokeshunzi[site1Char] < zysz.pokeshunzi[site2Char] then
                            result = 2
                        else --��С���
                            result = 0
                        end
                    end
                else--site2����ͬ��˳
                    result = 1
                end
			else--site1����ͬ��˳
				if site2Paixing == 4 then--site2��ͬ��˳
					result = 2
				else--������ͬ��˳
				    --ͬ�����͵ıȽ�
					if site1Paixing == 3 then --site1ͬ��
						if site2Paixing == 3 then	--site2��ͬ��
							--�Ƚϵ��Ŵ�С
							result = validDanZhang(site1pokes,site2pokes)
						else--site2����ͬ�� 
							result = 1 
						end
					else--site1����ͬ�� 
						if site2Paixing == 3 then--site2��ͬ��
							result = 2
						else--������ͬ��
						    --˳�����͵ıȽ�
							if site1Paixing == 2 then --site1˳��
								if site2Paixing == 2 then	--site2��˳��
									--�Ƚϴ�С
									if zysz.pokeshunzi[site1Char] > zysz.pokeshunzi[site2Char] then
					   					result = 1
									else
										if zysz.pokeshunzi[site1Char] < zysz.pokeshunzi[site2Char] then
											result = 2
										else--һ����
											result = 0
										end
									end
								else--site2����˳�� 
									 result = 1 
								end
							else--site1����˳��
								if site2Paixing == 2 then	--site2��˳��
							 		result = 2
							 	else--������˳��
								    --�������͵ıȽ� 
									if site1Paixing == 1 then --site1����
										if site2Paixing == 1 then	--site2�Ƕ���
											--�Ƚϴ�С
											if zysz.pokeduizi[site1Char] > zysz.pokeduizi[site2Char]  then
					   							result = 1
											else
												if zysz.pokeduizi[site1Char] < zysz.pokeduizi[site2Char]  then
													result = 2
												else--һ����
													result = 0
												end
											end
										else--site2���Ƕ��� 
									 		result = 1 
										end
									else--site1���Ƕ���
										if site2Paixing == 1 then	--site2�Ƕ���
							 				result = 2
							 			else--�����Ƕ���
							 			    --�������͵ıȽ� --�Ƚϵ��Ŵ�С
                                            result = validDanZhang(site1pokes,site2pokes)
							 			end 
								 	end 
								end				 
							end
						end
					end
				end
			end
		end
    end

	return result
end

--�������ͱȽϴ�С�����Ȼ�ɫ��
--���������num1_3��ʾ���ĵ���
--return 1:num1ϵ�� ��2��num2ϵ�д� ��0��һ����
function validDanZhang(site1pokes,site2pokes)
	local compareValue3 = 0
	local compareValue2 = 0
	local compareValue1 = 0
   	compareValue3 = validTwoPoker(site1pokes[3],site2pokes[3])
	if compareValue3 == 1 then
		 return 1
	elseif compareValue3 == 2 then
		return 2
	end

	compareValue2 = validTwoPoker(site1pokes[2],site2pokes[2])
	if compareValue2 == 1 then
		 return 1
	elseif compareValue2 == 2 then
		return 2
	end

	compareValue1 = validTwoPoker(site1pokes[1],site2pokes[1])
	if compareValue1 == 1 then
		 return 1
	elseif compareValue1 == 2 then
		return 2
	end

	return 0
end 


--���ƱȽϴ�С�����Ȼ�ɫ��
--return 1:num1 ��2��num2�� ��0��һ����
function validTwoPoker(num1,num2)
	local result = 0
   	if zysz.pokenum[num1] >  zysz.pokenum[num2] then
   	   result = 1
   	else
   		if zysz.pokenum[num1] <  zysz.pokenum[num2] then
   			result = 2
		else 
			result = 0
   		end
    end

   	return result
end 

--�ж��Ƿ�ͬ��
--���룺�����Ƶ����ֱ�ʾ
--���أ�true/false
function validColor(pokes)
	if zysz.pokecolor[pokes[1]] == zysz.pokecolor[pokes[2]] and  zysz.pokecolor[pokes[2]] == zysz.pokecolor[pokes[3]] then
		return true
	else
		return false
	end
end

--�ж��Ƿ����AKQ
--���룺�����Ƶ��ַ���ʾ����"222"
--���أ�true/false
function validRedAKQ(pokes,pokerChar)
	local result = false;
	--���ж��Ƿ�ͬ��˳����
	if validColor(pokes) and validShunzi(pokerChar) then --ͬ��˳
		--�Ƿ����
		if zysz.pokecolor[pokes[1]] == 3 then
		--�Ƿ�AKQ
			if zysz.pokeshunzi[pokerChar] == 12 then
				result = true;
			end
		end
	end
	return result;
end

--�ж��Ƿ���
--���룺�����Ƶ��ַ���ʾ����"222"
--���أ�true/false
function validBaozi(pokerChar)
	if zysz.pokebaozi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

function validJJDuizi(pokerChar)
	local result = false;
	--�Ƿ����
	if validDuizi(pokerChar) then 
		--�Ƿ�J���ϵĶ�
		if zysz.pokeduizi[pokerChar] > 108  then
			result = true;
		end
	end
	return result;
end

--�ж��Ƿ�˳��
--���룺�����Ƶ��ַ���ʾ����"234"
--���أ�true/false
function validShunzi(pokerChar)
	if zysz.pokeshunzi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--�ж��Ƿ����
--���룺�����Ƶ��ַ���ʾ����"234"
--���أ�true/false
function validDuizi(pokerChar)
	if zysz.pokeduizi[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--�ж��Ƿ�͵������
--���룺�����Ƶ��ַ���ʾ����"234"
--���أ�true/false
--ע����Ҫ�Լ����ϻ�ɫ�ж�
function validTouji(pokerChar)
	if zysz.poketouji[pokerChar] ~= nil then
		return true
	else
		return false
	end
end

--52���Ʒ�����������
function resetpoke(deskno)
	for i = 1,room.cfg.pokerCount do
		desklist[deskno].number_count[i] = 1
	end
end

--��������������������������Ӧ�����б�
function makePaiList(deskno)
	local paiCount = desklist[deskno].peopleplaygame * 3	--������
	desklist[deskno].paiList = {}
	for i= 1,paiCount do
		desklist[deskno].paiList[i] = {}
		desklist[deskno].paiList[i].id = makePai(deskno)
		desklist[deskno].paiList[i].isOut = false
	end
end

--����һ����
function fapai(deskno)
	local number = 0
	local orderId = 0
	local paiCount = desklist[deskno].peopleplaygame * 3	--������
	
	orderId = math.random(1,paiCount)
	number = desklist[deskno].paiList[orderId].id;

	if desklist[deskno].paiList[orderId].isOut then
	   number = fapai(deskno)
	else
	   desklist[deskno].paiList[orderId].isOut = true;
	end

	return number
end

--����һ����
function makePai(deskno)
   local number = 0
   number = math.random(1,room.cfg.pokerCount)

   if desklist[deskno].number_count[number] > 0 then
	   desklist[deskno].number_count[number] = desklist[deskno].number_count[number] - 1
   else
		number = makePai(deskno)
   end

   return number
end
-----------------------------����Э����غ���-----------------------------------------
--����T������
function net_Send_KickUser(userinfo)
    netlib.send(function(buf)
	    buf:writeString("ZYSZREKU")
	end,userinfo.ip, userinfo.port)
end


function broad_prize_filter(user_info)
    if (user_info ~= nil and user_info.desk) then
        return 1        
    else
        return 0
    end
end

function broad_caici_filter(user_info)
    if (user_info ~= nil and user_info.desk) then
        if ((user_info.userId % 100) == zysz.cfg.last_broadcast_user_id) then
            return 1
        else
            return 0
        end
    else
        return 0
    end
end

--���Ͳʳ���Ϣ
--isBorcastAll,0��ʾ�㲥���Լ���1�㲥��������
function net_send_caichi_message(isBorcastAll,userinfo)
	if isBorcastAll == 1 then
		broadcast_lib.borcast_room_event_by_filter("ZYSZCTIF", broad_caici_filter)
	elseif isBorcastAll == 0 then
		if userinfo then
			netlib.send(function(buf)
				net_broadcast_caichi_info(buf)
			end,userinfo.ip,userinfo.port)
		end
	end
end

--���Ͳʳ��ܽ����Ϣ
function net_broadcast_caichi_info(buf)
	buf:writeString("ZYSZCTIF")
	buf:writeInt(zysz.caichi.sumgold)
end

--������ҵ���ʳغ�֪ͨ�����˵�ǰ�Ĳʳ��ܽ��
function net_broadcast_caichi_sumgold(buf)
	buf:writeString("ZYSZSNCC")
	buf:writeInt(zysz.caichi.sumgold)    --�ʳ��ܽ��
end

--���߲ʳ��н��ģ��Լ��вʳ���
function net_send_telluser_getprize(buf)
    local tbtime = os.date("*t",zysz.caichi.lastwintime)
	local lasttime = tbtime.month .."-"..tbtime.day.." "..tbtime.hour..":"..tbtime.min

    buf:writeString("ZYSZCCOK")--д��Ϣͷ
    buf:writeInt(zysz.caichi.userid) --˭����
    buf:writeByte(zysz.caichi.isshowhuojiang)
    buf:writeString(zysz.caichi.lastwinuser)
    buf:writeString(lasttime)
    buf:writeInt(zysz.caichi.lastwinmoney)
end

--֪ͨ�ͻ���ĳ�˵㿪ʼ��
function net_broadcast_game_start(deskno,startsite)
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZNTST")
    	buf:writeByte(startsite)
    end,deskno, netlib.borcast_target.all)
end

--�㲥�Զ�������Ϸ����
function net_broadcast_game_over(deskno,doType,winlist,lostlist)
	local fengold = math.floor(desklist[deskno].betmoney / #winlist)--Ӯ���˷�Ǯ
	broadcast_lib.borcast_desk_event(function(buf)
		buf:writeString("ZYSZNTGO")
        	buf:writeByte(doType) 	--1Ϊ��ע������2Ϊ��������
		buf:writeInt(desklist[deskno].betmoney) --д�������ܽ��
		buf:writeByte(#winlist) 	--������Ӯ��
		for k,v in pairs(winlist) do
			local sitedata = desklist[deskno].site[v]
			buf:writeByte(v) --��λ��		
			buf:writeInt(fengold)--��ҵõ�����Ǯ
			buf:writeInt(fengold - sitedata.betmoney) --�����ʵӮ�˶���
			buf:writeByte(#sitedata.handpokes)
			for i = 1,#sitedata.handpokes do
				buf:writeByte(sitedata.handpokes[i])--����ID
			end
			buf:writeByte(sitedata.paixing) --��������
		end
		buf:writeByte(#lostlist) 	--����������
		for k,v in pairs(lostlist) do
			local sitedata = desklist[deskno].site[v]
			buf:writeByte(v) --��λ��		
			buf:writeInt(-sitedata.betmoney)--���˶���
			buf:writeByte(#sitedata.handpokes)
			for i = 1,#sitedata.handpokes do
				buf:writeByte(sitedata.handpokes[i])--����ID
			end
			buf:writeByte(sitedata.paixing) --��������
		end
	end,deskno, netlib.borcast_target.all)
end

--�㲥��ҷ���
function net_broadcastdesk_user_lose(deskno,giveupsiteno)
	local deskdata = desklist[deskno]
	local winsitedata = deskdata.site[desklist[deskno].winner]
    broadcast_lib.borcast_desk_event(function(buf)
	    buf:writeString("ZYSZSRFQ")
	    buf:writeByte(giveupsiteno)   --��������λ��.
		buf:writeInt(-deskdata.site[giveupsiteno].betmoney)--���˶���
		buf:writeByte(desklist[deskno].isgiveupover)    --��ҷ���ʱ�Ƿ��½���
		if desklist[deskno].isgiveupover == 1 then
			buf:writeByte(deskdata.winner) --����ʱӮ�������λ��
			buf:writeInt(deskdata.betmoney) --Ӯ�˶���Ǯ
			buf:writeInt(deskdata.betmoney - winsitedata.betmoney) --����Ӯ�˶���
            buf:writeByte(#winsitedata.handpokes)
			for i = 1,#winsitedata.handpokes do
				buf:writeByte(winsitedata.handpokes[i])--����ID
			end
			buf:writeByte(winsitedata.paixing) --��������
		end
    end,deskno, netlib.borcast_target.all)
end

--�㲥�����ע��Ϣ
function net_broadcastdesk_user_xiazhu(userinfo,xztype)
    local deskno,siteno = userinfo.desk,userinfo.site
    local sitedata = desklist[deskno].site[siteno]
    local deskdata = desklist[deskno]
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZSRXZ")
    	buf:writeByte(siteno)       --��ע����λ��
    	buf:writeInt(sitedata.betmoney) --����������ע�Ľ��
    	buf:writeInt(sitedata.curbet)   --�������˶���
    	buf:writeInt(deskdata.betmoney)	   --̨���ܽ�� 
    	buf:writeByte(xztype)	   --��ǰ��ע����,1��ע��2��ע
		--buf:writeByte(deskdata.isfengding) --�Ƿ����˷ⶥ
    end,deskno, netlib.borcast_target.all)
end

--���͸���������Ϣ
function net_send_show_action_list(userinfo)
    local deskno,siteno = userinfo.desk,userinfo.site
	local sitedata = deskmgr.getsitedata(deskno,siteno)
    netlib.send(function(buf)
		buf:writeString("ZYSZPAIF")
    	buf:writeByte(siteno)	--��һ����������
    	buf:writeByte(sitedata.action_look or 0)		--���� 
    	buf:writeByte(sitedata.action_vs or 0)		--����
    	buf:writeByte(sitedata.action_add or 0)		--��ע
    	buf:writeByte(sitedata.action_follow or 0)		--��ע
        buf:writeInt(sitedata.followgold or 0)       --��ע����
    	buf:writeByte(sitedata.action_giveup or 0)		--����
    end,userinfo.ip,userinfo.port)
end

--�㲥������Ϣ
function net_send_fapai(deskno)
	local players = {}
	local zhuangsite = desklist[deskno].zhuangjia
	table.insert(players, 1, zhuangsite)		--���÷���˳��
	local nextsite = zhuangsite
	for i = 1,room.cfg.DeskSiteCount do
		nextsite = deskmgr.getnextsite(deskno,nextsite) 
		if nextsite == zhuangsite then
			break
		end
		table.insert(players,1,nextsite)
	end
    broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZNTFP")
    	buf:writeByte(zhuangsite)--ׯ����λ��
    	buf:writeInt(desklist[deskno].dizhu)     --��ע
        buf:writeInt(desklist[deskno].choushui)  --��ˮ
    	buf:writeInt(desklist[deskno].betmoney)  --̨���ܽ��
        buf:writeInt(desklist[deskno].addCaichiMoney)
		buf:writeByte(#players)--���ٸ�����������
		for i = 1,#players do
			buf:writeByte(players[i])--��λ��
		end
    end,deskno, netlib.borcast_target.all)
end

--�㲥��ҿ�����Ϣ
function net_send_kanpai(deskno,kanpaisite)
    --�������
	for _,player in pairs(deskmgr.getplayers(deskno)) do
		local userinfo = deskmgr.getsiteuser(deskno,player.siteno)
		local userpokes = {}
		if player.siteno == kanpaisite then
			userpokes = desklist[deskno].site[kanpaisite].handpokes
		end

		netlib.send(function(buf)
			buf:writeString("ZYSZNTKP")
			buf:writeByte(kanpaisite)  			--���Ƶ���λ��
			buf:writeByte(#userpokes)           --������
			if #userpokes > 0 then
				for i = 1,#userpokes do
					buf:writeByte(userpokes[i])	    --����id
				end
				buf:writeByte(desklist[deskno].site[kanpaisite].paixing)--�������
			end
		end,userinfo.ip,userinfo.port)
	end
end

--�㲥����ֶ�������Ϣ
function net_broadcast_userkaipai_info(deskno,kaipaisiteno,losesite)
	local winnersite = desklist[deskno].winner
	local winpokes = desklist[deskno].site[winnersite].handpokes
	local losepokes = desklist[deskno].site[losesite].handpokes
	local wingold = desklist[deskno].betmoney - desklist[deskno].site[winnersite].betmoney
	local lostgold = - desklist[deskno].site[losesite].betmoney

	broadcast_lib.borcast_desk_event(function(buf)
    	buf:writeString("ZYSZSRKP")
        buf:writeByte(kaipaisiteno)--��������λ��
		buf:writeInt(desklist[deskno].betmoney)--�������ܽ��
        buf:writeInt(desklist[deskno].site[kaipaisiteno].betmoney)--����������ע
        buf:writeInt(desklist[deskno].site[kaipaisiteno].curbet)--�����˱�����ע����
        buf:writeByte(winnersite)--Ӯ����λ��
		buf:writeInt(wingold)--Ӯ�˶���
    	buf:writeByte(#winpokes)
        for i = 1,#winpokes do
    	    buf:writeByte(winpokes[i])	--����ID
		end
		buf:writeByte(desklist[deskno].site[winnersite].paixing)--Ӯ������
        buf:writeByte(losesite)--�����λ��
		buf:writeInt(lostgold)--���˶���
        buf:writeByte(#losepokes)
        for i = 1,#losepokes do
    	    buf:writeByte(losepokes[i])	--����ID
		end
		buf:writeByte(desklist[deskno].site[losesite].paixing)--�������
    end,deskno, netlib.borcast_target.all)
end

--�㲥������״̬
function net_broadcastdesk_playerinfo(desk)
	broadcast_lib.borcast_desk_event(
		function(buf, user)
			local len = 0;
			local data = {};
			for _, player in pairs(deskmgr.getplayers(desk)) do
				local state = hall.desk.get_site_state(desk, player.siteno)
				local statecode = 0
				if state == SITE_STATE.NOTREADY or state == SITE_STATE.WATCH then statecode = 2 end
				if state == SITE_STATE.READYWAIT then statecode = 1 end
				if state == SITE_STATE.FAPAI then statecode = 3 end
				local timeout = hall.desk.get_site_timeout(desk, player.siteno)
				if timeout < 0 then timeout = 0 end
				table.insert(data, {site = player.siteno, state = statecode, time = timeout});
				len = len + 1
			end
			buf:writeString("ZYSZNTZT")
			buf:writeInt(len)
			for i = 1, #data do
				buf:writeByte(data[i].site);		--��λ��
				buf:writeByte(data[i].state)		--״̬��
				buf:writeByte(data[i].time)		    --��ʱʱ��
			end
		end
	,desk, netlib.borcast_target.all)
end

-----------------------------��Ϸ�ӿ�ʵ�ֺ���-----------------------------------------
--�յ�����ĳ�û���ʱ���ߵ���Ϣ��ͨ�����û����̱�������ֹ��������һ��ʱ��û����Ӧ
zysz.OnTempOffline = function(userinfo)
end

zysz.onentergameroom = function(userid, roomtype, gamescore)
	return true
end

zysz.OnBeforeUserReLogin = function(userinfo)
    hall.desk.set_site_state(userinfo.desk, userinfo.site, NULL_STATE)
    doUserGiveUp(userinfo)
    if (userinfo.desk ~= nil) then
        doUserStandup(userinfo.key, false)
    end
    return 0
end

zysz.getGameStart = function(deskno,siteno)
	local gamestate = deskmgr.get_game_state(deskno)
	local bGameAlreadyStart  = true	
	
	if gamestate == gameflag.notstart then
		bGameAlreadyStart = false
    end

    if(siteno and siteno > 0) then
        local sitedata = deskmgr.getsitedata(deskno,siteno)
        local bSitelreadyStart = sitedata.islose == 0

        bGameAlreadyStart = bGameAlreadyStart and  bSitelreadyStart
    end

	return bGameAlreadyStart
end

zysz.AfterUserSitDown = function(userid, desk, site, bRelogin)  --�û����º�
    trace("�������£�������".."desk="..desk.."site="..site)
    local userinfo = userlist[hall.desk.get_user(desk, site)]
    if(bRelogin == 0) then	--���Ƕ��ߵ����        
        hall.desk.set_site_state(desk, site, SITE_STATE.NOTREADY)        
    end
    --���Ͳʳ���Ϣ
	zysz.caichi.isshowhuojiang = 0
	net_send_caichi_message(0,userinfo)
end

--�û����µ���Ϣ������֮��
zysz.AfterUserSitDownMessage = function(userid, desk, site, bRelogin)  --�û����º�
    local user_info = usermgr.GetUserById(userid)    
    if (watch_lib.is_watch_user(user_info) == 1) then        
        hall.desk.set_site_state(desk, site, SITE_STATE.WATCH)
        zysz.netSendGZFP(user_info);
    end
end
--�������Ÿ���ս���˷������˵���
zysz.netSendGZFP = function(user_info)
	local desk_info = desklist[user_info.desk]
	local desk_sites = desk_info.site --��λ�б�
	netlib.send(function(buf)
        buf:writeString("GZFP");
        buf:writeByte(#desk_sites);
        for i=1,#desk_sites do
        	local site_id = -1;
        	if desk_sites[i].user ~= nil and userlist[desk_sites[i].user] ~= nil then --����λ����
        		if watch_lib.is_watch_user(userlist[desk_sites[i].user]) ~= 1 then --���Ҹ���λ�ϵ��˲��ڹ�ս�б�
        			site_id = i;
        		end
        	end
        	buf:writeByte(site_id);
        end
    end, user_info.ip, user_info.port)
end

zysz.OnUserStandup = function(userid, desk, site)
	trace(string.format("�û�(%s)֪ͨ�Ѿ��뿪", desk..":"..site))

	--�˴���AfterUserStandup�е�������ͬ��������Ӧ�ò���Ҫ�����ط������ã��������ﲻ���û���״̬�����µ�BUG
	hall.desk.set_site_state(desk, site, NULL_STATE)
end

zysz.AfterOnUserStandup = function(userid, desk, site)
	--�����û�״̬
	hall.desk.set_site_state(desk, site, NULL_STATE)

	--���Կ�ʼ����
	playgame(desk)
end

zysz.AfterUserWatch = function(user_info)
    --�ָ�����
    if (watch_lib.is_watch_user(user_info) == 1) then        
        zysz.netSendGZFP(user_info);
    end
end

zysz.CanEnterGameGroup = function(szPlayingGroupName, nPlayingGroupId, nScore)
    --�ж��Ƿ�����Ϸ������
    if nPlayingGroupId ~= 0 then
		if tonumber(groupinfo.groupid) == nPlayingGroupId then
			return 1, ""
		else
			return -102, "���� "..szPlayingGroupName.." ����Ϸ���ڽ�����,�޷�����÷��䡣"
		end
    else
		trace("��ǰû�����ڽ�����Ϸ��id")
    end
end

--�ж��û��Ƿ�����Ŷ�
zysz.CanUserQueue = function(userKey, deskno)
    return 1, 0
end

--�ж��û�����Ϸ���ܲ��������ĳ�ּ۸����Ʒ
zysz.CanAfford = function(userinfo, paygold, pay_limit)
	local gold = userinfo.gamescore 
	if userinfo.desk then gold = gold - (pay_limit or groupinfo.pay_limit) end
	return gold - paygold >= 0,paygold - gold
end

zysz.init_desk_info = function()
end

zysz.init_site_info = function()
end

zysz.init_desk_data = function(deskno)
    local i = deskno
    desklist[i].gamestate = gameflag.notstart
    desklist[i].peoplejiesuan = 0	-- ��һ�����Ѿ����������
    desklist[i].peopleplaygame = 0	-- ��һ����������Ϸ������
    desklist[i].nextpeople = 0  --��һ����������
    desklist[i].winner = 0      --Ӯ����λ��(0Ϊ�ж��Ӯ��)
	desklist[i].zhuangjia = 0   --ׯ����λ��

    desklist[i].logsql = ""   	--�����������־��Ϣ��¼sql
    desklist[i].logpeople = 0	--�����ļ�¼��־��������Ϊ�˱������Ϸ�߼���ͻ����������һ������
    desklist[i].starttime = ""	--������Ϸ��ʼ��ʱ��
    desklist[i].giveup_people_num = 0    --�Ƿ������
	desklist[i].firstkaipai = 0 --�Ƿ�����,0δ���ƣ�����Ϊ������λ��
    desklist[i].isgiveupover = 0    --������Ϸ�����˷������� 
	
    desklist[i].number_count = {} 
    for j = 1, room.cfg.pokerCount do
        desklist[i].number_count[j] = 1	--ÿ���Ƶ����� 
    end

    desklist[i].betmoney = 0		--̨���ܽ��
    desklist[i].gamestart_playercount = 0  --��Ϸ��ʼ��ʱ���м�����
    desklist[i].game = {}

    for j = 1, room.cfg.DeskSiteCount do
        desklist[i].site[j].handpokes = {}      --��ҵ�����
        desklist[i].site[j].handchar = ""       --��ҵ������ַ���	
		desklist[i].site[j].paixing = -1        --��ҵ���������	
        desklist[i].site[j].betmoney = 0	    --ʵ����ע���
        desklist[i].site[j].betpercent = 0      --�����µ���ע���
        desklist[i].site[j].maxbetmoney = 0	    --���˵�ÿ�ֿ����ܽ���Ϊ���˽�Ҳ�ͬ����ͬ��
        desklist[i].site[j].islook = 0          --�Ƿ񿴹���,0δ����,1����
        desklist[i].site[j].iscaichi = 0        --�Ƿ�Ͷע�ʳ�,0δͶע��1Ͷע��,2����Ͷ��
        desklist[i].site[j].islose = 0          --�Ƿ������,0Ϊ����,1������
        desklist[i].site[j].action_look = 0	    --����
        desklist[i].site[j].action_vs = 0	    --����
        desklist[i].site[j].action_add = 0	    --��ע
        desklist[i].site[j].action_follow = 0   --��ע
        desklist[i].site[j].followgold = 0
        desklist[i].site[j].action_giveup = 0   --����
        desklist[i].site[j].wincaichi_beishu = 0  --Ӯ�ʳر���
        desklist[i].site[j].wincaichi_gold = 0  --Ӯ�ʳؽ���
        desklist[i].site[j].win_jinhua = 0      --Ӯ�˱��˵Ľ�
        desklist[i].site[j].spike = 0           --��ɱ
        desklist[i].site[j].xiansheng = 0       --��ʤ
        desklist[i].site[j].curbet = 0          --���ÿ����ע�Ľ��
		desklist[i].site[j].isfapaiover = 0     --�����Ƿ����,0δ����,1�Ѿ�����
		desklist[i].site[j].isadd = 0           --����Ƿ�ӹ�ע
		desklist[i].site[j].isnarrow = 0	    --�Ƿ�Ϊ��ͬ������ʤ
        desklist[i].site[j].isautokaipai = 0    --�Ƿ��Զ�����
    end

    desklist[i].addCaichiMoney = 0 --�ʳؼ�ע��
    desklist[i].mingamescore = 0  --Я����СǮ��Ǯ��
    desklist[i].dizhu = 0         --�þ���Ϸ�ĵ�ע
    desklist[i].curdeskzhu = 0    --�þ���Ϸ�ĵ�ǰ����ע
    desklist[i].choushui = 0      --�þ���Ϸ��ˮ
    desklist[i].isfengding = 0    --�þ���Ϸ�ⶥ�Ƿ�����0δ������1����
    desklist[i].kaifengsiteno = 0 --�þ���Ϸ�����ⶥ����λ��
    desklist[i].fengdingmoney = 0 --�þ���Ϸ�����ⶥʱ���ⶥ��λ���µ�ע
	desklist[i].winpeoplenum = 0	--�����ж�����Ӯ��
	desklist[i].lostpeoplenum = 0  --����ϵͳ���ƶ���������
end

zysz.init_desk_all = function()
    for i = 1, room.cfg.deskcount do
        zysz.init_desk_data(i)
    end
end

--��ʼ����Ϸ������ÿ����Ϸ������ʱ����ã�
function initGameData(deskno)
    desklist[deskno].logsql = ""
    desklist[deskno].logpeople = 0
    desklist[deskno].firstkaipai = 0 --�Ƿ�����,0δ���ƣ�����Ϊ������λ��
    desklist[deskno].giveup_people_num = 0 --����������
    desklist[deskno].gamestart_playercount = 0 --ÿ�̿�ʼ������
    desklist[deskno].betmoney = 0 --̨���ܽ��
    
    desklist[deskno].addCaichiMoney = 0 --�ʳؼ�ע��
    desklist[deskno].mingamescore = 0  --Я����СǮ��Ǯ��
    desklist[deskno].dizhu = 0         --�þ���Ϸ�ĵ�ע
    desklist[deskno].curdeskzhu = 0    --�þ���Ϸ�ĵ�ǰ����ע
    desklist[deskno].choushui = 0      --�þ���Ϸ��ˮ
    desklist[deskno].isfengding = 0    --�þ���Ϸ�ⶥ�Ƿ�����0δ������1����
    desklist[deskno].kaifengsiteno = 0 --�þ���Ϸ�����ⶥ����λ��
    desklist[deskno].fengdingmoney = 0 --�þ���Ϸ�����ⶥʱ���ⶥ��λ���µ�ע

    desklist[deskno].peopleplaygame = 0	-- ��һ����������Ϸ������
    desklist[deskno].nextpeople = 0     --��һ����������
	desklist[deskno].winpeoplenum = 0	--�����ж�����Ӯ��
	desklist[deskno].lostpeoplenum = 0  --����ϵͳ���ƶ���������
	desklist[deskno].winner = 0			--Ӯ����λ��(0Ϊ�ж��Ӯ��)
    desklist[deskno].isgiveupover = 0        --������Ϸ�����˷�������

    for i = 1, room.cfg.DeskSiteCount do 		
        desklist[deskno].site[i].handpokes = {}   --��ҵ�����
        desklist[deskno].site[i].handchar = ""    --��ҵ������ַ���
		desklist[deskno].site[i].paixing = -1	  --��ҵ���������
        desklist[deskno].site[i].islook = 0  	  --�Ƿ񿴹���,0δ����,1����
        desklist[deskno].site[i].iscaichi = 0     --�Ƿ�Ͷע�ʳ�,0δͶע��1Ͷע��,2����Ͷע��
        desklist[deskno].site[i].islose = 0       --�Ƿ������,0Ϊ����,1������
        desklist[deskno].site[i].betmoney = 0	  --��ע���
        desklist[deskno].site[i].betpercent = 0   --�����µ���ע���
		desklist[deskno].site[i].action_look = 0	--����
        desklist[deskno].site[i].action_vs = 0	--����
        desklist[deskno].site[i].action_add = 0	--��ע
        desklist[deskno].site[i].action_follow = 0  --��ע
        desklist[deskno].site[i].followgold = 0
        desklist[deskno].site[i].action_giveup = 0  --����
		desklist[deskno].site[i].maxbetmoney = 0  --���˵�ÿ�ֿ����ܽ���Ϊ���˽�Ҳ�ͬ����ͬ��
        desklist[deskno].site[i].wincaichi_beishu = 0  --Ӯ�ʳر���
        desklist[deskno].site[i].wincaichi_gold = 0    --Ӯ�ʳؽ���
        desklist[deskno].site[i].win_jinhua = 0  --Ӯ�˱��˵Ľ�
        desklist[deskno].site[i].spike = 0       --��ɱ
        desklist[deskno].site[i].xiansheng = 0   --��ʤ
		desklist[deskno].site[i].curbet = 0      --���ÿ����ע�Ľ��
		desklist[deskno].site[i].isfapaiover = 0 --�����Ƿ����,0δ����,1�Ѿ�����
		desklist[deskno].site[i].isadd = 0       --����Ƿ�ӹ�ע
		desklist[deskno].site[i].isnarrow = 0	 --�Ƿ�Ϊ��ͬ������ʤ
        desklist[deskno].site[i].isautokaipai = 0 --�Ƿ��Զ�����
	end

	--�������ϵ���״̬����Ϊδ׼��
	for _,player in pairs(deskmgr.getplayers(deskno)) do
		if hall.desk.get_site_state(deskno,player.siteno) ~= SITE_STATE.NOTREADY then
			--�û�״̬��Ϊ����
			hall.desk.set_site_state(deskno,player.siteno,SITE_STATE.NOTREADY)
		end
	end

    --����ϴ��
    resetpoke(deskno)

end

zysz.on_start_server = function()
    zysz.init_desk_all();
    TraceError("���������������ݿ��òʳ���Ϣ")
    getCaichiInfo();
end

--��λ״̬��
zysz.init_state = function()
    hall.desk.register_site_states(newStrongTable(
	{
		NOTREADY 	= {ss_notready_offline,	 ss_notready_timeout, 20},
		READYWAIT 	= {ss_readywait_offline, NULL_FUNC,           0},
		FAPAI       = {ss_fapai_offline,     ss_fapai_timeout,    10},
        PANEL       = {ss_panel_offline,	 ss_panel_timeout,    13},
        KANPAI      = {ss_kanpai_offline,	 ss_kanpai_timeout,   10},
		WAIT 		= {ss_wait_offline, 	 NULL_FUNC,			  0},
        WATCH 		= {ss_watch_offline, 	 NULL_FUNC,			  0},
	}))
    hall.desk.register_site_state_change(ss_onstatechange)
end

------------------------------�շ�Э����غ���--------------------------------------------
zysz.init_map = function()
    cmdGameHandler = {
	    ["ZYSZST"] = onZYSZRecvGameStart,		--�û�����ʼ
		["ZYSZFO"] = onZYSZRecvFapaiOver,		--�յ����ƽ���
	    ["ZYSZCC"] = onZYSZRecvClickCaiChi,		--�û�����ʳ�
	    ["ZYSZFQ"] = onZYSZRecvLose,			    --�û�����
	    ["ZYSZBP"] = onZYSZRecvKaiPai,		 	--�û�����(����)
	    ["ZYSZKP"] = onZYSZRecvKanpai,			--�û�����
	    ["ZYSZGZ"] = OnZYSZRecvGenZhu,			--�û���ע
        ["ZYSZJZ"] = OnZYSZRecvJiaZhu,			--�û���ע
        ["ZYSZOG"] = OnZYSZRecvForceOutGame,    --�û�ǿ���˳���Ϸ
        
		--Ϊ����ԭ���Ĵ���ִ����Ϣ
		["ZYSZSNCC"] = net_broadcast_caichi_sumgold, --������Ҽ�ע��ʳ���Ϣ
		["ZYSZCTIF"] = net_broadcast_caichi_info,--���Ͳʳ���ϸ��Ϣ
        ["ZYSZCCOK"] = net_send_telluser_getprize,--���������� ���˲ʳ��н���
	}
end

zysz.init_state();
zysz.init_map();

