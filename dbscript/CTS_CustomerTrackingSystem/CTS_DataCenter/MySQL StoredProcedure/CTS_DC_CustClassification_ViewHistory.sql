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
			
			
		Param's Explanation (filtered by):		
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_ViewHistory(43600889);
	*/   
		DECLARE CONST_LICBA_CATEGORYID				SMALLINT UNSIGNED DEFAULT 2;
        DECLARE CONST_LICVIPPROBLEM_CATEGORYID		SMALLINT UNSIGNED DEFAULT 3;
		DECLARE CONST_LICVIPNORMAL_CATEGORYID		SMALLINT UNSIGNED DEFAULT 4;        
        
        DECLARE lv_LicBA_CategoryName				VARCHAR(50);
		DECLARE lv_LicBA_CC							SMALLINT UNSIGNED;
		DECLARE lv_LicVIPProblem_CC					SMALLINT UNSIGNED;
		DECLARE lv_LicVIPNormal_CC					SMALLINT UNSIGNED;
        DECLARE lv_LicVIPProblem_CategoryName		VARCHAR(50);
        DECLARE lv_LicVIPNormal_CategoryName		VARCHAR(50);        
        
        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicVIPProblem_CategoryName, lv_LicVIPProblem_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_LICVIPPROBLEM_CATEGORYID;
        
        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicVIPNormal_CategoryName, lv_LicVIPNormal_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_LICVIPNORMAL_CATEGORYID;        
        
        SELECT cat.CategoryName, cat.CustomerClass
        INTO lv_LicBA_CategoryName, lv_LicBA_CC
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = CONST_LICBA_CATEGORYID;  
        
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
            ,	temp.TWGroupBettingRate
            ,	temp.TWTicketRejectRate
            ,	temp.TWDesktopUsageRate
			,	(CASE WHEN temp.Remark LIKE 'Auto MatchID: %' THEN REPLACE(temp.Remark,'Auto MatchID: ','') ELSE temp.Remark END) AS Remark
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
		FROM 	CTS_DataCenter.CTSCustomerClassification_History AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cc1 ON temp.CategoryID = cc1.CategoryID
			LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND temp.SourceTypeID = s.ItemID
			LEFT JOIN CTS_Admin.CTSUser AS u ON temp.LastModifiedBy = u.UserID
        WHERE 	temp.CTSCustID = ip_CTSCustID AND temp.IsDataChanged = 1
		ORDER BY temp.ID DESC; 
END$$
DELIMITER ;
