/*
Creator: 20190612@Casey
Task:	 DCS_RawTransaction Schema
Server:  
DBName:	 DCS_RawTransaction

Reviewer: 
*/

CREATE DATABASE IF NOT EXISTS DCS_RawTransaction;

CREATE TABLE IF NOT EXISTS DCS_RawTransaction.RawTransaction(
	LoginName					VARCHAR(100) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci' 	NOT NULL	
	, SubscriberName			VARCHAR(50) 						NOT NULL
	, TransTime					TIMESTAMP(4)	 					NOT NULL
	, CreatedDate				DATETIME	 						NOT NULL	COMMENT 'Date Only'
	, DeviceCode				VARCHAR(62) 						NULL		COMMENT 'DI DeviceCode: 32 characters is auto generated'
    , FingerprintCode			VARCHAR(2000)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
    , FingerprintMoreInfo		TEXT	CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'		NULL
    , UserAgent					TEXT		 						NULL
	, IP						VARCHAR(50) 						NULL
    , IPID						DECIMAL(50,0)						NULL
	, PluginID					BIGINT 								NULL	
	, URL						VARCHAR(500) 						NULL
    , Action					VARCHAR(100) 						NULL
	, ActionResult				VARCHAR(100) 						NULL
	, InvalidDevice				TEXT	CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'		NULL
    , TransStatus				BIT(16)								NULL	  COMMENT 	'Refer Table TransStatus'
) ENGINE=InnoDB;


