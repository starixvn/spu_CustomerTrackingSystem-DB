/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TransformCTSCustomerRetryManual`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TransformCTSCustomerRetryManual`(IN ip_fromCTSCustID BIGINT, IN ip_toCTSCustID BIGINT, IN ip_Batch INT)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20201117@CaseyHuynh
		Task:		
		DB:			This script use to scanning CTSCustomer to:
					+ update LastLoginTime
                    + Retry Transform Account(Set Account.IsCTSTransformed = 0) if matching Username and UserName2
		Original:

		Revisions:
			- 20201117@CaseyHuynh: Created  [RedmineID : #145277]
            - 20201126@CaseyHuynh: Write Log [RedmineID : #145277]
	*/    
	
    DECLARE vrCTSCustID BIGINT;
    
     ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_TransformCTSCustomerRetryManual' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = CONCAT(ip_fromCTSCustID,'_',ip_toCTSCustID);		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO CTS_Log.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime, FromID)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime, ip_fromCTSCustID);
	  
	### PERFORMANCE: END  	
    SET vrCTSCustID = ip_fromCTSCustID;
    
    DROP TEMPORARY TABLE IF EXISTS temp_CTSCustomer;
    #14:02:03	CALL CTS_DataCenter.CTS_DC_TransformCTSCustomerRetryManual(1, 7000, 1000)	Error Code: 1051. Unknown table 'CTS_DataCenter.temp_CTSCustomer'	0.000 sec

	CREATE TEMPORARY TABLE temp_CTSCustomer (
			CTSCustID bigint unsigned NOT NULL AUTO_INCREMENT
            , MapAccountID BIGINT
			, SubscriberID int unsigned DEFAULT NULL
			, UserName varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
			, UserName2 varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
            
			, INDEX (CTSCustID, MapAccountID)
			           
			, INDEX  IX_CTSCustomer_UserName_UserName2 (SubscriberID, UserName)
			, INDEX  IX_CTSCustomer_UserName2 (SubscriberID, UserName2)
	) ENGINE=InnoDB;    
	
    WHILE vrCTSCustID < ip_toCTSCustID
    DO
			TRUNCATE TABLE temp_CTSCustomer;
            INSERT INTO temp_CTSCustomer(CTSCustID, SubscriberID, UserName, UserName2)
            SELECT 		cus.CTSCustID, cus.SubscriberID, cus.UserName
						, TRIM(LEADING sub.SubscriberPrefix FROM cus.UserName2 ) AS UserName2
            FROM 		CTS_DataCenter.CTSCustomer		AS cus
            LEFT JOIN	CTS_Admin.Subscriber			AS sub
						ON sub.SubscriberID = cus.SubscriberID
			WHERE		cus.CTSCustID > vrCTSCustID
            ORDER BY 	cus.CTSCustID
            LIMIT		ip_Batch;	
            
            UPDATE 		temp_CTSCustomer AS temp_cus
            INNER JOIN 	CTS_DataCenter.CustDCSAccount	AS cua
						ON  temp_cus.CTSCustID = cua.CTSCustID
			SET 		MapAccountID = AccountID;
            
            # Update LastLoginTime
           
            UPDATE		CTS_DataCenter.CTSCustomer AS cus
            INNER JOIN	temp_CTSCustomer AS tmp_cus
						ON cus.CTSCustID = tmp_cus.CTSCustID
            INNER JOIN	DCS_DataCenter.Account	AS acc
						ON tmp_cus.MapAccountID = acc.AccountID			
			SET			cus.LastLoginTime = acc.LastLoginTime
            WHERE		cus.LastLoginTime < acc.LastLoginTime
						AND tmp_cus.MapAccountID > 0;
			
            # Turn on Transformed Account if matching 
          
            UPDATE		DCS_DataCenter.Account	AS acc
            INNER JOIN	temp_CTSCustomer AS tmp_cus
						ON tmp_cus.SubscriberID = acc.SubscriberID
							AND tmp_cus.UserName = acc.LoginName
			SET			acc.IsCTSTransformed = 0		
            WHERE		tmp_cus.MapAccountID IS NULL;
          
            UPDATE		DCS_DataCenter.Account	AS acc
            INNER JOIN	temp_CTSCustomer AS tmp_cus
						ON tmp_cus.SubscriberID = acc.SubscriberID
							AND tmp_cus.UserName2 = acc.LoginName
			SET			acc.IsCTSTransformed = 0		
            WHERE		tmp_cus.MapAccountID IS NULL;            
            
    SET  vrCTSCustID =  (SELECT MAX(CTSCustID) FROM  temp_CTSCustomer);      
    
    ### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
	SELECT 	Count(1), Max(tas.CTSCustID)
    INTO	vrTotalRecord,  vrToID
    FROM	temp_CTSCustomer AS tas;    
    
    UPDATE	CTS_Log.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(SECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrTotalRecord
            , z.ToID		= vrToID
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    ### PERFORMANCE: END
    
    END WHILE;

END$$
DELIMITER ;
