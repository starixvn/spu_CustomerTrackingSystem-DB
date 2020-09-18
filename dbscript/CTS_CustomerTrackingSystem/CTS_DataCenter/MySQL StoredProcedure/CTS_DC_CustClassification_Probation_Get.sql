USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_Get`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_Get`(
	IN ip_Username				VARCHAR(50),
	IN ip_DaysLeft				SMALLINT,
	IN ip_CategoryMode			TINYINT
)
BEGIN
	/*
		Created:	20200918@Lex.Khuat
		Task :		Implement Probation Monitor page
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200918@Lex.Khuat [Redmine ID: #141755]: Created
            
		Param's Explanation:
			Sample: call CTS_DataCenter.CTS_DC_CustClassification_Probation_Get('', -1, 1);
            - ip_Username: null or '' to skip filter
            - ip_DaysLeft: null or negative number to skip filter
            - ip_CategoryMode: 1 for General Category, 2 for Detailed Category
	*/ 
    DECLARE lv_CurrentDate		DATE DEFAULT CURRENT_DATE();
    DECLARE	lv_CTSCustID		BIGINT UNSIGNED DEFAULT 0;

	#============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_ProbationCustomer;
    #============================================

    CREATE TEMPORARY TABLE Temp_ProbationCustomer (
		CTSCustID			BIGINT UNSIGNED
	, 	CustID				INT UNSIGNED
	,	SubscriberID		INT	UNSIGNED
    ,	Username			VARCHAR(50)
    ,	Site				VARCHAR(50)
    ,	SportGroupID		SMALLINT
    ,	SportGroupName		VARCHAR(50)
    ,	TargetCategoryID	SMALLINT
    ,	TargetCategoryName	VARCHAR(50)
    ,	CreatedDate			DATETIME
    ,	CreatedTime			DATETIME
    ,	FirstMargin			DECIMAL(20, 4)
    ,	DaysLeft			SMALLINT
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    #========= IF SEARCH FOR SPECIFIC CUSTOMER, GET CTSCUSTID FROM KEYWORD =========
    IF IFNULL(ip_Username, '') <> '' THEN
		SELECT	CTSCustID
        INTO lv_CTSCustID
        FROM CTS_DataCenter.CTSCustomer
        WHERE UserName = ip_Username
        LIMIT 1;
    END IF;
    
    #========= GET DATA BY FILTERS =========
    INSERT INTO Temp_ProbationCustomer(CTSCustID, CustID, SportGroupID, TargetCategoryID, TargetCategoryName, FirstMargin, CreatedDate, CreatedTime, DaysLeft)
    SELECT	pam.CTSCustID
			, pam.CustID
            , pam.SportGroupID
            , pam.TargetCategoryID
            , cc.CategoryName
            , pam.FirstMargin
            , pam.CreatedDate
            , pam.CreatedTime
            , 60 - DATEDIFF(lv_CurrentDate, pam.CreatedDate)
    FROM CTS_DataCenter.ProbationAccountMonitor AS pam
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc
		ON pam.TargetCategoryID = cc.CategoryID
    WHERE (lv_CTSCustID = 0 OR lv_CTSCustID = pam.CTSCustID)
		AND (IFNULL(ip_DaysLeft, -1) < 0 OR 60 - DATEDIFF(lv_CurrentDate, pam.CreatedDate) = ip_DaysLeft)
        AND	CASE 	WHEN IFNULL(ip_CategoryMode, -1) = 1 THEN 200	# General catergory
					WHEN IFNULL(ip_CategoryMode, -1) = 2 THEN 1		# Detailed category
					ELSE -1
			END = cc.ParentID;
    
    #========= UPDATE MISC INFOR =========
    UPDATE Temp_ProbationCustomer AS tmp
    INNER JOIN CTS_DataCenter.CTSCustomer AS c
		ON tmp.CTSCustID = c.CTSCustID
	LEFT JOIN CTS_DataCenter.SportGroup AS sg
		ON tmp.SportGroupID = sg.SportGroupID
	SET tmp.SubscriberID = c.SubscriberID
		, tmp.Username = c.UserName
        , tmp.Site = c.Site
        , tmp.SportGroupName = sg.SportGroupName
        , tmp.DaysLeft =	CASE	WHEN tmp.DaysLeft < 0 THEN 0
									ELSE tmp.DaysLeft
							END;
    
    #========= RETURN DATA =========
    SELECT	CustID
			, Username
			, Site
            , SportGroupName AS Sport
            , TargetCategoryName AS TargetCategory
            , CreatedTime AS TaggedDate
            , FirstMargin
            , null AS CurrentMargin
            , DaysLeft
    FROM Temp_ProbationCustomer
    ORDER BY DaysLeft DESC;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;

