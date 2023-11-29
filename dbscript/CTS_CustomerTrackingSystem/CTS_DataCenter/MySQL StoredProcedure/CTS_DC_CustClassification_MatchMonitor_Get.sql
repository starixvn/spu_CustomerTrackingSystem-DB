/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_MatchMonitor_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MatchMonitor_Get`(
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220627@Casey.Huynh	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20220627@Casey.Huynh [Redmine ID: #174218]: Created 
            - 20231120@Thomas.Nguyen [Redmine ID: #188553]: Add the condition SportType = 2 and KickOffTime < 60mins

		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Get();
	 */ 	
     DECLARE lv_Sub90minute DATETIME;
     DECLARE lv_Sub60minute DATETIME;

     SET lv_Sub90minute = TIMESTAMPADD(MINUTE,-90, NOW());
     SET lv_Sub60minute = TIMESTAMPADD(MINUTE,-60, NOW());

     SELECT DISTINCT mm.MatchID
     FROM CTS_DataCenter.MatchMonitor AS mm
     WHERE	mm.ClassifyStatus = 0
		AND ((mm.SportType = 1 AND mm.KickOffTime < lv_Sub90minute)
			OR (mm.SportType = 2 AND mm.KickOffTime < lv_Sub60minute AND mm.MatchID > 9687291)) ; 
END$$
DELIMITER ;