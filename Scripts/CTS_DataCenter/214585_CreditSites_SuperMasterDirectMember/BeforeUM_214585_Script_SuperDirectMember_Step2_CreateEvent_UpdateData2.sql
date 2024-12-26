/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241226@Victoria.Le
	Task :		Credit - Super/Master Direct Member - Update values for MRecommend/Recommend
	DB:			CTS_DataCenter

	Revisions:
		- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
			
	Param's Explanation:
	Example:

*/

USE CTS_DataCenter;

DELIMITER |
CREATE EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF
    ON SCHEDULE
		 EVERY 1 DAY
    DO
      BEGIN

		DECLARE lv_LastExecTime				DATETIME;
		DECLARE lv_LastStatus				VARCHAR(20);
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @errCode = RETURNED_SQLSTATE, @errMsg = MESSAGE_TEXT;
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF', @errCode, @errMsg, NOW(), NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';
			
		END;
		
		SELECT LastExecTime, Status
		INTO lv_LastExecTime, lv_LastStatus
		FROM CTS_DataCenter.SystemEventStatus
		WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';
		
		IF (lv_LastStatus = 'Start') THEN
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF', NULL, 'LastStatus:Start', lv_LastExecTime, NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';
		
		ELSEIF (lv_LastStatus = 'Stop') THEN

			CAll CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF(); 
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF';
		
		END IF;
		
	END |

DELIMITER ;