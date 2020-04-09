DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.zzzIssueLoginName_Step3_RemoveCustIDNULL_CTSCustomer$$

CREATE PROCEDURE DCS_DataCenter.zzzIssueLoginName_Step3_RemoveCustIDNULL_CTSCustomer()
BEGIN
	/*
		Created:	20200313@CaseyHuynh
		Task :		Wrong LoginName
	*/
    
	DECLARE vr_MaxID BIGINT;
    
	DECLARE vr_FromID BIGINT;
    DECLARE vr_ToID BIGINT;
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
	
    SELECT	MIN(zz.CTSCustID), MAX(zz.CTSCustID)
    INTO 	 vr_FromID, vr_MaxID
	FROM 	CTS_DataCenter.zzzIssueLoginName_CTSCustomer AS zz
    INNER JOIN 	CTS_DataCenter.CTSCustomer AS ct
				ON ct.CTSCustID = zz.CTSCustID;
    

   WHILE (vr_FromID < vr_MaxID)  
   DO
		SET vr_ToID = (	SELECT MAX(tmp.CTSCustID) 
							FROM (SELECT CTSCustID FROM CTS_DataCenter.zzzIssueLoginName_CTSCustomer WHERE CTSCustID >= vr_FromID LIMIT 500) AS tmp);
		SELECT vr_FromID, vr_MaxID;
        DELETE 	ct
        FROM 	CTS_DataCenter.CTSCustomer AS ct
        INNER JOIN	CTS_DataCenter.zzzIssueLoginName_CTSCustomer AS zz
					ON ct.CTSCustID = zz.CTSCustID
        WHERE		ct.CTSCustID BETWEEN vr_FromID AND vr_ToID;
        
        SET vr_FromID = vr_ToID + 1 ;
        
	END WHILE;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;