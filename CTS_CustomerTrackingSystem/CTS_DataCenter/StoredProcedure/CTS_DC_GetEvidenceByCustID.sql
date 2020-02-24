DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetEvidenceByCustID $$

CREATE PROCEDURE CTS_DC_GetEvidenceByCustID (
	IN ip_CustID INT,    
    IN ip_EvidenceCodes TEXT,
	IN ip_IsFlagged BIT
)
BEGIN
	/*
		Created:	20200123@Thai
		Task:		Get (Flagged or Affected) evidences by CustID [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
			IsFlagged = 1 OR NULL --> Get flagged (direct) evidences, else get affected evidences
        
        CALL CTS_DC_GetEvidenceByCustID (27, '1.1,6.1,6.2', 0)
	*/
        
    DECLARE EviLevel TINYINT;	
	DECLARE a INT Default 0 ;
	DECLARE str VARCHAR(255);
   	
    IF IFNULL(ip_IsFlagged, 1) = 1 THEN 
		SET EviLevel = 0;
	ELSE SET EviLevel = 2;
    END IF;
    
    /* Get evidence codes to table  */
    DROP TABLE IF EXISTS tmpEvidenceCodes;
    CREATE TEMPORARY TABLE tmpEvidenceCodes(
		EviCode VARCHAR(10) PRIMARY KEY    
	);
    
    IF ip_EvidenceCodes IS NOT NULL THEN
		Evidence_loop: LOOP
			 SET a = a + 1;
			 SET str = SPLIT_STR(ip_EvidenceCodes,",",a);
			 IF str = '' THEN
				LEAVE Evidence_loop;
			 END IF;         
			 INSERT INTO tmpEvidenceCodes VALUES (str);
		END LOOP Evidence_loop;
    END IF;
      
   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
	SELECT e.EvidenceID
		   ,e.EvidenceCode           
		   ,e.EvidenceName
		   ,e.EvidenceDesc           		   
		   ,e.CreatedDate
           ,ce.Level		   
           ,ce.Remark
           ,user.UserName
    FROM Evidence AS e 	
	INNER JOIN CustEvidence AS ce 
		   ON (e.EvidenceID = ce.EvidenceID)	
	INNER JOIN CTS_Admin.CTSUser AS user
		   ON (user.UserID = ce.CreatedBy)
    INNER JOIN tmpEvidenceCodes AS codes
		   ON (codes.EviCode = e.EvidenceCode)       
	WHERE e.IsActive = True
		  AND ce.CTSCustID = ip_CustID
          AND ce.Level = EviLevel;    
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    	
END$$
DELIMITER ;