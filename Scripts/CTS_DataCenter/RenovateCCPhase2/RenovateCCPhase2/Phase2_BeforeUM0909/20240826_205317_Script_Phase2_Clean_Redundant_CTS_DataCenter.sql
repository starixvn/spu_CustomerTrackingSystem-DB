/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (996, 'Redundant_Clean_CustID', 'Redundant_Clean_CustID','BIGINT',593520)
,	(995, 'Redundant_Clean_Batchsize', 'Redundant_Clean_Batchsize','INT',500);

/*
SELECT COUNT(1), max(CustID), min(CustID) FROM CTS_DataCenter.AdhocVic_Customer;
-- 175368	102979792	593520
-- AROUND 6 HOURS
*/

-- Event
INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant','Stop', NOW());