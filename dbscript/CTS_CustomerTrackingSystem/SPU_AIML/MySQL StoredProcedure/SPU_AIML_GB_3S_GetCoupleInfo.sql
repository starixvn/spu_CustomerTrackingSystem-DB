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
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCoupleInfo (@ip_CustID1 := 62218173, @ip_CustID2:=66688622);
			
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfo;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfo( 		
			CoupleID			BIGINT UNSIGNED NOT NULL
        , 	CreatedDate			DATE
		,	TypeIPEntanglement	SMALLINT
		
        ,	PRIMARY KEY (CoupleID,CreatedDate)
    );
	
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleDetails;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleDetails(
			MatchID				BIGINT
		,	StateID				BIGINT
		,	CoupleID			BIGINT
        ,	CreatedDate			DATE
        ,	PRIMARY KEY (MatchID,StateID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_StateSingleCust;
	CREATE TEMPORARY TABLE Temp_GB3S_StateSingleCust(
			StateID				BIGINT 	PRIMARY KEY
		,	CntCustID			SMALLINT
	);
    
    INSERT INTO Temp_GB3S_CoupleInfo
	(
			CoupleID
        ,	CreatedDate
		,	TypeIPEntanglement
	)
	SELECT 	CoupleID
		,	CreatedDate
		,	TypeIPEntanglement
	FROM SPU_AIML.GB_3S_CoupleInfo
	WHERE CustID1 = ip_CustID1
		AND CustID2 = ip_CustID2;
    
	INSERT IGNORE INTO Temp_GB3S_CoupleDetails
	(
			MatchID
		,	StateID
		,	CoupleID
		,	CreatedDate
	)
	SELECT 	cfi.MatchID
		,	cfi.StateID
		,	cfi.CoupleID
		,	cfi.CreatedDate
	FROM SPU_AIML.GB_3S_CoupleFraudInfo AS cfi
		INNER JOIN SPU_AIML.GB_3S_State AS s ON s.StateID = cfi.StateID
		INNER JOIN Temp_GB3S_CoupleInfo AS tmp ON tmp.CoupleID = cfi.CoupleID
													AND tmp.CreatedDate = cfi.CreatedDate
	WHERE s.StateID <> 0
	ORDER BY tmp.CreatedDate DESC;
	
	INSERT INTO Temp_GB3S_StateSingleCust (StateID,CntCustID)
	WITH CTE AS (
		SELECT 	
			DISTINCT 
				ei.StateID
			,	ei.CustID
		FROM SPU_AIML.GB_3S_EventInfo AS ei
			INNER JOIN Temp_GB3S_CoupleDetails AS tmp ON tmp.StateID = ei.StateID
		WHERE ei.CustID = ip_CustID1 
			OR ei.CustID = ip_CustID2
	)
	SELECT 	StateID
		,	COUNT(CustID) AS CntCustID
	FROM 	CTE
	GROUP BY StateID;

	DELETE tc
	FROM Temp_GB3S_CoupleDetails AS tc
		INNER JOIN Temp_GB3S_StateSingleCust AS ts ON ts.StateID = tc.StateID
	WHERE ts.CntCustID = 1;
    
	SELECT 	
		DISTINCT 
			ti.CoupleID
		,	ti.CreatedDate
		,	ti.TypeIPEntanglement
    FROM Temp_GB3S_CoupleInfo AS ti
		INNER JOIN Temp_GB3S_CoupleDetails AS tc ON tc.CoupleID = ti.CoupleID
													AND tc.CreatedDate = ti.CreatedDate
    ORDER BY ti.CreatedDate DESC;

    
END$$
DELIMITER ;