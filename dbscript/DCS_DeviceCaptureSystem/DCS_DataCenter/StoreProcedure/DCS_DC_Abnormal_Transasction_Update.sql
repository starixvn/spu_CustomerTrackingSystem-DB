/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Update`(
	IN ip_TransJson LONGTEXT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20230321@Jonathan.Doan
	Task : Support return new device login for Alpha
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20230321@Jonathan.Doan: Update status for Completed Data [Redmine ID: 185185]
		
	Param's Explanation (filtered by):

	Example:
		- CALL DCS_DataCenter.DCS_DC_Abnormal_Transasction_Update(10);
	*/
    DECLARE lv_SystemSettingVGroup VARCHAR(128) DEFAULT 'DCS_AbnormalTransaction_Processed';
    DECLARE lv_SystemSettingVName VARCHAR(128) DEFAULT 'MaxID';
    DECLARE lv_SystemSettingVValue BIGINT UNSIGNED;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_InputTrans(
			ID				BIGINT	UNSIGNED PRIMARY KEY
		, 	Status			TINYINT
	);
    
    INSERT INTO Temp_InputTrans(
			ID
		,	Status
	)
	SELECT	tmp.ID
		,	tmp.Status
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
					ID					BIGINT UNSIGNED	PATH "$.ID"
				,	Status				TINYINT			PATH "$.Status"
			)
		) AS tmp;
    
    UPDATE DCS_DataCenter.AbnormalTransasction AS trans
		INNER JOIN Temp_InputTrans AS tmp ON tmp.ID = trans.ID
	SET trans.Status = tmp.Status;
    
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    SELECT MAX(ID)
    INTO lv_SystemSettingVValue
	FROM Temp_InputTrans;
    
    UPDATE DCS_DataCenter.SystemSetting AS ss
	SET 	ss.VValue = CONCAT('', lv_SystemSettingVValue)
	   ,	ss.UpdatedTime = lv_CurrentDatetime
    WHERE VGroup=lv_SystemSettingVGroup 
		AND VName=lv_SystemSettingVName;
END$$
DELIMITER ;
