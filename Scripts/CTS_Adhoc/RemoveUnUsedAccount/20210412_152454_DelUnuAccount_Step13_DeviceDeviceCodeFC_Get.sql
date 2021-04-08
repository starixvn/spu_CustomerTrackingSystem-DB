/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/
USE CTS_Adhoc;
DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step13_DeviceDeviceCodeDeviceFP_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step13_DeviceDeviceCodeDeviceFP_Get`(
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
    DECLARE	lv_MaxDeviceID	BIGINT UNSIGNED;# The Last AccountID
    DECLARE	lv_FromDeviceID	BIGINT UNSIGNED;	
    DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceID;
    CREATE TEMPORARY TABLE Temp_DeviceID
    (
		DeviceID BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountID;
    CREATE TEMPORARY TABLE Temp_AccountID
    (
		AccountID BIGINT UNSIGNED PRIMARY KEY
    );
    
    SET	lv_StartTime = NOW();	
    
    SELECT 	MIN(DeviceID), MAX(DeviceID)
    INTO 	lv_FromDeviceID, lv_MaxDeviceID
    FROM 	CTS_Adhoc.CS152454_DelUnuAccount_Association;
    
	INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(13, 13,'CTS_AD_DelUnuAccount_Step13_DeviceDeviceCodeDeviceFP_Get',lv_StartTime,NOW(),lv_FromDeviceID);   
       
    WHILE (lv_FromDeviceID IS NOT NULL)
    DO			
        INSERT INTO Temp_DeviceID(DeviceID)
        SELECT	DISTINCT(delAss.DeviceID)				
        FROM	CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss		
        WHERE	delAss.DeviceID > lv_FromDeviceID
        ORDER BY delAss.DeviceID
        LIMIT	ip_Size;           
        
        SET lv_FromDeviceID = (SELECT MAX(DeviceID) FROM Temp_DeviceID);             
        
        DELETE 	tmp_dv
        FROM	Temp_DeviceID AS tmp_dv
			INNER JOIN	DCS_DataCenter.Association AS ass ON tmp_dv.DeviceID = ass.DeviceID
			LEFT JOIN 	CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss ON delAss.AccountID = ass.AccountID
		WHERE	delAss.AccountID IS NULL;       
        
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_Device(DeviceID, FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime)
        SELECT	dv.DeviceID, dv.FirstDeviceCode, dv.UserAgentKey, dv.FirstTransID, dv.CreatedTime, dv.CreatedDate, dv.InsertTime			
        FROM	DCS_DataCenter.Device AS dv
			INNER JOIN	Temp_DeviceID AS tmpDv ON tmpDv.DeviceID = dv.DeviceID;   
      
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode(DeviceCodeID, DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
        SELECT	dc.DeviceCodeID, dc.DeviceCode, dc.DeviceID, dc.FirstTransID, dc.CreatedTime, dc.CreatedDate, dc.InsertTime			
        FROM	DCS_DataCenter.DeviceCode AS dc
			INNER JOIN	Temp_DeviceID AS tmpDv ON tmpDv.DeviceID = dc.DeviceID; 
            
		INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint(DeviceFingerprintID, DeviceID, FingerprintCode, FingerprintMoreInfo, CreatedTime, CreatedDate, InsertTime)
        SELECT	df.DeviceFingerprintID, df.DeviceID, df.FingerprintCode, df.FingerprintMoreInfo, df.CreatedTime, df.CreatedDate, df.InsertTime		
        FROM	DCS_DataCenter.DeviceFingerprint AS df
			INNER JOIN	Temp_DeviceID AS tmpDv ON tmpDv.DeviceID = df.DeviceID;
            
        #=======================================================
        UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
		SET 	Notes = lv_FromDeviceID
				, EndTime = NOW()
		WHERE ID = 13; 
        
        TRUNCATE TABLE Temp_DeviceID;
        
        DO SLEEP(ip_DelaySec);           
        
    END WHILE;

END