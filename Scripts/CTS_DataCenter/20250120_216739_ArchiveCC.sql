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

SELECT *
FROM SystemParameter
WHERE ParameterID IN (41,119);

UPDATE SystemParameter
SET ParameterValue = 30
WHERE ParameterID IN (41,119);


#==============UPDATE LastID OF ArchiveBySport=====================
SELECT *
FROM SystemParameter
WHERE ParameterID IN (117,118,119);

UPDATE SystemParameter
SET ParameterValue = @lv_lastArchiveID = <<Suggest update min By SPORT History ID within Count and Monitor data >>
WHERE ParameterID IN (118);
