/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FP_DeviceEvolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FP_DeviceEvolution_Insert`(
    IN ip_DeviceEvolutionJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20240729@Jonathan.Doan: Created [RedmineID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_FP_DeviceEvolution_Insert('[{"ID":9,"EvolveByID":null,"DeviceID":1}]');
	*/
    DECLARE CONST_MINID_FP_DEVICEEVOLUTION	INT DEFAULT 23;
    
    DECLARE lv_CurrentDate 					TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	DECLARE lv_Max_FP_DeviceEvolutionID  	BIGINT UNSIGNED;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceEvolution;
    
	CREATE TEMPORARY TABLE Temp_DeviceEvolution(
			ID				 			BIGINT UNSIGNED    	NOT NULL
		,	EvolveByID		 			BIGINT UNSIGNED    	NULL
		,	DeviceID 					BIGINT UNSIGNED 	NOT NULL
        
        ,	PRIMARY KEY (ID)
    );
    
    
    INSERT IGNORE INTO Temp_DeviceEvolution(ID, EvolveByID, DeviceID)
    SELECT	rt.ID
		,	rt.EvolveByID
		,	rt.DeviceID
	FROM JSON_TABLE(
			ip_DeviceEvolutionJson,
			 "$[*]" COLUMNS(
						ID					BIGINT UNSIGNED 	PATH "$.ID"
					,	EvolveByID			BIGINT UNSIGNED 	PATH "$.EvolveByID"
					,	DeviceID			BIGINT UNSIGNED 	PATH "$.DeviceID"
				)
		   ) AS rt;
	
    UPDATE DCS_DataCenter.FP_DeviceFingerprintAccount AS dfa
		INNER JOIN Temp_DeviceEvolution AS tmp ON tmp.ID = dfa.ID
	SET dfa.EvolveByID = tmp.EvolveByID,
		dfa.DeviceID = tmp.DeviceID;
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    SET lv_Max_FP_DeviceEvolutionID = (SELECT MAX(ID) FROM Temp_DeviceEvolution);
    
    IF lv_Max_FP_DeviceEvolutionID IS NOT NULL AND lv_Max_FP_DeviceEvolutionID > 0 THEN
		UPDATE DCS_DataCenter.SystemSetting AS sys
		SET sys.VValue 	= CONCAT('', lv_Max_FP_DeviceEvolutionID),
		    sys.UpdatedTime = lv_CurrentDate
		WHERE ID = CONST_MINID_FP_DEVICEEVOLUTION;
    END IF;
    
END$$

DELIMITER ;