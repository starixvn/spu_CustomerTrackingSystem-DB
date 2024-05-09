/*
	Creator:	20240507@Victoria.Le
	Task:		Update data - CC2300 - Missing fraud tickets 
	Server:		bodb_VR2Model
	
	Revisions:
			- 20240507@Victoria.Le:  Initial Writing [Redmine ID: #204731]	
*/

USE	bodb_VR2Model;
GO

UPDATE dbo.CustomerClassification_ScannedNewCust WITH(UPDLOCK, ROWLOCK) 
SET GBTicketCount = 3
, 	SportType = 2
,	JobScannedType = 2 
WHERE CustId = 119470176;