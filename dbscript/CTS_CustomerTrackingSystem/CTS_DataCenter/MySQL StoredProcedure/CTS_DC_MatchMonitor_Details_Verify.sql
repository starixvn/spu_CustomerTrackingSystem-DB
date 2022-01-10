/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_Verify`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_Verify`(
		IN ip_MatchID 		BIGINT UNSIGNED   
    ,	IN ip_LiveIndicator	BOOLEAN      
    ,	IN ip_BettypeID		INT UNSIGNED
    ,	IN ip_BetID			BIGINT
    ,	IN ip_ListTransID	LONGTEXT
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
        -	20220110@Casey.Huynh: Enhance MM, Add BetID [Redmine ID: 166986]
	
	Param's Explanation (filtered by):	

	Example: CALL CTS_DC_MatchMonitor_Details_Verify(1,0,1,'1,2,4,5',8);
			CALL CTS_DC_MatchMonitor_Details_Verify(1,0,2,'11,12,14,15',9);
	*/ 
	
    INSERT INTO CTS_DataCenter.MatchMonitorDetailsVerifiedTrans(MatchID, LiveIndicator, BettypeID, BetID, ListTransID, VerifiedBy, VerifiedDate)
    VALUES (ip_MatchID, ip_LiveIndicator, ip_BettypeID, ip_BetID, ip_ListTransID, ip_VerifiedBy, CURRENT_TIME());	   
	
END$$
DELIMITER ;