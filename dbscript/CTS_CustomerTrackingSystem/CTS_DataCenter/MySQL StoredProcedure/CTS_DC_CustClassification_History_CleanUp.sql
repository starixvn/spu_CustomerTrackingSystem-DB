/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_History_CleanUp`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_History_CleanUp`(
		IN ip_TakeDays 	INT 
    ,	IN ip_Batch 	INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20210324@Irena.Vo	
		Task :		Clean-up Classification History are not used. Only take 30 lastest days.
		DB:			CTS_DataCenter
		Original:
		
		Revisions:	
			- 20210324@Irena.Vo: Created [RedmineID: #148997]
            - 20210406@Irena.Vo: Fix bug Clean ID is NULL [RedmineID: #152938]
			- 20210622@Aries.Nguyen: Update coding convention and improve locking  [Redmine ID: #157203]	

		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_History_CleanUp(30,200);
	*/
    DECLARE lv_MaxDate 		DATE;
    DECLARE lv_CleanedID 	BIGINT;
	DECLARE lv_EndID 		BIGINT;
    
    SET	lv_MaxDate = DATE_SUB(CURRENT_DATE(), INTERVAL ip_TakeDays DAY);

    SELECT ParameterValue
	INTO lv_CleanedID
	FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 15; 

    SELECT MAX(temp.ID) 
	INTO lv_EndID
	FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History
		  WHERE ID > lv_CleanedID AND InsertDate <= lv_MaxDate AND IsDataChanged = 0
		  ORDER BY ID ASC
		  LIMIT ip_Batch) AS temp;
                            
    IF (lv_EndID IS NULL) THEN 
		LEAVE sp; 
	END IF;
    
	DELETE 
	FROM CTS_DataCenter.CTSCustomerClassification_History
	WHERE ID > lv_CleanedID AND ID <= lv_EndID AND InsertDate <= lv_MaxDate AND IsDataChanged = 0;
	
	UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_EndID
	WHERE ParameterID = 15; 
END$$
DELIMITER ;