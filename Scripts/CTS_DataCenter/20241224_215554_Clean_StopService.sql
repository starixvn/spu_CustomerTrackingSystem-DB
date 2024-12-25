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

/**********************************************RELEASE STEP BY STEP****************************************************************/
/*1.Insert new group to scan*/
INSERT INTO CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Group(GroupID, Created, FromCreated,TotalScanMember,ProcessStatus )
WITH cte AS
(
	SELECT  GroupID, MAX(gr.Created) AS FromCreated
	FROM CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Group AS gr
	GROUP BY GroupID
)
SELECT ass.GroupID, ass.Created, MIN(cte.FromCreated), COUNT(1), 0
FROM CTS_DataCenter.AssociatedGroupAccount AS ass
	INNER JOIN cte ON cte.GroupID = ass.GroupID AND ass.Created > cte.FromCreated
    GROUP BY ass.GroupID, ass.Created;

/*2.Scan for new group*/
CALL Adhoc_HF115554_RescanMemberGroup();

/*3.Clean data*/
INSERT IGNORE INTO CTS_DataCenter.Adhoc_HF215554_AssociatedGroupAccount_Clean(GroupID,CTSCustID,IsAuto,Remark,Created,CreatedBy,LastModifiedDate,LastModifiedBy)
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
