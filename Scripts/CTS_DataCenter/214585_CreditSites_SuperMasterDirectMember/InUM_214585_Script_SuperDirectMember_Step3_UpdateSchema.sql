/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241217@Victoria.Le
	Task:		Update schema - remove UNSIGNED from some columns in CTSCustomer & CTSCustomerDuplicate
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241217@Victoria.Le:			Initial Writing [Redmine ID: #214585]
*/

USE CTS_DataCenter;

ALTER EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF
	DISABLE;
    
ALTER EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_Update
	DISABLE;

/*1. CTSCustomerDuplicate*/
ALTER TABLE CTSCustomerDuplicate
	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;


ALTER TABLE CTSCustomerDuplicate
	ADD COLUMN MRecommend INT AFTER SRecommend
,	ADD COLUMN Recommend INT AFTER MRecommend
;


UPDATE CTSCustomerDuplicate
SET MRecommend = MRecommend_bk
, 	Recommend = Recommend_bk
;

ALTER TABLE CTSCustomerDuplicate
	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;


/*2. CTSCustomer*/
ALTER TABLE CTSCustomer
	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;

ALTER TABLE CTSCustomer
	RENAME COLUMN MRecommend_new TO MRecommend
,	RENAME COLUMN Recommend_new TO Recommend
;

ALTER TABLE CTSCustomer
	DROP INDEX IX_CTSCustomer_MRecommend
,	DROP INDEX IX_CTSCustomer_Recommend
;

ALTER TABLE CTSCustomer
	ADD INDEX IX_CTSCustomer_MRecommend (MRecommend)
,	ADD INDEX IX_CTSCustomer_Recommend (Recommend)
;

ALTER TABLE CTSCustomer
	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;