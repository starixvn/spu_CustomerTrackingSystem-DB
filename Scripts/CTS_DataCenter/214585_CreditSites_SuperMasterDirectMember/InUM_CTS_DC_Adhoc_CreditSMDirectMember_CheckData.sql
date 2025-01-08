/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Adhoc_CreditSMDirectMember_CheckData`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Adhoc_CreditSMDirectMember_CheckData`()
    SQL SECURITY INVOKER
spc:BEGIN 
	/*
		Created:	20241226@Victoria.Le
		Task :		Credit - Super/Master Direct Member - Check MRecommend/Recommend < 0 (unitl this feature is released)
		DB:			CTS_DataCenter

		Revisions:
			- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
                
        Param's Explanation:
        Example:
			- CALL CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_CheckData();
	*/ 
	
	DECLARE lv_Batchsize						INT;
	DECLARE lv_MaxCTSCustID						BIGINT;
	DECLARE lv_MaxModifiedTime					DATETIME;
	DECLARE lv_MinCTSCustID_Diff				BIGINT;
	DECLARE lv_MaxCTSCustID_Diff				BIGINT;
	DECLARE lv_MaxModifiedTime_Diff				DATETIME(4);
	DECLARE lv_Total_Diff						BIGINT;
	
	DECLARE lv_NextCTSCustID					BIGINT;
	DECLARE lv_NextModifiedTime					DATETIME(4);
	
	SELECT ParameterValue
	INTO lv_Batchsize
	FROM CTS_DataCenter.SystemParameter
	WHERE ParameterID = 995;
	
	SELECT ParameterValue
	INTO lv_MaxCTSCustID
	FROM CTS_DataCenter.SystemParameter
	WHERE ParameterID = 994;
	
	SELECT ParameterValue
	INTO lv_MaxModifiedTime
	FROM CTS_DataCenter.SystemParameter
	WHERE ParameterID = 992;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID_DIFF;
    CREATE TEMPORARY TABLE Temp_CTSCustID_DIFF (
			CTSCustID		BIGINT PRIMARY KEY
		,	ModifiedTime	DATETIME(4)
	);
	
	INSERT IGNORE INTO Temp_CTSCustID_DIFF (CTSCustID,ModifiedTime)
	SELECT CTSCustID,ModifiedTime
	FROM CTS_DataCenter.CTSCustomer
	WHERE CTSCustID <= lv_MaxCTSCustID
		AND ModifiedTime >= lv_MaxModifiedTime
		AND (MRecommend < 0 OR Recommend < 0)
	;
	
	SELECT MAX(ModifiedTime), COUNT(1),MIN(CTSCustID), MAX(CTSCustID)
	INTO lv_MaxModifiedTime_Diff, lv_Total_Diff, lv_MinCTSCustID_Diff, lv_MaxCTSCustID_Diff
	FROM Temp_CTSCustID_DIFF;
	
	IF (lv_MinCTSCustID_Diff > 0) THEN
		INSERT INTO CTS_DataCenter.Adhoc_StoredProcedureExecError(StoredProcedureName, ErrCode, ErrMsg, ErrDate, ErrDateTime)
		SELECT 'CTS_DC_Adhoc_CreditSMDirectMember_CheckData', NULL, CONCAT('MaxScan:',lv_MaxCTSCustID,'|MinDiff:',lv_MinCTSCustID_Diff,'|MaxDiff:',lv_MaxCTSCustID_Diff,'|MinTimeScan:',lv_MaxModifiedTime,'|TotalDiff:',lv_Total_Diff), lv_MaxModifiedTime_Diff, NOW();
	
	END IF;
	
	SELECT MAX(CTSCustID),MIN(ModifiedTime)
	INTO lv_NextCTSCustID,lv_NextModifiedTime
	FROM CTS_DataCenter.CTSCustomer
	WHERE CTSCustID > lv_MaxCTSCustID;
	
	UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = IFNULL(lv_NextCTSCustID,lv_MaxCTSCustID + 1)
	WHERE ParameterID = 994;
	
	UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = IFNULL(lv_NextModifiedTime,DATE_ADD(lv_MaxModifiedTime, INTERVAL 1 SECOND))
	WHERE ParameterID = 992;

END$$

DELIMITER ;