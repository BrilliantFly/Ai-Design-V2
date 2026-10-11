-- ============================================================
-- biz-info-collector · 采集结果转 SQL
-- 源文件: biz-info-nev-2026-10-10.json
-- 生成时间: 2026-10-10T04:57:10.607Z
-- 目标库: know_boot_v1
-- 说明: id 由脚本生成(雪花)；create_time/update_time 为毫秒时间戳；关联表在主表之后
-- ============================================================
SET NAMES utf8mb4;

START TRANSACTION;

-- biz_industry
INSERT INTO biz_industry (id, industry_name, definition, technology, tags, upstream_chain, midstream_chain, downstream_channel, downstream_marketing, development_overview, market_size, growth_potential, dynamic_info, value_info, industry_resources, strategy, visibility, sort, create_time, update_time, del_flag) VALUES (2108783878519918593, '新能源汽车', '以新型能源驱动 + 技术先进性为核心、采用非常规车用能源的汽车，主要包括纯电动(BEV)、插电式混动(PHEV，含增程)、燃料电池(FCEV)；普通油电混动(HEV)因不能外接充电不再归入新能源汽车范畴。', '三大核心技术（三电）：电池、电机、电控；另含热管理、轻量化与电路系统等。', '新能源汽车,纯电,插混,三电,动力电池,以旧换新', '上游：锂/钴/镍等关键矿产、正极/负极材料、隔膜、电解液等电池材料。', '中游：动力电池、电机、电控、热管理、轻量化与电路系统；整车制造。', '下游：整车销售、充换电服务、汽车金融/后市场、出口。', '直营+经销（4S/商超店）、线上直播与内容营销、以旧换新与价格促销。', '连续 11 年位居全球首位。2025 年产销双双突破 1600 万辆、同比增超 25%，国内新车市场渗透率达 50.8%；2026 年预计销量（含出口）约 2000 万辆、渗透率升至 57%、保有量突破 6000 万辆。', '2025 年产销突破 1600 万辆（国内渗透率 50.8%）；2026 年预计销量（含出口）达 2000 万辆。', '2025 年同比增超 25%，渗透率四年翻 3 倍；2026 年渗透率预计升至 57%。', '2026 年新能源汽车购置税由全额免征改为减半征收、免税门槛提高；以旧换新补贴由定额改为按新车价格比例；价格战、智能化（智驾）与出海成为主线。', '燃油车替代大周期叠加出口高增长，产业链景气度高。', '三电核心技术、锂等关键矿产、动力电池产能、整车产销规模与品牌。', '整车端拼规模、智驾与出海；产业链端卡位动力电池与关键材料；把握以旧换新与出口政策窗口。', 1, 0, 1791608230606, 1791608230606, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, consumer_insight, life_cycle, downstream_channel, create_time, update_time, del_flag) VALUES (2108783878519918594, '纯电动汽车(BEV)', '完全由车载动力电池供电、以电动机驱动的汽车，无内燃机。', '整车类型', '用车成本低、加速与静谧性好；主要顾虑为续航与补能。', '成长期', '个人消费者、网约车/出租、企业与政府车队。', 1791608230606, 1791608230606, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, consumer_insight, life_cycle, create_time, update_time, del_flag) VALUES (2108783878519918595, '插电式混动/增程(PHEV/EREV)', '可外接充电、兼具电动机与内燃机的车型；增程以电机直驱、发动机发电为主。', '整车类型', '可油可电，缓解续航焦虑，适合充电条件有限的用户。', '成长期', 1791608230606, 1791608230606, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, life_cycle, midstream_chain, create_time, update_time, del_flag) VALUES (2108783878519918596, '动力电池', '新能源汽车的核心能量存储部件（以锂离子电池为主），是整车成本占比最高的部件之一。', '核心零部件 / 中游', '成长期', '中游：动力电池制造（含磷酸铁锂、三元等路线）。', 1791608230606, 1791608230606, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783878519918597, '比亚迪', '生产商', '新能源汽车整车（纯电+插混）、动力电池与电子。', '2025 年全年销量 460.2 万辆，首次跻身全球车企集团销量前五（超越通用、福特、本田、日产），连续 4 年全球新能源汽车销量冠军；2025 年海外销量超 104.9 万辆，同比 +145%；2025 年纯电销量 166 万辆，同比 +18.5%。', 0, 1791608230606, 1791608230606, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783878519918598, '特斯拉', '生产商', '纯电动汽车整车。', '2025 年全球纯电销量 60.7 万辆，同比 -8.4%，被比亚迪反超。', 0, 1791608230606, 1791608230606, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783878519918599, '宁德时代', '生产商', '动力电池与储能电池。', '据 SNE Research，2025 年全球动力电池使用量市占率提升 1.2 个百分点至 39.2%，连续 9 年全球第一；2025 年营收 4237.02 亿元（+17.04%），净利润 722.01 亿元（+42.28%）。', 0, 1791608230606, 1791608230606, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783878519918600, '吉利汽车', '生产商', '新能源汽车整车（传统车企转型代表）。', '位列 2025 年新能源汽车十大销量品牌。', 0, 1791608230606, 1791608230606, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783878519918601, '小米汽车', '生产商', '新能源汽车整车（新势力）。', '位列 2025 年新能源汽车十大销量品牌。', 0, 1791608230606, 1791608230606, 0);
-- biz_industry_market
INSERT INTO biz_industry_market (id, demand, value_proposition, opportunity, customer_segment, channel, customer_relation, revenue_source, key_resource, key_partner, key_activity, cost_structure, competition_method, promo_channel, value_distribution, dynamic_info, value_info, strategy, create_time, update_time, del_flag) VALUES (2108783878519918602, '燃油车替代叠加双碳目标，需求由政策驱动转向市场驱动；2025 年国内新车渗透率达 50.8%，产销突破 1600 万辆。', '更低的用车成本（电费/能耗）、更好的智能化体验与环保价值。', '燃油车存量置换、下沉市场与出口市场；比亚迪 2025 年海外销量超 104.9 万辆、同比 +145%。', '个人消费者、网约车/出租车、企业与政府车队。', '直营 + 经销（4S 店/商超店）、线上直播与内容营销。', '直营品牌以用户社区与 OTA 持续运营；经销体系依赖 4S 网络。', '整车销售为主；充换电服务费、软件/服务订阅、汽车金融与后市场为补充。', '三电技术、动力电池供应、产能规模、品牌与渠道。', '动力电池厂商（宁德时代等）、零部件/材料供应商、充电运营商。', '整车研发制造、渠道与营销、充换电网络建设、出口。', '电池/供应链成本占比高（电池为主要成本项），靠规模效应与垂直整合降本。', '价格战 + 智能化（智驾）+ 出海；头部集中，比亚迪全球份额超 20%。', '线上直播/新媒体 + 线下商超店/车展 + 以旧换新补贴。', '利润向电池环节（宁德时代高净利）与头部整车集中，中小车企承压。', '2026 年购置税减半征收、门槛提高；以旧换新改为按新车价格比例补贴；价格战与智驾竞争加剧。', '替代燃油车大周期 + 出口高增长，龙头与电池环节确定性更强。', '头部拼规模、智驾与出海；产业链卡位电池与关键材料。', 1791608230606, 1791608230606, 0);

-- ---------- 关联关系 ----------
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112907, 2108783878519918593, 2108783878519918594, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112908, 2108783878519918593, 2108783878519918595, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112909, 2108783878519918593, 2108783878519918596, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783878524112910, 2108783878519918593, 2108783878519918597, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783878524112911, 2108783878519918593, 2108783878519918598, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783878524112912, 2108783878519918593, 2108783878519918599, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783878524112913, 2108783878519918593, 2108783878519918600, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783878524112914, 2108783878519918593, 2108783878519918601, 1791608230606, 1791608230606, 0);
INSERT INTO biz_industry_market_rel (id, industry_id, market_id, create_time, update_time, del_flag) VALUES (2108783878524112915, 2108783878519918593, 2108783878519918602, 1791608230606, 1791608230606, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112916, 2108783878519918597, 2108783878519918594, 1791608230606, 1791608230606, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112917, 2108783878519918597, 2108783878519918595, 1791608230606, 1791608230606, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112918, 2108783878519918597, 2108783878519918596, 1791608230606, 1791608230606, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112919, 2108783878519918598, 2108783878519918594, 1791608230606, 1791608230606, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783878524112920, 2108783878519918599, 2108783878519918596, 1791608230606, 1791608230606, 0);

COMMIT;
