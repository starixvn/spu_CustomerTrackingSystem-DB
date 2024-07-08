/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_GetCategories`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_GetCategories`(
	IN ip_IsFromPAM BOOLEAN
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220307@Irena.Vo
		Task:		Get Category Filter for ProblemAccount Management page
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220307@Irena.Vo: Created [Redmine ID: #159014]
			- 20220407@Irena.Vo: Change logic get [Redmine ID: #170135]
            - 20220519@Casey.Huynh: Renovate PA Process [Redmine ID: #172061]
			- 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]            
			- 20220830@Long.Luu: update to show for System Detect Group Betting [Redmine ID: #176976]
            - 20230515@Casey.Huynh: New Category for Robot OCRD [Redmine ID: #186991]
			- 20240103@Thomas.Nguyen: New Category for System Detect Unauthorized Login [RedmineID: #197710]
            - 20240626@Thomas.Nguyen: Renovate CC phase 2 - Remove hardcode CategoryID [Redmine ID: #205317]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_ProblemAccountManagement_GetCategories();
	*/
	DECLARE CONST_CATEID_INFOBET				INT;
	DECLARE CONST_CATEID_GROUPBETTING			INT;
	DECLARE CONST_CATEID_HEDGING				INT;
	DECLARE CONST_CATEID_ARBITRAGE				INT;
	DECLARE CONST_CATEID_FIXEDGAME				INT;
	DECLARE CONST_CATEID_IRRIGATION				INT;
	DECLARE CONST_CATEID_FORMULABET				INT;
	DECLARE CONST_CATEID_SYSTEMDETECTGB			INT;
	DECLARE CONST_CATEID_UNAUTHORIZEDLOGIN		INT;
	DECLARE CONST_CATEID_ROBOTUSER				INT;
	DECLARE CONST_CATEID_ROBOTOCRD				INT;

	SET CONST_CATEID_INFOBET 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INFOBET');
	SET CONST_CATEID_GROUPBETTING 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_GROUPBETTING');
	SET CONST_CATEID_HEDGING 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_HEDGING');
	SET CONST_CATEID_ARBITRAGE 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ARBITRAGE');
	SET CONST_CATEID_FIXEDGAME 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_FIXEDGAME');
	SET CONST_CATEID_IRRIGATION 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_IRRIGATION');
	SET CONST_CATEID_FORMULABET 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_FORMULABET');
	SET CONST_CATEID_SYSTEMDETECTGB 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SYSTEMDETECTGB');
	SET CONST_CATEID_UNAUTHORIZEDLOGIN 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGIN');
	SET CONST_CATEID_ROBOTUSER					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSER');
	SET CONST_CATEID_ROBOTOCRD					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRD');

	IF ip_IsFromPAM = 1 THEN
		SELECT 	DISTINCT 
				cat.CategoryName
			, 	cat.CategoryGroupID
			, 	cat.RelevantCategoryID AS RelevantCategoryGroup
			, 	cat.CategoryGroupID AS CategoryID
			,	cat.CategoryPriority AS Priority
		FROM CTS_DataCenter.CustomerCategory AS cat
		WHERE	cat.CategoryID IN (CONST_CATEID_INFOBET, CONST_CATEID_GROUPBETTING, CONST_CATEID_HEDGING, CONST_CATEID_ARBITRAGE, CONST_CATEID_FIXEDGAME, CONST_CATEID_IRRIGATION
									, CONST_CATEID_FORMULABET, CONST_CATEID_ROBOTUSER)
				AND cat.IsActive = 1
		ORDER BY cat.CategoryPriority;
	ELSE
		SELECT 	DISTINCT 
				cat.CategoryName
			, 	cat.CategoryGroupID
			, 	cat.RelevantCategoryID AS RelevantCategoryGroup
			, 	cat.CategoryGroupID AS CategoryID
			,	cat.CategoryPriority AS Priority
			,	CASE WHEN cat.CategoryID IN (CONST_CATEID_SYSTEMDETECTGB, CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_ROBOTOCRD) THEN 1 ELSE 0 END AS IsDisabled
		FROM CTS_DataCenter.CustomerCategory AS cat
		WHERE 	cat.CategoryID IN (CONST_CATEID_INFOBET, CONST_CATEID_GROUPBETTING, CONST_CATEID_HEDGING, CONST_CATEID_ARBITRAGE, CONST_CATEID_FIXEDGAME, CONST_CATEID_IRRIGATION
									, CONST_CATEID_FORMULABET, CONST_CATEID_SYSTEMDETECTGB, CONST_CATEID_UNAUTHORIZEDLOGIN, CONST_CATEID_ROBOTUSER, CONST_CATEID_ROBOTOCRD)
				AND cat.IsActive = 1
		ORDER BY cat.CategoryPriority;
	END IF;

END$$
DELIMITER ;

