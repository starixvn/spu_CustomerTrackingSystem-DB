/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Update`(
	IN ip_TransJson LONGTEXT,
    IN ip_MinID BIGINT UNSIGNED,
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
		- CALL DCS_DataCenter.DCS_DC_Abnormal_Transasction_Update('[{"ID":3,"Status":1}]', 1, 10);
	*/
    DECLARE lv_SystemSettingVGroup VARCHAR(128) DEFAULT 'DCS_AbnormalTransaction_Processed';
    DECLARE lv_SystemSettingVName VARCHAR(128) DEFAULT 'MaxID';
    DECLARE lv_StatusNotSend INT DEFAULT 2;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_InputTrans(
			AssociationID	BIGINT	UNSIGNED PRIMARY KEY
		, 	Status			TINYINT
	);

    IF ip_TransJson <> '' THEN
		INSERT INTO Temp_InputTrans(
				AssociationID
			,	Status
		)
		SELECT	tmp.AssociationID
			,	tmp.Status
		FROM JSON_TABLE(
				ip_TransJson,
				 "$[*]" COLUMNS(
						AssociationID			BIGINT UNSIGNED	PATH "$.AssociationID"
					,	Status		TINYINT			PATH "$.Status"
				)
			) AS tmp;
		
		UPDATE Temp_InputTrans AS tmp
			INNER JOIN DCS_DataCenter.NewAccountDevice AS trans ON tmp.AssociationID = trans.AssociationID
		SET trans.Status = tmp.Status
        ,	trans.ModifiedDate = lv_CurrentDatetime;
    END IF;
    
    /*****UPDATE status for Trans not send****************************************************/
	UPDATE DCS_DataCenter.NewAccountDevice AS trans
	SET trans.Status = lv_StatusNotSend
	,	trans.ModifiedDate = lv_CurrentDatetime
    WHERE trans.AssociationID BETWEEN ip_MinID AND ip_MaxID
		AND trans.AssociationID NOT IN (SELECT AssociationID FROM Temp_InputTrans);
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    IF ip_MaxID IS NOT NULL AND ip_MaxID > 0 THEN
		UPDATE DCS_DataCenter.SystemSetting AS sys
		SET 	sys.VValue = CONCAT('', ip_MaxID)
		   ,	sys.UpdatedTime = lv_CurrentDatetime
		WHERE VGroup=lv_SystemSettingVGroup 
			AND VName=lv_SystemSettingVName;
    END IF;
END$$
DELIMITER ;
