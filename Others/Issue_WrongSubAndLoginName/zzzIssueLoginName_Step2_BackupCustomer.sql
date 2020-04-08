DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.zzzIssueLoginName_Step2_BackupCustomer$$

CREATE PROCEDURE DCS_DataCenter.zzzIssueLoginName_Step2_BackupCustomer()
BEGIN
	/*
		Created:	20200313@CaseyHuynh
		Task :		Wrong LoginName
	*/
    
	DECLARE vr_MaxID BIGINT;
	DECLARE vr_LoopID BIGINT DEFAULT 0;
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
	SET vr_MaxID = (SELECT	MAX(CTSCustID)
					FROM 	CTS_DataCenter.CTSCustomer
					WHERE	CustID IS NULL AND SubscriberID NOT IN (2367,2328));  
   
   WHILE (vr_LoopID <= vr_MaxID)  
   DO
		
        INSERT INTO zzzIssueLoginName_CTSCustomer
        SELECT 	*
        FROM	zzzIssueLoginName_CTSCustomer
        WHERE	CustID IS NULL AND SubscriberID NOT IN (2367,2328)
        LIMIT 	50000;
        
        SET vr_LoopID = (SELECT	MAX(CTSCustID) FROM zzzIssueLoginName_CTSCustomer);
	END WHILE;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;