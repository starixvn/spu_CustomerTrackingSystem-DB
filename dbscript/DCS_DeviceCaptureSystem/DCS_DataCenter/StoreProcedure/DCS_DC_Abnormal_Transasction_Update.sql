/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Update`(
	IN ip_TransJson LONGTEXT,
    IN ip_MaxID BIGINT UNSIGNED
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
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    IF ip_TransJson <> '' THEN
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
    END IF;
    
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    IF ip_MaxID IS NOT NULL AND ip_MaxID > 0 THEN
		UPDATE DCS_DataCenter.SystemSetting AS ss
		SET 	ss.VValue = CONCAT('', ip_MaxID)
		   ,	ss.UpdatedTime = lv_CurrentDatetime
		WHERE VGroup=lv_SystemSettingVGroup 
			AND VName=lv_SystemSettingVName;
    END IF;
END$$
DELIMITER ;
