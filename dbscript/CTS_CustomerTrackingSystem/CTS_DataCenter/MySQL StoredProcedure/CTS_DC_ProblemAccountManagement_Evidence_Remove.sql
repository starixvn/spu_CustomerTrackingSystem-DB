/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_ProblemAccountManagement_Evidence_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemAccountManagement_Evidence_Remove`(
		IN ip_CustIDs		LONGTEXT
    ,	IN ip_SourceType    SMALLINT UNSIGNED
)
    SQL SECURITY INVOKER
sp :BEGIN
	/*
		Created:	20220322@Aries.Nguyen
		Task:		Allow Unmark and Update on PA Management Function [Redmine ID: #170135]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220322@Aries.Nguyen: Created [Redmine ID: #170135]

        Param's Explanation (filtered by):
			- ip_SourceType: 1 - NAP, 0 - Others
        Example: 
			- CALL CTS_DC_ProblemAccountManagement_Evidence_Remove('1,2,3,4,5',1);
*/   
	DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID(	  
			CustID	BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;    
	CREATE TEMPORARY TABLE Temp_CTSCustID(	  
			CTSCustID	BIGINT UNSIGNED PRIMARY KEY
		,	EviLevel	TINYINT DEFAULT 0
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceExist;    
	CREATE TEMPORARY TABLE Temp_CustEvidenceExist(	 
			CustEvidID	BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID	BIGINT UNSIGNED 
        ,	EvidenceID  SMALLINT
        ,	UNIQUE KEY	UN_Temp_CustEvidenceExist_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
	);
  
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
    
    INSERT IGNORE INTO Temp_CTSCustID(CTSCustID)
    SELECT cust.CTSCustID
    FROM Temp_CustID AS tmp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON tmp.CustID = cust.CustID AND cust.CustSubID = 0;
        
	INSERT INTO Temp_CustEvidenceExist(CustEvidID,CTSCustID,EvidenceID)
	SELECT 	ev.CustEvidID
		,	ev.CTSCustID
        ,	ev.EvidenceID
	FROM CTS_DataCenter.CustEvidence AS ev USE INDEX (IX_CustEvidence_Level_CTSCustID)
	WHERE EXISTS (SELECT 1 
				  FROM Temp_CTSCustID AS tmp 
                  WHERE ev.CTSCustID = tmp.CTSCustID 
					AND ev.Level = tmp.EviLevel
                    AND ev.SourceType = ip_SourceType);
                    
	INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID)
    SELECT 	tmp.CTSCustID
		,	tmp.EvidenceID
    FROM Temp_CustEvidenceExist AS tmp;
    
    DELETE 
    FROM CTS_DataCenter.CustEvidence AS ev
    WHERE EXISTS (SELECT 1 FROM Temp_CustEvidenceExist AS tmp WHERE tmp.CustEvidID = ev.CustEvidID);
    
END$$
DELIMITER ;