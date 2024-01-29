/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240129@Jonathan.Doan
	Task:	 	Truncate data [Redmine ID: #200335]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20240129@Jonathan.Doan: Truncate data [Redmine ID: #200335]
	Reviewer:
*/
USE DCS_DataCenter;

UPDATE Transaction07
SET FPDeviceID = NULL,
	RecoverType = NULL,
	RawFingerPrintID = NULL,
	CookieID = NULL,
	BrowserInstanceID = NULL,
	RawUserAgentID = NULL
WHERE CreatedDate > '2024-01-24'
	AND FPDeviceID > 0;

TRUNCATE TABLE FPDevice;
TRUNCATE TABLE FPDeviceFingerPrint;
TRUNCATE TABLE DeviceCookie;
TRUNCATE TABLE AccountFingerprint;
TRUNCATE TABLE EvolvedTransaction;
TRUNCATE TABLE AssociationMapping;

SELECT 	AssociationID
	,	AccountID
	,	DeviceID
INTO @associationID, @accountID, @deviceID
FROM Association
WHERE CreatedDate = '2024-01-25'
ORDER BY AssociationID ASC
LIMIT 1;

SELECT AssociationID
INTO @associationNewID
FROM AssociationNew
WHERE AccountID = @accountID
	AND DeviceID = @deviceID
LIMIT 1;

DELETE FROM AssociationNew
WHERE AssociationID >= @associationNewID;

INSERT INTO AssociationNew(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime, IsCTSTransformed)
SELECT	AccountID
    ,	DeviceID
    ,	SubscriberID
    ,	CreatedTime
    ,	CreatedDate
    ,	InsertTime AS InsertedTime
    ,	IsCTSTransformed
FROM Association
WHERE AccountID = @accountID
	AND DeviceID = @deviceID;
