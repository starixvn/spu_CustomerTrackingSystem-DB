/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231222@Casey.Huynh
Task:	 	Correct Islicensee
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211213@Casey.Huynh: Created [Redmine ID: #198667]
Reviewer:
#MAxCustID at Deploy Time 105854864
*/


USE CTS_Adhoc;

CREATE TABLE Casey198667_Super(
  SRecommend INT PRIMARY KEY
  , SubscriberID INT
  , IsLicensee BOOLEAN
  , IsCorrectData BOOLEAN
 );

CREATE TABLE Casey198667_Downline(
		DownlineID INT PRIMARY KEY
	,	DownlineIsLicensee  BOOLEAN
    , 	RoleID INT
    ,	SRecommend INT 
	, 	SuperIsLicensee BOOLEAN    
    );
#=========================================================================
#Noted MaxCTSCustID
SELECT MAX(CTSCustID) FROM CTS_DataCenter.CTSCustomer;  


# Get List Super has member wrong IsLicensee
INSERT INTO Casey198667_Super(SRecommend, SubscriberID)
SELECT SRecommend, SubscriberID
FROM CTS_DataCenter.CTSCustomer AS cus 
GROUP BY SRecommend, SubscriberID
HAVING COUNT(DISTINCT IsLicensee) > 1;

# Get info Super.IsLicensee and Super.IsCorrectData
UPDATE Casey198667_Super AS sup
INNER JOIN CTS_DataCenter.CTSCustomer AS cus  ON cus.CustID = sup.SRecommend AND cus.CustSubID = 0
INNER JOIN CTS_Admin.Subscriber AS sub ON sup.SubscriberID = sub.SubscriberID 
SET sup.IsCorrectData = (CASE WHEN cus.UserName LIKE '%test%'                                        
							OR cus.UserName LIKE '%Athena%'                                        
							OR cus.CurrencyID IN (20,27,28) 
							OR sub.subscriberStatus = -1 THEN 0 ELSE 1 END)
 , sup.IsLicensee = cus.IsLicensee;
 
SELECT * FROM Casey198667_Super WHERE sup.IsCorrectData = 1;

# Get Downline Need to Correct IsLicensee
INSERT INTO Casey198667_Downline(SRecommend,SuperIsLicensee, DownlineID, DownlineIsLicensee, RoleID)
SELECT sup.SRecommend, sup.IsLicensee, cus.CustID, cus.IsLicensee, cus.RoleID
FROM CTS_DataCenter.CTSCustomer cus
INNER JOIN Casey198667_Super AS sup ON cus.SRecommend = sup.SRecommend AND RoleID IN (1,2,3) AND CustSubID = 0
WHERE cus.IsLicensee <> sup.IsLicensee
	AND sup.IsCorrectData = 1;

SELECT * FROM Casey198667_Downline;

# UPDATE Downline Need to Correct IsLicensee
UPDATE CTS_DataCenter.CTSCustomer cus
INNER JOIN Casey198667_Downline AS dl ON cus.CustID = dl.DownlineID AND CustSubID = 0
SET cus.IsLicensee = dl.SuperIsLicensee;

#=========Check Data==============
SELECT cus.IsLicensee, dl.SuperIsLicensee, cus.*
FROM CTS_DataCenter.CTSCustomer cus
INNER JOIN Casey198667_Downline AS dl ON cus.CustID = dl.DownlineID AND CustSubID = 0;


#OUT_PUT Rescan CC
SELECT DownlineID AS custID
FROM Casey198667_Downline AS dl
WHERE RoleID = 1;