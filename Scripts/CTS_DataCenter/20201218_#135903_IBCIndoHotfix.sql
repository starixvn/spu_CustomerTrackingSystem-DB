/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 202012090@CaseyHuynh
Task: 	#135903, Update Data for IBCIndo (MainDB Issue, allow customer of (IBCIndo, AlphaIBCIndo) Site login to MaxBet, Alpha login(130,2) 
DB: 	DCS_DataCenter, CTS_DataCenter
*/

###########################################################
USE CTS_Adhoc;

#******Step 1: DCS_DataCenter.Account*****************************************************************************************************************
#*****************************************************************************************************************************************************
/*
# Step 1a: Get Wrong Account Mapping by username
INSERT INTO Iss135903_IBCIndo_DCS_Account
SELECT 	acc.* 
		, 1 AS 	`MapByUserName`
		, NULL	`CorrectedAccountID`
		, NULL 	`CorrectedSubscriberID`
		, 0 AS 	`ActType`
        , NULL
FROM		DCS_DataCenter.Account AS acc
INNER JOIN	CTS_Adhoc.Iss135903_IBCIndo_00MainDB AS icus
			ON acc.LoginName = icus.UserName
			AND acc.SubscriberID IN (2,130)
; #66971 row(s) affected Records: 66971  Duplicates: 0  Warnings: 0 ; 44.578s

# Step 1b: Get Wrong Account Mapping by username2
INSERT INTO Iss135903_IBCIndo_DCS_Account
SELECT 	acc.* 
		, 2 AS 	`MapByUserName`
		, NULL	`CorrectedAccountID`
		, NULL 	`CorrectedSubscriberID`
		, 0 AS 	`ActType`
        , NULL
FROM		DCS_DataCenter.Account AS acc
INNER JOIN	CTS_Adhoc.Iss135903_IBCIndo_00MainDB AS icus
			ON acc.LoginName = icus.UserName2
			AND acc.SubscriberID IN (2)
; #564 row(s) affected Records: 564  Duplicates: 0  Warnings: 0; 0.391

# Step 1c: Get Wrong Account Mapping by username2
INSERT INTO Iss135903_IBCIndo_DCS_Account
SELECT 	acc.* 
		, 2 AS 	`MapByUserName`
		, NULL	`CorrectedAccountID`
		, NULL 	`CorrectedSubscriberID`
		, 0 AS 	`ActType`
        , NULL
FROM		DCS_DataCenter.Account AS acc
INNER JOIN	CTS_Adhoc.Iss135903_IBCIndo_00MainDB AS icus
			ON acc.LoginName = icus.UserName2
			AND acc.SubscriberID IN (130)
; #0 row(s) affected Records: 0  Duplicates: 0  Warnings: 0 #0.25

UPDATE 		CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
INNER JOIN	DCS_DataCenter.Account AS acc
			ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 13659		
SET 		iacc.CorrectedAccountID = acc.AccountID
			, iacc.CorrectedSubscriberID = acc.SubscriberID
            , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE		iacc.SubscriberID = 2 #469 row(s) affected Rows matched: 469  Changed: 469  Warnings: 0
;

UPDATE 		CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
INNER JOIN	DCS_DataCenter.Account AS acc
			ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 13658		
SET 		iacc.CorrectedAccountID = acc.AccountID
			, iacc.CorrectedSubscriberID = acc.SubscriberID
            , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE		iacc.SubscriberID = 130 #43335 row(s) affected Rows matched: 43335  Changed: 43335  Warnings: 0
;
*/
#*** Step 1d: UPDATE DATA  DCS_DataCenter.Account: Correct Subscriber
SELECT 		'ESTIMATE', COUNT(1)
FROM 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
WHERE		iacc.ActType = 0
			AND acc.SubscriberID IN (2, 130); #23731

USE 		DCS_DataCenter;
UPDATE 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
SET			acc.SubscriberID = (CASE WHEN acc.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE		iacc.ActType = 0
			AND acc.SubscriberID IN (2, 130);
#*** Step 1e: UPDATE DATA  DCS_DataCenter.Account: Update LastLoginTime and Delete Account duplicate
#===========================================================
SELECT 		'ESTIMATE', COUNT(1)
from		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID   
WHERE		iacc.ActType = -1
			AND acc.CreatedDate > iacc.CreatedDate;  #10797
            
USE 		DCS_DataCenter;
UPDATE 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID
SET 		acc.CreatedDate = iacc.CreatedDate       
WHERE		iacc.ActType = -1
			AND acc.CreatedDate > iacc.CreatedDate;            
#===========================================================
SELECT 		'ESTIMATE', COUNT(1)
from		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID   
WHERE		iacc.ActType = -1
			AND acc.LastLoginTime < iacc.LastLoginTime;  #10863
            
USE 		DCS_DataCenter;
UPDATE		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID
SET			acc.LastLoginTime = iacc.LastLoginTime
WHERE		iacc.ActType = -1
			AND acc.LastLoginTime < iacc.LastLoginTime;  #10863
#===========================================================
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Account AS acc
INNER JOIN  CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1; #43804

USE 		DCS_DataCenter;
DELETE		acc
FROM		DCS_DataCenter.Account AS acc
INNER JOIN  CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1;

#******Step 2: DCS_DataCenter.Association*************************************************************************************************************
#*****************************************************************************************************************************************************

# Step 2a: GET Associaton
/*
USE 		CTS_Adhoc;

SELECT 		'ESTIMATE', COUNT(1) #179373
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON ass.AccountID = iacc.AccountID;
            
INSERT INTO Iss135903_IBCIndo_DCS_Association	
SELECT 		ass.*, iacc.CorrectedAccountID, iacc.SubscriberID, 0 ActType
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON ass.AccountID = iacc.AccountID;          
     
USE 		CTS_Adhoc;
UPDATE 		CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
INNER JOIN	DCS_DataCenter.Association AS ass
			ON iass.CorrectedAccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			iass.ActType = -1
WHERE		iass.CorrectedAccountID IS NOT NULL;
*/ 
#===========================================================
# Step 2b: 	UPDATE Associaton   
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = 0
			AND ass.SubscriberID IN (2, 130)
			AND iass.CorrectedAccountID IS NULL; #45818
    
USE			DCS_DataCenter;
UPDATE		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			ass.SubscriberID = (CASE WHEN ass.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE		iass.ActType = 0
            AND ass.SubscriberID IN (2, 130)
            AND iass.CorrectedAccountID IS NULL;
#===========================================================
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = 0
			AND iass.CorrectedAccountID IS NOT NULL; #61852 

USE			DCS_DataCenter;
UPDATE		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			ass.SubscriberID = iass.CorrectedSubscriberID
			, ass.AccountID = iass.CorrectedAccountID
WHERE		iass.ActType = 0
			AND iass.CorrectedAccountID IS NOT NULL;
#===========================================================
#Step 2C: 	UPDATE Associaton. Remove duplicate Association
USE			DCS_DataCenter;
DELETE 		ass
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = -1;

/*
SELECT 		COUNT(1)
FROM		CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
INNER JOIN  DCS_DataCenter.Transaction07 AS tss
			ON iacc.SubscriberID = tss.SubscriberID
				AND iacc.AccountID = tss.AccountID; #0

SELECT MAX(LastLoginTime)
FROM CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iass; #2020-11-12 04:30:14.7448
*/

#******STEP 03: CTS_DataCenter.CustDCSAccount***************************************************************
#********************************************************************************************************
# Step 3a: Update CTS_DataCenter.CustDCSAccount
SELECT 		'ESTIMATE', COUNT(1)
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1 #3708
;
USE			CTS_DataCenter;
DELETE 		cda
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1 #3708
;
#===========================================================
SELECT 		'ESTIMATE', COUNT(1)
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID #10545
WHERE		iacc.ActType = 0 
			AND CorrectedAccountID IS NULL; #6837

USE			CTS_DataCenter;
UPDATE		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID #10545
SET			cda.SubscriberID = (CASE WHEN cda.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE		iacc.ActType = 0 AND abd.SubscriberID IN (2, 130) ;
#===========================================================
	
/*
INSERT INTO CTS_Adhoc.Iss135903_IBCIndo_CTS_CTSCustUpdate
SELECT 		DISTINCT cda.CTSCustID, cda.SubscriberID
FROM		CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
INNER JOIN	CTS_DataCenter.CustDCSAccount 	AS cda
			ON iacc.AccountID = cda.AccountID 
WHERE 		iacc.ActType = 0;
*/
SELECT 			'ESTIMATE', COUNT(1)
FROM			CTS_DataCenter.AssociationByDevice 	AS abd 
INNER JOIN		CTS_Adhoc.Iss135903_IBCIndo_CTS_CTSCustUpdate cus
				ON cus.CTSCustID = abd.CTSCustID    
WHERE			abd.SubscriberID IN (2, 130) 
                ; #27166

USE				CTS_DataCenter;
UPDATE 			CTS_DataCenter.AssociationByDevice 	AS abd 
INNER JOIN		CTS_Adhoc.Iss135903_IBCIndo_CTS_CTSCustUpdate cus
				ON cus.CTSCustID = abd.CTSCustID
SET				abd.SubscriberID = (CASE WHEN cda.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE			abd.SubscriberID IN (2, 130) 
                ;

SELECT		'ESTIMATE', COUNT(1)
FROM		CTS_DataCenter.CTSCustomer 		AS cus
INNER JOIN  (	SELECT 	CTSCustID, MAX(acc.LastLoginTime) 	AS LastLoginTime
				FROM 	CTS_DataCenter.CustDCSAccount		AS cda
				INNER JOIN 	DCS_DataCenter.Account			AS acc
							ON  acc.AccountID = cda.AccountID
				INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account			AS iacc
							ON  iacc.AccountID = acc.AccountID				
				WHERE 		iacc.ActType = -1
				GROUP BY	cda.CTSCustID) AS grp
			ON cus.CTSCustID = grp.CTSCustID; #3708 row(s) returned, 0.172 sec / 0.000 sec


USE				CTS_DataCenter;
UPDATE 		CTS_DataCenter.CTSCustomer 		AS cus
INNER JOIN  (	SELECT 	CTSCustID, MAX(acc.LastLoginTime) 	AS LastLoginTime
				FROM 	CTS_DataCenter.CustDCSAccount		AS cda
				INNER JOIN 	DCS_DataCenter.Account			AS acc
							ON  acc.AccountID = cda.AccountID
				INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account			AS iacc
							ON  iacc.AccountID = acc.AccountID				
				WHERE 		iacc.ActType = -1
				GROUP BY	cda.CTSCustID) AS grp
			ON cus.CTSCustID = grp.CTSCustID
SET			cus.LastLoginTime = grp.LastLoginTime;

/*
SELECT 		cus.*, '---', cda.*, '---', iacc.*
FROM		CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
INNER JOIN	CTS_DataCenter.CTSCustomer AS cus
			ON cda.CTSCustID = cus.CTSCustID	
WHERE		cus.SubscriberID = 169
            ;

SELECT 	*
FROM 	Iss135903_IBCIndo_00MainDB
WHERE 	CustID = 45897861;

SELECT *
FROM 	Iss135903_IBCIndo_00MainDB
WHERE UserName2 = 'SD9D450101C';

SELECT *
FROM 	Iss135903_IBCIndo_00MainDB
WHERE 	UserName = 'NO39BO339'; #44217321

SELECT 	*
FROM 	DCS_DataCenter.Account
WHERE	LoginName = 'NO39BO339' ;

SELECT *
FROM	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
WHERE	AccountID = 19614190;
SELECT 	*
FROM 	CTS_DataCenter.CustDCSAccount AS cda
WHERE	cda.AccountID = 19614190;

SELECT * FROM CTS_DataCenter.CTSCustomer AS cus
WHERE	CTSCustID IN (45432892,42881235);

SELECT 	*
FROM 	DCS_DataCenter.Account
WHERE	LoginName = 'SD9D450101C' ;

SELECT 	*
FROM 	CTS_DataCenter.CustDCSAccount AS cda
WHERE	cda.AccountID = 19614197; 45432892

#=================================================================================
*/
#*** Step 1f: ReTransformed Account

USE 		DCS_DataCenter;
UPDATE  	DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
SET 		IsCTSTransformed = 0
WHERE		IsCTSTransformed < 0







