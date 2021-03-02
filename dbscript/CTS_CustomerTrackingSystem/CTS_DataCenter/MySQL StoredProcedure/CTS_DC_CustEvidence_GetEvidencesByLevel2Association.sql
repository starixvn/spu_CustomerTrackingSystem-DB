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
		   
		Param's Explanation (filtered by):			
        
        CALL CTS_DataCenter.CTS_DC_CustEvidence_GetEvidencesByLevel2Association('443153');
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationLevel2;
    CREATE TEMPORARY TABLE Temp_AssociationLevel2(
		 	CTSCustID		BIGINT UNSIGNED  
		,	RootCTSCustID	BIGINT UNSIGNED  
        ,	RootCustID		BIGINT UNSIGNED  
	);
    
    SET @sql = 	CONCAT("INSERT INTO Temp_RootCustomer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    UPDATE      Temp_RootCustomer AS temp
		INNER JOIN  CTS_DataCenter.CTSCustomer AS tcust ON tcust.CustID = temp.CustID AND tcust.CustSubID = 0
    SET         temp.CTSCustID = tcust.CTSCustID;
    
    INSERT INTO Temp_AssociationLevel1 (CTSCustID, RootCTSCustID, RootCustID)
    SELECT CASE WHEN ass.FromCTSCustID = tcust.CTSCustID THEN ass.ToCTSCustID ELSE ass.FromCTSCustID END
		, tcust.CTSCustID
		, tcust.CustID
    FROM Temp_RootCustomer tcust
		INNER JOIN CTS_DataCenter.Association ass ON ass.FromCTSCustID = tcust.CTSCustID
			OR ass.ToCTSCustID = tcust.CTSCustID;
	
    INSERT INTO Temp_AssociationLevel2 (CTSCustID, RootCTSCustID, RootCustID)
	SELECT CASE WHEN ass2.FromCTSCustID = ass1.CTSCustID THEN ass2.ToCTSCustID ELSE ass2.FromCTSCustID END
		,	ass1.RootCTSCustID
		,	ass1.RootCustID
    FROM Temp_AssociationLevel1 ass1
		INNER JOIN CTS_DataCenter.Association ass2 ON ass2.FromCTSCustID = ass1.CTSCustID
			OR ass2.ToCTSCustID = ass1.CTSCustID;
	
    SELECT ass2.RootCustID AS 'Level0CustId'
		, cus.CustID
        , evi.EvidenceCode
        , evi.EvidenceName
        , ce.CreatedDate
        , 2 AS 'AssociatedLevel'
    FROM Temp_AssociationLevel2 ass2
		INNER JOIN CTS_DataCenter.CustEvidence ce ON ass2.CTSCustID = ce.CTSCustID AND ass2.CTSCustID = ce.FromCustID
        INNER JOIN CTS_DataCenter.Evidence evi ON ce.EvidenceID = evi.EvidenceID
        INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ass2.CTSCustID
        LEFT JOIN Temp_RootCustomer tcust ON tcust.CTSCustID = ass2.CTSCustID
        LEFT JOIN Temp_AssociationLevel1 ass1 ON ass1.CTSCustID = ass2.CTSCustID
	WHERE tcust.CTSCustID IS NULL AND ass1.CTSCustID IS NULL;
  
END$$

DELIMITER ;