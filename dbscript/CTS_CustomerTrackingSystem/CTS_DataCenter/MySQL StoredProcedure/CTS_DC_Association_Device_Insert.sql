/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Device_Insert`(
		IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20210226@Aries.Nguyen
		Task:		Insert association by device
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210226@Aries.Nguyen: Created [Redmine ID: #148998]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_Device_Insert(200);
	*/
    DECLARE lv_CTSAssDevID BIGINT UNSIGNED;
    DECLARE lv_CTSAssDevID_Next BIGINT UNSIGNED;
    
    SELECT IFNULL(CONVERT(ParameterValue, UNSIGNED),0)
    INTO lv_CTSAssDevID
    FROM  CTS_DataCenter.SystemParameter
    WHERE ParameterID = 13;
    
    WITH CTE_NewAccountDevice AS (
			SELECT CTSAssDevID
			FROM CTS_DataCenter.AssociationByDevice as asDe
			WHERE CTSAssDevID > lv_CTSAssDevID
			LIMIT ip_BatchSize
	)
	SELECT  IFNULL(MAX(CTSAssDevID), lv_CTSAssDevID)
    INTO lv_CTSAssDevID_Next
	FROM CTE_NewAccountDevice;
    
    IF lv_CTSAssDevID_Next = lv_CTSAssDevID THEN
		LEAVE sp;
	END IF;
    
	INSERT IGNORE INTO Association(FromCTSCustID,ToCTSCustID,CreatedDate)
	WITH CTE_NewAccountDevice AS (
		SELECT 	asDe.CTSCustID
			,	asDe.DCSDeviceID
            ,	asDe.CreatedTime
		FROM CTS_DataCenter.AssociationByDevice as asDe
		WHERE CTSAssDevID BETWEEN lv_CTSAssDevID AND lv_CTSAssDevID_Next
	)
	SELECT  LEAST(cte.CTSCustID, dev.CTSCustID)
		,	GREATEST(cte.CTSCustID, dev.CTSCustID) 
		,	GREATEST(cte.CreatedTime, dev.CreatedTime)
	FROM CTE_NewAccountDevice AS cte
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dev ON dev.DCSDeviceID = cte.DCSDeviceID 
															AND dev.CTSAssDevID <= lv_CTSAssDevID_Next
															AND cte.CTSCustID != dev.CTSCustID;
    
    UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = lv_CTSAssDevID_Next
	WHERE ParameterID = 13;
END$$

DELIMITER ;