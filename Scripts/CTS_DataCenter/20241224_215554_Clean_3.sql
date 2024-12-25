/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241224@Thomas.Nguyen
Task:	 	add tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241224@Thomas.Nguyen: Created [Redmine ID: #215554]
Reviewer:
*/
USE CTS_DataCenter;

DROP TABLE IF EXISTS Adhoc_HF215554_AssociatedGroupAccount_Clean;
CREATE TABLE Adhoc_HF215554_AssociatedGroupAccount_Clean (
  GroupID bigint unsigned NOT NULL AUTO_INCREMENT,
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

INSERT INTO CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Clean(GroupID,CTSCustID,IsAuto,Remark,Created,CreatedBy,LastModifiedDate,LastModifiedBy)
WITH CTE AS (
		SELECT GroupID, Max(Created) AS MaxCreated
		FROM CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Group AS g
		GROUP BY GroupID
    )
SELECT ass.GroupID, ass.CTSCustID, ass.IsAuto, ass.Remark, ass.Created, ass.CreatedBy, ass.LastModifiedDate, ass.LastModifiedBy
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN CTE AS ct ON ct.GroupID = ass.GroupID AND ass.Created <= ct.MaxCreated
LEFT JOIN CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Target AS t On ass.CTSCustID = t.CTSCustID AND ass.GroupID = t.GroupID
WHERE t.CTSCustID IS NULL;

DELETE ass
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
    INNER JOIN CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Clean AS c
ON c.GroupID = ass.GroupID AND c.CTSCustID = ass.CTSCustID;