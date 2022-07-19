/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220719@Casey.Huynh
    Task:	 	Missing Transaction Due to wrong Subscriber Prefix [Redmine ID: #174973]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

UPDATE DCS_DataCenter.Account AS a 
SET 	a.IsCTSTransformed = 0
WHERE	a.SubscriberID = 5732996
	AND a.IsCTSTransformed = -1;
