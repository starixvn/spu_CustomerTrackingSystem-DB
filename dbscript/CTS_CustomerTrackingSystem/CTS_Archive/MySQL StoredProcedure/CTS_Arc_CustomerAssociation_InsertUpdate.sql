/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2" executers="ctsServiceAdmin,ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Arc_CustomerAssociation_InsertUpdate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Arc_CustomerAssociation_InsertUpdate`(
		IN ip_CustInfo 	JSON
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20211026@Aries.Nguyen
		Task:		Archive Inactive Association
		DB:			CTS_Archive
		Original:
		Revisions:
			- 20211026@Aries.Nguyen: Created [Redmine ID: #163087]
            
        Param's Explanation (filtered by):
        
        Example:
			- CALL CTS_Arc_CustomerAssociation_InsertUpdate('[{"CTSCustID": 1,"CustID": 221882500}]');
	*/   
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;    
	CREATE TEMPORARY TABLE Temp_Cust( 	  
			CTSCustID 	BIGINT UNSIGNED	
		,	CustID		BIGINT UNSIGNED
        ,	PRIMARY	KEY (CTSCustID)
	);
    
	INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT	info.CTSCustID
		, 	info.CustID
	FROM JSON_TABLE(ip_CustInfo,
		 "$[*]" COLUMNS(
				CTSCustID	BIGINT UNSIGNED	PATH "$.CTSCustID" 
			, 	CustID		BIGINT UNSIGNED	PATH "$.CustID" 
			, 	CustSubID	BIGINT UNSIGNED	PATH "$.CustSubID" 
			, 	RoleID		TINYINT			PATH "$.RoleID" )
	) AS info
	WHERE info.RoleID = 1 AND info.CustSubID = 0;
    
    INSERT INTO CTS_DataCenter.CTSCustomerAssociationStatus(CTSCustID, CustID, LastTicketDate)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	NOW()
	FROM Temp_Cust AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerAssociationStatus AS arc  WHERE arc.CTSCustID = tmp.CTSCustID);
    
END$$
DELIMITER ;