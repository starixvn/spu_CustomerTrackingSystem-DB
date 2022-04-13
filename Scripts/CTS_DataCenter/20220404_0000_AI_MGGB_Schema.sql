/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	202204040@Long.Luu
Task:	 	Schema for MGGB [Redmine ID: 0000] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

DROP TABLE CTS_DataCenter.AssociationGroupByAI;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationGroupByAI (
		ID					BIGINT UNSIGNED AUTO_INCREMENT
	,	GroupID				BIGINT UNSIGNED
    ,	OriginGroupID		BIGINT UNSIGNED 	
	, 	CustID				BIGINT UNSIGNED
    ,	CreatedDate			DATETIME
    ,	PRIMARY KEY			PK_AssociationGroupByAI_GroupIDCustID(GroupID,CustID)
	, 	INDEX				IX_AssociationGroupByAI_ID(ID)
	, 	INDEX				IX_AssociationGroupByAI_OriginGroupIDCustID(OriginGroupID,CustID)
    , 	INDEX				IX_AssociationGroupByAI_CustIDGroupID(CustID,GroupID)
) ENGINE=INNODB;


