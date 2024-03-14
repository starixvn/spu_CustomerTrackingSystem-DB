/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_SpecialCustClass_ValidateUsername`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_ValidateUsername`(
	  IN ip_ListUser 		LONGTEXT
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

    DROP TEMPORARY TABLE IF EXISTS Temp_User;
    CREATE TEMPORARY TABLE Temp_User(
			Username 	    VARCHAR(50)
		,	CTSCustID	    BIGINT UNSIGNED
		,	CustID		    INT UNSIGNED
		,	SportID		    SMALLINT UNSIGNED
		,	ValidatedID	    TINYINT DEFAULT 1 /* 0: not existed in CTS, 1: valid, 2: SMA, 3: marked VVIP, 4: marked Special CC*/
		,	IsExistedCust   BIT DEFAULT 0
		,	PRIMARY KEY (Username, SportID)
		,	KEY IX_Temp_User_IsExistedCust_CTSCustID (IsExistedCust, ValidatedID, SportID)
		,	KEY IX_Temp_User_CustID (CustID)
	);
    
	INSERT IGNORE INTO Temp_User (Username,SportID)
	SELECT	tmp.Username
		,	tmp.SportID
	FROM JSON_TABLE(ip_ListUser, 
						'$[*]' COLUMNS (Username	VARCHAR(50)			PATH '$.Username'
									,	SportID		SMALLINT UNSIGNED   PATH '$.SportID' 
								)) AS tmp;

	UPDATE Temp_User AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName = tmp.UserName
	SET		tmp.CTSCustID = cus.CTSCustID
		,	tmp.CustID = cus.CustID
		,	tmp.IsExistedCust = 1
		,	tmp.ValidatedID = CASE WHEN cus.RoleID <> 1 THEN 2 ELSE tmp.ValidatedID END
	WHERE tmp.IsExistedCust = 0;

	UPDATE Temp_User AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName2 = tmp.UserName
	SET		tmp.CTSCustID = cus.CTSCustID
		,	tmp.CustID = cus.CustID
		,	tmp.IsExistedCust = 1
		,	tmp.ValidatedID = CASE WHEN cus.RoleID <> 1 THEN 2 ELSE tmp.ValidatedID END
	WHERE tmp.IsExistedCust = 0 AND tmp.ValidatedID = 1;

    UPDATE Temp_User AS tmp
    SET tmp.ValidatedID = 0
    WHERE tmp.IsExistedCust = 0;

	UPDATE Temp_User AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS class ON class.CustID = tmp.CustID 
	SET tmp.ValidatedID	= 3
	WHERE tmp.IsExistedCust = 1 AND class.SportGroupID = CONST_GROUP_NORMAL AND class.CategoryID = CONST_CATEGORYID_VVIP;
	
	UPDATE Temp_User AS tmp
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS scc ON scc.CustID = tmp.CustID
	SET tmp.ValidatedID = 4
	WHERE tmp.IsExistedCust = 1 AND tmp.ValidatedID = 1 AND tmp.SportID = 0 AND scc.CreatedFromFunction = 1;

	UPDATE Temp_User AS tmp
		INNER JOIN CTS_DataCenter.SpecialCustomerClass_BySport AS sbs ON sbs.CustID = tmp.CustID AND sbs.SportID = tmp.SportID
	SET tmp.ValidatedID = 4
	WHERE tmp.IsExistedCust = 1 AND tmp.ValidatedID = 1 AND tmp.SportID <> 0;

	SELECT	tmp.Username
		,	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.SportID
		,	tmp.ValidatedID
		,	CASE WHEN tmp.IsExistedCust = 1 AND tmp.ValidatedID = 1 THEN 1 ELSE 0 END IsValid
	FROM Temp_User AS tmp;

END$$
DELIMITER ;