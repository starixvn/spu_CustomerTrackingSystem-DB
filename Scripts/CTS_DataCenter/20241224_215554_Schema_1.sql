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

DROP TABLE IF EXISTS Adhoc_HF215554_AssociatedGroupAccount_Group;
CREATE TABLE Adhoc_HF215554_AssociatedGroupAccount_Group(
	GroupID INT
    , Created DATETIME
	, FromCreated DATETIME
    , TotalScanMember INT
    , ProcessStatus TINYINT    
    
    , PRIMARY KEY (GroupID, Created)
    , INDEX IX_Adhoc_HF215554_AssociatedGroupAccount_Group_ProcessStatus(ProcessStatus)
);
DROP TABLE IF EXISTS Adhoc_HF215554_AssociatedGroupAccount_Target;
CREATE TABLE Adhoc_HF215554_AssociatedGroupAccount_Target (
  GroupID bigint unsigned NOT NULL AUTO_INCREMENT,
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

INSERT INTO CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Group(GroupID, Created, FromCreated,TotalScanMember,ProcessStatus )
WITH cte AS
(
	SELECT  GroupID, Min(Created) AS FromCreated
	FROM CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency
	GROUP BY GroupID
)
SELECT ass.GroupID, ass.Created, MIN(cte.FromCreated), COUNT(1), 0
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN cte ON cte.GroupID = ass.GroupID AND ass.Created >= cte.FromCreated
GROUP BY ass.GroupID, ass.Created;

INSERT INTO CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Target(GroupID,CTSCustID,IsAuto,Remark,Created,CreatedBy,LastModifiedDate,LastModifiedBy,IsScaned)
WITH cte AS
(
	SELECT  GroupID, Min(Created) AS FromCreated
	FROM CTS_Adhoc.Adhoc_HF215554_AssociatedGroupAccount_Agency
	GROUP BY GroupID
)
SELECT ass.GroupID, ass.CTSCustID, ass.IsAuto, ass.Remark, ass.Created, ass.CreatedBy, ass.LastModifiedDate, ass.LastModifiedBy, 0
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN cte ON cte.GroupID = ass.GroupID AND ass.Created < cte.FromCreated;

/**/