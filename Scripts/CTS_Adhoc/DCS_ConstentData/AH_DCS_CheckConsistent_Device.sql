DROP PROCEDURE IF EXISTS `AH_CheckConsistent_DCS_Device`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `AH_CheckConsistent_DCS_Device`(
	IN ip_BatchSize INT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211206@CaseyHuynh
		Task:		GET Data not consistent: Device
		DB:			AH_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):   
        
        Example: 
			- CALL AH_DAH_CheckConsistent_Device (1000)
	*/	  
	DECLARE lv_FromID BIGINT ;
    DECLARE lv_ToID BIGINT ;
    DECLARE lv_MaxID BIGINT;
    
    SET lv_FromID = (SELECT ParameterValue FROM CTS_Adhoc.CS_Adhoc_Setting WHERE ID = 1);    
    SET lv_MaxID = (SELECT MAX(DeviceID) FROM DCS_DataCenter.Device AS dv);
    
	WHILE (lv_FromID <= lv_MaxID)
    DO
		
		SET lv_ToID = lv_FromID + ip_BatchSize;  
        
		# Check NOT EIXSTING DeviceCode
        INSERT INTO CTS_Adhoc.AH_CheckConsistent_Device(DeviceID, FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime, MissingDeviceCode )
		SELECT	dv.DeviceID
			,	dv.FirstDeviceCode
            ,	dv.UserAgentKey
            ,	dv.FirstTransID
            ,	dv.CreatedTime
            ,	dv.CreatedDate
			, 	dv.InsertTime
			,	1 AS MissingDeviceCode
		FROM DCS_DataCenter.Device AS dv 
		WHERE dv.DeviceID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.DeviceCode AS dc WHERE dv.DeviceID = dc.DeviceID );
      
		# Check NOT EIXSTING DeviceFingerprint
		INSERT INTO CTS_Adhoc.AH_CheckConsistent_Device(DeviceID, FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime, MissingDeviceFingerprint )
		SELECT	dv.DeviceID
			,	dv.FirstDeviceCode
            ,	dv.UserAgentKey
            ,	dv.FirstTransID
            ,	dv.CreatedTime
            ,	dv.CreatedDate
			, 	dv.InsertTime
			,	1 AS MissingDeviceFingerprint
		FROM	DCS_DataCenter.Device AS dv 
		WHERE 	dv.DeviceID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.DeviceFingerprint AS df WHERE dv.DeviceID = df.DeviceID )
		ON DUPLICATE KEY UPDATE MissingDeviceFingerprint = 1;

		#=========================
		SET lv_FromID = lv_ToID + 1;   
        
		UPDATE CTS_Adhoc.CS_Adhoc_Setting
        SET ParameterValue = LEAST(lv_ToID, lv_MaxID)
        WHERE ID = 1;
        
    END WHILE;
	
END$$
DELIMITER ;
