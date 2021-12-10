/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2" executers="ctsServiceAdmin,ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Arc_CustomerAssociation_LastTicketDate_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Arc_CustomerAssociation_LastTicketDate_Update`(
		IN ip_CustInfo 		LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20211026@Aries.Nguyen
		Task:		Archive Inactive Association
		DB:			CTS_Archive
		Original:
		Revisions:
			- 20211026@Aries.Nguyen [Redmine ID: #163087]: Created
            
        Param's Explanation (filtered by):

        Example: 
			- CALL CTS_Arc_CustomerAssociation_LastTicketDate_Update('221882500,122,443');
*/   
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;    
	CREATE TEMPORARY TABLE Temp_Cust( 	  
			CustID		INT UNSIGNED	
        ,	PRIMARY	KEY (CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustArchived;    
	CREATE TEMPORARY TABLE Temp_CustArchived( 	  
			CTSCustID 		BIGINT 	UNSIGNED
		,	CustID			INT 	UNSIGNED
        ,	PRIMARY	KEY (CTSCustID)
	);
	
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Cust (CustID) VALUES ('", REPLACE(ip_CustInfo, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    INSERT INTO Temp_CustArchived(CTSCustID, CustID)
    SELECT 	cus.CTSCustID
		,	cus.CustID
    FROM CTS_Archive.CTSCustomerAssociationStatus AS cus
    WHERE cus.IsArchived = 1 
		AND EXISTS (SELECT 1 FROM Temp_Cust AS tmp WHERE tmp.CustID = cus.CustID);
        
    DELETE 
    FROM Temp_Cust AS cus
    WHERE EXISTS (SELECT 1 FROM Temp_CustArchived AS arc WHERE arc.CustID = cus.CustID);
    
    UPDATE CTS_Archive.CTSCustomerAssociationStatus AS cus
    SET 	cus.LastTicketDate = NOW()
    WHERE EXISTS (SELECT 1 FROM Temp_Cust AS tmp WHERE tmp.CustID = cus.CustID);
    
    DELETE 
    FROM CTS_Archive.CTSCustomerAssociationArchive_Process AS pro
    WHERE EXISTS (SELECT 1 FROM Temp_CustArchived AS tmp WHERE tmp.CTSCustID = pro.CTSCustID);
    
    UPDATE CTS_Archive.CTSCustomerAssociationStatus AS cus
    SET 	cus.LastTicketDate = NOW()
		,	cus.IsRollBack = 1
        ,	cus.RollBackDate = NOW()
        ,	cus.IsArchived = 0
    WHERE EXISTS (SELECT 1 FROM Temp_CustArchived AS arc WHERE arc.CTSCustID = cus.CTSCustID);

END$$
DELIMITER ;