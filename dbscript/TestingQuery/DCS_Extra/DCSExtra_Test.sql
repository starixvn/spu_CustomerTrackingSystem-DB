USE DCS_Extra;

#========INSERT RAW TRANSACTION===============================================
TRUNCATE TABLE DCS_Extra.AccountDevice;
TRUNCATE TABLE DCS_Extra.AccountLastLoginTimeProcess;
TRUNCATE TABLE DCS_Extra.ActionResult;
TRUNCATE TABLE DCS_Extra.Association;
TRUNCATE TABLE DCS_Extra.Device;
TRUNCATE TABLE DCS_Extra.DeviceCode;
TRUNCATE TABLE DCS_Extra.DeviceFingerprint;
TRUNCATE TABLE DCS_Extra.DeviceType;
TRUNCATE TABLE DCS_Extra.OS;
TRUNCATE TABLE DCS_Extra.ProcessedTransaction;
TRUNCATE TABLE DCS_Extra.Transaction;
TRUNCATE TABLE DCS_Extra.Transaction07;
TRUNCATE TABLE DCS_Extra.URL;
TRUNCATE TABLE DCS_Extra.UserAgent;

#==============================================================================

CALL DCS_ET_Transform_RawTrans_Insert (@ip_RawTransJson:='[
		{"LoginName":"mytam","SubscriberName":"MAXBET789Y","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:00.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"hanhi","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:01.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"buianhtuan","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:02.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"hanhi","SubscriberName":"Velki","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:03.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"buianhtuan","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:04.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"lannha","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:05.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"phanmanhquynh","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:06.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"phamhoainam","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:07.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"phamhoainam","SubscriberName":"MAXBET789Y","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:08.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"trucnhan","SubscriberName":"MAXBET789Y","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:09.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"trucnhan","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:10.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"lannha","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:11.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"hanhi","SubscriberName":"Velki","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:12.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"quangdung","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:13.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"phanmanhquynh","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:14.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"haanhtuan","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:15.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"hoangquyen","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:16.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"HaTran","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:17.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"DenVau","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:18.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"Karik","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:19.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"VickyNhung","SubscriberName":"Velki","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:20.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"QuangDung","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:21.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"HaNhi","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:22.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
	,	{"LoginName":"HoaMi","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:23.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
	,	{"LoginName":"DanNguyen","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:24.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
]');

SELECT * FROM RawTransaction;
SET @TransID = 0;
UPDATE RawTransaction
SET LoginName = ELT(0.5 + RAND()*47,'Affecting','Exciting','Heated','Hysterical','Impassioned','Moving','Nervous','Passionate','Poignant','Sensitive','Sentimental','Spontaneous','Touching','Ardent','Disturbed','Ecstatic','Emotive','Enthusiastic','Excitable','Falling Apart','Fanatical','Feeling','Fervent','Fervid','Fickle','Fiery','Heartwarming','Histrionic','Histrionical','Hot-Blooded','Impetuous','Impulsive','Irrational','Overwrought','Pathetic','Responsive','Roused','Sentient','Stirred','Stirring','Susceptible','Tear-Jerking','Temperamental','Tender','Thrilling','Warm','Zealous'
			)
	, SubscriberName = ELT(0.5 + RAND()*20,'Velki','CTMAX','Velki','CTMAX','Velki','NoName','CTMAX','Velki','CTMAX','Velki','CTMAX','Velki','CTMAX','Velki','CTMAX','Velki','CTMAX','Velki','CTMAX','Velki','CTMAX')
    , TransTime = timestampadd(MICROSECOND, 534227*TransID,NOW())
    , TransStatus = 0, IsProcessed = 0
    , TransID = @TransID:=@TransID+1
    ;

SELECT * FROM SystemSetting;
SELECT * FROM DCS_Extra.AccountDevice;
SELECT * FROM DCS_Extra.AccountLastLoginTimeProcess;
SELECT * FROM DCS_Extra.ActionResult;
SELECT * FROM DCS_Extra.Association;
SELECT * FROM DCS_Extra.Device;
SELECT * FROM DCS_Extra.DeviceCode;
SELECT * FROM DCS_Extra.DeviceFingerprint;
SELECT * FROM DCS_Extra.DeviceType;
SELECT * FROM DCS_Extra.OS;
SELECT * FROM DCS_Extra.ProcessedTransaction;
SELECT * FROM DCS_Extra.Subscriber;
SELECT * FROM DCS_Extra.Transaction;
SELECT * FROM DCS_Extra.Transaction07;
SELECT * FROM DCS_Extra.URL;
SELECT * FROM DCS_Extra.UserAgent;
SELECT TransStatus, IsProcessed, TransID, r.* FROM RawTransaction r; 

UPDATE SystemSetting SET VValue = '2001-01-01' WHERE ID = 2;
UPDATE SystemSetting SET VValue = 0 WHERE ID = 1;
UPDATE SystemSetting SET VValue = 0 WHERE ID = 3;
#========2. TRANSFORM ACCOUNT: from Table RawTransaction TO Table Transaction===============================================
	#2.1 Service Call:
    CALL DCS_Extra.DCS_ET_Transform_RawTrans_GetPackage(@ip_IsProcessed:=0, @ip_NoOfTickets:=5, @ip_NoOfBatch:=2); 
		SELECT * FROM SystemSetting WHERE ID = 3; #Expected: value = SELECT MIN(transID) FROM RawTransaction WHERE  IsProcessed = 0;
    
	#=====2.1.a TRANSFORM BATCH 1
		CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT TransStatus, IsProcessed, TransID, r.* FROM RawTransaction r; SELECT * FROM DCS_Extra.ActionResult;
        CALL DCS_ET_TransformData_UserAgent_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT * FROM UserAgent;
        CALL DCS_ET_Transform_Transaction_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); 
			SELECT * FROM Account; 
            SELECT * FROM AccountLastLoginTimeProcess ;
            SELECT * FROM Transaction; 
            SELECT * FROM ProcessedTransaction;
            SELECT TransID, IsProcessed, TransStatus, r.* FROM RawTransaction r;

    #=====2.b TRANSFORM BATCH 2
		CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT TransStatus, IsProcessed, TransID, r.* FROM RawTransaction r; SELECT * FROM DCS_Extra.ActionResult;
        CALL DCS_ET_TransformData_UserAgent_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT * FROM UserAgent;
        CALL DCS_ET_Transform_Transaction_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); 
			SELECT * FROM Account; 
            SELECT * FROM AccountLastLoginTimeProcess ;
            SELECT * FROM Transaction; 
            SELECT * FROM ProcessedTransaction;
            SELECT TransID, IsProcessed, TransStatus, r.* FROM RawTransaction r;
	#2.2 Service Call:
	CALL DCS_Extra.DCS_ET_Transform_RawTrans_GetPackage(@ip_IsProcessed:=0, @ip_NoOfTickets:=5, @ip_NoOfBatch:=2); SELECT * FROM SystemSetting WHERE ID = 3;
	#=====2.a TRANSFORM BATCH 1
		CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT TransStatus, IsProcessed, r.* FROM RawTransaction r;
        CALL DCS_ET_TransformData_UserAgent_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT * FROM UserAgent;
        CALL DCS_ET_Transform_Transaction_Insert(@ip_FromTransID:=1, @ip_ToTransID:=5); SELECT * FROM Account; SELECT * FROM AccountLastLoginTimeProcess ;SELECT * FROM Transaction; SELECT * FROM ProcessedTransaction;SELECT TransID, IsProcessed, TrasStatus, r.* FROM RawTransaction r;

    #=====2.b TRANSFORM BATCH 2
		CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=6, @ip_ToTransID:=10); SELECT TransStatus, IsProcessed, r.* FROM RawTransaction r;
        CALL DCS_ET_TransformData_UserAgent_Insert(@ip_FromTransID:=6, @ip_ToTransID:=10); SELECT * FROM UserAgent;
        CALL DCS_ET_Transform_Transaction_Insert(@ip_FromTransID:=6, @ip_ToTransID:=10); SELECT * FROM Account;SELECT * FROM Transaction; SELECT * FROM ProcessedTransaction;SELECT TransID, IsProcessed, TransStatus, r.* FROM RawTransaction r;
                      
#========3. TRANSFORM DEVICE: from Table Transaction TO Table Transaction07===============================================        
CALL DCS_ET_Transform_Device_GetPackage(@ip_NoOfTickets:=5, @ip_NoOfBatch:=2);
	#3.a TRANSFROM BATCH 1
    CALL `DCS_ET_Transform_Device_Insert`(@ip_TransJson:='[{"TransId":8},{"TransId":9},{"TransId":10},{"TransId":11},{"TransId":12}]');
    SELECT * FROM Device;
    SELECT * FROM DeviceCode;
    SELECT * FROM DeviceFingerprint;
    SELECT * FROM Association;
    SELECT * FROM Transaction07;
	SELECT * FROM Transaction;
    #3.2 TRANSFROM BATCH 1
        
CALL DCS_Extra.DCS_ET_Transform_RawTrans_GetPackage(@ip_IsProcessed:=0, @ip_NoOfTickets:=5, @ip_NoOfBatch:=2); SELECT * FROM SystemSetting WHERE ID = 3;        
    #=====2.a TRANSFORM BATCH 1
		CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=11, @ip_ToTransID:=15); SELECT TransStatus, IsProcessed, r.* FROM RawTransaction r;
        CALL DCS_ET_Transform_UserAgent_Insert(@ip_FromTransID:=11, @ip_ToTransID:=15); SELECT * FROM UserAgent;
        CALL DCS_ET_Transform_Transaction_Insert(@ip_FromTransID:=11, @ip_ToTransID:=15); SELECT * FROM Account; SELECT * FROM AccountLastLoginTimeProcess ;SELECT * FROM Transaction; SELECT * FROM ProcessedTransaction;SELECT TransID, IsProcessed, TrasStatus, r.* FROM RawTransaction r;
	    
	#=====2.2 TRANSFROM BATCH 2
    CALL DCS_ET_Transform_UnhandleSubscriberAction(@ip_FromTransID:=6, @ip_ToTransID:=10);
    
SELECT r.TransID, r.TransStatus, r.IsProcessed, r.* FROM DCS_Extra.RawTransaction as r;
SELECT * FROM Transaction;

UPDATE DCS_Extra.RawTransaction SET TransStatus = 0 , IsProcessed = 0;
SELECT * FROM SystemSetting;
SELECT * FROM Subscriber;