/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241219@Casey.Huynh	
Task:	 	Move Agency
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241219@Casey.Huynh: Created [Redmine ID: #215554]
Reviewer: Long
*/
#*********************GET BACKUP********************************
USE CTS_Adhoc;
DROP TABLE IF EXISTS Adhoc_HF215554_AssociatedGroupAccount_Agency;
CREATE TABLE Adhoc_HF215554_AssociatedGroupAccount_Agency (
		GroupID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CTSCustID BIGINT UNSIGNED NOT NULL
	,	IsAuto BIT(1) DEFAULT b'0'
	,	Remark VARCHAR(200) DEFAULT NULL
	,	Created DATETIME DEFAULT CURRENT_TIMESTAMP
	,	CreatedBy INT UNSIGNED DEFAULT NULL
	,	LastModifiedDate DATETIME DEFAULT NULL
	,	LastModifiedBy INT UNSIGNED DEFAULT NULL
	,	RoleID TINYINT

	,	PRIMARY KEY (GroupID,CTSCustID)
	,	KEY IX_AssociatedGroupAccount_CTSCustID (CTSCustID)
) ENGINE=InnoDB
;

INSERT INTO CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency
SELECT agc.*, cus.RoleID
FROM  CTS_DataCenter.AssociatedGroupAccount AS agc	
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON agc.CTSCustID = cus.CTSCustID AND RoleID <> 1
WHERE agc.IsAuto = 1
;

SELECT COUNT(1) AS TotalAgency
FROM  CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency
;
#*********************DELETE********************************
USE CTS_DataCenter;

SELECT COUNT(1) AS expectedRemoveAgency
FROM CTS_DataCenter.AssociatedGroupAccount AS del
	INNER JOIN CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency AS agent ON agent.CTSCustID = del.CTSCustID AND agent.GroupID = del.GroupID
;

DELETE del
FROM CTS_DataCenter.AssociatedGroupAccount AS del
	INNER JOIN CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency AS agent ON agent.CTSCustID = del.CTSCustID AND agent.GroupID = del.GroupID
;