/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230720@Terry.Nguyen
	Task:	 	Correct Flagged for UC Browser [Redmine ID: #190219]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230720@Terry.Nguyen: Created [Redmine ID: #190219]
	Reviewer:
*/
USE DCS_DataCenter;
 
 #pw202324
 
 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202324) trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 PARTITION (pw202324) a 
				INNER JOIN DCS_DataCenter.UserAgent b on a.UserAgentKey = b.UserAgentKey
	WHERE BrowserID = 9 AND BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null ;
 

#pw202325

 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202325) trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 PARTITION (pw202325) a 
				INNER JOIN DCS_DataCenter.UserAgent b on a.UserAgentKey = b.UserAgentKey
	WHERE BrowserID = 9 AND BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null ;
 
 #pw202326
 
  UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202326) trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 PARTITION (pw202326) a 
				INNER JOIN DCS_DataCenter.UserAgent b on a.UserAgentKey = b.UserAgentKey
	WHERE BrowserID = 9 AND BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null ;
 
 #pw202327
 
  UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202327) trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 PARTITION (pw202327) a 
				INNER JOIN DCS_DataCenter.UserAgent b on a.UserAgentKey = b.UserAgentKey
	WHERE BrowserID = 9 AND BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null ;
 
  #pw202328
  
 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202328) trans
	INNER JOIN (SELECT a.TransID FROM DCS_DataCenter.Transaction07 PARTITION (pw202328) a 
				INNER JOIN DCS_DataCenter.UserAgent b on a.UserAgentKey = b.UserAgentKey
	WHERE BrowserID = 9 AND BotDetectionValue = 264) tmp ON trans.TransID = tmp.TransID
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null ;