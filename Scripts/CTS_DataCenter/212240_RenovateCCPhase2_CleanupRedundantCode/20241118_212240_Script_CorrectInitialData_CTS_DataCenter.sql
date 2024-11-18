/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241118@Victoria.Le
	Task:		RenovateCC Phase 2 - Correct data initial - IsAffectToDownline (roleid = 1) and IsDisabled  (RobotImperva)
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241118@Victoria.Le:			Initial Writing [Redmine ID: #212240]
										- IsAffectToDownline (roleid = 1): TOTAL = 959
										- IsDisabled  (RobotImperva): TOTAL = 78
*/

USE CTS_DataCenter;

-- IsAffectToDownline (roleid = 1): TOTAL = 959 - Renovate CC Phase 2: incorrect initial
DROP TEMPORARY TABLE IF EXISTS Temp_CCMain_IsAffectToDownline;
CREATE TEMPORARY TABLE Temp_CCMain_IsAffectToDownline(
	CustID						BIGINT UNSIGNED
, 	CTSCustID					BIGINT UNSIGNED
,	SubscriberID 				INT UNSIGNED
,	RoleID						INT		
,	CategoryID		    		INT UNSIGNED
,	ParentID		    		INT UNSIGNED
,	IsAffectToDownline    		TINYINT(1)
,	PRIMARY KEY (CustID,CategoryID,ParentID)
);


INSERT INTO Temp_CCMain_IsAffectToDownline (CustID,CTSCustID,SubscriberID,RoleID,CategoryID,ParentID,IsAffectToDownline)
SELECT cust.CustID,cust.CTSCustID,cust.SubscriberID,cust.RoleID,cc.CategoryID,cc.ParentID,cc.IsAffectToDownline
FROM CTS_DataCenter.CTSCustomerClassification AS cc
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust on cust.CustID = cc.CustID AND cust.RoleID = 1
WHERE cc.ParentID IN (1000,20000) -- VVIP & PA
	AND cc.IsAffectToDownline = 1
;

-- SELECT * FROM Temp_CCMain_IsAffectToDownline;

UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
	INNER JOIN Temp_CCMain_IsAffectToDownline AS temp ON temp.CustID = cc.CustID AND temp.ParentID = cc.ParentID AND temp.CategoryID = cc.CategoryID
SET cc.IsAffectToDownline = 0
;


-- IsDisabled (RobotImperva): TOTAL = 78 - Renovate CC Phase 2: Missing update to this so that rescanning into RobotImperva is not possible after umark PA
DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva_IsDisabled;
CREATE TEMPORARY TABLE Temp_RobotImperva_IsDisabled(
	LogID 						BIGINT PRIMARY KEY
,	CustID						BIGINT UNSIGNED
,	IsDisabled 		    		TINYINT(1)
);

INSERT INTO Temp_RobotImperva_IsDisabled (LogID,CustID,IsDisabled)
SELECT r.LogID,r.CustID,r.IsDisabled
FROM CTS_DataCenter.RobotImperva AS r
	,LATERAL (SELECT cate.ParentID,cate.CustomerClassName,cate.CategoryID
			 FROM CTS_DataCenter.CTSCustomerClassification AS cc
				INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = cc.CategoryID
			 WHERE cc.CustID = r.CustID
				AND r.IsDisabled = 0
			 ORDER BY cate.CustomerClassPriority
			 LIMIT 1
			)AS latest
WHERE (latest.ParentID = 20000 AND latest.CustomerClassName <> 'Robot')
	OR latest.ParentID = 40000
;

DELETE temp
FROM Temp_RobotImperva_IsDisabled AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CustID = temp.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = cc.CategoryID
WHERE cate.CustomerClassName = 'Robot';

UPDATE CTS_DataCenter.RobotImperva AS r
	INNER JOIN Temp_RobotImperva_IsDisabled AS temp ON temp.LogID = r.LogID
SET r.IsDisabled = 1;