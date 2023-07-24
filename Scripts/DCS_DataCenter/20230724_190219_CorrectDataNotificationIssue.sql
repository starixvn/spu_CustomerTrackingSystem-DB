/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230720@Terry.Nguyen
	Task:	 	Correct Flagged for Notification rule [Redmine ID: #190219]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230724@Terry.Nguyen: Created [Redmine ID: #190219]
	Reviewer:
*/
USE DCS_DataCenter;
 
#pw202324
  
 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202324) trans
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null 
WHERE Flagged = 27 AND BotDetectionValue = 262144;
 

#pw202325

 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202325) trans
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null 
WHERE Flagged = 27 AND BotDetectionValue = 262144;
 
#pw202326
 
 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202326) trans
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null 
WHERE Flagged = 27 AND BotDetectionValue = 262144;

#pw202327
 
 UPDATE DCS_DataCenter.Transaction07 PARTITION (pw202327) trans
 SET 	trans.Flagged = 1,
		trans.BotComponentID = null,  
		trans. BotDetectionValue = null 
WHERE Flagged = 27 AND BotDetectionValue = 262144;
