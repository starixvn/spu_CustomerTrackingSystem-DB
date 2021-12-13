DROP PROCEDURE IF EXISTS `AH_CTS_CheckConsistent_AssociationByDevice`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `AH_CTS_CheckConsistent_AssociationByDevice`(
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
    
    SET lv_FromID = (SELECT st.ParameterValue FROM CTS_Adhoc.CS_Adhoc_Setting AS st WHERE st.ID = 5);    
    SET lv_MaxID = (SELECT MAX(ass.CTSAssDevID) FROM CTS_DataCenter.AssociationByDevice AS ass);
    
	WHILE (lv_FromID <= lv_MaxID)
    DO
		
		SET lv_ToID = lv_FromID + ip_BatchSize;  
        
		# Check NOT EIXSTING Device
        INSERT IGNORE INTO CTS_Adhoc.AH_CheckConsistent_AssociationByDevice_MissDevice(CTSAssDevID, CTSCustID,  DCSDeviceID, SubscriberID, CreatedTime, InsertTime)
		SELECT	ass.CTSAssDevID
			,	ass.CTSCustID
            ,	ass.DCSDeviceID
            ,	ass.SubscriberID
            ,	ass.CreatedTime
			, 	ass.InsertTime
		FROM CTS_DataCenter.AssociationByDevice AS ass 
		WHERE ass.CTSAssDevID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Device AS dv WHERE dv.DeviceID = ass.DCSDeviceID );     
        
		#=========================
		SET lv_FromID = lv_ToID + 1;   
        
		UPDATE CTS_Adhoc.CS_Adhoc_Setting
        SET ParameterValue = LEAST(lv_ToID, lv_MaxID)
        WHERE ID = 5;
        
    END WHILE;
	
END$$
DELIMITER ;
