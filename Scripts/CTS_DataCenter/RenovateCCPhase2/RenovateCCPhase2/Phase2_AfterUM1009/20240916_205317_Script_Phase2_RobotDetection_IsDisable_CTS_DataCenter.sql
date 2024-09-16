/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240916@Victoria.Le
	Task :	Fix Data and Init Missing TVSVoidRequest (UM10092024)
	DB:			
	
	Description: 

	Revisions:	
		- 20240916@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
										RobotDetection - Update IsDisabled = 1 for customers archieved
										-- 71583 rows -	49885 CustID
		
	Param's Explanation (filtered by):

	Example:
*/

DROP TEMPORARY TABLE IF EXISTS Temp_RobotDetection;    
CREATE TEMPORARY TABLE Temp_RobotDetection(	  
		ID						BIGINT PRIMARY KEY
	,	CustID					BIGINT 
	,	IsUpdated				TINYINT(1) DEFAULT 0
);


DROP TEMPORARY TABLE IF EXISTS Temp_CustID_Archive;    
CREATE TEMPORARY TABLE Temp_CustID_Archive(	  
		CustID						BIGINT PRIMARY KEY
);

INSERT INTO Temp_RobotDetection (ID, CustID)
SELECT rd.ID, rd.CustID
FROM CTS_DataCenter.RobotDetection AS rd
	LEFT JOIN CTS_DataCenter.CTSCustomer as cust on cust.CustID = rd.CustID
WHERE cust.CustID IS NULL AND rd.IsDisabled = 0
;

INSERT IGNORE INTO Temp_CustID_Archive (CustID)
SELECT temp.CustID
FROM Temp_RobotDetection AS temp
,	LATERAL (
			SELECT ar.IsReactivated, ar.CustID
			FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS ar
			WHERE ar.CustID = temp.CustID
			ORDER BY ar.InsertTime DESC, ar.ID DESC
			LIMIT 1
		) AS latest
WHERE temp.CustID =  latest.CustID
and latest.IsReactivated = 0;

UPDATE Temp_RobotDetection AS rd
	INNER JOIN Temp_CustID_Archive AS ar ON ar.CustID = rd.CustID
SET rd.IsUpdated = 1
;

UPDATE CTS_DataCenter.RobotDetection AS rd
	INNER JOIN Temp_RobotDetection AS temp ON temp.ID = rd.ID
SET rd.IsDisabled = 1
WHERE temp.IsUpdated = 1
;