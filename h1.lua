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
--用于只执行一次的初始化程序1
--netbuf.trace("svrpreinit.lua loaded!") --不能作，因TRACE尚未初始化

--math.randomseed(os.time())
--outputlogstr("svrpreinit.lua start loading...")
channellist = {}
userlist = {} --初始化时，无任何用户
userOnline = {} --todo这里应该从数据库中读取
--[[userOnline = {
	totalCount = 0, --用户的在线人数
	playingCount = 0,--用户的在玩人数
	robotCount = 0, --机器人的个数
}--]]
userNeedCheckOnline = {} --需要检测断网的用户
groupsUsersCount = {} --所有服务器的在线人数情况。
userlistIndexId = {} --初始化时，无任何用户,用用户id做索引
desklist = {}
channel_desklist={}
displaydesk = {} --缓存玩家请求的桌子列表
deskqueue={}
usermgr = {}  --用于管理用户
debugpkg = debug
inblacklog = netbuf.trace
g_KeywordFilter = {}    --关键词过滤

-- 保留表的定义，目前仅提供两个函数reg_page_user, unreg_page_user
visible_page_list = {}

--排名，德州只有经验和筹码
g_topusers = _S{
	--金币数    user_info.gamescore
	gold 		= _S{rule = function(user_info) return user_info.gamescore end, data = {},},
	--经验      user_info.gameInfo.exp
	exp 		= _S{rule = function(user_info) return user_info.gameInfo.exp end, data = {},},
	--声望      user_info.gameInfo.prestige
	--prestige 	= _S{rule = function(user_info) return user_info.gameInfo.prestige end, data = {},},
	--荣誉      user_info.gameInfo.integral
	--integral 	= _S{rule = function(user_info) return user_info.gameInfo.integral end, data = {},},
}

--时间检查类型
CheckTimeType =
{
	day     = 1,
	hour    = 2,
	minute  = 3,
	sec     = 4
}

offlinetype = {
	tempoffline = 1, --临时离线
}

room = { --作为命名空间使用
}

roomtype = {normal = 0, baofang = 1}

room.cfg = {
	deskcount=1000,     --一千张桌
	DeskSiteCount = 9,  --每桌最多9个位
	--desksiteicon=0, --用0号图标
	istimecheck=true, --是否进行时间检查，及调用游戏中的时间检查
	timeOfflineInterval = 7,  --多久进行一次断线检查
	--checkkicktimeinterval = 120, --临时离线多久强行踢走离线用户 改为，当局如果没有结束，用户回来有效，结束仍没有回来，则自动踢走
	deskicon=1,		  --0表示圆桌-当group.allowclicksite ==1 时可以设置>0的值，1表示3人桌，2表示4人桌，3表示6人桌
	DeskMustHavePerson = 1, --1表示每桌必须至少有一个自然人才让此桌进入游戏状态，否则本桌所有人重新排队
	ongameOverReQueue = 1, -- 1表示每次游戏结束后,都试图将所有人打乱重新排桌
	timerandomwait = 3, --表示每局结束后等待多久,才试图进行随机重排
	sendclientnum = 5, --表示5个一组发出reac消息,暂时解决数据包过大问题
	ignorerobot = 0, --1表示忽略机器人与自然人在排队规则中的区别
	checksameip = 0, --表示是否设置相同ip的人不能同桌打牌
	oncheckbupeiqian = 0, --表示 1=不赔钱 0=赔钱
	beginTimeOut = 30,	--未准备超时时间，暂时放在h2，因为坐下时候发
	roomtype = roomtype.normal, --房间类型
    MaxPrestige = 728800,     --玩家声望上限
    PrestigeToGold = 100,    --声望比对金币比例
    totalquestcount = 0,        --总任务数量
	MaxIntegral = 2100000000,       -- 玩家积分上限
	MaxExperience = 2100000000,     --玩家经验上限
	MaxLevel = 100,     --玩家等级上限
    freshman_limit = 1500;    --新手场限制，筹码大于1500不坐到新手场

	--德州扑克破产赠送(公测送30万次上线必须改回来)
	gold_bankrupt_give_value = 100,    --赠送金币数
	gold_bankrupt_give_times = 3,    --送3次
	--欢乐场破产记录表
	gold_bankrupt_selectsql = "insert ignore into user_gold_bankruptcy_info(user_id, give_count, give_time, remark) values(%d, 0, 0, ''); commit; "..
							"select * from user_gold_bankruptcy_info where user_id = %d ",
	gold_bankrupt_updatesql = "update user_gold_bankruptcy_info set %s where user_id = %d ",
}

room.time = 0 --用于作为心跳的检查
room.timeflagMin = 100 --时间检查标识分钟
room.maxnetdelaytime = 10 --网络延时超过X秒的用户要被踢走，单位(秒)
room.queueplayer = 0 --正在排队中的用户总数
room.deskplayer = 0  --占用了桌子的用户总数
room.maxWatchUserCount = 20 --观战人员改成20，之前是30
room.timeSortDelay = 600 -- 牌桌排名的排序定时设置，大约秒为单位
room.timeLastTime = 0	-- 最后一次的时间记录room.time
room.sortTopMax = 20 -- 牌桌排名的人数限制

--做性能统计用
room.perf = {
	check_interval_max = 2000,
	time_check_prev = os.clock(),
	recv_packcount = 0,
	recv_slicelen = 0,
	send_packcount = 0,
	send_slicelen = 0,
	cmdlist = {}
}

room.arg = {} --作为fireEvent中使用的全局变量命名空间使用

startflag={notready = 0, ready = 1}
gameOverReason = {normal = 1, nobodyjiao = 10}


SITE_STATE = nil  --座位上的状态机, 从游戏里面给覆盖

--广播方式
borcastTarget = _S{
	playingOnly = 1,		--只对桌上玩家
	watchingOnly = 2,			--只对桌上观战人
	all = 3,				--对所有人
}

SITE_UI_VALUE = _S{NULL = 0, NOTREADY = 1, READY = 2, PLAYING = 3}

g_queueindex = 0 --用于队列排序的序号，每有人排队，这个序号自动+1

--以下是队列对象化实现，用于排队新机制
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

--获取最前面的值
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
			--将后面的内容向前移动一下
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

--排队相关的变量
--用户进入排队队列的原因
queryReasonFlg={login = 0, gameOverAndWin = 1, gameOverAndLost=2, inValid = 3}

g_QueueLoginPeople1 = Queue:new()
g_QueueLoginPeople2 = Queue:new()
g_QueueWinPeople1 = Queue:new()
g_QueueWinPeople2 = Queue:new()
g_QueueLostPeople = Queue:new()
g_QueueRobot = Queue:new()
g_QueueInvalid = Queue:new()
g_LastInsertWinIn1= 0		--上一次赢的用户是否是插入了g_QueueWinPeople1
g_LastInsertLoginIn1= 0		--上一次登陆的人是否插入了g_QueueWinPeople1
g_UserQueue = {} --用户队列，用于记录哪些用户在排队
g_LastQueueCount = 0		--上一次发送到客户端排队的人数

--排队相关
UserQueueMgr = {}
DeskQueueMgr = {}

--登陆IP限制
LoginIPs = {}

g_randomflag = 0
--坐下类型:正常坐下、重登录、排队坐下
g_sittype = {normal = 1, relogin = 2, queue = 3}
--初始化等级经验对照表
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
		nextneedexp = 100 + (40 + (i - 5)*2)*(i - 5) --(公式，必须和客户端一致)
	end
	at_each_level_need_total_exp = at_each_level_need_total_exp + nextneedexp
	g_ExpLevelMap[i] = at_each_level_need_total_exp
end
--TraceError(g_ExpLevelMap)
--经验增加规则
--1、游戏输了所得经验(不含放弃输了的)
--2、游戏赢了所得经验
--3、3级以上每日送经验(每日首次坐下贈送)
--4、完成任务加经验
--单桌淘汰赛
--5、参加比赛加经验
--6、游戏输了得经验(不含放弃输了的)
--7、游戏赢了得经验
--8、比赛得前三名加经验
--每日淘汰赛
--9、 参加比赛加经验
--10、游戏输了得经验(不含放弃输了的)
--11、游戏赢了得经验
--12、比赛得前三名加经验
--13、开宝箱奖励经验
g_ExpType = {
	--普通场
	lost = 1,  --输
	win = 2, 
	firstsit = 3, 
	quest = 4,
	--单桌淘汰赛
	deskmatchjoin = 5,
	deskmatchlost = 6,
	deskmatchwin = 7,
	deskmatchprize = 8,
	--每日淘汰赛
	daymatchjoin = 9,
	daymatchlost = 10,
	daymatchwin = 11,
	daymatchprize = 12,

	baoxiang = 13,
    wdg_huodong=14, --五道杠活动
    jhm_huodong=15, --激活码活动
	}

--金币增加规则
--999999、人工补偿
--81、成就奖励(产出)
--83、每天领奖(产出)
--1000、充值(产出)
--1001、升级奖励(产出)
--1002、任务奖励(产出)
--1003、购买(消耗)
--普通游戏桌
--1004、普通场抽水(消耗)
--1005、德州游戏输掉或赢取
--单桌淘汰赛
--1006、单桌淘汰赛抽水(消耗)
--1007、单桌淘汰赛报名费
--1008、单桌淘汰赛奖励
--每日淘汰赛
--1009、每日淘汰赛抽水(消耗)
--1010、每日淘汰赛报名费
--1011、每日淘汰赛奖励
--1012、破产赠送(产出)
--其他
--1013、发表情费用(消耗)
--1014、第一次学习教程奖励(产出)
--1015、注册奖励(产出)
--1016、开宝箱奖励(产出)
--1017、出售礼品(产出)
--1018、VIP会员每天额外送钱(产出)
--1019、魅力农夫每天额外送钱(产出)
--1020、农场神秘果实开出筹码送钱(产出)
--1021、农场神秘果实开出VIP送钱(产出)
--1022、出售礼品的抽水(消耗)
--1023、购买甜蜜之心
--1024、出售甜蜜之心
--1025、出售甜蜜之心的抽水(消耗)
--1026、元宵节猜灯谜奖励(产出)
--1027、挂机活动领奖(产出)
g_GoldType = {
	achievegive = 81,
	daygive = 83,
	recharge = 1000,
	upgradegive = 1001,
	quest     	= 1002,
	buy		 	= 1003,
	--普通场
	normalchoushui   = 10100,
	normalwinlost    = 10101,

	--单桌淘汰赛
	deskmatchchoushui = 1006,
	deskmatchjoin     = 1007,
	deskmatchprize    = 1008,

	--每日淘汰赛
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
	--农场神秘果实
	farmfruitgold   = 1020,
	farmfruitVIP   = 1021,
    salegifttax   = 1022,

    --情人节甜蜜之心
    buysweetheart   = 1023,
    salesweetheart   = 1024,
    sweethearttax   = 1025,

	--挂机活动领奖
    onlineprize = 1027, --在线时长领奖
    riddleprize = 1026, --答题发奖（元宵节猜灯谜）
    jifenhuodong = 50, --积分场活动发奖
    regAddGold = 21, --注册送钱
    regAddGold = 22, --登陆送钱
    jhm_huodong=1030, --激活码
    spq_usespq=1031, --使用算牌器
    quest_wdg_alltastkdown=1032,--所有的每日任务都已完成
    quest_wdg_jiangping=1033,--五道杠发奖
    quest_wdg_nextdaylogin=1034,--五道杠次日领奖
    new_user_gold=1035, --新手首次玩游戏送200
    channel_day_gold =1036, --频道用户每日送钱
    quest_wdg_choujiang=1037, --五道杠发奖
    invite_match_gold=1038, --邀请赛发奖
    dhome_share_gold=1039, --D家分享加钱
    daxiao_gold=1040, --心跳十分钟的金币类型
    daxiao_choushui=1041, --心跳十分钟取银票时的抽水
    
    --活动奖励
    longzhou_match = 2000 --龙舟赛奖励
	}
g_DeskType ={normal = 1, tournament = 2, VIP = 3, channel =4, channel_world=5, channel_tournament=6, match=7, nobleroom = 10}
g_FarmType ={online = 1, fruits = 2,}
hall = {}

