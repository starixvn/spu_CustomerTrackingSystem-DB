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
-- --------------------------------------------
/*STEP 1: Disable event*/
-- --------------------------------------------
ALTER EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF
	DISABLE;
    
ALTER EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_Update
	DISABLE;

-- --------------------------------------------
/*STEP 2: Check DIFF*/
-- --------------------------------------------
SELECT ParameterValue
INTO @lv_MinCTSCustID
FROM CTS_DataCenter.SystemParameter
WHERE ParameterID = 994;

SELECT ParameterValue
INTO @lv_MaxModifiedTime
FROM CTS_DataCenter.SystemParameter
WHERE ParameterID = 992;

SELECT MAX(CTSCustID)
INTO @lv_MaxCTSCustID
FROM CTSCustomer;

-- Victoria TO A.LONG >> IF @lv_MaxCTSCustID > lv_MinCTSCustID >> EXECUTE THE COMMAND BELOW
/*
	UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = @lv_MaxCTSCustID
	WHERE ParameterID = 994;
	
	UPDATE CTS_DataCenter.SystemEventStatus 
	SET 	Status = 'StartedUM' 
		,	LastExecTime = NOW()
	WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';

	CAll CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF(); 
	
	UPDATE CTS_DataCenter.SystemEventStatus 
	SET 	Status = 'StoppedUM'
		,	LastExecTime = NOW()
	WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';
	
	SELECT @lv_MinCTSCustID,@lv_MaxCTSCustID,@lv_MaxModifiedTime;
	
*/

-- --------------------------------------------
/*STEP 3: Rename and drop columns - CTSCustomerDuplicate - Total rows: 2,911 rows*/
-- --------------------------------------------
/*1. CTSCustomerDuplicate*/
/*TOTAL EXEC TIME: 0.016 sec*/
ALTER TABLE CTSCustomerDuplicate
	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;

/*TOTAL EXEC TIME: 0.140 sec*/
ALTER TABLE CTSCustomerDuplicate
	ADD COLUMN MRecommend INT AFTER SRecommend
,	ADD COLUMN Recommend INT AFTER MRecommend
;

/*TOTAL EXEC TIME: 0.140 sec*/
UPDATE CTSCustomerDuplicate
SET MRecommend = MRecommend_bk
, 	Recommend = Recommend_bk
;

/*TOTAL EXEC TIME: 2.125 sec*/
ALTER TABLE CTSCustomerDuplicate
	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;

/*2. CTSCustomer - Total rows: 120,797,508 rows*/
-- --------------------------------------------
/*STEP 4: DROP index - CTSCustomer*/
-- --------------------------------------------
/*TOTAL EXEC TIME: 4.750 sec*/
ALTER TABLE CTSCustomer
	DROP INDEX IX_CTSCustomer_MRecommend
,	DROP INDEX IX_CTSCustomer_Recommend
;

-- --------------------------------------------
/*STEP 5: Rename columns - CTSCustomer*/
-- --------------------------------------------
/*TOTAL EXEC TIME: 0.031 sec*/
ALTER TABLE CTSCustomer
	RENAME COLUMN MRecommend TO MRecommend_bk
,	RENAME COLUMN Recommend TO Recommend_bk
;

/*TOTAL EXEC TIME: 0.016 sec*/
ALTER TABLE CTSCustomer
	RENAME COLUMN MRecommend_new TO MRecommend
,	RENAME COLUMN Recommend_new TO Recommend
;

-- --------------------------------------------
/*STEP 6: ADD index - CTSCustomer*/
-- --------------------------------------------
/*TOTAL EXEC TIME: 1200 sec / 20 min*/
ALTER TABLE CTSCustomer
	ADD INDEX IX_CTSCustomer_MRecommend (MRecommend)
,	ADD INDEX IX_CTSCustomer_Recommend (Recommend)
;

-- --------------------------------------------
/*STEP 7: DROP columns - CTSCustomer - OPTIONAL*/
-- --------------------------------------------
/*TOTAL EXEC TIME: 6300 sec / 105 min / 1.75 hours*/
ALTER TABLE CTSCustomer
	DROP COLUMN MRecommend_bk
,	DROP COLUMN Recommend_bk
;