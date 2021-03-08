/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetEvidencesByLevel2Association`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetEvidencesByLevel2Association`(IN ip_CustIDs TEXT)
    SQL SECURITY INVOKER
BEGIN

	/*
		Created:	20210301@Harvey.Nguyen
		Task:		Get all evidences by Custs for level 2 [Redmine ID: 150456]
		DB:			CTS_DataCenter
		Original:

		Revisions:
           - 20210301@Harvey.Nguyen [Redmine ID: #150917]: Created
		   - 20210308@Jonas.Huynh [Redmine ID: #150917]: Update logic SP
           
		Param's Explanation (filtered by):			
        
        CALL CTS_DataCenter.CTS_DC_CustEvidence_GetEvidencesByLevel2Association('17004');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RootCustomer;
    CREATE TEMPORARY TABLE Temp_RootCustomer(
		 	CTSCustID		BIGINT UNSIGNED  
		,	CustID          BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationLevel1;
    CREATE TEMPORARY TABLE Temp_AssociationLevel1(
		 	CTSCustID		BIGINT UNSIGNED  
		,	RootCTSCustID	BIGINT UNSIGNED  
        ,	RootCustID		BIGINT UNSIGNED  
	);
    
	DROP TEMPORARY TABLE IF EXISTS   Temp_AssociationLevel2;
    CREATE TEMPORARY TABLE Temp_AssociationLevel2(
		 	AssCTSCustID		BIGINT UNSIGNED  
		,	RootCustID			BIGINT UNSIGNED
        ,	EvidenceID			INT
		,	CreatedDate			DATETIME
		, 	AssociationLevel	SMALLINT
	);
    
    SET @sql = 	CONCAT("INSERT INTO Temp_RootCustomer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    UPDATE      Temp_RootCustomer AS temp
		INNER JOIN  CTS_DataCenter.CTSCustomer AS tcust ON tcust.CustID = temp.CustID AND tcust.CustSubID = 0
    SET         temp.CTSCustID = tcust.CTSCustID;
    
	/* Get Direct Association */
    INSERT INTO Temp_AssociationLevel1 (CTSCustID, RootCTSCustID, RootCustID)
    SELECT DISTINCT
			ass.ToCTSCustID
		,	cust.CTSCustID
		, 	cust.CustID
    FROM Temp_RootCustomer cust INNER JOIN CTS_DataCenter.Association ass ON ass.FromCTSCustID = cust.CTSCustID;
    
    INSERT INTO Temp_AssociationLevel1 (CTSCustID, RootCTSCustID, RootCustID)
    SELECT DISTINCT
			ass.FromCTSCustID
		,	cust.CTSCustID
		, 	cust.CustID
    FROM Temp_RootCustomer cust INNER JOIN CTS_DataCenter.Association ass ON ass.ToCTSCustID = cust.CTSCustID;
	
    /* Get Association Lv2*/
    INSERT INTO Temp_AssociationLevel2 (AssCTSCustID, RootCustID, EvidenceID, CreatedDate, AssociationLevel)
	SELECT  ce.FromCustID 	AS AssCTSCustID
		,	c.RootCustID 	AS RootCustID
        , 	ce.EvidenceID
        , 	ce.CreatedDate
        ,	2 AS AssociationLevel	   
	FROM Temp_AssociationLevel1 AS c 
		INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = c.CTSCustID AND ce.Level = 2
	WHERE ce.FromCustID <> c.RootCTSCustID;

    -- Return CustId, Level0CustId, EvidenceCode, EvidenceName, CreatedDate, AssociatedLevel
    SELECT DISTINCT cust.CustID				AS CustId
				,	e.EvidenceCode			AS EvidenceCode
                ,	e.EvidenceName			AS EvidenceName
                ,	temp.RootCustID 		AS Level0CustId
                ,	temp.CreatedDate		AS CreatedDate
                ,	temp.AssociationLevel	AS AssociatedLevel
    FROM Temp_AssociationLevel2 AS temp
  		INNER JOIN CTS_DataCenter.Evidence AS e ON e.EvidenceID = temp.EvidenceID AND e.IsActive = True
        INNER JOIN CTS_DataCenter.CTSCustomer cust ON cust.CTSCustID = temp.AssCTSCustID;
        
END$$

DELIMITER ;