/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete_V1`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete_V1`(
		IN ip_Size INT
	,	IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Delete DeviceCode 
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	DECLARE lv_FromDeviceID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToDeviceID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();
	
	SELECT 	MIN(tmp.DeviceID), MAX(tmp.DeviceID)
	INTO 	lv_FromDeviceID, lv_ToDeviceID
	FROM	(SELECT delDf.DeviceID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf WHERE delDf.DeviceID > lv_ToDeviceID LIMIT ip_Size) AS tmp;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
	VALUES(340, 340,'CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete_V1',lv_StartTime,NOW(), lv_FromDeviceID);
    
	#====Step01. Remove Account From CS152454_DelUnuAccount_Account: IsCTSTransformed = 1 OR LastLoginTime >= '20210101' OUTPUT UmRemoveDeviceID
    WHILE(lv_FromDeviceID IS NOT NULL)
    DO			
            DELETE 	df
            FROM	DCS_DataCenter.DeviceFingerprint AS df
				INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf ON delDf.DeviceID = df.DeviceID
            WHERE	delDf.DeviceID BETWEEN  lv_FromDeviceID AND lv_ToDeviceID;
			
            UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_ToDeviceID
					, EndTime = NOW()
			WHERE ID = 340;
            
            SELECT 	MIN(tmp.DeviceID), MAX(tmp.DeviceID)
			INTO 	lv_FromDeviceID, lv_ToDeviceID
			FROM	(SELECT delDf.DeviceID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf WHERE delDf.DeviceID > lv_ToDeviceID LIMIT ip_Size) AS tmp;
            
            DO SLEEP(ip_DelaySec);
            
    END WHILE;

END