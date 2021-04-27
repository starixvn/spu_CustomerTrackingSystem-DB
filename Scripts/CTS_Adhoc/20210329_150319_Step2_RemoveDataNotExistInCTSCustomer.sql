/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Created: John.Ngo
	Task:	 Remove data from tables which is not existing in CTSCustomer
	DB: 	 CTS_Adhoc

	Revisions:
			- 20210329@John.Ngo: Created [Redmine ID: 150319]
*/
USE CTS_Adhoc;

DELIMITER $$
DROP PROCEDURE IF EXISTS `CTS_Adhoc`.`CTS_AD_RemoveDataNotExistInCTSCustomer`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_RemoveDataNotExistInCTSCustomer`(IN ip_Batch INT, IN ip_Delay SMALLINT)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: John.Ngo
		Task:	 Remove data from tables which is not existing in CTSCustomer
		DB: 	 CTS_Adhoc

		Revisions:
				- 20210329@John.Ngo: Created [Redmine ID: 150319]

		Param's Explanation (filtered by):  
				- ip_Batch:   Batch count of CustID/CTSCustID/AccountID to run each cycle
                - ip_Delay:   Delay time between each cycle

		Example: CALL CTS_AD_RemoveDataNotExistInCTSCustomer(10000, 1);
	*/
    DECLARE vr_Count BIGINT DEFAULT 0;
	DECLARE MinID 	 BIGINT DEFAULT 0;
	DECLARE MaxID 	 BIGINT DEFAULT 0;
    
	#============================================
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerToDelete;
	#============================================

	CREATE TEMPORARY TABLE Temp_CustomerToDelete (
		CTSCustID			BIGINT UNSIGNED
	,	CustID				BIGINT UNSIGNED
	,	AccountID			BIGINT UNSIGNED
	,	INDEX	IX_Temp_CustomerToDelete_CTSCustID(CTSCustID) 
	,	INDEX	IX_Temp_CustomerToDelete_CustID(CustID)
	,	INDEX	IX_Temp_CustomerToDelete_AccountID(AccountID) 
	);
    
	SET vr_Count = 0;
	MYLOOP1:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'ProbationAccountMonitor';
               
        SELECT MAX(temp.CustID)
        INTO   MaxID
		FROM  (SELECT p.CustID FROM CTS_DataCenter.ProbationAccountMonitor AS p 
			   WHERE p.CustID > MinID
			   ORDER BY p.CustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CustID FROM CTS_DataCenter.ProbationAccountMonitor AS p 
					   WHERE p.CustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP1;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CustID)
		SELECT DISTINCT p.CustID
		FROM 	CTS_DataCenter.ProbationAccountMonitor AS p
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CustID = c.CustID and c.CustSubID = 0
		WHERE	p.CustID BETWEEN MinID AND MaxID
			AND c.CustID IS NULL;
			
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_ProbationAccountMonitor
		SELECT bk.* FROM CTS_DataCenter.ProbationAccountMonitor AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CustID = cus.CustID
		WHERE bk.CustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.ProbationAccountMonitor AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CustID = cus.CustID
		WHERE dd.CustID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'ProbationAccountMonitor';
		
	END WHILE MYLOOP1;
    SELECT vr_Count AS 'ProbationAccountMonitor_Count';
    
	SET vr_Count = 0;
	MYLOOP2:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'CTSCustomerClassification';
               
        SELECT MAX(temp.CustID)
        INTO   MaxID
		FROM  (SELECT p.CustID FROM CTS_DataCenter.CTSCustomerClassification AS p 
			   WHERE p.CustID > MinID
			   ORDER BY p.CustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CustID FROM CTS_DataCenter.CTSCustomerClassification AS p 
					   WHERE p.CustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP2;
        END IF;

		INSERT INTO Temp_CustomerToDelete(CustID)
		SELECT DISTINCT p.CustID
		FROM 	CTS_DataCenter.CTSCustomerClassification AS p			
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CustID = c.CustID and c.CustSubID = 0
		WHERE	p.CustID BETWEEN MinID AND MaxID
			AND c.CustID IS NULL;
			
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_CTSCustomerClassification
		SELECT bk.* FROM CTS_DataCenter.CTSCustomerClassification AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CustID = cus.CustID
		WHERE  bk.CustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.CTSCustomerClassification AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CustID = cus.CustID
		WHERE  dd.CustID BETWEEN MinID AND MaxID;
			
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'CTSCustomerClassification';
		
	END WHILE MYLOOP2;
    SELECT vr_Count AS 'CTSCustomerClassification_Count';
    
	SET vr_Count = 0;
	MYLOOP3:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'CTSCustomerClassification_History';
               
        SELECT MAX(temp.CustID)
        INTO   MaxID
		FROM  (SELECT p.CustID FROM CTS_DataCenter.CTSCustomerClassification_History AS p 
			   WHERE p.CustID > MinID
			   ORDER BY p.CustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CustID FROM CTS_DataCenter.CTSCustomerClassification_History AS p 
					   WHERE p.CustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP3;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CustID)
		SELECT DISTINCT p.CustID
		FROM 	CTS_DataCenter.CTSCustomerClassification_History AS p	
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CustID = c.CustID and c.CustSubID = 0
		WHERE	p.CustID BETWEEN MinID AND MaxID
			AND c.CustID IS NULL;
        
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_CTSCustomerClassification_History
		SELECT bk.* FROM CTS_DataCenter.CTSCustomerClassification_History AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CustID = cus.CustID
		WHERE  bk.CustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.CTSCustomerClassification_History AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CustID = cus.CustID
		WHERE  dd.CustID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
		
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'CTSCustomerClassification_History';
        
	END WHILE MYLOOP3;
    SELECT vr_Count AS 'CTSCustomerClassification_History_Count';

	SET vr_Count = 0;
	MYLOOP4:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'CustEvidence';
               
        SELECT MAX(temp.CTSCustID)
        INTO   MaxID
		FROM  (SELECT p.CTSCustID FROM CTS_DataCenter.CustEvidence AS p 
			   WHERE p.CTSCustID > MinID
			   ORDER BY p.CTSCustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CTSCustID FROM CTS_DataCenter.CustEvidence AS p 
					   WHERE p.CTSCustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP4;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CTSCustID)
		SELECT DISTINCT p.CTSCustID
		FROM 	CTS_DataCenter.CustEvidence AS p
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CTSCustID = c.CTSCustID and c.CustSubID = 0
		WHERE	p.CTSCustID BETWEEN MinID AND MaxID
			AND c.CTSCustID IS NULL;
        
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_CustEvidence
		SELECT bk.* FROM CTS_DataCenter.CustEvidence AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CTSCustID = cus.CTSCustID
		WHERE bk.CTSCustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.CustEvidence AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CTSCustID = cus.CTSCustID
		WHERE dd.CTSCustID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'CustEvidence';
		
	END WHILE MYLOOP4;
    SELECT vr_Count AS 'CustEvidence_Count';
	
	SET vr_Count = 0;
	MYLOOP5:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'CustDCSAccount';
               
        SELECT MAX(temp.AccountID)
        INTO   MaxID
		FROM  (SELECT p.AccountID FROM CTS_DataCenter.CustDCSAccount AS p 
			   WHERE p.AccountID > MinID
			   ORDER BY p.AccountID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.AccountID FROM CTS_DataCenter.CustDCSAccount AS p 
					   WHERE p.AccountID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP5;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CTSCustID)
		SELECT DISTINCT p.CTSCustID
		FROM 	CTS_DataCenter.CustDCSAccount AS p
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CTSCustID = c.CTSCustID and c.CustSubID = 0
		WHERE	p.AccountID BETWEEN MinID AND MaxID
			AND c.CTSCustID IS NULL;
        
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_CustDCSAccount
		SELECT bk.* FROM CTS_DataCenter.CustDCSAccount AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CTSCustID = cus.CTSCustID
		WHERE  bk.AccountID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.CustDCSAccount AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CTSCustID = cus.CTSCustID
		WHERE  dd.AccountID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'CustDCSAccount';
		
	END WHILE MYLOOP5;
    SELECT vr_Count AS 'CustDCSAccount_Count';

	SET vr_Count = 0;
	MYLOOP6:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'SpecialCustomerClass';
               
        SELECT MAX(temp.CustID)
        INTO   MaxID
		FROM  (SELECT p.CustID FROM CTS_DataCenter.SpecialCustomerClass AS p 
			   WHERE p.CustID > MinID
			   ORDER BY p.CustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CustID FROM CTS_DataCenter.SpecialCustomerClass AS p 
					   WHERE p.CustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP6;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CustID)
		SELECT DISTINCT p.CustID
		FROM 	CTS_DataCenter.SpecialCustomerClass AS p
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CustID = c.CustID and c.CustSubID = 0
		WHERE	p.CustID BETWEEN MinID AND MaxID
			AND c.CustID IS NULL;
			
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_SpecialCustomerClass
		SELECT bk.* FROM CTS_DataCenter.SpecialCustomerClass AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CustID = cus.CustID
		WHERE bk.CustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.SpecialCustomerClass AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CustID = cus.CustID
		WHERE dd.CustID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'SpecialCustomerClass';
		
	END WHILE MYLOOP6;
    SELECT vr_Count AS 'SpecialCustomerClass_Count';	
	
	SET vr_Count = 0;
	MYLOOP7:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'AssociationByDevice';
               
        SELECT MAX(temp.CTSCustID)
        INTO   MaxID
		FROM  (SELECT p.CTSCustID FROM CTS_DataCenter.AssociationByDevice AS p 
			   WHERE p.CTSCustID > MinID
			   ORDER BY p.CTSCustID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.CTSCustID FROM CTS_DataCenter.AssociationByDevice AS p 
					   WHERE p.CTSCustID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP7;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(CTSCustID)
		SELECT DISTINCT p.CTSCustID
		FROM 	CTS_DataCenter.AssociationByDevice AS p
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON p.CTSCustID = c.CTSCustID and c.CustSubID = 0
		WHERE	p.CTSCustID BETWEEN MinID AND MaxID
			AND c.CTSCustID IS NULL;
        
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_AssociationByDevice
		SELECT bk.* FROM CTS_DataCenter.AssociationByDevice AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.CTSCustID = cus.CTSCustID
		WHERE  bk.CTSCustID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM CTS_DataCenter.AssociationByDevice AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.CTSCustID = cus.CTSCustID
		WHERE  dd.CTSCustID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
        
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'AssociationByDevice';
		
	END WHILE MYLOOP7;
    SELECT vr_Count AS 'AssociationByDevice_Count';
	
	SET vr_Count = 0;
	MYLOOP8:WHILE (1 = 1)
	DO
		DO SLEEP(ip_Delay);
		TRUNCATE TABLE Temp_CustomerToDelete;
		
		SELECT (p.MaxID + 1)
        INTO   MinID
        FROM CTS_Adhoc.BK150319_Parameter AS p WHERE p.TableName = 'Account';
               
        SELECT MAX(temp.AccountID)
        INTO   MaxID
		FROM  (SELECT p.AccountID FROM DCS_DataCenter.Account AS p 
			   WHERE p.AccountID > MinID
			   ORDER BY p.AccountID ASC LIMIT ip_Batch) AS temp;
		
        IF NOT EXISTS (SELECT p.AccountID FROM DCS_DataCenter.Account AS p 
					   WHERE p.AccountID > MinID LIMIT 1)
		THEN
			LEAVE MYLOOP8;
        END IF;
		
		INSERT INTO Temp_CustomerToDelete(AccountID)
		SELECT DISTINCT p.AccountID
		FROM 	DCS_DataCenter.Account AS p
			LEFT JOIN CTS_DataCenter.CustDCSAccount AS a ON p.AccountID = a.AccountID
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID and c.CustSubID = 0
		WHERE	p.AccountID BETWEEN MinID AND MaxID
			AND a.AccountID IS NULL
			AND c.CTSCustID IS NULL 
			AND p.IsCTSTransformed = 1;
        
		/* BACKUP */        
		INSERT IGNORE INTO CTS_Adhoc.BK150319_Account
		SELECT bk.* FROM DCS_DataCenter.Account AS bk
			INNER JOIN Temp_CustomerToDelete AS cus ON bk.AccountID = cus.AccountID
		WHERE  bk.AccountID BETWEEN MinID AND MaxID;
		
		/* DELETE */
		DELETE dd
		FROM DCS_DataCenter.Account AS dd
			INNER JOIN Temp_CustomerToDelete AS cus ON dd.AccountID = cus.AccountID
		WHERE  dd.AccountID BETWEEN MinID AND MaxID;
		
        SET vr_Count = vr_Count + (SELECT COUNT(*) FROM Temp_CustomerToDelete);
        
		DELETE d
		FROM Temp_CustomerToDelete AS d;
		
		UPDATE CTS_Adhoc.BK150319_Parameter AS p 
		SET 	p.MinID		= MinID
			,	p.MaxID		= MaxID
		WHERE p.TableName = 'Account';
        
	END WHILE MYLOOP8;
    SELECT vr_Count AS 'Account_Count';
	
END$$
DELIMITER ;

#Execution 
CALL CTS_AD_RemoveDataNotExistInCTSCustomer(10000, 1);

DROP PROCEDURE IF EXISTS CTS_AD_RemoveDataNotExistInCTSCustomer;