/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220627@Casey.Huynh
Task:	 	Auto Classify Group Betting for 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211213@Casey.Huynh: Created [Redmine ID: #166986]
Reviewer:
*/

USE CTS_DataCenter;
/******************ALTER TABLE *************************/
ALTER TABLE MatchMonitor
ADD COLUMN ClassifyStatus TINYINT DEFAULT 0 COMMENT '0: Default, 1: Classify Done, 2: Ready To Classify (Match Complete)';

ALTER TABLE MatchMonitor
ADD INDEX IX_MatchMonitor_SportTypeClassifyStatus(SportType,ClassifyStatus,KickOffTime);

ALTER TABLE MatchMonitorDetails
ADD COLUMN ClassifyStatus TINYINT  DEFAULT 0 COMMENT '0: Default, 1: Classify Done';

/******************Init SystemParameter***************************/
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(95,'Classification_MatchMonitor_PackSize','Last Classification_MatchMonitor_PackSize.ID','INT','100')
	,	(96,'Classification_MatchMonitor_InProcessMatchID','In_process MatchMonitor.MatchID','BIGINT UNSIGNED',NULL);

/******************Init StaticList***************************/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,35,'Classification Source Type','Classification Source Type','Auto Mark Group Betting From Match Monitor','Auto Mark Group Betting From Match Monitor',35,1,'Auto Mark Group Betting From Match Monitor',NOW());
    

