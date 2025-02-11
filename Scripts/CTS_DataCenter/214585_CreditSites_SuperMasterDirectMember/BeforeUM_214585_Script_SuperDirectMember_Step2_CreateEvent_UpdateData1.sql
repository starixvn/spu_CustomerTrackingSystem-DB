/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241226@Victoria.Le
	Task :		Credit - Super/Master Direct Member - Update values for MRecommend/Recommend
	DB:			CTS_DataCenter

	Revisions:
		- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
		- 20241226@Victoria.Le: 	Adjust Event to update MRecommend/Recommend to latest CTSCustID [RedmineID: #214585]
			
	Param's Explanation:
	Example:
		
*/

USE CTS_DataCenter;

DELIMITER |
ALTER EVENT EV_CTS_DC_Adhoc_CreditSMDirectMember_Update
    ON SCHEDULE
		 EVERY 15 SECOND
    DO
      BEGIN

		DECLARE lv_MinCTSCustID				BIGINT DEFAULT 0;
		DECLARE lv_BatchSize				BIGINT DEFAULT 0;
		DECLARE lv_NextCTSCustID			BIGINT DEFAULT 0;
		DECLARE lv_TotalExecutionSP			BIGINT DEFAULT 0;
		DECLARE lv_LastExecTime				DATETIME;
		DECLARE lv_LastStatus				VARCHAR(20);
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @errCode = RETURNED_SQLSTATE, @errMsg = MESSAGE_TEXT;
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update', @errCode, @errMsg, NOW(), NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';
			
		END;
		
		SELECT LastExecTime, Status
		INTO lv_LastExecTime, lv_LastStatus
		FROM CTS_DataCenter.SystemEventStatus
		WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';
		
		IF (lv_LastStatus IN ('Start','Complete')) THEN
			INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
			SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update', NULL, CONCAT('LastStatus:',lv_LastStatus), lv_LastExecTime, NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';
		
		ELSEIF (lv_LastStatus = 'Stop') THEN
		
			SELECT ParameterValue
			INTO lv_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 995;
			
			SELECT ParameterValue
			INTO lv_MinCTSCustID
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 994;
			
			SELECT ParameterValue
			INTO lv_TotalExecutionSP
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 993;

			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';

			CAll CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_Update(lv_BatchSize,lv_MinCTSCustID,lv_NextCTSCustID); 
			
			IF (lv_MinCTSCustID = lv_NextCTSCustID) THEN
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Complete' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';
				
			ELSEIF ((lv_MinCTSCustID < lv_NextCTSCustID)) THEN
			
				UPDATE CTS_DataCenter.SystemParameter 
				SET ParameterValue = lv_NextCTSCustID
				WHERE ParameterID = 994;
				
				UPDATE CTS_DataCenter.SystemParameter 
				SET ParameterValue = (lv_TotalExecutionSP + 1)
				WHERE ParameterID = 993;
			
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Stop' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update';
			END IF;
		
		END IF;
		
	END |

DELIMITER ;