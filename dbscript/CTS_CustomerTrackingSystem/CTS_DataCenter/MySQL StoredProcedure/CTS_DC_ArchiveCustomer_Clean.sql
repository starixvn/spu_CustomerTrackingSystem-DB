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
			- 	20210927@Aries.Nguyen: Created [Redmine ID: #162277]
		Param's Explanation (filtered by):	
			
	*/
    
    DECLARE lv_CustBatchSize 			INT;
    DECLARE lv_CleanTableBatchSize 		INT;
    DECLARE lv_LastID 					BIGINT UNSIGNED;
    DECLARE lv_NextID 					BIGINT UNSIGNED;
    DECLARE lv_Table 					VARCHAR(100);
    
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
    ORDER BY ID ASC
    LIMIT lv_CustBatchSize;

	IF NOT EXISTS (SELECT 1 FROM Temp_CustInfo) THEN
		LEAVE sp; 
	END IF;
	
    /******************************************** 1. DCS_DataCenter.Association *********************************************************/
    IF (lv_Table = 'DCS_DataCenter.Association') THEN
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.Association  WHERE  AccountID IN (SELECT AccountID FROM Temp_CustInfo )) THEN
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
            
            DELETE ass
			FROM  DCS_DataCenter.Association AS ass
				INNER JOIN Temp_Association_Clean AS tmp ON tmp.AccountID = ass.AccountID AND tmp.DeviceID = ass.DeviceID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.Association'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;

        SET lv_Table = 'DCS_DataCenter.Account';
    END IF;
	

    /********************************************* 2. DCS_DataCenter.Account *********************************************************/
	IF (lv_Table = 'DCS_DataCenter.Account') THEN 
		IF EXISTS (SELECT 1  FROM DCS_DataCenter.Account  WHERE  AccountID IN (SELECT AccountID FROM Temp_CustInfo )) THEN
			DELETE acc
			FROM DCS_DataCenter.Account AS acc
				INNER JOIN  Temp_CustInfo AS tmp ON acc.AccountID = tmp.AccountID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'DCS_DataCenter.Account'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociatedAccountMonitor';
    END IF;
    

	/********************************************* 3. CTS_DataCenter.AssociatedAccountMonitor *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociatedAccountMonitor') THEN 
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountMonitor WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
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
    
    /********************************************* 4. CTS_DataCenter.AssociatedAccountNotification *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociatedAccountNotification') THEN 
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountNotification WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccountNotification_Clean;
			CREATE TEMPORARY TABLE Temp_AssociatedAccountNotification_Clean(
					AccountNewAssID   	BIGINT UNSIGNED  PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociatedAccountNotification_Clean(AccountNewAssID)
            SELECT AccountNewAssID
			FROM CTS_DataCenter.AssociatedAccountNotification
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE
			FROM CTS_DataCenter.AssociatedAccountNotification
			WHERE  AccountNewAssID IN (SELECT AccountNewAssID FROM Temp_AssociatedAccountNotification_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociatedAccountNotification'
			WHERE ParameterID = 46;

			LEAVE sp;
        END IF;
        SET lv_Table = 'CTS_DataCenter.AssociationByAI-From';
    END IF;
    

    /********************************************* 5. CTS_DataCenter.AssociationByAI *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByAI-From') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI WHERE  FromCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					FromCustID   	BIGINT UNSIGNED  
				,	ToCustID		BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCustID, ToCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(FromCustID, ToCustID)
            SELECT 	FromCustID
				,	ToCustID
			FROM CTS_DataCenter.AssociationByAI 
			WHERE  FromCustID IN (SELECT CustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationByAI AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.FromCustID = ass.FromCustID AND tmp.ToCustID = ass.ToCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByAI-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
		SET lv_Table = 'CTS_DataCenter.AssociationByAI-To';
    END IF;
    
    IF (lv_Table = 'CTS_DataCenter.AssociationByAI-To') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
					FromCustID   	BIGINT UNSIGNED  
				,	ToCustID		BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCustID, ToCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByAI_Clean(FromCustID, ToCustID)
            SELECT 	FromCustID
				,	ToCustID
			FROM CTS_DataCenter.AssociationByAI 
			WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationByAI AS ass
				INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.FromCustID = ass.FromCustID AND tmp.ToCustID = ass.ToCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByAI-To'
			WHERE ParameterID = 46;

			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByDevice';
    END IF;
	

    /********************************************* 6. CTS_DataCenter.AssociationByDevice *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByDevice') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByDevice WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByDevice_Clean(
					CTSAssDevID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByDevice_Clean(CTSAssDevID)
            SELECT 	CTSAssDevID
			FROM CTS_DataCenter.AssociationByDevice
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.AssociationByDevice
			WHERE  CTSAssDevID IN (SELECT CTSAssDevID FROM Temp_AssociationByDevice_Clean);
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByDevice'
			WHERE ParameterID = 46;
        
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByIP-From';
	END IF; 
    
	
	/********************************************* 7. CTS_DataCenter.AssociationByIP *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByIP-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP WHERE FromCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.AssociationByIP
			WHERE  FromCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.AssociationByIP
			WHERE  ID IN (SELECT ID FROM Temp_AssociationByIP_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByIP-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByIP-To';
	 END IF; 
     
     
     
     IF (lv_Table = 'CTS_DataCenter.AssociationByIP-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP WHERE ToCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.AssociationByIP
			WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.AssociationByIP
			WHERE  ID IN (SELECT ID FROM Temp_AssociationByIP_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByIP-To'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-From';
	 END IF;   
     
     
    
    /********************************************* 8. CTS_DataCenter.AssociationByManual *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual WHERE FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.AssociationByManual 
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_DataCenter.AssociationByManual AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-From'
			WHERE ParameterID = 46;
        
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-To';
	 END IF;  
     
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByManual_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationByManual_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationByManual_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.AssociationByManual 
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
			DELETE ass
			FROM CTS_DataCenter.AssociationByManual AS ass
				INNER JOIN Temp_AssociationByManual_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-To'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationRemove-From';
	 END IF;    
     
     
     
    /********************************************* 9. CTS_DataCenter.AssociationRemove *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationRemove-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove WHERE FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo))  THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemove_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationRemove_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationRemove_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.AssociationRemove 
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationRemove AS ass
				INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationRemove-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationRemove-To';
	END IF;  
    
    
    
    IF (lv_Table = 'CTS_DataCenter.AssociationRemove-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemove_Clean;
			CREATE TEMPORARY TABLE Temp_AssociationRemove_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_AssociationRemove_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.AssociationRemove 
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.AssociationRemove AS ass
				INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationRemove-To'
			WHERE ParameterID = 46;

			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification';
	 END IF; 


	/********************************************* 10. CTS_DataCenter.CTSCustomerClassification *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Clean(
					CustID   			BIGINT UNSIGNED  
				,	SportGroupID		BIGINT UNSIGNED
                ,	CategoryID			SMALLINT
                ,	PRIMARY KEY(CustID, SportGroupID, CategoryID)
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_Clean(CustID, SportGroupID, CategoryID)
            SELECT 	CustID
				,	SportGroupID
                ,	CategoryID
			FROM CTS_DataCenter.CTSCustomerClassification
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE cl
			FROM CTS_DataCenter.CTSCustomerClassification AS cl
				INNER JOIN Temp_CTSCustomerClassification_Clean AS tmp ON tmp.CustID = cl.CustID 
																		AND tmp.SportGroupID = cl.SportGroupID
																		AND tmp.CategoryID = cl.CategoryID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_History';
	 END IF; 
     
     
    
    /********************************************* 11. CTS_DataCenter.CTSCustomerClassification_History *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_History') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_History WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_History_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_History_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_History_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.CTSCustomerClassification_History
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CTSCustomerClassification_History
			WHERE  ID IN (SELECT ID FROM Temp_CTSCustomerClassification_History_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_History'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog';
	 END IF; 
     

    /********************************************* 12. CTS_DataCenter.CTSCustomerClassification_InputDataLog *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN 
			DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_InputDataLog_Clean;
			CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_InputDataLog_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CTSCustomerClassification_InputDataLog_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog
			WHERE  ID IN (SELECT ID FROM Temp_CTSCustomerClassification_InputDataLog_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CTSCustomerClassification_InputDataLog'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustDCSAccount';
	 END IF; 
    
    
    /********************************************* 13. CTS_DataCenter.CustDCSAccount *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustDCSAccount') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustDCSAccount WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.CustDCSAccount
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustDCSAccount'
			WHERE ParameterID = 46;
					
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidence-Leve0';
	 END IF; 
    

    /********************************************* 14. CTS_DataCenter.CustEvidence *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidence-Leve0') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
            SELECT 	CustEvidID
			FROM CTS_DataCenter.CustEvidence
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CustEvidence
			WHERE  CustEvidID IN (SELECT CustEvidID FROM Temp_CustEvidence_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidence-Leve0'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidence-Leve2';
	 END IF; 
     
	
    IF (lv_Table = 'CTS_DataCenter.CustEvidence-Leve2') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence WHERE FromCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
            SELECT 	CustEvidID
			FROM CTS_DataCenter.CustEvidence
			WHERE  FromCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CustEvidence
			WHERE  CustEvidID IN (SELECT CustEvidID FROM Temp_CustEvidence_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidence-Leve2'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceFromFile';
	 END IF;         
     

	/********************************************* 15. CTS_DataCenter.CustEvidenceFromFile *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceFromFile') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceFromFile WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceFromFile_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceFromFile_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceFromFile_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.CustEvidenceFromFile
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CustEvidenceFromFile
			WHERE  ID IN (SELECT ID FROM Temp_CustEvidenceFromFile_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceFromFile'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceLog';
	 END IF;     
     
     
     
    /********************************************* 16. CTS_DataCenter.CustEvidenceLog *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceLog') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceLog WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceLog_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceLog_Clean(
					CustEvidID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceLog_Clean(CustEvidID)
            SELECT 	CustEvidID
			FROM CTS_DataCenter.CustEvidenceLog
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CustEvidenceLog
			WHERE  CustEvidID IN (SELECT CustEvidID FROM Temp_CustEvidenceLog_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceLog'
			WHERE ParameterID = 46;
		   
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidenceQueue';
	 END IF; 
     
     
    /********************************************* 17. CTS_DataCenter.CustEvidenceQueue *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustEvidenceQueue') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceQueue WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceQueue_Clean;
			CREATE TEMPORARY TABLE Temp_CustEvidenceQueue_Clean(
					ID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_CustEvidenceQueue_Clean(ID)
            SELECT 	ID
			FROM CTS_DataCenter.CustEvidenceQueue
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.CustEvidenceQueue
			WHERE  ID IN (SELECT ID FROM Temp_CustEvidenceQueue_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidenceQueue'
			WHERE ParameterID = 46;
		
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustException-From';
	 END IF;   
	
	/********************************************* 18. CTS_DataCenter.CustException *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustException-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException WHERE FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustException_Clean;
			CREATE TEMPORARY TABLE Temp_CustException_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_CustException_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.CustException 
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.CustException AS ass
				INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustException-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustException-To';
	 END IF; 
     
     
     
    IF (lv_Table = 'CTS_DataCenter.CustException-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustException_Clean;
			CREATE TEMPORARY TABLE Temp_CustException_Clean(
					FromCTSCustID   	BIGINT UNSIGNED  
				,	ToCTSCustID			BIGINT UNSIGNED
                ,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
			);
            
            INSERT IGNORE INTO Temp_CustException_Clean(FromCTSCustID, ToCTSCustID)
            SELECT 	FromCTSCustID
				,	ToCTSCustID
			FROM CTS_DataCenter.CustException 
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ass
			FROM CTS_DataCenter.CustException AS ass
				INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustException-To'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustRetractEvidence';
	 END IF; 
     
     
    
    /********************************************* 19. CTS_DataCenter.CustRetractEvidence *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.CustRetractEvidence' ) THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustRetractEvidence WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_CustRetractEvidence_Clean;
			CREATE TEMPORARY TABLE Temp_CustRetractEvidence_Clean(
					CTSCustID   		BIGINT UNSIGNED  
				,	EvidenceID			BIGINT UNSIGNED
                ,	PRIMARY KEY(CTSCustID, EvidenceID)
			);
            
			INSERT IGNORE INTO Temp_CustRetractEvidence_Clean(CTSCustID, EvidenceID)
            SELECT 	CTSCustID
				,	EvidenceID
			FROM CTS_DataCenter.CustRetractEvidence 
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
            LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.CustRetractEvidence AS ev
				INNER JOIN Temp_CustRetractEvidence_Clean AS tmp ON tmp.CTSCustID = ev.CTSCustID
															AND tmp.EvidenceID = ev.EvidenceID;
			
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustRetractEvidence'
			WHERE ParameterID = 46;
		   
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.PinCustomerCategory';
	 END IF; 
     
     
     
	/********************************************* 20. CTS_DataCenter.PinCustomerCategory *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.PinCustomerCategory') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.PinCustomerCategory WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_PinCustomerCategory_Clean;
			CREATE TEMPORARY TABLE Temp_PinCustomerCategory_Clean(
					CTSCustID   BIGINT UNSIGNED PRIMARY KEY
			);
            
            INSERT IGNORE INTO Temp_PinCustomerCategory_Clean(CTSCustID)
            SELECT 	CTSCustID
			FROM CTS_DataCenter.PinCustomerCategory
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            
            DELETE 
			FROM CTS_DataCenter.PinCustomerCategory
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_PinCustomerCategory_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.PinCustomerCategory'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.ProbationAccountMonitor';
	 END IF;  
     
    /********************************************* 21. CTS_DataCenter.ProbationAccountMonitor *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.ProbationAccountMonitor') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.ProbationAccountMonitor WHERE CustID IN (SELECT CustID FROM Temp_CustInfo))  THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_ProbationAccountMonitor_Clean;
			CREATE TEMPORARY TABLE Temp_ProbationAccountMonitor_Clean(
					CustID   		BIGINT UNSIGNED 
				,	SportGroupID	SMALLINT
                ,	PRIMARY KEY(CustID, SportGroupID)
			);
            
            INSERT IGNORE INTO Temp_ProbationAccountMonitor_Clean(CustID, SportGroupID)
            SELECT 	CustID
				,	SportGroupID
			FROM CTS_DataCenter.ProbationAccountMonitor
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.ProbationAccountMonitor AS ev
				INNER JOIN Temp_ProbationAccountMonitor_Clean AS tmp ON tmp.CustID = ev.CustID
																	AND tmp.SportGroupID = ev.SportGroupID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.ProbationAccountMonitor'
			WHERE ParameterID = 46;
		
			LEAVE sp;
        END IF;
	 END IF;  
     
     SET lv_Table = 'CTS_DataCenter.ProblemCaseMonitor';
    
    /********************************************* 22. CTS_DataCenter.ProblemCaseMonitor *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.ProblemCaseMonitor') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.ProblemCaseMonitor WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_ProblemCaseMonitor_Clean;
			CREATE TEMPORARY TABLE Temp_ProblemCaseMonitor_Clean(
					CustID   		BIGINT UNSIGNED 
				,	ProblemCaseID	SMALLINT
                ,	PRIMARY KEY(CustID, ProblemCaseID)
			);
            
            INSERT IGNORE INTO Temp_ProblemCaseMonitor_Clean(CustID, ProblemCaseID)
            SELECT 	CustID
				,	ProblemCaseID
			FROM CTS_DataCenter.ProblemCaseMonitor
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE pr
			FROM CTS_DataCenter.ProblemCaseMonitor AS pr
				INNER JOIN Temp_ProblemCaseMonitor_Clean AS tmp ON tmp.CustID = pr.CustID
																AND tmp.ProblemCaseID = pr.ProblemCaseID;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.ProblemCaseMonitor'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.RobotClassification';
	 END IF;  
     
	/********************************************* 23. CTS_DataCenter.RobotClassification *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.RobotClassification') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.RobotClassification WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassification_Clean;
			CREATE TEMPORARY TABLE Temp_RobotClassification_Clean(
					CustID   		BIGINT UNSIGNED 
				,	SportTypeID		SMALLINT UNSIGNED
                ,	BetTypeID		SMALLINT UNSIGNED
                ,	LiveIndicator 	BIT
                ,	FromDate		DATE
                ,	PRIMARY KEY(CustID, SportTypeID, BetTypeID, LiveIndicator, FromDate)
			);
            
            INSERT IGNORE INTO Temp_RobotClassification_Clean(CustID, SportTypeID, BetTypeID, LiveIndicator, FromDate)
            SELECT 	CustID
				,	SportTypeID
                ,	BetTypeID
                ,	LiveIndicator
                ,	FromDate
			FROM CTS_DataCenter.RobotClassification
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ro
			FROM CTS_DataCenter.RobotClassification AS ro
				INNER JOIN Temp_RobotClassification_Clean AS tmp ON tmp.CustID = ro.CustID
																AND tmp.SportTypeID = ro.SportTypeID
                                                                AND tmp.BetTypeID = ro.BetTypeID
                                                                AND tmp.LiveIndicator = ro.LiveIndicator
                                                                AND tmp.FromDate = ro.FromDate;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.RobotClassification'
			WHERE ParameterID = 46;
		
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SmartGroupHistory';
	 END IF;
	
    
    
    /********************************************* 24. CTS_DataCenter.SmartGroupHistory *********************************************************/
	IF (lv_Table = 'CTS_DataCenter.SmartGroupHistory') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SmartGroupHistory WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SmartGroupHistory_Clean;
			CREATE TEMPORARY TABLE Temp_SmartGroupHistory_Clean(
					CustID   		BIGINT UNSIGNED 
				,	CreatedDate		DATE
                ,	PRIMARY KEY(CustID, CreatedDate)
			);
            
            INSERT IGNORE INTO Temp_SmartGroupHistory_Clean(CustID, CreatedDate)
            SELECT 	CustID
				,	CreatedDate
			FROM CTS_DataCenter.SmartGroupHistory
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE ev
			FROM CTS_DataCenter.SmartGroupHistory AS ev
				INNER JOIN Temp_SmartGroupHistory_Clean AS tmp ON tmp.CustID = ev.CustID
																AND tmp.CreatedDate = ev.CreatedDate;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SmartGroupHistory'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.SpecialCustomerClass';
	 END IF;
     

    /********************************************* 25. CTS_DataCenter.SpecialCustomerClass *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.SpecialCustomerClass') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_Clean;
			CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_Clean(
					CTSCustID   			BIGINT UNSIGNED 
				,	CreatedFromFunction		TINYINT
                ,	PRIMARY KEY(CTSCustID, CreatedFromFunction)
			);
            
            INSERT IGNORE INTO Temp_SpecialCustomerClass_Clean(CTSCustID, CreatedFromFunction)
            SELECT 	CTSCustID
				,	CreatedFromFunction
			FROM CTS_DataCenter.SpecialCustomerClass
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
			DELETE sp
			FROM CTS_DataCenter.SpecialCustomerClass AS sp
				INNER JOIN Temp_SpecialCustomerClass_Clean AS tmp ON tmp.CTSCustID = sp.CTSCustID
																AND tmp.CreatedFromFunction = sp.CreatedFromFunction;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.SpecialCustomerClass'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.TaggingExclusion';
	 END IF;    
     

    /********************************************* 26. CTS_DataCenter.TaggingExclusion *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.TaggingExclusion') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.TaggingExclusion WHERE CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DROP TEMPORARY TABLE IF EXISTS Temp_TaggingExclusion_Clean;
			CREATE TEMPORARY TABLE Temp_TaggingExclusion_Clean(
					CTSCustID   	BIGINT UNSIGNED PRIMARY KEY 
			);
            
            INSERT IGNORE INTO Temp_TaggingExclusion_Clean(CTSCustID)
            SELECT 	CTSCustID
			FROM CTS_DataCenter.TaggingExclusion
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
            
            DELETE 
			FROM CTS_DataCenter.TaggingExclusion
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_TaggingExclusion_Clean);
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.TaggingExclusion'
			WHERE ParameterID = 46;

			LEAVE sp;
        END IF;
	 END IF;   
      
        
	/********************************************* 27. CTS_DataCenter.CTSCustomer *********************************************************/
	DELETE 
	FROM CTS_DataCenter.CTSCustomer
	WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo);
  
    UPDATE  CTS_DataCenter.SystemParameter 
	SET ParameterValue = 'DCS_DataCenter.Association'
	WHERE ParameterID = 46;
    
    SELECT MAX(ArchiveID) 
    INTO lv_NextID
    FROM Temp_CustInfo;
    
    UPDATE  CTS_DataCenter.SystemParameter 
	SET ParameterValue = lv_NextID
	WHERE ParameterID = 45;


END$$
DELIMITER ;

