DROP PROCEDURE IF EXISTS `AH_CheckConsistent_DCS_DeviceCode`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `AH_CheckConsistent_DCS_DeviceCode`(
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
    
    SET lv_FromID = (SELECT st.ParameterValue FROM CTS_Adhoc.CS_Adhoc_Setting AS st WHERE st.ID = 2);    
    SET lv_MaxID = (SELECT MAX(dc.DeviceCodeID) FROM DCS_DataCenter.DeviceCode AS dc);
    
	WHILE (lv_FromID <= lv_MaxID)
    DO
		
		SET lv_ToID = lv_FromID + ip_BatchSize;  
        
		# Check NOT EIXSTING DeviceCode
        INSERT INTO CTS_Adhoc.AH_CheckConsistent_DeviceCode(DeviceCodeID, DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime, MissingDevice )
		SELECT	dc.DeviceCodeID
			,	dc.DeviceCode
            ,	dc.DeviceID
            ,	dc.FirstTransID
            ,	dc.CreatedTime
            ,	dc.CreatedDate
			, 	dc.InsertTime
			,	1 AS MissingDevice
		FROM DCS_DataCenter.DeviceCode AS dc 
		WHERE dc.DeviceCodeID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Device AS dv WHERE dv.DeviceID = dc.DeviceID );     

		#=========================
		SET lv_FromID = lv_ToID + 1;   
        
		UPDATE CTS_Adhoc.CS_Adhoc_Setting
        SET ParameterValue = LEAST(lv_ToID, lv_MaxID)
        WHERE ID = 2;
        
    END WHILE;
	
END$$
DELIMITER ;
