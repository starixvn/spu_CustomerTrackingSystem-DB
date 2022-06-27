/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
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
            
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Get();
	 */ 	
     
     SELECT DISTINCT mm.MatchID
     FROM CTS_DataCenter.MatchMonitor AS mm
     WHERE mm.SportType = 1 AND mm.ClassifyStatus = 0;
    
END$$
DELIMITER ;