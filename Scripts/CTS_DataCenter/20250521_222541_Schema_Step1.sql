/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250520@Thomas.Nguyen
Task:	 	add tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250520@Thomas.Nguyen: Created [Redmine ID: #222541]
Reviewer:
*/

USE CTS_DataCenter;

DROP TABLE IF EXISTS Adhoc_HF222541_AssociatedGroupAccount_Group;
CREATE TABLE Adhoc_HF222541_AssociatedGroupAccount_Group(
  GroupID INT
    , Created DATETIME
    , TotalScanMember INT
    , ProcessStatus TINYINT    
    
    , PRIMARY KEY (GroupID, Created)
    , INDEX IX_Adhoc_HF222541_AssociatedGroupAccount_Group_ProcessStatus(ProcessStatus)
);

DROP TABLE IF EXISTS Adhoc_HF222541_AssociatedGroupAccount_Target;
CREATE TABLE Adhoc_HF222541_AssociatedGroupAccount_Target (
  GroupID bigint unsigned NOT NULL,
  CTSCustID bigint unsigned NOT NULL,
  IsAuto bit(1) DEFAULT 0,
  Remark varchar(200) DEFAULT NULL,
  Created datetime DEFAULT CURRENT_TIMESTAMP,
  CreatedBy int unsigned DEFAULT NULL,
  LastModifiedDate datetime DEFAULT NULL,
  LastModifiedBy int unsigned DEFAULT NULL,
  IsScaned BOOLEAN Default 0,
  PRIMARY KEY (GroupID,CTSCustID),
  KEY IX_AssociatedGroupAccount_Target_CTSCustID (CTSCustID)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Adhoc_HF222541_CustNeedToUpdateABI;
CREATE TABLE Adhoc_HF222541_CustNeedToUpdateABI(
		CustID bigint unsigned NOT NULL
  , UserName varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  , ABI tinyint
  , GroupID bigint unsigned
  , Created datetime
  , PRIMARY KEY (CustID, GroupID)
);

INSERT INTO CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Group(GroupID, Created,TotalScanMember,ProcessStatus )
WITH cte AS
(
	SELECT  ass.GroupID, Min(ass.Created) AS FromCreated
	FROM CTS_DataCenter.AssociatedGroupAccount AS ass
    INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON ag.GroupID = ass.GroupID
  WHERE ag.IsDisable = 0 AND ass.GroupID IN (14,25)
  GROUP BY ass.GroupID
)
SELECT ass.GroupID, ass.Created, COUNT(1), 0
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN cte ON cte.GroupID = ass.GroupID AND ass.Created > cte.FromCreated
GROUP BY ass.GroupID, ass.Created;

INSERT INTO CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Target(GroupID,CTSCustID,IsAuto,Remark,Created,CreatedBy,LastModifiedDate,LastModifiedBy,IsScaned)
WITH cte AS
(
	SELECT  ass.GroupID, MIN(ass.Created) AS FromCreated
	FROM CTS_DataCenter.AssociatedGroupAccount AS ass
    INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON ag.GroupID = ass.GroupID
  WHERE ag.IsDisable = 0 AND ass.GroupID IN (14,25)
  GROUP BY ass.GroupID
)
SELECT ass.GroupID, ass.CTSCustID, ass.IsAuto, ass.Remark, ass.Created, ass.CreatedBy, ass.LastModifiedDate, ass.LastModifiedBy, 0
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN cte ON cte.GroupID = ass.GroupID AND ass.Created = cte.FromCreated;