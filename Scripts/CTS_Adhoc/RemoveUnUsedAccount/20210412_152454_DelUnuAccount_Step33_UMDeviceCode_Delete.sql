/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/


DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step33_DeviceCode_Delete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step33_DeviceCode_Delete`(
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
	DECLARE lv_FromDeviceCodeID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToDeviceCodeID	BIGINT UNSIGNED DEFAULT 0;
	DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();	
    
	SELECT 	MIN(tmp.DeviceCodeID), MAX(tmp.DeviceCodeID)
	INTO 	lv_FromDeviceCodeID, lv_ToDeviceCodeID
	FROM	(SELECT delDc.DeviceCodeID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode AS delDc WHERE delDc.DeviceCodeID > lv_ToDeviceCodeID LIMIT ip_Size) AS tmp;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(33, 33,'CTS_AD_DelUnuAccount_Step33_DeviceCode_Delete',lv_StartTime,NOW(), lv_FromDeviceCodeID); 
    
    WHILE(lv_FromDeviceCodeID IS NOT NULL)
    DO			
		DELETE 		dc
		FROM		DCS_DataCenter.DeviceCode AS dc
		INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode AS delDc ON delDc.DeviceCodeID = dc.DeviceCodeID
		WHERE		delDc.DeviceCodeID BETWEEN  lv_FromDeviceCodeID AND lv_ToDeviceCodeID;
		
        UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
		SET 	Notes = lv_ToDeviceCodeID
				, EndTime = NOW()
		WHERE ID = 33;
        
		SELECT 	MIN(tmp.DeviceCodeID), MAX(tmp.DeviceCodeID)
		INTO 	lv_FromDeviceCodeID, lv_ToDeviceCodeID
		FROM	(SELECT delDc.DeviceCodeID FROM CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode AS delDc WHERE delDc.DeviceCodeID > lv_ToDeviceCodeID LIMIT ip_Size) AS tmp;
		
		DO SLEEP(ip_DelaySec);
    END WHILE;

END