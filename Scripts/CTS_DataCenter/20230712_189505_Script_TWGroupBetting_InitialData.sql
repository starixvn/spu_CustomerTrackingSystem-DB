/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20230712@Victoria.Le
	Task :		
	DB:			
	
	Description: 

	Revisions:	
		- 20230712@Victoria.Le: 	Initial Writing [Redmine ID: #189505]
		- 20230713@Victoria.Le: 	Update Value [Redmine ID: #189505]
		
	Param's Explanation (filtered by):

	Example:
*/
UPDATE SystemParameter
SET ParameterValue = 118184600808 -- Max(SequenceID) 2023-07-12
WHERE ParameterID = 136
;

/*
INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (137, 'TWGroupBetting_CountTotalTicket_Status', 'TWGroupBetting_CountTotalTicket_Status','BOOLEAN',0);

UPDATE SystemParameter
SET ParameterValue = 118179303068 -- Max(SequenceID)
WHERE ParameterID = 136 
;
*/
/*
SELECT TOP 100 b.matchid,b.bettype,b.betfrom,b.SequenceID,b.* FROM dbo.bettrans b (nolock)
--LEFT JOIN [bodb02].dbo.match AS m WITH (NOLOCK) ON b.matchid = m.matchid AND m.sporttype < 100
WHERE b.transdate BETWEEN '2023-07-11 23:59:58.000' AND '2023-07-11 23:59:59.000' order by b.SequenceID desc

*/

