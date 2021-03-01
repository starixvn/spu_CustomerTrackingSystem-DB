/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetEvidencesByDirectAssociation`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetEvidencesByDirectAssociation`(
		IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN

	/*
		Created:	20210226@JonasHuynh
		Task:		Get Flagged Evidences by Association for level 0,1 [Redmine ID: 150456]
		DB:			CTS_DataCenter
		Original:

		Revisions:
           - 20210226@JonasHuynh [Redmine ID: #150456]: Created
		   
		Param's Explanation (filtered by):			
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_GetAllEvidencesByCusts('43600693,1176086');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer(	  
			CustID              BIGINT UNSIGNED PRIMARY KEY 
		,	CTSCustID           BIGINT UNSIGNED
		,	INDEX 				 IX_Temp_Customer_CTSCustID (CTSCustID)
	);
	    
	DROP TEMPORARY TABLE IF EXISTS Temp_DirectAssociation;    
	CREATE TEMPORARY TABLE Temp_DirectAssociation (	  
			 RootCustID		INT UNSIGNED  
		 ,	 CustID			INT UNSIGNED  
         ,   CTSCustID 		BIGINT UNSIGNED
         ,	 PRIMARY KEY 	PK_Temp_DirectedAssociation (RootCustID, CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_FlaggedEvidence;
    CREATE TEMPORARY TABLE Temp_FlaggedEvidence(
		 	CTSCustID		BIGINT UNSIGNED  
		,	CustID			BIGINT UNSIGNED
		,	EvidenceCode	VARCHAR(10)
		,	EvidenceName	VARCHAR(50)
		,	FromCustID		BIGINT
		,	CreatedDate		DATETIME
		, 	Level			SMALLINT
	);
        
	/* Insert CustIDs  */
	SET @sql = 	CONCAT("INSERT INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
	/* Update CTSCustID */
    UPDATE      Temp_Customer AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET         temp.CTSCustID = cust.CTSCustID;
    
    /* Get Direct Association */
    INSERT IGNORE INTO Temp_DirectAssociation(RootCustID, CustID, CTSCustID)
	SELECT root.CustID, cust.CustID, ce.CTSCustID 
	FROM CTS_DataCenter.CustEvidence AS ce	
		INNER JOIN Temp_Customer AS root ON root.CTSCustID = ce.FromCustID AND ce.Level = 2
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = ce.CTSCustID;
    
	/* Get Flagged Evidence (Level 0)*/
	INSERT INTO Temp_FlaggedEvidence(CustID, EvidenceCode, EvidenceName, FromCustID, CreatedDate, Level)
	SELECT c.CustID, e.EvidenceCode, e.EvidenceName, c.CustID as FromCustID, ce.CreatedDate, ce.Level	   
	FROM CTS_DataCenter.CustEvidence AS ce	
		INNER JOIN Temp_Customer AS c ON ce.FromCustID = c.CTSCustID AND ce.Level = 0
		INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = ce.EvidenceID AND e.IsActive = True;

    
	/* Get Flagged Evidence (Level 1)*/    
	INSERT INTO Temp_FlaggedEvidence(CustID, EvidenceCode, EvidenceName, FromCustID, CreatedDate, Level)
	SELECT rootAss.CustID, e.EvidenceCode, e.EvidenceName, rootAss.RootCustID AS FromCustID, ce.CreatedDate AS CreatedDate, 1 as Level
	FROM Temp_DirectAssociation AS rootAss
		INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.FromCustID = rootAss.CTSCustID AND ce.Level = 0
		INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = ce.EvidenceID AND e.IsActive = True;
	  
	 -- Return CustId, Level0CustId, EvidenceCode, EvidenceName, CreatedDate, AssociatedLevel
    SELECT DISTINCT temp.CustID			AS CustId
				,	temp.EvidenceCode	AS EvidenceCode
                ,	temp.EvidenceName	AS EvidenceName
                ,	temp.FromCustID 	AS Level0CustId
                ,	temp.CreatedDate	AS CreatedDate
                ,	temp.Level			AS AssociatedLevel
    FROM Temp_FlaggedEvidence AS temp;
  
END$$

DELIMITER ;