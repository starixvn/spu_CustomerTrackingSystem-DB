/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_ViewHistory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ViewHistory`(
	IN ip_CTSCustID 	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
  /*
		Created:	20201214@Irena.Vo
		Task:		View History for customer category in CTS
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210105@Irena.Vo: 		Created. Update logic SP [RedmineID: #145951]
			- 20210226@Irena.Vo: 		Get TaggingType flag for log [RedmineID: #150454]
			- 20210401@Irena.Vo: 		Update View Log [RedmineID: #152249]
			- 20210525@Irena.Vo: 		Change view log: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210610@Irena.Vo: 		Write log for Inactive Account [RedmineID: #156465] 
			- 20210722@Irena.Vo: 		Refactor SP [RedmineID: #157203] 
			- 20210727@Long.Luu: 		Return more data for TW's categories [RedmineID: #155956] 
			- 20210907@Long.Luu: 		Update Robot Users rules  [Redmine ID: #161232]
			- 20211116@Aries.Nguyen: 	Return history with CTSUser is null[Redmine ID: #156935]
			- 20220510@Irena.Vo: 		Update for return CreatedBy [Redmine ID: #171512]
			- 20220519@Aries.Nguyen: 	Renovate the Category Log History [Redmine ID: #172560]
			- 20200705@Casey.Huynh: 	Add New Category LicVIP, LicBA [Redmine ID: #174219]       
			- 20220817@Long.Luu: 		Rearrange CC's IDs [Redmine ID: #175698]
			- 20220913@Casey.Huynh: 	Update Remark [Redmine ID: #176976]
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
			- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeId [Redmine ID: #185319] 
			- 20230404@Victoria.Le		Return First5TWGBTicketCount [Redmine ID: #195060] 
			- 20240626@Thomas.Nguyen:	Renovate CC phase 2 - Get remark from template [Redmine ID: #205317]
			
		Param's Explanation (filtered by):		
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_ViewHistory_UAT4(25);
	*/  
	/* 
		DECLARE CONST_LICBA_CATEGORYID				SMALLINT UNSIGNED DEFAULT 2;
        DECLARE CONST_LICVIPPROBLEM_CATEGORYID		SMALLINT UNSIGNED DEFAULT 3;
		DECLARE CONST_LICVIPNORMAL_CATEGORYID		SMALLINT UNSIGNED DEFAULT 4;        
      */  
		DECLARE CONST_CATEID_LICBA 						INT;
    	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 			INT;
    	DECLARE CONST_CATEID_LICVIPDANGEROUS 			INT;
		DECLARE	CONST_CATEID_UNAUTHORIZEDLOGIN 			INT;
		DECLARE	CONST_CATEID_UNAUTHORIZEDLOGINLOSING	INT;
		DECLARE	CONST_CATEID_EARLYWARNINGMEMBERS 		INT;
		DECLARE	CONST_CATEID_EARLYWARNINGMEMBERSLOSING	INT;
		DECLARE	CONST_CATEID_INITIALGB		 			INT;
		DECLARE	CONST_CATEID_INITIALGBLOSING			INT;
		DECLARE	CONST_CATEID_INITIALSMART		 		INT;
		DECLARE	CONST_CATEID_INITIALSMARTLOSING			INT;

        DECLARE lv_LicBA_CategoryName				VARCHAR(50);
		DECLARE lv_LicBA_CC							SMALLINT UNSIGNED;
		DECLARE lv_LicVIPProblem_CC					SMALLINT UNSIGNED;
		DECLARE lv_LicVIPNormal_CC					SMALLINT UNSIGNED;
        DECLARE lv_LicVIPProblem_CategoryName		VARCHAR(50);
        DECLARE lv_LicVIPNormal_CategoryName		VARCHAR(50);        
        
		SET CONST_CATEID_LICBA 		                    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
    	SET CONST_CATEID_LICVIPSUSPICIOUS 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
    	SET CONST_CATEID_LICVIPDANGEROUS 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
		SET CONST_CATEID_UNAUTHORIZEDLOGIN 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGIN');
		SET CONST_CATEID_UNAUTHORIZEDLOGINLOSING 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGINLOSING');
		SET CONST_CATEID_EARLYWARNINGMEMBERS 		    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNINGMEMBERS');
		SET CONST_CATEID_EARLYWARNINGMEMBERSLOSING 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNINGMEMBERSLOSING');
		SET CONST_CATEID_INITIALGB 		                = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGB');
		SET CONST_CATEID_INITIALGBLOSING 		        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGBLOSING');
		SET CONST_CATEID_INITIALSMART 		            = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');
		SET CONST_CATEID_INITIALSMARTLOSING 		    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMARTLOSING');

        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicVIPProblem_CategoryName, lv_LicVIPProblem_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_CATEID_LICVIPDANGEROUS;
        
        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicVIPNormal_CategoryName, lv_LicVIPNormal_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;        
        
        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicBA_CategoryName, lv_LicBA_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_CATEID_LICBA;  
        
		DROP TEMPORARY TABLE IF EXISTS Temp_CustRemark;
		CREATE TEMPORARY TABLE 	Temp_CustRemark (
					HistoryID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
				,	CustID				BIGINT UNSIGNED
				,	CategoryID			INT
				,	Remark				TEXT
				,	KEY IX_Temp_CustRemark_CustID_CateID(CustID, CategoryID)	
		);

		INSERT IGNORE INTO Temp_CustRemark(HistoryID, CustID, CategoryID, Remark)
        SELECT  clss.ID
			,	clss.CustID
            ,   clss.CategoryID
            ,   cr.RemarkTemplate
        FROM CTS_DataCenter.CTSCustomerClassification_History AS clss
            INNER JOIN CTS_DataCenter.CustomerClassification_Remark AS cr ON cr.RemarkID = clss.SourceTypeID
		WHERE 	clss.CTSCustID = ip_CTSCustID AND clss.IsDataChanged = 1 AND clss.SourceTypeID IS NOT NULL;
	/*
	Detect SourceTypeID for historical data 
	*/

		IF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_UNAUTHORIZEDLOGINLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN CTS_DataCenter.CustomerLoginInfoDetection AS cld ON cld.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tmp.Remark,'[FBDate]', DATE_FORMAT(cld.FirstBetDate, '%b %d, %Y'))
								,'[DetectedDate]', DATE_FORMAT(cld.DetectionDate, '%b %d, %Y')), '[Bot]', cld.Bot),'[BotPCT]',cld.BotTransPercentage),'[InvalidBrowser]'
                                ,cld.InvalidBrowser),'[InvalidBrowserPCT]',cld.InvalidBrowserInfoTransPercentage)
            WHERE tmp.CategoryID IN (CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_UNAUTHORIZEDLOGINLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_EARLYWARNINGMEMBERS, CONST_CATEID_EARLYWARNINGMEMBERSLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN CTS_DataCenter.Customer_DangerousScore AS cds ON cds.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cds.ClassifiedDate, '%b %d, %Y')), '[DangerousScore]', CAST(cds.ClassifiedScore*100 AS DECIMAL(5,2)))
            WHERE tmp.CategoryID IN (CONST_CATEID_EARLYWARNINGMEMBERS, CONST_CATEID_EARLYWARNINGMEMBERSLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_INITIALSMART, CONST_CATEID_INITIALSMARTLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN CTS_DataCenter.Customer_InitialSmart AS cis ON cis.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cis.SourceCreatedDate, '%b %d, %Y')), '[Probability]', cis.Probability)
            WHERE tmp.CategoryID IN (CONST_CATEID_INITIALSMART, CONST_CATEID_INITIALSMARTLOSING);

        ELSEIF EXISTS (SELECT 1 FROM Temp_CustRemark WHERE CategoryID IN (CONST_CATEID_INITIALGB, CONST_CATEID_INITIALGBLOSING)) THEN
            UPDATE Temp_CustRemark AS tmp
                INNER JOIN CTS_DataCenter.Customer_InitialGroupBetting AS cgb ON cgb.CustID = tmp.CustID
            SET tmp.Remark = REPLACE(REPLACE(REPLACE(tmp.Remark,'[DetectedDate]', DATE_FORMAT(cgb.SourceCreatedDate, '%b %d, %Y')), '[GBTicketCount]', cgb.GBTicketCount), '[Sport]', cgb.SportType)
            WHERE tmp.CategoryID IN (CONST_CATEID_INITIALGB, CONST_CATEID_INITIALGBLOSING);
        END IF;

		SELECT  temp.ID
			,	temp.LastModifiedDate AS CreatedTime
			,   (CASE WHEN temp.CategoryID IS NULL THEN '-' ELSE cc1.CategoryName END) AS CategoryName
			,   (CASE WHEN temp.TargetCC IN (-1, -99) THEN '-' /* -1: Remove, -99: No mapping CC */ ELSE temp.TargetCC END) AS CustomerClass
			,	temp.CategoryID
			,    s.ItemNameDisplay AS SourceTypeName
			, 	s.ItemID AS SourceTypeID
			,   temp.TurnOverRM AS TurnOver
			,   temp.WinlossRM AS WinLoss
			,	(CASE WHEN temp.TurnOverRM = 0 THEN 0 ELSE (temp.WinlossRM/ temp.TurnOverRM) * 100 END) AS Margin
			,   temp.BetCount
			,   temp.ActiveDays 
			,   temp.RobotCounter
			,   IFNULL(u.UserName, temp.LastModifiedBy) AS CreatedBy
            ,	temp.TWBetCount
            ,	temp.First5TWGBTicketCount
            ,	temp.TWGroupBettingRate
            ,	temp.TWTicketRejectRate
            ,	temp.TWDesktopUsageRate
			/*,	(CASE WHEN temp.Remark LIKE 'Auto MatchID: %' THEN REPLACE(temp.Remark,'Auto MatchID: ','') ELSE temp.Remark END) AS Remark*/
			,	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tmpcr.Remark, 
                        '[TVSRequestID]', temp.TVSRequestID)
                    ,   '[Winloss]', temp.WinlossRM)
                    ,   '[TVSSportType]', temp.SportType)
                    ,   '[Margin]', CASE WHEN temp.TurnOverRM = 0 THEN 0 ELSE (temp.WinlossRM/temp.TurnoverRM) * 100 END)
                    ,   '[BetCount]', temp.BetCount)
                    ,   '[TurnOver]', temp.TurnoverRM)
                    ,   '[ActiveDays]', temp.ActiveDays)
                    /*,   '[TWBetCount]', temp.TWBetCount*/
                    ,   '[TWGBRate]', temp.TWGroupBettingRate)
                    ,   '[TWDesktopUsageRate]', temp.TWDesktopUsageRate)
                    ,   '[TWTicketRejectRate]', temp.TWTicketRejectRate)
                    ,   '[TWRobotCounter]', temp.RobotCounter)
                    ,   '[MatchID]', CASE WHEN temp.Remark LIKE 'Auto MatchID: %' THEN REPLACE(temp.Remark,'Auto MatchID: ','') END)
                    ,   '[UserComment]', IFNULL(temp.Remark,'')) AS Remark
			,	temp.TVSRequestID
            ,	temp.IsFromTVS
            ,	temp.IsFromTW
            ,	temp.IsFromCTS
            ,	temp.IsFromAI
			,	temp.IsFromImperva
			,	(CASE	WHEN temp.TargetCC = lv_LicVIPProblem_CC THEN lv_LicVIPProblem_CategoryName
						WHEN temp.TargetCC = lv_LicVIPNormal_CC THEN lv_LicVIPNormal_CategoryName 
                        ELSE NULL END) AS LicVIP
            ,	(CASE	WHEN temp.TargetCC = lv_LicBA_CC THEN lv_LicBA_CategoryName ELSE NULL END) AS LicBA
			,	temp.IsParlay
			,	temp.SportType
			,	temp.IssueTypeID
		FROM 	CTS_DataCenter.CTSCustomerClassification_History_205317 AS temp
			LEFT JOIN Temp_CustRemark AS tmpcr ON tmpcr.HistoryID = temp.ID
			LEFT JOIN CTS_DataCenter.CustomerCategory_205317 AS cc1 ON temp.CategoryID = cc1.CategoryID
			LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND temp.SourceTypeID = s.ItemID
			LEFT JOIN CTS_Admin.CTSUser AS u ON temp.LastModifiedBy = u.UserID
        WHERE 	temp.CTSCustID = ip_CTSCustID AND temp.IsDataChanged = 1
		ORDER BY temp.ID DESC; 
END$$
DELIMITER ;
