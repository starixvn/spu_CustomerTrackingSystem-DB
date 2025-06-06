/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250528@Thomas.Nguyen
Task:	 	add table to clean
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250528@Thomas.Nguyen: Created [Redmine ID: #222541]
Reviewer:
*/
USE CTS_DataCenter;

DROP TABLE IF EXISTS Adhoc_HF222541_AssociatedGroupAccount_Clean;
CREATE TABLE Adhoc_HF222541_AssociatedGroupAccount_Clean (
  GroupID bigint unsigned NOT NULL,
  CTSCustID bigint unsigned NOT NULL,
  IsAuto bit(1) DEFAULT 0,
  Remark varchar(200) DEFAULT NULL,
  Created datetime DEFAULT CURRENT_TIMESTAMP,
  CreatedBy int unsigned DEFAULT NULL,
  LastModifiedDate datetime DEFAULT NULL,
  LastModifiedBy int unsigned DEFAULT NULL,
  PRIMARY KEY (GroupID,CTSCustID),
  KEY IX_AssociatedGroupAccount_Clean_CTSCustID (CTSCustID)
) ENGINE=InnoDB;

INSERT INTO CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Clean(GroupID,CTSCustID,IsAuto,Remark,Created,CreatedBy,LastModifiedDate,LastModifiedBy)
SELECT ass.GroupID, ass.CTSCustID, ass.IsAuto, ass.Remark, ass.Created, ass.CreatedBy, ass.LastModifiedDate, ass.LastModifiedBy
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
  LEFT JOIN CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Target AS t On ass.CTSCustID = t.CTSCustID AND ass.GroupID = t.GroupID
WHERE ass.GroupID IN (14,25) AND t.CTSCustID IS NULL;

DELETE ass
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
    INNER JOIN CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Clean AS c
ON c.GroupID = ass.GroupID AND c.CTSCustID = ass.CTSCustID;