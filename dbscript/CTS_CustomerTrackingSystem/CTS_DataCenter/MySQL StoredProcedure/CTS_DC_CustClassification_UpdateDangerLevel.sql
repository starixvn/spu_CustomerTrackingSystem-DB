/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsAPIAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_UpdateDangerLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_UpdateDangerLevel`(
		IN ip_ProcessedCustList 	JSON
    , 	IN ip_TypeID 				SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20210401@Irena.Vo
		Task:		Update IsAppliedDangerlevel from Customer List are updated Danger level in mainDB successfully
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210401@Irena.Vo: Create [RedmineID: #152249] 
			- 20210625@Long.Luu: Refactor  [Redmine ID: #157203]
		Param's Explanation (filtered by):		
			- ip_ProcessedCustList ; ip_TypeID: 1(Original) / 2(ABI) / 3(Other)
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_UpdateDangerLevel('[{"CustId":"2324948","ScannedTime":"2021-03-08 04:04:48"},{"CustId":"36266996","ScannedTime":"2021-03-08 04:13:38"}]', 1);
	*/ 
    
	DECLARE	CONST_GROUP_NORMAL 				INT DEFAULT 200;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedCustList;    
	CREATE TEMPORARY TABLE Temp_ProcessedCustList 
    (	  
			CustID              BIGINT UNSIGNED 
        ,   ScannedTime         DATETIME
        ,   PRIMARY KEY 		PK_Temp_ProcessedCustList_CustID_ScannedTime(CustID,ScannedTime)
     );
    
    INSERT INTO Temp_ProcessedCustList(CustID, ScannedTime)
	SELECT DISTINCT 	temp.CustID
					, 	temp.ScannedTime
	FROM JSON_TABLE(ip_ProcessedCustList,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, ScannedTime		DATETIME		    PATH "$.ScannedTime"
		 )) AS temp;
    
    IF (ip_TypeID = 1) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = CONST_GROUP_NORMAL 
                AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedCC = 1 AND his.IsAppliedDangerLevel1 = 0 
		SET his.IsAppliedDangerLevel1 = 1;
	END IF;
    
	/* IF (ip_TypeID = 2) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedCC = 1 AND his.IsAppliedDangerLevel2 = 0 
		SET his.IsAppliedDangerLevel2 = 1;
	END IF;
	IF (ip_TypeID = 3) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedCC = 1 AND his.IsAppliedDangerLevel3 = 0 
		SET his.IsAppliedDangerLevel3 = 1;
	END IF; */
END$$
DELIMITER ;