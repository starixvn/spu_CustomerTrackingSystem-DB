/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transform_Account_UpdateTransformStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transform_Account_UpdateTransformStatus`(
		IN BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210705@Aries.Nguyen
		Task:		Fix deadlock issue [Redmine ID: #157203]
		DB:			DCS_Extra
		Original:

		Revisions:
			- 20210705@Aries.Nguyen: Created
			
		Param's Explanation (filtered by):
	*/ 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountTransformStatus;  
	CREATE TEMPORARY TABLE Temp_AccountTransformStatus(
			ID 					BIGINT UNSIGNED
		,	AccountID 			BIGINT UNSIGNED
		,	IsCTSTransformed 	TINYINT
		,	PRIMARY KEY (ID)     
        ,	INDEX 			IX_Temp_AccountTransformStatus_AccountID(AccountID)
    );
    
    INSERT INTO Temp_AccountTransformStatus(ID, AccountID, IsCTSTransformed)
    SELECT 	acc.ID
		,	acc.AccountID
        ,	acc.IsCTSTransformed
    FROM DCS_Extra.AccountTransformStatus AS acc
    ORDER BY acc.ID ASC
    LIMIT BatchSize;
    
    UPDATE DCS_Extra.Account 	AS acc
        INNER JOIN	Temp_AccountTransformStatus AS tll ON acc.AccountID = tll.AccountID
	SET	 acc.IsCTSTransformed = tll.IsCTSTransformed; 
    
    DELETE FROM DCS_Extra.AccountTransformStatus AS acc
    WHERE acc.ID IN (SELECT ID FROM Temp_AccountTransformStatus);
    

END$$
DELIMITER ;
