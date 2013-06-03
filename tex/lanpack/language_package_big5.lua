if not inited_lan_big5 then inited_lan_big5 = true
lan_big5=
{	
	--huodong.lua
	jhm_error="激活碼錯誤";
	jhm_error_beenUsed="激活碼已被使用";
	jhm_error_expired="激活碼過期";
	jhm_error_usedSameType="您已用過同類型的激活碼或激活碼已被使用";
	jhm_error2="激活碼驗證錯誤";

	jhm_chouma_type_688="688籌碼、30經驗值";
	jhm_chouma_type_888="銅卡VIP3日體驗、888籌碼、30經驗值";
	jhm_chouma_type_retresult24="銅卡VIP 3日體驗、1888籌碼";
	jhm_chouma_type_retresult25="銀卡VIP 3日體驗、3888籌碼";
	jhm_chouma_type_retresult26="金卡VIP 3日體驗、5888籌碼";
	jhm_chouma_type_retresult27="銅卡VIP 3日體驗、60000籌碼";
	jhm_chouma_type_retresult28="金卡VIP 3日體驗、40000籌碼";
	jhm_chouma_type_retresult29="銀卡VIP 3日體驗、75000籌碼";
	jhm_chouma_type_retresult30="銅卡VIP 3日體驗、100000籌碼";
	jhm_chouma_type_retresult31="金卡VIP 15日體驗、甲殼蟲汽車、80000籌碼";
	jhm_chouma_type_retresult32="金卡VIP 30日體驗、寶馬Z4汽車、30000籌碼";
	jhm_chouma_type_retresult33="銅卡VIP 1日體驗、10000籌碼";
	jhm_chouma_type_retresult34="銅卡VIP 1日體驗、15000籌碼";
	jhm_chouma_type_retresult35="銅卡VIP 1日體驗、15000籌碼";
	jhm_chouma_type_retresult36="銅卡VIP 1日體驗、15000籌碼";
	jhm_error_usedSameType_retresult5 = "您在7天之內已經使用過同類型的激活碼";
	jhm_error_usedSameType_retresult6 = "您在3天之內已經使用過同類型的激活碼";
	jhm_error_usedSameType_retresult7 = "您在1天之內已經使用過同類型的激活碼";
	jhm_chouma_type_1688="銅卡VIP5日體驗、1688籌碼、50經驗值、\n限量繽紛冰激淩商城禮品";
	jhm_chouma_type_5000W="5000W籌碼";
	jhm_chouma_type_2000W="2000W籌碼";
	jhm_chouma_type_1000W="1000W籌碼";
	jhm_chouma_type_500W="500W籌碼";
	jhm_chouma_type_200W="200W籌碼";
	jhm_chouma_type_100W="100W籌碼";
	jhm_chouma_type_90W="90W籌碼";
	jhm_chouma_type_80W="80W籌碼";
	jhm_chouma_type_70W="70W籌碼";
	jhm_chouma_type_60W="60W籌碼";
	jhm_chouma_type_50W="50W籌碼";
	jhm_chouma_type_40W="40W籌碼";
	jhm_chouma_type_30W="30W籌碼";
	jhm_chouma_type_20W="20W籌碼";
	jhm_chouma_type_10W="10W籌碼";
	jhm_chouma_type_QQ="QQ車";
	jhm_chouma_type_Car="瑪莎";
	jhm_chouma_type_Car1="奧拓";
	jhm_chouma_type_Car2="甲殼蟲";
	jhm_chouma_type_Car3="VIP銀卡30天體驗、雪鐵龍C2一輛、\n紅寶石兩個";
	
	--tex.match.lua
	match_msg = "抱歉，參加邀請賽需要至少金卡VIP身份，請充值獲取金卡VIP身份!";
	match_msg_awards_1 ="恭喜玩家";
	match_msg_awards_2 = "獲得了每日%s競技場第%d名，獎勵籌碼%s";
	match_msg_awards_type_1="獲得了每日業餘競技場第%d名，獎勵藏寶圖%d張";
	match_msg_awards_type_2="獲得了每日職業競技場第%d名，獎勵藏寶圖%d張";
	match_msg_awards_type_3="獲得了每日專家競技場第%d名，獎勵藏寶圖%d張";
	
	match_msg_zbs_awards_type_1="獲得了最強爭霸賽第%d名";
	match_msg_zbs_awards_type_2="獲得了最強爭霸賽第%d名";
	match_msg_zbs_awards_type_3="獲得了最強爭霸賽第%d名";
	
	match_msg_noti="競技場已火熱開啟，趕快加入，贏取藏寶圖挖寶";
	match_msg_noti2="爭霸賽已火熱開啓，趕快加入";

    match_msg_lz_awards_type_1="獲得了龍舟競渡業餘場第%d名";
	match_msg_lz_awards_type_2="獲得了龍舟競渡職業場第%d名";
	match_msg_lz_awards_type_3="獲得了龍舟競渡專家場第%d名";
	match_msg_noti3="龍舟競渡已火熱開啟，趕快加入";
	
	
	--tex.quest.lua
	quest_desc_jiangpin_1 = "德州撲克大師套裝一套";
	quest_desc_jiangpin_5005 = "黑寶石一枚";
	quest_desc_jiangpin_5007 = "霸氣五道杠";
	quest_desc_jiangpin_5008 = "霸氣三道杠";
	quest_desc_jiangpin_5009 = "霸氣二道杠";
	quest_desc_jiangpin_5010 = "霸氣一道杠";
	quest_msg_jiangpin = "恭喜玩家";
	quest_msg_jiangpin_2 = "在霸氣轉盤中抽中限量";
	quest_msg_jiangpin_5011 = "抽中了價值188W的禮物:奧迪A8";
	quest_msg_jiangpin_5012 = "抽中了價值28.8W的禮物:甲殼蟲";
	quest_msg_jiangpin_5013 = "抽中了價值1.88W的禮物:奧拓";
	quest_msg_jiangpin_5020 = "抽中了價值28W的禮物:LV包";
	quest_msg_jiangpin_5021 = "抽中了價值280W的禮物:瑪莎拉蒂";
	quest_msg_jiangpin_5001 = "抽中了價值10000的禮物:藍寶石";
	quest_msg_jiangpin_5022 = "抽中了價值2.55W的禮物:QQ車";
	
	quest_msg_task = "恭喜玩家";
	quest_msg_task_1 = "完成了每日任務，獲得88888獎勵。";
	
	--tex.speaker.lua
	speaker_msg = "【系統廣播】：";
	
	--h2.lua
	h2_msg = "對不起，該IP允許的最大登入賬戶數超過限制，請明天再試!";
	h2_msg_1 = "可以登錄";
	h2_msg_2 = "手機客戶端";
	
	h2_msg_autojoin_1 = "對不起，您輸入的桌子號碼超出範圍，請重新輸入!";
	h2_msg_autojoin_2 = "對不起，您選擇的桌子人數已滿，請選擇其他桌子!";
	h2_msg_autojoin_3 = "對不起，您選擇的桌子需要%d級才可以進入，您等級不夠!";
	h2_msg_autojoin_4 = "對不起，您選擇的桌子需要VIP權限才能進入!";
	h2_msg_autojoin_5 = "對不起，請輸入正確的房間ID!";
	
	h2_msg_givegold = "您成功領取了今日破產救濟金$";
	h2_msg_givegold_1 = "每天"; 
	h2_msg_givegold_2 = "今天第"; 
	
	h2_msg_err_1 = "包含敏感詞匯，請重新輸入";
	h2_msg_err_2 = "更新成功，重新登錄生效";
	
	--onlineprize.lua
	onlineprize_msg_1 = "對不起，活動還沒開始或者已經結束!";
	onlineprize_msg_2 = "領取失敗，活動還沒開始或者已經結束!";
	onlineprize_msg_3 = "領取失敗，您的遊戲時間不足!ret=-1";
	onlineprize_msg_4 = "領取失敗，您的遊戲時間不足!ret=-2";
	onlineprize_msg_5 = "領取失敗，您的遊戲時間不足!ret=-3";
	
	--riddle_forgs.lua
	riddle_forgs_msg_1 = "恭喜";
	riddle_forgs_msg_2 = " 第一個猜中燈謎，獲得 ";
	riddle_forgs_msg_3 = " 籌碼獎勵。燈謎正確答案為： ";
	
	--treasure_box.lua
	treasure_box_type_gold = "金寶箱";
	treasure_box_type_silver = "銀寶箱";
	treasure_box_msg_1 = "恭喜";
	treasure_box_msg_2 = "開啟了";
	treasure_box_msg_3 = " 獲得了[";
	treasure_box_msg_4 = "]獎勵。趕快進入盲注500/1000以上的房間，開啟屬於您的寶箱吧。";
	
	--za_dan.lua
	za_dan_type_primary = "初級彩蛋";
	za_dan_type_advance = "高級彩蛋";
	za_dan_msg_1 = "恭喜";
	za_dan_msg_2 = "開啟了";
	za_dan_msg_3 = " 獲得了[";
	za_dan_msg_4 = "]獎勵。趕快進入，開啟屬於您的彩蛋吧。";
	
	--newyear_activity.lua
	newyear_activity_msg_awards_1 ="恭喜";
	newyear_activity_msg = "領取驅魔禮包，獲得10萬籌碼！";
	newyear_activity_msg_awards = "襲擊年獸，獲得%d萬獎勵！";
    lz_activity_msg_awards = "襲擊水獸，獲得%d萬獎勵！";
	
	--valentine_activity.lua
	valentine_activity_msg_awards_1 ="恭喜";
	valentine_activity_msg = "領取神秘禮包，獲得10萬籌碼！";
	valentine_activity_msg_awards = "使用紅玫瑰，獲得10萬獎勵！";
	valentine_activity_msg_awards_2 = "使用愛心巧克力，獲得20萬獎勵！";
	valentine_activity_msg_awards_3 = "使用愛心巧克力，獲得138萬瑪莎拉蒂獎勵！";
	valentine_activity_msg_awards_4 = "使用愛心巧克力，獲得588萬法拉利獎勵！";
	
	--act_wabao_lib.lua 
	act_wabao_lib_msg_5 ="恭喜";
	act_wabao_lib_msg = " 在競技場挖寶，獲得 %d萬籌碼！"; 
	act_wabao_lib_msg_1 = " 在競技場挖寶，獲得288萬奔馳豪華房車獎勵！";
	act_wabao_lib_msg_2 = " 在競技場挖寶，獲得588萬法拉利獎勵！";
	act_wabao_lib_msg_3 = " 在競技場挖寶，獲得1888萬蘭博基尼獎勵！"; 
	act_wabao_lib_msg_4 = " 在競技場挖寶，獲得138萬瑪莎拉蒂獎勵！";
	
}



end
