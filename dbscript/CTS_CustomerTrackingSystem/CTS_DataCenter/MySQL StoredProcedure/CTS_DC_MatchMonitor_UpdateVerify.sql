/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_UpdateVerify`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_UpdateVerify`(
	IN 	ip_ID 				BIGINT UNSIGNED,
    IN	ip_UserID			INT UNSIGNED,
    
    OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Match Monitor report - Update verification
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		
		Example:
			-	CALL CTS_DC_MatchMonitor_UpdateVerify(1,8,@msg);
	*/
	
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Bettype;
    CREATE TEMPORARY TABLE Temp_Bettype(
		BettypeID 	INT UNSIGNED
	);
 
	UPDATE CTS_DataCenter.MatchMonitor AS s
    SET s.IsVerified = 1
		,	s.VerifiedBy = ip_UserID
		,	s.VerifiedDate = NOW()
	WHERE  s.ID = ip_ID;
    
END$$
DELIMITER ;
