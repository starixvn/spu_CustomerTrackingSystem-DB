/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
		Created:	20210426@John.Ngo
		Task:		Remove Duplicate Customer [Redmine ID: #153283]
		DB:			CTS_Adhoc

		Revisions:
			- 20210426@John.Ngo: Created [Redmine ID: #153283]

*/
USE CTS_Adhoc;

DELIMITER $$
DROP PROCEDURE IF EXISTS `CTS_Adhoc`.`CTS_AD_RemoveDuplicateCustomer`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_RemoveDuplicateCustomer`(IN ip_Size INT, IN ip_Delay SMALLINT)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210426@John.Ngo
		Task:		Remove Duplicate Customer [Redmine ID: #153283]
		DB:			CTS_Adhoc

		Revisions:
			- 20210426@John.Ngo: Created [Redmine ID: #153283]
            
		Param's Explanation (filtered by):         
        
        Example:
       
	*/
	DECLARE lv_FromCTSCustID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToCTSCustID BIGINT UNSIGNED DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ArchiveCTSCustomer;
    CREATE TEMPORARY TABLE Temp_ArchiveCTSCustomer(
			CTSCustID BIGINT UNSIGNED
		,	CustID BIGINT UNSIGNED
        ,	PRIMARY KEY PK_Temp_ArchiveCTSCustomer_CTSCustID(CTSCustID)
        ,	INDEX IX_Temp_ArchiveCTSCustomer_CustID(CustID)        
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ArchiveDCSAccount;
    CREATE TEMPORARY TABLE Temp_ArchiveDCSAccount(
			AccountID BIGINT UNSIGNED
        ,	PRIMARY KEY PK_Temp_ArchiveDCSAccount_AccountID(AccountID)
    );
    
    WHILE lv_ToCTSCustID IS NOT NULL
    DO
		
        SET lv_ToCTSCustID = (SELECT MAX(tmp.CTSCustID) 
								FROM ( 	SELECT arcCus.CTSCustID 
										FROM CTS_Adhoc.BK153283_MainDB_Customer AS arcCus
                                        WHERE arcCus.CTSCustID >=  lv_FromCTSCustID
                                        ORDER BY arcCus.CTSCustID ASC
										LIMIT ip_Size) AS tmp);
		
		INSERT IGNORE INTO Temp_ArchiveCTSCustomer(CTSCustID, CustID)
		SELECT 		arcCus.CTSCustID, arcCus.CustID
        FROM		CTS_Adhoc.BK153283_MainDB_Customer AS arcCus
        WHERE	arcCus.CTSCustID BETWEEN lv_FromCTSCustID AND lv_ToCTSCustID;
		
		/********************** GET ARCHIVE CTS DATA****************************************************/        
		INSERT IGNORE INTO CTS_Adhoc.BK153283_CTSCustomer
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CTSCustomer AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID; 
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CTSCustomer AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID; 
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CustDCSAccount
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CustDCSAccount AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CustDCSAccount AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;  
        
		/******************************************************/
		INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByDevice
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByDevice AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;   
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByDevice AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;  
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByManual
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByManual AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByManual AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;   
        
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByManual
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByManual AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID AND ctsCus.FromCTSCustID <> ctsCus.ToCTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByManual AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID;		
        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByAI
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByAI AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.FromCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByAI AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.FromCustID;   
        
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByAI
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByAI AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.ToCustID AND ctsCus.FromCustID <> ctsCus.ToCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByAI AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.ToCustID;		
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByIP
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByIP AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.FromCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByIP AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.FromCustID;   
        
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationByIP
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationByIP AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.ToCustID AND ctsCus.FromCustID <> ctsCus.ToCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationByIP AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.ToCustID;		
		/******************************************************/ 
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationRemove
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationRemove AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationRemove AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;   
        
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociationRemove
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociationRemove AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociationRemove AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID;        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociatedAccountMonitor
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociatedAccountMonitor AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociatedAccountMonitor AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_AssociatedAccountNotification
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.AssociatedAccountNotification AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.AssociatedAccountNotification AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;  
		
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CustEvidence
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CustEvidence AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CustEvidence AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCustID; 
        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CustRetractEvidence
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CustRetractEvidence AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CustRetractEvidence AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CustEvidenceLog
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CustEvidenceLog AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;
		
		DELETE		ctsCus
        FROM		CTS_DataCenter.CustEvidenceLog AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCustID; 
        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CustException(FromCTSCustID, ToCTSCustID, CreatedDate, CreatedBy, Comment)
        SELECT 		ctsCus.FromCTSCustID, ctsCus.ToCTSCustID, ctsCus.CreatedDate, ctsCus.CreatedBy, ctsCus.Comment
        FROM		CTS_DataCenter.CustException AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;
        
		DELETE		ctsCus
        FROM		CTS_DataCenter.CustException AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.FromCTSCustID;   
        
		INSERT IGNORE INTO CTS_Adhoc.BK153283_CustException(FromCTSCustID, ToCTSCustID, CreatedDate, CreatedBy, Comment)
        SELECT 		ctsCus.FromCTSCustID, ctsCus.ToCTSCustID, ctsCus.CreatedDate, ctsCus.CreatedBy, ctsCus.Comment
        FROM		CTS_DataCenter.CustException AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID;
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CustException AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.ToCTSCustID;    
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_CTSCustomerClassification
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CTSCustomerClassification AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CTSCustomerClassification AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID; 
        /******************************************************/
		INSERT IGNORE INTO CTS_Adhoc.BK153283_CTSCustomerClassification_History
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.CTSCustomerClassification_History AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.CTSCustomerClassification_History AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;   

        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_PinCustomerCategory
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.PinCustomerCategory AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.PinCustomerCategory AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;   
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_SpecialCustomerClass
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.SpecialCustomerClass AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.SpecialCustomerClass AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;        
		
        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_ProbationAccountMonitor
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.ProbationAccountMonitor AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.ProbationAccountMonitor AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;   
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_SmartGroup
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.SmartGroup AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.SmartGroup AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;   
        
        /******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_SmartGroupHistory
        SELECT 		ctsCus.*
        FROM		CTS_DataCenter.SmartGroupHistory AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;    
        
        DELETE		ctsCus
        FROM		CTS_DataCenter.SmartGroupHistory AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CustID = ctsCus.CustID;   
        
        /***************************GET ARCHIVE DCS DATA*****************************************/        
		INSERT IGNORE INTO Temp_ArchiveDCSAccount(AccountID)
        SELECT 		ctsCus.AccountID
        FROM		CTS_DataCenter.CustDCSAccount AS ctsCus
        INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON tmpCus.CTSCustID = ctsCus.CTSCustID;    
        
		/******************************************************/
        INSERT IGNORE INTO CTS_Adhoc.BK153283_DCS_Account
        SELECT 		dcsAcc.*
        FROM		DCS_DataCenter.Account AS dcsAcc
        INNER JOIN	Temp_ArchiveDCSAccount AS tmpAcc ON tmpAcc.AccountID = dcsAcc.AccountID;  
        
        DELETE		dcsAcc
        FROM		DCS_DataCenter.Account AS dcsAcc
        INNER JOIN	Temp_ArchiveDCSAccount AS tmpAcc ON tmpAcc.AccountID = dcsAcc.AccountID;  
        
		/******************************************************/        
        INSERT IGNORE INTO CTS_Adhoc.BK153283_DCS_Association
        SELECT 		dcsAss.*
        FROM		DCS_DataCenter.Association AS dcsAss
        INNER JOIN	Temp_ArchiveDCSAccount AS tmpAcc ON tmpAcc.AccountID = dcsAss.AccountID;   
        
        DELETE		dcsAss
        FROM		DCS_DataCenter.Association AS dcsAss
        INNER JOIN	Temp_ArchiveDCSAccount AS tmpAcc ON tmpAcc.AccountID = dcsAss.AccountID;
        
        /******************************************************/     
        /*
		DELETE		arcCus
        FROM 		CTS_Adhoc.BK153283_MainDB_Customer AS arcCus 
		WHERE 		arcCus.CTSCustID BETWEEN lv_FromCTSCustID AND lv_ToCTSCustID;
		*/
		SET lv_FromCTSCustID = lv_ToCTSCustID + 1;
        
        TRUNCATE TABLE Temp_ArchiveCTSCustomer;
        TRUNCATE TABLE Temp_ArchiveDCSAccount;
        
        DO SLEEP(ip_Delay);
    END WHILE;
END$$
DELIMITER ;

#Execution 
CALL CTS_AD_RemoveDuplicateCustomer(2000, 1);

DROP PROCEDURE IF EXISTS CTS_AD_RemoveDuplicateCustomer;


