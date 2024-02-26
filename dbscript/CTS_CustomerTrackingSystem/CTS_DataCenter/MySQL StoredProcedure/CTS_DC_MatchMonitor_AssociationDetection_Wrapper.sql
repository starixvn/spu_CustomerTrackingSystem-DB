/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_AssociationDetection_Wrapper`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_AssociationDetection_Wrapper`(
)
    SQL SECURITY INVOKER
sp:BEGIN 
/*
	Created:	20230614@Victoria.Le
	Task :		
	DB:			
	
	Description: 

	Revisions:	
		- 20230614@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		- 20230614@Victoria.Le: 	Update SP after renovating SP Association Detection and Match Monitor Rule Hedging [Redmine ID: #192172]
		- 20240226@Victoria.Le: 	Get incorrect column for next loop: LogInfo >> ListCustID [Redmine ID: #201271]
		
	Param's Explanation (filtered by):

	Example: CALL CTS_DataCenter.CTS_DC_MatchMonitor_AssociationDetection_Wrapper();
*/

	DECLARE lv_BeginDate 			DATETIME;
    DECLARE lv_Today				DATETIME DEFAULT CURDATE();
    DECLARE lv_MMDetailsID			BIGINT;
    DECLARE lv_MMDetailsInsertTime	DATETIME(3);
    DECLARE lv_LogInfo				LONGTEXT;
    DECLARE lv_DateValid			DATETIME;
    DECLARE lv_DateCount			TINYINT;
    DECLARE lv_GroupCount			BIGINT;
    DECLARE lv_CustCount_Org		BIGINT;
	DECLARE lv_CustCount_Detection	BIGINT;
    DECLARE lv_Monitor_ID			BIGINT;
	DECLARE lv_Next_MMDetailsID		BIGINT;
	
	DECLARE CONST_MMHedging_Reason	INT DEFAULT 1;
    
	SELECT ParameterValue
	INTO lv_BeginDate
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 141;
    
    SET lv_DateValid = DATE_SUB(lv_BeginDate, INTERVAL 1 DAY);
    
    SET lv_DateCount = TIMESTAMPDIFF(DAY,lv_DateValid,lv_Today);
    
    IF (lv_DateCount < 0 OR lv_DateCount >= 7) THEN
        LEAVE sp;
	ELSE
		SELECT ParameterValue
		INTO lv_MMDetailsID
		FROM CTS_DataCenter.SystemParameter 
		WHERE ParameterID = 142;
        
        IF (lv_MMDetailsID > 0) THEN
			SELECT ID
			INTO lv_Monitor_ID
            FROM CTS_DataCenter.MatchMonitor_AssociationDetection_Monitor AS m
            WHERE MMDetailsID = lv_MMDetailsID
            ORDER BY ID DESC
            LIMIT 1;
        
			DELETE 
            FROM CTS_DataCenter.MatchMonitor_AssociationDetection_Monitor AS m
			WHERE ID = lv_Monitor_ID;
            
        END IF;
    
		SELECT ListCustID,InsertTime,ID
		INTO lv_LogInfo,lv_MMDetailsInsertTime,lv_MMDetailsID
		FROM CTS_DataCenter.MatchMonitorDetails
		WHERE InsertTime >= lv_DateValid AND InsertTime < lv_Today
			AND (lv_MMDetailsID = 0 OR ID = lv_MMDetailsID)
            AND Reason = CONST_MMHedging_Reason
		ORDER BY ID
		LIMIT 1;
        
        WHILE (lv_MMDetailsID > 0) DO
        
			SET lv_GroupCount = 0;
			SET lv_CustCount_Org = 0;
            SET lv_CustCount_Detection = 0;
			
			IF (lv_LogInfo IS NULL) THEN
				INSERT INTO CTS_DataCenter.MatchMonitor_AssociationDetection_Monitor (MMDetailsID,LogInfo,MMDetailsInsertTime,CreatedDateTime)
                SELECT lv_MMDetailsID,lv_LogInfo,lv_MMDetailsInsertTime,NOW();
				
			ELSE
				CALL CTS_DataCenter.CTS_DC_AssociationDetection_DetectGroup_Monitor (lv_LogInfo);
            
				SELECT COUNT(DISTINCT GroupID)
				INTO lv_GroupCount
				FROM Temp_DetectGroup_GroupResult;
				
				IF (lv_GroupCount > 1) THEN
					INSERT INTO CTS_DataCenter.MatchMonitor_AssociationDetection_Monitor (MMDetailsID,LogInfo,MMDetailsInsertTime,CreatedDateTime)
					SELECT lv_MMDetailsID,lv_LogInfo,lv_MMDetailsInsertTime,NOW();
				ELSE
					WITH CTE AS (
						SELECT DISTINCT tmp.CustID
						FROM JSON_TABLE(CONCAT('[',lv_LogInfo,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
					)
					SELECT COUNT(1)
					INTO lv_CustCount_Org
					FROM CTE;
					
					SELECT COUNT(DISTINCT cus.CustID)
					INTO lv_CustCount_Detection
					FROM Temp_DetectGroup_Cust AS cus
						LEFT JOIN Temp_DetectGroup_GroupResult AS grp ON cus.CTSCustID = grp.CTSCustID
					WHERE IFNULL(grp.GroupID,0) <> 0;
					
					IF (lv_CustCount_Org > lv_CustCount_Detection) THEN
						INSERT INTO CTS_DataCenter.MatchMonitor_AssociationDetection_Monitor (MMDetailsID,LogInfo,MMDetailsInsertTime,CreatedDateTime)
						SELECT lv_MMDetailsID,lv_LogInfo,lv_MMDetailsInsertTime,NOW();
					END IF;
				END IF;
				
			END IF;
            
            UPDATE CTS_DataCenter.SystemParameter 
			SET ParameterValue = lv_MMDetailsID
			WHERE ParameterID = 142; 
            
            SELECT ListCustID,InsertTime,ID
            INTO lv_LogInfo,lv_MMDetailsInsertTime,lv_Next_MMDetailsID
            FROM CTS_DataCenter.MatchMonitorDetails
            WHERE ID > lv_MMDetailsID
				AND InsertTime >= lv_DateValid AND InsertTime < lv_Today
                AND Reason = CONST_MMHedging_Reason
            ORDER BY ID
            LIMIT 1;
            
            IF lv_Next_MMDetailsID >  lv_MMDetailsID THEN
				SET lv_MMDetailsID = lv_Next_MMDetailsID;
			ELSE
				SET lv_MMDetailsID = -1;
            END IF;
            
        END WHILE;

        IF (lv_MMDetailsID = -1) THEN
			UPDATE CTS_DataCenter.SystemParameter 
			SET ParameterValue = 0
			WHERE ParameterID = 142; 
        END IF;
    END IF;
	
END$$

DELIMITER ;