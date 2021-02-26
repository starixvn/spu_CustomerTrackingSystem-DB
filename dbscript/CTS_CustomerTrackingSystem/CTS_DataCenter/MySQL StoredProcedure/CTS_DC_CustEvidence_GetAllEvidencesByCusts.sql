/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetAllEvidencesByCusts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetAllEvidencesByCusts`(IN ip_CustIDs TEXT)
    SQL SECURITY INVOKER
BEGIN

	/*
		Created:	20210226@JonasHuynh
		Task:		Get all evidences by Custs for level 0,1 [Redmine ID: 150456]
		DB:			CTS_DataCenter
		Original:

		Revisions:
           - 20210226@JonasHuynh [Redmine ID: #150456]: Created
		   
		Param's Explanation (filtered by):			
        
        CALL CTS_DataCenter.CTS_DC_CustEvidence_GetAllEvidencesByCusts('43600693');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customers;    
	CREATE TEMPORARY TABLE Temp_Customers 
    (	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
         ,   CTSCustID           BIGINT UNSIGNED
         ,	 INDEX 				 IX_Temp_Customers_CTSCustID (CTSCustID)
     );
	
   	DROP TEMPORARY TABLE IF EXISTS   Temp_EvidencesResult;
    CREATE TEMPORARY TABLE Temp_EvidencesResult(
			CustID			BIGINT UNSIGNED
		,	EvidenceCode	VARCHAR(10)
        ,	EvidenceName	VARCHAR(50)
        ,	FromCustID		BIGINT
        ,	CreatedDate		DATETIME
        , 	Level			SMALLINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_FlaggedEvidences;
    CREATE TEMPORARY TABLE Temp_FlaggedEvidences(
			CustID			BIGINT UNSIGNED
		,	EvidenceCode	VARCHAR(10)
        ,	EvidenceName	VARCHAR(50)
        ,	FromCustID		BIGINT
        ,	CreatedDate		DATETIME
        , 	Level			SMALLINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedAssociation;    
	CREATE TEMPORARY TABLE Temp_AffectedAssociation 
	(	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
         ,   CTSCustID           BIGINT UNSIGNED
         ,	 INDEX 				 Temp_AffectedAssociation (CTSCustID)
	);
     
     -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
     -- Update CTSCustID, SubscriberID
    UPDATE      Temp_Customers AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET         temp.CTSCustID = cust.CTSCustID;
    
    /* Get Evidence By Customers*/
	INSERT INTO Temp_FlaggedEvidences(CustID, EvidenceCode, EvidenceName, FromCustID, CreatedDate, Level)
	SELECT c.CustID, e.EvidenceCode, e.EvidenceName, ce.FromCustID, ce.CreatedDate, ce.Level	   
	FROM CTS_DataCenter.CustEvidence AS ce	
	INNER JOIN Temp_Customers AS c ON ce.CTSCustID = c.CTSCustID
	INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = ce.EvidenceID
	WHERE e.IsActive = True;
    
    /* Get Flagged Evidence (Level 0)*/
	INSERT INTO Temp_EvidencesResult(CustID, EvidenceCode, EvidenceName, FromCustID, CreatedDate, Level)
	SELECT CustID, EvidenceCode, EvidenceName, CustID as FromCustID, CreatedDate, Level
	FROM Temp_FlaggedEvidences
	WHERE Level = 0;
    
        /*Get Affected Evidence */    
	INSERT INTO Temp_EvidencesResult(CustID, EvidenceCode, EvidenceName, FromCustID, CreatedDate, Level)
	SELECT cust.CustID, e.EvidenceCode, e.EvidenceName, root.CustID as FromCustID, ce.CreatedDate as CreatedDate, 1 as Level
	FROM CTS_DataCenter.CustEvidence AS ce
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = ce.CTSCustID
	INNER JOIN Temp_FlaggedEvidences AS root ON cust.CTSCustID = root.FromCustID AND cust.CustSubID = 0 AND root.Level = 2
	INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = ce.EvidenceID
	WHERE e.IsActive = True  AND ce.Level = 0;
  
	 -- Return CustId, Level0CustId, EvidenceCode, EvidenceName, CreatedDate, AssociatedLevel
    SELECT DISTINCT temp.CustId			as CustId
				,	temp.EvidenceCode	as EvidenceCode
                ,	temp.EvidenceName	as EvidenceName
                ,	temp.FromCustID 	as Level0CustId
                ,	temp.CreatedDate	as CreatedDate
                ,	temp.Level			as AssociatedLevel
    FROM Temp_EvidencesResult AS temp;
  
END$$

DELIMITER ;