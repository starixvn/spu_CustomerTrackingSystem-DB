/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_SpecialCustClass_ValidateUsername`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_ValidateUsername`(
		IN ip_FunctionID	TINYINT /*1: Add, 2: Remove*/
	,	IN ip_ListUser 		JSON	
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240314@Thomas.Nguyen
		Task:		Validate a list of usernames for adding/removing special CC[Redmine ID: #201360]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20240314@Thomas.Nguyen: Created [Redmine ID: #201360]
		
		Param's Explanation (filtered by):   
            
		Example:			
			- CALL CTS_DataCenter.CTS_DC_SpecialCustClass_ValidateUsername('');
	*/
    
	DECLARE	CONST_CATEGORYID_VVIP 	INT DEFAULT 210;
	DECLARE	CONST_GROUP_NORMAL		INT DEFAULT 200;

    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			Username 	    VARCHAR(50) 
		,	CTSCustID	    BIGINT UNSIGNED
		,	CustID		    INT UNSIGNED
		,	SportID		    SMALLINT UNSIGNED
		,	SubscriberID	INT
		,	IsLicenseeVIP	TINYINT
		,	IsExistedCust   BIT DEFAULT 0
		,	ValidatedID	    TINYINT DEFAULT 1 /* 0: not existed in CTS, 1: valid, 2: not a member, 3: marked VVIP, 4: marked Special CC*/
		,	PRIMARY KEY (Username, SportID)
		,	KEY IX_Temp_Cust_IsExistedCust_CTSCustID (IsExistedCust, ValidatedID, SportID)
		,	KEY IX_Temp_Cust_CustID (CustID)
	);
    
	INSERT IGNORE INTO Temp_Cust(Username,CTSCustID,CustID,SportID,SubscriberID,IsLicenseeVIP,IsExistedCust,ValidatedID)
	SELECT	tmp.Username
		,	cus.CTSCustID
		,	cus.CustID
		,	tmp.SportID
		,	cus.SubscriberID
		,	cus.IsLicenseeVIP
		,	CASE WHEN cus.CTSCustID IS NOT NULL THEN 1 ELSE 0 END AS IsExistedCust
		,	CASE	WHEN cus.CTSCustID IS NULL THEN 0
					WHEN cus.RoleID <> 1 THEN 2 ELSE 1 END AS ValidatedID
	FROM JSON_TABLE(ip_ListUser, 
						'$[*]' COLUMNS (Username	VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH '$.Username'
									,	SportID		SMALLINT UNSIGNED   PATH '$.SportID' 
								)) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName = tmp.UserName;

	UPDATE Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName2 = tmp.UserName
	SET		tmp.CTSCustID = cus.CTSCustID
		,	tmp.CustID = cus.CustID
		,	tmp.SubscriberID = cus.SubscriberID
		,	tmp.IsLicenseeVIP = cus.IsLicenseeVIP
		,	tmp.IsExistedCust = 1
		,	tmp.ValidatedID = CASE WHEN cus.RoleID <> 1 THEN 2 ELSE 1 END
	WHERE tmp.IsExistedCust = 0;

	UPDATE Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS class ON class.CustID = tmp.CustID 
	SET tmp.ValidatedID	= 3
	WHERE tmp.IsExistedCust = 1 AND class.SportGroupID = CONST_GROUP_NORMAL AND class.CategoryID = CONST_CATEGORYID_VVIP;
	
	UPDATE Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS scc ON scc.CustID = tmp.CustID
	SET tmp.ValidatedID = 4
	WHERE tmp.IsExistedCust = 1 AND tmp.ValidatedID = 1 AND tmp.SportID = 0 AND scc.CreatedFromFunction = 1;

	UPDATE Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.SpecialCustomerClass_BySport AS sbs ON sbs.CustID = tmp.CustID AND sbs.SportID = tmp.SportID
	SET tmp.ValidatedID = 4
	WHERE tmp.IsExistedCust = 1 AND tmp.ValidatedID = 1 AND tmp.SportID <> 0;

	SELECT	tmp.Username
		,	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.SportID
		,	tmp.SubscriberID
		,	tmp.IsLicenseeVIP
		,	tmp.ValidatedID
		,	CASE WHEN tmp.IsExistedCust = 1 AND ((ip_FunctionID = 1 AND tmp.ValidatedID = 1) OR (ip_FunctionID = 2 AND tmp.ValidatedID = 4)) THEN 1 ELSE 0 END IsValid
	FROM Temp_Cust AS tmp;

END$$
DELIMITER ;