/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Created:	20240912@Victoria.Le
	Task :	Init new tables
	DB:			
	
	Description: 

	Revisions:	
		- 20240912@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_Archive;

INSERT INTO CTS_Archive.CTSCustomerClassification_History_Renovate_Archive(
	HistoryID
,	CustID
,	CTSCustID
,	ParentID
,	CategoryID
,	TurnoverRM
,	WinlossRM
,	BetCount
,	ActiveDays
,	RobotCounter
,	TargetCC
,	SourceTypeID
,	OldCategoryID 			
,	DWCategoryID 						
,	IsDataChanged 			
,	ActionType 				
,	IsAuto 					
,	LastModifiedDate 		
,	LastModifiedBy 			
,	InsertDate 				
,	TaggingType 			
,	TargetDangerLevel1 		
,	TWGroupBettingRate 		
,	TWTicketRejectRate 		
,	TWBetCount 				
,	TWDesktopUsageRate   
,	Remark
,   IsMarkedDirectly
,   TVSRequestID
,	IsFromTVS 				 
,	IsFromTW 				
,	IsFromCTS 				
,	IsFromAI
,	IsFromImperva
,	IsParlay
,	SportType
,	IssueTypeID
,	PerformanceTime
)
SELECT	HistoryID
,	CustID
,	CTSCustID
,	SportGroupID
,	CategoryID
,	TurnoverRM
,	WinlossRM
,	BetCount
,	ActiveDays
,	RobotCounter
,	TargetCC
,	SourceTypeID
,	FromCategoryID 			
,	ToCategoryID 					
,	IsDataChanged 			
,	ActionType 				
,	IsAuto 					
,	LastModifiedDate 		
,	LastModifiedBy 			
,	InsertDate 				
,	TaggingType 			
,	TargetDangerLevel1 		
,	TWGroupBettingRate 		
,	TWTicketRejectRate 		
,	TWBetCount 				
,	TWDesktopUsageRate  
,	Remark
,   IsDirect
,   TVSRequestID
,	IsFromTVS 				 
,	IsFromTW 				
,	IsFromCTS 				
,	IsFromAI 	
,	IsFromImperva
,	IsParlay
,	SportType
,	IssueTypeID
,	PerformanceTime
FROM CTS_Archive.CTSCustomerClassification_History_Archive
WHERE ID >= 273353193
;

INSERT INTO CTS_Archive.CTSCustomerClassification_BySport_History_Renovate_Archive(
		HistoryID,CustID,CTSCustID,SportID,ParentID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate
	,	LastModifiedBy,InsertDate,PerformanceTime)
SELECT	HistoryID
	,	CustID 				
	,	CTSCustID 			
	,	SportID 
	,	CASE WHEN CategoryID IS NULL THEN NULL
			WHEN CategoryID = 10300 THEN 10000 
			WHEN CategoryID > 40000 THEN 40000
			ELSE NULL
		END AS ParentID
	,	CategoryID 			
	,	TurnoverRM 			
	,	WinlossRM 			
	,	BetCount 			
	,	ActiveDays 			
	,	TargetCC 				
	,	ActionType 			
	,	LastModifiedDate 	
	,	LastModifiedBy 		
	,	InsertDate 
	,	PerformanceTime
FROM CTSCustomerClassification_BySport_History_Archive
WHERE ID >= 5351141
;

DELETE FROM CTSCustomerClassification_History_Archive WHERE ID >= 273353193;
DELETE FROM CTSCustomerClassification_BySport_History_Archive WHERE ID >= 5351141;