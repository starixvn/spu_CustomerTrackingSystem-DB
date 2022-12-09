/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_TransferAccount_ValidateUsername`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_TransferAccount_ValidateUsername`(
		IN ip_ListUsername 		LONGTEXT
	,	IN ip_GroupID			BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/* 
		Created:	20221206@Victoria.Le
		Task:		Check the exist of UserName in current group
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20221206@Victoria.Le: Initial Writing [Redmine ID: #179398]
        
		Param's Explanation (filtered by):
			ip_ListUsername: string (username1, username2, username3)
            ip_GroupID: it's current group which need to check ip_ListUsername
            
        Example:			
			- CALL CTS_DataCenter.CTS_DC_AssociatedGroup_TransferAccount_ValidateUsername ('922SD,668TB,TEST1234567789',7 );
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Username;
    CREATE TEMPORARY TABLE Temp_Username(
			Username 	VARCHAR(50) PRIMARY KEY
		,	CTSCustID	BIGINT DEFAULT NULL
		,	CustID 		INT	DEFAULT NULL
        ,	IsValid		BIT DEFAULT 0
        ,	IsExist		BIT DEFAULT 0
	);
    
	SET @sql = CONCAT("INSERT INTO Temp_Username (Username) VALUES ('", REPLACE(ip_ListUsername, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    UPDATE Temp_Username AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  temp.Username = cus.Username
	SET		temp.CTSCustID = cus.CTSCustID
		,	temp.CustID = cus.CustID
        ,	temp.IsValid = 1;
    
    /*Check the exist in current group*/
    UPDATE Temp_Username AS temp
		INNER JOIN CTS_DataCenter.AssociatedGroupAccount AS acc ON acc.CTSCustID = temp.CTSCustID
        INNER JOIN CTS_DataCenter.AssociatedGroup AS grp ON grp.GroupID = acc.GroupID AND grp.IsDisable = 0
    SET temp.IsExist = 1
    WHERE temp.IsValid = 1 
		AND grp.GroupID = ip_GroupID;
	
    SELECT 	temp.Username
		,	temp.CTSCustID
        ,	temp.CustID
        ,	CASE WHEN temp.IsValid = 0 OR temp.IsExist = 0 THEN "Invalid Account"
			ELSE NULL END AS ErrorMsg
    FROM Temp_Username AS temp;
    
END$$
DELIMITER ;