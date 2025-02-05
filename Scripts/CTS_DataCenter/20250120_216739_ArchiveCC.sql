/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20250120@Casey.Huynh
Task:	 	Adjust Archive Schedule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
	-	[20250120@Casey.Huynh]:  [Remind ID: #216739]
Reviewer:
*/
#==============UPDATE Archive Take Days SCHEDULE 30 Days=====================
USE CTS_DataCenter;

UPDATE SystemParameter
SET ParameterValue = 30
WHERE ParameterID IN (41,119);

#==============UPDATE LastID OF Archive History=====================
UPDATE SystemParameter
SET ParameterValue = 1
WHERE ParameterID IN (35,118);

/* CHECK Data 
SELECT *
FROM SystemParameter
WHERE ParameterID IN (35,40,41,117,118,119);

SELECT *
FROM SystemParameter
WHERE ParameterID IN (117,118,119);

SELECT COUNT(1)
FROM CTSCustomerClassification_History
WHERE InsertDate <  DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY); #133473948

SELECT COUNT(1)
FROM CTSCustomerClassification_BySport_History
WHERE InsertDate <  DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY); #20409022
*/
