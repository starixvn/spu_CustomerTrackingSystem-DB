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

/*1. CTSCustomer*/
-- ALTER TABLE CTSCustomer DISABLE KEYS;

ALTER TABLE CTSCustomer
	RENAME COLUMN SRecommend TO SRecommend_bk
,	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;


ALTER TABLE CTSCustomer
	ADD COLUMN SRecommend INT AFTER CurrencyID
,	ADD COLUMN MRecommend INT AFTER SRecommend
,	ADD COLUMN Recommend INT AFTER MRecommend
;


UPDATE CTSCustomer
SET SRecommend = SRecommend_bk
, 	MRecommend = MRecommend_bk
, 	Recommend = Recommend_bk
;


ALTER TABLE CTSCustomer
	DROP COLUMN SRecommend_bk
,	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;


ALTER TABLE CTSCustomer
	ADD INDEX IX_CTSCustomer_SRecommend (SRecommend)
,	ADD INDEX IX_CTSCustomer_MRecommend (MRecommend)
,	ADD INDEX IX_CTSCustomer_Recommend (Recommend)
;

-- ALTER TABLE CTSCustomer ENABLE KEYS;

ANALYZE TABLE CTSCustomer;

/*2. CTSCustomerDuplicate*/
-- ALTER TABLE CTSCustomerDuplicate DISABLE KEYS;

ALTER TABLE CTSCustomerDuplicate
	RENAME COLUMN SRecommend TO SRecommend_bk
,	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;


ALTER TABLE CTSCustomerDuplicate
	ADD COLUMN SRecommend INT AFTER CurrencyID
,	ADD COLUMN MRecommend INT AFTER SRecommend
,	ADD COLUMN Recommend INT AFTER MRecommend
;


UPDATE CTSCustomerDuplicate
SET SRecommend = SRecommend_bk
, 	MRecommend = MRecommend_bk
, 	Recommend = Recommend_bk
;


ALTER TABLE CTSCustomerDuplicate
	DROP COLUMN SRecommend_bk
,	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;

-- ALTER TABLE CTSCustomerDuplicate ENABLE KEYS;

ANALYZE TABLE CTSCustomerDuplicate;
