DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetAffectedEvidence $$

CREATE PROCEDURE CTS_DC_GetAffectedEvidence (
	IN ip_CTSCustID BIGINT,    
    IN ip_EvidenceCodes TEXT
)
BEGIN
	/*
		Created:	20200123@Thai
		Task:		Get affected evidences for CustID and evidence codes [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_GetAffectedEvidence (11113, '1.2,6.1,6.2')
	*/        
           
	DECLARE a INT Default 0 ;
	DECLARE str VARCHAR(255);
   	    
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
           ,cust.UserName2 As LoginID		   
           ,'Device' AS AssociationType
           ,ce.CreatedDate
           ,cust.LastLoginTime					
    FROM Evidence AS e 	
	INNER JOIN CustEvidence AS ce 
		   ON (e.EvidenceID = ce.EvidenceID)	
	INNER JOIN CTSCustomer AS cust
		   ON (cust.CTSCustID = ce.CTSCustID)	
    INNER JOIN tmpEvidenceCodes AS codes
		   ON (codes.EviCode = e.EvidenceCode)           
	WHERE e.IsActive = True
		  AND ce.Level = 2
		  AND ce.CTSCustID = ip_CTSCustID;          
          
    SELECT e.EvidenceID
		   ,e.EvidenceCode           
		   ,e.EvidenceName
		   ,e.EvidenceDesc           		   
           ,cust.UserName2 As LoginID		   
           ,'Device' AS AssociationType
           ,cre.CreatedDate
           ,cust.LastLoginTime					
    FROM Evidence AS e 	
	INNER JOIN CustRetractEvidence AS cre
		   ON (e.EvidenceID = cre.EvidenceID)	
	INNER JOIN CTSCustomer AS cust
		   ON (cust.CTSCustID = cre.CTSCustID)	
    INNER JOIN tmpEvidenceCodes AS codes
		   ON (codes.EviCode = e.EvidenceCode)           
	WHERE e.IsActive = True		  
		  AND cre.CTSCustID = ip_CTSCustID;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    	
END$$
DELIMITER ;