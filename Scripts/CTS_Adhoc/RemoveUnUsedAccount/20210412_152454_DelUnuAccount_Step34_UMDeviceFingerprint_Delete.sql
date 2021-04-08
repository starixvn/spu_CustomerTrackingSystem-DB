/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete`(
	IN ip_Size INT
	, IN ip_DelaySec TINYINT
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
	DECLARE lv_FromDeviceFingerprintID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToDeviceFingerprintID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();
	
	SELECT 	MIN(tmp.DeviceFingerprintID), MAX(tmp.DeviceFingerprintID)
	INTO 	lv_FromDeviceFingerprintID, lv_ToDeviceFingerprintID
	FROM	(SELECT delDf.DeviceFingerprintID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf WHERE delDf.DeviceFingerprintID > lv_ToDeviceFingerprintID LIMIT ip_Size) AS tmp;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
	VALUES(34, 34,'CTS_AD_DelUnuAccount_Step34_DeviceFingerprint_Delete',lv_StartTime,NOW(), lv_FromDeviceFingerprintID);
    
	#====Step01. Remove Account From CS152454_DelUnuAccount_Account: IsCTSTransformed = 1 OR LastLoginTime >= '20210101' OUTPUT UmRemoveDeviceID
    WHILE(lv_FromDeviceFingerprintID IS NOT NULL)
    DO			
            DELETE 		df
            FROM		DCS_DataCenter.DeviceCode AS df
            INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf ON delDf.DeviceFingerprintID = df.DeviceFingerprintID
            WHERE		delDf.DeviceFingerprintID BETWEEN  lv_FromDeviceFingerprintID AND lv_ToDeviceFingerprintID;
			
            UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_ToDeviceFingerprintID
					, EndTime = NOW()
			WHERE ID = 34;
            
            SELECT 	MIN(tmp.DeviceFingerprintID), MAX(tmp.DeviceFingerprintID)
			INTO 	lv_FromDeviceFingerprintID, lv_ToDeviceFingerprintID
			FROM	(SELECT delDf.DeviceFingerprintID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf WHERE delDf.DeviceFingerprintID > lv_ToDeviceFingerprintID LIMIT ip_Size) AS tmp;
            
            DO SLEEP(ip_DelaySec);
            
    END WHILE;

END