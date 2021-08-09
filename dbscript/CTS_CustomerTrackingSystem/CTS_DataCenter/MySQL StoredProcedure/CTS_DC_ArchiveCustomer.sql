/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ArchiveCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ArchiveCustomer`(
		IN ip_CustomerList JSON
	,	IN ip_CustType TINYINT
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210804@Casey.Huynh
		Task :		Archive Customer
		DB:			CTS_DataCenter, DCS_DataCenter
		Original:

		Revisions:
			- 	20210804@Casey.Huynh: Created [Redmine ID: 152883]
			-	20210719@Casey.Huynh: Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_ArchiveCustomer(ip_TempGroupID);
			
	*/
    DECLARE lv_MaxArchiveTime DATETIME(3);
    DECLARE lv_MaxCustID INT UNSIGNED;
    DECLARE lv_MinArchiveDate DATETIME(3);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomer;
    CREATE TEMPORARY TABLE Temp_InputCustomer
    (
			CustID	INT UNSIGNED
        ,	ArchivedDateMainDB	DATETIME(3)
        
        ,	PRIMARY KEY Temp_InputCustomer(ArchivedDateMainDB, CustID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ArchiveCustDCSAccount;
    CREATE TEMPORARY TABLE Temp_ArchiveCustDCSAccount(		
			AccountID BIGINT UNSIGNED
        ,	CTSCustID BIGINT UNSIGNED
        ,	ArchivedDateMainDB	DATETIME(3)	
        ,	PRIMARY KEY PK_Temp_ArchiveCustDCSAccount_AccountID(AccountID, ArchivedDateMainDB)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ArchiveCTSCustomer;
    CREATE TEMPORARY TABLE Temp_ArchiveCTSCustomer(		
        	ArchivedDateMainDB	DATETIME(3)
		,	CTSCustID	BIGINT UNSIGNED
		, 	CustID	INT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	UserName2	VARCHAR(50)
        ,	SubscriberID	INT
        ,	RoleID			TINYINT
        
        ,	PRIMARY KEY Temp_ArchiveCustomer(CTSCustID, ArchivedDateMainDB)
        ,	INDEX Temp_ArchiveCustomer(CustID, CustSubID)
    ); 
	
	/***********************GET ARCHIVE DATA TO TEMPTABLE*************************************************************/
    INSERT INTO Temp_InputCustomer(CustID, ArchivedDateMainDB)
	SELECT		CustID	
			,	ArchivedDateMainDB
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
						CustID				INT	 UNSIGNED		PATH "$.CustID" 
					,	ArchivedDateMainDB	DATETIME(3)			PATH "$.ArchivedDateMainDB"
				)
	) AS js;
    
    INSERT INTO Temp_ArchiveCTSCustomer(ArchivedDateMainDB, CTSCustID, CustID, CustSubID, UserName, UserName2, SubscriberID, RoleID)
    SELECT tmpCus.ArchivedDateMainDB
		,	cus.CTSCustID
        ,	cus.CustID
        ,	cus.CustSubID
        ,	cus.UserName
        ,	cus.UserName2
        ,	cus.SubscriberID
        ,	cus.RoleID
    FROM Temp_InputCustomer AS tmpCus
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID;
        
    INSERT IGNORE INTO Temp_ArchiveCustDCSAccount(AccountID, CTSCustID, ArchivedDateMainDB)
    SELECT 	tmpCus.CTSCustID
		,	cda.AccountID
        ,	cda.AccountID
	FROM	 Temp_ArchiveCTSCustomer AS tmpCus
    INNER JOIN CTS_DataCenter.CustDCSAccount AS cda ON tmpCus.CTSCustID = cda.CTSCustID;
   
    /***********************REMOVE PREVIOUS ARCHIVE DATA*************************************************************/
    SELECT MIN(ArchivedDateMainDB)
    INTO lv_MinArchiveDate
    FROM Temp_ArchiveCTSCustomer;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arcCus WHERE ArchivedDateMainDB < lv_MinArchiveDate)
    THEN
		DELETE  arcCus
		FROM	ArchiveCustomer_CTSCustomer AS arcCus
		WHERE	ArchivedDateMainDB < lv_MinArchiveDate;
	END IF;
    
    /***********************BACKUP ARCHIVE DATA*************************************************************/
    INSERT IGNORE INTO CTS_DataCenter.ArchiveCustomer_CTSCustomer(ArchivedDateMainDB, CTSCustID, SubscriberID, CustID, CustSubID, UserName, UserName2, RoleID, InsertTime)
    SELECT	tmpCus.ArchivedDateMainDB
		,	tmpCus.CTSCustID
        ,	tmpCus.SubscriberID
        ,	tmpCus.CustID
        ,	tmpCus.CustSubID
        ,	tmpCus.UserName
        ,	tmpCus.UserName2
        ,	tmpCus.RoleID
        ,	CURRENT_TIMESTAMP(3)
    FROM Temp_ArchiveCTSCustomer AS tmpCus;
	
    /**********************DELETE DCS DATA *********************************************************/
    /***********************************************************************************************/
    #=============1.==================================================================================
	DELETE del
    FROM DCS_DataCenter.Association AS del
		INNER JOIN Temp_ArchiveCustDCSAccount AS tmpAcc ON del.AccountID = tmpAcc.AccountID;
    
    #=============2.==================================================================================
    DELETE del
    FROM DCS_DataCenter.Account AS del
		INNER JOIN Temp_ArchiveCustDCSAccount AS tmpAcc ON del.AccountID = tmpAcc.AccountID;
    
	/**********************DELETE CTS DATA *********************************************************/
    #==============1.=================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociatedAccountMonitor AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;
    
    #==============2.=================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociatedAccountNotification AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;
    
    #===============3.================================================================================
    DELETE del
	FROM CTS_DataCenter.Association AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCTSCustID = tmpCus.CTSCustID;
    
    DELETE del
	FROM CTS_DataCenter.Association AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCTSCustID = tmpCus.CTSCustID;
    
    #===============4.================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociationByAI AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCustID = tmpCus.CustID;
    
    DELETE del
	FROM CTS_DataCenter.AssociationByAI AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCustID = tmpCus.CustID;
    
    #===============5.================================================================================
	DROP TABLE IF EXISTS Temp_DCSDevice;
    CREATE TEMPORARY TABLE Temp_DCSDevice(
		DCSDeviceID BIGINT UNSIGNED
    );
    
    INSERT INTO Temp_DCSDevice(DCSDeviceID)
    SELECT asd.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS asd
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON asd.CTSCustID = tmpCus.CTSCustID
        INNER JOIN	CTS_DataCenter.DeviceAssociationDay AS dad ON dad.DCSDeviceID = asd.DCSDeviceID;
  
    DELETE del
	FROM CTS_DataCenter.AssociationByDevice AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;
    
    DROP TABLE IF EXISTS Temp_RemoveDCSDevice;
    CREATE TEMPORARY TABLE Temp_RemoveDCSDevice(
		DCSDeviceID BIGINT UNSIGNED
    );
    
    #===============6.================================================================================
    INSERT INTO CTS_DataCenter.Temp_RemoveDCSDevice(DCSDeviceID)
    SELECT tmp.DCSDeviceID
    FROM Temp_DCSDevice AS tmp
    INNER JOIN CTS_DataCenter.AssociationByDevice AS asd ON tmp.DCSDeviceID = asd.DCSDeviceID
    GROUP BY DCSDeviceID
    HAVING COUNT(1) = 1;
    
    DELETE del
	FROM CTS_DataCenter.DeviceAssociationDay AS del
		INNER JOIN	Temp_RemoveDCSDevice AS tmpDev ON del.DCSDeviceID = tmpDev.DCSDeviceID;   
        
	#===============7.================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociationByIP AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCustID = tmpCus.CustID;
    
    DELETE del
	FROM CTS_DataCenter.AssociationByIP AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCustID = tmpCus.CustID;
    
    #===============8.================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociationByManual AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCTSCustID = tmpCus.CTSCustID;
    
    DELETE del
	FROM CTS_DataCenter.AssociationByManual AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCTSCustID = tmpCus.CTSCustID;    
    
    #===============9.================================================================================
    DELETE del
	FROM CTS_DataCenter.AssociationRemove AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCTSCustID = tmpCus.CTSCustID;
    
    DELETE del
	FROM CTS_DataCenter.AssociationRemove AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCTSCustID = tmpCus.CTSCustID;
        
	#===============10.================================================================================
	DELETE del
	FROM CTS_DataCenter.CTSCustomerClassification AS del
		INNER JOIN Temp_ArchiveCTSCustomer AS tmpCus ON  del.CustID = tmpCus.CustID; 
    
    #===============11.================================================================================
	DELETE del
	FROM CTS_DataCenter.CTSCustomerClassification_History AS del
		INNER JOIN Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID; 
    
    #===============12.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID; 
    
    #===============13.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustDCSAccount AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
    #===============14.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustEvidence AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
    DELETE 	del
	FROM CTS_DataCenter.CustEvidence AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCustID = tmpCus.CTSCustID;      
    
	#===============15.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustEvidenceFromFile AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
	
    #===============16.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustEvidenceLog AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
    #===============17.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustEvidenceQueue AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
        
	#===============18.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustException AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.FromCTSCustID = tmpCus.CTSCustID; 
        
	DELETE 	del
	FROM CTS_DataCenter.CustException AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.ToCTSCustID = tmpCus.CTSCustID; 
    
    #===============19.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustRetractEvidence AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
    #===============20.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CustRetractEvidence AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
	#===============21.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.PinCustomerCategory AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID; 
    
    #===============22.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.ProbationAccountMonitor AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID; 
    
     #===============23.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.ProblemCaseMonitor AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID; 
    
	#===============24.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.RobotClassification AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID;     
    
    #===============25.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.SmartGroupHistory AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CustID = tmpCus.CustID; 

    #===============25.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.SpecialCustomerClass AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;     
    
    #===============26.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.TaggingExclusion AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;   
        
	#===============27.================================================================================
	DELETE 	del
	FROM CTS_DataCenter.CTSCustomer AS del
		INNER JOIN	Temp_ArchiveCTSCustomer AS tmpCus ON del.CTSCustID = tmpCus.CTSCustID;  
    
    /********UPDATE SYSTEM PARAMETER*****************************************/
    /************************************************************************/

    IF EXISTS(SELECT 1 FROM  Temp_ArchiveCTSCustomer)
    THEN
		SELECT MAX(ArchivedDateMainDB) 
		INTO lv_MaxArchiveTime
		FROM Temp_ArchiveCTSCustomer;
        
		SELECT lv_MaxArchiveTime;
        
        SELECT MAX(CustID) 
		FROM Temp_ArchiveCTSCustomer
		WHERE ArchivedDateMainDB = lv_MaxArchiveTime;
        
		SELECT MAX(CustID) 
		INTO lv_MaxCustID
		FROM Temp_ArchiveCTSCustomer
		WHERE ArchivedDateMainDB = lv_MaxArchiveTime;
		
        IF (ip_CustType = 0) THEN
			UPDATE CTS_DataCenter.SystemParameter
			SET ParameterValue = lv_MaxArchiveTime
			WHERE ParameterID = 24;
			
			UPDATE CTS_DataCenter.SystemParameter
			SET ParameterValue = lv_MaxCustID
			WHERE ParameterID = 25;
		END IF;
        
        IF (ip_CustType = 1) THEN
			UPDATE CTS_DataCenter.SystemParameter
			SET ParameterValue = lv_MaxArchiveTime
			WHERE ParameterID = 26;
			
			UPDATE CTS_DataCenter.SystemParameter
			SET ParameterValue = lv_MaxCustID
			WHERE ParameterID = 27;
		END IF;
    END IF;
END$$
DELIMITER ;

