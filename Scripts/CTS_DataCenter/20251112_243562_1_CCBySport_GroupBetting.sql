/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250724@Casey.Huynh
Task:	 	
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250724@Casey.Huynh: Created  [Redmine ID: #219679]
Reviewer:
*/

USE CTS_DataCenter;

#1. New table: CTSCustomerClassificationBySport_DailyPAQueue (ID, CustID, CreatedTime)
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassificationBySport_DailyPAQueue(
		ID 			BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	CustID 		BIGINT UNSIGNED NOT NULL
    ,	CreatedTime DATETIME NOT NULL
	,	INDEX	IX_CTSCustomerClassificationBySport_DailyPAQueue_CreatedTime_CustID(CreatedTime, CustID)  
)ENGINE=INNODB, AUTO_INCREMENT = 1;

#================================================================================
ALTER TABLE MatchMonitor
	ADD COLUMN ClassifyStatusBySport TINYINT DEFAULT 0
;

ALTER TABLE MatchMonitorDetails
	ADD COLUMN ClassifyStatusBySport TINYINT DEFAULT 0
;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(@ListID:=24,@ItemID:=31,@ListName:='Flow Classification BySport Insert',@ListNameDisplay:='INPUTFLOWID',@ItemName:='CONST_INPUTFLOWID_BYSPORT_INSERT_PACATEGORY',@ItemNameDisplay:='CONST_INPUTFLOWID_BYSPORT_INSERT_PACATEGORY',@ItemValue:='335',@ItemDefaultValue:='335',@ItemParentItemID:=4,@PriorityOrder:=NULL,@Status:=1,@Description:=NULL,@CreatedDate:=NOW())
;
SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 24;

#=========================CTS_DataCenter.SystemParameter===================================

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(199,'Classification_BySport_MM_PackSize','Last Classification_BySport_MatchMonitor_PackSize.ID','INT','100')
	,	(200,'Classification_BySport_MM_InProcessMatchID','In_process_BySport MatchMonitor.MatchID','INT ',0);

SELECT * FROM CTS_DataCenter.SystemParameter WHERe ParameterID IN (199,200);
#===============================================================================================================
