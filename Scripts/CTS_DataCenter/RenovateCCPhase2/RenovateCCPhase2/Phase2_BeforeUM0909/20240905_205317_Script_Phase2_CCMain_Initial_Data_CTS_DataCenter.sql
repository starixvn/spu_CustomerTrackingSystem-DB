/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240905@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240905@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

/*
SELECT * FROM SystemParameter WHERE ParameterID IN (775,774);

DELETE FROM SystemParameter WHERE ParameterID IN (775,774);

UPDATE SystemEventStatus SET Status = 'Stop' WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
*/

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES 	(775, 'CCMain_CorrectData_CustID', 'CCMain_CorrectData_CustID','BIGINT',0)
,		(774, 'CCMain_CorrectData_Batchsize', 'CCMain_CorrectData_Batchsize','INT',3000);

INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData','Stop', NOW());