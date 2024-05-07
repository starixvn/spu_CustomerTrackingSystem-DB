/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_Account_Archive`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_Account_Archive`(
		IN ip_BatchSize INT UNSIGNED
        
	,	OUT op_ShouldContinue INT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240419@Jonathan.Doan
		Task:		Cook unused data to Archive tables
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20240419@Jonathan.Doan: Created [Redmine ID: #203691]
		Param's Explanation (filtered by):
            CALL DCS_DataCenter.DCS_DC_ArchiveData_Account_Archive(50, @shouldContinue); SELECT @shouldContinue;
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCode;
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountIP;
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountFingerprint;
    
    CREATE TEMPORARY TABLE Temp_Account(
			AccountID 		BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_Association(
			AccountID 		BIGINT UNSIGNED NOT NULL,
			DeviceID 		BIGINT UNSIGNED NOT NULL,
			PRIMARY KEY (AccountID, DeviceID)
    );
    
    CREATE TEMPORARY TABLE Temp_Device(
			DeviceID 		BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_DeviceCode(
			DeviceCodeID 	BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_AccountIP(
			ID 	BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_AccountDevice(
			ID BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_AccountFingerprint(
			ID BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    INSERT INTO Temp_Account(AccountID)
	SELECT AccountID
	FROM DCS_DataCenter.ArchiveAccount_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_Association(AccountID, DeviceID)
	SELECT	AccountID
		,	DeviceID
	FROM DCS_DataCenter.ArchiveAssociation_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_Device(DeviceID)
	SELECT DeviceID
	FROM DCS_DataCenter.ArchiveDevice_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_DeviceCode(DeviceCodeID)
	SELECT DeviceCodeID
	FROM DCS_DataCenter.ArchiveDeviceCode_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_AccountIP(ID)
	SELECT ID
	FROM DCS_DataCenter.ArchiveAccountIP_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_AccountDevice(ID)
	SELECT ID
	FROM DCS_DataCenter.ArchiveAccountDevice_NotUsed
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_AccountFingerprint(ID)
	SELECT ID
	FROM DCS_DataCenter.ArchiveAccountFingerprint_NotUsed
	LIMIT ip_BatchSize;
    
    /* DELETE Account */
	DELETE acc
	FROM DCS_DataCenter.Account AS acc
		INNER JOIN Temp_Account AS tmp ON tmp.AccountID = acc.AccountID;
        
	DELETE sumAcc
	FROM DCS_DataCenter.SumAccountLogin AS sumAcc
		INNER JOIN Temp_Account AS tmp ON tmp.AccountID = sumAcc.AccountID;
        
	DELETE sumAccTotal
	FROM DCS_DataCenter.SumAccountLoginTotal AS sumAccTotal
		INNER JOIN Temp_Account AS tmp ON tmp.AccountID = sumAccTotal.AccountID;
	
	DELETE arcAcc
    FROM DCS_DataCenter.ArchiveAccount_NotUsed AS arcAcc
		INNER JOIN Temp_Account AS tmp ON tmp.AccountID = arcAcc.AccountID;
	
    /* DELETE Association */
	DELETE ass
	FROM DCS_DataCenter.Association AS ass
		INNER JOIN Temp_Association AS tmp ON tmp.AccountID = ass.AccountID
										AND tmp.DeviceID = ass.DeviceID;
                                        
	DELETE arcAss
	FROM DCS_DataCenter.ArchiveAssociation_NotUsed AS arcAss
		INNER JOIN Temp_Association AS tmp ON tmp.AccountID = arcAss.AccountID
										AND tmp.DeviceID = arcAss.DeviceID;
    
    /* DELETE Device & DeviceFingerprint*/
	DELETE dv
	FROM DCS_DataCenter.Device AS dv
		INNER JOIN Temp_Device AS tmp ON tmp.DeviceID = dv.DeviceID;
        
	DELETE dvf
	FROM DCS_DataCenter.DeviceFingerprint AS dvf
		INNER JOIN Temp_Device AS tmp ON tmp.DeviceID = dvf.DeviceID;

	DELETE arcDv
    FROM DCS_DataCenter.ArchiveDevice_NotUsed AS arcDv
		INNER JOIN Temp_Device AS tmp ON tmp.DeviceID = arcDv.DeviceID;
    
    /* DELETE DeviceCode */
	DELETE dvc
	FROM DCS_DataCenter.DeviceCode AS dvc
		INNER JOIN Temp_DeviceCode AS tmp ON tmp.DeviceCodeID = dvc.DeviceCodeID;

	DELETE arcDvc
    FROM DCS_DataCenter.ArchiveDeviceCode_NotUsed AS arcDvc
		INNER JOIN Temp_DeviceCode AS tmp ON tmp.DeviceCodeID = arcDvc.DeviceCodeID;
    
    /* DELETE AccountIP */
	DELETE accIp
	FROM DCS_DataCenter.AccountIP AS accIp
		INNER JOIN Temp_AccountIP AS tmp ON tmp.ID = accIp.ID;

	DELETE arcAccIp
    FROM DCS_DataCenter.ArchiveAccountIP_NotUsed AS arcAccIp
		INNER JOIN Temp_AccountIP AS tmp ON tmp.ID = arcAccIp.ID;
    
    /* DELETE AccountDevice */
	DELETE accDv
	FROM DCS_DataCenter.AccountDevice AS accDv
		INNER JOIN Temp_AccountDevice AS tmp ON tmp.ID = accDv.ID;
        
	DELETE arcAccDv
    FROM DCS_DataCenter.ArchiveAccountDevice_NotUsed AS arcAccDv
		INNER JOIN Temp_AccountDevice AS tmp ON tmp.ID = arcAccDv.ID;
    
    /* DELETE AccountFingerprint */
	DELETE accFp
	FROM DCS_DataCenter.AccountFingerprint AS accFp
		INNER JOIN Temp_AccountFingerprint AS tmp ON tmp.ID = accFp.ID;

	DELETE arcAccFp
    FROM DCS_DataCenter.ArchiveAccountFingerprint_NotUsed AS arcAccFp
		INNER JOIN Temp_AccountFingerprint AS tmp ON tmp.ID = arcAccFp.ID;
	
    /* Update op_ShouldContinue */
    IF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveAccount_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveAssociation_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveDevice_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveDeviceCode_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveAccountIP_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveAccountDevice_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSEIF (EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveAccountFingerprint_NotUsed LIMIT 1)) THEN
		SET op_ShouldContinue = 1;
	ELSE
		SET op_ShouldContinue = 0;
	END IF;
    
END$$

DELIMITER ;
