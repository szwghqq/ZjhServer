dofile("common/common.lua")
function nulloutput()
end

trace = nulloutput
OutputLogStr = nulloutput
function TraceError(e)
	if (type(e) == "table") then
		netbuf.trace(tostringex(e))
	else
		netbuf.trace(e)
	end
end
silenttrace = nulloutput
--����ִֻ��һ�εĳ�ʼ������1
--netbuf.trace("svrpreinit.lua loaded!") --����������TRACE��δ��ʼ��

--math.randomseed(os.time())
--outputlogstr("svrpreinit.lua start loading...")
channellist = {}
userlist = {} --��ʼ��ʱ�����κ��û�
userOnline = {} --todo����Ӧ�ô����ݿ��ж�ȡ
--[[userOnline = {
	totalCount = 0, --�û�����������
	playingCount = 0,--�û�����������
	robotCount = 0, --�����˵ĸ���
}--]]
userNeedCheckOnline = {} --��Ҫ���������û�
groupsUsersCount = {} --���з��������������������
userlistIndexId = {} --��ʼ��ʱ�����κ��û�,���û�id������
desklist = {}
channel_desklist={}
displaydesk = {} --�����������������б�
deskqueue={}
usermgr = {}  --���ڹ����û�
debugpkg = debug
inblacklog = netbuf.trace
g_KeywordFilter = {}    --�ؼ��ʹ���

-- ������Ķ��壬Ŀǰ���ṩ��������reg_page_user, unreg_page_user
visible_page_list = {}

--����������ֻ�о���ͳ���
g_topusers = _S{
	--�����    user_info.gamescore
	gold 		= _S{rule = function(user_info) return user_info.gamescore end, data = {},},
	--����      user_info.gameInfo.exp
	exp 		= _S{rule = function(user_info) return user_info.gameInfo.exp end, data = {},},
	--����      user_info.gameInfo.prestige
	--prestige 	= _S{rule = function(user_info) return user_info.gameInfo.prestige end, data = {},},
	--����      user_info.gameInfo.integral
	--integral 	= _S{rule = function(user_info) return user_info.gameInfo.integral end, data = {},},
}

--ʱ��������
CheckTimeType =
{
	day     = 1,
	hour    = 2,
	minute  = 3,
	sec     = 4
}

offlinetype = {
	tempoffline = 1, --��ʱ����
}

room = { --��Ϊ�����ռ�ʹ��
}

roomtype = {normal = 0, baofang = 1}

room.cfg = {
	deskcount=1000,     --һǧ����
	DeskSiteCount = 9,  --ÿ�����9��λ
	--desksiteicon=0, --��0��ͼ��
	istimecheck=true, --�Ƿ����ʱ���飬��������Ϸ�е�ʱ����
	timeOfflineInterval = 7,  --��ý���һ�ζ��߼��
	--checkkicktimeinterval = 120, --��ʱ���߶��ǿ�����������û� ��Ϊ���������û�н������û�������Ч��������û�л��������Զ�����
	deskicon=1,		  --0��ʾԲ��-��group.allowclicksite ==1 ʱ��������>0��ֵ��1��ʾ3������2��ʾ4������3��ʾ6����
	DeskMustHavePerson = 1, --1��ʾÿ������������һ����Ȼ�˲��ô���������Ϸ״̬�������������������Ŷ�
	ongameOverReQueue = 1, -- 1��ʾÿ����Ϸ������,����ͼ�������˴�����������
	timerandomwait = 3, --��ʾÿ�ֽ�����ȴ����,����ͼ�����������
	sendclientnum = 5, --��ʾ5��һ�鷢��reac��Ϣ,��ʱ������ݰ���������
	ignorerobot = 0, --1��ʾ���Ի���������Ȼ�����Ŷӹ����е�����
	checksameip = 0, --��ʾ�Ƿ�������ͬip���˲���ͬ������
	oncheckbupeiqian = 0, --��ʾ 1=����Ǯ 0=��Ǯ
	beginTimeOut = 30,	--δ׼����ʱʱ�䣬��ʱ����h2����Ϊ����ʱ��
	roomtype = roomtype.normal, --��������
    MaxPrestige = 728800,     --�����������
    PrestigeToGold = 100,    --�����ȶԽ�ұ���
    totalquestcount = 0,        --����������
	MaxIntegral = 2100000000,       -- ��һ�������
	MaxExperience = 2100000000,     --��Ҿ�������
	MaxLevel = 100,     --��ҵȼ�����
    freshman_limit = 1500;    --���ֳ����ƣ��������1500���������ֳ�

	--�����˿��Ʋ�����(������30������߱���Ļ���)
	gold_bankrupt_give_value = 100,    --���ͽ����
	gold_bankrupt_give_times = 3,    --��3��
	--���ֳ��Ʋ���¼��
	gold_bankrupt_selectsql = "insert ignore into user_gold_bankruptcy_info(user_id, give_count, give_time, remark) values(%d, 0, 0, ''); commit; "..
							"select * from user_gold_bankruptcy_info where user_id = %d ",
	gold_bankrupt_updatesql = "update user_gold_bankruptcy_info set %s where user_id = %d ",
}

room.time = 0 --������Ϊ�����ļ��
room.timeflagMin = 100 --ʱ�����ʶ����
room.maxnetdelaytime = 10 --������ʱ����X����û�Ҫ�����ߣ���λ(��)
room.queueplayer = 0 --�����Ŷ��е��û�����
room.deskplayer = 0  --ռ�������ӵ��û�����
room.maxWatchUserCount = 20 --��ս��Ա�ĳ�20��֮ǰ��30
room.timeSortDelay = 600 -- ��������������ʱ���ã���Լ��Ϊ��λ
room.timeLastTime = 0	-- ���һ�ε�ʱ���¼room.time
room.sortTopMax = 20 -- ������������������

--������ͳ����
room.perf = {
	check_interval_max = 2000,
	time_check_prev = os.clock(),
	recv_packcount = 0,
	recv_slicelen = 0,
	send_packcount = 0,
	send_slicelen = 0,
	cmdlist = {}
}

room.arg = {} --��ΪfireEvent��ʹ�õ�ȫ�ֱ��������ռ�ʹ��

startflag={notready = 0, ready = 1}
gameOverReason = {normal = 1, nobodyjiao = 10}


SITE_STATE = nil  --��λ�ϵ�״̬��, ����Ϸ���������

--�㲥��ʽ
borcastTarget = _S{
	playingOnly = 1,		--ֻ���������
	watchingOnly = 2,			--ֻ�����Ϲ�ս��
	all = 3,				--��������
}

SITE_UI_VALUE = _S{NULL = 0, NOTREADY = 1, READY = 2, PLAYING = 3}

g_queueindex = 0 --���ڶ����������ţ�ÿ�����Ŷӣ��������Զ�+1

--�����Ƕ��ж���ʵ�֣������Ŷ��»���
Queue = {head=0, tail = -1, count = 0, list = {}}

function Queue:new(o)
    o = o or {}   -- create object if user does not provide one
	o.head = 0
	o.tail = -1
	o.list = {}
	o.count = 0
	setmetatable(o, self)
    self.__index = self
	return o
end

function Queue:Add(value)
  local tail = self.tail + 1
  self.tail = tail
  self.list[self.tail] = value
  self.count = self.count + 1
end

function Queue:Pop()
  local head = self.head
  --if head > self.tail then error("queue is empty") end
  if head > self.tail then
  	return nil
  end
  local value = self.list[head]
  self.list[head] = nil        -- to allow garbage collection
  self.head = self.head + 1
  self.count = self.count - 1
  return value
end

--��ȡ��ǰ���ֵ
function Queue:GetPopValue()
  local head = self.head
  --if head > self.tail then error("queue is empty") end
  if head > self.tail then
  	return nil
  end
  local value = self.list[head]
  return value
end

function Queue:Remove(value)
	local head = self.head
	--if head > self.tail then error("queue is empty") end
	if head > self.tail then
	return nil
	end

	local i, v
	for i = head, self.tail do
		v = self.list[i]
		if (value == v) then
			--�������������ǰ�ƶ�һ��
			local j
			for j = i, self.tail - 1 do
				self.list[j] = self.list[j + 1]
			end
			self.list[self.tail] = nil
			self.tail = self.tail - 1
			self.count = self.count - 1
			return i
		end
	end
	return nil
end

--�Ŷ���صı���
--�û������ŶӶ��е�ԭ��
queryReasonFlg={login = 0, gameOverAndWin = 1, gameOverAndLost=2, inValid = 3}

g_QueueLoginPeople1 = Queue:new()
g_QueueLoginPeople2 = Queue:new()
g_QueueWinPeople1 = Queue:new()
g_QueueWinPeople2 = Queue:new()
g_QueueLostPeople = Queue:new()
g_QueueRobot = Queue:new()
g_QueueInvalid = Queue:new()
g_LastInsertWinIn1= 0		--��һ��Ӯ���û��Ƿ��ǲ�����g_QueueWinPeople1
g_LastInsertLoginIn1= 0		--��һ�ε�½�����Ƿ������g_QueueWinPeople1
g_UserQueue = {} --�û����У����ڼ�¼��Щ�û����Ŷ�
g_LastQueueCount = 0		--��һ�η��͵��ͻ����Ŷӵ�����

--�Ŷ����
UserQueueMgr = {}
DeskQueueMgr = {}

--��½IP����
LoginIPs = {}

g_randomflag = 0
--��������:�������¡��ص�¼���Ŷ�����
g_sittype = {normal = 1, relogin = 2, queue = 3}
--��ʼ���ȼ�������ձ�
local at_each_level_need_total_exp = 0
g_ExpLevelMap = {}
for i = 1, 1000 do
	local nextneedexp = 0
	if(i == 1) then
		nextneedexp = 5
	elseif(i == 2) then
		nextneedexp = 15
	elseif(i == 3) then
		nextneedexp = 40
	elseif(i == 4) then
		nextneedexp = 60
	elseif(i == 5) then
		nextneedexp = 100
	else
		nextneedexp = 100 + (40 + (i - 5)*2)*(i - 5) --(��ʽ������Ϳͻ���һ��)
	end
	at_each_level_need_total_exp = at_each_level_need_total_exp + nextneedexp
	g_ExpLevelMap[i] = at_each_level_need_total_exp
end
--TraceError(g_ExpLevelMap)
--�������ӹ���
--1����Ϸ�������þ���(�����������˵�)
--2����ϷӮ�����þ���
--3��3������ÿ���;���(ÿ���״�����ٛ��)
--4���������Ӿ���
--������̭��
--5���μӱ����Ӿ���
--6����Ϸ���˵þ���(�����������˵�)
--7����ϷӮ�˵þ���
--8��������ǰ�����Ӿ���
--ÿ����̭��
--9�� �μӱ����Ӿ���
--10����Ϸ���˵þ���(�����������˵�)
--11����ϷӮ�˵þ���
--12��������ǰ�����Ӿ���
--13�������佱������
g_ExpType = {
	--��ͨ��
	lost = 1,  --��
	win = 2, 
	firstsit = 3, 
	quest = 4,
	--������̭��
	deskmatchjoin = 5,
	deskmatchlost = 6,
	deskmatchwin = 7,
	deskmatchprize = 8,
	--ÿ����̭��
	daymatchjoin = 9,
	daymatchlost = 10,
	daymatchwin = 11,
	daymatchprize = 12,

	baoxiang = 13,
    wdg_huodong=14, --����ܻ
    jhm_huodong=15, --������
	}

--������ӹ���
--999999���˹�����
--81���ɾͽ���(����)
--83��ÿ���콱(����)
--1000����ֵ(����)
--1001����������(����)
--1002��������(����)
--1003������(����)
--��ͨ��Ϸ��
--1004����ͨ����ˮ(����)
--1005��������Ϸ�����Ӯȡ
--������̭��
--1006��������̭����ˮ(����)
--1007��������̭��������
--1008��������̭������
--ÿ����̭��
--1009��ÿ����̭����ˮ(����)
--1010��ÿ����̭��������
--1011��ÿ����̭������
--1012���Ʋ�����(����)
--����
--1013�����������(����)
--1014����һ��ѧϰ�̳̽���(����)
--1015��ע�ά��(����)
--1016�������佱��(����)
--1017��������Ʒ(����)
--1018��VIP��Աÿ�������Ǯ(����)
--1019������ũ��ÿ�������Ǯ(����)
--1020��ũ�����ع�ʵ����������Ǯ(����)
--1021��ũ�����ع�ʵ����VIP��Ǯ(����)
--1022��������Ʒ�ĳ�ˮ(����)
--1023����������֮��
--1024����������֮��
--1025����������֮�ĵĳ�ˮ(����)
--1026��Ԫ���ڲµ��ս���(����)
--1027���һ���콱(����)
g_GoldType = {
	achievegive = 81,
	daygive = 83,
	recharge = 1000,
	upgradegive = 1001,
	quest     	= 1002,
	buy		 	= 1003,
	--��ͨ��
	normalchoushui   = 10100,
	normalwinlost    = 10101,

	--������̭��
	deskmatchchoushui = 1006,
	deskmatchjoin     = 1007,
	deskmatchprize    = 1008,

	--ÿ����̭��
	daymatchchoushui = 1009,
	daymatchjoin     = 1010,
	daymatchprize    = 1011,

	bankruptcy    = 1012, 
	buyemot	 	  = 1013,
	studyprize 	  = 1014,
	reggive 	  = 1015,

	baoxiang   = 1016,
	salegift   = 1017,

	vipdaygive   = 1018,
	charmdaygive   = 1019,
	--ũ�����ع�ʵ
	farmfruitgold   = 1020,
	farmfruitVIP   = 1021,
    salegifttax   = 1022,

    --���˽�����֮��
    buysweetheart   = 1023,
    salesweetheart   = 1024,
    sweethearttax   = 1025,

	--�һ���콱
    onlineprize = 1027, --����ʱ���콱
    riddleprize = 1026, --���ⷢ����Ԫ���ڲµ��գ�
    jifenhuodong = 50, --���ֳ������
    regAddGold = 21, --ע����Ǯ
    regAddGold = 22, --��½��Ǯ
    jhm_huodong=1030, --������
    spq_usespq=1031, --ʹ��������
    quest_wdg_alltastkdown=1032,--���е�ÿ�����������
    quest_wdg_jiangping=1033,--����ܷ���
    quest_wdg_nextdaylogin=1034,--����ܴ����콱
    new_user_gold=1035, --�����״�����Ϸ��200
    channel_day_gold =1036, --Ƶ���û�ÿ����Ǯ
    quest_wdg_choujiang=1037, --����ܷ���
    invite_match_gold=1038, --����������
    dhome_share_gold=1039, --D�ҷ����Ǯ
    daxiao_gold=1040, --����ʮ���ӵĽ������
    daxiao_choushui=1041, --����ʮ����ȡ��Ʊʱ�ĳ�ˮ
    
    --�����
    longzhou_match = 2000 --����������
	}
g_DeskType ={normal = 1, tournament = 2, VIP = 3, channel =4, channel_world=5, channel_tournament=6, match=7, nobleroom = 10}
g_FarmType ={online = 1, fruits = 2,}
hall = {}

