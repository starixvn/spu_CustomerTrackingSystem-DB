/*
Creator: 20190521@John
Task:	 FPS Reform [Redmine ID: 105252]
Server:  
DBName:	ADCStagingRawTrans

Revisions: 
Reviewer: 
*/

CREATE DATABASE IF NOT EXISTS DCS_RawTransaction;

CREATE TABLE IF NOT EXISTS DCS_RawTransaction.RawTransaction(	
	LoginName					VARCHAR(100) CHARACTER SET UTF8MB4	NOT NULL	
	, SubscriberName			VARCHAR(50) 						NOT NULL
	, TransTime					TIMESTAMP(4)	 					NOT NULL
	, CreatedDate				DATETIME	 						NOT NULL	COMMENT 'Date Only'
	, DeviceCode				VARCHAR(62) 						NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
    , FingerprintCode			VARCHAR(2000)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
    , FingerprintMoreInfo		TEXT	CHARACTER SET UTF8MB4		NULL
    , UserAgent					TEXT		 						NULL
	, IP						VARCHAR(50) 						NULL
	, PluginID					BIGINT 								NULL	
	, URL						VARCHAR(500) 						NULL
	, ActionResult				VARCHAR(100) 						NULL
	, InvalidDevice				TEXT	CHARACTER SET UTF8MB4		NULL
    , TransStatus				BIT(16)								NULL	  COMMENT 	'Refer Table TransStatus'
    
    , IsProcessed				TINYINT								NOT	NULL	DEFAULT '0'
    , TransID					BIGINT	UNSIGNED AUTO_INCREMENT 	NOT NULL		

	, PRIMARY KEY PK_RawTransaction_StaingTransID(TransID)
	, INDEX IX_RawTransaction_IsProcessed(IsProcessed)
	, INDEX IX_RawTransaction_SubscriberName(SubscriberName,CreatedDate)
    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
