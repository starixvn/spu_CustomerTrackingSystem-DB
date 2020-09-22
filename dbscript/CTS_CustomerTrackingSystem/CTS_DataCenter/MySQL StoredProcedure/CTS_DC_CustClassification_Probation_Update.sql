USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_Update`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_Update`(
		IN ip_CustidList		JSON
	,	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
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
			- ip_CustidList: Json list with CustID, SportGroupID, NewCategoryID
            - ip_Remark: Remark to manual mark in batch
            - ip_CreatedBy: UserID to mark in batch
		Sample:
			- call CTS_DataCenter.CTS_DC_CustClassification_Probation_Update('[{"CustID": 1408, "SportGroupID": 1, "NewCategoryID": 6}, {"CustID": 1408, "SportGroupID": 200, "NewCategoryID": 202}]', '', 8, @aaaa);
	*/
    
    DECLARE lv_CurrentTime	DATETIME DEFAULT CURRENT_TIME();

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
    ,	NewCategoryID		SMALLINT
    ,	ParentID			SMALLINT
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    #========= GET DATA TO UPDATE =========
	INSERT INTO Temp_TargetCustomerCategory(CustID, SportGroupID, NewCategoryID)
	SELECT 	tmp.CustID
		, 	tmp.SportGroupID
		, 	tmp.NewCategoryID
	FROM JSON_TABLE(ip_CustidList,
		 "$[*]" COLUMNS(
			  CustID 				BIGINT UNSIGNED		PATH "$.CustID"
			, SportGroupID			SMALLINT			PATH "$.SportGroupID"
			, NewCategoryID			SMALLINT			PATH "$.NewCategoryID"
		 )) AS tmp;
    
	#========= UPDATE CUSTOMER INFO =========
    UPDATE 	Temp_TargetCustomerCategory AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust
		ON	temp.CustID = cust.CustID
	SET		temp.CTSCustID = cust.CTSCustID
		,	temp.SubscriberID = cust.SubscriberID;
    
    #========= VALIDATE SPORTGROUP =========
    UPDATE 	Temp_TargetCustomerCategory AS temp
    INNER JOIN CTS_DataCenter.CustomerCategory AS cate
		ON	temp.NewCategoryID = cate.CategoryID
	SET		temp.ParentID = cate.ParentID
		,	temp.SportGroupID =		CASE	WHEN cate.ParentID = 200 THEN 200
											ELSE temp.SportGroupID
									END;
            
	#========= EXCLUDES VVIP, SPECIAL CUSTOMER =========
    DELETE temp
    FROM Temp_TargetCustomerCategory AS temp
    INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc
		ON	temp.CTSCustID = sc.CTSCustID
        AND	sc.CreatedFromFunction IN (1, 11);
      
    #========= REMOVE OLD GENERAL/DETAIL CATEGORIES =========
    DELETE cc
    FROM CTS_DataCenter.CTSCustomerClassification AS cc
    INNER JOIN Temp_TargetCustomerCategory AS temp
		ON	temp.CustID = cc.CustID
        AND	temp.SportGroupID = cc.SportGroupID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate
		ON	cc.CategoryID = cate.CategoryID
	WHERE temp.ParentID = cate.ParentID
		AND	cate.ParentID in (1, 200);

    #========= REMOVE PROBATION MONITOR DATA =========
    DELETE pam
    FROM CTS_DataCenter.ProbationAccountMonitor AS pam
    INNER JOIN Temp_TargetCustomerCategory AS temp
		ON	temp.CustID = pam.CustID
        AND	temp.SportGroupID = pam.SportGroupID;
    
    #========= INSERT NEW CUSTOMER CATEGORIES =========
    INSERT INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , temp.NewCategoryID
            , ip_Remark
			, lv_CurrentTime
			, ip_CreatedBy
			, lv_CurrentTime
			, ip_CreatedBy
            , DATE(lv_CurrentTime)
	FROM 	Temp_TargetCustomerCategory AS temp;
            
    #========= LOG NEW CUSTOMER CATEGORIES HISTORY =========   
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, temp.NewCategoryID
            , temp.SportGroupID
            , lv_CurrentTime
            , ip_CreatedBy
            , 0
            , 0
            , 0
            , 0
			, 1
            , 0
            , DATE(lv_CurrentTime)
	FROM 	Temp_TargetCustomerCategory AS temp;
    
    #========= SENDING CUSTOMER CLASS AFTER APPLY NEW GENERAL/DETAILED CUSTOMER CATEGORIES =========
    SELECT DISTINCT CustID,
	CASE	WHEN NewCategoryID = 205 THEN 1
			WHEN NewCategoryID = 202 THEN 2
            WHEN NewCategoryID = 206 THEN 5
			WHEN NewCategoryID = 203 THEN 6
			WHEN NewCategoryID = 204 THEN 7
	END AS CustomerClass
    FROM Temp_TargetCustomerCategory
    WHERE ParentID = 200;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;

