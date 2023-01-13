DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCoupleInfo`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCoupleInfo`(
		IN 	ip_CustID1			BIGINT UNSIGNED
	,	IN 	ip_CustID2			BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230112@Victoria.Le
		Task:		Get Couple Info
		DB:			SPU_AIML
		Original:

		Revisions:
			- 20230112@Victoria.Le: Initial Writting [Redmine ID: #181994]
		
        Param's Explanation (filtered by):
			ID pf ip_CustID1 < ID of ip_CustID2
		Example:
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCoupleInfo (@ip_CustID1 := 48641832, @ip_CustID2:=50846222);
			
	*/
    
    DECLARE lv_ToDate 			DATE DEFAULT NOW();
    DECLARE lv_FromDate			DATE;
    DECLARE lv_TotalCount		BIGINT DEFAULT 0;
    
    SET lv_FromDate = DATE_SUB(lv_ToDate, INTERVAL 31 DAY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfo;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfo( 		
			CoupleID			BIGINT UNSIGNED NOT NULL
		, 	CreatedDate			DATE
        ,	IsShow				SMALLINT DEFAULT 0
        ,	PRIMARY KEY (CoupleID,CreatedDate)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfoDetails;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfoDetails( 		
			CoupleID			BIGINT UNSIGNED NOT NULL
		, 	CreatedDate			DATE
        ,	FraudTransList		VARCHAR(3000)
        ,	Rn					BIGINT
    );
    
    
    INSERT INTO Temp_GB3S_CoupleInfo
    (
			CoupleID
		,	CreatedDate
    )
	SELECT 	CoupleID
		,	CreatedDate
	FROM SPU_AIML.GB_3S_CoupleInfo
	WHERE CustID1 = ip_CustID1
		AND CustID2 = ip_CustID2
		AND CreatedDate BETWEEN lv_FromDate AND lv_ToDate;
        
	SELECT COUNT(1)
    INTO lv_TotalCount
    FROM Temp_GB3S_CoupleInfo;
    
    SET lv_TotalCount = IFNULL(lv_TotalCount,0);
    
    IF lv_TotalCount > 0 THEN
        INSERT INTO Temp_GB3S_CoupleInfoDetails 
        (
				CoupleID
			,	CreatedDate
			,	FraudTransList
			,	Rn
        )
        SELECT	cfi.CoupleID	
			,	temp.CreatedDate
            ,	cfi.FraudTransList
			,	ROW_NUMBER() OVER (PARTITION BY cfi.FraudTransList ORDER BY cfi.CreatedDate DESC)
		FROM SPU_AIML.GB_3S_CoupleFraudInfo AS cfi
			INNER JOIN Temp_GB3S_CoupleInfo AS temp ON temp.CoupleID = cfi.CoupleID
		WHERE cfi.CreatedDate BETWEEN lv_FromDate AND lv_ToDate;

		UPDATE Temp_GB3S_CoupleInfo AS temp1
			INNER JOIN Temp_GB3S_CoupleInfoDetails AS temp2 ON temp2.CoupleID = temp1.CoupleID 
															AND temp2.CreatedDate = temp1.CreatedDate
		SET 	temp1.IsShow = 1
        WHERE 	temp2.Rn = 1;
        
	ELSE
		INSERT INTO Temp_GB3S_CoupleInfo
		(
				CoupleID
			,	CreatedDate
            ,	IsShow
		)
		SELECT 	CoupleID
			,	CreatedDate
            ,	1
		FROM SPU_AIML.GB_3S_CoupleInfo
		WHERE CustID1 = ip_CustID1
			AND CustID2 = ip_CustID2
			AND CreatedDate < lv_FromDate
		ORDER BY CreatedDate DESC
		LIMIT 1;
        
    END IF;
    
    SELECT 	CoupleID
		,	DATE_SUB(CreatedDate, INTERVAL 30 DAY) AS FromDate
        ,	CreatedDate AS ToDate
	FROM 	Temp_GB3S_CoupleInfo
	WHERE 	IsShow = 1;
    
END$$
DELIMITER ;