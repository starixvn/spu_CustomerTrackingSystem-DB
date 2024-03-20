/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_ArchiveData_LoginTransactionSummary_Delete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_ArchiveData_LoginTransactionSummary_Delete`(
    IN ip_RetentionDays INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231020@Jonathan.Doan
	Task : Delete data from LoginTransactionSummary
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231020@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_ArchiveData_LoginTransactionSummary_Delete('2023-10-01');
	*/
    
    DECLARE lv_LastDate DATE DEFAULT CURRENT_DATE() - INTERVAL ip_RetentionDays DAY;
    
    DELETE FROM DCS_DataTrace.LoginTransactionSummary
    WHERE TransDate <= lv_LastDate;
    
END$$
DELIMITER ;
