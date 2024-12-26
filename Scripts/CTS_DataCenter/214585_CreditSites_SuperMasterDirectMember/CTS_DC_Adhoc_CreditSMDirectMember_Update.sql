/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Adhoc_CreditSMDirectMember_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Adhoc_CreditSMDirectMember_Update`(
		IN 	ip_Batchsize			INT
	,	IN 	ip_MinCTSCustID			BIGINT
	,	OUT	op_NextCTSCustID		BIGINT
)
    SQL SECURITY INVOKER
spc:BEGIN 
	/*
		Created:	20241226@Victoria.Le
		Task :		Credit - Super/Master Direct Member - Update values for MRecommend/Recommend
		DB:			CTS_DataCenter

		Revisions:
			- 20241226@Victoria.Le: 	Initial Writing [RedmineID: #214585]
                
        Param's Explanation:
        Example:
			- CALL CTS_DataCenter.CTS_DC_Adhoc_CreditSMDirectMember_Update(4000,0,@op_NextCTSCustID);
	*/ 
	
	DECLARE lv_MaxCTSCustID						BIGINT;
	
	WITH CTE AS
	(
		SELECT CTSCustID
		FROM CTS_DataCenter.CTSCustomer
		WHERE CTSCustID >= ip_MinCTSCustID
		ORDER BY CTSCustID
		LIMIT ip_Batchsize
	)
	SELECT MAX(CTSCustID)
	INTO lv_MaxCTSCustID
	FROM CTE;
	
	IF lv_MaxCTSCustID IS NULL THEN
		SET op_NextCTSCustID = 0;
		LEAVE spc;
	ELSE
		SET op_NextCTSCustID = lv_MaxCTSCustID;
	END IF;
	
	UPDATE CTS_DataCenter.CTSCustomer AS cust
	SET 	cust.MRecommend_new = cust.MRecommend
		,	cust.Recommend_new 	= cust.Recommend
	WHERE CTSCustID >= ip_MinCTSCustID
		AND CTSCustID < lv_MaxCTSCustID
	;

END$$

DELIMITER ;