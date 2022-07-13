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
            - 20210105@Irena.Vo: Created. Update logic SP [RedmineID: #145951]
			- 20210226@Irena.Vo: Get TaggingType flag for log [RedmineID: #150454]
            - 20210401@Irena.Vo: Update View Log [RedmineID: #152249]
            - 20210525@Irena.Vo: Change view log: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210610@Irena.Vo: Write log for Inactive Account [RedmineID: #156465] 
            - 20210722@Irena.Vo: Refactor SP [RedmineID: #157203] 
            - 20210727@Long.Luu: Return more data for TW's categories [RedmineID: #155956] 
			- 20210907@Long.Luu: Update Robot Users rules  [Redmine ID: #161232]
			- 20211116@Aries.Nguyen: Return history with CTSUser is null[Redmine ID: #156935]
            - 20220510@Irena.Vo: Update for return CreatedBy [Redmine ID: #171512]
			- 20220519@Aries.Nguyen: Renovate the Category Log History [Redmine ID: #172560]
            - 20200705@Casey.Huynh: Add New Category LicVIP, LicBA [Redmine ID: #174219]
		Param's Explanation (filtered by):		
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_ViewHistory(43600889);
	*/   
		DECLARE CONST_CATEGORY_NEWMEMBER 				INT DEFAULT 201;
		DECLARE	CONST_CATEGORY_NORMALMEMBER 			INT DEFAULT 202;
		DECLARE CONST_CATEGORY_SMART 					INT DEFAULT 203;
		DECLARE CONST_CATEGORY_HIGHRISK 				INT DEFAULT 204;
		DECLARE CONST_CATEGORY_VIP 						INT DEFAULT 205;
		DECLARE CONST_CATEGORY_PROBATION				INT DEFAULT 206;
		DECLARE CONST_CATEGORY_INACTIVE					INT DEFAULT 1000;
        DECLARE lv_LicVIPProblem_CategoryID				SMALLINT UNSIGNED DEFAULT 3;
        DECLARE lv_LicVIPNormal_CategoryID				SMALLINT UNSIGNED DEFAULT 4;
        DECLARE lv_LicVIPProblem_CategoryName			VARCHAR(50);
        DECLARE lv_LicVIPNormal_CategoryName			VARCHAR(50);
        DECLARE lv_LicBA_CategoryID						SMALLINT UNSIGNED DEFAULT 2;
        DECLARE lv_LicBA_CategoryName					VARCHAR(50);
        
        SELECT cat.CategoryName
        INTO lv_LicVIPProblem_CategoryName
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = lv_LicVIPProblem_CategoryID;
        
        SELECT cat.CategoryName
        INTO lv_LicVIPNormal_CategoryName
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = lv_LicVIPNormal_CategoryID;        
        
        SELECT cat.CategoryName
        INTO lv_LicBA_CategoryName
        FROM CTS_DataCenter.CustomerCategory AS cat
        WHERE cat.CategoryID = lv_LicBA_CategoryID;  
        
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
			,	temp.Remark
			,	temp.TVSRequestID
            ,	temp.IsFromTVS
            ,	temp.IsFromTW
            ,	temp.IsFromCTS
            ,	temp.IsFromAI
			,	(CASE	WHEN temp.TargetCC = 99 THEN lv_LicVIPProblem_CategoryName
						WHEN temp.TargetCC = 100 THEN lv_LicVIPNormal_CategoryName 
                        ELSE NULL END) AS LicVIP
            ,	(CASE	WHEN temp.TargetCC = 14 THEN lv_LicBA_CategoryName ELSE NULL END) AS LicBA
		FROM 	CTS_DataCenter.CTSCustomerClassification_History AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cc1 ON temp.CategoryID = cc1.CategoryID
			LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND temp.SourceTypeID = s.ItemID
			LEFT JOIN CTS_Admin.CTSUser AS u ON temp.LastModifiedBy = u.UserID
        WHERE 	temp.CTSCustID = ip_CTSCustID AND temp.IsDataChanged = 1
		ORDER BY temp.ID DESC; 
END$$
DELIMITER ;