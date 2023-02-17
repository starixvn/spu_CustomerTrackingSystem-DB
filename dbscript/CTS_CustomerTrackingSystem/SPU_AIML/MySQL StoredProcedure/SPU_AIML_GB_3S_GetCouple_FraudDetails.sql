DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCouple_FraudDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCouple_FraudDetails`(
		IN 	ip_CoupleInfoDetails	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230112@Victoria.Le
		Task:		Get Couple Datails
		DB:			SPU_AIML
		Original:

		Revisions:
			- 20230112@Victoria.Le: Initial Writting [Redmine ID: #181994]
		
        Param's Explanation (filtered by):
			
		Example:
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCouple_FraudDetails (@ip_CoupleInfoDetails := '[{"CoupleID" : 17,"CreatedDate" : "2023-02-12", "TypeIPEntanglement:": 2},{"CoupleID" : 95,"CreatedDate" : "2023-02-11", "TypeIPEntanglement:": 2}]');
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
		,	SumStake			BIGINT
		,	BetCount			BIGINT
		,	EventDate			DATE
		,	FraudTransList		TEXT
        ,	PRIMARY KEY (MatchID,StateID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_StateSingleCust;
	CREATE TEMPORARY TABLE Temp_GB3S_StateSingleCust(
			MatchID				BIGINT
		,	StateID				BIGINT
	);
	
	INSERT INTO Temp_GB3S_CoupleInfo
	(
			CoupleID
        ,	CreatedDate
		,	TypeIPEntanglement
	)
	SELECT 	tmp.CoupleID
        ,	tmp.CreatedDate
		,	tmp.TypeIPEntanglement
	FROM JSON_TABLE(ip_CoupleInfoDetails,'$[*]' COLUMNS(CoupleID			BIGINT		PATH '$.CoupleID'
                                                    ,	CreatedDate			DATE		PATH '$.CreatedDate'
													,	TypeIPEntanglement	SMALLINT	PATH '$.TypeIPEntanglement'
					)) AS tmp;
	
	
	INSERT IGNORE INTO Temp_GB3S_CoupleDetails
	(
			MatchID
		,	StateID
		,	CoupleID
		,	CreatedDate
		,	SumStake
		,	BetCount
		,	EventDate
		,	FraudTransList
	)
	SELECT 	cfi.MatchID
		,	cfi.StateID
		,	cfi.CoupleID
		,	cfi.CreatedDate
		,	s.SumStake
		,	s.BetCount
		,	cfi.EventDate
		,	cfi.FraudTransList
	FROM SPU_AIML.GB_3S_CoupleFraudInfo AS cfi
		INNER JOIN SPU_AIML.GB_3S_State AS s ON s.StateID = cfi.StateID
		INNER JOIN Temp_GB3S_CoupleInfo AS temp ON temp.CoupleID = cfi.CoupleID
													AND temp.CreatedDate = cfi.CreatedDate
	WHERE s.StateID <> 0
	ORDER BY temp.CreatedDate DESC;
	
	INSERT INTO Temp_GB3S_StateSingleCust (MatchID,StateID)
	WITH CTE AS (
		SELECT 	ei.MatchID
			,	ei.StateID
			,	COUNT(ei.CustID) AS CntMatchIDStateID
		FROM SPU_AIML.GB_3S_EventInfo AS ei
			INNER JOIN Temp_GB3S_CoupleDetails AS tmp ON tmp.StateID = ei.StateID
														AND tmp.MatchID = ei.MatchID
		GROUP BY 	ei.MatchID
				,	ei.StateID
	)
	SELECT MatchID,StateID
	FROM CTE
	WHERE CntMatchIDStateID = 1;

	DELETE tc
	FROM Temp_GB3S_CoupleDetails AS tc
		INNER JOIN Temp_GB3S_StateSingleCust AS ts ON ts.StateID = tc.StateID
														AND ts.MatchID = tc.MatchID;
    
	SELECT 	StateID
		,	SumStake
        ,	BetCount
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
		,	CoupleID
		,	CreatedDate
    FROM Temp_GB3S_CoupleDetails
    ORDER BY CreatedDate DESC;
    
END$$
DELIMITER ;