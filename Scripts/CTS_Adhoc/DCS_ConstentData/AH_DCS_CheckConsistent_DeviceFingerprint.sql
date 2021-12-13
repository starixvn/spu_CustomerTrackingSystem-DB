DROP PROCEDURE IF EXISTS `AH_DCS_CheckConsistent_DeviceFingerprint`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `AH_DCS_CheckConsistent_DeviceFingerprint`(
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
    
    SET lv_FromID = (SELECT st.ParameterValue FROM CTS_Adhoc.CS_Adhoc_Setting AS st WHERE st.ID = 3);    
    SET lv_MaxID = (SELECT MAX(df.DeviceFingerprintID) FROM DCS_DataCenter.DeviceFingerprint AS df);
    
	WHILE (lv_FromID <= lv_MaxID)
    DO
		
		SET lv_ToID = lv_FromID + ip_BatchSize;  
        
		# Check NOT EIXSTING DeviceCode
        INSERT INTO CTS_Adhoc.AH_CheckConsistent_DeviceFingerprint(DeviceFingerprintID, DeviceID,  FingerprintCode, FingerprintMoreInfo, CreatedTime, CreatedDate, InsertTime, MissingDevice )
		SELECT	df.DeviceFingerprintID
			,	df.DeviceID
            ,	df.FingerprintCode
            ,	df.FingerprintMoreInfo
            ,	df.CreatedTime
            ,	df.CreatedDate
			, 	df.InsertTime
			,	1 AS MissingDevice
		FROM DCS_DataCenter.DeviceFingerprint AS df 
		WHERE df.DeviceFingerprintID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Device AS dv WHERE dv.DeviceID = df.DeviceID );     

		#=========================
		SET lv_FromID = lv_ToID + 1;   
        
		UPDATE CTS_Adhoc.CS_Adhoc_Setting
        SET ParameterValue = LEAST(lv_ToID, lv_MaxID)
        WHERE ID = 3;
        
    END WHILE;
	
END$$
DELIMITER ;
