USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_Update`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_Update`(
		IN ip_custidlist		JSON
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200918@Lex.Khuat
		Task :		Update general/detailed categories for customers from probation management page
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200918@Lex.Khuat [Redmine ID: #141755]: Created
            
		Param's Explanation:
	*/
    
    DECLARE lv_CurrentDate		DATE DEFAULT CURRENT_DATE();

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;

	#============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_TargetCustomerCategory;
    #============================================

    CREATE TEMPORARY TABLE Temp_TargetCustomerCategory (
		CTSCustID			BIGINT UNSIGNED
	, 	CustID				INT UNSIGNED
	,	SubscriberID		INT	UNSIGNED
    ,	SportGroupID		SMALLINT
    ,	TargetCategoryID	SMALLINT
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    #========= IF SEARCH FOR SPECIFIC CUSTOMER, GET CTSCUSTID FROM KEYWORD =========
	INSERT INTO Temp_TargetCustomerCategory(CustID, SportGroupID, TargetCategoryID)
	SELECT 	tmp.CustID
		, 	tmp.SportGroupID
		, 	tmp.TargetCategoryID
	FROM JSON_TABLE(ip_custidlist,
		 "$[*]" COLUMNS(
			  CustID 				BIGINT UNSIGNED		PATH "$.CustID"
			, SportGroupID			SMALLINT			PATH "$.SportGroupID"
			, TargetCategoryID		SMALLINT			PATH "$.TargetCategoryID"
		 )) AS tmp;
    
    SELECT	CustID
			, -1 AS CustomerClass
    FROM Temp_TargetCustomerCategory;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;

