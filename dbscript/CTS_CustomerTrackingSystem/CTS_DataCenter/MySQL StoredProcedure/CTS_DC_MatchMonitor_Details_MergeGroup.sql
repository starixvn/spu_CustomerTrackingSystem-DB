/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_MergeGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_MergeGroup`(
		IN ip_TransList		JSON       
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230105@Casey.Huynh
		Task :		CTS_DC_MatchMonitor_Details_MergeReasonGroup
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230222@Casey.Huynh: Created [Redmine ID: 181995]
    
            
		Param's Explanation (filtered by):
		
		Example:
			CALL CTS_DC_MatchMonitor_Details_MergeReasonGroup(@ip_TransList:='[
					{"TransID":87310633518759936,"Reason":0,"GroupID":4,"Betteam":"a","CustID":1267}
				,	{"TransID":87310689353334784,"Reason":0,"GroupID":4,"Betteam":"a","CustID":1261}
				,	{"TransID":87310994296012800,"Reason":0,"GroupID":6,"Betteam":"h","CustID":1265}
				,	{"TransID":87311045835620352,"Reason":0,"GroupID":6,"Betteam":"h","CustID":1267}
				]');

	*/ 
	SELECT 	87310633518759936 AS TransID		
        ,	0 AS ScoreDiff
        ,	'0,1' AS ReasonList
        ,	1 AS MergeGroupID;
	
END$$
DELIMITER ;
