DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCouple_FraudDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCouple_FraudDetails`(
		IN 	ip_CoupleID				BIGINT UNSIGNED
	,	IN 	ip_CreatedDate			DATE
	,	IN 	ip_CoupleInfoDetails	JSON
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
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCouple_FraudDetails (@ip_CoupleID := 1, @ip_CreatedDate := '2022-06-15', @ip_CoupleInfoDetails := '[{"CoupleInfoID" : 1,"CoupleID" : 5,"CreatedDate" : "2023-01-20"},{"CoupleInfoID" : 2,"CoupleID" : 4,"CreatedDate" : "2023-01-18"}]');
	*/
    DECLARE lv_CoupleInfoID	BIGINT UNSIGNED;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_GB3S_CoupleInfo;
	CREATE TEMPORARY TABLE Temp_GB3S_CoupleInfo( 		
			CoupleInfoID		BIGINT NOT NULL AUTO_INCREMENT
		,	CoupleID			BIGINT UNSIGNED NOT NULL
        , 	CreatedDate			DATE
        ,	PRIMARY KEY (CoupleInfoID)
        ,	INDEX IX_Temp_GB3S_CoupleInfo_CC (CoupleID,CreatedDate)
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
	
	INSERT INTO Temp_GB3S_CoupleInfo
	(
			CoupleInfoID
		,	CoupleID
        ,	CreatedDate
	)
	SELECT 	tmp.CoupleInfoID
		,	tmp.CoupleID
        ,	tmp.CreatedDate
	FROM JSON_TABLE(ip_CoupleInfoDetails,'$[*]' COLUMNS(CoupleInfoID	BIGINT 	PATH '$.CoupleInfoID' 
													,	CoupleID		BIGINT	PATH '$.CoupleID'
                                                    ,	CreatedDate		DATE	PATH '$.CreatedDate'
					)) AS tmp;

    SELECT CoupleInfoID
    INTO lv_CoupleInfoID
    FROM Temp_GB3S_CoupleInfo
    WHERE CoupleID = ip_CoupleID;
    
    IF (lv_CoupleInfoID = 1) THEN
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
		WHERE cfi.CoupleID = ip_CoupleID
			AND cfi.CreatedDate = ip_CreatedDate;
        
	ELSE
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
		ORDER BY temp.CoupleInfoID;
        
    END IF;
    
	SELECT 	StateID
		,	SumStake
        ,	BetCount
        ,	MatchID
        ,	EventDate
        ,	FraudTransList
    FROM Temp_GB3S_CoupleDetails
    WHERE CoupleID = ip_CoupleID
		AND CreatedDate = ip_CreatedDate;
    
END$$
DELIMITER ;