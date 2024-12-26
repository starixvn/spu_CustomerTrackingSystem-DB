/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF`()
    SQL SECURITY INVOKER
spc:BEGIN 
	/*
		Created:	20241226@Victoria.Le
		Task :		Credit - Super/Master Direct Member - Update values for MRecommend/Recommend
		DB:			CTS_DataCenter

		Revisions:
			- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
                
        Param's Explanation:
        Example:
			- CALL CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF();
	*/ 
	
	DECLARE lv_Batchsize						INT;
	DECLARE lv_MaxCTSCustID						BIGINT;
	DECLARE lv_MaxModifiedTime					DATETIME;
	
	DECLARE lv_FromID							BIGINT DEFAULT 0;
	DECLARE lv_ToID								BIGINT DEFAULT 0;
	DECLARE lv_MaxID							BIGINT DEFAULT 0;
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
			ID 				BIGINT AUTO_INCREMENT PRIMARY KEY
		,	CTSCustID		BIGINT 
		,	ModifiedTime	DATETIME(4) 
		,	KEY IX_Temp_CTSCustID_DIFF_CTSCustID (CTSCustID)
	);
	
	INSERT INTO Temp_CTSCustID_DIFF (CTSCustID,ModifiedTime)
	SELECT CTSCustID,ModifiedTime
	FROM CTS_DataCenter.CTSCustomer
	WHERE CTSCustID <= lv_MaxCTSCustID
		AND ModifiedTime > lv_MaxModifiedTime
		AND MRecommend <> MRecommend_new
		AND Recommend <> Recommend_new
	;
	
	SELECT MAX(ID), MAX(ModifiedTime)
	INTO lv_MaxID, lv_NextModifiedTime
	FROM Temp_CTSCustID_DIFF;
	
	IF (lv_MaxID > 0) THEN
		WHILE (lv_ToID <= lv_MaxID)
		DO
			SET lv_FromID = lv_ToID + 1;
			SET lv_ToID = lv_ToID + lv_Batchsize;
			
			UPDATE CTS_DataCenter.CTSCustomer AS cust
				INNER JOIN Temp_CTSCustID_DIFF AS tmp ON tmp.CTSCustID = cust.CTSCustID
			SET 	cust.MRecommend_new = cust.MRecommend
				,	cust.Recommend_new = cust.Recommend
			WHERE tmp.ID >= lv_FromID AND tmp.ID <= lv_ToID;
			
		END WHILE;
		
		UPDATE CTS_DataCenter.SystemParameter 
		SET ParameterValue = lv_NextModifiedTime
		WHERE ParameterID = 992;
	
	END IF;

END$$

DELIMITER ;