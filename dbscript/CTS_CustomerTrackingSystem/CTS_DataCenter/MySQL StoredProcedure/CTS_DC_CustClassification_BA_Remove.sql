/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BA_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BA_Remove`(
		IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20200705@Casey.Huynh
		Task :		New Category BA 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200705@Casey.Huynh [Redmine ID: #174219]: Created
            
		Param's Explanation:
            
		Example:
			CALL CTS_DC_CustClassification_BA_Insert('1,2,3,4');
	*/
    
    
    
    /*********************User Log*************************************************************/	
    IF ip_FromAction = 1 THEN
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT 10 AS LogTypeID
			, 	lv_SPName
			, 	CONCAT('Remove VVIP: CTSCustID', tmpCus.CTSCustID,'; AffectDownline_', ip_AffectDownline,'; CategoryID_', lv_CategoryID)
            ,	lv_CurrentDateTime
            , 	tmpCus.CreatedBy
        FROM Temp_Customer AS tmpCus;
    END IF;
    
END$$
DELIMITER ;