/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240129@Jonathan.Doan
	Task:	 	Init data [Redmine ID: #200335]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20240129@Jonathan.Doan: Init data [Redmine ID: #200335]
	Reviewer:
*/
USE DCS_DataCenter;

UPDATE Transaction07
SET 	FPDeviceID 			= NULL
	,	RecoverType 		= NULL
	,	RawFingerPrintID 	= NULL
	,	CookieID 			= NULL
	,	BrowserInstanceID 	= NULL
	,	RawUserAgentID 		= NULL
WHERE CreatedDate > '2024-01-24'
	AND FPDeviceID > 0;

-- Init data Association from 2024-01-25
SET @lv_AssociationID = 226431264;
SET @lv_AccountID = 90521530;
SET @lv_DeviceID = 130807816;
SET @lv_AssociationNewID = 63523526;

DELETE FROM AssociationNew
WHERE AssociationID >= @lv_AssociationNewID;

INSERT INTO AssociationNew(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime, IsCTSTransformed)
SELECT	AccountID
    ,	DeviceID
    ,	SubscriberID
    ,	CreatedTime
    ,	CreatedDate
    ,	InsertTime AS InsertedTime
    ,	IsCTSTransformed
FROM Association
WHERE AssociationID >= @lv_AssociationID;
