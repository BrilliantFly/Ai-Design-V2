-- ============================================================
-- biz-info-collector · 采集结果转 SQL
-- 源文件: biz-info-ai-2026-10-10.json
-- 生成时间: 2026-10-10T04:57:10.348Z
-- 目标库: know_boot_v1
-- 说明: id 由脚本生成(雪花)；create_time/update_time 为毫秒时间戳；关联表在主表之后
-- ============================================================
SET NAMES utf8mb4;

START TRANSACTION;

-- biz_industry
INSERT INTO biz_industry (id, industry_name, definition, technology, tags, upstream_chain, midstream_chain, downstream_channel, downstream_marketing, development_overview, market_size, growth_potential, dynamic_info, value_info, industry_resources, strategy, visibility, sort, create_time, update_time, del_flag) VALUES (2108783877429399553, '人工智能', '以机器学习/深度学习为核心，研究、开发用于模拟、延伸和扩展人的智能的理论、方法、技术及应用系统的技术科学；按技术路线分为符号主义（逻辑推理）、连接主义（神经网络）、行为主义（强化学习）。', '机器学习、深度学习、计算机视觉、自然语言处理(NLP)、语音识别；三大技术路线：符号主义 / 连接主义 / 行为主义。', 'AI,大模型,机器学习,深度学习,人工智能+', '基础层：传感器、AI 芯片(GPU/ASIC)、云计算、AI 基础数据服务。', '技术层：机器学习、计算机视觉、自然语言处理、语音识别；大模型与软件（AI 大脑）。', '应用层：智能驾驶、智能制造、智慧医疗、AI 应用等。', '线上多渠道数字营销、AI 精准营销与客户画像。', '产业正从概念验证走向规模化落地。2025-08 国务院印发《关于深入实施「人工智能+」行动的意见》(国发〔2025〕11号)，推动 AI 与经济社会各领域深度融合，明确未来 10 年发展目标。', '赛迪顾问预测 2026 年中国 AI 市场规模接近 6000 亿元（2026-01）；中商产业研究院预测 2026 年达 12534 亿元；英伟达 CEO 黄仁勋预计 2026 年中国 AI 市场达 500 亿美元。', '中国信通院：2025 年 AI 核心产业规模有望突破万亿元；另有报道称 2025 年中国 AI 产业规模超 9 千亿元、增速 25.7%；2026-10 有报道称核心产业规模突破 1.2 万亿元。', '政策端「人工智能+」行动与「十五五」规划持续深化数智化；行业竞争从「技术性能单维比拼」转向「生态与商业化落地」。', 'AI 被定位为新质生产力核心引擎，带动算力、模型、应用全链条机会。', '算力（芯片/云）、高质量数据、算法与人才、行业落地场景。', '沿「基础层—技术层—应用层」布局，把握「人工智能+」行业渗透与国产算力替代两条主线。', 1, 0, 1791608230346, 1791608230346, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, consumer_insight, life_cycle, midstream_chain, dynamic_info, create_time, update_time, del_flag) VALUES (2108783877429399554, '大模型平台', '基于海量参数与自监督预训练、具备通用任务泛化能力的 AI 基础模型（如大语言模型）。', 'AI 基础模型 / 软件', '企业希望以更低门槛获得通用智能能力，用于对话、生成、推理等场景。', '成长期', '技术层：大模型研发与训练。', '开源生态活跃，模型能力快速迭代。', 1791608230346, 1791608230346, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, upstream_chain, life_cycle, dynamic_info, create_time, update_time, del_flag) VALUES (2108783877429399555, 'AI 芯片(GPU/ASIC)', '面向 AI 训练与推理的算力芯片，构成 AI 产业的算力底座。', '算力硬件 / 基础层', '上游：晶圆制造、封装测试、EDA/IP。', '成长期', '上游材料（MLCC、铜箔、功率半导体等）随 AI 需求出现涨价与需求双驱动。', 1791608230346, 1791608230346, 0);
-- biz_industry_product
INSERT INTO biz_industry_product (id, product_name, product_concept, category, downstream_channel, create_time, update_time, del_flag) VALUES (2108783877429399556, '智能驾驶解决方案', '面向智能驾驶场景的 AI 软硬件一体化解决方案。', '应用层', '车企、Tier1、出行平台。', 1791608230346, 1791608230346, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783877429399557, '寒武纪', '生产商', 'AI 芯片（AI 算力芯片/加速卡）。', '位列《2025 胡润中国人工智能企业 50 强》第 1 名（按企业价值）。', 0, 1791608230346, 1791608230346, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783877429399558, '摩尔线程', '生产商', 'GPU 芯片。', '位列《2025 胡润中国人工智能企业 50 强》第 2 名。', 0, 1791608230346, 1791608230346, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783877429399559, '科大讯飞', '平台,生产商', '智能语音、大模型。', '位列《2025 胡润中国人工智能企业 50 强》。', 0, 1791608230346, 1791608230346, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, is_listed, create_time, update_time, del_flag) VALUES (2108783877429399560, '浪潮信息', '生产商', 'AI 服务器（上游算力基础设施）。', 0, 1791608230346, 1791608230346, 0);
-- biz_industry_enterprise
INSERT INTO biz_industry_enterprise (id, enterprise_name, enterprise_type, main_business, market_performance, is_listed, create_time, update_time, del_flag) VALUES (2108783877429399561, '海光信息', '生产商', 'CPU / DCU（AI 算力芯片）。', '2025 年第三季度营收 40.26 亿元（同比 +69.6%），净利润 7.6 亿元（同比 +13.04%），毛利润 24.17 亿元，毛利率 60.03%。', 0, 1791608230346, 1791608230346, 0);
-- biz_industry_market
INSERT INTO biz_industry_market (id, demand, value_proposition, opportunity, customer_segment, channel, customer_relation, revenue_source, key_resource, key_partner, key_activity, cost_structure, competition_method, promo_channel, value_distribution, dynamic_info, value_info, strategy, create_time, update_time, del_flag) VALUES (2108783877429399562, '各行业智能化转型需求旺盛；中国信通院预计 2025 年 AI 核心产业规模有望突破万亿元，需求由技术尝鲜转向规模化落地。', '以「算力+模型+应用」提升各行业生产效率，重塑生产生活范式，形成智能经济与智能社会新形态。', '国务院《关于深入实施「人工智能+」行动的意见》推动 AI 与实体经济深度融合，带来行业渗透机会。', '政府、金融、制造、医疗、互联网、交通等（ToG/ToB 为主）。', '云厂商渠道、行业系统集成商、直销与生态伙伴。', '以行业解决方案交付 + 持续运维/订阅维持客户关系。', '技术服务与订阅（SaaS 订阅、API 调用）、软硬件一体化、专业服务与生态（行业解决方案/系统集成/咨询）。', '算力、数据、算法与人才。', '芯片厂商、云厂商、行业 ISV/集成商。', '模型研发与训练、行业解决方案交付、算力运营。', '算力成本 + 研发投入 + 人才成本为主，偏重资产。', '头部科技巨头凭技术、数据与生态优势占据近 80% 市场份额，呈寡头垄断格局。', '企业级：行业峰会/生态合作；产品级：内容营销、多渠道数字营销与 AI 精准投放。', '产业链利润向基础层（芯片/云）与技术层（模型）集中，应用层竞争激烈、利润较薄。', '竞争从「技术性能单维比拼」转向「生态与商业化落地」；成本压缩与盈利模式创新成为主线。', '市场价值集中于基础设施与模型层，应用层机会在垂直场景与数据壁垒。', '优先卡位算力/模型基础设施，或以垂直行业数据壁垒切入应用层。', 1791608230346, 1791608230346, 0);

-- ---------- 关联关系 ----------
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788171, 2108783877429399553, 2108783877429399554, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788172, 2108783877429399553, 2108783877429399555, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_product_rel (id, industry_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788173, 2108783877429399553, 2108783877429399556, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783877437788174, 2108783877429399553, 2108783877429399557, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783877437788175, 2108783877429399553, 2108783877429399558, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783877437788176, 2108783877429399553, 2108783877429399559, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783877437788177, 2108783877429399553, 2108783877429399560, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_enterprise_rel (id, industry_id, enterprise_id, create_time, update_time, del_flag) VALUES (2108783877437788178, 2108783877429399553, 2108783877429399561, 1791608230346, 1791608230346, 0);
INSERT INTO biz_industry_market_rel (id, industry_id, market_id, create_time, update_time, del_flag) VALUES (2108783877437788179, 2108783877429399553, 2108783877429399562, 1791608230346, 1791608230346, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788180, 2108783877429399557, 2108783877429399555, 1791608230346, 1791608230346, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788181, 2108783877429399558, 2108783877429399555, 1791608230346, 1791608230346, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788182, 2108783877429399559, 2108783877429399554, 1791608230346, 1791608230346, 0);
INSERT INTO biz_enterprise_product_rel (id, enterprise_id, product_id, create_time, update_time, del_flag) VALUES (2108783877437788183, 2108783877429399561, 2108783877429399555, 1791608230346, 1791608230346, 0);

COMMIT;
