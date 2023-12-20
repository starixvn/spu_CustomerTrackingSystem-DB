/*<info serverAlias=CTSMain-CTS_DataCenter databaseType=2></info>*/
/*
Creator:	20231219@Long.Luu
Task:	 	Support more languages for CustomerClass
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231219@Long.Luu: Support more languages for CustomerClass [Redmine ID: #198364]

*/

USE CTS_DataCenter;

alter table CustomerCategory add CategoryNameCN3 varchar(50) after CategoryNameCN;
alter table CustomerCategory add CategoryNameTHB varchar(50) after CategoryNameCN3;
alter table CustomerCategory add CategoryNameIND varchar(50) after CategoryNameTHB;
alter table CustomerCategory add SabaIntelligent_RiskLevel_CN3 varchar(50) after SabaIntelligent_RiskLevel_SCN;
alter table CustomerCategory add SabaIntelligent_RiskLevel_THB varchar(50) after SabaIntelligent_RiskLevel_CN3;
alter table CustomerCategory add SabaIntelligent_RiskLevel_IND varchar(50) after SabaIntelligent_RiskLevel_THB;

set sql_safe_updates = 0;

update CustomerCategory
set CategoryNameCN3 = 'VVIP (nội bộ)', CategoryNameTHB = 'VVIP (ภายใน)', CategoryNameIND = 'VVIP (internal)', SabaIntelligent_RiskLevel_CN3 = 'VIP', SabaIntelligent_RiskLevel_IND = 'VIP', SabaIntelligent_RiskLevel_THB = 'VIP' where CustomerClass=999;
update CustomerCategory
set CategoryNameCN3 = 'VIP (Member Bình thường)', CategoryNameTHB = 'VIP (สมาชิกปกติ)', CategoryNameIND = 'VIP (Anggota Biasa)', SabaIntelligent_RiskLevel_CN3 = 'VIP', SabaIntelligent_RiskLevel_IND = 'VIP', SabaIntelligent_RiskLevel_THB = 'VIP' where CustomerClass=4000;
update CustomerCategory
set CategoryNameCN3 = 'VIP (Member Có vấn đề)', CategoryNameTHB = ' VIP (สมาชิกมีปัญหา)', CategoryNameIND = ' VIP (Anggota Ada Masalah)', SabaIntelligent_RiskLevel_CN3 = 'VIP', SabaIntelligent_RiskLevel_IND = 'VIP', SabaIntelligent_RiskLevel_THB = 'VIP' where CustomerClass=400;
update CustomerCategory
set CategoryNameCN3 = 'Tốt', CategoryNameTHB = 'ดี', CategoryNameIND = 'Baik', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=201;
update CustomerCategory
set CategoryNameCN3 = 'Tốt đã liên kết Robot', CategoryNameTHB = 'หุ่นยนต์ได้เชื่อมต่อแล้ว', CategoryNameIND = 'Robot telah terhubung dengan baik', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=2001;
update CustomerCategory
set CategoryNameCN3 = 'Tốt đã liên kết Nhóm', CategoryNameTHB = 'ดีแล้วที่เชื่อมโยงกับกลุ่ม', CategoryNameIND = 'Baik telah terhubung dengan Grup', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=2101;
update CustomerCategory
set CategoryNameCN3 = 'Tốt đã liên kết PA', CategoryNameTHB = 'PA ได้เชื่อมต่อแล้ว', CategoryNameIND = 'Baik telah terhubung PA', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=2201;
update CustomerCategory
set CategoryNameCN3 = 'Bình thường', CategoryNameTHB = 'ปกติ', CategoryNameIND = 'Biasa', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=202;
update CustomerCategory
set CategoryNameCN3 = 'Bình thường (Không hoạt động)', CategoryNameTHB = 'ปกติ (ไม่ทำงาน)', CategoryNameIND = 'Biasa (Tidak beroperasi)', SabaIntelligent_RiskLevel_CN3 = 'Tốt', SabaIntelligent_RiskLevel_IND = 'Baik', SabaIntelligent_RiskLevel_THB = 'ดี' where CustomerClass=901;
update CustomerCategory
set CategoryNameCN3 = 'Mới', CategoryNameTHB = 'ใหม่', CategoryNameIND = 'Baru', SabaIntelligent_RiskLevel_CN3 = 'Mới', SabaIntelligent_RiskLevel_IND = 'Baru', SabaIntelligent_RiskLevel_THB = 'นักเดิมพันใหม่' where CustomerClass=200;
update CustomerCategory
set CategoryNameCN3 = 'Mới (tuyến phụ)', CategoryNameTHB = 'ใหม่ (สายรอง)', CategoryNameIND = 'Baru (jalur sekunder)', SabaIntelligent_RiskLevel_CN3 = 'Mới', SabaIntelligent_RiskLevel_IND = 'Baru', SabaIntelligent_RiskLevel_THB = 'นักเดิมพันใหม่' where CustomerClass=2500;
update CustomerCategory
set CategoryNameCN3 = 'Bình thường đã liên kết Robot', CategoryNameTHB = 'ปกติแล้วเชื่อมต่อกับหุ่นยนต์แล้ว', CategoryNameIND = 'Biasanya telah terhubung dengan Robot', SabaIntelligent_RiskLevel_CN3 = 'Trung bình', SabaIntelligent_RiskLevel_IND = 'Rata-rata', SabaIntelligent_RiskLevel_THB = 'ทั่วไป' where CustomerClass=2002;
update CustomerCategory
set CategoryNameCN3 = 'Bình thường đã liên kết Nhóm', CategoryNameTHB = 'ปกติแล้วได้เชื่อมโยงกับกลุ่มแล้ว', CategoryNameIND = 'Biasanya telah terhubung Grup', SabaIntelligent_RiskLevel_CN3 = 'Trung bình', SabaIntelligent_RiskLevel_IND = 'Rata-rata', SabaIntelligent_RiskLevel_THB = 'ทั่วไป' where CustomerClass=2102;
update CustomerCategory
set CategoryNameCN3 = 'Bình thường đã liên kết PA', CategoryNameTHB = 'ปกติแล้วได้เชื่อมต่อ PA แล้ว', CategoryNameIND = 'Biasanya telah terhubung PA', SabaIntelligent_RiskLevel_CN3 = 'Trung bình', SabaIntelligent_RiskLevel_IND = 'Rata-rata', SabaIntelligent_RiskLevel_THB = 'ทั่วไป' where CustomerClass=2202;
update CustomerCategory
set CategoryNameCN3 = 'Theo dõi', CategoryNameTHB = 'ติดตาม', CategoryNameIND = 'Pantauan', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=203;
update CustomerCategory
set CategoryNameCN3 = 'Theo dõi đã liên kết Robot', CategoryNameTHB = 'ติดตาม Robot ที่เชื่อมต่อแล้ว', CategoryNameIND = 'Pantauan telah terhubung dengan Robot', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2003;
update CustomerCategory
set CategoryNameCN3 = 'Theo dõi đã liên kết Nhóm', CategoryNameTHB = 'ติดตามกลุ่มที่เชื่อมโยงแล้ว', CategoryNameIND = 'Pantauan telah terhubung dengan Grup', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2103;
update CustomerCategory
set CategoryNameCN3 = 'Theo dõi đã liên kết PA', CategoryNameTHB = 'ติดตาม PA ที่เชื่อมโยงแล้ว', CategoryNameIND = 'Telah terhubung dengan PA', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2203;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Theo dõi cao bị từ chối', CategoryNameTHB = ' กลุ่มติดตามสูงถูกปฏิเสธ', CategoryNameIND = ' Grup Pengikut tinggi ditolak', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2403;
update CustomerCategory
set CategoryNameCN3 = 'Mới đã liên kết Robot', CategoryNameTHB = 'ใหม่ได้เชื่อมโยงกับหุ่นยนต์แล้ว', CategoryNameIND = 'Baru telah terhubung Robot', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2000;
update CustomerCategory
set CategoryNameCN3 = 'Mới đã liên kết Nhóm', CategoryNameTHB = 'ใหม่ได้เชื่อมโยงกับกลุ่มแล้ว', CategoryNameIND = 'Baru telah terhubung Grup', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2100;
update CustomerCategory
set CategoryNameCN3 = 'Mới đã liên kết PA', CategoryNameTHB = 'เพิ่งเชื่อมโยง PA แล้ว', CategoryNameIND = 'Baru saja terhubung dengan PA', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2200;
update CustomerCategory
set CategoryNameCN3 = 'Theo dõi (tuyến phụ)', CategoryNameTHB = 'ติดตาม (สายรอง)', CategoryNameIND = 'Pantau (jalur sekunder)', SabaIntelligent_RiskLevel_CN3 = 'Đáng ngờ', SabaIntelligent_RiskLevel_IND = 'Mencurigakan', SabaIntelligent_RiskLevel_THB = 'น่าสงสัย' where CustomerClass=2503;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh', CategoryNameTHB = 'สมาร์ท', CategoryNameIND = 'Kecerdasan', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=204;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh đã liên kết Robot', CategoryNameTHB = 'ระบบปัญญาประดิษฐ์ได้เชื่อมต่อกับหุ่นยนต์แล้ว', CategoryNameIND = 'Kecerdasan telah terhubung dengan Robot', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2004;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh đã liên kết Nhóm', CategoryNameTHB = 'อัจฉริยะได้เชื่อมโยงกับกลุ่มแล้ว', CategoryNameIND = 'Kecerdasan telah terhubung dengan Grup', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2104;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh đã liên kết PA', CategoryNameTHB = 'PA ได้เชื่อมต่อกับ Thông minh', CategoryNameIND = 'Kecerdasan telah terhubung dengan PA', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2204;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Cược Mới', CategoryNameTHB = 'กลุ่มเดิมพันใหม่', CategoryNameIND = 'Grup Taruhan Baru', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2300;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Cược Thông minh', CategoryNameTHB = 'กลุ่มการเดิมพันอัจฉริยะ', CategoryNameIND = 'Grup Taruhan Cerdas', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2304;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Thông minh cao bị từ chối', CategoryNameTHB = 'กลุ่มอัจฉริยะสูงถูกปฏิเสธ', CategoryNameIND = 'Grup Pintar tinggi ditolak', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2404;
update CustomerCategory
set CategoryNameCN3 = 'Rủi ro', CategoryNameTHB = 'ความเสี่ยง', CategoryNameIND = 'Resiko', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=205;
update CustomerCategory
set CategoryNameCN3 = 'Rủi ro đã liên kết Robot', CategoryNameTHB = 'ความเสี่ยงที่เชื่อมโยงกับหุ่นยนต์', CategoryNameIND = 'Risiko telah terhubung Robot', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2005;
update CustomerCategory
set CategoryNameCN3 = 'Rủi ro đã liên kết Nhóm', CategoryNameTHB = 'ความเสี่ยงที่เชื่อมโยงกับกลุ่ม', CategoryNameIND = 'Risiko telah terhubung dengan Grup', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2105;
update CustomerCategory
set CategoryNameCN3 = 'Rủi ro đã liên kết PA', CategoryNameTHB = 'ความเสี่ยงที่เชื่อมโยงกับ PA', CategoryNameIND = 'Risiko telah terhubung PA', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2205;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Cược Rủi ro', CategoryNameTHB = 'กลุ่มการเดิมพันที่มีความเสี่ยง', CategoryNameIND = 'Kelompok Taruhan Risiko', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2305;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Rủi ro cao bị từ chối', CategoryNameTHB = 'กลุ่มความเสี่ยงสูงถูกปฏิเสธ', CategoryNameIND = 'Grup Risiko Tinggi ditolak', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2405;
update CustomerCategory
set CategoryNameCN3 = 'Người dùng BA', CategoryNameTHB = 'ผู้ใช้ BA', CategoryNameIND = 'Pengguna BA', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=401;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh (không hoạt động)', CategoryNameTHB = 'สมาร์ท (ไม่ทำงาน)', CategoryNameIND = 'Pintar (tidak berfungsi)', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=902;
update CustomerCategory
set CategoryNameCN3 = 'Nhóm Cược Theo dõi', CategoryNameTHB = 'กลุ่มการเดิมพันที่ติดตาม', CategoryNameIND = 'Kelompok Taruhan yang Diikuti', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2303;
update CustomerCategory
set CategoryNameCN3 = 'Thông minh (tuyến phụ)', CategoryNameTHB = 'สมาร์ท (สายรอง)', CategoryNameIND = 'Kecerdasan (jalur sekunder)', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2504;
update CustomerCategory
set CategoryNameCN3 = 'Rủi ro (tuyến phụ)', CategoryNameTHB = 'ความเสี่ยง (สายรอง)', CategoryNameIND = 'Risiko (jalur sekunder)', SabaIntelligent_RiskLevel_CN3 = 'Nguy hiểm', SabaIntelligent_RiskLevel_IND = 'Berbahaya', SabaIntelligent_RiskLevel_THB = 'อันตราย' where CustomerClass=2505;
update CustomerCategory
set CategoryNameCN3 = 'Người dùng Robot', CategoryNameTHB = 'ผู้ใช้งานโรบอท', CategoryNameIND = 'Pengguna Robot', SabaIntelligent_RiskLevel_CN3 = 'Robot', SabaIntelligent_RiskLevel_IND = 'Robot', SabaIntelligent_RiskLevel_THB = 'บอท' where CustomerClass=300;
update CustomerCategory
set CategoryNameCN3 = 'Người dùng Robot (Thua)', CategoryNameTHB = 'ผู้ใช้งานหุ่นยนต์ (แพ้)', CategoryNameIND = 'Pengguna Robot (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Robot', SabaIntelligent_RiskLevel_IND = 'Robot', SabaIntelligent_RiskLevel_THB = 'บอท' where CustomerClass=3000;
update CustomerCategory
set CategoryNameCN3 = 'Robot thu thập tỷ lệ cược', CategoryNameTHB = 'หุ่นยนต์รวบรวมอัตราการเดิมพัน', CategoryNameIND = 'Robot mengumpulkan taruhan odds', SabaIntelligent_RiskLevel_CN3 = 'Robot', SabaIntelligent_RiskLevel_IND = 'Robot', SabaIntelligent_RiskLevel_THB = 'บอท' where CustomerClass=3100;
update CustomerCategory
set CategoryNameCN3 = 'Robot thu thập tỷ lệ cược (Thua)', CategoryNameTHB = 'หุ่นยนต์รวบรวมอัตราการเดิมพัน (แพ้)', CategoryNameIND = 'Robot mengumpulkan peluang taruhan (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Robot', SabaIntelligent_RiskLevel_IND = 'Robot', SabaIntelligent_RiskLevel_THB = 'บอท' where CustomerClass=3200;
update CustomerCategory
set CategoryNameCN3 = 'Cược Nhóm', CategoryNameTHB = 'การเดิมพันกลุ่ม', CategoryNameIND = 'Taruhan Grup', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=301;
update CustomerCategory
set CategoryNameCN3 = 'Cược Nhóm (Thua)', CategoryNameTHB = 'การเดิมพันกลุ่ม (แพ้)', CategoryNameIND = 'Taruhan Grup (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=3001;
update CustomerCategory
set CategoryNameCN3 = 'Hệ thống phát hiện Cược Nhóm', CategoryNameTHB = 'ระบบตรวจจับการเดิมพันกลุ่ม', CategoryNameIND = 'Sistem Deteksi Taruhan Grup', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=3101;
update CustomerCategory
set CategoryNameCN3 = 'Hệ thống phát hiện Cược Nhóm (Thua)', CategoryNameTHB = 'ระบบตรวจจับการพนันกลุ่ม (แพ้)', CategoryNameIND = 'Sistem Deteksi Taruhan Grup (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=3201;
update CustomerCategory
set CategoryNameCN3 = 'Cược Chênh lệch', CategoryNameTHB = 'การเดิมพันแตกต่าง', CategoryNameIND = 'Taruhan Selisih', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID in (54,74,154,174);
update CustomerCategory
set CategoryNameCN3 = 'Cược Chênh lệch (Thua)', CategoryNameTHB = 'การเดิมพันตามผลต่าง (แพ้)', CategoryNameIND = 'Taruhan Selisih (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (94,114,134,182);
update CustomerCategory
set CategoryNameCN3 = 'Cược Sập giá', CategoryNameTHB = 'การพนันราคาล่ม', CategoryNameIND = 'Taruhan Harga Jatuh', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (58,78,158,177);
update CustomerCategory
set CategoryNameCN3 = 'Cược Sập giá (Thua)', CategoryNameTHB = 'การพนันราคาล่ม (แพ้)', CategoryNameIND = 'Taruhan Harga Runtuh (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (98,118,138,184);
update CustomerCategory
set CategoryNameCN3 = 'Dàn xếp tỷ số', CategoryNameTHB = 'การจัดระบบคะแนน', CategoryNameIND = 'Mengatur Skor', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (55,75,155,175);
update CustomerCategory
set CategoryNameCN3 = 'Dàn xếp tỷ số (Thua)', CategoryNameTHB = 'การจัดระบบคะแนน (แพ้)', CategoryNameIND = 'Mengatur skor (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (95,115,135,183);
update CustomerCategory
set CategoryNameCN3 = 'Cược Công thức', CategoryNameTHB = 'การเดิมพันสูตร', CategoryNameIND = 'Taruhan Formula', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (59,79,159,178);
update CustomerCategory
set CategoryNameCN3 = 'Cược Công thức (Thua)', CategoryNameTHB = 'การเดิมพันสูตร (แพ้)', CategoryNameIND = 'Taruhan Formula (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (99,119,139,185);
update CustomerCategory
set CategoryNameCN3 = 'Cược Bảo hiểm', CategoryNameTHB = 'การเดิมพันประกันภัย', CategoryNameIND = 'Taruhan Asuransi', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (53,73,153,173);
update CustomerCategory
set CategoryNameCN3 = 'Cượ̣c Bảo hiểm (Thua)', CategoryNameTHB = 'การเดิมพันประกันภัย (แพ้)', CategoryNameIND = 'Taruhan Asuransi (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CategoryID IN (93,113,133,181);
update CustomerCategory
set CategoryNameCN3 = 'Hệ thống Cảnh Báo Đăng Nhập Bất Thường ', CategoryNameTHB = 'ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ', CategoryNameIND = 'Sistem Peringatan Login Tidak Biasa', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=305;
update CustomerCategory
set CategoryNameCN3 = 'Hệ thống Cảnh Báo Đăng Nhập Bất Thường (Thua)', CategoryNameTHB = 'ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ (แพ้)', CategoryNameIND = 'Sistem Peringatan Login Tidak Biasa (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=3005;
update CustomerCategory
set CategoryNameCN3 = 'Cược Thông tin', CategoryNameTHB = 'ข้อมูลการเดิมพัน', CategoryNameIND = 'Informasi Taruhan', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=304;
update CustomerCategory
set CategoryNameCN3 = 'Cượ̣c Thông tin (Thua)', CategoryNameTHB = 'การเดิมพันข้อมูล (แพ้)', CategoryNameIND = 'Informasi Taruhan (Kalah)', SabaIntelligent_RiskLevel_CN3 = 'Vấn đề', SabaIntelligent_RiskLevel_IND = 'Masalah', SabaIntelligent_RiskLevel_THB = 'ปัญหา' where CustomerClass=3004;
update CustomerCategory
set CategoryNameCN3 = 'Ví dụ cho chưa phân loại', CategoryNameTHB = 'ตัวอย่างสำหรับที่ยังไม่ได้จัดหมวดหมู่', CategoryNameIND = 'Contoh untuk belum diklasifikasikan', SabaIntelligent_RiskLevel_CN3 = 'Chưa phân loại', SabaIntelligent_RiskLevel_IND = 'Tidak terdeteksi', SabaIntelligent_RiskLevel_THB = 'ยังไม่ได้จัดหมวดหมู่' where CustomerClass=-999999;

