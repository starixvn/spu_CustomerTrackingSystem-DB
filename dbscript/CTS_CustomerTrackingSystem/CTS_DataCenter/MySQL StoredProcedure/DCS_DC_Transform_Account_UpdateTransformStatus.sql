/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Account_UpdateTransformStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Account_UpdateTransformStatus`(
		IN BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210705@Aries.Nguyen
		Task:		Fix deadlock issue [Redmine ID: #157203]
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210705@Aries.Nguyen: Created
			- 20221107@Casey.Huynh: Log DCSAccount Transform to CTS  [Redmine ID: #180182]
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
    FROM DCS_DataCenter.AccountTransformStatus AS acc
    ORDER BY acc.ID ASC
    LIMIT BatchSize;
    
    UPDATE DCS_DataCenter.Account 	AS acc
        INNER JOIN	Temp_AccountTransformStatus AS tll ON acc.AccountID = tll.AccountID
	SET	 acc.IsCTSTransformed = tll.IsCTSTransformed;    
    
    #LOG: Start
		UPDATE CTS_Log.AccountTransformStatus_Log AS acc
        INNER JOIN	Temp_AccountTransformStatus AS tll ON acc.AccountID = tll.AccountID
		SET	 acc.UpdateIsCTSTransformed = tll.IsCTSTransformed;    
    #LOG: END 
    
    DELETE FROM DCS_DataCenter.AccountTransformStatus AS acc
    WHERE acc.ID IN (SELECT ID FROM Temp_AccountTransformStatus);    
	
END$$
DELIMITER ;
