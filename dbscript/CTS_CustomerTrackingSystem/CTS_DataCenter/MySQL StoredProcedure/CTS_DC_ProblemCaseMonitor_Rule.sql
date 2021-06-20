/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Rule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Rule`(
	ip_PackSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20210617@Casey.Huynh
		Task:  Generate Problem Case data [RedmineID: #156464]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20210612@Casey.Huynh: Created [RedmineID: #156464]
		Param's Explanation (filtered by):

		Example: ;
	*/ 
    
    DECLARE lv_sysLastAssByIP			DATETIME;
    DECLARE lv_sysLastAssByDevice		BIGINT UNSIGNED;
    DECLARE lv_sysLastClassification	BIGINT UNSIGNED;
    DECLARE lv_ProCasRobot 			SMALLINT DEFAULT 1;
    DECLARE lv_ProCasSuspiciousAss 	SMALLINT DEFAULT 4;
    DECLARE lv_ProCasProPunter 		SMALLINT DEFAULT 9;
    
    #===========================================================
    SET lv_sysLastAssByIP = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 21);
    SET lv_sysLastAssByDevice = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 22);
    SET lv_sysLastClassification = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 23);
        
    #====PROBLEM CASE ROBOT(1) AND PRO PUNTER(9)====================================================
    SET @LastCustClassHisID = lv_sysLastClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
    CREATE TEMPORARY TABLE Temp_Category
    (
			CategoryID INT PRIMARY KEY
        ,	CategoryGroup INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustProlemCase;
    CREATE TEMPORARY TABLE Temp_CustProlemCase
    (		
			CustID			BIGINT UNSIGNED
		,	ProblemCaseID	SMALLINT
        ,	CreatedDate		DATETIME        
        ,	ID				BIGINT	
        
        ,	PRIMARY KEY Temp_CustProlemCase_CustID_ProblemCaseID(CustID,ProblemCaseID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CategoryPA;
    CREATE TEMPORARY TABLE Temp_CategoryPA
    (
			CategoryID INT PRIMARY KEY
	);
    #======Scan CTSCustomerClassification_History FOR cat.CategoryGroup IN (59, 61, 204)
    INSERT IGNORE INTO Temp_CustProlemCase (ID, CreatedDate, CustID, ProblemCaseID)
    SELECT 	@LastCustClassHisID := his.ID
		,	DATE(his.LastModifiedDate) AS CreatedDate
		,	CustID
        ,	(CASE WHEN cat.CategoryGroup IN (59,61) THEN lv_ProCasRobot
				 WHEN cat.CategoryGroup IN (204) THEN lv_ProCasProPunter END) AS ProblemCaseID
    FROM CTS_DataCenter.CTSCustomerClassification_History AS his
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON his.CategoryID = cat.CategoryID
    WHERE his.ID > lv_sysLastClassification AND his.IsDataChanged = 1 AND cat.CategoryGroup IN (59, 61, 204)
    ORDER BY ID
    LIMIT ip_PackSize;   
    #lv_sysLastAssByDevice
    INSERT INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, ProblemCaseID, CustID, CustSubID, InsertTime)
    SELECT tmpCpc.CreatedDate, tmpCpc.ProblemCaseID, tmpCpc.CustID, 0 , CURRENT_TIME()
    FROM Temp_CustProlemCase AS tmpCpc
    WHERE NOT EXISTS(SELECT 1 FROM CTS_DataCenter.ProblemCaseMonitor AS pcm 
			WHERE tmpCpc.CustID = pcm.CustID AND tmpCpc.ProblemCaseID = pcm.ProblemCaseID);
    
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = @LastCustClassHisID
    WHERE sys.ParameterID = 23;  
    
    #==========================================================================
    #======GET NEW AssociaionByDevice=======================================   
    DROP TEMPORARY TABLE IF EXISTS Temp_NewAssDevice;
    CREATE TEMPORARY TABLE Temp_NewAssDevice(
			DCSDeviceID	BIGINT UNSIGNED
        ,	CTSCustID	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED 
        ,	CreatedDate	DATETIME
        ,	CTSAssDevID	BIGINT UNSIGNED
        
        , PRIMARY KEY PK_Temp_NewAssDevice_CTSCustID(DCSDeviceID,CTSCustID)
    );  
    
    SET @LastAssByDevice = lv_sysLastAssByDevice;    
    
    INSERT IGNORE INTO Temp_NewAssDevice(DCSDeviceID, CTSCustID, CustID, CustSubID, CreatedDate, CTSAssDevID)
	SELECT	ad.DCSDeviceID
		,	ad.CTSCustID
        ,	cus.CustID
        ,	cus.CustSubID
        ,	DATE(ad.CreatedTime)
        ,	@LastAssByDevice := ad.CTSAssDevID 
    FROM CTS_DataCenter.AssociationByDevice AS ad		
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ad.CTSCustID = cus.CTSCustID
    WHERE ad.CTSAssDevID > lv_sysLastAssByDevice
	ORDER BY ad.CTSAssDevID
    LIMIT ip_PackSize; 
    
    #======WHEN NewAss.CTSCustID Associated At least 3 PA Custs==========================
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE Temp_CustAssociation(
			FromCTSCustID	BIGINT UNSIGNED
		,	FromCustID		BIGINT UNSIGNED
        ,	FromCustSubID	BIGINT UNSIGNED
        ,	ToCTSCustID		BIGINT UNSIGNED
        ,	CreatedDate		DATETIME
        
        , PRIMARY KEY PK_Temp_NewAssDevice(FromCTSCustID, ToCTSCustID, CreatedDate)
    );  
    
    INSERT IGNORE INTO Temp_CustAssociation(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, CreatedDate)
 	SELECT	nad.CTSCustID
		,	nad.CustID
        ,	nad.CustSubID
		,	cus.CustID
        ,	nad.CreatedDate
    FROM Temp_NewAssDevice AS nad
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ad ON nad.DCSDeviceID = ad.DCSDeviceID AND ad.CTSCustID <> nad.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ad.CTSCustID = cus.CTSCustID AND cus.CustSubID = 0
    WHERE EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND ParentID = 50
					WHERE cus.CustID = cls.CustID AND cls.SportGroupID = 0);

    INSERT INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, ProblemCaseID, CustID, CustSubID, InsertTime)
    SELECT MIN(CreatedDate), lv_ProCasSuspiciousAss, tmpCa.FromCustID, tmpCa.FromCustSubID, CURRENT_TIME()
    FROM Temp_CustAssociation AS tmpCa
	WHERE NOT EXISTS(SELECT 1 FROM CTS_DataCenter.ProblemCaseMonitor AS pcm 
			WHERE tmpCa.FromCustID = pcm.CustID AND pcm.ProblemCaseID = lv_ProCasSuspiciousAss)
	GROUP BY  tmpCa.FromCustID, tmpCa.FromCustSubID
    HAVING COUNT(1) > 2;   
    
	#======WHEN NewAss.CTSCustID X IS PA CustID => CHECK Associated Cust has at least 3 PA Cust==========================
  	DROP TEMPORARY TABLE IF EXISTS Temp_NewAssDevice_PA;
    CREATE TEMPORARY TABLE Temp_NewAssDevice_PA(
			DCSDeviceID	BIGINT UNSIGNED
        ,	CTSCustID	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED 
        ,	CreatedDate	DATETIME
        
        , PRIMARY KEY PK_Temp_NewAssDevice_CTSCustID(DCSDeviceID,CTSCustID)
    );  
    
    DELETE tmpCa 
    FROM Temp_CustAssociation AS tmpCa
	WHERE NOT EXISTS (	SELECT 1 
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND cat.ParentID = 50
						WHERE tmpCa.FromCustID = cls.CustID AND cls.SportGroupID = 0);	
    
    TRUNCATE TABLE Temp_NewAssDevice;
    INSERT INTO Temp_NewAssDevice(DCSDeviceID, CTSCustID, CustID, CustSubID, CreatedDate)
    SELECT	ad.DCSDeviceID
		,	ad.CTSCustID
        ,	cus.CustID
        ,	cus.CustSubID
        ,	tmpCa.CreatedDate
    FROM CTS_DataCenter.AssociationByDevice AS ad
		INNER JOIN Temp_CustAssociation AS tmpCa ON ad.CTSCustID = tmpCa.ToCTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpCa.ToCTSCustID = cus.CTSCustID;   
    
    TRUNCATE TABLE Temp_CustAssociation;
	INSERT IGNORE INTO Temp_CustAssociation(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, CreatedDate)
 	SELECT	nad.CTSCustID
		,	nad.CustID
        ,	nad.CustSubID
		,	cus.CustID
        ,	nad.CreatedDate
    FROM Temp_NewAssDevice AS nad
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ad ON nad.DCSDeviceID = ad.DCSDeviceID AND ad.CTSCustID <> nad.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ad.CTSCustID = cus.CTSCustID AND cus.CustSubID = 0
    WHERE EXISTS (SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID AND ParentID = 50
					WHERE cus.CustID = cls.CustID AND cls.SportGroupID = 0);
    
    INSERT INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, ProblemCaseID, CustID, CustSubID, InsertTime)
    SELECT MIN(CreatedDate), lv_ProCasSuspiciousAss, tmpCa.FromCustID, tmpCa.FromCustSubID, CURRENT_TIME()
    FROM Temp_CustAssociation AS tmpCa
	WHERE NOT EXISTS(SELECT 1 FROM CTS_DataCenter.ProblemCaseMonitor AS pcm 
			WHERE tmpCa.FromCustID = pcm.CustID AND pcm.ProblemCaseID = lv_ProCasSuspiciousAss)
	GROUP BY  tmpCa.FromCustID, tmpCa.FromCustSubID
    HAVING COUNT(1) > 2;
    
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = @LastAssByDevice
    WHERE sys.ParameterID = 22;  
    
END$$

DELIMITER ;
TRUNCATE TABLE ProblemCaseMonitor;

UPDATE CTS_DataCenter.SystemParameter 
SET ParameterValue = 6939
WHERE ParameterID = 22;

CALL CTS_DC_ProblemCaseMonitor_Rule(10);

SELECT * FROM CTS_DataCenter.ProblemCaseMonitor WHERE ProblemCaseID = 4 AND CustID =1776432;

SELECT COUNT(1) FROM CTS_DataCenter.ProblemCaseMonitor; #165;