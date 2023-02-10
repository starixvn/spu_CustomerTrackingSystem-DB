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
    DECLARE lv_FromDate60		DATE;
    DECLARE lv_TotalCount		BIGINT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfo;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfo( 		
			CoupleInfoID		BIGINT NOT NULL AUTO_INCREMENT
		,	CoupleID			BIGINT UNSIGNED NOT NULL
		, 	CreatedDate			DATE
        ,	IsShow				TINYINT DEFAULT 0
        ,	PRIMARY KEY (CoupleInfoID)
        ,	INDEX IX_Temp_GB3S_CoupleInfo_CC (CoupleID,CreatedDate)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfo_Copy;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfo_Copy( 		
			CoupleID			BIGINT UNSIGNED NOT NULL
		, 	CreatedDate			DATE
        ,	FirstCreatedDate	DATE
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfoDetails;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfoDetails( 		
			MatchID				BIGINT UNSIGNED
        ,	StateID				BIGINT UNSIGNED
		,	CoupleID			BIGINT UNSIGNED NOT NULL
		, 	CreatedDate			DATE
        ,	PRIMARY KEY (MatchID,StateID)
        ,	INDEX IX_Temp_GB3S_CoupleInfoDetails_CC (CoupleID,CreatedDate)
    );
    
	SET lv_FromDate 	= 	DATE_SUB(lv_ToDate, INTERVAL 31 DAY);
	SET lv_FromDate60 	=	DATE_SUB(lv_ToDate, INTERVAL 61 DAY);
    
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
		AND CreatedDate BETWEEN lv_FromDate AND lv_ToDate
	ORDER BY CreatedDate DESC;
        
	SELECT COUNT(1)
    INTO lv_TotalCount
    FROM Temp_GB3S_CoupleInfo;
    
    SET lv_TotalCount = IFNULL(lv_TotalCount,0);
    
    IF lv_TotalCount > 0 THEN
        INSERT IGNORE INTO Temp_GB3S_CoupleInfoDetails 
        (
				MatchID
            ,	StateID
			,	CoupleID
			,	CreatedDate
        )
        SELECT	cfi.MatchID
            ,	cfi.StateID
			,	cfi.CoupleID	
			,	cfi.CreatedDate
		FROM SPU_AIML.GB_3S_CoupleFraudInfo AS cfi
			INNER JOIN Temp_GB3S_CoupleInfo AS temp ON temp.CoupleID = cfi.CoupleID
														AND temp.CreatedDate = cfi.CreatedDate
		WHERE cfi.CreatedDate BETWEEN lv_FromDate AND lv_ToDate
        ORDER BY temp.CoupleInfoID;
        
        WITH CTE AS
        (
			SELECT DISTINCT CoupleID,CreatedDate
            FROM Temp_GB3S_CoupleInfoDetails
        )
        UPDATE Temp_GB3S_CoupleInfo AS temp1
			INNER JOIN CTE AS temp2 ON temp2.CoupleID = temp1.CoupleID
										AND temp2.CreatedDate = temp1.CreatedDate
		SET temp1.IsShow = 1;
        
        INSERT INTO Temp_GB3S_CoupleInfo_Copy
        (
				CoupleID
            ,	CreatedDate
            ,	FirstCreatedDate
        )
        WITH CTE2 AS
        (
			SELECT 	tmp.CoupleID
				,	tmp.CreatedDate
				,	MIN(cfi.CreatedDate) OVER (PARTITION BY cfi.MatchID,cfi.StateID) AS FirstCreatedDate
			FROM Temp_GB3S_CoupleInfoDetails AS tmp
				INNER JOIN SPU_AIML.GB_3S_CoupleFraudInfo AS cfi ON tmp.MatchID = cfi.MatchID
																	AND tmp.StateID = cfi.StateID
				INNER JOIN SPU_AIML.GB_3S_CoupleInfo AS ci ON ci.CoupleID = cfi.CoupleID
																AND ci.CreatedDate = cfi.CreatedDate
			WHERE ci.CustID1 = ip_CustID1 AND ci.CustID2 = ip_CustID2
				AND ci.CreatedDate BETWEEN lv_FromDate60 AND lv_ToDate
		)
        SELECT CoupleID, CreatedDate, MIN(FirstCreatedDate) AS FirstCreatedDate
        FROM CTE2
        GROUP BY CoupleID, CreatedDate;
        
        SELECT 	tmp1.CoupleInfoID
			,	tmp1.CoupleID
			,	tmp1.CreatedDate
            ,	tmp2.FirstCreatedDate
		FROM Temp_GB3S_CoupleInfo AS tmp1
			INNER JOIN Temp_GB3S_CoupleInfo_Copy AS tmp2 ON tmp2.CoupleID = tmp1.CoupleID
														AND tmp2.CreatedDate = tmp1.CreatedDate
		WHERE IsShow = 1
		ORDER BY CoupleInfoID;
		
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

		SELECT 	CoupleInfoID
			,	CoupleID
			,	CreatedDate
            ,	CreatedDate AS FirstCreatedDate
		FROM Temp_GB3S_CoupleInfo;
        
    END IF;

    
END$$
DELIMITER ;