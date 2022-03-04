/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_ValidateMultipleInput`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_ValidateMultipleInput`(
		IN	ip_UserNames	LONGTEXT
    ,	IN 	ip_CategoryID 	SMALLINT
    ,	IN	ip_Comment		TEXT
    ,	IN 	ip_UserID		INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20220307@Irena.Vo
		Task:		Get Category Filter for Problem Account Management page
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220307@Irena.Vo: Created [Redmine ID: #159014]
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_ProblemAccountManagement_ValidateMultipleInput('55555,55555 ,def,222Sub00,Soon88ACCRMB,NextBetLAK01001,Soon88RMB01329,SA-GBP',153,'Na Test',8); 
			- CALL CTS_DC_ProblemAccountManagement_ValidateMultipleInput('Soon88BonusUUS,08RMB,339BHK,SBOTEST1,SupertestHF1',159,'Na Test',8);	
	*/
    DECLARE lv_ReasonID SMALLINT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_UserNames;
	CREATE TEMPORARY TABLE Temp_UserNames( 	 
			UserName				VARCHAR(50)
		,	IsDuplicated			BIT DEFAULT 0 /* 0: Not duplicated UserName;  1: Duplicated UserName */
        ,	IsInvalid 				BIT DEFAULT 0 /* 0: Existed CTSCustomer;  1: Not existed CTSCustomer */
        ,	IsSubAccount 			BIT DEFAULT 0 /* 0: Is Main Account;  1: Is Sub Account */
        ,	IsSMALicensee 			BIT DEFAULT 0 /* 0: Is not Upline Licensee Account;  1: Is Upline Licensee Account */
        ,	IsInternalAccount		BIT DEFAULT 0 /* 0: Is not OddsFeed Site/ Downline of 8RM, BARM/ CashOut; 1: Is OddsFeed Site/ Downline of 8RM, BARM/ CashOut */
        ,	IsExistedPinCategory	BIT DEFAULT 0 /* 0: Not existed Pin Category;  1: Existed Pin Category */
		,	IsExistedNAPPA 			BIT DEFAULT 0 /* 0: Not existed NAP PA (M);  1: Existed NAP PA (M) */
        ,	INDEX 					IX_Temp_UserNames_UserName (UserName)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DuplicatedUserNames;
	CREATE TEMPORARY TABLE Temp_DuplicatedUserNames( 	 
			UserName				VARCHAR(50)
        ,	INDEX 					IX_Temp_DuplicatedUserNames_UserName (UserName)
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedCustomers;
	CREATE TEMPORARY TABLE Temp_ExistedCustomers( 	 
			CTSCustID 				BIGINT UNSIGNED PRIMARY KEY
		,	UserName				VARCHAR(50)
        ,	RoleID					SMALLINT
        ,   CustSubID				SMALLINT
        ,	Recommend				BIGINT UNSIGNED
        ,	SiteID					INT
        ,	IsLicensee				BIT /* 0: Credit,  1: Licensee */
        ,	INDEX 					IX_Temp_ExistedCustomers_UserName (UserName)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedNAPPA;
	CREATE TEMPORARY TABLE Temp_ExistedNAPPA( 	
			UserName				VARCHAR(50)
        ,	INDEX 					IX_Temp_ExistedNAPPA_UserName (UserName)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ErrorResults;
	CREATE TEMPORARY TABLE Temp_ErrorResults( 	
			UserName				VARCHAR(50)
		,	ErrorMsg				TEXT
	);
    
    /*1. Receive UserName List */
    SET @sql = 	CONCAT("INSERT INTO Temp_UserNames (UserName) VALUES ('", REPLACE(ip_UserNames, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
    /*2. Validate for Duplicated UserName */
    INSERT IGNORE INTO Temp_DuplicatedUserNames(UserName)
    SELECT DISTINCT UserName
	FROM Temp_UserNames
	GROUP BY UserName
	HAVING COUNT(1) > 1;
    
    UPDATE Temp_UserNames AS u
		INNER JOIN Temp_DuplicatedUserNames AS d ON u.UserName = d.UserName
	SET u.IsDuplicated = 1;

	/*3. Get Existed Customers */
	INSERT IGNORE INTO Temp_ExistedCustomers(CTSCustID, UserName, RoleID, CustSubID, Recommend, SiteID, IsLicensee)
    SELECT 	DISTINCT c.CTSCustID
		,	u.UserName
        , 	c.RoleID
        ,	c.CustSubID
        ,	c.Recommend
        ,	c.SiteID
		,	CASE WHEN m.SubscriberGroupID = 2 THEN 1 ELSE 0 END AS IsLicensee
	FROM Temp_UserNames AS u
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON u.UserName = c.UserName
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS m ON m.SiteID = c.SiteID;

    /*4. Validate for Is Not Existed CTSCustomer */
    UPDATE Temp_UserNames AS u
	SET u.IsInvalid = 1
    WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedCustomers AS ec WHERE ec.UserName = u.UserName);
    
    /*5. Validate for Is Sub Account */
    UPDATE Temp_UserNames AS u
	SET u.IsSubAccount = 1
    WHERE EXISTS (SELECT 1 FROM Temp_ExistedCustomers AS ec WHERE ec.UserName = u.UserName AND ec.CustSubID <> 0);
    
     /*6. Validate for Is Upline Licensee Account */
    UPDATE Temp_UserNames AS u
	SET u.IsSMALicensee = 1
    WHERE EXISTS (SELECT 1 FROM Temp_ExistedCustomers AS ec WHERE ec.UserName = u.UserName AND ec.IsLicensee = 1 AND ec.RoleID <> 1);
    
	/*7. Validate for Is Internal Account */
	UPDATE Temp_UserNames AS u
		INNER JOIN Temp_ExistedCustomers AS ec ON ec.UserName = u.UserName  
        LEFT JOIN CTS_DataCenter.StaticList AS st ON st.ItemID = ec.SiteID AND st.ListID = 11 /* OddsFeed site: NextBet, 9wickets, 9wsports */
	SET u.IsInternalAccount = 1
	WHERE st.ItemID IS NOT NULL OR (ec.Recommend IN (52466,5707545) AND ec.RoleID = 1) OR ec.UserName Like '%CashOut';
    
	/*8. Validate for Existed Pin Category */
    UPDATE Temp_UserNames AS u
		INNER JOIN Temp_ExistedCustomers AS ec ON ec.UserName = u.UserName  
	SET u.IsExistedPinCategory = 1
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory AS pin WHERE pin.CTSCustID = ec.CTSCustID);
    
	/*9. Validate for Existed NAP PA (M) */
	INSERT IGNORE INTO Temp_ExistedNAPPA (UserName)
	SELECT DISTINCT u.UserName
	FROM Temp_UserNames AS u
		INNER JOIN Temp_ExistedCustomers AS ec ON ec.UserName = u.UserName  
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = ec.CTSCustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cc.CategoryID AND cat.SourceType = 'NAP' AND cat.ReasonID BETWEEN 102 AND 110;
	
	UPDATE Temp_UserNames AS u
	SET u.IsExistedNAPPA = 1
    WHERE EXISTS (SELECT 1 FROM Temp_ExistedNAPPA AS epa WHERE epa.UserName = u.UserName);
    
    /*10. Return Error Results */
    INSERT INTO Temp_ErrorResults (UserName, ErrorMsg) 
    SELECT UserName
			,	CASE 
					WHEN IsDuplicated = 1 THEN 'Duplicate Username'
					WHEN IsInvalid = 1 THEN 'Invalid Username'
                    WHEN IsSubAccount = 1 THEN 'Cannot mark for Sub Account'
                    WHEN IsSMALicensee = 1 THEN 'Cannot mark for Upline Licensee Account'
                    WHEN IsInternalAccount = 1 THEN 'Cannot mark for Internal Account: OddsFeed Site/ Downline of 8RM, BARM/ CashOut'
                    WHEN IsExistedPinCategory = 1 THEN 'Existed Pin Category'
					WHEN IsExistedNAPPA = 1 THEN 'Existed marked directly Problem Account'
				END AS ErrorMsg
	FROM Temp_UserNames
    WHERE IsDuplicated = 1 OR IsInvalid = 1 OR IsSubAccount = 1 OR IsSMALicensee = 1 OR IsInternalAccount = 1 OR IsExistedPinCategory = 1 OR IsExistedNAPPA = 1;
   
    IF EXISTS (SELECT 1 FROM Temp_ErrorResults) THEN
		SELECT UserName, ErrorMsg FROM Temp_ErrorResults;
        
        leave sp;
    END IF;
    
   /*11. Return Results for Sync to NAP CM */
   IF NOT EXISTS (SELECT 1 FROM Temp_ErrorResults) THEN       
		SELECT ReasonID INTO lv_ReasonID FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = ip_CategoryID;
                
		SELECT 		CASE WHEN ec.IsLicensee = 1 THEN 'Licensee' ELSE 'Credit' END AS Site
				,	ec.RoleID AS RoleID
				,	u.UserName AS UserName
				,	lv_ReasonID AS ReasonID
                ,	1 AS ActionID
                ,	ip_Comment AS Comment
                ,	ip_UserID AS UserID
		FROM Temp_UserNames AS u
			INNER JOIN Temp_ExistedCustomers AS ec ON ec.UserName = u.UserName
		ORDER BY ec.IsLicensee DESC, ec.RoleID ASC;
        
		leave sp;
   END IF;
END$$
DELIMITER ;