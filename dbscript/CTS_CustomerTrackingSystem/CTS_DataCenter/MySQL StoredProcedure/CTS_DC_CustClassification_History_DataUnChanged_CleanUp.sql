/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_History_DataUnChanged_CleanUp`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_History_DataUnChanged_CleanUp`(
    	OUT	op_IsDataExist		SMALLINT
)
    SQL SECURITY INVOKER
sp:BEGIN
		/*
		Created:	20210901@Aries.Nguyen	
		Task :		Clean-up Classification History are not used. Only take 30 lastest days.
		DB:			CTS_DataCenter
		Original:
		
		Revisions:	
			- 20210901@Aries.Nguyen: Created [RedmineID: #160758]	
            
		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_History_DataUnChanged_CleanUp(@IsDataExist);
	*/
    DECLARE lv_DateValid 		DATE;
	DECLARE lv_BatchSize 		INT;
	DECLARE lv_TakeDay 			INT;
	DECLARE lv_NextDate 		DATE;
    DECLARE lv_LastID 			BIGINT UNSIGNED;
	DECLARE lv_NextLastID 		BIGINT UNSIGNED;
	DECLARE lv_LastIDValid 		BIGINT UNSIGNED;
	DECLARE lv_NextIDInvalid 	BIGINT UNSIGNED;   

    SELECT ParameterValue
	INTO lv_LastID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 15; 

	SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 40; 

	SELECT ParameterValue
	INTO lv_TakeDay
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 41; 

	SET	lv_DateValid = DATE_SUB(CURRENT_DATE(), INTERVAL lv_TakeDay DAY);

	SELECT MAX(tbl.ID)
    INTO lv_NextLastID
    FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History
		  WHERE ID > lv_LastID
		  ORDER BY ID ASC
		  LIMIT lv_BatchSize) AS tbl;

	SELECT MAX(temp.ID) 
	INTO lv_LastIDValid
	FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History
		  WHERE ID BETWEEN lv_LastID AND lv_NextLastID 
			AND InsertDate <= lv_DateValid 
			AND IsDataChanged = 0) AS temp;
                            
    IF lv_LastIDValid IS NOT NULL THEN 
		DELETE 
		FROM CTS_DataCenter.CTSCustomerClassification_History
		WHERE ID BETWEEN lv_LastID AND lv_NextLastID 
			AND InsertDate <= lv_DateValid 
			AND IsDataChanged = 0;
	
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_LastIDValid
		WHERE ParameterID = 15; 

		SET op_IsDataExist = 1;

		LEAVE sp; 
	END IF;

	SELECT ID
	INTO lv_NextIDInvalid
	FROM CTS_DataCenter.CTSCustomerClassification_History 
	WHERE  ID BETWEEN lv_LastID AND lv_NextLastID
		AND InsertDate > lv_DateValid 
		AND IsDataChanged = 0
	ORDER BY ID ASC
	LIMIT 1;

	IF lv_NextIDInvalid IS NOT NULL THEN
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_NextIDInvalid
		WHERE ParameterID = 15; 

		SET op_IsDataExist = 0;

		LEAVE sp; 
	END IF;
	
	SELECT InsertDate
	INTO lv_NextDate
	FROM CTS_DataCenter.CTSCustomerClassification_History 
	WHERE  ID > lv_NextLastID
	ORDER BY ID ASC
	LIMIT 1;

	UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_NextLastID
	WHERE ParameterID = 15; 

	IF lv_NextDate <= lv_DateValid THEN
		SET op_IsDataExist = 1;
	ELSE
		SET op_IsDataExist = 0;
	END IF;

	LEAVE sp; 

END$$
DELIMITER ;