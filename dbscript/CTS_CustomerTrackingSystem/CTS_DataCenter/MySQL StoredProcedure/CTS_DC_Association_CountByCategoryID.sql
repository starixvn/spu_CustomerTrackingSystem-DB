/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_CountByCategoryID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_CountByCategoryID`(
		IN 	ip_ListCustID 			LONGTEXT
	,	IN 	ip_ListCategoryID 		LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221118@Aries.Nguyen
		Task :		Support suspicious Irrigation in Match Monitor
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20221118@Aries.Nguyen: 	Created [Redmine ID: #179499]
			- 	20230112@Victoria.Le: 	Modify SPs due to restructure AssociationByAI [Redmine ID: #181994]
            -	20230313@Casey.Huynh:	Applied Betting Parten OTGB [Redmine ID: #184791]
            
		Param's Explanation (filtered by):
			CALL CTS_DC_Association_CountByCategoryID('169686,169689,894977','201,205')
		Example:
        
	*/
	DECLARE CONST_ASSTYPE_BETTINGPATTERN 	INT DEFAULT 2;
	DECLARE CONST_ASSBYAI_ACTIVESTATUS 		INT DEFAULT 1;
	#=============================================================================
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustParam;
    CREATE TEMPORARY TABLE Temp_CustParam (
        	CTSCustID 		BIGINT UNSIGNED PRIMARY KEY 
		,	CustID			BIGINT UNSIGNED  
		,	INDEX			IX_Temp_CustInfo_CustID(CustID)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CategoryID;
    CREATE TEMPORARY TABLE 		Temp_CategoryID (
        	CategoryID			INT PRIMARY KEY 
    );  
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustClass;
    CREATE TEMPORARY TABLE Temp_CustClass (
			CustID					BIGINT UNSIGNED
		,	CustID_Level1			BIGINT UNSIGNED 
        ,	PRIMARY KEY(CustID, CustID_Level1)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByAI_AssType (
		AssTypeItemValue INT PRIMARY KEY            
	);
    
	#===========GET AssociationByAI status is Applied==============================================    
	INSERT INTO Temp_AssociationByAI_AssType(AssTypeItemValue)
	SELECT atd.AssTypeItemValue
	FROM CTS_DataCenter.AssociationTypeSetting AS atd
	WHERE atd.AssTypeID = CONST_ASSTYPE_BETTINGPATTERN AND atd.AssTypeItemStatus = CONST_ASSBYAI_ACTIVESTATUS;
    
    INSERT IGNORE INTO Temp_CustParam(CustID, CTSCustID)
    SELECT  cus.CustID
		,	cus.CTSCustID
    FROM JSON_TABLE(CONCAT('[',ip_ListCustID,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0;
        
	INSERT IGNORE INTO Temp_CategoryID(CategoryID)
    SELECT  tmp.CategoryID
    FROM JSON_TABLE(CONCAT('[',ip_ListCategoryID,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp;
    
    
    /**************************************  Device ************************************************/
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
    CREATE TEMPORARY TABLE Temp_CustDevice (
			CustID			BIGINT UNSIGNED  
        ,	DCSDeviceID		BIGINT UNSIGNED  
        ,	INDEX			IX_Temp_CustDevice_DCSDeviceID(DCSDeviceID)
		,	PRIMARY KEY(CustID, DCSDeviceID)
        
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
    CREATE TEMPORARY TABLE Temp_Device (
			DCSDeviceID		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceClass;
    CREATE TEMPORARY TABLE Temp_DeviceClass (
			CustID			BIGINT UNSIGNED
		,	DCSDeviceID		BIGINT UNSIGNED 
        ,	PRIMARY KEY(CustID, DCSDeviceID)
    );
    
    INSERT IGNORE INTO Temp_CustDevice(CustID, DCSDeviceID)
    SELECT 	tmp.CustID
		,	dv.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS dv 
		INNER JOIN Temp_CustParam AS tmp WHERE tmp.CTSCustID = dv.CTSCustID;
    
    INSERT IGNORE INTO Temp_Device(DCSDeviceID)
    SELECT	DISTINCT
			DCSDeviceID
    FROM 	Temp_CustDevice;
    
    INSERT IGNORE INTO Temp_DeviceClass(CustID, DCSDeviceID)
    SELECT  cus.CustID
		,	dv.DCSDeviceID
    FROM  Temp_Device AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON tmp.DCSDeviceID = dv.DCSDeviceID
		INNER JOIN CTSCustomer AS cus ON dv.CTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = cus.CustID);
                  
	INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	cus.CustID
		,	clss.CustID
    FROM Temp_CustDevice AS cus 
		INNER JOIN Temp_DeviceClass AS clss ON cus.DCSDeviceID = clss.DCSDeviceID AND cus.CustID != clss.CustID;
    
    /**************************************  Manual ************************************************/
    
    INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	cus.CustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByManual AS ma ON ma.FromCTSCustID = pa.CTSCustID
        INNER JOIN CTSCustomer AS cus ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = cus.CustID);
    
    INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	cus.CustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByManual AS ma ON ma.ToCTSCustID  = pa.CTSCustID
        INNER JOIN CTSCustomer AS cus ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = cus.CustID);
    
    /**************************************  AI  ************************************************/
    INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	ai.ToCustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByAI AS ai ON ai.FromCustID = pa.CustID AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	ai.FromCustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByAI AS ai ON ai.ToCustID  = pa.CustID AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = ai.FromCustID);

    /**************************************  AI Group ************************************************/
    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup;
    CREATE TEMPORARY TABLE Temp_CustGroup (
			CustID			BIGINT UNSIGNED  
        ,	GroupID			BIGINT UNSIGNED  
        ,	INDEX			IX_Temp_CustGroup_GroupID(GroupID)
		,	PRIMARY KEY(CustID, GroupID)
        
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
    CREATE TEMPORARY TABLE Temp_Group (
			GroupID		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupClass;
    CREATE TEMPORARY TABLE Temp_GroupClass (
			CustID			BIGINT UNSIGNED
		,	GroupID			BIGINT UNSIGNED 
        ,	PRIMARY KEY(CustID, GroupID)
    );
    
    INSERT IGNORE INTO Temp_CustGroup(CustID, GroupID)
    SELECT 	tmp.CustID
		,	grp.GroupID
    FROM CTS_DataCenter.AssociationGroupByAI AS grp 
		INNER JOIN Temp_CustParam AS tmp WHERE tmp.CustID = grp.CustID;
    
    INSERT IGNORE INTO Temp_Group(GroupID)
    SELECT	DISTINCT
			GroupID
    FROM Temp_CustGroup;
    
    INSERT IGNORE INTO Temp_GroupClass(CustID, GroupID)
    SELECT  grp.CustID
		,	grp.GroupID
    FROM  Temp_Group AS tmp 
		INNER JOIN CTS_DataCenter.AssociationGroupByAI AS grp ON tmp.GroupID = grp.GroupID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = grp.CustID);
    
    INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	cus.CustID
		,	clss.CustID
    FROM Temp_CustGroup AS cus 
		INNER JOIN Temp_GroupClass AS clss ON cus.GroupID = cus.GroupID AND clss.CustID != cus.CustID;
        
	/**************************************  IP  ************************************************/
    INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	ip.ToCustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByIP AS ip ON ip.FromCustID = pa.CustID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = ip.ToCustID);
    
	INSERT IGNORE INTO Temp_CustClass(CustID,CustID_Level1)
    SELECT 	pa.CustID
		,	ip.FromCustID
    FROM Temp_CustParam AS pa 
		INNER JOIN AssociationByIP AS ip ON ip.ToCustID  = pa.CustID
	WHERE EXISTS (SELECT 1 
                  FROM CTSCustomerClassification AS clss 
					  STRAIGHT_JOIN Temp_CategoryID AS cate ON cate.CategoryID = clss.CategoryID
                  WHERE clss.CustID = ip.FromCustID);
	
    /**************************************  Return  ************************************************/
    SELECT 	CustID
		,	(SELECT COUNT(1) 
			 FROM Temp_CustClass AS clss 
             WHERE clss.CustID = pa.CustID) AS Total
    FROM Temp_CustParam AS pa;
    
END$$
DELIMITER ;