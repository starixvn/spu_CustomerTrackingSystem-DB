/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transform_Account_UpdateLastLoginTime`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transform_Account_UpdateLastLoginTime`(
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
   
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountLastLoginTimeProcess;  
	CREATE TEMPORARY TABLE Temp_AccountLastLoginTimeProcess(
			ID 				BIGINT UNSIGNED
		,	AccountID 		BIGINT UNSIGNED
		,	LastLoginTime 	TIMESTAMP(4) NOT NULL
		,	PRIMARY KEY (ID)     
        ,	INDEX 			IX_Temp_AccountLastLoginTimeProcess_AccountID(AccountID)
    );
    
    INSERT INTO Temp_AccountLastLoginTimeProcess(ID, AccountID, LastLoginTime)
    SELECT 	acc.ID
		,	acc.AccountID
        ,	acc.LastLoginTime
    FROM DCS_Extra.AccountLastLoginTimeProcess AS acc
    ORDER BY acc.ID ASC
    LIMIT BatchSize;
    
    UPDATE DCS_Extra.Account 	AS acc
        INNER JOIN	Temp_AccountLastLoginTimeProcess AS tll ON acc.AccountID = tll.AccountID
	SET	 acc.LastLoginTime = tll.LastLoginTime; 
    
    DELETE FROM DCS_Extra.AccountLastLoginTimeProcess AS acc
    WHERE acc.ID IN (SELECT ID FROM Temp_AccountLastLoginTimeProcess);
    
    ###########################################################
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerLastLoginTimeProcess;  
	CREATE TEMPORARY TABLE Temp_CTSCustomerLastLoginTimeProcess(
			ID 				BIGINT UNSIGNED
		,	CTSCustID 		BIGINT UNSIGNED
		,	LastLoginTime 	TIMESTAMP(4) NOT NULL
        ,	IsValid			BIT DEFAULT 1
		,	PRIMARY KEY (ID)     
        ,	INDEX 			IX_Temp_CTSCustomerLastLoginTimeProcess_CTSCustID(CTSCustID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustInvalid;  
	CREATE TEMPORARY TABLE Temp_CTSCustInvalid(
			CTSCustID 		BIGINT UNSIGNED
        ,	INDEX 			IX_Temp_CTSCustInvalid_CTSCustID(CTSCustID)
    );
    
    INSERT INTO Temp_CTSCustomerLastLoginTimeProcess(ID, CTSCustID, LastLoginTime)
    SELECT 	cus.ID
		,	cus.CTSCustID
        ,	cus.LastLoginTime
    FROM DCS_Extra.CTSCustomerLastLoginTimeProcess AS cus
    ORDER BY cus.ID ASC
    LIMIT BatchSize;
    
    INSERT INTO Temp_CTSCustInvalid(CTSCustID)
    SELECT cus.CTSCustID
    FROM CTS_DataCenter.CTSCustomer  cus
		INNER JOIN 	Temp_CTSCustomerLastLoginTimeProcess AS tmp_cus ON cus.CTSCustID = tmp_cus.CTSCustID
	WHERE cus.LastLoginTime > tmp_cus.LastLoginTime;
    
    UPDATE Temp_CTSCustomerLastLoginTimeProcess AS cust
    SET cust.IsValid = 0
    WHERE cust.CTSCustID IN (SELECT CTSCustID FROM Temp_CTSCustInvalid);
	
     UPDATE CTS_DataCenter.CTSCustomer  cus
        INNER JOIN 	Temp_CTSCustomerLastLoginTimeProcess AS tmp_cus ON cus.CTSCustID = tmp_cus.CTSCustID AND tmp_cus.IsValid = 1
	 SET cus.LastLoginTime = tmp_cus.LastLoginTime;
     
	DELETE FROM DCS_Extra.CTSCustomerLastLoginTimeProcess AS cust
    WHERE cust.ID IN (SELECT ID FROM Temp_CTSCustomerLastLoginTimeProcess);

END$$
DELIMITER ;
