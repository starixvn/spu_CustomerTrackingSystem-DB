/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Association_GetDevicesPerAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Association_GetDevicesPerAccount`(
		IN ip_NoOfDevice	INT
	,	IN ip_LastDay		INT
	,	IN ip_PageSize		INT
	,	IN ip_PageIndex		INT
    
	,	OUT op_TotalPages	INT
	,	OUT op_TotalRows	INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20250521@Jonathan.Doan
	Task : Get Devices Per Account (Sub site)
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20230321@Jonathan.Doan: Created [Redmine ID: 227652]
		
	Param's Explanation (filtered by):

	Example:
		SET @NoOfDevice	= 1;
		SET @LastDay	= 5;
		SET @PageSize	= 5;
		SET @PageIndex	= 1;

		CALL DCS_DataCenter.DCS_DC_Association_GetDevicesPerAccount(@NoOfDevice, @LastDay, @PageSize, @PageIndex, @op_TotalPages, @op_TotalRows);
        SELECT @op_TotalPages,@op_TotalRows;
	*/
    
    DECLARE lv_CutoffDate	DATE;
    DECLARE lv_Offset 		INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountNoOfDevice;
	CREATE TEMPORARY TABLE Temp_AccountNoOfDevice (
            AccountID		BIGINT UNSIGNED PRIMARY KEY
		,	NoOfDevice		INT
	);
    
	SET lv_CutoffDate = DATE_SUB(NOW(), INTERVAL ip_LastDay DAY);

	INSERT INTO Temp_AccountNoOfDevice(AccountID, NoOfDevice)
	SELECT	ass.AccountID
		,	COUNT(ass.DeviceID) AS NoOfDevice
	FROM DCS_DataCenter.Association AS ass
		INNER JOIN DCS_DataCenter.Account AS acc ON ass.AccountID = acc.AccountID
	WHERE acc.LastLoginTime >= lv_CutoffDate
	GROUP BY ass.AccountID, acc.LoginName
	HAVING COUNT(ass.DeviceID) >= ip_NoOfDevice;
    
    SET op_TotalRows = (SELECT COUNT(1) FROM Temp_AccountNoOfDevice);
    
    IF op_TotalRows > 0 THEN
		SET ip_PageSize = LEAST(ip_PageSize, op_TotalRows);
		SET op_TotalPages = CEIL(op_TotalRows / ip_PageSize);
		SET lv_Offset = (ip_PageIndex - 1) * ip_PageSize;
        
		SELECT	tmp.AccountID
			,	acc.LoginName
			,	tmp.NoOfDevice
		FROM Temp_AccountNoOfDevice AS tmp
			INNER JOIN DCS_DataCenter.Account AS acc ON acc.AccountID = tmp.AccountID
		LIMIT ip_PageSize
		OFFSET lv_Offset;
	ELSE
		SET op_TotalPages = 0;
		SET op_TotalRows = 0;
    END IF;
    
END$$
DELIMITER ;