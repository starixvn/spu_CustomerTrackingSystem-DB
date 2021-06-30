/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210701@Long.Luu
Task:	 	Schema for Robot Classification
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	[20210701@Long.Luu][0000]: Schema for Robot Classification
Reviewer:
*/

DROP TABLE IF EXISTS CTS_DataCenter.RobotClassification;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.RobotClassification(
		CustID				BIGINT UNSIGNED
	, 	SportTypeID			SMALLINT UNSIGNED
	, 	BetTypeID			SMALLINT UNSIGNED
	, 	LiveIndicator		BIT
    ,	RobotType			TINYINT UNSIGNED
    ,	FromDate			DATE
    ,	ToDate				DATE
	, 	PRIMARY KEY			PK_RobotClassification_CustIDSportTypeIDBetTypeIDLiveIndicator(CustID,SportTypeID,BetTypeID,LiveIndicator,FromDate)
    , 	KEY					IX_RobotClassification_FromDateToDate(FromDate,ToDate)
) ENGINE=INNODB;

INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,0,'Robot Classification','Robot Classification Type','Observed Robot','Observed Robot',1,1,'Observed - Unknown Robot',NOW());
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,1,'Robot Classification','Robot Classification Type','Good Robot','Good Robot',1,1,'Good - Losing Robot',NOW());
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,2,'Robot Classification','Robot Classification Type','Bad Robot','Bad Robot',1,1,'Bad - Winning Robot',NOW());
