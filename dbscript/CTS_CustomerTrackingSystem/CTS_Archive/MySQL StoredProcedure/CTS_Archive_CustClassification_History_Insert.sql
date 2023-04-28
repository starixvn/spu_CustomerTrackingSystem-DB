/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Archive`.`CTS_Archive_CustClassification_History_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Archive_CustClassification_History_Insert`(
		IN ip_HistoryJson JSON
)
    SQL SECURITY INVOKER
BEGIN
/*
	Created: 20210826@Aries.Nguyen
	Task : Archive CTSCustomerClassification_History
	DB: CTS_Archive 
	Original:

	Revisions:
		- 20201006@Aries.Nguyen:	Created  [Redmine ID: #160758] 
		- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
		- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeId [Redmine ID: #185319] 
		- 20230428@Jonas.Huynh: 	Realtime Renovation [Redmine ID: #186678]
        
	Param's Explanation (filtered by):

*/

	INSERT INTO CTS_Archive.CTSCustomerClassification_History_Archive(
			HistoryID
        ,	CustID
        ,	CTSCustID
        ,	SportGroupID
        ,	CategoryID
        ,	TurnoverRM
        ,	WinlossRM
        ,	BetCount
        ,	ActiveDays
        ,	RobotCounter
        ,	ProbationPeriodWinloss
        ,	TargetCC
        ,	SourceTypeID
		,	FromCategoryID 			
        ,	ToCategoryID 			
        ,	IsAppliedCC 			
        ,	IsDataChanged 			
        ,	ActionType 				
        ,	IsAuto 					
        ,	LastModifiedDate 		
        ,	LastModifiedBy 			
        ,	InsertDate 				
        ,	TaggingType 			
        ,	TargetDangerLevel1 		
        ,	IsAppliedDangerLevel1 	
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
        ,	ProbationPeriodWinloss
        ,	TargetCC
        ,	SourceTypeID
		,	FromCategoryID 			
        ,	ToCategoryID 			
        ,	IsAppliedCC 			
        ,	IsDataChanged 			
        ,	ActionType 				
        ,	IsAuto 					
        ,	LastModifiedDate 		
        ,	LastModifiedBy 			
        ,	InsertDate 				
        ,	TaggingType 			
        ,	TargetDangerLevel1 		
        ,	IsAppliedDangerLevel1 	
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
	FROM JSON_TABLE(
			ip_HistoryJson,
			 "$[*]" COLUMNS(
								HistoryID				BIGINT UNSIGNED 	PATH "$.ID"       
							,	CustID					BIGINT UNSIGNED 	PATH "$.CustID"   
							,	CTSCustID				BIGINT UNSIGNED 	PATH "$.CTSCustID"
							,	SportGroupID			SMALLINT UNSIGNED	PATH "$.SportGroupID"
							,	CategoryID				SMALLINT			PATH "$.CategoryID"
							,	TurnoverRM				DECIMAL(20 , 4 )	PATH "$.TurnoverRM"
							,	WinlossRM				DECIMAL(20 , 4 ) 	PATH "$.WinlossRM"
							,	BetCount				BIGINT 				PATH "$.BetCount"
                            ,	ActiveDays				INT					PATH "$.ActiveDays"
                            ,	RobotCounter			SMALLINT			PATH "$.RobotCounter"
							,	ProbationPeriodWinloss	DECIMAL(20 , 4 ) 	PATH "$.ProbationPeriodWinloss"
							,	TargetCC				SMALLINT 			PATH "$.TargetCC"
                            ,	SourceTypeID			SMALLINT UNSIGNED	PATH "$.SourceTypeID"
							,	FromCategoryID 			SMALLINT UNSIGNED 	PATH "$.FromCategoryID"
							,	ToCategoryID 			SMALLINT UNSIGNED 	PATH "$.ToCategoryID"
							,	IsAppliedCC 			BIT(1) 				PATH "$.IsAppliedCC"
							,	IsDataChanged 			BIT(1) 				PATH "$.IsDataChanged"
							,	ActionType 				TINYINT 			PATH "$.ActionType"
							,	IsAuto 					BIT(1) 				PATH "$.IsAuto"
							,	LastModifiedDate 		DATETIME 			PATH "$.LastModifiedDate"
							,	LastModifiedBy 			INT UNSIGNED 		PATH "$.LastModifiedBy"
							,	InsertDate 				DATETIME  			PATH "$.InsertDate"
							,	TaggingType 			SMALLINT  			PATH "$.TaggingType"
							,	TargetDangerLevel1 		SMALLINT  			PATH "$.TargetDangerLevel1"
							,	IsAppliedDangerLevel1 	BIT(1)  			PATH "$.IsAppliedDangerLevel1"
							,	TWGroupBettingRate 		DECIMAL(10 , 4 )  	PATH "$.TWGroupBettingRate"
							,	TWTicketRejectRate 		DECIMAL(10 , 4 )  	PATH "$.TWTicketRejectRate"
							,	TWBetCount 				BIGINT  			PATH "$.TWBetCount"
							,	TWDesktopUsageRate		DECIMAL(10 , 4 ) 	PATH "$.TWDesktopUsageRate"
                            ,	Remark		            VARCHAR(500) 		PATH "$.Remark"
                            ,   IsDirect                BOOLEAN             PATH "$.IsDirect"
                            ,   TVSRequestID            BIGINT UNSIGNED 	PATH "$.TVSRequestID"   
                            ,	IsFromTVS 				BOOLEAN 	        PATH "$.IsFromTVS"
			                ,	IsFromTW 				BOOLEAN 	        PATH "$.IsFromTW"  
			                ,	IsFromCTS 				BOOLEAN 	        PATH "$.IsFromCTS"   
			                ,	IsFromAI 	            BOOLEAN 	        PATH "$.IsFromAI"  
							,	IsFromImperva			BOOLEAN 	        PATH "$.IsFromImperva"  
							,	IsParlay				BOOLEAN				PATH "$.IsParlay"  
							,	SportType				SMALLINT			PATH "$.SportType"  
							,	IssueTypeID				TINYINT				PATH "$.IssueTypeID"  
                            ,	PerformanceTime			DATETIME			PATH "$.PerformanceTime"  
							)
		   ) AS  tbl; 

END$$
DELIMITER ;