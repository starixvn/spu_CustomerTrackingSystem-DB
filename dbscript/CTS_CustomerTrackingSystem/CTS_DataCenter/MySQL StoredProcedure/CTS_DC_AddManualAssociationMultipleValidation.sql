DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AddManualAssociationMultipleValidation`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_AddManualAssociationMultipleValidation`(
		IN ip_UsernameList 	VARCHAR(2600),
        IN ip_RootCTSCustID	BIGINT
)
BEGIN
	/*
		Created:	20200622@Harvey
		Task :		Validation for add manual association muptiple
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200416@Harvey.Nguyen: Initial	 		[Redmine ID: #136212]
            
		Param's Explanation:
        
        CALL CTS_DataCenter.CTS_DC_AddManualAssociationMultipleValidation ('',1);
	*/ 

	DROP TABLE IF EXISTS TempItemTable;
	DROP TABLE IF EXISTS TempValidateUsername;
	CREATE TEMPORARY TABLE TempValidateUsername( 	 
		UserName			VARCHAR(50)
	,	CTSCustID			BIGINT
    ,	SubscriberID		INT
    ,	IsDuplicated		BOOLEAN		DEFAULT FALSE);
    
    DROP TABLE IF EXISTS TempUserStatistic;
    CREATE TEMPORARY TABLE TempUserStatistic( 	 
		CTSCustID			BIGINT
    ,	Quantity			INT);
 
    CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_UsernameList,",",'VARCHAR(50)');
    
    INSERT INTO TempValidateUsername(UserName)
    SELECT item FROM TempItemTable;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    UPDATE TempValidateUsername tvu
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON tvu.UserName = cust.UserName
    SET tvu.CTSCustID = cust.CTSCustID
	,	tvu.SubscriberID = cust.SubscriberID;
    
    UPDATE TempValidateUsername tvu
		INNER JOIN CTS_DataCenter.AssociationByManual abm 
			ON ((abm.FromCTSCustID = ip_RootCTSCustID AND abm.ToCTSCustID = tvu.CTSCustID)
				OR (abm.FromCTSCustID = tvu.CTSCustID AND abm.ToCTSCustID = ip_RootCTSCustID))
    SET tvu.IsDuplicated = TRUE;
    

    INSERT INTO TempUserStatistic (CTSCustID,Quantity)
	SELECT CTSCustID,count(CTSCustID)
		FROM TempValidateUsername
	GROUP BY CTSCustID;

	UPDATE TempValidateUsername tvu
		INNER JOIN TempUserStatistic tus ON tvu.CTSCustID = tus.CTSCustID
	SET tvu.IsDuplicated = TRUE
	WHERE tus.Quantity > 1;

    
    SELECT UserName
			,CTSCustID
            ,SubscriberID
			,IsDuplicated 
	FROM TempValidateUsername;
END$$	
DELIMITER ;