
/*
	Created:	20200706@Long.Luu
	Task:		Init Data [Redmine ID: #134652]
	DB:			CTS_DataCenter
	Original:

	Revisions:
		- 20200706@Long.Luu: Created [Redmine ID: #134652]
	
	Param's Explanation (filtered by):
*/

INSERT INTO CTS_Admin.LogType(LogTypeName, LogTypeDescription)
VALUES ('Insert Associated Account Monitor','Insert Associated Account Monitor');

INSERT INTO CTS_Admin.LogType(LogTypeName, LogTypeDescription)
VALUES ('Delete Associated Account Monitor','Delete Associated Account Monitor');

INSERT INTO CTS_DataCenter.CTSUserNotificationParameter(UserID,FromNewAssID,ToNewAssID)
SELECT 229, MAX(a.CTSAssDevID), MAX(a.CTSAssDevID)
FROM CTS_DataCenter.AssociationByDevice AS a;
