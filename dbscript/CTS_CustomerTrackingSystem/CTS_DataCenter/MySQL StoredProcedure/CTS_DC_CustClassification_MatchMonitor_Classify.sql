/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_MatchMonitor_Classify`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MatchMonitor_Classify`(
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220627@Casey.Huynh	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20220627@Casey.Huynh: Created [Redmine ID: #174218]
            - 20220908@Casey.Huynh: New CC for Classify MM [Redmine ID: #176976]
            - 20220113@Casey.Huynh: Rename Table [Redmine ID: #179502]
            - 20231120@Thomas.Nguyen: Add the condition SportType = 2 and include Odds Crawler Robot (CategoryID 165, 166), Abnormal Account - Robot (CategoryID 179) [Redmine ID: #188553]
			- 20240319@Casey.Huynh: Classify Danger Score [Redmine ID: #201358]
            - 20240425@Thomas.Nguyen: Classify Initial Group Betting - Remove GroupPriority [Redmine ID: #200854]    
			- 20240530@Casey.Huynh:	Saba Group Betting (NOT Classify Saba GB Match) [Redmine ID: #191972]
			- 20240717@Jonas.Huynh:	Renovate CC [Redmine ID: #205317]
            - 20241202@Casey.Huynh: Potential Risk cannot be classified into System Detect GB [Redmine ID: #214567]
            - 20241202@Casey.Huynh: Potential Risk - Correct Data [Redmine ID: #214567]
            
		Param's Explanation:
        
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Classify();

	 */

	DECLARE	CONST_CATEID_SYSTEMDETECTGB				INT;
  	DECLARE	CONST_CATEGROUPID_SYSTEMDETECTGB		INT;
    
	DECLARE lv_PackSize INT;
	DECLARE lv_MatchID INT;

    SET CONST_CATEID_SYSTEMDETECTGB	 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SYSTEMDETECTGB');    
    SET CONST_CATEGROUPID_SYSTEMDETECTGB 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SYSTEMDETECTGB');
	
    #======================CORRECT DATA ====================
    SELECT	DISTINCT tmpCust.CustID
        ,	tmpCust.MatchID
        ,	tmpCust.CTSCustID
        ,	tmpCust.RoleID
        ,	tmpCust.SubscriberID
        ,	tmpCust.IsLicensee
        ,	CONST_CATEID_SYSTEMDETECTGB AS CategoryID # Group Betting
        , 	CONST_CATEGROUPID_SYSTEMDETECTGB AS CategoryGroup # Group Betting
	FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_CorrectData AS tmpCust;
        
    SELECT '' AS MmDetailsIDList;

    
    SELECT 0 AS MatchID;
    
END$$
DELIMITER ;