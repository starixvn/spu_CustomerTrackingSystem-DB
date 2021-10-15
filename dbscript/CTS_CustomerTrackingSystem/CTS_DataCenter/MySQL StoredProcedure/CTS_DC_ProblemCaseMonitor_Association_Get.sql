/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Association_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Association_Get`(
		OUT op_AssDeviceID 		BIGINT UNSIGNED 
	,	OUT op_AssIPID 			BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20211006@Aries.Nguyen
		Task:  Get Problem Case data From Association[RedmineID: #162830]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20211006@Aries.Nguyen: Created [RedmineID: #162830]

		Param's Explanation (filtered by):

		Example: 
            - CALL CTS_DC_ProblemCaseMonitor_Association_Get(@op_AssDeviceID, @op_AssIPID);
	*/ 
	DECLARE	CONST_ProblemCase_SuspiciousAss	INT DEFAULT 4;
    
    DECLARE lv_LastAssIPID					BIGINT UNSIGNED;
	DECLARE lv_NextAssIPID					BIGINT UNSIGNED;
    DECLARE lv_AssIPBatchSize				INT;
    
    DECLARE lv_LastAssDeviceID				BIGINT UNSIGNED;
	DECLARE lv_NextAssDeviceID				BIGINT UNSIGNED;
    DECLARE lv_AssDeviceBatchSize			INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewAssIP;
    CREATE TEMPORARY TABLE Temp_NewAssIP(
        	FromCustID		BIGINT UNSIGNED
		,   FromCTSCustID	BIGINT UNSIGNED
		,	ToCustID		BIGINT UNSIGNED
        ,	ToCTSCustID		BIGINT UNSIGNED
        ,	PRIMARY KEY(FromCustID, ToCustID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewAssDevice;
    CREATE TEMPORARY TABLE Temp_NewAssDevice(
			DCSDeviceID	BIGINT UNSIGNED
        ,	CTSCustID	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
        ,	INDEX 		IX_Temp_NewAssDevice_CustID(CustID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssDevice_Level1;
    CREATE TEMPORARY TABLE Temp_AssDevice_Level1(
			DCSDeviceID	BIGINT UNSIGNED
        ,	CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
        ,	INDEX 		IX_Temp_AssDevice_Level1_CustID(CustID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE 	Temp_CustID (			
			CustID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;
    CREATE TEMPORARY TABLE 	Temp_PA (			
			CustID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssIP_PA;
    CREATE TEMPORARY TABLE 	Temp_AssIP_PA (			
			CustID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE 	Temp_CustAssociation (
			CustID 			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED 
        ,   CustID_Aff 		BIGINT UNSIGNED 
        ,   CTSCustID_Aff 	BIGINT UNSIGNED 
        ,	IsPA			BIT DEFAULT 0
        , 	PRIMARY KEY 	PK_Temp_Dev_CTSCustID_CustID(CTSCustID_Aff, CTSCustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Unlink;
    CREATE TEMPORARY TABLE 	Temp_Unlink (
			FromCTSCustID 	BIGINT UNSIGNED
		,	ToCTSCustID		BIGINT UNSIGNED
        ,	PRIMARY KEY 	PK_Temp_Unlink (FromCTSCustID,ToCTSCustID)
        ,	KEY				IX_Temp_Unlink_ToCTSCustID (ToCTSCustID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustProlemCase;
    CREATE TEMPORARY TABLE Temp_CustProlemCase(		
			CustID			BIGINT UNSIGNED PRIMARY KEY  
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProlemCase_Exist;
    CREATE TEMPORARY TABLE Temp_ProlemCase_Exist(		
			CustID			BIGINT UNSIGNED  PRIMARY KEY    
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceLevel1_Distinct;
    CREATE TEMPORARY TABLE Temp_DeviceLevel1_Distinct(		
			CustID			BIGINT UNSIGNED   
		,	CTSCustID		BIGINT UNSIGNED 
        ,	PRIMARY KEY (CTSCustID, CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AllDevice_Level1;
    CREATE TEMPORARY TABLE Temp_AllDevice_Level1(
			DCSDeviceID	BIGINT UNSIGNED
        ,	CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        , 	PRIMARY KEY(DCSDeviceID, CTSCustID)
    );
    /**************************IP****************************/
	
    SELECT ParameterValue 
    INTO lv_LastAssIPID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 21;
    
    SELECT ParameterValue 
    INTO lv_AssIPBatchSize
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 51;
    
    SELECT MAX(tbl.ID)
    INTO lv_NextAssIPID
    FROM (SELECT ID
		  FROM CTS_DataCenter.AssociationByIP
		  WHERE ID > lv_LastAssIPID
		  ORDER BY ID ASC
		  LIMIT lv_AssIPBatchSize) AS tbl;
    
    /*
		select @lv_LastAssIPID, @lv_AssIPBatchSize, @lv_NextAssIPID;
	*/
    
    IF lv_NextAssIPID IS NULL THEN
		SET lv_NextAssIPID = lv_LastAssIPID;
    END IF;
    
    INSERT IGNORE INTO Temp_AssIP_PA(CustID)
    SELECT 	ip.ToCustID
	FROM AssociationByIP AS ip
    WHERE ip.ID BETWEEN lv_LastAssIPID AND lv_NextAssIPID
		AND EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
                        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND cat.ParentID = 50 AND cat.CategoryGroup <> 52
					WHERE  cls.CustID = ip.FromCustID
						AND cls.SportGroupID = 0);
	
    INSERT IGNORE INTO Temp_AssIP_PA(CustID)
    SELECT 	ip.FromCustID
	FROM AssociationByIP AS ip
    WHERE ip.ID BETWEEN lv_LastAssIPID AND lv_NextAssIPID
		AND EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
                        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND cat.ParentID = 50 AND cat.CategoryGroup <> 52
					WHERE  cls.CustID = ip.ToCustID
						AND cls.SportGroupID = 0);
	
    INSERT IGNORE INTO Temp_NewAssIP(FromCustID, FromCTSCustID, ToCustID, ToCTSCustID)
    SELECT 	pa.CustID
		,	frCus.CTSCustID
		,	ip.ToCustID
        ,	toCus.CTSCustID
	FROM Temp_AssIP_PA AS pa 
		INNER JOIN  AssociationByIP AS ip ON pa.CustID = ip.FromCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS frCus ON frCus.CustID = pa.CustID AND frCus.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomer AS toCus ON toCus.CustID = ip.ToCustID AND toCus.CustSubID = 0;
	
    INSERT IGNORE INTO Temp_NewAssIP(FromCustID, FromCTSCustID, ToCustID, ToCTSCustID)
    SELECT 	pa.CustID
		,	frCus.CTSCustID
		,	ip.FromCustID
        ,	toCus.CTSCustID
	FROM Temp_AssIP_PA AS pa 
		INNER JOIN  AssociationByIP AS ip ON pa.CustID = ip.ToCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS frCus ON frCus.CustID = pa.CustID AND frCus.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomer AS toCus ON toCus.CustID = ip.FromCustID AND toCus.CustSubID = 0;
    
    /**************************Device****************************/
    
    
    SELECT ParameterValue 
    INTO lv_LastAssDeviceID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 22;
    
    SELECT ParameterValue 
    INTO lv_AssDeviceBatchSize
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 52;
    
    SELECT MAX(tbl.CTSAssDevID)
    INTO lv_NextAssDeviceID
    FROM (SELECT CTSAssDevID
		  FROM CTS_DataCenter.AssociationByDevice
		  WHERE CTSAssDevID > lv_LastAssDeviceID
		  ORDER BY CTSAssDevID ASC
		  LIMIT lv_AssDeviceBatchSize) AS tbl;
    
    IF lv_NextAssDeviceID IS NULL THEN
		SET lv_NextAssDeviceID = lv_LastAssDeviceID;
    END IF;
    
    INSERT INTO Temp_NewAssDevice(DCSDeviceID, CTSCustID, CustID)
    SELECT 	dv.DCSDeviceID
		,	dv.CTSCustID
        ,	cus.CustID
	FROM AssociationByDevice AS dv
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = dv.CTSCustID AND cus.CustSubID = 0
    WHERE dv.CTSAssDevID BETWEEN lv_LastAssDeviceID AND lv_NextAssDeviceID;
    
    INSERT INTO Temp_AssDevice_Level1(DCSDeviceID, CTSCustID, CustID)
    SELECT  DISTINCT
			ass.DCSDeviceID
		,	dv.CTSCustID
        ,	cus.CustID
    FROM Temp_NewAssDevice AS ass
		INNER JOIN AssociationByDevice AS dv ON ass.DCSDeviceID = dv.DCSDeviceID 
											AND ass.CTSCustID != dv.CTSCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = dv.CTSCustID AND cus.CustSubID = 0;

	/**********************************************************/
    
	INSERT IGNORE INTO Temp_CustID(CustID)
    SELECT ToCustID
    FROM Temp_NewAssIP;
    
	INSERT IGNORE INTO Temp_CustID(CustID)
    SELECT CustID
    FROM Temp_NewAssDevice;
    
	INSERT IGNORE INTO Temp_CustID(CustID)
    SELECT CustID
    FROM Temp_AssDevice_Level1;
    
    INSERT IGNORE INTO Temp_PA(CustID)
    SELECT tmp.CustID
    FROM Temp_CustID AS tmp
    WHERE EXISTS   (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
                        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND cat.ParentID = 50 AND cat.CategoryGroup <> 52
					WHERE  cls.CustID = tmp.CustID
						AND cls.SportGroupID = 0);
	
    INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CustID_Aff, CTSCustID_Aff)
    SELECT 	DISTINCT
			root.CustID
		,	root.CTSCustID
        ,	lv1.CustID
        ,	lv1.CTSCustID
    FROM Temp_NewAssDevice AS root
		INNER JOIN Temp_AssDevice_Level1 AS lv1 ON root.DCSDeviceID = lv1.DCSDeviceID AND root.CTSCustID != lv1.CTSCustID;
        
    INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CustID_Aff, CTSCustID_Aff)
    SELECT 	FromCustID
		,	FromCTSCustID
        ,	ToCustID
        ,	ToCTSCustID
    FROM Temp_NewAssIP;  
    
    /*****************************Remove Unlink****************************************/
    INSERT IGNORE INTO Temp_Unlink(FromCTSCustID,ToCTSCustID)
    SELECT 	DISTINCT 
			asRe.FromCTSCustID
		, 	asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID_Aff = asRe.ToCTSCustID AND cuAs.CTSCustID = asRe.FromCTSCustID;

	INSERT IGNORE INTO Temp_Unlink(FromCTSCustID,ToCTSCustID)
    SELECT DISTINCT asRe.FromCTSCustID, asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID = asRe.ToCTSCustID AND cuAs.CTSCustID_Aff = asRe.FromCTSCustID;
	
    DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_Unlink AS asRe ON cuAs.CTSCustID = asRe.FromCTSCustID AND cuAs.CTSCustID_Aff = asRe.ToCTSCustID;
	
    DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_Unlink AS asRe ON cuAs.CTSCustID_Aff = asRe.FromCTSCustID AND cuAs.CTSCustID = asRe.ToCTSCustID;
	
    INSERT IGNORE INTO Temp_CustProlemCase(CustID)
    SELECT 	ass.CustID
    FROM Temp_CustAssociation AS ass
		INNER JOIN Temp_PA AS pa on ass.CustID_Aff = pa.CustID
	GROUP BY ass.CustID
    HAVING COUNT(1) > 2;
    
     /*****************************Handle Association Level 1 Has 3 PA****************************************/
     
     /*Remove new ass cust isn't PA*/
     DELETE 
     FROM Temp_NewAssDevice AS ass
     WHERE ass.CustID NOT IN (SELECT pa.CustID FROM Temp_PA AS pa);
     
     DELETE 
     FROM Temp_AssDevice_Level1 AS lv1
     WHERE lv1.DCSDeviceID NOT IN (SELECT ass.DCSDeviceID FROM Temp_NewAssDevice AS ass);
     
     INSERT IGNORE INTO Temp_ProlemCase_Exist(CustID)
     SELECT lv1.CustID
     FROM Temp_AssDevice_Level1 AS lv1
     WHERE EXISTS (SELECT 1 
					FROM ProblemCaseMonitor AS prc 
                    WHERE prc.CustID = lv1.CustID 
						AND prc.ProblemCaseID = CONST_ProblemCase_SuspiciousAss);
					
	DELETE 
	FROM Temp_AssDevice_Level1 AS lv1
	WHERE lv1.CustID IN (SELECT prc.CustID FROM Temp_ProlemCase_Exist AS prc);
    
    INSERT IGNORE INTO Temp_DeviceLevel1_Distinct(CustID, CTSCustID)
	SELECT  CustID
		,	CTSCustID
    FROM Temp_AssDevice_Level1;
    
    INSERT IGNORE INTO Temp_AllDevice_Level1(DCSDeviceID, CTSCustID, CustID)
    SELECT  dv.DCSDeviceID
		,	lv1.CTSCustID
        ,	lv1.CustID
    FROM Temp_DeviceLevel1_Distinct AS lv1
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = lv1.CTSCustID;
	
    TRUNCATE TABLE Temp_CustAssociation;
    
    INSERT IGNORE INTO Temp_CustAssociation(CTSCustID, CustID, CTSCustID_Aff, CustID_Aff)
    SELECT	ass.CTSCustID
		,	ass.CustID
        ,	dv.CTSCustID
        ,	cus.CustID
    FROM Temp_AllDevice_Level1 AS ass
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON ass.DCSDeviceID = dv.DCSDeviceID AND   dv.CTSCustID != ass.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON dv.CTSCustID = cus.CTSCustID;
    
    /*****************************Remove Unlink****************************************/
    INSERT IGNORE INTO Temp_Unlink(FromCTSCustID,ToCTSCustID)
    SELECT 	DISTINCT 
			asRe.FromCTSCustID
		, 	asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID_Aff = asRe.ToCTSCustID AND cuAs.CTSCustID = asRe.FromCTSCustID;

	INSERT IGNORE INTO Temp_Unlink(FromCTSCustID,ToCTSCustID)
    SELECT DISTINCT asRe.FromCTSCustID, asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID = asRe.ToCTSCustID AND cuAs.CTSCustID_Aff = asRe.FromCTSCustID;
	
    DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_Unlink AS asRe ON cuAs.CTSCustID = asRe.FromCTSCustID AND cuAs.CTSCustID_Aff = asRe.ToCTSCustID;
	
    DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_Unlink AS asRe ON cuAs.CTSCustID_Aff = asRe.FromCTSCustID AND cuAs.CTSCustID = asRe.ToCTSCustID;
    
    UPDATE Temp_CustAssociation AS ass
    SET ass.IsPA = 1
	WHERE ass.CustID_Aff IN (SELECT pa.CustID FROM Temp_PA AS pa);
    
    INSERT IGNORE INTO Temp_PA(CustID)
	SELECT ass.CustID_Aff
    FROM Temp_CustAssociation AS ass
    WHERE ass.IsPA = 1 
		AND	EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
                        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND cat.ParentID = 50 AND cat.CategoryGroup <> 52
					WHERE  cls.CustID = ass.CustID_Aff
						AND cls.SportGroupID = 0);
	
    UPDATE Temp_CustAssociation AS ass
    SET ass.IsPA = 1
	WHERE ass.CustID_Aff IN (SELECT pa.CustID FROM Temp_PA AS pa);
    
    INSERT IGNORE INTO Temp_CustProlemCase(CustID)
    SELECT 	CustID
    FROM Temp_CustAssociation AS ass
	WHERE ass.IsPA = 1 
	GROUP BY ass.CustID
    HAVING COUNT(1) > 2;
    
    SELECT CustID
    FROM Temp_CustProlemCase;
    
    SET op_AssDeviceID = lv_NextAssDeviceID + 1;
    SET op_AssIPID = lv_NextAssDeviceID + 1;

END$$
DELIMITER ;