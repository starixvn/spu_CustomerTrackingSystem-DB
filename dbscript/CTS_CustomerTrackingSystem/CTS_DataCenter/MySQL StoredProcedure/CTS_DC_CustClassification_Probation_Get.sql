/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_Get`(IN ip_Username varchar(50), IN ip_FromDaysLeft smallint, IN ip_ToDaysLeft smallint, IN ip_SubscriberID int, IN ip_StatusIDs varchar(500))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200918@Lex.Khuat
		Task :		Implement Probation Monitor page
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200918@Lex.Khuat [Redmine ID: #141755]: Created
            - 20201006@Lex.Khuat [Redmine ID: #142546]: Enhance Probation Management
            - 20201010@Long.Luu [Redmine ID: #142546]: Tune the performance
            - 20201118@Lex.Khuat [Redmine ID: #145028]: Update probation rule to 20 days left
            - 20201208@Lex.Khuat [Redmine ID: #145950]: Remove isAssPA from result set
            
		Param's Explanation:
			Sample: call call CTS_DataCenter.CTS_DC_CustClassification_Probation_Get('', -1, -1, 130, '1,2,3,4,5,6,7,8,9,10');
            - ip_Username: null or '' to skip filter
            - ip_FromDaysLeft: null or negative number to skip filter
            - ip_ToDaysLeft: null or negative number to skip filter
            - ip_SubscriberID: null or number
            - ip_StatusIDs: null or '' to skip filter
	*/ 
    
	DECLARE	lv_CustID			BIGINT UNSIGNED		DEFAULT 0;
    DECLARE lv_DayLefts			SMALLINT 			DEFAULT 20; 
    DECLARE lv_CurrentDate		DATE 				DEFAULT CURRENT_DATE();
    DECLARE lv_FromDate			DATE				DEFAULT	DATE_ADD(lv_CurrentDate, INTERVAL IFNULL(ip_FromDaysLeft, 0) - lv_DayLefts DAY);
    DECLARE lv_ToDate			DATE				DEFAULT	DATE_ADD(lv_CurrentDate, INTERVAL IFNULL(ip_ToDaysLeft, 0) - lv_DayLefts DAY);

    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerStatus;
    CREATE TEMPORARY TABLE Temp_CustomerStatus (
			CustStatusID		TINYINT
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccounts;
    CREATE TEMPORARY TABLE Temp_AssociatedAccounts (
			RootCTSCustID		BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED
        ,	INDEX				IX_Temp_AssociatedAccounts_CTSCustID (CTSCustID)
        ,	INDEX				IX_Temp_AssociatedAccounts_RootCTSCustID (RootCTSCustID)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_ProbationAccounts;
    CREATE TEMPORARY TABLE Temp_ProbationAccounts (
    		CTSCustID			BIGINT UNSIGNED
    	, 	CustID				INT UNSIGNED
    	,	SubscriberID		INT	UNSIGNED
        ,	Username			VARCHAR(50)
        ,	CustStatusID		TINYINT
        ,	Site				VARCHAR(50)
        ,	SportGroupID		SMALLINT
        ,	SportGroupName		VARCHAR(50)
        ,	CreatedDate			DATETIME
        ,	CreatedTime			DATETIME
        ,	FirstMargin			DECIMAL(20, 4)
        ,	DaysLeft			SMALLINT
        ,	PRIMARY KEY			PK_Temp_ProbationAccounts_CustID_SportGroupID (CustID, SportGroupID)
        ,	INDEX				IX_Temp_ProbationAccounts_CTSCustID (CTSCustID)
	);
	
    #========= IF SEARCH FOR SPECIFIC CUSTOMER, GET CTSCUSTID FROM KEYWORD =========
    IF IFNULL(ip_Username, '') <> '' THEN
		SELECT	DISTINCT CustID
        INTO lv_CustID
        FROM CTS_DataCenter.CTSCustomer
        WHERE UserName = ip_Username
        LIMIT 1;
    END IF;
    
    #========= FILTER CUSTOMER STATUS =========
    IF IFNULL(ip_StatusIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO Temp_CustomerStatus (CustStatusID) VALUES ('", REPLACE(ip_StatusIDs, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;

    #========= GET DATA BY FILTERS =========
    INSERT IGNORE INTO Temp_ProbationAccounts(CustID, CTSCustID, SubscriberID, Username, CustStatusID, Site, SportGroupID, FirstMargin, CreatedDate, CreatedTime, DaysLeft)
    SELECT	DISTINCT
			pam.CustID
		,	cust.CTSCustID
		,	cust.SubscriberID
		,	cust.Username
        ,	cust.CustStatusID
		,	cust.Site
		,	pam.SportGroupID
		,	pam.FirstMargin
		,	pam.CreatedDate
		,	pam.CreatedTime
		,	lv_DayLefts - DATEDIFF(lv_CurrentDate, pam.CreatedDate)
    FROM CTS_DataCenter.ProbationAccountMonitor AS pam
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust
		ON pam.CustID = cust.CustID
	INNER JOIN Temp_CustomerStatus AS st
		ON cust.CustStatusID = st.CustStatusID
    WHERE (lv_CustID = 0 OR lv_CustID = pam.CustID)
		AND pam.SportGroupID = 200
		AND cust.SubscriberID = IFNULL(ip_SubscriberID, 0)
		AND (IFNULL(ip_FromDaysLeft, -1) < 0 OR pam.CreatedDate >= lv_FromDate)
        AND (IFNULL(ip_ToDaysLeft, -1) < 0 OR pam.CreatedDate <= lv_ToDate);
    
	#========= RETURN DATA =========
	SELECT	tmp.CustID
		,	tmp.CTSCustID
		,	tmp.Username
		,	tmp.Site
        ,	st.ItemNameDisplay AS Status
		,	tmp.SportGroupID
		,	tmp.SportGroupName AS Sport
		,	tmp.CreatedTime AS TaggedDate
		,	tmp.FirstMargin
		,	NULL AS CurrentMargin
		,	CASE	WHEN tmp.DaysLeft < 0 THEN 0
					ELSE tmp.DaysLeft
			END AS DaysLeft
	FROM Temp_ProbationAccounts AS tmp
    LEFT JOIN CTS_DataCenter.StaticList AS st
		ON	st.ListID = 1 AND tmp.CustStatusID = st.ItemID
	ORDER BY CASE	WHEN tmp.DaysLeft < 0 THEN 0
					ELSE tmp.DaysLeft
			END DESC;

END$$

DELIMITER ;

