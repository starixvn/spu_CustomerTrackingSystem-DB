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
           - 20210308@JonasHuynh [Redmine ID: #150456]: Update logic SP
		   
		Param's Explanation (filtered by):			
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_GetAllEvidencesByCusts('43600693,1176086');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RootCustomer;    
	CREATE TEMPORARY TABLE Temp_RootCustomer(	  
			RootCustID			INT UNSIGNED  
		,	CustID              BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID           BIGINT UNSIGNED
        ,	INDEX 				IX_Temp_RootCustomer (CTSCustID)
	);
	    
	DROP TEMPORARY TABLE IF EXISTS Temp_DirectAssociation;    
	CREATE TEMPORARY TABLE Temp_DirectAssociation (	  
			 RootCustID			INT UNSIGNED  
         ,   CTSCustID 			BIGINT UNSIGNED
         ,	 PRIMARY KEY 		PK_Temp_DirectedAssociation (CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_FlaggedEvidence;
    CREATE TEMPORARY TABLE Temp_FlaggedEvidence(
		 	CTSCustID			BIGINT UNSIGNED  
		,	CustID				BIGINT UNSIGNED
		,	FromCustID			BIGINT
        ,	EvidenceID			INT
		,	CreatedDate			DATETIME
		, 	AssociationLevel	SMALLINT
	);
        
	/* Insert CustIDs  */
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_RootCustomer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
	/* Update CTSCustID */
    UPDATE      Temp_RootCustomer AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET         temp.RootCustID = cust.CustID
			,	temp.CTSCustID = cust.CTSCustID;
		
    /* Get Direct Association */
    INSERT IGNORE INTO Temp_DirectAssociation(RootCustID, CTSCustID)
	SELECT rootCust.CustID 	AS RootCustID, ass.ToCTSCustID	AS CTSCustID
	FROM Temp_RootCustomer as rootCust INNER JOIN CTS_DataCenter.Association ass ON ass.FromCTSCustID = rootCust.CTSCustID;
    
    INSERT IGNORE INTO Temp_DirectAssociation(RootCustID, CTSCustID)
	SELECT rootCust.CustID 	AS RootCustID, ass.FromCTSCustID	AS CTSCustID
	FROM Temp_RootCustomer as rootCust INNER JOIN CTS_DataCenter.Association ass ON ass.ToCTSCustID = rootCust.CTSCustID;
    
	/* Get Flagged Evidence (Level 0)*/
	INSERT INTO Temp_FlaggedEvidence(CustID, FromCustID, EvidenceID, CreatedDate, AssociationLevel)
	SELECT c.CustID, c.RootCustID AS FromCustID, ce.EvidenceID, ce.CreatedDate, 0 as AssociationLevel	   
	FROM CTS_DataCenter.CustEvidence AS ce INNER JOIN Temp_RootCustomer AS c ON ce.FromCustID = c.CTSCustID AND ce.Level = 0;
	  
	/* Get Flagged Evidence (Level 1)*/
	INSERT INTO Temp_FlaggedEvidence(CustID, FromCustID, EvidenceID, CreatedDate, AssociationLevel)
	SELECT cust.CustID, c.RootCustID AS FromCustID, ce.EvidenceID, ce.CreatedDate, 1 as AssociationLevel	  
	FROM CTS_DataCenter.CustEvidence AS ce	
		INNER JOIN Temp_DirectAssociation AS c ON ce.FromCustID = c.CTSCustID AND ce.Level = 0
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON cust.CTSCustID = c.CTSCustID;
        
	-- Return CustId, Level0CustId, EvidenceCode, EvidenceName, CreatedDate, AssociatedLevel
    SELECT DISTINCT temp.CustID				AS CustId
				,	e.EvidenceCode			AS EvidenceCode
                ,	e.EvidenceName			AS EvidenceName
                ,	temp.FromCustID 		AS Level0CustId
                ,	temp.CreatedDate		AS CreatedDate
                ,	temp.AssociationLevel	AS AssociatedLevel
    FROM Temp_FlaggedEvidence AS temp
  		INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = temp.EvidenceID AND e.IsActive = True;
  
END$$

DELIMITER ;