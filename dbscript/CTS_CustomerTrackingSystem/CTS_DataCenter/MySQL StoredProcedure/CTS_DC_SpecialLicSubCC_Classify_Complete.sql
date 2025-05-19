/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_SpecialLicSubCC_Classify_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialLicSubCC_Classify_Complete`(
	IN ip_CustInfo JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250514@Casey.Huynh
		Task:	 	SpecialLicSubCC Scan Get
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250514@Casey.Huynh: 	Created [Redmine ID: #226847]

		Param's Explanation (filtered by): 

		Example:
			CALL CTS_DC_SpecialLicSubCC_Classify_Complete(@ip_CustInfo:=
						'[	{"CustID":"100020250","CategoryID":"2500"}
						,	{"CustID":"26803005","CategoryID":"2503"}
                        ,	{"CustID":"16647323","CategoryID":"NULL"}]');
			SELECT * FROM Customer_SpecialLicSubCC WHERE CustID IN (100020250,26803005,16647323);
            SELECT cat.CategoryName, cls.* FROM CTSCustomerClassification cls
				INNER JOIN CustomerCategory AS cat on cls.CategoryID = cat.CategoryID 
			WHERE CustID IN (100020250,26803005,16647323);
	*/
    DECLARE CONST_PROCESSSTATUS_INPROGRESS	TINYINT DEFAULT 1;
    DECLARE CONST_PROCESSSTATUS_COMPLETE	TINYINT DEFAULT 2;
	DECLARE CONST_CATEGORYID_NEW_LICSUB 	INT DEFAULT 40106;
	DECLARE CONST_CATEGORYID_PROB_LICSUB 	INT DEFAULT 40406;
	DECLARE CONST_CATEGORYID_SMART_LICSUB 	INT DEFAULT 40506;
	DECLARE CONST_CATEGORYID_RISKY_LICSUB 	INT DEFAULT 40606;
	DECLARE CONST_STATUSCODE_SUCCESS_EXACTLY		INT DEFAULT 200;
	DECLARE CONST_STATUSCODE_SUCCESS_VALIDRANGE		INT DEFAULT 201;
	DECLARE CONST_STATUSCODE_UNSUCCESS	 			INT DEFAULT 401;  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID			INT PRIMARY KEY
        ,	CategoryID		INT UNSIGNED
    );
   
    INSERT IGNORE INTO Temp_Cust(CustID, CategoryID)
	SELECT	info.CustID
		, 	info.CategoryID
	FROM JSON_TABLE(ip_CustInfo,
		 "$[*]" COLUMNS(
				CustID			BIGINT UNSIGNED	PATH "$.CustID" 
			, 	CategoryID		INT UNSIGNED	PATH "$.CategoryID"  )
	) AS info;
	
    UPDATE CTS_DataCenter.Customer_SpecialLicSubCC AS cus
		INNER JOIN Temp_Cust AS tmp ON cus.CustID = tmp.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmp.CategoryID
	SET 	cus.ProcessStatus = CONST_PROCESSSTATUS_COMPLETE
		,	cus.LatestCustomerClass = cat.CustomerClass
		,	cus.StatusCode = (CASE WHEN cus.APICustomerClass = cat.CustomerClass THEN CONST_STATUSCODE_SUCCESS_EXACTLY
									ELSE CONST_STATUSCODE_SUCCESS_VALIDRANGE END)
	WHERE cus.ProcessStatus = 1
		AND tmp.CategoryID IN (CONST_CATEGORYID_NEW_LICSUB,CONST_CATEGORYID_PROB_LICSUB,CONST_CATEGORYID_SMART_LICSUB,CONST_CATEGORYID_RISKY_LICSUB);

	UPDATE CTS_DataCenter.Customer_SpecialLicSubCC AS cus
		INNER JOIN Temp_Cust AS tmp ON cus.CustID = tmp.CustID
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CategoryID = tmp.CategoryID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmp.CategoryID
	SET 	cus.ProcessStatus = CONST_PROCESSSTATUS_COMPLETE
		,	cus.LatestCustomerClass = cat.CustomerClass
		,	cus.StatusCode = CONST_STATUSCODE_UNSUCCESS
    WHERE cus.ProcessStatus = 1
		AND tmp.CategoryID NOT IN (CONST_CATEGORYID_NEW_LICSUB,CONST_CATEGORYID_PROB_LICSUB,CONST_CATEGORYID_SMART_LICSUB,CONST_CATEGORYID_RISKY_LICSUB);
END$$
DELIMITER ;
