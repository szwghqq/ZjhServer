dofile("games/gift_gold_type.lua")	--金币类型
dofile("games/tex/tex.viproom.lua")--vip房间检查

--dofile("games/modules/lottery_activity.lua")	--元旦后抽奖活动
--dofile("games/modules/newyear_activity.lua")	--春节活动
--dofile("games/tex/tex.match.lua")				--竞技场
--dofile("games/modules/valentine_activity.lua")	--情人节活动
--dofile("games/modules/huodong/act_macth.lua")	--竞技场
--dofile("games/modules/huodong/act_macth_zbs.lua")	--争霸赛竞技场
--dofile("games/modules/huodong/act_wabao.lua")	--挖宝活动
--dofile("games/modules/huodong/act_macth_longzhou.lua")	--龙舟活动
--dofile("games/modules/huodong/act_water_bean.lua")	--端午水兽活动 
--dofile("games/modules/huodong/act_wabao_new.lua");
--dofile("games/modules/huodong/act_wabao_new_db.lua");
--春节活动加载文件
dofile("games/modules/huodong/20130204new_year/config_new_year.lua")
dofile("games/modules/huodong/20130204new_year/new_year.lua")
dofile("games/modules/huodong/20130204new_year/new_year_db.lua")
--加载情人节活动
dofile("games/modules/huodong/20130214loverday/config_for_yuandan.lua")
dofile("games/modules/huodong/20130214loverday/yuandan_lib.lua")
dofile("games/modules/huodong/20130214loverday/yuandan_lib_db.lua")

	
dofile("games/modules/huodong/choujiang_tools.lua")	--金币类型

--dofile("games/modules/gold_cow_db.lua")
--dofile("games/modules/gold_cow.lua")

--dofile("games/modules/super_cow_db.lua")
--dofile("games/modules/super_cow.lua")
--dofile("games/modules/super_cow_gm.lua")
--dofile("games/modules/huodong/football.lua")
--dofile("games/modules/huodong/football_db.lua")

--dofile("games/modules/huodong/ol_za_dan.lua")
--dofile("games/modules/za_dan.lua")

dofile("games/modules/chat_tools.lua")

dofile("games/modules/car/car_match.lua");
dofile("games/modules/car/car_match_db.lua");
dofile("games/modules/car/car_match_gm.lua");
dofile("games/modules/car/car_match_sj.lua");
dofile("games/modules/car/car_match_sj_db.lua");
dofile("games/modules/car/car_shop.lua");
dofile("games/modules/car/car_shop_db.lua");
dofile("games/modules/car/parking_system.lua");
dofile("games/modules/car/parking_system_db.lua");

--dofile("games/modules/signin_system.lua")--签到系统
--dofile("games/modules/user_sign_db.lua")--签到系统
dofile("games/modules/task.lua");
dofile("games/modules/task_db.lua");
--dofile("games/modules/huodong/zhounianqin_huodong.lua")
--dofile("games/modules/huodong/zhounianqin_huodong_db.lua")

--中秋活动加载文件
dofile("games/modules/hecheng.lua")--合成系统
dofile("games/modules/hecheng_db.lua")--合成系统
--dofile("games/modules/huodong/texas_zhongqiu.lua")
--dofile("games/modules/huodong/texas_zhongqiu_db.lua")

--dofile("games/modules/huodong/dyd_huodong.lua")
--dofile("games/modules/huodong/dyd_huodong_db.lua")
dofile("games/modules/daxiao/daxiao.adapter.lua") --加运维参数配置

dofile("games/modules/config_for_yunyin.lua") --加运维参数配置
dofile("games/modules/chenghao.lua") --称号模块


--dofile("games/modules/matches.lua");
--dofile("games/modules/matches_db.lua");
--dofile("games/modules/matches_taotai.lua");


dofile("games/modules/tex_wms_adapter.lua")  --仓储系统接口
dofile("games/modules/new_shop.lua")
dofile("games/modules/new_shop_db.lua")
dofile("games/modules/mobile.lua") --手机的处理
dofile("games/modules/config_for_yunyin.lua") --加运维参数配置

--高倍场掉落
dofile("games/modules/huodong/20130110gaobei_diaoluo/config_for_gaobei_diaoluo.lua") --德州高倍场掉落活动配置
dofile("games/modules/huodong/20130110gaobei_diaoluo/gaobei_diaoluo_lib.lua") --德州高倍场掉落活动

--充值送装配箱子
dofile("games/modules/huodong/20120503pay_give_box/config_pay_give_car.lua") --豪车升级狂欢派对活动需求
dofile("games/modules/huodong/20120503pay_give_box/pay_give_car.lua") --豪车升级狂欢派对活动需求

--加载爵位翅膀系统
dofile("games/modules/huodong/20130331wing_system/config_wing_lib.lua") --爵位系统配置
dofile("games/modules/huodong/20130331wing_system/wing_lib.lua") --爵位系统配置
dofile("games/modules/huodong/20130331wing_system/wing_lib_db.lua") --爵位系统配置