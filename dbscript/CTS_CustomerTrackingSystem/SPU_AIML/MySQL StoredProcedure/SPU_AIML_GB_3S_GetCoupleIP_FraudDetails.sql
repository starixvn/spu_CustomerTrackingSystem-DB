DROP PROCEDURE IF EXISTS `SPU_AIML_GB_3S_GetCoupleIP_FraudDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_GB_3S_GetCoupleIP_FraudDetails`(
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
			CALL SPU_AIML.SPU_AIML_GB_3S_GetCoupleIP_FraudDetails (@ip_CoupleID := 1, @ip_CreatedDate := '2022-06-15', @ip_CoupleInfoDetails := '[{"CoupleInfoID" : 1,"CoupleID" : 5,"CreatedDate" : "2023-01-20"},{"CoupleInfoID" : 2,"CoupleID" : 4,"CreatedDate" : "2023-01-18"}]');
			
	*/

	SELECT 	c.TypeIPEntanglement
		,	cfi.MatchID
		,	cfi.EventDate
		,	cfi.FraudTransList
	FROM SPU_AIML.GB_3S_CoupleIPFraudInfo AS cfi
		INNER JOIN SPU_AIML.GB_3S_CoupleInfo AS c ON c.CoupleID = cfi.CoupleID
													AND c.CreatedDate = cfi.CreatedDate
	WHERE cfi.CoupleID = ip_CoupleID
		AND cfi.CreatedDate = ip_CreatedDate;
        
END$$
DELIMITER ;