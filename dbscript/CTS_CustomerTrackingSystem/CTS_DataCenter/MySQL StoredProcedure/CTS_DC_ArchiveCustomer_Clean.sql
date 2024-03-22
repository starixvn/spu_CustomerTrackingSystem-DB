/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ArchiveCustomer_Clean`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ArchiveCustomer_Clean`()
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210927@Aries.Nguyen
		Task :		Archive Customer
		DB:			CTS_DataCenter, DCS_DataCenter
		Original:

		Revisions:
			- 	20210927@Aries.Nguyen: 	Created [Redmine ID: #162277]
			- 	20211123@Aries.Nguyen: 	Clean data inactive association [Redmine ID: #165001]
			- 	20211216@Aries.Nguyen: 	Clean data Sum Account Login Info [Redmine ID: #165105]
			-	20220408@Casey.Huynh: 	Add AssociationGroupByAI [Redmine ID: #171222]
			-	20220713@Aries.Nguyen: 	HotFix Customer NULL CC [Redmine ID: #175406]
			-	20220720@Aries.Nguyen: 	Missing remove unused columns in 'CTS_DC_ArchiveCustomer_Clean' [Redmine ID: #175631]
			-	20220519@Aries.Nguyen: 	Clean data Classification BySport tables   [Redmine ID: #176992]
			- 	20230112@Victoria.Le: 	Modify SPs due to restructure AssociationByAI [Redmine ID: #181994]
			- 	20231023@Jonas.Huynh:	HF wrong reactivated category [Redmine ID: #193050]
			-	20240321@Thomas.Nguyen:	Clean data for Special CC BySport/History and history of special CC general [Redmine ID: #201360]

		Param's Explanation (filtered by):	
        
        Example:
			CALL CTS_DC_ArchiveCustomer_Clean();
	*/
    
    DECLARE lv_CustBatchSize 			INT;
    DECLARE lv_CleanTableBatchSize 		INT;
    DECLARE lv_LastID 					BIGINT UNSIGNED;
    DECLARE lv_NextID 					BIGINT UNSIGNED;
    DECLARE lv_Table 					VARCHAR(100);
    DECLARE lv_Count				    INT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE Temp_CustInfo(
			ArchiveID	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
		,	CTSCustID	BIGINT UNSIGNED
        ,	AccountID   BIGINT UNSIGNED
        ,	INDEX 		IX_Temp_CustInfo_CTSCustID(CTSCustID)
        ,	INDEX 		IX_Temp_CustInfo_CustID(CustID)
        ,	INDEX 		IX_Temp_CustInfo_AccountID(AccountID)
    );
    
    SELECT ParameterValue
	INTO lv_CustBatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 43; 
    
	SELECT ParameterValue
	INTO lv_CleanTableBatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 44;
    
    SELECT ParameterValue
	INTO lv_LastID 
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 45; 
    
    SELECT ParameterValue
	INTO lv_Table 
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 46; 
  
    INSERT IGNORE INTO Temp_CustInfo(ArchiveID,CustID,CTSCustID,AccountID)
    SELECT	ID
		,	CustID
		,	CTSCustID
        ,	AccountID
    FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer
    WHERE ID > lv_LastID
		AND IsReactivated = 0
    ORDER BY ID ASC
    LIMIT lv_CustBatchSize;

	IF NOT EXISTS (SELECT 1 FROM Temp_CustInfo) THEN
		LEAVE sp; 
	END IF;
    
    /*************************************** 1. DCS_DataCenter.DeviceFingerprint *******************************/
    IF (lv_Table = 'DCS_DataCenter.DeviceFingerprint') THEN
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.ArchiveCustomer_Device) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerprint_Clean;
			CREATE TEMPORARY TABLE Temp_DeviceFingerprint_Clean(
					DeviceID   			BIGINT UNSIGNED
				,	FingerprintCode   	VARCHAR(620) COLLATE utf8_unicode_ci
				,	PRIMARY KEY(DeviceID, FingerprintCode)
			);
            
            INSERT IGNORE INTO Temp_DeviceFingerprint_Clean(DeviceID, FingerprintCode)
            SELECT 	df.DeviceID
				,	df.FingerprintCode
			FROM DCS_DataCenter.DeviceFingerprint AS df
            WHERE EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveCustomer_Device AS dv  WHERE dv.DeviceID = df.DeviceID)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE df
			FROM  DCS_DataCenter.DeviceFingerprint AS df
				INNER JOIN Temp_DeviceFingerprint_Clean AS tmp ON tmp.DeviceID = df.DeviceID AND tmp.FingerprintCode = df.FingerprintCode;
			
            UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.DeviceFingerprint'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_DeviceFingerprint_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
            
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
		SET lv_Table = 'DCS_DataCenter.DeviceCode';
    END IF;
    
    /*************************************** 2. DCS_DataCenter.DeviceCode **************************************/
    IF (lv_Table = 'DCS_DataCenter.DeviceCode') THEN
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.ArchiveCustomer_Device) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCode_Clean;
			CREATE TEMPORARY TABLE Temp_DeviceCode_Clean(
					DeviceCodeID   	BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_DeviceCode_Clean(DeviceCodeID)
            SELECT 	dc.DeviceCodeID
			FROM DCS_DataCenter.DeviceCode AS dc
            WHERE EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveCustomer_Device AS dv  WHERE dv.DeviceID = dc.DeviceID)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE dc
			FROM  DCS_DataCenter.DeviceCode AS dc
				INNER JOIN Temp_DeviceCode_Clean AS tmp ON tmp.DeviceCodeID = dc.DeviceCodeID;
			
            UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.DeviceCode'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_DeviceCode_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
            
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
		SET lv_Table = 'DCS_DataCenter.Device';
    END IF;
    
    /*************************************** 3. DCS_DataCenter.Device ******************************************/
    IF (lv_Table = 'DCS_DataCenter.Device') THEN
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.ArchiveCustomer_Device) THEN
            DELETE dv
			FROM  DCS_DataCenter.Device AS dv
				INNER JOIN DCS_DataCenter.ArchiveCustomer_Device AS tmp ON tmp.DeviceID = dv.DeviceID;
			
            SELECT COUNT(1)
            INTO lv_Count
            FROM DCS_DataCenter.ArchiveCustomer_Device;
            
            DELETE dv
			FROM  DCS_DataCenter.ArchiveCustomer_Device AS dv;
            
            UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.Device'
			WHERE ParameterID = 46;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
            
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
		SET lv_Table = 'DCS_DataCenter.Association';
    END IF;
	
    /*************************************** 4. DCS_DataCenter.Association *************************************/
    IF (lv_Table = 'DCS_DataCenter.Association') THEN
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.Association AS ass  WHERE  ass.AccountID IN (SELECT tmp.AccountID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_Association_Clean;
			CREATE TEMPORARY TABLE Temp_Association_Clean(
					AccountID   	BIGINT UNSIGNED
				,	DeviceID   		BIGINT UNSIGNED
				,	PRIMARY KEY(AccountID, DeviceID)
			);
            
            INSERT IGNORE INTO Temp_Association_Clean(AccountID, DeviceID)
            SELECT 	ass.AccountID
				, 	ass.DeviceID
			FROM DCS_DataCenter.Association AS ass
            WHERE  ass.AccountID IN (SELECT tmp.AccountID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            INSERT INTO DCS_DataCenter.ArchiveCustomer_Device(AccountID, DeviceID)
			SELECT  tmp.AccountID 
				,	tmp.DeviceID
			FROM Temp_Association_Clean AS tmp
			WHERE NOT EXISTS (SELECT 1 
							  FROM DCS_DataCenter.Association AS ass 
							  WHERE ass.DeviceID = tmp.DeviceID 
								AND ass.AccountID != tmp.AccountID);
            
            DELETE ass
			FROM  DCS_DataCenter.Association AS ass
				INNER JOIN Temp_Association_Clean AS tmp ON tmp.AccountID = ass.AccountID AND tmp.DeviceID = ass.DeviceID;
			
            IF EXISTS(SELECT 1 FROM DCS_DataCenter.ArchiveCustomer_Device) THEN
				UPDATE  CTS_DataCenter.SystemParameter 
				SET ParameterValue = 'DCS_DataCenter.DeviceFingerprint'
				WHERE ParameterID = 46;
                
                LEAVE sp;
            ELSE 
				UPDATE  CTS_DataCenter.SystemParameter 
				SET ParameterValue = 'DCS_DataCenter.Association'
				WHERE ParameterID = 46;
            END IF;
            
			
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_Association_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'DCS_DataCenter.Account';
    END IF;
	
    /*************************************** 5. DCS_DataCenter.Account *****************************************/
	IF (lv_Table = 'DCS_DataCenter.Account') THEN 
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.Account AS acc WHERE  acc.AccountID IN (SELECT tmp.AccountID FROM Temp_CustInfo AS tmp)) THEN
			DELETE acc
			FROM DCS_DataCenter.Account AS acc
				INNER JOIN  Temp_CustInfo AS tmp ON acc.AccountID = tmp.AccountID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.Account'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'DCS_DataCenter.SumAccountLoginTotal';
    END IF; 
    
    /*************************************** 6. DCS_DataCenter.SumAccountLoginTotal ******************************/
	IF (lv_Table = 'DCS_DataCenter.SumAccountLoginTotal') THEN 
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.SumAccountLoginTotal AS acc WHERE  acc.AccountID IN (SELECT tmp.AccountID FROM Temp_CustInfo AS tmp)) THEN
			DELETE acc
			FROM DCS_DataCenter.SumAccountLoginTotal AS acc
				INNER JOIN  Temp_CustInfo AS tmp ON acc.AccountID = tmp.AccountID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.SumAccountLoginTotal'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociatedAccountMonitor';
    END IF; 
    
	/*************************************** 7. CTS_DataCenter.AssociatedAccountMonitor ************************/
    IF (lv_Table = 'CTS_DataCenter.AssociatedAccountMonitor') THEN 
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountMonitor AS aam WHERE  aam.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DELETE aam
			FROM CTS_DataCenter.AssociatedAccountMonitor AS  aam
				INNER JOIN Temp_CustInfo AS tmp ON tmp.CTSCustID = aam.CTSCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociatedAccountMonitor'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        SET lv_Table = 'CTS_DataCenter.AssociatedAccountNotification';
    END IF;
    
    /*************************************** 8. CTS_DataCenter.AssociatedAccountNotification *******************/
    IF (lv_Table = 'CTS_DataCenter.AssociatedAccountNotification') THEN 
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountNotification AS ass WHERE  ass.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccountNotification_Clean;
			CREATE TEMPORARY TABLE Temp_AssociatedAccountNotification_Clean(
					AccountNewAssID   	BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociatedAccountNotification_Clean(AccountNewAssID)
            SELECT ass.AccountNewAssID
			FROM CTS_DataCenter.AssociatedAccountNotification AS ass
			WHERE  ass.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociatedAccountNotification AS ass
			WHERE  ass.AccountNewAssID IN (SELECT tmp.AccountNewAssID FROM Temp_AssociatedAccountNotification_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociatedAccountNotification'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociatedAccountNotification_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        SET lv_Table = 'CTS_DataCenter.AssociationByAI-From';
    END IF;
    
    /*************************************** 9. CTS_DataCenter.AssociationByAI *********************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByAI-From') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI AS ai WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					AssID	BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(AssID)
            SELECT 	ai.AssID
			FROM CTS_DataCenter.AssociationByAI  AS ai
			WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationByAI AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.AssID = ass.AssID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByAI-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
		SET lv_Table = 'CTS_DataCenter.AssociationByAI-To';
    END IF;
    
    IF (lv_Table = 'CTS_DataCenter.AssociationByAI-To') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI AS ai WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					AssID	BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(AssID)
            SELECT 	ai.AssID
			FROM CTS_DataCenter.AssociationByAI AS ai
			WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationByAI AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.AssID = ass.AssID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByAI-To'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationGroupByAI';
    END IF;
    
    IF (lv_Table = 'CTS_DataCenter.AssociationGroupByAI') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationGroupByAI AS asg WHERE  asg.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationGroupByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationGroupByAI_Clean(
					CustID 		BIGINT UNSIGNED NOT NULL
				,	GroupID 	BIGINT UNSIGNED NOT NULL
                
                ,	PRIMARY KEY (CustID, GroupID)
			) ENGINE=InnoDB;
            
            INSERT IGNORE INTO Temp_AssociationGroupByAI_Clean(CustID, GroupID)
            SELECT 	asg.CustID
				,	asg.GroupID
			FROM CTS_DataCenter.AssociationGroupByAI AS asg
			WHERE  asg.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE asg
			FROM CTS_DataCenter.AssociationGroupByAI AS asg
				INNER JOIN Temp_AssociationGroupByAI_Clean AS tmp ON tmp.CustID = asg.CustID AND tmp.GroupID = asg.GroupID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationGroupByAI'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationGroupByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByDevice';
    END IF;
	
   /**************************************** 10. CTS_DataCenter.AssociationByDevice ****************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByDevice') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByDevice  AS dv WHERE dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByDevice_Clean(
					CTSAssDevID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByDevice_Clean(CTSAssDevID)
            SELECT 	dv.CTSAssDevID
			FROM CTS_DataCenter.AssociationByDevice AS dv
			WHERE  dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE dv
			FROM CTS_DataCenter.AssociationByDevice AS dv
			WHERE  dv.CTSAssDevID IN (SELECT tmp.CTSAssDevID FROM Temp_AssociationByDevice_Clean AS tmp);
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByDevice'
			WHERE ParameterID = 46;
        
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByDevice_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByIP-From';
	END IF; 
    
	/*************************************** 11. CTS_DataCenter.AssociationByIP ********************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByIP-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP AS ip WHERE ip.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ip.ID
			FROM CTS_DataCenter.AssociationByIP AS ip
			WHERE  ip.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ip
			FROM CTS_DataCenter.AssociationByIP AS ip
			WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByIP-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByIP_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByIP-To';
	 END IF; 
     
	IF (lv_Table = 'CTS_DataCenter.AssociationByIP-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP AS ip WHERE ip.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ip.ID
			FROM CTS_DataCenter.AssociationByIP AS ip
			WHERE  ip.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.AssociationByIP AS ip
			WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByIP-To'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByIP_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-From';
	 END IF;   
     
    /*************************************** 12. CTS_DataCenter.AssociationByManual ***************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual AS ma WHERE ma.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	ma.FromCTSCustID
				,	ma.ToCTSCustID
			FROM CTS_DataCenter.AssociationByManual AS ma
			WHERE  ma.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_DataCenter.AssociationByManual AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-From'
			WHERE ParameterID = 46;
        
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByManual_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-To';
	 END IF;  
     
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual AS ma WHERE ma.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	ma.FromCTSCustID
				,	ma.ToCTSCustID
			FROM CTS_DataCenter.AssociationByManual AS ma
			WHERE  ma.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_DataCenter.AssociationByManual AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-To'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByManual_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationRemove-From';
	 END IF;    
     
    /*************************************** 13. CTS_DataCenter.AssociationRemove ****************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationRemove-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove AS rm WHERE rm.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp))  THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemove_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationRemove_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationRemove_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	rm.FromCTSCustID
				,	rm.ToCTSCustID
			FROM CTS_DataCenter.AssociationRemove AS rm
			WHERE  rm.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationRemove AS ass
				INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationRemove-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationRemove_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationRemove-To';
	END IF;  
    
    IF (lv_Table = 'CTS_DataCenter.AssociationRemove-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove AS rm WHERE rm.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemove_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationRemove_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationRemove_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	rm.FromCTSCustID
				,	rm.ToCTSCustID
			FROM CTS_DataCenter.AssociationRemove AS rm
			WHERE  rm.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationRemove AS ass
				INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationRemove-To'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationRemove_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification';
	 END IF; 

	/*************************************** 14. CTS_DataCenter.CTSCustomerClassification, CTSCustomerClassification_BySport ********************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification AS clss WHERE clss.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Clean(
					CustID   			BIGINT UNSIGNED  
				,	SportGroupID		BIGINT UNSIGNED
                ,	CategoryID			SMALLINT
                ,	PRIMARY KEY(CustID, SportGroupID, CategoryID)
			);
            
            DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Archive;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Archive(
					ArchiveID			BIGINT UNSIGNED PRIMARY KEY
				,	CustID   			BIGINT 
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_Clean(CustID, SportGroupID, CategoryID)
            SELECT 	clss.CustID
				,	clss.SportGroupID
                ,	clss.CategoryID
			FROM CTS_DataCenter.CTSCustomerClassification AS clss
			WHERE  clss.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_Archive(ArchiveID, CustID)
            SELECT 	arc.ID, arc.CustID
			FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc 
				INNER JOIN Temp_CustInfo AS temp ON temp.ArchiveID = arc.ID AND arc.CustSubID = 0
			WHERE arc.CategoryID IS NULL;
            
            IF EXISTS (SELECT 1 FROM Temp_CTSCustomerClassification_Archive) THEN
				UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
				INNER JOIN Temp_CTSCustomerClassification_Archive AS temp ON temp.ArchiveID = arc.ID,
				LATERAL
					(
						SELECT DISTINCT cc.CustID, cc.CategoryID, cate.Priority, cc.CreatedDate
						FROM CTS_DataCenter.CTSCustomerClassification AS cc
							INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cc.CategoryID = cate.CategoryID
						WHERE cc.CustID = arc.CustID
						ORDER BY  cate.Priority ASC 
								, cc.CreatedDate DESC
						LIMIT 1
					) AS cc
				SET arc.CategoryID = cc.CategoryID;
            END IF;
					
            DELETE cl
			FROM CTS_DataCenter.CTSCustomerClassification AS cl
				INNER JOIN Temp_CTSCustomerClassification_Clean AS tmp ON tmp.CustID = cl.CustID 
																		AND tmp.SportGroupID = cl.SportGroupID
																		AND tmp.CategoryID = cl.CategoryID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CTSCustomerClassification_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_BySport';
	 END IF; 

     IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_BySport') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_BySport AS clss WHERE clss.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_BySport_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_BySport_Clean(
					CustID   			BIGINT UNSIGNED  
				,	SportID				BIGINT UNSIGNED
                ,	PRIMARY KEY(CustID, SportID)
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_BySport_Clean(CustID, SportID)
            SELECT 	clss.CustID
				,	clss.SportID
			FROM CTS_DataCenter.CTSCustomerClassification_BySport AS clss
			WHERE  clss.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE cl
			FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cl
				INNER JOIN Temp_CTSCustomerClassification_BySport_Clean AS tmp ON tmp.CustID = cl.CustID 
																		AND tmp.SportID = cl.SportID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_BySport'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CTSCustomerClassification_BySport_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_History';
	 END IF; 
     
    /*************************************** 15. CTS_DataCenter.CTSCustomerClassification_History, CTSCustomerClassification_BySport_History ************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_History') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_History AS his WHERE his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_History_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_History_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_History_Clean(ID)
            SELECT 	his.ID
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			WHERE  his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE his
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			WHERE  his.ID IN (SELECT tmp.ID FROM Temp_CTSCustomerClassification_History_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_History'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CTSCustomerClassification_History_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_BySport_History';
	 END IF; 
     
     IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_BySport_History') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his WHERE his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_BySport_History_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_BySport_History_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_BySport_History_Clean(ID)
            SELECT 	his.ID
			FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his
			WHERE  his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE his
			FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his
			WHERE  his.ID IN (SELECT tmp.ID FROM Temp_CTSCustomerClassification_BySport_History_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_BySport_History'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CTSCustomerClassification_BySport_History_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog';
	 END IF; 
     
    /*************************************** 16. CTS_DataCenter.CTSCustomerClassification_InputDataLog *******/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo WHERE lo.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN 
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_InputDataLog_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_InputDataLog_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_InputDataLog_Clean(ID)
            SELECT 	lo.ID
			FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo
			WHERE  lo.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE lo
			FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo
			WHERE  lo.ID IN (SELECT tmp.ID FROM Temp_CTSCustomerClassification_InputDataLog_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CTSCustomerClassification_InputDataLog_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustDCSAccount';
	 END IF; 
    
    /*************************************** 17. CTS_DataCenter.CustDCSAccount *******************************/
	IF (lv_Table = 'CTS_DataCenter.CustDCSAccount') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustDCSAccount AS cu WHERE cu.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DELETE cu
			FROM CTS_DataCenter.CustDCSAccount AS cu
			WHERE  cu.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustDCSAccount'
			WHERE ParameterID = 46;
					
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidence-Leve0';
	 END IF; 
    
    /*************************************** 18. CTS_DataCenter.CustEvidence *********************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidence-Leve0') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
            SELECT 	ev.CustEvidID
			FROM CTS_DataCenter.CustEvidence AS ev
			WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustEvidence AS ev
			WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidence_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidence-Leve0'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustEvidence_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidence-Leve2';
	 END IF; 
     
    IF (lv_Table = 'CTS_DataCenter.CustEvidence-Leve2') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence AS ev WHERE ev.FromCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
            SELECT 	ev.CustEvidID
			FROM CTS_DataCenter.CustEvidence AS ev
			WHERE  ev.FromCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustEvidence  AS ev
			WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidence_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidence-Leve2'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustEvidence_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceFromFile';
	 END IF;         

	/*************************************** 19. CTS_DataCenter.CustEvidenceFromFile *************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceFromFile') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceFromFile AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceFromFile_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceFromFile_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceFromFile_Clean(ID)
            SELECT 	ev.ID
			FROM CTS_DataCenter.CustEvidenceFromFile AS ev
			WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustEvidenceFromFile AS ev
			WHERE  ev.ID IN (SELECT tmp.ID FROM Temp_CustEvidenceFromFile_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceFromFile'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustEvidenceFromFile_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceLog';
	 END IF;     
     
    /*************************************** 20. CTS_DataCenter.CustEvidenceLog ******************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceLog') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceLog AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceLog_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceLog_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceLog_Clean(CustEvidID)
            SELECT 	ev.CustEvidID
			FROM CTS_DataCenter.CustEvidenceLog AS ev
			WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustEvidenceLog AS ev
			WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidenceLog_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceLog'
			WHERE ParameterID = 46;
		   
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustEvidenceLog_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceQueue';
	 END IF; 
     
    /*************************************** 21. CTS_DataCenter.CustEvidenceQueue ****************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceQueue') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceQueue AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceQueue_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceQueue_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceQueue_Clean(ID)
            SELECT 	ev.ID
			FROM CTS_DataCenter.CustEvidenceQueue AS ev
			WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustEvidenceQueue AS ev
			WHERE  ev.ID IN (SELECT tmp.ID FROM Temp_CustEvidenceQueue_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceQueue'
			WHERE ParameterID = 46;
		
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustEvidenceQueue_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustException-From';
	 END IF;   
	
	/*************************************** 22. CTS_DataCenter.CustException ********************************/
	IF (lv_Table = 'CTS_DataCenter.CustException-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException AS ex WHERE ex.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustException_Clean;
			CREATE TEMPORARY TABLE Temp_CustException_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_CustException_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	ex.FromCTSCustID
				,	ex.ToCTSCustID
			FROM CTS_DataCenter.CustException AS ex
			WHERE  ex.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.CustException AS ass
				INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustException-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustException_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustException-To';
	 END IF; 
     
    IF (lv_Table = 'CTS_DataCenter.CustException-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException AS ex WHERE ex.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustException_Clean;
			CREATE TEMPORARY TABLE Temp_CustException_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_CustException_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	ex.FromCTSCustID
				,	ex.ToCTSCustID
			FROM CTS_DataCenter.CustException  AS ex
			WHERE  ex.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.CustException AS ass
				INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustException-To'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustException_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustRetractEvidence';
	 END IF; 
     
    /*************************************** 23. CTS_DataCenter.CustRetractEvidence ***************************/
	IF (lv_Table = 'CTS_DataCenter.CustRetractEvidence' ) THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustRetractEvidence  AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustRetractEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustRetractEvidence_Clean(
					CTSCustID   		BIGINT UNSIGNED  
				,	EvidenceID			BIGINT UNSIGNED
                ,	PRIMARY KEY(CTSCustID, EvidenceID)
			);
            
			INSERT IGNORE INTO Temp_CustRetractEvidence_Clean(CTSCustID, EvidenceID)
            SELECT 	ev.CTSCustID
				,	ev.EvidenceID
			FROM CTS_DataCenter.CustRetractEvidence AS ev
			WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustRetractEvidence AS ev
				INNER JOIN Temp_CustRetractEvidence_Clean AS tmp ON tmp.CTSCustID = ev.CTSCustID
															AND tmp.EvidenceID = ev.EvidenceID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustRetractEvidence'
			WHERE ParameterID = 46;
		   
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_CustRetractEvidence_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.PinCustomerCategory';
	 END IF; 
     
	/*************************************** 24. CTS_DataCenter.PinCustomerCategory ***************************/
	IF (lv_Table = 'CTS_DataCenter.PinCustomerCategory') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.PinCustomerCategory AS pin WHERE pin.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_PinCustomerCategory_Clean;
			CREATE TEMPORARY TABLE Temp_PinCustomerCategory_Clean(
					CTSCustID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_PinCustomerCategory_Clean(CTSCustID)
            SELECT 	pin.CTSCustID
			FROM CTS_DataCenter.PinCustomerCategory AS pin
			WHERE  pin.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            
            DELETE pin
			FROM CTS_DataCenter.PinCustomerCategory AS pin
			WHERE  pin.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_PinCustomerCategory_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.PinCustomerCategory'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_PinCustomerCategory_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.ProbationAccountMonitor';
	 END IF;  
     
    /*************************************** 25. CTS_DataCenter.ProbationAccountMonitor, ProbationAccountMonitor_BySport ***********************/
	IF (lv_Table = 'CTS_DataCenter.ProbationAccountMonitor') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.ProbationAccountMonitor AS pro WHERE pro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp))  THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_ProbationAccountMonitor_Clean;
			CREATE TEMPORARY TABLE Temp_ProbationAccountMonitor_Clean(
					CustID   		BIGINT UNSIGNED 
				,	SportGroupID	SMALLINT
                ,	PRIMARY KEY(CustID, SportGroupID)
			);
            
            INSERT IGNORE INTO Temp_ProbationAccountMonitor_Clean(CustID, SportGroupID)
            SELECT 	pro.CustID
				,	pro.SportGroupID
			FROM CTS_DataCenter.ProbationAccountMonitor AS pro
			WHERE  pro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.ProbationAccountMonitor AS ev
				INNER JOIN Temp_ProbationAccountMonitor_Clean AS tmp ON tmp.CustID = ev.CustID
																	AND tmp.SportGroupID = ev.SportGroupID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.ProbationAccountMonitor'
			WHERE ParameterID = 46;
		
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_ProbationAccountMonitor_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
		
        SET lv_Table = 'CTS_DataCenter.ProbationAccountMonitor_BySport';
	 END IF;  
     
	IF (lv_Table = 'CTS_DataCenter.ProbationAccountMonitor_BySport') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.ProbationAccountMonitor_BySport AS pro WHERE pro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp))  THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_ProbationAccountMonitor_BySport_Clean;
			CREATE TEMPORARY TABLE Temp_ProbationAccountMonitor_BySport_Clean(
					CustID   		BIGINT UNSIGNED 
				,	SportID			SMALLINT
                ,	PRIMARY KEY(CustID, SportID)
			);
            
            INSERT IGNORE INTO Temp_ProbationAccountMonitor_BySport_Clean(CustID, SportID)
            SELECT 	pro.CustID
				,	pro.SportID
			FROM CTS_DataCenter.ProbationAccountMonitor_BySport AS pro
			WHERE  pro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.ProbationAccountMonitor_BySport AS ev
				INNER JOIN Temp_ProbationAccountMonitor_BySport_Clean AS tmp ON tmp.CustID = ev.CustID
																	AND tmp.SportID = ev.SportID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.ProbationAccountMonitor_BySport'
			WHERE ParameterID = 46;
		
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_ProbationAccountMonitor_BySport_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
		
        SET lv_Table = 'CTS_DataCenter.ProblemCaseMonitor';
	 END IF;  
     
    /*************************************** 26. CTS_DataCenter.ProblemCaseMonitor ****************************/
	IF (lv_Table = 'CTS_DataCenter.ProblemCaseMonitor') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.ProblemCaseMonitor AS cas WHERE cas.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_ProblemCaseMonitor_Clean;
			CREATE TEMPORARY TABLE Temp_ProblemCaseMonitor_Clean(
					CustID   		BIGINT UNSIGNED 
				,	ProblemCaseID	SMALLINT
                ,	PRIMARY KEY(CustID, ProblemCaseID)
			);
            
            INSERT IGNORE INTO Temp_ProblemCaseMonitor_Clean(CustID, ProblemCaseID)
            SELECT 	cas.CustID
				,	cas.ProblemCaseID
			FROM CTS_DataCenter.ProblemCaseMonitor AS cas
			WHERE  cas.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE pr
			FROM CTS_DataCenter.ProblemCaseMonitor AS pr
				INNER JOIN Temp_ProblemCaseMonitor_Clean AS tmp ON tmp.CustID = pr.CustID
																AND tmp.ProblemCaseID = pr.ProblemCaseID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.ProblemCaseMonitor'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_ProblemCaseMonitor_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.RobotClassification';
	 END IF;  
     
	/*************************************** 27. CTS_DataCenter.RobotClassification ***************************/
	IF (lv_Table = 'CTS_DataCenter.RobotClassification') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.RobotClassification AS ro WHERE ro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassification_Clean;
			CREATE TEMPORARY TABLE Temp_RobotClassification_Clean(
					ID   BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_RobotClassification_Clean(ID)
            SELECT 	ro.ID
			FROM CTS_DataCenter.RobotClassification AS ro
			WHERE  ro.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ro
			FROM CTS_DataCenter.RobotClassification AS ro
				INNER JOIN Temp_RobotClassification_Clean AS tmp ON tmp.ID = ro.ID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.RobotClassification'
			WHERE ParameterID = 46;
		
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_RobotClassification_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SmartGroupHistory';
	 END IF;
	
    /*************************************** 28. CTS_DataCenter.SmartGroupHistory *****************************/
	IF (lv_Table = 'CTS_DataCenter.SmartGroupHistory') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SmartGroupHistory As his WHERE his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SmartGroupHistory_Clean;
			CREATE TEMPORARY TABLE Temp_SmartGroupHistory_Clean(
					CustID   		BIGINT UNSIGNED 
				,	CreatedDate		DATE
                ,	PRIMARY KEY(CustID, CreatedDate)
			);
            
            INSERT IGNORE INTO Temp_SmartGroupHistory_Clean(CustID, CreatedDate)
            SELECT 	his.CustID
				,	his.CreatedDate
			FROM CTS_DataCenter.SmartGroupHistory As his
			WHERE  his.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.SmartGroupHistory AS ev
				INNER JOIN Temp_SmartGroupHistory_Clean AS tmp ON tmp.CustID = ev.CustID
																AND tmp.CreatedDate = ev.CreatedDate;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SmartGroupHistory'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_SmartGroupHistory_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SpecialCustomerClass';
	 END IF;
	
    /*************************************** 29. CTS_DataCenter.SpecialCustomerClass **************************/
    IF (lv_Table = 'CTS_DataCenter.SpecialCustomerClass') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass As sp WHERE sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_Clean;
			CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_Clean(
					CTSCustID   			BIGINT UNSIGNED 
				,	CreatedFromFunction		TINYINT
                ,	PRIMARY KEY(CTSCustID, CreatedFromFunction)
			);
            
            INSERT IGNORE INTO Temp_SpecialCustomerClass_Clean(CTSCustID, CreatedFromFunction)
            SELECT 	sp.CTSCustID
				,	sp.CreatedFromFunction
			FROM CTS_DataCenter.SpecialCustomerClass As sp
			WHERE  sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
			DELETE sp
			FROM CTS_DataCenter.SpecialCustomerClass AS sp
				INNER JOIN Temp_SpecialCustomerClass_Clean AS tmp ON tmp.CTSCustID = sp.CTSCustID
																AND tmp.CreatedFromFunction = sp.CreatedFromFunction;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SpecialCustomerClass'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_SpecialCustomerClass_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.TaggingExclusion';
	 END IF;    
     
    /*************************************** 30. CTS_DataCenter.TaggingExclusion ******************************/
    IF (lv_Table = 'CTS_DataCenter.TaggingExclusion') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.TaggingExclusion AS tag WHERE tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_TaggingExclusion_Clean;
			CREATE TEMPORARY TABLE Temp_TaggingExclusion_Clean(
					CTSCustID   	BIGINT UNSIGNED PRIMARY KEY 
			);
            
            INSERT IGNORE INTO Temp_TaggingExclusion_Clean(CTSCustID)
            SELECT 	tag.CTSCustID
			FROM CTS_DataCenter.TaggingExclusion AS tag
			WHERE  tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE tag
			FROM CTS_DataCenter.TaggingExclusion AS tag
			WHERE  tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_TaggingExclusion_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.TaggingExclusion'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_TaggingExclusion_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;

		SET lv_Table = 'CTS_Archive.CTSCustomerAssociationStatus';
	 END IF;   
      
	/*************************************** 31. CTS_Archive.CTSCustomerAssociationStatus *********************/
	IF (lv_Table = 'CTS_Archive.CTSCustomerAssociationStatus') THEN 
		IF EXISTS (SELECT 1  FROM CTS_Archive.CTSCustomerAssociationStatus AS acc WHERE  acc.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DELETE acc
			FROM CTS_Archive.CTSCustomerAssociationStatus AS acc
				INNER JOIN  Temp_CustInfo AS tmp ON acc.CTSCustID = tmp.CTSCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.CTSCustomerAssociationStatus'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByAI_Arc-From';
    END IF; 
    
    /*************************************** 32. CTS_Archive.AssociationByAI_Arc ******************************/
	IF (lv_Table = 'CTS_Archive.AssociationByAI_Arc-From') THEN  
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByAI_Arc AS ai WHERE ai.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					ID   	BIGINT UNSIGNED  PRIMARY KEY 
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(ID)
            SELECT ai.ID
			FROM CTS_Archive.AssociationByAI_Arc AS ai
			WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_Archive.AssociationByAI_Arc AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.ID = ass.ID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByAI_Arc-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
		SET lv_Table = 'CTS_Archive.AssociationByAI_Arc-To';
    END IF;
    
    IF (lv_Table = 'CTS_Archive.AssociationByAI_Arc-To') THEN  
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByAI_Arc AS ai WHERE ai.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					ID   	BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(ID)
            SELECT 	ai.ID
			FROM CTS_Archive.AssociationByAI_Arc AS ai
			WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_Archive.AssociationByAI_Arc AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.ID = ass.ID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByAI_Arc-To'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationGroupByAI_Arc';
    END IF; 
    
    IF (lv_Table = 'CTS_Archive.AssociationGroupByAI_Arc') THEN  
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationGroupByAI_Arc AS ai WHERE ai.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationGroupByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationGroupByAI_Clean(
					ID   	BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationGroupByAI_Clean(ID)
            SELECT 	ai.ID
			FROM CTS_Archive.AssociationGroupByAI_Arc AS ai
			WHERE  ai.CustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_Archive.AssociationGroupByAI_Arc AS ass
				INNER JOIN Temp_AssociationGroupByAI_Clean AS tmp ON tmp.ID = ass.ID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationGroupByAI_Arc'
			WHERE ParameterID = 46;

			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationGroupByAI_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByDevice_Arc';
    END IF; 
    
	/*************************************** 33. CTS_Archive.AssociationByDevice_Arc ***************************/
    IF (lv_Table = 'CTS_Archive.AssociationByDevice_Arc') THEN
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByDevice_Arc AS dv WHERE dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByDevice_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByDevice_Clean(ID)
            SELECT 	dv.ID
			FROM CTS_Archive.AssociationByDevice_Arc AS dv
			WHERE  dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE dv
			FROM CTS_Archive.AssociationByDevice_Arc AS dv
			WHERE  dv.ID IN (SELECT tmp.ID FROM Temp_AssociationByDevice_Clean AS tmp);
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByDevice_Arc'
			WHERE ParameterID = 46;
        
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByDevice_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByIP_Arc-From';
	END IF; 
    
    /*************************************** 34. CTS_Archive.AssociationByIP_Arc *******************************/
    IF (lv_Table = 'CTS_Archive.AssociationByIP_Arc-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByIP_Arc AS ip WHERE ip.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ip.ID
			FROM CTS_Archive.AssociationByIP_Arc AS ip
			WHERE  ip.FromCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ip
			FROM CTS_Archive.AssociationByIP_Arc AS ip
			WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByIP_Arc-From'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByIP_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByIP_Arc-To';
	 END IF; 
     
	IF (lv_Table = 'CTS_Archive.AssociationByIP_Arc-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByIP_Arc AS ip WHERE ip.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ip.ID
			FROM CTS_Archive.AssociationByIP_Arc AS ip
			WHERE  ip.ToCustID IN (SELECT tmp.CustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ip
			FROM CTS_Archive.AssociationByIP_Arc AS ip
			WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByIP_Arc-To'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByIP_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByManual_Arc-From';
	 END IF;   
	
	/*************************************** 35. CTS_DataCenter.AssociationByManual_Arc ************************/
    IF (lv_Table = 'CTS_Archive.AssociationByManual_Arc-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByManual_Arc AS ma WHERE ma.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					ID  BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(ID)
            SELECT 	ma.ID
			FROM CTS_Archive.AssociationByManual_Arc AS ma
			WHERE  ma.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_Archive.AssociationByManual_Arc AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.ID = ass.ID;
			
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByManual_Arc-From'
			WHERE ParameterID = 46;
        
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByManual_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_Archive.AssociationByManual_Arc-To';
	 END IF;  
     
    IF (lv_Table = 'CTS_Archive.AssociationByManual_Arc-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByManual_Arc AS ma  WHERE ma.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					ID  BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(ID)
            SELECT 	ma.ID
			FROM CTS_Archive.AssociationByManual_Arc AS ma 
			WHERE  ma.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_Archive.AssociationByManual_Arc AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.ID = ass.ID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_Archive.AssociationByManual_Arc-To'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_AssociationByManual_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SpecialCustomerClass_BySport';
	 END IF;    

	/*************************************** 37. CTS_DataCenter.SpecialCustomerClass_BySport **************************/
    IF (lv_Table = 'CTS_DataCenter.SpecialCustomerClass_BySport') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass_BySport As sp WHERE sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_BySport_Clean;
			CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_BySport_Clean(
					CTSCustID   			BIGINT UNSIGNED 
				,	SportID					SMALLINT
                ,	PRIMARY KEY(CTSCustID, SportID)
			);
            
            INSERT IGNORE INTO Temp_SpecialCustomerClass_BySport_Clean(CTSCustID, SportID)
            SELECT 	sp.CTSCustID
				,	sp.SportID
			FROM CTS_DataCenter.SpecialCustomerClass_BySport As sp
			WHERE  sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
			DELETE sp
			FROM CTS_DataCenter.SpecialCustomerClass_BySport AS sp
				INNER JOIN Temp_SpecialCustomerClass_BySport_Clean AS tmp ON tmp.CTSCustID = sp.CTSCustID
																AND tmp.SportID = sp.SportID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SpecialCustomerClass_BySport'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_SpecialCustomerClass_BySport_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SpecialCustomerClass_History';
	 END IF;    

	/*************************************** 38. CTS_DataCenter.SpecialCustomerClass_History **************************/
    IF (lv_Table = 'CTS_DataCenter.SpecialCustomerClass_History') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass_History As sp WHERE sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_History_Clean;
			CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_History_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_SpecialCustomerClass_History_Clean(ID)
            SELECT 	sp.ID
			FROM CTS_DataCenter.SpecialCustomerClass_History As sp
			WHERE  sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
			DELETE sp
			FROM CTS_DataCenter.SpecialCustomerClass_History AS sp
				INNER JOIN Temp_SpecialCustomerClass_History_Clean AS tmp ON tmp.ID = sp.ID
																AND tmp.SportID = sp.SportID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SpecialCustomerClass_History'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_SpecialCustomerClass_History_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SpecialCustomerClass_BySport_History';
	 END IF;

	/*************************************** 39. CTS_DataCenter.SpecialCustomerClass_BySport_History **************************/
    IF (lv_Table = 'CTS_DataCenter.SpecialCustomerClass_BySport_History') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass_BySport_History As sp WHERE sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_BySport_History_Clean;
			CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_BySport_History_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_SpecialCustomerClass_BySport_History_Clean(ID)
            SELECT 	sp.ID
			FROM CTS_DataCenter.SpecialCustomerClass_BySport_History As sp
			WHERE  sp.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp)
			LIMIT lv_CleanTableBatchSize;
            
			DELETE sp
			FROM CTS_DataCenter.SpecialCustomerClass_BySport_History AS sp
				INNER JOIN Temp_SpecialCustomerClass_BySport_History_Clean AS tmp ON tmp.ID = sp.ID
																AND tmp.SportID = sp.SportID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SpecialCustomerClass_BySport_History'
			WHERE ParameterID = 46;
			
			SELECT COUNT(1)
            INTO lv_Count
            FROM Temp_SpecialCustomerClass_BySport_History_Clean;
            
            IF lv_Count >= lv_CleanTableBatchSize THEN
				LEAVE sp;
            END IF;
			
            SET lv_CleanTableBatchSize = lv_CleanTableBatchSize - lv_Count;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomer';
	 END IF;

    /*************************************** 40. CTS_DataCenter.CTSCustomer ************************************/
	
    DELETE cus
	FROM CTS_DataCenter.CTSCustomer AS cus
	WHERE  cus.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_CustInfo AS tmp);
  
    UPDATE  CTS_DataCenter.SystemParameter 
	SET ParameterValue = 'DCS_DataCenter.Association'
	WHERE ParameterID = 46;
    
    SELECT MAX(ArchiveID) 
    INTO lv_NextID
    FROM Temp_CustInfo;
    
    UPDATE  CTS_DataCenter.SystemParameter 
	SET ParameterValue = lv_NextID
	WHERE ParameterID = 45;

	UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS ar 
	SET	ar.ProcessedDate = NOW()
    WHERE EXISTS (SELECT 1 FROM Temp_CustInfo AS tmp WHERE ar.ID = tmp.ArchiveID);
    
END$$
DELIMITER ;

