/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_Get`(
		IN ip_MatchID 			BIGINT UNSIGNED   
	,	IN ip_LiveIndicator		BOOLEAN   
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
       
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Get Match Monitor Details report
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
			-	20211213@Casey.Huynh: Enhance MM, Return more data 'Verified Trans List', Remove input Parameter ip_EventDate [Redmine ID: 165606]
            -	20220110@Casey.Huynh: Enhance MM, BetID, Reason [Redmine ID: 166986]
            -	20221027@Casey.Huynh: Update Verify By Reason and Betteam [RedmineID: 179439]
            - 	20221122@Casey.Huynh: Update TotalScore to ScoreDiff [Redmine ID: #179499]
             -	20230109@Casey.Huynh: UpdateSoreDiff [Redmine ID: #182637]
             -	20230105@Casey.Huynh: Enhance Report, Seperate CustID List and TransID List [Redmine ID: #181995]
            
		Param's Explanation (filtered by):
		
		Example:
			CALL CTS_DC_MatchMonitor_Details_Get(@ip_MatchID:=62357347,@ip_LiveIndicator:=1,@ip_BettypeID:=3,@ip_BetID:=0);

	*/   
    
	SELECT 	DISTINCT cus.CTSCustID
        ,	cus.CustID
	FROM   CTS_DataCenter.MatchMonitorDetails AS mmd
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mmd.ListCustID), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
						) js
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON js.CustID = cus.CustID
	WHERE 	mmd.BettypeID = ip_BettypeID
		AND mmd.BetID = ip_BetID
		AND mmd.MatchID = ip_MatchID
		AND mmd.LiveIndicator = ip_LiveIndicator
	ORDER BY CustID;
	
	SELECT 	js.TransID		
        ,	mmd.ScoreDiff
        ,	GROUP_CONCAT(mmd.Reason) AS ReasonList
	FROM   CTS_DataCenter.MatchMonitorDetails AS mmd
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mmd.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE 	mmd.BettypeID = ip_BettypeID
		AND mmd.BetID = ip_BetID
		AND mmd.MatchID = ip_MatchID
		AND mmd.LiveIndicator = ip_LiveIndicator
	GROUP BY js.TransID, mmd.ScoreDiff
    ORDER BY js.TransID;
    
	SELECT	js.TransID AS VerifiedTransID
	FROM CTS_DataCenter.MatchMonitorDetailsVerifiedTrans AS mdv
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mdv.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE  	mdv.MatchID = ip_MatchID
		AND mdv.LiveIndicator = ip_LiveIndicator
        AND	mdv.BettypeID = ip_BettypeID
        AND	mdv.BetID = ip_BetID;          
	
END$$
DELIMITER ;
