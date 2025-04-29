/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_OpenSearch_FPFingerPrint_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_OpenSearch_FPFingerPrint_Get`(
	IN ip_FromDate		DATETIME,
	IN ip_ToDate		DATETIME,
	IN ip_BatchSize		INT,
	IN ip_LastID		BIGINT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20250429@Jonathan.Doan
	    Task : Get FP_FingerPrint
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20250428@Jonathan.Doan: Created [Redmine ID: #224502]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_OpenSearch_FPFingerPrint_Get('2025-03-24', '2025-05-01', 100, 0);
    */
    
    DECLARE CONST_DATABASE_NAME VARCHAR(255) DEFAULT 'DCS_DataCenter';
    DECLARE CONST_TABLE_NAME VARCHAR(255) DEFAULT 'FP_FingerPrint';
    
    DECLARE lv_MinID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxID BIGINT UNSIGNED DEFAULT 0;
    
    SELECT	MIN(MinID)
		,	MAX(MaxID)
    INTO lv_MinID, lv_MaxID
    FROM DCS_DataCenter.TableIDRange
    WHERE DatabaseName = CONST_DATABASE_NAME
		AND TableName = CONST_TABLE_NAME
        AND CreatedDate BETWEEN ip_FromDate AND ip_ToDate;
    
	IF lv_MinID = 0 THEN
		SELECT MaxID
		INTO lv_MinID
		FROM DCS_DataCenter.TableIDRange
		WHERE DatabaseName = CONST_DATABASE_NAME
			AND TableName = CONST_TABLE_NAME
			AND CreatedDate < ip_FromDate
		ORDER BY CreatedDate DESC
        LIMIT 1;
    END IF;
    
    SET lv_MinID := IFNULL(lv_MinID,0);
    SET lv_MaxID := IFNULL(lv_MaxID,0);
    
    SELECT	ID
		,	Code
        ,	Attribute
        ,	InsertedTime
    FROM DCS_DataCenter.FP_FingerPrint
    WHERE ID > LEAST(lv_MinID, ip_LastID)
		AND ID <= IF(lv_MaxID > 0, lv_MaxID, ID)
		AND InsertedTime >= ip_FromDate
		AND InsertedTime < DATE_ADD(ip_ToDate, INTERVAL 1 DAY)
	ORDER BY ID ASC
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;
