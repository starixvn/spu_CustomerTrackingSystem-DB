/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ArchiveCustomer_Reactivate_CheckExist`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ArchiveCustomer_Reactivate_CheckExist`(
		IN ip_CustIDs  LONGTEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20220713@Aries.Nguyen
		Task :		HotFix Customer NULL CC 
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20220713@Aries.Nguyen: Created [Redmine ID: #175406]
            
		Param's Explanation (filtered by):	

		Example:
			
	*/
    DECLARE lv_LastArchiveID 	BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustReactivate;
    CREATE TEMPORARY TABLE 		Temp_CustReactivate (
        	CustID				BIGINT UNSIGNED 
		,	ArchiveID			BIGINT UNSIGNED PRIMARY KEY 
    );    
    
	SELECT ParameterValue
	INTO lv_LastArchiveID
	FROM CTS_DataCenter.SystemParameter
	WHERE ParameterID = 45;
    
    INSERT INTO Temp_CustReactivate(ArchiveID, CustID)
	SELECT 	ar.ID AS ArchiveID
		,	ar.CustID
	FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.ArchiveCustomer_CTSCustomer AS ar ON ar.CustID = tmp.CustID AND ar.ID > lv_LastArchiveID;
        
	UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS ar 
	SET		ar.IsReactivated = 1
		,	ar.ReactivateDate = NOW()
    WHERE EXISTS (SELECT 1 FROM Temp_CustReactivate AS tmp WHERE ar.ID = tmp.ArchiveID);
    
    SELECT 	DISTINCT 
			CustID
    FROM Temp_CustReactivate;
END$$
DELIMITER ;

