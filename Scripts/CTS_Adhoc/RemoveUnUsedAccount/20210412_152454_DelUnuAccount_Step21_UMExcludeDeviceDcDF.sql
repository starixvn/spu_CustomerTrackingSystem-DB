/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step21_UMExcludeDeviceDcDF`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step21_UMExcludeDeviceDcDF`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		GET Device of Deleted Account
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_FromDeviceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToDeviceID	BIGINT UNSIGNED DEFAULT 0;    
    DECLARE lv_StartTime DATETIME(3) DEFAULT NOW();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveDeviceID;
    CREATE TEMPORARY TABLE Temp_RemoveDeviceID
    (
		DeviceID BIGINT UNSIGNED PRIMARY KEY
    );
    
    SELECT 	MIN(DeviceID), MAX(DeviceID)
	INTO 	lv_FromDeviceID, lv_ToDeviceID
	FROM	(SELECT DeviceID FROM CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDv WHERE delDv.DeviceID > lv_ToDeviceID LIMIT ip_Size) AS tmp;
	    
	INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(21, 21,'CTS_AD_DelUnuAccount_Step21_UMExcludeDeviceDcDF',lv_StartTime,NOW(), lv_FromDeviceID);   
    
    WHILE(lv_FromDeviceID IS NOT NULL)
    DO		
			
		INSERT INTO Temp_RemoveDeviceID(DeviceID)
        SELECT 		DISTINCT delDv.DeviceID
        FROM		CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDv
        INNER JOIN	DCS_DataCenter.Association AS ass ON delDv.DeviceID = ass.DeviceID
        LEFT JOIN	CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss ON delAss.AssociationID = ass.AssociationID
		WHERE		delDv.DeviceID BETWEEN lv_FromDeviceID AND lv_ToDeviceID;
		
        DELETE 		delDv
        FROM 		CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDv
        INNER JOIN	Temp_RemoveDeviceID AS tmpDv ON tmpDv.DeviceID = delDv.DeviceID;
        
        DELETE 		delDc
        FROM 		CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode AS delDc
        INNER JOIN	Temp_RemoveDeviceID AS tmpDv ON tmpDv.DeviceID = delDc.DeviceID;
       
        DELETE 		delDf
        FROM 		CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDf
        INNER JOIN	Temp_RemoveDeviceID AS tmpDv ON tmpDv.DeviceID = delDf.DeviceID;        
        
        UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
		SET 	Notes = lv_ToDeviceID
				, EndTime = NOW()
		WHERE ID = 21;		
        
        SELECT 	MIN(tmp.DeviceID), MAX(tmp.DeviceID)
		INTO 	lv_FromDeviceID, lv_ToDeviceID
		FROM	(SELECT DeviceID FROM CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDv WHERE delDv.DeviceID > lv_ToDeviceID LIMIT ip_Size) AS tmp;
       
        TRUNCATE TABLE Temp_RemoveDeviceID;
        
        DO SLEEP(ip_DelaySec);
        
    END WHILE;
    
END