/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetTaggingBySpecialLicSubCC`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetTaggingBySpecialLicSubCC`(
	IN ip_CustIDs		TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250515@Thomas.Nguyen
		Task:	 	Get Tagging By Special Lic Sub Customer Classification
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250515@Thomas.Nguyen: 	Created [Redmine ID: #226847]

		Param's Explanation (filtered by): 

		Example:
			CALL CTS_DC_CustClassification_GetTaggingBySpecialLicSubCC (@ip_CustIDs:= '1284,1287');
	*/ 
	DECLARE CONST_TAGGINGTYPE_SPECIALLICSUBCC                       SMALLINT DEFAULT 3;
	DECLARE CONST_TAGGINGID_SPECIALLICSUBCC                         SMALLINT DEFAULT 1;
    DECLARE CONST_PROCESSSTATUS_COMPLETED_SPECIALLICSUBCC           SMALLINT DEFAULT 2;

	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE 	Temp_Cust (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
		,	TaggingID		SMALLINT
		,	TaggingType		SMALLINT
	);   

	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Cust (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 

	UPDATE Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.Customer_SpecialLicSubCC AS sls ON tmp.CustID = sls.CustID
	SET		tmp.TaggingType = CONST_TAGGINGTYPE_SPECIALLICSUBCC 
		,	tmp.TaggingID = CONST_TAGGINGID_SPECIALLICSUBCC
    WHERE sls.IsDisabled = 0 AND sls.ProcessStatus = 2;

    SELECT  tmp.CustID
        ,	tmp.TaggingID
        ,	tmp.TaggingType
    FROM Temp_Cust AS tmp;

END$$
DELIMITER ;