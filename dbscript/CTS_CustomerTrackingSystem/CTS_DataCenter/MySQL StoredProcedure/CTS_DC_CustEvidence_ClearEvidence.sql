/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_ClearEvidence`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_ClearEvidence`(
		IN ip_CTSCustIDList 		VARCHAR(2000)
    
    ,	OUT op_ErrorMessage 		VARCHAR(200)
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Clear customer evidences [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
		
		Param's Explanation (filtered by):   
			- ActionID: 1 insert, 2 override, 3 clear
            
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidence_ClearEvidence('8', @op_ErrorMessage);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerIDs;
    CREATE TEMPORARY TABLE 		Temp_CustomerIDs (
			CustID 				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	PRIMARY KEY     	PK_Temp_CustomerIDs_CTSCustID_CustID(CTSCustID,CustID)
	);   
        
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustomerIDs (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SET SQL_SAFE_UPDATES = 0;
    /* Delete customer's flagged evidences */
    DELETE e
    FROM CTS_DataCenter.CustEvidence AS e
		INNER JOIN Temp_CustomerIDs AS t ON e.CTSCustID = t.CTSCustID
	WHERE e.Level = 0;
    
    /* Delete associated customer's evidences */
    DELETE e
    FROM CTS_DataCenter.CustEvidence AS e
		INNER JOIN Temp_CustomerIDs AS t ON t.CTSCustID = e.FromCustID
	WHERE e.Level = 2;

END$$

DELIMITER ;