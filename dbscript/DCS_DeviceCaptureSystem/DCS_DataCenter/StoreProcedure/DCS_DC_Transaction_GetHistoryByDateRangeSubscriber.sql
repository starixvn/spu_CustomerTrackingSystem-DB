/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetHistoryByDateRangeSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetHistoryByDateRangeSubscriber`(
		IN	ip_SubscriberID	INT	
    ,	IN	ip_FromDate		DATETIME
    ,	IN	ip_Limit 		INT
    )
    SQL SECURITY INVOKER
proc_label: BEGIN
	/*
		Created:	20240611@Terry.Nguyen
		Task:		Get history transaction by date and subscriber [Redmine ID: 206262]
		DB:			DCS_DataCenter
		Original:

		Revisions:
		- 20240611@Terry.Nguyen: 		Initial [Redmine ID: #206262]	           
		
        Param's Explanation (filtered by):

		Example:
			CALL DCS_DC_Transaction_GetHistoryByDateRangeSubscriber(@ip_SubscriberID:=2,@ip_FromDate:='2023-01-01',@ip_Limit:=100); 			
            
	*/ 
	
    #================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Flagged;
	CREATE TEMPORARY TABLE Temp_Flagged(
			Flagged 	SMALLINT PRIMARY KEY
        ,	DisplayName VARCHAR(200)
	);
    
    INSERT INTO Temp_Flagged(Flagged, DisplayName)
    SELECT	stl.ItemID
		,	stl.ItemName
    FROM DCS_DataCenter.StaticList AS stl
    WHERE stl.ListID = 1;
	#================================================================
     
    SELECT 		tmp.TransID			AS TransID
			,	tmp.TransTime		AS TransTime			
			,	ip_SubscriberID		AS SubscriberID						
			,	tmp.LoginName		AS UserName
			,	tmp.FirstDeviceCode	AS FirstDeviceCode
			,	tmp.Action			AS Action
			,	tmp.ActionResult	AS ActionResult
			,	tmp.OS				AS OS
			,	tmp.Browser			AS Browser
			,	tmp.URLDetails		AS URLDetails
			,	tmp.IP				AS IP
            ,	tmp.DisplayName		AS RobotTracking            
		FROM	(
				SELECT 	trs.TransTime                   
					,	trs.TransID
					,	trs.LoginName                   
					,	trs.FirstDeviceCode
					,	ar.Action
					,	ar.ActionResult
					,	uag.OS
					,	uag.Browser
					,	ur.URLDetails
					,	trs.IP
                    ,	tmpFg.DisplayName                   
				FROM	DCS_DataCenter.Transaction07 trs 				
					LEFT JOIN DCS_DataCenter.UserAgent AS uag ON trs.UserAgentKey = uag.UserAgentKey
					LEFT JOIN DCS_DataCenter.ActionResult AS ar ON trs.ActionResultID = ar.ActionResultID
					LEFT JOIN DCS_DataCenter.URL AS ur ON trs.URLID = ur.URLID
                    LEFT JOIN Temp_Flagged AS tmpFg ON trs.Flagged = tmpFg.Flagged
				WHERE trs.TransTime >= ip_FromDate
					AND trs.SubscriberID = ip_SubscriberID
				) AS tmp
			ORDER BY TransTime DESC
            LIMIT ip_Limit;    
    
END$$

DELIMITER ;
