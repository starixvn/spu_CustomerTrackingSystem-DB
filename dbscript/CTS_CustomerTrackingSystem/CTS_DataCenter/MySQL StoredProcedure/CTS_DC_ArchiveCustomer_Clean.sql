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
			DELETE 
			FROM  DCS_DataCenter.Association
			WHERE  AccountID IN (SELECT AccountID FROM Temp_CustInfo ) 
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM DCS_DataCenter.Account 
			WHERE  AccountID IN (SELECT AccountID FROM Temp_CustInfo )
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.AssociatedAccountMonitor  
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo )
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE
			FROM CTS_DataCenter.AssociatedAccountNotification
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.AssociationByAI 
			WHERE  FromCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByAI-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
		SET lv_Table = 'CTS_DataCenter.AssociationByAI-To';
    END IF;
    
    IF (lv_Table = 'CTS_DataCenter.AssociationByAI-To') THEN  
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.AssociationByAI 
			WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.AssociationByDevice
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
        
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
			DELETE 
			FROM CTS_DataCenter.AssociationByIP
			WHERE  FromCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByIP-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByIP-To';
	 END IF; 
     
     
     
     IF (lv_Table = 'CTS_DataCenter.AssociationByIP-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP WHERE ToCustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.AssociationByIP
			WHERE  ToCustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-To'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-From';
	 END IF;   
     
     
    
    /********************************************* 8. CTS_DataCenter.AssociationByManual *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-From') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual WHERE FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.AssociationByManual
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
        
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-From'
			WHERE ParameterID = 46;
        
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-To';
	 END IF;  
     
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByManual WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.AssociationByManual
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.AssociationRemove
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationRemove-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.AssociationByManual-To';
	END IF;  
    
    
    
    IF (lv_Table = 'CTS_DataCenter.AssociationByManual-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.AssociationRemove
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.AssociationByManual-To'
			WHERE ParameterID = 46;

			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CTSCustomerClassification';
	 END IF; 


	/********************************************* 10. CTS_DataCenter.CTSCustomerClassification *********************************************************/
    IF (lv_Table = 'CTS_DataCenter.CTSCustomerClassification') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification WHERE CustID IN (SELECT CustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.CTSCustomerClassification
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CTSCustomerClassification_History
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustEvidence
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustEvidence-Leve0'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustEvidence-Leve2';
	 END IF; 
     
	
    IF (lv_Table = 'CTS_DataCenter.CustEvidence-Leve2') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence WHERE FromCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.CustEvidence
			WHERE  FromCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustEvidenceFromFile
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustEvidenceLog
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustEvidenceQueue
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustException
			WHERE  FromCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
			UPDATE  CTS_DataCenter.SystemParameter 
			SET ParameterValue = 'CTS_DataCenter.CustException-From'
			WHERE ParameterID = 46;
			
			LEAVE sp;
        END IF;
        
        SET lv_Table = 'CTS_DataCenter.CustException-To';
	 END IF; 
     
     
     
    IF (lv_Table = 'CTS_DataCenter.CustException-To') THEN
		IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException WHERE ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)) THEN
			DELETE 
			FROM CTS_DataCenter.CustException
			WHERE  ToCTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.CustRetractEvidence
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.PinCustomerCategory
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.ProbationAccountMonitor
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.ProblemCaseMonitor
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.RobotClassification
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.SmartGroupHistory
			WHERE  CustID IN (SELECT CustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.SpecialCustomerClass
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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
			DELETE 
			FROM CTS_DataCenter.TaggingExclusion
			WHERE  CTSCustID IN (SELECT CTSCustID FROM Temp_CustInfo)
			LIMIT lv_CleanTableBatchSize;
			
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

