DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCoupleIP_FraudDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCoupleIP_FraudDetails`(
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
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCoupleIP_FraudDetails (@ip_CoupleID := 1, @ip_FromDate := '2022-06-15', @ip_ToDate := '2022-07-15');
			
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleIPDetails;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleIPDetails(
			TypeIPEntanglement	SMALLINT
        ,	MatchID				BIGINT
        ,	EventDate			DATE
        ,	FraudTransList		VARCHAR(3000)
        ,	Rn					BIGINT
        -- ,	PRIMARY KEY (CoupleID,CreatedDate)
    );

	INSERT INTO Temp_GB3S_CoupleIPDetails
    (
			TypeIPEntanglement
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
        ,	Rn
    )
    SELECT 	c.TypeIPEntanglement
		,	cfi.MatchID
        ,	cfi.EventDate
        ,	cfi.FraudTransList
        ,	ROW_NUMBER() OVER (PARTITION BY cfi.MatchID ORDER BY cfi.CreatedDate DESC) AS Rn
    FROM SPU_AIML.GB_3S_CoupleIPFraudInfo AS cfi
		INNER JOIN SPU_AIML.GB_3S_CoupleInfo AS c ON c.CoupleID = cfi.CoupleID
	WHERE cfi.CoupleID = ip_CoupleID
		AND cfi.CreatedDate BETWEEN ip_FromDate AND ip_ToDate;
        
	SELECT 	TypeIPEntanglement
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
    FROM Temp_GB3S_CoupleIPDetails
    WHERE Rn = 1;
    
END$$
DELIMITER ;