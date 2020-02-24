DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSTransactionIPToCTSAssociationByIP $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_TransformDCSTransactionIPToCTSAssociationByIP(IN ip_TransactionIPJson JSON)
BEGIN
	/*
		Created:	20190815@Terry.Nguyen
		Task :		Update User Agent (OS, Browser)
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_TransformDCSTransactionIPToCTSAssociationByIP' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Transform DCS.TransactionIP To CTS.AssociationByIP ';		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     

	DROP TABLE IF EXISTS Temp_TransactionIP;

	CREATE TEMPORARY TABLE Temp_TransactionIP
	( 
		TransID			BIGINT				UNSIGNED	NOT NULL
		, AccountID			INT				UNSIGNED	NOT NULL 
		, SubscriberID		INT				NOT NULL
		, IP				VARCHAR(50)			NULL
		, IPID				DECIMAL(50,0)		NULL
		, TransTime			TIMESTAMP(4)	NOT NULL
        , CTSCustID			BIGINT			UNSIGNED
	);

	#=======================================================
    DROP TABLE IF EXISTS Temp_AssociationIP;

	CREATE TEMPORARY TABLE Temp_AssociationIP
	( 
		CTSCustID			BIGINT	UNSIGNED
		, IP				VARCHAR(50)
		, IPID				DECIMAL(50,0)
		, SubscriberID		INT
		, CreatedTime		TIMESTAMP(4)
		, LastLoginTime		TIMESTAMP(4)
	);
	#===================================================================================================================
	INSERT INTO Temp_TransactionIP(TransID, AccountID, SubscriberID, IP, IPID, TransTime)
	SELECT 	tip.TransID
			, tip.AccountID
            , tip.SubscriberID
            , tip.IP
            , tip.IPID
            , tip.TransTime
	FROM
	JSON_TABLE(
				ip_TransactionIPJson
				, "$[*]" COLUMNS(
								TransID				BIGINT			PATH "$.TransId"
								, AccountID			INT				PATH "$.AccountId"  
                                , SubscriberID		INT				PATH "$.SubscriberId"   
								, IP				VARCHAR(50)		PATH "$.Ip"
								, IPID				DECIMAL(50,0)	PATH "$.IpId"
								, TransTime			TIMESTAMP(4)	PATH "$.TransTime"
								)
				) AS  tip;
	# =====================================================================================
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	UPDATE		Temp_TransactionIP AS tip
	INNER JOIN	CTS_DataCenter.CustDCSAccount AS ca
				ON tip.AccountID = ca.AccountID
	SET			tip.CTSCustID = ca.CTSCustID;
    
    INSERT INTO Temp_AssociationIP(CTSCustID, IP, IPID, SubscriberID, CreatedTime, LastLoginTime)
    SELECT		tip.CTSCustID
				, tip.IP
                , tip.IPID
                , tip.SubscriberID
                , MIN(tip.TransTime) AS  CreatedTime
				, MAX(tip.TransTime) AS  LastLoginTime
    FROM		Temp_TransactionIP AS tip
    WHERE		tip.CTSCustID IS NOT NULL
	GROUP BY	tip.CTSCustID,  tip.IP, tip.IPID, tip.SubscriberID;
        
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;	

	INSERT IGNORE INTO CTS_DataCenter.AssociationByIP(CTSCustID, IP, IPID, SubscriberID, CreatedTime, LastLoginTime, InsertTime)
	SELECT		tap.CTSCustID
				, tap.IP
                , tap.IPID
                , tap.SubscriberID
                , tap.CreatedTime
                , tap.LastLoginTime
                , CURRENT_TIMESTAMP(4) AS InsertTime
	FROM 		Temp_AssociationIP	AS tap;
    
	UPDATE 		CTS_DataCenter.AssociationByIP AS aip
    INNER JOIN	Temp_AssociationIP AS tap
				ON aip.CTSCustID = tap.CTSCustID
					AND aip.IPID = tap.IPID
	SET			aip.LastLoginTime = GREATEST(aip.LastLoginTime,tap.LastLoginTime);

    UPDATE		DCS_DataCenter.TransactionIP AS tp
    INNER JOIN	Temp_TransactionIP	AS tip
				ON	tip.TransID = tp.TransID
	SET			tp.IsCTSTransformed = 1
	WHERE		tip.CTSCustID IS NOT NULL;    
	
	# =====================================================================================
	DROP TABLE IF EXISTS Temp_TransactionIP;
	#=======================
    
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    
    ### PERFORMANCE: END
END$$

DELIMITER ;