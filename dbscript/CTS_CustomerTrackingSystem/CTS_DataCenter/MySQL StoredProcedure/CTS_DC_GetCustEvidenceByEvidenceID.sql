/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustEvidenceByEvidenceID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustEvidenceByEvidenceID`(IN ip_EvidenceID varchar(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20202105@Harvey.Nguyen
		Task :		Get CustEvidence by EvidenceID - [Redmine: 134591]
		DB:			CTS_DataCenter
		Original:
		
		Revisions:
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
		Param's Explanation (filtered by):
	*/ 
    
	DROP TEMPORARY TABLE IF EXISTS tempEviID;
    CREATE TEMPORARY TABLE tempEviID (
		EvidenceID INT PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO tempEviID (EvidenceID) VALUES ('", REPLACE(ip_EvidenceID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SELECT DISTINCT cust.CustID
	FROM CTS_DataCenter.CustEvidence ce
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON ce.CTSCustID = cust.CTSCustID
        INNER JOIN tempEviID te ON te.EvidenceID = ce.EvidenceID
	WHERE cust.CustID IS NOT NULL;			

END$$

DELIMITER ;