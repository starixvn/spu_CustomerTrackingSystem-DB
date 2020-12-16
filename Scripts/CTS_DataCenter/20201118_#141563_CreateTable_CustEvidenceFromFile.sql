/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201106@Adam.Tran
	Task: Import Customer Evidences [Redmine ID: #141563] 
	DB: CTS_DataCenter
*/
DROP TABLE IF EXISTS CTS_DataCenter.CustEvidenceFromFile;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustEvidenceFromFile(
		ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CTSCustID			BIGINT UNSIGNED NOT NULL
	,	CustID				INT UNSIGNED NOT NULL
	,	SubscriberID		INT UNSIGNED NOT NULL
	,	EvidenceID			SMALLINT UNSIGNED NOT NULL
	,	Remark 				VARCHAR(500) 
	,	IsOverwrite			BIT
	,	FileKey				VARCHAR(50) NOT NULL
	,	FileName			VARCHAR (200)
	,	IsProcessed			BIT	DEFAULT 0	
	,	CreatedBy			INT	UNSIGNED NOT NULL
	, 	CreatedTime			TIMESTAMP(4) NOT NULL
	,	LastModifiedBy		INT	UNSIGNED
	, 	LastModifiedTime	DATETIME	
    ,	PRIMARY KEY			PK_CustEvidenceFromFile_ID(ID)
	,	INDEX 		 		IX_CustEvidenceFromFile_FileKey(FileKey)
	,	INDEX 		 		IX_CustEvidenceFromFile_IsProcessed(IsProcessed)
	,	INDEX 		 		IX_CustEvidenceFromFile_CreatedTime(CreatedTime)
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
