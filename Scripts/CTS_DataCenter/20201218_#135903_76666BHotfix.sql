###########################################################
USE CTS_Adhoc;
/*
SELECT * 
FROM 	CTS_Admin.Subscriber
WHERE 	SubscriberName = '76666B';

SELECT * 
FROM 	CTS_DataCenter.MappingSubscriberSite
WHERE 	SiteName = '76666B';

INSERT INTO CTS_Adhoc.Iss135903_76666B_00CTSCustomer
SELECT  cus.*
FROM 	CTS_DataCenter.CTSCustomer AS cus
WHERE 	SiteID = 547
		AND SubscriberID IN (130, 2);
#573 row(s) affected Records: 573  Duplicates: 0  Warnings: 0


*/

#******Step 1: DCS_DataCenter.Account*****************************************************************************************************************
#*****************************************************************************************************************************************************
/*
# Step 1a: Get Wrong Account Mapping by username
INSERT INTO Iss135903_76666B_DCS_Account
SELECT 	acc.* 
		, 1 AS 	`MapByUserName`
		, NULL	`CorrectedAccountID`
		, NULL 	`CorrectedSubscriberID`
		, 0 AS 	`ActType`
        , NULL
FROM		DCS_DataCenter.Account AS acc
INNER JOIN	CTS_Adhoc.Iss135903_76666B_00CTSCustomer AS icus
			ON acc.LoginName = icus.UserName
			AND acc.SubscriberID IN (13658,13659)
; #184 row(s) affected Records: 184  Duplicates: 0  Warnings: 0

# Step 1b: Get Wrong Account Mapping by username2

INSERT INTO Iss135903_76666B_DCS_Account
SELECT 	acc.* 
		, 2 AS 	`MapByUserName`
		, NULL	`CorrectedAccountID`
		, NULL 	`CorrectedSubscriberID`
		, 0 AS 	`ActType`
        , NULL
FROM		DCS_DataCenter.Account AS acc
INNER JOIN	CTS_Adhoc.Iss135903_76666B_00CTSCustomer AS icus
			ON acc.LoginName = icus.UserName2
			AND acc.SubscriberID IN (13658,13659)
;# 1 row(s) affected Records: 1  Duplicates: 0  Warnings: 0

UPDATE 		CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN	DCS_DataCenter.Account AS acc
			ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 2 #IN (2,130)		
SET 		iacc.CorrectedAccountID = acc.AccountID
			, iacc.CorrectedSubscriberID = acc.SubscriberID
            , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE		iacc.SubscriberID = 13659 #1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0
;
UPDATE 		CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN	DCS_DataCenter.Account AS acc
			ON iacc.LoginName = acc.LoginName AND acc.SubscriberID = 130		
SET 		iacc.CorrectedAccountID = acc.AccountID
			, iacc.CorrectedSubscriberID = acc.SubscriberID
            , iacc.ActType = -1 # Delete Account because duplicate Acc
WHERE		iacc.SubscriberID = 13658 #118 row(s) affected Rows matched: 118  Changed: 118  Warnings: 0
*/
#*** Step 1d: UPDATE DATA  DCS_DataCenter.Account: Correct Subscriber
SELECT 		acc.*
FROM		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
WHERE		iacc.ActType = 0
			AND acc.SubscriberID IN (13658, 13659);

USE 		DCS_DataCenter;
UPDATE 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
SET			acc.SubscriberID = (CASE WHEN acc.SubscriberID = 13658 THEN 130 ELSE 2 END)
WHERE		iacc.ActType = 0
			AND acc.SubscriberID IN (13658, 13659);
            
#*** Step 1e: UPDATE DATA  DCS_DataCenter.Account: Update LastLoginTime and Delete Account duplicate
#===================================================
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID   
WHERE		iacc.ActType = -1
			AND acc.CreatedDate > iacc.CreatedDate;  #71
     
USE 		DCS_DataCenter;
UPDATE 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID
SET 		acc.CreatedDate = iacc.CreatedDate       
WHERE		iacc.ActType = -1
			AND acc.CreatedDate > iacc.CreatedDate;            
#===================================================
SELECT 		'ESTIMATE', COUNT(1)
from		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID   
WHERE		iacc.ActType = -1
			AND acc.LastLoginTime < iacc.LastLoginTime;  #38            
            
USE 		DCS_DataCenter;
UPDATE 		DCS_DataCenter.Account AS acc
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.CorrectedAccountID = acc.AccountID   
SET			acc.LastLoginTime = iacc.LastLoginTime
WHERE		iacc.ActType = -1
			AND acc.LastLoginTime < iacc.LastLoginTime;  #38
            
#===================================================
USE 		DCS_DataCenter;
DELETE		acc
FROM		DCS_DataCenter.Account AS acc
INNER JOIN  CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1;

#******Step 2: DCS_DataCenter.Association*************************************************************************************************************
#*****************************************************************************************************************************************************

# Step 2a: GET Associaton
/*


SELECT 		'ESTIMATE', COUNT(1) #179373
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON ass.AccountID = iacc.AccountID; #542
            
INSERT INTO CTS_Adhoc.Iss135903_76666B_DCS_Association	
SELECT 		ass.*, iacc.CorrectedAccountID, iacc.SubscriberID, 0 ActType
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON ass.AccountID = iacc.AccountID;   #542 row(s) affected Records: 542  Duplicates: 0  Warnings: 0

UPDATE 		CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
INNER JOIN	DCS_DataCenter.Association AS ass
			ON iass.CorrectedAccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			iass.ActType = -1
WHERE		iass.CorrectedAccountID IS NOT NULL; #139 row(s) affected Rows matched: 139  Changed: 139  Warnings: 0

*/ 

# Step 2b: 	UPDATE Associaton   
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = 0
            AND ass.SubscriberID IN (13659, 13658)
            AND iass.CorrectedAccountID IS NULL; #163  
            
USE			DCS_DataCenter;
UPDATE		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			ass.SubscriberID = (CASE WHEN ass.SubscriberID = 13659 THEN 2 ELSE 130 END)
WHERE		iass.ActType = 0
            AND ass.SubscriberID IN (13659, 13658)
            AND iass.CorrectedAccountID IS NULL;

SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = 0
			AND iass.CorrectedAccountID IS NOT NULL
            AND ass.SubscriberID IN (13659, 13658); #240 

USE			DCS_DataCenter;
UPDATE		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
SET			ass.SubscriberID = iass.CorrectedSubscriberID
			, ass.AccountID = iass.CorrectedAccountID
WHERE		iass.ActType = 0
			AND iass.CorrectedAccountID IS NOT NULL
            AND ass.SubscriberID IN (13659, 13658);

#Step 2C: 	UPDATE Associaton. Remove duplicate Association
USE			DCS_DataCenter;
DELETE 		ass
FROM		DCS_DataCenter.Association AS ass
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Association AS iass
			ON iass.AccountID = ass.AccountID
            AND	iass.DeviceID = ass.DeviceID
WHERE		iass.ActType = -1;

/**/
SELECT 		'ESTIMATE', COUNT(1)
FROM		DCS_DataCenter.Transaction07 AS tss
INNER JOIN  CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.SubscriberID = tss.SubscriberID
				AND iacc.AccountID = tss.AccountID
WHERE		iacc.ActType = -1;
                ; #1235
                
SELECT 		tss.*
FROM		DCS_DataCenter.Transaction07 AS tss
INNER JOIN  CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.SubscriberID = tss.SubscriberID
				AND iacc.AccountID = tss.AccountID
WHERE		iacc.ActType = -1
ORDER BY 	TransID DESC;
                ; #1235
=d=d=fdkffkfkdfkfkfkf 
;
SELECT 		 tss.TransID, tss.TransTime ,acc.LoginName, SiteID, SiteName, urlDetails AS URL, tss.IP
FROM 		DCS_DataCenter.Transaction07 AS tss
INNER JOIN 	CTS_DataCenter.MappingSubscriberSite mss
			ON tss.SubscriberID = mss.SubscriberID
INNER JOIN 	DCS_DataCenter.Account AS acc
			ON tss.AccountID = acc.AccountID
INNER JOIN 	DCS_DataCenter.URL AS url
			ON tss.urlID = url.URLID	
WHERE 		tss.AccountID = 25876989 AND tss.SubscriberID = 13658
ORDER BY 	TransID DESC;

SELECT *
FROM 	



1632126739
1632125680
1631972647
1631896155


UPDATE		DCS_DataCenter.Transaction07 AS tss
INNER JOIN  CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON iacc.SubscriberID = tss.SubscriberID
				AND iacc.AccountID = tss.AccountID; #1235
*/

#******STEP 03: CTS_DataCenter.CustDCSAccount***************************************************************
#********************************************************************************************************
# Step 3a: 
SELECT 		'ESTIMATE', COUNT(1)
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1 #3708
;

DELETE 		cda
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
WHERE		iacc.ActType = -1 #3708
;
SELECT 		'ESTIMATE', COUNT(1)
FROM		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID #10545
WHERE		iacc.ActType = 0 
			AND CorrectedAccountID IS NULL#6837
;

USE			CTS_DataCenter;
UPDATE		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID #10545
SET			cda.SubscriberID = (CASE WHEN cda.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE		iacc.ActType = 0 AND abd.SubscriberID IN (2, 130) ;
/*
INSERT INTO CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate
SELECT 		DISTINCT cda.CTSCustID, cda.SubscriberID
FROM		CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
INNER JOIN	CTS_DataCenter.CustDCSAccount 	AS cda
			ON iacc.AccountID = cda.AccountID 
WHERE 		iacc.ActType = 0;
*/
SELECT 			'ESTIMATE', COUNT(1)
FROM			CTS_DataCenter.AssociationByDevice 	AS abd 
INNER JOIN		CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
				ON cus.CTSCustID = abd.CTSCustID    
WHERE			abd.SubscriberID IN (2, 130) 
                ; #27166

SELECT  distinct SubscriberID
FROM			(
SELECT			abd.CTSCustID, abd.SubscriberID
FROM			CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
INNER JOIN		CTS_DataCenter.AssociationByDevice 	AS abd
				ON cus.CTSCustID = abd.CTSCustID                
WHERE			abd.SubscriberID IN (2, 130) )a; #31467                

UPDATE 			CTS_DataCenter.AssociationByDevice 	AS abd 
INNER JOIN		CTS_Adhoc.Iss135903_76666B_CTS_CTSCustUpdate cus
				ON cus.CTSCustID = abd.CTSCustID
SET				abd.SubscriberID = (CASE WHEN cda.SubscriberID = 2 THEN 13659 ELSE 13658 END)
WHERE			abd.SubscriberID IN (2, 130) 
                ;


/*
DELETE		CTS_DataCenter.CustDCSAccount 	AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID;
*/

/*
SELECT 		cus.*, '---', cda.*, '---', iacc.*
FROM		CTS_DataCenter.CustDCSAccount AS cda
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON cda.AccountID = iacc.AccountID
INNER JOIN	CTS_DataCenter.CTSCustomer AS cus
			ON cda.CTSCustID = cus.CTSCustID	
WHERE		cus.SubscriberID = 169
            ;

SELECT 	*
FROM 	Iss135903_76666B_00CTSCustomer
WHERE 	CustID = 45897861;

SELECT *
FROM 	Iss135903_76666B_00CTSCustomer
WHERE UserName2 = 'SD9D450101C';

SELECT *
FROM 	Iss135903_76666B_00CTSCustomer
WHERE 	UserName = 'NO39BO339'; #44217321

SELECT 	*
FROM 	DCS_DataCenter.Account
WHERE	LoginName = 'NO39BO339' ;

SELECT *
FROM	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
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
INNER JOIN 	CTS_Adhoc.Iss135903_76666B_DCS_Account AS iacc
			ON acc.AccountID = iacc.AccountID
SET 		IsCTSTransformed = 0
WHERE		IsCTSTransformed < 0








*/

