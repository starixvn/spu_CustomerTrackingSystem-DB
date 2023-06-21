/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_MonitorTransaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_MonitorTransaction_Get`(
		IN ip_RptDate 			DATE
	,	IN ip_LimitShowCust 	INT
        
	,	OUT op_CountResult 		INT UNSIGNED
	,	OUT op_ListUserName 	VARCHAR(2000)
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20230606@Jonathan.Doan
	    Task : Monitor Transform Transaction Level Customer
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
			-	20230606@Jonathan.Doan: Created [Redmine ID: 189323]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_MonitorTransaction_Get('2023-06-06');
    */    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MonitorTransaction;
    CREATE TEMPORARY TABLE Temp_MonitorTransaction(
			CustID		 	INT UNSIGNED PRIMARY KEY 
        ,	UserName		VARCHAR(50) NULL
    );
    
    INSERT INTO Temp_MonitorTransaction(CustID, UserName)
    SELECT	CustID
		,	UserName
	FROM DCS_DataCenter.MonitorTransaction
	WHERE LastScanDate = ip_TransDate;
    
    SELECT COUNT(CustID)
    INTO op_CountResult
    FROM Temp_MonitorTransaction;
    
	SELECT REPLACE(GROUP_CONCAT(UserName ORDER BY CustID ASC), ',', ', ')
    INTO op_ListUserName
    FROM Temp_MonitorTransaction
    LIMIT ip_LimitShowCust;
    
END$$
DELIMITER ;
