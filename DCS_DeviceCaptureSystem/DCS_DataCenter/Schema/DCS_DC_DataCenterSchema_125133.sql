/*
Creator: 20191217@CaseyHuynh
Task:	 	DCS_Schema
Server:  	Slave
DBName:		DCS_DataCenter

Revisions: 
	[20200310@Casey.Huynh][130109]: Create Schema table `Transaction07`
    
Reviewer:

*/
# [20200310@Casey.Huynh][130109]: Create Schema table `Transaction07`
 # =======Transactions============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.Transaction07(
		TransID				BIGINT	UNSIGNED					NOT NULL
		, LoginName			VARCHAR(100) 		CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'		NOT NULL
        , TransTime			TIMESTAMP(4)						NOT	NULL                
        , SubscriberID		INT									NULL
        , AccountID			BIGINT			UNSIGNED			NULL
        , URLID				BIGINT			UNSIGNED			NULL
		, DeviceCodeID		BIGINT			UNSIGNED			NULL
		, DeviceID			BIGINT			UNSIGNED			NULL
        , FirstDeviceCode	VARCHAR(64)							NULL
        , DeviceStatus		TINYINT								NULL
        , DeviceFingerprintID	BIGINT			UNSIGNED		NULL
        , UserAgentKey		VARCHAR(32)							NULL
        , IP				VARCHAR(50)							NULL
        , IPID				DECIMAL(50,0)						NULL
        , ActionResultID 	BIGINT								NULL
		, Flagged			SMALLINT							NULL		COMMENT 'captcha & browserless'		
        , PluginID			BIGINT 								NULL
        , TransStatus		BIT(16)								NULL
        , CreatedDate		DATETIME							NOT NULL	COMMENT 'Date Only'	NOT	NULL
        , InsertTime		TIMESTAMP(4)						NOT NULL
        
        , DeviceCode			VARCHAR(32)						NULL
        , FingerprintCode		VARCHAR(2000)					NULL
        , FingerprintMoreInfo	TEXT	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	NULL
        
        , PRIMARY KEY	PK_Transaction_TransID(TransID)
        , INDEX			IX_Transaction_SubscriberIDAccountID(SubscriberID, AccountID, CreatedDate)
        , INDEX			IX_Transaction_IPID_IP(IPID, IP)
        , INDEX			IX_Transaction_CreatedDate(CreatedDate)
        , INDEX			IX_Transaction_DeviceIDDeviceCode(DeviceID, DeviceCode)
	 ) ENGINE=InnoDB;
     
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.ArchiveStatus(
		ArchiveID				INT
		, ArchiveName			VARCHAR(100)	
		, LastArchivedDate		DATETIME
        , UpdateDate			DATETIME				
    ) ENGINE=InnoDB;

    CREATE TABLE IF NOT EXISTS DCS_DataCenter.ArchiveHistory(
		ID						INT UNSIGNED AUTO_INCREMENT
        , ArchiveID				INT
        , ArchivedDate			DATETIME
        , StartTime				TIMESTAMP(4)
        , EndTime				TIMESTAMP(4)
        , Status				TINYINT
        
		, PRIMARY KEY	PK_ArchiveHistory_ID(ID)
    ) ENGINE=InnoDB;