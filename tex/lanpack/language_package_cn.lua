if not inited_lan_cn then inited_lan_cn = true
lan_cn=
{
	--huodong.lua
	jhm_error="激活码错误";
	jhm_error_beenUsed="激活码已被使用";
	jhm_error_expired="激活码过期";
	jhm_error_usedSameType="您已用过同类型的激活码或激活码已被使用";
	jhm_error2="激活码验证错误";

	jhm_chouma_type_688="688筹码、30经验值";
	jhm_chouma_type_888="铜卡VIP3日体验、888筹码、30经验值";
	jhm_chouma_type_retresult24="铜卡VIP 3日体验、1888筹码";
	jhm_chouma_type_retresult25="银卡VIP 3日体验、3888筹码";
	jhm_chouma_type_retresult26="金卡VIP 3日体验、5888筹码";
	jhm_chouma_type_retresult27="铜卡VIP 3日体验、60000筹码";
	jhm_chouma_type_retresult28="金卡VIP 3日体验、40000筹码";
	jhm_chouma_type_retresult29="银卡VIP 3日体验、75000筹码";
	jhm_chouma_type_retresult30="铜卡VIP 3日体验、100000筹码";
	jhm_chouma_type_retresult31="金卡VIP 15日体验、甲壳虫汽车、80000筹码";
	jhm_chouma_type_retresult32="金卡VIP 30日体验、宝马Z4汽车、30000筹码";
	jhm_chouma_type_retresult33="铜卡VIP 1日体验、10000筹码";
	jhm_chouma_type_retresult34="铜卡VIP 1日体验、15000筹码";
	jhm_chouma_type_retresult35="铜卡VIP 1日体验、15000筹码";
	jhm_chouma_type_retresult36="铜卡VIP 1日体验、15000筹码";
	jhm_error_usedSameType_retresult5 = "您在7天之内已经使用过同类型的激活码";
	jhm_error_usedSameType_retresult6 = "您在3天之内已经使用过同类型的激活码";
	jhm_error_usedSameType_retresult7 = "您在1天之内已经使用过同类型的激活码";
	jhm_chouma_type_1688="铜卡VIP5日体验、1688筹码、50经验值、\n限量缤纷冰激凌商城礼品";
	jhm_chouma_type_5000W="5000W筹码";
	jhm_chouma_type_2000W="2000W筹码";
	jhm_chouma_type_1000W="1000W筹码";
	jhm_chouma_type_500W="500W筹码";
	jhm_chouma_type_200W="200W筹码";
	jhm_chouma_type_100W="100W筹码";
	jhm_chouma_type_90W="90W筹码";
	jhm_chouma_type_80W="80W筹码";
	jhm_chouma_type_70W="70W筹码";
	jhm_chouma_type_60W="60W筹码";
	jhm_chouma_type_50W="50W筹码";
	jhm_chouma_type_40W="40W筹码";
	jhm_chouma_type_30W="30W筹码";
	jhm_chouma_type_20W="20W筹码";
	jhm_chouma_type_10W="10W筹码";
	jhm_chouma_type_QQ="QQ车";
	jhm_chouma_type_Car="玛莎";
	jhm_chouma_type_Car1="奥拓";
	jhm_chouma_type_Car2="甲壳虫";
	jhm_chouma_type_youting="888W游艇";
	jhm_chouma_type_Car3="VIP银卡30天体验、雪铁龙C2一辆、\n红宝石两个";

	--tex.match.lua
	match_msg = "抱歉，参加邀请赛需要至少金卡VIP身份，请充值获取金卡VIP身份!";
	match_msg_awards_1 ="恭喜玩家";
	match_msg_awards_2 = "获得了每日%s竞技场第%d名，奖励筹码%s";
	match_msg_awards_type_1="获得了每日业余竞技场第%d名，奖励藏宝图%d张";
	match_msg_awards_type_2="获得了每日职业竞技场第%d名，奖励藏宝图%d张";
	match_msg_awards_type_3="获得了每日专家竞技场第%d名，奖励藏宝图%d张";

	match_msg_zbs_awards_type_1="获得了最强争霸赛第%d名";
	match_msg_zbs_awards_type_2="获得了最强争霸赛第%d名";
	match_msg_zbs_awards_type_3="获得了最强争霸赛第%d名";
	match_msg_noti="竞技场已火热开启，赶快加入，赢取藏宝图挖宝";
	match_msg_noti2="争霸赛已火热开启，赶快加入";

    match_msg_lz_awards_type_1="获得了龙舟竞渡业余场第%d名";
	match_msg_lz_awards_type_2="获得了龙舟竞渡职业场第%d名";
	match_msg_lz_awards_type_3="获得了龙舟竞渡专家场第%d名";
	match_msg_noti3="龙舟竞渡已火热开启，赶快加入";

	--tex.quest.lua
	quest_desc_jiangpin_1 = "德州扑克大师套装一套";
	quest_desc_jiangpin_5005 = "黑宝石一枚";
	quest_desc_jiangpin_5007 = "霸气五道杠";
	quest_desc_jiangpin_5008 = "霸气三道杠";
	quest_desc_jiangpin_5009 = "霸气二道杠";
	quest_desc_jiangpin_5010 = "霸气一道杠";
	quest_msg_jiangpin = "恭喜玩家";
	quest_msg_jiangpin_2 = "在霸气转盘中抽中限量";
	quest_msg_jiangpin_5011 = "抽中了价值188W的礼物:奥迪A8";
	quest_msg_jiangpin_5012 = "抽中了价值28.8W的礼物:甲壳虫";
	quest_msg_jiangpin_5013 = "抽中了价值1.88W的礼物:奥拓";
	quest_msg_jiangpin_5020 = "抽中了价值28W的礼物:LV包";
	quest_msg_jiangpin_5021 = "抽中了价值280W的礼物:玛莎拉蒂";
	quest_msg_jiangpin_5001 = "抽中了价值10000的礼物:蓝宝石";
	quest_msg_jiangpin_5022 = "抽中了价值2.55W的礼物:QQ车";

	quest_msg_task = "恭喜玩家";
	quest_msg_task_1 = "完成了每日任务，获得88888奖励。";

	--tex.speaker.lua
	speaker_msg = "【系统广播】：";

	--h2.lua
	h2_msg = "对不起，该IP允许的最大登入账户数超过限制，请明天再试!";
	h2_msg_1 = "可以登录";
	h2_msg_2 = "手机客户端";

	h2_msg_autojoin_1 = "对不起，您输入的桌子号码超出范围，请重新输入!";
	h2_msg_autojoin_2 = "对不起，您选择的桌子人数已满，请选择其他桌子!";
	h2_msg_autojoin_3 = "对不起，您选择的桌子需要%d级才可以进入，您等级不够!";
	h2_msg_autojoin_4 = "对不起，您选择的桌子需要VIP权限才能进入!";
	h2_msg_autojoin_5 = "对不起，请输入正确的房间ID!";

	h2_msg_givegold = "您成功领取了今日破产救济金$";
	h2_msg_givegold_1 = "每天";
	h2_msg_givegold_2 = "今天第";

	h2_msg_err_1 = "包含敏感词汇，请重新输入";
	h2_msg_err_2 = "更新成功，重新登录生效";

	--onlineprize.lua
	onlineprize_msg_1 = "对不起，活动还没开始或者已经结束!";
	onlineprize_msg_2 = "领取失败，活动还没开始或者已经结束!";
	onlineprize_msg_3 = "领取失败，您的游戏时间不足!ret=-1";
	onlineprize_msg_4 = "领取失败，您的游戏时间不足!ret=-2";
	onlineprize_msg_5 = "领取失败，您的游戏时间不足!ret=-3";

	--riddle_forgs.lua
	riddle_forgs_msg_1 = "恭喜";
	riddle_forgs_msg_2 = " 第一个猜中灯谜，获得 ";
	riddle_forgs_msg_3 = " 筹码奖励。灯谜正确答案为： ";

	--treasure_box.lua
	treasure_box_type_gold = "金宝箱";
	treasure_box_type_silver = "银宝箱";
	treasure_box_msg_1 = "恭喜";
	treasure_box_msg_2 = "开启了";
	treasure_box_msg_3 = " 获得了[";
	treasure_box_msg_4 = "]奖励。赶快进入盲注500/1000以上的房间，开启属于您的宝箱吧。";

	--za_dan.lua
	za_dan_type_primary = "初级彩蛋";
	za_dan_type_advance = "高级彩蛋";
	za_dan_msg_1 = "恭喜";
	za_dan_msg_2 = "开启了";
	za_dan_msg_3 = " 获得了[";
	za_dan_msg_4 = "]奖励。赶快进入，开启属于您的彩蛋吧。";

	--newyear_activity.lua
	newyear_activity_msg_awards_1 ="恭喜";
	newyear_activity_msg = "领取驱魔礼包，获得10万筹码！";
	newyear_activity_msg_awards = "袭击年兽，获得%d万奖励！";
	lz_activity_msg_awards = "袭击水兽，获得%d万奖励！";
	lz_activity_msg_awards1 = "袭击水兽，获得888W豪华游艇特别大奖！";

	--valentine_activity.lua
	valentine_activity_msg_awards_1 ="恭喜";
	valentine_activity_msg = "领取神秘礼包，获得10万筹码！";
	valentine_activity_msg_awards = "使用红玫瑰，获得10万奖励！";
	valentine_activity_msg_awards_2 = "使用爱心巧克力，获得20万奖励！";
	valentine_activity_msg_awards_3 = "使用爱心巧克力，获得138万玛莎拉蒂奖励！";
	valentine_activity_msg_awards_4 = "使用爱心巧克力，获得588万法拉利奖励！";

	--act_wabao_lib.lua
	act_wabao_lib_msg_5 ="恭喜";
	act_wabao_lib_msg = " 在竞技场挖宝，获得 %d万筹码！";
	act_wabao_lib_msg_1 = " 在竞技场挖宝，获得288万奔驰豪华房车奖励！";
	act_wabao_lib_msg_2 = " 在竞技场挖宝，获得588万法拉利奖励！";
	act_wabao_lib_msg_3 = " 在竞技场挖宝，获得1888万兰博基尼奖励！";
	act_wabao_lib_msg_4 = " 在竞技场挖宝，获得138万玛莎拉蒂奖励！";
}



end
