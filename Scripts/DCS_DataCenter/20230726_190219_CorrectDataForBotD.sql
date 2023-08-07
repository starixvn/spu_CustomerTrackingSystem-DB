/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230720@Terry.Nguyen
	Task:	 	Correct Flagged for UC Browser [Redmine ID: #190219]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230720@Terry.Nguyen: Created [Redmine ID: #190219]
			- 20230726@Terry.Nguyen: Update data from 2023-07-09 to 2023-07-17 [Redmine ID: #190219]
	Reviewer:
*/
USE DCS_DataCenter;
 
  UPDATE DCS_DataCenter.Transaction07 trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 a 
				INNER JOIN DCS_DataCenter.UserAgent b ON a.UserAgentKey = b.UserAgentKey
	WHERE a.CreatedDate > '2023-07-08' 
			AND a.CreatedDate <= '2023-07-17' 
			AND b.BrowserID = 9 
			AND a.BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null;
  		
		
 UPDATE DCS_DataCenter.Transaction07 trans
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null 
WHERE 	trans.CreatedDate > '2023-07-08' 
		AND trans.CreatedDate <= '2023-07-17' 
		AND trans.Flagged = 27 
		AND trans.BotDetectionValue = 262144;	
