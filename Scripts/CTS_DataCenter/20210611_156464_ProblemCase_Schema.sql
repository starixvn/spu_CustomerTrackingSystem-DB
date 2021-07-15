/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210611@Casey.Huynh
Task:	 	Schema Member Profile Check List [Redmine ID: 156464] 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
	-	[20210611@Casey.Huynh][156464]: Create
Reviewer:
*/
USE CTS_DataCenter;
ALTER TABLE AssociationByIP DROP INDEX IX_AssociationByIP_ToCustID;
ALTER TABLE AssociationByIP 
		DROP PRIMARY KEY
    , 	ADD COLUMN ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST
    , 	ADD UNIQUE KEY UX_AssociationByIP_FromCustIDToCustID(FromCustID,ToCustID)
    ,	ADD INDEX IX_AssociationByIP_ToCustIDFromCustID(ToCustID,FromCustID);

SET @MaxAssByIP = (SElECT MAX(ID) FROM CTS_DataCenter.AssociationByIP);
UPDATE SystemParameter
SET     ParameterValue = @MaxAssByIP
    ,   ParameterName  = 'ProblemCase_AssByIP_ID'
    ,   ParameterDesc  = 'Last Scan ID'
    ,   ParameterDataType = 'BIGINT UNSIGNED'
WHERE ParameterID = 21;
#=================================================================================
/*
ALTER TABLE CTS_DataCenter.SystemEventStatus ADD LastExecTime DATETIME;
ALTER TABLE CTS_DataCenter.AssociationByIP MODIFY CreatedDate DATETIME(3);


CREATE TABLE ProblemCaseMonitor(
		CreatedDate	DATETIME	
    ,	ProblemCaseID	SMALLINT
    , 	CustID		BIGINT UNSIGNED
	,	CustSubID	BIGINT UNSIGNED
    ,	InsertTime	DATETIME(3)
	, 	PRIMARY KEY	PK_ProblemAccountMonitor(CreatedDate,ProblemCaseID,CustID,CustSubID)
    ,	INDEX IX_ProblemCaseMonitor_CustIDProblemCaseID(CustID,ProblemCaseID)
) ENGINE=INNODB;

INSERT IGNORE INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,Status,Description,CreatedDate, PriorityOrder)
VALUES	(12,1,'Problem Case','Problem Case','Robot','Robot',1,NULL,NOW(),1)
	,	(12,2,'Problem Case','Problem Case','Hedging','Hedging',0,NULL,NOW(),2)
    ,	(12,3,'Problem Case','Problem Case','GroupBetting','Group Betting',0,NULL,NOW(),3)
    ,	(12,4,'Problem Case','Problem Case','SuspiciousAssociation','Suspicious Association',1,NULL,NOW(),4)
    ,	(12,5,'Problem Case','Problem Case','TimeInterval','Time Interval',0,NULL,NOW(),5)
    ,	(12,6,'Problem Case','Problem Case','ContinuousBetting','Continuous Betting',0,NULL,NOW(),6)
    ,	(12,7,'Problem Case','Problem Case','Odds Favors','Odds Favors',0,NULL,NOW(),7)
    ,	(12,8,'Problem Case','Problem Case','HighOddsBettor','High Odds Bettor',0,NULL,NOW(),8)
	,	(12,9,'Problem Case','Problem Case','ProPunter','Pro Punter',1,NULL,NOW(),9);

SET @MaxAssByIP = (SElECT MAX(CreatedDate) FROM CTS_DataCenter.AssociationByIP);
SET @MaxAssByDevice = (SElECT MAX(CTSAssDevID) FROM CTS_DataCenter.AssociationByDevice);
SET @MaxClasHis = (SElECT MAX(ID) FROM CTS_DataCenter.CTSCustomerClassification_History);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(21,'ProblemCase_AssByIP_CreatedDate', 'Last Scan time', 'DATETIME(3)', @MaxAssByIP)
	,	(22,'ProblemCase_AssByDevie_CTSAssDevID', 'Last Scan CTSAssDevID', 'BIGINT UNSIGNED', @MaxAssByDevice)
    ,	(23,'ProblemCase_CustClassHis_ID', 'Last Scan ID', 'BIGINT UNSIGNED', @MaxClasHis);

INSERT INTO SystemEventStatus(EventName, Status, LastExecTime)
VALUES('EV_CTS_ProblemCaseMonitor_Rule', 'Stop', CURRENT_TIME());
*/