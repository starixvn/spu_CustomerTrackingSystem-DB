/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingLoginTransaction_GetPackage`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingLoginTransaction_GetPackage`(
		IN ip_BatchSize     INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231009@Jonathan.Doan
	Task : Get Package of MissingLoginTransaction by batch
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231009@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Summary_MissingLoginTransaction_GetPackage(10);
	*/
    
    DECLARE CONST_SUMMARY_MAXTRANSDATE INT DEFAULT 2;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_TotalRecord INT UNSIGNED DEFAULT 0;
	DECLARE lv_NoOfBatch INT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxTransDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransDate = (SELECT DATE(VValue) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_MAXTRANSDATE);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BetTransactionSummary; 
    
    CREATE TEMPORARY TABLE Temp_BetTransactionSummary(		
		    MinID			BIGINT UNSIGNED
        ,   MaxID			BIGINT UNSIGNED
        ,   BatchCount		INT
    ) ENGINE = MEMORY;
    
	SET @RowId = 0;
    
    SET lv_TotalRecord = (SELECT COUNT(1) FROM DCS_DataTrace.BetTransactionSummary WHERE TransDate = lv_MaxTransDate);
    SET lv_NoOfBatch = CEIL(lv_TotalRecord/ip_BatchSize);
    
    INSERT INTO Temp_BetTransactionSummary (MinID, MaxID, BatchCount)
    SELECT  MIN(tmp.ID) AS MinID
        ,   MAX(tmp.ID) AS MaxID
        ,   SUM(1) AS BatchCount
	FROM (
		SELECT	@RowId := @RowId+1
			,   ID	
			,   CEIL(@RowId/ip_BatchSize) AS batchID
		FROM DCS_DataTrace.BetTransactionSummary
		WHERE TransDate = lv_MaxTransDate
        ORDER BY ID ASC
	) AS tmp
	GROUP BY batchID;
    
    SELECT	MinID
	    ,   MaxID
	FROM Temp_BetTransactionSummary;
END$$
DELIMITER ;
