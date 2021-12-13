/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_Verify`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_Verify`(
		IN ip_MatchID 		BIGINT UNSIGNED   
    ,	IN ip_Market		BOOLEAN      
    ,	IN ip_BettypeID		INT UNSIGNED
    ,	IN ip_TransList		LONGTEXT
	,	IN ip_VerifiedBy	INT	
)
    SQL SECURITY INVOKER
BEGIN
	/*Created:	20211213@Casey.Huynh
	Task :		Match Monitor Insert trans ticket to Staging table
	DB:			CTS_DataCenter
	Original:

	Revisions:
		- 	20211213@Casey.Huynh: Created [Redmine ID: 165606]
	
	Param's Explanation (filtered by):	

	Example: CALL CTS_DC_MatchMonitor_Details_Verify(1,1,1,'1,2,4,5',8);
	*/ 
	
    INSERT INTO MatchMonitorDetailsVerifiedTrans(MatchID, Market, BettypeID, TransList, VerifiedBy, VerifiedDate)
    VALUES (ip_MatchID, ip_Market, ip_BettypeID, ip_TransList, ip_VerifiedBy, CURRENT_DATE());	   
	
END$$
DELIMITER ;