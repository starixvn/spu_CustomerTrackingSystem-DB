DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCouple_FraudDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCouple_FraudDetails`(
		IN 	ip_CoupleID			BIGINT UNSIGNED
	,	IN 	ip_FromDate			DATE
    ,	IN	ip_ToDate			DATE
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
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCouple_FraudDetails (@ip_CoupleID := 1, @ip_FromDate := '2022-06-15', @ip_ToDate := '2022-07-15');
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleDetails;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleDetails(
			StateID				BIGINT
		,	SumStake			BIGINT
        ,	BetCount			BIGINT
        ,	MatchID				BIGINT
        ,	EventDate			DATE
        ,	FraudTransList		TEXT
        ,	Rn					BIGINT
    );

	INSERT INTO Temp_GB3S_CoupleDetails
    (
			StateID
		,	SumStake
        ,	BetCount
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
        ,	Rn
    )
    SELECT 	cfi.StateID
		,	s.SumStake
        ,	s.BetCount
		,	cfi.MatchID
        ,	cfi.EventDate
        ,	cfi.FraudTransList
        ,	ROW_NUMBER() OVER (PARTITION BY cfi.MatchID, cfi.StateID ORDER BY cfi.CreatedDate DESC) AS Rn
    FROM SPU_AIML.GB_3S_CoupleFraudInfo AS cfi
		INNER JOIN SPU_AIML.GB_3S_State AS s ON s.StateID = cfi.StateID
	WHERE cfi.CoupleID = ip_CoupleID
		AND cfi.CreatedDate BETWEEN ip_FromDate AND ip_ToDate;
        
	SELECT 	StateID
		,	SumStake
        ,	BetCount
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
    FROM Temp_GB3S_CoupleDetails
    WHERE Rn = 1;
    
END$$
DELIMITER ;