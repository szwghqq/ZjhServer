TraceError("init tex_wms_adapter_lib....")

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_after_user_login) then
    eventmgr:removeEventListener("h2_on_user_login", tex_wms_adapter_lib.on_after_user_login)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.timer) then
    eventmgr:removeEventListener("timer_second", tex_wms_adapter_lib.timer);
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.after_get_props_list) then
    eventmgr:removeEventListener("after_get_props_list", tex_wms_adapter_lib.after_get_props_list)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_game_over_event) then
    eventmgr:removeEventListener("game_event_ex", tex_wms_adapter_lib.on_game_over_event)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_user_add_gold) then
    eventmgr:removeEventListener("on_user_add_gold", tex_wms_adapter_lib.on_user_add_gold)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_get_safe_gold_info) then
    eventmgr:removeEventListener("on_get_safebox_info", tex_wms_adapter_lib.on_get_safe_gold_info)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_get_safe_gold_change) then
    eventmgr:removeEventListener("on_safebox_sq", tex_wms_adapter_lib.on_get_safe_gold_change)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.restart_server) then
    eventmgr:removeEventListener("on_server_start", tex_wms_adapter_lib.restart_server)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_after_init_car) then
    eventmgr:removeEventListener("finish_init_car", tex_wms_adapter_lib.on_after_init_car)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_after_init_parking) then
    eventmgr:removeEventListener("already_init_parking", tex_wms_adapter_lib.on_after_init_parking)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_after_init_yinpiao) then
    eventmgr:removeEventListener("already_init_yinpiao", tex_wms_adapter_lib.on_after_init_yinpiao)
end

if (tex_wms_adapter_lib and tex_wms_adapter_lib.on_user_change_coupon) then
    eventmgr:removeEventListener("on_user_change_coupon", tex_wms_adapter_lib.on_user_change_coupon)
end


tex_wms_adapter_lib = tex_wms_adapter_lib or {}
tex_wms_adapter_lib.gift_cfg = 
        {
            
            [0] = "筹码",
            [1] = "踢人卡",
            [2] = "全服喇叭",
            [3] = "方舟资格证书",
            [4] = "鞭炮",
            [5] = "烟花",
            [6] = "礼炮",
            [7] = "竞技场门票",
            [8] = "爱心巧克力",
            [9] = "藏宝图",  
            [10] = "钻石礼券",
            [14] = "木宝箱",
            [15] = "铁宝箱",
            [16] = "铜宝箱",
            [17] = "银宝箱",
            [18] = "金宝箱",
            [19] = "半盒香烟",
            [20] = "一瓶啤酒",
            [21] = "鲜榨果汁",
            [22] = "一小包零食",
            [23] = "红玫瑰",
            [24] = "粉玫瑰",
            [25] = "紫水晶",
            [26] = "蓝冰钻",
            [27] = "骑士翅膀",
            [28] = "准男爵翅膀",
            [29] = "男爵翅膀",
            [30] = "子爵翅膀",
            [31] = "伯爵翅膀",
            [32] = "侯爵翅膀",
            [33] = "公爵翅膀",
            [34] = "亲王翅膀",
            [35] = "国王翅膀",
            [36] = "爵位羽毛" ,
            [998]  = "三分钟赠票",
            [999]  = "三分钟银票",
            [1000] = "保险箱筹码",
            [1001] = "鲜の果汁",
            [1002] = "中式凉茶",
            [1003] = "可乐",
            [1004] = "啤酒",
            [1005] = "好汉酒",
            [1006] = "鸡尾酒",
            [1007] = "咖啡",
            [1008] = "威士忌",
            [1009] = "波尔多红酒",
            [1010] = "哈根达斯",
            [2001] = "疯狂烤鸡腿",
            [2002] = "灌汤小笼包",
            [2003] = "精致糕点",
            [2004] = "美味汉堡",
            [2005] = "美味拉面",
            [2006] = "美味肉荚膜",
            [2007] = "西瓜",
            [2008] = "巧克力蛋糕",
            [2009] = "三文鱼寿司",
            [2010] = "棒棒糖",
            [3001] = "雪茄",
            [3002] = "香烟",
            [3003] = "中式水烟",
            [3004] = "ZIPPO",
            [4001] = "玫瑰",
            [4002] = "弥勒佛",
            [4003] = "观音姐姐",
            [4004] = "招财神兽",
            [4005] = "中国娃娃",
            [4006] = "招财猫",
            [4007] = "招财金猪",
            [4008] = "一帆风顺",
            [4009] = "无敌幸运星",
            [4010] = "天下第一剑",
            [4011] = "绅士",
            [4012] = "晴天娃娃",
            [4013] = "吉祥锁",
            [4014] = "吉祥红包",
            [4015] = "皇冠",
            [4016] = "福禄双全",
            [4017] = "八卦图",
            [4018] = "发财护身符",
            [4019] = "幸运天使",
            [4020] = "恶魔",
            [4021] = "小财神",
            [4022] = "穷神附体",
            [4026] = "单身帅哥",
            [4027] = "单身美女",
            [5001] = "蓝宝石",
            [5002] = "绿宝石",
            [5003] = "黄宝石",
            [5004] = "红宝石",
            [5005] = "黑宝石",
            [5006] = "甜蜜之心",
            [9001] = "圣诞老人的臭袜子",
            [9002] = "红色冬帽",
            [9003] = "绿色冬帽",
            [9004] = "新年礼物-鞭炮",
            [9005] = "新年礼物-福到",
            [9006] = "新年礼物-金元宝",
            [9007] = "冰淇淋",
            [9008] = "任务达人标志",
            [9009] = "初级王者勋章",
            [9010] = "中级王者勋章",
            [9011] = "高级王者勋章",
            [9012] = "圣诞火鸡礼物",
            [9013] = "圣诞树礼物",
            [9014] = "“福”礼物",
            [9015] = "“红灯笼”礼物",
            [4023] = "关公",
            [4024] = "老神仙",
            [4025] = "葫芦仙",
            [5007] = "霸气五道杠",
            [5008] = "霸气三道杠",
            [5009] = "霸气二道杠",
            [5010] = "霸气一道杠",
            [5014] = "幸运符：财",
            [5015] = "幸运符：旺",
            [5016] = "幸运符：运",
            [5035] = "新手勋章",
            [5020] = "动感LV包",
            [5013] = "奥拓",
            [5022] = "奇瑞 QQ3",
            [5019] = "夏利 N5",
            [5018] = "雪铁龙 C2",
            [5012] = "甲壳虫",
            [5011] = "奥迪A8L",
            [5017] = "奔驰S600",
            [5021] = "玛莎拉蒂 总裁",
            [5024] = "法拉利 599",
            [5025] = "保时捷 Panamera",
            [5026] = "兰博基尼 Aventador",
            [5027] = "布加迪威龙 威航",
            [5030] = "丰田雅力士1.6GS",
            [5031] = "海马爱尚 1.0L",
            [5032] = "奇瑞瑞麟M5 1.3L",
            [5033] = "福克斯2.0L",
            [5034] = "铃木新奥拓1.0L",
            [5036] = "布加迪威龙 威航(黄金版)",
            [5037] = "Zenvo  ST1",
            [5038] = "莲花 2-Eleven",
            [5039] = "兰博基尼德州周年纪念版",
            [5040] = "保时捷德州周年纪念版",
            [5041] = "法拉利德州周年纪念版",
            [5042] = "神秘车",
            [5044] = "永久牌自行车",
            [5045] = "凤凰牌自行车",
            [5043] = "天津大发面的",
            [5046] = "高尔夫",
            [5047] = "英菲尼迪G",
            [5048] = "捷豹XF",
            [5049] = "宝马Z4",
            [5050] = "宾利慕尚",
            [5051] = "科鲁兹",
            [5023] = "游艇",
            [9023] = "冠军荣誉戒指",
            [61001] = "露天车库1",
            [62001] = "地下车库1",
            [63001] = "私家车库1",
            [64001] = "私家游艇1",
            [9016] = "红心礼物",
            [9017] = "红唇礼物",
            [9018] = "墓碑",
            [9019] = "幽灵",
            [9020] = "木乃伊",
            [9021] = "野兽",
            [9022] = "火辣girl",
            [9024] = "性感美女",
            [9025] = "水着美女",
            [5028] = "白银龙舟",
            [5029] = "黄金龙舟",
            [5301] = "晶月祝福",
            [5302] = "雅月祝福",
            [5303] = "素月祝福",
            [100020] = "晶月祝福图纸",
            [100021] = "雅月祝福图纸",
            [100022] = "素月祝福图纸",
            [100100] = "老奥拓图纸",
            [100101] = "老雪铁龙C2图纸",
            [100102] = "老甲壳虫图纸",
            [100103] = "老玛莎拉蒂图纸",
            [100104] = "老法拉利图纸",
            [100105] = "奥拓图纸1",
            [100106] = "奥拓图纸2",
            [100107] = "奥拓图纸3",
            [100108] = "雪铁龙图纸",
            [100109] = "甲壳虫图纸",
            [100110] = "玛莎拉蒂图纸",
            [100111] = "法拉利图纸",
            [100112] = "兰博基尼图纸",
            [100113] = "布加迪威龙图纸",
            [100114] = "布加迪威龙(黄金版)图纸",
            [100115] = "神秘车图纸",
            [100116] = "永久牌自行车图纸",
            [100117] = "凤凰牌自行车图纸",
            [100118] = "浪漫玫瑰礼盒卷轴",
            [100119] = "奢华晶钻礼盒卷轴",
            [200001] = "缤纷道具盒",
            [200002] = "普通赛冠军宝箱",
            [200003] = "名车赛冠军宝箱",
            [200004] = "铜宝箱",
            [200005] = "银宝箱",
            [200006] = "金宝箱",
            [200007] = "末日口粮",
            [200008] = "泉水",
            [200009] = "红包",
            [200010] = "宝石袋",
            [200011] = "道具箱",
            [200012] = "卷轴盒",
            [200013] = "车钥匙",
            [200014] = "浪漫玫瑰礼盒",
            [200015] = "奢华晶钻礼盒",            
            [200016] = "白银钥匙",
						[200017] = "黄金钥匙",					
						[200018] = "水晶钥匙",
						[200019] = "普通配件箱", 
						[200020] = "白银配件箱", 
						[200021] = "黄金配件箱", 
						[200022] = "百变道具卡", 
						[200027] = "成长勋章",          
        }
tex_wms_adapter_lib.gift_cfg_buy_sell = {
            [1001] = "鲜の果汁",
            [1002] = "中式凉茶",
            [1003] = "可乐",
            [1004] = "啤酒",
            [1005] = "好汉酒",
            [1006] = "鸡尾酒",
            [1007] = "咖啡",
            [1008] = "威士忌",
            [1009] = "波尔多红酒",
            [1010] = "哈根达斯",
            [2001] = "疯狂烤鸡腿",
            [2002] = "灌汤小笼包",
            [2003] = "精致糕点",
            [2004] = "美味汉堡",
            [2005] = "美味拉面",
            [2006] = "美味肉荚膜",
            [2007] = "西瓜",
            [2008] = "巧克力蛋糕",
            [2009] = "三文鱼寿司",
            [2010] = "棒棒糖",
            [3001] = "雪茄",
            [3002] = "香烟",
            [3003] = "中式水烟",
            [3004] = "ZIPPO",
            [4001] = "玫瑰",
            [4002] = "弥勒佛",
            [4003] = "观音姐姐",
            [4004] = "招财神兽",
            [4005] = "中国娃娃",
            [4006] = "招财猫",
            [4007] = "招财金猪",
            [4008] = "一帆风顺",
            [4009] = "无敌幸运星",
            [4010] = "天下第一剑",
            [4011] = "绅士",
            [4012] = "晴天娃娃",
            [4013] = "吉祥锁",
            [4014] = "吉祥红包",
            [4015] = "皇冠",
            [4016] = "福禄双全",
            [4017] = "八卦图",
            [4018] = "发财护身符",
            [4019] = "幸运天使",
            [4020] = "恶魔",
            [4021] = "小财神",
            [4022] = "穷神附体",
            [4026] = "单身帅哥",
            [4027] = "单身美女",
            [5001] = {"蓝宝石",10000,9500},
            [5002] = {"绿宝石",50000,4750},
            [5003] = {"黄宝石",100000,95000},
            [5004] = {"红宝石",500000,47500},
            [5005] = {"黑宝石",1000000,950000},
            [5006] = "甜蜜之心",
            [9001] = "圣诞老人的臭袜子",
            [9002] = "红色冬帽",
            [9003] = "绿色冬帽",
            [9004] = "新年礼物-鞭炮",
            [9005] = "新年礼物-福到",
            [9006] = "新年礼物-金元宝",
            [9007] = "冰淇淋",
            [9008] = "任务达人标志",
            [9009] = "初级王者勋章",
            [9010] = "中级王者勋章",
            [9011] = "高级王者勋章",
            [9012] = "圣诞火鸡礼物",
            [9013] = "圣诞树礼物",
            [9014] = "“福”礼物",
            [9015] = "“红灯笼”礼物",
            [4023] = "关公",
            [4024] = "老神仙",
            [4025] = "葫芦仙",
            [5007] = "霸气五道杠",
            [5008] = "霸气三道杠",
            [5009] = "霸气二道杠",
            [5010] = "霸气一道杠",
            [5014] = "幸运符：财",
            [5015] = "幸运符：旺",
            [5016] = "幸运符：运",
            [5035] = "新手勋章",
            [5020] = "动感LV包",
            [5013] = "奥拓",
            [5022] = "奇瑞 QQ3",
            [5019] = "夏利 N5",
            [5018] = "雪铁龙 C2",
            [5012] = "甲壳虫",
            [5011] = "奥迪A8L",
            [5017] = "奔驰S600",
            [5021] = "玛莎拉蒂 总裁",
            [5024] = "法拉利 599",
            [5025] = "保时捷 Panamera",
            [5026] = "兰博基尼 Aventador",
            [5027] = "布加迪威龙 威航",
            [5030] = "丰田雅力士1.6GS",
            [5031] = "海马爱尚 1.0L",
            [5032] = "奇瑞瑞麟M5 1.3L",
            [5033] = "福克斯2.0L",
            [5034] = "铃木新奥拓1.0L",
            [5036] = "布加迪威龙 威航(黄金版)",
            [5037] = "Zenvo  ST1",
            [5038] = "莲花 2-Eleven",
            [5039] = "兰博基尼德州周年纪念版",
            [5040] = "保时捷德州周年纪念版",
            [5041] = "法拉利德州周年纪念版",
            [5042] = "神秘车",
            [5044] = "永久牌自行车",
            [5045] = "凤凰牌自行车",
            [5043] = "天津大发面的",
            [5046] = "高尔夫",
            [5047] = "英菲尼迪G",
            [5048] = "捷豹XF",
            [5049] = "宝马Z4",
            [5050] = "宾利慕尚",
            [5051] = "科鲁兹",
            [5023] = "游艇",
            [9023] = "冠军荣誉戒指",
            [61001] = "露天车库1",
            [62001] = "地下车库1",
            [63001] = "私家车库1",
            [64001] = "私家游艇1",
            [9016] = "红心礼物",
            [9017] = "红唇礼物",
            [9018] = "墓碑",
            [9019] = "幽灵",
            [9020] = "木乃伊",
            [9021] = "野兽",
            [9022] = "火辣girl",
            [9024] = "性感美女",
            [9025] = "水着美女",
            [5028] = "白银龙舟",
            [5029] = "黄金龙舟",
            [1] = {"踢人卡",0},
            [2] = {"全服喇叭",0},
            [3] = "方舟资格证书",
            [4] = "鞭炮",
            [5] = "烟花",
            [6] = "礼炮",
            [7] = "竞技场门票",
            [8] = "爱心巧克力",
            [9] = "藏宝图",
            [5301] = "晶月祝福",
            [5302] = "雅月祝福",
            [5303] = "素月祝福",
            [14] = "木宝箱",
            [15] = "铁宝箱",
            [16] = "铜宝箱",
            [17] = "银宝箱",
            [18] = "金宝箱",
            [19] = "半盒香烟",
            [20] = "一瓶啤酒",
            [21] = "鲜榨果汁",
            [22] = "一小包零食",
            [23] = "红玫瑰",
            [24] = "粉玫瑰",
            [25] = "紫水晶",
            [26] = "蓝冰钻",
            [100020] = "晶月祝福图纸",
            [100021] = "雅月祝福图纸",
            [100022] = "素月祝福图纸",
            [100100] = "老奥拓图纸",
            [100101] = "老雪铁龙C2图纸",
            [100102] = "老甲壳虫图纸",
            [100103] = "老玛莎拉蒂图纸",
            [100104] = "老法拉利图纸",
            [100105] = "老保时捷图纸",
            [100106] = "老兰博基尼图纸",
            [100107] = "奥拓图纸",
            [100108] = "雪铁龙图纸",
            [100109] = {"甲壳虫图纸",88000},
            [100110] = {"玛莎拉蒂图纸",580000},
            [100111] = {"法拉利图纸",880000},
            [100112] = {"兰博基尼图纸",2880000},
            [100113] = {"布加迪威龙图纸",5880000},
            [100114] = {"布加迪威龙(黄金版)图纸",8880000},
            [100115] = {"神秘车图纸",88880000},
            [100116] = "永久牌自行车图纸",
            [100117] = "凤凰牌自行车图纸",
            [100118] = "浪漫玫瑰礼盒卷轴",
            [100119] = "奢华晶钻礼盒卷轴",
            [200001] = {"缤纷道具盒",58800},
            [200002] = "普通赛冠军宝箱",
            [200003] = "名车赛冠军宝箱",
            [200004] = "铜宝箱",
            [200005] = "银宝箱",
            [200006] = "金宝箱",
            [200007] = "末日口粮",
            [200008] = "泉水",
            [200009] = "红包",
            [200010] = "宝石袋",
            [200011] = "道具箱",
            [200012] = "卷轴盒",
            [200013] = "车钥匙",
            [200014] = "浪漫玫瑰礼盒",
            [200015] = "奢华晶钻礼盒",
            [200016] = "白银钥匙",
						[200017] = "黄金钥匙",					
						[200018] = "水晶钥匙",            
						[200027] = "成长勋章",
            [10] = "钻石礼券",
            [0] = "筹码",  
        }
tex_wms_adapter_lib.gold_type = tex_wms_adapter_lib.gold_type or {}
tex_wms_adapter_lib.last_unique_num = 0 --上一次的唯一数，用于创建唯一数字
tex_wms_adapter_lib.last_clock = 1 --上一次毫秒数
tex_wms_adapter_lib.max_pay_id = 200000000000
tex_wms_adapter_lib.max_user_id = 200000000000
tex_wms_adapter_lib.process_pay_ok = 1
tex_wms_adapter_lib.process_user_reg_ok = 1
tex_wms_adapter_lib.reg_site = tex_wms_adapter_lib.reg_site or {} --用户来自地方



function tex_wms_adapter_lib.restart_server(e)    
    for k, v in pairs(hall.gold_type) do
        tex_wms_adapter_lib.gold_type[v.id] = v.des
    end
    local sql = "select * from reg_site"
    dblib.execute(sql, function(dt)
        if (dt and #dt > 0) then
            for k, v in pairs(dt) do
                tex_wms_adapter_lib.reg_site[v.site_no] = v.site_name
            end
        end
    end)
    
end

--获取系统日期
function tex_wms_adapter_lib.get_day(time)
    return os.date("%Y_%m_%d", time or os.time())
end

function tex_wms_adapter_lib.lua_to_oracle_time(lua_time)
    return os.date("%Y%m%d%H%M%S", lua_time or os.time())
end

--用户登陆
function tex_wms_adapter_lib.on_after_user_login(e)
    local cur_time = os.time()
    local user_info = e.data["user_info"]
    --更新用户信息
    local user_nick = " "
    if (user_info.nick ~= "") then
        user_nick = user_info.nick
    end
    local sql = "select sys_time, reg_site_no, reg_ip from users where id = %d"
    sql = string.format(sql, user_info.userId)
    dblib.execute(sql, function(dt)
        --获取用户注册时间
        local reg_time = tex_wms_adapter_lib.lua_to_oracle_time(cur_time)
        if (dt and #dt > 0) then
            reg_time = tex_wms_adapter_lib.lua_to_oracle_time(tonumber(timelib.db_to_lua_time(dt[1].sys_time)))
        end
        local reg_site_name = tex_wms_adapter_lib.reg_site[dt[1].reg_site_no] or dt[1].reg_site_no
        local reg_ip = dt[1].reg_ip
        if (reg_ip == " ") then
            reg_ip = " "
        end
        sql = "insert into tex_wms.dozen_pub_dz_player_%s(playerid,playername,createtm,regip,activation,\
                lastgametm,lastloginip,passport,platformid,platformname)values(%d,'%s','%s','%s',%d,'%s','%s','%s','%s','%s')"
        sql = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, user_nick, 
                            reg_time, reg_ip, 1, tex_wms_adapter_lib.lua_to_oracle_time(cur_time), 
                            user_info.ip, user_info.passport or " ", dt[1].reg_site_no, reg_site_name)
        dblib.execute(sql)        
        --更新用户礼物信息
        local user_gift_info = deskmgr.getuserdata(user_info).giftinfo or {}
        if (#user_gift_info > 0) then
            sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                        reltime)values(%d,'%s',%d,'%s',%d,'%s')"
            local gift_info = {}
            for k, v in pairs(user_gift_info) do            
                if (gift_info[v.id] == nil) then
                    gift_info[v.id] = {count = 0, name = " "}
                end
                gift_info[v.id].count = gift_info[v.id].count + 1
                gift_info[v.id].name = tex_wms_adapter_lib.gift_cfg[v.id] or v.id                
            end
            local user_nick = " "
            if (user_info.nick ~= "") then
                user_nick = user_info.nick
            end            
            for k, v in pairs(gift_info) do
                local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, 
                                               user_nick, k, _U(v.name), v.count, tex_wms_adapter_lib.lua_to_oracle_time())
                dblib.execute(sql_info)
            end
        end
        --增加用户筹码信息
        local gift_info = {}
        gift_info[0] = {count = user_info.gamescore, name = tex_wms_adapter_lib.gift_cfg[0]}
        for k, v in pairs(gift_info) do
            local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, 
                                           user_nick, k, _U(v.name), v.count, tex_wms_adapter_lib.lua_to_oracle_time())
            dblib.execute(sql_info)
        end
    end)
    --增加用户筹码
    local gift_info = {}
    gift_info[0] = {count = user_info.gamescore, name = tex_wms_adapter_lib.gift_cfg[0]}
    for k, v in pairs(gift_info) do
        local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, 
                                       user_nick, k, _U(v.name), v.count, tex_wms_adapter_lib.lua_to_oracle_time())
        dblib.execute(sql_info)
    end
end

--更新用户礼物信息
function tex_wms_adapter_lib.after_get_props_list(e)
    --更新用户道具信息    
    local user_info = usermgr.GetUserById(e.data["user_id"])
    if (user_info == nil) then
        return
    end
    local user_prop_info = user_info.propslist or {}
    if (#user_prop_info > 0) then
        sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                    reltime)values(%d,'%s',%d,'%s',%d,'%s')"
        local prop_info = {}
        for k, v in pairs(user_prop_info) do            
            if (prop_info[k] == nil and v ~= 0) then
                prop_info[k] = {count = v, name = tex_wms_adapter_lib.gift_cfg[k] or k}
            end
        end
        local user_nick = " "
        if (user_info.nick ~= "") then
            user_nick = user_info.nick
        end
        for k, v in pairs(prop_info) do
            local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, 
                                           user_nick, k, _U(v.name), v.count, 
                                           tex_wms_adapter_lib.lua_to_oracle_time())
            dblib.execute(sql_info)
        end
    end
end


function tex_wms_adapter_lib.on_after_init_car(e)
    local user_id = e.data["user_id"]
    if (user_id  == nil) then
        return
    end
    sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                    reltime)values(%d,'%s',%d,'%s',%d,'%s')"
    local gift_info = {}
    if car_match_lib.user_list[user_id].car_list then
      for k, v in pairs(car_match_lib.user_list[user_id].car_list) do            
          if (gift_info[v.car_type] == nil) then
              gift_info[v.car_type] = {count = 0, name = " "}
          end
          gift_info[v.car_type].count = gift_info[v.car_type].count + 1
          gift_info[v.car_type].name = tex_wms_adapter_lib.gift_cfg[v.car_type] or v.car_type
      end
    local user_nick = " "
      local user_info = usermgr.GetUserById(user_id)
      if (user_info ~= nil and user_info.nick ~= "") then
          user_nick = user_info.nick
      end
      for k, v in pairs(gift_info) do
       
          local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_id, 
                                         user_nick, k, _U(v.name), v.count, tex_wms_adapter_lib.lua_to_oracle_time())
          dblib.execute(sql_info)
        
    end
  end
   
end


function tex_wms_adapter_lib.on_after_init_parking(e)
      --记录车位信息
    local parking_info = {}
    local parking_data = parkinglib.user_list[e.data.user_id]
    local parking_list = parking_data.parking_list
    local user_nick = " "
    local user_id = e.data.user_id
    local user_info = usermgr.GetUserById(user_id)
    if (user_info ~= nil and user_info.nick ~= "") then
        user_nick = user_info.nick
    end
    local tb_car_type = {61001,62001,63001,64001}
    sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                    reltime)values(%d,'%s',%d,'%s',%d,'%s')"
    for k,v in pairs (parking_list) do
      if v.parking_count and  v.parking_count > 0 then
        local sql2 = string.format(sql, tex_wms_adapter_lib.get_day(), user_id, 
                         user_nick, tb_car_type[k], _U(tex_wms_adapter_lib.gift_cfg[tb_car_type[k]]), v.parking_count, tex_wms_adapter_lib.lua_to_oracle_time())
        dblib.execute(sql2)
      end
    end
end

function tex_wms_adapter_lib.on_after_init_yinpiao(e)
     --记录车位信息
    local user_nick = " "
    local user_id = e.data.user_id
    local user_info = daxiao_hall.get_user_info(user_id)
    if (user_info ~= nil and user_info.nick ~= "") then
        user_nick = user_info.nick
    end
    local yinpiao_count = e.data.yinpiao_count
    local ex_yinpiao_count = e.data.ex_yinpiao_count
    sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                reltime)values(%d,'%s',%d,'%s',%d,'%s')"
    
    local sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), user_id, 
                     user_nick, 999, _U(tex_wms_adapter_lib.gift_cfg[999]), yinpiao_count, tex_wms_adapter_lib.lua_to_oracle_time())
    dblib.execute(sql1)
    
    local sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), user_id, 
                     user_nick, 998, _U(tex_wms_adapter_lib.gift_cfg[998]), ex_yinpiao_count, tex_wms_adapter_lib.lua_to_oracle_time())
    dblib.execute(sql1)
    
end
function tex_wms_adapter_lib.on_user_change_coupon(e)
    local businessname = "礼券交易"
    local user_id =  e.data["user_id"]
    local to_user_id =  e.data["to_user_id"] or user_id
    local add_gool_id = e.data["gools_id"] or 0 
    local add_gool_num = e.data["gift_count"]
    local bet_count = e.data["smallbet"] or " "
    local coupon_num = e.data["coupon_num"]
    if not tex_wms_adapter_lib.gift_cfg_buy_sell[add_gool_id][2] then
        TraceError("礼券商城该物品没有配置改物品价值，请配置，谢谢合作")
        TraceError(debug.traceback())
    end  
    local billcode = tex_wms_adapter_lib.get_unique_code()
    --写主表
    local businessid = _U(hall.gold_type.COUPON_SYS.id..add_gool_id) or " "
    local businessname =  _U(hall.gold_type.COUPON_SYS.des..tex_wms_adapter_lib.gift_cfg[add_gool_id] or " ")
    local remark = _U(hall.gold_type.COUPON_SYS.des..tex_wms_adapter_lib.gift_cfg[add_gool_id]..add_gool_id)
    tex_wms_adapter_lib.write_dozen_wms_dz_movemas(billcode, businessid, businessname, 0, 4, 1, bet_count or " ")
   
    --写礼券交易明细 自己和 系统
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, 10, 1, tex_wms_adapter_lib.gift_cfg_buy_sell[add_gool_id][2], -coupon_num, remark)
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, "PM000000", _U("德州游戏系统"), 10, 0, tex_wms_adapter_lib.gift_cfg_buy_sell[add_gool_id][2], coupon_num, remark)
    
    --写gools交易明细 自己和系统
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, to_user_id, nil, add_gool_id, 0, tex_wms_adapter_lib.gift_cfg_buy_sell[add_gool_id][2], add_gool_num, remark)
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, "PM000000", _U("德州游戏系统"), add_gool_id, 1, tex_wms_adapter_lib.gift_cfg_buy_sell[add_gool_id][2], -add_gool_num, remark)

end

--读取到保险箱信息
function tex_wms_adapter_lib.on_get_safe_gold_info(e)
    local user_info = e.data["user_info"]
    if (user_info == nil) then
        return
    end
    local user_nick = " "
    if (user_info.nick ~= "") then
        user_nick = user_info.nick
    end
            
    sql = "insert into tex_wms.dozen_pub_dz_playergools_%s(playerid,playername,goolsid,goolsname,gameqty,\
                reltime)values(%d,'%s',%d,'%s',%d,'%s')"
    gift_info = {count= user_info.safegold * 10000, name = tex_wms_adapter_lib.gift_cfg[0]}
    local sql_info = string.format(sql, tex_wms_adapter_lib.get_day(), user_info.userId, 
                                       user_nick, 0, _U(gift_info.name), gift_info.count, 
                                       tex_wms_adapter_lib.lua_to_oracle_time())
    dblib.execute(sql_info)
end

--收到保险箱变换信息
function tex_wms_adapter_lib.on_get_safe_gold_change(e)
    local user_info = e.data["userinfo"]
    local user_id = user_info.userId
    local change_type =  e.data["nType"] -- 1为取钱 
    local add_gold = e.data["gold"]
    local billcode = tex_wms_adapter_lib.get_unique_code()
    local trade_type = 0
    local tb_bussiness_info = {} 
    if change_type == 1 then
      trade_type = 1
      tb_bussiness_info = hall.gold_type.SAFE_BOX_GET
      add_gold = -add_gold
    else
      tb_bussiness_info = hall.gold_type.SAFE_BOX_CUN
    end
    
    --小盲注信息
  	local deskno =user_info.desk
  	local deskinfo = desklist[deskno]
    if deskinfo and deskinfo.smallbet then
      bet_count = deskinfo.smallbet
    end
    
    
    --写主表
    local businessid = _U(tb_bussiness_info.id or " ")
    local businessname =  _U(tb_bussiness_info.des or " ")
    local remark = _U(tb_bussiness_info.des or " ")
    tex_wms_adapter_lib.write_dozen_wms_dz_movemas(billcode, businessid, businessname, 0, 2, 1, bet_count or " ")
   
    --写交易明细自己和保险箱
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, 0, (trade_type + 1) % 2, math.abs(add_gold)*10000, -add_gold*10000, remark)
    tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, 1000, trade_type, math.abs(add_gold)*10000, add_gold*10000, remark)
   
end

--获取唯一的交易号
function tex_wms_adapter_lib.get_unique_code()
    local cur_clock = os.clock() * 1000
    if (cur_clock ~= tex_wms_adapter_lib.last_clock) then
        tex_wms_adapter_lib.last_clock = cur_clock
        tex_wms_adapter_lib.last_unique_num = 0
    else
        tex_wms_adapter_lib.last_unique_num = tex_wms_adapter_lib.last_unique_num + 1
    end
    return tex_wms_adapter_lib.lua_to_oracle_time()..groupinfo.groupid..tex_wms_adapter_lib.last_clock.."00"..tex_wms_adapter_lib.last_unique_num
end

--监听用户加金币接口新新新 没有实现
function tex_wms_adapter_lib.on_user_add_gold(e)
    local user_id = e.data["user_id"]
    local to_user_id = e.data["to_user_id"] or user_id  
    local add_gold = e.data["add_gold"]
    local add_type = e.data["add_type"]
    local chou_shui_gold = e.data["chou_shui_gold"]
    local chou_shui_type = e.data["chou_shui_type"] 
    local add_gool_id = e.data["gools_id"] or -1 
    local add_gool_num = e.data["gools_num"]
    local bet_count = 0
    
    --小盲注信息
  	local user_info = usermgr.GetUserById(user_id)
  	if not user_info then
  	  user_info = daxiao_hall.get_user_info(user_id)
  	end
  	
  	local deskno = nil
  	if user_info then
    	deskno =user_info.desk
    	local deskinfo = desklist[deskno]
      if deskinfo and deskinfo.smallbet then
        bet_count = deskinfo.smallbet
      else
        deskno = 0
      end
    end
  
    if add_gool_id > 0 and add_gool_num == nil then 
      add_gool_num = 1
    elseif add_gool_num == nil then
      add_gool_num = 0
    end
    local player_num = 2  --交易用户数量
    if (add_gool_id and add_gool_id > 0 ) then
        player_num = 4
    end
    --游戏结算另外算
    if (add_type ~= 10101) then
        if (add_gold ~= 0) then
             local billcode = tex_wms_adapter_lib.get_unique_code()
             local businessid = ((add_type or " ")..(add_gool_id or " ")) or " "
             local businessname = _U((tex_wms_adapter_lib.gold_type[add_type] or " ")..((tex_wms_adapter_lib.gift_cfg[add_gool_id] or " ") or "其他"))
             local trade_type = 1  --0表示产出，1表示消耗
             if (add_gold > 0) then
                 trade_type = 0
             end      
            --写主表
            tex_wms_adapter_lib.write_dozen_wms_dz_movemas(billcode, businessid, businessname, 0, player_num, 1, bet_count or " ", deskno)   
            
            --从表交易明细
            --写交易明细 自己和 系统
            local remark = businessname..businessid
            tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, 0, trade_type, math.abs(add_gold), add_gold, remark)
            tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, "PM000000", _U("德州游戏系统"), 0, (trade_type + 1) % 2, math.abs(add_gold), -add_gold, remark)
            --如果add_gool_id则有4条明细
            if add_gool_id and add_gool_id > 0 then
              --自己的物品明细
              tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, add_gool_id, (trade_type + 1) % 2, math.abs(add_gold), -add_gool_num, remark)
              tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, "PM000000", _U("德州游戏系统"), add_gool_id, trade_type, math.abs(add_gold), add_gool_num, remark)
            end
        end
        
        --如果有抽水信息，则一样 先写入主表，再写入明细表
        if (chou_shui_gold ~= 0 and chou_shui_type and chou_shui_type ~= 10100) then
            local billcode = tex_wms_adapter_lib.get_unique_code()
            local businessid = ((chou_shui_type or " ")..(add_gool_id or " ")) or " "
            local businessname = _U((tex_wms_adapter_lib.gold_type[chou_shui_type] or " ")..((tex_wms_adapter_lib.gift_cfg[add_gool_id] or " ") or "其他"))
            local remark = businessname..businessid
            --写主表
            tex_wms_adapter_lib.write_dozen_wms_dz_movemas(billcode, businessid, businessname, 0, 2, 1, bet_count or " ", deskno)   
            --写从表抽水明细（自己和系统）
            local remark = businessname..add_gool_id
            tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, nil, 0, 1, math.abs(chou_shui_gold), chou_shui_gold, remark)
            tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, "PM000000", _U("德州游戏系统"), 0, 0, math.abs(chou_shui_gold), -chou_shui_gold, remark)
        end
    end
end


--监听用户加金币接口
--function tex_wms_adapter_lib.on_user_add_gold(e)
--    TraceError(e.data)
--    local user_id = e.data["user_id"]
--    local add_gold = e.data["add_gold"]
--    local chou_shui_gold = e.data["chou_shui_gold"]
--    local add_type = e.data["add_type"]
--    local chou_shui_type = e.data["chou_shui_type"]
--    local add_gool_id = e.data["gools_id"] or -1 
--    local to_user_id = e.data["to_user_id"] or user_id
--    local add_gool_num = e.data["gools_num"]
--    if add_gool_id > 0 and add_gool_num == nil then 
--      add_gool_num = 1
--    elseif add_gool_num == nil then
--      add_gool_num = 0
--    end
--    --local add_gool_num = e.data["gools_num"]
--    local player_num = 2  --交易用户数量
--    if (add_gool_id and add_gool_id > 0 ) or (chou_shui_gold ~= 0 and add_type ~= chou_shui_type) then
--        player_num = 4
--    end
--    --游戏结算另外算
--    if (add_type ~= 10101) then
--        if (add_gold ~= 0) then
--            --交易总信息
--            local businessname = "交易"
--            if (add_type == 10100) then
--                businessname = "游戏抽水"
--            end
--            local billcode = tex_wms_adapter_lib.get_unique_code()
--            local sql = "insert into tex_wms.dozen_wms_dz_movemas_%s(billcode,businessid,businessname,tradeno,\
--                        businessdate,sumqty,playernumber,state,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
--            local gold_type = tex_wms_adapter_lib.gold_type[add_type] or " "
--            gold_type = _U(gold_type.."_"..add_type)
--            TraceError("sssssss"..gold_type)
--            --gold_type = add_type
--            sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, ((add_type or " ")..(add_gool_id or " ")) or " ",
--                                (_U(tex_wms_adapter_lib.gold_type[add_type] or " ").._U(tex_wms_adapter_lib.gift_cfg[add_gool_id] or " ") or "其他"), billcode, tex_wms_adapter_lib.lua_to_oracle_time(),
--                                0, player_num, 1, " ")
--            dblib.execute(sql)
--            --交易明细
--            sql = "insert into tex_wms.dozen_wms_dz_movedet_%s(billcode,playerid,playername,goolsid,\
--                   goolsname,goolsvalue, tradetype,tradeqty,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
--            local trade_type = 1  --0表示产出，1表示消耗
--            if (add_gold > 0) then
--                trade_type = 0
--            end
--            local user_nick = " "
--            local user_info = usermgr.GetUserById(user_id)
--            if (user_info ~= nil and user_info.nick ~= " ") then
--                user_nick = user_info.nick
--            end
--            --自己的明细
--            local sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, user_id, user_nick, 0, 
--                                _U(tex_wms_adapter_lib.gift_cfg[0]), math.abs(add_gold), trade_type, add_gold, gold_type)
--            dblib.execute(sql1)
--            --系统的明细
--            sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "PM000000", _U("德州游戏系统"), 0, 
--                                _U(tex_wms_adapter_lib.gift_cfg[0]), math.abs(add_gold), (trade_type + 1) % 2, -add_gold, gold_type)
--            dblib.execute(sql1)
--            if add_gool_id and add_gool_id > 0 then
--              --自己的物品明细
--              local user_nick = " "
--              local user_info = usermgr.GetUserById(to_user_id)
--              if (user_info ~= nil and user_info.nick ~= " ") then
--                  user_nick = user_info.nick
--              end
--              local sql2 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, to_user_id, user_nick, add_gool_id, 
--                                  _U(tex_wms_adapter_lib.gift_cfg[add_gool_id] or " "), math.abs(add_gold), (trade_type + 1) % 2, add_gool_num, gold_type)
--              dblib.execute(sql2)
--              --系统的物品明细
--              sql2 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "PM000000", _U("德州游戏系统"), add_gool_id, 
--                                  _U(tex_wms_adapter_lib.gift_cfg[add_gool_id] or " "), math.abs(add_gold), trade_type, -add_gool_num, gold_type)
--              dblib.execute(sql2)
--            end
--        end
--        --写入抽水信息
--        if (chou_shui_gold ~= 0 and add_type ~= chou_shui_type) then
--          --如果需要抽水，请先写主表
--            local trade_type = 0  --0表示产出，1表示消耗
--            --写入自己的抽水信息
--            gold_type = tex_wms_adapter_lib.gold_type[chou_shui_type] or " "
--            gold_type = _U(gold_type.."_"..chou_shui_type)
--
--            sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, user_id, user_nick, 0, 
--                                _U(tex_wms_adapter_lib.gift_cfg[0]), chou_shui_gold, trade_type, chou_shui_gold, gold_type)
--            dblib.execute(sql1)
--            --写入系统的抽水信息
--            sql1 = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "PM000000", _U("德州游戏系统"), 0, 
--                                _U(tex_wms_adapter_lib.gift_cfg[0]), -chou_shui_gold, (trade_type + 1) % 2, -chou_shui_gold, gold_type)
--            dblib.execute(sql1)
--        end
--    end
--end

--游戏结算结果
function tex_wms_adapter_lib.on_game_over_event(e)
    local sum_gold = 0
    local player_num = 0
    local smallbet = 0
    local desk_no = 0
    for k, v in pairs(e.data) do
        if (v.wingold ~= 0)  then
            sum_gold = sum_gold + v.wingold
            player_num = player_num + 1
            smallbet = v.smallbet or 0
            desk_no = v.deskno
        end
    end
    local billcode = tex_wms_adapter_lib.get_unique_code()
    local sql = "insert into tex_wms.dozen_wms_dz_movemas_%s(billcode,businessid,businessname,tradeno,\
                businessdate,sumqty,playernumber,state,remark,roomno)values('%s','%d','%s','%s','%s',%d,%d,%d,'%s',%d)"
    sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "10101",
                        _U("游戏结算"), billcode, tex_wms_adapter_lib.lua_to_oracle_time(),
                        sum_gold, player_num, 1, smallbet,desk_no)
    dblib.execute(sql)
    for k, v in pairs(e.data) do
        if (v.wingold ~= 0)  then
            sql = "insert into tex_wms.dozen_wms_dz_movedet_%s(billcode,playerid,playername,goolsid,\
                   goolsname,goolsvalue, tradetype,tradeqty,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
            local user_nick = " "
            local user_info = usermgr.GetUserById(v.userid)
            if (user_info ~= nil and user_info.nick ~= "") then
                user_nick = user_info.nick
            end
            local trade_type = 1
            if (v.wingold > 0) then
                trade_type = 0
            end
            sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, v.userid, user_nick, 0, 
                                _U(tex_wms_adapter_lib.gift_cfg[0]), math.abs(v.wingold), trade_type, v.wingold, _U("游戏结算_10101"))
            dblib.execute(sql)
        end
    end
end

--检测注册送钱，从user表中查询
function tex_wms_adapter_lib.check_user_reg()    
    local check_func = function(dt)
        if (dt and dt[1].num > (tex_wms_adapter_lib.max_user_id or 200000000000) and             
            tex_wms_adapter_lib.process_user_reg_ok == 1) then
            tex_wms_adapter_lib.process_user_reg_ok = 0
            local cur_time = os.time()
            local sql = "SELECT id as user_id, gold, nick_name as nick, reg_ip, sys_time, reg_site_no FROM users where id >= %d"
            sql = string.format(sql, tex_wms_adapter_lib.max_user_id or 200000000000)
            dblib.execute(sql, function(dt) 
                if (dt and #dt > 0) then
                    for i = 1, #dt do
                        local user_nick = " "
                        if (dt[i].nick ~= " ") then
                            user_nick = dt[i].nick
                        end
                        local reg_time = tex_wms_adapter_lib.lua_to_oracle_time(cur_time)
                        if (dt and #dt > 0) then
                            reg_time = tex_wms_adapter_lib.lua_to_oracle_time(tonumber(timelib.db_to_lua_time(dt[i].sys_time)))
                        end
                        local reg_ip = dt[i].reg_ip
                        if (reg_ip == " ") then
                            reg_ip = " "
                        end
                        local nick = dt[i].nick
                        if (nick == "") then
                            nick = " "
                        end
                        local reg_site_name = tex_wms_adapter_lib.reg_site[dt[i].reg_site_no] or dt[i].reg_site_no
                        --写入用户信息，因为可能用户不会登陆
                        local sql = "insert into tex_wms.dozen_pub_dz_player_%s(playerid,playername,createtm,regip,activation,\
                                lastgametm,lastloginip,passport,platformid,platformname)values(%d,'%s','%s','%s',%d,'%s','%s','%s','%s','%s')"
                        sql = string.format(sql, tex_wms_adapter_lib.get_day(), dt[i].user_id, nick, 
                                            reg_time, reg_ip, 1, tex_wms_adapter_lib.lua_to_oracle_time(cur_time), 
                                            reg_ip, " ", dt[i].reg_site_no, reg_site_name)
                        dblib.execute(sql)
                        local businessid = hall.gold_type.regAddGold.id;
                        --写交易总信息
                        local billcode = tex_wms_adapter_lib.get_unique_code()
                        sql = "insert into tex_wms.dozen_wms_dz_movemas_%s(billcode,businessid,businessname,tradeno,\
                                    businessdate,sumqty,playernumber,state,remark)values('%s','%d','%s','%s','%s',%d,%d,%d,'%s')"
                        sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, businessid,
                                            _U(tex_wms_adapter_lib.gold_type[businessid]), billcode, tex_wms_adapter_lib.lua_to_oracle_time(),
                                            0, 2, 1, " ")
                        dblib.execute(sql)
                        local trade_type = 1
                        --写明细
                        sql = "insert into tex_wms.dozen_wms_dz_movedet_%s(billcode,playerid,playername,goolsid,\
                               goolsname,goolsvalue, tradetype,tradeqty,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
                        local sql_temp = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, dt[i].user_id, nick, 0, 
                                            _U(tex_wms_adapter_lib.gift_cfg[0]), dt[i].gold, (trade_type + 1) % 2, dt[i].gold, _U("注册_1000"))
                        dblib.execute(sql_temp)
                        sql_temp = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "PM000000", _U("德州游戏系统"), 0, 
                                            _U(tex_wms_adapter_lib.gift_cfg[0]), dt[i].gold, trade_type, -dt[i].gold, _U("充值_1000"))
                        dblib.execute(sql_temp)
                        --记录索引
                        tex_wms_adapter_lib.max_user_id = tex_wms_adapter_lib.max_user_id + 1
                        sql = "update tex_wms.table_index_info2 set user_reg_index = user_reg_index + 1"
                        dblib.execute(sql)                        
                    end
                end
                tex_wms_adapter_lib.process_user_reg_ok = 1
            end)
        end
    end
    local sql = "select max(id) as num from users"
    --检测有没有新的用户记录
    dblib.execute(sql, check_func)
    --检测上一次用户记录写到哪里了
    if (tex_wms_adapter_lib.max_user_id == nil or tex_wms_adapter_lib.max_user_id == 200000000000) then
        local sql = "select user_reg_index from tex_wms.table_index_info2"
        dblib.execute(sql, function(dt) 
            if (dt and #dt > 0) then
                tex_wms_adapter_lib.max_user_id = dt[1].user_reg_index
            end
        end)                
    end
end


--检测充值，写入运营系统
function tex_wms_adapter_lib.check_pay_wms()    
    local check_func = function(dt)
        if (dt and dt[1].num > (tex_wms_adapter_lib.max_pay_id or 200000000000) and tex_wms_adapter_lib.process_pay_ok == 1) then
            tex_wms_adapter_lib.process_pay_ok = 0
            local sql = "SELECT a.userid as user_id, a.gold as gold, b.nick_name as nick, a.rmb as rmb FROM log_pay_success a, users b WHERE a.id >= %d AND a.userid = b.id"
            sql = string.format(sql, tex_wms_adapter_lib.max_pay_id or 200000000000)
            dblib.execute(sql, function(dt) 
                if (dt and #dt > 0) then
                    for i = 1, #dt do
                        local user_nick = " "
                        if (dt[i].nick ~= "") then
                            user_nick = dt[i].nick
                        end
                        --写交易总信息
                        local billcode = tex_wms_adapter_lib.get_unique_code()
                        local sql = "insert into tex_wms.dozen_wms_dz_movemas_%s(billcode,businessid,businessname,tradeno,\
                                    businessdate,sumqty,playernumber,state,remark)values('%s','%d','%s','%s','%s',%d,%d,%d,'%s')"
                        sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, 1000,
                                            _U(tex_wms_adapter_lib.gold_type[1000]), billcode, tex_wms_adapter_lib.lua_to_oracle_time(),
                                            0, 2, 1, " ")
                        dblib.execute(sql)
                        local trade_type = 1
                        --写明细
                        sql = "insert into tex_wms.dozen_wms_dz_movedet_%s(billcode,playerid,playername,goolsid,\
                               goolsname,goolsvalue, tradetype,tradeqty,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
                        local sql_temp = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, dt[i].user_id, user_nick, 0, 
                                            _U(tex_wms_adapter_lib.gift_cfg[0]), dt[i].gold, (trade_type + 1) % 2, dt[i].gold, _U("充值_1000"))
                        dblib.execute(sql_temp)
                        sql_temp = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, "PM000000", _U("德州游戏系统"), 0, 
                                            _U(tex_wms_adapter_lib.gift_cfg[0]), dt[i].gold, trade_type, -dt[i].gold, _U("充值_1000"))
                        dblib.execute(sql_temp)
                        --记录索引
                        tex_wms_adapter_lib.max_pay_id = tex_wms_adapter_lib.max_pay_id + 1
                        sql = "update tex_wms.table_index_info2 set pay_index = pay_index + 1"
                        dblib.execute(sql)                        
                    end
                end
                tex_wms_adapter_lib.process_pay_ok = 1
            end)
        end
    end
    local sql = "select max(id) as num from log_pay_success"
    --检测有没有新的充值记录
    dblib.execute(sql, check_func)
    --检测上一次充值记录写到哪里了
    if (tex_wms_adapter_lib.max_pay_id == nil or tex_wms_adapter_lib.max_pay_id == 200000000000) then
        local sql = "select pay_index from tex_wms.table_index_info2"
        dblib.execute(sql, function(dt) 
            if (dt and #dt > 0) then
                tex_wms_adapter_lib.max_pay_id = dt[1].pay_index
            end
        end)                
    end
end

function tex_wms_adapter_lib.timer(e)
    if (gamepkg.name == 'tex' and groupinfo.groupid == "18002") then   
        tex_wms_adapter_lib.check_pay_wms()
        tex_wms_adapter_lib.check_user_reg()
    end
end



------------------------------------------------------------------------
--------------------------数据库操作------------------------------------
------------------------------------------------------------------------
--写主表函数
--billcode单据, businessid编号， businessname名称，sumqty总和一般为0， playernumber交易明细数量汇总，state为1有效，remark小盲注
function tex_wms_adapter_lib.write_dozen_wms_dz_movemas(billcode, businessid, businessname, sumqty, playernumber, state, remark, deskno)
    local sql = "insert into tex_wms.dozen_wms_dz_movemas_%s(billcode,businessid,businessname,tradeno,\
                businessdate,sumqty,playernumber,state,remark,roomno)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s',%d)"
    sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, businessid or " ",
                        businessname or "其他", billcode, tex_wms_adapter_lib.lua_to_oracle_time(),
                        sumqty, playernumber, state, remark, deskno or 0)
    dblib.execute(sql)
end

--写从表函数 
--billcode单据 goolsvalue永远为正数
function tex_wms_adapter_lib.write_dozen_wms_dz_movedet(billcode, user_id, user_nick, goolsid, tradetype, goolsvalue, tradeqty, remark)
      if tradetype == 1 then
        tradeqty = -math.abs(tradeqty)
      else
        tradeqty = math.abs(tradeqty)
      end
      --交易明细
      sql = "insert into tex_wms.dozen_wms_dz_movedet_%s(billcode,playerid,playername,goolsid,\
             goolsname,tradetype,goolsvalue,tradeqty,remark)values('%s','%s','%s','%s','%s',%d,%d,%d,'%s')"
             
      if not user_nick then 
        user_nick = " "
        user_info = usermgr.GetUserById(user_id)
        if (user_info ~= nil and user_info.nick ~= "") then
            user_nick = user_info.nick
        else
          if daxiao_hall then
            user_info = daxiao_hall.get_user_info(user_id)
            if (user_info ~= nil and user_info.nick ~= "") then
              user_nick = user_info.nick
            end
          end
        end   
      end
   
      sql = string.format(sql, tex_wms_adapter_lib.get_day(), billcode, user_id, user_nick, goolsid, 
                          _U(tex_wms_adapter_lib.gift_cfg[goolsid]), tradetype, goolsvalue, tradeqty, remark)
      dblib.execute(sql)
end



eventmgr:addEventListener("h2_on_user_login", tex_wms_adapter_lib.on_after_user_login)
eventmgr:addEventListener("after_get_props_list", tex_wms_adapter_lib.after_get_props_list)
eventmgr:addEventListener("timer_second", tex_wms_adapter_lib.timer);
eventmgr:addEventListener("on_user_add_gold", tex_wms_adapter_lib.on_user_add_gold)
eventmgr:addEventListener("on_get_safebox_info", tex_wms_adapter_lib.on_get_safe_gold_info)
eventmgr:addEventListener("on_safebox_sq", tex_wms_adapter_lib.on_get_safe_gold_change)
eventmgr:addEventListener("game_event_ex", tex_wms_adapter_lib.on_game_over_event)
eventmgr:addEventListener("on_server_start", tex_wms_adapter_lib.restart_server)
eventmgr:addEventListener("finish_init_car", tex_wms_adapter_lib.on_after_init_car)
eventmgr:addEventListener("already_init_parking", tex_wms_adapter_lib.on_after_init_parking)
eventmgr:addEventListener("already_init_yinpiao", tex_wms_adapter_lib.on_after_init_yinpiao)
eventmgr:addEventListener("on_user_change_coupon", tex_wms_adapter_lib.on_user_change_coupon)

