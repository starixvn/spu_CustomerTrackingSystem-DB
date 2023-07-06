/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20230706@Victoria.Le
	Task :		
	DB:			
	
	Description: 

	Revisions:	
		- 20230706@Victoria.Le: 	Initial Writing [Redmine ID: #189505]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (135, 'TWGroupBetting_CountTotalTicket_BatchSize', 'TWGroupBetting_CountTotalTicket_BatchSize','INT','5000');

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (136, 'TWGroupBetting_CountTotalTicket_LastSequenceId', 'TWGroupBetting_CountTotalTicket_LastSequenceId','BIGINT',0);



