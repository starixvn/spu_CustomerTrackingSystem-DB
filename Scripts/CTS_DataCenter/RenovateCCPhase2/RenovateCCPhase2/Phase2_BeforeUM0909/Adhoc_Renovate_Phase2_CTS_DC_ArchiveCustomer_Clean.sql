/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Clean`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Clean`()
    SQL SECURITY INVOKER
sp: BEGIN
/*
		Created:	20240826@Victoria.Le
		Task:		Clean CCMain/History Redundant - General + BySport
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Clean(1000,9999,op_MaxHistoryID);
			
		Revisions: 
			- 20240826@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

    /*************************************** 1. DCS_DataCenter.Association *************************************/
	IF EXISTS (SELECT 1  FROM DCS_DataCenter.Association AS ass  WHERE  ass.AccountID IN (SELECT tmp.AccountID FROM Temp_Customer_Archive AS tmp)) THEN
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
		WHERE  ass.AccountID IN (SELECT tmp.AccountID FROM Temp_Customer_Archive AS tmp);
		
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
		
	END IF;
	
    /*************************************** 2. DCS_DataCenter.Account *****************************************/
	IF EXISTS (SELECT 1  FROM DCS_DataCenter.Account AS acc WHERE  acc.AccountID IN (SELECT tmp.AccountID FROM Temp_Customer_Archive AS tmp)) THEN
		
		DELETE acc
		FROM DCS_DataCenter.Account AS acc
			INNER JOIN  Temp_Customer_Archive AS tmp ON acc.AccountID = tmp.AccountID;

	END IF;
    
    /*************************************** 3. DCS_DataCenter.SumAccountLoginTotal ******************************/
	IF EXISTS (SELECT 1  FROM DCS_DataCenter.SumAccountLoginTotal AS acc WHERE  acc.AccountID IN (SELECT tmp.AccountID FROM Temp_Customer_Archive AS tmp)) THEN
		
		DELETE acc
		FROM DCS_DataCenter.SumAccountLoginTotal AS acc
			INNER JOIN  Temp_Customer_Archive AS tmp ON acc.AccountID = tmp.AccountID;
		
	END IF;
    
	/*************************************** 4. CTS_DataCenter.AssociatedAccountMonitor ************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountMonitor AS aam WHERE  aam.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		
		DELETE aam
		FROM CTS_DataCenter.AssociatedAccountMonitor AS  aam
			INNER JOIN Temp_Customer_Archive AS tmp ON tmp.CTSCustID = aam.CTSCustID;

	END IF;
    
    /*************************************** 5. CTS_DataCenter.AssociatedAccountNotification *******************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociatedAccountNotification AS ass WHERE  ass.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccountNotification_Clean;
		CREATE TEMPORARY TABLE Temp_AssociatedAccountNotification_Clean(
				AccountNewAssID   	BIGINT UNSIGNED  PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociatedAccountNotification_Clean(AccountNewAssID)
		SELECT ass.AccountNewAssID
		FROM CTS_DataCenter.AssociatedAccountNotification AS ass
		WHERE  ass.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.AssociatedAccountNotification AS ass
		WHERE  ass.AccountNewAssID IN (SELECT tmp.AccountNewAssID FROM Temp_AssociatedAccountNotification_Clean AS tmp);

	END IF;
    
    /*************************************** 6. CTS_DataCenter.AssociationByAI *********************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI AS ai WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
				AssID	BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByAI_Clean(AssID)
		SELECT 	ai.AssID
		FROM CTS_DataCenter.AssociationByAI  AS ai
		WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.AssociationByAI AS ass
			INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.AssID = ass.AssID;
	END IF;
    
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByAI AS ai WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
				AssID	BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByAI_Clean(AssID)
		SELECT 	ai.AssID
		FROM CTS_DataCenter.AssociationByAI AS ai
		WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.AssociationByAI AS ass
			INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.AssID = ass.AssID;

	END IF;


	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationGroupByAI AS asg WHERE  asg.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationGroupByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationGroupByAI_Clean(
				CustID 		BIGINT UNSIGNED NOT NULL
			,	GroupID 	BIGINT UNSIGNED NOT NULL
			
			,	PRIMARY KEY (CustID, GroupID)
		);
		
		INSERT IGNORE INTO Temp_AssociationGroupByAI_Clean(CustID, GroupID)
		SELECT 	asg.CustID
			,	asg.GroupID
		FROM CTS_DataCenter.AssociationGroupByAI AS asg
		WHERE  asg.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE asg
		FROM CTS_DataCenter.AssociationGroupByAI AS asg
			INNER JOIN Temp_AssociationGroupByAI_Clean AS tmp ON tmp.CustID = asg.CustID AND tmp.GroupID = asg.GroupID;

	END IF;
	
   /**************************************** 7. CTS_DataCenter.AssociationByDevice ****************************/

	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByDevice  AS dv WHERE dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByDevice_Clean(
				CTSAssDevID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByDevice_Clean(CTSAssDevID)
		SELECT 	dv.CTSAssDevID
		FROM CTS_DataCenter.AssociationByDevice AS dv
		WHERE  dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE dv
		FROM CTS_DataCenter.AssociationByDevice AS dv
		WHERE  dv.CTSAssDevID IN (SELECT tmp.CTSAssDevID FROM Temp_AssociationByDevice_Clean AS tmp);
	
		
	END IF;
    
	/*************************************** 8. CTS_DataCenter.AssociationByIP ********************************/

	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP AS ip WHERE ip.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
		SELECT 	ip.ID
		FROM CTS_DataCenter.AssociationByIP AS ip
		WHERE  ip.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ip
		FROM CTS_DataCenter.AssociationByIP AS ip
		WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);

	END IF;
     
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationByIP AS ip WHERE ip.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
		SELECT 	ip.ID
		FROM CTS_DataCenter.AssociationByIP AS ip
		WHERE  ip.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE 
		FROM CTS_DataCenter.AssociationByIP AS ip
		WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
		
		
	END IF;  
     
    /*************************************** 9. CTS_DataCenter.AssociationRemove ****************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove AS rm WHERE rm.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp))  THEN
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
		WHERE  rm.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.AssociationRemove AS ass
			INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;
		
		
	END IF;
    
    
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.AssociationRemove AS rm WHERE rm.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
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
		WHERE  rm.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.AssociationRemove AS ass
			INNER JOIN Temp_AssociationRemove_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;

	END IF;

	/*************************************** 10. CTS_DataCenter.CTSCustomerClassification/History, CTSCustomerClassification_BySport/History ********************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification AS clss WHERE clss.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp WHERE tmp.TypeCC IN (1,3))) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Clean;
		CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Clean(
				CustID   			BIGINT UNSIGNED  
			,	SportGroupID		INT UNSIGNED
			,	CategoryID			INT
			,	ParentID			INT
			,	CategoryID_new		INT
			,	PRIMARY KEY(CustID, SportGroupID, CategoryID)
		);

		INSERT IGNORE INTO Temp_CTSCustomerClassification_Clean(CustID, SportGroupID, CategoryID, ParentID, CategoryID_new)
		SELECT 	tmp.CustID
			,	latest.SportGroupID
			,	latest.CategoryID
			,	latest.ParentID
			,	latest.CategoryID_new
		FROM Temp_Customer_Archive AS tmp 
			, LATERAL (
				SELECT cc.SportGroupID, cc.CategoryID, cate.ParentID, cate.CategoryID AS CategoryID_new
				FROM CTS_DataCenter.CTSCustomerClassification AS cc
					INNER JOIN CTS_DataCenter.CustomerCategory_new AS cate ON cate.OldCategoryID = cc.CategoryID
				WHERE cc.CustID = tmp.CustID
					AND tmp.TypeCC IN (1,3)
				ORDER BY cate.CustomerClassPriority ASC, cc.LastModifiedDate DESC
				LIMIT 1
			) AS latest
		;

		IF EXISTS (SELECT 1 FROM Temp_CTSCustomerClassification_Clean) THEN
			UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
				INNER JOIN Temp_Customer_Archive AS temp ON temp.ArchiveID = arc.ID AND temp.RoleID = 1 AND temp.TypeCC IN (1,3)
				INNER JOIN Temp_CTSCustomerClassification_Clean AS cate ON cate.CustID = arc.CustID
			SET 	arc.ParentID = CASE WHEN arc.CategoryID IS NULL THEN cate.ParentID ELSE arc.ParentID END
				,	arc.CategoryID_bk = CASE WHEN arc.CategoryID IS NULL THEN cate.CategoryID ELSE arc.CategoryID_bk END
				,	arc.CategoryID_new = CASE WHEN arc.CategoryID IS NULL THEN cate.CategoryID_new ELSE arc.CategoryID_new END
				,	arc.CategoryID = CASE WHEN arc.CategoryID IS NULL THEN cate.CategoryID ELSE arc.CategoryID END
			;
			
			DELETE cl
			FROM CTS_DataCenter.CTSCustomerClassification AS cl
				INNER JOIN Temp_CTSCustomerClassification_Clean AS tmp ON tmp.CustID = cl.CustID;
			
			DELETE his
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
				INNER JOIN Temp_CTSCustomerClassification_Clean AS tmp ON tmp.CustID = his.CustID
			;
			
		END IF;

	END IF;

	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_BySport AS clss WHERE clss.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp WHERE tmp.TypeCC IN (2,3))) THEN
		
		DELETE cl
		FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cl
			INNER JOIN Temp_Customer_Archive AS tmp ON tmp.CustID = cl.CustID
		WHERE tmp.TypeCC IN (2,3);
		
		DELETE his
		FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his
			INNER JOIN Temp_Customer_Archive AS tmp ON tmp.CustID = his.CustID
		;
	END IF;
     
    /*************************************** 11. CTS_DataCenter.CTSCustomerClassification_InputDataLog *******/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo WHERE lo.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN 
		DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_InputDataLog_Clean;
		CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_InputDataLog_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CTSCustomerClassification_InputDataLog_Clean(ID)
		SELECT 	lo.ID
		FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo
		WHERE lo.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE lo
		FROM CTS_DataCenter.CTSCustomerClassification_InputDataLog AS lo
		WHERE  lo.ID IN (SELECT tmp.ID FROM Temp_CTSCustomerClassification_InputDataLog_Clean AS tmp);

	END IF;
    
    /*************************************** 12. CTS_DataCenter.CustDCSAccount *******************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustDCSAccount AS cu WHERE cu.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		
		DELETE cu
		FROM CTS_DataCenter.CustDCSAccount AS cu
		WHERE  cu.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp);

	END IF;
    
    /*************************************** 13. CTS_DataCenter.CustEvidence *********************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
		CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
				CustEvidID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
		SELECT 	ev.CustEvidID
		FROM CTS_DataCenter.CustEvidence AS ev
		WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustEvidence AS ev
		WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidence_Clean AS tmp);
		
	END IF;
     
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidence AS ev WHERE ev.FromCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence_Clean;
		CREATE TEMPORARY TABLE Temp_CustEvidence_Clean(
				CustEvidID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CustEvidence_Clean(CustEvidID)
		SELECT 	ev.CustEvidID
		FROM CTS_DataCenter.CustEvidence AS ev
		WHERE  ev.FromCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustEvidence  AS ev
		WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidence_Clean AS tmp);

	END IF;

	/*************************************** 14. CTS_DataCenter.CustEvidenceFromFile *************************/

	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceFromFile AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceFromFile_Clean;
		CREATE TEMPORARY TABLE Temp_CustEvidenceFromFile_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CustEvidenceFromFile_Clean(ID)
		SELECT 	ev.ID
		FROM CTS_DataCenter.CustEvidenceFromFile AS ev
		WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustEvidenceFromFile AS ev
		WHERE  ev.ID IN (SELECT tmp.ID FROM Temp_CustEvidenceFromFile_Clean AS tmp);

	END IF;  
     
    /*************************************** 15. CTS_DataCenter.CustEvidenceLog ******************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceLog AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceLog_Clean;
		CREATE TEMPORARY TABLE Temp_CustEvidenceLog_Clean(
				CustEvidID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CustEvidenceLog_Clean(CustEvidID)
		SELECT 	ev.CustEvidID
		FROM CTS_DataCenter.CustEvidenceLog AS ev
		WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustEvidenceLog AS ev
		WHERE  ev.CustEvidID IN (SELECT tmp.CustEvidID FROM Temp_CustEvidenceLog_Clean AS tmp);

	END IF;
     
    /*************************************** 16. CTS_DataCenter.CustEvidenceQueue ****************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustEvidenceQueue AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceQueue_Clean;
		CREATE TEMPORARY TABLE Temp_CustEvidenceQueue_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_CustEvidenceQueue_Clean(ID)
		SELECT 	ev.ID
		FROM CTS_DataCenter.CustEvidenceQueue AS ev
		WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustEvidenceQueue AS ev
		WHERE  ev.ID IN (SELECT tmp.ID FROM Temp_CustEvidenceQueue_Clean AS tmp);

	END IF;  
	
	/*************************************** 17. CTS_DataCenter.CustException ********************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException AS ex WHERE ex.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
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
		WHERE  ex.FromCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.CustException AS ass
			INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;

	END IF;
     
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustException AS ex WHERE ex.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
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
		WHERE  ex.ToCTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_DataCenter.CustException AS ass
			INNER JOIN Temp_CustException_Clean AS tmp ON tmp.FromCTSCustID = ass.FromCTSCustID AND tmp.ToCTSCustID = ass.ToCTSCustID;

	END IF;
     
    /*************************************** 18. CTS_DataCenter.CustRetractEvidence ***************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.CustRetractEvidence  AS ev WHERE ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
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
		WHERE  ev.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ev
		FROM CTS_DataCenter.CustRetractEvidence AS ev
			INNER JOIN Temp_CustRetractEvidence_Clean AS tmp ON tmp.CTSCustID = ev.CTSCustID
														AND tmp.EvidenceID = ev.EvidenceID;

	END IF; 
	
    /*************************************** 19. CTS_DataCenter.SpecialCustomerClass/History **************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass As sp WHERE sp.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp WHERE tmp.TypeCC IN (1,3))) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_Clean;
		CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_Clean(
				CustID   				BIGINT UNSIGNED 
			,	CreatedFromFunction		TINYINT
			,	PRIMARY KEY(CustID, CreatedFromFunction)
		);
		
		INSERT IGNORE INTO Temp_SpecialCustomerClass_Clean(CustID, CreatedFromFunction)
		SELECT 	sp.CustID
			,	sp.CreatedFromFunction
		FROM CTS_DataCenter.SpecialCustomerClass As sp
		WHERE  sp.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE sp
		FROM CTS_DataCenter.SpecialCustomerClass AS sp
			INNER JOIN Temp_SpecialCustomerClass_Clean AS tmp ON tmp.CustID = sp.CustID
															AND tmp.CreatedFromFunction = sp.CreatedFromFunction;
															
		DELETE sp
		FROM CTS_DataCenter.SpecialCustomerClass_History AS sp
			INNER JOIN Temp_SpecialCustomerClass_Clean AS tmp ON tmp.CustID = sp.CustID;
	END IF;  
     
    /*************************************** 20. CTS_DataCenter.TaggingExclusion ******************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.TaggingExclusion AS tag WHERE tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_TaggingExclusion_Clean;
		CREATE TEMPORARY TABLE Temp_TaggingExclusion_Clean(
				CTSCustID   	BIGINT UNSIGNED PRIMARY KEY 
		);
		
		INSERT IGNORE INTO Temp_TaggingExclusion_Clean(CTSCustID)
		SELECT 	tag.CTSCustID
		FROM CTS_DataCenter.TaggingExclusion AS tag
		WHERE  tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE tag
		FROM CTS_DataCenter.TaggingExclusion AS tag
		WHERE  tag.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_TaggingExclusion_Clean AS tmp);

	END IF;  
      
	/*************************************** 21. CTS_Archive.CTSCustomerAssociationStatus *********************/
	IF EXISTS (SELECT 1  FROM CTS_Archive.CTSCustomerAssociationStatus AS acc WHERE  acc.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		
		DELETE acc
		FROM CTS_Archive.CTSCustomerAssociationStatus AS acc
			INNER JOIN  Temp_Customer_Archive AS tmp ON acc.CustID = tmp.CustID;
			
	END IF;
	
    /*************************************** 22. CTS_Archive.AssociationByAI_Arc ******************************/
 
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByAI_Arc AS ai WHERE ai.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
				ID   	BIGINT UNSIGNED  PRIMARY KEY 
		);
		
		INSERT IGNORE INTO Temp_AssociationByAI_Clean(ID)
		SELECT ai.ID
		FROM CTS_Archive.AssociationByAI_Arc AS ai
		WHERE  ai.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_Archive.AssociationByAI_Arc AS ass
			INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.ID = ass.ID;
			
	END IF;
    
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByAI_Arc AS ai WHERE ai.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByAI_Clean(
				ID   	BIGINT UNSIGNED  PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByAI_Clean(ID)
		SELECT 	ai.ID
		FROM CTS_Archive.AssociationByAI_Arc AS ai
		WHERE  ai.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_Archive.AssociationByAI_Arc AS ass
			INNER JOIN Temp_AssociationByAI_Clean AS tmp ON tmp.ID = ass.ID;
	
	END IF;
    
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationGroupByAI_Arc AS ai WHERE ai.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationGroupByAI_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationGroupByAI_Clean(
				ID   	BIGINT UNSIGNED  PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationGroupByAI_Clean(ID)
		SELECT 	ai.ID
		FROM CTS_Archive.AssociationGroupByAI_Arc AS ai
		WHERE  ai.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ass
		FROM CTS_Archive.AssociationGroupByAI_Arc AS ass
			INNER JOIN Temp_AssociationGroupByAI_Clean AS tmp ON tmp.ID = ass.ID;
	
	END IF;
    
	/*************************************** 23. CTS_Archive.AssociationByDevice_Arc ***************************/
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByDevice_Arc AS dv WHERE dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByDevice_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByDevice_Clean(ID)
		SELECT 	dv.ID
		FROM CTS_Archive.AssociationByDevice_Arc AS dv
		WHERE  dv.CTSCustID IN (SELECT tmp.CTSCustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE dv
		FROM CTS_Archive.AssociationByDevice_Arc AS dv
		WHERE  dv.ID IN (SELECT tmp.ID FROM Temp_AssociationByDevice_Clean AS tmp);
	
	END IF; 
    
    /*************************************** 24. CTS_Archive.AssociationByIP_Arc *******************************/
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByIP_Arc AS ip WHERE ip.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
		SELECT 	ip.ID
		FROM CTS_Archive.AssociationByIP_Arc AS ip
		WHERE  ip.FromCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ip
		FROM CTS_Archive.AssociationByIP_Arc AS ip
		WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
		
	END IF;
     
	IF EXISTS (SELECT 1  FROM CTS_Archive.AssociationByIP_Arc AS ip WHERE ip.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_Clean;
		CREATE TEMPORARY TABLE Temp_AssociationByIP_Clean(
				ID   BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssociationByIP_Clean(ID)
		SELECT 	ip.ID
		FROM CTS_Archive.AssociationByIP_Arc AS ip
		WHERE  ip.ToCustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE ip
		FROM CTS_Archive.AssociationByIP_Arc AS ip
		WHERE  ip.ID IN (SELECT tmp.ID FROM Temp_AssociationByIP_Clean AS tmp);
		
	END IF; 

	/*************************************** 25. CTS_DataCenter.SpecialCustomerClass_BySport/History **************************/
	IF EXISTS (SELECT 1  FROM CTS_DataCenter.SpecialCustomerClass_BySport As sp WHERE sp.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp WHERE tmp.TypeCC IN (2,3))) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass_BySport_Clean;
		CREATE TEMPORARY TABLE Temp_SpecialCustomerClass_BySport_Clean(
				CustID		   			BIGINT UNSIGNED 
			,	SportID					SMALLINT
			,	PRIMARY KEY(CustID, SportID)
		);
		
		INSERT IGNORE INTO Temp_SpecialCustomerClass_BySport_Clean(CustID, SportID)
		SELECT 	sp.CustID
			,	sp.SportID
		FROM CTS_DataCenter.SpecialCustomerClass_BySport As sp
		WHERE  sp.CustID IN (SELECT tmp.CustID FROM Temp_Customer_Archive AS tmp)
		;
		
		DELETE sp
		FROM CTS_DataCenter.SpecialCustomerClass_BySport AS sp
			INNER JOIN Temp_SpecialCustomerClass_BySport_Clean AS tmp ON tmp.CustID = sp.CustID
																		AND tmp.SportID = sp.SportID;
															
		DELETE sp
		FROM CTS_DataCenter.SpecialCustomerClass_BySport_History AS sp
			INNER JOIN Temp_SpecialCustomerClass_BySport_Clean AS tmp ON tmp.CustID = sp.CustID
																		AND tmp.SportID = sp.SportID;
															
	END IF; 
    
END$$
DELIMITER ;

