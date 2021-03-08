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
	      
    DROP TEMPORARY TABLE IF EXISTS   Temp_FlaggedEvidence;
    CREATE TEMPORARY TABLE Temp_FlaggedEvidence(
		 	AssCTSCustID		BIGINT UNSIGNED  
		,	RootCustID			BIGINT UNSIGNED
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
    INSERT INTO Temp_FlaggedEvidence (AssCTSCustID, RootCustID, EvidenceID, CreatedDate, AssociationLevel)
	SELECT  ce.FromCustID 	AS AssCTSCustID
		,	c.CustID 		AS RootCustID
        , 	ce.EvidenceID
        , 	ce.CreatedDate
        ,	CASE WHEN ce.Level = 0 THEN 0 ELSE 1 END AS AssociationLevel	   
	FROM Temp_RootCustomer AS c	INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = c.CTSCustID;
        
	-- Return CustId, Level0CustId, EvidenceCode, EvidenceName, CreatedDate, AssociatedLevel
    SELECT DISTINCT cust.CustID				AS CustId
				,	e.EvidenceCode			AS EvidenceCode
                ,	e.EvidenceName			AS EvidenceName
                ,	temp.RootCustID 		AS Level0CustId
                ,	temp.CreatedDate		AS CreatedDate
                ,	temp.AssociationLevel	AS AssociatedLevel
    FROM Temp_FlaggedEvidence AS temp
  		INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = temp.EvidenceID AND e.IsActive = True
        INNER JOIN CTS_DataCenter.CTSCustomer cust ON cust.CTSCustID = temp.AssCTSCustID;
  
END$$

DELIMITER ;