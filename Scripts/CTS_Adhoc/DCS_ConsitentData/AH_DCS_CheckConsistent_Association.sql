DROP PROCEDURE IF EXISTS `AH_DCS_CheckConsistent_Association`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `AH_DCS_CheckConsistent_Association`(
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
    
    SET lv_FromID = (SELECT st.ParameterValue FROM CTS_Adhoc.CS_Adhoc_Setting AS st WHERE st.ID = 4);    
    SET lv_MaxID = (SELECT MAX(ass.AssociationID) FROM DCS_DataCenter.Association AS ass);
    
	WHILE (lv_FromID <= lv_MaxID)
    DO
		
		SET lv_ToID = lv_FromID + ip_BatchSize;  
        
		# Check NOT EIXSTING DeviceCode
        INSERT IGNORE INTO CTS_Adhoc.AH_CheckConsistent_Association_MissDevice(AssociationID, DeviceID,  AccountID, SubscriberID, CreatedTime, CreatedDate, InsertTime, IsCTSTransformed)
		SELECT	ass.AssociationID
			,	ass.DeviceID
            ,	ass.AccountID
            ,	ass.SubscriberID
            ,	ass.CreatedTime
            ,	ass.CreatedDate
			, 	ass.InsertTime
			,	ass.IsCTSTransformed
		FROM DCS_DataCenter.Association AS ass 
		WHERE ass.AssociationID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Device AS dv WHERE dv.DeviceID = ass.DeviceID );     

		# Check NOT EIXSTING DeviceCode
        INSERT IGNORE INTO CTS_Adhoc.AH_CheckConsistent_Association_MissAccount(AssociationID, DeviceID,  AccountID, SubscriberID, CreatedTime, CreatedDate, InsertTime, IsCTSTransformed)
		SELECT	ass.AssociationID
			,	ass.DeviceID
            ,	ass.AccountID
            ,	ass.SubscriberID
            ,	ass.CreatedTime
            ,	ass.CreatedDate
			, 	ass.InsertTime
			,	ass.IsCTSTransformed
		FROM DCS_DataCenter.Association AS ass 
		WHERE ass.AssociationID BETWEEN lv_FromID AND lv_ToID
				AND NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Account AS acc WHERE acc.AccountID = ass.AccountID );     

		#=========================
		SET lv_FromID = lv_ToID + 1;   
        
		UPDATE CTS_Adhoc.CS_Adhoc_Setting
        SET ParameterValue = LEAST(lv_ToID, lv_MaxID)
        WHERE ID = 4;
        
    END WHILE;
	
END$$
DELIMITER ;
