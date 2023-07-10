/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Archive`.`CTS_Archive_CustClassification_BySport_History_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Archive_CustClassification_BySport_History_Insert`(
		IN ip_HistoryJson JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220909@Aries.Nguyen
		Task : Archive CTSCustomerClassification_BySport_History
		DB: CTS_Archive 
		Original:

		Revisions:
			- 20220909@Aries.Nguyen:Created  [Redmine ID: #176992] 
            - 20230707@Jonas.Huynh:	Renovate normal classification [Redmine ID: #189875]
            
		Param's Explanation (filtered by):

	*/
	
    INSERT INTO CTS_Archive.CTSCustomerClassification_BySport_History_Archive(HistoryID,CustID,CTSCustID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate,PerformanceTime)
	SELECT	HistoryID
        ,	CustID 				
		,	CTSCustID 			
		,	SportID 			
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
	FROM JSON_TABLE(
			ip_HistoryJson,
			 "$[*]" COLUMNS(
								HistoryID			BIGINT UNSIGNED 	PATH "$.ID"       
							,	CustID 				BIGINT UNSIGNED		PATH "$.CustID"       
							,	CTSCustID 			BIGINT UNSIGNED		PATH "$.CTSCustID"       
							,	SportID 			SMALLINT UNSIGNED	PATH "$.SportID"       
							,	CategoryID 			SMALLINT UNSIGNED	PATH "$.CategoryID"       
							,	TurnoverRM 			DECIMAL(20 , 4 )	PATH "$.TurnoverRM"       
							,	WinlossRM 			DECIMAL(20 , 4 )	PATH "$.WinlossRM"       
							,	BetCount 			BIGINT				PATH "$.BetCount"       
							,	ActiveDays 			INT					PATH "$.ActiveDays"       
							,	TargetCC 			SMALLINT			PATH "$.TargetCC"            
							,	ActionType 			TINYINT				PATH "$.ActionType"       
							,	LastModifiedDate 	DATETIME			PATH "$.LastModifiedDate"       
							,	LastModifiedBy 		INT UNSIGNED		PATH "$.LastModifiedBy"       
							,	InsertDate 			DATETIME 			PATH "$.InsertDate" 
                            ,	PerformanceTime 	DATETIME 			PATH "$.PerformanceTime" 
				)
		   ) AS  tbl;  
END$$
DELIMITER ;