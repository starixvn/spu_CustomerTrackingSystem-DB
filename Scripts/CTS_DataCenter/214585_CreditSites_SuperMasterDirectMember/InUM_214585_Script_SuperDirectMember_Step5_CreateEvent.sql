/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241226@Victoria.Le
	Task :		Credit - Super/Master Direct Member - Check MRecommend/Recommend < 0 (unitl this feature is released)
	DB:			CTS_DataCenter

	Revisions:
		- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
			
	Param's Explanation:
	Example:

*/

USE CTS_DataCenter;

DELIMITER |
CREATE EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData
    ON SCHEDULE
		 EVERY 60 SECOND
    DO
      BEGIN

		DECLARE lv_LastExecTime				DATETIME;
		DECLARE lv_LastStatus				VARCHAR(20);
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @errCode = RETURNED_SQLSTATE, @errMsg = MESSAGE_TEXT;
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData', @errCode, @errMsg, NOW(), NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData';
			
		END;
		
		SELECT LastExecTime, Status
		INTO lv_LastExecTime, lv_LastStatus
		FROM CTS_DataCenter.SystemEventStatus
		WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData';
		
		IF (lv_LastStatus IN ('Start','Complete')) THEN
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData', NULL, CONCAT('LastStatus:',lv_LastStatus), lv_LastExecTime, NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData';
		
		ELSEIF (lv_LastStatus = 'Stop') THEN

			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData';

			CAll CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_CheckData(); 
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData';
		
		END IF;
		
	END |

DELIMITER ;