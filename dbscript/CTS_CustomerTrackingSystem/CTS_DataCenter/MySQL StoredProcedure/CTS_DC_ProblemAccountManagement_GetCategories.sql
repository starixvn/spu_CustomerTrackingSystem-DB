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
	DECLARE CONST_CATEID_ROBOTUSER 			INT;
	DECLARE CONST_CATEID_ROBOTOCRD 			INT;

	SET CONST_CATEID_ROBOTUSER 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSER');
	SET CONST_CATEID_ROBOTOCRD 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRD');

	IF ip_IsFromPAM = 1 THEN
		SELECT 	DISTINCT 
				cat.CategoryName
			, 	cat.CategoryGroup
			, 	cat.RelevantCategoryID AS RelevantCategoryGroup
			, 	cat.CategoryGroup AS CategoryID
			,	cat.CategoryPriority AS Priority
			,	CASE WHEN cat.CategoryID = CONST_CATEID_ROBOTUSER AS IsRobotUser
			,	CASE WHEN cat.CategoryID = CONST_CATEID_ROBOTOCRD AS IsRobotOCRD
		FROM CTS_DataCenter.CustomerCategory AS cat
		WHERE 	(cat.CategoryID BETWEEN 52 AND 64 OR cat.CategoryID IN (163,165))
			AND cat.IsActive = 1
		ORDER BY cat.CategoryPriority;
	ELSE
		SELECT 	DISTINCT 
				cat.CategoryName
			, 	cat.CategoryGroup
			, 	cat.RelevantCategoryID AS RelevantCategoryGroup
			, 	cat.CategoryGroup AS CategoryID
			,	cat.CategoryPriority AS Priority
		FROM CTS_DataCenter.CustomerCategory AS cat
		WHERE 	(cat.CategoryID BETWEEN 52 AND 64 OR cat.CategoryID IN (163,165))
			AND cat.IsActive = 1
		ORDER BY cat.CategoryPriority;
	END IF;

END$$
DELIMITER ;

