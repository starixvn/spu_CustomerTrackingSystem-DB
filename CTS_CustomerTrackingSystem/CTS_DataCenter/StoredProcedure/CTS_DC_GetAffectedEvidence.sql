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
		Task:		Get evidences which the member is affected and evidences which the member is retracted [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_GetAffectedEvidence (10515, '6.9')
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
    
    
    DROP TABLE IF EXISTS tmpAffectedEvidences;
    CREATE TEMPORARY TABLE tmpAffectedEvidences(
        CustEvidID BIGINT,
        CTSCustID BIGINT,
        FromCTSCustID BIGINT,
		EvidenceID SMALLINT,
        EvidenceCode VARCHAR(10),
        EvidenceName VARCHAR(50),        
        CreatedDate DATETIME
	);
    
    #=====GET AFFECTED EVIDENCES FOR MEMBER==========================
    
    INSERT INTO tmpAffectedEvidences (EvidenceID, CTSCustID, FromCTSCustID, EvidenceCode, EvidenceName, CreatedDate)
	SELECT e.EvidenceID
		   ,ce.CTSCustID
           ,ce.FromCustID
		   ,e.EvidenceCode           
		   ,e.EvidenceName					              
           ,ce.CreatedDate		
    FROM CustEvidence AS ce 	
	INNER JOIN Evidence AS e 
		   ON (ce.EvidenceID = e.EvidenceID)		
    INNER JOIN tmpEvidenceCodes AS codes
		   ON (codes.EviCode = e.EvidenceCode)           
	WHERE e.IsActive = True
		  AND ce.Level = 2
		  AND ce.CTSCustID = ip_CTSCustID
          AND ce.EvidenceID NOT IN (SELECT cre.EvidenceID
									FROM CustRetractEvidence AS cre
									WHERE cre.CTSCustID = ce.CTSCustID);
                                                                 
	#=====DISPLAY EVIDENCES CREATED BY==========================
    
    DROP TABLE IF EXISTS tmpEvidences;
    CREATE TEMPORARY TABLE tmpEvidences( 
		CTSCustID BIGINT,
		EvidenceID SMALLINT,
        EvidenceCode VARCHAR(10),        
        EvidenceName VARCHAR(50),
        LoginID VARCHAR(50),
        UserName VARCHAR(50),  
        AssociationType VARCHAR(50),
        LastLoginTime DATETIME,
        CreatedDate DATETIME,
        RowNumber SMALLINT
	);
    
    INSERT tmpEvidences(CTSCustID, 
    EvidenceID,     
    EvidenceCode, 
    EvidenceName,
    LoginID,
    UserName,
    AssociationType,
    LastLoginTime, 
    CreatedDate,
    RowNumber)
    SELECT 
		e.FromCTSCustID
		,e.EvidenceID 
		,e.EvidenceCode
        ,e.EvidenceName
        ,cust.UserName2
        ,cust.UserName
        ,'Device'
		,cust.LastLoginTime
        ,e.CreatedDate
        , ROW_NUMBER() OVER (PARTITION BY e.EvidenceID ORDER BY cust.LastLoginTime DESC) AS RowNumber
    FROM tmpAffectedEvidences AS e	 
	INNER JOIN CTSCustomer AS cust
		   ON (cust.CTSCustID = e.FromCTSCustID);	
    
    
	SELECT 
		CTSCustID
		,EvidenceID    
		,EvidenceCode
		,EvidenceName
		,LoginID
		,UserName
		,AssociationType
		,LastLoginTime
		,CreatedDate              
    FROM tmpEvidences 
    WHERE RowNumber <= 50;	        
          
    #=====GET RETRACTED EVIDENCES FOR MEMBER==========================
    SELECT e.EvidenceID
		   ,e.EvidenceCode           
		   ,e.EvidenceName
		   ,e.EvidenceDesc
		   ,cust.CTSCustID		   
           ,cust.UserName2 As LoginID
		   ,cust.UserName
		   ,'Device' AS AssociationType
           ,cre.Remark
           ,cre.CreatedDate
           ,user.UserName AS Creator
           ,cust.LastLoginTime					
    FROM Evidence AS e 	
	INNER JOIN CustRetractEvidence AS cre
		   ON (e.EvidenceID = cre.EvidenceID)	
	INNER JOIN CTSCustomer AS cust
		   ON (cust.CTSCustID = cre.CTSCustID)	
    INNER JOIN tmpEvidenceCodes AS codes
		   ON (codes.EviCode = e.EvidenceCode)           
	INNER JOIN CTS_Admin.CTSUser AS user
		   ON (user.UserID = cre.CreatedBy)
	WHERE e.IsActive = True		  
		  AND cre.CTSCustID = ip_CTSCustID;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    	
END$$
DELIMITER ;