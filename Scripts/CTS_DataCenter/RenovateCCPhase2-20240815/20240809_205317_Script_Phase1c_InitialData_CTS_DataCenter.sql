/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Initial data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 1-b: Initial Data [Redmine ID: #205317]
										I. Data Setting:
											1. CustomerCategory_new 
											2. CustomerCategorySettings 
											3. CustomerClassification_Remark 
										II. Data Classification:
											1. Customer_InitialGroupBetting - 2600/2601 
											2. TVSVoidRequest - Replace TVSVoidRequest_History & CTSCustomerClassificationOldCategory
											3. CTSRobotUser - Replace CTSCustomerClassificationOldCategory
											4. TWRobotUser
											5. CTSCustomerClassification
											6. CTSCustomerClassification_History
											7. CTSCustomerClassification_Log
											8. CTSCustomerClassificationQueue
											9. CTSCustomerClassification_BySport
											10. CTSCustomerClassification_BySport_History
											11. CTSCustomerClassification_BySport_Log
											12. ArchiveCustomer_CTSCustomer
*/

USE CTS_DataCenter;
/************************* I. Data Setting ******************************/
/* 1. CustomerCategory_new  */
INSERT INTO CustomerCategory_new(CategoryID,CategoryName,CategorySpec,CustomerClass,CustomerClassName,ParentID,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,ScanTaggingIntervalInSecond,RootTaggingID,RelevantCategoryID,IsHedgingReasonMM,TVSReasonID,IsPAProbation,IsDangerProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,TaggingID,TaggingType,Ext_ABIDangerLevel_Licensee,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,OldCategoryID,Ext_CategoryGroupID,Ext_EvidenceID_Licensee,Ext_EvidenceID_Credit,Ext_SabaIntelligentRiskLevel,Ext_SabaIntelligentRiskLevelTCN,Ext_SabaIntelligentRiskLevelSCN,Ext_SabaIntelligentRiskLevelCN3,Ext_SabaIntelligentRiskLevelTHB,Ext_SabaIntelligentRiskLevelIND,ColorTypeID)
VALUES
(1010,'VVIP (internal)','VVIP',999,'Healthy +',1000,1010,10,10,30,1,Null,Null,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','超级贵宾','VVIP (nội bộ)','VVIP (ภายใน)','VVIP (internal)','健康+',Null,Null,Null,Null,Null,1,210,210,Null,Null,'VIP','VIP玩家','VIP玩家','VIP','VIP','VIP',1),
(10100,'BA User','BA User',401,'Dangerous',10000,10100,300,900,NULL,1,Null,Null,14,Null,Null,Null,0,0,Null,Null,'2022/08/09 03:32:29','BA 用戶','Người dùng BA','ผู้ใช้ BA','Pengguna BA','危險',Null,Null,Null,Null,Null,0,2,2,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',Null),
(10200,'VIP (Normal Member)','VIP (Normal Member)',4000,'Suspicious',10000,10200,320,310,NULL,1,Null,Null,99,10201,Null,Null,1,1,Null,Null,'2022/08/09 03:32:29','VIP会员 (正常会员)','VIP (Member Bình thường)','VIP (สมาชิกปกติ)','VIP (Anggota Biasa)','可疑',Null,Null,Null,Null,Null,0,4,99,Null,Null,'VIP','VIP玩家','VIP玩家','VIP','VIP','VIP',Null),
(10201,'VIP (Problem Member)','VIP (Problem Member)',400,'Dangerous',10000,10200,300,300,NULL,1,Null,Null,99,10200,Null,Null,0,0,Null,Null,'2022/08/09 03:32:29','VIP会员（问题会员)','VIP (Member Có vấn đề)','VIP (สมาชิกมีปัญหา)','VIP (Anggota Ada Masalah)','危險',Null,Null,Null,Null,Null,0,3,99,Null,Null,'VIP','VIP玩家','VIP玩家','VIP','VIP','VIP',Null),
(10300,'Special CC','Special CC',Null,Null,10000,10300,200,200,NULL,1,Null,Null,Null,NULL,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,0,NULL,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null),
(20100,'Group Betting','Group Betting',301,'Problems',20000,20100,400,400,10,1,Null,Null,8,25100,Null,28,0,0,1,'NAP','2020/07/26 22:29:56','群组投注','Cược Nhóm','การเดิมพันกลุ่ม','Taruhan Grup','問題','1,2',Null,Null,11,1,2,52,52,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20101,'Group Betting','Group Betting (Evidence)',301,'Problems',20000,20100,400,400,10,1,Null,Null,8,25101,Null,Null,0,0,1,'Evidence','2020/10/20 22:58:31','群组投注','Cược Nhóm','การเดิมพันกลุ่ม','Taruhan Grup','問題','1,2',Null,Null,11,1,2,72,52,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20102,'Group Betting','Group Betting(M)',301,'Problems',20000,20100,400,400,10,1,Null,Null,8,25102,Null,Null,0,0,1,'NAP','2020/07/26 22:29:56','群组投注','Cược Nhóm','การเดิมพันกลุ่ม','Taruhan Grup','問題','1,2',Null,Null,11,1,2,152,52,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20103,'Group Betting','Group Betting - Abnormal Account, IssueType:13',301,'Problems',20000,20100,400,400,10,1,Null,Null,8,25103,Null,100,0,0,1,'NAP','2023/04/18 22:30:04','群组投注','Cược Nhóm','การเดิมพันกลุ่ม','Taruhan Grup','問題','1,2',Null,Null,11,1,2,172,52,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20200,'Hedging','Hedging',303,'Problems',20000,20200,400,400,10,1,Null,Null,10,25200,1,29,0,0,2,'NAP','2020/07/26 22:29:56','出货群组','Cược Bảo hiểm','การเดิมพันประกันภัย','Taruhan Asuransi','問題','2',Null,Null,14,4,2,53,53,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20201,'Hedging','Hedging (Evidence)',303,'Problems',20000,20200,400,400,10,1,Null,Null,10,25201,1,Null,0,0,2,'Evidence','2020/10/20 22:58:31','出货群组','Cược Bảo hiểm','การเดิมพันประกันภัย','Taruhan Asuransi','問題','2',Null,Null,14,4,2,73,53,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20202,'Hedging','Hedging(M)',303,'Problems',20000,20200,400,400,10,1,Null,Null,10,25202,1,Null,0,0,2,'NAP','2020/07/26 22:29:56','出货群组','Cược Bảo hiểm','การเดิมพันประกันภัย','Taruhan Asuransi','問題','2',Null,Null,14,4,2,153,53,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20203,'Hedging','Hedging - Abnormal Account, IssueType:13',303,'Problems',20000,20200,400,400,10,1,Null,Null,10,25203,1,101,0,0,2,'NAP','2023/04/18 22:30:04','出货群组','Cược Bảo hiểm','การเดิมพันประกันภัย','Taruhan Asuransi','問題','2',Null,Null,14,4,2,173,53,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20300,'Arbitrage','Arbitrage',302,'Problems',20000,20300,400,400,10,1,Null,Null,Null,25300,Null,30,0,0,3,'NAP','2020/07/26 22:29:56','打水套利','Cược Chênh lệch','การเดิมพันแตกต่าง','Taruhan Selisih','問題','1,2',Null,Null,13,3,2,54,54,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20301,'Arbitrage','Arbitrage (Evidence)',302,'Problems',20000,20300,400,400,10,1,Null,Null,Null,25301,Null,Null,0,0,3,'Evidence','2020/10/20 22:58:31','打水套利','Cược Chênh lệch','การเดิมพันแตกต่าง','Taruhan Selisih','問題','1,2',Null,Null,13,3,2,74,54,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20302,'Arbitrage','Arbitrage(M)',302,'Problems',20000,20300,400,400,10,1,Null,Null,Null,25302,Null,Null,0,0,3,'NAP','2020/07/26 22:29:56','打水套利','Cược Chênh lệch','การเดิมพันแตกต่าง','Taruhan Selisih','問題','1,2',Null,Null,13,3,2,154,54,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20303,'Arbitrage','Arbitrage - Abnormal Account, IssueType:13',302,'Problems',20000,20300,400,400,10,1,Null,Null,Null,25303,Null,102,0,0,3,'NAP','2023/04/18 22:30:04','打水套利','Cược Chênh lệch','การเดิมพันแตกต่าง','Taruhan Selisih','問題','1,2',Null,Null,13,3,2,174,54,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20400,'Fixed Game','Fixed Game',303,'Problems',20000,20400,400,400,10,1,Null,Null,10,25400,Null,31,0,0,4,'NAP','2020/07/26 22:29:56','内定赛事','Dàn xếp tỷ số','การจัดระบบคะแนน','Mengatur Skor','問題','2',Null,Null,12,2,2,55,55,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20401,'Fixed Game','Fixed Game (Evidence)',303,'Problems',20000,20400,400,400,10,1,Null,Null,10,25401,Null,Null,0,0,4,'Evidence','2020/10/20 22:58:31','内定赛事','Dàn xếp tỷ số','การจัดระบบคะแนน','Mengatur Skor','問題','2',Null,Null,12,2,2,75,55,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20402,'Fixed Game','Fixed Game(M)',303,'Problems',20000,20400,400,400,10,1,Null,Null,10,25402,Null,Null,0,0,4,'NAP','2020/07/26 22:29:56','内定赛事','Dàn xếp tỷ số','การจัดระบบคะแนน','Mengatur Skor','問題','2',Null,Null,12,2,2,155,55,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20403,'Fixed Game','Fixed Game - Abnormal Account, IssueType:13',303,'Problems',20000,20400,400,400,10,1,Null,Null,10,25403,Null,103,0,0,4,'NAP','2023/04/18 22:30:04','内定赛事','Dàn xếp tỷ số','การจัดระบบคะแนน','Mengatur Skor','問題','2',Null,Null,12,2,2,175,55,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20500,'Irrigation Bet','Irrigation Bet',302,'Problems',20000,20500,400,400,10,1,Null,Null,Null,25500,Null,37,0,0,5,'NAP','2020/07/26 22:29:56','灌水投注','Cược Sập giá','การพนันราคาล่ม','Taruhan Harga Jatuh','問題','1,2',Null,Null,15,5,2,58,58,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20501,'Irrigation Bet','Irrigation Bet (Evidence)',302,'Problems',20000,20500,400,400,10,1,Null,Null,Null,25501,Null,Null,0,0,5,'Evidence','2020/10/20 22:58:31','灌水投注','Cược Sập giá','การพนันราคาล่ม','Taruhan Harga Jatuh','問題','1,2',Null,Null,15,5,2,78,58,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20502,'Irrigation Bet','Irrigation Bet(M)',302,'Problems',20000,20500,400,400,10,1,Null,Null,Null,25502,Null,Null,0,0,5,'NAP','2020/07/26 22:29:56','灌水投注','Cược Sập giá','การพนันราคาล่ม','Taruhan Harga Jatuh','問題','1,2',Null,Null,15,5,2,158,58,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20503,'Irrigation Bet','Irrigation Bet - Abnormal Account, IssueType:13',302,'Problems',20000,20500,400,400,10,1,Null,Null,Null,25503,Null,106,0,0,5,'NAP','2023/04/18 22:30:04','灌水投注','Cược Sập giá','การพนันราคาล่ม','Taruhan Harga Jatuh','問題','1,2',Null,Null,15,5,2,177,58,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20600,'Formula Bet','System Formula Bet',303,'Problems',20000,20600,400,400,10,1,Null,Null,10,25600,Null,38,0,0,6,'NAP','2020/07/26 22:29:56','系统计算投注','Cược Công thức','การเดิมพันสูตร','Taruhan Formula','問題','2',Null,Null,16,6,2,59,59,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20601,'Formula Bet','System Formula Bet (Evidence)',303,'Problems',20000,20600,400,400,10,1,Null,Null,10,25601,Null,Null,0,0,6,'Evidence','2020/10/20 22:58:31','系统计算投注','Cược Công thức','การเดิมพันสูตร','Taruhan Formula','問題','2',Null,Null,16,6,2,79,59,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20602,'Formula Bet','System Formula Bet(M)',303,'Problems',20000,20600,400,400,10,1,Null,Null,10,25602,Null,Null,0,0,6,'NAP','2020/07/26 22:29:56','系统计算投注','Cược Công thức','การเดิมพันสูตร','Taruhan Formula','問題','2',Null,Null,16,6,2,159,59,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20603,'Formula Bet','System Formula Bet - Abnormal Account, IssueType:13',303,'Problems',20000,20600,400,400,10,1,Null,Null,10,25603,Null,107,0,0,6,'NAP','2023/04/18 22:30:04','系统计算投注','Cược Công thức','การเดิมพันสูตร','Taruhan Formula','問題','2',Null,Null,16,6,2,178,59,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20700,'Bonus Hunter','Bonus Hunter',11,'Problems',20000,20700,400,400,10,0,Null,Null,Null,25700,Null,0,0,0,8,'NAP','2020/10/20 22:58:15','赏金猎人',Null,Null,Null,'問題',Null,Null,Null,18,Null,2,60,60,Null,Null,'Problems','問題','问题',Null,Null,Null,6),
(20701,'Bonus Hunter','Bonus Hunter (Evidence)',11,'Problems',20000,20700,400,400,10,0,Null,Null,Null,25701,Null,0,0,0,8,'Evidence','2020/10/20 22:58:31','赏金猎人',Null,Null,Null,'問題',Null,Null,Null,18,Null,2,80,60,50,Null,'Problems','問題','问题',Null,Null,Null,6),
(20800,'Info Bet','Info Bet',304,'Problems',20000,20800,400,400,10,1,Null,Null,Null,25800,Null,Null,0,0,7,'NAP','2021/05/14 00:03:06','资讯单','Cược Thông tin','ข้อมูลการเดิมพัน','Informasi Taruhan','問題',Null,Null,Null,19,9,2,62,162,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20801,'Info Bet','Info Bet (Evidence)',304,'Problems',20000,20800,400,400,10,1,Null,Null,Null,25801,Null,Null,0,0,7,'Evidence','2021/05/14 00:03:06','资讯单','Cược Thông tin','ข้อมูลการเดิมพัน','Informasi Taruhan','問題',Null,Null,Null,19,9,2,82,162,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20802,'Info Bet','Info Bet (M)',304,'Problems',20000,20800,400,400,10,1,Null,Null,Null,25802,Null,Null,0,0,7,'NAP','2021/05/14 00:03:06','资讯单','Cược Thông tin','ข้อมูลการเดิมพัน','Informasi Taruhan','問題',Null,Null,Null,19,9,2,162,162,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(20900,'System Detect Group Betting','System Detect Group Betting',3101,'Problems',20000,20900,400,400,10,1,Null,Null,8,25900,Null,Null,0,0,Null,'CTS','2022/09/19 23:30:07','系统侦测群组投注','Hệ thống phát hiện Cược Nhóm','ระบบตรวจจับการเดิมพันกลุ่ม','Sistem Deteksi Taruhan Grup','問題',Null,Null,Null,11,1,2,63,63,Null,Null,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(21000,'System Detect Unauthorized Login','System Detect Unauthorized Login',305,'Problems',20000,21000,420,420,10,1,Null,Null,Null,26000,Null,Null,0,0,Null,'CTS','2024/01/15 23:11:53','系统侦测軟件登入','Hệ thống Cảnh Báo Đăng Nhập Bất Thường','ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ','Sistem Peringatan Login Tidak Biasa','問題',Null,Null,Null,Null,Null,2,64,64,Null,Null,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',6),
(21100,'Robot User','Robot User',300,'Robot',20000,21100,500,500,10,1,Null,Null,13,26100,Null,Null,0,0,Null,'AI','2022/03/02 02:42:36','机械玩家','Người dùng Robot','ผู้ใช้งานโรบอท','Pengguna Robot','機械','2',Null,Null,Null,Null,2,163,163,Null,Null,'Robot','機械','机械','Robot','บอท','Robot',6),
(21101,'Robot User','Robot User (Evidence)',Null,'Robot',20000,21100,400,400,10,0,Null,Null,Null,Null,Null,0,0,0,Null,'Evidence','2021/05/14 00:03:06','机械用户',Null,Null,Null,'機械',Null,Null,Null,16,6,2,161,61,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(21103,'Robot User','Robot User - Abnormal Account, IssueType:13',13,'Robot',20000,21100,400,400,10,0,Null,Null,13,21700,Null,105,0,0,Null,'NAP','2023/04/18 22:30:04','机械用户',Null,Null,Null,'機械',Null,Null,Null,16,6,2,179,61,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(21200,'Odds Crawler Robot','Odds Crawler Robot',3100,'Robot',20000,21200,450,450,10,1,Null,Null,13,26200,Null,Null,0,0,Null,'AI','2023/05/29 00:03:51','机械爬虫','Robot thu thập tỷ lệ cược','หุ่นยนต์รวบรวมอัตราการเดิมพัน','Robot mengumpulkan taruhan odds','機械','2',Null,Null,Null,Null,2,165,165,Null,Null,'Robot','機械','机械','Robot','บอท','Robot',6),
(21300,'Abnormal','Abnormal',Null,Null,20000,21300,400,400,10,0,Null,Null,Null,Null,Null,27,0,0,Null,'NAP','2020/07/26 22:29:56','非正常',Null,Null,Null,Null,Null,Null,Null,Null,Null,2,51,51,Null,Null,Null,Null,Null,Null,Null,Null,6),
(21302,'Abnormal','Abnormal(M)',Null,Null,20000,21300,400,400,10,0,Null,Null,Null,Null,Null,Null,0,0,Null,'NAP','2020/07/26 22:29:56','非正常',Null,Null,Null,Null,Null,Null,Null,Null,Null,2,151,51,Null,Null,Null,Null,Null,Null,Null,Null,6),
(21303,'Abnormal','Abnormal - Abnormal Account, IssueType:13',Null,Null,20000,21300,400,400,10,1,Null,Null,Null,Null,Null,39,0,0,Null,'NAP','2023/04/18 22:30:04','非正常',Null,Null,Null,Null,Null,Null,Null,Null,Null,2,171,51,Null,Null,Null,Null,Null,Null,Null,Null,6),
(21402,'Others','Others(M)',Null,Null,20000,21400,400,400,10,0,Null,Null,Null,Null,Null,Null,0,0,Null,'NAP','2020/07/26 22:29:56',Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,2,160,Null,Null,Null,Null,Null,Null,Null,Null,Null,6),
(21500,'AB Bet','AB Bet',11,'Problems',20000,21500,400,400,10,0,Null,Null,Null,Null,Null,32,0,0,Null,'NAP','2020/07/26 22:29:56','AB投注',Null,Null,Null,'問題',Null,Null,Null,17,Null,2,56,56,49,Null,'Problems','問題','问题',Null,Null,Null,6),
(21501,'AB Bet','AB Bet (Evidence)',11,'Problems',20000,21500,400,400,10,0,Null,Null,Null,Null,Null,32,0,0,Null,'Evidence','2020/10/20 22:58:31','AB投注',Null,Null,Null,'問題',Null,Null,Null,17,Null,2,76,56,49,Null,'Problems','問題','问题',Null,Null,Null,6),
(21502,'AB Bet','AB Bet(M)',11,'Problems',20000,21500,400,400,10,0,Null,Null,Null,Null,Null,106,0,0,Null,'NAP','2020/07/26 22:29:56','AB投注',Null,Null,Null,'問題',Null,Null,Null,17,Null,2,156,56,49,Null,'Problems','問題','问题',Null,Null,Null,6),
(21503,'AB Bet','AB Bet - Abnormal Account, IssueType:13',11,'Problems',20000,21500,400,400,10,0,Null,Null,Null,Null,Null,104,0,0,Null,'NAP','2023/04/18 22:30:04','AB投注',Null,Null,Null,'問題',Null,Null,Null,17,Null,2,176,56,49,Null,'Problems','問題','问题',Null,Null,Null,6),
(21600,'Robot Betting','Robot Betting',13,'Robot',20000,21600,400,400,10,0,Null,Null,13,Null,Null,229,0,0,Null,'NAP','2020/07/26 22:29:56','机器人投注',Null,Null,Null,'機械',Null,Null,Null,Null,Null,2,57,57,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(21602,'Robot Betting','Robot Betting(M)',13,'Robot',20000,21600,400,400,10,0,Null,Null,13,Null,Null,107,0,0,Null,'NAP','2020/07/26 22:29:56','机器人投注',Null,Null,Null,'機械',Null,Null,Null,Null,Null,2,157,57,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(21700,'Robot User','Robot User',13,'Robot',20000,21700,400,400,10,0,Null,Null,13,21700,Null,36,0,0,Null,'NAP','2021/03/21 23:33:47','机械用户',Null,Null,Null,'機械',Null,Null,Null,16,6,2,61,61,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(21701,'Robot User','Robot User (Evidence)',Null,'Robot',20000,21700,400,400,10,0,Null,Null,Null,Null,Null,0,0,0,Null,'Evidence','2021/05/14 00:03:06','机械用户',Null,Null,Null,'機械',Null,Null,Null,16,6,2,81,61,Null,Null,'Robot','機械','机械',Null,Null,Null,6),
(25100,'Group Betting (Losing)','Group Betting (Probation)',3001,'Problems -',20000,25100,400,400,10,1,Null,Null,8,20100,Null,28,1,1,1,'NAP','2022/04/24 23:27:55','群组投注 (输钱)','Cược Nhóm (Thua)','การเดิมพันกลุ่ม (แพ้)','Taruhan Grup (Kalah)','問題-','1,2',Null,Null,11,1,2,92,92,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25101,'Group Betting (Losing)','Group Betting (Evidence - Probation)',3001,'Problems -',20000,25100,400,400,10,1,Null,Null,8,20101,Null,Null,1,1,1,'Evidence','2022/04/24 23:27:55','群组投注 (输钱)','Cược Nhóm (Thua)','การเดิมพันกลุ่ม (แพ้)','Taruhan Grup (Kalah)','問題-','1,2',Null,Null,11,1,2,112,92,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25102,'Group Betting (Losing)','Group Betting (M - Probation)',3001,'Problems -',20000,25100,400,400,10,1,Null,Null,8,20102,Null,Null,1,1,1,'NAP','2022/04/24 23:27:55','群组投注 (输钱)','Cược Nhóm (Thua)','การเดิมพันกลุ่ม (แพ้)','Taruhan Grup (Kalah)','問題-','1,2',Null,Null,11,1,2,132,92,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25103,'Group Betting (Losing)','Group Betting (Probation) - Abnormal Account, IssueType:13',3001,'Problems -',20000,25100,400,400,10,1,Null,Null,8,20103,Null,100,1,1,1,'NAP','2023/04/18 22:30:04','群组投注 (输钱)','Cược Nhóm (Thua)','การเดิมพันกลุ่ม (แพ้)','Taruhan Grup (Kalah)','問題-','1,2',Null,Null,11,1,2,180,92,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25200,'Hedging (Losing)','Hedging (Probation)',3003,'Problems -',20000,25200,400,400,10,1,Null,Null,10,20200,1,29,1,1,2,'NAP','2022/04/24 23:27:55','出货群组 (输钱)','Cượ̣c Bảo hiểm (Thua)','การเดิมพันประกันภัย (แพ้)','Taruhan Asuransi (Kalah)','問題-','2',Null,Null,14,4,2,93,93,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25201,'Hedging (Losing)','Hedging (Evidence - Probation)',3003,'Problems -',20000,25200,400,400,10,1,Null,Null,10,20201,1,Null,1,1,2,'Evidence','2022/04/24 23:27:55','出货群组 (输钱)','Cượ̣c Bảo hiểm (Thua)','การเดิมพันประกันภัย (แพ้)','Taruhan Asuransi (Kalah)','問題-','2',Null,Null,14,4,2,113,93,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25202,'Hedging (Losing)','Hedging (M - Probation)',3003,'Problems -',20000,25200,400,400,10,1,Null,Null,10,20202,1,Null,1,1,2,'NAP','2022/04/24 23:27:55','出货群组 (输钱)','Cượ̣c Bảo hiểm (Thua)','การเดิมพันประกันภัย (แพ้)','Taruhan Asuransi (Kalah)','問題-','2',Null,Null,14,4,2,133,93,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25203,'Hedging (Losing)','Hedging (Probation) - Abnormal Account, IssueType:13',3003,'Problems -',20000,25200,400,400,10,1,Null,Null,10,20203,1,101,1,1,2,'NAP','2023/04/18 22:30:04','出货群组 (输钱)','Cượ̣c Bảo hiểm (Thua)','การเดิมพันประกันภัย (แพ้)','Taruhan Asuransi (Kalah)','問題-','2',Null,Null,14,4,2,181,93,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25300,'Arbitrage (Losing)','Arbitrage (Probation)',3002,'Problems -',20000,25300,400,400,10,1,Null,Null,Null,20300,Null,30,1,1,3,'NAP','2022/04/24 23:27:55','打水套利 (输钱)','Cược Chênh lệch (Thua)','การเดิมพันตามผลต่าง (แพ้)','Taruhan Selisih (Kalah)','問題-','1,2',Null,Null,13,3,2,94,94,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25301,'Arbitrage (Losing)','Arbitrage (Evidence - Probation)',3002,'Problems -',20000,25300,400,400,10,1,Null,Null,Null,20301,Null,Null,1,1,3,'Evidence','2022/04/24 23:27:55','打水套利 (输钱)','Cược Chênh lệch (Thua)','การเดิมพันตามผลต่าง (แพ้)','Taruhan Selisih (Kalah)','問題-','1,2',Null,Null,13,3,2,114,94,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25302,'Arbitrage (Losing)','Arbitrage (M - Probation)',3002,'Problems -',20000,25300,400,400,10,1,Null,Null,Null,20302,Null,Null,1,1,3,'NAP','2022/04/24 23:27:55','打水套利 (输钱)','Cược Chênh lệch (Thua)','การเดิมพันตามผลต่าง (แพ้)','Taruhan Selisih (Kalah)','問題-','1,2',Null,Null,13,3,2,134,94,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25303,'Arbitrage (Losing)','Arbitrage (Probation) - Abnormal Account, IssueType:13',3002,'Problems -',20000,25300,400,400,10,1,Null,Null,Null,20303,Null,102,1,1,3,'NAP','2023/04/18 22:30:04','打水套利 (输钱)','Cược Chênh lệch (Thua)','การเดิมพันตามผลต่าง (แพ้)','Taruhan Selisih (Kalah)','問題-','1,2',Null,Null,13,3,2,182,94,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25400,'Fixed Game (Losing)','Fixed Game (Probation)',3003,'Problems -',20000,25400,400,400,10,1,Null,Null,10,20400,Null,31,1,1,4,'NAP','2022/04/24 23:27:55','内定赛事 (输钱)','Dàn xếp tỷ số (Thua)','การจัดระบบคะแนน (แพ้)','Mengatur skor (Kalah)','問題-','2',Null,Null,12,2,2,95,95,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25401,'Fixed Game (Losing)','Fixed Game (Evidence - Probation)',3003,'Problems -',20000,25400,400,400,10,1,Null,Null,10,20401,Null,Null,1,1,4,'Evidence','2022/04/24 23:27:55','内定赛事 (输钱)','Dàn xếp tỷ số (Thua)','การจัดระบบคะแนน (แพ้)','Mengatur skor (Kalah)','問題-','2',Null,Null,12,2,2,115,95,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25402,'Fixed Game (Losing)','Fixed Game (M - Probation)',3003,'Problems -',20000,25400,400,400,10,1,Null,Null,10,20402,Null,Null,1,1,4,'NAP','2022/04/24 23:27:55','内定赛事 (输钱)','Dàn xếp tỷ số (Thua)','การจัดระบบคะแนน (แพ้)','Mengatur skor (Kalah)','問題-','2',Null,Null,12,2,2,135,95,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25403,'Fixed Game (Losing)','Fixed Game (Probation) - Abnormal Account, IssueType:13',3003,'Problems -',20000,25400,400,400,10,1,Null,Null,10,20403,Null,103,1,1,4,'NAP','2023/04/18 22:30:04','内定赛事 (输钱)','Dàn xếp tỷ số (Thua)','การจัดระบบคะแนน (แพ้)','Mengatur skor (Kalah)','問題-','2',Null,Null,12,2,2,183,95,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25500,'Irrigation Bet (Losing)','Irrigation Bet (Probation)',3002,'Problems -',20000,25500,400,400,10,1,Null,Null,Null,20500,Null,37,1,1,5,'NAP','2022/04/24 23:27:55','灌水投注 (输钱)','Cược Sập giá (Thua)','การพนันราคาล่ม (แพ้)','Taruhan Harga Runtuh (Kalah)','問題-','1,2',Null,Null,15,5,2,98,98,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25501,'Irrigation Bet (Losing)','Irrigation Bet (Evidence - Probation)',3002,'Problems -',20000,25500,400,400,10,1,Null,Null,Null,20501,Null,Null,1,1,5,'Evidence','2022/04/24 23:27:55','灌水投注 (输钱)','Cược Sập giá (Thua)','การพนันราคาล่ม (แพ้)','Taruhan Harga Runtuh (Kalah)','問題-','1,2',Null,Null,15,5,2,118,98,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25502,'Irrigation Bet (Losing)','Irrigation Bet (M - Probation)',3002,'Problems -',20000,25500,400,400,10,1,Null,Null,Null,20502,Null,Null,1,1,5,'NAP','2022/04/24 23:27:55','灌水投注 (输钱)','Cược Sập giá (Thua)','การพนันราคาล่ม (แพ้)','Taruhan Harga Runtuh (Kalah)','問題-','1,2',Null,Null,15,5,2,138,98,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25503,'Irrigation Bet (Losing)','Irrigation Bet (Probation) - Abnormal Account, IssueType:13',3002,'Problems -',20000,25500,400,400,10,1,Null,Null,Null,20503,Null,106,1,1,5,'NAP','2023/04/18 22:30:04','灌水投注 (输钱)','Cược Sập giá (Thua)','การพนันราคาล่ม (แพ้)','Taruhan Harga Runtuh (Kalah)','問題-','1,2',Null,Null,15,5,2,184,98,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25600,'Formula Bet (Losing)','System Formula Bet (Probation)',3003,'Problems -',20000,25600,400,400,10,1,Null,Null,10,20600,Null,38,1,1,6,'NAP','2022/04/24 23:27:55','机械/系统计算投注 (输钱)','Cược Công thức (Thua)','การเดิมพันสูตร (แพ้)','Taruhan Formula (Kalah)','問題-','2',Null,Null,16,6,2,99,99,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25601,'Formula Bet (Losing)','System Formula Bet (Evidence - Probation)',3003,'Problems -',20000,25600,400,400,10,1,Null,Null,10,20601,Null,Null,1,1,6,'Evidence','2022/04/24 23:27:55','机械/系统计算投注 (输钱)','Cược Công thức (Thua)','การเดิมพันสูตร (แพ้)','Taruhan Formula (Kalah)','問題-','2',Null,Null,16,6,2,119,99,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25602,'Formula Bet (Losing)','System Formula Bet (M - Probation)',3003,'Problems -',20000,25600,400,400,10,1,Null,Null,10,20602,Null,Null,1,1,6,'NAP','2022/04/24 23:27:55','机械/系统计算投注 (输钱)','Cược Công thức (Thua)','การเดิมพันสูตร (แพ้)','Taruhan Formula (Kalah)','問題-','2',Null,Null,16,6,2,139,99,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25603,'Formula Bet (Losing)','System Formula Bet (Probation) - Abnormal Account, IssueType:13',3003,'Problems -',20000,25600,400,400,10,1,Null,Null,10,20603,Null,107,1,1,6,'NAP','2023/04/18 22:30:04','机械/系统计算投注 (输钱)','Cược Công thức (Thua)','การเดิมพันสูตร (แพ้)','Taruhan Formula (Kalah)','問題-','2',Null,Null,16,6,2,185,99,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25700,'Bonus Hunter (Losing)','Bonus Hunter (Probation)',116,'Problems -',20000,25700,400,400,10,0,Null,Null,Null,20700,Null,0,1,1,8,'NAP','2022/04/24 23:27:55','赏金猎人 (输钱)',Null,Null,Null,'問題-',Null,Null,Null,18,Null,2,100,100,Null,Null,'Problems','問題','问题',Null,Null,Null,7),
(25701,'Bonus Hunter (Losing)','Bonus Hunter (Evidence - Probation)',116,'Problems -',20000,25700,400,400,10,0,Null,Null,Null,20701,Null,0,1,1,8,'Evidence','2022/04/24 23:27:55','赏金猎人 (输钱)',Null,Null,Null,'問題-',Null,Null,Null,18,Null,2,120,100,50,Null,'Problems','問題','问题',Null,Null,Null,7),
(25800,'Info Bet (Losing)','Info Bet (Probation)',3004,'Problems -',20000,25800,400,400,10,1,Null,Null,Null,20800,Null,Null,1,1,7,'NAP','2022/04/24 23:27:55','资讯单投注 (输钱)','Cượ̣c Thông tin (Thua)','การเดิมพันข้อมูล (แพ้)','Informasi Taruhan (Kalah)','問題-',Null,Null,Null,19,9,2,102,102,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25801,'Info Bet (Losing)','Info Bet (Evidence - Probation)',3004,'Problems -',20000,25800,400,400,10,1,Null,Null,Null,20801,Null,Null,1,1,7,'Evidence','2022/04/24 23:27:55','资讯单投注 (输钱)','Cượ̣c Thông tin (Thua)','การเดิมพันข้อมูล (แพ้)','Informasi Taruhan (Kalah)','問題-',Null,Null,Null,19,9,2,122,102,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25802,'Info Bet (Losing)','Info Bet (M - Probation)',3004,'Problems -',20000,25800,400,400,10,1,Null,Null,Null,20802,Null,Null,1,1,7,'NAP','2022/04/24 23:27:55','资讯单投注 (输钱)','Cượ̣c Thông tin (Thua)','การเดิมพันข้อมูล (แพ้)','Informasi Taruhan (Kalah)','問題-',Null,Null,Null,19,9,2,142,102,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(25900,'System Detect Group Betting (Losing)','System Detect Group Betting (Losing)',3201,'Problems -',20000,25900,400,400,10,1,Null,Null,8,20900,Null,Null,1,1,Null,'CTS','2022/09/19 23:30:07','系统侦测群组投注 (输钱)','Hệ thống phát hiện Cược Nhóm (Thua)','ระบบตรวจจับการพนันกลุ่ม (แพ้)','Sistem Deteksi Taruhan Grup (Kalah)','問題-',Null,Null,Null,11,1,2,103,103,Null,Null,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(26000,'System Detect Unauthorized Login (Losing)','System Detect Unauthorized Login (Losing)',3005,'Problems -',20000,26000,420,420,10,1,Null,Null,Null,21000,Null,Null,1,1,Null,'CTS','2024/01/15 23:11:53','系统侦测軟件登入（输钱）','Hệ thống Cảnh Báo Đăng Nhập Bất Thường (Thua)','ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ (แพ้)','Sistem Peringatan Login Tidak Biasa (Kalah)','問題-',Null,Null,Null,Null,Null,2,104,104,Null,Null,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah',7),
(26100,'Robot User (Losing)','Robot User (Losing)',3000,'Robot',20000,26100,500,500,10,1,Null,Null,13,21100,Null,Null,1,1,Null,'AI','2022/03/02 02:42:36','机械玩家 (输钱)','Người dùng Robot (Thua)','ผู้ใช้งานหุ่นยนต์ (แพ้)','Pengguna Robot (Kalah)','機械','2',Null,Null,Null,Null,2,164,164,Null,Null,'Robot','機械','机械','Robot','บอท','Robot',7),
(26200,'Odds Crawler Robot (Losing)','Odds Crawler Robot (Losing)',3200,'Robot',20000,26200,450,450,10,1,Null,Null,13,21200,Null,Null,1,1,Null,'AI','2023/05/29 00:03:51','机械爬虫 (输钱)','Robot thu thập tỷ lệ cược (Thua)','หุ่นยนต์รวบรวมอัตราการเดิมพัน (แพ้)','Robot mengumpulkan peluang taruhan (Kalah)','機械','2',Null,Null,Null,Null,2,166,166,Null,Null,'Robot','機械','机械','Robot','บอท','Robot',7),
(30100,'Early Warning Members','Early Warning Members',2800,'Dangerous',30000,30100,530,530,30,1,Null,Null,Null,35100,Null,Null,0,0,Null,'AI','2024/04/07 23:34:52','预警会员','Thành viên cảnh báo sớm','สมาชิกที่ได้รับการแจ้งเตือนล่วงหน้า','Anggota Peringatan Dini','危險',Null,Null,Null,Null,Null,Null,65,65,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(30200,'Initial Smart','Initial Smart',2700,'Dangerous',30000,30200,560,560,30,1,Null,Null,Null,35200,Null,Null,0,0,Null,'','2024/06/02 22:59:59','初始精明玩家','Cược Thông Minh','นักเดิมพันฉลาดเบื้องต้น','Pemain Pintar Awal','危險',Null,Null,Null,Null,Null,Null,66,66,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(30300,'Initial Group Betting','Initial Group Betting',2600,'Dangerous',30000,30300,570,570,30,1,Null,Null,Null,35300,Null,Null,0,0,Null,'CTS','2024/05/15 23:32:15','初始群组投注','Cược Nhóm Khởi Đầu','การเดิมพันกลุ่มเบื้องต้น','Taruhan Grup Awal','危險',Null,Null,Null,Null,Null,Null,67,67,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(35100,'Early Warning Members (Losing)','Early Warning Members (Losing)',2801,'Dangerous-',30000,35100,530,530,30,1,Null,Null,Null,30100,Null,Null,1,1,Null,'AI','2024/04/07 23:34:52','预警会员 (输钱)','Thành viên cảnh báo sớm (Thua)','สมาชิกที่ได้รับการเตือนล่วงหน้า (ขาดทุน)','Anggota Peringatan Dini (Kalah)','危險 -',Null,Null,Null,Null,Null,Null,105,105,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',5),
(35200,'Initial Smart (Losing)','Initial Smart (Losing)',2701,'Dangerous -',30000,35200,560,560,30,1,Null,Null,Null,30200,Null,Null,1,1,Null,'','2024/06/02 22:59:59','初始精明玩家 (输钱)','Cược Thông Minh (Thua)','นักเดิมพันฉลาดเริ่มต้น (ขาดทุน)','Pemain Pintar Awal (Kalah)','危險-',Null,Null,Null,Null,Null,Null,106,106,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',5),
(35300,'Initial Group Betting (Losing)','Initial Group Betting (Losing)',2601,'Dangerous -',30000,35300,570,570,30,1,Null,Null,Null,30300,Null,Null,1,1,Null,'CTS','2024/05/15 23:32:15','初始群组投注 (输钱)','Cược Nhóm Khởi Đầu (Thua)','การเดิมพันกลุ่มเริ่มต้น (ขาดทุน)','Taruhan Grup Awal (Kalah)','危險-',Null,Null,Null,Null,Null,Null,107,107,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',5),
(40100,'New','New Member',200,'New',40000,40100,1000,1000,30,1,Null,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','新会员','Mới','ใหม่','Baru','新會員',Null,0,0,Null,Null,1,201,201,Null,Null,'New','新玩家','新玩家','Mới','นักเดิมพันใหม่','Baru',1),
(40101,'New linked Robot','New Member (33)',2000,'Suspicious +',40000,40100,800,800,20,1,Null,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/01/28 03:26:29','新会员关联机械投注会员','Mới đã liên kết Robot','ใหม่ได้เชื่อมโยงกับหุ่นยนต์แล้ว','Baru telah terhubung Robot','可疑+',Null,13,1,Null,Null,1,233,201,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',3),
(40102,'New linked Group','New Member (31)',2100,'Suspicious',40000,40100,800,800,20,1,Null,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/01/28 03:26:29','新会员关联群组投注会员','Mới đã liên kết Nhóm','ใหม่ได้เชื่อมโยงกับกลุ่มแล้ว','Baru telah terhubung Grup','可疑',Null,8,1,Null,Null,1,231,201,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',3),
(40103,'New linked PA','New Member (32)',2200,'Suspicious',40000,40100,800,800,20,1,Null,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/01/28 03:26:29','新会员关联问题会员','Mới đã liên kết PA','เพิ่งเชื่อมโยง PA แล้ว','Baru saja terhubung dengan PA','可疑',Null,10,1,Null,Null,1,232,201,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',3),
(40104,'New Group Betting','New Member',2300,'Dangerous -',40000,40100,600,600,30,0,Null,Null,Null,Null,Null,Null,0,0,Null,Null,'2023/11/21 23:36:20','新群组投注玩家','Nhóm Cược Mới','กลุ่มเดิมพันใหม่','Grup Taruhan Baru','危險-',Null,9,2,Null,Null,1,239,201,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',3),
(40106,'New (Lic Sub)','New Member (43)',2500,'New',40000,40100,550,550,30,0,Null,Null,Null,Null,Null,Null,0,1,Null,Null,'2022/03/23 05:42:14','新注册玩家','Mới (tuyến phụ)','ใหม่ (สายรอง)','Baru (jalur sekunder)','新會員',Null,Null,Null,Null,Null,1,234,201,Null,Null,'New','新玩家','新玩家','Mới','นักเดิมพันใหม่','Baru',Null),
(40200,'Good','Good Member',201,'Healthy +',40000,40200,1000,1000,30,1,604800,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','优质会员','Tốt','ดี','Baik','健康+',Null,0,0,Null,Null,1,205,205,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',1),
(40201,'Good linked Robot','Good Member (113)',2001,'Healthy -',40000,40200,800,800,20,1,604800,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','优质会员关联机械投注会员','Tốt đã liên kết Robot','หุ่นยนต์ได้เชื่อมต่อแล้ว','Robot telah terhubung dengan baik','健康-',Null,13,1,Null,Null,1,213,205,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',3),
(40202,'Good linked Group','Good Member (111)',2101,'Healthy -',40000,40200,800,800,20,1,604800,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','优质会员关联群组投注会员','Tốt đã liên kết Nhóm','ดีแล้วที่เชื่อมโยงกับกลุ่ม','Baik telah terhubung dengan Grup','健康-',Null,8,1,Null,Null,1,211,205,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',3),
(40203,'Good linked PA','Good Member (112)',2201,'Healthy -',40000,40200,800,800,20,1,604800,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','优质会员关联问题会员','Tốt đã liên kết PA','PA ได้เชื่อมต่อแล้ว','Baik telah terhubung PA','健康-',Null,10,1,Null,Null,1,212,205,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',3),
(40300,'Normal','Normal Account',202,'Healthy',40000,40300,1000,1000,30,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','普通会员','Bình thường','ปกติ','Biasa','健康',Null,0,0,Null,Null,1,202,202,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',1),
(40301,'Normal linked Robot','Normal Account (123)',2002,'Moderate +',40000,40300,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','普通会员关联机械投注会员','Bình thường đã liên kết Robot','ปกติแล้วเชื่อมต่อกับหุ่นยนต์แล้ว','Biasanya telah terhubung dengan Robot','中等+',Null,13,1,Null,Null,1,223,202,Null,Null,'Moderate','中等','中等','Trung bình','ทั่วไป','Rata-rata',3),
(40302,'Normal linked Group','Normal Account (121)',2102,'Moderate',40000,40300,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','普通会员关联群组投注会员','Bình thường đã liên kết Nhóm','ปกติแล้วได้เชื่อมโยงกับกลุ่มแล้ว','Biasanya telah terhubung Grup','中等',Null,8,1,Null,Null,1,221,202,Null,Null,'Moderate','中等','中等','Trung bình','ทั่วไป','Rata-rata',3),
(40303,'Normal linked PA','Normal Account (122)',2202,'Moderate -',40000,40300,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2021/03/08 23:02:07','普通会员关联问题会员','Bình thường đã liên kết PA','ปกติแล้วได้เชื่อมต่อ PA แล้ว','Biasanya telah terhubung PA','中等-',Null,10,1,Null,Null,1,222,202,Null,Null,'Moderate','中等','中等','Trung bình','ทั่วไป','Rata-rata',3),
(40400,'Probation','Probation',203,'Suspicious',40000,40400,1000,1000,30,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','观察中玩家','Theo dõi','ติดตาม','Pantauan','可疑',Null,0,0,Null,Null,1,206,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',2),
(40401,'Prob linked Robot','Probation (53)',2003,'Suspicious +',40000,40400,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','观察中玩家关联机械投注会员','Theo dõi đã liên kết Robot','ติดตาม Robot ที่เชื่อมต่อแล้ว','Pantauan telah terhubung dengan Robot','可疑+',Null,13,1,Null,Null,1,253,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',4),
(40402,'Prob linked Group','Probation (51)',2103,'Suspicious +',40000,40400,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','观察中玩家关联群组投注会员','Theo dõi đã liên kết Nhóm','ติดตามกลุ่มที่เชื่อมโยงแล้ว','Pantauan telah terhubung dengan Grup','可疑+',Null,8,1,Null,Null,1,251,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',4),
(40403,'Prob linked PA','Probation (52)',2203,'Suspicious +',40000,40400,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','观察中玩家关联问题会员','Theo dõi đã liên kết PA','ติดตาม PA ที่เชื่อมโยงแล้ว','Telah terhubung dengan PA','可疑+',Null,10,1,Null,Null,1,252,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',4),
(40404,'Prob Group Betting','Probation (57)',2303,'Dangerous -',40000,40400,600,600,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','观察中群组投注玩家','Nhóm Cược Theo dõi','กลุ่มการเดิมพันที่ติดตาม','Kelompok Taruhan yang Diikuti','危險-',Null,7,2,Null,Null,1,257,206,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40405,'Prob High Rejected','Probation (58)',2403,'Suspicious -',40000,40400,580,580,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','观察中资讯投注玩家','Nhóm Theo dõi cao bị từ chối','กลุ่มติดตามสูงถูกปฏิเสธ','Grup Pengikut tinggi ditolak','可疑-',Null,8,2,Null,Null,1,258,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',2),
(40406,'Prob (Lic Sub)','Probation (45)',2503,'Suspicious',40000,40400,550,550,30,0,Null,Null,Null,Null,Null,Null,0,0,Null,Null,'2022/03/23 05:42:15','观察中玩家','Theo dõi (tuyến phụ)','ติดตาม (สายรอง)','Pantau (jalur sekunder)','可疑',Null,Null,Null,Null,Null,1,254,206,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan',Null),
(40500,'Smart','Smart Punter',204,'Dangerous',40000,40500,1000,1000,30,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','精明玩家','Thông minh','สมาร์ท','Kecerdasan','危險',Null,0,0,Null,Null,1,203,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40501,'Smart linked Robot','Smart Punter (63)',2004,'Dangerous +',40000,40500,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','精明玩家关联机械投注会员','Thông minh đã liên kết Robot','ระบบปัญญาประดิษฐ์ได้เชื่อมต่อกับหุ่นยนต์แล้ว','Kecerdasan telah terhubung dengan Robot','危險+',Null,13,1,Null,Null,1,263,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40502,'Smart linked Group','Smart Punter (61)',2104,'Dangerous +',40000,40500,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','精明玩家关联群组投注会员','Thông minh đã liên kết Nhóm','อัจฉริยะได้เชื่อมโยงกับกลุ่มแล้ว','Kecerdasan telah terhubung dengan Grup','危險+',Null,8,1,Null,Null,1,261,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40503,'Smart linked PA','Smart Punter (62)',2204,'Dangerous +',40000,40500,800,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','精明玩家关联问题会员','Thông minh đã liên kết PA','PA ได้เชื่อมต่อกับ Thông minh','Kecerdasan telah terhubung dengan PA','危險+',Null,10,1,Null,Null,1,262,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40504,'Smart Group Betting','Smart Punter (67)',2304,'Dangerous -',40000,40500,600,600,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','精明群组投注玩家','Nhóm Cược Thông minh','กลุ่มการเดิมพันอัจฉริยะ','Grup Taruhan Cerdas','危險-',Null,7,2,Null,Null,1,267,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40505,'Smart High Rejected','Smart Punter (68)',2404,'Dangerous -',40000,40500,580,580,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','精明资讯投注玩家','Nhóm Thông minh cao bị từ chối','กลุ่มอัจฉริยะสูงถูกปฏิเสธ','Grup Pintar tinggi ditolak','危險-',Null,8,2,Null,Null,1,268,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40506,'Smart (Lic Sub)','Smart Punter (46)',2504,'Dangerous',40000,40500,550,550,30,0,Null,Null,Null,Null,Null,Null,0,0,Null,Null,'2022/03/23 05:42:15','精明玩家','Thông minh (tuyến phụ)','สมาร์ท (สายรอง)','Kecerdasan (jalur sekunder)','危險',Null,Null,Null,Null,Null,1,264,203,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',Null),
(40600,'Risky','High Risk Punter',205,'Dangerous',40000,40600,1000,1000,30,1,1209600,86400,Null,Null,Null,Null,0,1,Null,Null,'2020/09/04 00:25:30','高危玩家','Rủi ro','ความเสี่ยง','Resiko','危險',Null,0,0,Null,Null,1,204,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40601,'Risky linked Robot','High Risk Punter (73)',2005,'Dangerous +',40000,40600,795,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','高危玩家关联机械投注会员','Rủi ro đã liên kết Robot','ความเสี่ยงที่เชื่อมโยงกับหุ่นยนต์','Risiko telah terhubung Robot','危險+',Null,13,1,Null,Null,1,273,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40602,'Risky linked Group','High Risk Punter (71)',2105,'Dangerous +',40000,40600,795,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','高危玩家关联群组投注会员','Rủi ro đã liên kết Nhóm','ความเสี่ยงที่เชื่อมโยงกับกลุ่ม','Risiko telah terhubung dengan Grup','危險+',Null,8,1,Null,Null,1,271,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40603,'Risky linked PA','High Risk Punter (72)',2205,'Dangerous +',40000,40600,795,800,20,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/03/08 23:02:07','高危玩家关联问题会员','Rủi ro đã liên kết PA','ความเสี่ยงที่เชื่อมโยงกับ PA','Risiko telah terhubung PA','危險+',Null,10,1,Null,Null,1,272,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',4),
(40604,'Risky Group Betting','High Risk Punter (77)',2305,'Dangerous +',40000,40600,595,600,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','高危群组投注玩家','Nhóm Cược Rủi ro','กลุ่มการเดิมพันที่มีความเสี่ยง','Kelompok Taruhan Risiko','危險+',Null,7,2,Null,Null,1,277,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40605,'Risky High Rejected','High Risk Punter (78)',2405,'Dangerous +',40000,40600,575,580,30,1,1209600,86400,Null,Null,Null,Null,0,0,Null,Null,'2021/08/10 23:05:54','高危资讯投注玩家','Nhóm Rủi ro cao bị từ chối','กลุ่มความเสี่ยงสูงถูกปฏิเสธ','Grup Risiko Tinggi ditolak','危險+',Null,8,2,Null,Null,1,278,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2),
(40606,'Risky (Lic Sub)','High Risk Punter (47)',2505,'Dangerous',40000,40600,545,550,30,0,Null,Null,Null,Null,Null,Null,0,0,Null,Null,'2022/03/23 05:42:15','高风险玩家','Rủi ro (tuyến phụ)','ความเสี่ยง (สายรอง)','Risiko (jalur sekunder)','危險',Null,Null,Null,Null,Null,1,274,204,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',Null),
(40700,'Normal (inactive)','Normal Member Inactive',901,'Healthy',40000,40700,1000,1000,40,1,Null,Null,Null,Null,Null,Null,0,1,Null,Null,'2021/07/19 05:13:45','不活跃正常会员','Bình thường (Không hoạt động)','ปกติ (ไม่ทำงาน)','Biasa (Tidak beroperasi)','健康',Null,Null,0,Null,Null,1,1001,1000,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik',1),
(40701,'Smart (inactive)','Pro Punter Inactive',902,'Dangerous -',40000,40700,1000,1000,40,1,Null,Null,Null,Null,Null,Null,0,1,Null,Null,'2021/07/19 05:13:45','不活跃精明玩家','Thông minh (không hoạt động)','สมาร์ท (ไม่ทำงาน)','Pintar (tidak berfungsi)','危險-',Null,Null,0,Null,Null,1,1002,1000,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya',2);



/* 2. CustomerCategorySettings  */
INSERT INTO CustomerCategorySettings(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID)
VALUES(1010,1010,1000,0,0,0,NULL),
(10100,10100,10000,1,1,1,NULL),
(10200,10200,10000,1,1,1,NULL),
(10201,10200,10000,1,1,1,NULL),
(10300,10300,10000,1,1,0,NULL),
(20100,20100,20000,0,1,1,NULL),
(20101,20100,20000,0,1,1,NULL),
(20102,20100,20000,0,1,1,NULL),
(20103,20100,20000,0,1,1,NULL),
(20200,20200,20000,0,1,1,NULL),
(20201,20200,20000,0,1,1,NULL),
(20202,20200,20000,0,1,1,NULL),
(20203,20200,20000,0,1,1,NULL),
(20300,20300,20000,0,1,1,NULL),
(20301,20300,20000,0,1,1,NULL),
(20302,20300,20000,0,1,1,NULL),
(20303,20300,20000,0,1,1,NULL),
(20400,20400,20000,0,1,1,NULL),
(20401,20400,20000,0,1,1,NULL),
(20402,20400,20000,0,1,1,NULL),
(20403,20400,20000,0,1,1,NULL),
(20500,20500,20000,0,1,1,NULL),
(20501,20500,20000,0,1,1,NULL),
(20502,20500,20000,0,1,1,NULL),
(20503,20500,20000,0,1,1,NULL),
(20600,20600,20000,0,1,1,NULL),
(20601,20600,20000,0,1,1,NULL),
(20602,20600,20000,0,1,1,NULL),
(20603,20600,20000,0,1,1,NULL),
(20700,20700,20000,0,1,1,NULL),
(20701,20700,20000,0,1,1,NULL),
(20800,20800,20000,0,1,1,NULL),
(20801,20800,20000,0,1,1,NULL),
(20802,20800,20000,0,1,1,NULL),
(20900,20900,20000,0,1,1,NULL),
(21000,21000,20000,0,1,1,39),
(21100,21100,20000,0,1,1,NULL),
(21101,21100,20000,0,1,1,NULL),
(21103,21100,20000,0,1,1,NULL),
(21200,21200,20000,0,1,1,NULL),
(21300,21300,20000,0,1,1,NULL),
(21302,21300,20000,0,1,1,NULL),
(21303,21300,20000,0,1,1,NULL),
(21402,21400,20000,0,1,1,NULL),
(21500,21500,20000,0,1,1,NULL),
(21501,21500,20000,0,1,1,NULL),
(21502,21500,20000,0,1,1,NULL),
(21503,21500,20000,0,1,1,NULL),
(21600,21600,20000,0,1,1,NULL),
(21602,21600,20000,0,1,1,NULL),
(21700,21700,20000,0,1,1,NULL),
(21701,21700,20000,0,1,1,NULL),
(25100,25100,20000,0,1,1,NULL),
(25101,25100,20000,0,1,1,NULL),
(25102,25100,20000,0,1,1,NULL),
(25103,25100,20000,0,1,1,NULL),
(25200,25200,20000,0,1,1,NULL),
(25201,25200,20000,0,1,1,NULL),
(25202,25200,20000,0,1,1,NULL),
(25203,25200,20000,0,1,1,NULL),
(25300,25300,20000,0,1,1,NULL),
(25301,25300,20000,0,1,1,NULL),
(25302,25300,20000,0,1,1,NULL),
(25303,25300,20000,0,1,1,NULL),
(25400,25400,20000,0,1,1,NULL),
(25401,25400,20000,0,1,1,NULL),
(25402,25400,20000,0,1,1,NULL),
(25403,25400,20000,0,1,1,NULL),
(25500,25500,20000,0,1,1,NULL),
(25501,25500,20000,0,1,1,NULL),
(25502,25500,20000,0,1,1,NULL),
(25503,25500,20000,0,1,1,NULL),
(25600,25600,20000,0,1,1,NULL),
(25601,25600,20000,0,1,1,NULL),
(25602,25600,20000,0,1,1,NULL),
(25603,25600,20000,0,1,1,NULL),
(25700,25700,20000,0,1,1,NULL),
(25701,25700,20000,0,1,1,NULL),
(25800,25800,20000,0,1,1,NULL),
(25801,25800,20000,0,1,1,NULL),
(25802,25800,20000,0,1,1,NULL),
(25900,25900,20000,0,1,1,NULL),
(26000,26000,20000,0,1,1,39),
(26100,26100,20000,0,1,1,NULL),
(26200,26200,20000,0,1,1,NULL),
(30100,30100,30000,0,0,0,48),
(30200,30200,30000,0,0,0,47),
(30300,30300,30000,0,0,0,46),
(35100,35100,30000,0,0,0,48),
(35200,35200,30000,0,0,0,47),
(35300,35300,30000,0,0,0,46),
(40100,40100,40000,0,0,0,42),
(40101,40100,40000,0,0,0,42),
(40102,40100,40000,0,0,0,42),
(40103,40100,40000,0,0,0,42),
(40104,40100,40000,0,0,0,NULL),
(40106,40100,40000,0,0,0,NULL),
(40200,40200,40000,0,0,0,43),
(40201,40200,40000,0,0,0,43),
(40202,40200,40000,0,0,0,43),
(40203,40200,40000,0,0,0,43),
(40300,40300,40000,0,0,0,42),
(40301,40300,40000,0,0,0,42),
(40302,40300,40000,0,0,0,42),
(40303,40300,40000,0,0,0,42),
(40400,40400,40000,0,0,0,42),
(40401,40400,40000,0,0,0,42),
(40402,40400,40000,0,0,0,42),
(40403,40400,40000,0,0,0,42),
(40404,40400,40000,0,0,0,44),
(40405,40400,40000,0,0,0,45),
(40406,40400,40000,0,0,0,NULL),
(40500,40500,40000,0,0,1,42),
(40501,40500,40000,0,0,1,42),
(40502,40500,40000,0,0,1,42),
(40503,40500,40000,0,0,1,42),
(40504,40500,40000,0,0,1,44),
(40505,40500,40000,0,0,1,45),
(40506,40500,40000,0,0,1,NULL),
(40600,40600,40000,0,0,1,42),
(40601,40600,40000,0,0,1,42),
(40602,40600,40000,0,0,1,42),
(40603,40600,40000,0,0,1,42),
(40604,40600,40000,0,0,1,44),
(40605,40600,40000,0,0,1,45),
(40606,40600,40000,0,0,1,NULL),
(40700,40700,40000,0,0,0,49),
(40701,40700,40000,0,0,0,49);

/* 3. CustomerClassification_Remark  */
INSERT INTO CustomerClassification_Remark (RemarkID,RemarkTemplate,Description)
VALUES (1,'Account has less than 10 bets for first time scan','New: New Customer'),
(2,'Re-scan after 10 bets','Other: From New To Normal,VIP/VIP,Normal,Probation,Smart,High Risk...Probation: From New To Probation,Smart,High Risk'),
(3,'Re-scan on Schedule Date','Other: From Normal,VIP To VIP,Normal/ From Probation To Normal,VIP/ From Smart,High Risk To High Risk,Smart...Probation: From Normal,VIP To Probation,Smart,High Risk'),
(4,'Pass 20 days Probation','Other: From Probation To Smart,High Risk'),
(5,'Cannot pass Probation','Probation: From Probation To Probation'),
(6,'Add from NAP CM manually','From NapCM'),
(7,'Add from Evidence manually','From Evidence'),
(8,'Remove Problem Account manually','From PA'),
(9,'Remove Problem Account manually','From Evidence'),
(10,'Add Customer Class manually | [Remark]','From Special CC'),
(11,'Update Category and Customer Class','From Robot'),
(12,'Remove Customer Class manually | [Remark]','From CC'),
(13,'VVIP is marked manually | [Remark]','From VVIP'),
(14,'VVIP is unmarked manually','From VVIP'),
(15,'Re-scan Problem Account by Customer','From PA'),
(16,'Re-scan Problem Account by Customer','From Evidence'),
(17,'Re-scan Normal Account by Customer','From Normal'),
(18,'Inactive account','Inactive account (Normal)'),
(19,'Inactive account','Inactive account (Pro Punter)'),
(20,'Check Normal Category checkbox','Check Normal Category checkbox'),
(21,'Uncheck Normal Category checkbox','Uncheck Normal Category checkbox'),
(22,'Update Problem Account manually','From PA'),
(23,'Re-scan Problem Account',NULL),
(24,'VVIP tag is affected by Super | [Remark]','Mark VVIP For Downline'),
(25,'VVIP tag is affected by Master | [Remark]','Mark VVIP For Downline'),
(26,'VVIP tag is affected by Agent | [Remark]','Mark VVIP For Downline'),
(27,'VVIP untag is affected by Super','Remove VVIP For Downline'),
(28,'VVIP untag is affected by Master','Remove VVIP For Downline'),
(29,'VVIP untag is affected by Agent','Remove VVIP For Downline'),
(30,'VVIP tag is affected by direct upline','Insert New Cust Affected By Upline'),
(31,'Problem Account is marked directly | Win loss: [Winloss] | [Remark]','Problem Account is marked directly'),
(32,'Problem Account is affected by Uplines | Win loss: [Winloss] | [Remark]','Problem Account is affected by Uplines'),
(33,'Problem Account is unmarked directly | [Remark]','Problem Account is unmarked directly'),
(34,'Unmarking Problem Account is affected by Uplines | [Remark]','Unmarking Problem Account is affected by Uplines'),
(35,'Match ID [MatchID] | Win loss: [Winloss]','Auto Mark Group Betting From Match Monitor'),
(36,'Win loss: [Winloss]','Rescan Robot'),
(37,'Insert Robot','Insert Robot'),
(38,'[CategoryName]','Not show Details'),
(39,'First Bet Date: [FBDate] | Detection Date: [DetectedDate] - Bot Trans: [Bot] ([BotPCT]%) - Invalid Browser Info Trans: [InvalidBrowser] ([InvalidBrowserPCT]%) | Win loss: [Winloss]','System Detect Unauthorized Login'),
(40,'Void by RequestID: [TVSRequestID] | Win loss: [Winloss] | Sport: [SportName] | Parlay',NULL),
(41,'Void by BetID | Win loss: [Winloss] | Sport: [SportName] | Parlay',NULL),
(42,'Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]',NULL),
(43,'Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount] | Active Day: [ActiveDays]',NULL),
(44,'Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount] | Group Betting Percent: [TWGBRate]',NULL),
(45,'Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount] | Desktop Percent: [TWDesktopUsageRate] | Reject Percent: [TWTicketRejectRate]',NULL),
(46,'Detection Date: [DetectedDate] - GB Bet Count: [GBTicketCount] - Sport: [SportName] | Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]',NULL),
(47,'Detection Date: [DetectedDate] - Probability Threshold: [Probability] | Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]',NULL),
(48,'Detection Date: [DetectedDate] - Dangerous Score: [DangerousScore]% | Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]',NULL),
(49,'[SourceTypeName]',NULL),
(50,'Counter: [TWRobotCounter] | Win loss: [Winloss]',NULL),
(51,'[Remark] Win loss: [Winloss]',NULL),
(52,'Win loss: [Winloss]',NULL),
(53,'Robot is marked directly | Win loss: [Winloss] | [Remark]',NULL),
(54,'Void by RequestID: [TVSRequestID] | Win loss: [Winloss]',NULL),
(55,'Void by BetID | Win loss: [Winloss]',NULL),
(56,'[Remark] | Win loss: [Winloss]',NULL);


/************************* II. Data Classification ******************************/
/* 1. Customer_InitialGroupBetting - 2600/2601 */

	LOAD DATA LOCAL INFILE 'D:/Tasks/RenovationCC/ListCust_2600_2601.csv'
	INTO TABLE Customer_InitialGroupBetting
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS;

	SELECT 'Customer_InitialGroupBetting', COUNT(1) FROM Customer_InitialGroupBetting;

/* 2. TVSVoidRequest - Replace TVSVoidRequest_History & CTSCustomerClassificationOldCategory  */
	/* select COUNT(1)
	from CTSCustomerClassification
	where IsFromTVS = 1 
	and CategoryID NOT in (57,61,81,157,161,163,164,165,166,179)
	;
	
	172177
	*/
	
	
	
	

/* 3. CTSRobotUser - Replace CTSCustomerClassificationOldCategory  */
	/*
	select CategoryID, count(1)
	from CTSCustomerClassification
	where IsFromCTS = 1
	and CategoryID in (57,61,81,157,161,163,164,165,166,179)
	group by CategoryID
	;
	
	163	1851
	164	579
	
	*/



/* 4. TWRobotUser  - WILL BE INITIAL DATA IN PHASE 2*/
	/*
	select CategoryID, count(1)
	from CTSCustomerClassification
	where IsFromTW = 1
	and CategoryID in (57,61,81,157,161,163,164,165,166,179)
	group by CategoryID
	;
	
	
	163	58566
	164	13018
	*/


/* 5. CTSCustomerClassification  */
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,151,1339367,244);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,51,1339367,160);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,159,79873,78455);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,79,328436,62106);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,164,5053,49785);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,52,55053,133466);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,153,401765,8425);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,155,493474,6557);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,163,115770,132743);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,59,511989,30890);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,55,493474,55961);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,152,20,47132);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,54,55053,5028);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,72,632680,51905);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,74,925145,3725);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,154,2103048,2742);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,158,16653809,712);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,73,401765,7522);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,53,511989,4815);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,58,11646775,339);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,78,10185253,339);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,162,18004048,303);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,119,10728,4941);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,139,10728,6173);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,92,926312,25571);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,99,780963,4329);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,112,24256,8869);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,132,937176,8339);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,103,961597,25117);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,95,61146,9571);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,166,1906349,226);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,63,1473601,61779);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,115,401808,1028);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,75,493474,7437);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,135,401808,882);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,94,1018105,389);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,114,10385702,521);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,134,10385702,349);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,82,19011495,222);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,64,106954653,8917);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,104,107899552,75);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,98,8524996,151);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,118,64906,199);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,138,64906,320);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,113,221583,1826);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,133,221583,1993);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,93,964209,1280);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,165,10569668,233);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,160,4710622,35);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,122,46944498,2);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,0,142,48494430,2);

	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,100,4,858252,38281);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,100,3,1074204,6520);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,100,2,10377395,3654);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,150,105,1111247,1979);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,150,65,1453219,201908);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,150,67,29891364,4257);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,150,106,137009547,48);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,150,66,54367073,4121);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 10000,150,107,119685510,10);

	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,201,344007,14561290);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,202,8765,651329);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,203,87903,665);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,204,1829,8702);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,205,3293,90333);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,206,8143,128202);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,210,2344,2438);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,211,4106654,213);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,212,1310208,352);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,213,7393983,136);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,221,9497807,874);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,222,1182879,1687);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,223,4381410,1141);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,231,16903816,214);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,232,2584728,487);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,233,15050405,291);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,251,8590786,226);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,252,7448749,329);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,253,16055482,152);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,257,4800978,8249);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,258,19381770,76);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,261,33813044,1);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,262,118157726,5);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,263,142366592,1);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,267,59441111,15);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,271,40872275,6);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,272,19761668,155);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,273,1647708,106);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,277,14180580,175);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,278,49139881,2);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,1001,8,65467061);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification( 50000,200,1002,1346,1446543);

	
/* 6. CTSCustomerClassification_History  */

	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History( 50000,0,8,691719);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History( 50000,100,251125211,39515);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History( 50000,150,433274760,211791);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History( 50000,200,820722,141413286);
	
	-- SportGroupID = NULL	MinID = 3675859		Counter = 1,655,192


/* 7. CTSCustomerClassification_Log  - SKIP */


/* 8. CTSCustomerClassificationQueue  - SKIP - WILL BE INITIAL DATA IN PHASE 2*/

/* 9. CTSCustomerClassification_BySport  */
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,201,21938,4656228);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,202,2344,2160858);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,203,56194,1355);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,204,56196,41145);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,205,3293,253378);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,1,206,1829,753258);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,201,3562,2315386);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,202,3293,620556);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,203,1485650,912);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,204,2344,14934);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,205,5053,76399);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,2,206,917156,307753);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,201,608032,322953);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,202,810408,80720);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,203,1416276,1934);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,204,2037494,1320);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,205,1025821,10291);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,43,206,980528,37158);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,201,3293,1669282);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,202,8634,189516);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,203,402076,2444);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,204,985371,1924);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,205,55901,29806);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,99,206,405952,65257);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,201,8634,637333);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,202,12063,334211);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,203,8535866,199);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,204,12381144,228);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,205,190264,29095);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,145,206,755416,87506);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,201,5053,998608);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,202,0,317295);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,203,1423112,261);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,204,15262797,751);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,205,3293,185469);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,229,206,668206,44030);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,201,431580,210213);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,202,1032857,49595);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,203,405747,720);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,204,1940292,2426);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,205,937400,8588);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport( 50000,912,206,1001546,15658);



/* 10. CTSCustomerClassification_BySport_History  */
	/*
	DataSource						SportID			MinID				Counter
	CTSCustClassifi_BySport_History	1				815					11,815,675
	CTSCustClassifi_BySport_History	2				328					4,518,641
	CTSCustClassifi_BySport_History	43				3427				554,521
	CTSCustClassifi_BySport_History	99				8					2,062,883
	CTSCustClassifi_BySport_History	145				22599626			1,707,237
	CTSCustClassifi_BySport_History	229				10056402			2,395,285
	CTSCustClassifi_BySport_History	912				22599664			375,951
	*/

	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,1,815,11815675);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,2,328,4518641);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,43,3427,554521);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,99,8,2062883);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,145,22599626,1707237);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,229,10056402,2395285);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History( 50000,912,22599664,375951);


/* 11. CTSCustomerClassification_BySport_Log - SKIP */


/* 12. ArchiveCustomer_CTSCustomer  */
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,201,28584246,65);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,202,35827191,1);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,204,35822903,1);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,205,35822848,8);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 50000,1001,27599254,26657731);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 50000,1002,27599279,243987);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,210,44458862,24);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,2,42997317,4);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,3,27603378,456);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,4,27599256,6987);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,51,27627093,10);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,52,27600999,21936);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,53,27635925,3722);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,54,27610909,433);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,55,27601423,13318);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,58,37014238,46);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,59,27599364,16551);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,63,27599315,1028);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,72,27599835,4530);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,73,43003175,321);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,74,27640553,154);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,75,27611819,1722);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,78,40608985,2);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,79,27601593,677);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,82,27732634,17);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,92,27599423,1030);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,93,27723280,870);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,94,27602137,106);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,95,27599655,1925);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,98,27812681,44);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,99,27600708,4019);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,103,27599277,425);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,112,27599435,740);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,113,27929684,47);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,114,27601988,10);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,115,27607570,46);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,118,39655504,2);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,119,27723312,58);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,132,27599283,476);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,133,40839821,158);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,134,27812686,19);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,135,27602462,82);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,138,39655501,7);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,139,27599478,384);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,142,28000053,2);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,152,27599460,10708);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,153,27869036,722);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,154,27616668,289);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,155,27611441,1669);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,158,28130196,17);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,159,27599493,7547);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,162,27680788,106);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,163,27599732,17979);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,164,27599255,8860);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,165,27752942,7);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_ArchiveCustomer_CTSCustomer( 5000,166,44717493,1);


