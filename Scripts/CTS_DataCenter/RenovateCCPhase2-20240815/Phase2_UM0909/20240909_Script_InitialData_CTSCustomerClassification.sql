/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Initial Data CTSCustomerClassification
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
									Tables:
										1. SpecialCustomerClass
										2. SpecialCustomerClass_BySport
										3. CTSCustomerClassification - Current: CC = VVIP - From CTSCustomerClassificationVVIP | CTSCustomerClassificationOldCategory
										4. CTSCustomerClassification - Current: CC = PA - From CTSCustomerClassificationOldCategory
										5. RobotDetection - Update IsDisable = 1 - Customers have been archived
										6. RobotImperva - Update IsDisable = 1 - Customers have been archived
										7. TWRobotUser/CTSRobotUser - From CTSCustomerClassification: IsFromTW/IsFromCTS = 1
										8. 
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

/*Initial variable*/
SET @CONST_CATEID_VVIP 				:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
SET @CONST_CATEID_SPECIALCC 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
SET @CONST_CATEGROUPID_RISKY 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_RISKY');
SET @CONST_CATEGROUPID_SMART 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SMART');
SET @CONST_PARENTID_WRAPPER 		:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
SET @CONST_PARENTID_NORMAL 			:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
SET @CONST_PARENTID_PA 				:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');

---------------------------------
/*1. SpecialCustomerClass - 20240827: 158 cust*/
---------------------------------

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_SpecialCC;    
CREATE TEMPORARY TABLE Temp_Customer_SpecialCC(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	SubscriberID			INT 
	,	RoleID					INT 
	,	CreatedDate				DATETIME 
	,	LastModifiedBy			INT 
	,	LastModifiedDate		DATETIME 
	,	LastScannedDate			DATETIME 
	,	Remark					VARCHAR(500) 
	,	PRIMARY KEY (CTSCustID,CustID)
);

INSERT INTO Temp_Customer_SpecialCC (CTSCustID, CustID, SubscriberID, RoleID, CreatedDate, LastModifiedBy, LastScannedDate, Remark)
SELECT sp.CTSCustID, sp.CustID, cust.SubscriberID, cust.RoleID, sp.CreatedDate, sp.LastModifiedBy, sp.LastScannedDate, sp.Remark
FROM SpecialCustomerClass as sp
	INNER JOIN CTSCustomer as cust on cust.CTSCustID = sp.CTSCustID
WHERE NOT EXISTS (SELECT 1 FROM CTSCustomerClassification AS cc WHERE cc.CTSCustID = sp.CTSCustID AND cc.CategoryID = @CONST_CATEID_VVIP) 
;

INSERT INTO CTS_DataCenter.CTSCustomerClassification (
		CustID, CTSCustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy
	, 	LastModifiedDate, LastModifiedBy, LastScannedDate, Remark)
SELECT  temp.CustID
	, 	temp.CTSCustID
	,	temp.SubscriberID
	,	temp.RoleID
	,	@CONST_PARENTID_WRAPPER AS ParentID
	,	@CONST_CATEID_SPECIALCC AS CategoryID
	, 	temp.CreatedDate
	, 	temp.LastModifiedBy AS CreatedBy
	, 	NOW() AS LastModifiedDate
	, 	temp.LastModifiedBy
	, 	temp.LastScannedDate
	, 	temp.Remark
FROM Temp_Customer_SpecialCC AS temp;

---------------------------------
/*2. SpecialCustomerClass_BySport - 20240827: 0 cust*/
---------------------------------

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_SpecialCC_BySport;    
CREATE TEMPORARY TABLE Temp_Customer_SpecialCC_BySport(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	SportID					SMALLINT 
	,	CreatedDate				DATETIME 
	,	LastModifiedBy			INT 
	,	LastModifiedDate		DATETIME 
	,	LastScannedDate			DATETIME 
	,	Remark					VARCHAR(500) 
	,	PRIMARY KEY (CTSCustID,CustID,SportID)
);

INSERT INTO Temp_Customer_SpecialCC_BySport (CTSCustID, CustID, SportID, CreatedDate, LastModifiedBy, LastScannedDate, Remark)
SELECT sp.CTSCustID, sp.CustID, sp.SportID, sp.CreatedDate, sp.LastModifiedBy, sp.LastScannedDate, sp.Remark
FROM SpecialCustomerClass_BySport as sp
	INNER JOIN CTSCustomer as cust on cust.CTSCustID = sp.CTSCustID 
;

INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (
		CustID, CTSCustID, SportID, ParentID, CategoryID, CreatedDate, CreatedBy
	, 	LastModifiedDate, LastModifiedBy, LastScannedDate)
SELECT DISTINCT 
		temp.CustID
	, 	temp.CTSCustID
	, 	temp.SportID
	,	@CONST_PARENTID_WRAPPER AS ParentID
	, 	@CONST_CATEID_SPECIALCC AS CategoryID
	, 	temp.CreatedDate
	, 	temp.LastModifiedBy AS CreatedBy
	, 	NOW() AS LastModifiedDate
	, 	temp.LastModifiedBy
	, 	temp.LastScannedDate
FROM Temp_Customer_SpecialCC_BySport AS temp;

---------------------------------
/*3. CTSCustomerClassification - Current: CC = VVIP - From CTSCustomerClassificationVVIP | CTSCustomerClassificationOldCategory*/
---------------------------------

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_VVIP;    
CREATE TEMPORARY TABLE Temp_Customer_VVIP(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	RoleID					INT 
	,	IsMarkedDirectly		TINYINT(1)
	,	IsAffectToDownline 		TINYINT(1) 
	,	PRIMARY KEY (CTSCustID,CustID)
);

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_VVIP_Old;    
CREATE TEMPORARY TABLE Temp_Customer_VVIP_Old(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	RoleID					INT 
	,	SubscriberID			INT 
	,	ParentID 				INT
	,	CategoryID 				INT
	,	Remark					VARCHAR(500) 
	,	CreatedDate				DATETIME
	,	CreatedBy				BIGINT
	,	LastModifiedDate		DATETIME
	,	LastModifiedBy			BIGINT
	,	LastScannedDate			DATETIME
	,	IsFromTVS				TINYINT(1)
	,	IsFromCTS				TINYINT(1)
	,	IsFromAI				TINYINT(1)
	,	IsMarkedDirectly		TINYINT(1)
	,	IsFromImperva			TINYINT(1)
	,	IsParlay				TINYINT(1)
	,	TVSRequestID			BIGINT
	,	IssueTypeId				BIGINT
	,	SportType				SMALLINT
	,	IsRobot					TINYINT(1)
	,	IsInsertSource			TINYINT(1)
	,	PRIMARY KEY (CustID,ParentID,CategoryID)
);


INSERT INTO Temp_Customer_VVIP (CTSCustID, CustID, RoleID, IsMarkedDirectly, IsAffectToDownline)
SELECT cc.CTSCustID, cc.CustID, cc.RoleID, IFNULL(cc.IsDirect,1), cc.IsAffectToDownline
FROM CTSCustomerClassification AS cc
	INNER JOIN CTSCustomerClassificationVVIP AS sp ON cc.CustID = sp.CustID 
	INNER JOIN CTSCustomer AS cust ON cust.CustID = sp.CustID 
where cc.CategoryID = @CONST_CATEID_VVIP
;

INSERT INTO Temp_Customer_VVIP_Old (CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsFromTVS, IsFromCTS, IsFromAI, IsMarkedDirectly, IsFromImperva, IsParlay, TVSRequestID, IssueTypeId, SportType)
SELECT oc.CTSCustID, oc.CustID, c.RoleID, oc.SubscriberID, cate.ParentID, cate.CategoryID, oc.Remark, oc.CreatedDate, oc.CreatedBy, oc.LastModifiedDate, oc.LastModifiedBy
	, oc.LastScannedDate, oc.IsFromTVS, oc.IsFromCTS, oc.IsFromAI, oc.IsDirect, oc.IsFromImperva, oc.IsParlay, oc.TVSRequestID, oc.IssueTypeId, oc.SportType
	, CASE WHEN cate.CustomerClass = 'Robot' THEN 1 ELSE 0 END AS IsRobot
	, CASE WHEN cate.ParentID = @CONST_PARENTID_PA AND cate.CustomerClass <> 'Robot' AND oc.IsFromTVS = 1 THEN 1 ELSE 0 END AS IsInsertSource
FROM Temp_Customer_VVIP AS c
	INNER JOIN CTSCustomerClassificationOldCategory AS oc ON oc.CustID = c.CustID
	INNER JOIN CustomerCategory AS cate ON cate.OldCategoryID = oc.CategoryID AND cate.IsActive = 1
WHERE cate.ParentID = @CONST_PARENTID_NORMAL AND cate.CategoryGroupID IN (@CONST_CATEGROUPID_SMART,@CONST_CATEGROUPID_RISKY)
	OR (cate.ParentID = @CONST_PARENTID_PA AND cate.CustomerClass = 'Robot' AND oc.IsFromCTS = 1)
	OR (cate.ParentID = @CONST_PARENTID_PA AND cate.CustomerClass <> 'Robot' AND (oc.IsFromCTS = 1 OR oc.IsFromTVS = 1))
;

UPDATE CTSCustomerClassification AS cc
	INNER JOIN Temp_Customer_VVIP AS c ON c.CustID = cc.CustID
SET 	cc.RoleID = c.RoleID
	,	cc.IsAffectToDownline = c.IsAffectToDownline
	,	cc.IsMarkedDirectly = c.IsMarkedDirectly
WHERE cc.CategoryID = @CONST_CATEID_VVIP;


INSERT INTO CTSCustomerClassification (CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsFromTVS, IsFromCTS, IsFromAI, IsMarkedDirectly, IsFromImperva, IsParlay, TVSRequestID, IssueTypeId, SportType)
SELECT CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsFromTVS, IsFromCTS, IsFromAI, IsMarkedDirectly, IsFromImperva, IsParlay, TVSRequestID, IssueTypeId, SportType
FROM Temp_Customer_VVIP_Old;

INSERT INTO CTSRobotUser (CustID, CategoryID, Remark, CreatedDate, InsertedTime)
SELECT CustID, CategoryID, Remark, CreatedDate, NOW()
FROM Temp_Customer_VVIP_Old
WHERE IsRobot = 1;


INSERT INTO TVSVoidRequest (TVSRequestID, CustID, CategoryID, TVSReasonID, IssueTypeID, CreatedBy, IsParlay, SportType, RequestTypeID, CreatedDate, InsertedTime)
SELECT o.TVSRequestID, o.CustID, o.CategoryID, h.TVSReasonID, o.IssueTypeID, o.CreatedBy, o.IsParlay, o.SportType, 1, o.CreatedDate, NOW()
FROM Temp_Customer_VVIP_Old AS o
	LEFT JOIN TVSVoidRequest_History AS h ON h.TVSReasonID = o.TVSReasonID
WHERE o.IsInsertSource = 1;

---------------------------------
/*4. CTSCustomerClassification - Current: CC = PA - From CTSCustomerClassificationOldCategory*/
---------------------------------

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_PA_Old;    
CREATE TEMPORARY TABLE Temp_Customer_PA_Old(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	RoleID					INT 
	,	SubscriberID			INT 
	,	ParentID 				INT
	,	CategoryID 				INT
	,	Remark					VARCHAR(500) 
	,	CreatedDate				DATETIME
	,	CreatedBy				BIGINT
	,	LastModifiedDate		DATETIME
	,	LastModifiedBy			BIGINT
	,	LastScannedDate			DATETIME
	,	IsMarkedDirectly		TINYINT(1)
	,	PRIMARY KEY (CustID,ParentID,CategoryID)
);

INSERT INTO Temp_Customer_PA_Old (CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsMarkedDirectly)
SELECT DISTINCT oc.CTSCustID, oc.CustID, cust.RoleID, oc.SubscriberID, cate.ParentID, cate.CategoryID, oc.Remark, oc.CreatedDate, oc.CreatedBy, oc.LastModifiedDate, oc.LastModifiedBy
	, oc.LastScannedDate, oc.IsDirect
FROM CTSCustomerClassification AS c
	INNER JOIN CTSCustomer as cust on cust.CustID = c.CustID 
	INNER JOIN CTSCustomerClassificationOldCategory AS oc ON oc.CustID = c.CustID
	INNER JOIN CustomerCategory AS cate ON cate.OldCategoryID = oc.CategoryID AND cate.IsActive = 1
WHERE c.ParentID = @CONST_PARENTID_PA
	AND cate.ParentID = @CONST_PARENTID_NORMAL AND cate.CategoryGroupID IN (@CONST_CATEGROUPID_SMART,@CONST_CATEGROUPID_RISKY)
;

INSERT INTO CTSCustomerClassification (CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsMarkedDirectly)
SELECT CTSCustID, CustID, RoleID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
	, LastScannedDate, IsMarkedDirectly
FROM Temp_Customer_PA_Old;

---------------------------------
/* 5. RobotDetection - Update IsDisable = 1 - Customers have been archived */
---------------------------------

DROP TEMPORARY TABLE IF EXISTS Temp_RobotDetection;    
CREATE TEMPORARY TABLE Temp_RobotDetection(	  
		ID						BIGINT PRIMARY KEY
	,	CustID					BIGINT 
	,	IsUpdated				TINYINT(1) DEFAULT 0
);

INSERT INTO Temp_RobotDetection (ID, CustID)
SELECT rd.ID, rd.CustID
FROM RobotDetection AS rd
	LEFT JOIN CTSCustomer as cust on cust.CustID = rd.CustID
WHERE cust.CustID IS NULL AND rd.IsDisabled = 0
;

DROP TEMPORARY TABLE IF EXISTS Temp_RobotDetection_Duplicate;
CREATE TEMPORARY TABLE Temp_RobotDetection_Duplicate LIKE Temp_RobotDetection;


UPDATE Temp_RobotDetection AS rd
	INNER JOIN Temp_RobotDetection_Duplicate AS temp ON temp.CustID = rd.CustID
	,	LATERAL (
			SELECT ar.IsReactivated 
			FROM ArchiveCustomer_CTSCustomer AS ar
			WHERE ar.CustID = temp.CustID
			ORDER BY ar.InsertTime DESC, ar.ID DESC
			LIMIT 1
		) AS latest
SET rd.IsUpdated = 1
WHERE latest.IsReactivated = 0
;

UPDATE RobotDetection AS rd
	INNER JOIN Temp_RobotDetection AS temp ON temp.ID = rd.ID
SET rd.IsDisabled = 1
WHERE temp.IsUpdated = 1
;

---------------------------------
/* 6. RobotImperva - Update IsDisable = 1 - Customers have been archived */
---------------------------------
DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva;    
CREATE TEMPORARY TABLE Temp_RobotImperva(	  
		LogID 					BIGINT PRIMARY KEY
	,	CustID					BIGINT 
	,	IsUpdated				TINYINT(1) DEFAULT 0
);

INSERT INTO Temp_RobotImperva (LogID, CustID)
SELECT rd.LogID, rd.CustID
FROM RobotImperva AS rd
	LEFT JOIN CTSCustomer as cust on cust.CustID = rd.CustID
WHERE cust.CustID IS NULL AND rd.IsDisabled = 0
;

DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva_Duplicate;
CREATE TEMPORARY TABLE Temp_RobotImperva_Duplicate LIKE Temp_RobotImperva;


UPDATE Temp_RobotImperva AS rd
	INNER JOIN Temp_RobotImperva_Duplicate AS temp ON temp.CustID = rd.CustID
	,	LATERAL (
			SELECT ar.IsReactivated 
			FROM ArchiveCustomer_CTSCustomer AS ar
			WHERE ar.CustID = temp.CustID
			ORDER BY ar.InsertTime DESC, ar.LogID DESC
			LIMIT 1
		) AS latest
SET rd.IsUpdated = 1
WHERE latest.IsReactivated = 0
;

UPDATE RobotImperva AS rd
	INNER JOIN Temp_RobotImperva AS temp ON temp.LogID = rd.LogID
SET rd.IsDisabled = 1
WHERE temp.IsUpdated = 1
;

---------------------------------
/* 7. TWRobotUser/CTSRobotUser - From CTSCustomerClassification: IsFromTW/IsFromCTS = 1 */
---------------------------------
INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (994, 'Adhoc_Renovate_Phase2_Robot_InitialData', 'Initial Data - ID - Table History','BIGINT',?)
;

CALL CTS_DataCenter.Adhoc_Renovate_Phase2_Robot_InitialData (ip_Batchsize,ip_MinID,@NextID);
SELECT @NextID;

CALL CTS_DataCenter.Adhoc_Renovate_Phase2_Robot_InitialData (ip_Batchsize,@NextID,@NextID);
CALL CTS_DataCenter.Adhoc_Renovate_Phase2_Robot_InitialData (ip_Batchsize,@NextID,@NextID);

---------------------------------
---------------------------------
---------------------------------
---------------------------------
---------------------------------
