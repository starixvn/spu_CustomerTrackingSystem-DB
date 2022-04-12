/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	20220408@Casey.Huynh: Add AssociationGroupByAI [Redmine ID: #171222]
	Task: Add table schema.
	DB: CTS_Archive
*/
USE CTS_Archive;

CREATE TABLE AssociationGroupByAI_Arc(
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	GroupID 		BIGINT UNSIGNED NOT NULL
	,	OriginGroupID 	BIGINT UNSIGNED DEFAULT NULL
	,	CustID 			BIGINT UNSIGNED NOT NULL
	,	CreatedDate 	DATETIME DEFAULT NULL
	
	,	PRIMARY KEY (CustID, GroupID)
    ,	INDEX IX_AssociationGroupByAI_Arc_GroupIDCustID(GroupID, CustID)
    ,	INDEX IX_AssociationGroupByAI_Arc_OriginGroupIDCustID(OriginGroupID, CustID)
) ENGINE=InnoDB;
            
