DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_RawTransaction.DCS_RT_RawTrans_Insert$$

CREATE PROCEDURE DCS_RawTransaction.DCS_RT_RawTrans_Insert(IN ip_RawTransJson LONGTEXT)
BEGIN

	/*
	Created: 20190610@Casey.Huynh
	Task : Insert to Raw Table
	DB: FPS_RawTrans
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions
    (
		LoginName					VARCHAR(100) CHARACTER SET UTF8MB4 	NOT NULL	
		, SubscriberName			VARCHAR(50) 						NOT NULL
		, TransTime					TIMESTAMP(4)	 					NOT NULL
		, DeviceCode				VARCHAR(62) 						NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
		, FingerprintCode			VARCHAR(2000)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
		, FingerprintMoreInfo		TEXT	CHARACTER SET UTF8MB4		NULL
		, UserAgent					TEXT		 						NULL
		, IP						VARCHAR(50) 						NULL
        , IPID						BIGINT								NULL
		, PluginID					BIGINT 								NULL	
		, URL						VARCHAR(500) 						NULL
		, ActionResult				VARCHAR(100) 						NULL
		, InvalidDevice				TEXT	CHARACTER SET UTF8MB4		NULL
		, TransStatus				BIT(16)								NULL	
    );     
		
	INSERT INTO Temp_Transactions
	(	LoginName
		, SubscriberName
		, TransTime
		, DeviceCode
		, FingerprintCode
		, FingerprintMoreInfo
		, UserAgent
		, IP
        , IPID
		, PluginID
		, URL
		, ActionResult
        , InvalidDevice
		, TransStatus
	)
	SELECT
			rt.LoginName
			, rt.SubscriberName
			, rt.TransTime
			, rt.DeviceCode
			, (CASE WHEN rt.DeviceCode ="" THEN "" ELSE rt.FingerprintCode 		END) 	AS FingerprintCode
			, (CASE WHEN rt.DeviceCode ="" THEN "" ELSE rt.FingerprintMoreInfo	END) AS FingerprintMoreInfo
			, rt.UserAgent
			, rt.IP
            , rt.IPID
			, rt.PluginID            
			, rt.URL
			, rt.ActionResult
            , InvalidDevice
			, TransStatus
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
							  LoginName				VARCHAR(100) CHARACTER SET UTF8MB4	PATH "$.LoginName"       
							, SubscriberName		VARCHAR(50) 	PATH "$.SubscriberName"   
							, TransTime				TIMESTAMP(4) 	PATH "$.TransTime"
							, DeviceCode			VARCHAR(64)		PATH "$.DeviceCode"
							, FingerprintCode		VARCHAR(2000)	PATH "$.FingerprintCode"
							, FingerprintMoreInfo	TEXT	CHARACTER SET UTF8MB4  	PATH "$.FingerprintMoreInfo"
							, UserAgent				TEXT 	PATH "$.UserAgent"
							, IP					VARCHAR(50) 	PATH "$.IP"
                            , IPID					BIGINT			PATH "$.IPId"
							, PluginID				BIGINT 			PATH "$.PluginID"
							, URL					VARCHAR(500) 	PATH "$.URL"
							, ActionResult			VARCHAR(100) 	PATH "$.ActionResult"
                            , InvalidDevice	TEXT	CHARACTER SET UTF8MB4 	PATH "$.InvalidDevice"
                            , TransStatus	BIT(16)		 					PATH "$.TransStatus"
							)
		   ) AS  rt; 
	
	INSERT INTO DCS_RawTransaction.RawTransaction
	(	LoginName
		, SubscriberName
		, TransTime
		, CreatedDate
		, DeviceCode
		, FingerprintCode
		, FingerprintMoreInfo
		, UserAgent
		, IP
        , IPID
		, PluginID
		, URL
		, ActionResult
        , InvalidDevice
        , TransStatus
	)
	SELECT
		rt.LoginName
		, rt.SubscriberName
		, rt.TransTime
		, DATE(rt.TransTime) AS CreatedDate
		, rt.DeviceCode
		, rt.FingerprintCode
		, rt.FingerprintMoreInfo
		, rt.UserAgent
		, rt.IP
        , rt.IPID
		, rt.PluginID
		, rt.URL
		, rt.ActionResult
        , rt.InvalidDevice
        , rt.TransStatus
	FROM	Temp_Transactions AS rt;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
END$$
DELIMITER ;
