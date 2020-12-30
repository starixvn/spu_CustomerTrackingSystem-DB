/*
Created: 20201230@CaseyHuynh
Task: 	#135903, Update Data for MaxBet, Alpha (MainDB Issue, allow customer of (IBCIndo, AlphaIBCIndo) Site login to IBCIndo, AlphaIBCIndo)
DB: 	DCS_DataCenter, CTS_DataCenter
*/

###########################################################
USE CTS_Adhoc;
/*
#=======================================================================

SELECT *
FROM CTS_DataCenter.MappingSubscriberSite
WHERE SiteName = '76666B'; # SubscriberID (130,2), SiteID(547)

#=======================================================================
SELECT COUNT(1)
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547
 AND SubscriberID = 130;
 
INSERT INTO CTS_Adhoc.Iss135903_76666B_00CTSCustomer
SELECT cus.*
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547
 AND SubscriberID = 130;
#546 row(s) affected Records: 546 Duplicates: 0 Warnings: 0
#=======================================================================

SELECT COUNT(1)
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547
 AND SubscriberID = 2;
 
INSERT INTO CTS_Adhoc.Iss135903_76666B_00CTSCustomer
SELECT cus.*
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547
 AND SubscriberID = 2;

#260 row(s) affected Records: 260 Duplicates: 0 Warnings: 0


*/

#******Step 1: DCS_DataCenter.Account*****************************************************************************************************************
#*****************************************************************************************************************************************************
/**/

# Step 1a: Get Wrong Account Mapping by username

USE CTS_Adhoc;
TRUNCATE TABLE CTS_Adhoc.Iss135903_76666B_DCS_Account;
#==============================================================

INSERT INTO Iss135903_76666B_DCS_Account
SELECT acc.* 
 , 1 AS `MapByUserName`
 , NULL `CorrectedAccountID`
 , NULL `CorrectedSubscriberID`
 , 0 AS `ActType`
 , NULL
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_00CTSCustomer AS icus
 ON acc.LoginName = icus.UserName
 AND acc.SubscriberID IN (13658,13659)
; #186 row(s) affected Records: 186 Duplicates: 0 Warnings: 0

# Step 1b: Get Wrong Account Mapping by username2
#=======================================================================

INSERT INTO Iss135903_76666B_DCS_Account
SELECT acc.* 
 , 2 AS `MapByUserName`
 , NULL `CorrectedAccountID`
 , NULL `CorrectedSubscriberID`
 , 0 AS `ActType`
 , NULL
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_00CTSCustomer AS icus
 ON acc.LoginName = icus.UserName2
 AND acc.SubscriberID IN (13658,13659)
;# 1 row(s) affected Records: 1 Duplicates: 0 Warnings: 0

/* Check LastLoginTime
SELECT MAX(LastLoginTime)
FROM Iss135903_76666B_DCS_Account; #'2020-12-18 06:19:27.4848'
*/
#=======================================================================

UPDATE CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN DCS_DataCenter.Account AS acc
 ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 2 #IN (2,130) 
SET iacc.CorrectedAccountID = acc.AccountID
 , iacc.CorrectedSubscriberID = acc.SubscriberID
 , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE iacc.SubscriberID = 13659 #1 row(s) affected Rows matched: 1 Changed: 1 Warnings: 0
;
#=======================================================================

UPDATE CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN DCS_DataCenter.Account AS acc
 ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 130 
SET iacc.CorrectedAccountID = acc.AccountID
 , iacc.CorrectedSubscriberID = acc.SubscriberID
 , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE iacc.SubscriberID = 13658; #129 row(s) affected Rows matched: 129 Changed: 129 Warnings: 0
#=======================================================================
#*** Step 1d: UPDATE DATA DCS_DataCenter.Account: Correct Subscriber
SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
WHERE iacc.ActType = 0
 AND acc.SubscriberID IN (13658, 13659); #57

USE DCS_DataCenter;
UPDATE DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
SET acc.SubscriberID = (CASE WHEN acc.SubscriberID = 13658 THEN 130 ELSE 2 END)
WHERE iacc.ActType = 0
 AND acc.SubscriberID IN (13658, 13659);
#=======================================================================
 
#*** Step 1e: UPDATE DATA DCS_DataCenter.Account: Update LastLoginTime and Delete Account duplicate

SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON iacc.CorrectedAccountID = acc.AccountID 
WHERE iacc.ActType = -1
 AND acc.CreatedDate > iacc.CreatedDate; #80
 
USE DCS_DataCenter;
UPDATE DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON iacc.CorrectedAccountID = acc.AccountID
SET acc.CreatedDate = iacc.CreatedDate 
WHERE iacc.ActType = -1
 AND acc.CreatedDate > iacc.CreatedDate; 
#===================================================
SELECT 'ESTIMATE', COUNT(1)
from DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON iacc.CorrectedAccountID = acc.AccountID 
WHERE iacc.ActType = -1
 AND acc.LastLoginTime < iacc.LastLoginTime; #29 
 
USE DCS_DataCenter;
UPDATE DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON iacc.CorrectedAccountID = acc.AccountID 
SET acc.LastLoginTime = iacc.LastLoginTime
WHERE iacc.ActType = -1
 AND acc.LastLoginTime < iacc.LastLoginTime; 
 
#=============================
SELECT 'ESTIMATE', COUNT(1) 
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
WHERE iacc.ActType = -1; #130

USE DCS_DataCenter;
DELETE acc
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
WHERE iacc.ActType = -1;

#******Step 2: DCS_DataCenter.Association*************************************************************************************************************
#*****************************************************************************************************************************************************

# Step 2a: GET Associaton
#===================================================
SELECT 'ESTIMATE', COUNT(1) #179373
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON ass.AccountID = iacc.AccountID; #547

#===================================================
USE CTS_Adhoc;
TRUNCATE TABLE CTS_Adhoc.Iss135903_76666B_DCS_Association;

INSERT INTO CTS_Adhoc.Iss135903_76666B_DCS_Association 
SELECT ass.*, iacc.CorrectedAccountID, iacc.SubscriberID, 0 ActType
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON ass.AccountID = iacc.AccountID; #547 row(s) affected Records: 547  Duplicates: 0  Warnings: 0

SELECT 'ESTIMATE', COUNT(1) #179373
FROM	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
INNER JOIN DCS_DataCenter.Association AS ass
 ON iass.CorrectedAccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
WHERE iass.CorrectedAccountID IS NOT NULL; #153

UPDATE CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
INNER JOIN DCS_DataCenter.Association AS ass
 ON iass.CorrectedAccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
SET iass.ActType = -1
WHERE iass.CorrectedAccountID IS NOT NULL; #153 row(s) affected Rows matched: 153  Changed: 153  Warnings: 0


# Step 2b: UPDATE Associaton 
SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
WHERE iass.ActType = 0
 AND ass.SubscriberID IN (13658, 13659)
 AND iass.CorrectedAccountID IS NULL; #146

USE DCS_DataCenter;
UPDATE DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
SET ass.SubscriberID = (CASE WHEN ass.SubscriberID = 13659 THEN 2 ELSE 130 END)
WHERE iass.ActType = 0
 AND ass.SubscriberID IN (13659, 13658)
 AND iass.CorrectedAccountID IS NULL;

SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
WHERE iass.ActType = 0
 AND iass.CorrectedAccountID IS NOT NULL
 AND ass.SubscriberID IN (13659, 13658); #248 

USE DCS_DataCenter;
UPDATE DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
SET ass.SubscriberID = iass.CorrectedSubscriberID
	, ass.AccountID	= iass.CorrectedAccountID
WHERE iass.ActType = 0
 AND iass.CorrectedAccountID IS NOT NULL
 AND ass.SubscriberID IN (13659, 13658);

#Step 2C: UPDATE Associaton. Remove duplicate Association
SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
WHERE iass.ActType = -1; #153


USE DCS_DataCenter;
DELETE ass
FROM DCS_DataCenter.Association AS ass
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
 ON iass.AccountID = ass.AccountID
 AND iass.DeviceID = ass.DeviceID
WHERE iass.ActType = -1;

/*
SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Transaction07 AS tss
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON iacc.SubscriberID = tss.SubscriberID
 AND iacc.AccountID = tss.AccountID; #0
 ; 

SELECT *
FROM DCS_DataCenter.Transaction07 AS tss
ORDER BY TransID ASC
LIMIT 1; #1640210123 "2020-12-20 01:00:00.0052"*/
#******STEP 03: CTS_DataCenter.CustDCSAccount***************************************************************
#********************************************************************************************************
# Step 3a: 
SELECT 'ESTIMATE', COUNT(1)
FROM CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON cda.AccountID = iacc.AccountID
WHERE iacc.ActType = -1 #1
;
#======================================================================
USE CTS_DataCenter;
DELETE cda
FROM CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON cda.AccountID = iacc.AccountID
WHERE iacc.ActType = -1 
;

#======================================================================
SELECT 'ESTIMATE', COUNT(1)
FROM CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON cda.AccountID = iacc.AccountID #10545
WHERE iacc.ActType = 0 AND cda.SubscriberID IN (13659, 13658) ; #0


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON cda.AccountID = iacc.AccountID #10545
SET cda.SubscriberID = (CASE WHEN cda.SubscriberID =13659 THEN 2 ELSE 130 END)
WHERE iacc.ActType = 0 AND cda.SubscriberID IN (13659, 13658) ;
/*
SELECT 'ESTIMATE', COUNT(1)
FROM CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN CTS_DataCenter.CustDCSAccount AS cda
 ON iacc.AccountID = cda.AccountID 
WHERE iacc.ActType = 0; #0

INSERT INTO CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate
SELECT DISTINCT cda.CTSCustID, cda.SubscriberID
FROM CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN CTS_DataCenter.CustDCSAccount AS cda
 ON iacc.AccountID = cda.AccountID 
WHERE iacc.ActType = 0;

SELECT 'ESTIMATE', COUNT(1)
FROM CTS_DataCenter.AssociationByDevice AS abd 
INNER JOIN CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
 ON cus.CTSCustID = abd.CTSCustID 
WHERE abd.SubscriberID IN (13659, 13658) 
 ; #27166

SELECT distinct SubscriberID
FROM (
SELECT abd.CTSCustID, abd.SubscriberID
FROM CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
INNER JOIN CTS_DataCenter.AssociationByDevice AS abd
 ON cus.CTSCustID = abd.CTSCustID 
WHERE abd.SubscriberID IN (2, 130) )a; #31467 

UPDATE CTS_DataCenter.AssociationByDevice AS abd 
INNER JOIN CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
 ON cus.CTSCustID = abd.CTSCustID
SET abd.SubscriberID = (CASE WHEN cda.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE abd.SubscriberID IN (2, 130) 
 ;
*/
/*
SELECT 'ESTIMATE', COUNT(1)
FROM CTS_DataCenter.CTSCustomer AS cus
INNER JOIN ( SELECT CTSCustID, MAX(acc.LastLoginTime) AS LastLoginTime
 FROM CTS_DataCenter.CustDCSAccount AS cda
 INNER JOIN DCS_DataCenter.Account AS acc
 ON acc.AccountID = cda.AccountID
 INNER JOIN CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
 ON iacc.AccountID = acc.AccountID 
 WHERE iacc.ActType = -1
 GROUP BY cda.CTSCustID) AS grp
 ON cus.CTSCustID = grp.CTSCustID; #0


USE CTS_DataCenter;
UPDATE CTS_DataCenter.CTSCustomer AS cus
INNER JOIN ( SELECT CTSCustID, MAX(acc.LastLoginTime) AS LastLoginTime
 FROM CTS_DataCenter.CustDCSAccount AS cda
 INNER JOIN DCS_DataCenter.Account AS acc
 ON acc.AccountID = cda.AccountID
 INNER JOIN CTS_Adhoc.Iss135903_IBCIndo_DCS_Account AS iacc
 ON iacc.AccountID = acc.AccountID 
 WHERE iacc.ActType = -1
 GROUP BY cda.CTSCustID) AS grp
 ON cus.CTSCustID = grp.CTSCustID
SET cus.LastLoginTime = grp.LastLoginTime;

#=================================================================================
*/
#*** Step 1f: ReTransformed Account
SELECT 'ESTIMATE', COUNT(1)
FROM DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
WHERE acc.IsCTSTransformed < 0; #186

USE DCS_DataCenter;
UPDATE DCS_DataCenter.Account AS acc
INNER JOIN CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
 ON acc.AccountID = iacc.AccountID
SET acc.IsCTSTransformed = 0
WHERE acc.IsCTSTransformed < 0;

